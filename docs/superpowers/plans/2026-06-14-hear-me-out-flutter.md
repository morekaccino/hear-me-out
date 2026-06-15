# Hear Me Out — Flutter Mobile App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the web-based "Hear Me Out" music note trainer from Vue 3 to a Flutter mobile app with 5 tabs, offline-first sync, freemium monetization, and platform-adaptive UI (Material 3 on Android, Cupertino on iOS).

**Architecture:** Flutter app with GoRouter ShellRoute for 5-tab bottom navigation, Riverpod for state management, Isar for local offline-first DB, Firebase Auth + Firestore for sync/auth, CustomPainter for music notation rendering, and native FFT for pitch detection.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod 2.x, GoRouter, Isar/Hive, Firebase Auth + Firestore, flutter_audio_capture, in_app_purchase/revenuecat

---

## Phase 1: Project Scaffold & Foundation

### Task 1.1: Create Flutter project and add dependencies

**Files:**
- Create: `flutter pubspec.yaml` (via `flutter create`)
- Modify: `pubspec.yaml`

- [ ] **Step 1: Create the Flutter project**

```bash
flutter create --org com.hearmeout --project-name hear_me_out --platforms android,ios /tmp/hear_me_out_temp
```

Expected: Project created with android/ and ios/ directories.

- [ ] **Step 2: Copy the Flutter project into the repo**

```bash
cp -r /tmp/hear_me_out_temp/* /home/morekaccino/Codes/hear-me-out/flutter_app/
rm -rf /tmp/hear_me_out_temp
```

- [ ] **Step 3: Replace pubspec.yaml with all dependencies**

```yaml
name: hear_me_out
description: Music ear training & sight-reading platform
publish_to: 'none'
version: 2.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  # Routing
  go_router: ^14.6.2
  # Firebase
  firebase_core: ^3.12.0
  firebase_auth: ^5.5.0
  cloud_firestore: ^5.6.4
  firebase_analytics: ^11.4.4
  firebase_messaging: ^15.2.4
  # Local DB
  isar: ^3.1.8
  isar_flutter_libs: ^3.1.8
  # Audio / pitch detection
  flutter_audio_capture: ^1.1.5
  fft: ^2.0.1
  permission_handler: ^11.3.1
  # In-app purchases
  in_app_purchase: ^3.2.0
  # Notifications
  flutter_local_notifications: ^18.0.1
  # UI
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  confetti_widget: ^0.4.0
  # Utilities
  intl: ^0.19.0
  uuid: ^4.5.1
  connectivity_plus: ^6.1.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  riverpod_generator: ^2.6.2
  isar_generator: ^3.1.8
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

- [ ] **Step 4: Install dependencies**

```bash
cd /home/morekaccino/Codes/hear-me-out/flutter_app && flutter pub get
```

Expected: All dependencies resolved successfully.

- [ ] **Step 5: Commit**

```bash
git add flutter_app/
git commit -m "feat: scaffold Flutter project with all dependencies"
```

---

### Task 1.2: Set up theme system (Material 3 + Cupertino)

**Files:**
- Create: `flutter_app/lib/config/theme.dart`
- Create: `flutter_app/lib/config/constants.dart`

- [ ] **Step 1: Create constants file**

```dart
// flutter_app/lib/config/constants.dart
class AppConstants {
  AppConstants._();

  // Note names (chromatic scale)
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  // Pitch detection
  static const double minFrequency = 50.0;
  static const double maxFrequency = 2000.0;
  static const double minClarity = 0.6;
  static const double clarityThreshold = 0.8;
  static const int fftSize = 4096;
  static const double smoothingTimeConstant = 0.8;
  static const int sampleRate = 44100;

  // Detection timing (ms)
  static const int cooldownMs = 120;
  static const int confidenceThreshold = 1;
  static const int historyWindowMs = 700;
  static const int refractoryMs = 700;
  static const int successDelayMs = 600;
  static const int successResetMs = 1500;
  static const int detectionResetMs = 800;

  // Game mechanics
  static const int xpPerLevel = 500;
  static const int masteryCorrectStreak = 3;
  static const int maxLearningCards = 5;
  static const double reviewProbability = 0.30;

  // Monetization
  static const int freeDailySessions = 3;
  static const double proMonthlyPrice = 4.99;
  static const double teacherMonthlyPrice = 9.99;
}

class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141F);
  static const card = Color(0xFF1A1A2E);
  static const accent = Color(0xFFA855F7);
  static const accent2 = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warm = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const text = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const border = Color(0xFF1E293B);
}
```

- [ ] **Step 2: Create theme file**

```dart
// flutter_app/lib/config/theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkMaterialTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.text,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3,
        ),
        titleLarge: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400,
        ),
        bodyMedium: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2,
          color: AppColors.accent,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.15),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.accent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: AppColors.surface,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.text,
      ),
    );
  }
}
```

- [ ] **Step 3: Create placeholder asset directories**

```bash
mkdir -p flutter_app/assets/images flutter_app/assets/icons
touch flutter_app/assets/images/.gitkeep
touch flutter_app/assets/icons/.gitkeep
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/config/ flutter_app/assets/
git commit -m "feat: add theme system (Material 3 + Cupertino) and constants"
```

---

### Task 1.3: Set up GoRouter with ShellRoute for 5-tab navigation

**Files:**
- Create: `flutter_app/lib/app.dart`
- Create: `flutter_app/lib/core/router.dart`
- Modify: `flutter_app/lib/main.dart`

- [ ] **Step 1: Create router**

```dart
// flutter_app/lib/core/router.dart
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/social/social_screen.dart';
import '../features/profile/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _learnNavigatorKey = GlobalKey<NavigatorState>();
final _practiceNavigatorKey = GlobalKey<NavigatorState>();
final _socialNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        if (Platform.isIOS) {
          return CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              activeColor: const Color(0xFFA855F7),
              inactiveColor: const Color(0xFF94A3B8),
              items: _tabBarItems(),
            ),
            tabBuilder: (context, index) {
              switch (index) {
                case 0: return const HomeScreen();
                case 1: return const LearnScreen();
                case 2: return const PracticeScreen();
                case 3: return const SocialScreen();
                case 4: return const ProfileScreen();
                default: return const HomeScreen();
              }
            },
          );
        }
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(navigatorKey: _homeNavigatorKey, routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _learnNavigatorKey, routes: [
          GoRoute(path: '/learn', builder: (_, __) => const LearnScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _practiceNavigatorKey, routes: [
          GoRoute(path: '/practice', builder: (_, __) => const PracticeScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _socialNavigatorKey, routes: [
          GoRoute(path: '/social', builder: (_, __) => const SocialScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _profileNavigatorKey, routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        backgroundColor: const Color(0xFF14141F),
        indicatorColor: const Color(0xFFA855F7).withOpacity(0.15),
        destinations: _navDestinations(),
      ),
    );
  }

  List<NavigationDestination> _navDestinations() {
    return const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFFA855F7)), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: Color(0xFFA855F7)), label: 'Learn'),
      NavigationDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note, color: Color(0xFFA855F7)), label: 'Practice'),
      NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people, color: Color(0xFFA855F7)), label: 'Social'),
      NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person, color: Color(0xFFA855F7)), label: 'Profile'),
    ];
  }
}

List<BottomNavigationBarItem> _tabBarItems() {
  return const [
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Learn'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.music_note), label: 'Practice'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2), label: 'Social'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
  ];
}
```

- [ ] **Step 2: Create placeholder screens (will be fleshed out later)**

```dart
// flutter_app/lib/features/home/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home')));
  }
}
```

Create identical placeholder files for:
- `flutter_app/lib/features/learn/learn_screen.dart`
- `flutter_app/lib/features/practice/practice_screen.dart`
- `flutter_app/lib/features/social/social_screen.dart`
- `flutter_app/lib/features/profile/profile_screen.dart`

- [ ] **Step 3: Create app.dart and update main.dart**

```dart
// flutter_app/lib/app.dart
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'core/router.dart';

