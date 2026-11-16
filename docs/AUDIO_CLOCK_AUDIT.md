# Audio clock audit (T1.3)

Audited on 2026-11-16 on branch `t1.3-closeout` (cut from
`year-long-rewrite`) with Flutter 3.47.9 / Dart 3.13.7 on Windows. Paths
are relative to `flutter_app/` unless noted.

| # | Clause | Verdict | Code evidence | Test evidence |
|---|---|---|---|---|
| 1 | Effective sample rate and channel count come from the recorder config, not assumed 44.1 kHz mono. | PASS | `lib/core/audio/pitch_source.dart:325-337` maps the platform `RecordConfig.sampleRate` and `numChannels` into `PcmCaptureConfig`; `:195-220` stores the reported config and rebuilds the decoder at that format. `lib/core/audio/phrase_recorder.dart:214-231` follows the reported format before the first sample; `:144-149` reports `sourceSampleRate` / `sourceChannels`. | `test/pitch_source_test.dart:159` `effective stereo config feeds the sample clock and decodes 440 Hz`; `test/phrase_recorder_test.dart:109` `uses the effective stereo 48 kHz format and downmixes to mono`; `test/phrase_recorder_test.dart:155` `uses the effective 44.1 kHz format when the platform reports it`; `test/pitch_source_test.dart:231` `falls back to 44.1 kHz when 48 kHz is rejected`. |
| 2 | Non-44.1 kHz input is resampled or rejected explicitly; stereo is downmixed or handled explicitly. A 48 kHz source must not read ~8.8% sharp. | PASS | `lib/core/audio/pcm_stream.dart:98-107` averages every channel frame to mono; `:109-124` linearly resamples by `inputSampleRate / outputSampleRate`. `pitch_source.dart:163-168` and `phrase_recorder.dart:103-108` construct the decoder from the effective config. | `test/pcm_stream_test.dart:109` `48 kHz mono keeps a 440 Hz tone at 440 Hz, not 8.8% high`; `test/pcm_stream_test.dart:158` `44.1 kHz stereo downmixes and resamples at 440 Hz`; `test/pcm_stream_test.dart:142` `48 kHz stereo downmixes left-only, right-only, and identical`; `test/pcm_stream_test.dart:172` `stereo channels are averaged, so opposite phases cancel`; `test/pcm_stream_test.dart:183` `any channel count is averaged to mono`; end to end, `test/phrase_player_screen_test.dart:135` `play, count-in, record, stop, correction, and retry` scores a clean 48 kHz take as a clean take. |
| 3 | Tests cover 44.1 and 48 kHz, and mono and stereo. | PASS | n/a (test inventory) | 44.1 mono: `test/pcm_stream_test.dart:98`; 48 mono: `test/pcm_stream_test.dart:109`; 44.1 stereo: `test/pcm_stream_test.dart:158`; 48 stereo: `test/pcm_stream_test.dart:142`; recorder 44.1 mono: `test/phrase_recorder_test.dart:155`; recorder 48 mono: `test/phrase_recorder_test.dart:48`; recorder 48 stereo: `test/phrase_recorder_test.dart:109`. |
| 4 | `PitchFrame` carries a monotonic sample-clock timestamp. | PASS | `lib/core/audio/pitch_source.dart:13-30` declares `sampleIndex` and `sampleTime`; `:240-248` sets both from `_frameStart`; `:256-262` converts the analysis-sample index to a duration. The index advances by `hopSize` and never resets while a stream is live; a post-frame format correction continues from `_decodedSamples` (`:195-220`). | `test/pitch_source_test.dart:124` `PitchFrame carries a sample-clock position`; `test/pitch_source_test.dart:284` `a post-frame config correction keeps the sample clock monotonic`; `test/pitch_source_test.dart:203` `sampleIndex restarts at zero on start after stop`. |
| 5 | No `DateTime.now()` (or equivalent wall clock) is used to align or time audio frames anywhere in the capture, segment, align, or score path. | PASS (phrase capture/segment/align/score path) | Fixed in this change. `lib/core/audio/pitch_source.dart:27` makes `timestamp` an optional, nullable display-only label; `:140-177` and `:229-254` contain no clock read and never set it. The capture path stamps only `sampleIndex` / `sampleTime`. | `test/pitch_source_test.dart:138` `the capture path never stamps wall-clock time` fails on the old code (`timestamp` was a `DateTime`) and passes now. |
| 6 | The phrase scorer and recorder consume the sample clock, not wall time. | PASS | `lib/core/audio/phrase_recorder.dart:25-26` derives `durationSeconds` from `samples.length / sampleRate`; the file reads no clock. `lib/core/audio/phrase_scorer.dart:174-196` passes sample buffers and a fixed `sampleRate` to the detector and segmenter; `lib/core/audio/onset_detector.dart:216-224` converts `sampleIndex / sampleRate` to seconds; `lib/core/audio/alignment.dart:302-307` matches on sounding MIDI, not time. | `test/phrase_recorder_test.dart:130` `take length comes from the sample clock, not elapsed wall time`; `test/phrase_scorer_test.dart:642` `the same samples produce identical JSON`. |

**Device evidence:** pending / human-owned (48 kHz-only and
stereo-negotiating device pass). The in-memory fixtures and CI do not prove
that a real device negotiated 48 kHz or stereo.

## Change applied

Clause 5 failed before this change: `RecordPitchSource.start` called
`DateTime.now()` and stamped every `PitchFrame.timestamp`. The read and the
`_streamEpoch` field were removed. `PitchFrame.timestamp` is now an optional
display-only label that the capture path leaves null; all alignment and scoring
stay on `sampleIndex` / `sampleTime`. No scoring threshold, gate, recorder
request shape, or phrase prompt changed.

The only remaining wall-clock read under `lib/core/audio/` is
`note_matcher.dart:70,104`, the injectable `now` for the 250 ms live-lesson
grace. It does not consume `PitchFrame.timestamp` and is outside the phrase
capture, segment, align, and score path audited here.

## Verification

From `flutter_app/`:

```text
flutter analyze                  No issues found! (ran in 8.3s)
flutter test                     1174 tests passed
flutter build web --release      Built build\web
```
