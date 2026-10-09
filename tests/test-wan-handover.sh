#!/bin/sh
# Mocked checks for WAN handover. This does not touch a modem.
set -eu

script=${1:-}
if [ -z "$script" ]; then
  echo "Usage: $0 /path/to/wan-handover.sh" >&2
  exit 2
fi
lan_dhcp=$(dirname "$script")/lan-dhcp.sh

root=$(mktemp -d)
trap 'kill $(cat "$root/live/watchdog.pid" 2>/dev/null) 2>/dev/null || true; rm -rf "$root"' EXIT

bin=$root/bin
cfg=$root/cfg
base=$root/base
run=$root/run
mkdir -p "$bin" "$cfg" "$base" "$run" "$base/bin"

export DJA_BACKHAUL_BASE=$base
export DJA_BACKHAUL_RUN=$run
export DJA_CONFIG_DIR=$cfg
export DJA_DNSMASQ_INIT=$bin/dnsmasq-init
export WIFI_STA_DEV=wl1_3
export WIFI_STATUS_FILE=$run/status
export WAN_HANDOVER_WATCHDOG_SEC=30
export WAN_HANDOVER_NO_WATCHDOG=1
export PATH="$bin:/usr/bin:/bin"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

cat > "$bin/uci" <<'EOF'
#!/bin/sh
db() {
  for f in "$DJA_CONFIG_DIR/network" "$DJA_CONFIG_DIR/dhcp"; do
    [ -f "$f" ] && cat "$f"
  done
}
q=n
while [ $# -gt 0 ]; do
  case "$1" in
    -q) q=y; shift ;;
    get)
      shift
      key=$1
      val=$(db | sed -n "s/^$key=//p" | head -n 1)
      [ -n "$val" ] || exit 1
      printf '%s\n' "$val"
      exit 0
      ;;
    set)
      shift
      key=${1%%=*}
      val=${1#*=}
      case "$key" in
        dhcp.*) file=$DJA_CONFIG_DIR/dhcp ;;
        *) file=$DJA_CONFIG_DIR/network ;;
      esac
      grep -v "^$key=" "$file" > "$file.new" || true
      printf '%s=%s\n' "$key" "$val" >> "$file.new"
      mv "$file.new" "$file"
      exit 0
      ;;
    delete)
      shift
      key=$1
      case "$key" in
        dhcp.*) file=$DJA_CONFIG_DIR/dhcp ;;
        *) file=$DJA_CONFIG_DIR/network ;;
      esac
      grep -v "^$key=" "$file" > "$file.new" || true
      mv "$file.new" "$file"
      exit 0
      ;;
    commit) exit 0 ;;
    *) shift ;;
  esac
done
exit 0
EOF

cat > "$bin/ip" <<'EOF'
#!/bin/sh
if [ "$1" = "-4" ]; then
  dev=
  prev=
  for arg in "$@"; do
    if [ "$prev" = dev ]; then
      dev=$arg
    fi
    prev=$arg
  done
  case "$dev" in
    wl1_3) printf '2: wl1_3 inet %s brd 192.168.100.255 scope global wl1_3\n' "${MOCK_STA:-192.168.100.31/24}" ;;
    br-lan) printf '3: br-lan inet %s brd 192.168.100.255 scope global br-lan\n' "${MOCK_LAN:-192.168.100.4/24}" ;;
  esac
  exit 0
fi
exit 0
EOF

cat > "$bin/ping" <<'EOF'
#!/bin/sh
mkdir -p "$DJA_BACKHAUL_RUN"
printf '%s\n' "$*" >> "$DJA_BACKHAUL_RUN/ping.log"
n=0
if [ -f "$DJA_BACKHAUL_RUN/ping.count" ]; then
  n=$(cat "$DJA_BACKHAUL_RUN/ping.count")
fi
n=$((n + 1))
printf '%s\n' "$n" > "$DJA_BACKHAUL_RUN/ping.count"
ok=${PING_OK_COUNT:-100}
if [ "$n" -gt "$ok" ]; then
  exit 1
fi
case " $* " in
  *" -I "*) exit 0 ;;
esac
exit 1
EOF

