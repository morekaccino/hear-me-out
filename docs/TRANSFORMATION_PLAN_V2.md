# Hear Me Out — Transformation Plan v2

**Status:** Revised after five adversarial reviews (learning science, guitar pedagogy, product/growth, engineering, business)  
**Date:** 2026-11-03  
**Strategic choice:** Win the **notation/sight-reading practice** niche for adult returners and classical/folk guitarists first. Do not fight Simply/Yousician/Duolingo for the mass beginner song market.

---

## 0. What changed from v1, and why

The first plan tried to become a mass-market song-first beginner app in 30 weeks. Five reviews found the same fatal pattern: it kept the app's weakest asset (a finite theory course), chased the most crowded market (beginner pop songs), deferred the hardest problem (polyphonic assessment), and assumed Duolingo-level retention with no acquisition model.

This version makes a narrower bet:

> **Hear Me Out becomes the adaptive sight-reading and repertoire coach for guitarists who read music — or want to.**

The app already has the differentiated assets for this: guitar-correct notation, mic pitch detection, FSRS-style scheduling, and a structured reading course. The plan turns those into a **5–10 minute daily practice loop around real pieces**, with honest phrase assessment, generated sight-reading, and before/after recordings.

| v1 problem | v2 response |
|---|---|
| Mass beginner song market is crowded and licensing-heavy | Target adult returners / classical-folk / exam candidates; public-domain repertoire; no pop catalog |
| 30 songs × 3 levels × 6 phrases = 360–720 phrases, unrealistic | 10 pieces × 1 level × 4 phrases + 30 generated etudes for launch |
| Polyphonic chords/strumming deferred but core to beginners | Chords/strumming are **out of V1**; V1 is monophonic solo lines |
| Backing track + mic bleed invalidates assessment | V1 uses click/drone; simultaneous backing only with wired headphones or call-and-response |
| Phrase assessment unvalidated; DTW timing wrong | 3-week assessment spike with corpus; fixed click grid for timing; exact pitch; tri-state; no FSRS update on indeterminate |
| Mastery inflated by MC/tap “production” and “transfer” | Performance-only mastery: unhinted, mic-verified, at tempo, 3 days, plus novel transfer |
| FSRS treated as validated performance model | FSRS stays for atomic skills; repertoire uses a separate time-budgeted queue; claims softened |
| 12–15 min five-block session, too much for beginners | 5–10 min, 3 blocks, one target, one recording per week |
| Social/recital/teacher/cloud/AI in 12 months | All cut from V1; teacher pilot and exam packs after core retention |
| No acquisition plan | Content/SEO/teacher/community plan; free web sight-reading test; no paid UA |
| Free tier gives away the product | Free = demo: 3 pieces, 10 etudes, 3 recordings |
| Vague “success” targets | Category benchmarks, kill criteria, blinded learning test |

The rest of this document is the revised plan.

---

## 1. Current-state audit

### 1.1 What ships today

A code-level audit (built from every generated lesson) found:

| Metric | Current value |
|---|---:|
| Lessons | 240 |
| Total prompts | 3,984 |
| Scored prompts | 3,740 |
| Unique objectives | 153 |
| Multiple-choice / order | ~2,142 (54%) |
| Note-play prompts (mic) | 606 (15%) |
| Rhythm-tap | 368 (9%) |
| Fret-tap (on-screen) | ~317 (8%) |
| Note-name | 264 (7%) |
| Teach cards | 244 (6%) |
| Repertoire objectives | 0 |
| Sight-reading objectives | 0 |
| Improvisation objectives | 0 |
| Technique objectives | 22 prompts |

The course is theory/harmony-heavy, mic-light, and padded: 3,984 prompts from 153 objectives, with five exposures per objective across six lessons. The helpers `repertoireConcept`, `sightReadingConcept`, and `improvisationConcept` exist but are never called. Those families are labels, not behaviors.

### 1.2 What the learner experiences

- A 240-node linear path of identical locked note nodes; no piece titles, no musical goals.
- “Today” = next lesson in the course, not a daily practice plan.
- Single-note naming/playing and multiple-choice theory; no phrase, piece, recording, or performance.
- Hearts/gems/chests/streaks compensate for a thin musical payoff.
- Onboarding asks only for a daily XP goal; no placement, taste, or experience.
- Practice is a review queue over the same objectives; no repertoire.
- No recording, playback, backing track, share, or teacher loop.

### 1.3 Strengths to keep

