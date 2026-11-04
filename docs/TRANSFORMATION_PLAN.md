# Hear Me Out — Transformation Plan

**Status:** Draft for adversarial review  
**Date:** 2026-11-03  
**Scope:** Product, curriculum, learning science, audio/AI, growth, monetization  
**Decision:** Evolve the existing notation trainer into a song-first guitar practice system, keeping the FSRS engine and guitar-correct notation as core assets.

---

## 0. Executive summary

Hear Me Out today is a well-engineered **notation and music-theory quiz app with a guitar skin**. It has a real spaced-repetition engine, honest pitch detection, and a coherent visual language. But it does not yet deliver the thing a guitarist actually wants: **playing music they care about, hearing themselves improve, and having a reason to come back tomorrow.**

The audit is blunt:

- 240 lessons, but only **153 unique learning objectives**.
- **3,984 scored prompts**, of which **54.6% are multiple choice**.
- Only **15.2%** require playing a note into the microphone.
- **Zero** repertoire, sight-reading, or improvisation objectives in the course, despite those families existing in code.
- The "Today" card is just the next lesson in a linear path.
- The course can be completed. Then the product has nothing left to teach.

The transformation:

> **Turn Hear Me Out from a finite course about music into an infinite practice system built on songs.**

The new core loop is:

```
choose a song → hear it → play a phrase → diagnose the limiting bar
→ generate a drill → apply it back to the song → perform/record
→ update the learner model → next session
```

The FSRS scheduler, mastery gates, repair chain, written-vs-sounding pitch model, and mic pipeline stay. The 240-lesson path becomes a **structured reading path inside a larger song-first product**, not the whole product.

Success means:

- A new learner plays a real phrase in the first five minutes.
- A returning learner can start at their level, not at open strings.
- Every song generates dozens of exercises, so content is never exhausted.
- A learner can hear a before/after recording within seven days.
- The app can be recommended to a friend with a shareable performance card.
- The business can charge for the value it creates without betraying the privacy promise.

---

## 1. Current-state audit

### 1.1 What the code actually ships

I audited the generated course by building every lesson and counting the prompts.

| Metric | Current value |
|---|---:|
| Lessons | 240 |
| Scored prompts | 3,984 |
| Unique objectives | 153 |
| Multiple-choice prompts | 2,176 (54.6%) |
| Note-play prompts (mic) | 606 (15.2%) |
| Rhythm-tap prompts | 395 (9.9%) |
| Fret-tap prompts (on-screen) | 317 (8.0%) |
| Note-name prompts | 264 (6.6%) |
| Order/build prompts | 140 (3.5%) |
| Teach cards | 43 (1.1%) |
| Staff-tap prompts | 43 (1.1%) |
| Repertoire objectives | 0 |
| Sight-reading objectives | 0 |
| Improvisation objectives | 0 |
| Technique objectives | 22 prompts |

Family mix across the generated lessons:

| Family | Prompt references |
|---|---:|
| Theory | 1,547 |
| Harmony | 1,016 |
| Ear | 612 |
| Rhythm | 520 |
| Fretboard | 478 |
| Technique | 22 |
| Repertoire / sight-reading / improvisation | 0 |

The helpers `repertoireConcept`, `sightReadingConcept`, and `improvisationConcept` exist in `course_concepts.dart` but are **never called** by `course_data.dart`. The `repertoire`, `sightReading`, and `improvisation` templates are all the same `ChoiceTemplate`. They are labels, not behaviors.

### 1.2 What the learner experiences

From the built web app and the UI code:

- The path is a long column of identical locked music-note nodes. There are no song titles, no lesson labels, no album art, no sense of what is ahead.
- The "Today" card says "Next: Discover" and "Lesson 1 of 240." It is a course player, not a daily practice plan.
- The first unit is open strings. A learner may not play a recognizable piece for weeks.
- The path has a chest, a streak, gems, hearts, quests, and a shop. The gamification is Duolingo-shaped, but the musical payoff is thin.
- Lessons are one prompt at a time: name a note, tap a staff, tap a fret, choose an interval, choose a chord shape. The mic is used for single notes only.
- Practice is a review queue over the same objectives. It is not "practice a song."
- There is no recording, no playback, no performance mode, no backing track, no jam, no share.
- Onboarding asks only for a daily XP goal. It does not ask experience, taste, goals, or a placement test.

### 1.3 Strengths to protect

1. **FSRS-6-style scheduler** with stability, difficulty, retrievability, mastery gates, production/transfer evidence, repair chain, fragile/leech states. This is more sophisticated than most consumer music apps.
2. **Guitar-correct notation**: written pitch vs sounding pitch, first-position fingerings, octave-error detection.
3. **Honest pitch feedback**: YIN detector, stability frames, cents tolerance, grace period, octave errors.
4. **Clean architecture**: `core/` is widget-free and testable; `content/` is additive; 224 tests pass; web build succeeds.
5. **Coherent visual language**: Duolingo-style but original mascot and sound family.
6. **Privacy-first**: local-only progress, no network, no analytics. This is a trust asset if made explicit and optional rather than an obstacle.

