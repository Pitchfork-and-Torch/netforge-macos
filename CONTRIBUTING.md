# Contributing to NetForge for macOS

Thanks for helping improve NetForge.

## Before you start

- Test on a spare Mac or VM when possible
- Do **not** commit personal network data (IPs, SSIDs, MACs, hostnames, usernames in paths)
- Keep scripts idempotent — safe to run repeatedly
- Prefer read-only status scripts first when available

## Development setup

```bash
git clone https://github.com/Pitchfork-and-Torch/netforge-macos.git
cd netforge-macos
sudo ./src/install-network-auto.sh
```

## Pull requests

1. Fork and create a feature branch
2. Test install, manual run, and uninstall paths
3. Run ShellCheck if available on scripts under `src/` and `install.sh`
4. Describe security/compat tradeoffs (DNS, firewall, launchd)
5. One logical change per PR when possible

## Reporting issues

Include:

- macOS version
- Ethernet, Wi-Fi, or VPN involved
- Redacted log lines (paths only if non-identifying)

## Code style

- `bash` with `set -euo pipefail`
- Use config under `config/` — never hardcode user paths
- Optional features gated by config flags
