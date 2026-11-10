## Purpose and scope
- What behavior or policy changes? What is deliberately unchanged?

## Verification
- [ ] Relevant targeted tests completed
- [ ] `swift build` completed (or state why unavailable)
- [ ] `swift test --parallel` completed (or state why unavailable)
- [ ] Exact-head required macOS CI is green before merge
- [ ] Real macOS UI/clipboard/accessibility verification when behavior changes (or explicit limitation)
- [ ] Exact-main CI checked after merge

## Security, privacy and data safety
- [ ] No real clipboard payloads, secrets, personal identities or work contact details in code, logs, fixtures or artifacts
- [ ] Clipboard representation limits, privacy markers, self-copy filtering and failure cases considered where relevant
- [ ] Pinned retention, persisted formats, migrations and cleanup safety considered where relevant
- [ ] Dependencies, Actions pins/permissions and OS privileges reviewed if affected
- [ ] No weakening of rulesets, CodeQL, secret scanning or required checks

## Icon and release invariants
- [ ] No modification of owner-approved canonical artwork (or explicit approved replacement with checksum)
- [ ] No unsigned/unverified release claim, unexpected tag rewrite or signing-secret exposure

## Full audit / milestone exit (only when applicable)
- [ ] Complete two-pass repository-wide audit/refactor/review performed per `docs/agent/AUDIT_REFACTOR.md`
- [ ] Findings, fixes, deferred risks, platform limitations and final-main verification recorded
