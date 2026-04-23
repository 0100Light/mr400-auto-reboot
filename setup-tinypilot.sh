#!/usr/bin/env bash
# Setup script for running the MR400 reboot job on a TinyPilot (or any
# Debian/Ubuntu/Raspberry Pi OS host). Idempotent — safe to re-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Installing python3-venv (requires sudo) =="
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y python3-venv
fi

echo "== Creating virtualenv =="
if [ ! -d venv ]; then
    python3 -m venv venv
fi

echo "== Installing Python dependencies =="
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

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
