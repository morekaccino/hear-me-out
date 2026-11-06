# Latency, clock, and bleed test rig

Timing scores are only trustworthy when the device has been measured. This
runbook describes the rig that measures output-to-input offset, clock drift,
false onsets, note recall, and speaker/headphone bleed before the app may claim
a note was played "in time".

The rig is implemented in:

- `flutter_app/lib/core/audio/wav.dart` - PCM16 WAV reader/writer.
- `flutter_app/lib/core/audio/calibration.dart` - offset, drift, recall, and
  bleed analysis.
- `flutter_app/tool/latency_rig.dart` - command-line entry point.
- `flutter_app/test/wav_test.dart` and
  `flutter_app/test/calibration_test.dart` - regression tests.
- `flutter_app/test/fixtures/audio/` - simulated smoke-test takes.

Nothing in the rig opens a microphone. It only reads WAV files, so it runs on a
laptop while the app is closed.

## Decision gates

| Gate | Threshold | Applies to | Failure consequence |
|---|---|---|---|
| Offset | `abs(offset) <= 10 ms` | `loopback` | Do not score timing |
| Clock drift | `abs(drift) <= 20 ms / 60 s` | `loopback` | Do not score timing |
| False onsets | `<= 1 / min` | `recall`, `bleed` | Headphones or notes-only |
| Note recall | `>= 95%` | `recall` | Check the take before scoring |
| Recall drop | `<= 5%` | `bleed` | Headphones required |
| Speaker false onsets | `<= 1 / min` | `bleed` | Headphones required |

`loopback` decides only offset and drift. Bleed is a separate decision because
a clean click loopback does not prove that a speaker is not leaking into the
microphone during a guitar take. The `bleed` command makes that decision.

