#!/usr/bin/env python3
"""Sync TestFlight feedback from App Store Connect into GitHub issues."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any

import jwt


APP_STORE_CONNECT_API_BASE = "https://api.appstoreconnect.apple.com"
GITHUB_API_BASE = "https://api.github.com"
DEFAULT_ISSUE_LABELS = ["source:testflight", "type:feedback"]
CRASH_ISSUE_LABELS = ["source:testflight", "type:bug"]
LABEL_COLORS = {
    "source:testflight": "0e8a16",
    "type:feedback": "1d76db",
    "type:bug": "d73a4a",
}


@dataclass(frozen=True)
class Config:
    asc_app_id: str
    asc_issuer_id: str
    asc_key_id: str
    asc_private_key: str
    github_token: str
    github_repository: str


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def load_config() -> Config:
    return Config(
        asc_app_id=require_env("APP_STORE_CONNECT_APP_ID"),
        asc_issuer_id=require_env("APP_STORE_CONNECT_ISSUER_ID"),
        asc_key_id=require_env("APP_STORE_CONNECT_KEY_ID"),
        asc_private_key=require_env("APP_STORE_CONNECT_PRIVATE_KEY").replace("\\n", "\n"),
        github_token=require_env("GITHUB_TOKEN"),
        github_repository=require_env("GITHUB_REPOSITORY"),
    )


def build_asc_token(config: Config) -> str:
    now = int(time.time())
    payload = {
        "iss": config.asc_issuer_id,
        "aud": "appstoreconnect-v1",
        "iat": now,
        "exp": now + 19 * 60,
    }
    headers = {"alg": "ES256", "kid": config.asc_key_id, "typ": "JWT"}
    return jwt.encode(payload, config.asc_private_key, algorithm="ES256", headers=headers)


def request_json(url: str, *, method: str = "GET", headers: dict[str, str] | None = None, payload: dict[str, Any] | None = None) -> Any:
    body = None
    request_headers = {"Accept": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=body, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            content = response.read()
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: {exc.code} {details}") from exc

    if not content:
        return None
    return json.loads(content)


def asc_get(config: Config, path_or_url: str, params: dict[str, str] | None = None) -> Any:
    if path_or_url.startswith("http://") or path_or_url.startswith("https://"):
        url = path_or_url
    else:
        url = f"{APP_STORE_CONNECT_API_BASE}{path_or_url}"
    if params:
        query = urllib.parse.urlencode(params)
        url = f"{url}?{query}"
    return request_json(url, headers={"Authorization": f"Bearer {build_asc_token(config)}"})


def github_request(config: Config, path: str, *, method: str = "GET", payload: dict[str, Any] | None = None) -> Any:
    return request_json(
        f"{GITHUB_API_BASE}{path}",
        method=method,
        payload=payload,
        headers={
            "Authorization": f"Bearer {config.github_token}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )


def ensure_labels(config: Config, labels: list[str]) -> None:
    for label in labels:
        try:
            github_request(
                config,
                f"/repos/{config.github_repository}/labels",
                method="POST",
                payload={"name": label, "color": LABEL_COLORS.get(label, "ededed")},
            )
        except RuntimeError as exc:
            if "already_exists" in str(exc) or "Validation Failed" in str(exc):
                continue
            raise


def fetch_feedback_collection(config: Config, only_kind: str | None = None) -> list[dict[str, Any]]:
    path = "/v1/betaFeedbackCrashSubmissions" if only_kind == "crash" else "/v1/betaTesterFeedbacks"
    params = {"include": "build", "limit": "200", "sort": "-createdDate"}
    items: list[dict[str, Any]] = []
    next_url: str | None = path

    while next_url:
        response = asc_get(config, next_url, params if next_url == path else None)
        included = response.get("included", [])
        included_map = {(entry["type"], entry["id"]): entry for entry in included}
        for entry in response.get("data", []):
            entry["_included_map"] = included_map
            items.append(entry)
        next_url = response.get("links", {}).get("next")

    return items


def get_related_resource(feedback: dict[str, Any], relationship_name: str) -> dict[str, Any] | None:
    relation = feedback.get("relationships", {}).get(relationship_name, {})
    related = relation.get("data")
    if not related:
        return None
    return feedback.get("_included_map", {}).get((related["type"], related["id"]))


def issue_exists(config: Config, feedback_id: str) -> bool:
    query = urllib.parse.quote(f'repo:{config.github_repository} is:issue "ASC Feedback ID: {feedback_id}"')
    result = github_request(config, f"/search/issues?q={query}")
    return result.get("total_count", 0) > 0


def first_non_empty(*values: Any) -> str | None:
    for value in values:
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def redact_for_privacy(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    trimmed = value.strip()
    if not trimmed:
        return None
    lowered = trimmed.lower()
    if "@" in trimmed or any(token in lowered for token in ["iphone", "ipad", "ios ", "ipados", "device", "serial", "identifier", "email"]):
        return "_redacted for privacy_"
    return trimmed


def build_issue_payload(feedback: dict[str, Any], *, crash_only: bool) -> tuple[str, str, list[str]]:
    feedback_id = feedback["id"]
    attrs = feedback.get("attributes", {})
    build = get_related_resource(feedback, "build") or {}
    build_attrs = build.get("attributes", {})
    build_number = first_non_empty(build_attrs.get("version"))
    kind = "crash" if crash_only else "feedback"
    title = f"TestFlight {kind} {feedback_id}"
    if build_number:
        title += f" (build {build_number})"

    body_lines = [
        f"ASC Feedback ID: {feedback_id}",
        f"Kind: {kind}",
        f"Build number: {build_number or '_unknown_'}",
        f"App version: {first_non_empty(attrs.get('appVersion'), build_attrs.get('appVersionString')) or '_unknown_'}",
    ]

    comment = redact_for_privacy(first_non_empty(attrs.get("comment"), attrs.get("text"), attrs.get("crashReason")))
    if comment:
        body_lines.extend(["", "Feedback summary", comment])

    body_lines.extend([
        "",
        "Privacy note",
        "Sensitive tester/device-identifying details are intentionally redacted from synced issues.",
    ])

    labels = CRASH_ISSUE_LABELS if crash_only else DEFAULT_ISSUE_LABELS
    return title, "\n".join(body_lines), labels


def create_issue(config: Config, title: str, body: str, labels: list[str]) -> None:
    ensure_labels(config, labels)
    github_request(
        config,
        f"/repos/{config.github_repository}/issues",
        method="POST",
        payload={"title": title, "body": body, "labels": labels},
    )


def main() -> int:
    config = load_config()
    crash_only = os.environ.get("TESTFLIGHT_FEEDBACK_ONLY_KIND", "").strip().lower() == "crash"
    try:
        feedback_items = fetch_feedback_collection(config, only_kind="crash" if crash_only else None)
    except RuntimeError as exc:
        message = str(exc)
        if "404" in message and "does not match a defined resource type" in message:
            print("TestFlight feedback endpoint is unavailable for this app/API context, skipping sync without failure.")
            return 0
        raise
    created = 0
    for feedback in feedback_items:
        feedback_id = feedback["id"]
        if issue_exists(config, feedback_id):
            continue
        title, body, labels = build_issue_payload(feedback, crash_only=crash_only)
        create_issue(config, title, body, labels)
        created += 1
        print(f"Created issue for feedback {feedback_id}")
    print(f"Done, created {created} issue(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
