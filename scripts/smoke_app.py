#!/usr/bin/env python3
"""Check packaged-app launch on a disposable Actions Mac, with capture disabled."""
import os
from pathlib import Path
import subprocess
import sys
import time

if (sys.platform != "darwin" or os.environ.get("GITHUB_ACTIONS") != "true"
        or os.environ.get("GITHUB_REPOSITORY") != "StanleyLl0yd/Copiva"):
    raise SystemExit("Smoke launch requires this repository's macOS Actions runner")

binary = Path(__file__).resolve().parents[1] / "dist/Copiva.app/Contents/MacOS/Copiva"
child = subprocess.Popen(
    [str(binary), "-captureConsent", "NO", "-recordingEnabled", "NO",
     "-ApplePersistenceIgnoreState", "YES"],
    stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
)
try:
    time.sleep(3)
    if child.poll() is not None:
        raise SystemExit(f"Packaged app exited during smoke launch: {child.returncode}")
    print("Packaged app stayed alive with recording forced off. UI/paste acceptance remains pending.")
finally:
    if child.poll() is None:
        child.terminate()
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait(timeout=5)
