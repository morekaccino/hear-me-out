# ASO plan — Hear Me Out

**Ticket:** T8.2 / HEARM-91.
**Status:** Draft for store review. Docs-only; no screenshot images and no app
changes are part of this ticket.
**Owner:** Growth/store listing. The 10-user test, the store submission, and every
paid decision are human-owned.
**Last updated:** 2026-11-06.
**Scope:** App Store and Google Play listing copy, keyword plan, screenshot
storyboard, screenshot test protocol, launch sequencing, claims and compliance,
and the metrics that decide whether any of it worked.
**Source of truth:** Plane T8.2. The approved plan is
[`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md); see its sections
2, 6, 11.4, 11.5, 12, and 13. The design rules are in [`DESIGN.md`](DESIGN.md).
Gate evidence is in [`PHASE_GATES.md`](PHASE_GATES.md). Demand assumptions are in
[`ASSUMPTION_TRACKER.md`](ASSUMPTION_TRACKER.md).

> **Read this before copying anything into a store console.** The app in this
> repository is still the 240-lesson notation course. The approved 5-minute,
> song-first transformation is not implemented. The phrase loop sits behind
> `phraseLoopEnabled = false`, has no main-navigation entry, and has no validated
> microphone accuracy. The recording screen and before/after comparison are not
> built. Do not publish a listing or a screenshot that presents a gated or
> unbuilt feature as live. Section 3 marks each frame.

**Acceptance criteria status**

| Criterion | Status |
|---|---|
| Do not buy installs before organic/teacher traction | Encoded as a hard rule in section 5. This plan authorizes no paid spend. |
| Test screenshots with 10 target users | **Not run.** The protocol, pass/fail rules, and recording format are in section 4. Human-owned. |

---

## 1. Store listing

### 1.1 Field limits and naming decision

| Field | Store limit | Proposed value | Count | Status |
|---|---|---:|---:|---|
| App name | 30 (both stores) | `Hear Me Out` | 11 | Use. It carries no guitar or learn keyword; the subtitle carries discovery. |
| Subtitle | 30 (App Store) | `Guitar Sight-Reading & Practice` | 31 | Canonical line. Over the App Store limit; see 1.2 for the proposed fallback. |
| Short description | 80 (Google Play) | `Practice guitar sight-reading with notation drills. No account, no ads.` | 71 | Use. |
| Long description | 4,000 (both stores) | Section 1.4 | Under 4,000 | Use only after the claims audit in section 6. |
| Keyword field | 100 (App Store) | Section 2.4 | 94–97 | Use per locale. |
| What's new | 500 (Google Play) / 4,000 (App Store) | Section 1.5 | Template | Use the short form on Google Play. |
| Promotional text | 170 (App Store) | Not used in this plan | — | Optional, only with a dated promotion. |

The name **Hear Me Out** is kept as the brand. It does not contain a guitar,
notation, or learning keyword, so the subtitle, the keyword field, the short
description, and the screenshot order do the discovery work. Do not add a
keyword-stuffed suffix to the app name; it weakens the brand and risks a metadata
rejection.

### 1.2 Subtitle

**Canonical positioning line**

```
Guitar Sight-Reading & Practice
```

That is 31 characters. As of the App Store Connect field limit at the time of
writing, the subtitle field allows 30 characters. Do not submit a truncated
string and do not drop a word to make it fit.

**Proposed fallback**

```
Guitar Sight-Reading Practice
```

That is 29 characters and keeps all four words: guitar, sight, reading, and
practice. The ampersand is punctuation; do not rely on it as a search token. If
the console accepts the 31-character line at submission time, use the canonical
line; otherwise use the 29-character variant and record the choice in the listing
handoff.

Google Play has no subtitle field. The short description and the first sentence of
the long description carry the same job.

### 1.3 Short description

Google Play short description (80 max):

```
Practice guitar sight-reading with notation drills. No account, no ads.
```

71 characters. It starts with the primary verb and keyword, names notation, and
states the privacy differentiators. It does not claim a 5-minute session, real
pieces, recordings, validated microphone accuracy, or unlimited content.

Apple has no short-description field. The first two lines of the long description
perform that job.

### 1.4 Long description — current build, publishable after review

Plain text, ready for the store console. It describes the app that exists today.

```
Read music. Play guitar.

Hear Me Out is a calm, local-only guitar sight-reading and note-reading trainer.
A typical lesson shows a note on a treble staff and asks you to name it or play
it. Other lessons add chords, rhythm, and ear training. The microphone listens on
your device and tells you what it heard. If the microphone is unavailable, you can
answer with note names instead.

WHAT YOU GET
• 240 lessons across 40 units, from open strings and first position to rhythm,
  chords, harmony, scales, ear training, and fretboard work.
• Guitar-correct notation. The staff shows written pitch; the app listens for
  the octave below.
• One review schedule for the skills the course teaches: notes, rhythm, chords
  and harmony, theory, ear training, and fretboard work. Mastery needs correct
  answers across several days, not one lucky tap.
• A standard-tuning tuner and a 60-second technique self-check.
• No hearts, no loss loops, no leaderboards. A wrong answer never costs a life.
• Local-only progress. No account, no cloud, no ads, no third-party trackers.
  Your progress is stored in the app on your device, and you can copy a JSON
  backup if you want one.

WHO IT IS FOR
Adult beginners and returners who want to learn to read standard notation on
guitar, practice alone for a few minutes, and see honest feedback. It suits
classical, folk, acoustic, and fingerstyle players who want a notation-first
practice routine. It is not a tab library, a chord-song app, or a replacement for
a teacher.

WHAT IS NOT IN THIS VERSION
A guided 5-minute Today session, real-piece phrase practice, recordings, and
before/after comparison are planned, not shipped. The app does not claim
validated microphone accuracy or unlimited generated content.

No account. No ads. No cloud. Read music. Play guitar.
```

**en-GB spelling note:** in the long description, change "practice alone" to
"practise alone". "Practice routine" is a noun and stays as written. The en-GB
short description is in section 2.4. No other wording changes.

**Claims check:** every sentence above maps to a shipped surface, a
target-audience statement, or an explicit "not in this version" statement. Do not
"improve" it by adding a phrase, a before/after promise, a five-minute promise, or
an accuracy percentage before the matching gate ships. Section 6 is the gate.

### 1.5 What's new template

```
Version <version> — <one theme>

• New: <user-visible change>.
• Improved: <change to an existing flow>.
• Fixed: <bug or rough edge>.

No account, no ads. Your practice stays on this device.
```

Rules:

- Google Play's release-note field is short (500 characters at the time of
  writing); confirm the current limit in the console and keep the Google version
  to the three bullets and the closing line.
- Announce only what is in the build. If the phrase loop is still gated, do not
  mention it. If a beta phrase loop ships, write "Beta: phrase practice" and
  never an accuracy percentage.
- No testimonials, ratings, install counts, or "now better than ever" without a
  dated source.
- Put the user-visible change first, not the internal ticket name.

### 1.6 Copy held for later gates

These lines are planned but **must not appear in the current listing**:

| Copy element | Hold until | Why |
|---|---|---|
| "5-minute Today session" | The Today loop is built and the Phase 1 gate passes | The current Today card is a next-lesson card, not a timed five-minute session. |
| "Real pieces" or "phrase practice" | T1.7 passes, `phraseLoopEnabled` is enabled, and a navigation entry exists | The phrase player is gated and has no main-navigation entry. No microphone-accuracy claim is validated. |
| "Before/after recordings" | T4.2 ships the recording UI plus a real comparison surface | The media store exists; the recording screen and comparison do not. |
| "Technique videos" | The video assets exist | The technique screen currently shows written cues and "Demo video pending." |
| "Teacher" or "classroom" features | COPPA/guardian consent and legal clearance plus the Phase 2 teacher work | The teacher channel is not in the base case. |

If the phrase loop later ships as a beta, use a visible **Beta** label in the
screenshot and the listing. Do not show a score, a percentage, or a green
"validated" badge.

---

## 2. Keyword plan

### 2.1 Ranking hypothesis

The name has no query relevance. Store search relevance therefore has to come
from the subtitle, the keyword field, and natural use in the short and long
descriptions. The plan tests a **notation-first** query space rather than the
broad "learn guitar" space:

- Broad guitar queries are dominated by tabs, chords, and song-play apps. The
  target for this app is the smaller group that wants to read standard notation
  and practice a real instrument.
- The four required terms — **guitar sight reading**, **learn notation**,
  **classical guitar practice**, and **adult guitar** — are specific, high-intent,
  and less contested than "learn guitar." A small number of well-targeted
  installs can move rank for them; a broad term needs volume this plan does not
  have.
- Store conversion and early retention feed back into placement. Clear notation
  screenshots should raise product-page conversion, which supports rank. That is
  a hypothesis, not a promise: rank without installs, or installs without
  retention, is not a win.
- The plan does not buy installs to force a rank. Section 5 is the rule.

Measure the hypothesis as described in section 7: fixed keyword set, fixed
locale, logged-out store search or a disclosed rank tracker, weekly capture, and
a separate product-page conversion series. Change one field at a time and hold
the measurement window long enough to see a direction.

### 2.2 Primary keywords

| Keyword | Intent | Where it appears | Feature proof | Priority |
|---|---|---|---|---|
| guitar sight reading | Required. A guitarist wants to read notation and play it. | Subtitle, short description, long description, keyword field | Staff lessons with name/play answers and on-device pitch feedback | P0 |
| learn notation | Required. A beginner wants to learn to read music. | Long description, keyword field | 240-lesson notation course with a teaching arc | P0 |
| classical guitar practice | Required. A classical or folk player wants a practice routine. | Keyword field; long description names classical/folk players | Tuner, technique check, spaced review, notation lessons | P0 |
| adult guitar | Required. An adult wants a guitar learning path built for them. | Keyword field; long description names adult beginners/returners | Adult beginner/returner positioning; no child-directed copy | P0 |
| guitar sight-reading app | High-intent synonym for the category. | Subtitle, short description | The app is a notation trainer, not a tab library | P1 |
| read music on guitar | High-intent description of the job. | Long description (tagline), keyword field (reading) | Guitar-correct staff and octave handling | P1 |
| guitar note reading | Synonym for note naming. | Keyword field (note, reading), long description (note-reading) | Note-naming lessons and string/fret hints | P1 |
| sight-reading trainer | Category term with practice intent. | Candidate only; not in the current fields | Short lessons plus spaced review | P2 |

### 2.3 Secondary keywords

Use these only where the feature or claim is true. They are supporting terms, not
a substitute for the primary four.

- standard notation guitar
- first position guitar
- treble clef guitar
- guitar sight-reading exercises
- adult beginner guitar
- returning guitarist
- classical guitar practice routine
- guitar rhythm reading
- ear training for guitar
- guitar technique check
- guitar tuner practice
- offline guitar practice (verify airplane mode on both stores before publishing)
- no ads guitar app
- local-only guitar app

Do not repeat a secondary term in every sentence. Google Play treats keyword
stuffing as a metadata problem, and Apple's keyword field is a relevance field,
not a slogan.

### 2.4 Store fields by locale

The app is English-only. Create en-US, en-GB, and en-CA listings; do not machine
translate into other locales. Localize spelling, not claims.

**App Store keyword field (100 characters max, comma-separated, no spaces after
commas):**

| Locale | Keyword field | Count |
|---|---|---:|
| en-US | `sight,reading,notation,learn,classical,adult,returner,beginner,treble,clef,note,first,position` | 94 |
| en-GB | `sight,reading,notation,learn,classical,adult,returner,beginner,treble,clef,note,practise,first` | 94 |
| en-CA | `sight,reading,notation,learn,classical,adult,returner,beginner,treble,clef,note,practise,position` | 97 |

The subtitle already carries guitar, sight, reading, and practice (or the
field-compliant variant). The keyword field adds the required "learn" and
"adult" tokens, classical, and the gap terms below. It deliberately does not
repeat the app name.

**Google Play:**

| Locale | Short description | Count |
|---|---|---:|
| en-US / en-CA | `Practice guitar sight-reading with notation drills. No account, no ads.` | 71 |
| en-GB | `Practise guitar sight-reading with notation drills. No account, no ads.` | 71 |

Google Play has no keyword field. Put the terms in the short description and in
natural sentences in the long description. Do not paste the comma-separated
Apple list into the description.

### 2.5 Competitor gap terms

These are the gaps this listing can occupy without naming a competitor. Each is a
hypothesis to measure, not a proven ranking opportunity.

| Gap | Why it may be open | Terms to use | Do not use |
|---|---|---|---|
| Notation-first, not tabs | Most guitar apps lead with tabs, chords, or songs. | standard notation, read music on guitar, treble clef, guitar note reading | tabs, chords, easy songs, songbook |
| Adult returner | Many beginner apps target teens or absolute beginners. | adult guitar, adult beginner guitar, returning guitarist | kids, children, family, classroom |
| Structured practice | "Practice" apps often sell a tuner or a metronome, not a plan. | classical guitar practice, guitar practice routine, sight-reading exercises | "AI practice coach" until it exists |
| Local-only privacy | Few guitar apps make no-account/no-cloud a first-class promise. | no ads guitar app, local-only guitar app, offline guitar practice | "military-grade", "encrypted", "100% private" |
| Technique self-check | The app has a real 60-second checklist, not a video course. | guitar technique check, 60-second technique drill | teacher-approved, hand-tracking, AI posture |

### 2.6 Do-not-target list

Do not target or lead with these in metadata, screenshots, previews, ads, review
replies, or the website. A term may appear only as an explicit exclusion or as a
curriculum topic (for example "not tabs" or "chords and harmony" in the course
description); it must never become a discovery claim. Each item below is
unlicensed, unbuilt, unprovable, or wrong intent.

| Category | Do not use | Reason |
|---|---|---|
| Exam boards | ABRSM, Trinity College London, RCM/Royal Conservatory, Rockschool, AMEB, LCM, MTB, UNISA, NZMEB, "Grade 1 guitar", "exam ready" | No license or affiliation. Board names are reserved until the legal gate in the plan and T6.3 allow them. |
| Copyrighted methods or editions | Suzuki, Mel Bay, Hal Leonard, Berklee, Aaron Shearer, Frederick Noad, Pumping Nylon, and named editions of Carcassi or Sor | Method names and edited editions can be protected. Public-domain compositions still need a cleared arrangement. |
| Unbuilt features | "unlimited generated etudes", "AI teacher", "AI feedback", "personalized AI", "5-minute session" (now), "before/after recordings" (now), "real pieces" (now), "technique videos" (now), "teacher dashboard", "student accounts", "classroom" | Not shipped or gated. A store listing is not a roadmap. |
| Unprovable claims | "validated microphone accuracy", "scientifically proven", "guaranteed improvement", "learn guitar in 30 days", "become a confident guitarist in 6 months", "70% weekly assignment use", "#1", "best guitar app", "thousands of students", "teacher-approved", "5-star" | No dated evidence. Do not invent a benchmark or a testimonial. |
| Wrong audience or scope | "kids", "children", "family", "beginner songs", "easy songs", "tabs" as a lead term, "chords" as a lead term, "strumming", "pop songs", "electric guitar", "shred" | The app is an adult notation trainer. The wrong query wastes a tap and hurts conversion. Chords and harmony are course topics, not the product promise. |
| Competitor names | Duolingo, Yousician, Fender Play, Simply Guitar, Justin Guitar, GuitarTuna, Ultimate Guitar, SmartMusic, Tonara, and similar marks | Trademark and comparison risk. Do not target or imply endorsement. |
| Price or promotion | "free forever", "no subscription", "50% off" | Pricing and the paywall are not settled. Use no price language until the launch price is locked. |

### 2.7 Measurement

The ranking measurement is a fixed, pre-registered keyword set, not a search for
whatever looks good that week.

- Check each locale's terms in a logged-out store on a clean device, or use a
  rank tracker and disclose the tool. Record the date, locale, device, and
  position (or "not found").
- Capture product-page impressions, product-page views, and installs in the same
  window. Rank is not installs.
- Change one variable at a time: subtitle variant, keyword field, short
  description, or screenshot order. Hold for at least two weeks before judging.
- Keep paid and organic sources separate. A paid install never counts toward an
  organic or retention gate.
- Report sample size and denominator. A single week or a single search is an
  observation, not a result.

---

## 3. Screenshot storyboard

### 3.1 Production rules

This ticket delivers a storyboard and captions, not image files. A designer
captures from a real build after the frame is marked shippable.

- **No fake UI.** Every visible number, note, phrase, and progress state must come
  from a real session on the test device. Do not edit numbers into a capture.
  Captions and callouts may be added around the UI, not over the note head or the
  feedback text.
- **No unshipped frame in a store listing.** A frame marked "not shippable yet" is
  a design brief. Publish it only after its gate ships and the screenshot is
  recaptured from the build.
- **One job per frame.** Headline of seven words or fewer, subline of twelve words
  or fewer. Nunito ExtraBold, sentence case for the subline, uppercase only for a
  short badge.
- **Contrast and crop.** Keep captions out of the status bar and home indicator.
  Keep at least 4.5:1 contrast. Do not crop ledger lines, the staff clef, or the
  feedback text.
- **Sizes.** Use the sizes App Store Connect requires at submission time (the
  6.9-inch and 6.5-inch phone sets are the current baseline) and a 9:16 Android
  set at 1080×1920 or larger. Export PNG, sRGB, no alpha, no device-brand frame
  that the store has not approved.
- **Localization.** Leave room for 30% text expansion. Use en-GB "practise" where
  the word is a verb. Do not add a translated screenshot before the app is
  localized.

### 3.2 Storyboard at a glance

| # | Job | Headline | Implementation status |
|---|---|---|---|
| 1 | Notation is the hero | Read the note. Play the note. | **Shippable today** (lesson screen) |
| 2 | A real phrase, not a quiz | Practice a real phrase. | **Not shippable yet** (phrase loop gated) |
| 3 | Before/after proof | Hear the difference. | **Not shippable yet** (no recording UI) |
| 4 | Five-minute Today session | Five minutes. One next step. | **Partially shippable** (Today card only) |
| 5 | Technique self-check | A 60-second technique check. | **Shippable today** (Practice → Technique check; video pending) |
| 6 | Privacy/local-only | No account. No cloud. No ads. | **Shippable with crop** (Profile privacy card; media sentence excluded) |
| 7 | Progress/can-play | Real progress, not a streak. | **Partially shippable** (progress stats; no can-play evidence) |

### 3.3 Frame details

#### Frame 1 — Notation

- **Caption:** `Read the note. Play the note.`
- **Subline:** `One staff. One clear answer.`
- **Visual:** a real lesson screen with a single treble-staff note, the answer
  choices, the mic meter, and a green feedback panel showing the correct
  string/fret hint. Use a real note from the course; the design example
  `E4 · D string, fret 2` is acceptable only if that is the note on screen.
- **Proof point:** guitar-correct notation. The staff shows written pitch and the
  microphone listens for the sounding pitch one octave below; the string/fret
  hint uses the same mapping. Naming is a first-class fallback when the mic is
  unavailable.
- **Status:** **Shippable today.** Capture from the lesson screen. No accuracy
  percentage, no "100% correct", no waveform.
- **Designer note:** the staff is the hero. Do not place the caption over the
  staff or hide the feedback. One note, one answer, one clear next action.

#### Frame 2 — A real phrase

- **Caption:** `Practice a real phrase.`
- **Subline:** `Hear it. Play it. Fix one bar.`
- **Visual:** the phrase player with a two-to-four-bar public-domain phrase, a
  model/listen control, a mic take, one correction, and a small **Beta** badge if
  the loop ships as beta. No score percentage.
- **Proof point:** phrase-level practice with one correction, not a definition
  quiz. The phrase is real repertoire, and the feedback is one actionable next
  step.
- **Status:** **Not shippable yet.** The phrase player, prompt, verifier, recorder,
  and scored-take gate exist, but `phraseLoopEnabled` is false and no screen calls
  the player. T1.7 corpus evidence is not passed, and no microphone-accuracy
  claim is validated. The onboarding "Pick a first piece" cards have a synth
  preview; they are not phrase practice. Do not capture or publish this frame.
- **Designer note:** design against the phrase-player spec, but do not invent a
  waveform score, a teacher rating, or a "98% accurate" badge. If the loop is
  still gated at submission, omit the frame entirely.

#### Frame 3 — Before/after

- **Caption:** `Hear the difference.`
- **Subline:** `Record a take. Compare it later.`
- **Visual:** two take cards, "Before" and "After", with a date, duration, and a
  play control, plus a plain note that recordings stay on the device. A simple
  A/B toggle is enough; no waveform editor.
- **Proof point:** the learner can hear their own change over time. The comparison
  is user-initiated and local.
- **Status:** **Not shippable yet.** The local media store and its platform rules
  exist, but there is no recording screen, no take comparison, and no
  before/after surface. T4.2 and the phrase integration are prerequisites. Do not
  show a waveform, a date, or a score that the app cannot produce.
- **Designer note:** keep it plain and honest. No "AI analysis", no teacher
  rating, no "progress guaranteed". If the backup-exclusion copy is not confirmed
  on the device, do not imply that a take is excluded from cloud backup.

#### Frame 4 — Five-minute Today session

- **Caption:** `Five minutes. One next step.`
- **Subline:** `Tune, focus, play, reflect.`
- **Visual (full launch):** the Today screen with a six-block timeline: tune and
  setup, technique, model, acquire, apply, reflect; one target; one measured
  minute count. This is the plan's session design, not the current screen.
- **Visual (current build):** the actual Today card on Learn: the next lesson, the
  weekly minutes goal, and the due/fragile chips. Use the current-build caption
  `Your next step, ready when you are.` and do not show the five-minute timeline.
- **Proof point:** one clear next action, real measured minutes, and real due and
  fragile counts. The full five-minute block sequence is a plan target, not a
  shipped feature.
- **Status:** **Partially shippable.** The Today card is shippable today. The
  guided five-minute session is not built; the session model exists in
  `core/learning` and `content`, but no main-navigation screen runs it. Use the
  current-build frame only, or hold the full frame until the Today loop ships and
  the Phase 1 evidence exists.
- **Designer note:** do not draw a timer, a checkmark for each block, or a
  "5 min" badge on the current card. That would present the plan as the product.

#### Frame 5 — Technique checklist

- **Caption:** `A 60-second technique check.`
- **Subline:** `Posture, hands, one focused drill.`
- **Visual:** the technique screen with the stage picker, the pain warning above
  the fold, three checklist items, three self-rating rows, the 60-second timer,
  and the written demo cues. Do not show a video player.
- **Proof point:** a real self-check, not automated hand assessment. The copy says
  the mic cannot see hands and the checklist is not a substitute for a teacher.
  Ticks and ratings are session-only.
- **Status:** **Shippable today.** The screen is reachable from Practice →
  Technique check. The demo video is pending; the screen says "Demo video
  pending". Crop to the checklist, timer, and written cues, or leave the pending
  copy visible.
- **Designer note:** keep the pain, numbness, and tingling warning visible. Do not
  imply medical advice or automated posture detection.

#### Frame 6 — Privacy and local-only

- **Caption:** `No account. No cloud. No ads.`
- **Subline:** `Your practice stays on your device.`
- **Visual:** the Profile Privacy heading, the beta usage log card with the switch
  off, and the clipboard backup row. Crop out the `MediaPrivacyCard` recording
  sentence. Use the real state from the test profile; do not invent a "0 KB
  uploaded" counter.
- **Proof point:** progress is stored in `shared_preferences`; there is no account,
  no cloud, no ads, and no third-party tracker. The microphone is active only
  during a lesson, practice, or tuner session. The optional usage log is local,
  bounded, and eraseable.
- **Status:** **Shippable today only with that crop.** `mediaPrivacyNote` always
  adds a "When you record a take…" sentence, and the recording UI is not built, so
  a full-card capture would claim an unshipped flow. Do not show the media card
  until T4.2 and the backup-exclusion copy exist.
- **Designer note:** do not add a shield, lock, or "encrypted" badge that the app
  does not support. The plain copy is the proof.

#### Frame 7 — Progress, not a personality score

- **Caption:** `Real progress, not a streak.`
- **Subline:** `See the notes you can read and what needs work.`
- **Visual:** two or three real stats, for example completed lessons, weekly
  measured minutes, accuracy, and per-note box progress. The Practice mini-stats
  (`Mastered`, `Learned`, `Accuracy`) also work.
- **Proof point:** every number comes from `ProgressState` or a real session.
  Mastery requires spaced correct answers, not a lucky tap. The weekly goal is
  measured guitar time.
- **Status:** **Partially shippable.** The progress stats are shippable today. The
  "can play this piece" repertoire evidence is not built; there is no piece
  certificate, can-play badge, or recording proof. Use "see what you can read",
  not "you can play".
- **Designer note:** show the real numbers, not a wall of vanity metrics. Do not
  add a fake streak, a league, or a comparison to other learners.

### 3.4 Order and launch sets

**Full launch order, after every gate ships:** 1 notation → 2 phrase → 3
before/after → 4 Today → 5 technique → 6 privacy → 7 progress.

**Current-build order, five frames (two partial):** 1 notation → 4 Today card
(retitled) → 5 technique → 6 privacy → 7 progress. Both stores allow five frames.
Do not pad the list with a gated frame.

**Minimum set if a store limits the count:** notation, privacy, progress. The
notation frame must do the discovery work in any set; the name alone does not.

### 3.5 Status and gate table

| Frame | Current implementation evidence | Gate to publish |
|---|---|---|
| 1 Notation | Lesson screen with staff, answer choices, mic meter, feedback | None |
| 2 Real phrase | Phrase player and verifier exist behind `phraseLoopEnabled = false`; no navigation entry; T1.7 not passed | T1.7 pass, loop enabled, navigation entry, real capture |
| 3 Before/after | Local media store only; no recording UI or comparison | T4.2 recording UI, comparison surface, device backup copy |
| 4 Today session | Today card exists; five-minute session model exists in core/content but no UI | Today loop screen and Phase 1 evidence for the full frame |
| 5 Technique | Technique screen reachable from Practice; video pending | None for the checklist; video asset for a video frame |
| 6 Privacy | Profile privacy card and beta log off by default; crop out the media recording sentence | None; confirm store labels and legal copy |
| 7 Progress | Profile and Practice stats from `ProgressState` | None for progress; can-play evidence later |

---

## 4. Screenshot test plan

**Status: Not run.**
**Date:** —.
**Participants:** 0 of 10.
**Owner:** Human growth owner.
**Version tested:** —.

This is a human test of the **shippable** screenshot set. Do not show a gated
frame as if it is in the app. If the team also wants concept feedback on future
frames, run a separate test that tells participants they are looking at design
mockups; do not count that test as the store screenshot test.

### 4.1 Participants

Recruit 10 adults who match the beachhead:

- **5 beginners:** adults 25–55 who have played guitar for less than 12 months, or
  cannot comfortably read a treble staff.
- **5 returners:** adults 25–55 who played for 1–5 years, stopped, and want to
  return; they may read a little.

Exclude employees, contractors, and existing beta power users. Recruit from
classical/folk guitar communities, teacher networks, and adult beginner groups.
Ask for consent to take notes or record audio. Store only an anonymized
participant id and the segment; do not put names, emails, or raw recordings in
Plane. A small incentive is optional; record it if paid.

Ten people is a directional sample. Report counts, not a population estimate, and
do not call the result a benchmark.

### 4.2 Materials

- The current-build set of five frames (two partial) in the intended order, at
  phone size, with the captions a shopper would see.
- A card with the title, subtitle, and short description.
- A notes sheet with the fields in 4.5.
- No app access and no unshipped frame.

### 4.3 Script

Read this without adding the target words before the unaided questions. Do not
say "sight-reading", "notation", "adult", or "local-only" first; those are the
comprehension checks.

1. "Thanks for helping. We are testing store screenshots, not you. There are no
   wrong answers, and you can stop at any time. May I take notes and record
   audio?"
2. "Here are five screenshots from an app store listing. Please look at them for
   about 20 seconds before I ask anything."
3. "What do you think this app does?"
4. "Who do you think it is for?"
5. "What would you expect to do in the first five minutes?"
6. "Which screenshot would make you most likely to install? Which one is least
   clear? Why?"
7. "What, if anything, looks confusing or hard to believe?"
8. "Here is the title, subtitle, and short description. What would you type into
   the store search to find this?"
9. "Would you install it? Use a 1–5 scale, where 1 is definitely not and 5 is
   definitely yes. Why?"
10. "Is there anything else you would change?"

### 4.4 Pass/fail rules

These are pre-registered product criteria, not industry benchmarks. A single
failed trust check fails the set even if the averages look good.

| Check | Pass | Fail |
|---|---|---|
| Unaided comprehension | At least 8 of 10 mention guitar and at least one of reading, notation, staff, or notes | 7 or fewer |
| Audience | At least 7 of 10 describe adults, returners, or beginners; 0 describe children | Any child-directed read |
| Next action | At least 7 of 10 describe reading a note, playing it, or practicing | 6 or fewer |
| Trust | At least 8 of 10 say nothing looks fake or misleading; 0 believe microphone accuracy is guaranteed | Any participant believes an unshipped feature is live; any accuracy guarantee |
| Install intent | At least 6 of 10 rate 4 or 5 | 5 or fewer |
| Standout | At least 6 of 10 name notation or the Today card among the top two most useful frames | No frame stands out |

Overall: pass only if every row passes. If a row fails, revise the failing
frames or captions and rerun with 10 new participants. Keep the first result;
do not average it away. Do not reuse the same participants for the retest.

### 4.5 Recording the result

Use a restricted sheet, linked from T8.2. One row per participant:

| Field | Value |
|---|---|
| Participant id | P01–P10 (no names) |
| Date | YYYY-MM-DD |
| Segment | Beginner / returner |
| Unaided description | Verbatim or close paraphrase |
| Audience read | Adult / returner / beginner / child / unclear |
| Next action | Verbatim |
| Top frame | Frame number |
| Least clear frame | Frame number |
| Trust flags | Any fake/unshipped/accuracy read |
| Install intent | 1–5 |
| Quotes | Short, anonymized |
| Set version | Date or hash of the screenshot set |
| Pass/fail | Per 4.4 |

**Result block**

- Status: **Not run**
- Participants: 0/10
- Pass/fail: —
- Changes made: —
- Retest: —

---

## 5. Launch sequencing

### 5.1 Hard rule

**Do not buy installs before organic or teacher traction.** Paid installs cannot
satisfy a phase gate, cannot substitute for retention, and must never be mixed
into an organic cohort. The plan's initial position is no paid UA; the math is
unfavorable at the plan's assumed CPI and conversion, and a paid test is a
separate, capped experiment.

### 5.2 Stages

| Stage | When | Work | Paid installs? | Exit or gate |
|---|---|---|---|---|
| 0 — Pre-launch organic base | Now | Finish this plan; pass the screenshot test on the shippable set; start T8.1 free web test and T8.3 free lessons/tools; draft T8.5 community plan and prepare the T8.4 video cadence; run the legal/store policy check | No | Screenshot test pass; claims audit complete; web funnel and content base live |
| 1 — Organic soft launch | After the Phase 1 gate | Current-build listing; execute the T8.5 community launch; run the T8.4 short-form video engine | No | Four weeks of organic data; keyword rank and page conversion recorded |
| 2 — Teacher traction | Phase 2 | T8.5 teacher outreach; three paid teacher pilots; COPPA/legal clearance; manual export | No | Phase 2 gate: D30 ≥10%, free→Pro ≥2%, three paid teacher pilots |
| 3 — Consider paid acquisition | Only after the trigger in 5.3 | One capped test on one channel with one creative set | Yes, capped | The pre-registered CPI/CAC and quality thresholds pass; otherwise stop |

The Phase 1 gate is not a store milestone. It is the plan's evidence gate: 20
users, at least 30% of actives at three or more sessions per week for four weeks,
false fail at or below 10%, and D7 at or above 18%. Do not start paid acquisition
because a listing is live.

### 5.3 Paid acquisition trigger

All of these must be true before the first paid dollar:

1. The Phase 2 gate passes: D30 at or above 10%, free-to-Pro at or above 2%, and
   three paid teacher pilots.
2. The T9.9 scale review records no active section 12.4 kill criterion,
   including session-2 return below 35%, recording by day 7 below 25%, or content
   cadence below one new piece per month.
3. Four consecutive weeks of organic installs have a recorded denominator,
   product-page conversion, and keyword rank, with no unexplained decline.
4. A paid test is pre-registered: a separate $500 paid-test cap, one channel,
   one creative set, a maximum CPI/CAC, a minimum D7 or trial-to-paid quality
   bar, and a stop rule if the cap is hit or the paid cohort is worse than
   organic.
5. Legal and privacy review covers the ad creative, the landing page, and the
   install source tracking.

If any condition is missing, there is no paid spend. If the test fails, stop. Do
not "buy through" a gate and do not count paid installs toward an organic target.

### 5.4 How the related tickets fit

| Ticket | Role | Gate or dependency |
|---|---|---|
| T8.4 — short-form video engine | Organic awareness: 2 videos per week for 8 weeks, using only shippable screens and real captures | No before/after or phrase claim until those frames ship |
| T8.5 — community launch plan | Organic/teacher demand: r/classicalguitar, Delcamp, societies, teacher newsletters; participate, do not spam | Teacher copy waits for the Phase 2 path and COPPA/legal clearance |
| T9.9 — scale gate review | The guardrail for D30, free-to-Pro, and content cadence | Paid acquisition waits for its recorded review |
| T8.1 — free web sight-reading test | Top of funnel and email capture | It is not a substitute for the store listing test and does not prove store conversion |

### 5.5 Stop rules

- Stop paid spend if CPI/CAC exceeds the pre-registered cap.
- Stop if the paid cohort's D7 or free-to-Pro is below the organic cohort's.
- Stop if a section 12.4 kill criterion fires.
- Stop if the creative shows a frame that is not shippable.
- Re-run the T9.9 review before restarting. Keep paid and organic reports
  separate.

---

## 6. Claims and compliance

### 6.1 Claims matrix

| Claim | Evidence today | Listing status | Allowed wording |
|---|---|---|---|
| Local-only progress, no account, no cloud, no ads | Source, README, Profile privacy card | Allowed | "No account. No cloud. No ads. Progress stays on your device." |
| On-device microphone pitch feedback | Lesson and tuner code and tests | Allowed with a hedge | "on-device pitch feedback"; never "validated accuracy" or "guaranteed" |
| 240 lessons across 40 units | Curriculum and tests | Allowed | The exact number |
| Spaced review and mastery across days | Scheduler and progress tests | Allowed | "spaced review"; "mastery needs correct answers across days" |
| Standard-tuning tuner | Practice screen and tests | Allowed | "standard-tuning tuner" |
| 60-second technique self-check | Technique screen and content | Allowed | "60-second technique check"; not "hand assessment" |
| 5-minute Today session | Not built | **Hold** | Do not use until the Today loop ships |
| Real pieces or phrase practice | Gated; `phraseLoopEnabled = false` | **Hold** | "Beta phrase practice" only after the gate and a visible Beta label |
| Before/after recordings | Not built | **Hold** | Do not use until T4.2 and a comparison surface ship |
| Technique video | Asset pending | **Hold** | "written cues" or no video |
| Teacher or classroom features | Gated; COPPA plan | **Prohibited** | Do not use |
| Unlimited generated etudes | Not built or validated | **Prohibited** | Do not use |
| AI teacher or AI feedback | Not built | **Prohibited** | Do not use |
| Exam prep or affiliation | No license | **Prohibited** | No board names, no "exam ready" |
| "Proven", "#1", "best", testimonials, install counts | No dated evidence | **Prohibited** | Remove |

### 6.2 App Store checks

| Area | Check | Current action |
|---|---|---|
| Guideline 2.3 — accurate metadata | The listing matches the app; no hidden or unshipped feature is presented as live | Use the current-build copy and the shippable screenshot set only |
| Guideline 2.3.7 — accurate screenshots | Screenshots show the actual app, not a mockup of a future feature | Storyboard only; capture after the gate |
| Guideline 3.1.1 — in-app purchase | If a subscription or Pro unlock ships, it uses Apple IAP | No paid digital content today; revisit at the paywall |
| Guideline 5.1.1 — privacy policy and data collection | A privacy policy URL is live; the microphone purpose string is accurate; data is minimized | Final policy and URL are a launch prerequisite |
| Guideline 5.1.2 — data use and sharing | No tracking or third-party analytics; confirm the final SDK list | Audit dependencies before ticking "Data Not Collected" |
| Guideline 1.3 — kids | The listing is not child-directed; no child or classroom imagery | Use adult copy; no "kids", "family", or "classroom" |
| Age rating | Answer the content questions truthfully; music content only | Review at submission |
| Guideline 2.3.1 — hidden features | No gated feature in screenshots or copy | Enforced by section 3 |

### 6.3 Google Play checks

| Area | Check | Current action |
|---|---|---|
| Metadata policy | No misleading claims, no keyword stuffing, no irrelevant terms; title, short description, and long description agree | Use natural sentences; do not paste the Apple keyword list |
| Deceptive behavior | No fake functionality; screenshots match the app | Shippable frames only; no before/after or phrase mockup |
| Store listing and promotion | Screenshots and videos are accurate; no "best" or "#1" without evidence | No ranking claim; no testimonial |
| Data safety | Declare collection and sharing truthfully; microphone permission is explained | Expect "no data collected" after the SDK audit; confirm before submission |
| Families policy | The app is not child-directed and does not opt into Families | No teacher/student roster, no classroom copy |
| Permissions | Microphone is declared and used only for practice | Keep `RECORD_AUDIO` and `NSMicrophoneUsageDescription` copy accurate |
| Subscriptions | If added, use Google Play Billing with clear terms | Not in the current build |

### 6.4 Privacy labels

| Data type | App Store nutrition label (expected) | Google Play Data safety (expected) | Basis |
|---|---|---|---|
| Progress and settings | Not collected; stored on the device | Not collected | `shared_preferences`; no network persistence |
| Microphone audio | Not collected; processed on the device and not retained or uploaded | Not collected | Mic active only during a lesson, practice, tuner, or recording session |
| Beta usage log | Not collected; local, opt-in, never uploaded | Not collected | See [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md); off by default |
| Diagnostics and crash data | Not collected; no crash SDK | Not collected | Verify the final dependency list |
| Recordings (future) | Not collected by the developer; user-initiated export only | Not collected; user-initiated share only | When T4.2 ships, confirm the local media rules and the backup copy |

These are expectations, not a completed audit. Confirm the final SDK list, the
OS-level collection, and the policy wording with counsel before ticking "Data Not
Collected." If any dependency collects diagnostics, declare it. A local-only
claim is not a substitute for the privacy label.

### 6.5 Prohibited names and claims

Do not use any of these in the listing, screenshots, previews, ads, website, or
review replies:

- Exam-board names: ABRSM, Trinity College London, RCM/Royal Conservatory,
  Rockschool, AMEB, LCM, MTB, UNISA, NZMEB.
- Method or edition names: Suzuki, Mel Bay, Hal Leonard, Berklee, Aaron Shearer,
  Frederick Noad, Pumping Nylon, named Carcassi or Sor editions.
- Unbuilt claims: "unlimited generated etudes", "AI teacher", "AI feedback",
  "5-minute session" (now), "before/after" (now), "real pieces" (now), "technique
  videos" (now), "teacher dashboard", "student accounts".
- Unprovable claims: "validated microphone accuracy", "scientifically proven",
  "guaranteed", "learn guitar in 30 days", "confident guitarist in 6 months",
  "70% weekly assignment use", "#1", "best", "thousands of students",
  "teacher-approved", "5-star".
- Child-directed or out-of-scope copy: "kids", "children", "family", "classroom",
  "beginner songs", "easy songs", "tabs", "chords", "strumming", "pop songs".
- Competitor names and marks, including Duolingo, Yousician, Fender Play, Simply
  Guitar, Justin Guitar, GuitarTuna, Ultimate Guitar, SmartMusic, and Tonara.

### 6.6 Child-directed and teacher/COPPA caveat

The consumer app is for adults. Do not use child-directed copy, do not show
minors, and do not answer the store audience questions as a kids' app. The age
rating is a content label, not a marketing audience; a low rating does not make
the listing child-directed.

The teacher channel is Phase 2 and is gated by
[`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) and its legal
review. Until that gate clears:

- No teacher or student accounts, rosters, uploads, public recitals, or classroom
  features in the listing.
- No "teacher-approved", "used in schools", or "for your students" copy.
- Teacher referrals, if mentioned at all, are for adult students only.
- Do not use a child's image, a school logo, or a testimonial from a minor.

### 6.7 Pre-submission checklist

- [ ] The copy matches the current build; no gated feature is presented as live.
- [ ] The screenshot test passed on the shippable set; the result is recorded.
- [ ] Every screenshot was captured from a real build with real session data.
- [ ] The privacy policy URL is live; the data labels are audited.
- [ ] The microphone purpose strings are accurate on both platforms.
- [ ] No exam-board, method, or competitor names appear anywhere.
- [ ] No testimonial, rating, install count, or accuracy percentage appears
      without dated evidence.
- [ ] The age rating and audience answers are reviewed.
- [ ] The subtitle character count is checked; the fallback is recorded.
- [ ] The listing preview is checked on a phone and a tablet; en-GB/en-CA
      spelling is checked.
- [ ] The legal review (T6.3) and the store policy check are recorded.

---

## 7. Metrics

### 7.1 Metric definitions

| Metric | Definition | Source | Cadence | Baseline | Use |
|---|---|---|---|---|---|
| Store impressions / listing visitors | Impressions where the console reports them; otherwise store listing visitors | App Store Connect, Google Play Console | Weekly | None yet | Denominator or context |
| Product-page views | Views or visitors of the store product page | Same | Weekly | None yet | Funnel step |
| Store page conversion | Installs divided by product-page views/visitors; also report views/visitors divided by impressions where available | Same | Weekly | None yet | Compare copy and screenshot sets |
| Keyword rank | Position for the fixed keyword set in each locale, logged out | Manual store search or a disclosed rank tracker | Weekly | None yet | Judge a subtitle or keyword change |
| Installs by source | Organic, paid, web, referral, unknown | Store acquisition reports, campaign links, UTM, referral codes | Weekly | None yet | Channel decisions; keep paid separate |
| Screenshot test | Pass/fail per section 4 | The 10-user test | Per set | **Not run** | Ship or revise |
| D7 and D30 retention | Cohort retention by install week | T9.9 | Monthly | None yet | Guardrail; not an ASO claim |
| Free-to-Pro | Paid conversion after the paywall ships | T9.9 | Monthly | None yet | Guardrail; not an ASO claim |
| Teacher traction | Paid teacher pilots and signed LOIs | T8.5, T9.9 | Monthly | None yet | Paid-acquisition trigger |
| Content cadence | New pieces per month | T9.9 | Monthly | None yet | Kill criterion |

