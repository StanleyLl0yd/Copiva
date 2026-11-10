# Release procedure

- Versions and GitHub release titles contain numeric `X.Y.Z` only. Releases are ordinary GitHub Releases, not prereleases; protected tags are `vX.Y.Z`.
- Update `release/VERSION`, `Config/Info.plist` and a matching owner-authorized `release/REQUEST` in a focused PR. Increment the bundle build number for a replacement build.
- PR Actions validate the universal app, version, ad-hoc signature, ZIP round-trip and checksums with read-only permissions.
- The publishing job runs only on protected main. It waits for exact-main CI and Swift CodeQL, checks medium-or-higher/error CodeQL alerts and the authorized profile/noreply Git identity, validates artifact metadata/checksums, creates an immutable tag and a draft release, compares uploaded bytes, then publishes an ordinary release and verifies anonymous downloads.
- No release/tag/asset overwrite is allowed. The previous qualified preview entry is archived as a draft only after the numeric replacement is verified; its protected historical tag and original asset bytes remain intact.
- Temporary build evidence is retained seven days. Final packages, SHA-256 and build metadata remain in GitHub Releases.
- This pipeline currently uses ad-hoc signing. Developer ID signing, Apple notarization, production authorization and actual user acceptance remain separate requirements. Do not present the GitHub release classification as proof of those requirements.
