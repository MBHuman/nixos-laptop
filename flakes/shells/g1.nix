{ pkgs, ... }:

let
  pythonShell = import ./python.nix { inherit pkgs; };
  rustShell   = import ./rust.nix     { inherit pkgs; };
in
pkgs.mkShell {
  name = "python-rust-dev-shell";

  # Merge buildInputs from both shells
  inputsFrom = [
    pythonShell
    rustShell
  ];

  # Extra packages on top of reused Python + Rust envs
  buildInputs = with pkgs; [
    # Python↔Rust interop
    maturin         # Build & publish Python packages from Rust (PyO3)

    # CLI / productivity tools
    just            # Task runner (make alternative)
    fd              # Fast find (find alternative)
    ripgrep         # Fast grep (grep alternative)
    bat             # cat with syntax highlighting
    eza             # ls replacement (icons, git status)
    delta           # Better diff for git
    tokei           # Code lines counter
    hyperfine       # Benchmarking tool

    # Database tools
    cassandra       # Apache Cassandra (includes cqlsh)
  ];

  shellHook = ''
    # === Python env ===
    export PYTHONPATH=""
    export VIRTUAL_ENV=""
    export UV_CACHE_DIR=$HOME/.cache/uv
    mkdir -p "$HOME/.virtualenvs"

    # === Rust env ===
    export RUSTUP_HOME=$HOME/.rustup
    export CARGO_HOME=$HOME/.cargo
    export PATH=$CARGO_HOME/bin:$PATH

    if [ -f "$CARGO_HOME/env" ]; then
      . "$CARGO_HOME/env"
    fi

    if ! rustup default 2>/dev/null | grep -q .; then
      echo "⚙ Installing stable Rust toolchain..."
      rustup default stable
    fi

    echo "▶ Python + Rust dev environment loaded"
    echo "  Python:  $(python --version 2>/dev/null || echo 'N/A')"
    echo "  Rust:    $(rustc --version 2>/dev/null || echo 'N/A')"
    echo "  Cargo:   $(cargo --version 2>/dev/null || echo 'N/A')"
    echo "  uv:      $(uv --version 2>/dev/null || echo 'N/A')"
    echo "  maturin: $(maturin --version 2>/dev/null || echo 'N/A')"

    exec ${pkgs.zsh}/bin/zsh
  '';
}