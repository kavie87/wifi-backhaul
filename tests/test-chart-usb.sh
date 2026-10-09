#!/bin/sh
# Chart visibility and USB schedule classification. No modem is contacted.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
script=$root/wifi-backhaul
fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

WIFI_BACKHAUL_LIB_ONLY=1
# shellcheck disable=SC1090
. "$script"

work=$(mktemp -d 2>/dev/null || echo "/tmp/wb-chart.$$")
mkdir -p "$work/bin" "$work/uci"
cat > "$work/bin/uci" <<'UCI'
#!/bin/sh
store=${UCI_STORE:?}
mkdir -p "$store"
if [ "$1" = -q ]; then
  shift
fi
if [ "$1" = set ]; then
  key=$(printf '%s' "$2" | sed "s/=.*//")
  val=$(printf '%s' "$2" | sed "s/.*=//")
  printf '%s' "$val" > "$store/$(printf '%s' "$key" | tr '.' '_')"
  exit 0
fi
case "$1" in
  get)
    f=$store/$(printf '%s' "$2" | tr '.' '_')
    [ -f "$f" ] || exit 1
    cat "$f"
    ;;
  commit) exit 0 ;;
  *) exit 1 ;;
esac
UCI
chmod 755 "$work/bin/uci"
PATH="$work/bin:$PATH"
UCI_STORE=$work/uci
export PATH UCI_STORE

