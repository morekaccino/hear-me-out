# Hear Me Out — Transformation Plan v3.1

**Status:** Final candidate after three adversarial review rounds  
**Date:** 2026-11-03  
**Review outcome:** Four reviewers approved v3; the business reviewer required a P&L, teacher/exam separation, price test, funding decision, and legal budget. v3.1 adds them, plus all non-blocking fixes.  
**Strategic choice:** Win the **notation/sight-reading practice** niche for adult returners and classical/folk guitarists. Do not fight Simply/Yousician/Duolingo for the mass beginner song market.

---

## 0. The one-paragraph plan

Hear Me Out becomes the **adaptive sight-reading and repertoire coach for guitarists who read music — or want to.** The learner opens a 5-minute session, hears a human reference, plays one bar of a real piece, gets one honest correction, and records a take. The app decomposes pieces into phrases, generates level-matched sight-reading etudes, and proves progress with before/after recordings. It uses the existing FSRS-style scheduler for atomic skills, but performance mastery is earned only by unhinted, mic-verified, at-tempo playing on multiple days. V1 is strictly monophonic, local-only, and narrow: 10 public-domain pieces, 60 reviewed etudes, no chords, no social, no cloud, no AI. A 3-week assessment spike is a hard gate; if the mic cannot score beginner phrases honestly, the phrase loop does not ship.

---

## 1. Why this plan, and what changed

The first plan tried to become a mass-market song-first beginner app in 30 weeks. Five reviews found the same fatal pattern: it kept the app's weakest asset (a finite theory course), chased the most crowded market (beginner pop songs), deferred the hardest problem (polyphonic assessment), and assumed Duolingo-level retention with no acquisition model.

V2 narrowed to the notation niche. All five reviewers approved in principle. V3 resolves their remaining conditions:

| Remaining condition | V3 response |
|---|---|
| Phrase-level false negatives, not just per-note | Primary gate: per-phrase false pass ≤5%, false fail ≤10%; per-note recall ≥99%; indeterminate = incomplete, never fail |
| Monophonic assessment vs. polyphonic repertoire | V1 repertoire is strictly monophonic; validator enforces one sounding note at a time; two-voice/chords moved to Phase 2 |
| Timing/click contradiction | Headphones + shared sample clock, loopback latency calibration; no drones during scored takes; if no clock, score notes only and drop “in time” |
| Intonation ±50 cents too loose | Exact pitch class; report cents; “in tune” threshold ±30 cents; performance mastery requires median intonation within ±30 cents |
| Mastery durability | Performance mastery requires 3 separate days, ≥7 days after first, novel transfer, delayed unassisted checkpoint |
| Curriculum promises unassessable skills | V1 ships stages 1–3, 5, 9–12; stages 4/6/7/8 are Phase 2 or self/teacher-reviewed |
| Sight-reading “unlimited” overclaim | 60 reviewed etudes at launch; generator beta with a guitar-specific playability validator; no “unlimited” claim |
| Technique checklist too thin | Per-stage technique focus; video demos; 3-item rubric; 60-second drill in rotation; export for teacher; pain/numbness/tingling warning |
| No placement for returners | 3–5 minute diagnostic; manual override; three-piece starter set; re-test every 4–6 weeks |
| No return trigger | Local notification with the specific task; weekly recap; before/after trigger; no account |
| Acquisition is a channel list | One beachhead; 12-month content calendar; 20 free lessons/tools; shareable web sight-reading test; keyword evidence; realistic base case |
| Teacher/exam contradictions | Teacher removed from base case; manual export pilot at $19/mo; generic grade packs, no board names until licensed |
| 10 pieces is a demo | 24-month content calendar; 2–3 new pieces/month; 40–60 pieces by year 2; or one-time pricing |
| 3-year model unrealistic | Bottom-up base case: 5–10k installs year 1, 150–300 Pro, $150–250k revenue by year 3; teacher/exam excluded from base |
| Tri-state not integrated | `AttemptOutcome` at domain boundary; `PracticeSession` separate from `LessonRun`; indeterminate touches no FSRS/XP/streak |
| Click/drone bleed | Headphones + shared clock; click-in-recording alternative; ban drones during scored takes; bleed gate |
| Spike too optimistic | 3 weeks only with dedicated DSP engineer + pre-recruited corpus; otherwise 5 weeks |
| Owned audience | Optional email capture; free web sight-reading test; waitlist; measure capture rate |
| Paywall timing | After first recording + day-7 recap; 7-day trial; test gating etudes/diagnosis vs. piece count |

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

**Secondary (Phase 2):**

- exam candidates (generic Grade 1–3 sight-reading; no board names until licensed);
- classical/folk teachers (manual export pilot at $19/mo);
- adult beginners who want notation from the start (smaller, motivated segment).

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

- Uses the app's actual differentiator: guitar-correct notation + mic feedback + sequencing.
- Competitors teach tabs/shapes or songs; notation/sight-reading is underserved.
- Public-domain classical/folk repertoire is on-genre, not a licensing compromise.
- Monophonic solo lines are technically assessable; polyphonic chords are not required.
- Willingness to pay is anchored to lessons and exam prep.
- The audience congregates in identifiable communities: r/classicalguitar, Delcamp, classical guitar societies, exam forums, teacher newsletters.
- The same engine expands to piano later, a 3–5× larger notation market.

