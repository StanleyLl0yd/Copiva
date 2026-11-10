# GitHub repository security baseline

This document records Copiva's protection and release-security expectations. Re-verify GitHub-hosted settings directly when required checks, credentials, trust boundaries or release automation change. Repository rulesets and Actions settings are operational controls, not merely documentation.

## Verified baseline (2026-11-10)

- Public repository with protected default branch `main`.
- Active branch ruleset `Copiva main: PR and CI required` (ID `26940387`), no bypass actors: pull request required, squash-only merge, zero mandatory human approvals for a sole maintainer, conversation resolution, linear history, blocked deletion and non-fast-forward update.
- Strict GitHub Actions check `macOS 26 / Swift`, scoped to GitHub Actions integration `15368`.
- GitHub Actions restricted to GitHub-owned actions; workflow token read-only and cannot approve pull requests.
- CodeQL default setup for Swift is configured; initial setup/analysis completed successfully.
- Dependabot alerts and security updates, GitHub secret scanning and push protection were enabled via the repository hardening scripts.
- GitHub `noreply` identity is the required identity for Copiva commits. No legal name, private contact address or clipboard payloads in public artifacts.
- Merge commits and rebase merges are disabled; squash merges and branch deletion on merge are enabled.

## Workflow and supply-chain rules

- Pin every external action to a complete immutable commit SHA with a human-readable version comment; use digest-pinned containers, not `latest`.
- Set workflow permissions to `{}` and grant narrowly scoped job permissions. Use `persist-credentials: false` for checkout. Avoid `pull_request_target` and untrusted-code execution with secrets or write-capable tokens.
- Never bypass the exact-head required checks. Verify post-merge exact-main CI.
- Keep secrets outside Git; do not include user clipboard content in CI artifacts, logs, fixtures, or uploads.
- Dependency security and license compliance must be assessed before adding packages.
- Keep private vulnerability reporting available where supported; route sensitive reports privately instead of posting exploit details publicly.

## Additional protections to stage deliberately

- **Release tags:** before first published version, add a no-bypass tag ruleset for `refs/tags/v*` blocking updates and deletion while allowing initial tag creation. Bind releases to successful protected-main history and prohibit overwriting assets.
- **CodeQL gate:** add merge-blocking CodeQL code-scanning rules for medium-or-higher findings once PR-triggered Swift analysis is confirmed reliable. CodeQL setup success alone does not prove PR gating.
- **Signed commits:** evaluate after verifying the full GitHub connector and local Git signing paths; do not introduce a setting that makes authorized single-maintainer development impossible.
- **Releases:** require macOS `.app` and DMG signing/notarization validation, immutable artifacts, SHA-256 checksums and provenance/attestation where feasible. Keep signing material only in a protected release environment.
- **Additional scanners:** add only when they catch distinct, material classes of risk with reliable and maintainable CI output.

See `AGENTS.md` for code, icon and milestone invariants and `docs/agent/AUDIT_REFACTOR.md` for the full mandatory audit procedure.