cat > "$bin/arping" <<'EOF'
#!/bin/sh
if [ "${ARPING_CONFLICT:-}" = 1 ]; then
  echo "Unicast reply from 192.168.100.4"
else
  echo "Sent 2 probes"
fi
exit 0
EOF

cat > "$bin/brctl" <<'EOF'
#!/bin/sh
show=$DJA_CONFIG_DIR/bridge
touch "$show"
case "$1" in
  show) cat "$show" ;;
  addif)
    printf '%s\n' "$3" >> "$show"
    printf 'add %s\n' "$3" >> "$DJA_BACKHAUL_RUN/brctl.log"
    ;;
  delif)
    grep -v "^$3$" "$show" > "$show.new" || true
    mv "$show.new" "$show"
    printf 'del %s\n' "$3" >> "$DJA_BACKHAUL_RUN/brctl.log"
    ;;
esac
exit 0
EOF

cat > "$bin/ifdown" <<'EOF'
#!/bin/sh
printf 'down %s\n' "$1" >> "$DJA_BACKHAUL_RUN/if.log"
exit 0
EOF
cat > "$bin/ifup" <<'EOF'
#!/bin/sh
printf 'up %s\n' "$1" >> "$DJA_BACKHAUL_RUN/if.log"
exit 0
EOF
cat > "$bin/dnsmasq-init" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >> "$DJA_BACKHAUL_RUN/dns.log"
exit 0
EOF
chmod 755 "$bin"/*

seed_fresh() {
  rm -rf "$base" "$run" "$cfg"
  mkdir -p "$base" "$run" "$cfg" "$base/backups"
  cat > "$cfg/network" <<'EOF'
network.lan.ifname=eth0 eth1 eth2 eth3
network.lan.ipaddr=192.168.100.4
network.lan.netmask=255.255.255.0
network.wan.ifname=eth4
network.wan.proto=dhcp
network.wan.auto=1
network.wan6=interface
network.wan6.proto=dhcpv6
EOF
  cat > "$cfg/dhcp" <<'EOF'
dhcp.lan.ignore=0
dhcp.lan.dhcpv4=server
EOF
  printf 'br-lan\neth0\neth1\neth2\neth3\n' > "$cfg/bridge"
  printf 'relay-experimental\n' > "$base/client-addressing"
  printf 'Telstra\n' > "$base/ssid"
  printf 'secret\n' > "$base/password"
  printf 'aa:bb:cc:dd:ee:ff\n' > "$base/bssid"
  printf '192.168.100.31\n' > "$run/lease.ip"
  printf '192.168.100.1\n' > "$run/gateway"
  cat > "$run/status" <<'EOF'
wpa_state=COMPLETED
ssid=Telstra
bssid=aa:bb:cc:dd:ee:ff
EOF
  unset ARPING_CONFLICT || true
  export MOCK_STA=192.168.100.31/24
  export MOCK_LAN=192.168.100.4/24
  export PING_OK_COUNT=100
  rm -f "$run/ping.count" "$run/ping.log" "$run/brctl.log"
}

run_sh() {
  /bin/sh "$script" "$@"
}

seed_fresh
if run_sh already; then
  fail "fresh Ethernet WAN was treated as already converted"
fi
pass "fresh WAN is not already converted"

seed_fresh
run_sh record
[ -s "$base/wan-port" ] || fail "WAN port was not recorded"
grep -q '^eth4$' "$base/wan-port" || fail "recorded port was not eth4"
[ ! -f "$base/wan-as-lan" ] || fail "record marked a fresh WAN as LAN"
[ -s "$base/backups/pre-handover/network" ] || fail "pre-handover backup missing"
pass "fresh WAN port is recorded without conversion"

seed_fresh
sed -i 's/^network.wan.ifname=eth4$/network.wan.proto=none/' "$cfg/network"
printf 'network.lan.ifname=eth0 eth1 eth2 eth3 eth4\n' > "$cfg/network.new"
grep -v '^network.lan.ifname=' "$cfg/network" >> "$cfg/network.new"
# The sed above may have removed ifname and broken proto. Rebuild this case.
cat > "$cfg/network" <<'EOF'
network.lan.ifname=eth0 eth1 eth2 eth3 eth4
network.lan.ipaddr=192.168.100.4
network.wan.proto=none
network.wan.auto=0
EOF
if ! run_sh already; then
  fail "existing WAN-as-LAN installation was not recognised"
fi
run_sh record
[ -f "$base/wan-as-lan" ] || fail "existing installation was not marked"
pass "existing WAN-as-LAN installation is preserved"

seed_fresh
if WIFI_BACKHAUL_VERIFIED=1 run_sh verify; then
  pass "verified Wi-Fi path"
else
  fail "expected verification to pass"
fi
grep -q 'WPA authentication successful.' "$base/handover.log" || fail "missing WPA success"
grep -q 'Verifying upstream gateway.' "$base/handover.log" || fail "missing gateway check"
grep -q 'Wi-Fi backhaul verified.' "$base/handover.log" || fail "missing verified message"
grep -q -- '-I 192.168.100.31' "$run/ping.log" || fail "gateway ping was not bound to the Wi-Fi address"
pass "gateway test is bound to the Wi-Fi address"

seed_fresh
printf 'wpa_state=SCANNING\nssid=\nbssid=\n' > "$run/status"
if run_sh verify; then
  fail "missing SSID was accepted"
fi
grep -q 'Upstream Wi-Fi did not connect. Ethernet WAN preserved.' "$base/handover.log" || fail "missing SSID message"
grep -q '^network.wan.proto=dhcp$' "$cfg/network" || fail "WAN changed when the SSID was missing"
pass "unavailable SSID keeps Ethernet WAN"

seed_fresh
printf 'WRONG_KEY\n' > "$run/wpa.log"
printf 'wpa_state=DISCONNECTED\nssid=\nbssid=\n' > "$run/status"
if run_sh verify; then
  fail "wrong password was accepted"
fi
grep -q 'Wi-Fi authentication failed. Ethernet WAN preserved.' "$base/handover.log" || fail "missing authentication message"
pass "wrong password keeps Ethernet WAN"

seed_fresh
rm -f "$run/lease.ip" "$run/gateway"
if run_sh verify; then
  fail "missing DHCP lease was accepted"
fi
grep -q 'Upstream DHCP failed. Ethernet WAN preserved.' "$base/handover.log" || fail "missing DHCP message"
pass "failed upstream DHCP keeps Ethernet WAN"

seed_fresh
export PING_OK_COUNT=0
if run_sh verify; then
  fail "unreachable gateway was accepted"
fi
grep -q 'Upstream gateway is not reachable over Wi-Fi. Ethernet WAN preserved.' "$base/handover.log" || fail "missing gateway failure"
grep -q '^network.wan.proto=dhcp$' "$cfg/network" || fail "WAN changed when the gateway test failed"
pass "unreachable gateway keeps Ethernet WAN"

seed_fresh
export ARPING_CONFLICT=1
if run_sh verify; then
  fail "address conflict was accepted"
fi
grep -q 'The management address conflicts with another device. Ethernet WAN preserved.' "$base/handover.log" || fail "missing conflict message"
pass "management address conflict keeps Ethernet WAN"

seed_fresh
export MOCK_STA=192.168.100.31/16
if run_sh verify; then
  fail "non-/24 upstream was accepted"
fi
grep -q 'Upstream network is not compatible with the LAN management address. Ethernet WAN preserved.' "$base/handover.log" || fail "missing mask message"
pass "non-/24 upstream is rejected"

seed_fresh
cp "$cfg/network" "$root/before-network"
cp "$cfg/dhcp" "$root/before-dhcp"
if run_sh apply; then
  fail "apply ran without verification"
fi
cmp -s "$cfg/network" "$root/before-network" || fail "unverified apply changed network"
pass "unverified apply makes no network change"

seed_fresh
export PING_OK_COUNT=0
cp "$cfg/network" "$root/before-network"
cp "$cfg/dhcp" "$root/before-dhcp"
if WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "failed final ping was treated as success"
fi
cmp -s "$cfg/network" "$root/before-network" || fail "rollback did not restore network"
cmp -s "$cfg/dhcp" "$root/before-dhcp" || fail "rollback did not restore DHCP"
[ ! -f "$base/wan-as-lan" ] || fail "failed handover left the WAN-as-LAN marker"
[ -f "$base/handover-hold" ] || fail "failed handover did not pause retries"
grep -q 'Handover failed — restoring previous configuration.' "$base/handover.log" || fail "missing rollback message"
if WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "held handover ran again"
fi
pass "failed handover rolls back once and does not repeat"

seed_fresh
cp "$cfg/network" "$root/before-network"
if ! WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "successful apply returned an error"
fi
grep -q '^network.lan.ifname=eth0 eth1 eth2 eth3 eth4$' "$cfg/network" || fail "WAN port was not added to the LAN bridge list"
grep -q '^network.wan.ifname=' "$cfg/network" && fail "WAN ifname remained"
grep -q '^network.wan.proto=none$' "$cfg/network" || fail "WAN protocol was not cleared"
grep -q '^dhcp.lan.ignore=1$' "$cfg/dhcp" || fail "LAN DHCP was not disabled"
grep -q '^dhcp.lan.dhcpv4=disabled$' "$cfg/dhcp" || fail "LAN DHCP mode was not disabled"
grep -q '^eth4$' "$cfg/bridge" || fail "WAN port was not added in the bridge"
adds=$(grep -c '^add eth4$' "$run/brctl.log" || true)
[ "$adds" = 1 ] || fail "WAN port was added $adds times"
[ -f "$base/wan-as-lan" ] || fail "success marker missing"
[ ! -f "$base/handover-pending" ] || fail "pending marker left behind"
[ -f "$run/handover-now" ] || fail "this-run marker missing"
grep -q 'Preparing WAN-to-LAN handover.' "$base/handover.log" || fail "missing prepare message"
grep -q 'Converting Ethernet WAN port to LAN.' "$base/handover.log" || fail "missing convert message"
grep -q 'Updating DHCP configuration.' "$base/handover.log" || fail "missing DHCP message"
grep -q 'down wan' "$run/if.log" || fail "WAN was not brought down"
if ! WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "second apply failed"
fi
adds=$(grep -c '^add eth4$' "$run/brctl.log" || true)
[ "$adds" = 1 ] || fail "second apply moved the port again"
pass "successful handover converts once"

seed_fresh
mkdir -p "$base/backups/handover"
cp "$cfg/network" "$base/backups/handover/network"
cp "$cfg/dhcp" "$base/backups/handover/dhcp"
printf 'port=eth4\nlease=192.168.100.31\n' > "$base/backups/handover/state"
printf 'network.lan.ifname=eth0 eth1 eth2 eth3 eth4\nnetwork.wan.proto=none\n' > "$cfg/network"
: > "$base/handover-pending"
WAN_HANDOVER_NO_WATCHDOG=0 WAN_HANDOVER_WATCHDOG_SEC=0 run_sh watchdog
grep -q '^network.wan.ifname=eth4$' "$cfg/network" || fail "watchdog did not restore WAN"
[ -f "$base/handover-hold" ] || fail "watchdog did not pause another attempt"
pass "watchdog restores WAN once"

seed_fresh
mkdir -p "$base/backups/handover"
cp "$cfg/network" "$base/backups/handover/network"
cp "$cfg/dhcp" "$base/backups/handover/dhcp"
printf 'port=eth4\nlease=192.168.100.31\n' > "$base/backups/handover/state"
printf 'network.lan.ifname=eth0 eth1 eth2 eth3 eth4\nnetwork.wan.proto=none\n' > "$cfg/network"
: > "$base/handover-pending"
export WAN_HANDOVER_WATCHDOG_SEC=0
run_sh boot
grep -q '^network.wan.ifname=eth4$' "$cfg/network" || fail "boot did not restore WAN"
[ ! -f "$base/handover-pending" ] || fail "boot left the pending marker"
[ -f "$base/handover-hold" ] || fail "boot did not pause another attempt"
pass "reboot during an unfinished handover restores WAN"

seed_fresh
: > "$base/wan-as-lan"
if /bin/sh "$lan_dhcp" on; then
  grep -q '^dhcp.lan.ignore=0$' "$cfg/dhcp" || fail "DHCP changed after a finished handover"
else
  fail "lan-dhcp on should be a no-op after handover"
fi
pass "a later DHCP-on request does not undo a finished handover"

seed_fresh
printf '255.255.255.252\n' > "$base/waiting-netmask"
printf '1 1\n' > "$base/waiting-dhcp"
/bin/sh "$lan_dhcp" on || fail "lan-dhcp on failed with a leftover marker"
/bin/sh "$lan_dhcp" off || fail "lan-dhcp off failed with a leftover marker"
grep -q '^network.lan.ipaddr=192.168.100.4$' "$cfg/network" || fail "leftover marker changed the LAN address"
grep -q '^network.lan.netmask=255.255.255.0$' "$cfg/network" || fail "leftover marker changed the LAN subnet"
grep -q '^dhcp.lan.ignore=0$' "$cfg/dhcp" || fail "leftover marker changed DHCP"
grep -q '^dhcp.lan.dhcpv4=server$' "$cfg/dhcp" || fail "leftover marker changed the DHCP mode"
grep -q '^network.wan.proto=dhcp$' "$cfg/network" || fail "leftover marker changed WAN"
pass "a leftover waiting-netmask does not change the LAN subnet"

seed_fresh
printf '255.255.255.252\n' > "$base/waiting-netmask"
if ! WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "handover with a leftover marker failed"
fi
grep -q '^network.lan.netmask=255.255.255.0$' "$cfg/network" || fail "handover applied the old waiting subnet"
grep -q '^network.lan.ipaddr=192.168.100.4$' "$cfg/network" || fail "handover changed the management address"
grep -q '^dhcp.lan.ignore=1$' "$cfg/dhcp" || fail "handover did not update DHCP forwarding"
pass "handover ignores a leftover waiting-netmask"

seed_fresh
printf '255.255.255.252\n' > "$base/waiting-netmask"
export PING_OK_COUNT=0
cp "$cfg/network" "$root/before-network"
cp "$cfg/dhcp" "$root/before-dhcp"
if WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "failed handover with a leftover marker was treated as success"
fi
cmp -s "$cfg/network" "$root/before-network" || fail "rollback changed the network while a leftover marker was present"
cmp -s "$cfg/dhcp" "$root/before-dhcp" || fail "rollback changed DHCP while a leftover marker was present"
pass "rollback still restores the saved network when a leftover marker is present"

seed_fresh
cat > "$bin/start-stop-daemon" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$DJA_BACKHAUL_RUN/ssd-args"
case " $* " in
  *" -m "*|*" -p "*) exit 0 ;;
esac
echo "/bin/sh is already running" >&2
exit 1
EOF
chmod +x "$bin/start-stop-daemon"
if ! WAN_HANDOVER_NO_WATCHDOG=0 WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "handover aborted because the watchdog matched every shell"
fi
grep -q -- ' -p ' "$run/ssd-args" || fail "watchdog was not started with its own pid file"
grep -q -- ' -m ' "$run/ssd-args" || fail "watchdog pid file was not created by the start"
grep -q '^eth4$' "$cfg/bridge" || fail "watchdog start did not reach the port move"
[ ! -f "$base/handover-pending" ] || fail "pending marker left behind after a started watchdog"
pass "watchdog starts while other shells are running"

seed_fresh
cat > "$bin/start-stop-daemon" <<'EOF'
#!/bin/sh
echo "/bin/sh is already running" >&2
exit 1
EOF
chmod +x "$bin/start-stop-daemon"
cp "$cfg/network" "$root/before-network"
if WAN_HANDOVER_NO_WATCHDOG=0 WIFI_BACKHAUL_VERIFIED=1 run_sh apply; then
  fail "handover continued after the watchdog could not start"
fi
cmp -s "$cfg/network" "$root/before-network" || fail "a failed watchdog start changed the network"
if grep -q '^eth4$' "$cfg/bridge"; then
  fail "a failed watchdog start moved the WAN port"
fi
[ ! -f "$base/handover-pending" ] || fail "a failed watchdog start left the pending marker"
rm -f "$bin/start-stop-daemon"
pass "a failed watchdog start leaves Ethernet WAN unchanged"

if grep -q 'waiting-netmask' "$script"; then
  fail "wan-handover still consults waiting-netmask"
fi
if grep -q 'network.lan.netmask' "$lan_dhcp"; then
  fail "lan-dhcp can still write a LAN subnet"
fi
pass "the old waiting subnet is not referenced by handover"

echo "All mocked handover tests passed."
