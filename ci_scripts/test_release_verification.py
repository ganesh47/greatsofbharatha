"""Release verifier fixtures exercise identity, terminal errors, and retry safety."""

import unittest
from unittest.mock import Mock, patch

import jwt
import requests
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
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
    ensure_tv_workflow,
    exact_build,
    find_or_start_run,
    group_contains_build,
    has_archive,
    observe_cloud,
    platform_config,
    selected_group,
    tag_starts_automatically,
    validate_inputs,
    validate_release_workflow,
)

SHA = "a" * 40


def fixture_build(marketing="0.2.0", number="17", state="VALID", beta="IN_BETA_TESTING", expired=False, platform="IOS"):
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
        ("preReleaseVersions", "version-02"): {"attributes": {"version": marketing, "platform": platform}},
        ("buildBetaDetails", "beta-17"): {"attributes": {"internalBuildState": beta}},
    }
    api = Mock()
    api.collection.return_value = ([build], included)
    return api


def fixture_archive(platform="TVOS"):
    return {
        "name": "Archive for TestFlight",
        "actionType": "ARCHIVE",
        "platform": platform,
        "scheme": "GreatsOfBharathaTV" if platform == "TVOS" else "GreatsOfBharatha",
        "destination": "ANY_TVOS_DEVICE" if platform == "TVOS" else "ANY_IOS_DEVICE",
        "isRequiredToPass": True,
        "buildDistributionAudience": "INTERNAL_ONLY",
    }


def fixture_gate_runs(include_tv=False):
    names = [
        "CI",
        "Python CI Scripts",
        "Workflow Lint",
        "Workflow Security",
        "XcodeGen Drift",
        "SwiftLint",
        "Secret Scan",
    ]
    if include_tv:
        names.append("tvOS")
    return [
        {
            "id": i,
            "name": name,
            "event": "push",
            "head_branch": "main",
            "head_sha": SHA,
            "status": "completed",
            "conclusion": "success",
            "html_url": "https://example.com/run/" + str(i),
        }
        for i, name in enumerate(names)
    ]


def fixture_workflow_seed():
    return {
        "id": "ios-workflow",
        "attributes": {
            "name": "Default",
            "containerFilePath": "GreatsOfBharatha.xcodeproj",
            "actions": [fixture_archive("IOS")],
            "tagStartCondition": {"source": {"isAllMatch": False, "patterns": [{"pattern": "v", "isPrefix": True}]}},
        },
        "relationships": {
            "product": {"data": {"type": "ciProducts", "id": "same-app-product"}},
            "repository": {"data": {"type": "scmRepositories", "id": "same-repository"}},
            "xcodeVersion": {"data": {"type": "ciXcodeVersions", "id": "selected-xcode"}},
            "macOsVersion": {"data": {"type": "ciMacOsVersions", "id": "selected-macos"}},
        },
    }


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


