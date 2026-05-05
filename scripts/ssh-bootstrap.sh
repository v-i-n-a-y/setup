#!/usr/bin/env bash
# Generate an ed25519 SSH key (if missing), copy the pubkey to the clipboard,
# and remind you to paste it into GitHub.

set -euo pipefail

KEY="$HOME/.ssh/id_ed25519"
EMAIL="$(git config --global user.email 2>/dev/null || true)"
if [[ -z "$EMAIL" ]]; then
    read -rp "Email for SSH key comment: " EMAIL
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$KEY" ]]; then
    echo "Existing key at $KEY — keeping it."
else
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
fi

if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    ssh-add "$KEY" 2>/dev/null || true
fi

PUB="$KEY.pub"
echo
echo "Public key ($PUB):"
cat "$PUB"
echo

if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$PUB" && echo "Copied to clipboard (pbcopy)."
elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$PUB" && echo "Copied to clipboard (xclip)."
elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$PUB" && echo "Copied to clipboard (wl-copy)."
else
    echo "(No clipboard tool found — copy manually.)"
fi

echo
echo "Add it at: https://github.com/settings/ssh/new"
