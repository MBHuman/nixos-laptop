{ pkgs, ... }:

let
  python = pkgs.python312;
  pythonEnv = python.withPackages (ps: with ps; [
    pip
    setuptools
    wheel
    virtualenv
    pytest
    pytest-xdist
    pytest-cov
    black
    mypy
    pylint
    flake8
    ipython
    ipdb
    rich
    requests
    httpx
    pyyaml
    toml
    jinja2
    click
    poetry-core
  ]);
in
pkgs.mkShell {
  name = "python-dev-shell";

  buildInputs = with pkgs; [
    pythonEnv

    # Python package managers
    uv
    poetry

    # Build essentials (for native extensions)
    gcc
    pkg-config
    openssl
    libffi
    zlib

    # LSP & tools
    pyright
    ruff

    # Extra tools
    jq
    curl
    git
  ];

  shellHook = ''
    export PYTHONPATH=""
    export VIRTUAL_ENV=""
    export UV_CACHE_DIR=$HOME/.cache/uv

    # Create default venv directory if it doesn't exist
    mkdir -p "$HOME/.virtualenvs"

    echo "▶ Python dev environment loaded"
    echo "  Python:  $(python --version)"
    echo "  uv:      $(uv --version 2>/dev/null || echo 'N/A')"
    echo "  poetry:  $(poetry --version 2>/dev/null || echo 'N/A')"
    echo ""
    echo "  Quick start:"
    echo "    uv venv .venv && source .venv/bin/activate"
    echo "    uv pip install <package>"

    exec ${pkgs.zsh}/bin/zsh
  '';
}