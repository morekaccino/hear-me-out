# Design Language & Product Direction

This is the source of truth for product intent, visual language, copy, and
gamification. Use it with [`../AGENTS.md`](../AGENTS.md) and the design tokens in
[`../flutter_app/lib/shared/theme/app_theme.dart`](../flutter_app/lib/shared/theme/app_theme.dart).

## Mission

**Help a beginner read standard notation on guitar through short, forgiving
practice with honest pitch feedback.**

The tagline is **“Read music. Play guitar.”** The promise is narrow on purpose:
a learner should be able to open the app for a few minutes, see a note, answer
it, and understand exactly what happened.

### Who it is for

- Beginner and early-intermediate guitarists who can play a little but cannot
  comfortably read a treble staff.
- People practicing alone at home, often on a phone, sometimes with no
  microphone or no quiet room.
- Learners who want a calm daily habit, not a social competition.

### Product principles

1. **Practice over performance.** Short sessions, one clear task at a time,
   immediate feedback. No seven-step setup before the first note.
2. **Honest progress.** XP and streaks are real. Mastery means spaced correct
   answers, not three lucky taps. Never invent a statistic to make the screen
   look fuller.
3. **Guitar-correct by default.** The staff shows written pitch; the mic listens
   for sounding pitch one octave lower. String and fret hints use the same
   mapping.
4. **Never punish a missing microphone.** Naming is a first-class answer mode.
   The app must remain usable when permission is denied.
5. **Privacy is a feature.** No account, no cloud, no analytics, no ads. Audio
   is analyzed in memory and discarded.
6. **Encouraging, not childish.** The tone is warm and direct. A mistake is
   information, not a moral failure.

## Brand personality

- **Friendly coach:** clear, patient, specific.
- **Playful but not silly:** the mascot and confetti are seasoning, not the meal.
- **Musically credible:** correct notation, correct octaves, correct guitar
  fingerings. Never trade musical accuracy for a nicer animation.
- **Calm confidence:** the app has a plan; the learner does not need to manage
  settings to get value.

Do **not** copy Duolingo’s owl, mascot art, exact layouts, or trademarks. The
reference is the interaction style: bold shapes, friendly feedback, visible
progress, and a low-friction lesson loop.

## Visual language

### Overall feel

A bright, rounded, high-contrast learning surface with thick outlines and
“pressable” controls. It should feel like a friendly instrument practice card,
not a dashboard or a music-production tool.

The app uses Material 3 primitives as a shell, but the visible controls are
custom Duolingo-style components. Do not fall back to stock Material cards,
filled buttons, ripples, or default elevation when a shared component fits.

### Palette

Use `AppColors`; do not add one-off hex values in widgets.

| Token | Hex | Use |
|---|---|---|
| `green` | `#58CC02` | Primary action, success, current lesson |
| `greenDark` | `#58A700` | Pressed/shadow side, success text |
| `greenSoft` | `#D7FFB8` | Success background, selected nav pill |
| `blue` | `#1CB0F6` | Secondary action, info, practice, Accidentals |
| `blueDark` | `#1899D6` | Secondary pressed/text |
| `blueSoft` | `#DDF4FF` | Info panels, mic idle surface |
| `red` | `#FF4B4B` | Error, wrong answer, hearts |
| `redDark` | `#EA2B2B` | Error text, pressed red |
| `redSoft` | `#FFDFE0` | Error/feedback background |
| `yellow` | `#FFC800` | Achievement, XP, completed lesson |
| `yellowDark` | `#E5A400` | Achievement text/shadow |
| `purple` | `#CE82FF` | First Position section, free practice accent |
| `purpleDark` | `#A560E8` | Purple pressed/text |
| `orange` | `#FF9600` | Streak flame and streak reward |
| `purpleSoft` | `#F7E6FF` | Purple section background |
| `background` | `#FFFFFF` | App background |
| `surface` | `#F7F7F7` | Cards, neutral fills |
| `border` | `#E5E5E5` | Standard 1.5–2 px outline |
| `borderStrong` | `#D0D0D0` | Stronger control outline |
| `text` | `#3C3C3C` | Primary text |
| `textMuted` | `#777777` | Supporting text |
| `textLight` | `#AFAFAF` | Disabled/tertiary text |
| `ink` | `#1F1F1F` | High-contrast text, snackbar, mascot features |

Color is meaningful: green means success/primary and the Foundations section,
purple means First Position or free practice, blue means information, a
secondary action, or Accidentals, red means error or lost life, and yellow means
reward/progress. Section color is carried by the section divider and current
unit banner.

### Typography