1. FSRS-style scheduler with stability, difficulty, retrievability, repair chain, fragile/leech states.
2. Guitar-correct written-vs-sounding pitch and first-position fingerings.
3. YIN pitch detection, stability frames, cents tolerance, octave errors.
4. Clean architecture, 224 passing tests, web build succeeds.
5. Coherent visual language and original sound family.
6. Local-first privacy — a real asset for teachers, exam candidates, and adults.

### 1.4 Root cause

The product's unit is a **lesson**, not a **musical performance**. It teaches *about* music and *single notes*, not *pieces*. The path can be completed; the learner's relationship with music does not deepen.

---

## 2. Target user and positioning

### 2.1 Target

**Primary: adult returners and early-intermediate guitarists (25–55)** who:

- played for 1–5 years, stopped, and want to return;
- can read a little or want to learn;
- play classical, folk, acoustic, or fingerstyle;
- have 5–15 minutes a day;
- want to play real pieces, not pop covers;
- will pay for a coach that replaces or supplements lessons.

**Secondary:**

- **Exam candidates** (ABRSM/RCM/Trinity Grades 1–5 sight-reading and repertoire).
- **Classical/folk teachers** who assign notation and need practice tracking.
- **Adult beginners** who want notation from the start (a smaller, motivated segment).

**Not V1:** absolute beginners wanting pop songs, electric/shred, chords/strumming, children under 13, producers/DAWs.

### 2.2 Positioning

> **Hear Me Out — the practice coach for guitarists who read music.**  
> Turn any piece into a 5-minute daily practice plan. We hear the bar that's holding you back, generate the drill, and show you the before/after.

Alternative taglines:

- “Read music. Play real pieces.”
- “Never wonder which bar to practice again.”
- “Sight-read better in 5 minutes a day.”

Do not promise “unlimited songs” or “become a confident guitarist in 6 months.” Promise **“always the next bar”** and **“proof you improved.”**

### 2.3 Why this wedge

- It uses the app's actual differentiator: guitar-correct notation + mic feedback + sequencing.
- Competitors teach tabs/shapes or songs; notation/sight-reading is underserved.
- Public-domain classical/folk repertoire is on-genre, not a licensing compromise.
- Monophonic solo lines are technically assessable; polyphonic chords are not required.
- Willingness to pay is anchored to lessons and exam prep.
- The audience congregates in identifiable communities: r/classicalguitar, Delcamp, classical guitar societies, exam forums, teacher newsletters.
- The same engine expands to piano later, a 3–5× larger notation market.

### 2.4 The infinite-practice promise

Not “infinite content.” **“Always the next bar.”**

Content multipliers:

| Multiplier | What it does | Example |
|---|---|---|
| Decompose | One piece → phrases and bars | Isolate the shift in bar 9; loop the cadence |
| Vary | Same phrase, new constraints | Tempo ladder, loop, dynamics, articulation, starting point |
| Generate | New sight-reading at target difficulty | 2–4 bar etudes from a grammar |
| Import | Learner's own pieces | MusicXML; later PDF/audio |
| Create | Call-and-response, improv over a drone | Echo 2–4 notes; vary a phrase |

One 8-bar phrase with 5 tempo levels, 4 articulations, 3 dynamics, 4 rhythm variants, and 2 starting points yields 480 variants. Most are not useful; even 5% useful is 24 drills from one phrase. The value is **selection and feedback**, not combinatorial volume.

---

## 3. Product principles

1. **Performance first.** Every session ends with the learner playing a phrase from a piece. At least 60% of session time is guitar in hand.
2. **One target per session.** One bar, one phrase, one correction. No five-block committee meeting.
3. **Model → acquire → apply → reflect.** Listen/hum/clap; slow blocked reps; apply to the piece; self-assess before seeing the score.
4. **5 minutes minimum, 10 default.** Busy days count. Progress is weekly time on instrument, not streak length.
5. **Honest assessment.** Score only what the mic can measure. Low confidence = indeterminate, not “wrong.” No invented feedback.
6. **Technique is part of the curriculum.** Setup, tuning, posture, hands, picking, fretting, muting, pain warnings. Photo/video checklists; teacher referral. The mic cannot see hands, so the app must not pretend it can.
7. **Mastery means performance.** Unhinted, mic-verified, at tempo, in time, on three separate days, plus a novel transfer. Multiple-choice never masters a performance skill.
8. **Autonomy.** Learner chooses the piece, tempo, and session length; the app chooses the next bar.
9. **Privacy by default.** Local-first; recordings stay on device; no accounts/cloud in V1.
10. **No punishment loops.** No hearts, no loss-framed streaks, no public leaderboards in V1.
11. **Author generators, not lessons.** A lesson teaches one thing once; a generator and a piece teach many things forever.
12. **Say what you cannot measure.** Publish an assessment contract for every prompt.