### 1.4 Root causes

1. **The unit of content is a lesson, not a musical behavior.** The course is a deck of facts and single notes. Music is phrases, songs, grooves, and performance.
2. **The curriculum is padded.** 240 lessons from 153 objectives means most lessons repeat the same objectives with different prompt surfaces. The path looks longer than the learning.
3. **Theory is over-weighted because it is easy to author.** Multiple-choice questions are cheap to generate and test; phrase assessment is hard. The product optimized for authoring cost, not learner value.
4. **The app has no emotional payoff.** There is no "I can play that" moment, no recording, no performance, no share.
5. **Gamification is compensating for a weak core loop.** Hearts, gems, chests, and streaks are doing work the musical experience should do.
6. **The product is optimized for completion, not retention.** A finite course is a churn machine at the end; a practice system with songs and feedback is not.

---

## 2. Product thesis and positioning

### 2.1 The thesis

**People do not want to finish a music course. They want to play songs they love, feel themselves getting better, and have a reason to pick up the guitar tomorrow.**

The app should be a **practice coach**, not a course library:

> **Play guitar. Read music.**  
> Learn the songs you love, one phrase at a time, with a coach that hears you and always knows what to practice next.

The reading path remains a differentiator: most guitar apps teach tabs or shapes; Hear Me Out can teach real notation and musicianship. But reading must be **in service of playing**, not the product itself.

### 2.2 Who it is for

Primary: **adult and young-adult beginners and returners (16–45)** who:

- own a guitar and can play a little, or are starting from zero;
- have 10–20 minutes a day, not an hour;
- want to play songs, not study theory;
- practice alone, often on a phone;
- are willing to pay for a coach that replaces or supplements lessons.

Secondary:

- **Intermediate players stuck at a plateau** who need diagnosis and structured practice.
- **Teachers and music schools** who need assignment, tracking, and recording review.
- **Parents** who want to see real progress, not streaks.

Not the target initially: professional players, producers, DAW users, children under 10 (needs a different UX and parental controls).

### 2.3 The infinite-practice promise

Do not promise "unlimited content." Promise **"always the next step."**

The content multipliers:

| Multiplier | What it does | Example |
|---|---|---|
| Decompose | One song → many phrases and bars | Loop the chorus, isolate the shift, separate melody/bass |
| Vary | Same phrase, new constraints | Tempo ladder, transpose, rhythm displacement, dynamics, articulation |
| Generate | New material at target difficulty | Sight-reading phrases, technique drills, call-and-response |
| Create | Learner makes the content | Improvise over a backing track, compose a variation |
| Curate | Community and teacher content | Weekly challenge, UGC arrangement, studio assignment |

One 8-bar phrase with 5 tempo levels, 12 keys, 4 articulations, 3 dynamics, 4 rhythm variants, and 2 hand options yields 5,760 versions. Most are musically useless; even 2% useful is 115 exercises from one phrase. That is the content engine.

### 2.4 What the app is not

- Not a bigger song library with licensed hits.
- Not a DAW, tab editor, or social network.
- Not a gamified quiz with a guitar icon.
- Not a replacement for a teacher; the layer between lessons.
- Not an AI that generates full songs and calls it pedagogy.

---

## 3. Design principles

These principles are the contract for every feature. Each is tied to evidence.

1. **Play first.** At least 50% of scored prompts in a session must require playing the instrument; at least 30% must be a phrase or song, not a single note.  
   *Why:* self-selected repertoire increases persistence and strategy use (Renwick & McPherson, 2002); flow requires challenge-skill balance (2020 adaptive music study).

2. **One song from day one.** The first session ends with the learner playing a recognizable phrase with a backing track.  
   *Why:* emotional payoff and identity; most beginners churn before they experience music-making.

3. **Diagnose → drill → apply → perform.** Never drill in isolation without applying it back to the song in the same session.  
   *Why:* transfer-appropriate processing; deliberate practice needs a clear target and feedback (Macnamara et al., 2014; ITS meta-analysis, Ma et al., 2014).

4. **Target 80% success.** Adapt tempo, phrase length, and complexity in real time. Too easy is boring; too hard is frustrating.  
   *Why:* flow theory; dynamic difficulty adjustment research; the 2020 adaptive piano study.

5. **Interleave, don't block.** Rotate song, technique, ear, and rhythm within a session; revisit across days.  
   *Why:* interleaved practice improved advanced clarinet performance vs blocked repetition (Frontiers in Psychology, 2016); variable practice improves transfer.

6. **Ask the learner to judge first.** Before showing a score, ask "How did that feel?" Then show evidence and one correction.  
   *Why:* self-regulated learning; a 2026 review warns that AI assessment can create dependence when learners outsource evaluation.

