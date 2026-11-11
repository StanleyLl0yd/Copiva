# GitHub security and release baseline

## Verified 2026-11-10

- Main ruleset `26940387`: active, no bypass, PR/squash/linear history, strict `macOS 26 / Swift` from GitHub Actions, deletion and force-push protection.
- CodeQL enforcement is now present in that ruleset: `medium_or_higher` security alerts, `errors` alert threshold, tool CodeQL. API re-read after the owner saved the rule.
- Owner-supplied Code Security UI confirms default CodeQL setup, Medium or higher / Only errors check thresholds, Secret Protection and Push protection enabled.
- Tag ruleset `26948978`: active, no bypass, `refs/tags/v*` updates/deletion blocked; initial creation allowed.
- GraphQL confirms Dependabot alerts enabled and zero open alerts. Owner UI confirms Dependabot security updates enabled; grouped security updates off. Weekly GitHub Actions version updates are committed in `.github/dependabot.yml`.
- Owner Actions UI confirms selected owner/GitHub-created actions, default read-only contents/packages token, PR creation/approval disabled, first-time fork contributors require approval, and 90-day default log/artifact retention.
- Full-length Action-SHA server enforcement is off; all committed external Action dependencies are nevertheless pinned to immutable SHAs, with credential persistence disabled and minimal job permissions.
- Private vulnerability reporting is enabled. Read-only Actions security-events access verified zero open CodeQL alerts.
- The owner authorized the GitHub profile name for Git metadata; verified noreply email remains mandatory. API commits and protected squash author/committer metadata are checked without printing profile values.

## Verification limits

The connected App and read-only Actions token still return 403 for several owner-setting/alert endpoints and omit `security_and_analysis`. The fields above distinguish API/GraphQL evidence from owner-supplied UI. Do not infer missing server settings or alert counts from a 403. Durable evidence and manual-Mac acceptance remain in issue #2.

## Numeric release policy

Versions and GitHub release titles are numeric `X.Y.Z` only; ordinary GitHub Releases have `prerelease: false`, with protected `vX.Y.Z` tags. `release/VERSION`, bundle version and owner-authorized `release/REQUEST` must match.

Read-only PR build jobs verify the Apple Silicon arm64 app, ad-hoc signature, ZIP and checksums. Publication runs only on protected main, waits for exact-main CI plus Swift/Python CodeQL and medium-or-higher/error alert policy, verifies authorized profile/noreply metadata, stages and verifies draft bytes, then publishes and checks anonymous public downloads. No overwrite or protected-tag movement/deletion is permitted. The superseded qualified preview entry is archived as a draft after 0.0.1 verification, preserving tag and original bytes; the completed one-time migration is retired from reusable automation.

Temporary release evidence expires after seven days; final ZIP, SHA-256 and build metadata remain in GitHub Releases. The current pipeline uses ad-hoc signing without Apple Developer ID or Apple notarization. Numeric release naming does not establish production readiness or milestone acceptance. Production signing/notarization, canonical-icon approval and real-Mac acceptance remain required at their applicable gates.

See `AGENTS.md`, `docs/release/RELEASING.md`, the audit reports and issue #2.

The owner accepted M0 runtime behavior and supplied a running-app screenshot on 2026-11-10. Future distribution is Apple Silicon arm64 only; the already published 0.0.1 universal artifact remains immutable. See the complete M0 exit record and issue #2.

Artifact construction is separate from publication intent. A manual build defaults to no publication; the write-capable job requires a matching request/version/owner/date/purpose and explicit Publish on manual dispatch. Build metadata must also state publication_authorized=true. Version0.0.2 preparation records build-only scope from continuing development instructions and does not invent GitHub Release authorization.
