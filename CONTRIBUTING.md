# Contributing

Hear Me Out is a Flutter app. The product code lives in `flutter_app/`.
Requires Flutter 3.47+ and Dart 3.13+.

## Setup

```bash
cd flutter_app
flutter pub get
flutter run
```

Run the checks before opening a pull request:

```bash
flutter analyze
flutter test
flutter build web --release
```

## Documentation for contributors and agents

- [`AGENTS.md`](AGENTS.md) — project rules, commands, architecture map, and
  current verification state
- [`docs/DESIGN.md`](docs/DESIGN.md) — mission, Duolingo-style design language,
  copy, and gamification
- [`docs/SOUND.md`](docs/SOUND.md) — Warm Mallet family, assets, event map,
  and sound settings
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — layers, data flow, and
  invariants
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — setup, debugging, test helpers,
  and manual device checks
- [`LEARNING_ALGORITHM.md`](LEARNING_ALGORITHM.md) — scheduling and session rules

Read `AGENTS.md` before making changes. Update it when a rule, command, storage
format, or verification step changes.

## Rules of the codebase

- Keep music math, scheduling, pitch detection, and notation geometry in
  `lib/core/` and free of widgets. They must be testable as pure Dart.
- Add or update a test for every algorithm change. A UI-only change still needs
  a widget test if it affects the lesson flow.
- Never add placeholder stats, fake lesson progress, or dead buttons. Every
  number on screen must come from `ProgressState`.
- No cloud persistence, analytics, auth, or network calls. Progress belongs in
  `ProgressStore`; audio stays in memory.
- Keep guitar transposition in mind. Written pitch and sounding pitch are not
  the same note.
- Match the existing Duolingo-style design tokens in
  `lib/shared/theme/app_theme.dart` and the rules in
  [`docs/DESIGN.md`](docs/DESIGN.md). Reuse `DuoButton`, `SectionCard`,
  `AnswerOption`, and the other shared widgets before adding new styles.
- Keep the mission in view: short, forgiving practice with honest pitch
  feedback. Do not add social pressure, fake stats, or monetization surfaces.

## Pull requests

1. Fork and create a branch.
2. Make the smallest change that solves the problem.
3. Run `flutter analyze` and `flutter test`.
4. Describe what changed, how you verified it, and any device/mic testing.
5. Include screenshots for UI changes.

## Reporting issues

Include:

- Flutter version (`flutter --version`)
- Device or browser
- Steps to reproduce
- Expected vs actual behavior
- Console logs or screenshots if available

For audio issues, mention the instrument, the note played, and whether the
tuner detected it correctly.
