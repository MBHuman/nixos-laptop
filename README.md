# NixOS Laptop Configuration

Flake-based NixOS configuration for **Honor MagicBook X14 Pro** with Intel Arc GPU.

## Structure

```
flakes/
├── flake.nix              # Flake inputs & outputs (nixpkgs, devShells)
├── configuration.nix      # Main system configuration
├── hyprland.conf          # Hyprland window manager config (auto-deployed)
├── wireguard.nix          # WireGuard VPN template (fill in & import when ready)
├── shells/
│   └── picodata.nix       # Picodata dev shell (Rust, Python, Node.js)
└── hardware-configuration.nix  # Auto-generated (create on the laptop!)
docs/
└── hyprland-guide.md      # Hyprland user guide (keybindings, tips)
```

## What's Included

| Category | Details |
|---|---|
| **Boot** | systemd-boot, latest kernel (for Intel Arc) |
| **GPU** | Intel Arc drivers, mesa, VA-API |
| **Audio** | PipeWire ( PulseAudio compatible ) |
| **Desktop** | Hyprland (from nixpkgs) + waybar, kitty, rofi, dunst |
| **Login** | greetd + tuigreet |
| **Shell** | ZSH + Oh My Zsh (agnoster theme, autosuggestions, syntax highlighting) |
| **Editors** | Neovim, VS Code |
| **Browser** | Google Chrome |
| **Messaging** | Telegram Desktop |
| **VPN** | WireGuard tools + OpenVPN + config template |
| **Network** | NetworkManager, Bluetooth |
| **Firmware** | fwupd |
| **Dev** | Picodata dev shell (Rust, Python 3.11, Node.js 20) |

## Setup on a fresh NixOS install

### 1. Clone this repo

```bash
git clone https://github.com/YOUR_USERNAME/nixos-laptop.git
cd nixos-laptop
```

### 2. Generate hardware config

If you don't have `hardware-configuration.nix` yet:

```bash
# On the laptop, generate it from the current system
nixos-generate-config --dir /tmp/nixos-config
cp /tmp/nixos-config/hardware-configuration.nix flakes/hardware-configuration.nix
```

### 3. Set your password

Uncomment the `initialPassword` line in `configuration.nix` for first boot, then change it:

```bash
passwd
```

### 4. Build & apply

```bash
# Build the configuration
sudo nixos-rebuild switch --flake .#honor

# Or just test it first (won't make it default)
sudo nixos-rebuild test --flake .#honor
```

## Shell: ZSH + Oh My Zsh

Default shell is **zsh** with:
- **Theme:** agnoster (clean prompt with git branch info)
- **Plugins:** git, sudo, z, history, colored-man-pages, command-not-found
- **Autosuggestions** — suggests commands as you type based on history
- **Syntax highlighting** — commands colored green/red as you type

Config is managed by NixOS. For personal customizations, edit `~/.zshrc` after the Oh My Zsh block.

## Dev Shells

### Picodata (default)

```bash
# Enter the Picodata dev environment
nix develop

# Or explicitly:
nix develop .#picodata
```

Includes: Rust (via rustup), Python 3.11, Node.js 20, Yarn, CMake, GCC, and all required libraries.

### Adding new dev shells

1. Create `flakes/shells/your-shell.nix`
2. Add it to `devShells` in `flake.nix`
3. Run: `nix develop .#your-shell`

## WireGuard VPN Setup

### Quick manual usage

```bash
# Import a .conf file from your VPN provider
sudo wg-quick up ./my-vpn.conf

# Disconnect
sudo wg-quick down ./my-vpn.conf
```

### Permanent NixOS-managed tunnel

1. Fill in `flakes/wireguard.nix` with your server details
2. Generate a private key on the laptop:
   ```bash
   wg genkey | sudo tee /etc/wireguard/wg0.private
   sudo chmod 600 /etc/wireguard/wg0.private
   ```
3. Import `wireguard.nix` in `configuration.nix`:
   ```nix
   imports = [ ./hardware-configuration.nix ./wireguard.nix ];
   ```
4. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#honor
   ```

## OpenVPN (Corporate VPN)

```bash
# Connect with a config file
sudo openvpn --config /path/to/your-corporate-vpn.ovpn

# Or run as a background service
sudo systemctl start openvpn-your-config
```

## Adding packages

Edit `environment.systemPackages` in `configuration.nix`, then rebuild.

## Documentation

- 📖 [Hyprland — Руководство пользователя](docs/hyprland-guide.md) — хоткеи, навигация, скриншоты, устранение неполадок

## Updating

```bash
# Update all flake inputs
nix flake update

# Rebuild with updated inputs
sudo nixos-rebuild switch --flake .#honor