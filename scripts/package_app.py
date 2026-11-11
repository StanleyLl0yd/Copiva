#!/usr/bin/env python3
"""Package a numeric Copiva release on a GitHub macOS runner."""
import hashlib
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

from release_policy import build_authorized, publication_authorized

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "release" / "VERSION").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", VERSION):
    raise SystemExit("Release versions must contain only numeric X.Y.Z components")
request = json.loads((ROOT / "release" / "REQUEST").read_text(encoding="utf-8"))
if not build_authorized(request, VERSION):
    raise SystemExit("A matching owner-authorized build/release request is required")
authorized = publication_authorized(request, VERSION)
TAG = f"v{VERSION}"
ARCHIVE = f"Copiva-{VERSION}-macos-arm64.zip"


def run(*args, capture=False):
    return subprocess.run(
        args, cwd=ROOT, check=True, text=True,
        stdout=subprocess.PIPE if capture else None,
    ).stdout


def sha256(path):
    with path.open("rb") as stream:
        digest = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
        return digest.hexdigest()


if sys.platform != "darwin" or os.environ.get("GITHUB_ACTIONS") != "true":
    raise SystemExit("Packaging requires a GitHub-hosted macOS Actions runner")
if os.environ.get("GITHUB_REPOSITORY") != "StanleyLl0yd/Copiva":
    raise SystemExit("Unexpected source repository")
commit = os.environ["GITHUB_SHA"]
if not re.fullmatch(r"[0-9a-f]{40}", commit):
    raise SystemExit("Invalid source commit")
if run("git", "rev-parse", "HEAD", capture=True).strip() != commit:
    raise SystemExit("Checkout differs from the workflow source commit")

xcode = run("xcodebuild", "-version", capture=True).strip()
swift = run("xcrun", "swift", "--version", capture=True).strip()
run("xcrun", "swift", "build", "--configuration", "release", "--arch", "arm64",
    "--product", "Copiva")
directory = run("xcrun", "swift", "build", "--configuration", "release",
                "--arch", "arm64", "--show-bin-path", capture=True).strip()
binary = Path(directory) / "Copiva"

dist = ROOT / "dist"
dist.mkdir(exist_ok=False)
app = dist / "Copiva.app"
macos = app / "Contents" / "MacOS"
resources = app / "Contents" / "Resources"
macos.mkdir(parents=True)
resources.mkdir()
executable = macos / "Copiva"
shutil.copyfile(binary, executable)
executable.chmod(0o755)
architectures = run("xcrun", "lipo", "-archs", str(executable),
                    capture=True).split()
if architectures != ["arm64"]:
    raise SystemExit("Apple Silicon app must contain arm64 only")

with (ROOT / "Config" / "Info.plist").open("rb") as stream:
    info = plistlib.load(stream)
if (info["CFBundleIdentifier"] != "io.github.StanleyLl0yd.Copiva"
        or info["CFBundleShortVersionString"] != VERSION
        or info["LSMinimumSystemVersion"] != "26.0"
        or info["LSUIElement"] is not True):
    raise SystemExit("Unexpected bundle identity or platform requirements")
info["CopivaSourceRevision"] = commit
info["CopivaReleaseTag"] = TAG
with (app / "Contents" / "Info.plist").open("wb") as stream:
    plistlib.dump(info, stream)
shutil.copyfile(ROOT / "LICENSE", resources / "LICENSE.txt")
run("plutil", "-lint", str(app / "Contents" / "Info.plist"))
run("codesign", "--force", "--sign", "-", "--timestamp=none", str(app))
run("codesign", "--verify", "--strict", "--verbose=2", str(app))

archive = dist / ARCHIVE
run("ditto", "-c", "-k", "--sequesterRsrc", "--keepParent",
    str(app), str(archive))
with zipfile.ZipFile(archive) as package:
    if package.testzip() is not None:
        raise SystemExit("ZIP integrity verification failed")
with tempfile.TemporaryDirectory(prefix="copiva-verify-",
                                 dir=os.environ["RUNNER_TEMP"]) as temporary:
    run("ditto", "-x", "-k", str(archive), temporary)
    unpacked = Path(temporary) / "Copiva.app"
    run("codesign", "--verify", "--strict", "--verbose=2", str(unpacked))
    if sha256(unpacked / "Contents" / "MacOS" / "Copiva") != sha256(executable):
        raise SystemExit("Packaged executable differs from the verified app")

run_url = (
    f"https://github.com/{os.environ['GITHUB_REPOSITORY']}/actions/runs/"
    f"{os.environ['GITHUB_RUN_ID']}"
)
metadata = {
    "schema_version": 1, "version": VERSION, "release_tag": TAG,
    "publication_authorized": authorized,
    "source_repository": "StanleyLl0yd/Copiva", "source_commit": commit,
    "source_ref": os.environ["GITHUB_REF"], "workflow_run": run_url,
    "architectures": sorted(architectures), "minimum_macos": "26.0",
    "code_signature": "ad-hoc", "apple_notarized": False,
    "user_acceptance": "pending", "xcode": xcode, "swift": swift,
    "archive": ARCHIVE, "archive_sha256": sha256(archive),
}
metadata_path = dist / "BUILD-INFO.json"
metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
(dist / "SHA256SUMS").write_text(
    "".join(f"{sha256(path)}  {path.name}\n"
            for path in (archive, metadata_path)), encoding="utf-8",
)
notes = (ROOT / "docs" / "releases" / f"{VERSION}.md").read_text(encoding="utf-8")
(dist / "RELEASE_NOTES.md").write_text(
    notes + f"\nSource commit: {commit}.\nBuild evidence: {run_url}.\n",
    encoding="utf-8",
)
artifact_name = f"copiva-{VERSION}-{commit}-{os.environ['GITHUB_RUN_ATTEMPT']}"
with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
    output.write(f"artifact_name={artifact_name}\nversion={VERSION}\n")
    output.write(f"publication_authorized={str(authorized).lower()}\n")
print(f"Verified {ARCHIVE}: {metadata['archive_sha256']}")
