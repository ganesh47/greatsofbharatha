# DevSecOps

## GitHub Actions hardening

All third-party `uses:` entries in `.github/workflows/*.yml` should be pinned to a full commit SHA. Keep the resolved version tag as an inline comment, for example `# v6.0.2`, so reviewers can understand what release the SHA represents.

Dependabot remains the update path for GitHub Actions. The existing `.github/dependabot.yml` `github-actions` ecosystem entry should open weekly PRs; review those PRs, confirm the new upstream release is appropriate, and merge the SHA update with the version comment refreshed.

`workflow-security.yml` runs zizmor against the repository's workflow definitions. zizmor is a static analyzer for GitHub Actions security issues such as risky triggers, token exposure, and supply-chain weaknesses. Its results are uploaded to code scanning when GitHub Advanced Security or public-repository code scanning support is available.

Exceptions to SHA pinning should be rare. Document the reason in the workflow near the `uses:` line when a ref cannot be pinned without breaking the workflow, such as a trusted local reusable workflow, a temporary upstream incident workaround, or a GitHub-owned action that must deliberately track a moving ref for compatibility.
