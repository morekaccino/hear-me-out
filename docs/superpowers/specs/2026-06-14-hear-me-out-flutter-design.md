# Hear Me Out — Flutter Mobile App Design Spec

**Date:** 2026-06-14
**Status:** Approved
**Source:** Conversion of web-based Vue 3 POC to Flutter mobile app

---

## 1. Context & Strategy

### 1.1 What We're Converting From

The existing web app is a Vue 3 + Vite + Firebase single-page music note trainer:
- Users see a musical note rendered on a staff (VexFlow)
- They play the note on their instrument into a microphone
- Real-time pitch detection (Pitchy.js + Web Audio API) checks accuracy
- Progressive learning algorithm introduces notes gradually via spaced repetition
- Firestore persistence under anonymous authentication
- 28 source files: 4 Vue components, 5 composables, 3 service classes, utilities

**Live URL:** https://hearmeout-1995.web.app

### 1.2 Strategic Pivot

We are NOT doing a 1:1 feature conversion. The web app was a proof of concept. For the mobile launch, we are pivoting from **"note flashcard trainer"** to **"music ear training & sight-reading platform"** — broader appeal, deeper content, and clear monetization path.

### 1.3 Design Goals

- **Engaging & sticky** — daily habit loops, gamification, social competition
- **Monetizable** — freemium model with Pro and Teacher tiers
- **Platform-native** — Material Design 3 on Android, Cupertino/HIG on iOS
- **Offline-first** — local storage with Firebase sync
- **Fluid & modern** — 2026 aesthetic: dark mode, vibrant accents, haptic-rich

---

## 2. App Structure

### 2.1 Navigation

5 bottom tabs using GoRouter with ShellRoute (each tab maintains its own navigation stack):

| Tab | Icon | Purpose |
|-----|------|---------|
| **Home** | 🏠 | Dashboard: streak, XP level, daily challenge, league position, quick-start |
| **Learn** | 📚 | Structured courses with levels, progress tracking, Pro-gated content |
| **Practice** | 🎼 | Core trainer: mode selector (Notes/Intervals/Chords/Rhythm), card, mic |
| **Social** | 👥 | Weekly league leaderboard, friend duels, community challenges |
| **Profile** | 👤 | Stats, achievements, settings, upgrade prompt |

- Home tab is the default on app open
- GoRouter deep links: `/home`, `/learn`, `/practice`, `/social`, `/profile`
- Platform-adaptive: `NavigationBar` (Android) / `CupertinoTabBar` (iOS)

### 2.2 Screen Details

#### Home
- Greeting + username
- Animated streak ring (conic gradient, fire animation on milestone)
- XP progress bar toward next level
- Daily Challenge card (time-limited, shows remaining time, current ranking)
- League position row (e.g., "#4 in Sapphire League")
- "Continue Learning" primary CTA (jumps to Learn or Practice based on last activity)
- Quick stats: mastered count, learning count, accuracy %

#### Learn
- Structured course list in progressive order:
  1. **Note Basics** (Free) — Identify single notes on the staff
  2. **Intervals I** (Free) — Major & minor 2nds, 3rds
  3. **Chord Recognition** (Pro) — Major, minor, diminished triads
  4. **Sight Reading I** (Pro) — Play melodies from notation
  5. Future: Intervals II, Rhythm I, Jazz Chords, etc.
- Each course shows: level label, title, description, progress bar with %
- Pro-gated courses show a "PRO" badge and are visually locked
- Tapping a locked course shows the upgrade paywall sheet

#### Practice (Core Trainer)
- Mode selector chips: Notes | Intervals | Chords | Rhythm
- Music card with staff notation (Flutter CustomPainter rendering)
- "Listen to reference" button (plays the note via a synth/audio)
- Live microphone status indicator (pulsing dot when listening)
- Pitch accuracy feedback bar (tuner-style: shows cents sharp/flat, not binary)
- Session stats during practice: correct count, incorrect count, current streak
- Auto-advance: play → detect → show result (1.5s) → next card
- Celebration animation on streak milestones (3, 5, 10)
- Haptic feedback: short buzz (correct), double-tap (streak), gentle nudge (incorrect)

#### Social
- Current league banner (name, icon, time remaining)
- Leaderboard showing top 5 + your position
- Gold/silver/bronze styling for top 3
- "Challenge a Friend" section — generate a link/code, race to identify 20 notes
- Friend list (future iteration)

#### Profile
- Avatar + name + level + league name
- Stat grid: notes mastered, accuracy %, day streak, total XP
- Achievement showcase (earned badges with unlock dates)
- Settings rows: instrument, range, haptics toggle, theme, share, reset
- "Upgrade to Pro" card (prominent, with gradient — only shown to free users)
- App version

---

## 3. Feature Changes from Web App

