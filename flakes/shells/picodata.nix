{ pkgs, ... }:

let
  python = pkgs.python311;
  pythonEnv = python.withPackages (ps: with ps; [
    pip
    setuptools
    wheel
    virtualenv
    pytest
    pytest-xdist
    ipdb
  ]);
in
pkgs.mkShell {
  name = "picodata-dev-shell";

  buildInputs = with pkgs; [
    # Core build tools
    rustup
    cmake
    gcc
    gnumake
    git
    patch
    curl
    pkg-config
    libxcrypt
    autoconf
    automake
    libtool
    c-ares

    # Static linking support
    stdenv.cc.cc.lib

    # Web UI build
    nodejs_20
    yarn

    # Python for integration tests
    pythonEnv

    # Dependencies for dynamic_build
    openssl
    readline
    zlib
    zstd
    libyaml
    icu
    icu.dev
    openldap

    # Performance profiling
    perf
    flamegraph
  ];

  shellHook = ''
    export RUSTUP_HOME=$HOME/.rustup
    export CARGO_HOME=$HOME/.cargo
    export PATH=$CARGO_HOME/bin:$PATH
    export LDFLAGS="-L${pkgs.libxcrypt}/lib -L${pkgs.icu}/lib $LDFLAGS"
    export CFLAGS="-I${pkgs.libxcrypt}/include -I${pkgs.icu.dev}/include $CFLAGS"
    export NIX_LDFLAGS="-L${pkgs.libxcrypt}/lib -lcrypt -L${pkgs.icu}/lib -licuuc -licudata $NIX_LDFLAGS"
    export RUSTFLAGS="-L ${pkgs.libxcrypt}/lib -L ${pkgs.icu}/lib $RUSTFLAGS"
    export PKG_CONFIG_PATH="${pkgs.icu.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"

    echo "▶ Picodata dev environment loaded"
    echo "   Rust via rustup is available. Run:"
    echo "       rustup toolchain install stable"
  '';
}