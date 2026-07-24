#!/usr/bin/env bash
# NetForge macOS — network performance tuning and optional hardening
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH=""

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

TRIGGER="manual"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trigger) TRIGGER="${2:-manual}"; shift 2 ;;
    --config) CONFIG_PATH="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

CONFIG_FILE="${CONFIG_PATH:-$REPO_ROOT/config/defaults.conf}"
netforge_load_config "$CONFIG_FILE"
netforge_require_root

netforge_acquire_lock
trap netforge_release_lock EXIT

netforge_rotate_log
netforge_log "=== ${APP_NAME} trigger=${TRIGGER} ==="

service_type() {
  local svc="$1"
  if [[ "$svc" =~ [Ww][Ii][-[:space:]]?[Ff][Ii] ]]; then
    echo wifi
  elif [[ "$svc" =~ [Ee]thernet|[Tt]hunderbolt|[Dd]ock|[Uu][Ss][Bb] ]]; then
    echo ethernet
  else
    echo other
  fi
}

apply_network_services() {
  command -v networksetup >/dev/null 2>&1 || return 0

  local -a services=()
  while IFS= read -r line; do
    [[ -n "$line" && "$line" != *"*"* ]] && services+=("$line")
  done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)

  local has_eth=false has_wifi=false svc stype
  for svc in "${services[@]}"; do
    stype=$(service_type "$svc")
    [[ "$stype" == ethernet ]] && has_eth=true
    [[ "$stype" == wifi ]] && has_wifi=true
  done

  # Prefer Ethernet over Wi-Fi when both exist
  if [[ "$has_eth" == true && "$has_wifi" == true ]]; then
    local -a eth_svcs=() wifi_svcs=() other_svcs=()
    for svc in "${services[@]}"; do
      stype=$(service_type "$svc")
      case "$stype" in
        ethernet) eth_svcs+=("$svc") ;;
        wifi) wifi_svcs+=("$svc") ;;
        *) other_svcs+=("$svc") ;;
      esac
    done
    local -a order_svcs=("${eth_svcs[@]}" "${wifi_svcs[@]}")
    if ((${#other_svcs[@]} > 0)); then
      order_svcs+=("${other_svcs[@]}")
    fi
    networksetup -ordernetworkservices "${order_svcs[@]}" 2>/dev/null || true
    netforge_log "Service order: Ethernet before Wi-Fi"
  fi

  local dns_args=()
  read -r -a dns_args <<<"$DNS_SERVERS"

  for svc in "${services[@]}"; do
    stype=$(service_type "$svc")
    networksetup -setdnsservers "$svc" "${dns_args[@]}" 2>/dev/null || true
    case "$stype" in
      ethernet) netforge_log "Ethernet [$svc] DNS set" ;;
      wifi) netforge_log "Wi-Fi [$svc] DNS set" ;;
      *) netforge_log "Other [$svc] DNS set" ;;
    esac
  done
}

apply_sysctl() {
  local kv
  local -a tunings=(
    "net.inet.tcp.delayed_ack=0"
    "net.inet.tcp.mssdflt=1440"
    "net.inet.tcp.recvspace=131072"
    "net.inet.tcp.sendspace=131072"
  )
  for kv in "${tunings[@]}"; do
    sysctl -w "$kv" >/dev/null 2>&1 || true
  done
  netforge_log "sysctl applied"
}

apply_power() {
  [[ "$HIGH_PERFORMANCE_POWER" == true ]] || return 0
  pmset -a sleep 0 disksleep 0 lessbright 0 2>/dev/null || true
  pmset -a lowpowermode 0 2>/dev/null || true
  netforge_log "pmset: high performance-ish profile"
}

apply_firewall() {
  if [[ -x /usr/libexec/ApplicationFirewall/socketfilterfw ]]; then
    /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null || true
    netforge_log "Application firewall enabled"
  fi
}

apply_sharing() {
  # systemsetup can block for minutes without a TTY; launchctl is enough for daemon runs.
  if [[ "$DISABLE_SSHD" == true ]]; then
    launchctl bootout system/com.openssh.sshd 2>/dev/null || true
    launchctl unload -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    if [[ "$TRIGGER" != "daemon" ]]; then
      systemsetup -setremotelogin off 2>/dev/null || true
    fi
    netforge_log "Remote Login disabled"
  fi
  if [[ "$DISABLE_FILE_SHARE" == true ]]; then
    launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
    if [[ "$TRIGGER" != "daemon" ]]; then
      systemsetup -setfilesharing off 2>/dev/null || true
    fi
    netforge_log "File Sharing disabled"
  fi
}

apply_awdl() {
  [[ "$DISABLE_AWDL" == true ]] || return 0
  if sysctl -w net.link.ieee80211.awdl.disabled=1 >/dev/null 2>&1; then
    netforge_log "AWDL sysctl disabled"
  else
    netforge_log "AWDL sysctl unavailable on this macOS version"
  fi
  ifconfig awdl0 down 2>/dev/null || true
  netforge_log "AWDL hardening attempted (may not persist on recent macOS)"
}

apply_network_services
apply_sysctl
apply_power
apply_firewall
apply_sharing
apply_awdl

dscacheutil -flushcache 2>/dev/null || true
killall -HUP mDNSResponder 2>/dev/null || true
netforge_log "=== complete ==="
