# Neighbor-repository review — 2026-11-10

The owner requested comparison of existing repositories before resolving Copiva's merge/privacy and administrative-access blockers, and explicitly authorized a downloadable app for real-Mac testing.

## Evidence

- [TreMana release workflow](https://github.com/StanleyLl0yd/tremana/blob/9293934100039539d95a75600dc7dfb7acc3316c/.github/workflows/release.yml) and its [packaging script](https://github.com/StanleyLl0yd/tremana/blob/9293934100039539d95a75600dc7dfb7acc3316c/scripts/package-app.sh): GitHub Actions builds the app, creates/verifies an ad-hoc signature, publishes a ZIP with SHA-256 and checks downloaded bytes. Its release notes explicitly disclose absent Developer ID signing/notarization.
- [MeteoOne owner/admin issue #12](https://github.com/StanleyLl0yd/meteoone/issues/12): the connected integration could read rulesets but could not mutate them. Owner-side administrative changes were applied and re-read later; an earlier erroneous closure was reopened when live verification contradicted it.
- [Kenato security settings](https://github.com/StanleyLl0yd/kenato/blob/main/docs/security/GITHUB_SETTINGS.md): strict PR/CI controls, a separate CodeQL enforcement ruleset and owner-controlled signing/release settings. Historical enablement is not a substitute for current access.
- Sampled protected squash commits from TreMana PRs #52/#41/#40, Kenato #199/#198/#197, MeteoOne #306/#305/#304 and CopyFix #44/#43/#42: verified GitHub service committer and the owner's noreply email, but the author name did **not** match the required public Git author handle. Only equality results were inspected/reported; no other identity strings are reproduced.

## Conclusions and Copiva implementation

No safe precedent was found for assuming that GitHub squash merge preserves the explicitly chosen author name. Do not copy a profile-derived name into Copiva or publish a test merge to discover its identity. Ordinary Git data commits continue to use explicitly supplied and verified public-handle/noreply author and committer fields.

Administrative access is a real permission boundary, not an API spelling problem. Fresh Copiva reads still return 403 for Actions settings and security-alert access. No ruleset bypass, speculative token, new owner approval requirement or false verification is introduced. Issue #2 retains the exact outstanding administrative checks.

The M0 test build adopts TreMana's app/ZIP/ad-hoc/checksum/download verification approach, with immutable Action pins, separate read-only build and minimal write-capable publication jobs, seven-day temporary artifact retention and exact-source CI/CodeQL/review gates. The existing SwiftUI/SwiftPM application remains unchanged.

The owner's 2026-11-10 instruction authorizes this **M0 hardware-acceptance prerelease** from the exact reviewed PR commit while protected-main integration is blocked. It also authorizes the owner to download/install/test the binary. Source edits, compilation, tests and artifact production remain GitHub-only. A fixed protected version tag binds the prerelease to that SHA; this narrowly scoped test publication is not production release authorization, milestone acceptance, a main-branch bypass, Developer ID signing or Apple notarization.

Release evidence and manual acceptance remain in issue #2. Production releases retain the protected-main, signing/notarization and explicit authorization gates.

## Owner clarification and integration

Later on 2026-11-10 the owner explicitly authorized using the GitHub profile name for commit metadata. The author-name blocker is therefore resolved by authorization, with the verified GitHub noreply email retained. PR #1 was protected-squash-merged as `548af44dbc788f05ec8063528c5fd44a528f5ed2`; author/profile equality, noreply email and the verified GitHub service committer were checked without reproducing profile identity values here. Exact-main CI `42876007183` passed.

The M0 test release was successfully published from `39f5f35d44e354b112c95006bee7d54c2daffd02`. Its one-shot publication workflow remains preserved at that immutable tag and in Actions run `42843564520`, attempt 2, and is retired from the integration branch after publication. This avoids unused default-branch automation and attempts to overwrite the existing release. Packaging source, bundle configuration, checksums, release notes and byte-verified assets remain in GitHub. The published tag/assets are not rewritten.

Actions readback additionally verified zero open CodeQL alerts, active no-bypass branch/tag rulesets and private vulnerability reporting. Other owner-controlled settings still require evidence because the available tokens return 403; this is tracked separately from the resolved author-name issue in #2.