- **Nunito** throughout. The Bravura font is only for music glyphs.
- Headings use weight `w800`; supporting text `w600`/`w700`.
- No thin or light weights. The UI should feel sturdy and legible.
- Typical sizes: display 40, page heading 30, section heading 24/20,
  body 16/14, labels 11–15, staff labels 9–10, answer options 22.
- Small labels are uppercase with letter spacing around `0.8–1.2`.
- Keep copy short. Prefer one sentence over a paragraph.

### Shape, borders, and depth

- Rounded corners are a core part of the brand: cards `18–22`, controls `16`,
  chips `10–12`, feedback panel top `26`.
- Use visible outlines (`1.5–2 px`) rather than relying only on fills.
- The signature “Duolingo” depth is a **hard offset shadow**: blur `0`, offset
  `3–5 px`, usually using a darker version of the fill. Avoid soft Material
  elevation and heavy blur.
- Primary buttons use a thicker bottom edge (`4 px`; `2 px` when pressed) and
  physically move down `3 px` on press.
- No splash ripple: `NoSplash.splashFactory`, transparent highlight. Motion is
  managed by the custom controls.

### Spacing and layout

- Phone-first, centered, responsive content width: **600 px** for the path and
  lessons, **720 px** for hubs (`PageFrame`).
- At **900 px and wider**, replace the five bottom tabs with a 252 px left side
  rail. The content stays centered beside it.
- Use `SafeArea`; keep the bottom navigation clear of the content.
- Prefer the existing spacing rhythm: `4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24,
  28, 32`.
- Cards use `EdgeInsets.all(18)` by default.
- One primary action per screen. Secondary actions are outline buttons or text
  buttons.
- The app should fit a 390×844 viewport without clipping. On tablets and
  desktop it widens into a centered reading column and uses the side rail.

### Components

Use the shared widgets before creating new ones.

- **`DuoButton`** — primary action. Default height 56, radius 16, uppercase
  label, 16 px text, bottom edge depth, pressed translate. Compact instances
  (feedback/tuner) use 48–54 px.
- **`OutlineDuoButton`** — secondary action. Height 52, radius 16, 2 px outline.
- **`SectionCard`** — neutral content card. Radius 20, 2 px border, 18 px
  padding.
- **`AnswerOption`** — answer choice. Height 64, radius 16, 2 px border, 22 px
  label, hard bottom shadow when idle; states are idle/correct/wrong/dimmed.
- **`FeedbackPanel`** — bottom feedback. Solid green/red background, top radius
  24, white circular icon, white title, optional translucent detail card, white
  continue button with colored text.
- **`LessonProgressBar`** — 16 px default height, rounded, 280 ms fill.
- **`HeartsRow`** — five 26 px hearts for lessons only; practice shows a
  `PRACTICE` label instead.
- **`StatPill` / pill counters** — compact icon+number pills for streak, gems,
  hearts, and XP. Use the orange flame, blue diamond, and red heart
  consistently; the learn column shows them without borders.
- **`Mascot`** — original green music-note character with `happy`, `cheer`, and
  `thinking` moods. Use at onboarding, empty/result states, and profile; do not
  crowd every card with it.
- **`PageFrame`** — responsive centered column (600 px default, 720 px hubs).
- **`StatPill`**, **`SectionCard`**, and the shared theme handles most stat/row
  layout.

### Motion

- Press feedback: about 70 ms.
- Answer option state change: about 120 ms.
- Card/button state changes: about 160 ms.
- Progress bar fill: about 280 ms.
- Onboarding page transition: about 320 ms ease-out.
- Current path node: an 800 ms bob, two gentle cycles when the path appears.
  Do not loop it forever; the route should feel alive, not restless.
- Guidebook bottom sheet: standard 320 ms transition.
- Confetti is reserved for a passed lesson/practice result. Do not use it for
  every correct answer.
- Respect the haptics setting: light impact for correct, medium for incorrect.

### Mascot and illustration

The mascot is a green note with a rounded body, white eyes, dark pupils, a stem,
and a flag. It is original to this project. Use it to make empty/result states
and the current path node feel human, but keep the interface usable without it.
The staff itself is the hero visual on lesson screens.

### Iconography

- Use Material rounded icons (`Icons.*_rounded`) consistently.
- Common status icons: flame for streak, bolt for XP, flag for daily goal,
  favorite/heart for hearts, diamond for gems, mic for play, music note for
  notation.
- Most icons are 20–28 px; navigation icons are 26 px.
- Icons reinforce text; they should not be the only way to understand a value
  or action.
- Do not use emoji in product UI. Emoji belong in repository docs, not the app.

