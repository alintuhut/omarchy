# Alin's Omarchy Extensions

Personal customizations for Omarchy that live outside the core files.

## Structure

```
alin/
├── bin/                          # Custom scripts → ~/.local/bin/
│   ├── omarchy-vpn-list          # List available VPNs
│   ├── omarchy-vpn-toggle        # Connect/disconnect VPNs
│   ├── omarchy-vpn-status        # Waybar status indicator
│   └── omarchy-vpn-menu          # Standalone VPN picker menu
├── config/                       # Reference configs (for documentation)
│   ├── hypr/bindings.conf
│   └── waybar/
│       ├── vpn-module.jsonc
│       └── vpn-style.css
├── install/                      # Individual feature installers
│   └── vpn.sh                    # VPN extension installer
├── install.sh                    # Main installer (runs all install/*.sh)
└── README.md
```

## Installation

### Install everything

```bash
./alin/install.sh
```

This runs all installers in `install/` directory.

### Install specific extension

```bash
./alin/install/vpn.sh
```

## Extensions

### VPN Selector (Super+Shift+V)

**Installer:** `install/vpn.sh`

Supports both **WireGuard** and **OpenVPN**:

| Type | Config Location |
|------|-----------------|
| WireGuard | `/etc/wireguard/<name>.conf` |
| OpenVPN | `/etc/openvpn/client/<name>.conf` |

Features:
- Shows menu with all available VPNs
- Current VPN is pre-selected
- Selecting same VPN disconnects it
- Selecting different VPN switches to it
- Waybar indicator (󰌾) shows when connected

What `install/vpn.sh` does:
1. ✅ Installs packages (`wireguard-tools`, `openvpn`)
2. ✅ Configures sudoers for passwordless VPN control
3. ✅ Copies scripts to `~/.local/bin/`
4. ✅ Adds keybinding to `~/.config/hypr/bindings.conf`
5. ✅ Adds VPN module to `~/.config/waybar/config.jsonc`
6. ✅ Adds VPN styles to `~/.config/waybar/style.css`

## Adding New Extensions

1. Create `install/your-feature.sh`
2. Add scripts to `bin/`
3. Add reference configs to `config/`
4. Run `./install.sh` to install all, or `./install/your-feature.sh` for just that one

## Philosophy

Following the [Omarchy dotfiles documentation](https://learn.omacom.io/2/the-omarchy-manual/65/dotfiles):

- Scripts go to `~/.local/bin/` (in PATH, outside Omarchy)
- Config changes go to `~/.config/` (user's domain)
- Never modify `~/.local/share/omarchy/` directly
- Omarchy updates won't break your customizations
