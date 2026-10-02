"""Exact-commit GitHub gates shared by publishing and Xcode Cloud bootstrap.

The repository is public, so Cloud needs no additional credentials. If a token is
provided it stays in the request header and is never printed.
"""

import argparse
import json
import os
import re
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

REQUIRED_WORKFLOWS = {
    "CI",
    "Python CI Scripts",
    "Workflow Lint",
    "Workflow Security",
    "XcodeGen Drift",
    "SwiftLint",
    "Secret Scan",
}


class GateError(RuntimeError):
    pass


def github_get(path):
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "GreatsOfBharatha-release-gate"}
    if os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["GITHUB_TOKEN"]
    for attempt in range(4):
        try:
            with urlopen(Request("https://api.github.com" + path, headers=headers), timeout=30) as response:
                return json.load(response)
        except HTTPError as exc:
            # 404 can be briefly observed while a new SHA's runs propagate.
            if exc.code in {404, 429, 500, 502, 503, 504} and attempt < 3:
                time.sleep(2**attempt)
                continue
            raise GateError(f"GitHub gate API HTTP {exc.code}") from exc
        except URLError as exc:
            if attempt < 3:
                time.sleep(2**attempt)
                continue
            raise GateError("GitHub gate API network retries exhausted") from exc
    raise GateError("GitHub gate API retries exhausted")


def check_github_gates(sha, get=None, repository=None, platform="IOS"):
    if platform not in {"IOS", "TVOS"}:
        raise GateError("Release platform must be IOS or TVOS")
    required = REQUIRED_WORKFLOWS | ({"tvOS"} if platform == "TVOS" else set())
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise GateError("An exact full lowercase source SHA is required")
    repo = repository or os.environ["GITHUB_REPOSITORY"]
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repo):
        raise GateError("Invalid GitHub repository identity")
    get = get or github_get
    runs = []
    for page in range(1, 11):
        batch = get(f"/repos/{repo}/actions/runs?head_sha={sha}&per_page=100&page={page}")["workflow_runs"]
        runs.extend(batch)
        if len(batch) < 100:
            break
    latest = {}
    # Main push tests include the final integration commit. PR tests do not.
    for run in sorted(runs, key=lambda r: r["id"]):
        if (
            run.get("event") == "push"
            and run.get("head_branch") == "main"
            and run.get("head_sha") == sha
            and run.get("name") in required
        ):
            latest[run["name"]] = run
    missing = required - latest.keys()
    failing = [name for name, run in latest.items() if run.get("conclusion") != "success"]
    if missing or failing:
        raise GateError(f"Exact-SHA main CI gate not green; missing={sorted(missing)}, non-success={sorted(failing)}")
    return {name: run["html_url"] for name, run in sorted(latest.items())}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sha", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--platform", choices=["IOS", "TVOS"], default="IOS")
    args = parser.parse_args()
    # Only missing check metadata is retried. Reported failed checks fail fast.
    for attempt in range(4):
        try:
            report = check_github_gates(args.sha, repository=args.repository, platform=args.platform)
            print(json.dumps({"sourceSha": args.sha, "ciGates": report}, indent=2))
            return
        except GateError as exc:
            if "non-success=[]" in str(exc) and attempt < 3:
                time.sleep(2**attempt)
                continue
            raise


if __name__ == "__main__":
    main()