reset_cards() {
  rm -f "$work/uci"/*
  printf '%s' "$1" > "$work/uci/web_card_Charts_hide"
  printf '%s' "$2" > "$work/uci/web_card_CPU_hide"
  printf '%s' "$3" > "$work/uci/web_card_RAM_hide"
  printf '%s' "$4" > "$work/uci/web_card_A_BackhaulDown_hide"
  printf '%s' "$5" > "$work/uci/web_card_B_BackhaulUp_hide"
  # Presence checks use uci -q get web.card_CPU, which reads web_card_CPU.
  printf '%s' section > "$work/uci/web_card_CPU"
  printf '%s' section > "$work/uci/web_card_RAM"
  printf '%s' section > "$work/uci/web_card_A_BackhaulDown"
  printf '%s' section > "$work/uci/web_card_B_BackhaulUp"
  printf '%s' section > "$work/uci/web_card_Charts"
}

# 1. Summary on, individuals hidden. Fresh install must not rewrite them.
reset_cards 0 1 1 1 1
UPDATE=n
apply_chart_visibility
[ "$(cat "$work/uci/web_card_CPU_hide")" = 1 ] || fail "summary mode hid a card that was already hidden, or showed it"
[ "$(cat "$work/uci/web_card_Charts_hide")" = 0 ] || fail "summary chart was turned off"
pass "summary chart with hidden detail cards is preserved"

# 2. Summary on, CPU visible, backhaul cards already hidden.
reset_cards 0 0 1 1 1
UPDATE=n
apply_chart_visibility
[ "$(cat "$work/uci/web_card_CPU_hide")" = 0 ] || fail "a visible CPU card was hidden"
[ "$(cat "$work/uci/web_card_A_BackhaulDown_hide")" = 1 ] || fail "a hidden backhaul card was shown"
pass "CPU stays visible and hidden backhaul cards stay hidden"

# 2b. Summary on, backhaul cards visible. Fresh install hides them.
reset_cards 0 0 0 0 0
UPDATE=n
apply_chart_visibility
[ "$(cat "$work/uci/web_card_A_BackhaulDown_hide")" = 1 ] || fail "summary mode left Backhaul Download visible"
[ "$(cat "$work/uci/web_card_B_BackhaulUp_hide")" = 1 ] || fail "summary mode left Backhaul Upload visible"
[ "$(cat "$work/uci/web_card_CPU_hide")" = 0 ] || fail "summary mode hid CPU"
[ "$(cat "$work/uci/web_card_Charts_hide")" = 0 ] || fail "summary chart was turned off"
pass "a prior summary chart hides the separate backhaul cards"

# 3. Summary off, detail cards visible. Fresh install keeps them visible.
reset_cards 1 0 0 0 0
UPDATE=n
apply_chart_visibility
[ "$(cat "$work/uci/web_card_CPU_hide")" = 0 ] || fail "visible detail card was hidden"
[ "$(cat "$work/uci/web_card_Charts_hide")" = 1 ] || fail "summary chart was turned on"
pass "detail cards stay visible when the summary chart is off"

# 4. Summary off, backhaul cards manually hidden. Fresh install currently
# shows the four detail cards. Record that this path changes a hidden
# backhaul card back to visible, because there is no summary chart.
reset_cards 1 0 0 1 1
UPDATE=n
apply_chart_visibility
[ "$(cat "$work/uci/web_card_A_BackhaulDown_hide")" = 0 ] || fail "fresh install did not show the backhaul card"
pass "a fresh install without a summary chart shows the detail cards"

# 5. Summary setting missing. Do not invent summary mode.
rm -f "$work/uci/web_card_Charts_hide" "$work/uci/web_card_Charts"
UPDATE=n
apply_chart_visibility
[ ! -f "$work/uci/web_card_Charts_hide" ] || fail "a missing summary chart was created"
pass "a missing summary chart setting is left missing"

# 6 and 7. Update preserves a mixed layout.
reset_cards 0 0 1 1 1
UPDATE=y
apply_chart_visibility
[ "$(cat "$work/uci/web_card_CPU_hide")" = 0 ] || fail "update hid a visible card"
[ "$(cat "$work/uci/web_card_RAM_hide")" = 1 ] || fail "update showed a hidden card"
[ "$(cat "$work/uci/web_card_Charts_hide")" = 0 ] || fail "update changed the summary chart"
pass "an update preserves the existing chart layout"

# USB schedule classification from the packed web-control.sh
fn=$work/usb-kind.sh
WB_SCRIPT=$(cygpath -w "$script" 2>/dev/null || printf '%s\n' "$script")
WB_FN=$(cygpath -w "$fn" 2>/dev/null || printf '%s\n' "$fn")
export WB_SCRIPT WB_FN
python -c "
import base64, io, os, tarfile
from pathlib import Path
b=Path(os.environ['WB_SCRIPT']).read_bytes()
start=b.index(b'\nH4sI')+1
end=b.index(b'\nEND_DJA_WIFI_BACKHAUL_PAYLOAD')
raw=base64.b64decode(b[start:end].replace(b'\n', b''))
tf=tarfile.open(fileobj=io.BytesIO(raw), mode='r:gz')
text=tf.extractfile('./dja-backhaul/web-control.sh').read().decode()
a=text.index('usb_schedule_kind()')
b=text.index('publish_backup_schedule', a)
Path(os.environ['WB_FN']).write_text(text[a:b], encoding='utf-8', newline='\n')
"
# shellcheck disable=SC1090
. "$fn"
[ "$(usb_schedule_kind '8 3 * * * /root/mtd-backup -d backups -ceoy')" = daily ] || fail "daily"
[ "$(usb_schedule_kind '08 09 * * * /root/mtd-backup -d backups -ceoy')" = daily ] || fail "leading zero"
[ "$(usb_schedule_kind '*/30 * * * * /root/mtd-backup -d backups -ceoy')" = advanced ] || fail "every 30 minutes"
[ "$(usb_schedule_kind '0 */6 * * * /root/mtd-backup -d backups -ceoy')" = advanced ] || fail "every 6 hours"
[ "$(usb_schedule_kind '#8 3 * * * /root/mtd-backup -d backups -ceoy')" = disabled ] || fail "disabled row"
pass "USB backup keeps advanced and disabled schedules out of the daily editor"

rm -rf "$work"
echo "Chart and USB checks passed."