If the rig fails, the product rule from
[`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) section 4.4
applies: **score note accuracy only and drop the "in time" claim**. Do not
average a failing device into a passing result.

## Quick start

Run all commands from `flutter_app/`:

```powershell
cd flutter_app
dart run tool/latency_rig.dart --help
```

Run the committed simulated fixtures:

```powershell
dart run tool/latency_rig.dart loopback `
  --reference test/fixtures/audio/ref.wav `
  --recorded test/fixtures/audio/take.wav `
  --json
```

The fixture take has a known 5 ms delay, so the object should report
`"offsetMs":5.0` and `"timingUsable":true`. `late.wav` has a known 25 ms delay
and must report `"timingUsable":false` with exit code 1.

These fixtures validate the rig. They are **not** device evidence. Only a
recorded device run populates the matrix below.

## Generating the reference click WAV

The rig can generate its own reference click train. This is the exact command
used to create the committed fixture:

```powershell
dart run tool/latency_rig.dart generate `
  --out test/fixtures/audio/ref.wav `
  --expected-out test/fixtures/audio/expected.json `
  --duration 12 `
  --interval 0.5 `
  --sample-rate 16000
```

For a real calibration take, use 60 seconds so drift is measured across the
full gate window:

```powershell
dart run tool/latency_rig.dart generate `
  --out ref60.wav `
  --expected-out expected60.json `
  --duration 60 `
  --interval 1 `
  --sample-rate 48000
```

Keep the interval at 1 s when testing Bluetooth or any device with more than
100 ms of latency. A 0.5 s train plus a 300 ms Bluetooth offset can alias:
the correlation window cannot tell a 300 ms delay from a 200 ms early arrival.
The analyzer bounds its search to less than half the click interval for this
reason.

The generated click is a short 2.5 kHz burst with a fast decay. A metronome or
the Bright Pluck synth is also acceptable, provided the onsets are sharp and
the same reference file is used for every condition.

## Loopback methods

### Cable or audio interface (preferred)

1. Connect the device output to the recording input with a shielded cable, or
   route an audio interface output back into its own input.
2. Play `ref60.wav` through the same output path the app will use.
3. Record the return at the same sample rate as the reference.
4. Export the recording as PCM16 WAV, exactly as captured. Do not trim the
   start, normalize, denoise, or apply a fade.
5. Run `loopback`.

A single interface that clocks both playback and recording gives the cleanest
offset and drift measurement. A phone output feeding a laptop input includes
two clocks; that is still a valid measurement of the practice setup, but drift
then belongs to the pair, not to the phone alone.

### Tap method (speaker and microphone)

1. Place the device at the normal practice distance, in the normal room.
2. Play `ref60.wav` through the speaker.
3. Record with the device microphone at the same gain used for lessons.
4. Export as PCM16 WAV without processing.
5. Run `loopback`.

The tap method measures output latency, the acoustic path, and input latency
together. That total is what the scorer experiences, so it is useful. Its
tradeoffs are room reflections, a small distance term (about 0.3 ms per 10 cm),
and microphone automatic gain. Use a quiet room, disable AGC/noise suppression,
and repeat the take three times. Treat the median as the device value and the
spread as measurement uncertainty.

Tap calibration cannot separate output latency from input latency. Cable
loopback can. Use cable for the decision when available; use tap to confirm the
real practice path.

## Speaker, wired headphone, and Bluetooth procedure

Record one condition at a time, then record the next condition without changing
the microphone position or gain.

1. **Wired headphones.** Connect wired headphones before starting playback.
   Record the click with the microphone. This is the lowest-latency condition
   and should pass first.
2. **Speaker.** Disconnect headphones, keep the same microphone position, and
   record again. The offset should include the acoustic path. If the offset
   passes but the guitar bleed test fails, headphones are mandatory.
3. **Bluetooth.** Pair the device, wait for the codec to settle, and record a
   full 60 s take. Bluetooth adds codec and buffer latency, commonly
   100-300 ms. A Bluetooth take that fails the 10 ms offset gate must not be
   used for scored timing, even if the app feels responsive.

Run the same click reference in all three conditions and keep each take. Do not
compare a Bluetooth take with a speaker take that used a different reference
file, sample rate, or microphone gain.

For the product decision, a device passes only when the condition used during
scored practice passes. If scored practice uses the speaker, a passing wired
headphone take does not rescue it.

## Bleed procedure

Bleed is measured with guitar notes, not with a click-only take.

1. Choose a 4-8 note phrase at 60-90 BPM. Use a real phrase from the corpus or
   the app.
2. Record the phrase twice with the same microphone, gain, and distance:
   - **Speaker condition:** click or backing track audible through the device
     speaker.
   - **Headphone condition:** the same click or backing through wired
     headphones, with no speaker output.
3. Export both takes as PCM16 WAV at the same sample rate.
4. Write `expected.json` for the **guitar note onsets**, not the click onsets.
5. Run:

```powershell
dart run tool/latency_rig.dart bleed `
  --speaker speaker.wav `
  --headphones headphones.wav `
  --expected expected.json
```

6. Pass when `recallDrop <= 0.05` and
   `speakerFalseOnsetsPerMinute <= 1`.

The committed `speaker.wav` and `headphones.wav` fixtures simulate the failure
case: three notes are masked and three bleed clicks are added. They exist to
prove the gate fails. They are not evidence that a real device leaks.

If bleed fails:

- Require wired headphones for scored takes.
- Remove drones and backing tracks from scored takes.
- Lower the click level or use a shorter, higher-frequency click.
- If none of those work, score notes only and drop the "in time" claim.

## Labeling expected onsets

An expected manifest is a JSON file. The rig accepts any of these forms:

```json
[0.5, 1.5, 2.5, 3.5]
```

```json
{ "onsetsSeconds": [0.5, 1.5, 2.5, 3.5] }
```

```json
{
  "notes": [
    { "onsetSeconds": 0.5 },
    { "onsetSeconds": 1.5 }
  ]
}
```

Rules:

- Onsets are seconds from sample 0 of the recorded WAV.
- Values must be finite and non-negative. They are sorted for matching.
- Use the intended note attack, not the peak of the recording.
- The default match window is 50 ms. Override it with `--match-window-ms` only
  when the phrase has genuinely wider timing.
- For a click-loopback take, `generate --expected-out` writes the manifest for
  you.
- For guitar phrases, place markers on the waveform in a DAW at the first
  visible attack of each note, then export the marker times. Round to 1 ms.
- Do not label a note that was not played. A missing note lowers recall; that
  is the measurement working, not a labeling error.

## Reading the output

Every measurement command prints a table and a final decision:

```text
Metric                Measured        Gate                Result
offset                5.00 ms         <= 10.00 ms         PASS
drift                 -0.00 ms/60s    <= 20.00 ms/60s     PASS
false onsets          0.00 /min       report only         -
note recall           1.000           report only         -

timingUsable: YES (offset + drift; bleed is a separate gate)
```

The JSON form is one object on stdout and nothing else. Progress messages from
the Dart toolchain go to stderr. Exit codes:

| Code | Meaning |
|---|---|
| 0 | Every decision gate passed |
| 1 | At least one decision gate failed |
| 2 | Bad input: missing file, malformed WAV, malformed manifest |

`--json` output for `loopback` includes `offsetMs`, `driftMsPer60s`,
`falseOnsetsPerMinute`, `noteRecall`, `timingUsable`, `failures`,
`expectedOnsets`, `matchedOnsets`, `detectedOnsets`, and the active `gates`.
`recall` and `bleed` use the same shape with their own decision fields.

## Device matrix

Fill this in from real device runs. Leave a row blank until the take exists;
do not copy values from another device or from the simulated fixtures.

| Device | OS / browser | Sample rate | Path | Offset (ms) | Drift (ms/60 s) | False onsets (/min) | Decision | Date | Evidence |
|---|---|---:|---|---:|---:|---:|---|---|---|
| Mid-range Android (e.g. Pixel 6a) | Android 14 | 48000 | Wired loopback | - | - | - | Not run | - | - |
| Mid-range Android (e.g. Pixel 6a) | Android 14 | 48000 | Speaker + mic | - | - | - | Not run | - | - |
| iPhone (e.g. iPhone 13) | iOS 17 | 48000 | Wired loopback | - | - | - | Not run | - | - |
| iPhone (e.g. iPhone 13) | iOS 17 | 48000 | Speaker + mic | - | - | - | Not run | - | - |
| Tablet (e.g. iPad) | iPadOS 17 | 48000 | Wired loopback | - | - | - | Not run | - | - |
| Laptop | Windows 11 + Chrome | 48000 | Cable loopback | - | - | - | Not run | - | - |
| Laptop | macOS + Safari | 48000 | Cable loopback | - | - | - | Not run | - | - |

For each row, record at least three 60 s takes and report the median. Attach or
link the WAV files and the JSON output. A row is complete only when the
`loopback` decision, the `recall` decision, and (for speaker conditions) the
`bleed` decision are all recorded.

## What the rig does not measure

- Musical timing, groove, swing, rubato, or expressive timing.
- Strumming, chords, or any polyphonic attack. The onset detector sees one
  energy peak per event.
- Pitch accuracy, intonation, or timbre.
- The app's real-time scheduler, frame drops, or battery behavior.
- Bluetooth codec changes that happen after the calibration take.
- Room acoustics beyond the speaker/headphone comparison.
- Whether the app recorder actually opened the sample rate you requested. That
  is a separate configuration check (T1.3).
- The scorer's phrase-level false-pass/false-fail rates. Those belong to the
  phrase-scoring spike, not this rig.

## Fixture provenance

The WAV fixtures were produced with the `generate` and `simulate` commands in
this tool, plus a one-off script for the bleed pair:

- `ref.wav`: 12 s, 16 kHz, mono, 23 clicks every 0.5 s starting at 0.5 s.
- `take.wav`: `ref.wav` with a known +5 ms offset.
- `late.wav`: `ref.wav` with a known +25 ms offset.
- `headphones.wav`: copy of `take.wav`.
- `speaker.wav`: `ref.wav` with three notes removed and three bleed clicks
  added at non-note times.
- `expected.json`: the 23 reference onset times.

Because they are generated, they prove the analyzer and CLI work. They do not
prove any device passes.
