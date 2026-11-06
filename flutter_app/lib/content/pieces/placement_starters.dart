import '../../core/learning/placement.dart';
import 'launch_pieces.dart';

/// A short human label for each V1 placement stage.
String placementStageLabel(int stage) => switch (stage) {
  1 => 'Open strings',
  2 => 'First notes',
  3 => 'Low first position',
  5 => 'Position shifts',
  9 => 'Sight-reading',
  10 => 'Repertoire',
  _ => 'Stage $stage',
};

/// The tier a V1 stage belongs to. Stages 1-3 are Foundation; 5, 9, and 10
/// are Returner.
String placementStageTier(int stage) => stage <= 3 ? 'Foundation' : 'Returner';

/// The stage outcome from plan section 6.1, or null for a non-V1 stage.
String? placementStageOutcome(int stage) => v1StageOutcomes[stage];

/// Exactly three real launch pieces for [stage].
///
/// Pieces at the placed stage come first, then pieces in the same tier by
/// distance, then the other tier. The list never invents a piece and never
/// returns a duplicate. The result is empty for a non-V1 stage.
List<LaunchPiece> placementStarterSet(int stage, {int count = 3}) {
  if (!v1PlacementStages.contains(stage) || count <= 0) {
    return const <LaunchPiece>[];
  }

  final placed = piecesForStage(stage);
  final tier = placed.isEmpty ? null : placed.first.tier;
  final sameTier = <LaunchPiece>[
    if (tier != null)
      for (final piece in launchPiecesForTier(tier))
        if (piece.v1Stage != stage) piece,
  ]..sort((a, b) => _distanceThenStage(a.v1Stage, b.v1Stage, stage));
  final otherTier =
      launchPieces.where((piece) => tier == null || piece.tier != tier).toList()
        ..sort((a, b) => _distanceThenStage(a.v1Stage, b.v1Stage, stage));

  final result = <LaunchPiece>[];
  final seen = <String>{};
  for (final piece in [...placed, ...sameTier, ...otherTier]) {
    if (result.length >= count) break;
    if (!seen.add(piece.piece.id)) continue;
    result.add(piece);
  }
  return List<LaunchPiece>.unmodifiable(result);
}

int _distanceThenStage(int a, int b, int stage) {
  final distanceA = (a - stage).abs();
  final distanceB = (b - stage).abs();
  if (distanceA != distanceB) return distanceA.compareTo(distanceB);
  return a.compareTo(b);
}

/// The three V1 stage ids in plan order. Kept here so UI code does not
/// hand-maintain a second stage table.
List<int> get placementStageOptions => v1PlacementStages;

/// The Phase 2 stage label, if [inferredStage] was mapped away.
int? placementPhase2Stage(int inferredStage) => phase2StageFor(inferredStage);