### 3.1 Removed

| Feature | Reason |
|---------|--------|
| Anonymous-only authentication | Replaced with email/Google/Apple sign-in; monetization requires real accounts |
| LeitnerSystemService (5-box SRS) | Unused dead code in the web app; ProgressiveLearningService is better |
| Manual swipe-left for wrong answers | Friction. Auto-advance after feedback. Wrong = show correct answer, move on |
| Single-note-only flashcard mode | Expanded to intervals, chords, rhythm modes |
| localStorage StorageAdapter | Replaced with offline-first SQLite/Hive |

### 3.2 Kept & Enhanced

| Feature | Enhancement |
|---------|-------------|
| ProgressiveLearningService | Extended to support multiple training modes (notes, intervals, chords) |
| Real-time pitch detection | Feedback now shows cents ± accuracy, not just correct/incorrect |
| VexFlow music notation | Replaced with Flutter-native CustomPainter (no WebView) |
| Firestore persistence | Augmented with local SQLite/Hive for offline-first operation |
| Card-based UI | Replaced with auto-advancing flashcard flow (no manual swipe required) |

### 3.3 New

| Feature | Purpose |
|---------|---------|
| Structured courses & levels | Content depth, progression, Pro paywall placement |
| Daily challenges | FOMO-driven daily retention; time-limited, leaderboard-ranked |
| Weekly leagues (Duolingo-style) | Competitive engagement; 30 users per league, top 7 promote |
| Pitch accuracy visualization | Tuner-style bar showing cents sharp/flat; gamifies precision |
| Friend duels | Head-to-head races to identify 20 notes; viral growth channel |
| Streaks & XP system | Gamification backbone; levels unlock cosmetic rewards |
| Achievement badges | Milestone rewards: "First Note", "Perfect Session", "50 Notes Mastered", etc. |
| Push notifications | Streak at risk, league ending, friend challenged you, new daily challenge |
| Haptic feedback patterns | Distinct vibrations for correct, streak, incorrect, level-up |
| Offline mode | Full functionality without internet; syncs when back online |

---

## 4. Monetization

### 4.1 Tiers

| | Free | Pro ($4.99/mo) | Teacher ($9.99/mo) |
|---|---|---|---|
| Note training | ✅ | ✅ | ✅ |
| Course levels | 1 level (Note Basics) | All levels | All levels |
| Daily sessions | 3/day | Unlimited | Unlimited |
| Weekly leagues | ✅ | ✅ | ✅ |
| Offline mode | ❌ | ✅ | ✅ |
| Pitch accuracy graphs | ❌ | ✅ | ✅ |
| Ads | Between sessions | No ads | No ads |
| Custom practice mode | ❌ | ✅ | ✅ |
| Student management | ❌ | ❌ | Up to 30 students |
| Assign exercises | ❌ | ❌ | ✅ |
| Student dashboard | ❌ | ❌ | ✅ |

### 4.2 Paywall Placement

- Free users hit the Pro paywall at ~30% through Level 2 (Intervals I)
- Daily session limit reached triggers upgrade prompt
- Offline download triggers upgrade prompt
- Profile tab has persistent upgrade card for free users

---

## 5. Technical Architecture

### 5.1 Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter 3.x (Dart) | Cross-platform, native performance, platform-adaptive widgets |
| State management | Riverpod 2.x | Type-safe, testable, better than Provider for complex state |
| Routing | GoRouter | Declarative, deep linking, ShellRoute for tab navigation |
| Local DB | Isar / Hive | Offline-first storage, fast, type-safe |
| Backend | Firebase (existing project) | Firestore + Firebase Auth (reuse existing project) |
| Auth | Firebase Auth (email, Google, Apple, anonymous trial) | Needed for monetization + cross-device sync |
| Music notation | Custom Flutter CustomPainter | Replaces VexFlow; no WebView dependency |
| Pitch detection | flutter_audio_capture / fft package | Native audio analysis in Dart |
| In-app purchases | revenuecat_flutter or in_app_purchase | Cross-platform IAP for subscriptions |
| Notifications | firebase_messaging + flutter_local_notifications | Push + local reminder notifications |
| Haptics | HapticFeedback (Flutter built-in) | Platform-adaptive haptic patterns |
| Analytics | firebase_analytics + custom events | Track engagement, conversion, retention |

### 5.2 Directory Structure (Flutter)

