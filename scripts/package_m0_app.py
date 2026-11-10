#!/usr/bin/env python3
"""Package the owner-requested M0 acceptance app on a GitHub macOS runner."""
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

ROOT = Path(__file__).resolve().parents[1]
TAG = "v0.0.1-m0.1"
ARCHIVE = f"Copiva-{TAG}-macos-universal.zip"


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
binaries = []
for arch in ("arm64", "x86_64"):
    run("xcrun", "swift", "build", "--configuration", "release", "--arch", arch,
        "--product", "Copiva")
    directory = run("xcrun", "swift", "build", "--configuration", "release",
                    "--arch", arch, "--show-bin-path", capture=True).strip()
    binaries.append(str(Path(directory) / "Copiva"))

dist = ROOT / "dist"
dist.mkdir(exist_ok=False)
app = dist / "Copiva.app"
macos = app / "Contents" / "MacOS"
resources = app / "Contents" / "Resources"
macos.mkdir(parents=True)
resources.mkdir()
executable = macos / "Copiva"
run("xcrun", "lipo", "-create", *binaries, "-output", str(executable))
executable.chmod(0o755)
architectures = run("xcrun", "lipo", "-archs", str(executable),
                    capture=True).split()
if sorted(architectures) != ["arm64", "x86_64"]:
    raise SystemExit("Universal app must contain exactly arm64 and x86_64")

with (ROOT / "Config" / "Info.plist").open("rb") as stream:
    info = plistlib.load(stream)
if (info["CFBundleIdentifier"] != "io.github.StanleyLl0yd.Copiva"
        or info["CFBundleShortVersionString"] != "0.0.1"
        or info["LSMinimumSystemVersion"] != "26.0"
        or info["LSUIElement"] is not True):
    raise SystemExit("Unexpected M0 bundle identity or platform requirements")
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
    "schema_version": 1, "release_tag": TAG,
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
notes = (ROOT / "docs" / "releases" / f"{TAG}.md").read_text(encoding="utf-8")
(dist / "RELEASE_NOTES.md").write_text(
    notes + f"\nSource commit: {commit}.\nBuild evidence: {run_url}.\n",
    encoding="utf-8",
)
artifact_name = f"copiva-m0-{commit}-{os.environ['GITHUB_RUN_ATTEMPT']}"
with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
    output.write(f"artifact_name={artifact_name}\n")
print(f"Verified {ARCHIVE}: {metadata['archive_sha256']}")
