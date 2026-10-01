"""Validate and stamp XcodeGen versions using only the Python standard library."""

import argparse
import re
from pathlib import Path

VERSION_RE = re.compile(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\Z")


def stamp(source, tag, build_number):
    if not re.fullmatch(r"[1-9]\d*", build_number):
        raise ValueError("Build number must be a positive integer")
    if tag:
        if not tag.startswith("v") or not VERSION_RE.fullmatch(tag[1:]):
            raise ValueError("Release tag must be v plus three numeric version components")
        source, count = re.subn(r"(?m)^(\s*MARKETING_VERSION:) [^\n]+$", rf"\g<1> {tag[1:]}", source)
        if count != 1:
            raise ValueError("Expected exactly one MARKETING_VERSION in project.yml")
    source, count = re.subn(r"(?m)^(\s*CURRENT_PROJECT_VERSION:) [^\n]+$", rf"\g<1> {build_number}", source)
    if count != 1:
        raise ValueError("Expected exactly one CURRENT_PROJECT_VERSION in project.yml")
    return source


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--tag", default="")
    parser.add_argument("--build-number", required=True)
    args = parser.parse_args()
    path = Path(args.project)
    path.write_text(stamp(path.read_text(), args.tag, args.build_number))


if __name__ == "__main__":
    main()
