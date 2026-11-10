# Copiva — Repository Agent Instructions

## Scope and precedence

These instructions apply to the entire repository and to every coding, security, CI, documentation, design, audit, review and release task. Any more-specific directory instructions may refine, but must not weaken, these invariants. Inspect current code, roadmap, CI, protection and open work before changes; do not restart completed work or discard unrelated changes.

## Product and architecture invariants

- Copiva is an independent, native macOS clipboard manager built with Swift, SwiftUI and AppKit. It is not a Spotlight extension and does not depend on Copibara.
- The primary interaction is a fast, compact, keyboard-first picker near the active text insertion point, with safe positioning fallbacks.
- Global shortcuts must be configurable and must handle conflicts. Keyboard navigation, accessibility and correct focus restoration are core requirements.
- Keep ordinary history searchable and configurable; pinned clips must survive restarts, upgrades and history cleanup indefinitely until explicitly deleted by the user.
- Preserve supported original pasteboard representations (including rich-text representations when present) and offer distinct original-format and plain-text paste actions. Do not promise fidelity or paste support beyond the receiving application's capabilities.
- The persistence design is local-first. Planned components are SQLite/FTS5 for indexed metadata and managed files for larger payloads. Changes to schema, migrations and retention require compatibility and data-loss analysis.
- Never replace a real working feature with a visual mock, placeholder, fake test or optimistic claim. The initial menu-bar skeleton is not a functioning clipboard history implementation.
- Prefer the smallest maintainable design and built-in Apple frameworks. Keep UI, pasteboard adapters, persistence, policy and testable domain logic distinct where that separation provides real value.

## Clipboard privacy and reliability

- Clipboard contents are untrusted and potentially highly sensitive. Never commit, log, print, upload, transmit, include in telemetry, or expose real captured payloads in CI artifacts, diagnostics or crash reports.
- The product runs locally, without mandatory cloud services or analytics. No background network sharing of clipboard data.
- Respect pasteboard confidentiality markers and excluded applications. Do not claim that every password manager can be detected or every secret excluded. Test permission and accessibility failure paths.
- Bound payload sizes, processing time, representation count and memory consumption; handle malformed/unavailable types, temporary file URLs, permission changes and concurrent pasteboard modifications safely.
- Prevent recording app-generated clipboard writes as new user clips. Avoid destroying unrelated current clipboard content and avoid unintended insertion into the wrong app or field.
- Do not silently delete or alter pinned items. Test crashes, cancellation, concurrent access and restart/upgrade recovery for persistence-affecting changes.
- Require explicit user intent for destructive actions, external network integration and new OS privileges. Minimize requested accessibility/input-monitoring permissions.

## Repository workflow and security

- Use focused topic branches and protected, squash-only pull requests. Never push directly to `main`, bypass rules, suppress security findings or remove required checks to get a merge.
- Inspect the exact PR diff and its dependencies, error paths, privacy impact, regression tests and CI before merging. Verify exact-head required checks and post-merge exact-main CI. Do not assert tests, native UI behavior or notarization without evidence.
- Run targeted verification in GitHub Actions first, then expand to complete checks for security-sensitive changes, milestone exits or release gates.
- GitHub Actions use immutable full 40-character SHAs with a nearby version comment; pin workflow containers by digest, use `persist-credentials: false`, minimal job-level permissions and no privileged PR code execution. Do not add `pull_request_target` without an explicit threat-model review.
- Never commit tokens, credentials, personal identifiers, private or work contact details, signing keys, provisioning profiles, environment secrets, local user data, or real captured clipboard content. For new Git metadata, use the repository owner's GitHub profile name (explicitly authorized by the owner on 2026-11-10) and verified GitHub-generated noreply email. GitHub's verified service committer is permitted for protected squash merges. Do not copy profile identity strings into source, documentation, fixtures or logs.
- Preserve CodeQL, Dependabot, secret scanning/push protection and repository rulesets. Security/release config changes require focused PR review and CI.
- Do not add dependencies without clear benefit, license review, pinned/reproducible resolution and vulnerability review. Keep source and tests deterministic.
- Keep source-code comments in English. Update durable architecture/security documentation for changes to invariants or interfaces.

## Canonical application icon protection

- No owner-approved canonical Copiva app icon is currently committed. Do not claim the provisional SF Symbol used by the menu-bar skeleton is approved application artwork.
- Once the project owner explicitly supplies and approves an original PNG as the app icon, store the **exact original PNG bytes** as the canonical source under `artwork/`, record its SHA-256 and dimensions, and preserve its provenance.
- Do not trace, redraw, recreate, regenerate, vectorize, restyle, recolor, crop, pad, sharpen, recompress, optimize in place, or overwrite the canonical PNG during routine development, review, audit, refactoring or release preparation. No SVG, vector PDF or SF Symbol substitution without explicit owner instruction.
- Generate only separately named raster derivatives necessary for macOS packaging (including ICNS and correctly sized PNGs). Keep the visual design unchanged and the master file immutable. Verify generated assets against the recorded master and inspect actual small-size readability on both light and dark appearances.
- Do not modify approved app icons, menu-bar artwork or branding as an incidental side effect of a refactor. Any intentional replacement needs an explicit owner-approved source, a focused PR, updated source/hash/derivatives/references, and visual acceptance on macOS.
- The future canonical checksum is not yet known; never invent it.