### 2.4 The infinite-practice promise

Not “infinite content.” **“Always the next bar.”**

| Multiplier | What it does | Example |
|---|---|---|
| Decompose | One piece → phrases and bars | Isolate the shift in bar 9; loop the cadence |
| Vary | Same phrase, new constraints | Tempo ladder, loop, dynamics, articulation, starting point |
| Generate | New sight-reading at target difficulty | 2–4 bar etudes from a validated grammar |
| Import | Learner's own pieces | MusicXML in Phase 2 |
| Create | Call-and-response, vary a phrase | Echo 2–4 notes; change one note |

One 8-bar phrase with 5 tempo levels, 4 articulations, 3 dynamics, 4 rhythm variants, and 2 starting points yields 480 variants. Most are not useful; even 5% useful is 24 drills from one phrase. The value is **selection and feedback**, not combinatorial volume.

---

## 3. V1 scope

### 3.1 In

- Guitar, standard tuning, no capo.
- **Strictly monophonic** solo lines, 1–4 bars, 50–90 BPM, quarter/eighth notes.
- 10 public-domain pieces, 1 level, 4 phrases each; two tiers: **Foundation (stages 1–3)** and **Returner (stages 5, 9–10)**.
- 60 reviewed sight-reading etudes (levels 1–5) + a generator beta behind a validator.
- 5-minute default session; 10-minute option; 20-minute deep practice.
- Phrase assessment with tri-state result.
- Local recording, playback, A/B; AAC for storage, WAV for analysis.
- Technique checklist + video demos + 3-item rubric; pain/numbness/tingling warning.
- Existing 240-lesson Reading Lab as optional.
- Free demo + Pro unlock (store IAP; no app account).
- Local notifications; optional email capture for the web test/waitlist.
- Opt-in aggregate analytics or a hand-recruited beta cohort.

### 3.2 Out

- Chords, strumming, polyphonic assessment, double stops.
- Pop/rock catalog, licensed songs.
- Social feed, recital, leaderboards, peer comments.
- Teacher dashboard, accounts, cloud sync.
- AI feedback, audio-to-score import, PDF import.
- Bass/ukulele/piano in the 12-month plan.
- Improvisation, advanced harmony, modes, odd meters.
- 100+ songs, 3 levels, “unlimited” catalog.
- Exam board names/syllabi until licensed.

### 3.3 Why this scope

It is the smallest loop that proves the thesis: a returner can open the app, play a real piece, hear one specific correction, record a take, and come back tomorrow. If this does not retain, no amount of songs/social/AI will save it.

---

## 4. Assessment contract

### 4.1 What V1 measures

| Prompt | Measures | Tolerance | Not measured |
|---|---|---|---|
| Single note | Pitch, octave, intonation | Exact pitch class; ±30 cents “in tune” | Tone, fingering, posture |
| Phrase (1–4 bars) | Note accuracy, onset timing vs click, tempo stability, completeness | Exact pitch class; onset precision ±20–30 ms; pedagogical tolerance ±80 ms at 60 BPM, ±50 ms at 90 BPM | Polyphony, chord quality, strum direction, tone |
| Full piece | Concatenated phrase scores + continuity/coverage/no-stop | Phrase tolerances; no-stop | Note-level mastery beyond phrase; expression |
| Rhythm tap | Onset vs click | ±40 ms | Guitar technique |
| Sight-reading | First-read accuracy/timing | Same as phrase | Musicality, phrasing |
| Technique | Self-check/photo/video | N/A | Automated hand assessment |

Full pieces are scored as concatenated phrase attempts plus a continuity/coverage check; **note-level mastery is awarded at the phrase level**, not the full piece. “Performance-ready” for a full piece means no stops and all constituent phrases have passed, not that every note was re-scored in one take.

### 4.2 Pipeline

```
record → PCM16 → effective sample rate/channels → resample
→ onset detection (spectral flux, 5–10 ms hop)
→ pitch per onset (harmonic-aware f0; 2–3 stable frames)
→ note events → constrained alignment to target
→ score: note accuracy, timing vs fixed click, tempo stability, coverage
→ tri-state: correct / incorrect / indeterminate
```

### 4.3 Decision rules

- **Timing is measured against the fixed click/beat grid, not a DTW-warped grid.** DTW is only for note alignment, with constrained slope and coverage.
- **Exact pitch class; intonation reported in cents.** “In tune” is ±30 cents; do not gate at ±50.
- **Octave errors reported separately**; an octave-off take fails or is indeterminate.
- **Indeterminate does not update FSRS, streaks, XP, or daily counters.** It means “incomplete — retry.”
- **Per-note confidence.** Undetected notes are indeterminate, not wrong.
- **Per-phrase decision rule:**
  - Practice pass: ≥85% of determinate notes correct, timing within pedagogical tolerance; allows drilling.
  - Performance mastery: 100% of notes determinate and correct, no bar with an error, timing within tolerance, 3 separate days, ≥7 days after first, novel transfer, delayed unassisted checkpoint.
  - False pass ≤5%; false fail ≤10%; per-note recall ≥99%; per-note precision ≥95%; expert ICC(2,k) ≥0.75 and kappa ≥0.70 for pass/fail; 95% confidence intervals; stratify by 4/8/16-note phrases and user segment.
  - Tempo stability: if drift exceeds pedagogical tolerance across two or more bars, the take fails timing; report “rushed” or “dragged,” not a generic score.
  - Extra notes count as errors. Missed notes are indeterminate if not attempted, errors if attempted incorrectly. A false start or early stop is incomplete, not failed.
  - Per-note confidence <0.6 is indeterminate; if more than 20% of notes are indeterminate, the whole take is incomplete.
  - The validation corpus must include 16-note phrases even though the launch phrases are 1–4 bars, so the mastery threshold is tested.
