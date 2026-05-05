# setup

A one-command bootstrap for fresh Linux and macOS boxes.

I move computers (or crash them) often enough that I'd rather not redo the
same dotfiles, package installs, and shell configuration by hand each time.
`setup.sh` installs the tools I use, drops my dotfiles into `$HOME` via
[GNU stow](https://www.gnu.org/software/stow/), and wires up pre-commit
hooks if the repo is a git checkout.

## Quick start

```sh
git clone https://github.com/v-i-n-a-y/setup.git ~/setup
cd ~/setup
./setup.sh
```

Re-running is safe. Every install step short-circuits when the tool is
already present, and `stow --restow` is idempotent. Pre-existing regular
files at stow's targets are moved aside to `<path>.pre-stow.<timestamp>`
before the symlinks are placed, so nothing on disk is destroyed silently.

After `setup.sh`, three optional follow-ups:

```sh
chsh -s "$(command -v fish)"      # make fish the login shell
./scripts/ssh-bootstrap.sh        # generate an ed25519 key, copy it to clipboard
./cron/install.sh                 # schedule monthly OS-package updates
```

## What gets installed

**macOS** — Homebrew bootstraps itself, then `brew bundle install` reads
`Brewfile`:

| Tool | Purpose |
|------|---------|
| `fish` | shell |
| `neovim`, `tmux` | editor, multiplexer |
| `direnv`, `stow` | per-directory env vars, dotfile linking |
| `uv` | Python package and tool manager |
| `gh`, `pre-commit` | GitHub CLI, git hook framework |
| `rclone` | cloud storage sync |
| `gcc`, `mas` | C toolchain (mac builds), Mac App Store CLI |

Rust is installed separately via `rustup` so it's toolchain-managed rather
than pinned to a Homebrew formula version.

**Linux** (Debian / Ubuntu) — `apt-get install` for the same tools where
they exist in the standard repos. `gh` is installed from the official
GitHub apt source. Neovim is pulled from GitHub releases (apt's version is
too old). `uv` and `rust` come from their respective install scripts.
`xclip` and `wl-clipboard` are added so `ssh-bootstrap.sh` can copy
the generated public key on both X11 and Wayland sessions.

`mas` and `pre-commit` are macOS-only / handled differently on Linux as
appropriate; the Brewfile is untouched on Linux.

## Layout

```
setup.sh                          # entry point
Brewfile                          # macOS package list
.pre-commit-config.yaml           # hooks (formatting, linting, secrets)
dotfiles/                         # stow packages — one dir per logical group
  nvim/.config/nvim/init.vim
  fish/.config/fish/{config.fish,conf.d/*,functions/*}
  git/.config/git/{config,ignore}
  tmux/.config/tmux/tmux.conf
scripts/
  ssh-bootstrap.sh                # ed25519 keygen + clipboard + GitHub URL
cron/                             # opt-in monthly OS-update cron job
  install.sh                      # generate update.sh, schedule it
  generate.py                     # render update.sh from template + commands.json
  update.sh.tmpl                  # script template
  commands.json                   # per-OS list of update commands
  README.md                       # setup details, Telegram secrets, etc.
```

## Editing dotfiles

Files under `dotfiles/` are symlinked into `$HOME` by stow, so editing
`~/.config/fish/config.fish` *is* editing
`dotfiles/fish/.config/fish/config.fish`. Commit and push, and the change
propagates to every other box on the next `git pull`.

A consequence of stow's directory-level tree-folding: if `~/.config/tmux`
is itself a symlink to the repo (which it will be after stow), then
`rm ~/.config/tmux/<file>` deletes the file from the repo, not just the
symlink. Use `git rm` from inside the repo instead.

## Pre-commit hooks

`.pre-commit-config.yaml` pulls hooks from
[`v-i-n-a-y/pre-commits`](https://github.com/v-i-n-a-y/pre-commits) v0.5.0:

- `trailing-whitespace`, `end-of-file-fixer`, `mixed-line-endings` — file hygiene
- `detect-secrets` — block AWS keys, GitHub/Slack tokens, JWTs, private keys
- `ruff-check`, `ruff-format` — Python lint and format

`setup.sh` runs `pre-commit install` automatically when this repo is a git
checkout. Manual install:

```sh
pre-commit install
pre-commit run --all-files
```

## Cron-scheduled OS updates (optional)

`cron/install.sh` interactively builds an `update.sh` from a list of
candidate update commands (per OS, defined in `cron/commands.json`),
installs it to `~/.local/bin`, and adds a monthly cron entry. Optional
Telegram notifications are read from `~/.config/crontab-updater/env` at
runtime — the bot token never lands in the generated script. See
`cron/README.md` for details.

## License

[MIT](LICENSE).
