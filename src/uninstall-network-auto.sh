#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/defaults.conf"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
netforge_load_config "$CONFIG_FILE"
netforge_require_root

launchctl bootout system/com.netforge.network-auto 2>/dev/null || true
launchctl unload /Library/LaunchDaemons/com.netforge.network-auto.plist 2>/dev/null || true
rm -f /Library/LaunchDaemons/com.netforge.network-auto.plist

echo "${APP_NAME} LaunchDaemon removed."
echo "Files in ${INSTALL_DIR:-/opt/netforge} and DNS/service settings were not reverted."