7. **Autonomy.** Let the learner choose the song, the goal, and the style; the app chooses the path.  
   *Why:* self-determination theory (Evans, 2015); autonomy-supportive teaching predicts practice quality.

8. **Relatedness.** Give a weekly recital, a practice buddy, a studio, or a teacher. Music is social.  
   *Why:* SDT relatedness; Tonic's success with live practice studios; Duolingo's leagues (but avoid pressure).

9. **No punishment loops.** Mistakes trigger repair, not lost lives. Never block a lesson because of a wrong answer.  
   *Why:* gamification meta-analysis found short-term gains but long-term negative associations; hearts punish the exact behavior beginners need.

10. **Honest feedback.** Score what you can measure; say what you cannot. Never fake a statistic.  
    *Why:* trust; the current app already protects this.

11. **Privacy by default, sharing by choice.** Local-first; optional encrypted sync; explicit consent for any upload.  
    *Why:* trust and differentiation from ad-funded apps.

12. **Author generators, not lessons.** A lesson teaches one thing once; a generator teaches many things forever.  
    *Why:* the content treadmill; automatic item generation research.

---

## 4. The new core loop

### 4.1 Today session (12–15 minutes)

The home screen becomes a daily plan, not "next lesson."

| Block | Time | What happens |
|---|---:|---|
| Tune + warm-up | 2 min | One due skill or technique drill; ear call-and-response |
| Song focus | 6 min | One phrase from the current song; diagnose; 2–3 drills; apply |
| Play | 4 min | Full phrase/song at tempo with backing track; record |
| Reflect | 1–2 min | Self-rating first; app shows evidence and one correction; save take |

The session always contains a song. The learner can swap the song, shorten the session, or choose "just practice" without losing progress.

### 4.2 Song Lab

A library of songs and pieces, each with:

- 3 levels: melody, melody + bass/thumb, chords/strum or fingerstyle.
- 4–8 phrases per level.
- A backing track (bass, drums, chord pad) at adjustable tempo.
- Skill tags: notes, rhythm, chords, technique, ear.
- A "learn" flow: listen → clap → play slowly → play with backing → perform.
- "Fix this bar": select a bar; app diagnoses and generates drills.

The Song Lab is the new home. The structured path is one way through it.

### 4.3 Skill map

The FSRS graph becomes visible:

- **Can play** (mastered, with production + transfer evidence).
- **Shaky** (fragile, due soon).
- **Learning** (new or weak).
- **Next** (recommended, at the edge of ability).

The map shows musical behaviors, not lesson numbers: "read E4–G4," "keep 8th-note strumming," "hear a minor third," "change G→C in time."

### 4.4 Performance and recital

- **Record** a take locally.
- **Compare** to the previous take and the reference.
- **Share** a performance card (image + optional audio clip) with privacy controls.
- **Weekly recital**: one take, one peer comment, one teacher comment (if in a studio).

This is the emotional and viral core.

### 4.5 Loop diagram

```
choose song
   ↓
listen / read phrase
   ↓
play phrase → diagnose limiting bar
   ↓
generate drill (tempo / loop / rhythm / transpose)
   ↓
apply back to phrase
   ↓
perform with backing track → record
   ↓
self-assess → app evidence → update learner model
   ↓
next session
```

---

## 5. Feature specifications

### 5.1 Song and phrase model

New domain models in `lib/core/music/`:

```dart
class Song {
  final String id;
  final String title;
  final String composer;
  final String genre;
  final Difficulty difficulty;
  final List<SongLevel> levels;
  final String license; // publicDomain, original, licensed
}

class SongLevel {
  final int level; // 1 melody, 2 melody+bass, 3 chords/strum
  final List<Phrase> phrases;
  final BackingTrack backingTrack;
}

class Phrase {
  final String id;
  final String songId;
  final int level;
  final int startBar;
  final int barCount;
  final int bpm;
  final List<NoteEvent> notes;
  final List<RhythmEvent> rhythm;
  final List<Fingering> fingerings;
  final Set<SkillId> skills;
  final String? tabHint;
}

class NoteEvent {
  final int midi;
  final double startBeat;
  final double durationBeats;
  final int string;
  final int fret;
  final Dynamic dynamic;
  final Articulation articulation;
}
```

Authoring format: YAML or JSON with validation tests.

```yaml
song: ode-to-joy
title: Ode to Joy
license: public-domain
level: 1
bpm: 80
phrases:
  - bars: 1-4
    notes:
      - {midi: 64, start: 0, duration: 1, string: 4, fret: 2}
      - {midi: 64, start: 1, duration: 1, string: 4, fret: 2}
      - {midi: 65, start: 2, duration: 1, string: 4, fret: 3}
      - {midi: 67, start: 3, duration: 1, string: 4, fret: 5}
```

Validation:

- every note has a valid guitar position within the target position;
- phrase duration matches bar count and time signature;
- no overlapping monophonic notes at level 1;
- tempo and difficulty are within the level band;
- all referenced skills exist in the skill catalog;
- public-domain/original license is present.

### 5.2 Phrase assessment

The current `NoteMatcher` is designed for one sustained note. Phrase assessment needs note segmentation and alignment.

**V1 approach (monophonic, slow-to-medium tempo):**

1. Capture PCM as today.
2. Detect note onsets via RMS flux and pitch stability changes.
3. For each onset, estimate MIDI with YIN; require 2–3 stable frames.
4. Align detected events to target events with dynamic time warping (DTW), allowing tempo scaling and small insertions/deletions.
5. Score:
   - **Note accuracy**: percentage of target notes matched within ±1 semitone (with octave-error flag).
   - **Timing**: mean absolute deviation from the aligned beat grid; flag rushed/dragged bars.
   - **Tempo stability**: variance of inter-onset intervals.
   - **Completeness**: missed notes and extra notes.
6. Feedback:
   - "Bar 2, beat 3: you rushed the change from G to C."
   - "Right notes, but the last two eighths were uneven."
   - "You stopped at bar 3; loop bars 1–3 at 60 BPM."
7. If confidence is low, show "I couldn't hear that clearly" and offer a slower tempo or self-rating. Never punish a false negative.

**V1.1 MIDI path:** support USB/Bluetooth MIDI guitar or interface. Exact pitch/timing; use it for chords and fast passages. This de-risks the hardest assessment problems and serves electric guitar players.

**V2 audio chords:** chroma/template matching for open chords (C, G, D, A, E, Am, Em, Dm). Confidence threshold; fallback to "did it feel clean?" self-rating. Do not claim chord accuracy until validated on real recordings.

**Technical risks:**

- Fast passages and polyphony are hard; limit V1 to monophonic phrases at 60–100 BPM with quarter/eighth notes.
- Guitar harmonics can cause octave errors; add harmonic correction and octave-error feedback.
- Phone mic quality varies; test on 10 devices, 5 room conditions.
- Latency: process in 2–4 second chunks; feedback after the phrase, not real-time.

### 5.3 Drill generator

Rule-based first. Inputs: phrase, target skill, error profile, current tempo, difficulty.

Templates:

1. **Tempo ladder**: 50/60/70/80/90/100% of target; pass at 80% accuracy twice to advance.
2. **Loop**: bar range; 1 bar, 2 bars, 4 bars; overlap by one bar.
3. **Hands separate**: melody only; bass/thumb only; then together.
4. **Rhythm displacement**: shift onsets by 1/8 or 1/4; add rests; syncopate.
5. **Transpose**: ±1, ±2, ±5 semitones; keep fingering shape where possible.
6. **Dynamics**: p, mp, mf, f; same phrase, different dynamic.
7. **Articulation**: legato, staccato, accent; compare tone.
8. **Call-and-response**: app plays, learner echoes; then swap; length adapts.
9. **Sight-reading**: generate a new 2–4 bar phrase from a grammar at target difficulty.
10. **Improv constraint**: backing track + 3 notes, chord tones, question/answer, trade 4s.

Selection policy:

- If accuracy <70%: slow down, shorten phrase, isolate one bar.
- If 70–85%: repeat at same level with one variation.
- If >85% twice: increase tempo or add complexity.
- Rotate templates; never repeat the same template twice in a row.
- Respect FSRS due dates; a due skill can replace the warm-up.

### 5.4 Backing tracks

- Generate with the existing synth/or a small sample library.
- Styles: folk strum, classical pad, blues shuffle, rock backbeat, metronome-only.
- Tempo 40–140 BPM, adjustable in 5 BPM steps.
- Mix: bass, drums, chord pad, click; volume controls.
- Count-in: 1 bar; visual beat indicator.
- Loop: phrase or full song.
- No network; render locally to WAV or stream via `audioplayers`.

### 5.5 Recording, performance, and sharing

- Record locally with the `record` package; save to app documents.
- Playback with A/B comparison: current take vs previous take.
- Waveform + pitch/timing overlay; highlight the worst bar.
- Performance mode: no stops, no hints, one score; share card.
- Share card: song, level, accuracy, timing, streak, a 15-second audio clip; privacy toggle.
- Default: private. No upload without explicit action.
- Storage: cap recordings (e.g., 50 takes), auto-delete oldest; export/delete.

### 5.6 Ear-to-hand and improvisation

**Ear-to-hand (call-and-response):**

- App plays a 2–4 note phrase; learner plays it back.
- Adaptive length: 2 notes → 3 → 4 → 5; intervals, scale degrees, chord tones.
- Assessment: pitch + timing; partial credit for contour.
- This replaces "which interval is this?" MC as the primary ear task.

**Improvisation:**

