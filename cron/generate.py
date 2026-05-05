#!/usr/bin/env python3
"""Render update.sh from update.sh.tmpl + commands.json.

Prompts y/N for each command available on the current OS, then substitutes
the selected commands into the template. install.sh moves the result into
~/.local/bin.
"""

from __future__ import annotations

import json
import platform
import shlex
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TEMPLATE = ROOT / "update.sh.tmpl"
COMMANDS = ROOT / "commands.json"
OUTPUT = ROOT / "update.sh"
PLACEHOLDER = "__COMMANDS__"


def main() -> int:
    system = platform.system().lower()
    if system not in {"linux", "darwin"}:
        print(f"Unsupported OS: {system}", file=sys.stderr)
        return 1

    commands = json.loads(COMMANDS.read_text())
    available = commands.get(system, [])
    if not available:
        print(f"No commands defined for {system} in commands.json", file=sys.stderr)
        return 1

    print(f"{system.capitalize()} detected. Pick commands to include:")
    selected: list[str] = []
    for entry in available:
        choice = (
            input(f"  include '{entry['description']}: {entry['command']}'? (y/N) ")
            .strip()
            .lower()
        )
        if choice == "y":
            selected.append(entry["command"])

    if not selected:
        print("No commands selected; aborting.", file=sys.stderr)
        return 1

    rendered = "\n".join(f"run {shlex.quote(cmd)}" for cmd in selected)
    OUTPUT.write_text(TEMPLATE.read_text().replace(PLACEHOLDER, rendered))
    OUTPUT.chmod(0o755)
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
