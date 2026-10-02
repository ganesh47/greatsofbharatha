"""Read-only exact version/build availability check (does not publish).

The release orchestrator additionally checks Cloud SHA/run and group membership.
"""

import os
import re
import sys

from testflight_release import VERSION_RE, AppleAPI, Pending, ReleaseError, exact_build


def main():
    version = os.environ["TARGET_VERSION"]
    number = os.environ.get("TARGET_BUILD_NUMBER", "")
    if not VERSION_RE.fullmatch(version) or not re.fullmatch(r"[1-9]\d*", number):
        raise ReleaseError("Numeric TARGET_VERSION and exact TARGET_BUILD_NUMBER are required")
    platform = os.environ.get("TARGET_PLATFORM", "IOS")
    build, state = exact_build(AppleAPI(), os.environ["APP_STORE_CONNECT_APP_ID"], version, number, platform)
    print(f"Exact {platform} build {build['id']}: {version} ({number}), {state}; group assignment not checked")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Pending as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(2)
    except (ReleaseError, KeyError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