- Backing track (12-bar blues, pop loop, modal vamp).
- Constraint: use only 3 notes; target chord tones; question/answer; trade 4s; one-note solo.
- Assessment: rhythm/onset, note choice against chord tones, phrase length; no "wrong notes" shaming.
- Record and reflect; optional share.
- This is the "learner as content" multiplier.

### 5.7 Chord and strumming

**V1:** MIDI input for exact chord/strum assessment. Support open chords and simple progressions. This is enough for electric players and tests the pedagogy.

**V1.5:** Audio chroma for open chords; confidence threshold; fallback to self-rating.

**V2:** strum pattern timing via onset detection; down/up detection is hard—start with "strum in time" not "correct direction."

Do not claim chord quality assessment from phone mic until validated.

### 5.8 Curriculum redesign

Current: 40 units × 6 lessons = 240 lessons, 153 objectives, theory-heavy.

New:

- **40 units, each with a song outcome.** Example: Unit 1 "Open Strings" → play the open-string riff of "Ode to Joy" (simplified); Unit 14 "Strumming" → play a 4-chord folk progression in time.
- **6 sessions per unit**, but only 4 are core; 2 are optional mastery:
  1. **Discover** — listen, read, learn the phrase.
  2. **Build** — isolate the hard bar; drills.
  3. **Connect** — rhythm/ear/chord context.
  4. **Apply** — play with backing; record.
  5. **Integrate** — new key/tempo/context; transfer.
  6. **Perform** — full piece/checkpoint; record/share.
- **30% max theory/reading, 50% playing, 20% rhythm/ear.** Enforce in the session validator.
- **Placement test:** 5 minutes; play a phrase, tap a rhythm, name notes, identify chords; place at unit 1/6/12/20/30.
- **Choice:** two song options per unit; same skills, different repertoire.
- **Side quests:** technique, ear, sight-reading, improvisation; optional, rewarded.
- **Core path:** 120 sessions (about 6 months at 5/week); mastery path adds 120 optional sessions. The product no longer ends at 240.

### 5.9 Gamification redesign

**Remove hearts as a gate.** Replace with:

- **Streak:** any completed practice session (not just lesson) advances; freeze optional.
- **Weekly goal:** minutes or phrases, not XP.
- **Mastery map:** the primary progress visual.
- **Performance badges:** first recording, first full song, 5-day streak, 10 clean phrases.
- **Challenges:** weekly phrase, opt-in; leaderboard by accuracy/timing, not spending.
- **Gems/chests:** keep only as cosmetic/reward layer; no heart refills; no punishment economy.
- **Quests:** "play 3 phrases," "record a take," "learn a new chord," "practice 10 minutes," not "answer 10 notes."
- **Confetti:** only on performance/recording, not every correct answer.

### 5.10 Social, teacher, and accountability

- **Weekly recital:** asynchronous; record a 30–60s take; one peer/teacher comment.
- **Practice buddy:** opt-in; see weekly minutes and one recording; no feed.
- **Teacher studio:** create a class, assign songs/drills, see practice data and recordings, comment. B2B2C.
- **Challenge links:** "Can you play this at 80 BPM?" share a link; friend tries in web/app.
- **Community:** later; UGC arrangements with licensing/moderation.

### 5.11 Monetization

- **Free:** core 40 units, 10 songs, daily practice, basic feedback, local-only.
- **Pro:** $9.99/month or $59/year: full Song Lab (100+ songs), all levels, recordings, generative drills, advanced feedback, cloud sync, offline.
- **Lifetime:** $149 early adopter.
- **Teacher:** $5/student/month, dashboard, assignments, recordings.
- **No ads.**
- Validate with a fake-door/pre-sale before building the full paywall.

### 5.12 Analytics and experiments

Privacy-respecting, opt-in, local-first. Events:

- onboarding start/complete, experience/taste selection;
- first phrase played/passed, first recording;
- session start/complete, block durations;
- phrase attempts, accuracy, timing, tempo;
- drill type, pass/fail, next action;
- song started/completed, level;
- recording created/shared;
- paywall view, trial start, purchase, cancel;
- mic failure/false-negative reports.

North star: **weekly successful phrases** (phrase played at target tempo with ≥80% accuracy and recorded) or **weekly effective practice minutes**. Use phrases as the primary; minutes as a guardrail.

Targets (first 6 months after launch):

| Metric | Target |
|---|---:|
| First phrase played in first session | ≥70% |
| First phrase passed in first session | ≥50% |
| First recording within 7 days | ≥30% |
| D1 | ≥50% |
| D7 | ≥35% |
| D30 | ≥20% |
| 3+ sessions/week among actives | ≥40% |
| Free → Pro by day 30 | ≥5% |
| Phrase accuracy improvement first→last | ≥20% |
| Timing deviation reduction | ≥30% |
| NPS | ≥40 |

Experiments:

1. Song-first vs course-first onboarding.
2. Hearts vs no hearts.
3. Recording vs no recording.
4. Backing track vs metronome only.
5. Weekly recital vs no recital.
6. Rule-based vs AI feedback.
7. 12-min vs 20-min default session.
8. Learner-chosen song vs assigned song.
9. Public-domain vs licensed song in the first session (if licensed).
10. Share card vs private-only.

