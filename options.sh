# ---------------------------------------------------------------------------
# Television (tv) is the fuzzy finder (migrated from fzf).
#   - Channels (source + preview + actions) live in ~/.config/television/cable/*.toml
#   - UI, keybindings and shell triggers live in ~/.config/television/config.toml
# fzf is still installed as a fallback but nothing here depends on it.
# ---------------------------------------------------------------------------

export CLAUDE_CODE_NO_FLICKER=1
export EDITOR='nvim'

# Initialize zsh's completion system. tv's init script registers a completion
# (`compdef _tv tv`), which requires compinit to have run first -- otherwise
# sourcing prints "command not found: compdef". (fzf's script guarded this; tv's
# does not.) compinit also backs the `completion` autosuggest strategy below.
autoload -Uz compinit && compinit

# Shell integration: binds ^T (smart path/argument autocomplete) and ^R
# (command history) -- the television equivalents of fzf's ^T / ^R. Which
# channel a given command opens (e.g. `git checkout` + ^T -> git-branch) is
# configured under [shell_integration] in config.toml.
_tv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/tv_init.zsh"
if [[ ! -f "$_tv_cache" || $(which tv) -nt "$_tv_cache" ]]; then
  tv init zsh >| "$_tv_cache"
fi
source "$_tv_cache"
unset _tv_cache

# tv's smart-autocomplete widget, on an EMPTY line, falls back to zsh's default
# completion -- the "do you wish to see all 4290 possibilities" dump. We want an
# empty line to open tv instead.
#
# This used to be done with `fzf_default_completion=_tv_open`, but that variable
# is GLOBAL: fzf's completion.zsh (which binds <Tab> to `fzf-completion`) reads
# the same variable as its fallback. On any machine where fzf's shell
# integration is loaded, that made <Tab> open tv. We now scope the behaviour to
# our own wrapper widget below and leave <Tab> as plain zsh completion.
_tv_open() {
  local result
  result=$(tv </dev/tty)
  [[ -n "$result" ]] && LBUFFER="${LBUFFER}${result}"
  typeset -f _enable_bracketed_paste >/dev/null && _enable_bracketed_paste
  zle reset-prompt
}
zle -N _tv_open

# Empty line -> open tv outright; otherwise run tv's context-aware smart
# autocomplete (e.g. `git checkout ` -> branches).
_tv_smart_or_open() {
  if [[ -z "${LBUFFER//[[:space:]]/}" ]]; then
    _tv_open
  else
    zle tv-smart-autocomplete
  fi
}
zle -N _tv_smart_or_open

# Ctrl-F / Ctrl-T trigger smart autocomplete. Bound in viins/vicmd since
# EDITOR=nvim puts zsh in vi mode. <Tab> is intentionally left untouched so it
# keeps doing normal zsh completion.
bindkey -M viins '^F' _tv_smart_or_open
bindkey -M vicmd '^F' _tv_smart_or_open
bindkey -M viins '^T' _tv_smart_or_open
bindkey -M vicmd '^T' _tv_smart_or_open

_starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship_init.zsh"
if [[ ! -f "$_starship_cache" || $(which starship) -nt "$_starship_cache" ]]; then
  starship init zsh >| "$_starship_cache"
fi
source "$_starship_cache"
unset _starship_cache

export ITEM_DIR="/Users/noetrevino/.config/sketchybar/items"

# ---- Eza (better ls) -----
alias ls="eza --icons=always --color=always --long  --no-filesize --no-time --no-user --no-permissions"

# ---- Fuzzy-find a file and open it in nvim ----
# Was: fd | fzf-tmux --preview 'bat ...' | xargs nvim
# The `files` channel already previews with bat and uses the fd source defined
# in files.toml (hidden, excludes .git). Tab multi-selects; each opens in nvim.
v() {
  local files
  files=$(tv files) || return
  [[ -n "$files" ]] && print -rl -- "$files" | xargs -ro nvim
}

update() {
  echo "=== Updating system with pacman ==="
  sudo pacman -Syu --noconfirm

  echo "=== Updating AUR packages with yay ==="
  yay -Syu --noconfirm

  echo "=== System fully updated! ==="
}

