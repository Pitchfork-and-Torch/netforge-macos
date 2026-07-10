#!/usr/bin/env bash
# Read-only NetForge health report for macOS (no system changes).
set -euo pipefail

echo "NetForge status (read-only) — $(date '+%Y-%m-%dT%H:%M:%S%z')"
echo

echo "=== networksetup services ==="
if command -v networksetup >/dev/null 2>&1; then
  networksetup -listallnetworkservices 2>/dev/null || true
  echo
  echo "=== Service order (first = preferred) ==="
  networksetup -listnetworkserviceorder 2>/dev/null | head -n 40 || true
  echo
  echo "=== DNS per service (sample) ==="
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == *"*"* || "$line" == "An asterisk"* ]] && continue
    echo "-- $line"
    networksetup -getdnsservers "$line" 2>/dev/null || true
  done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | head -n 8)
else
  echo "(networksetup not found — run on macOS)"
fi

echo
echo "=== Default routes ==="
netstat -rn -f inet 2>/dev/null | head -n 20 || route -n get default 2>/dev/null || true

echo
echo "=== Application Firewall ==="
if command -v /usr/libexec/ApplicationFirewall/socketfilterfw >/dev/null 2>&1; then
  /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || true
else
  echo "(socketfilterfw not available)"
fi

echo
echo "=== LaunchDaemons (NetForge) ==="
ls -la /Library/LaunchDaemons/*netforge* 2>/dev/null || ls -la /Library/LaunchDaemons/*NetForge* 2>/dev/null || echo "(no NetForge LaunchDaemons found)"

echo
echo "=== Log tail ==="
LOG="/var/log/netforge/network-auto.log"
if [[ -f "$LOG" ]]; then
  echo "Log: $LOG"
  tail -n 8 "$LOG" 2>/dev/null || true
else
  echo "(no NetForge log yet at $LOG)"
fi

echo
echo "No settings were changed."
