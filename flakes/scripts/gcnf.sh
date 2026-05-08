#!/usr/bin/env bash
set -euo pipefail

PROFILES_FILE="$HOME/.config/git-profiles/profiles.conf"

name=$(git config --global user.name 2>/dev/null || echo "<not set>")
email=$(git config --global user.email 2>/dev/null || echo "<not set>")

# Try to find matching profile name
profile=""
if [ -f "$PROFILES_FILE" ] && [ -n "$email" ]; then
  if grep -q "|${email}$" "$PROFILES_FILE" 2>/dev/null; then
    profile=" ($(grep "|${email}$" "$PROFILES_FILE" | head -1 | cut -d'|' -f1))"
  fi
fi

echo "📋 Current Git config${profile}:"
echo "   user.name:  $name"
echo "   user.email: $email"