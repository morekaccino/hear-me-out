/// The technique strand is a self-check, not a measurement.
///
/// The microphone can hear notes; it cannot see a thumb, a wrist, or a shift.
/// These models therefore describe what the learner should observe and rate,
/// and they never feed the FSRS scheduler or claim automated hand assessment.
enum TechniqueArea {
  setup,
  leftHand,
  rightHand,
  damping,
  shifts,
  slurs,
  performance,
}

extension TechniqueAreaLabel on TechniqueArea {
  String get label => switch (this) {
    TechniqueArea.setup => 'Setup and posture',
    TechniqueArea.leftHand => 'Left hand',
    TechniqueArea.rightHand => 'Right hand',
    TechniqueArea.damping => 'Damping',
    TechniqueArea.shifts => 'Shifts',
    TechniqueArea.slurs => 'Slurs',
    TechniqueArea.performance => 'Performance',
  };
}

/// The stop rule shown with every checklist. It is not medical advice.
const String techniquePainWarning =
    'Stop if you feel pain, numbness, or tingling. Rest, and ask a teacher or '
    'health professional before you continue. This app cannot assess your '
    'hands and does not replace a teacher.';

/// One stage's technique focus: three observable checks, three self-rating
/// rows, a 60-second drill, and a demo script.
class TechniqueChecklist {
  const TechniqueChecklist({
    required this.stage,
    required this.title,
    required this.area,
    required this.items,
    required this.rubric,
    required this.drill,
    required this.demo,
    required this.painWarning,
  }) : assert(stage > 0);

  final int stage;
  final String title;
  final TechniqueArea area;

  /// Exactly three observable checklist items.
  final List<String> items;

  /// Exactly three self-rating rows.
  final List<String> rubric;

  final TechniqueDrill drill;
  final TechniqueDemo demo;
  final String painWarning;
}

/// A short drill that fits the technique slot of the 5-minute session.
class TechniqueDrill {
  const TechniqueDrill({
    required this.id,
    required this.title,
    required this.seconds,
    required this.instructions,
    required this.tempoBpm,
    required this.repetitions,
  }) : assert(seconds == 60),
       assert(tempoBpm > 0),
       assert(repetitions > 0);

  final String id;
  final String title;

  /// 60 for every V1 drill.
  final int seconds;

  final String instructions;
  final int tempoBpm;
  final int repetitions;
}

/// A written demo script. The video is produced separately; until it exists
/// [videoAsset] stays null and the UI says so.
class TechniqueDemo {
  const TechniqueDemo({
    required this.title,
    required this.script,
    this.videoAsset,
  });

  final String title;

  /// Three to five short cues.
  final List<String> script;

  /// Null until a real video asset is added to the repository.
  final String? videoAsset;

  bool get hasVideo => videoAsset != null;
}
