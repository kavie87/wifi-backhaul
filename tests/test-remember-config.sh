#!/bin/sh
# Mocked checks for -Sr and remembered installer settings.
# Usage: sh tests/test-remember-config.sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
script=$root/wifi-backhaul
fail() {
  echo "FAIL: $1"
  exit 1
}
pass() {
  echo "PASS: $1"
}

WIFI_BACKHAUL_LIB_ONLY=1
# shellcheck disable=SC1090
. "$script"

parse_wifi_args -Sr
[ "$SYNC_REMOVE" = y ] && [ "$SYNC_HOUR" = n ] && [ -z "$PARSE_ERROR" ] || fail "-Sr was treated as enable"
pass "-Sr does not enable synchronisation"

parse_wifi_args -S
[ "$SYNC_HOUR" = y ] && [ "$SYNC_REMOVE" = n ] && [ -z "$PARSE_ERROR" ] || fail "-S parse"
pass "-S enables synchronisation"

parse_wifi_args -S -Sr
[ "$PARSE_ERROR" = remove-combined ] || fail "-S -Sr should be rejected"
pass "-S and -Sr together are rejected"

parse_wifi_args -Sr -y
[ "$SYNC_REMOVE" = y ] && [ "$YES" = y ] && [ -z "$PARSE_ERROR" ] || fail "-Sr -y"
pass "-Sr can skip the confirmation prompt"

if ( parse_wifi_args -X >/dev/null 2>&1 ); then
  fail "-X should not be accepted"
fi
pass "-X is not a removal command"

parse_wifi_args -U -Sr -y
[ "$PARSE_ERROR" = remove-combined ] || fail "-U -Sr should be rejected"
pass "-U -Sr is rejected"
grep -q 'Run ./wifi-backhaul -Sr on its own.' "$script" || fail "rejection message"

if ( parse_wifi_args -r >/dev/null 2>&1 ); then
  fail "lone -r should not be accepted"
fi
pass "lone -r is not a removal command"

work=$(mktemp -d 2>/dev/null || echo "/tmp/wb-remember.$$")
mkdir -p "$work/base"
base=$work/base
cron=$work/cron
DJA_BACKHAUL_BASE=$base
DJA_CRON_FILE=$cron
export DJA_BACKHAUL_BASE DJA_CRON_FILE

printf '%s' 'kept-secret' > "$base/password"
printf '%s' 'Telstra1234' > "$base/ssid"
chmod 600 "$base/password" "$base/ssid"
printf '%s\n' '0 * * * * /root/dja-backhaul/sync-upstream-ssid' '30 3 * * * /root/usb-backup' > "$cron"
: > "$base/sync-ssid"
out=$(remove_hourly_sync)
printf '%s\n' "$out" | grep -q 'SSID synchronisation has been disabled. Your current Wi-Fi configuration has been preserved.' || fail "removal message"
grep -q usb-backup "$cron" || fail "unrelated cron removed"
if grep -q sync-upstream-ssid "$cron"; then
  fail "sync cron still present"
fi
[ ! -f "$base/sync-ssid" ] || fail "marker still present"
printf '%s' 'kept-secret' | cmp -s - "$base/password" || fail "password changed by removal"
printf '%s' 'Telstra1234' | cmp -s - "$base/ssid" || fail "ssid changed by removal"
out=$(remove_hourly_sync)
printf '%s\n' "$out" | grep -q 'SSID synchronisation is not currently enabled. Nothing to remove.' || fail "second removal"
pass "remove once, remove again, keep other cron and credentials"

printf '%s\n' '#0 * * * * /root/dja-backhaul/sync-upstream-ssid' > "$cron"
if sync_cron_active; then
  fail "commented row counted as enabled"
fi
pass "a Scheduled Tasks row that is switched off is not enabled"

printf '%s\n' '#0 */6 * * * /root/dja-backhaul/sync-upstream-ssid' '30 3 * * * /root/usb-backup' > "$cron"
activate_sync_cron
grep -q '^0 \*/6 \* \* \* /root/dja-backhaul/sync-upstream-ssid$' "$cron" || fail "commented row was not restored"
grep -q usb-backup "$cron" || fail "usb row lost while restoring sync"
pass "-S can turn an existing switched-off row back on"

printf '%s\n' 'mode=static' 'ip=192.168.100.31' 'netmask=255.255.255.0' 'gateway=192.168.100.1' 'dns1=1.1.1.1' 'dns2=9.9.9.9' > "$base/backhaul-ip"
printf '%s\n' bh > "$base/backhaul-mode"
cp "$base/backhaul-ip" "$work/ip-before"
printf '%s\n' '#0 * * * * /root/dja-backhaul/sync-upstream-ssid' > "$cron"
YES=y
SYNC_HOUR=n
review_saved_config >/dev/null
[ "$CFG_SSID" = Telstra1234 ] || fail "saved ssid not loaded"
[ "$CFG_HAS_PASS" = y ] || fail "saved password not detected"
[ "$CFG_MODE" = bh ] || fail "BH mode not loaded"
[ "$CFG_IP_MODE" = static ] || fail "static mode not loaded"
[ "$CFG_IP" = 192.168.100.31 ] || fail "static address not loaded"
[ "$CFG_SYNC" = disable ] || fail "disabled cron should load as disabled"
[ -z "$CFG_PASS_NEW" ] || fail "non-interactive run replaced the password"
pass "non-interactive run loads saved settings and does not replace the password"

