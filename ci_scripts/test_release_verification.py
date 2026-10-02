"""Release verifier fixtures exercise identity, terminal errors, and retry safety."""

import unittest
from unittest.mock import Mock, patch

import requests
from release_gates import GateError
from release_gates import check_github_gates as shared_gates
from stamp_release import stamp
from testflight_release import (
    AppleAPI,
    Pending,
    ReleaseError,
    check_github_gates,
    check_tag_sha,
    configure_archive,
    exact_build,
    find_or_start_run,
    group_contains_build,
    observe_cloud,
    selected_group,
    tag_starts_automatically,
    validate_inputs,
)

SHA = "a" * 40


def fixture_build(marketing="0.2.0", number="17", state="VALID", beta="IN_BETA_TESTING", expired=False):
    build = {
        "type": "builds",
        "id": "build-17",
        "attributes": {"version": number, "processingState": state, "expired": expired},
        "relationships": {
            "preReleaseVersion": {"data": {"type": "preReleaseVersions", "id": "version-02"}},
            "buildBetaDetail": {"data": {"type": "buildBetaDetails", "id": "beta-17"}},
        },
    }
    included = {
        ("preReleaseVersions", "version-02"): {"attributes": {"version": marketing}},
        ("buildBetaDetails", "beta-17"): {"attributes": {"internalBuildState": beta}},
    }
    api = Mock()
    api.collection.return_value = ([build], included)
    return api


def fixture_run(sha=SHA, progress="COMPLETE", status="SUCCEEDED", ref="tag-02"):
    api = Mock()
    api.get.return_value = {
        "data": {
            "id": "run-17",
            "attributes": {
                "sourceCommit": {"commitSha": sha},
                "executionProgress": progress,
                "completionStatus": status,
            },
            "relationships": {"sourceBranchOrTag": {"data": {"id": ref, "type": "scmGitReferences"}}},
        }
    }
    return api


class ExactBuildTests(unittest.TestCase):
    def test_matches_marketing_version_and_build_number_separately(self):
        build, state = exact_build(fixture_build(), "app", "0.2.0", "17")
        self.assertEqual(build["id"], "build-17")
        self.assertEqual(state, "IN_BETA_TESTING")

    def test_marketing_mismatch_cannot_pass(self):
        with self.assertRaises(Pending):
            exact_build(fixture_build(marketing="0.1.13"), "app", "0.2.0", "17")

    def test_build_number_mismatch_cannot_pass(self):
        with self.assertRaises(Pending):
            exact_build(fixture_build(number="16"), "app", "0.2.0", "17")

    def test_processing_retries(self):
        with self.assertRaises(Pending):
            exact_build(fixture_build(state="PROCESSING"), "app", "0.2.0", "17")

    def test_invalid_and_failed_do_not_retry(self):
        for state in ["FAILED", "INVALID"]:
            with self.subTest(state=state), self.assertRaises(ReleaseError):
                exact_build(fixture_build(state=state), "app", "0.2.0", "17")

    def test_expired_build_cannot_pass(self):
        with self.assertRaises(ReleaseError):
            exact_build(fixture_build(expired=True), "app", "0.2.0", "17")

    def test_export_compliance_blocks_release(self):
        for state in ["MISSING_EXPORT_COMPLIANCE", "IN_EXPORT_COMPLIANCE_REVIEW"]:
            with self.subTest(state=state), self.assertRaises(ReleaseError):
                exact_build(fixture_build(beta=state), "app", "0.2.0", "17")

    def test_unknown_beta_state_does_not_pass(self):
        with self.assertRaises(Pending):
            exact_build(fixture_build(beta="PROCESSING"), "app", "0.2.0", "17")

    def test_ambiguous_build_does_not_pass(self):
        api = fixture_build()
        builds, included = api.collection.return_value
        api.collection.return_value = (builds * 2, included)
        with self.assertRaises(ReleaseError):
            exact_build(api, "app", "0.2.0", "17")


