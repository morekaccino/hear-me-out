import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/placement_starters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/placement_controller.dart';
import '../../state/providers.dart';
import 'placement_navigation.dart';

/// The non-blocking entry to the placement check.
///
/// On the path it appears when no placement exists or a re-test is due. In
/// Profile it always appears so the starting point can be changed manually.
class PlacementPromptCard extends ConsumerStatefulWidget {
  const PlacementPromptCard({super.key, this.profile = false});

  final bool profile;

  @override
  ConsumerState<PlacementPromptCard> createState() =>
      _PlacementPromptCardState();
}

class _PlacementPromptCardState extends ConsumerState<PlacementPromptCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(placementControllerProvider);
    if (async.isLoading) return const SizedBox.shrink();
    final record = async.asData?.value;
    if (async.hasError && record == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final due = record?.retestDue(now) ?? false;

    if (_hidden) return const SizedBox.shrink();
    if (!widget.profile && record != null && !due) {
      return const SizedBox.shrink();
    }

    final isRetest = !widget.profile && record != null && due;
    final title = widget.profile
        ? 'Starting point'
        : 'Not sure where to start?';
    final body = widget.profile
        ? (record == null
              ? 'A short check can place you.'
              : 'Stage ${record.stage} · ${placementStageLabel(record.stage)}')
        : isRetest
        ? 'Time for a short check-in? Your starting point can be updated.'
        : 'A short check can place you.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(DuoSpacing.md, 4, DuoSpacing.md, 8),
      child: SectionCard(
        key: const ValueKey('placement-prompt'),
        color: record == null ? AppColors.blueSoft : AppColors.greenSoft,
        borderColor: record == null ? AppColors.blue : AppColors.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  record == null ? Icons.explore_rounded : Icons.flag_rounded,
                  size: 18,
                  color: record == null
                      ? AppColors.blueDark
                      : AppColors.greenDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: record == null
                          ? AppColors.blueDark
                          : AppColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: AppColors.textMuted,
              ),
            ),
            if (record?.hasPhase2Gap ?? false) ...[
              const SizedBox(height: 4),
              Text(
                'Stage ${record!.phase2Stage} is Phase 2, so this is the '
                'nearest V1 start.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (widget.profile && record != null)
              DuoButton(
                key: const ValueKey('placement-prompt-start'),
                label: 'CHANGE STARTING POINT',
                height: 44,
                fontSize: 13,
                onPressed: () =>
                    _open(initialStage: record.stage, startAtResult: true),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DuoButton(
                      key: const ValueKey('placement-prompt-start'),
                      label: isRetest ? 'START CHECK' : 'START SHORT CHECK',
                      height: 44,
                      fontSize: 13,
                      onPressed: () => _open(startAtResult: false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    key: const ValueKey('placement-prompt-skip'),
                    onPressed: isRetest ? _dismissRetest : _hide,
                    child: Text(
                      isRetest ? 'NOT NOW' : 'SKIP FOR NOW',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open({int? initialStage, required bool startAtResult}) async {
    await openPlacementFlow(
      context,
      ref,
      initialStage: initialStage,
      startAtResult: startAtResult,
    );
  }

  void _hide() {
    setState(() => _hidden = true);
  }

  Future<void> _dismissRetest() async {
    await ref.read(placementControllerProvider.notifier).dismissRetest();
    if (mounted) setState(() => _hidden = true);
  }
}
