#!/usr/bin/env bash
set -euo pipefail

PROFILES_DIR="$HOME/.config/git-profiles"
PROFILES_FILE="$PROFILES_DIR/profiles.conf"

ensure_profiles_file() {
  mkdir -p "$PROFILES_DIR"
  [ -f "$PROFILES_FILE" ] || touch "$PROFILES_FILE"
}

current_email() {
  git config --global user.email 2>/dev/null || echo ""
}

current_name() {
  git config --global user.name 2>/dev/null || echo ""
}

current_profile() {
  local email
  email=$(current_email)
  if [ -n "$email" ] && [ -f "$PROFILES_FILE" ] && grep -q "|${email}$" "$PROFILES_FILE"; then
    grep "|${email}$" "$PROFILES_FILE" | head -1 | cut -d'|' -f1
  else
    echo ""
  fi
}

list_profiles() {
  ensure_profiles_file
  local cur_email cur_name
  cur_email=$(current_email)
  cur_name=$(current_name)

  if [ ! -s "$PROFILES_FILE" ]; then
    echo "No profiles configured. Run: gswp add"
    return
  fi

  echo "Git profiles:"
  echo "─────────────────────────────────────────────"
  while IFS='|' read -r pname pemail puname; do
    [ -z "$pname" ] && continue
    if [ "$pemail" = "$cur_email" ]; then
      echo "  ★ $pname  ($puname <$pemail>)  [active]"
    else
      echo "    $pname  ($puname <$pemail>)"
    fi
  done < "$PROFILES_FILE"
  echo "─────────────────────────────────────────────"
  echo "Current: ${cur_name:-<not set>} <${cur_email:-not set}>"
}

switch_profile() {
  local target="$1"
  ensure_profiles_file

  if ! grep -q "^${target}|" "$PROFILES_FILE"; then
    echo "Profile '$target' not found."
    list_profiles
    return 1
  fi

  local pname pemail puname
  IFS='|' read -r pname pemail puname < <(grep "^${target}|" "$PROFILES_FILE")
  git config --global user.name "$puname"
  git config --global user.email "$pemail"
  echo "Switched to: $pname ($puname <$pemail>)"
}

interactive_switch() {
  ensure_profiles_file

  if [ ! -s "$PROFILES_FILE" ]; then
    echo "No profiles configured. Run: gswp add"
    return 1
  fi

  if ! command -v fzf &>/dev/null; then
    echo "fzf not found. Install it or use: gswp <profile_name>"
    return 1
  fi

  local cur_email selection target
  cur_email=$(current_email)

  selection=$(while IFS='|' read -r pname pemail puname; do
    [ -z "$pname" ] && continue
    if [ "$pemail" = "$cur_email" ]; then
      echo "* $pname"
    else
      echo "  $pname"
    fi
  done < "$PROFILES_FILE" | fzf --height=10 --prompt="Switch to> " --no-multi 2>/dev/null)

  [ -z "$selection" ] && echo "Cancelled." && return
  target=$(echo "$selection" | sed 's/^[* ]*//')
  switch_profile "$target"
}

add_profile() {
  ensure_profiles_file

  local pname puname pemail
  read -rp "Profile name (e.g. work, personal): " pname
  [ -z "$pname" ] && echo "Cancelled." && return

  if grep -q "^${pname}|" "$PROFILES_FILE"; then
    echo "Profile '$pname' already exists. Use: gswp edit $pname"
    return 1
  fi

  read -rp "Git user.name: " puname
  [ -z "$puname" ] && echo "Cancelled." && return

  read -rp "Git user.email: " pemail
  [ -z "$pemail" ] && echo "Cancelled." && return

  echo "${pname}|${pemail}|${puname}" >> "$PROFILES_FILE"
  echo "Profile '$pname' added: $puname <$pemail>"

  read -rp "Switch to this profile now? [Y/n] " ans
  [[ "$ans" =~ ^[Yy]*$ ]] && switch_profile "$pname"
}

