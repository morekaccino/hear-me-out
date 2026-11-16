import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/app_controller.dart';
import '../../state/first_session_controller.dart';
import 'first_session_screen.dart';

/// The only Path entry to the guided first session (T5.8).
///
/// It is an invitation, not a debt. It shows while the session is not completed
/// and the learner has not skipped it in this app run. SKIP FOR NOW inside the
/// screen hides it until the next launch; completing the flow removes it.
class FirstSessionCard extends ConsumerWidget {
  const FirstSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      appControllerProvider.select(
        (async) => async.asData?.value.progress.settings.firstSessionStatus,
      ),
    );
    final skippedThisRun = ref.watch(firstSessionRunSkipProvider);
    if (status == null ||
        status == FirstSessionStatus.completed ||
        skippedThisRun) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(DuoSpacing.md, 4, DuoSpacing.md, 8),
      child: SectionCard(
        key: const ValueKey('first-session-card'),
        color: AppColors.purpleSoft,
        borderColor: AppColors.purple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: AppColors.purpleDark,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Your first 3 minutes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purpleDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Hear four notes, play them back, see one correction, then record '
              'ten seconds. About 3 minutes.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            DuoButton(
              key: const ValueKey('first-session-card-start'),
              label: 'START 3 MINUTES',
              height: 44,
              fontSize: 13,
              onPressed: () => _open(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await Navigator.of(context).push<void>(
      duoLessonRoute((context) => const FirstSessionScreen()),
    );
  }
}
