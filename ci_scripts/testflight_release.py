"""Publish an exact tested release tag using Xcode Cloud and verify TestFlight.

Apple API contracts: ciBuildRuns, ciWorkflows, builds, betaGroups.
Never logs JWTs, credentials, tester records, author identities, or raw API bodies.
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from urllib.parse import quote, urlparse

import jwt
import requests

ASC_ORIGIN = "https://api.appstoreconnect.apple.com"
VERSION_RE = re.compile(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\Z")
SHA_RE = re.compile(r"[0-9a-f]{40}\Z")
READY_STATES = {"READY_FOR_BETA_TESTING", "IN_BETA_TESTING"}


class ReleaseError(RuntimeError):
    """A terminal error; a failed release must not look like delayed processing."""


class Pending(RuntimeError):
    """A build may become available on a subsequent observation."""


class AppleAPI:
    def __init__(self):
        self.session = requests.Session()

    def request(self, method, path, params=None, body=None):
        url = path if path.startswith("https://") else ASC_ORIGIN + path
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.netloc != "api.appstoreconnect.apple.com":
            raise ReleaseError("Refusing an API or pagination link outside Apple's API origin")
        for attempt in range(4):
            now = int(time.time())
            token = jwt.encode(
                {"iss": os.environ["APP_STORE_CONNECT_ISSUER_ID"], "iat": now,
                 "exp": now + 600, "aud": "appstoreconnect-v1"},
                os.environ["APP_STORE_CONNECT_PRIVATE_KEY"], algorithm="ES256",
                headers={"kid": os.environ["APP_STORE_CONNECT_KEY_ID"], "typ": "JWT"},
            )
            try:
                response = self.session.request(
                    method, url, params=params, json=body, timeout=45,
                    headers={"Authorization": f"Bearer {token}"},
                )
            except requests.RequestException as exc:
                # POST must never be blindly retried: its outcome can be unknown.
                if method != "GET":
                    raise ReleaseError("Apple mutation outcome unknown; inspect preflight/run history before retrying") from exc
                if attempt == 3:
                    raise ReleaseError("Apple API network retries exhausted") from exc
                time.sleep(2 ** attempt)
                continue
            if response.status_code in {429, 500, 502, 503, 504} and method == "GET" and attempt < 3:
                time.sleep(min(int(response.headers.get("Retry-After", 2 ** attempt)), 60))
                continue
            if not response.ok:
                try:
                    codes = sorted({e.get("code", "UNKNOWN") for e in response.json().get("errors", [])})
                except ValueError:
                    codes = ["NON_JSON_RESPONSE"]
                raise ReleaseError(f"Apple API HTTP {response.status_code}: {', '.join(codes)}")
            return response.json() if response.content else {}
        raise ReleaseError("Apple API retries exhausted")

    def get(self, path, params=None):
        return self.request("GET", path, params=params)

    def collection(self, path, params=None):
        resources, included = [], {}
        visited = set()
        while path:
            if path in visited:
                raise ReleaseError("Apple API pagination loop")
            visited.add(path)
            document = self.get(path, params)
            resources.extend(document.get("data", []))
            included.update({(r["type"], r["id"]): r for r in document.get("included", [])})
            path, params = document.get("links", {}).get("next"), None
        return resources, included


def relation(resource, name):
    return resource.get("relationships", {}).get(name, {}).get("data")


def summarize_run(run):
    attrs = run.get("attributes", {})
    return {"id": run["id"], "number": attrs.get("number"),
            "executionProgress": attrs.get("executionProgress"),
            "completionStatus": attrs.get("completionStatus"),
            "sourceSha": attrs.get("sourceCommit", {}).get("commitSha"),
            "createdDate": attrs.get("createdDate")}


def discover(api, app_id):
    app = api.get(f"/v1/apps/{app_id}")["data"]
    if app.get("attributes", {}).get("bundleId") != "com.ganesh47.greatsofbharatha":
        raise ReleaseError("Configured App Store Connect app has the wrong bundle identifier")
    groups, _ = api.collection(f"/v1/apps/{app_id}/betaGroups", {"limit": 200})
    products, _ = api.collection("/v1/ciProducts", {"filter[app]": app_id, "limit": 200})
    report = {"app": {"id": app_id, "bundleId": app["attributes"]["bundleId"]},
              "groups": [{"id": g["id"], "name": g.get("attributes", {}).get("name"),
                          "internal": g.get("attributes", {}).get("isInternalGroup"),
                          "hasAccessToAllBuilds": g.get("attributes", {}).get("hasAccessToAllBuilds")}
                         for g in groups], "products": []}
    for product in products:
        workflows, _ = api.collection(f"/v1/ciProducts/{product['id']}/workflows", {"limit": 200})
        summaries = []
        for workflow in workflows:
            attrs = workflow.get("attributes", {})
            runs, _ = api.collection(f"/v1/ciWorkflows/{workflow['id']}/buildRuns", {"limit": 5, "sort": "-number"})
            # Do not expose other applications, author identities, or commit messages.
            summaries.append({"id": workflow["id"], "name": attrs.get("name"),
                              "enabled": attrs.get("isEnabled"), "locked": attrs.get("isLockedForEditing"),
                              "container": attrs.get("containerFilePath"), "actions": attrs.get("actions", []),
                              "repository": relation(workflow, "repository"),
                              "recentRuns": [summarize_run(r) for r in runs[:5]]})
        report["products"].append({"id": product["id"], "name": product.get("attributes", {}).get("name"),
                                   "workflows": summaries})
    builds, included = api.collection("/v1/builds", {"filter[app]": app_id, "limit": 5,
                                                     "sort": "-uploadedDate", "include": "preReleaseVersion"})
    report["recentBuilds"] = []
    for build in builds[:5]:
        rel = relation(build, "preReleaseVersion") or {}
        version = included.get(("preReleaseVersions", rel.get("id")), {}).get("attributes", {}).get("version")
        report["recentBuilds"].append({"id": build["id"], "marketingVersion": version,
                                      "buildNumber": build.get("attributes", {}).get("version"),
                                      "processingState": build.get("attributes", {}).get("processingState")})
    return report


def validate_inputs(version, sha, tag):
    if not VERSION_RE.fullmatch(version):
        raise ReleaseError("Marketing version must be three numeric components, for example 0.2.0")
    if not SHA_RE.fullmatch(sha):
        raise ReleaseError("An exact full lowercase source SHA is required")
    if tag != "v" + version:
        raise ReleaseError("Release tag must match v plus the requested marketing version")


def github_get(path):
    response = requests.get("https://api.github.com" + path, timeout=30,
                            headers={"Authorization": "Bearer " + os.environ["GITHUB_TOKEN"],
                                     "Accept": "application/vnd.github+json"})
    if not response.ok:
        raise ReleaseError(f"GitHub verification failed: HTTP {response.status_code}")
    return response.json()


def check_tag_sha(tag, sha):
    repo = os.environ["GITHUB_REPOSITORY"]
    ref = github_get(f"/repos/{repo}/git/ref/tags/{quote(tag, safe='')}")["object"]
    for _ in range(5):
        if ref["type"] != "tag":
            break
        ref = github_get(f"/repos/{repo}/git/tags/{ref['sha']}")["object"]
    if ref["type"] != "commit" or ref["sha"] != sha:
        raise ReleaseError("Release tag does not resolve to the exact tested source SHA")


def check_github_gates(sha):
    repo = os.environ["GITHUB_REPOSITORY"]
    required = {"CI", "Python CI Scripts", "Workflow Lint", "Workflow Security", "XcodeGen Drift", "SwiftLint", "Secret Scan"}
    runs = []
    for page in range(1, 11):
        batch = github_get(f"/repos/{repo}/actions/runs?head_sha={sha}&per_page=100&page={page}")["workflow_runs"]
        runs.extend(batch)
        if len(batch) < 100:
            break
    latest = {}
    # Prefer main push runs when present; otherwise exact SHA PR run.
    for run in sorted(runs, key=lambda r: r["id"]):
        if run.get("event") in {"push", "pull_request"} and run.get("name") in required:
            latest[run["name"]] = run
    missing = required - latest.keys()
    failing = [name for name, run in latest.items() if run.get("conclusion") != "success"]
    if missing or failing:
        raise ReleaseError(f"Exact-SHA CI gate not green; missing={sorted(missing)}, non-success={sorted(failing)}")
    return {name: run["html_url"] for name, run in sorted(latest.items())}


def selected_workflow(api, report, workflow_id):
    valid_ids = {w["id"] for p in report["products"] for w in p["workflows"]}
    if workflow_id not in valid_ids:
        raise ReleaseError("Select an existing workflow belonging to this app from preflight")
    return api.get(f"/v1/ciWorkflows/{workflow_id}")["data"]


def selected_group(report, group_id):
    groups = [g for g in report["groups"] if g["id"] == group_id and g["internal"] is True]
    if len(groups) != 1:
        raise ReleaseError("An existing internal beta group ID belonging to this app is required")
    return groups[0]


def configure_archive(api, workflow):
    attrs = workflow.get("attributes", {})
    if attrs.get("isLockedForEditing"):
        raise ReleaseError("Xcode Cloud workflow is locked; cannot repair archive configuration")
    actions = list(attrs.get("actions", []))
    if not any(a.get("actionType") == "ARCHIVE" and a.get("platform") == "IOS" for a in actions):
        actions.append({"name": "Archive iOS for TestFlight", "actionType": "ARCHIVE", "platform": "IOS",
                        "scheme": "GreatsOfBharatha", "destination": "ANY_IOS_DEVICE", "isRequiredToPass": True,
                        "buildDistributionAudience": "INTERNAL_ONLY"})
    patch = {"data": {"type": "ciWorkflows", "id": workflow["id"],
                      "attributes": {"actions": actions, "isEnabled": True, "clean": True,
                                     "manualTagStartCondition": {"source": {"isAllMatch": True}}}}}
    return api.request("PATCH", f"/v1/ciWorkflows/{workflow['id']}", body=patch)["data"]


def workflow_repository(api, workflow):
    rel = relation(workflow, "repository")
    if rel:
        repository = api.get(f"/v1/scmRepositories/{rel['id']}")["data"]
    else:
        repository = api.get(f"/v1/ciWorkflows/{workflow['id']}/repository")["data"]
    attrs = repository.get("attributes", {})
    if (attrs.get("ownerName", "").lower() + "/" + attrs.get("repositoryName", "").lower()
            != os.environ["GITHUB_REPOSITORY"].lower()):
        raise ReleaseError("Xcode Cloud workflow repository does not match this GitHub repository")
    return repository


def find_tag(api, repository_id, tag):
    refs, _ = api.collection(f"/v1/scmRepositories/{repository_id}/gitReferences", {"limit": 200})
    matches = [r for r in refs if r.get("attributes", {}).get("canonicalName") == "refs/tags/" + tag
               and not r.get("attributes", {}).get("isDeleted")]
    if len(matches) != 1:
        raise Pending("Release tag has not appeared in Xcode Cloud yet")
    return matches[0]


def find_or_start_run(api, workflow_id, ref_id, sha):
    runs, _ = api.collection(f"/v1/ciWorkflows/{workflow_id}/buildRuns", {"limit": 200, "sort": "-number",
                                                                       "include": "sourceBranchOrTag"})
    matches = [r for r in runs if (relation(r, "sourceBranchOrTag") or {}).get("id") == ref_id]
    if matches:
        run = matches[0]
        source = run.get("attributes", {}).get("sourceCommit", {}).get("commitSha")
        if source and source != sha:
            raise ReleaseError("Existing Cloud run for this tag has a different source SHA")
        if run.get("attributes", {}).get("completionStatus") not in {None, "SUCCEEDED"}:
            raise ReleaseError("Existing run for this release tag failed; use a new version/tag for retry")
        return run
    return api.request("POST", "/v1/ciBuildRuns", body={"data": {"type": "ciBuildRuns",
                       "attributes": {"clean": True}, "relationships": {
                           "workflow": {"data": {"type": "ciWorkflows", "id": workflow_id}},
                           "sourceBranchOrTag": {"data": {"type": "scmGitReferences", "id": ref_id}}}}})["data"]


def observe_cloud(api, run_id, sha, ref_id):
    run = api.get(f"/v1/ciBuildRuns/{run_id}", {"include": "sourceBranchOrTag"})["data"]
    attrs = run.get("attributes", {})
    source = attrs.get("sourceCommit", {}).get("commitSha")
    if source and source != sha:
        raise ReleaseError("Cloud run source commit differs from the tested SHA")
    if (relation(run, "sourceBranchOrTag") or {}).get("id") != ref_id:
        raise ReleaseError("Cloud run is not linked to the selected immutable release tag")
    if attrs.get("completionStatus") not in {None, "SUCCEEDED"}:
        raise ReleaseError("Xcode Cloud build ended: " + str(attrs["completionStatus"]))
    if attrs.get("executionProgress") != "COMPLETE" or attrs.get("completionStatus") != "SUCCEEDED":
        raise Pending("Cloud run is still building")
    return run


def exact_build(api, app_id, version, build_number):
    builds, included = api.collection("/v1/builds", {"filter[app]": app_id,
        "filter[version]": str(build_number), "include": "preReleaseVersion,buildBetaDetail", "limit": 200})
    matches = []
    for build in builds:
        rel = relation(build, "preReleaseVersion") or {}
        prerelease = included.get(("preReleaseVersions", rel.get("id")), {})
        if prerelease.get("attributes", {}).get("version") == version and str(build["attributes"]["version"]) == str(build_number):
            matches.append(build)
    if not matches:
        raise Pending("Exact marketing version/build number has not appeared in App Store Connect")
    if len(matches) != 1:
        raise ReleaseError("Exact version/build number lookup is ambiguous")
    build = matches[0]
    attrs = build.get("attributes", {})
    if attrs.get("expired") or attrs.get("processingState") in {"FAILED", "INVALID"}:
        raise ReleaseError("Exact App Store Connect build is expired or invalid")
    if attrs.get("processingState") != "VALID":
        raise Pending("Exact App Store Connect build is still processing")
    detail_rel = relation(build, "buildBetaDetail") or {}
    detail = included.get(("buildBetaDetails", detail_rel.get("id")), {})
    if not detail:
        detail = api.get(f"/v1/builds/{build['id']}/buildBetaDetail")["data"]
    state = detail.get("attributes", {}).get("internalBuildState")
    if state in {"PROCESSING_EXCEPTION", "EXPIRED", "MISSING_EXPORT_COMPLIANCE", "IN_EXPORT_COMPLIANCE_REVIEW"}:
        raise ReleaseError("Exact build cannot be tested internally: " + state)
    if state not in READY_STATES:
        raise Pending("Internal TestFlight availability is pending")
    return build, state


def group_contains_build(api, group_id, build_id):
    builds, _ = api.collection(f"/v1/betaGroups/{group_id}/relationships/builds", {"limit": 200})
    return any(b["id"] == build_id for b in builds)


def wait_for(callback, timeout=3600, interval=30):
    deadline = time.monotonic() + timeout
    while True:
        try:
            return callback()
        except Pending as exc:
            if time.monotonic() >= deadline:
                raise ReleaseError("Timed out: " + str(exc)) from exc
            print(json.dumps({"waiting": str(exc)}), flush=True)
            time.sleep(min(interval, max(0, deadline - time.monotonic())))


def write_report(report, path):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2), flush=True)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as summary:
            summary.write("\n```json\n" + json.dumps(report, indent=2) + "\n```\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--operation", choices=["preflight", "configure", "publish", "verify"], default="preflight")
    parser.add_argument("--version", default=os.environ.get("TARGET_VERSION", ""))
    parser.add_argument("--build-number", default="")
    parser.add_argument("--sha", default="")
    parser.add_argument("--tag", default="")
    parser.add_argument("--workflow-id", default="")
    parser.add_argument("--group-id", default="")
    parser.add_argument("--cloud-run-id", default="")
    parser.add_argument("--report", default="release-evidence/testflight.json")
    args = parser.parse_args()
    api, app_id = AppleAPI(), os.environ["APP_STORE_CONNECT_APP_ID"]
    report = discover(api, app_id)
    write_report(report, args.report)
    if args.operation == "preflight":
        return 0
    workflow = selected_workflow(api, report, args.workflow_id)
    repository = workflow_repository(api, workflow)
    if args.operation == "configure":
        selected_group(report, args.group_id)
        workflow = configure_archive(api, workflow)
        write_report({"configuredWorkflow": workflow["id"], "actions": workflow["attributes"]["actions"],
                      "note": "Archive uploads through Xcode Cloud; publishing explicitly attaches the resulting build to the existing internal group."}, args.report)
        return 0
    validate_inputs(args.version, args.sha, args.tag)
    check_tag_sha(args.tag, args.sha)
    gates = check_github_gates(args.sha)
    group = selected_group(report, args.group_id)
    attrs = workflow.get("attributes", {})
    if not attrs.get("isEnabled") or not any(a.get("actionType") == "ARCHIVE" and a.get("platform") == "IOS"
                                            for a in attrs.get("actions", [])):
        raise ReleaseError("Selected workflow must be enabled and archive iOS; run configure if needed")
    ref = wait_for(lambda: find_tag(api, repository["id"], args.tag), timeout=300)
    if args.operation == "publish":
        run = find_or_start_run(api, workflow["id"], ref["id"], args.sha)
        run_id = run["id"]
        write_report({"cloudRun": summarize_run(run), "tag": args.tag, "sourceSha": args.sha,
                      "requestedVersion": args.version, "group": group, "ciGates": gates}, args.report)
    else:
        if not args.cloud_run_id or not re.fullmatch(r"[1-9]\d*", args.build_number):
            raise ReleaseError("Verify requires explicit Cloud run ID and numeric build number")
        run_id = args.cloud_run_id
    run = wait_for(lambda: observe_cloud(api, run_id, args.sha, ref["id"]))
    run_workflow = relation(run, "workflow")
    if run_workflow and run_workflow.get("id") != workflow["id"]:
        raise ReleaseError("Cloud run belongs to another workflow")
    build_number = str(run["attributes"]["number"])
    if args.build_number and args.build_number != build_number:
        raise ReleaseError("Requested build number differs from Xcode Cloud run number")
    build, state = wait_for(lambda: exact_build(api, app_id, args.version, build_number))
    linked, _ = api.collection(f"/v1/ciBuildRuns/{run_id}/builds", {"limit": 200})
    if not any(b["id"] == build["id"] for b in linked):
        raise ReleaseError("Exact App Store Connect build is not linked to this Cloud run")
    check_tag_sha(args.tag, args.sha)
    if not group_contains_build(api, group["id"], build["id"]):
        if args.operation != "publish":
            raise ReleaseError("Exact build is not assigned to the intended internal group")
        api.request("POST", f"/v1/betaGroups/{group['id']}/relationships/builds",
                    body={"data": [{"type": "builds", "id": build["id"]}]})
    if not group_contains_build(api, group["id"], build["id"]):
        raise ReleaseError("Group assignment did not verify")
    write_report({"result": "AVAILABLE_TO_INTERNAL_TESTERS", "sourceSha": args.sha, "tag": args.tag,
                  "marketingVersion": args.version, "buildNumber": build_number, "appId": app_id,
                  "ascBuildId": build["id"], "cloudRunId": run_id, "workflowId": workflow["id"],
                  "internalBuildState": state, "group": group, "ciGates": gates,
                  "deviceInstallSmokeTest": "Requires a real device; API availability does not prove installation."}, args.report)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ReleaseError, KeyError) as exc:
        print("Release stopped: " + str(exc), file=sys.stderr)
        sys.exit(1)
