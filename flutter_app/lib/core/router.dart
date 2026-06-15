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
import '../config/constants.dart';

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
              activeColor: AppColors.accent,
              inactiveColor: AppColors.textSecondary,
              items: const [
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Learn'),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.music_note), label: 'Practice'),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2), label: 'Social'),
                BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
              ],
            ),
            tabBuilder: (context, index) {
              return switch (index) {
                0 => const HomeScreen(),
                1 => const LearnScreen(),
                2 => const PracticeScreen(),
                3 => const SocialScreen(),
                4 => const ProfileScreen(),
                _ => const HomeScreen(),
              };
            },
          );
        }
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(navigatorKey: _homeNavigatorKey, routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _learnNavigatorKey, routes: [
          GoRoute(path: '/learn', builder: (_, _) => const LearnScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _practiceNavigatorKey, routes: [
          GoRoute(path: '/practice', builder: (_, _) => const PracticeScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _socialNavigatorKey, routes: [
          GoRoute(path: '/social', builder: (_, _) => const SocialScreen()),
        ]),
        StatefulShellBranch(navigatorKey: _profileNavigatorKey, routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
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
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.accent), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book, color: AppColors.accent), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note, color: AppColors.accent), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people, color: AppColors.accent), label: 'Social'),
          NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person, color: AppColors.accent), label: 'Profile'),
        ],
      ),
    );
  }
}
