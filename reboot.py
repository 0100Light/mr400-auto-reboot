#!/usr/bin/env python3
"""Reboot the TP-Link Archer MR400 via its web API.

Designed to be invoked from cron on a TinyPilot (or any Linux host).

Configuration (in order of precedence):
  1. Environment variables: ROUTER_IP, ROUTER_USERNAME, ROUTER_PASSWORD
  2. password.txt next to this script (password only)
  3. Defaults: IP=192.168.1.1, USERNAME=admin
"""
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

from tplinkrouterc6u import TplinkRouterProvider
from tplinkrouterc6u.common.exception import ClientException, AuthorizeError


SCRIPT_DIR = Path(__file__).resolve().parent


def load_password():
    env_pw = os.environ.get("ROUTER_PASSWORD")
    if env_pw:
        return env_pw
    pw_file = SCRIPT_DIR / "password.txt"
    if pw_file.exists():
        return pw_file.read_text(encoding="utf-8").strip()
    raise SystemExit("No password: set ROUTER_PASSWORD or create password.txt")


def log(msg):
    print(f"[{datetime.now().isoformat(timespec='seconds')}] {msg}", flush=True)


def main():
    router_ip = os.environ.get("ROUTER_IP", "192.168.1.1")
    username = os.environ.get("ROUTER_USERNAME", "admin")
    password = load_password()

    logger = logging.getLogger("mr400-reboot")
    logger.setLevel(logging.WARNING)

    log(f"Connecting to router at {router_ip} as {username}")
    router = TplinkRouterProvider.get_client(
        f"http://{router_ip}",
        password,
        username=username,
        logger=logger,
    )
    try:
        router.authorize()
        log(f"Authorized ({type(router).__name__}) — sending reboot")
        router.reboot()
        log("Reboot command accepted")
    except (ClientException, AuthorizeError) as e:
        log(f"ERROR: {e}")
        return 1
    except Exception as e:
        log(f"UNEXPECTED ERROR: {e!r}")
        return 2
    finally:
        try:
            router.logout()
        except Exception:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
