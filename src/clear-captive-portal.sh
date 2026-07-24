#!/usr/bin/env bash
# Temporarily clear custom DNS so captive portals can load. Re-run network-auto after login.
set -euo pipefail
echo "NetForge captive-portal recovery (macOS)"
while IFS= read -r svc; do
  [[ -z "$svc" ]] && continue
  echo "  service: $svc"
  networksetup -setdnsservers "$svc" Empty 2>/dev/null || true
done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)
echo "Open the portal page, authenticate, then: sudo ./src/network-auto.sh"