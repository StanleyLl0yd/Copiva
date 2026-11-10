# GitHub repository security baseline

Re-verify GitHub-hosted controls when checks, credentials, trust boundaries or release automation change. A documented expectation is not proof that a setting is enabled.

## Verified through GitHub API (2026-11-10)

- Public repository; default branch `main` is protected.
- Active branch ruleset `26940387`: PR required, squash-only merge, linear history, conversation resolution, no force-push/deletion and no bypass actors. Zero mandatory human approvals supports the sole maintainer.
- Strict required check `macOS 26 / Swift` is bound to GitHub Actions integration `15368`.
- Merge commits and rebase merges are disabled; squash merges and branch deletion on merge are enabled.
- Active tag ruleset `26948978` covers `refs/tags/v*`, blocks update/deletion and has no bypass actors. Initial tag creation remains allowed. The original audit baseline had no tags or releases; later M0 test publication is tracked in issue #2.
- PR #1 at `9f65daa54a642adcdbb4ccc9bb3dad28c9dc0944` passed macOS CI, Swift CodeQL analysis and the CodeQL PR result. This is evidence of analysis, not a merge-blocking CodeQL rule.
- Private vulnerability reporting is enabled.
- The authenticated account's GitHub-generated noreply address was verified without publishing private profile or email-list data.

## Settings requiring privileged re-verification

The current GitHub App returns HTTP 403 for legacy branch protection, Actions allowed-actions/default-token settings, Dependabot alerts/security updates and CodeQL default-setup configuration. Repository metadata also omits `security_and_analysis`; secret scanning and push protection cannot be independently confirmed through this connection.

Earlier hardening work recorded these settings as enabled. Preserve that historical record, but do not present it as a fresh verification. Keep the M0 exit issue open until required settings are checked with appropriately scoped access. Do not weaken controls or request secret values in chat.

## Workflow and supply-chain rules

- Pin external actions to immutable full commit SHAs with version comments; pin containers by digest. Checkout is pinned to v7.0.1, uses Node 24 and disables credential persistence.
- Workflow permissions default to `{}`; only the build job receives `contents: read`. Do not execute PR code with secrets or write-capable tokens, or add `pull_request_target` without a threat-model review.
- Preserve required-check names and exact-head verification. Verify CI again on the resulting protected-main commit.
- Build/test both the runner's current default toolchain and Xcode 26.0.1 (Swift 6.2), the declared minimum. A future runner-image removal must fail visibly and be addressed without silently dropping minimum-version coverage.
- Review dependency usage, licenses, resolution and vulnerabilities before adding packages. There are no third-party Swift package dependencies.
- Never include real clipboard contents, secrets, private identities or work addresses in fixtures, logs or artifacts.
- The owner explicitly authorized the GitHub profile name for Git metadata on 2026-11-10. Use that profile name and verified GitHub noreply email for new API commits; protected squash merges may use GitHub's verified service committer. Verify resulting metadata without printing private identity values. PR #1 was merged with the authorized profile author, noreply email and verified GitHub committer.

## Evidence and artifact retention

- Ordinary M0 CI produces no uploaded build/test artifacts. The owner-authorized M0 packaging workflow retains its ZIP, checksum, build metadata and release notes for seven days before permanent GitHub Release publication. Keep durable audit decisions and exact SHA/run links in versioned reports and the milestone exit issue.
- Any future diagnostic/test artifact upload must set `retention-days: 7`, use synthetic data only, and exclude clipboard stores and signing material.
- Keep essential release packages, checksums and provenance in GitHub Releases. Do not create routine duplicate CI packages or overwrite published release assets.
- The account's log/artifact retention setting is not readable with this connection; no successful configuration change is claimed.

## Additional protections and release prerequisites

- Add a merge-blocking CodeQL code-scanning rule for medium-or-higher findings after verifying reliable PR analysis and an authorized administrative path. A successful scan alone is not enforcement.
- Evaluate signed-commit requirements only after verifying compatibility with the connector and the sole-maintainer workflow.
- Bind production releases to successful protected-main history and immutable version tags. Require signed/notarized `.app` and DMG validation, checksums and provenance where feasible; keep signing material in a protected release environment.
- Production publication needs explicit owner authorization. No signed release, approved canonical icon or real-hardware acceptance is claimed.

## Owner-authorized M0 hardware test

On 2026-11-10 the owner explicitly requested a downloadable app to test M0. The fixed `v0.0.1-m0.1` prerelease may originate from the exact reviewed `release/m0-macos-test` PR commit before protected-main integration. Publication requires successful exact-source macOS CI, Swift analysis, CodeQL PR result, a recorded exact-source packaging/security review, verified public Git identity, a verified universal app/ZIP and an immutable tag. The one-shot workflow is preserved at the immutable published tag; it is retired from the integration branch after successful publication to prevent repeated attempts to publish an existing version. It only creates a prerelease, refuses overwrites, checks both draft and anonymous public download bytes, and cannot publish a production version.

This explicit M0-only authorization does not close M0, replace real-Mac acceptance, waive administrative verification or weaken production release signing/notarization and protected-main requirements. The published tag and its assets remain bound to source `39f5f35d44e354b112c95006bee7d54c2daffd02`; subsequent documentation/integration commits do not rewrite that release. See `docs/security/NEIGHBOR_REVIEW_2026-11-10.md`.

See `AGENTS.md`, `docs/agent/AUDIT_REFACTOR.md` and M0 exit issue #2.
