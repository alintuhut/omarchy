#!/bin/bash

# VPN Extension Installer
# Installs VPN selector with WireGuard and OpenVPN support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="$HOME/.local/bin"
HYPR_CONFIG="$HOME/.config/hypr"
WAYBAR_CONFIG="$HOME/.config/waybar"

echo "󰌾 Installing VPN extension..."
echo ""

# ─────────────────────────────────────────────────────────────
# 1. Install required packages
# ─────────────────────────────────────────────────────────────
echo "  📦 Installing packages..."

if ! command -v wg &>/dev/null; then
  sudo pacman -S --noconfirm --needed wireguard-tools
  echo "     ✓ wireguard-tools"
else
  echo "     ✓ wireguard-tools (already installed)"
fi

if ! command -v openvpn &>/dev/null; then
  sudo pacman -S --noconfirm --needed openvpn
  echo "     ✓ openvpn"
else
  echo "     ✓ openvpn (already installed)"
fi

# Ensure jq is installed for safe JSON manipulation
if ! command -v jq &>/dev/null; then
  sudo pacman -S --noconfirm --needed jq
  echo "     ✓ jq"
else
  echo "     ✓ jq (already installed)"
fi

# ─────────────────────────────────────────────────────────────
# 2. Setup sudoers for passwordless VPN
# ─────────────────────────────────────────────────────────────
echo "  🔐 Configuring sudoers..."

