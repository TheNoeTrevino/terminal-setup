# ---------------------------------------------------------------------------
# fzf is the fuzzy finder for everything in this file.
#   - Shell integration (^T files, ^R history, Alt-C cd) comes from `fzf --zsh`
#   - Git pickers (^G chords) come from fzf-git.sh, sourced further down
#   - fd builds the file lists; bat renders the previews
# ---------------------------------------------------------------------------

# claude code options
export CLAUDE_CODE_NO_FLICKER=1

export EDITOR='nvim'

# ---- Command history ----
# zsh ships with no HISTFILE and SAVEHIST=0, so history was in-memory only and
# capped at 30 lines -- every new terminal started blank. fzf's ^R widget reads
# the *in-memory* list (`fc -rl 1`), so persistence has to happen here.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000 # lines kept in memory (what ^R searches)
SAVEHIST=100000 # lines written to HISTFILE

# share_history: write each command out immediately AND pull in commands other
# live sessions have written, so ^R in one terminal sees what you typed in
# another. It sets append_history and subsumes inc_append_history, so neither
# needs setting here. Anything below that re-sets these will silently win, so
# keep history config in this one block.
setopt share_history
setopt extended_history     # record timestamp + duration per entry
setopt hist_ignore_all_dups # drop the older copy when a command repeats
setopt hist_ignore_space    # leading space keeps a command out of history
setopt hist_reduce_blanks   # tidy up whitespace before storing
setopt hist_verify          # expansions land on the line for review, not run

# Initialize zsh's completion system. This has to run BEFORE fzf's integration:
# fzf's completion.zsh reads whatever is currently bound to <Tab> and reuses it
# as its own fallback, so compinit must have claimed <Tab> first. compinit also
# backs the `completion` autosuggest strategy set in .zshrc.
autoload -Uz compinit && compinit

# ---- fzf sources and previews ----
# fd replaces find: it honours .gitignore, and --hidden with --exclude .git
# picks up dotfiles without the .git object noise.
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# ctrl-k moves down and ctrl-l moves up in every fzf picker.
export FZF_DEFAULT_OPTS='--bind ctrl-k:down,ctrl-l:up'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"

# Path and directory sources for fzf's `**<Tab>` completion trigger.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# Shell integration: binds ^T (insert a file path), ^R (command history) and
# Alt-C (cd into a subdirectory), each in the emacs, viins and vicmd keymaps.
# It also binds <Tab> to `fzf-completion`, which only takes over after the `**`
# trigger -- a plain <Tab> still runs the zsh completion compinit installed.
_fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf_init.zsh"
if [[ ! -f "$_fzf_cache" || $(which fzf) -nt "$_fzf_cache" ]]; then
  fzf --zsh >|"$_fzf_cache"
fi
source "$_fzf_cache"
unset _fzf_cache

# ^F is a second key for the file widget, for muscle memory.
bindkey -M viins '^F' fzf-file-widget
bindkey -M vicmd '^F' fzf-file-widget

_starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship_init.zsh"
if [[ ! -f "$_starship_cache" || $(which starship) -nt "$_starship_cache" ]]; then
  starship init zsh >|"$_starship_cache"
fi
source "$_starship_cache"
unset _starship_cache

export ITEM_DIR="/Users/noetrevino/.config/sketchybar/items"

# ---- Interactive-only aliases ----
# This file is sourced by non-interactive shells too (scripts, `zsh -c`, agents
# and other tooling that loads the profile). Aliases are still expanded there,
# so things like `ls` -> eza or `claude` -> --dangerously-skip-permissions leak
# into automation and break scripts that expect the real command. Use `ialias`
# instead of `alias` for anything that's purely a typing shortcut; it's a no-op
# unless the shell is interactive. Functions below are left unguarded on
# purpose -- they're new names, not overrides.
ialias() {
  [[ -o interactive ]] && alias "$@"
  return 0
}

# ---- Eza (better ls) -----
ialias ls="eza --icons=always --color=always --long  --no-filesize --no-time --no-user --no-permissions"

# ---- Run a picker in a herdr popup ----
# Same idea as the ^G chords from fzf-git.sh: inside herdr the picker floats in
# a popup, and everywhere else it draws inline. The plugin that owns the popup
# is ~/terminal-setup/herdr-popup, registered once with:
#   herdr plugin link ~/terminal-setup/herdr-popup
#
# Returns 0 when herdr took the request, so the caller stops. Returns non-zero
# when the caller must run the picker inline instead. That covers every case:
# no herdr, plugin not linked, or a herdr too old for plugin panes.
herdr-popup() {
  [[ ${HERDR_ENV:-} == 1 ]] || return 1
  [[ -n ${HERDR_PANE_ID:-} ]] || return 1
  command -v herdr > /dev/null 2>&1 || return 1
  [[ -x $1 ]] || return 1

  # The popup is a child of the herdr server, not of this shell, so it inherits
  # the server's environment and none of these exports. Forward them by hand or
  # the popup ignores settings that work everywhere else.
  local v val
  local -a envopts
  envopts=()
  for v in NO_COLOR EDITOR PAGER BAT_STYLE BAT_THEME \
           FZF_DEFAULT_OPTS FZF_DEFAULT_COMMAND FZF_DEFAULT_OPTS_FILE; do
    eval "val=\${$v:-}"
    [[ -n $val ]] && envopts+=(--env "$v=$val")
  done

  herdr plugin pane open --plugin local.popup --entrypoint script \
    "${envopts[@]}" \
    --env "HERDR_POPUP_SCRIPT=$1" \
    --env "HERDR_POPUP_CALLER=$HERDR_PANE_ID" \
    --cwd "$PWD" > /dev/null 2>&1
}