- **If any note is indeterminate, the take is incomplete.** Offer retry; never fail.
- **Test–retest determinism:** same WAV produces the same score on Android, iOS, and web; no `DateTime.now()` or random seed in scoring.

### 4.4 Latency, clock, and bleed

Choose one architecture before the spike:

- **Headphones + shared sample clock (recommended):** record and click start from the same audio engine; measure output latency with a loopback calibration; store `beatZeroSample`; compensate per device. Require offset ≤10 ms and drift ≤20 ms/60 s.
- **Click-in-recording alternative:** high-frequency click, detect and subtract; prove no false onsets.
- **Ban drones during scored takes.** If neither architecture passes, score note accuracy only and drop the “in time” claim.

### 4.5 Spike (3 weeks with a dedicated DSP engineer; 5 weeks otherwise)

**Corpus:** 6–10 players (beginner/returner), 4 devices (mid-range Android, iPhone, tablet, laptop/web), 3 conditions (quiet, room noise, click/drone), **≥240 takes (≥20 per device/condition cell)**, 4–8 note phrases plus 16-note phrases, 60–90 BPM. Include actual piece phrases, slurs/ties/rests/shifts, nylon and steel strings, open and fretted notes.

**Pass/fail:**

- per-phrase false pass ≤5%, false fail ≤10%;
- per-note recall ≥99%, precision ≥95%;
- per-string recall ≥90% (E2/A2/D3/G3/B3/E4, open and fretted);
- octave-error rate ≤2%;
- onset MAE ≤40 ms; offset/drift gates above;
- expert ICC ≥0.75; held-out split by player and piece;
- ≥20 takes per device/condition;
- one 48 kHz-only Android case and one stereo case; pitch error <10 cents after resampling;
- tuning offsets 0/30/50 cents: >30 cents prompts tune/indeterminate, not “wrong”;
- artifacts (squeak, buzz, body thump, chair, breathing, speech, TV, clipping): false positive ≤5%, noise indeterminate ≥90%;
- **bleed gate:** speaker click/drone vs. headphones note-recall drop ≤5% and false onsets ≤1/min; if exceeded, headphones mandatory or score notes only;
- endpoints: count-in, pickup, rest, early stop, extra note, missed note; unattempted ≠ wrong;
- early stop/one missed note/one extra note/false start tests;
- 30 s analysis <2 s mid-range Android, <4 s mobile Safari; memory <100 MB; ≥50 fps; no ANR;
- 60 s WAV ≤6 MB; 20 takes ≤120 MB; delete/export works; no OOM.

**If fail:** do not build the phrase loop. Pivot to call-and-response, single-bar assessment, or a pure notation trainer. That is a legitimate smaller product.

### 4.6 Required code fixes

- Read effective `RecordConfig` sample rate/channels; resample explicitly (the current 44.1 kHz assumption is a latent pitch bug on 48 kHz devices).
- Add monotonic sample-clock timestamps to `PitchFrame`.
- Separate onset detection from pitch frames.
- Fix the first-review FSRS lapse branch.
- Use pure versioned migrations; fixtures v1–v5; explicit rollback behavior.
- Separate progress, media, content, and account stores.
- Do not put recordings in `ProgressState`; use a `MediaStore` with web/mobile conditional imports.
- Update privacy copy and iOS usage string before recording ships.
- Add Android/web builds to CI; iOS release build; corpus tests as a slow job; manual device checklist.

---

## 5. Session design

### 5.1 Default 5-minute session

| Time | Block | Detail |
|---|---|---|
| 0:00–0:30 | Tune/setup | Tuner; posture checklist; no score |
| 0:30–1:30 | Technique | One 60-second rotating drill (right hand/left hand/shift) |
| 1:30–2:00 | Model | Listen to human reference; hum; clap rhythm |
| 2:00–3:30 | Acquire | One bar at 50–70%; 3–5 blocked reps; one correction |
| 3:30–4:30 | Apply | Play the bar at target tempo; one take (record only on performance day) |
| 4:30–5:00 | Reflect | Self-rating first; app shows one metric + one next step |

On maintenance days, extend to **6 minutes** and add one previously learned bar/phrase at the end. Do not squeeze maintenance into the 5-minute standard; the 5-minute session is already full.

### 5.2 10-minute option

Adds: a second bar/phrase, a sight-reading etude, or a technique drill. Still one target.

### 5.3 Rules