```
lib/
├── main.dart                          # Entry point, Firebase init
├── app.dart                           # MaterialApp/CupertinoApp, GoRouter setup
├── config/
│   ├── firebase_config.dart           # Firebase initialization
│   ├── theme.dart                     # ThemeData (Material 3) + CupertinoTheme
│   └── constants.dart                 # Note names, pitch thresholds, colors, timing
├── core/
│   ├── audio/
│   │   └── pitch_detection_service.dart    # Native FFT pitch detection
│   ├── notation/
│   │   ├── staff_painter.dart              # CustomPainter for music staff
│   │   └── note_renderer.dart              # Renders notes on staff
│   ├── learning/
│   │   └── progressive_learning_service.dart  # Mastery-based spaced repetition
│   └── sync/
│       ├── sync_service.dart               # Offline-first sync engine
│       └── local_storage_service.dart      # Isar/Hive abstraction
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       ├── streak_ring.dart
│   │       ├── daily_challenge_card.dart
│   │       └── league_position_row.dart
│   ├── learn/
│   │   ├── learn_screen.dart
│   │   └── widgets/
│   │       ├── course_card.dart
│   │       └── paywall_sheet.dart
│   ├── practice/
│   │   ├── practice_screen.dart
│   │   └── widgets/
│   │       ├── music_card.dart
│   │       ├── mode_chips.dart
│   │       ├── mic_status_bar.dart
│   │       ├── pitch_accuracy_bar.dart
│   │       └── session_stats_bar.dart
│   ├── social/
│   │   ├── social_screen.dart
│   │   └── widgets/
│   │       ├── leaderboard.dart
│   │       └── duel_card.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── widgets/
│           ├── stat_grid.dart
│           ├── achievement_showcase.dart
│           └── upgrade_card.dart
├── shared/
│   ├── models/
│   │   ├── user.dart
│   │   ├── course.dart
│   │   ├── learning_card.dart
│   │   ├── session_stats.dart
│   │   └── achievement.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── learning_provider.dart
│   │   ├── practice_provider.dart
│   │   ├── league_provider.dart
│   │   └── settings_provider.dart
│   ├── services/
│   │   ├── firestore/
│   │   │   ├── firestore_service.dart        # Base CRUD
│   │   │   ├── user_service.dart             # User document management
│   │   │   └── learning_progress_service.dart # Learning data CRUD
│   │   └── revenue/
│   │       └── subscription_service.dart     # IAP handling
│   └── utils/
│       ├── note_conversion.dart              # Frequency ↔ MIDI ↔ note name
│       └── haptic_patterns.dart              # Haptic feedback presets
└── l10n/                                     # Localization (future)
    └── app_en.arb
```

### 5.3 Data Models

```dart
// Firestore: /users/{uid}
class User {
  String uid;
  String email;
  String displayName;
  DateTime accountCreated;
  DateTime updatedAt;
  String instrument;        // "guitar", "piano", "voice", etc.
  String instrumentRange;   // "E2-E5"
  int xp;
  int level;
  String currentLeague;     // "bronze", "silver", "gold", "sapphire", etc.
  bool isPro;
  String? subscriptionId;
}

// Firestore: /users/{uid}/learningProgress/current
class LearningProgress {
  List<LearningCard> learningCards;
  List<MasteredCard> masteredCards;
  int cardIdCounter;
  SessionStats stats;
  String currentCourseId;
  Map<String, CourseProgress> courseProgress;  // per-course progress
}

class LearningCard {
  String noteValue;
  int correctStreak;
  int totalCorrect;
  int totalIncorrect;
  DateTime lastSeen;
}

class MasteredCard {
  String noteValue;
  int totalCorrect;
  int totalIncorrect;
  DateTime masteredAt;
  int reviewCount;
}

// Local DB (Isar): mirror of Firestore data + pending sync queue
class SyncQueueItem {
  int id;
  String collection;
  String documentId;
  Map<String, dynamic> data;
  DateTime timestamp;
  bool synced;
}
```

### 5.4 State Management (Riverpod)

```
authProvider          → FirebaseAuth user state, sign-in/out methods
learningProvider      → ProgressiveLearningService wrapper, card stack, stats
practiceProvider      → Current session state, mic status, pitch results
courseProvider        → Course list, per-course progress, locked/unlocked state
leagueProvider        → Current league data, leaderboard, time remaining
challengeProvider     → Daily challenge state, time remaining, user's rank
settingsProvider      → Instrument, range, haptics, theme preferences
subscriptionProvider  → Pro/Teacher status, IAP product list, purchase flow
syncProvider          → Online/offline status, pending sync count
```

### 5.5 Offline-First Sync Strategy

1. All learning progress is written to local Isar DB FIRST
2. A sync queue tracks pending writes
3. When online, sync queue is drained to Firestore
4. On app start, Firestore data is pulled and merged with local (server wins on conflicts, but local streak data takes priority)
5. Auth state is cached locally; anonymous trial works offline
6. Pro features check is cached with 24h TTL; re-verified online

---

## 6. Key Technical Challenges

### 6.1 Music Notation Rendering

**Replacing VexFlow with Flutter CustomPainter:**