---

## 4. The core loop

### 4.1 Today session (5–10 minutes)

| Block | Time | What happens |
|---|---:|---|
| Model + warm-up | 1–2 min | Tune; listen to the phrase; hum; clap the rhythm; one slow rep |
| Acquire + apply | 3–5 min | One bar/phrase at 50–70%; 3–5 blocked reps; one correction; apply to the piece at target tempo |
| Record + reflect | 1–2 min | One take; self-rating first; app evidence; one next step; save for before/after |

Default 5 minutes; 10-minute option; 20-minute “deep practice” optional. One no-score play session per week.

### 4.2 Repertoire

10 public-domain pieces at launch, one level, 4 phrases each. Each piece has:

- notation + tab toggle;
- a human reference recording at target and slow tempo;
- phrase breakdown with technical/musical focus;
- a drone or click (no simultaneous backing + mic in V1);
- a before/after recording slot;
- a performance outcome: “play bars 1–8 at 72 BPM, no stops.”

Launch pieces (verify public domain per territory; use original arrangements/recordings):

- Sor — Study in B minor (Segovia No. 5) or a simpler Sor study
- Giuliani — Andantino / a beginner study
- Carcassi — Study in A minor
- Bach — Minuet in G (BWV Anh. 114) melody
- Spanish Romance (anonymous) — simplified melody
- Greensleeves — melody
- Scarborough Fair — melody (original arrangement; avoid copyrighted Simon & Garfunkel)
- Danny Boy / Londonderry Air — melody
- Ode to Joy — melody
- Amazing Grace — melody

The exact list must be vetted by a guitar pedagogue for difficulty, range, and musical payoff. Avoid arrangements associated with copyrighted recordings.

### 4.3 Sight-reading lab

- 30 generated 2–4 bar etudes at levels 1–5.
- Grammar: key, meter, rhythm cells, intervals, position, range.
- Difficulty model: notes per bar, interval size, rhythm complexity, position shifts, accidentals.
- One etude per session; no score on first read; second read for feedback.
- This is the infinite content engine: every etude is new, level-matched, and notation-based.

### 4.4 Reading lab (existing course)

The 240-lesson course becomes an optional **Reading Lab**, not the home. It remains useful for notation/theory fundamentals, but it is no longer the product's spine. Learners can jump in/out; the Today loop is primary.

### 4.5 Progress

- **Can play** (performance mastery): piece/phrase, tempo, date, recording.
- **Shaky** (due/fragile atomic skills).
- **Reading** (notes/rhythms/intervals mastered).
- **Next** (recommended bar/etude).
- Weekly recap: minutes, phrases, recordings, one before/after.

No lesson-completion percentage as the primary metric.

---

## 5. V1 scope

### 5.1 In

- Guitar, standard tuning, no capo.
- Monophonic solo lines, 2–4 bars, 50–90 BPM, quarter/eighth notes.
- 10 public-domain pieces, 1 level, 4 phrases each.
- 30 generated sight-reading etudes.
- 5–10 minute Today session.
- Phrase assessment with tri-state result.
- Local WAV recording, playback, A/B.
- Technique checklist + photo/video prompts; pain warning.
- Existing Reading Lab as optional.
- Free demo + Pro unlock (store IAP; no app account).
- Opt-in, privacy-preserving aggregate analytics or a hand-recruited beta cohort.

### 5.2 Out

- Chords, strumming, polyphonic assessment.
- Pop/rock catalog, licensed songs.
- Social feed, recital, leaderboards, peer comments.
- Teacher dashboard, accounts, cloud sync.
- AI feedback, audio-to-score import, PDF import.
- Bass/ukulele/piano (later).
- Improvisation, advanced harmony, modes, odd meters.
- 100+ songs, 3 levels, “unlimited” catalog.

### 5.3 Why this scope

It is the smallest loop that proves the thesis: a returner can open the app, play a real piece, hear one specific correction, record a take, and come back tomorrow. If this does not retain, no amount of songs/social/AI will save it.

---

## 6. Assessment contract

### 6.1 What V1 measures