---

## 6. Technical architecture changes

### 6.1 New/changed layers

| Area | Change |
|---|---|
| `core/music/` | Add `Song`, `Phrase`, `NoteEvent`, `RhythmEvent`, `Fingering`, `BackingTrack`, `Difficulty`. |
| `core/learning/` | Add `PhraseProgress`, `PhraseAttempt`, `PracticeSession`, `SessionBlock`, `ErrorProfile`; extend `SkillProgress` with phrase/transfer evidence. |
| `core/audio/` | Add `OnsetDetector`, `PhraseMatcher`, `ChromaMatcher` (later), `BackingTrackSynth`, `Recorder`. |
| `core/learning/prompt.dart` | Add `PhrasePlayPrompt`, `EarPlayPrompt`, `ImprovPrompt`, `SightReadPrompt`, `StrumPrompt`. |
| `content/songs/` | Song JSON/YAML + parser + validator. |
| `content/drills/` | Drill templates and selection policy. |
| `features/today/` | New home session UI. |
| `features/songs/` | Song Lab, song detail, phrase player. |
| `features/performance/` | Recording, playback, A/B, share card. |
| `features/skills/` | Skill map. |
| `features/teacher/` | Teacher studio (later). |
| `state/` | New controllers/providers for song, session, recording, analytics. |
| Schema | `schemaVersion` 5: songs/phrases/recordings; 6: accounts/sync; migrations tested. |

### 6.2 Prompt and verifier design

- `PhrasePlayPrompt` carries `List<NoteEvent>`, `bpm`, `tolerance`, `backingTrackId`, `level`.
- `PhraseVerifier` returns `PhraseResult` with note accuracy, timing, tempo stability, worst bar, confidence, and feedback.
- `EarPlayPrompt` carries a target phrase and a `playback` spec; verifier compares.
- `ImprovPrompt` carries a backing track, constraint, and duration; verifier scores rhythm/note choice loosely.
- Keep `core/learning` topic-agnostic; new prompt types live in `core/learning/prompt.dart` only if the UI needs exhaustive switching.

### 6.3 Audio pipeline

```
record → PCM16 44.1k → decimate 22.05k → onset detection
→ pitch per onset (YIN) → note events → DTW alignment → score
```

- Process in chunks; feedback after phrase.
- Add a calibration step (mic latency, device noise floor).
- Add a "can't hear you" path; never fail silently.
- For MIDI: `flutter_midi_command` or platform channel; exact events; no pitch detection.

### 6.4 Testing

- Unit tests for song parsing, phrase validation, DTW, scoring, drill selection.
- Golden tests for phrase player UI.
- Integration tests with synthetic audio (sine, plucked, noise, harmonics).
- Device matrix: iPhone, Android mid-range, desktop web, Bluetooth mic.
- Regression tests for every behavior change, per AGENTS.md.

### 6.5 Migration

- `schemaVersion` 5 adds songs/phrases/recordings; old progress preserved.
- Do not silently drop completed lessons, XP, notes, or skills.
- Provide export/import; test migrations from v1–v4.

---

## 7. Content plan

### 7.1 Song shortlist (public domain / original)

Start with 30 songs, 3 levels, 4–8 phrases each.

**Classical / folk (public domain):**

- Ode to Joy (Beethoven)
- Für Elise (simplified)
- Canon in D (simplified)
- Greensleeves
- Scarborough Fair
- Amazing Grace
- Danny Boy
- House of the Rising Sun (traditional)
- Down by the Riverside
- When the Saints Go Marching In
- Twinkle, Twinkle, Little Star (rhythm/reading)
- Mary Had a Little Lamb (first phrase)

**Blues / rock (original riffs and progressions):**

- 12-bar blues in A (original)
- Shuffle riff in E (original)
- Minor pentatonic lick (original)
- Power-chord riff (original)
- Rock ballad progression (original)
- Funk groove (original)
- Fingerstyle pattern (original)

**Pop/folk progressions (original, not copied melodies):**

- I–V–vi–IV in G
- ii–V–I in C
- vi–IV–I–V in D
- 4-chord loop in Em
- Capo transposition piece

**Sight-reading etudes (original):**

- 12 generated 2–4 bar etudes at levels 1–5.

Do not use copyrighted melodies or recordings without a license. Public-domain compositions are safe; arrangements should be original.

### 7.2 Content multiplier

For each song:

- 4–8 phrases.
- 3 levels.
- 6 tempo steps.
- 5 drill templates.
- 2 hand options.
- 3 dynamics/articulations.

A 6-phrase song with 3 levels and 5 drills yields ~90 practice items before generation. 30 songs yield ~2,700 items. That is enough for years, and the drill generator can create more.

### 7.3 Authoring workflow