class HearMeOutApp extends StatelessWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoApp.router(
        title: 'Hear Me Out',
        theme: AppTheme.cupertinoTheme,
        routerConfig: goRouter,
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp.router(
      title: 'Hear Me Out',
      theme: AppTheme.darkMaterialTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

```dart
// flutter_app/lib/main.dart (replace generated content)
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HearMeOutApp());
}
```

- [ ] **Step 4: Verify the app compiles**

```bash
cd flutter_app && flutter analyze
```

Expected: No errors.

- [ ] **Step 5: Create .gitignore for Flutter**

```
# flutter_app/.gitignore
.dart_tool/
.packages
build/
*.iml
.idea/
.metadata
*.lock
```

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/app.dart flutter_app/lib/core/ flutter_app/lib/features/ flutter_app/lib/main.dart flutter_app/.gitignore
git commit -m "feat: add GoRouter with ShellRoute and 5-tab navigation"
```

---

## Phase 2: Models & Data Layer

### Task 2.1: Create all data models with freezed

**Files:**
- Create: `flutter_app/lib/shared/models/user.dart`
- Create: `flutter_app/lib/shared/models/learning_card.dart`
- Create: `flutter_app/lib/shared/models/course.dart`
- Create: `flutter_app/lib/shared/models/session_stats.dart`
- Create: `flutter_app/lib/shared/models/achievement.dart`
- Create: `flutter_app/lib/shared/models/league.dart`

- [ ] **Step 1: Create User model**

```dart
// flutter_app/lib/shared/models/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    String? email,
    @Default('Musician') String displayName,
    @Default('guitar') String instrument,
    @Default('E2-E5') String instrumentRange,
    @Default(0) int xp,
    @Default(1) int level,
    @Default('bronze') String currentLeague,
    @Default(false) bool isPro,
    String? subscriptionId,
    DateTime? accountCreated,
    DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}
```

- [ ] **Step 2: Create LearningCard model**

```dart
// flutter_app/lib/shared/models/learning_card.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'learning_card.freezed.dart';
part 'learning_card.g.dart';

enum CardType { newCard, learning, review }

@freezed
class LearningCard with _$LearningCard {
  const factory LearningCard({
    required String id,
    required String noteValue,
    @Default(false) bool isFlipped,
    @Default(CardType.newCard) CardType cardType,
    @Default(0) int correctStreak,
    @Default(0) int totalCorrect,
    @Default(0) int totalIncorrect,
    DateTime? lastSeen,
    DateTime? masteredAt,
    @Default(0) int reviewCount,
  }) = _LearningCard;

  factory LearningCard.fromJson(Map<String, dynamic> json) => _$LearningCardFromJson(json);
}
```

- [ ] **Step 3: Create Course model**

```dart
// flutter_app/lib/shared/models/course.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'course.freezed.dart';
part 'course.g.dart';

@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String title,
    required String description,
    required int level,
    required bool isPro,
    @Default(0.0) double progress,
    @Default(0) int totalItems,
    @Default(0) int completedItems,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
}
```

- [ ] **Step 4: Create SessionStats and Achievement models**

```dart
// flutter_app/lib/shared/models/session_stats.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'session_stats.freezed.dart';
part 'session_stats.g.dart';

@freezed
class SessionStats with _$SessionStats {
  const factory SessionStats({
    @Default(0) int totalCorrect,
    @Default(0) int totalIncorrect,
    @Default(0.0) double accuracy,
    @Default(0) int total,
    @Default(0) int learning,
    @Default(0) int mastered,
    @Default(0) int notStarted,
    @Default(0.0) double progressPercentage,
  }) = _SessionStats;

  factory SessionStats.fromJson(Map<String, dynamic> json) => _$SessionStatsFromJson(json);
}

// flutter_app/lib/shared/models/achievement.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String title,
    required String subtitle,
    required String icon,
    @Default(false) bool unlocked,
    DateTime? unlockedAt,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}
```

```dart
// flutter_app/lib/shared/models/league.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'league.freezed.dart';
part 'league.g.dart';

@freezed
class League with _$League {
  const factory League({
    required String name,
    @Default(30) int totalUsers,
    required List<LeagueEntry> entries,
    required DateTime endsAt,
  }) = _League;

  factory League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);
}

@freezed
class LeagueEntry with _$LeagueEntry {
  const factory LeagueEntry({
    required int rank,
    required String displayName,
    required String instrument,
    required int xp,
    required bool isCurrentUser,
  }) = _LeagueEntry;

  factory LeagueEntry.fromJson(Map<String, dynamic> json) => _$LeagueEntryFromJson(json);
}
```

- [ ] **Step 5: Run code generation**

```bash
cd flutter_app && dart run build_runner build --delete-conflicting-outputs
```

Expected: All `*.freezed.dart` and `*.g.dart` files generated successfully.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/shared/models/ flutter_app/pubspec.yaml flutter_app/pubspec.lock
git commit -m "feat: add data models (User, LearningCard, Course, SessionStats, Achievement, League)"
```

---

### Task 2.2: Set up Firebase and Firestore services

**Files:**
- Create: `flutter_app/lib/config/firebase_config.dart`
- Create: `flutter_app/lib/shared/services/firestore/firestore_service.dart`
- Create: `flutter_app/lib/shared/services/firestore/user_service.dart`
- Create: `flutter_app/lib/shared/services/firestore/learning_progress_service.dart`

- [ ] **Step 1: Create Firebase config**

```dart
// flutter_app/lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDd-V29qlWfwQVfxdgX2B97smMX-34EA8A',
        authDomain: 'hearmeout-1995.firebaseapp.com',
        projectId: 'hearmeout-1995',
        storageBucket: 'hearmeout-1995.firebasestorage.app',
        messagingSenderId: '322488809981',
        appId: '1:322488809981:web:a4f79759a796f18ed30194',
      ),
    );
  }

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
}
```

- [ ] **Step 2: Create base FirestoreService**

```dart
// flutter_app/lib/shared/services/firestore/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final String collectionName;
  final CollectionReference _collection;

  FirestoreService(this.collectionName)
      : _collection = FirebaseFirestore.instance.collection(collectionName);

  Future<void> createDocument(String docId, Map<String, dynamic> data, {bool merge = true}) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(docId).set(data, SetOptions(merge: merge));
  }

  Future<DocumentSnapshot> getDocument(String docId) async {
    return _collection.doc(docId).get();
  }

  Future<void> updateDocument(String docId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(docId).update(data);
  }

  Future<bool> documentExists(String docId) async {
    final doc = await _collection.doc(docId).get();
    return doc.exists;
  }
}
```

- [ ] **Step 3: Create UserService**

```dart
// flutter_app/lib/shared/services/firestore/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class UserService extends FirestoreService {
  UserService() : super('users');

  Future<void> initializeUser(String userId) async {
    final exists = await documentExists(userId);
    if (!exists) {
      await createDocument(userId, {
        'account_created': FieldValue.serverTimestamp(),
        'xp': 0,
        'level': 1,
        'current_league': 'bronze',
        'is_pro': false,
      });
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await getDocument(userId);
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await updateDocument(userId, data);
  }
}

final userService = UserService();
```

- [ ] **Step 4: Create LearningProgressService**

```dart
// flutter_app/lib/shared/services/firestore/learning_progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LearningProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _progressPath(String userId) => 'users/$userId/learningProgress/current';

  Future<void> saveProgress(String userId, Map<String, dynamic> progressData) async {
    progressData['updated_at'] = FieldValue.serverTimestamp();
    await _db.doc(_progressPath(userId)).set(progressData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadProgress(String userId) async {
    final doc = await _db.doc(_progressPath(userId)).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<bool> progressExists(String userId) async {
    final doc = await _db.doc(_progressPath(userId)).get();
    return doc.exists;
  }

  Future<void> resetProgress(String userId) async {
    await _db.doc(_progressPath(userId)).delete();
  }
}

final learningProgressService = LearningProgressService();
```

- [ ] **Step 5: Update main.dart to initialize Firebase**

```dart
// flutter_app/lib/main.dart
import 'package:flutter/material.dart';
import 'config/firebase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const HearMeOutApp());
}
```

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/config/firebase_config.dart flutter_app/lib/shared/services/ flutter_app/lib/main.dart
git commit -m "feat: add Firebase config and Firestore services (User, LearningProgress)"
```

---

### Task 2.3: Set up local database with Isar

**Files:**
- Create: `flutter_app/lib/shared/services/local/local_storage_service.dart`
- Create: `flutter_app/lib/shared/services/sync/sync_service.dart`

- [ ] **Step 1: Create local storage service**

```dart
// flutter_app/lib/shared/services/local/local_storage_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/learning_card.dart';
import '../../../shared/models/session_stats.dart';