### State design

- **Loading:** compact spinner on the splash/path, never a blank white screen
  with no explanation.
- **Startup error:** mascot in `thinking` mood, plain-language message, retry
  action.
- **Mic unavailable:** soft red panel, reason, and a visible “use note names”
  path. Never trap the learner on a play exercise.
- **Empty notes:** explain that notes appear after the first lesson; do not show
  an empty card with no next action.
- **No due/weak notes:** say so plainly and offer free practice.
- **Locked lesson:** neutral node, no fake progress, brief “finish the lesson
  before this one” snackbar.
- **Correct:** green feedback, check icon, concrete note/string/fret hint.
- **Incorrect:** red feedback, close icon, correct answer, and a recovery action.
- **Out of hearts:** clear lesson result, refill-and-retry action when gems
  allow, back-to-path action; practice must never reach this state.

### Musical content rules

- The staff always shows **written** pitch. The microphone target is the
  sounding pitch one octave lower.
- Answer labels include the octave (`E4`, not `E`).
- Use ♯/♭ glyphs in display text and keep the exercise’s spelling; never turn a
  B-flat exercise into A-sharp.
- String/fret hints use standard tuning and first-position-friendly choices.
- The treble clef, staff lines, ledger lines, accidentals, and note head must
  remain musically legible before decorative styling is added.
- Audio input is for pitch detection. Short original UI cues are separate from
  the tuner and respect the Sound effects setting.

## Sound

Sound is part of the design language, not an afterthought. The app uses an
original **Bright Pluck** family: a short plucked synth body, glass-bell
sparkle, dry UI blips, and soft low error cues. It should feel musical and
friendly, never arcade-loud or punitive.

- Correct/combo/complete/perfect share a C-major pluck and bell palette.
- Wrong/octave/failed use lower, softer plucked phrases; no harsh buzzers.
- UI taps are short, dry blips mixed lower than answer feedback.
- Never play a continuous tone while the tuner or lesson mic is listening.
- Respect **Profile → Sound effects**; it persists independently of haptics.
- Do not stack a tap, answer sound, and reward sound. Play one deliberate cue,
  then at most one reward layer on a result screen.

The full asset map, event map, generator, and audition tool are in
[`SOUND.md`](SOUND.md).

## Screen intent

### Path

The home screen. Show the next lesson clearly, the current section and unit,
streak, XP, and daily goal. The path is organized as sections and units, not a
flat list.

- **Section header:** a large colored card with the section number, title,
  one sentence of intent, section progress, and a compact **JUMP HERE?** test
  action for sections 2 and 3. Foundations is green, First Position purple,
  Accidentals blue.
- **Unit banner:** a compact rounded banner with `UNIT n`, the unit title,
  one-line focus, unit progress, and a guidebook icon. The current unit uses a
  light tint of the section color; completed units use yellow; future units stay
  neutral. New-note lists live in the guidebook, not in the banner.
- **Guidebook:** a bottom sheet listing the unit's notes with first-position
  string/fret hints. New notes are marked; the sheet is reference material, not
  a new lesson.
- **Path geometry:** one continuous section curve instead of a per-unit
  restart. Units pick up the same sine at the offset where the previous unit
  ended, so the path does not reset to center between units. Nodes are 84 px
  circles on a 116 px vertical rhythm, joined by cubic curves. A chest gets its
  own 120 px slot: nodes after it slide down, so the chest never overlaps its
  neighbors.
- **Backdrop:** soft translucent blobs and a faint dot grid in the section
  color sit behind the path so the route does not float on bare white.
- **Path header:** the learn column shows compact, end-aligned icon+number
  counters (c flame, blue diamond, red heart) with the wordmark in the side
  rail only, then a bordered daily-goal card, then the section banner.
- **Section banners:** large colored cards for the section; a unit banner in a
  light tint of the section color sits underneath, and an `UP NEXT` marker
  precedes the section after the player's current one.
- **Nodes:** completed yellow star, current green star with a green START pill
  above; locked nodes tint their lock toward the section color, checkpoints are
  trophy nodes with a yellow border. A 56 px mascot stands beside the current
  node, on the side away from the curve. Only current and completed lessons
  open. The current node bobs gently and settles; motion never blocks a tap.
- **Chests:** one 58 px chest per unit, occupying its own slot on the path. It
  is locked until the lesson before it is complete, then opens once for gems.
- **No labels under every node.** The unit banner and guidebook carry context;
  the nodes stay scannable.

The path should feel like a route, not a game board or a spreadsheet.

### Lesson

