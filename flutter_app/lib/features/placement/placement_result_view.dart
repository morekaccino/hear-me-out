import 'package:flutter/material.dart';

import '../../content/pieces/launch_pieces.dart';
import '../../content/pieces/placement_starters.dart';
import '../../core/learning/placement.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';

/// The editable result of the placement check.
///
/// The stage chips are the manual override. Nothing is persisted until the
/// caller saves the surrounding flow.
class PlacementResultView extends StatelessWidget {
  const PlacementResultView({
    super.key,
    required this.inferredStage,
    required this.selectedStage,
    required this.onStageChanged,
  });

  final int inferredStage;
  final int selectedStage;
  final ValueChanged<int> onStageChanged;

  @override
  Widget build(BuildContext context) {
    final starters = placementStarterSet(selectedStage);
    final phase2Stage = phase2StageFor(inferredStage);
    final resolvedStage = resolvePlacementStage(inferredStage);
    final phase2Copy = selectedStage == resolvedStage
        ? 'Your check pointed to Stage $phase2Stage, which is Phase 2. '
              'This build starts you at Stage $selectedStage, the nearest V1 '
              'stage.'
        : 'Your check pointed to Stage $phase2Stage, which is Phase 2. '
              'You chose Stage $selectedStage.';
    final outcome = placementStageOutcome(selectedStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mascot(size: 86),
        const SizedBox(height: 8),
        const Text(
          'Your starting point',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'This is a starting point, not a grade. You can change this '
          'anytime.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          color: AppColors.greenSoft,
          borderColor: AppColors.green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'STAGE $selectedStage',
                    key: const ValueKey('placement-result-stage'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const Spacer(),
                  _TierBadge(label: placementStageTier(selectedStage)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                placementStageLabel(selectedStage),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              if (outcome != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Stage focus: $outcome.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (phase2Stage != null) ...[
          const SizedBox(height: 10),
          SectionCard(
            color: AppColors.blueSoft,
            borderColor: AppColors.blue.withValues(alpha: 0.35),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.blueDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key: const ValueKey('placement-phase2-note'),
                    phase2Copy,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AppColors.blueDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'CHANGE YOUR STARTING POINT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stage in placementStages)
              _StageChip(
                key: ValueKey('placement-stage-$stage'),
                stage: stage,
                selected: stage == selectedStage,
                onTap: () => onStageChanged(stage),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'THREE STARTER PIECES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        for (final starter in starters)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StarterPieceCard(piece: starter),
          ),
        const SizedBox(height: 4),
        Text(
          'You can change this anytime in Profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    super.key,
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  final int stage;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Stage $stage, ${placementStageLabel(stage)}',
      child: DuoTappable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenSoft : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STAGE $stage',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: selected ? AppColors.greenDark : AppColors.textMuted,
                ),
              ),
              Text(
                placementStageLabel(stage),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarterPieceCard extends StatelessWidget {
  const _StarterPieceCard({required this.piece});

  final LaunchPiece piece;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            piece.piece.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            piece.piece.composer,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _TierBadge(label: placementStageTier(piece.v1Stage)),
              Text(
                'Stage ${piece.v1Stage} · ${placementStageLabel(piece.v1Stage)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.blueDark,
        ),
      ),
    );
  }
}
