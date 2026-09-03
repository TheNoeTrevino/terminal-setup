#!/usr/bin/env zsh
# Fuzzy-find a file and open it in nvim. Tab multi-selects, and every selected
# file opens in the same nvim.
#
# Two ways in, and one copy of the picker:
#   - the v() function runs this directly, and nvim takes over this process
#   - a herdr popup runs it, and HERDR_POPUP_CALLER names the pane that asked
#
# A popup cannot host nvim. It is modal, and herdr closes it the moment the
# command exits. So the popup sends the command back to the calling pane and
# lets nvim open there, which is where v has always put it.

emulate -L zsh
setopt no_unset

caller=${HERDR_POPUP_CALLER:-}

if [[ -n $caller ]]; then
  # The popup pane is already sized, so the picker takes all of it.
  geometry=(--height=100%)
else
  # --tmux draws a tmux popup when inside tmux. fzf ignores the flag outside
  # tmux, and --height takes over instead.
  geometry=(--tmux center,80%,60% --height 60%)
fi

files=$(
  fd --type f --hidden --exclude .git |
    fzf --multi $geometry --border --layout=reverse \
      --preview-window 'right,66%,border-left' \
      --preview 'bat --style=numbers --color=always --line-range :500 {}'
) || exit 0

[[ -n $files ]] || exit 0

if [[ -z $caller ]]; then
  # -o reopens stdin on the terminal, which nvim needs to draw.
  print -rl -- "$files" | xargs -ro nvim
  exit
fi

# ${(q)f} quotes each path, so a name with a space stays one argument.
cmd=nvim
while IFS= read -r f; do
  [[ -n $f ]] && cmd+=" ${(q)f}"
done <<< "$files"

herdr pane run "$caller" "$cmd" > /dev/null 2>&1
