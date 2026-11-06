import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/app_controller.dart';

/// Musical habits, not currency. Completing the real action completes the
/// quest, so there is no claim button and no reward to collect.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    progress.refreshQuests(DateTime.now());
    final daily = [
      for (final quest in questDefinitions)
        if (quest.period == QuestPeriod.daily) quest,
    ];
    final weekly = [
      for (final quest in questDefinitions)
        if (quest.period == QuestPeriod.weekly) quest,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text(
                'Quests',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Musical habits for today and this week. No currency, no '
                'leaderboards.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              _QuestBanner(progress: progress),
              const SizedBox(height: 24),
              const Text(
                'Today',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Resets at local midnight. ${_resetCopy()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              for (final quest in daily) ...[
                _QuestCard(quest: quest, progress: progress),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              const Text(
                'This week',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Resets on Monday. ${_weekResetCopy()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              for (final quest in weekly) ...[
                _QuestCard(quest: quest, progress: progress),
                const SizedBox(height: 8),
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
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quests are tracked on this device. There are no '
                        'leagues, leaderboards, currencies, or friend '
                        'challenges.',
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
    return '${left.inHours}h ${left.inMinutes % 60}m left';
  }

  String _weekResetCopy() {
    final days = 8 - DateTime.now().weekday;
    return days == 1 ? '1 day left' : '$days days left';
  }
}

class _QuestBanner extends StatelessWidget {
  const _QuestBanner({required this.progress});

  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final completed = questDefinitions
        .where((quest) => progress.isQuestComplete(quest))
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Icon(Icons.music_note_rounded, size: 46, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed of ${questDefinitions.length} done',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  completed == questDefinitions.length
                      ? 'All musical quests done. Keep playing.'
                      : 'Play phrases, record a take, and learn bars.',
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
  const _QuestCard({required this.quest, required this.progress});

  final QuestDefinition quest;
  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.questProgress(quest);
    final ratio = (value / quest.target).clamp(0.0, 1.0);
    final complete = value >= quest.target;
    final (color, icon) = switch (quest.kind) {
      'phrases' => (AppColors.green, Icons.music_note_rounded),
      'recordings' => (AppColors.purple, Icons.mic_rounded),
      'bars' => (AppColors.blue, Icons.straighten_rounded),
      _ => (AppColors.green, Icons.music_note_rounded),
    };
    final comingSoon = quest.awaitingProducer && !complete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            offset: const Offset(0, 3),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  quest.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                if (comingSoon) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Coming with recordings. Progress stays at zero until a '
                    'real take is saved.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: AppColors.purpleDark,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
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
                      '${value.clamp(0, quest.target)}/${quest.target}',
                      style: TextStyle(
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
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: complete
                ? const _DoneBadge()
                : _TodoBadge(comingSoon: comingSoon),
          ),
        ],
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(12),
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

class _TodoBadge extends StatelessWidget {
  const _TodoBadge({required this.comingSoon});

  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Text(
        comingSoon ? 'COMING SOON' : 'IN PROGRESS',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: comingSoon ? AppColors.purpleDark : AppColors.textMuted,
        ),
      ),
    );
  }
}
