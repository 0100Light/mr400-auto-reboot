#!/usr/bin/env bash
# Setup script for running the MR400 reboot job on a TinyPilot (or any
# Debian/Ubuntu/Raspberry Pi OS host). Idempotent — safe to re-run.
#
# TinyPilot ships Debian Bullseye with Python 3.9, but `tplinkrouterc6u`
# requires Python >= 3.10. We use `uv` to install a self-contained Python 3.11
# without touching the system Python.
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
    echo "ERROR: do not run this script with sudo." >&2
    echo "       uv installs to \$HOME/.local/bin — running as root puts it in /root." >&2
    echo "       Just run: ./setup-tinypilot.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PY_VERSION="3.11"

echo "== Installing uv (if missing) =="
if ! command -v uv >/dev/null 2>&1; then
    # uv installs to $HOME/.local/bin; add that to PATH for this session.
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi
# Ensure subsequent shells also see uv
if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "== Installing Python $PY_VERSION via uv =="
uv python install "$PY_VERSION"

echo "== Creating virtualenv with Python $PY_VERSION =="
if [ -d venv ]; then
    # If venv exists but uses the wrong python, recreate.
    if ! ./venv/bin/python -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" 2>/dev/null; then
        echo "Existing venv uses old Python — recreating"
        rm -rf venv
    fi
fi
if [ ! -d venv ]; then
    uv venv --python "$PY_VERSION" venv
fi

echo "== Installing Python dependencies =="
uv pip install --python ./venv/bin/python -r requirements.txt

echo "== Verifying import =="
./venv/bin/python -c "from tplinkrouterc6u import TplinkRouterProvider; print('Import OK')"

echo "== Checking password.txt =="
if [ ! -f password.txt ]; then
    echo "WARNING: password.txt not found. Create it with:"
    echo "    echo 'your_router_password' > $SCRIPT_DIR/password.txt"
    echo "    chmod 600 $SCRIPT_DIR/password.txt"
else
    chmod 600 password.txt
fi

echo
echo "Setup complete. Next steps:"
echo "  1. Test a reboot manually (WARNING: this WILL reboot your router):"
echo "       $SCRIPT_DIR/run-reboot.sh"
echo "  2. Install the cron entry (edit interval if you want something other than daily at 04:00):"
echo "       crontab -l 2>/dev/null | grep -v run-reboot.sh > /tmp/ct; \\"
echo "         echo '0 4 * * * $SCRIPT_DIR/run-reboot.sh >> $SCRIPT_DIR/reboot.log 2>&1' >> /tmp/ct; \\"
echo "         crontab /tmp/ct && rm /tmp/ct"
