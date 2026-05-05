#!/usr/bin/env bash
# Install the generated update.sh into ~/.local/bin and schedule it via cron.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/crontab-updater"
CRON_JOB="0 2 1 * * $INSTALL_DIR/update.sh"

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

python3 "$SCRIPT_DIR/generate.py"

mv "$SCRIPT_DIR/update.sh" "$INSTALL_DIR/update.sh"
chmod +x "$INSTALL_DIR/update.sh"

touch "$HOME/update.log"

if [[ ! -f "$CONFIG_DIR/env" ]]; then
    cat > "$CONFIG_DIR/env" <<'EOF'
# Sourced by update.sh. Set these to enable Telegram notifications.
# BOT_TOKEN=your-bot-token
# CHAT_ID=your-chat-id
EOF
    chmod 600 "$CONFIG_DIR/env"
    echo "Wrote skeleton $CONFIG_DIR/env — populate BOT_TOKEN and CHAT_ID there."
fi

EXISTING="$(crontab -l 2>/dev/null || true)"
echo "$EXISTING" > "$HOME/crontab_backup_$(date +%Y%m%d%H%M%S).txt"

if echo "$EXISTING" | grep -Fxq "$CRON_JOB"; then
    echo "Cron job already configured."
else
    echo "Adding cron job: $CRON_JOB"
    { [[ -n "$EXISTING" ]] && echo "$EXISTING"; echo "$CRON_JOB"; } | crontab -
fi

echo "Done. Current crontab:"
crontab -l
