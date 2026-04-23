# TP-Link Archer MR400 Auto-Reboot

Scheduled reboot of a TP-Link Archer MR400 LTE router, designed to run from
cron on a TinyPilot (or any Debian/Ubuntu/Raspberry Pi OS host).

Uses [`tplinkrouterc6u`](https://pypi.org/project/tplinkrouterc6u/), which
handles the GDPR-encrypted auth flow the newer MR400 firmware requires.

## Install on TinyPilot

TinyPilot ships Debian Bullseye with Python 3.9, but `tplinkrouterc6u` requires
Python ≥3.10. The setup script uses [`uv`](https://docs.astral.sh/uv/) to
install a self-contained Python 3.11 without touching the system Python.

```bash
git clone <this-repo-url> ~/archer-mr400-sms-forwarder
cd ~/archer-mr400-sms-forwarder

# Router admin password (kept out of git via .gitignore)
echo 'your_router_password' > password.txt
chmod 600 password.txt

# DO NOT use sudo — uv installs into $HOME/.local/bin
./setup-tinypilot.sh
```

## Test once

Will actually reboot the router (~1–2 min downtime):

```bash
./run-reboot.sh
```

## Schedule with cron

```bash
crontab -e
```

Add one of:

```cron
# Daily at 04:00
0 4 * * * /home/USER/archer-mr400-sms-forwarder/run-reboot.sh >> /home/USER/archer-mr400-sms-forwarder/reboot.log 2>&1

# Every 6 hours
0 */6 * * * /home/USER/archer-mr400-sms-forwarder/run-reboot.sh >> /home/USER/archer-mr400-sms-forwarder/reboot.log 2>&1
```

## Configuration

`reboot.py` reads, in order of precedence:

1. Environment variables: `ROUTER_IP`, `ROUTER_USERNAME`, `ROUTER_PASSWORD`
2. `password.txt` next to the script (password only)
3. Defaults: `ROUTER_IP=192.168.1.1`, `ROUTER_USERNAME=admin`

## License

MIT — see `LICENSE`.