# ---- TMUX ----
# Was: fzf-tmux with `sesh preview` (sesh isn't installed -> preview was broken).
# The tmux-sessions channel previews with `tmux capture-pane`, no sesh needed.
tmux-list() {
  local session
  session=$(tv tmux-sessions) || return
  [[ -n "$session" ]] || return
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach -t "$session"
  fi
}

tmux-kill() {
  local session
  session=$(tv tmux-sessions) || return
  [[ -n "$session" ]] && tmux kill-session -t "$session"
}

alias t='tmux-list'

# ---- Zoxide (better cd) ----
_zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.zsh"
if [[ ! -f "$_zoxide_cache" || $(which zoxide) -nt "$_zoxide_cache" ]]; then
  zoxide init zsh >| "$_zoxide_cache"
fi
source "$_zoxide_cache"
unset _zoxide_cache

export PATH="$HOME/.cargo/bin:$PATH"

# ---- Git aliases ----
alias l="git log --oneline"
alias lg="lazygit"
alias gr='function _gr() { if [[ "$1" =~ ^[0-9]+$ ]]; then git rebase -i HEAD~$1; else git rebase -i $1; fi; }; _gr'
alias g='git'
alias n='clear && neofetch'

# ---- Television git pickers (replaces fzf-git.sh) ----
# Each channel ships its own actions; run them inside a git repo:
#   gb   git-branch  enter=checkout  ctrl-d=delete  ctrl-m=merge  ctrl-r=rebase
#   gf   git-files   f12=edit in $EDITOR
#   glo  git-log     ctrl-y=cherry-pick  ctrl-r=revert  ctrl-o=checkout
#   gst  git-stash   enter=apply  ctrl-p=pop  ctrl-d=drop
#   gtag git-tags    enter=checkout  ctrl-d=delete
# Press ctrl-x inside any channel to see/run all available actions.
alias gb='tv git-branch'
alias gf='tv git-files'
alias glo='tv git-log'
alias gst='tv git-stash'
alias gtag='tv git-tags'

# ---- Process picker ----
# Was: sps() { ps -ef | fzf ... } bound to ^P.
# The procs channel can act on the selection: F3=kill, F2=term, ctrl-s=stop,
# ctrl-c=cont. `sps` kept as an alias for muscle memory.
alias sps='tv procs'
_tv_procs_widget() {
  tv procs >/dev/null
  zle reset-prompt
}
zle -N _tv_procs_widget

_tv_fg_widget() { fg; }
zle -N _tv_fg_widget

# ---- Jobs picker ----
# Was: jobs | fzf. `jobs | tv` builds an ad-hoc channel straight from stdin.
fjob() {
  local job
  job=$(jobs | tv | awk '{print $1}' | tr -d '[]')
  [[ -n "$job" ]] && fg "%$job"
}

bindkey '^P' _tv_procs_widget
bindkey '^Z' _tv_fg_widget

# ---- vi-mode navigation remap (j=left, k=down, l=up, ;=right) ----
bindkey -M vicmd 'j' vi-backward-char     # was h (left)
bindkey -M vicmd 'k' down-line-or-history # was j (down)
bindkey -M vicmd 'l' up-line-or-history   # was k (up)
bindkey -M vicmd ';' vi-forward-char      # was l (right)

bindkey -M visual 'j' vi-backward-char
bindkey -M visual 'k' down-line-or-history
bindkey -M visual 'l' up-line-or-history
bindkey -M visual ';' vi-forward-char

bindkey -M viins '^[[1;5D' backward-word # Alt+Left
bindkey -M viins '^[[1;5C' forward-word  # Alt+Right (verify with cat -v)

alias claude='claude --dangerously-skip-permissions'

# ---- Reload config ----
# Use this instead of `source ~/.zshrc`. Re-sourcing re-runs compinit + re-binds
# ^T/^R/^F/^P *while the line editor is live*; during that ~0.8s window stray
# terminal input lands on the freshly-rebound keys and fires tv pickers (which
# then open $EDITOR via their f12 action). `exec zsh` replaces the shell so the
# config loads cleanly before zle is interactive, and picks up all changes.
alias reload='exec zsh'