class TVBuildIdentityTests(unittest.TestCase):
    def test_ready_tv_build_requires_explicit_prerelease_tv_os(self):
        build, state = exact_build(fixture_build(platform="TV_OS"), "app", "0.2.0", "17", platform="TVOS")
        self.assertEqual(build["id"], "build-17")
        self.assertEqual(state, "IN_BETA_TESTING")

    def test_identical_ios_version_and_number_cannot_satisfy_tv_release(self):
        with self.assertRaises(Pending):
            exact_build(fixture_build(), "app", "0.2.0", "17", platform="TVOS")

    def test_tv_build_cannot_satisfy_default_ios_release(self):
        with self.assertRaises(Pending):
            exact_build(fixture_build(platform="TV_OS"), "app", "0.2.0", "17")

    def test_missing_null_or_cloud_platform_spelling_cannot_pass(self):
        for platform in [None, "TVOS", "MAC_OS"]:
            with self.subTest(platform=platform), self.assertRaises(Pending):
                exact_build(fixture_build(platform=platform), "app", "0.2.0", "17", platform="TVOS")
        api = fixture_build(platform="TV_OS")
        del api.collection.return_value[1][("preReleaseVersions", "version-02")]["attributes"]["platform"]
        with self.assertRaises(Pending):
            exact_build(api, "app", "0.2.0", "17", platform="TVOS")

    def test_same_number_on_two_platforms_selects_only_requested_platform(self):
        api = fixture_build()
        ios_builds, included = api.collection.return_value
        tv_builds, tv_included = fixture_build(platform="TV_OS").collection.return_value
        tv_builds[0]["id"] = "build-tv-17"
        tv_builds[0]["relationships"]["preReleaseVersion"]["data"]["id"] = "version-tv"
        included[("preReleaseVersions", "version-tv")] = tv_included[("preReleaseVersions", "version-02")]
        api.collection.return_value = (ios_builds + tv_builds, included)
        self.assertEqual(exact_build(api, "app", "0.2.0", "17", platform="TVOS")[0]["id"], "build-tv-17")
        self.assertEqual(exact_build(api, "app", "0.2.0", "17")[0]["id"], "build-17")

    def test_duplicate_tv_build_is_terminal_even_with_an_ios_match(self):
        api = fixture_build(platform="TV_OS")
        builds, included = api.collection.return_value
        api.collection.return_value = (builds * 2, included)
        with self.assertRaises(ReleaseError):
            exact_build(api, "app", "0.2.0", "17", platform="TVOS")

    def test_tv_identity_does_not_bypass_processing_expiry_or_compliance(self):
        for kwargs in [
            {"state": "FAILED"},
            {"state": "INVALID"},
            {"expired": True},
            {"beta": "MISSING_EXPORT_COMPLIANCE"},
        ]:
            with self.subTest(kwargs=kwargs), self.assertRaises(ReleaseError):
                exact_build(fixture_build(platform="TV_OS", **kwargs), "app", "0.2.0", "17", platform="TVOS")
        with self.assertRaises(Pending):
            exact_build(fixture_build(platform="TV_OS", state="PROCESSING"), "app", "0.2.0", "17", platform="TVOS")

    def test_unknown_release_platform_fails_before_api_lookup(self):
        api = fixture_build(platform="TV_OS")
        with self.assertRaises(ReleaseError):
            exact_build(api, "app", "0.2.0", "17", platform="TV_OS")
        api.collection.assert_not_called()


class TVArchiveTests(unittest.TestCase):
    def test_publish_rejects_mixed_platform_workflow_even_with_valid_tv_archive(self):
        workflow = {"attributes": {"isEnabled": True, "actions": [fixture_archive(), fixture_archive("IOS")]}}
        with self.assertRaisesRegex(ReleaseError, "TV-only"):
            validate_release_workflow(workflow, "TVOS")

    def test_publish_rejects_disabled_or_noncanonical_tv_workflow(self):
        for attrs in [
            {"isEnabled": False, "actions": [fixture_archive()]},
            {"isEnabled": True, "actions": [fixture_archive("IOS")]},
            {"isEnabled": True, "actions": []},
        ]:
            with self.subTest(attrs=attrs), self.assertRaises(ReleaseError):
                validate_release_workflow({"attributes": attrs}, "TVOS")

    def test_publish_accepts_enabled_canonical_tv_only_workflow(self):
        validate_release_workflow({"attributes": {"isEnabled": True, "actions": [fixture_archive()]}}, "TVOS")

    def test_ios_default_workflow_validation_remains_compatible(self):
        validate_release_workflow({"attributes": {"isEnabled": True, "actions": [fixture_archive("IOS")]}}, "IOS")

    def test_tv_archive_has_tv_scheme_and_internal_required_distribution(self):
        api = Mock()
        api.request.return_value = {"data": {}}
        configure_archive(api, {"id": "w", "attributes": {"actions": []}}, platform="TVOS")
        action = api.request.call_args.kwargs["body"]["data"]["attributes"]["actions"][0]
        self.assertEqual(action["actionType"], "ARCHIVE")
        self.assertEqual(action["platform"], "TVOS")
        self.assertEqual(action["scheme"], "GreatsOfBharathaTV")
        self.assertEqual(action["destination"], "ANY_TVOS_DEVICE")
        self.assertEqual(action["buildDistributionAudience"], "INTERNAL_ONLY")
        self.assertIs(action["isRequiredToPass"], True)

    def test_configure_tv_preserves_existing_ios_and_build_actions(self):
        api = Mock()
        api.request.return_value = {"data": {}}
        previous = [fixture_archive("IOS"), {"name": "Build", "actionType": "BUILD"}]
        configure_archive(api, {"id": "w", "attributes": {"actions": previous}}, platform="TVOS")
        actions = api.request.call_args.kwargs["body"]["data"]["attributes"]["actions"]
        self.assertEqual(actions[:2], previous)
        self.assertEqual(len(actions), 3)
        self.assertTrue(has_archive({"attributes": {"actions": actions}}, "TVOS"))

    def test_existing_valid_tv_archive_is_not_duplicated(self):
        for destination in ["ANY_TVOS_DEVICE", None]:
            with self.subTest(destination=destination):
                api = Mock()
                api.request.return_value = {"data": {}}
                action = fixture_archive()
                action["destination"] = destination
                workflow = {"id": "w", "attributes": {"actions": [action]}}
                self.assertTrue(has_archive(workflow, "TVOS"))
                configure_archive(api, workflow, platform="TVOS")
                actions = api.request.call_args.kwargs["body"]["data"]["attributes"]["actions"]
                self.assertEqual(actions, [action])

    def test_wrong_platform_scheme_destination_or_audience_is_not_accepted(self):
        invalid_fields = [
            ("platform", "IOS"),
            ("scheme", "GreatsOfBharatha"),
            ("destination", "ANY_IOS_DEVICE"),
            ("destination", "ANY_TVOS_SIMULATOR"),
            ("buildDistributionAudience", "APP_STORE_ELIGIBLE"),
            ("buildDistributionAudience", None),
            ("isRequiredToPass", False),
        ]
        for name, value in invalid_fields:
            with self.subTest(name=name, value=value):
                action = fixture_archive()
                action[name] = value
                self.assertFalse(has_archive({"attributes": {"actions": [action]}}, "TVOS"))

    def test_locked_workflow_cannot_be_reconfigured(self):
        api = Mock()
        with self.assertRaises(ReleaseError):
            configure_archive(api, {"id": "w", "attributes": {"isLockedForEditing": True}}, platform="TVOS")
        api.request.assert_not_called()

    def test_platform_names_are_distinct_between_cloud_and_prerelease(self):
        self.assertEqual(platform_config("TVOS")["prerelease"], "TV_OS")
        self.assertEqual(platform_config("IOS")["prerelease"], "IOS")
        with self.assertRaises(ReleaseError):
            platform_config("TV_OS")