class CloudIdentityTests(unittest.TestCase):
    def test_wrong_source_sha_fails(self):
        with self.assertRaises(ReleaseError):
            observe_cloud(fixture_run(sha="b" * 40), "run-17", SHA, "tag-02")

    def test_wrong_tag_link_fails(self):
        with self.assertRaises(ReleaseError):
            observe_cloud(fixture_run(ref="old-tag"), "run-17", SHA, "tag-02")

    def test_completed_run_without_source_sha_cannot_pass(self):
        api = fixture_run()
        del api.get.return_value["data"]["attributes"]["sourceCommit"]
        with self.assertRaisesRegex(ReleaseError, "must report the exact tested"):
            observe_cloud(api, "run-17", SHA, "tag-02")

    def test_completed_run_with_null_source_sha_cannot_pass(self):
        api = fixture_run()
        api.get.return_value["data"]["attributes"]["sourceCommit"] = None
        with self.assertRaises(ReleaseError):
            observe_cloud(api, "run-17", SHA, "tag-02")

    def test_incomplete_run_without_source_sha_remains_pending(self):
        api = fixture_run(status=None, progress="RUNNING")
        del api.get.return_value["data"]["attributes"]["sourceCommit"]
        with self.assertRaises(Pending):
            observe_cloud(api, "run-17", SHA, "tag-02")

    def test_failed_cloud_run_does_not_retry(self):
        with self.assertRaises(ReleaseError):
            observe_cloud(fixture_run(status="FAILED"), "run-17", SHA, "tag-02")

    def test_incomplete_cloud_run_retries(self):
        with self.assertRaises(Pending):
            observe_cloud(fixture_run(status=None, progress="RUNNING"), "run-17", SHA, "tag-02")

    def test_successful_cloud_run_has_tag_and_commit(self):
        self.assertEqual(observe_cloud(fixture_run(), "run-17", SHA, "tag-02")["id"], "run-17")

    def test_existing_cloud_run_is_reused_not_reposted(self):
        api = fixture_run()
        run = api.get.return_value["data"]
        api.collection.return_value = ([run], {})
        self.assertEqual(find_or_start_run(api, "workflow", "tag-02", SHA)["id"], "run-17")
        api.request.assert_not_called()

    def test_failed_existing_run_does_not_blindly_restart(self):
        api = fixture_run(status="FAILED")
        api.collection.return_value = ([api.get.return_value["data"]], {})
        with self.assertRaises(ReleaseError):
            find_or_start_run(api, "workflow", "tag-02", SHA)
        api.request.assert_not_called()

    def test_automatic_tag_trigger_is_not_duplicated(self):
        api = Mock()
        api.collection.return_value = ([], {})
        with self.assertRaises(Pending):
            find_or_start_run(api, "workflow", "tag-02", SHA, allow_start=False)
        api.request.assert_not_called()

    def test_automatic_tag_prefix_match(self):
        workflow = {
            "attributes": {
                "tagStartCondition": {"source": {"isAllMatch": False, "patterns": [{"pattern": "v", "isPrefix": True}]}}
            }
        }
        self.assertTrue(tag_starts_automatically(workflow, "v0.2.0"))
        self.assertFalse(tag_starts_automatically(workflow, "candidate-02"))

    def test_external_or_other_app_group_is_rejected(self):
        report = {"groups": [{"id": "external", "internal": False}, {"id": "internal", "internal": True}]}
        for group in ["external", "another-app"]:
            with self.subTest(group=group), self.assertRaises(ReleaseError):
                selected_group(report, group)

    def test_group_membership_is_exact(self):
        api = Mock()
        api.collection.return_value = ([{"id": "old-build"}], {})
        self.assertFalse(group_contains_build(api, "internal", "build-17"))

    def test_configure_preserves_existing_actions(self):
        api = Mock()
        api.request.return_value = {"data": {}}
        action = {"name": "Build", "actionType": "BUILD"}
        workflow = {"id": "w", "attributes": {"actions": [action]}}
        configure_archive(api, workflow)
        patch_body = api.request.call_args.kwargs["body"]
        self.assertEqual(patch_body["data"]["attributes"]["actions"][0], action)
        self.assertEqual(patch_body["data"]["attributes"]["actions"][1]["buildDistributionAudience"], "INTERNAL_ONLY")