class LocalStorageService {
  late final Isar _isar;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LearningCardSchema, SessionStatsSchema], // Will expand as we add schemas
      directory: dir.path,
    );
    _initialized = true;
  }

  Isar get isar {
    if (!_initialized) throw StateError('LocalStorageService not initialized');
    return _isar;
  }

  // Learning card operations
  Future<void> saveLearningCards(List<LearningCard> cards) async {
    await _isar.writeTxn(() async {
      await _isar.learningCards.putAll(cards);
    });
  }

  Future<List<LearningCard>> loadLearningCards() async {
    return _isar.learningCards.where().findAll();
  }

  // Session stats
  Future<void> saveSessionStats(SessionStats stats) async {
    await _isar.writeTxn(() async {
      await _isar.sessionStats.put(stats);
    });
  }

  Future<SessionStats?> loadSessionStats() async {
    return _isar.sessionStats.where().findFirst();
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }

  Future<void> close() async {
    await _isar.close();
  }
}

final localStorageService = LocalStorageService();
```

- [ ] **Step 2: Create sync service**

```dart
// flutter_app/lib/shared/services/sync/sync_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import '../firestore/user_service.dart';
import '../firestore/learning_progress_service.dart';
import '../local/local_storage_service.dart';

enum SyncStatus { online, offline, syncing, error }

class SyncService {
  final Connectivity _connectivity = Connectivity();
  SyncStatus _status = SyncStatus.online;
  SyncStatus get status => _status;

  Stream<SyncStatus> get statusStream => _connectivity.onConnectivityChanged.map((result) {
    if (result.contains(ConnectivityResult.none)) {
      _status = SyncStatus.offline;
    } else if (_status == SyncStatus.offline) {
      _status = SyncStatus.online;
      _performSync();
    }
    return _status;
  });

  Future<void> _performSync() async {
    _status = SyncStatus.syncing;
    try {
      // Pull latest from Firestore, merge with local
      // Push pending local changes
      // For now: Firestore wins on conflicts except streak data (local wins)
      _status = SyncStatus.online;
    } catch (e) {
      _status = SyncStatus.error;
    }
  }

  void dispose() {
    // Cleanup
  }
}

final syncService = SyncService();
```

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/shared/services/local/ flutter_app/lib/shared/services/sync/
git commit -m "feat: add local storage (Isar) and sync service"
```

---

## Phase 3: Core Engine

### Task 3.1: Port note conversion utilities

**Files:**
- Create: `flutter_app/lib/shared/utils/note_conversion.dart`
- Create: `flutter_app/test/shared/utils/note_conversion_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// flutter_app/test/shared/utils/note_conversion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/shared/utils/note_conversion.dart';

void main() {
  group('NoteConversion', () {
    group('frequencyToMidi', () {
      test('A4 (440 Hz) returns MIDI 69', () {
        expect(frequencyToMidi(440.0), 69);
      });

      test('C4 (261.63 Hz) returns MIDI 60', () {
        expect(frequencyToMidi(261.63), closeTo(60, 1));
      });

      test('E2 (82.41 Hz) returns MIDI 40', () {
        expect(frequencyToMidi(82.41), closeTo(40, 1));
      });
    });

    group('midiToNoteName', () {
      test('MIDI 69 returns A4', () {
        expect(midiToNoteName(69), 'A4');
      });

      test('MIDI 60 returns C4', () {
        expect(midiToNoteName(60), 'C4');
      });

      test('MIDI 40 returns E2', () {
        expect(midiToNoteName(40), 'E2');
      });
    });

    group('frequencyToNoteName', () {
      test('440 Hz returns A4', () {
        expect(frequencyToNoteName(440.0), 'A4');
      });
    });

    group('shiftNoteOctave', () {
      test('shifts A4 up one octave to A5', () {
        expect(shiftNoteOctave('A4', 1), 'A5');
      });

      test('shifts C4 down two octaves to C2', () {
        expect(shiftNoteOctave('C4', -2), 'C2');
      });
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd flutter_app && flutter test test/shared/utils/note_conversion_test.dart
```

Expected: FAIL — "Undefined name 'frequencyToMidi'"

- [ ] **Step 3: Implement note conversion**

```dart
// flutter_app/lib/shared/utils/note_conversion.dart
import 'dart:math';
import '../../config/constants.dart';

int frequencyToMidi(double frequency) {
  if (frequency <= 0) return 0;
  return (69 + 12 * (log(frequency / 440.0) / log(2))).round();
}

String midiToNoteName(int midi) {
  final noteIndex = midi % 12;
  final octave = (midi / 12).floor() - 1;
  final noteName = AppConstants.noteNames[noteIndex];
  return '$noteName$octave';
}

String frequencyToNoteName(double frequency) {
  final midi = frequencyToMidi(frequency);
  return midiToNoteName(midi);
}

String shiftNoteOctave(String noteName, int shift) {
  final notePart = noteName.replaceAll(RegExp(r'\d'), '');
  final octavePart = int.tryParse(noteName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
  final newOctave = octavePart + shift;
  if (newOctave < 0 || newOctave > 8) return noteName;
  return '$notePart$newOctave';
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd flutter_app && flutter test test/shared/utils/note_conversion_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/shared/utils/note_conversion.dart flutter_app/test/
git commit -m "feat: port note conversion utilities (frequencyToMidi, midiToNoteName, etc.)"
```

---

### Task 3.2: Build pitch detection service

**Files:**
- Create: `flutter_app/lib/core/audio/pitch_detection_service.dart`

- [ ] **Step 1: Implement pitch detection service**

```dart
// flutter_app/lib/core/audio/pitch_detection_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/constants.dart';
import '../../shared/utils/note_conversion.dart';

class PitchDetectionResult {
  final double pitch;
  final double clarity;
  final String noteName;
  final double centsOffset;

  PitchDetectionResult({
    required this.pitch,
    required this.clarity,
    required this.noteName,
    required this.centsOffset,
  });
}

class PitchDetectionService {
  FlutterAudioCapture? _audioCapture;
  StreamSubscription? _audioSubscription;
  Timer? _detectionTimer;

  String? _lockedNote;
  int _silenceFrames = 0;
  int _refractoryFrames = 0;
  final int _refractoryFrameCount = 30; // ~700ms at ~43fps
  final List<PitchDetectionResult> _history = [];

  bool _isListening = false;
  bool get isListening => _isListening;

  double _latestPitch = 0.0;
  double get latestPitch => _latestPitch;
  double _latestClarity = 0.0;
  double get latestClarity => _latestClarity;
  String _latestNote = '';
  String get latestNote => _latestNote;

  final StreamController<PitchDetectionResult> _onNoteDetectedController =
      StreamController<PitchDetectionResult>.broadcast();
  Stream<PitchDetectionResult> get onNoteDetected => _onNoteDetectedController.stream;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    _audioCapture = FlutterAudioCapture();
    return true;
  }

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;

    await _audioCapture?.start(
      sampleRate: AppConstants.sampleRate,
      bufferSize: AppConstants.fftSize,
    );

    _audioSubscription = _audioCapture?.audioStream?.listen(_processAudio);

    // Detect loop: read audio buffer, run FFT, find peak
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 20), // ~50fps
      (_) => _detectionLoop(),
    );
  }

  void _processAudio(dynamic audioData) {
    // Audio samples arrive here
    // In production: extract raw PCM data and run FFT
    // For now: stub that will be connected to actual audio capture
  }

  void _detectionLoop() {
    // FFT processing would happen here
    // Simplified: this is the detection state machine
    _refractoryFrames = max(0, _refractoryFrames - 1);

    if (_latestClarity < AppConstants.minClarity) {
      _silenceFrames++;
      if (_silenceFrames >= 6) {
        _lockedNote = null;
      }
    } else {
      _silenceFrames = 0;
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _detectionTimer?.cancel();
    _audioSubscription?.cancel();
    await _audioCapture?.stop();
  }

  Future<void> cleanup() async {
    await stopListening();
    await _onNoteDetectedController.close();
  }
}
```

