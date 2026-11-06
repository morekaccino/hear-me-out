# Corpus label validator

`validate_labels.dart` checks one corpus label JSON file, and optionally a
manifest, against the v1 schema in
[`docs/CORPUS_LABELING.md`](../../docs/CORPUS_LABELING.md) and
[`docs/CORPUS_PROTOCOL.md`](../../docs/CORPUS_PROTOCOL.md).

It is pure Dart: it imports only `dart:convert`, `dart:io`, and `dart:math`. It
does not use Flutter and does not add a package dependency.

## Run

If `dart` is not on `PATH`, use the Dart SDK bundled with Flutter:
`<flutter-sdk>/bin/cache/dart-sdk/bin/dart`.

From the repository root:

```powershell
dart run tool/corpus/validate_labels.dart test/fixtures/corpus/valid_labels.json
```

Expected: exit code 0 and `OK: label is valid`.

```powershell
dart run tool/corpus/validate_labels.dart test/fixtures/corpus/invalid_labels.json
```

Expected: exit code 1 and a list of errors. The fixture deliberately contains a
wrong written/sounding pair, an overlap, an out-of-range fret, a non-finite
time, a phrase-count mismatch, a bad review pair, and a bad consent combination.

Validate a label together with its manifest:

```powershell
dart run tool/corpus/validate_labels.dart `
  test/fixtures/corpus/valid_labels.json `
  --manifest test/fixtures/corpus/manifest.json
```

Validate only a manifest:

```powershell
dart run tool/corpus/validate_labels.dart --manifest corpus/manifest.json
```

Machine-readable output:

```powershell
dart run tool/corpus/validate_labels.dart --json test/fixtures/corpus/valid_labels.json
```

`--json` prints one JSON object to stdout. Human-readable reports, including
warnings and errors, are not mixed into that output.

## Options

| Option | Meaning |
|---|---|
| `<label.json>` | Label file to validate. Optional when `--manifest` is given. |
| `--manifest <path>` | Validate a manifest and cross-check the label against its take entry. |
| `--json` | Print one machine-readable JSON object. |
| `-h`, `--help` | Print usage. |

## Exit codes

| Code | Meaning |
|---:|---|
| 0 | Valid. Warnings are allowed. |
| 1 | Validation errors. |
| 2 | Usage error or I/O error (missing file, unreadable file). |

## What it checks

Label:

- required fields are present and not JSON `null`; no unknown fields;
  `schemaVersion = 1`;
- enums for `platform`, `condition`, `guitar`, `expert.outcome`, and
  `expert.completeness`;
- `takeId`, `playerId`, and `device` slug forms;
- `takeId` starts with `<playerId>-<device>-<condition>-`; a mismatch is an
  error;
- `sampleRate` 8000–192000, `channels` 1–2, `tempoBpm` 60–90;
- `phraseNoteCount` is 4, 8, or 16 and equals the target length;
- target indices are contiguous and in performance order;
- written note ids and MIDI range;
- `soundingMidi = writtenMidi - 12`;
- `soundingMidi = openStringMidi[string] + fret`;
- non-negative finite onsets, positive finite durations, finite confidence
  0–1;
- `onsetSeconds` agrees with `onsetSample / sampleRate`;
- no overlapping monophonic events;
- any target note with confidence < 0.6 forces `completeness = "incomplete"`
  and `outcome = "indeterminate"`;
- `expert.outcome = correct` requires complete timing and accuracy ≥0.85;
- incomplete takes cannot be labelled `incorrect`;
- `labeler` and `reviewedBy` are different;
- `consent.keepRawAudio` is not true when `consent.audioCapture` is false.

Manifest:

- required fields are present and not JSON `null`; no unknown fields;
  `schemaVersion = 1`;
- player, device, and take references;
- unique player, device, and take ids;
- device class/platform agreement (`iphone` = `ios`, `laptop-web` = `web`,
  `mid-range-android` = `android`, `tablet` = `ios` or `android`);
- `takeId` starts with `<playerId>-<device>-<condition>-`;
- `.json`/`.wav` paths exactly match
  `<playerId>/<device>/<condition>/<takeId>.<ext>`, are relative, use forward
  slashes, and contain no `..`;
- warnings for a corpus that is not yet at the required player mix, device
  coverage, or 20 accepted takes per device/condition cell.

When a label and manifest are passed together, the label's `takeId` must appear
in the manifest, and `playerId`, `device`, `platform`, `condition`, and `guitar`
must agree. The `guitar` check accepts either instrument when the player is
registered as `both`. A manifest status of `failed` requires the label to be
`indeterminate` and `incomplete`.

## Tests

The repository has no root `pubspec.yaml` and this ticket must not add a
dependency, so the test is a standalone Dart program:

```powershell
dart run test/corpus_label_test.dart
```

It exits non-zero if any assertion fails. The test covers:

- the valid and invalid fixtures;
- null top-level and nested fields, including manifest collections and
  `schemaVersion`;
- missing fields, unknown fields, unsupported schema version;
- overlaps, non-contiguous indices, phrase-count mismatch;
- wrong written/sounding pairs, unknown note ids, bad string/fret combinations;
- NaN/infinite times and sample/second mismatches;
- low-confidence notes forcing `incomplete`/`indeterminate`;
- incomplete/incorrect outcome consistency, review independence;
- `takeId` prefixes and folder-layout paths;
- device class/platform agreement and player-guitar agreement;
- manifest references, paths, and label/manifest agreement;
- CLI `--json`, `--help`, exit codes, and clean JSON output.

`flutter test` does not discover this root-level test because it is outside
`flutter_app/`. The CI workflow runs it explicitly with
`dart run test/corpus_label_test.dart`; `flutter test` remains the regression
check for the Flutter app.

## Fixtures

- `test/fixtures/corpus/valid_labels.json` — a valid 8-note E-minor first-position
  phrase at 60 BPM. Every written note is one octave above its sounding MIDI.
- `test/fixtures/corpus/invalid_labels.json` — deliberately invalid in several
  independent ways.
- `test/fixtures/corpus/manifest.json` — a small manifest used to test
  cross-checks and warnings.

The fixtures are synthetic. They are not corpus evidence and contain no audio.