- One new demand at a time: notes OR rhythm OR tempo OR expression.
- Phrase length 1→2→4 bars; tempo 50→60→70→80→target; change one variable per step.
- Blocked acquisition first; interleave later once the phrase is playable at 70–80%.
- Feedback after 2–3 reps, one correction, then a rep applying it.
- Fade the score: ask for a prediction; show evidence after.
- If two consecutive reps fail, reduce tempo/length; do not repeat the same failed rep.
- **Record 1–2× per week on a performance day, not every session.**
- One no-score play session per week; one “play for someone” assignment in week 4.
- **Maintenance play:** one previously learned bar/phrase at the end of a 10-minute session; on a 5-minute maintenance day, extend to 6 minutes and add it at the end.
- **Technique:** 60-second rotating drill is built into the 5-minute timetable above; per-stage focus.
- Measure time on instrument, not prompt count. Target: 3+ minutes guitar in hand in a 5-minute session.

### 5.4 Onboarding and placement

Three screens:

1. “Do you have your guitar?” Yes/Not now.
2. “How well do you read?” Note names / slow reader / comfortable.
3. “Pick a first piece” (three cards with audio).

Then a 3–5 minute diagnostic:

- play a 4-bar phrase at 60/80/100 BPM;
- sight-read two bars;
- identify a few notes/rhythms;
- three technique self-checks.

Place only within stages that have V1 content: **1–3, 5, 9–10**. If the diagnostic suggests stage 6–8, map to the nearest V1 stage (5 or 9) and label the missing stage “Phase 2.” Allow manual override; start with a three-piece set; re-test every 4–6 weeks. The diagnostic is skippable; the app can infer a starting tier from the first 30–60 seconds of playing so the “first phrase <3 min” target is protected. Returners start at stage 3, 5, or 9, not open strings.

### 5.5 Notifications

- Local notification at a user-chosen time with the specific task: “Today: bars 5–8 of Sor, 5 min.”
- Weekly recap: minutes, phrases, one before/after.
- “Your before/after is ready” trigger after a performance take.
- No account required. Measure opt-in and session-2 lift.

---

## 6. Curriculum and content

### 6.1 12 stages (V1 subset)

| Stage | Focus | V1? | Outcome |
|---|---|---|---|
| 1 | First position, open strings, pulse | Yes | Play a 4-bar monophonic study at 60 BPM |
| 2 | Notes on strings 1–3, simple rhythms | Yes | Play an 8-bar folk melody |
| 3 | Notes on strings 4–6, accidentals | Yes | Play a 12-bar monophonic piece |
| 4 | Two-voice texture, rest stroke | Phase 2 | Play a Bach minuet with bass (teacher/self-review) |
| 5 | Position shifts, guide fingers | Yes (monophonic) | Play a 12-bar study with two shifts |
| 6 | Slurs, articulation | Phase 2 / self-review | Play a phrase with clean slurs (rubric) |
| 7 | Chords/arpeggios (reading) | Phase 2 | Play a broken-chord study (self/teacher) |
| 8 | Expression: dynamics, rubato | Phase 2 / self-review | Play pp→mf→pp (rubric) |
| 9 | Sight-reading fluency | Yes | Read a 4-bar etude at sight at 70 BPM |
| 10 | Repertoire consolidation | Yes | Perform a 1-minute monophonic piece |
| 11 | Exam-style tasks | Phase 2 | Generic Grade 1–2 sight-reading mock |
| 12 | Performance/recording | Yes | Record a 2-minute program |

V1 stages: 1–3, 5, 9–12. Stages 4/6/7/8 are explicitly self/teacher-reviewed or Phase 2; they are not mic-mastery claims.

### 6.2 Launch pieces (strictly monophonic)

10 pieces, one level, 4 phrases each; all validated as one sounding note at a time:

- Greensleeves — melody
- Scarborough Fair — melody (original arrangement)
- Londonderry Air / Danny Boy — melody
- Ode to Joy — melody
- Amazing Grace — melody
- Bach — Minuet in G melody (single line, no bass)
- Spanish Romance — melody (single line)
- Two original monophonic studies (beginner/returner)
- Down by the Riverside — melody

No Sor/Giuliani/Carcassi two-voice studies in V1. Two-voice/chord repertoire is Phase 2.

Validator enforces:

- one sounding note at a time;
- no overlapping durations;
- no chords/double stops;
- written vs sounding pitch explicit;
- string/fret matches sounding pitch;
- time signature, bars, rests, ties, pickup;
- range/position;
- human reference recording exists;
- license/territory.

**Piece-to-stage map (V1):**

| Tier | Piece | V1 stage |
|---|---|---|
| Foundation | Greensleeves (melody) | 1 |
| Foundation | Ode to Joy (melody) | 2 |
| Foundation | Amazing Grace (melody) | 2 |
| Foundation | Down by the Riverside (melody) | 3 |
| Foundation | Original monophonic study 1 | 3 |
| Returner | Scarborough Fair (melody) | 5 |
| Returner | Londonderry Air / Danny Boy (melody) | 5 |
| Returner | Bach Minuet in G (single line) | 9 |
| Returner | Spanish Romance (single line) | 9 |
| Returner | Original monophonic study 2 | 10 |

Stage 12 is a performance/recording checkpoint using any passed piece. Stages 4/6/7/8 are Phase 2 or self/teacher-reviewed and are not placement targets in V1.

### 6.3 Sight-reading

