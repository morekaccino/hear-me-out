import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/path/path_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/quests/quests_screen.dart';
import '../features/shop/shop_screen.dart';
import '../shared/audio/sound_service.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/mascot.dart';
import '../state/app_controller.dart';
import '../state/providers.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _destinations = [
    _TabDestination(
      label: 'Learn',
      icon: Icons.route_outlined,
      selectedIcon: Icons.route_rounded,
    ),
    _TabDestination(
      label: 'Practice',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
    ),
    _TabDestination(
      label: 'Quests',
      icon: Icons.military_tech_outlined,
      selectedIcon: Icons.military_tech_rounded,
    ),
    _TabDestination(
      label: 'Shop',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
    ),
    _TabDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _select(int index) {
    if (index == _index) return;
    unawaited(ref.read(soundServiceProvider).play(Sfx.uiNavigate));
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    const screens = [
      PathScreen(),
      PracticeScreen(),
      QuestsScreen(),
      ShopScreen(),
      ProfileScreen(),
    ];
    final progress = ref.watch(appControllerProvider).asData?.value.progress;
    final levelLabel = progress == null
        ? null
        : 'Level ${progress.level}  ·  ${progress.xp} XP';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _SideRail(
                    index: _index,
                    destinations: _destinations,
                    onSelected: _select,
                    levelLabel: levelLabel,
                  ),
                  Expanded(child: screens[_index]),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: Container(
            color: AppColors.background,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabDestination {
  const _TabDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.destinations,
    required this.onSelected,
    required this.levelLabel,
  });

  final int index;
  final List<_TabDestination> destinations;
  final ValueChanged<int> onSelected;
  final String? levelLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(right: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Mascot(size: 46),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Hear Me Out',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (levelLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    levelLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: _RailItem(
                destination: destinations[i],
                selected: i == index,
                onTap: () => onSelected(i),
              ),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textLight),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Local only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
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

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _TabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 25,
              color: selected ? AppColors.greenDark : AppColors.textMuted,
            ),
            const SizedBox(width: 14),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: selected ? AppColors.greenDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
