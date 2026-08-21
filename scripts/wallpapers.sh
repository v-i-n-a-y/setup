#!/usr/bin/env bash
# Clone (or update) the wallpapers repo, pick an image from it, and set it as
# the desktop background.

set -euo pipefail

REPO="https://github.com/v-i-n-a-y/wallpapers.git"
DEST="$HOME/Pictures/wallpapers"

if [[ -d "$DEST/.git" ]]; then
    echo "Updating existing clone at $DEST..."
    git -C "$DEST" pull --ff-only
else
    git clone "$REPO" "$DEST"
fi

# An image is any top-level file that `file` identifies as image/* — that also
# catches extension-less images and skips non-image strays (a README, etc.).
# Without `file` available, fall back to a known-extension match.
is_image() {
    if command -v file >/dev/null 2>&1; then
        [[ "$(file -b --mime-type "$1" 2>/dev/null)" == image/* ]]
    else
        case "$1" in
            *.jpg|*.jpeg|*.png|*.webp|*.gif|*.bmp|*.JPG|*.JPEG|*.PNG|*.WEBP|*.GIF|*.BMP) return 0 ;;
        esac
        return 1
    fi
}

IMAGES=()
while IFS= read -r -d '' img; do
    if is_image "$img"; then
        IMAGES+=("$img")
    fi
done < <(find "$DEST" -maxdepth 1 -type f -print0 | sort -z)

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "No images found in $DEST — nothing to set."
    exit 0
fi

# Non-interactive runs (piped, CI) clone/update but never apply a wallpaper.
if [[ ! -t 0 ]]; then
    echo "Not interactive — skipped picking a wallpaper. ${#IMAGES[@]} image(s) available in $DEST."
    exit 0
fi

echo "Available wallpapers:"
i=1
for img in "${IMAGES[@]}"; do
    printf " %2d) %s\n" "$i" "${img#$DEST/}"
    i=$((i + 1))
done

read -rp "Set a wallpaper? [1-${#IMAGES[@]}], or Enter to skip: " choice
if [[ -z "$choice" ]]; then
    echo "Skipped."
    exit 0
fi
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#IMAGES[@]} )); then
    echo "Not a valid choice — skipped."
    exit 0
fi
IMG="${IMAGES[choice - 1]}"

apply_macos() {
    # Escape the one character that can't appear unquoted in an AppleScript
    # string literal, then refresh the Dock so the new picture shows up.
    local esc="${IMG//\"/\\\"}"
    osascript -e "tell application \"System Events\" to set picture of every desktop to \"$esc\""
    killall Dock 2>/dev/null || true
    echo "Wallpaper set (macOS): $IMG"
}

apply_gnome() {
    # Set both light and dark URIs so it also applies in GNOME's dark mode.
    local uri="file://${IMG}"
    gsettings set org.gnome.desktop.background picture-uri "$uri"
    gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
    echo "Wallpaper set (GNOME): $IMG"
}

apply_x11() {
    local tool
    if command -v xwallpaper >/dev/null 2>&1; then
        xwallpaper --zoom "$IMG"
        tool="xwallpaper"
    elif command -v feh >/dev/null 2>&1; then
        feh --bg-fill "$IMG"
        tool="feh"
    else
        return 1
    fi
    echo "Wallpaper set ($tool): $IMG"
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    apply_macos
elif command -v gsettings >/dev/null 2>&1 \
    && gsettings get org.gnome.desktop.background picture-uri &>/dev/null; then
    apply_gnome
elif [[ -n "${DISPLAY:-}" ]]; then
    apply_x11 || echo "Couldn't find xwallpaper or feh — set it manually: $IMG"
else
    echo "No supported wallpaper setter found in this session — set it manually: $IMG"
fi
