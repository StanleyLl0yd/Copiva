"""Keep build-only validation separate from GitHub Release publication."""
from datetime import date
import re

VERSION_PATTERN = r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"


def build_authorized(request, version):
    if not isinstance(version, str) or not re.fullmatch(VERSION_PATTERN, version):
        return False
    if not isinstance(request, dict):
        return False
    if (request.get("version") != version
            or request.get("authorized_by") != "StanleyLl0yd"
            or request.get("publication") not in ("github-release", "actions-artifact")):
        return False
    value = request.get("authorization_date")
    if not isinstance(value, str):
        return False
    try:
        return date.fromisoformat(value).isoformat() == value
    except ValueError:
        return False


def publication_authorized(request, version):
    return build_authorized(request, version) and request["publication"] == "github-release"
