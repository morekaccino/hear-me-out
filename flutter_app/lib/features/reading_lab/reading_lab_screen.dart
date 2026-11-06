import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music/curriculum.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../path/path_screen.dart';
import 'reading_lab_entry.dart';

/// Opens the optional Reading Lab on top of the shell. The route hosts the
/// existing path and `LessonRun`, so no progress or lesson moves.
Route<void> readingLabRoute() =>
    duoLessonRoute<void>((_) => const ReadingLabScreen());

/// The original 240-lesson notation and theory course, labelled as the
/// optional Reading Lab. It is a bridge for current learners, not the core
/// Today loop, and it adds no gate of its own.
class ReadingLabScreen extends ConsumerWidget {
  const ReadingLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(appControllerProvider).asData?.value.progress;
    final completed = progress?.completedLessons.length ?? 0;

    return Scaffold(
      key: const ValueKey('reading-lab-screen'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReadingLabHeader(
              completedLessons: completed,
              onClose: () {
                unawaited(
                  ref.read(soundServiceProvider).play(Sfx.uiTapSecondary),
                );
                Navigator.of(context).maybePop();
              },
            ),
            const Expanded(child: PathScreen(showReadingLabLabel: false)),
          ],
        ),
      ),
    );
  }
}

class _ReadingLabHeader extends StatelessWidget {
  const _ReadingLabHeader({
    required this.completedLessons,
    required this.onClose,
  });

  final int completedLessons;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final total = allLessons.length;
    final done = completedLessons.clamp(0, total);
    final column = pathContentColumnFor(MediaQuery.sizeOf(context).width);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      padding: EdgeInsets.only(
        left: column.left,
        top: DuoSpacing.xs,
        bottom: DuoSpacing.sm,
      ),
      child: SizedBox(
        width: column.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back',
                  child: DuoTappable(
                    onTap: onClose,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DuoSpacing.sm),
                Expanded(
                  child: Text(
                    'READING LAB',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.blueDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DuoSpacing.xs,
                    vertical: DuoSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$done / $total lessons',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blueDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DuoSpacing.xs),
            const Text(
              'Structured reading practice, optional',
              key: ValueKey('reading-lab-header-title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              readingLabCopy(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