class TVWorkflowCreationTests(unittest.TestCase):
    def test_creates_only_tv_action_from_same_product_repository_and_toolchain(self):
        api = Mock()
        api.request.return_value = {"data": {"id": "new-tv-workflow"}}
        seed = fixture_workflow_seed()
        report = {"products": [{"id": "same-app-product", "workflows": [{"id": seed["id"], "name": "Default"}]}]}
        result = ensure_tv_workflow(api, report, seed)
        self.assertEqual(result["id"], "new-tv-workflow")
        self.assertEqual(api.request.call_args.args, ("POST", "/v1/ciWorkflows"))
        data = api.request.call_args.kwargs["body"]["data"]
        self.assertEqual(data["type"], "ciWorkflows")
        self.assertEqual(data["relationships"], seed["relationships"])
        attrs = data["attributes"]
        self.assertEqual(attrs["name"], "Apple TV TestFlight")
        self.assertEqual(attrs["containerFilePath"], "GreatsOfBharatha.xcodeproj")
        self.assertIs(attrs["clean"], True)
        self.assertIs(attrs["isEnabled"], True)
        self.assertEqual(len(attrs["actions"]), 1)
        self.assertTrue(has_archive({"attributes": attrs}, "TVOS"))
        self.assertNotIn("tagStartCondition", attrs)
        self.assertNotIn("branchStartCondition", attrs)
        self.assertNotIn("pullRequestStartCondition", attrs)
        self.assertEqual(
            attrs["manualTagStartCondition"]["source"],
            {"isAllMatch": False, "patterns": [{"pattern": "tvos-v", "isPrefix": True}]},
        )
        self.assertEqual(seed["attributes"]["actions"], [fixture_archive("IOS")])
        self.assertTrue(tag_starts_automatically(seed, "v0.2.1"))
        self.assertFalse(tag_starts_automatically(seed, "tvos-v0.2.1"))

    def test_unique_existing_tv_workflow_is_reused_without_post(self):
        api = Mock()
        workflow = {"id": "tv-existing", "attributes": {"actions": [fixture_archive()]}}
        api.get.return_value = {"data": workflow}
        api.request.return_value = {"data": workflow}
        report = {"products": [{"workflows": [{"id": "tv-existing", "name": "Apple TV TestFlight"}]}]}
        self.assertEqual(ensure_tv_workflow(api, report, fixture_workflow_seed())["id"], "tv-existing")
        api.get.assert_called_once_with(
            "/v1/ciWorkflows/tv-existing", {"include": "repository,product,xcodeVersion,macOsVersion"}
        )
        self.assertEqual(api.request.call_count, 1)
        self.assertEqual(api.request.call_args.args, ("PATCH", "/v1/ciWorkflows/tv-existing"))
        self.assertEqual(api.request.call_args.kwargs["body"]["data"]["attributes"]["actions"], [fixture_archive()])

    def test_duplicate_named_tv_workflows_fail_before_mutation(self):
        api = Mock()
        report = {
            "products": [{"workflows": [{"id": name, "name": "Apple TV TestFlight"} for name in ["tv-1", "tv-2"]]}]
        }
        with self.assertRaises(ReleaseError):
            ensure_tv_workflow(api, report, fixture_workflow_seed())
        api.request.assert_not_called()
        api.get.assert_not_called()

    def test_existing_tv_name_with_ios_action_is_not_repaired_or_uploaded(self):
        api = Mock()
        api.get.return_value = {"data": {"id": "tv-existing", "attributes": {"actions": [fixture_archive("IOS")]}}}
        report = {"products": [{"workflows": [{"id": "tv-existing", "name": "Apple TV TestFlight"}]}]}
        with self.assertRaises(ReleaseError):
            ensure_tv_workflow(api, report, fixture_workflow_seed())
        api.request.assert_not_called()

    def test_missing_or_mistyped_seed_identity_fails_without_creation(self):
        for relationship in ["product", "repository", "xcodeVersion", "macOsVersion"]:
            for mutation in ["missing", "wrong-type", "empty-id"]:
                with self.subTest(relationship=relationship, mutation=mutation):
                    seed = fixture_workflow_seed()
                    data = seed["relationships"][relationship]["data"]
                    if mutation == "missing":
                        del seed["relationships"][relationship]
                    elif mutation == "wrong-type":
                        data["type"] = "wrongResource"
                    else:
                        data["id"] = ""
                    api = Mock()
                    with self.assertRaises(ReleaseError):
                        ensure_tv_workflow(api, {"products": []}, seed)
                    api.request.assert_not_called()

    def test_unexpected_seed_project_fails_without_creation(self):
        seed = fixture_workflow_seed()
        seed["attributes"]["containerFilePath"] = "OtherApp.xcodeproj"
        api = Mock()
        with self.assertRaises(ReleaseError):
            ensure_tv_workflow(api, {"products": []}, seed)
        api.request.assert_not_called()


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

    def test_tv_tag_does_not_trigger_existing_ios_version_prefix(self):
        ios_workflow = {
            "attributes": {
                "tagStartCondition": {"source": {"isAllMatch": False, "patterns": [{"pattern": "v", "isPrefix": True}]}}
            }
        }
        self.assertFalse(tag_starts_automatically(ios_workflow, "tvos-v0.2.1"))
        tv_workflow = {
            "attributes": {
                "tagStartCondition": {
                    "source": {"isAllMatch": False, "patterns": [{"pattern": "tvos-v", "isPrefix": True}]}
                }
            }
        }
        self.assertTrue(tag_starts_automatically(tv_workflow, "tvos-v0.2.1"))
        self.assertFalse(tag_starts_automatically(tv_workflow, "v0.2.1"))

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
    def test_default_ios_retains_all_seven_existing_gates(self):
        runs = fixture_gate_runs()
        result = shared_gates(SHA, get=lambda path: {"workflow_runs": runs}, repository="owner/repo")
        self.assertEqual(len(result), 7)

    def test_ios_only_green_cannot_authorize_tv_release(self):
        with self.assertRaisesRegex(GateError, "tvOS"):
            shared_gates(
                SHA, get=lambda path: {"workflow_runs": fixture_gate_runs()}, repository="owner/repo", platform="TVOS"
            )

    def test_all_eight_exact_main_gates_authorize_tv_release(self):
        result = shared_gates(
            SHA,
            get=lambda path: {"workflow_runs": fixture_gate_runs(include_tv=True)},
            repository="owner/repo",
            platform="TVOS",
        )
        self.assertEqual(len(result), 8)
        self.assertIn("tvOS", result)

    def test_wrong_sha_pr_or_branch_tv_run_cannot_authorize_release(self):
        for field, value in [("head_sha", "b" * 40), ("event", "pull_request"), ("head_branch", "codex/tv")]:
            with self.subTest(field=field), self.assertRaises(GateError):
                runs = fixture_gate_runs(include_tv=True)
                runs[-1][field] = value
                shared_gates(SHA, get=lambda path: {"workflow_runs": runs}, repository="owner/repo", platform="TVOS")

    def test_latest_tv_failure_cannot_be_masked_by_older_green(self):
        runs = fixture_gate_runs(include_tv=True)
        runs.append({**runs[-1], "id": 99, "conclusion": "failure"})
        with self.assertRaises(GateError):
            shared_gates(SHA, get=lambda path: {"workflow_runs": runs}, repository="owner/repo", platform="TVOS")

    def test_green_tv_does_not_bypass_a_failed_base_gate(self):
        runs = fixture_gate_runs(include_tv=True)
        runs[0]["conclusion"] = "failure"
        with self.assertRaises(GateError):
            shared_gates(SHA, get=lambda path: {"workflow_runs": runs}, repository="owner/repo", platform="TVOS")

    @patch("testflight_release.os.environ", {"GITHUB_REPOSITORY": "owner/repo"})
    @patch("testflight_release.github_get")
    def test_release_wrapper_passes_tv_platform_to_shared_gates(self, get):
        get.return_value = {"workflow_runs": fixture_gate_runs()}
        with self.assertRaisesRegex(ReleaseError, "tvOS"):
            check_github_gates(SHA, platform="TVOS")
        get.return_value = {"workflow_runs": fixture_gate_runs(include_tv=True)}
        self.assertEqual(len(check_github_gates(SHA, platform="TVOS")), 8)

    def test_unknown_gate_platform_cannot_fall_back_to_ios(self):
        with self.assertRaises(GateError):
            shared_gates(
                SHA, get=lambda path: {"workflow_runs": fixture_gate_runs()}, repository="owner/repo", platform="TV_OS"
            )

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