class GitHubGateTests(unittest.TestCase):
    def test_all_green_other_sha_cannot_authorize_release(self):
        names = [
            "CI",
            "Python CI Scripts",
            "Workflow Lint",
            "Workflow Security",
            "XcodeGen Drift",
            "SwiftLint",
            "Secret Scan",
        ]
        runs = [
            {
                "id": i,
                "name": name,
                "event": "push",
                "head_branch": "main",
                "head_sha": "b" * 40,
                "conclusion": "success",
                "html_url": "https://example.com",
            }
            for i, name in enumerate(names)
        ]
        with self.assertRaises(GateError):
            shared_gates(SHA, get=lambda path: {"workflow_runs": runs}, repository="owner/repo")

    def test_all_green_pr_cannot_authorize_main(self):
        names = [
            "CI",
            "Python CI Scripts",
            "Workflow Lint",
            "Workflow Security",
            "XcodeGen Drift",
            "SwiftLint",
            "Secret Scan",
        ]
        runs = [
            {
                "id": i,
                "name": name,
                "event": "pull_request",
                "head_branch": "main",
                "head_sha": SHA,
                "conclusion": "success",
                "html_url": "https://example.com",
            }
            for i, name in enumerate(names)
        ]
        with self.assertRaises(GateError):
            shared_gates(SHA, get=lambda path: {"workflow_runs": runs}, repository="owner/repo")

    @patch("testflight_release.os.environ", {"GITHUB_REPOSITORY": "owner/repo"})
    @patch("testflight_release.github_get")
    def test_missing_gates_fail(self, get):
        get.return_value = {"workflow_runs": []}
        with self.assertRaises(ReleaseError):
            check_github_gates(SHA)

    @patch("testflight_release.os.environ", {"GITHUB_REPOSITORY": "owner/repo"})
    @patch("testflight_release.github_get")
    def test_old_green_run_cannot_mask_new_failure(self, get):
        names = [
            "CI",
            "Python CI Scripts",
            "Workflow Lint",
            "Workflow Security",
            "XcodeGen Drift",
            "SwiftLint",
            "Secret Scan",
        ]
        runs = [
            {
                "id": i,
                "name": name,
                "event": "push",
                "head_branch": "main",
                "head_sha": SHA,
                "conclusion": "success",
                "html_url": "https://example.com",
            }
            for i, name in enumerate(names)
        ]
        runs.append(
            {"id": 99, "name": "CI", "event": "push", "head_branch": "main", "head_sha": SHA, "conclusion": "failure"}
        )
        get.return_value = {"workflow_runs": runs}
        with self.assertRaises(ReleaseError):
            check_github_gates(SHA)

    @patch("testflight_release.os.environ", {"GITHUB_REPOSITORY": "owner/repo"})
    @patch("testflight_release.github_get")
    def test_moved_tag_fails(self, get):
        get.return_value = {"object": {"type": "commit", "sha": "b" * 40}}
        with self.assertRaises(ReleaseError):
            check_tag_sha("v0.2.0", SHA)

    @patch("testflight_release.os.environ", {"GITHUB_REPOSITORY": "owner/repo"})
    @patch("testflight_release.github_get")
    def test_annotated_tag_is_peeled(self, get):
        get.side_effect = [{"object": {"type": "tag", "sha": "tag-object"}}, {"object": {"type": "commit", "sha": SHA}}]
        check_tag_sha("v0.2.0", SHA)