1. Music educator selects song and level.
2. Enters notes/rhythm/fingering in YAML.
3. Validator checks position, range, duration, license.
4. Generates MIDI/WAV preview.
5. QA: play on guitar, check notation, check backing track.
6. Add skill tags and difficulty.
7. Test in app; record reference take.
8. Publish; add to path/song lab.

### 7.4 Content team

- 1 guitarist/music educator (full-time or contract).
- 1 arranger (part-time).
- 1 QA guitarist.
- 1 editor for copy/notation.
- Community contributors later.

---

## 8. Roadmap

### Phase 0 — Baseline and de-risk (weeks 1–2)

- Recruit 20–30 beginners/returners.
- Interview 10; observe first session.
- Add opt-in analytics/event log; baseline retention.
- Build a paper prototype of Today + Song Lab; test.
- Decide: MIDI-first or mic-first for phrase assessment.
- Gate: 60% of testers say they would use the song-first version weekly; baseline D7 measured.

### Phase 1 — Song-first core (weeks 3–8)

- Song/Phrase model + schema v5.
- `PhrasePlayPrompt` + `PhraseMatcher` (monophonic, slow/medium).
- 12 public-domain phrases, 3 levels.
- Backing track synth + tempo control.
- Today session UI.
- Remove hearts from song sessions; update economy/tests.
- Gate: 20 users, 3x/week for 4 weeks; ≥60% report a specific musical improvement; D7 ≥ 40%.

### Phase 2 — Repertoire and performance (weeks 9–14)

- Song Lab: 30 songs, phrase decomposition.
- Recording/playback/A-B; performance mode.
- Fix This Bar; drill generator (rule-based).
- Placement test; onboarding segment (experience, taste, goal).
- Weekly recital; share card.
- Gate: ≥30% of weekly actives record; D30 ≥ 25%; NPS ≥ 40.

### Phase 3 — Adaptive and creative (weeks 15–22)

- Phrase FSRS; skill map integration.
- Ear-to-hand call-and-response.
- Improv mode + backing tracks.
- MIDI chord/strum assessment; chroma beta.
- Generative sight-reading.
- Gate: ≥50% of sessions use generated drills; transfer test improves vs control.

### Phase 4 — Social, teacher, monetization (weeks 23–30)

- Optional accounts/cloud sync.
- Teacher studio beta.
- Pro subscription; paywall; fake-door validation.
- Weekly challenges/leaderboards; referral links.
- Content pipeline to 100 songs.
- Gate: ≥5% free→Pro; 5 teachers/50 students pilot; LTV/CAC >3.

### Phase 5 — AI and scale (months 8–12)

- AI feedback on recordings (pitch/timing/dynamics) with guardrails.
- Audio-to-score transcription for user imports (beta).
- UGC arrangements; moderation.
- Expand to bass/ukulele if data supports.
- Gate: AI feedback improves outcomes vs rule-based; retention uplift; cost per session under target.

### 90-day sprint detail

| Week | Deliverable |
|---|---|
| 1 | User interviews; baseline analytics; decide MIDI vs mic. |
| 2 | Paper prototype; song format spec; 3 reference songs. |
| 3 | Song/Phrase models; parser; validator; tests. |
| 4 | PhrasePlayPrompt; onset detector; phrase matcher. |
| 5 | Today session UI; backing track synth. |
| 6 | 12 phrases; first user test; fix. |
| 7 | Song Lab UI; 10 songs. |
| 8 | Recording/playback; A/B; performance mode. |
| 9 | Fix This Bar; drill generator. |
| 10 | Placement/onboarding; weekly recital. |
| 11 | 30 songs; QA; device testing. |
| 12 | Launch beta; measure; decide Phase 3. |

---

## 9. Metrics and experiments

### 9.1 Funnel

```
install → onboarding → first phrase played → first phrase passed
→ first recording → second session → first song completed
→ week 2 → week 4 → paid
```

### 9.2 Targets

- Activation: 70% first phrase played; 50% first phrase passed.
- Retention: D1 50%, D7 35%, D30 20%.
- Engagement: 3+ sessions/week for 40% of actives.
- Learning: +20% phrase accuracy; -30% timing deviation.
- Social: 30% record; 10% share.
- Monetization: 5% free→Pro; 70% 6-month Pro retention.

### 9.3 Kill criteria

- If <40% play a phrase in the first session, the onboarding/song choice is wrong.
- If <25% return in week 2, the core loop is not rewarding.
- If <10% record in the first month, performance is not compelling.
- If phrase assessment false-negative rate >15%, mic-first is not viable; go MIDI-first.
- If free→Pro <2% after 3 months, the paywall/value is wrong.

---