## Mandatory full audit, safe refactoring and code-review protocol

- For **full audit, security audit, repository-wide code review, deep refactoring, cleanup, simplification or optimization**, follow **every** applicable requirement of `docs/agent/AUDIT_REFACTOR.md`, not merely the current diff or recent modules.
- Perform a complete first repository-wide audit and actual safe remediation/refactoring pass, then a **second complete pass over the entire repository after those changes**. Include source, tests, resources/icons, macOS integration, SwiftPM, configuration, CI/CD, release tooling, dependencies, persistence, documentation and security settings.
- Prove a symbol, resource or path is unused before removing it: check SwiftUI/AppKit lifecycle, selectors, target membership, packaging resources, dynamic/framework registrations, serialization and indirect entry points. Preserve functionality, UI/UX, formatting fidelity, pinned retention, settings, security and data compatibility.
- Code review requires concrete findings with severity, file/line scope, reproducible rationale, fix and regression coverage. Separate confirmed defects from hypotheses. Implement justified fixes; avoid unrelated churn and cosmetic code changes.
- Preserve tests and platform behavior; don't make checks weaker to produce a green build. Clearly disclose checks unavailable from the current environment and any unresolved blockers.

## Mandatory milestone exit gate

- Before accepting or closing **each** milestone (M0, M1, M2, M3, M4, M5 and future stages), create or reuse a milestone-specific exit issue and execute the complete two-pass repository-wide audit, safe refactor, security review and code review.
- Record scope, findings, completed fixes, deliberate non-changes, CI/test evidence, unavailable runtime checks, before/after measurements where meaningful, and the final protected-main verification. Unresolved required findings block milestone closure.
- Do not call M0 completed merely because CI is green: validate the scaffold on a real Mac and complete its exit gate. Do not call a release accepted before user testing/authorization and successful signed/notarized artifact checks.
- A future signed/notarized release must be bound to an immutable version tag, an exact verified main commit, least-privilege signing automation, checksums and provenance/attestation where supported. Release engineering is not authorization to publish a release.

## Status and reporting

Report verified facts with exact relevant commit/PR/check links. Distinguish planned, implemented, tested, deployed and user-accepted states. Continue from the existing ROADMAP or open findings when asked to proceed; avoid repeating already completed work. Do not disclose sensitive clipboard data or personal/work identity in reports.

## Numeric release versions

- The owner requires numeric release versions and GitHub release names: `X.Y.Z` only, for example `0.0.1`. No alpha/beta/rc, milestone suffixes or other qualifiers. Publish ordinary GitHub Releases with `prerelease: false`.
- Version tags use the existing protected `vX.Y.Z` namespace; the version itself remains numeric. Artifact version components must also be numeric.
- Record the version in `release/VERSION`, require a matching owner-authorized `release/REQUEST`, and verify the app bundle version before packaging. Publish only from successfully verified protected main.
- Numeric naming does not imply user acceptance, Developer ID signing, notarization or production readiness. Describe the actual implemented features and signing status accurately.
- Never move/delete protected historical tags or overwrite published assets. Supersede an earlier publication with a new authorized numeric release; preserve essential historical evidence in GitHub.

## Distribution architecture

- The owner selected Apple Silicon-only distribution on 2026-11-10. Future application packages target arm64 only; universal/Intel packaging is not required unless the owner explicitly changes this scope.
- Keep already published version tags/assets immutable. Release 0.0.1 remains its verified universal artifact; subsequent versions use the arm64 package pipeline.

## GitHub-only agent work

- Keep durable project source, documentation, reports, decisions, reviews, history and artifacts in GitHub. Inspect and edit through GitHub tools/APIs; run compilation, tests, scans and packaging in GitHub Actions.
- Do not create a persistent external repository checkout or use a personal device/Codex workspace as project storage. Temporary runner checkouts are allowed only to execute workflows.
- The owner explicitly authorized downloading/installing the application binary and reporting manual Mac test results; do not ask the owner to compile, edit or upload project source.

## Public README content

- Keep both READMEs focused on the application: its purpose, useful workflows, current capabilities, planned experience and ways to contribute. Use an inviting, conversational and factual tone, with restrained humor where natural, without advertising or commercial claims. The owner's FootClubSim, CopyFix and SeaBattle READMEs are tone/layout references; adapt the presentation to Copiva's actual capabilities.
- Include useful linked project badges. Keep current availability clear, but put build commands, audit findings, CI/check evidence, milestone acceptance and implementation progress reports in the relevant documentation, issues or release notes.
- Maintain equivalent Russian and English content. Describe planned features as plans; badges and prose must not imply unimplemented functionality or unverified release guarantees.