- 60 reviewed etudes at launch (12 per level, levels 1–5).
- Generator beta with a guitar-specific playability validator: max stretch, string crossings, position shifts, open strings, repeated notes, range, rhythm cells, musical cadence.
- First read recorded and scored silently; feedback after the second read; first-read accuracy/timing is the metric.
- No “unlimited” claim until the generator is validated.

### 6.4 Reference recordings

A synth is not a model of guitar tone, articulation, or phrasing. Record a human guitarist at target and slow tempo for every launch piece and etude level. Non-negotiable.

### 6.5 Content calendar

- Launch: 10 pieces, 60 etudes, 10 technique checklists, **20 reference recordings** (each piece at target and slow tempo; etude-level references as needed).
- Months 1–6: 2 new pieces/month; 2 new etudes/week; 1 technique video/month.
- Months 7–12: 2–3 pieces/month; 40 pieces total; 100+ etudes.
- Months 13–24: 40–60 pieces; 200+ etudes; exam-style packs (generic).
- Cost per piece: $500–1,500 and 8–16 hours; budget and contractor plan required.
- If the calendar cannot be sustained, switch to one-time piece packs at $49–79 instead of a subscription.

**T3.9 status:** modeled in [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md). The
10-piece launch is a 2–3 month supply, not a year. Launch plus 24 months costs
about $57k low / $116k base / $174k high at contractor rates, about $51k above
the plan's $25k/$40k content lines. The document recommends funding the base
cadence or switching to one-time piece packs at $49–$79, and defines the
measurable gate.

### 6.6 Technique strand

- Per-stage focus: setup/tuning/posture; left-hand thumb/arch/fingertips; right-hand rest/free stroke/alternation; damping; shifts; slurs.
- 60-second drill in the 5-minute rotation.
- Video demos; three-item rubric (thumb/arch/wrist; rest/free/alternation; damping/tension).
- Export-for-teacher review in V1.
- Pain warning: stop if pain, numbness, or tingling; see a teacher; no medical claims.
- No automated hand assessment. The app must not claim to replace a teacher for setup/posture.

---

## 7. Mastery, FSRS, and progress

### 7.1 Three claims

1. **Can recognize** — note/rhythm/theory quiz; FSRS.
2. **Can play slowly** — unhinted, mic-verified, 70–80% tempo.
3. **Can perform** — unhinted, mic-verified, target tempo, in time, 3 separate days, ≥7 days after first, novel transfer, delayed unassisted checkpoint.

Only #3 is “mastered” in the UI.

### 7.2 Fixes

- `transfer` = new key/position/piece/context, not any review.
- `production` = playing into mic/MIDI, not staff/fret tap/order.
- `mastered` requires a passed performance checkpoint.
- Hinted/revealed answers are not “correct” for mastery.
- Add a test: a multiple-choice-only learner cannot master a performance skill.
- Fix the first-review FSRS lapse branch.
- FSRS stays for atomic skills (notes, rhythms, intervals).
- Repertoire uses a separate time-budgeted queue: 3–5 pieces in rotation; one maintenance play per session; monthly full performance.
- Do not call FSRS stability “performance mastery.”

### 7.3 Progress UI

- **Can play** (performance mastery): piece/phrase, tempo, date, recording.
- **Shaky** (due/fragile atomic skills).
- **Reading** (notes/rhythms/intervals mastered).
- **Next** (recommended bar/etude).
- Weekly recap: minutes, phrases, recordings, one before/after.
- No lesson-completion percentage as the primary metric.

---

## 8. Gamification and social

- Remove hearts entirely.
- **Streak:** optional; any effective practice (3+ minutes guitar or one recorded take) counts; freeze; no loss framing.
- **Weekly goal:** minutes or phrases, not XP.
- **Mastery map:** “can play” pieces/phrases, not lesson completion.
- **Personal bests:** tempo, accuracy, timing, recordings.
- **Badges:** first recording, first full piece, 5-day streak, 10 clean phrases.
- **No public leaderboards or score-sharing in V1.**
- **No gems/chests/shop** in V1.
- **Quests:** “play 3 phrases,” “record a take,” “learn 4 bars,” not “answer 10 notes.”
- **Social:** none in V1. Phase 3 only after 10k MAU and a moderation/privacy plan.

---

## 9. Recording and privacy

- Record WAV for analysis; compress to AAC for storage; keep first and last take per piece for before/after.
- Local `MediaStore`; web IndexedDB, mobile files.
- Playback + A/B; normalize loudness before comparison.
- Before/after card: piece, phrase, date, one metric, optional audio clip; no public score.
- Default private. Share only by explicit export.
- Cap 60 s per take, 20 takes; delete/export; reconcile orphans.
- Exclude recordings from iCloud/Android backup unless the user opts in.
- Update privacy copy and iOS usage string before shipping.
- No accounts/cloud in V1.
- Optional email capture is separate from progress, explicit consent, no audio.

---

## 10. Technical plan

### 10.1 3-week spike (gate)

See §4.5. Do not build UI/content until the spike passes.

### 10.2 Phase 1 (10–12 weeks with a team; 5 pieces/30 etudes if solo)

