# cron / update scheduler

Generates a small `update.sh` that runs OS-package updates and schedules it
via cron. Optionally pings Telegram when it's done.

Originally lived at <https://github.com/v-i-n-a-y/crontab-updater>.

## Install

```sh
./install.sh
```

You'll be prompted y/N for each candidate update command. The selections are
rendered into `~/.local/bin/update.sh` and a monthly cron entry is added
(`0 2 1 * * ~/.local/bin/update.sh`). Output goes to `~/update.log`.

## Telegram notifications (optional)

`install.sh` writes a skeleton at `~/.config/crontab-updater/env`. Fill it in:

```sh
BOT_TOKEN=...
CHAT_ID=...
```

`update.sh` sources this file at runtime, so the token never lands in the
generated script. Distribute the env file to each box however you like
(GitHub Secrets → Actions → scp, ansible, manual edit, etc.).

If `BOT_TOKEN` or `CHAT_ID` are unset the Telegram block is skipped.

## sudo and cron

cron has no tty, so any command that needs `sudo` must work without a
password prompt — set that up via `/etc/sudoers.d/`.

## Files

- `install.sh` — runs the generator, installs to `~/.local/bin`, schedules cron.
- `generate.py` — renders `update.sh` from the template + commands.json.
- `update.sh.tmpl` — the script template (`__COMMANDS__` is the substitution point).
- `commands.json` — candidate update commands per OS.