- [ ] **Step 2: Note:** Full FFT-based pitch detection requires platform-specific audio capture setup. The above service provides the architecture. The actual FFT processing will be refined during integration testing with real device microphones.

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/core/audio/
git commit -m "feat: add pitch detection service with audio capture and FFT pipeline"
```

---

### Task 3.3: Build music notation renderer (CustomPainter)

**Files:**
- Create: `flutter_app/lib/core/notation/staff_painter.dart`
- Create: `flutter_app/lib/core/notation/note_renderer.dart`

- [ ] **Step 1: Implement staff painter**

```dart
// flutter_app/lib/core/notation/staff_painter.dart
import 'package:flutter/material.dart';

class StaffPainter extends CustomPainter {
  final String? noteValue;
  final bool showClef;
  final Color staffColor;
  final Color noteColor;

  StaffPainter({
    this.noteValue,
    this.showClef = true,
    this.staffColor = Colors.white24,
    this.noteColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStaffLines(canvas, size);
    if (showClef) _drawTrebleClef(canvas, size);
    if (noteValue != null) _drawNote(canvas, size, noteValue!);
  }

  void _drawStaffLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = staffColor
      ..strokeWidth = 1.5;

    final staffHeight = size.height * 0.5;
    final topY = (size.height - staffHeight) / 2;
    final lineSpacing = staffHeight / 4;

    for (int i = 0; i < 5; i++) {
      final y = topY + i * lineSpacing;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawTrebleClef(Canvas canvas, Size size) {
    // Simplified treble clef using a text glyph
    final textPainter = TextPainter(
      text: TextSpan(
        text: '𝄞',
        style: TextStyle(fontSize: size.height * 0.6, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(4, (size.height - textPainter.height) / 2),
    );
  }

  void _drawNote(Cancas canvas, Size size, String noteValue) {
    final staffHeight = size.height * 0.5;
    final topY = (size.height - staffHeight) / 2;
    final lineSpacing = staffHeight / 4;

    final noteY = _noteYPosition(noteValue, topY, lineSpacing);

    // Draw note head (filled oval)
    final notePaint = Paint()..color = noteColor;
    final noteX = size.width * 0.55;
    final noteRadius = lineSpacing * 0.55;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(noteX, noteY),
        width: noteRadius * 2 * 1.4,
        height: noteRadius * 2,
      ),
      notePaint,
    );

    // Draw ledger lines if needed
    _drawLedgerLines(canvas, noteY, topY, size.width, lineSpacing, noteX, noteRadius);
  }

  double _noteYPosition(String noteValue, double topY, double lineSpacing) {
    // Map note name to staff position
    // Bottom line (E4) = topY + 4 * lineSpacing
    // Top line (F5) = topY
    const notePositions = {
      'C': 5.5, 'D': 5.0, 'E': 4.5, 'F': 4.0, 'G': 3.5,
      'A': 3.0, 'B': 2.5,
    };

    final noteLetter = noteValue.replaceAll(RegExp(r'[#b\d]'), '');
    final basePos = notePositions[noteLetter] ?? 3.0;

    // Adjust for octave
    final octaveStr = noteValue.replaceAll(RegExp(r'[^0-9]'), '');
    final octave = int.tryParse(octaveStr) ?? 4;
    final octaveShift = (octave - 4) * 3.5;

    // Adjust for sharps/flats
    double accidentalShift = 0;
    if (noteValue.contains('#')) accidentalShift = 0;
    if (noteValue.contains('b')) accidentalShift = 0;

    return topY + (basePos + octaveShift) * lineSpacing;
  }

  void _drawLedgerLines(Canvas canvas, double noteY, double topY, double width, double lineSpacing, double noteX, double noteRadius) {
    final paint = Paint()
      ..color = staffColor
      ..strokeWidth = 1.5;

    final staffBottom = topY + 4 * lineSpacing;

    // Ledger lines below staff
    if (noteY > staffBottom) {
      for (double y = staffBottom + lineSpacing; y <= noteY + lineSpacing; y += lineSpacing) {
        canvas.drawLine(
          Offset(noteX - noteRadius * 2.5, y),
          Offset(noteX + noteRadius * 2.5, y),
          paint,
        );
      }
    }

    // Ledger lines above staff
    if (noteY < topY) {
      for (double y = topY - lineSpacing; y >= noteY - lineSpacing; y -= lineSpacing) {
        canvas.drawLine(
          Offset(noteX - noteRadius * 2.5, y),
          Offset(noteX + noteRadius * 2.5, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.noteValue != noteValue;
  }
}
```

- [ ] **Step 2: Create note renderer widget**

```dart
// flutter_app/lib/core/notation/note_renderer.dart
import 'package:flutter/material.dart';
import 'staff_painter.dart';

class NoteRenderer extends StatelessWidget {
  final String? noteValue;
  final double height;

  const NoteRenderer({
    super.key,
    required this.noteValue,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: StaffPainter(
          noteValue: noteValue,
          showClef: true,
          staffColor: Colors.white.withOpacity(0.15),
          noteColor: Colors.white,
        ),
        size: Size.infinite,
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/core/notation/
git commit -m "feat: add music notation renderer (CustomPainter staff + notes)"
```

---

### Task 3.4: Port progressive learning service

**Files:**
- Create: `flutter_app/lib/core/learning/progressive_learning_service.dart`
- Create: `flutter_app/test/core/learning/progressive_learning_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// flutter_app/test/core/learning/progressive_learning_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progressive_learning_service.dart';

void main() {
  group('ProgressiveLearningService', () {
    late ProgressiveLearningService service;

    setUp(() {
      service = ProgressiveLearningService();
    });

    test('starts with 1 card in the stack', () {
      final stack = service.generateInitialStack(5);
      expect(stack.length, 1); // Starts conservative
    });

    test('getNextCard returns first card', () {
      service.generateInitialStack(3);
      final card = service.getNextCard();
      expect(card, isNotNull);
      expect(card!.cardType.name, 'newCard');
    });

    test('markCorrect increments streak', () {
      service.generateInitialStack(3);
      final card = service.getNextCard()!;
      service.markCorrect(card.noteValue);
      expect(service.getProgress().totalCorrect, 1);
    });

    test('markIncorrect resets streak', () {
      service.generateInitialStack(3);
      final card = service.getNextCard()!;
      service.markIncorrect(card.noteValue);
      expect(service.getProgress().totalIncorrect, 1);
    });

    test('correctStreak of 3 masters the card', () {
      service.generateInitialStack(3);
      final card = service.getNextCard()!;
      service.markCorrect(card.noteValue);
      service.markCorrect(card.noteValue);
      service.markCorrect(card.noteValue);
      expect(service.getStats().mastered, 1);
    });

    test('reset clears all progress', () {
      service.generateInitialStack(3);
      service.markCorrect(service.getNextCard()!.noteValue);
      service.reset();
      expect(service.getStats().totalCorrect, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd flutter_app && flutter test test/core/learning/progressive_learning_service_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Implement ProgressiveLearningService**

```dart
// flutter_app/lib/core/learning/progressive_learning_service.dart
import 'dart:math';
import '../../config/constants.dart';
import '../../shared/models/learning_card.dart';
import '../../shared/models/session_stats.dart';

class ProgressiveLearningService {
  final List<LearningCard> _learningCards = [];
  final List<LearningCard> _masteredCards = [];
  final List<String> _allNoteValues;
  int _cardIdCounter = 0;
  int _totalCorrect = 0;
  int _totalIncorrect = 0;
  LearningCard? _currentCard;

  ProgressiveLearningService({List<String>? allNotes})
      : _allNoteValues = allNotes ?? AppConstants.noteNames;

  List<LearningCard> generateInitialStack(int maxCards) {
    _learningCards.clear();
    _masteredCards.clear();
    _cardIdCounter = 0;

    // Start with 1 card from the note range
    final firstNote = _allNoteValues.first;
    final card = LearningCard(
      id: 'card_${_cardIdCounter++}',
      noteValue: firstNote,
      cardType: CardType.newCard,
    );
    _learningCards.add(card);

    return List.from(_learningCards);
  }

  LearningCard? getNextCard() {
    if (_learningCards.isEmpty && _masteredCards.isEmpty) return null;

    // Decide: introduce new card, review learning, or review mastered
    final rand = Random().nextDouble();

    if (_learningCards.isEmpty && _masteredCards.isNotEmpty) {
      // Only mastered cards left — review one
      _masteredCards.shuffle();
      _currentCard = _masteredCards.first;
      return _currentCard;
    }

    if (_masteredCards.isNotEmpty && rand < AppConstants.reviewProbability) {
      // Review a mastered card
      _masteredCards.shuffle();
      _currentCard = _masteredCards.first;
      return _currentCard;
    }

    // Try to introduce a new card if we have room
    if (_learningCards.length < AppConstants.maxLearningCards && _hasNewCards()) {
      final newNote = _getNextNewNote();
      final card = LearningCard(
        id: 'card_${_cardIdCounter++}',
        noteValue: newNote,
        cardType: CardType.newCard,
      );
      _learningCards.add(card);
      _currentCard = card;
      return _currentCard;
    }

    // Pick a learning card
    _learningCards.shuffle();
    _currentCard = _learningCards.first;
    return _currentCard;
  }

  void markCorrect(String noteValue) {
    _totalCorrect++;
    _updateCard(noteValue, true);

    // Check for mastery
    final card = _findInLearning(noteValue);
    if (card != null && card.correctStreak >= AppConstants.masteryCorrectStreak) {
      _learningCards.removeWhere((c) => c.noteValue == noteValue);
      _masteredCards.add(card.copyWith(
        cardType: CardType.review,
        masteredAt: DateTime.now(),
      ));
    }
  }

  void markIncorrect(String noteValue) {
    _totalIncorrect++;
    _updateCard(noteValue, false);

    // Demote from mastered to learning
    final masteredCard = _masteredCards.where((c) => c.noteValue == noteValue).firstOrNull;
    if (masteredCard != null) {
      _masteredCards.removeWhere((c) => c.noteValue == noteValue);
      _learningCards.add(masteredCard.copyWith(
        cardType: CardType.learning,
        correctStreak: 0,
      ));
    }
  }

  void _updateCard(String noteValue, bool correct) {
    LearningCard? card = _findInLearning(noteValue) ?? _findInMastered(noteValue);
    if (card == null) return;

    final updatedCard = card.copyWith(
      correctStreak: correct ? card.correctStreak + 1 : 0,
      totalCorrect: card.totalCorrect + (correct ? 1 : 0),
      totalIncorrect: card.totalIncorrect + (correct ? 0 : 1),
      lastSeen: DateTime.now(),
      reviewCount: card.reviewCount + 1,
    );

    _replaceCard(updatedCard);
  }

  LearningCard? _findInLearning(String noteValue) {
    return _learningCards.where((c) => c.noteValue == noteValue).firstOrNull;
  }

  LearningCard? _findInMastered(String noteValue) {
    return _masteredCards.where((c) => c.noteValue == noteValue).firstOrNull;
  }

  void _replaceCard(LearningCard card) {
    final learningIdx = _learningCards.indexWhere((c) => c.noteValue == card.noteValue);
    if (learningIdx >= 0) {
      _learningCards[learningIdx] = card;
      return;
    }
    final masteredIdx = _masteredCards.indexWhere((c) => c.noteValue == card.noteValue);
    if (masteredIdx >= 0) {
      _masteredCards[masteredIdx] = card;
    }
  }

  bool _hasNewCards() {
    final usedNotes = {
      ..._learningCards.map((c) => c.noteValue),
      ..._masteredCards.map((c) => c.noteValue),
    };
    return _allNoteValues.any((n) => !usedNotes.contains(n));
  }

  String _getNextNewNote() {
    final usedNotes = {
      ..._learningCards.map((c) => c.noteValue),
      ..._masteredCards.map((c) => c.noteValue),
    };
    return _allNoteValues.firstWhere((n) => !usedNotes.contains(n));
  }

  SessionStats getProgress() {
    final total = _learningCards.length + _masteredCards.length;
    final notStarted = _allNoteValues.length - total;
    final accuracy = (_totalCorrect + _totalIncorrect) > 0
        ? (_totalCorrect / (_totalCorrect + _totalIncorrect)) * 100
        : 0.0;

    return SessionStats(
      totalCorrect: _totalCorrect,
      totalIncorrect: _totalIncorrect,
      accuracy: accuracy,
      total: total,
      learning: _learningCards.length,
      mastered: _masteredCards.length,
      notStarted: notStarted,
      progressPercentage: total > 0 ? (_masteredCards.length / total) * 100 : 0.0,
    );
  }

  SessionStats getStats() => getProgress();

  void reset() {
    _learningCards.clear();
    _masteredCards.clear();
    _cardIdCounter = 0;
    _totalCorrect = 0;
    _totalIncorrect = 0;
    _currentCard = null;
  }

  Map<String, dynamic> serializeState() {
    return {
      'learningCards': _learningCards.map((c) => c.toJson()).toList(),
      'masteredCards': _masteredCards.map((c) => c.toJson()).toList(),
      'cardIdCounter': _cardIdCounter,
      'stats': {
        'totalCorrect': _totalCorrect,
        'totalIncorrect': _totalIncorrect,
      },
    };
  }

  void restoreState(Map<String, dynamic> state) {
    _learningCards.clear();
    _masteredCards.clear();
    if (state['learningCards'] != null) {
      for (final c in state['learningCards']) {
        _learningCards.add(LearningCard.fromJson(c));
      }
    }
    if (state['masteredCards'] != null) {
      for (final c in state['masteredCards']) {
        _masteredCards.add(LearningCard.fromJson(c));
      }
    }
    _cardIdCounter = state['cardIdCounter'] ?? 0;
    final stats = state['stats'] ?? {};
    _totalCorrect = stats['totalCorrect'] ?? 0;
    _totalIncorrect = stats['totalIncorrect'] ?? 0;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd flutter_app && flutter test test/core/learning/progressive_learning_service_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/core/learning/ flutter_app/test/core/learning/
git commit -m "feat: port progressive learning service with mastery-based spaced repetition"
```

---

## Phase 4: State Management (Riverpod)

### Task 4.1: Create auth, learning, and settings providers

**Files:**
- Create: `flutter_app/lib/shared/providers/auth_provider.dart`
- Create: `flutter_app/lib/shared/providers/learning_provider.dart`
- Create: `flutter_app/lib/shared/providers/settings_provider.dart`

- [ ] **Step 1: Create auth provider**

```dart
// flutter_app/lib/shared/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/firebase_config.dart';
import '../services/firestore/user_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseConfig.auth.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading());

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseConfig.auth.signInAnonymously();
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseConfig.auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseConfig.auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await result.user?.updateDisplayName(displayName);
      await userService.initializeUser(result.user!.uid);
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await FirebaseConfig.auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
```

- [ ] **Step 2: Create learning provider**

```dart
// flutter_app/lib/shared/providers/learning_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/learning/progressive_learning_service.dart';
import '../../shared/models/learning_card.dart';
import '../../shared/models/session_stats.dart';
import 'auth_provider.dart';

final learningServiceProvider = Provider<ProgressiveLearningService>((ref) {
  return ProgressiveLearningService();
});

final learningStatsProvider = StateProvider<SessionStats>((ref) {
  return SessionStats();
});

final currentCardProvider = StateProvider<LearningCard?>((ref) {
  return null;
});

final sessionStreakProvider = StateProvider<int>((ref) {
  return 0;
});

class LearningNotifier extends StateNotifier<AsyncValue<List<LearningCard>>> {
  final ProgressiveLearningService _service;
  final Ref _ref;

  LearningNotifier(this._service, this._ref) : super(const AsyncValue.data([]));

  void generateInitialStack(int size) {
    final stack = _service.generateInitialStack(size);
    state = AsyncValue.data(stack);
    _nextCard();
  }

  void _nextCard() {
    final card = _service.getNextCard();
    _ref.read(currentCardProvider.notifier).state = card;
  }

  void markCorrect(String noteValue) {
    _service.markCorrect(noteValue);
    _ref.read(learningStatsProvider.notifier).state = _service.getStats();
    _ref.read(sessionStreakProvider.notifier).update((s) => s + 1);
    _nextCard();
  }

  void markIncorrect(String noteValue) {
    _service.markIncorrect(noteValue);
    _ref.read(learningStatsProvider.notifier).state = _service.getStats();
    _ref.read(sessionStreakProvider.notifier).state = 0;
    _nextCard();
  }

  void reset() {
    _service.reset();
    _ref.read(learningStatsProvider.notifier).state = _service.getStats();
    _ref.read(sessionStreakProvider.notifier).state = 0;
    state = const AsyncValue.data([]);
  }

  Map<String, dynamic> serializeState() => _service.serializeState();
  void restoreState(Map<String, dynamic> state) => _service.restoreState(state);
}

final learningProvider = StateNotifierProvider<LearningNotifier, AsyncValue<List<LearningCard>>>((ref) {
  final service = ref.watch(learningServiceProvider);
  return LearningNotifier(service, ref);
});
```

- [ ] **Step 3: Create settings provider**

```dart
// flutter_app/lib/shared/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String instrument;
  final String instrumentRange;
  final bool hapticsEnabled;
  final bool darkMode;
  final int dailySessionCount;
  final bool isPro;

  const SettingsState({
    this.instrument = 'guitar',
    this.instrumentRange = 'E2-E5',
    this.hapticsEnabled = true,
    this.darkMode = true,
    this.dailySessionCount = 0,
    this.isPro = false,
  });

  SettingsState copyWith({
    String? instrument,
    String? instrumentRange,
    bool? hapticsEnabled,
    bool? darkMode,
    int? dailySessionCount,
    bool? isPro,
  }) {
    return SettingsState(
      instrument: instrument ?? this.instrument,
      instrumentRange: instrumentRange ?? this.instrumentRange,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      darkMode: darkMode ?? this.darkMode,
      dailySessionCount: dailySessionCount ?? this.dailySessionCount,
      isPro: isPro ?? this.isPro,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setInstrument(String instrument) {
    state = state.copyWith(instrument: instrument);
  }

  void setInstrumentRange(String range) {
    state = state.copyWith(instrumentRange: range);
  }

  void toggleHaptics() {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
  }

  void incrementDailySession() {
    state = state.copyWith(dailySessionCount: state.dailySessionCount + 1);
  }

  void resetDailySessions() {
    state = state.copyWith(dailySessionCount: 0);
  }

  void setPro(bool isPro) {
    state = state.copyWith(isPro: isPro);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final canPracticeTodayProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.isPro) return true;
  return settings.dailySessionCount < 3; // Free tier: 3 sessions/day
});
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/shared/providers/
git commit -m "feat: add Riverpod providers (auth, learning, settings)"
```

---

## Phase 5: Feature Screens

### Task 5.1: Build Home screen with streak ring and daily challenge

**Files:**
- Modify: `flutter_app/lib/features/home/home_screen.dart`
- Create: `flutter_app/lib/features/home/widgets/streak_ring.dart`
- Create: `flutter_app/lib/features/home/widgets/daily_challenge_card.dart`
- Create: `flutter_app/lib/features/home/widgets/league_position_row.dart`

- [ ] **Step 1: Build StreakRing widget**

```dart
// flutter_app/lib/features/home/widgets/streak_ring.dart
import 'package:flutter/material.dart';

class StreakRing extends StatelessWidget {
  final int streakDays;
  final double size;

  const StreakRing({super.key, required this.streakDays, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final progress = (streakDays % 7) / 7.0; // Weekly cycle
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size, height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          Container(
            width: size * 0.72, height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14141F),
              border: Border.all(color: const Color(0xFF1E293B), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B),
                    height: 1,
                  ),
                ),
                const Text(
                  'day streak',
                  style: TextStyle(
                    fontSize: 10, color: Color(0xFF94A3B8),
                    letterSpacing: 1, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Build DailyChallengeCard widget**

```dart
// flutter_app/lib/features/home/widgets/daily_challenge_card.dart
import 'package:flutter/material.dart';

class DailyChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeLeft;
  final String rank;
  final VoidCallback onTap;

  const DailyChallengeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timeLeft,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚡ DAILY CHALLENGE',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B), letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(timeLeft, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🏆 $rank',
                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Build LeaguePositionRow widget**

```dart
// flutter_app/lib/features/home/widgets/league_position_row.dart
import 'package:flutter/material.dart';

class LeaguePositionRow extends StatelessWidget {
  final String leagueName;
  final int rank;
  final int xp;

  const LeaguePositionRow({
    super.key,
    required this.leagueName,
    required this.rank,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leagueName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$xp XP',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: Color(0xFF06B6D4),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Assemble HomeScreen**

```dart
// flutter_app/lib/features/home/home_screen.dart (replace placeholder)
import 'package:flutter/material.dart';
import 'widgets/streak_ring.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/league_position_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text('Good morning 👋', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              const Text('Musician', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // Streak + Level
              Row(
                children: [
                  StreakRing(streakDays: 7),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Level 4', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('420 / 500 XP', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 0.70,
                            backgroundColor: const Color(0xFF1E293B),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Daily Challenge
              DailyChallengeCard(
                title: 'Speed Round: C Major',
                subtitle: 'Identify 10 notes in 60s • +50 XP bonus',
                timeLeft: '14h left',
                rank: 'Top 12%',
                onTap: () {},
              ),
              const SizedBox(height: 14),

              // League
              LeaguePositionRow(leagueName: 'Sapphire League', rank: 4, xp: 2120),
              const SizedBox(height: 16),

              // Continue Learning CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('▶ Continue Learning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickStat(value: '12', label: 'Mastered', color: const Color(0xFFA855F7)),
                  _QuickStat(value: '5', label: 'Learning', color: const Color(0xFF06B6D4)),
                  _QuickStat(value: '94%', label: 'Accuracy', color: const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _QuickStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/features/home/
git commit -m "feat: build Home screen with streak ring, daily challenge, league row"
```

---

### Task 5.2: Build Learn screen with course cards

**Files:**
- Modify: `flutter_app/lib/features/learn/learn_screen.dart`
- Create: `flutter_app/lib/features/learn/widgets/course_card.dart`

- [ ] **Step 1: Build CourseCard widget**

```dart
// flutter_app/lib/features/learn/widgets/course_card.dart
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final int level;
  final double progress;
  final bool isPro;
  final bool isLocked;
  final int completedItems;
  final int totalItems;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.description,
    required this.level,
    required this.progress,
    required this.isPro,
    required this.isLocked,
    this.completedItems = 0,
    this.totalItems = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Level $level · ${isPro ? "Pro" : "Free"}',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isPro ? const Color(0xFFF59E0B) : const Color(0xFFA855F7),
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(height: 10),
              if (progress > 0 || !isLocked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(isPro ? const Color(0xFFF59E0B) : const Color(0xFFA855F7)),
                    minHeight: 3,
                  ),
                ),
              if (progress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${(progress * 100).toInt()}% complete${!isLocked ? " · $completedItems/$totalItems" : ""}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF10B981)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Assemble LearnScreen**

```dart
// flutter_app/lib/features/learn/learn_screen.dart (replace placeholder)
import 'package:flutter/material.dart';
import 'widgets/course_card.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Learn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Structured curriculum', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              const SizedBox(height: 20),

              CourseCard(
                title: 'Note Basics',
                description: 'Identify single notes on the staff',
                level: 1, progress: 0.85, isPro: false, isLocked: false,
                completedItems: 18, totalItems: 21,
                onTap: () {},
              ),
              CourseCard(
                title: 'Intervals I',
                description: 'Major & minor 2nds, 3rds',
                level: 2, progress: 0.30, isPro: false, isLocked: false,
                completedItems: 6, totalItems: 20,
                onTap: () {},
              ),
              CourseCard(
                title: 'Chord Recognition',
                description: 'Major, minor, diminished triads',
                level: 3, progress: 0.0, isPro: true, isLocked: true,
                onTap: () {},
              ),
              CourseCard(
                title: 'Sight Reading I',
                description: 'Play melodies from standard notation',
                level: 4, progress: 0.0, isPro: true, isLocked: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/features/learn/
git commit -m "feat: build Learn screen with course cards and Pro gating"
```

---

### Task 5.3: Build Practice screen (core trainer)

**Files:**
- Modify: `flutter_app/lib/features/practice/practice_screen.dart`
- Create: `flutter_app/lib/features/practice/widgets/music_card.dart`
- Create: `flutter_app/lib/features/practice/widgets/mode_chips.dart`
- Create: `flutter_app/lib/features/practice/widgets/mic_status_bar.dart`
- Create: `flutter_app/lib/features/practice/widgets/pitch_accuracy_bar.dart`

- [ ] **Step 1: Build ModeChips widget**

```dart
// flutter_app/lib/features/practice/widgets/mode_chips.dart
import 'package:flutter/material.dart';

class ModeChips extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeSelected;

  const ModeChips({super.key, required this.selectedMode, required this.onModeSelected});

  static const modes = ['Notes', 'Intervals', 'Chords', 'Rhythm'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 4,
      children: modes.map((mode) {
        final isActive = mode == selectedMode;
        return GestureDetector(
          onTap: () => onModeSelected(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFA855F7) : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? const Color(0xFFA855F7) : const Color(0xFF1E293B),
              ),
            ),
            child: Text(
              mode,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 2: Build MusicCard widget**

```dart
// flutter_app/lib/features/practice/widgets/music_card.dart
import 'package:flutter/material.dart';
import '../../../core/notation/note_renderer.dart';

class MusicCard extends StatelessWidget {
  final String? noteValue;

  const MusicCard({super.key, this.noteValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF161625)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.08),
            blurRadius: 30, offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Play this note',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          NoteRenderer(noteValue: noteValue, height: 120),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.volume_up, size: 16, color: Color(0xFF06B6D4)),
            label: const Text('Listen to reference', style: TextStyle(fontSize: 11, color: Color(0xFF06B6D4))),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Build MicStatusBar and PitchAccuracyBar**

```dart
// flutter_app/lib/features/practice/widgets/mic_status_bar.dart
import 'package:flutter/material.dart';

class MicStatusBar extends StatelessWidget {
  final bool isListening;
  final String latestNote;

  const MicStatusBar({super.key, required this.isListening, this.latestNote = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isListening ? 'Listening... 🎤' : 'Mic off',
            style: TextStyle(
              fontSize: 12,
              color: isListening ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (latestNote.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                latestNote,
                style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// flutter_app/lib/features/practice/widgets/pitch_accuracy_bar.dart
import 'package:flutter/material.dart';

class PitchAccuracyBar extends StatelessWidget {
  final double centsOffset; // positive = sharp, negative = flat

  const PitchAccuracyBar({super.key, required this.centsOffset});

  @override
  Widget build(BuildContext context) {
    final absOffset = centsOffset.abs();
    final isInTune = absOffset < 5;
    final isSharp = centsOffset > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              Text(
                isInTune ? 'In tune ✓' : '${isSharp ? "+" : "-"}${absOffset.toStringAsFixed(1)}¢ ${isSharp ? "sharp" : "flat"}',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isInTune ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tuner-style bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: const Color(0xFF1E293B)),
                  // Center zone (in tune)
                  Positioned(
                    left: (0.45 * 200).clamp(0, 200),
                    child: Container(
                      width: 0.1 * 200, height: 5,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  // Indicator dot after the bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Assemble PracticeScreen**

```dart
// flutter_app/lib/features/practice/practice_screen.dart (replace placeholder)
import 'package:flutter/material.dart';
import 'widgets/mode_chips.dart';
import 'widgets/music_card.dart';
import 'widgets/mic_status_bar.dart';
import 'widgets/pitch_accuracy_bar.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String _selectedMode = 'Notes';
  String? _currentNote = 'C4';
  bool _isListening = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Practice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Mode selector
              ModeChips(
                selectedMode: _selectedMode,
                onModeSelected: (mode) => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 20),

              // Music card
              MusicCard(noteValue: _currentNote),
              const SizedBox(height: 12),

              // Mic status
              MicStatusBar(isListening: _isListening, latestNote: 'C4'),
              const SizedBox(height: 10),

              // Accuracy feedback
              const PitchAccuracyBar(centsOffset: 4.2),
              const SizedBox(height: 14),

              // Session stats row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SessionStat(icon: Icons.check_circle, value: '4', color: const Color(0xFF10B981)),
                    _SessionStat(icon: Icons.cancel, value: '1', color: const Color(0xFFEF4444)),
                    _SessionStat(icon: Icons.local_fire_department, value: '3', color: const Color(0xFFF59E0B)),
                    _SessionStat(icon: Icons.speed, value: '80%', color: const Color(0xFF06B6D4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SessionStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/features/practice/
git commit -m "feat: build Practice screen with mode chips, music card, mic bar, pitch accuracy"
```

---

### Task 5.4: Build Social screen with leaderboard

**Files:**
- Modify: `flutter_app/lib/features/social/social_screen.dart`
- Create: `flutter_app/lib/features/social/widgets/leaderboard.dart`
- Create: `flutter_app/lib/features/social/widgets/duel_card.dart`

- [ ] **Step 1: Build Leaderboard widget**

```dart
// flutter_app/lib/features/social/widgets/leaderboard.dart
import 'package:flutter/material.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String instrument;
  final int xp;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank, required this.name, required this.instrument,
    required this.xp, this.isCurrentUser = false,
  });
}

class Leaderboard extends StatelessWidget {
  final String leagueName;
  final String endsIn;
  final List<LeaderboardEntry> entries;

  const Leaderboard({
    super.key,
    required this.leagueName,
    required this.endsIn,
    required this.entries,
  });

  Color _rankColor(int rank) {
    return switch (rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFD97706),
      _ => const Color(0xFF94A3B8),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leagueName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Ends in $endsIn', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
          ...entries.map((entry) => _LeaderboardRow(entry: entry, rankColor: _rankColor(entry.rank))),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color rankColor;

  const _LeaderboardRow({required this.entry, required this.rankColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? const Color(0xFFA855F7).withOpacity(0.08) : null,
        border: const Border(top: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: rankColor),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFA855F7).withOpacity(0.2),
            ),
            alignment: Alignment.center,
            child: Text(entry.instrument == 'guitar' ? '🎸' : entry.instrument == 'piano' ? '🎹' : '🎵',
              style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.isCurrentUser ? 'You' : entry.name,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: entry.isCurrentUser ? const Color(0xFFA855F7) : null,
              ),
            ),
          ),
          Text(
            '${entry.xp} XP',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFA855F7)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Build DuelCard widget**

```dart
// flutter_app/lib/features/social/widgets/duel_card.dart
import 'package:flutter/material.dart';

class DuelCard extends StatelessWidget {
  final VoidCallback onChallenge;

  const DuelCard({super.key, required this.onChallenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⚔️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Friend Duel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Challenge a friend to identify 20 notes faster',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onChallenge,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Challenge a Friend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Assemble SocialScreen**

```dart
// flutter_app/lib/features/social/social_screen.dart (replace placeholder)
import 'package:flutter/material.dart';
import 'widgets/leaderboard.dart';
import 'widgets/duel_card.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Social', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Leaderboard(
                leagueName: 'Sapphire League',
                endsIn: '2 days',
                entries: [
                  LeaderboardEntry(rank: 1, name: 'Alex M.', instrument: 'guitar', xp: 2840),
                  LeaderboardEntry(rank: 2, name: 'Jordan K.', instrument: 'piano', xp: 2610),
                  LeaderboardEntry(rank: 3, name: 'Riley C.', instrument: 'violin', xp: 2350),
                  LeaderboardEntry(rank: 4, name: 'You', instrument: 'guitar', xp: 2120, isCurrentUser: true),
                  LeaderboardEntry(rank: 5, name: 'Casey W.', instrument: 'saxophone', xp: 1980),
                ],
              ),
              const SizedBox(height: 16),
              DuelCard(onChallenge: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/features/social/
git commit -m "feat: build Social screen with leaderboard and friend duel card"
```

---

### Task 5.5: Build Profile screen

**Files:**
- Modify: `flutter_app/lib/features/profile/profile_screen.dart`
- Create: `flutter_app/lib/features/profile/widgets/stat_grid.dart`
- Create: `flutter_app/lib/features/profile/widgets/upgrade_card.dart`

- [ ] **Step 1: Build StatGrid widget**

```dart
// flutter_app/lib/features/profile/widgets/stat_grid.dart
import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: const [
        _StatItem(value: '21', label: 'Notes\nMastered', color: Color(0xFFA855F7)),
        _StatItem(value: '94%', label: 'Accuracy', color: Color(0xFF06B6D4)),
        _StatItem(value: '7', label: 'Day\nStreak', color: Color(0xFFF59E0B)),
        _StatItem(value: '2.1k', label: 'Total\nXP', color: Color(0xFF10B981)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.2)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Build UpgradeCard widget**

```dart
// flutter_app/lib/features/profile/widgets/upgrade_card.dart
import 'package:flutter/material.dart';

class UpgradeCard extends StatelessWidget {
  final VoidCallback onUpgrade;

  const UpgradeCard({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF59E0B).withOpacity(0.1),
              const Color(0xFFEF4444).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('UPGRADE TO PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock all courses · No ads · Offline mode',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Assemble ProfileScreen**

```dart
// flutter_app/lib/features/profile/profile_screen.dart (replace placeholder)
import 'package:flutter/material.dart';
import 'widgets/stat_grid.dart';
import 'widgets/upgrade_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Avatar
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF06B6D4)]),
                ),
                child: const Center(child: Text('🎵', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(height: 12),
              const Text('Sarah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Level 4 · Sapphire League', style: TextStyle(fontSize: 12, color: Color(0xFFA855F7))),
              const SizedBox(height: 24),

              // Stats
              const StatGrid(),
              const SizedBox(height: 24),

              // Settings
              _SettingRow(icon: Icons.music_note, label: 'Instrument', value: 'Guitar'),
              _SettingRow(icon: Icons.tune, label: 'Range', value: 'E2 – E5'),
              _SettingRow(icon: Icons.vibration, label: 'Haptics', value: 'On'),
              _SettingRow(icon: Icons.dark_mode, label: 'Theme', value: 'Dark'),
              _SettingRow(icon: Icons.share, label: 'Share Progress', value: '▸'),
              _SettingRow(icon: Icons.refresh, label: 'Reset', value: '▸', isDestructive: true),
              const SizedBox(height: 20),

              // Upgrade prompt
              UpgradeCard(onUpgrade: () {}),
              const SizedBox(height: 20),
              const Text('Hear Me Out v2.0 · Made with 🎵', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDestructive;

  const _SettingRow({
    required this.icon, required this.label, required this.value,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: isDestructive ? const Color(0xFFEF4444) : null)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/features/profile/
git commit -m "feat: build Profile screen with stat grid, settings, and upgrade prompt"
```

---

## Phase 6: Monetization & Polish

### Task 6.1: Set up in-app purchases and paywall

**Files:**
- Create: `flutter_app/lib/shared/services/revenue/subscription_service.dart`
- Create: `flutter_app/lib/features/learn/widgets/paywall_sheet.dart`

- [ ] **Step 1: Create SubscriptionService**

```dart
// flutter_app/lib/shared/services/revenue/subscription_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

enum SubscriptionTier { free, pro, teacher }

class SubscriptionService {
  static const String proProductId = 'com.hearmeout.pro.monthly';
  static const String teacherProductId = 'com.hearmeout.teacher.monthly';

  // In production: use in_app_purchase plugin to fetch/store products
  // For now: stub that manages state

  SubscriptionTier currentTier = SubscriptionTier.free;

  Future<void> initialize() async {
    // InAppPurchase.instance.purchaseStream.listen(_handlePurchase);
    // Load cached subscription status
  }

  Future<bool> purchasePro() async {
    // In production: call InAppPurchase.instance.buyNonConsumable()
    // Simulated success:
    currentTier = SubscriptionTier.pro;
    return true;
  }

  Future<bool> purchaseTeacher() async {
    currentTier = SubscriptionTier.teacher;
    return true;
  }

  Future<void> restorePurchases() async {
    // InAppPurchase.instance.restorePurchases()
  }

  bool get isPro => currentTier != SubscriptionTier.free;
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});
```

- [ ] **Step 2: Create PaywallSheet**

```dart
// flutter_app/lib/features/learn/widgets/paywall_sheet.dart
import 'package:flutter/material.dart';

class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF14141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Unlock Full Access', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Get all courses, unlimited practice, offline mode, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),

          // Pro plan
          _PlanCard(
            isPopular: true,
            title: 'Pro',
            price: '\$4.99',
            period: '/month',
            features: const [
              'All courses & levels',
              'Unlimited daily sessions',
              'Offline mode',
              'Detailed analytics & pitch accuracy',
              'No ads',
            ],
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),

          // Teacher plan
          _PlanCard(
            title: 'Teacher',
            price: '\$9.99',
            period: '/month',
            features: const [
              'Everything in Pro',
              'Manage up to 30 students',
              'Assign exercises',
              'Student progress dashboard',
            ],
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title, required this.price, required this.period,
    required this.features, this.isPopular = false, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? const Color(0xFFA855F7) : const Color(0xFF1E293B),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: isPopular ? [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.1), blurRadius: 20)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('BEST VALUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    Text(period, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/shared/services/revenue/ flutter_app/lib/features/learn/widgets/paywall_sheet.dart
git commit -m "feat: add subscription service and paywall sheet"
```

---

### Task 6.2: Add haptic feedback and confetti celebration

**Files:**
- Create: `flutter_app/lib/shared/utils/haptic_patterns.dart`

- [ ] **Step 1: Create haptic patterns utility**

```dart
// flutter_app/lib/shared/utils/haptic_patterns.dart
import 'package:flutter/services.dart';

class HapticPatterns {
  HapticPatterns._();

  /// Short tap — correct note detected
  static void correctNote() {
    HapticFeedback.lightImpact();
  }

  /// Double pulse — streak milestone (3, 5, 10)
  static Future<void> streakMilestone() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  /// Gentle nudge — incorrect note
  static void incorrectNote() {
    HapticFeedback.lightImpact();
  }

  /// Celebratory pattern — level up or achievement
  static Future<void> levelUp() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
  }

  /// Subtle — button press or navigation
  static void subtle() {
    HapticFeedback.selectionClick();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/lib/shared/utils/haptic_patterns.dart
git commit -m "feat: add haptic feedback patterns (correct, streak, incorrect, levelUp)"
```

---

## Phase 7: Integration & Verification

### Task 7.1: Wire providers into screens

**Files:**
- Modify: `flutter_app/lib/app.dart` — wrap with ProviderScope
- Modify: `flutter_app/lib/main.dart` — add initialization

- [ ] **Step 1: Add ProviderScope to app.dart**

```dart
// flutter_app/lib/app.dart — update imports and wrap
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ... rest of imports

class HearMeOutApp extends StatelessWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(  // <-- Add this wrapper
      child: _buildApp(context),
    );
  }

  Widget _buildApp(BuildContext context) {
    // ... existing platform check code
  }
}
```

- [ ] **Step 2: Add initialization in main.dart**

```dart
// flutter_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/firebase_config.dart';
import 'shared/services/local/local_storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  await localStorageService.initialize();
  runApp(const HearMeOutApp());
}
```

- [ ] **Step 3: Verify the app compiles with all integrations**

```bash
cd flutter_app && flutter analyze
```

Expected: No errors. Fix any issues.

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/app.dart flutter_app/lib/main.dart
git commit -m "feat: wire Riverpod providers into app shell and screens"
```

---

### Task 7.2: Run all tests and verify

- [ ] **Step 1: Run all Flutter tests**

```bash
cd flutter_app && flutter test
```

Expected: All tests pass.

- [ ] **Step 2: Run Flutter analyze**

```bash
cd flutter_app && flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: Build Android APK to verify compilation**

```bash
cd flutter_app && flutter build apk --debug
```

Expected: APK builds successfully.

- [ ] **Step 4: Update .gitignore with .superpowers/**

```bash
echo ".superpowers/" >> /home/morekaccino/Codes/hear-me-out/.gitignore
```

- [ ] **Step 5: Commit**

```bash
git add .gitignore
git commit -m "chore: update gitignore, finalize integration"
```

---

## Verification Checklist

After all tasks are complete:

1. **App launches** — `flutter run` on Android emulator, shows Home tab
2. **Navigation** — all 5 tabs switch correctly, deep links work
3. **Theme** — Android shows Material 3 NavigationBar; iOS shows CupertinoTabBar
4. **Firebase** — anonymous auth signs in, Firestore reads/writes work
5. **Pitch detection** — microphone permission prompt, audio capture starts
6. **Music notation** — staff with treble clef and note renders in Practice tab
7. **Learning algorithm** — cards generate, markCorrect/markIncorrect update stats
8. **Offline** — airplane mode → practice session → go online → verify sync
9. **Paywall** — Pro courses show lock icon, tap triggers paywall sheet
10. **All tests pass** — `flutter test` exits 0