- `AttemptOutcome` tri-state at the domain boundary.
- `PracticeSession` separate from `LessonRun`; Reading Lab keeps `LessonRun`.
- Piece/Phrase models + parser/validator; strictly monophonic.
- PhrasePlayPrompt + constrained matcher + tri-state.
- 10 pieces, 60 etudes, 10 reference recordings.
- Today session UI (5/10 min).
- Recording/A-B/MediaStore.
- Technique checklist + videos.
- Free demo + Pro IAP.
- Remove hearts; optional streak/weekly goal.
- Runtime phrase-objective resolver; content versioning.
- **Phrase evidence granularity:** a phrase attempt updates the phrase objective; per-note atomic skills update only from determinate, high-confidence note evidence. No double-counting. An indeterminate phrase updates nothing. Add tests for both paths.
- Tests: parsing, DTW, scoring, migration, widget, indeterminate-no-update, no-double-count.

### 10.3 Phase 2 (8–10 weeks)

- MusicXML import (user's own monophonic pieces).
- Generic Grade 1–3 sight-reading packs (no board names until licensed).
- Teacher pilot: manual export workflow at $19/mo; COPPA plan; no persistent cloud.
- Adaptive etude generator v2.
- Opt-in aggregate analytics.
- Two-voice/MIDI path research only.

### 10.4 Phase 3 (months 6–12)

- **No piano in the 12-month plan.** Piano is a post-12-month optional expansion; it is polyphonic and needs a separate assessment spike.
- Technique video check/teacher review.
- Ear-to-hand call-and-response.
- Cloud sync/accounts only if users ask and privacy model is updated.
- AI feedback only after rule-based proves learning gains and cost <$0.02/session.

### 10.5 Phase 4 (months 12+)

- Social/recital only after 10k MAU and moderation plan.
- UGC/teacher marketplace only if teacher pilot works.
- Advanced repertoire, exam packs 4–5.

---

## 11. Business model

### 11.1 Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | 3 pieces, 10 etudes, 3 recordings, tuner, basic feedback |
| Pro | $8.99/mo or $69/yr | All 10+ pieces, 60+ etudes, recordings, advanced feedback, offline |
| Exam packs | $19–29 per grade (Phase 2) | Generic Grade 1–3 sight-reading; no board names |
| Teacher Studio | $19/mo per teacher, up to 30 students; $0.75/student above (Phase 2) | Manual export, assignments, progress |
| Lifetime | $129, capped 500 | Pro forever |

No ads. No cloud AI in V1. No licensed pop catalog. No social feed.

### 11.2 Paywall timing

- After the first recording + day-7 recap.
- 7-day free trial.
- Test gating etudes/diagnosis vs. piece count.
- Free tier is a demo, not the product.

### 11.3 Base case P&L and cash model (organic only, no teacher/exam revenue)

Assumptions: 3% install→paid; 50% annual renewal; $69/year blended; 15% store fee; 5% refunds/tax reserve; teacher and exam revenue excluded.

| Line | Year 1 | Year 2 | Year 3 |
|---|---:|---:|---:|
| Installs | 7,500 | 20,000 | 40,000 |
| New Pro | 225 | 600 | 1,200 |
| Retained Pro (50%) | 0 | 113 | 357 |
| Total Pro | 225 | 713 | 1,557 |
| Gross revenue | $15,525 | $49,197 | $107,433 |
| Net after store fee/refunds | $12,536 | $39,726 | $86,752 |
| Content (pieces/etudes/recordings) | $25,000 | $40,000 | $60,000 |
| DSP/dev contractor | $15,000 | $20,000 | $25,000 |
| Legal/compliance | $8,000 | $3,000 | $3,000 |
| Hosting/support | $2,000 | $5,000 | $10,000 |
| Marketing/content | $3,000 | $8,000 | $12,000 |
| Tools/ops | $2,000 | $3,000 | $4,000 |
| **Total costs** | **$55,000** | **$79,000** | **$114,000** |
| **Profit** | **-$42,464** | **-$39,274** | **-$27,248** |
| Cumulative cash | -$42,464 | -$81,738 | -$108,986 |

This implies roughly **625 / 1,667 / 3,333 installs per month**. If organic acquisition cannot deliver 3,300/month by Year 3, use the downside case.

**Break-even:** ~2,500 Pro at ~$172k gross / ~$139k net revenue, with costs near $120k. That is Year 4 at the current growth rate, or Year 3 if installs reach ~60k/year.

**Downside case (2% conversion, 40% renewal):**

| Line | Year 1 | Year 2 | Year 3 |
|---|---:|---:|---:|
| New Pro | 150 | 400 | 800 |
| Retained Pro | 0 | 60 | 184 |
| Total Pro | 150 | 460 | 984 |
| Net revenue | $8,360 | $25,640 | $54,840 |
| Total costs | $55,000 | $79,000 | $114,000 |
| Profit | -$46,640 | -$53,360 | -$59,160 |
| Cumulative cash | -$46,640 | -$100,000 | -$159,160 |

The monthly model is the annual table divided into 12 install cohorts, 3% conversion, ~4.2%/month churn (50% annual), net revenue after fees/refunds, and costs divided into monthly contractor/legal/hosting lines. Track cash monthly; the annual table is the summary, not a substitute for the cash schedule.

**Upside/stretch:** 3,000 Pro + 100 teachers ≈ $220k gross, ~$50–80k profit. Teacher and exam revenue are **upside only**, not in the base case, until three paid teacher pilots pass.

Founder salary is not included. If a market salary of $60–100k/year is required, add it and break-even moves to ~4,000–5,000 Pro or a higher price.

**Implication:** this is a bootstrap/lifestyle niche business. It needs ~$110–160k of runway to reach break-even, or a lower cost base. It is not a venture-scale consumer app on this plan. If venture is the goal, the path is piano, schools, and exam boards—not pop songs—and it needs a separate plan.

### 11.4 Acquisition

**Beachhead:** consumer classical/folk returners. Teacher/exam are Phase 2.

- **SEO/content:** “guitar sight reading app,” “how to read music on guitar,” “classical guitar practice,” “Sor study,” “Carcassi etude,” “ABRSM guitar sight reading” (generic content until licensed).
- **Free web sight-reading test:** 2-minute test; shareable result; email capture; top of funnel.
- **Short-form:** “Can you sight-read this in 30 seconds?”, “Fix this bar,” before/after clips, teacher tips; 2/week.
- **Communities:** r/classicalguitar, Delcamp, classical guitar societies, exam forums, teacher newsletters; participate, don't spam.
- **Teacher referrals (Phase 2):** 3 LOIs; manual export; referral code. Not in the base case.
- **ASO:** subtitle “Guitar Sight-Reading & Practice”; screenshots show notation, before/after, 5-minute session.
- **20 free lessons/tools** in the first 12 months (sight-reading basics, rhythm, practice method).
- **No paid UA initially.** The math is unfavorable at $5+ CPI and 3% conversion.

### 11.5 Validation before build

1. **Pre-sale price test:** three landing-page cells at **$49 / $69 / $99** annual founding pre-order; 1,000 targeted visitors per cell (3,000 total); gate: **30+ pre-orders across cells or ≥3% conversion in the best cell**, email capture ≥10%. Drop the CAC <$50 gate for organic traffic; run a separate $500 paid test only if paid acquisition is being considered.
2. **Concierge:** 12 adult returners, 4 weeks, 5 min/day, weekly Zoom; $25; gate: 60% do 3+ sessions/week, 50% would pay $8/mo.
3. **Teacher LOIs only (pre-build):** 10 interviews; 3 non-binding LOIs at $19/month for 20–30 students. Manual export flow: the student selects a take → exports audio + a one-page JSON/PDF summary via the share sheet → the teacher opens it in the app/web viewer. No persistent cloud, no automatic sync. Do not claim “70% weekly assignment use” before the product exists. Paid teacher pilots are Phase 2 and require a COPPA/guardian-consent plan before any under-13 student participates.
4. **Assessment spike:** see §4.5. Budget $1–2k for corpus/device testing.
5. **Learning pilot:** 12–20 returners, 4 weeks, 5 min/day, before/after recordings, blind teacher ratings, delayed transfer (7–14 days), active control; pre-register, report effect size/CI; acknowledge pilot power. Budget $2–5k.

Do these in parallel before Phase 1. **Total validation budget: $5–8k**, including the learning pilot and corpus. Add **$5–10k** for legal review before launch.

### 11.6 Funding and legal gate

- **Funding decision before Phase 1:** one page. Bootstrap: target $250k ARR, 24-month runway, ~$110–160k cash need. Venture: only with a credible piano/schools/exam path to $10M+ ARR; the current plan does not show that.
- **Legal review ($5–10k):** public-domain status by territory; arrangement copyright; exam-board IP (no board names until licensed); pre-sale consumer terms; recording consent and privacy policy; app-store subscription terms. Go/no-go before Phase 1.

---

## 12. Metrics and experiments

### 12.1 North star

**Weekly effective practice minutes** — proxy: mic-active minutes with valid pitch plus at least one phrase attempt, validated against self-report — with a quality guardrail: **weekly recorded phrases/pieces**.

### 12.2 Targets (category benchmarks)

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

### 12.3 Learning proof

- Delayed (7–14 day) performance of a practiced and a held-out transfer phrase, blind-rated by two teachers or a validated automated score, at fixed tempo, unassisted.
- Compare against an active control (metronome/current course).
- Report effect size and confidence interval; do not call in-app accuracy “learning.”

### 12.4 Kill criteria

- Phrase-level false fail >10% or false pass >5% in the spike → stop mic-first.
- <35% return for session 2 within 48 h → fix onboarding/loop.
- <25% record by day 7 → performance is not compelling.
- Best-cell pre-sale conversion <1.5% or <15 pre-orders → demand is not proven.
- D30 <8% after 3 months → niche/positioning wrong.
- Free→Pro <1.5% after 3 months → paywall/value wrong.
- Content calendar slips below 1 new piece/month → subscription promise broken.

### 12.5 Experiments

1. 5-min vs 10-min default.
2. 60 reviewed etudes vs generator beta.
3. Recording/A-B vs no recording.
4. Human reference vs synth reference.
5. Self-rating first vs score first.
6. Streak vs weekly goal only.
7. Pre-sale $49 vs $69 vs $99 annual (decide price before Phase 1).
8. Free demo 3 pieces vs 5 pieces.
9. Teacher-assigned vs self-chosen piece.
10. Generic grade pack vs general repertoire.

---

## 13. Roadmap

| Phase | Weeks | Deliverables | Gate |
|---|---:|---|---|
| 0 | 1–3 | Assessment spike; corpus; latency/bleed tests; three-cell pre-sale; concierge; legal/funding decision | Spike pass; 30+ pre-orders or 3% best-cell conversion; 60% concierge retention; legal go/no-go |
| 1 | 4–15 | Today loop; 10 pieces; 60 etudes; recording; technique; paywall | 20 users, 3x/week, 4 weeks; false fail ≤10%; D7 ≥18% |
| 2 | 16–25 | MusicXML import; generic grade packs; teacher pilot; generator v2 | D30 ≥10%; free→Pro ≥2%; 3 teacher pilots |
| 3 | 26–52 | Technique video; ear-to-hand; cloud/AI evaluation; post-12-month piano research only | Guitar retention proven; separate assessment gate for any expansion |
| 4 | 12+ months | Social/recital; UGC; marketplace; optional piano | 10k MAU; moderation/privacy plan; piano assessment spike passes |

**90-day sprint:**

| Week | Deliverable |
|---|---|
| 1 | Corpus recruited; latency/bleed rig; sample-rate fixes |
| 2 | Onset detector + constrained matcher; tri-state; spike metrics |
| 3 | Spike report; go/no-go; three-cell pre-sale live; legal/funding decision |
| 4 | `AttemptOutcome`/`PracticeSession`; piece model; validator |
| 5 | Phrase prompt; 3 pieces; 15 etudes |
| 6 | Today UI; recording/MediaStore |
| 7 | 6 pieces; 30 etudes; technique checklist |
| 8 | 10 pieces; 60 etudes; reference recordings |
| 9 | Paywall; notifications; onboarding/placement |
| 10 | 20-user pilot; fix |
| 11 | Learning pilot; before/after; blind ratings |
| 12 | Launch beta; decide Phase 2 |

---

## 14. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Phrase assessment inaccurate | High | High | 3-week spike; exact pitch; fixed click; tri-state; corpus; false fail ≤10% |
| Backing/click bleed | High | High | Headphones + shared clock; no drones; click-in-recording alternative; score notes only if no clock |
| Content authoring too slow | High | High | 10 pieces, 4 phrases; 60 etudes; contractor; reference recordings; 24-month calendar |
| Market too small | Medium | High | Teacher/exam Phase 2; post-12-month piano expansion; validate pre-sale |
| Retention below niche benchmark | Medium | High | 5-min default; one target; recording; human reference; notifications; placement |
| Technique not assessed | High | Medium | Checklist/video/rubric; teacher referral; no false claims |
| Privacy contradiction | Medium | Medium | No accounts/cloud in V1; local recordings; update copy |
| Copyright | Medium | High | Public domain/original; legal review; territory check; no copyrighted arrangements |
| Solo bandwidth | High | High | Cut scope; 3-week spike; contractor for DSP/content; 5 pieces/30 etudes if solo |
| Open-source code copyable | High | Medium | Moat = pedagogy, content quality, teacher trust, brand; not code |
| AI overpromise | Medium | Medium | No AI in V1; rule-based DSP; later only if validated |
| Subscription promise vs. content | High | High | 2–3 new pieces/month or one-time pricing; content calendar |

---

## 15. What not to do

- Do not build a mass-market pop-song app.
- Do not license a 100-song catalog.
- Do not add chords/strumming/polyphony to V1.
- Do not add social/recital/leaderboards/teacher dashboards/cloud/AI to V1.
- Do not keep hearts or punishment loops.
- Do not call multiple-choice/tap “mastery.”
- Do not use DTW-warped timing as a timing score.
- Do not use ±50 cents as “exact.”
- Do not claim technique/tone/chord assessment the mic cannot measure.
- Do not ship two-voice pieces as monophonic V1 content.
- Do not ship 30 songs before 10 pieces work.
- Do not spend on paid UA before organic/teacher traction.
- Do not promise “become a confident guitarist in 6 months.”
- Do not call a 10-piece demo a year of subscription content.

---

## 16. Open decisions

1. Exact 10 monophonic pieces, vetted for difficulty/musical payoff (Phase 0).
2. Free demo: 3 pieces vs. 5; gate etudes/diagnosis vs. piece count (Phase 1 experiment).
3. Email capture: optional vs. required for the free web test (Phase 0).
4. Teacher pilot: manual export workflow details (Phase 2).
5. Exam packs: generic vs. board partnership (Phase 2).
6. **Locked for V1:** 5-minute default; 10-minute option; price decided by the three-cell pre-sale before Phase 1; piano post-12-month; bootstrap-vs-venture decision before Phase 1.

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

Greensleeves; Scarborough Fair (original arrangement); Londonderry Air/Danny Boy; Ode to Joy; Amazing Grace; Bach Minuet in G (BWV Anh. 114) melody; Spanish Romance (anonymous) melody; Down by the Riverside; two original monophonic studies. Use original arrangements/recordings; avoid arrangements associated with copyrighted recordings; legal review per territory.

---

**Bottom line:** stop trying to become a worse Yousician. Become the best practice coach for guitarists who read music. Prove the mic on a corpus, ship 10 monophonic pieces and 60 etudes, make a 5-minute loop that ends with a real phrase and a recording, charge from day one, and earn the right to expand.
