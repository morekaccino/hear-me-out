import '../../core/music/piece.dart';
import '../../core/music/sound_spec.dart';

/// One card on the "Pick a first piece" onboarding screen.
///
/// The preview is a short synth motif, not a human reference recording. T3.1
/// locks the launch list and T3.5 records human references; this is temporary
/// feature-layer data until then.
// TODO(T3.1): replace with the locked 10-piece launch list.
class OnboardingPiece {
  const OnboardingPiece({
    required this.id,
    required this.title,
    required this.composer,
    required this.stage,
    required this.description,
    required this.preview,
    required this.license,
  });

  final String id;
  final String title;
  final String composer;

  /// Human-readable starting tier, for example "Foundation · Stage 1".
  final String stage;
  final String description;

  /// A short original/synth motif for the preview button.
  final SoundSpec preview;
  final LicenseStatus license;
}

const onboardingPieces = <OnboardingPiece>[
  OnboardingPiece(
    id: 'greensleeves',
    title: 'Greensleeves',
    composer: 'Traditional English',
    stage: 'Foundation · Stage 1',
    description:
        'A gentle 6/8 melody for open strings and first-position notes.',
    license: LicenseStatus.publicDomain,
    preview: SoundSpec(
      bpm: 100,
      label: 'Greensleeves preview motif',
      events: [
        SoundEvent(midi: 57, startBeat: 0, durationBeats: 1.5),
        SoundEvent(midi: 60, startBeat: 1.5, durationBeats: 0.5),
        SoundEvent(midi: 62, startBeat: 2, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 3, durationBeats: 1.5),
        SoundEvent(midi: 65, startBeat: 4.5, durationBeats: 0.5),
        SoundEvent(midi: 64, startBeat: 5, durationBeats: 1),
        SoundEvent(midi: 62, startBeat: 6, durationBeats: 1.5),
        SoundEvent(midi: 59, startBeat: 7.5, durationBeats: 0.5),
        SoundEvent(midi: 55, startBeat: 8, durationBeats: 1),
        SoundEvent(midi: 57, startBeat: 9, durationBeats: 1.5),
        SoundEvent(midi: 59, startBeat: 10.5, durationBeats: 0.5),
        SoundEvent(midi: 60, startBeat: 11, durationBeats: 1),
      ],
    ),
  ),
  OnboardingPiece(
    id: 'ode-to-joy',
    title: 'Ode to Joy',
    composer: 'Ludwig van Beethoven',
    stage: 'Foundation · Stage 2',
    description:
        'A stepwise classical melody that builds confident note reading.',
    license: LicenseStatus.publicDomain,
    preview: SoundSpec(
      bpm: 128,
      label: 'Ode to Joy preview motif',
      events: [
        SoundEvent(midi: 64, startBeat: 0, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 1, durationBeats: 1),
        SoundEvent(midi: 65, startBeat: 2, durationBeats: 1),
        SoundEvent(midi: 67, startBeat: 3, durationBeats: 1),
        SoundEvent(midi: 67, startBeat: 4, durationBeats: 1),
        SoundEvent(midi: 65, startBeat: 5, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 6, durationBeats: 1),
        SoundEvent(midi: 62, startBeat: 7, durationBeats: 1),
        SoundEvent(midi: 60, startBeat: 8, durationBeats: 1),
        SoundEvent(midi: 60, startBeat: 9, durationBeats: 1),
        SoundEvent(midi: 62, startBeat: 10, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 11, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 12, durationBeats: 1.5),
        SoundEvent(midi: 62, startBeat: 13.5, durationBeats: 0.5),
        SoundEvent(midi: 62, startBeat: 14, durationBeats: 2),
      ],
    ),
  ),
  OnboardingPiece(
    id: 'amazing-grace',
    title: 'Amazing Grace',
    composer: 'Traditional American',
    stage: 'Foundation · Stage 2',
    description: 'A slow 3/4 tune for steady counting and long phrases.',
    license: LicenseStatus.publicDomain,
    preview: SoundSpec(
      bpm: 96,
      label: 'Amazing Grace preview motif',
      events: [
        SoundEvent(midi: 55, startBeat: 0, durationBeats: 2),
        SoundEvent(midi: 60, startBeat: 2, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 3, durationBeats: 2),
        SoundEvent(midi: 60, startBeat: 5, durationBeats: 1),
        SoundEvent(midi: 64, startBeat: 6, durationBeats: 2),
        SoundEvent(midi: 62, startBeat: 8, durationBeats: 1),
        SoundEvent(midi: 60, startBeat: 9, durationBeats: 2),
        SoundEvent(midi: 57, startBeat: 11, durationBeats: 1),
      ],
    ),
  ),
];