The focus screen. One staff card, one prompt, four choices or a live mic meter,
then a feedback panel. The learner should always know:

- what note is being asked,
- how to answer,
- whether they were right,
- and what to do next.

Show the correct string/fret on feedback. Keep the five hearts visible for
lessons; show `PRACTICE` instead for practice. A checkpoint is a 15-exercise
mixed review with trophy copy and the standard lesson flow.

If a note is missed, it returns once at the end under “Mistake review.” Keep the
base progress bar full during this phase; the learner should feel a short,
specific repair, not a second lesson.

### Practice

Low-pressure drilling. The tuner is a utility; smart practice is the main event.
Due, weak, and free practice are separate intents. Never imply a practice
session is a test. Practice does not consume hearts and restores one on
completion.

### Profile

A transparent record of real work: notes with box progress, accuracy, completed
lessons, streak, XP, settings, backup/restore, reset. No vanity metrics. Privacy
copy is part of the design, not a footer afterthought.

### Onboarding

Four short pages: welcome, name/play explanation, optional mic check, daily
goal. The mic check must be skippable and must explain the fallback. The user
should reach the path in under a minute.

## Gamification rules

- **Streak:** a daily habit signal, not a punishment. It increments on the first
  completed lesson of a local day. Practice does not advance it.
- **XP:** 10 normal lesson, 15 review, +5 perfect; replay 5, +3 perfect replay;
  practice 5; jump test 20. Double XP doubles the award. Show real earned
  amounts.
- **Hearts:** five shared hearts. A wrong lesson answer costs one; zero ends the
  lesson. One heart regenerates every four hours, practice restores one, and a
  350-gem refill fills all five. Practice never costs hearts.
- **Gems:** earned from chests and claimed daily quests. Spent only in the
  local shop on heart refills, streak freezes, and double XP.
- **Chests:** one per unit, unlocked by the lesson before it, opened once.
- **Daily quests:** complete a lesson, answer ten notes, and build a five-answer
  combo. Each pays gems once per local day.
- **Streak freeze:** up to two equipped; one protects a missed day.
- **Daily goal:** 10/20/30 XP, tracked per local day.
- **Combo:** positive feedback only; do not add a combo loss mechanic.
- **Level:** `xp ~/ 100 + 1`; do not invent a separate progression currency.
- **Jump ahead:** a 15-exercise test can unlock earlier sections without
  deleting note progress.
- **No leaderboards, leagues, friend duels, ads, subscriptions, real-money
  purchases, or social pressure.** Those are explicit non-goals. The shop is a
  closed gem economy, not a storefront.

## Copy and tone

- Encourage without hype: “Correct!”, “Not quite”, “Try again”, “Nice work today.”
- Be specific: “E4 · D string, fret 2” is better than “Great job!”
- Explain errors without blame: “Right note, wrong octave” and “Check which
  string and octave you are using.”
- Never shame the learner or call an answer “bad.”
- Use sentence case for prose, uppercase for button labels and small badges.
- Use the musical spelling the exercise uses. B-flat stays B-flat; F-sharp stays
  F-sharp.

## Accessibility and inclusion

- Staff views and custom buttons expose `Semantics` labels.
- Maintain strong contrast and large touch targets (buttons 52–64 px tall).
- Feedback panels use icons and text; answer-option colors are reinforced by
  the feedback message and the correct-note hint.
- Keep the app usable with a keyboard on web where practical.
- Respect the haptics setting.
- The current app is light-theme only and English-only. Do not promise dark
  mode or localization in copy until they are implemented.
- Known gaps to address before a wider release: keyboard focus for custom
  gesture controls, reduced-motion support, dark theme, localization, and
  screen-reader testing on the staff card.

## Non-goals

- Social feeds, leagues, friend duels, leaderboards, or public profiles.
- Accounts, cloud sync, analytics, ads, subscriptions, or paywalls.
- Recording or uploading audio.
- Fake lesson progress or decorative stats.
- Copying Duolingo’s proprietary art, mascot, or exact screen layouts.
- Becoming a general-purpose DAW, tab editor, or full music-theory course.

## Changing the design

1. Reuse `AppColors`, `AppTheme`, and the shared widgets.
2. If a new token or component is necessary, update `app_theme.dart` and this
   document together.
3. Check phone (390×844), tablet, and desktop-web widths.
4. Verify feedback states, empty states, disabled states, and mic-failure states.
5. Add or update widget tests for lesson-flow changes.
6. Run `flutter analyze`, `flutter test`, and `flutter build web --release`.

See [`../README.md`](../README.md) for the product tour and
[`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md) for the learning rules.