| Prompt | Measures | Tolerance | Not measured |
|---|---|---|---|
| Single note | Pitch, octave, intonation | Exact pitch class; ±50 cents | Tone, fingering, posture |
| Phrase (2–4 bars) | Note accuracy, onset timing vs click, tempo stability, completeness | Exact pitch class; ±50 cents; onset MAE target ≤40 ms | Polyphony, chord quality, strum direction, tone |
| Rhythm tap | Onset vs click | ±40 ms | Guitar technique |
| Sight-reading | Notes + rhythm on first/second read | Same as phrase | Musicality, phrasing |
| Technique | Self-check/photo/video | N/A | Automated hand assessment |

### 6.2 Pipeline

```
record → PCM16 → effective sample rate/channels → resample
→ onset detection (spectral flux, 5–10 ms hop)
→ pitch per onset (harmonic-aware f0; 2–3 stable frames)
→ note events → constrained alignment to target
→ score: note accuracy, timing vs fixed click, tempo stability
→ tri-state: correct / incorrect / indeterminate
```

Key rules:

- **Timing is measured against the fixed click/beat grid, not a DTW-warped grid.** DTW is only for note alignment.
- **Exact pitch class, ±50 cents.** ±1 semitone tolerance is forbidden; adjacent-fret errors are the most common beginner error.
- **Octave errors are reported separately.**
- **Indeterminate does not update FSRS, streaks, XP, or daily counters.** Add a third `SkillAnswer` state.
- **Per-note confidence.** Do not mark undetected notes wrong; mark them indeterminate.
- **Pass thresholds by phrase length.** 4 notes: 100% notes, timing within tolerance. 8 notes: ≥90% notes, no bar with two errors. 16 notes: ≥85%, error budget per bar.
- **Null model.** Random note sequences must pass <5%; one semitone error must fail; perfect take must score 100%.
- **Confidence threshold.** Low confidence → “I couldn't hear that clearly; try again or self-rate.” Never punish.

### 6.3 Validation spike (3 weeks, before UI/content)

**Corpus:** 6–10 players (beginner/returner), 4 devices (mid-range Android, iPhone, tablet, laptop/web), 3 conditions (quiet, room noise, click/drone), 60–100 takes, 4–8 note phrases, 60–90 BPM. Label with notation + MIDI subset + hand labels.

**Metrics:**

- per-note recall/precision ≥95%;
- false-negative rate ≤10% (target ≤5%);
- false-positive rate ≤5%;
- onset MAE ≤40 ms;
- expert rating correlation ≥0.7;
- silence/noise → indeterminate ≥90%;
- one-semitone error → fail 100%;
- random sequence pass ≤5%.

**Audio session test:**

- record + playback start latency <150 ms;
- drift <20 ms over 60 s;
- no route conflict on iOS/Android/web;
- 30 s analysis <2 s mid-range Android, <4 s mobile Safari;
- 60 s WAV ≤6 MB; 20 takes ≤120 MB; delete/export works.

**If fail:** do not build the song/piece loop. Pivot to call-and-response, single-bar assessment, or a pure notation trainer. That is a legitimate smaller product.

### 6.4 Technical fixes required

- Read effective `RecordConfig` sample rate/channels; resample explicitly (the current 44.1 kHz assumption is a latent pitch bug on 48 kHz devices).
- Add monotonic sample-clock timestamps to `PitchFrame`.
- Separate onset detection from pitch frames.
- Fix the first-review FSRS lapse branch.
- Use pure versioned migrations; fixtures v1–v5; explicit rollback behavior.
- Separate progress, media, content, and account stores.
- Do not put recordings in `ProgressState`; use a `MediaStore` with web/mobile conditional imports.
- Update privacy copy and iOS usage string before recording ships.
- Add Android/web builds to CI; corpus tests as a slow job; manual device checklist.

---

## 7. Pedagogy and curriculum

### 7.1 Technique strand (mandatory)

The mic cannot see hands, so the app must teach and check technique explicitly:

- setup: action, strings, tuning, intonation, posture, strap, footstool;
- left hand: thumb, arch, fingertip placement, pressure, wrist;
- right hand: rest stroke, free stroke, pick angle, alternation, damping;
- practice: slow reps, loops, one correction, rest;
- pain warning: stop if sharp pain; see a teacher; no medical claims.

Format: 30-second checklist before a piece; photo/video self-check; optional teacher review. No automated scoring. The app must not claim to replace a teacher for setup/posture.

### 7.2 Curriculum shape

12 stages, not 40 units. Each stage has 3–5 pieces/etudes and one performance outcome.

