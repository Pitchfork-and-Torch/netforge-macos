#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH=""; DRY_RUN=false; TRIGGER="manual"
source "$SCRIPT_DIR/lib/common.sh"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trigger) TRIGGER="${2:-manual}"; shift 2 ;;
    --config) CONFIG_PATH="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) echo "Usage: $0 [--dry-run] [--config path] [--trigger name]"; exit 0 ;;
    *) shift ;;
  esac
done
CONFIG_FILE="${CONFIG_PATH:-$REPO_ROOT/config/defaults.conf}"
netforge_load_config "$CONFIG_FILE"
plan() { echo "  [would] $*"; }
if [[ "$DRY_RUN" == true ]]; then echo "NetForge dry-run (no changes) - config: $CONFIG_FILE"
else netforge_require_root; netforge_acquire_lock; trap netforge_release_lock EXIT; netforge_rotate_log; netforge_log "=== ${APP_NAME} v2 trigger=${TRIGGER} ==="; fi
service_type() {
  local svc="$1"
  if [[ "$svc" =~ [Vv][Pp][Nn]|[Ww]ire[Gg]uard|[Tt]unnel|[Tt]ailscale|[Zz]scaler ]]; then echo vpn
  elif [[ "$svc" =~ [Ww][Ii][-[:space:]]?[Ff][Ii] ]]; then echo wifi
  elif [[ "$svc" =~ [Ee]thernet|[Tt]hunderbolt|[Dd]ock|[Uu][Ss][Bb] ]]; then echo ethernet
  else echo other; fi
}
apply_network_services() {
  command -v networksetup >/dev/null 2>&1 || return 0
  local -a services=()
  while IFS= read -r line; do [[ -n "$line" && "$line" != *"*"* ]] && services+=("$line"); done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)
  local has_eth=false has_wifi=false svc stype
  for svc in "${services[@]}"; do stype=$(service_type "$svc"); [[ "$stype" == ethernet ]] && has_eth=true; [[ "$stype" == wifi ]] && has_wifi=true; done
  if [[ "$has_eth" == true && "$has_wifi" == true ]]; then
    local -a eth_svcs=() wifi_svcs=() other_svcs=()
    for svc in "${services[@]}"; do
      stype=$(service_type "$svc")
      case "$stype" in
        ethernet) eth_svcs+=("$svc") ;;
        wifi) wifi_svcs+=("$svc") ;;
        vpn) if [[ "${RESPECT_VPN:-true}" == true ]]; then [[ "$DRY_RUN" == true ]] && plan "skip VPN [$svc]"; continue; fi; other_svcs+=("$svc") ;;
        *) other_svcs+=("$svc") ;;
      esac
    done
    local -a order=("${eth_svcs[@]}" "${wifi_svcs[@]}" "${other_svcs[@]}")
    if [[ "$DRY_RUN" == true ]]; then plan "service order Ethernet before Wi-Fi"
    else networksetup -ordernetworkservices "${order[@]}" 2>/dev/null || true; netforge_log "Service order: Ethernet before Wi-Fi"; fi
  fi
  local dns_args=(); read -r -a dns_args <<<"$DNS_SERVERS"
  for svc in "${services[@]}"; do
    stype=$(service_type "$svc")
    if [[ "$stype" == vpn && "${RESPECT_VPN:-true}" == true ]]; then
      [[ "$DRY_RUN" == true ]] && plan "skip DNS on VPN [$svc]"; continue
    fi
    if [[ "$DRY_RUN" == true ]]; then plan "DNS on [$svc] -> $DNS_SERVERS"
    else networksetup -setdnsservers "$svc" "${dns_args[@]}" 2>/dev/null || true; netforge_log "DNS set [$svc]"; fi
  done
}
apply_sysctl() {
  if [[ "$DRY_RUN" == true ]]; then plan "sysctl TCP buffers"; return 0; fi
  sysctl -w net.inet.tcp.delayed_ack=0 >/dev/null 2>&1 || true
  sysctl -w net.inet.tcp.recvspace=131072 >/dev/null 2>&1 || true
  sysctl -w net.inet.tcp.sendspace=131072 >/dev/null 2>&1 || true
  netforge_log "sysctl applied"
}
apply_sharing() {
  if [[ "${DISABLE_SSHD:-true}" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then plan "disable Remote Login"; else
      launchctl bootout system/com.openssh.sshd 2>/dev/null || true
      launchctl unload -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
      [[ "$TRIGGER" != "daemon" ]] && systemsetup -setremotelogin off 2>/dev/null || true
      netforge_log "Remote Login disabled"
    fi
  fi
  if [[ "${DISABLE_FILE_SHARE:-true}" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then plan "disable File Sharing"; else
      launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
      [[ "$TRIGGER" != "daemon" ]] && systemsetup -setfilesharing off 2>/dev/null || true
      netforge_log "File Sharing disabled"
    fi
  fi
}
apply_network_services; apply_sysctl; apply_sharing
if [[ "$DRY_RUN" == true ]]; then echo "Dry-run complete. No settings changed."; exit 0; fi
dscacheutil -flushcache 2>/dev/null || true
killall -HUP mDNSResponder 2>/dev/null || true
netforge_write_last_run "$TRIGGER"
netforge_log "=== complete ==="