# Security

NetForge modifies **local** macOS network settings. No telemetry, no cloud, no router access.

## Permissions

- **root** (`sudo`) for install and `networksetup` / `sysctl` / `pmset`

## macOS-specific notes

- DNS is applied via `networksetup` (not DoH by default)
- Disabling File Sharing / Remote Login affects system services you may rely on
- Application Firewall enablement may prompt for app allowances
- LaunchDaemon runs skip `systemsetup` for sharing changes (it can hang without a TTY); `launchctl` is used instead
- `DISABLE_AWDL` is best-effort â€” Apple removed or restricted AWDL disable APIs on recent macOS releases

## Safe install

Clone and read `src/network-auto.sh` before running. Install only from [github.com/Pitchfork-and-Torch/netforge-macos](https://github.com/Pitchfork-and-Torch/netforge-macos). Prefer `./src/netforge-status.sh` (read-only) before elevating.

## Edge cases

| Situation | Guidance |
|-----------|----------|
| Captive portal | Custom DNS can slow portal detection. Temporarily clear DNS via System Settings â†’ Network, authenticate, then re-run NetForge. |
| VPN / always-on | Service order (Ethernet before Wi-Fi) may interact with VPN virtual interfaces â€” review with status script. |
| Offline | After first clone, applies only local settings; no network required to re-run. |
| MDM / supervised Macs | Org profiles can override `networksetup` â€” NetForge cannot fight MDM. |

## Uninstall

`sudo ./src/uninstall-network-auto.sh`

## Captive portal recovery

If hotel/airport Wi-Fi will not show a login page after NetForge DNS changes, run **`./src/clear-captive-portal.sh`** (elevated), authenticate, then re-run the normal NetForge apply script.