Apple and Google use different funnel labels. Record the console's own label and
the export date so the series is reproducible; do not map one store's label onto
another without saying so.

### 7.2 Reporting rules

- Use real data only. Do not invent a benchmark, an industry average, or a
  "typical" conversion rate.
- Report the numerator, denominator, window, locale, source, and date. A
  percentage without a denominator is not a measurement.
- Treat the 10-user test as directional. Report counts; do not present it as a
  population estimate or a confidence interval.
- Rank is not installs. Store conversion is not retention. A paid install is not
  an organic install.
- Attribute installs only with campaign links, referral codes, or store source
  data. Call the residual "unknown" instead of guessing.
- Apple and Google privacy rules can hide source data. Say "unknown" rather than
  inventing an attribution.
- Do not publish a metric in the listing unless it is verified, dated, and allowed
  by section 6. No such metric exists today.

### 7.3 Dashboard fields

One row per week and locale:

`date, locale, channel, impressions, product_page_views, installs, installs_by_source, page_conversion, keyword_ranks, d7, d30, free_to_pro, teacher_traction, notes`

Keep the raw export or a link to it next to the summary. A dashboard without a
raw source is a claim, not evidence.

### 7.4 Current status

- Store listing: not submitted.
- Keyword rank: not measured.
- Store page conversion: not measured.
- Installs by source: not measured.
- Screenshot test: **Not run**.
- No baseline exists. Do not fill these cells with a plan target.

