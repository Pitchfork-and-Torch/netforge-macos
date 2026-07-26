# NetForge for macOS

**Automatic network performance tuning and optional hardening for macOS.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-12+-000000)](https://github.com/Pitchfork-and-Torch/netforge-macos)

Part of the **NetForge suite** — same philosophy as [Windows](https://github.com/Pitchfork-and-Torch/netforge-windows) and [Linux](https://github.com/Pitchfork-and-Torch/netforge-linux). See [SUITE.md](SUITE.md) for platform differences and related tools.

---

## Quick install

```bash
git clone https://github.com/Pitchfork-and-Torch/netforge-macos.git
cd netforge-macos
# Optional: read-only health report first
./src/netforge-status.sh
sudo ./src/install-network-auto.sh
```

Bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/Pitchfork-and-Torch/netforge-macos/main/install.sh | sudo bash
```

Review `install.sh` before piping to `bash`.

---

## What it does

| Area | Action |
|------|--------|
| **DNS** | Cloudflare + Google on each network service via `networksetup` |
| **Routing** | Ethernet services ordered before Wi-Fi when both exist |
| **TCP** | Buffer tuning via `sysctl` |
| **Power** | `pmset` reduced sleep on AC |
| **Firewall** | Enables Application Firewall |
| **Optional** | Disables Remote Login and File Sharing |
| **Optional** | Best-effort AWDL disable (`DISABLE_AWDL`) |

**Triggers:** LaunchDaemon at boot, on network plist changes, and every 5 minutes.

Logs: `/var/log/netforge/network-auto.log`

macOS does not expose Windows-style DoH APIs — DNS is set via `networksetup`. See [SECURITY.md](SECURITY.md).

### Status (read-only doctor)

```bash
./src/netforge-status.sh
```

Reports network services, DNS, routes, Application Firewall, LaunchDaemons, and recent log lines **without changing anything**.

---

## Suite

| Platform | Repo |
|----------|------|
| Windows | [netforge-windows](https://github.com/Pitchfork-and-Torch/netforge-windows) |
| Linux | [netforge-linux](https://github.com/Pitchfork-and-Torch/netforge-linux) |
| macOS | [netforge-macos](https://github.com/Pitchfork-and-Torch/netforge-macos) |

**Related:** [trench-coat](https://github.com/Pitchfork-and-Torch/trench-coat) (privacy routing) · [ghost-continuum](https://github.com/Pitchfork-and-Torch/ghost-continuum) (defense plane)

---

## Requirements

- macOS 12+ recommended
- Administrator (`sudo`)

---

## Configuration

Edit `config/defaults.conf` before install. See `config/defaults.example.conf`.

---

## Uninstall

```bash
sudo ./src/uninstall-network-auto.sh
```

---

## FAQ

### Will this break hotel / airport captive portals?

Sometimes. Custom DNS can slow or block the portal login page. Temporarily clear DNS in **System Settings → Network**, authenticate, then re-run NetForge (or restore your preferred DNS). Details are in [SECURITY.md](SECURITY.md).

### Does NetForge for macOS enable DNS-over-HTTPS like the Windows build?

Not the same way. Windows can force DoH through OS APIs; macOS applies resolvers with `networksetup`. Encrypted DNS is still possible via system/browser settings outside this script.

### Can I inspect changes before elevating?

Yes — run the read-only doctor first:

```bash
./src/netforge-status.sh
```

### Is there telemetry?

No. Settings and logs stay on the Mac.

### Where do I report bugs?

[GitHub Issues](https://github.com/Pitchfork-and-Torch/netforge-macos/issues) on this repo.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Support the work

NetForge is **free and open source**. Bug reports and feature requests are welcome via [GitHub Issues](https://github.com/Pitchfork-and-Torch/netforge-macos/issues).