- Draw 5 staff lines as horizontal lines with standard spacing
- Treble clef rendered as a path (can use a pre-built SVG path or custom bezier curves)
- Notes rendered as filled ovals at correct vertical positions (based on note name → staff position mapping)
- Ledger lines for notes above/below the staff
- Sharp/flat accidental symbols
- The rendering must work at card-size (small) and detail-size (zoomed)

**Fallback option:** If CustomPainter proves too complex for clef + accidentals, use a pre-rendered SVG asset for the staff background and overlay note dots programmatically.

### 6.2 Pitch Detection

**Replacing Pitchy.js with Dart-native audio processing:**

1. Use `flutter_audio_capture` or `record` package to get raw PCM audio from mic
2. Apply FFT (Fast Fourier Transform) using the `fft` Dart package or a native implementation
3. Find peak frequency in the spectrum
4. Apply same anti-bounce logic from the web app (confidence voting over time window, refractory period, silence detection)
5. Convert frequency → MIDI note → note name using ported `noteConversion` logic

**Risk:** Dart FFT performance on older devices. Mitigation: use `dart:ffi` with a C FFT library if needed, or process on a separate isolate.

### 6.3 Platform-Adaptive UI

- Use `Theme.of(context).platform` to switch between Material and Cupertino widgets
- Bottom nav: `NavigationBar` (Material 3) vs `CupertinoTabBar`
- Lists: `ListView` with Material vs `CupertinoScrollbar`
- Dialogs: `AlertDialog` vs `CupertinoAlertDialog`
- Settings: `Switch` vs `CupertinoSwitch`
- Typography: Material 3 type scale vs SF Pro scale

---

## 7. Engagement & Retention

### 7.1 Habit Loops

1. **Daily:** Push notification → Daily Challenge → XP → League position update → Streak protected
2. **Competitive:** Friend passes you → Duel → Practice to improve → Check leaderboard
3. **Progression:** Complete lesson → Unlock next → See course % → Hit paywall → Subscribe → Binge

### 7.2 Notification Strategy

| Trigger | Message | Frequency |
|---------|---------|-----------|
| Streak at risk | "Your 7-day streak ends in 4 hours! 🔥" | Once, 4h before midnight local |
| League ending | "You're #5 — top 7 promote! Keep going 🏆" | Once, 6h before league end |
| New daily challenge | "Today's challenge: Speed Round C Major ⚡" | Once, 9am local |
| Friend duel | "Alex challenged you to a note duel! ⚔️" | On-demand |
| Inactive 3 days | "Your notes are getting rusty 🎵 Come practice!" | Once after 3 days |

### 7.3 Gamification

- **XP:** Earned per correct note, bonus for streaks, daily challenge completion
- **Levels:** Every 500 XP = new level. Cosmetic rewards (card themes, app icons)
- **Streaks:** Days with at least 1 session. Visualized as fire ring animation
- **Leagues:** 30 users, weekly. Top 7 promote, bottom 5 demote. Bronze → Silver → Gold → Sapphire → Diamond
- **Achievements:** Incremental and surprise badges. "First Note", "Perfect Session", "50 Mastered", "100 Day Streak"

---

## 8. What We Don't Build (Yet)

These are intentionally deferred to post-launch:

- Rhythm training mode (tap-to-the-beat detection)
- Real song fragments / licensed music content
- Teacher dashboard web portal (teacher features start mobile-only)
- Social friend system (search/add friends beyond duels)
- Localization beyond English
- Widget/home screen streak widget
- Dynamic Island live activity (nice-to-have)
- AI-powered feedback ("Your F# is sharp, relax your embouchure")

---

## 9. Verification Plan

### 9.1 Build & Run
- `flutter run` on Android emulator + iOS simulator
- `flutter build apk --release` for Android APK
- `flutter build ios --release` for iOS (requires macOS + Xcode)

### 9.2 Feature Gates
- Free tier: verify daily session limit (3), course lock at Level 2, ads between sessions
- Pro tier: verify all courses unlocked, offline mode works, no ads
- Offline: airplane mode → complete session → go online → verify sync

### 9.3 Core Flow
1. Fresh install → onboarding → anonymous trial → sign-up prompt
2. Home screen shows 0 streak, Level 1, "Start Learning" CTA
3. Learn → Note Basics course → Practice session
4. Play note on instrument → pitch detected → accuracy shown → auto-advance
5. Check stats after session → XP gained, streak updated
6. Kill app, reopen → progress persists (local DB)
7. Sign in → progress syncs to Firestore

### 9.4 Cross-Platform
- Android (Material 3): verify NavigationBar, Material switches, Roboto typography
- iOS (Cupertino): verify CupertinoTabBar, Cupertino switches, SF Pro typography
- Both: verify haptic patterns feel right on each platform