YES=n
SYNC_HOUR=n
# ssid, password, bssid, backhaul mode, ip mode, address, mask, gateway, dns, dns, sync
review_saved_config >/dev/null <<'EOF'










EOF
[ "$CFG_SSID" = Telstra1234 ] || fail "enter did not keep ssid"
[ "$CFG_MODE" = bh ] || fail "enter did not keep BH mode"
[ "$CFG_IP_MODE" = static ] || fail "enter did not keep static mode"
[ "$CFG_IP" = 192.168.100.31 ] || fail "enter did not keep static address"
[ "$CFG_GW" = 192.168.100.1 ] || fail "enter did not keep gateway"
[ "$CFG_DNS1" = 1.1.1.1 ] || fail "enter did not keep dns"
[ -z "$CFG_PASS_NEW" ] || fail "enter replaced the password"
[ "$CFG_SSID_TOUCHED" = n ] || fail "enter marked the ssid as changed"
apply_reviewed_settings
cmp -s "$work/ip-before" "$base/backhaul-ip" || fail "untouched static configuration was rewritten"
printf '%s' 'kept-secret' | cmp -s - "$base/password" || fail "password file changed"
pass "pressing Enter keeps SSID, BH mode, static addressing and the password"

review_saved_config >/dev/null <<'EOF'
OnlySsid










EOF
[ "$CFG_SSID" = OnlySsid ] || fail "ssid was not changed"
[ -z "$CFG_PASS_NEW" ] || fail "ssid change replaced the password"
apply_reviewed_settings
printf '%s' 'OnlySsid' | cmp -s - "$base/ssid" || fail "new ssid was not stored"
printf '%s' 'kept-secret' | cmp -s - "$base/password" || fail "password changed with the ssid"
pass "changing only the SSID keeps the password"

review_saved_config >"$work/out" <<'EOF'

newpassword










EOF
if grep -q newpassword "$work/out"; then
  fail "new password was printed"
fi
if grep -q kept-secret "$work/out"; then
  fail "old password was printed"
fi
[ -s "$CFG_PASS_NEW" ] || fail "new password was not stored aside"
printf '%s' 'newpassword' | cmp -s - "$CFG_PASS_NEW" || fail "stored password mismatch"
apply_reviewed_settings
printf '%s' 'newpassword' | cmp -s - "$base/password" || fail "new password was not installed"
pass "a new password replaces the saved one without being displayed"

review_saved_config >"$work/out" <<'EOF'

********










EOF
grep -q 'That password was not saved.' "$work/out" || fail "asterisks were accepted"
[ -z "$CFG_PASS_NEW" ] || fail "asterisks were stored"
pass "asterisks are not saved as a password"

printf '%s\n' 'mode=dhcp' 'ip=' 'netmask=255.255.255.0' 'gateway=' 'dns1=' 'dns2=' > "$base/backhaul-ip"
cp "$base/backhaul-ip" "$work/dhcp-before"
review_saved_config >/dev/null <<'EOF'






EOF
[ "$CFG_IP_MODE" = dhcp ] || fail "dhcp was not kept"
apply_reviewed_settings
cmp -s "$work/dhcp-before" "$base/backhaul-ip" || fail "dhcp configuration was rewritten"
pass "pressing Enter keeps DHCP"

rm -f "$base/ssid" "$base/password" "$base/bssid" "$base/backhaul-mode"
printf '%s\n' 'mode=dhcp' 'ip=' 'netmask=255.255.255.0' 'gateway=' 'dns1=' 'dns2=' > "$base/backhaul-ip"
review_saved_config >/dev/null <<'EOF'






EOF
[ -z "$CFG_SSID" ] || fail "blank first run invented an SSID"
[ -z "$CFG_PASS_NEW" ] || fail "blank first run invented a password"
[ "$CFG_MODE" = standard ] || fail "first run should offer Standard Wi-Fi"
pass "a first run does not invent an SSID or password"

printf '%s\n' '0 * * * * /root/dja-backhaul/sync-upstream-ssid' > "$cron"
review_saved_config >/dev/null <<EOF







EOF
[ "$CFG_SYNC" = enable ] || fail "active cron was not detected"
[ "$CFG_SYNC_TOUCHED" = n ] || fail "keeping sync was treated as a new request"
pass "an existing scheduled task is detected and kept"

printf '%s\n' '30 3 * * * /root/usb-backup' > "$cron"
: > "$base/sync-ssid"
YES=y
review_saved_config >/dev/null
[ "$CFG_SYNC" = disable ] || fail "missing cron row was still enabled"
# Applying the preserve rule: no enabled row and the user did not ask to enable.
rm -f "$base/sync-ssid"
if grep -q sync-upstream-ssid "$cron"; then
  fail "a removed row was recreated"
