# Release procedure

- Versions and GitHub release titles contain numeric `X.Y.Z` only. Releases are ordinary GitHub Releases, not prereleases; protected tags are `vX.Y.Z`.
- Update `release/VERSION`, `Config/Info.plist` in a focused PR. A matching owner-authorized `release/REQUEST` is still required before packaging. An `actions-artifact` request covers build-only validation under continuing development instructions; only `github-release` purpose may authorize publication. Increment the bundle build number for a replacement build.
- PR Actions validate the Apple Silicon arm64 app, version, ad-hoc signature, ZIP round-trip and checksums with read-only permissions.
- Manual dispatch builds an artifact by default; its Publish input defaults to false. The publishing job runs only on protected main with matching request-derived publication authorization, for a version/request push or explicit Publish dispatch. It waits for exact-main CI plus Swift and Python CodeQL, checks medium-or-higher/error CodeQL alerts and the authorized profile/noreply Git identity, validates artifact metadata/checksums, creates an immutable tag and a draft release, compares uploaded bytes, then publishes an ordinary release and verifies anonymous downloads.
- No release/tag/asset overwrite is allowed. The previous qualified preview entry was archived as a draft after 0.0.1 verification; its protected historical tag and original asset bytes remain intact. The completed one-time migration is removed from reusable automation.
- Temporary build evidence is retained seven days. Final packages, SHA-256 and build metadata remain in GitHub Releases.
- This pipeline currently uses ad-hoc signing. Developer ID signing, Apple notarization, production authorization and actual user acceptance remain separate requirements. Do not present the GitHub release classification as proof of those requirements.

Release 0.0.1 remains its verified universal artifact. Future versions use `Copiva-X.Y.Z-macos-arm64.zip`, with an explicit arm64-only architecture check.

Prepared 0.0.2 artifacts are for M1 Mac testing. The new request explicitly scopes the continuing development instruction to artifact construction. It does not claim new publication authorization; historical0.0.1 authorization remains in immutable Git history. A prospective release_tag in BUILD-INFO is a naming field, not evidence that a tag/release exists. Metadata and the build output explicitly identify publication authorization.
