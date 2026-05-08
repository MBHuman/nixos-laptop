{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ]; # We will link this in Step 5!

  # ==========================================
  # 1. NIX SETTINGS (flakes MUST be enabled!)
  # ==========================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Auto-optimize the nix store to save disk space
  nix.settings.auto-optimise-store = true;

  # ==========================================
  # 2. HARDWARE (Crucial for Intel Arc)
  # ==========================================
  # FORCE the latest kernel. Without this, your screen will stay black.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Drivers for Intel Arc video decoding and hardware acceleration
    extraPackages = with pkgs; [
      intel-media-driver
      mesa
      libvdpau-va-gl
    ];
  };

  # ==========================================
  # 3. BOOTLOADER
  # ==========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ==========================================
  # 4. NETWORKING & BLUETOOTH
  # ==========================================
  networking.networkmanager.enable = true;
  networking.hostName = "honor"; # Define your hostname
  hardware.bluetooth.enable = true;

  # ==========================================
  # 4b. WIREGUARD VPN
  # ==========================================
  # Install wireguard-tools for manual `wg-quick up/dn` usage
  # Option B: Declare a WireGuard interface — see wireguard.nix template
  #
  # networking.wg-quick.interfaces.wg0 = {
  #   address = [ "10.0.0.2/24" ];
  #   dns = [ "1.1.1.1" ];
  #   privateKeyFile = "/etc/wireguard/wg0.private";
  #   peers = [
  #     {
  #       publicKey = "SERVER_PUBLIC_KEY_HERE";
  #       allowedIPs = [ "0.0.0.0/0" ];
  #       endpoint = "VPN.SERVER.IP:51820";
  #       persistentKeepalive = 25;
  #     }
  #   ];
  # };

  # ==========================================
  # 5. AUDIO (PipeWire)
  # ==========================================
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ==========================================
  # 6. FONTS (Nerd Fonts required for agnoster theme)
  # ==========================================
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # ==========================================
  # 7. HYPRLAND (from nixpkgs, pre-built binary)
  # ==========================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Deploy Hyprland config from flake repo to /etc/hyprland.conf
  environment.etc."hyprland.conf".source = ./hyprland.conf;

  # Auto-link config to user's ~/.config/hypr/ on each rebuild
  system.activationScripts.hyprland-config = ''
    mkdir -p /home/mbhuman/.config/hypr
    ln -sf /etc/hyprland.conf /home/mbhuman/.config/hypr/hyprland.conf
    mkdir -p /home/mbhuman/Screenshots
    chown mbhuman:users /home/mbhuman/.config/hypr /home/mbhuman/Screenshots
  '';

  # Required for Hyprland to function properly (login, audio auth, etc.)
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # A simple terminal login manager so you can access Hyprland
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # ==========================================
  # 8. USER & PASSWORD
  # ==========================================
  users.users.mbhuman = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
    # initialPassword = "temp_password"; # Uncomment to set a temporary password via the flake
  };

  # ==========================================
  # 9. SHELL: ZSH + Oh My Zsh
  # ==========================================
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "sudo"
        "z"
        "history"
        "colored-man-pages"
        "command-not-found"
      ];
    };
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 10000;
    setOptions = [
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
      "SHARE_HISTORY"
    ];
  };

  # ==========================================
  # 10. PACKAGES
  # ==========================================
  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    curl
    wget
    killall

    # Hyprland essentials
    waybar          # Status bar
    dunst           # Notifications
    kitty           # Terminal emulator
    rofi-wayland    # App launcher
    nautilus        # File manager

    # Wayland utilities
    grim            # Screenshot tool
    slurp           # Region selection
    wl-clipboard    # Clipboard manager
    cliphist        # Clipboard history
    brightnessctl   # Screen brightness keys
    pamixer         # Volume control
    pavucontrol     # Audio GUI
    networkmanagerapplet # Wi-Fi GUI
    blueman         # Bluetooth GUI

    # === Editors ===
    vscode

    # === Browsers ===
    google-chrome

    # === Messaging ===
    telegram-desktop        # Telegram Desktop

    # === VPN ===
    wireguard-tools # wg-quick, wg CLI tools
    openvpn         # Corporate VPN
  ];

  # Allow unfree packages (required for Google Chrome, VS Code)
  nixpkgs.config.allowUnfree = true;

  # ==========================================
  # 11. LOCALE & TIMEZONE
  # ==========================================
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  # ==========================================
  # 12. FIRMWARE UPDATES
  # ==========================================
  services.fwupd.enable = true;

  system.stateVersion = "24.05"; # Don't touch this
}