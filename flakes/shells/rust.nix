{ pkgs, ... }:

pkgs.mkShell {
  name = "rust-dev-shell";

  buildInputs = with pkgs; [
    # Rust toolchain
    rustup
    cargo
    rustc
    rust-analyzer
    clippy
    rustfmt

    # Build essentials
    gcc
    gnumake
    cmake
    pkg-config
    autoconf
    automake
    libtool

    # Common native dependencies
    openssl
    libffi
    zlib
    curl
    git

    # Cargo tools (installed via shellHook for flexibility)
    cargo-watch
    cargo-edit
    cargo-outdated
    cargo-audit
    cargo-expand

    # Extra tools
    gdb
    valgrind
  ];

  shellHook = ''
    export RUSTUP_HOME=$HOME/.rustup
    export CARGO_HOME=$HOME/.cargo
    export PATH=$CARGO_HOME/bin:$PATH

    # Source cargo environment
    if [ -f "$CARGO_HOME/env" ]; then
      . "$CARGO_HOME/env"
    fi

    # Install and set default Rust toolchain if not configured
    if ! rustup default 2>/dev/null | grep -q .; then
      echo "⚙ Installing stable Rust toolchain..."
      rustup default stable
    fi

    echo "▶ Rust dev environment loaded"
    echo "  rustc:   $(rustc --version 2>/dev/null || echo 'N/A')"
    echo "  cargo:   $(cargo --version 2>/dev/null || echo 'N/A')"
    echo "  rustup:  $(rustup --version 2>/dev/null || echo 'N/A')"
    echo ""
    echo "  Installed cargo tools:"
    echo "    cargo-watch    — auto-recompile on changes"
    echo "    cargo-edit     — add/rm deps from CLI"
    echo "    cargo-outdated — find outdated deps"
    echo "    cargo-audit    — security vulnerability check"
    echo "    cargo-expand   — macro expansion"

    exec ${pkgs.zsh}/bin/zsh
  '';
}