edit_profile() {
  ensure_profiles_file
  local target="$1"

  if [ -z "$target" ]; then
    if ! command -v fzf &>/dev/null; then
      echo "fzf not found. Use: gswp edit <profile_name>"
      return 1
    fi
    target=$(while IFS='|' read -r pname _pe _pu; do
      [ -z "$pname" ] && continue
      echo "$pname"
    done < "$PROFILES_FILE" | fzf --height=10 --prompt="Edit> " --no-multi 2>/dev/null)
    [ -z "$target" ] && echo "Cancelled." && return
  fi

  if ! grep -q "^${target}|" "$PROFILES_FILE"; then
    echo "Profile '$target' not found."
    return 1
  fi

  local old_email old_user
  old_email=$(grep "^${target}|" "$PROFILES_FILE" | cut -d'|' -f2)
  old_user=$(grep "^${target}|" "$PROFILES_FILE" | cut -d'|' -f3)

  echo "Editing '$target' (leave empty to keep current)"
  read -rp "  user.name [$old_user]: " new_user
  new_user="${new_user:-$old_user}"
  read -rp "  user.email [$old_email]: " new_email
  new_email="${new_email:-$old_email}"

  local tmp
  tmp=$(mktemp)
  while IFS= read -r line; do
    if [[ "$line" == "${target}|"* ]]; then
      echo "${target}|${new_email}|${new_user}"
    else
      echo "$line"
    fi
  done < "$PROFILES_FILE" > "$tmp"
  mv "$tmp" "$PROFILES_FILE"
  echo "Profile '$target' updated: $new_user <$new_email>"

  # Reapply if active
  local cur_email
  cur_email=$(current_email)
  if [ "$cur_email" = "$old_email" ] || [ "$cur_email" = "$new_email" ]; then
    switch_profile "$target"
  fi
}

remove_profile() {
  ensure_profiles_file
  local target="$1"

  if [ -z "$target" ]; then
    if ! command -v fzf &>/dev/null; then
      echo "fzf not found. Use: gswp remove <profile_name>"
      return 1
    fi
    target=$(while IFS='|' read -r pname _pe _pu; do
      [ -z "$pname" ] && continue
      echo "$pname"
    done < "$PROFILES_FILE" | fzf --height=10 --prompt="Remove> " --no-multi 2>/dev/null)
    [ -z "$target" ] && echo "Cancelled." && return
  fi

  if ! grep -q "^${target}|" "$PROFILES_FILE"; then
    echo "Profile '$target' not found."
    return 1
  fi

  local pemail puname
  IFS='|' read -r _pname pemail puname < <(grep "^${target}|" "$PROFILES_FILE")

  read -rp "Remove '$target' ($puname <$pemail>)? [y/N] " ans
  [[ ! "$ans" =~ ^[Yy]$ ]] && echo "Cancelled." && return

  grep -v "^${target}|" "$PROFILES_FILE" > "$(mktemp)" && mv "$(mktemp)" "$PROFILES_FILE"
  echo "Profile '$target' removed."
}

interactive_menu() {
  if ! command -v fzf &>/dev/null; then
    echo "fzf not installed. Use subcommands: gswp <list|add|edit|remove|switch>"
    echo ""
    list_profiles
    return
  fi

  local has_profiles=false
  [ -s "$PROFILES_FILE" ] && has_profiles=true

  local actions="add\nhelp"
  if $has_profiles; then
    actions="list\nswitch\nadd\nedit\nremove\nhelp"
  fi

  local action
  action=$(echo -e "$actions" | fzf --height=10 --prompt="gswp> " --no-multi 2>/dev/null)

  case "$action" in
    list)   list_profiles ;;
    switch) interactive_switch ;;
    add)    add_profile ;;
    edit)   edit_profile "" ;;
    remove) remove_profile "" ;;
    help|--help|-h)
      echo "Usage: gswp [command] [args]"
      echo ""
      echo "Commands:"
      echo "  (no args)      Interactive menu"
      echo "  <profile>      Quick switch"
      echo "  list           List profiles"
      echo "  add            Add new profile"
      echo "  edit [name]    Edit profile"
      echo "  remove [name]  Remove profile"
      echo "  help           Show help"
      ;;
    *) echo "Cancelled." ;;
  esac
}

# === Main ===
ensure_profiles_file

case "${1:-}" in
  list|ls|l)
    list_profiles
    ;;
  add|a|new)
    add_profile
    ;;
  edit|e)
    edit_profile "${2:-}"
    ;;
  remove|rm|del|d)
    remove_profile "${2:-}"
    ;;
  switch|s)
    if [ -n "${2:-}" ]; then
      switch_profile "$2"
    else
      interactive_switch
    fi
    ;;
  help|h|--help|-h)
    echo "Usage: gswp [command] [args]"
    echo ""
    echo "Commands:"
    echo "  (no args)      Interactive menu"
    echo "  <profile>      Quick switch"
    echo "  list           List profiles"
    echo "  add            Add new profile"
    echo "  edit [name]    Edit profile"
    echo "  remove [name]  Remove profile"
    echo "  help           Show help"
    ;;
  "")
    interactive_menu
    ;;
  *)
    switch_profile "$1"
    ;;
esac