| Stage | Focus | Example outcome |
|---|---|---|
| 1 | First position, open strings, pulse | Play a 4-bar Sor study at 60 BPM, no stops |
| 2 | Notes on strings 1–3, simple rhythms | Play the first phrase of a Carcassi study |
| 3 | Notes on strings 4–6, accidentals | Play a 8-bar folk melody |
| 4 | Two-voice texture, rest stroke | Play a Bach minuet melody with steady bass |
| 5 | Position shifts, guide fingers | Play a 12-bar study with two shifts |
| 6 | Slurs, articulation | Play a phrase with clean hammer-ons/pull-offs |
| 7 | Chords/arpeggios (reading, not strumming) | Play a broken-chord study |
| 8 | Expression: dynamics, rubato | Play a phrase pp→mf→pp |
| 9 | Sight-reading fluency | Read a 4-bar etude at sight at 70 BPM |
| 10 | Repertoire consolidation | Perform a 1-minute piece start-to-finish |
| 11 | Exam-style tasks | Pass a Grade 1–2 sight-reading mock |
| 12 | Performance/recording | Record a 2-minute program |

The existing 240-lesson course maps to stages as a **Reading Lab**; it is not mandatory.

### 7.3 Repertoire difficulty ladder

Rank by range, position, rhythm, polyphony, accidentals, shifts, and technique—not title recognition. Each piece tagged with:
- `range`, `positions`, `shifts`, `rhythms`, `accidentals`, `polyphony`, `technique`;
- `minimumVersion` (melody), `targetVersion` (written), `performanceVersion`;
- `musicalFocus` (phrasing, dynamics, tone), `technicalFocus`;
- reference recording (human, target + slow).

### 7.4 Mastery model

Separate three claims:

1. **Can recognize** — note/rhythm/theory quiz; FSRS.
2. **Can play slowly** — unhinted, mic-verified, 70–80% tempo.
3. **Can perform** — unhinted, mic-verified, target tempo, in time, three separate days, plus a novel transfer (new piece/phrase, new key/position), plus a checkpoint.

Only #3 is “mastered” in the UI. Fix:
- `transfer` = new key/position/piece/context, not any review.
- `production` = playing into mic/MIDI, not staff/fret tap/order.
- `mastered` requires a passed checkpoint.
- Hinted/revealed answers are not “correct” for mastery.
- Add a test: a multiple-choice-only learner cannot master a performance skill.

FSRS stays for atomic skills (notes, rhythms, intervals). Repertoire uses a separate time-budgeted queue (3–5 pieces in rotation; one maintenance play per session; monthly full performance). Do not call FSRS stability “performance mastery.”

---

## 8. Session design

### 8.1 Default 5-minute session

| Time | Block | Detail |
|---|---|---|
| 0:00–0:30 | Tune/setup | Tuner; posture checklist; no score |
| 0:30–1:30 | Model | Listen to human reference; hum; clap rhythm |
| 1:30–3:30 | Acquire | One bar at 50–70%; 3–5 blocked reps; one correction |
| 3:30–4:30 | Apply | Play the phrase at target tempo; one take |
| 4:30–5:00 | Reflect | Self-rating first; app shows one metric + one next step |

### 8.2 10-minute option

Adds: a second bar/phrase, a sight-reading etude, or a technique drill. Still one target.

### 8.3 Rules

- One new demand at a time: notes OR rhythm OR tempo OR expression.
- Phrase length 1→2→4 bars; tempo 50→60→70→80→target; change one variable per step.
- Blocked acquisition first; interleave later once the phrase is playable at 70–80%.
- Feedback after 2–3 reps, one correction, then a rep applying it.
- Fade the score: ask for a prediction; show evidence after.
- If two consecutive reps fail, reduce tempo/length; do not repeat the same failed rep.
- Record 1–2× per week on a performance day, not every session.
- One no-score play session per week; one “play for someone” assignment in week 4.
- Measure time on instrument, not prompt count. Target: 3+ minutes guitar in hand in a 5-minute session.

---

## 9. Gamification

Remove hearts entirely. Replace with:

- **Streak:** optional; any effective practice (3+ minutes guitar or one recorded take) counts; freeze; no loss framing.
- **Weekly goal:** minutes or phrases, not XP.
- **Mastery map:** “can play” pieces/phrases, not lesson completion.
- **Personal bests:** tempo, accuracy, timing, recordings.
- **Badges:** first recording, first full piece, 5-day streak, 10 clean phrases.
- **No public leaderboards or score-sharing in V1.**
- **No gems/chests/shop** in V1; keep the economy out until retention is proven.
- **Quests:** “play 3 phrases,” “record a take,” “learn 4 bars,” not “answer 10 notes.”

