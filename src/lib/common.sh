#!/usr/bin/env bash
set -euo pipefail

netforge_load_config() {
  local config_file="${1:-}"
  APP_NAME="NetForge"
  DNS_SERVERS="1.1.1.1 1.0.0.1 8.8.8.8"
  ETHERNET_METRIC=5
  WIFI_METRIC_ALONE=10
  WIFI_METRIC_WITH_ETH=50
  LOCK_SECONDS=90
  MAX_LOG_LINES=2000
  DISABLE_SSHD=true
  DISABLE_FILE_SHARE=true
  DISABLE_AWDL=false
  HIGH_PERFORMANCE_POWER=true

  if [[ -n "$config_file" && -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    source "$config_file"
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    DATA_DIR="/var/log/netforge"
  else
    DATA_DIR="${HOME}/Library/Application Support/${APP_NAME}"
  fi
  LOG_FILE="${DATA_DIR}/network-auto.log"
  LOCK_FILE="${DATA_DIR}/network-auto.lock"
}

netforge_log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$LOG_FILE"
}

netforge_rotate_log() {
  [[ -f "$LOG_FILE" ]] || return 0
  local count
  count=$(wc -l <"$LOG_FILE" | tr -d ' ')
  if (( count > MAX_LOG_LINES )); then
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" >"${LOG_FILE}.tmp"
    mv "${LOG_FILE}.tmp" "$LOG_FILE"
  fi
}

netforge_acquire_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local age now mtime
    now=$(date +%s)
    mtime=$(stat -f %m "$LOCK_FILE" 2>/dev/null || stat -c %Y "$LOCK_FILE")
    age=$((now - mtime))
    if (( age < LOCK_SECONDS )); then
      exit 0
    fi
  fi
  mkdir -p "$(dirname "$LOCK_FILE")"
  : >"$LOCK_FILE"
}

netforge_release_lock() {
  rm -f "$LOCK_FILE"
}

netforge_require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "NetForge requires root. Re-run with: sudo $0 $*" >&2
    exit 1
  fi
}