# Sound Design

Hear Me Out uses an original **Bright Pluck** sound family. The goal is a
friendly, musical learning loop like Duolingo, without copying Duolingo’s
copyrighted audio.

## Family rules

- **Body:** short plucked synth with a bright second and third harmonic.
- **Reward:** glass-bell partials, bright but gentle.
- **UI:** dry high blip, short and quiet.
- **Negative:** soft low plucked thud or descending phrase — never a harsh buzzer.
- **Key center:** C major for every reward cue.
- **Processing:** shared EQ, a very short room tail, peak normalized to −1.7 dBFS.
- **No** chiptune leads, cinematic risers, spoken words, or random stock clips.
- **No** sound while the tuner or lesson mic is actively listening, except the
  answer-feedback cue after the answer is committed. Tuner start/stop sounds are
  played by the button before capture begins.
- **Do not stack a tap, an answer sound, and a reward sound.** The UI plays one
  deliberate cue at a time; result screens may play one base cue followed by one
  reward cue and one XP tick.

## Ear-training audio

Ear-training questions use a local synth (`core/audio/synth.dart`) rather than
bundled per-pitch assets. It renders a short plucked-string WAV from a
`SoundSpec` (single note, interval, chord, progression, or melody). The engine
stops any stimulus before the microphone starts. The synth is a musical prompt,
not UI feedback, so it is mixed quieter than answer cues.

## Asset map

All files live in `flutter_app/assets/audio/`. They are mono 44.1 kHz, 16-bit
PCM WAV. The family is intentionally small.

| Asset | Use |
|---|---|
| `ui_tap_primary.wav` | Primary buttons |
| `ui_tap_secondary.wav` | Outline/secondary buttons |
| `ui_select.wav` | Mode tabs, goal chips, string chips, settings cycles |
| `ui_navigate.wav` | Bottom navigation |
| `ui_toggle_on.wav` | Haptics/sound switches on |
| `ui_toggle_off.wav` | Haptics/sound switches off |
| `ui_locked.wav` | Locked lesson, destructive confirm |
| `ui_page.wav` | Onboarding page continue |
| `lesson_start.wav` | Entering a lesson or practice session |
| `tuner_on.wav` | Tuner start |
| `tuner_off.wav` | Tuner stop |
| `answer_correct.wav` | Correct answer |
| `answer_correct_combo.wav` | Correct answer with combo >= 3 |
| `answer_wrong.wav` | Wrong answer |
| `answer_octave.wav` | Right note, wrong octave |
| `lesson_complete.wav` | Passed lesson |
| `lesson_perfect.wav` | Passed lesson with 100% accuracy |
| `lesson_failed.wav` | Lesson finished below the pass accuracy |
| `practice_complete.wav` | Passed practice session |
| `reward_streak.wav` | Streak advanced |
| `reward_streak_milestone.wav` | Streak hits 7/14/30/50/100/180/365 |
| `reward_weekly_goal.wav` | Weekly minutes goal reached |
| `reward_level_up.wav` | Level increased |
| `reward_unlock.wav` | Finish onboarding; unlock moments |
| `xp_tick.wav` | One small XP tally after a result |
| `copy_success.wav` | Backup copied/restored |
| `error_soft.wav` | Clipboard/error recovery |

## Event map

- **Shared buttons:** `DuoButton` plays `uiTapPrimary`, `OutlineDuoButton` plays
  `uiTapSecondary`, and both accept a `sound:` override for special actions.
- **Onboarding:** mode tabs/goal chips use `uiSelect`; page continue uses
  `uiPage`; final “Let’s Play” uses `rewardUnlock`; mic test/skip uses button
  sounds; no sound is played while the mic is listening.
- **Path:** current/completed lesson node → `lessonStart`; locked node →
  `uiLocked`; opening a unit guidebook → `uiSelect`; completing a musical quest
  → `copySuccess`.
- **Lesson:** correct → `answerCorrect`; combo 3+ → `answerCorrectCombo`;
  wrong → `answerWrong`; octave → `answerOctave`; result screen →
  completion/failure cue, then one reward cue (level > weekly goal > streak
  milestone > streak) and `xpTick`. There is no life-lost cue.
- **Quests:** completing a musical quest may play `copySuccess`. There is no
  purchase, claim, or currency cue.
- **Practice:** tuner button uses `tunerOn`/`tunerOff`; string select uses
  `uiSelect`; starting due/weak/free practice uses `lessonStart`; answer and
  result cues reuse the lesson family.
- **Profile:** settings cycles use `uiSelect`; haptics/sound toggles use
  `uiToggleOn/Off`; copy/restore use `copySuccess` or `errorSoft`; reset uses
  `uiSelect` and `uiLocked`.
- **App:** startup-error retry uses `uiTapPrimary`.

## Settings and lifecycle

`AppSettings.soundEffects` defaults to `true`, persists in the progress JSON, and
is exposed as **Profile → Sound effects**. It is independent of haptics. The
service mirrors the setting from `AppController` whenever settings load, change,
restore, or reset. Cues are short one-shots, so there is no loop to stop; the
audio context uses:

- Android: sonification/game usage, no audio focus.
- iOS: ambient category, respecting the Ring/Silent switch and mixing with other
  audio.
- Web: browser-managed playback after the first user gesture.

Core cues are preloaded at startup. Rare reward cues are created lazily so the
app does not keep dozens of native players alive on low-end devices.

## Implementation

- `flutter_app/lib/shared/audio/sound_service.dart` — `Sfx` enum, service,
  preloading, audio context, volume per cue.
- `flutter_app/lib/state/providers.dart` — `soundServiceProvider`.
- `flutter_app/test/support/fakes.dart` — `FakeSoundService`.
- `flutter_app/tool/generate_sounds.py` — deterministic generator for every asset.
- `flutter_app/tool/soundboard.html` — audition page for all cues.

Regenerate assets:

```powershell
cd flutter_app
python tool/generate_sounds.py
flutter build web --release
```

Audition locally:

```powershell
cd flutter_app
python -m http.server 8081 --directory build/web
```

Then open `/soundboard.html` on that server. The soundboard is a development
tool; it is not part of the Flutter app.

## Review notes

- Correct/combo/complete/perfect share a C-major pluck + bell palette.
- Wrong/octave/failure use lower, softer plucked phrases rather than buzzers.
- UI taps are short dry blips and are mixed at a lower volume.
- `xp_tick` is deliberately quiet; it is a tally, not a celebration.
- Do not add a continuous tuner beep: the microphone would hear it.
- Do not use rips of Duolingo sounds or other copyrighted app audio. The family
  is original and generated from code in this repository.