class TransportTests(unittest.TestCase):
    env = {
        "APP_STORE_CONNECT_ISSUER_ID": "fixture",
        "APP_STORE_CONNECT_KEY_ID": "fixture",
        "APP_STORE_CONNECT_PRIVATE_KEY": "fixture",
    }

    @patch("testflight_release.os.environ", env)
    @patch("testflight_release.jwt.encode", return_value="fixture-jwt")
    def test_403_agreement_is_terminal_and_sanitized(self, _encode):
        api = AppleAPI()
        response = Mock(ok=False, status_code=403)
        response.json.return_value = {
            "errors": [
                {"code": "FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED", "detail": "sensitive detail fixture"}
            ]
        }
        api.session.request = Mock(return_value=response)
        with self.assertRaisesRegex(ReleaseError, "FORBIDDEN.REQUIRED_AGREEMENTS") as error:
            api.get("/v1/apps/app")
        self.assertNotIn("sensitive", str(error.exception))
        self.assertEqual(api.session.request.call_count, 1)

    @patch("testflight_release.os.environ", env)
    @patch("testflight_release.jwt.encode", return_value="fixture-jwt")
    def test_unknown_post_outcome_does_not_duplicate(self, _encode):
        api = AppleAPI()
        api.session.request = Mock(side_effect=requests.Timeout())
        with self.assertRaisesRegex(ReleaseError, "outcome unknown"):
            api.request("POST", "/v1/ciBuildRuns", body={})
        self.assertEqual(api.session.request.call_count, 1)

    def test_pagination_link_cannot_leak_bearer_token(self):
        api = AppleAPI()
        api.session.request = Mock()
        with self.assertRaises(ReleaseError):
            api.get("https://attacker.invalid/collect")
        api.session.request.assert_not_called()

    @patch("testflight_release.os.environ", env)
    @patch("testflight_release.jwt.encode", return_value="fixture-jwt")
    @patch("testflight_release.time.sleep")
    def test_retryable_get_is_retried(self, _sleep, _encode):
        api = AppleAPI()
        response = Mock(ok=False, status_code=503, headers={})
        good = Mock(ok=True, content=b"{}")
        good.json.return_value = {"data": []}
        api.session.request = Mock(side_effect=[response, good])
        self.assertEqual(api.get("/v1/builds"), {"data": []})
        self.assertEqual(api.session.request.call_count, 2)

    def test_pagination_collects_all_pages(self):
        api = AppleAPI()
        api.get = Mock(
            side_effect=[{"data": [{"id": "1"}], "links": {"next": "/v1/builds?page=2"}}, {"data": [{"id": "2"}]}]
        )
        self.assertEqual([r["id"] for r in api.collection("/v1/builds")[0]], ["1", "2"])


class VersionStampTests(unittest.TestCase):
    source = "settings:\n    MARKETING_VERSION: 0.1.0-dev\n    CURRENT_PROJECT_VERSION: 1\n"

    def test_tag_and_cloud_number_stamp(self):
        output = stamp(self.source, "v0.2.0", "17")
        self.assertIn("MARKETING_VERSION: 0.2.0", output)
        self.assertIn("CURRENT_PROJECT_VERSION: 17", output)

    def test_malformed_tags_rejected(self):
        for tag in ["v0.2.0-dev", "v0.2", "v00.2.0", "v0.2.0\nOTHER: injected", "0.2.0"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                stamp(self.source, tag, "17")

    def test_nonpositive_or_injected_build_number_rejected(self):
        for number in ["0", "-1", "01", "17\nOTHER: injected"]:
            with self.subTest(number=number), self.assertRaises(ValueError):
                stamp(self.source, "v0.2.0", number)

    def test_duplicate_version_keys_rejected(self):
        with self.assertRaises(ValueError):
            stamp(self.source + self.source, "v0.2.0", "17")

    def test_source_tag_version_must_match(self):
        with self.assertRaises(ReleaseError):
            validate_inputs("0.2.0", SHA, "v0.1.13")


if __name__ == "__main__":
    unittest.main()
