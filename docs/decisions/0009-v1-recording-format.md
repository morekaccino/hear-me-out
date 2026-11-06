# Decision 0009 — V1 stores bounded WAV recordings; AAC compression is a follow-up

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** Engineering
**Supersedes:** Nothing
**Related:** T4.2, T4.1, T4.5, T9.2, plan section 9

## Context

Plan section 9 says: “Record WAV for analysis; compress to AAC for storage.” That
sentence assumes two things at once: a PCM analysis buffer and a second encoded
copy for storage. The current dependency set has no tested cross-platform AAC
encoder that can do this without opening a second capture.

`record` can either record an encoded file (AAC on mobile) or expose a PCM16
stream. It cannot produce both on one `AudioRecorder` at the same time. Recording
AAC directly would remove the PCM stream that phrase scoring uses. Recording PCM
and then encoding to AAC would require a platform encoder for Android, iOS, web,
macOS, Windows, and Linux; the app has no such dependency, and adding one would
also add a second audio code path to validate.

The ticket also requires honest privacy copy and forbids claiming a feature that
is not shipped. Shipping “AAC storage” because a plan line says so would be a
false claim.

## Decision

1. V1 **stores bounded PCM16 WAV** in the existing local `MediaStore` (files on
   IO, IndexedDB on web). The stored WAV is the 22.05 kHz mono analysis buffer,
   so the analysis buffer and the stored take are the same buffer: one capture,
   no second recorder.
2. The `RecordingEncoder` seam exists in `core/media/recording_encoder.dart`
   with one implementation, `WavRecordingEncoder`. `RecordingService` depends on
   the interface, so a future encoder can replace it without changing the
   recorder contract. The seam does not by itself make AAC available.
3. Storage stays bounded by the quota, not by compression:
   - 60 seconds per take, truncated and marked capped when the timer stops it;
   - 20 takes globally;
   - 200 MB global byte cap;
   - the first and last take per piece are protected.
4. AAC is a follow-up. A future ticket must choose and test an encoder on every
   target, prove it does not require a second capture, migrate existing WAV
   takes without data loss, and update the privacy and storage copy.
5. No recording-quality claim is made. The WAV path has automated coverage for
   capture, truncation, storage, quota, delete, export, and reconciliation, but
   no device microphone accuracy or codec-quality validation is claimed by
   T4.2.

## Consequences

Positive: one recorder, one analyzed take, no lossy re-encode, no new codec
dependency, and a straightforward path to export. The 200 MB cap keeps the
larger format bounded.

Negative: WAV uses more disk than AAC. A learner with 20 full-length takes
stores about 50 MB at 22.05 kHz mono PCM16, well under the configured 200 MB
cap, but storage use is still larger than the plan’s compression target. The
AAC follow-up now owns encoder selection, migration, and codec-quality
evidence.
