#!/usr/bin/env bash

# Define it to empty
GROUPED_SESSIONS=""
d=$'\t'

pane_format() {
  local format
  format+="#{session_name}"
  format+="${d}"
  format+="#{window_index}"
  format+="${d}"
  format+="#{pane_index}"
  format+="${d}"
  format+="#{pane_id}"
  echo "$format"
}

pane_virtualenv() {
  local pane_id="$1"
  tmux show-window-option -v -t "$pane_id" "@virtualenv$pane_id" 2>/dev/null || true
}


dump_panes_virtualenv() {
  local session_name window_number pane_index pane_id
  tmux list-panes -a -F "$(pane_format)" |
  while IFS=$d read -r session_name window_number pane_index pane_id; do
    # not saving panes from grouped sessions
    if is_session_grouped "$session_name"; then
      continue
    fi
    local venv
    venv=$(pane_virtualenv "$pane_id")

    if [ -n "$venv" ]; then
      echo "virtualenv${d}${session_name}${d}${window_number}${d}${pane_index}${d}${venv}"
    fi
  done
}

restore_panes_virtualenv() {
  local session_name window_number pane_index pane_id
  awk 'BEGIN { FS="\t"; OFS="\t" } $1 == "virtualenv"' "$(last_resurrect_file)" |
  while read -r _ session_name window_number pane_index venv; do
    tmux send-keys -t "${session_name}:${window_number}.${pane_index}" -l "$(printf " %q" workon "$venv")"
    tmux send-keys -t "${session_name}:${window_number}.${pane_index}" "C-m"
  done
}

install() {
  [[ -n "${VIRTUALENVWRAPPER_HOOK_DIR}" ]] || {
    echo >&2 "virtualenvwrapper environment variables not found!"
    exit 1
  }

  CURRENT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  hook="${VIRTUALENVWRAPPER_HOOK_DIR}/predeactivate"
  cmd="tmux-virtualenv.sh deactivate-venv"
  _add_line_to_file "tmux-virtualenv.sh" "$CURRENT_DIR/$cmd" "$hook"

  hook="${VIRTUALENVWRAPPER_HOOK_DIR}/preactivate"
  cmd="tmux-virtualenv.sh activate-venv"
  _add_line_to_file "tmux-virtualenv.sh" "$CURRENT_DIR/$cmd \"\$1\"" "$hook"

  tmux set-option -gq "@resurrect-hook-post-save-layout" "$CURRENT_DIR/tmux-virtualenv.sh save"
  tmux set-option -gq "@resurrect-hook-pre-restore-history" "$CURRENT_DIR/tmux-virtualenv.sh restore"
}

_add_line_to_file() {
  local pattern="$1"
  local line="$2"
  local file="$3"

  sed -i.bak -e "s#.*/$pattern.*#$line#" "$file"
  if ! grep -q "$pattern" "$file"; then
    # Not there, add to end
    echo "$line" >> "$file"
  fi
}


main() {
  local path
  path=$(dirname "$(tmux show-option -gv "@resurrect-restore-script-path")")
  source "$path/variables.sh"
  source "$path/helpers.sh"

  # set after we have sourced the helpers from tmux-resurrect
  set -eu -o pipefail

  case "$1" in
    install)
      install
      ;;
    activate-venv)
      # Are we currently inside a tmux session
      if [ -n "${TMUX_PANE-}" ]; then
        tmux set-window-option "@virtualenv${TMUX_PANE}" "$2"
      fi
      ;;
    deactivate-venv)
      if [ -n "${TMUX_PANE-}" ]; then
        tmux set-window-option -u "@virtualenv${TMUX_PANE}"
      fi
      ;;
    save)
      dump_panes_virtualenv >> "$2"
      ;;
    restore)
      restore_panes_virtualenv
      ;;
  esac
}

main "$@"

