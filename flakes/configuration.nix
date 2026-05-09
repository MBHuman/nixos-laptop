{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ]; # We will link this in Step 5!

  documentation = {
    nixos.enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = true;
  };
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
  # 2a. KEYBOARD & TOUCHPAD (Honor MagicBook X14 Pro)
  # ==========================================
  # Keyboard: Honor laptops use PS/2 via i8042 but the controller is non-standard.
  # Without these parameters, the keyboard is not detected at all.
  #
  #   i8042.nopnp=1    — skip ACPI PnP probe, use hardcoded I/O ports (60/64)
  #   i8042.reset=1    — reset PS/2 controller at boot for clean state
  #   i8042.dumbkbd=1  — treat keyboard as write-only (no ACK expected).
  #                       Honor keyboard controller doesn't respond to PS/2 probe
  #                       commands, so the driver thinks no keyboard is present.
  #   i8042.noaux=1    — disable AUX port probing (no PS/2 mouse, avoids conflicts)
  #
  # Touchpad: I2C controllers (intel-lpss PCI 00:15.x) need ACPI _PRT to get IRQs.
  # Honor firmware only populates proper _PRT entries when it detects Windows 10.
  #   acpi_osi="Windows 2020" — add Windows 10 identity so _PRT is populated correctly.
  #   NOTE: do NOT use "acpi_osi=!" — clearing identities breaks _PRT entirely.
  boot.kernelParams = [
    # Keyboard: Honor PS/2 controller doesn't respond to probes — treat as write-only
    "i8042.nopnp=1"
    "i8042.reset=1"
    "i8042.dumbkbd=1"
    "i8042.noaux=1"

    # Touchpad/ACPI: Honor firmware only populates proper _PRT (IRQ routing) and WMI
    # tables when it detects Windows. Without this, I2C controllers (intel-lpss),
    # thermal sensors (WTEC.ECAV), and WMI methods (SMLS) all fail with unresolved symbols.
    "acpi_osi=Windows 2020"
  ];

  # Touchpad: I2C HID device — must load all dependencies early for detection.
  # Also load keyboard modules in initrd for early keyboard support (greetd login).
  boot.initrd.kernelModules = [
    # Keyboard (PS/2 via i8042)
    "atkbd"                     # AT keyboard driver (uses serio layer)
    "serio"                     # Serial I/O bus (used by atkbd/i8042)
    "i8042"                     # PS/2 controller driver

    # Touchpad (I2C HID)
    "i2c_hid_acpi"              # ACPI glue for I2C HID devices (touchpad)
    "i2c_hid"                   # Core I2C HID protocol driver
    "i2c_designware_platform"   # DesignWare I2C bus controller (Intel SoC)
    "i2c_designware_core"       # DesignWare I2C core library
    "pinctrl_intel"             # Pin multiplexing for I2C pins
    "intel_lpss_pci"            # Intel Low-Power Subsystem PCI driver
    "hid_multitouch"            # Multitouch protocol for touchpads
    "hid_generic"               # Generic HID driver
  ];

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
  # 4a. SSH AGENT
  # ==========================================
  programs.ssh.startAgent = true;

  # ==========================================
  # 4a. AUTO-MOUNT USB DRIVES & DISKS
  # ==========================================
  services.udisks2.enable = true;   # Auto-mount daemon
  services.gvfs.enable = true;      # Virtual filesystem (Nautilus integration)
  boot.supportedFilesystems = [ "ntfs" "exfat" "vfat" "ext4" "btrfs" "xfs" "f2fs" "hfsplus" "udf" "cifs" "nfs" ];
  # ntfs    — Windows NTFS
  # exfat   — USB drives, SD cards (cross-platform)
  # vfat    — FAT32 (legacy USB drives)
  # ext4    — Linux standard
  # btrfs   — Linux (snapshots, compression)
  # xfs     — Linux (large storage)
  # f2fs    — Flash-optimized (SSD, eMMC)
  # hfsplus — macOS HFS+
  # udf     — optical discs (DVD, Blu-ray)
  # cifs    — Windows network shares (SMB)
  # nfs     — Linux network shares
  # NOTE: ZFS removed — kernel module broken on linux 6.18.2

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
  # 5. AUDIO (PipeWire — full support for speakers, mic, Bluetooth)
  # ==========================================
  hardware.enableAllFirmware = true;

  security.rtkit.enable = true;  # Real-time scheduling for PipeWire (no audio cracks/stutter)

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;     # PulseAudio compatibility (legacy apps)
    jack.enable = true;      # JACK compatibility (pro audio apps)
    wireplumber.enable = true;  # Session manager — auto-detects & configures mic/headphones
  };

  # PulseAudio daemon — disabled, PipeWire handles everything
  services.pulseaudio.enable = false;

  # ==========================================
  # 5a. WEBCAM / VIDEO CAPTURE
  # ==========================================
  # Most UVC webcams (and built-in laptop cameras) work out of the box via the
  # uvcvideo kernel module (auto-loaded). xhci_pci is already in initrd
  # (hardware-configuration.nix), so USB 3.0 webcams are covered.
  #
  # User is added to 'video', 'input', 'plugdev' groups (see section 8)
  # for webcam and microphone device access.

  # ==========================================
  # 6. FONTS (Nerd Fonts required for agnoster theme)
  # ==========================================
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # ==========================================
  # 7. TOUCHPAD (macOS-like experience)
  # ==========================================
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;       # macOS-style scroll direction
      tapping = true;                # Tap to click (like macOS)
      tappingDragLock = false;       # Don't lock drag (macOS doesn't)
      clickMethod = "clickfinger";   # 2-finger=right, 3-finger=middle (macOS-style, no bottom zones)
      disableWhileTyping = true;     # Prevent accidental touches while typing
      middleEmulation = false;       # No middle-click emulation (use 3-finger tap)
      scrollMethod = "twofinger";    # Two-finger scroll (macOS default)
    };
  };

  # ==========================================
  # 7a. HYPRLAND (from nixpkgs, pre-built binary)
  # ==========================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Expose hyprexpo plugin .so for Hyprland to load at runtime
  # environment.etc."hyprland-plugins/hyprexpo.so".source = "${pkgs.hyprlandPlugins.hyprexpo}/lib/libhyprexpo.so";

  # Cursor theme for all sessions
  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    GTK_THEME = "Adwaita:dark";       # Dark GTK theme
    QT_STYLE_OVERRIDE = "Adwaita-Dark"; # Dark Qt theme
  };

  # GNOME Sushi — quick file preview in Nautilus (press Space, like macOS Quick Look)
  services.gnome.sushi.enable = true;

  # Tumbler — thumbnailing service for Nautilus (video, image, PDF previews)
  services.tumbler.enable = true;

  # Deploy Hyprland config from flake repo to /etc/hyprland.conf
  environment.etc."hyprland.conf".source = ./hyprland.conf;

  # Deploy theme configs (Catppuccin Mocha)
  environment.etc."waybar/config".source = ./themes/waybar/config;
  environment.etc."waybar/style.css".source = ./themes/waybar/style.css;
  environment.etc."dunst/dunstrc".source = ./themes/dunst/dunstrc;
  environment.etc."kitty/kitty.conf".source = ./themes/kitty/kitty.conf;
  environment.etc."gtk-3.0/settings.ini".source = ./themes/gtk-3.0/settings.ini;
  environment.etc."gtk-4.0/settings.ini".source = ./themes/gtk-4.0/settings.ini;

  # Deploy editor configs
  environment.etc."vimrc".source = ./configs/vimrc;

  # Deploy swappy config (screenshot annotation editor)
  environment.etc."swappy/config".source = ./configs/swappy/config;

  # Deploy kanshi config (automatic monitor profiles)
  environment.etc."kanshi/config".source = ./configs/kanshi/config;

  # Auto-link all configs to user's ~/.config/ on each rebuild
  system.activationScripts.dotfiles-config = ''
    # Hyprland
    mkdir -p /home/mbhuman/.config/hypr
    ln -sf /etc/hyprland.conf /home/mbhuman/.config/hypr/hyprland.conf

    # Waybar
    mkdir -p /home/mbhuman/.config/waybar
    ln -sf /etc/waybar/config /home/mbhuman/.config/waybar/config
    ln -sf /etc/waybar/style.css /home/mbhuman/.config/waybar/style.css

    # Dunst
    mkdir -p /home/mbhuman/.config/dunst
    ln -sf /etc/dunst/dunstrc /home/mbhuman/.config/dunst/dunstrc

    # Kitty
    mkdir -p /home/mbhuman/.config/kitty
    ln -sf /etc/kitty/kitty.conf /home/mbhuman/.config/kitty/kitty.conf

    # GTK dark theme
    mkdir -p /home/mbhuman/.config/gtk-3.0
    ln -sf /etc/gtk-3.0/settings.ini /home/mbhuman/.config/gtk-3.0/settings.ini
    mkdir -p /home/mbhuman/.config/gtk-4.0
    ln -sf /etc/gtk-4.0/settings.ini /home/mbhuman/.config/gtk-4.0/settings.ini

    # Vim — link to home dir (vim looks for ~/.vimrc)
    ln -sf /etc/vimrc /home/mbhuman/.vimrc
    # Neovim — also use the same config
    mkdir -p /home/mbhuman/.config/nvim
    ln -sf /etc/vimrc /home/mbhuman/.config/nvim/init.vim

    # Swappy (screenshot annotation)
    mkdir -p /home/mbhuman/.config/swappy
    ln -sf /etc/swappy/config /home/mbhuman/.config/swappy/config

    # Kanshi (monitor auto-config)
    mkdir -p /home/mbhuman/.config/kanshi
    ln -sf /etc/kanshi/config /home/mbhuman/.config/kanshi/config

    # Screenshots & Recordings dirs
    mkdir -p /home/mbhuman/Screenshots
    mkdir -p /home/mbhuman/Recordings

    # Fix ownership
    chown -R mbhuman:users /home/mbhuman/.config /home/mbhuman/.vimrc /home/mbhuman/Screenshots /home/mbhuman/Recordings
  '';

  # Required for Hyprland to function properly (login, audio auth, etc.)
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # A simple terminal login manager so you can access Hyprland
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # ==========================================
  # 8. USER & PASSWORD
  # ==========================================
  users.users.mbhuman = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "plugdev" "docker" ];
    # video   — webcam / GPU acceleration
    # audio   — PipeWire / ALSA audio access
    # input   — microphone input devices
    # plugdev — hot-plug devices (USB webcams, etc.)
    # docker  — run Docker without sudo
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
    shellAliases = {
      "dev" = "nix develop ~/Documents/github/nixos-laptop";
      "dev-picodata" = "nix develop ~/Documents/github/nixos-laptop#picodata";
      "dev-python" = "nix develop ~/Documents/github/nixos-laptop#python";
      "dev-rust" = "nix develop ~/Documents/github/nixos-laptop#rust";
      "dev-g1" = "nix develop ~/Documents/github/nixos-laptop#g1";
      "g1" = "nix develop ~/Documents/github/nixos-laptop#g1";
    };
  };

  # ==========================================
  # 10. PACKAGES
  # ==========================================
  environment.systemPackages = with pkgs; [
    # Custom scripts
    (writeShellScriptBin "gswp" (builtins.readFile ./scripts/gswp.sh))
    (writeShellScriptBin "gcnf" (builtins.readFile ./scripts/gcnf.sh))

    vim
    neovim
    git
    curl
    wget
    killall
    htop

    # Hyprland essentials
    waybar          # Status bar
    dunst           # Notifications
    libnotify       # notify-send CLI (used by dunst)
    kitty           # Terminal emulator
    rofi    # App launcher
    nautilus        # File manager
    jq              # JSON parser (for window screenshots)

    # Cursor & GTK themes
    bibata-cursors
    gnome-themes-extra  # Adwaita-dark GTK theme
    dconf               # GTK settings backend

    # Wayland utilities
    grim            # Screenshot tool
    slurp           # Region selection
    swappy          # Screenshot annotation editor
    wl-clipboard    # Clipboard manager
    cliphist        # Clipboard history
    wf-recorder     # Screen recording (Wayland)
    brightnessctl   # Screen brightness keys
    pamixer         # Volume control (CLI)
    pavucontrol     # Audio GUI (PulseAudio/PipeWire — control mic & speakers)
    pwvucontrol     # PipeWire native volume control (more detailed)
    networkmanagerapplet # Wi-Fi GUI
    blueman         # Bluetooth GUI

    # Monitor management
    nwg-displays    # GUI monitor settings (resolution, Hz, scale, position, mirror)
    wlr-randr       # CLI monitor configuration (xrandr for Wayland)
    kanshi          # Auto-detect & apply monitor profiles on hotplug

    # === Editors ===
    vscode

    # === Browsers ===
    google-chrome

    # === Messaging ===
    telegram-desktop        # Telegram Desktop

    # === Webcam & Audio Utilities ===
    v4l-utils              # Video4Linux2 CLI tools (v4l2-ctl — webcam settings/config)

    # === Docker ===
    docker-compose         # Docker Compose v2 (plugin)

    # === VPN ===
    wireguard-tools # wg-quick, wg CLI tools
    openvpn         # Corporate VPN

    # === File Preview & Viewers ===
    loupe               # Image viewer (GNOME, Wayland native)
    mpv                 # Video & audio player (minimal, Wayland native)
    evince              # PDF/document viewer (GNOME, like macOS Preview)
    file-roller         # Archive manager (GNOME, for tar/zip etc.)
    ffmpegthumbnailer   # Video thumbnails in Nautilus

    # === CLI Tools ===
    fzf             # Fuzzy finder (used by gswp)
    just            # Task runner (make alternative)

    # === Python (base) ===
    python312       # Python interpreter
    uv              # Fast Python package manager
    ruff            # Python linter & formatter

    # === Rust (base) ===
    rustup          # Rust toolchain manager
    rust-analyzer   # Rust LSP

    # === Other =========
    # Environment management
    direnv
    nix-direnv
  ];

  # ==========================================
  # 10a. DEFAULT APPLICATIONS (MIME types)
  # ==========================================
  # Set default apps so Nautilus and other apps open files correctly
  xdg.mime.defaultApplications = {
    # Images → Loupe
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/avif" = "org.gnome.Loupe.desktop";
    "image/heif" = "org.gnome.Loupe.desktop";

    # Video → mpv
    "video/mp4" = "mpv.desktop";
    "video/mpeg" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";      # mkv
    "video/x-msvideo" = "mpv.desktop";       # avi
    "video/x-flv" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";       # mov

    # Audio → mpv
    "audio/mpeg" = "mpv.desktop";
    "audio/ogg" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";
    "audio/wav" = "mpv.desktop";
    "audio/aac" = "mpv.desktop";

    # PDF & Documents → Evince
    "application/pdf" = "org.gnome.Evince.desktop";
    "application/epub+zip" = "org.gnome.Evince.desktop";
    "image/x-eps" = "org.gnome.Evince.desktop";
    "image/x-xcf" = "org.gnome.Loupe.desktop";
    "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
  };

  # ==========================================
  # XDG DESKTOP PORTAL (screen sharing, file picker)
  # ==========================================
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Allow unfree packages (required for Google Chrome, VS Code)
  nixpkgs.config.allowUnfree = true;

  # ==========================================
  # 10b. EXTRA PATH (custom binaries)
  # ==========================================
  environment.extraInit = ''
    export PATH="/home/mbhuman/Documents/builds:$PATH"
  '';

  # ==========================================
  # 11. LOCALE & TIMEZONE
  # ==========================================
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  # ==========================================
  # 12. DOCKER
  # ==========================================
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;   # Start dockerd at boot
  };

  # ==========================================
  # 13. FIRMWARE UPDATES
  # ==========================================
  services.fwupd.enable = true;

  # ==========================================
  # 14. MODULE BLACKLIST
  # ==========================================
  # huawei-wmi: Honor firmware's WMI methods (SMLS, micmute LED) are broken on Linux.
  # The module repeatedly fails and spams logs. Blacklist to silence errors.
  boot.blacklistedKernelModules = [ "huawei_wmi" ];

  system.stateVersion = "24.05"; # Don't touch this
}