## 10. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Phrase assessment inaccurate | High | High | MIDI-first; slow monophonic phrases; confidence; fallback; device testing |
| Content authoring too slow | High | High | Start with 10 songs; YAML + validator; contractor; reuse phrases |
| Scope creep | High | High | One instrument, one genre, one platform; kill criteria |
| Gamification backlash | Medium | Medium | Remove hearts; measure; no punishment |
| Privacy vs social conflict | Medium | Medium | Local-first; optional sync; explicit consent |
| Copyright | Medium | High | Public domain/original; private imports; legal review |
| Market crowded | High | Medium | Differentiate on songs + feedback + intermediate segment |
| AI overpromise | Medium | High | Rule-based first; AI assist; validate |
| Teacher unit economics | Medium | Medium | Tool, not marketplace; pilot |
| Solo founder bandwidth | High | High | Cut scope; 12-month plan; contractors |

---

## 11. What not to do

- Do not add more theory multiple-choice lessons.
- Do not build a 500-song licensed catalog.
- Do not add a social feed or leaderboards before the core loop works.
- Do not use an LLM to generate full songs and call it a curriculum.
- Do not keep hearts as a gate.
- Do not target all instruments at once.
- Do not build a DAW or tab editor.
- Do not claim chord/tone assessment you cannot measure.
- Do not hide the microphone fallback.

---

## 12. Open decisions

1. **Mic-first vs MIDI-first for phrase assessment.** Recommendation: mic-first for acoustic beginners, MIDI-first for electric; ship MIDI in parallel as a precision path.
2. **Pivot vs dual-track.** Recommendation: dual-track for 3 months (keep course, add Song Lab), then make Today the home.
3. **Free vs paid.** Recommendation: free core + Pro; validate with fake door.
4. **Social vs privacy.** Recommendation: local-first, optional sharing; no public feed in v1.
5. **Licensed songs.** Recommendation: public domain/original first; license 3–5 recognizable songs only after retention is proven.
6. **AI.** Recommendation: rule-based drills and feedback first; AI for transcription/explanation later.

---

## Appendix A — Research base

- Renwick & McPherson (2002), self-selected repertoire and practice behavior: https://doi.org/10.1017/S0265051702000256
- Macnamara et al. (2014), deliberate practice meta-analysis: https://pubmed.ncbi.nlm.nih.gov/24986855/
- Ma et al. (2014), intelligent tutoring systems meta-analysis: https://doi.org/10.1037/a0037123
- Interleaved practice in music (2016): https://doi.org/10.3389/fpsyg.2016.01251
- Evans (2015), self-determination theory in music education: https://doi.org/10.1177/1029864914568044
- Gamification meta-analysis (2021): https://doi.org/10.3390/ijerph18073550
- AI-assisted practice app study (2025): https://doi.org/10.3389/fpsyg.2025.1675762
- Violin real-time feedback RCT (2021): https://doi.org/10.3389/fpsyg.2021.648479
- Difficulty-aware score generation (2025): https://arxiv.org/abs/2509.16913
- Difficulty-controlled simplification (2025): https://arxiv.org/abs/2511.16228
- Tuning Music Education (2024): https://arxiv.org/abs/2412.13514
- Flow and adaptive music software (2020): https://arxiv.org/abs/2004.13362
- Empowerment vs. dependency review (2026): https://doi.org/10.3389/fpsyg.2026.1776445
- Technology-enhanced music learning review (2026): https://doi.org/10.1016/j.caeo.2026.100354
- Ruth & Müllensiefen (2021), musical dropout: https://doi.org/10.1371/journal.pone.0259105
- Naavik, music games and licensing: https://naavik.co/digest/music-games-and-the-setlist-problem/

## Appendix B — Competitor map

| Competitor | Model | Strength | Gap |
|---|---|---|---|
| Simply Piano | Gamified course + song library + mic | Mass market, polish | Beginner, fixed course, no diagnosis |
| Yousician | Instrument detection + levels + songs | Broad, real-time | Beginner/intermediate, library-driven |
| Flowkey | Listen-and-play songs | Repertoire | No adaptive practice |
| Skoove | Adult-oriented course + feedback | Adults, structure | Course-finite |
| Piano Marvel | Assessment + 10k library + upload | Serious piano | Library, not guitar; no generative drills |
| Tonic | Social practice studios + gamification | Relatedness, accountability | No pedagogy/assessment |
| tonebase | Premium masterclasses | Depth, artists | Watch/learn, not daily practice |
| Pickup Music | Structured courses | Genre depth | Course-finite |
| Chordify/Moises | Song tools | Any song | No teaching |
| Duolingo Music | Literacy game | Distribution, habit | Completability; not instrument performance |

## Appendix C — Public-domain shortlist

See §7.1. Verify each composition's public-domain status in the target countries; use original arrangements and recordings. Do not use copyrighted sound recordings.

---

**Bottom line:** the app already has the hard engine. The missing piece is the musical experience. Build the song-first loop, keep the FSRS spine, remove the punishment economy, add recording/performance, and let the learner's own repertoire generate the content. That is the path from a finite quiz to an infinite practice system.