sudo tee /etc/sudoers.d/omarchy-vpn >/dev/null <<EOF
# Allow VPN control without password
$USER ALL=(ALL) NOPASSWD: /usr/bin/wg-quick
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl start openvpn-client@*
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop openvpn-client@*
# Allow listing VPN configs (directories are protected)
$USER ALL=(ALL) NOPASSWD: /usr/bin/find /etc/wireguard *
$USER ALL=(ALL) NOPASSWD: /usr/bin/find /etc/openvpn/client *
$USER ALL=(ALL) NOPASSWD: /usr/bin/test -f /etc/wireguard/*
$USER ALL=(ALL) NOPASSWD: /usr/bin/test -f /etc/openvpn/client/*
EOF
sudo chmod 440 /etc/sudoers.d/omarchy-vpn
echo "     ✓ /etc/sudoers.d/omarchy-vpn"

# ─────────────────────────────────────────────────────────────
# 3. Install scripts
# ─────────────────────────────────────────────────────────────
echo "  📜 Installing scripts..."

mkdir -p "$LOCAL_BIN"

for script in omarchy-vpn-list omarchy-vpn-menu omarchy-vpn-status omarchy-vpn-toggle; do
  if [[ -f "$SCRIPT_DIR/bin/$script" ]]; then
    cp "$SCRIPT_DIR/bin/$script" "$LOCAL_BIN/$script"
    chmod +x "$LOCAL_BIN/$script"
    echo "     ✓ $script"
  fi
done

# ─────────────────────────────────────────────────────────────
# 4. Add keybinding to Hyprland config (read from config file)
# ─────────────────────────────────────────────────────────────
echo "  ⌨️  Configuring keybindings..."

HYPR_BINDINGS="$HYPR_CONFIG/bindings.conf"
HYPR_BINDINGS_SRC="$SCRIPT_DIR/config/hypr/bindings.conf"

if [[ -f "$HYPR_BINDINGS" ]]; then
  if grep -qF "omarchy-vpn-menu" "$HYPR_BINDINGS"; then
    echo "     ✓ Keybinding already exists"
  else
    echo "" >> "$HYPR_BINDINGS"
    # Append bindings from config file (skip comment-only lines at start)
    cat "$HYPR_BINDINGS_SRC" >> "$HYPR_BINDINGS"
    echo "     ✓ Added to $HYPR_BINDINGS"
  fi
else
  mkdir -p "$HYPR_CONFIG"
  echo "# Alin's custom keybindings" > "$HYPR_BINDINGS"
  echo "" >> "$HYPR_BINDINGS"
  cat "$HYPR_BINDINGS_SRC" >> "$HYPR_BINDINGS"
  echo "     ✓ Created $HYPR_BINDINGS"
fi

# ─────────────────────────────────────────────────────────────
# 5. Add VPN module to Waybar config (in center, after clock)
# ─────────────────────────────────────────────────────────────
echo "  📊 Configuring Waybar..."

WAYBAR_CONF="$WAYBAR_CONFIG/config.jsonc"
VPN_MODULE_SRC="$SCRIPT_DIR/config/waybar/vpn-module.jsonc"
# Extract the custom/vpn module from config file (strip comments)
VPN_MODULE=$(sed 's|//.*||g' "$VPN_MODULE_SRC" | jq '."custom/vpn"')

if [[ -f "$WAYBAR_CONF" ]]; then
  if grep -qF '"custom/vpn"' "$WAYBAR_CONF"; then
    echo "     ✓ Waybar module already configured"
  else
    # Create backup
    cp "$WAYBAR_CONF" "$WAYBAR_CONF.bak"
    echo "     ✓ Backup created: config.jsonc.bak"
    
    # Strip comments for jq processing (JSONC -> JSON)
    # Then add our module and convert back
    TEMP_JSON=$(mktemp)
    
    # Remove // comments and trailing commas for jq
    sed 's|//.*||g' "$WAYBAR_CONF" | jq '.' > "$TEMP_JSON" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
      # Add custom/vpn to modules-center after "clock"
      jq '."modules-center" |= (
        if index("clock") then
          .[:index("clock")+1] + ["custom/vpn"] + .[index("clock")+1:]
        else
          ["custom/vpn"] + .
        end
      )' "$TEMP_JSON" > "${TEMP_JSON}.1" && mv "${TEMP_JSON}.1" "$TEMP_JSON"
      
      # Add the custom/vpn module definition
      jq --argjson vpn "$VPN_MODULE" '."custom/vpn" = $vpn' "$TEMP_JSON" > "${TEMP_JSON}.1" && mv "${TEMP_JSON}.1" "$TEMP_JSON"
      
      # Format nicely and save
      jq '.' "$TEMP_JSON" > "$WAYBAR_CONF"
      rm -f "$TEMP_JSON"
      
      echo "     ✓ Added custom/vpn to modules-center"
      echo "     ✓ Added module definition"
    else
      rm -f "$TEMP_JSON"
      # Restore backup if jq failed
      mv "$WAYBAR_CONF.bak" "$WAYBAR_CONF"
      echo "     ⚠ Failed to parse config - restored backup"
      echo "     ℹ Add manually to ~/.config/waybar/config.jsonc:"
      echo '       1. Add "custom/vpn" to "modules-center" after "clock"'
      echo '       2. Add this module definition:'
      echo '          "custom/vpn": {'
      echo '            "exec": "omarchy-vpn-status",'
      echo '            "return-type": "json",'
      echo '            "interval": 5,'
      echo '            "signal": 9,'
      echo '            "on-click": "omarchy-vpn-menu"'
      echo '          }'
    fi
  fi
else
  echo "     ⚠ config.jsonc not found"
  echo "     ℹ Add manually when config exists"
fi

# ─────────────────────────────────────────────────────────────
# 6. Add VPN styles to Waybar CSS (read from config file)
# ─────────────────────────────────────────────────────────────
WAYBAR_STYLE="$WAYBAR_CONFIG/style.css"
VPN_STYLE_SRC="$SCRIPT_DIR/config/waybar/vpn-style.css"

if [[ -f "$WAYBAR_STYLE" ]]; then
  if grep -qF '#custom-vpn' "$WAYBAR_STYLE"; then
    echo "     ✓ Waybar styles already exist"
  else
    # Append styles from config file (skip comment lines)
    echo "" >> "$WAYBAR_STYLE"
    grep -v '^/\*\|^\*/' "$VPN_STYLE_SRC" >> "$WAYBAR_STYLE"
    echo "     ✓ Added styles to style.css"
  fi
else
  echo "     ⚠ style.css not found - skip"
fi

echo ""
echo "  ✅ VPN extension installed!"
echo "     Place configs in: /etc/wireguard/ or /etc/openvpn/client/"
echo "     Keybinding: Super+Shift+V"
