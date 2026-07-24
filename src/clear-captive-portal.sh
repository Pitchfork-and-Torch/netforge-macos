#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
CONFIG_FILE="${REPO_ROOT}/config/defaults.conf"; RESTORE=false; PROBE_ONLY=false
while [[ $# -gt 0 ]]; do case "$1" in --restore) RESTORE=true; shift;; --probe-only) PROBE_ONLY=true; shift;; --config) CONFIG_FILE="$2"; shift 2;; *) shift;; esac; done
netforge_load_config "$CONFIG_FILE"
echo "NetForge captive-portal recovery (macOS)"
for u in http://captive.apple.com/hotspot-detect.html http://connectivitycheck.gstatic.com/generate_204; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 -L --max-redirs 0 "$u" 2>/dev/null || echo 000)
  echo "  [$code] $u"
done
if [[ "$RESTORE" == true ]]; then
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Need sudo" >&2; exit 1; }
  "$SCRIPT_DIR/network-auto.sh" --trigger captive-restore --config "$CONFIG_FILE"; exit 0
fi
[[ "$PROBE_ONLY" == true ]] && exit 0
[[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Need sudo" >&2; exit 1; }
while IFS= read -r svc; do
  [[ -z "$svc" || "$svc" == *"*"* ]] && continue
  networksetup -setdnsservers "$svc" Empty 2>/dev/null || true
  echo "  cleared DNS: $svc"
done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)
dscacheutil -flushcache 2>/dev/null || true
echo "After login: sudo $0 --restore"