class ES256TokenTests(unittest.TestCase):
    def test_actual_apple_token_can_be_signed_and_verified(self):
        # Ephemeral fixture key; no account credentials are read or printed.
        key = ec.generate_private_key(ec.SECP256R1())
        private = key.private_bytes(
            serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
        ).decode()
        api = AppleAPI()
        response = Mock(ok=True, content=b"{}")
        response.json.return_value = {"data": []}
        api.session.request = Mock(return_value=response)
        with patch.dict(
            "testflight_release.os.environ",
            {
                "APP_STORE_CONNECT_ISSUER_ID": "fixture-issuer",
                "APP_STORE_CONNECT_KEY_ID": "fixture-key",
                "APP_STORE_CONNECT_PRIVATE_KEY": private,
            },
        ):
            api.get("/v1/builds")
        authorization = api.session.request.call_args.kwargs["headers"]["Authorization"]
        token = authorization.removeprefix("Bearer ")
        claims = jwt.decode(
            token, key.public_key(), algorithms=["ES256"], audience="appstoreconnect-v1", issuer="fixture-issuer"
        )
        self.assertEqual(claims["exp"] - claims["iat"], 600)
        self.assertEqual(jwt.get_unverified_header(token)["kid"], "fixture-key")


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

    def test_tv_tag_stamps_shared_version_without_platform_prefix(self):
        output = stamp(self.source, "tvos-v0.2.1", "21")
        self.assertIn("MARKETING_VERSION: 0.2.1", output)
        self.assertIn("CURRENT_PROJECT_VERSION: 21", output)
        self.assertNotIn("tvos-v", output)

    def test_tv_tag_requires_exact_requested_version_and_tv_platform(self):
        validate_inputs("0.2.1", SHA, "tvos-v0.2.1", platform="TVOS")
        for tag in ["v0.2.1", "tvos-v0.2.0"]:
            with self.subTest(tag=tag), self.assertRaises(ReleaseError):
                validate_inputs("0.2.1", SHA, tag, platform="TVOS")
        with self.assertRaises(ReleaseError):
            validate_inputs("0.2.1", SHA, "tvos-v0.2.1")

    def test_invalid_tv_tags_and_nonpositive_builds_are_rejected(self):
        for tag in ["tvos-v0.2.1-dev", "tvos-v0.2", "tvos-v00.2.1", "tvos-v0.2.1\nOTHER: injected", "TVOS-v0.2.1"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                stamp(self.source, tag, "21")
        for number in ["0", "-1", "01", "21\nOTHER: injected"]:
            with self.subTest(number=number), self.assertRaises(ValueError):
                stamp(self.source, "tvos-v0.2.1", number)

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
