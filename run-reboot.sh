#!/usr/bin/env bash
# Wrapper for cron: activate the venv and run reboot.py with a proper cwd.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
exec ./venv/bin/python reboot.py
