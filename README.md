# Terminal Setup

## Requirements

- shell: zsh
- git
- television (`tv`) — fuzzy finder (replaces fzf)
- fd
- Tmux
- bat
- lazygit
- eza

## Nice to haves

- starship
- zsh auto-completion
- zsh syntax highlighting

## Television

Migrated from fzf. Channel prototypes (source + preview + actions) live in
`~/.config/television/cable/*.toml`; UI, keybindings and shell triggers in
`~/.config/television/config.toml`. Refresh the built-in channel set with
`tv update-channels` (this overwrites edited prototypes in `cable/`, so the
`files`/`procs` tweaks would need reapplying).

Handy entry points (see `options.sh`): `v` (find file → nvim), `t` (tmux
sessions), `sps`/`^T`-`procs` (processes), `gb`/`gf`/`glo`/`gst`/`gtag` (git
branch/files/log/stash/tags). Shell integration: `^T` smart autocomplete,
`^R` history.
