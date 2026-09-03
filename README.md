# Terminal Setup

`options.sh` is the whole shell config. Source it from `.zshrc`.

## Setup on a new machine

```sh
git clone git@github.com:TheNoeTrevino/terminal-setup.git ~/terminal-setup
echo 'source ~/terminal-setup/options.sh' >> ~/.zshrc

# Register the herdr popup plugins. herdr stores these as absolute paths in
# ~/.config/herdr/plugins.json, which the dotfiles repo does not track, so
# every machine runs these itself.
herdr plugin link ~/terminal-setup/fzf-git.sh
herdr plugin link ~/terminal-setup/herdr-popup

exec zsh
```

Check the plugins with `herdr plugin list`. Both must appear as `enabled`.
Skip the two link commands if you do not use herdr. Every picker falls back
to drawing inline.

The packages come from `~/.config/install.sh` in the dotfiles repo.

## Requirements

- zsh
- git
- [herdr](https://herdr.dev) — terminal multiplexer, replaced tmux
- fzf — fuzzy finder
- fd — file lists
- bat — file previews
- delta — diff previews, set as `core.pager` in the dotfiles repo
- neovim
- eza
- lazygit

tmux still works. `t`, `tmux-list` and `tmux-kill` are unchanged, and every
picker uses a tmux popup when `$TMUX` is set.

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
- `^G` chords — git pickers from `fzf-git.sh`.
- `**` then `<Tab>` — fuzzy path completion. A plain `<Tab>` stays normal zsh
  completion.

### The `^G` git pickers

Each takes `^G b` or `^G ^B`. The full set:

| Chord | Picker | Chord | Picker |
|---|---|---|---|
| `^G f` | Files | `^G s` | Stashes |
| `^G b` | Branches | `^G l` | Reflogs |
| `^G t` | Tags | `^G e` | Each ref |
| `^G r` | Remotes | `^G w` | Worktrees |
| `^G h` | Hashes | | |

Inside a picker: `CTRL-O` opens in a browser, `ALT-A` widens the list,
`ALT-E` opens in `$EDITOR`, `CTRL-/` moves the preview, and `TAB`
multi-selects.

## Popups

Inside herdr every picker floats in a popup. Outside herdr it draws inline,
and under tmux it uses a tmux popup. Nothing needs configuring; the picker
detects where it is running.

herdr has no CLI command that opens a popup, and fzf's own `--popup` supports
only tmux and Zellij. A plugin pane declared with `placement = "popup"` is the
only popup a shell command can open, which is why the two plugins above exist:

- `fzf-git.sh/herdr-plugin.toml` — serves the `^G` chords.
- `herdr-popup/herdr-plugin.toml` — generic. It runs whatever script the
  caller names in `HERDR_POPUP_SCRIPT`.

A popup cannot return text on stdout, so it writes back into the pane that
opened it with `herdr pane send-text` or `herdr pane run`.

To give another picker a popup, add a script to `pickers/` and one line to the
function:

```zsh
herdr-popup ~/terminal-setup/pickers/<name>.zsh && return
```

`pickers/v.zsh` is the worked example. It branches on `HERDR_POPUP_CALLER` so
one copy of the picker serves both the popup and the inline path.

## Entry points

See `options.sh`.

| Command | Does |
|---|---|
| `v` | Find a file, open it in nvim. Popup inside herdr. |
| `t` / `tmux-list` | Attach to a tmux session. |
| `tmux-kill` | Kill a tmux session. |
| `sps` | Process picker. |
| `fjob` | Jobs picker. |
| `reload` | Restart the shell with the new config. |