---

## 10. Recording and sharing

- Record WAV locally; analyze after stop; save to a separate `MediaStore`.
- Playback + A/B; normalize loudness before comparison.
- Before/after card: piece, phrase, date, one metric, optional audio clip; **no public score**.
- Default private. Share only by explicit export.
- Cap 60 s per take, 20 takes; delete/export; reconcile orphans.
- Exclude recordings from iCloud/Android backup unless the user opts in.
- Update privacy copy and iOS usage string before shipping.

---

## 11. Content plan

### 11.1 Launch content

- 10 public-domain pieces, 1 level, 4 phrases each.
- 30 generated sight-reading etudes (levels 1–5).
- 10 technique checklists.
- 10 human reference recordings (target + slow).
- No pop catalog, no chords/strumming, no UGC.

### 11.2 Content cost

Assume 8–16 hours per piece for notation, fingering, tags, reference, QA. 10 pieces = 80–160 hours, ~2–4 weeks for a guitarist/arranger. 30 etudes = 2–3 weeks with a generator + review. This is realistic for a small team.

### 11.3 Authoring format

Use a proper score model, not a loose note list:

```yaml
piece: sor-study-b-minor
title: Study in B Minor
composer: Fernando Sor
license: public-domain
tuning: standard
capo: 0
timeSignature: 3/4
key: B minor
phrases:
  - id: p1
    bars: 1-4
    notes:
      - {written: "B3", sounding: "B2", string: 5, fret: 2, start: 0, duration: 1}
      - {written: "F#4", sounding: "F#3", string: 4, fret: 4, start: 1, duration: 1}
```

Validation:

- written vs sounding pitch explicit;
- string/fret matches sounding pitch;
- time signature, bars, rests, ties, repeats;
- range/position;
- license/territory;
- reference recording exists;
- all skills exist.

### 11.4 Reference recordings

A synth is not a model of guitar tone, articulation, or phrasing. Record a human guitarist at target and slow tempo. This is non-negotiable for a notation/repertoire product.

---

## 12. Technical plan

### 12.1 3-week spike (gate)

See §6.3. Do not build UI/content until the spike passes.

### 12.2 Phase 1 (weeks 4–10)

- Piece/Phrase models + parser/validator.
- PhrasePlayPrompt + constrained matcher + tri-state.
- 10 pieces, 30 etudes, 10 reference recordings.
- Today session UI (5/10 min).
- Recording/A-B/MediaStore.
- Technique checklist.
- Free demo + Pro IAP.
- Remove hearts; add optional streak/weekly goal.
- Tests: parsing, DTW, scoring, migration, widget.

### 12.3 Phase 2 (weeks 11–18)

