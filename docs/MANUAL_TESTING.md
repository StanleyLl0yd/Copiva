# M1 real-Mac acceptance checklist

M0 launch/Quit acceptance does not accept these new features. Run this checklist using a verified arm64 application artifact on macOS 26 or later. Native CI proves compilation, persistence and synthetic integration paths; it cannot establish another application's actual focus or insertion behavior.

Use only synthetic text such as `Copiva sample one`, `Copiva sample two` and `Пример для Copiva`. Do not include private clipboard contents, full paths, identity information or permission screenshots containing personal details in GitHub reports.

## Capture and persistence

- Launch with fresh Copiva settings: recording is paused, and existing clipboard text is not imported.
- Choose Record copied text, read the local plaintext-storage explanation, and cancel once. Copy synthetic text; it must not appear.
- If macOS asks for clipboard access, exercise refusal and allowance. With persistent Deny, recording must stop with an explanation; grant access through System Settings and explicitly resume. No content should be imported from before resume.
- Enable recording. Copy the three synthetic samples in TextEdit; each new copy appears once, with search working for English and Russian word prefixes.
- Copy an item from Copiva; it must not become a new history entry.
- Pause, copy another sample, then resume: the paused sample must not be imported retroactively.
- Quit and reopen. Saved items, consent, recording choice, retention choice and exclusions remain.
- Set a smaller history limit and confirm ordinary retention; choose Clear, cancel once, then confirm. Saved history clears without changing the current clipboard.
- Configure TextEdit's bundle ID as an exclusion and copy a fresh sample there. Remove the exclusion and make a new copy; only the new allowed copy is captured. Foreground attribution and unmarked-secret limitations remain as documented.

## Keyboard picker

- From an editable TextEdit document, press the displayed shortcut (default Control-Option-V).
- Search, move with Up/Down, and verify the selected item stays visible. Escape closes without changing clipboard or inserting text.
- Choose a different shortcut in settings, quit/reopen and verify it persists.
- Assign a combination already used by another app: Copiva shows the conflict and the old working combination remains registered. Resolve a startup conflict by assigning a free combination.
- Check English/Russian layouts, IME marked-text composition, light/dark appearance, VoiceOver labels, narrow/multiple displays, Spaces and fullscreen. The M1 window uses a pointer fallback, not caret placement.

## Paste and failure paths

- With Accessibility disabled, explicit Paste copies the selection and explains the permission/manual Command-V fallback. Browsing/copying must not prompt.
- Enable Accessibility through macOS settings. Reopen the picker from TextEdit and explicitly paste: exactly one selected text appears in the intended field, original focus returns, and no modifier remains stuck.
- Test another installed text editor and a browser text field. Record which apps accept automatic paste and which correctly use Copy; do not claim universal support.
- Switch app or field while the picker/action is open. No automatic paste should reach the new destination.
- Try a secure field and an app without writable AX text access: expect Copy rather than automatic insertion.
- Revoke Accessibility while running, hold shortcut modifiers, cancel an action, and make a newer external clipboard copy during selection. No delayed paste or restoration over a newer clipboard is allowed.
- Check Return, Command-Return, mouse buttons and rapid repeat invocations; no duplicate automatic insertion.

Record the artifact source commit, macOS version, architecture, tested target apps and pass/fail outcomes in issue #6. A failure keeps M1 open. Keep untested cases explicitly untested; do not infer them from CI.
