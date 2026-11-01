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

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    progress.refreshDaily(DateTime.now());

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
                      'Quests',
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
                'Fresh quests every day. Claim them for gems.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _QuestBanner(progress: progress),
              const SizedBox(height: 20),
              const Text(
                'Daily quests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Resets at midnight. ${_resetCopy()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              for (final quest in dailyQuestDefinitions) ...[
                _QuestCard(
                  quest: quest,
                  progress: progress.questProgress(quest),
                  claimed: progress.isQuestClaimed(quest),
                  onClaim: () async {
                    final claimed = await ref
                        .read(appControllerProvider.notifier)
                        .claimQuest(quest.id);
                    if (!context.mounted) return;
                    unawaited(
                      ref
                          .read(soundServiceProvider)
                          .play(claimed ? Sfx.copySuccess : Sfx.uiLocked),
                    );
                    if (claimed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Claimed ${quest.rewardGems} gems. Nice work.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.blueDark,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quests are tracked on this device. There are no leagues, leaderboards, or friend challenges.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                          color: AppColors.blueDark,
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

  String _resetCopy() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final left = midnight.difference(now);
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    return '${hours}h ${minutes}m left';
  }
}

class _QuestBanner extends StatelessWidget {
  const _QuestBanner({required this.progress});

  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final completed = dailyQuestDefinitions
        .where((quest) => progress.isQuestComplete(quest))
        .length;
    final claimed = dailyQuestDefinitions
        .where((quest) => progress.isQuestClaimed(quest))
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellowDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.yellowDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 46, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$claimed of ${dailyQuestDefinitions.length} claimed',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  completed == dailyQuestDefinitions.length
                      ? 'All quests complete. Collect your gems.'
                      : 'Complete quests to earn gems for the shop.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
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

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.progress,
    required this.claimed,
    required this.onClaim,
  });

  final QuestDefinition quest;
  final int progress;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / quest.target).clamp(0.0, 1.0);
    final complete = progress >= quest.target;
    final color = switch (quest.kind) {
      'correct' => AppColors.blue,
      'combo' => AppColors.purple,
      _ => AppColors.green,
    };
    final icon = switch (quest.kind) {
      'correct' => Icons.check_circle_rounded,
      'combo' => Icons.local_fire_department_rounded,
      _ => Icons.menu_book_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(14),
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.diamond_rounded,
                      size: 15,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${quest.rewardGems}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  quest.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: LessonProgressBar(
                        value: ratio,
                        color: complete ? AppColors.green : color,
                        height: 9,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${progress.clamp(0, quest.target)}/${quest.target}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: claimed
                ? const _ClaimedBadge()
                : DuoButton(
                    label: complete ? 'CLAIM' : 'TODO',
                    onPressed: complete ? onClaim : null,
                    color: AppColors.green,
                    height: 44,
                    fontSize: 13,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClaimedBadge extends StatelessWidget {
  const _ClaimedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'DONE',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.greenDark,
        ),
      ),
    );
  }
}