- MusicXML import (user's own pieces).
- Exam packs (ABRSM/RCM/Trinity Grade 1–3 sight-reading).
- Teacher pilot (3 teachers, manual dashboard or simple web view).
- Adaptive etude generator v2.
- Opt-in aggregate analytics.

### 12.4 Phase 3 (months 5–9)

- Piano expansion (same engine; larger notation market).
- Technique video check/teacher review.
- Ear-to-hand call-and-response.
- Cloud sync/accounts only if users ask and privacy model is updated.
- AI feedback only after rule-based proves learning gains.

### 12.5 Phase 4 (months 9–12)

- Social/recital only after 10k MAU and moderation plan.
- UGC/teacher marketplace only if teacher pilot works.
- Advanced repertoire, exam packs 4–5.

---

## 13. Business model

### 13.1 Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | 3 pieces, 10 etudes, 3 recordings, tuner, basic feedback |
| Pro | $8.99/mo or $69/yr | All 10+ pieces, unlimited etudes, recordings, advanced feedback, offline |
| Exam packs | $19–29 per grade | ABRSM/RCM/Trinity sight-reading Grades 1–3 |
| Teacher Studio | $19/mo per teacher, up to 30 students; $0.75/student above | Assignments, progress, recordings |
| Lifetime | $129, capped 500 | Pro forever |

No ads. No cloud AI in V1. No licensed pop catalog. No social feed.

### 13.2 Why this price

- Anchored to lessons ($50–100/hour) and exam prep.
- $69/year is 1–2 lessons; high perceived value for a serious returner.
- Teacher price matches the market anchor (My Music Staff ~$17/mo unlimited students); per-teacher, not per-student.

### 13.3 Illustrative 3-year model

Organic acquisition, 3% install→paid, 15% store fee:

| Line | Year 1 | Year 2 | Year 3 |
|---|---:|---:|---:|
| Pro subscribers | 1,200 | 3,500 | 8,000 |
| Pro revenue | $82.8k | $241.5k | $552k |
| Teachers | 40 | 120 | 300 |
| Teacher revenue | $9.1k | $27.4k | $68.4k |
| Gross revenue | $91.9k | $268.9k | $620.4k |
| Net after fees | $78.1k | $228.6k | $527.3k |
| Content | -$40k | -$80k | -$120k |
| Hosting/support | -$12k | -$25k | -$40k |
| Marketing | -$8k | -$25k | -$40k |
| Team | -$60k | -$120k | -$200k |
| Profit | -$42k | -$21k | +$127k |

This is a **niche business**, not a venture-scale consumer app. At 20k Pro + 800 teachers, ~$1.5M revenue / $400–500k profit. If the goal is venture scale, the expansion path is piano, schools, and exam boards—not pop songs.

### 13.4 Acquisition

- **SEO/content:** “guitar sight reading app,” “how to read music on guitar,” “ABRSM guitar sight reading,” “Sor study,” “Carcassi etude,” “classical guitar practice.”
- **Short-form:** “Can you sight-read this in 30 seconds?”, “Fix this bar,” before/after clips, teacher tips.
- **Communities:** r/classicalguitar, Delcamp, classical guitar societies, exam forums, teacher newsletters.
- **Free web tool:** sight-reading test/tuner as top of funnel.
- **Teacher referrals:** 3 pilot teachers; affiliate/referral code.
- **No paid UA initially.** Paid acquisition math is unfavorable at $5+ CPI and 3% conversion.

### 13.5 Validation before build

1. **Pre-sale:** landing page with 3 sample lessons; $39 founding pre-order; 2,000 targeted visitors; gate: 10+ pre-orders, CAC <$30.
2. **Concierge:** 12 adult returners, 4 weeks, 5 min/day, weekly Zoom; $25; gate: 60% do 3+ sessions/week, 50% would pay $8/mo.
3. **Teacher pilot:** 10 interviews, 3 paid pilots at $50/month for 20–30 students; gate: 3 signed, 70% weekly assignment use.
4. **Assessment spike:** see §6.3.

Do these in parallel before Phase 1. Total cost <$2,000.

---

## 14. Metrics and experiments

### 14.1 North star

**Weekly effective practice minutes** (guitar in hand, not app time) with a quality guardrail: **weekly recorded phrases/pieces**.

Do not use “weekly successful phrases” alone; it is gameable by verifier strictness.

### 14.2 Targets (category benchmarks, not Duolingo)

| Metric | Target |
|---|---:|
| First note in <60 s | 60% |
| First phrase in <3 min | 50% |
| First recording by day 7 | 25% |
| D1 | 35–40% |
| D7 | 18–22% |
| D30 | 10–15% |
| 3+ sessions/week among actives | 30% |
| Free→Pro by day 30 | 2–3% |
| Annual renewal | 45–55% |
| NPS | 20–30 early |

### 14.3 Learning proof

- Delayed (7–14 day) performance of a practiced and a held-out transfer phrase, blind-rated by two teachers or a validated automated score, at fixed tempo, unassisted.
- Compare against an active control (metronome/current course).
- Report effect size and confidence interval; do not call in-app accuracy “learning.”

### 14.4 Kill criteria

- False-negative rate >10% in the spike → stop mic-first.
- <35% return for session 2 within 48 h → fix onboarding/loop.
- <25% record by day 7 → performance is not compelling.
- <0.5% pre-sale conversion → demand is not proven.
- D30 <8% after 3 months → niche/positioning wrong.
- Free→Pro <1.5% after 3 months → paywall/value wrong.

### 14.5 Experiments

1. 5-min vs 10-min default.
2. Generated etudes vs fixed etudes.
3. Recording/A-B vs no recording.
4. Human reference vs synth reference.
5. Self-rating first vs score first.
6. Streak vs weekly goal only.
7. $69 vs $99 annual.
8. Free demo 3 pieces vs 5 pieces.
9. Teacher-assigned vs self-chosen piece.
10. Exam pack vs general repertoire.

---

## 15. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Phrase assessment inaccurate | High | High | 3-week spike; exact pitch; fixed click; tri-state; corpus; false-negative <10% |
| Backing bleed | High | High | Click/drone only; wired headphones; call-and-response; no simultaneous backing in V1 |
| Content authoring too slow | High | High | 10 pieces, 4 phrases; one level; contractor; reference recordings |
| Market too small | Medium | High | Teacher/exam channel; piano expansion; validate pre-sale |
| Retention below niche benchmark | Medium | High | 5-min default; one target; recording; human reference; fix onboarding |
| Technique not assessed | High | Medium | Checklist/photo/video; teacher referral; no false claims |
| Privacy contradiction | Medium | Medium | No accounts/cloud in V1; update copy; local recordings |
| Copyright | Medium | High | Public domain/original; legal review; territory check; no copyrighted arrangements |
| Solo bandwidth | High | High | Cut scope; 3-week spike; contractor for DSP/content |
| Open-source code copyable | High | Medium | Moat = pedagogy, content quality, teacher trust, brand; not code |
| AI overpromise | Medium | Medium | No AI in V1; rule-based DSP; later only if validated |

---

## 16. What not to do

- Do not build a mass-market pop-song app.
- Do not license a 100-song catalog.
- Do not add chords/strumming/polyphony to V1.
- Do not add social/recital/leaderboards/teacher dashboards/cloud/AI to V1.
- Do not keep hearts or punishment loops.
- Do not call multiple-choice/tap “mastery.”
- Do not use DTW-warped timing as a timing score.
- Do not use ±1 semitone tolerance.
- Do not claim technique/tone/chord assessment the mic cannot measure.
- Do not ship 30 songs before 10 pieces work.
- Do not spend on paid UA before organic/teacher traction.
- Do not promise “become a confident guitarist in 6 months.”

---

## 17. Open decisions

1. **Piece list:** exact 10 public-domain pieces, vetted for difficulty/musical payoff.
2. **Exam board:** ABRSM vs RCM vs Trinity first; licensing/affiliation.
3. **Teacher pilot:** manual vs simple web dashboard.
4. **Analytics:** opt-in aggregate vs hand-recruited beta only.
5. **Piano expansion:** when (month 6–9) and whether same brand.
6. **Funding:** bootstrap niche vs venture with piano/schools path.

---

## Appendix A — Research base (use carefully)

- Renwick & McPherson (2002), self-selected repertoire: case study, not general proof.
- Macnamara et al. (2014), deliberate practice explains ~21% of music variance; necessary, not sufficient.
- Ma et al. (2014), ITS meta-analysis: g≈0.42–0.57; supports adaptive tutoring.
- Interleaved practice in music (2016): n=10 advanced clarinetists; promising, not beginner-proof.
- Evans (2015), SDT in music education: autonomy/competence/relatedness.
- Gamification meta-analysis (2021): short-term gains, long-term negative associations; avoid punishment.
- AI-assisted practice app (2025): small study; self-efficacy/performance gains.
- Violin real-time feedback RCT (2021): supports feedback, not all instruments.
- Difficulty-aware score generation (2025): feasibility, not validated pedagogy.
- Empowerment vs dependency review (2026): assessment AI supports self-monitoring; generative AI may undermine forethought.
- Technology-enhanced music learning review (2026): beginner/performance bias; expression/aesthetic outcomes underrepresented.
- Ruth & Müllensiefen (2021): ~50% dropout by 17; motivation/environment, not content exhaustion.

## Appendix B — Competitor gap

| Competitor | Strength | Gap |
|---|---|---|
| Simply Guitar | Song-first beginner polish, licensed catalog | Notation/sight-reading, diagnosis |
| Yousician | Real-time audio, huge catalog, scale | Notation depth, adult returner |
| Flowkey | Listen-and-play songs | Adaptive practice, diagnosis |
| Skoove | Adult-oriented course | Repertoire depth, sight-reading |
| Piano Marvel | Assessment + library + upload | Guitar; notation-specific; generative |
| tonebase | Premium classical depth | Daily adaptive practice |
| YouTube/JustinGuitar | Free, human teachers, any song | Feedback, sequence, diagnosis |
| Duolingo Music | Habit, distribution | Instrument performance, depth |

## Appendix C — Public-domain shortlist (verify per territory)

Sor studies; Giuliani studies; Carcassi studies; Bach Minuet in G (BWV Anh. 114); Spanish Romance (anonymous); Greensleeves; Scarborough Fair (original arrangement); Londonderry Air/Danny Boy; Ode to Joy; Amazing Grace. Use original arrangements/recordings; avoid arrangements associated with copyrighted recordings.

---

**Bottom line:** stop trying to become a worse Yousician. Become the best practice coach for guitarists who read music. Prove the mic on a corpus, ship 10 pieces and 30 etudes, make a 5-minute loop that ends with a recording, charge from day one, and earn the right to expand.
