# Terminal Setup

## Requirements

- shell: zsh
- git
- fzf — fuzzy finder
- fd
- Tmux
- bat
- lazygit
- eza

## Nice to haves

- starship
- zsh auto-completion
- zsh syntax highlighting

## fzf

`fzf --zsh` supplies the shell integration. `options.sh` caches its output in
`$XDG_CACHE_HOME/fzf_init.zsh` and regenerates it when the `fzf` binary is
newer. `fd` builds the file lists and `bat` renders the previews.

Key bindings:

- `^T` and `^F` — insert a file path on the command line.
- `^R` — search command history.
- `Alt-C` — cd into a subdirectory.
- `^P` — process picker (`ctrl-r` reload, `f2` term, `f3` kill).
- `^Z` — foreground the last job.
- `^G` chords — git pickers from `fzf-git.sh` (`^G^F` files, `^G^B` branches,
  `^G^H` hashes, `^G^S` stashes; `^G^?` lists them all).
- `**` then `<Tab>` — fuzzy path completion. A plain `<Tab>` stays normal zsh
  completion.

Entry points (see `options.sh`): `v` (find a file, open it in nvim), `t` /
`tmux-list` (attach to a tmux session), `tmux-kill`, `sps` (processes), `fjob`
(jobs), `reload` (restart the shell with the new config).
