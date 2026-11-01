import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    progress.refreshHearts(DateTime.now());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Shop',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatPill(
                    icon: Icons.diamond_rounded,
                    value: '${progress.gems}',
                    iconColor: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Spend the gems you earn from lessons, chests, and quests.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _ShopCard(
                icon: Icons.favorite_rounded,
                color: AppColors.red,
                title: 'Refill hearts',
                subtitle: progress.hearts >= maxHearts
                    ? 'Your hearts are full.'
                    : '${progress.hearts} of $maxHearts hearts left.',
                price: heartRefillCost,
                actionLabel: progress.hearts >= maxHearts ? 'FULL' : 'REFILL',
                enabled:
                    progress.hearts < maxHearts &&
                    progress.gems >= heartRefillCost,
                onBuy: () async {
                  final bought = await ref
                      .read(appControllerProvider.notifier)
                      .buyHeartRefill();
                  if (!context.mounted) return;
                  unawaited(
                    ref
                        .read(soundServiceProvider)
                        .play(bought ? Sfx.copySuccess : Sfx.uiLocked),
                  );
                  _snack(
                    context,
                    bought
                        ? 'Hearts refilled.'
                        : 'Not enough gems for a refill.',
                  );
                },
              ),
              const SizedBox(height: 10),
              _ShopCard(
                icon: Icons.ac_unit_rounded,
                color: AppColors.blue,
                title: 'Streak freeze',
                subtitle:
                    '${progress.streakFreezes} of $maxStreakFreezes equipped. Protects one missed day.',
                price: streakFreezeCost,
                actionLabel: progress.streakFreezes >= maxStreakFreezes
                    ? 'MAX'
                    : 'BUY',
                enabled:
                    progress.streakFreezes < maxStreakFreezes &&
                    progress.gems >= streakFreezeCost,
                onBuy: () async {
                  final bought = await ref
                      .read(appControllerProvider.notifier)
                      .buyStreakFreeze();
                  if (!context.mounted) return;
                  unawaited(
                    ref
                        .read(soundServiceProvider)
                        .play(bought ? Sfx.copySuccess : Sfx.uiLocked),
                  );
                  _snack(
                    context,
                    bought
                        ? 'Streak freeze equipped.'
                        : 'You cannot buy another freeze right now.',
                  );
                },
              ),
              const SizedBox(height: 10),
              _ShopCard(
                icon: Icons.bolt_rounded,
                color: AppColors.yellowDark,
                title: 'Double XP',
                subtitle: progress.xpBoostActive
                    ? 'Active for ${_boostMinutes(progress)} more minutes.'
                    : 'Double XP for 15 minutes.',
                price: xpBoostCost,
                actionLabel: 'BUY',
                enabled: progress.gems >= xpBoostCost,
                onBuy: () async {
                  final bought = await ref
                      .read(appControllerProvider.notifier)
                      .buyXpBoost();
                  if (!context.mounted) return;
                  unawaited(
                    ref
                        .read(soundServiceProvider)
                        .play(bought ? Sfx.rewardLevelUp : Sfx.uiLocked),
                  );
                  _snack(
                    context,
                    bought
                        ? 'Double XP is active.'
                        : 'Not enough gems for a boost.',
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Everything here is bought with gems earned in the app. There are no real-money purchases, subscriptions, ads, or accounts.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _boostMinutes(ProgressState progress) {
    final until = progress.xpBoostUntil;
    if (until == null) return '0';
    final minutes = until.difference(DateTime.now()).inMinutes;
    return minutes.clamp(0, 15).toString();
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.actionLabel,
    required this.enabled,
    required this.onBuy,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int price;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      size: 15,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$price',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: DuoButton(
              label: actionLabel,
              onPressed: enabled ? onBuy : null,
              color: AppColors.green,
              height: 48,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