fi
grep -q usb-backup "$cron" || fail "usb row lost"
pass "a task removed outside the installer stays removed"

cron_src=$work/sync-ssid-cron.sh
WB_SCRIPT=$(cygpath -w "$script" 2>/dev/null || printf '%s\n' "$script")
WB_CRON_SRC=$(cygpath -w "$cron_src" 2>/dev/null || printf '%s\n' "$cron_src")
export WB_SCRIPT WB_CRON_SRC
python -c "
import base64, io, os, tarfile
from pathlib import Path
b=Path(os.environ['WB_SCRIPT']).read_bytes()
start=b.index(b'\nH4sI')+1
end=b.index(b'\nEND_DJA_WIFI_BACKHAUL_PAYLOAD')
raw=base64.b64decode(b[start:end].replace(b'\n', b''))
tf=tarfile.open(fileobj=io.BytesIO(raw), mode='r:gz')
Path(os.environ['WB_CRON_SRC']).write_bytes(tf.extractfile('./dja-backhaul/sync-ssid-cron.sh').read())
"
sed "s#/root/dja-backhaul#$base#g; s#/etc/crontabs/root#$cron#g; s#mkdir -p /etc/crontabs#mkdir -p $work#g" "$cron_src" > "$work/cron-helper.sh"
chmod 755 "$work/cron-helper.sh"
mkdir -p "$base"
: > "$base/sync-ssid"
printf '%s\n' '15 * * * * /root/dja-backhaul/sync-upstream-ssid' '15 * * * * /root/dja-backhaul/sync-upstream-ssid' '30 3 * * * /root/usb-backup' > "$cron"
sh "$work/cron-helper.sh"
sh "$work/cron-helper.sh"
count=$(grep -c sync-upstream-ssid "$cron" || true)
[ "$count" = 1 ] || fail "duplicate sync rows were not collapsed ($count)"
grep -q '^15 \* \* \* \* '"$base/sync-upstream-ssid"'$' "$cron" || fail "custom minute was not kept"
grep -q usb-backup "$cron" || fail "usb row lost by the cron helper"
pass "running the sync installer twice keeps one custom schedule"

mkdir -p "$work/bin" "$work/uci"
cat > "$work/bin/uci" <<'UCI'
#!/bin/sh
store=${UCI_STORE:?}
mkdir -p "$store"
if [ "$1" = -q ]; then
  shift
fi
if [ "$1" = -f ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    key=$(printf '%s' "$line" | sed "s/^set //;s/='.*//")
    val=$(printf '%s' "$line" | sed "s/.*='//;s/'$//")
    printf '%s' "$val" > "$store/$(printf '%s' "$key" | tr '.' '_')"
  done < "$2"
  exit 0
fi
case "$1" in
  get)
    f=$store/$(printf '%s' "$2" | tr '.' '_')
    [ -f "$f" ] || exit 1
    cat "$f"
    ;;
  commit|revert) exit 0 ;;
  *) exit 1 ;;
esac
UCI
chmod 755 "$work/bin/uci"
printf '%s' 'Booster24' > "$work/uci/wireless_wl0_ssid"
printf '%s' 'Booster5' > "$work/uci/wireless_wl1_ssid"
printf '%s' 'local-secret' > "$work/uci/wireless_ap0_wpa_psk_key"
printf '%s' 'local-secret' > "$work/uci/wireless_ap2_wpa_psk_key"
printf '%s' 'UpstreamName' > "$base/ssid"
printf '%s' 'kept-secret' > "$base/password"
printf '%s\n' 'mode=dhcp' 'ip=' 'netmask=255.255.255.0' 'gateway=' 'dns1=' 'dns2=' > "$base/backhaul-ip"
printf '%s\n' standard > "$base/backhaul-mode"
PATH="$work/bin:$PATH"
UCI_STORE=$work/uci
export PATH UCI_STORE
YES=n
SYNC_HOUR=n
review_saved_config >/dev/null <<'EOF'




NewBooster




EOF
[ "$CFG_LOCAL_READ" = y ] || fail "local Wi-Fi was not read"
[ "$CFG_SSID" = UpstreamName ] || fail "upstream SSID changed with the booster"
[ "$CFG_SSID24" = NewBooster ] || fail "booster SSID was not changed"
[ "$CFG_SSID5" = Booster5 ] || fail "unchanged booster band was lost"
apply_reviewed_settings
printf '%s' 'NewBooster' | cmp -s - "$work/uci/wireless_wl0_ssid" || fail "booster SSID was not written"
printf '%s' 'local-secret' | cmp -s - "$work/uci/wireless_ap0_wpa_psk_key" || fail "booster password was rewritten"
printf '%s' 'kept-secret' | cmp -s - "$base/password" || fail "upstream password changed with the booster SSID"
pass "changing the booster SSID keeps both passwords"

rm -rf "$work"
echo "All remembered-configuration checks passed."
