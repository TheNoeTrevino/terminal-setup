# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--bind ctrl-k:down,ctrl-l:up'

eval "$(fzf --zsh)"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"

export ITEM_DIR="/Users/noetrevino/.config/sketchybar/items"

# ---- Eza (better ls) -----

alias ls="eza --icons=always --color=always --long  --no-filesize --no-time --no-user --no-permissions"

alias v="
fd --type f --hidden --exclude .git | fzf-tmux -p --height 40% --border --preview 'bat --style=numbers --color=always --line-range :500 {}' | xargs nvim
"

update() {
  echo "=== Updating system with pacman ==="
  sudo pacman -Syu --noconfirm

  echo "=== Updating AUR packages with yay ==="
  yay -Syu --noconfirm

  echo "=== System fully updated! ==="
}

# ---- TMUX -----
tmux-list() {
  session="$(tmux ls -F "#{session_name}" | fzf-tmux -p --preview "sesh preview {}")" || exit
  if [ -n "$session" ]; then
    if [ -n "$TMUX" ]; then
      tmux switch-client -t "$session"
    else
      tmux attach -t "$session"
    fi
  fi
}

tmux-kill() {
  tmux kill-session -t "$(tmux ls -F '#{session_name}' | fzf-tmux -p --preview 'sesh preview {}')"
}

alias t='tmux-list'

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

export PATH="$HOME/.cargo/bin:$PATH"
# Git log oneline
alias l="git log --oneline"
alias lg="lazygit"
# Git rebase alias
alias gr='function _gr() { if [[ "$1" =~ ^[0-9]+$ ]]; then git rebase -i HEAD~$1; else git rebase -i $1; fi; }; _gr'
alias g='git'
alias n='clear && neofetch'

sps() {
  ps -ef | fzf --bind 'ctrl-r:reload(ps -ef)' \
    --header 'Press CTRL-R to reload' \
    --header-lines=1 \
    --height=50% \
    --layout=reverse
}

fzf_sps_widget() {
  sps
}
zle -N fzf_sps_widget

bindkey '^P' fzf_sps_widget

source ~/terminal-setup/fzf-git.sh/fzf-git.sh
