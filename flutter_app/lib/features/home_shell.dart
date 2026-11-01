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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      color: AppColors.yellow,
    ),
    _TabDestination(
      label: 'Practice',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
      color: AppColors.blue,
    ),
    _TabDestination(
      label: 'Quests',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      color: AppColors.orange,
    ),
    _TabDestination(
      label: 'Shop',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      color: AppColors.red,
    ),
    _TabDestination(
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle_rounded,
      color: AppColors.purple,
    ),
  ];

  void _select(int index) {
    if (index == _index) return;
    unawaited(ref.read(soundServiceProvider).play(Sfx.uiNavigate));
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final screens = [
          PathScreen(onOpenQuests: () => _select(2)),
          const PracticeScreen(),
          const QuestsScreen(),
          const ShopScreen(),
          const ProfileScreen(),
        ];
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _SideRail(
                    index: _index,
                    destinations: _destinations,
                    onSelected: _select,
                    width: constraints.maxWidth >= 1280 ? 256 : 232,
                  ),
                  Expanded(child: screens[_index]),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 2),
              ),
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _BottomBar(
                  index: _index,
                  destinations: _destinations,
                  onSelected: _select,
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
    required this.color,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.destinations,
    required this.onSelected,
  });

  final int index;
  final List<_TabDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _BottomItem(
                  destination: destinations[i],
                  selected: i == index,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatefulWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _TabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BottomItem> createState() => _BottomItemState();
}

class _BottomItemState extends State<_BottomItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final selected = widget.selected;
    final accent = destination.color == AppColors.yellow
        ? AppColors.yellowDark
        : destination.color;
    final color = selected ? accent : AppColors.textLight;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? destination.color.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 25,
                  color: selected ? accent : color,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                child: Text(destination.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.destinations,
    required this.onSelected,
    required this.width,
  });

  final int index;
  final List<_TabDestination> destinations;
  final ValueChanged<int> onSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('side-rail'),
      width: width,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: GestureDetector(
              onTap: () => onSelected(0),
              child: const Text(
                'Hear Me Out',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.green,
                ),
              ),
            ),
          ),
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _RailItem(
                destination: destinations[i],
                selected: i == index,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _TabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected
        ? (AppColors.isDark ? AppColors.text : AppColors.blue)
        : AppColors.textMuted;
    final selectedBorder = AppColors.isDark
        ? AppColors.borderStrong
        : AppColors.blueLine;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blueSoft
                : _hover
                ? AppColors.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? selectedBorder : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: selected || _hover ? 1.08 : 1,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: Icon(
                  widget.destination.selectedIcon,
                  size: 28,
                  color: widget.destination.color,
                ),
              ),
              const SizedBox(width: 14),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: color,
                ),
                child: Text(widget.destination.label.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
