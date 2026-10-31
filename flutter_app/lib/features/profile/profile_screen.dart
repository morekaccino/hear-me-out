import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../core/music/curriculum.dart';
import '../../core/music/note.dart';
import '../../core/storage/progress_store.dart';
import '../../state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    final settings = progress.settings;
    final notes =
        noteCatalog
            .where((note) => (progress.progressFor(note)?.attempts ?? 0) > 0)
            .toList()
          ..sort((a, b) {
            final boxA = progress.progressFor(a)?.box ?? 0;
            final boxB = progress.progressFor(b)?.box ?? 0;
            if (boxA != boxB) return boxB.compareTo(boxA);
            return a.id.compareTo(b.id);
          });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  const Mascot(size: 74),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guitarist',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Level ${progress.level}  ·  ${progress.xp} XP',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatPill(
                    icon: Icons.local_fire_department_rounded,
                    value: '${progress.effectiveStreak}',
                    iconColor: const Color(0xFFFF9600),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.15,
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF9600),
                    value: '${progress.effectiveStreak}',
                    label: 'Day streak',
                  ),
                  _StatCard(
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.yellowDark,
                    value: '${progress.bestStreak}',
                    label: 'Best streak',
                  ),
                  _StatCard(
                    icon: Icons.music_note_rounded,
                    color: AppColors.green,
                    value: '${progress.masteredCount}',
                    label: 'Mastered',
                  ),
                  _StatCard(
                    icon: Icons.speed_rounded,
                    color: AppColors.blue,
                    value: '${(progress.accuracy * 100).round()}%',
                    label: 'Accuracy',
                  ),
                  _StatCard(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.purple,
                    value:
                        '${progress.completedLessons.length}/${allLessons.length}',
                    label: 'Lessons',
                  ),
                  _StatCard(
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFFB020),
                    value: '${progress.xp}',
                    label: 'Total XP',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Your notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Boxes fill as notes move into long-term memory.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                child: notes.isEmpty
                    ? const Text(
                        'No notes learned yet. Start Unit 1 on the Learn tab.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final note in notes)
                            _NoteChip(
                              note: note,
                              progress: progress.progressFor(note)!,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SectionCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.touch_app_rounded,
                      label: 'Answer mode',
                      value: switch (settings.answerMode) {
                        AnswerMode.mixed => 'Mixed',
                        AnswerMode.name => 'Name only',
                        AnswerMode.play => 'Play only',
                      },
                      onTap: () => _cycleAnswerMode(ref, settings),
                    ),
                    const Divider(),
                    _SettingRow(
                      icon: Icons.tune_rounded,
                      label: 'Pitch tolerance',
                      value: '±${settings.toleranceCents} cents',
                      onTap: () => _cycleTolerance(ref, settings),
                    ),
                    const Divider(),
                    _SettingRow(
                      icon: Icons.music_note_rounded,
                      label: 'Tuning reference',
                      value: 'A4 = ${settings.a4Hz.toStringAsFixed(0)} Hz',
                      onTap: () => _cycleA4(ref, settings),
                    ),
                    const Divider(),
                    _SettingRow(
                      icon: Icons.flag_rounded,
                      label: 'Daily goal',
                      value: '${settings.dailyGoalXp} XP',
                      onTap: () => _cycleGoal(ref, settings),
                    ),
                    const Divider(),
                    _SettingRow(
                      icon: Icons.vibration_rounded,
                      label: 'Haptics',
                      trailing: Switch.adaptive(
                        value: settings.haptics,
                        activeThumbColor: AppColors.green,
                        onChanged: (value) => ref
                            .read(appControllerProvider.notifier)
                            .updateSettings(settings.copyWith(haptics: value)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.copy_rounded,
                      label: 'Copy backup',
                      value: 'JSON',
                      onTap: () => _copyBackup(context, progress),
                    ),
                    const Divider(),
                    _SettingRow(
                      icon: Icons.restore_rounded,
                      label: 'Restore backup',
                      value: 'Paste',
                      onTap: () => _restoreBackup(context, ref),
                    ),
                    const Divider(),
                    _SettingRow(
                      icon: Icons.restart_alt_rounded,
                      label: 'Reset progress',
                      value: '',
                      destructive: true,
                      onTap: () => _confirmReset(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                      Icons.lock_outline_rounded,
                      color: AppColors.blueDark,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No account. No cloud. Your progress, streak, and settings stay on this device. Audio is analyzed live and never recorded.',
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
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Hear Me Out 3.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cycleAnswerMode(WidgetRef ref, AppSettings settings) {
    final next = AnswerMode
        .values[(settings.answerMode.index + 1) % AnswerMode.values.length];
    return ref
        .read(appControllerProvider.notifier)
        .updateSettings(settings.copyWith(answerMode: next));
  }

  Future<void> _cycleTolerance(WidgetRef ref, AppSettings settings) {
    const values = [20, 30, 40];
    final index = values.indexOf(settings.toleranceCents);
    return ref
        .read(appControllerProvider.notifier)
        .updateSettings(
          settings.copyWith(
            toleranceCents: values[(index + 1) % values.length],
          ),
        );
  }

  Future<void> _cycleA4(WidgetRef ref, AppSettings settings) {
    const values = [432.0, 440.0, 442.0];
    final index = values.indexOf(settings.a4Hz);
    return ref
        .read(appControllerProvider.notifier)
        .updateSettings(
          settings.copyWith(a4Hz: values[(index + 1) % values.length]),
        );
  }

  Future<void> _cycleGoal(WidgetRef ref, AppSettings settings) {
    const values = [10, 20, 30];
    final index = values.indexOf(settings.dailyGoalXp);
    return ref
        .read(appControllerProvider.notifier)
        .updateSettings(
          settings.copyWith(dailyGoalXp: values[(index + 1) % values.length]),
        );
  }

  Future<void> _copyBackup(BuildContext context, ProgressState progress) async {
    await Clipboard.setData(ClipboardData(text: exportProgress(progress)));
    if (!context.mounted) return;
    _snack(context, 'Backup copied to clipboard.');
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    final restored = data == null ? null : importProgress(data.text ?? '');
    if (!context.mounted) return;
    if (restored == null) {
      _snack(context, 'No valid backup found in the clipboard.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace progress?'),
        content: const Text(
          'This replaces the current progress with the backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(appControllerProvider.notifier).replaceProgress(restored);
    if (context.mounted) _snack(context, 'Progress restored.');
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'Your notes, XP, streak, and lesson history will be cleared. Settings stay as they are.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(appControllerProvider.notifier).resetProgress();
    if (context.mounted) _snack(context, 'Progress reset.');
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
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

class _NoteChip extends StatelessWidget {
  const _NoteChip({required this.note, required this.progress});

  final Note note;
  final NoteProgress progress;

  @override
  Widget build(BuildContext context) {
    final color = progress.mastered
        ? AppColors.green
        : progress.accuracy < 0.7 && progress.attempts >= 2
        ? AppColors.red
        : progress.box >= 2
        ? AppColors.blue
        : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.display,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          for (var box = 1; box <= 5; box++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: box <= progress.box
                    ? color
                    : color.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value = '',
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: destructive ? AppColors.red : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: destructive ? AppColors.red : AppColors.text,
                ),
              ),
            ),
            ?trailing,
            if (trailing == null) ...[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