---

## 8. Open decisions and dependencies

| Item | Owner | Blocks | Status |
|---|---|---|---|
| Subtitle: canonical 31-character line vs 29-character store variant | Growth/design | App Store submission | Fallback documented; decide at submission |
| T1.7 phrase gate and phrase-loop navigation | Human evidence owner/engineering | Frame 2 | Open; loop disabled |
| T4.2 recording UI and comparison | Engineering | Frame 3 | Not built |
| Today loop and five-minute session | Engineering | Full frame 4 | Not built |
| Technique video assets | Content | Video version of frame 5 | Pending; written cues ship |
| Store policy and privacy-label audit | Legal/engineering | Submission | Open (A-021) |
| 10-user screenshot test | Human growth owner | Listing | **Not run** |
| Paywall and launch price | T6.x | Price copy and promotional text | Not shipped |
| Teacher/COPPA clearance | Legal | Teacher copy and referrals | Open |

---

## 9. Related documents

- [`README.md`](../README.md) — current product tour and limitations.
- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) — approved plan,
  especially sections 2, 6, 11.4, 11.5, 12, and 13.
- [`DESIGN.md`](DESIGN.md) — screen intent, copy tone, visual language.
- [`PHASE_GATES.md`](PHASE_GATES.md) — the gate evidence a launch must not
  shortcut.
- [`ASSUMPTION_TRACKER.md`](ASSUMPTION_TRACKER.md) — demand assumptions and the
  rule that a document is not evidence.
- [`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) — the
  teacher-channel gate.
- [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) — the local,
  opt-in usage log referenced in the privacy copy.