# ---- Fuzzy-find a file and open it in nvim ----
# The picker itself lives in pickers/v.zsh, so the popup and the inline path
# share one copy. Inside herdr it floats; everywhere else it draws inline.
v() {
  herdr-popup ~/terminal-setup/pickers/v.zsh && return
  ~/terminal-setup/pickers/v.zsh
}

update() {
  echo "=== Updating system with pacman ==="
  sudo pacman -Syu --noconfirm

  echo "=== Updating AUR packages with yay ==="
  yay -Syu --noconfirm

  echo "=== System fully updated! ==="
}

# ---- TMUX ----
# `tmux capture-pane` previews the session's current pane, so there is no
# dependency on sesh (which isn't installed).
_tmux_pick_session() {
  tmux ls -F '#{session_name}' 2>/dev/null |
    fzf --tmux center,80%,60% --height 40% --border --layout=reverse \
      --preview 'tmux capture-pane -ep -t {}'
}

tmux-list() {
  local session
  session=$(_tmux_pick_session) || return
  [[ -n "$session" ]] || return
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach -t "$session"
  fi
}

tmux-kill() {
  local session
  session=$(_tmux_pick_session) || return
  [[ -n "$session" ]] && tmux kill-session -t "$session"
}

ialias t='tmux-list'

# ---- Zoxide (better cd) ----
_zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.zsh"
if [[ ! -f "$_zoxide_cache" || $(which zoxide) -nt "$_zoxide_cache" ]]; then
  zoxide init zsh >|"$_zoxide_cache"
fi
source "$_zoxide_cache"
unset _zoxide_cache

export PATH="$HOME/.cargo/bin:$PATH"

# ---- Git aliases ----
ialias l="git log --oneline"
ialias lg="lazygit"
ialias gr='function _gr() { if [[ "$1" =~ ^[0-9]+$ ]]; then git rebase -i HEAD~$1; else git rebase -i $1; fi; }; _gr'
ialias g='git'
ialias n='clear && neofetch'

# ---- Git pickers: fzf-git.sh (Ctrl-G chords) ----
# junegunn's fzf-git.sh: each Ctrl-G chord opens an fzf picker and inserts the
# selected object at the cursor. It only binds the two-key ^G chords (in
# viins/vicmd), so ^T/^R/^F and the other pickers here are untouched.
#   ^G^F files    ^G^B branches  ^G^T tags      ^G^R remotes    ^G^H hashes
#   ^G^S stashes  ^G^L reflogs   ^G^E each-ref  ^G^W worktrees   (^G^? lists all)
source ~/terminal-setup/fzf-git.sh/fzf-git.sh

# ---- Process picker ----
# ctrl-r refreshes the list. f2 sends TERM to the highlighted process and f3
# sends KILL; both refresh afterwards. Field 2 of `ps -ef` is the PID.
sps() {
  ps -ef | fzf --header-lines=1 --height=50% --layout=reverse --border \
    --header 'ctrl-r reload | f2 term | f3 kill' \
    --bind 'ctrl-r:reload(ps -ef)' \
    --bind 'f2:execute-silent(kill -TERM {2})+reload(ps -ef)' \
    --bind 'f3:execute-silent(kill -KILL {2})+reload(ps -ef)'
}

_fzf_procs_widget() {
  sps >/dev/null
  zle reset-prompt
}
zle -N _fzf_procs_widget

_fg_widget() { fg; }
zle -N _fg_widget

# ---- Jobs picker ----
fjob() {
  local job
  job=$(jobs | fzf --height=40% --layout=reverse --border |
    awk '{print $1}' | tr -d '[]')
  [[ -n "$job" ]] && fg "%$job"
}

bindkey '^P' _fzf_procs_widget
bindkey '^Z' _fg_widget

bindkey -M viins '^[[1;5D' backward-word # Alt+Left
bindkey -M viins '^[[1;5C' forward-word  # Alt+Right (verify with cat -v)

ialias claude='claude --dangerously-skip-permissions'

# ---- Reload config ----
# Use this instead of `source ~/.zshrc`. Re-sourcing re-runs compinit + re-binds
# ^T/^R/^F/^P *while the line editor is live*; during that window stray terminal
# input lands on the freshly-rebound keys and fires the pickers. `exec zsh`
# replaces the shell so the config loads cleanly before zle is interactive, and
# picks up all changes.
ialias reload='exec zsh'

# remove lag from going into vi mode in shell
export KEYTIMEOUT=45
