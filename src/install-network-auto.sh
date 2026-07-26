#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/defaults.conf"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
netforge_load_config "$CONFIG_FILE"
netforge_require_root

INSTALL_DIR="${INSTALL_DIR:-/opt/netforge}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -a "$REPO_ROOT/." "$INSTALL_DIR/"
rm -rf "$INSTALL_DIR/.git" "$INSTALL_DIR/dist" 2>/dev/null || true

chmod +x "$INSTALL_DIR/src/network-auto.sh"
chmod +x "$INSTALL_DIR/src/install-network-auto.sh"
chmod +x "$INSTALL_DIR/src/uninstall-network-auto.sh"
chmod +x "$INSTALL_DIR/src/lib/common.sh"

mkdir -p /var/log/netforge

cat >/Library/LaunchDaemons/com.netforge.network-auto.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.netforge.network-auto</string>
  <key>ProgramArguments</key>
  <array>
    <string>${INSTALL_DIR}/src/network-auto.sh</string>
    <string>--trigger</string>
    <string>daemon</string>
    <string>--config</string>
    <string>${INSTALL_DIR}/config/defaults.conf</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>300</integer>
  <key>WatchPaths</key>
  <array>
    <string>/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist</string>
    <string>/Library/Preferences/SystemConfiguration/preferences.plist</string>
  </array>
  <key>StandardOutPath</key>
  <string>/var/log/netforge/launchd-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>/var/log/netforge/launchd-stderr.log</string>
</dict>
</plist>
EOF

chmod 644 /Library/LaunchDaemons/com.netforge.network-auto.plist
launchctl bootout system/com.netforge.network-auto 2>/dev/null || true
launchctl unload /Library/LaunchDaemons/com.netforge.network-auto.plist 2>/dev/null || true
if ! launchctl bootstrap system /Library/LaunchDaemons/com.netforge.network-auto.plist 2>/dev/null; then
  launchctl load -w /Library/LaunchDaemons/com.netforge.network-auto.plist
fi
launchctl enable system/com.netforge.network-auto 2>/dev/null || true
launchctl kickstart -k system/com.netforge.network-auto 2>/dev/null || true

"$INSTALL_DIR/src/network-auto.sh" --trigger install --config "${INSTALL_DIR}/config/defaults.conf"

printf '[%s] Installed LaunchDaemon -> %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$INSTALL_DIR" >>/var/log/netforge/network-auto.log

echo ""
echo "${APP_NAME} installed successfully."
echo "  Install dir:   $INSTALL_DIR"
echo "  LaunchDaemon:  com.netforge.network-auto"
echo "  Log file:      /var/log/netforge/network-auto.log"
echo ""
echo "Run manually:  sudo ${INSTALL_DIR}/src/network-auto.sh --trigger manual"
echo ""