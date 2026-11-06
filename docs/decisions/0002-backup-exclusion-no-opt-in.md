# Decision 0002 — Exclude recordings from cloud backup with no V1 opt-in

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** Engineering
**Supersedes:** Nothing
**Related:** T4.5, T4.2, T9.2, plan section 9

## Context

The plan says recordings are excluded from iCloud and Android backup unless the
user opts in. A real opt-in needs a settings surface, explicit copy, and a
tested off-by-default path. T4.5 must make recording private before T4.2 ships
any recording UI, and the app must not tell the learner a take is excluded when
the platform did not confirm it.

## Decision

1. Android excludes the recording directory (`filesDir/media`) from Auto Backup
   and device transfer through manifest rules. This is build-time enforcement
   with no runtime toggle.
2. iOS asks the system to set `NSURLIsExcludedFromBackupKey` on the recording
   directory before the media store is created, reads the value back, and
   reports the result through `mediaBackupStatusProvider`.
3. V1 has **no opt-in** to include recordings in cloud backup. Exclusion is the
   default and there is no setting that turns it off.
4. Privacy copy is conditional. The app may say "excluded from cloud backup by
   default" only when the status is confirmed (`excluded` or
   `excludedByRules`). A failed, unsupported, or still-loading status says the
   exclusion is unconfirmed and the take may be included in device backup.
5. **T4.2 gate:** the recording UI must consume `mediaBackupStatusProvider`. It
   must not present a take as private or excluded when the status is not
   confirmed. If the status is unconfirmed, it must show the warning and may
   allow recording only while that warning is visible. No recording flow may
   bypass this check.
6. T4.2 also owns the delete and export controls. V1 privacy copy describes
   those controls as commitments for the recording UI, not as shipped features.
7. Adding an opt-in later requires a new decision record, an explicit
   default-off setting, updated copy, and tests that the iOS resource value and
   the Android rules are actually cleared when the learner opts in.

## Consequences

Positive: recordings are private by default without asking the learner to
manage a security setting; the failure path has honest copy instead of a false
claim; T4.2 inherits a clear contract.

Negative: a learner cannot use cloud backup to move takes between devices in
V1. A real iOS device check is still needed to prove the system honors the
resource value, and Android device backup still needs device evidence.
