import '../../core/learning/technique.dart';

/// The V1 technique strand. Stages 4, 6, 7, and 8 have no V1 content yet.
///
/// Each stage has one focus, exactly three observable checks, exactly three
/// self-rating rows, one 60-second drill, and a demo script. The scripts are
/// written; the videos are still a content-production task, so every
/// [TechniqueDemo.videoAsset] is null.
const List<TechniqueChecklist> allTechniqueChecklists = [
  TechniqueChecklist(
    stage: 1,
    title: 'Setup, tuning, and posture',
    area: TechniqueArea.setup,
    items: [
      'Tune each string until the tuner reads in tune before you start.',
      'Sit with both feet supported and the guitar on one leg, or use a strap.',
      'Angle the neck up about 45° so the headstock is near shoulder height.',
    ],
    rubric: [
      'I tuned every string before the first note.',
      'My shoulders and jaw stayed loose for the whole drill.',
      'The guitar stayed steady without my fretting hand holding it up.',
    ],
    drill: TechniqueDrill(
      id: 'open-string-pulse',
      title: 'Open-string pulse',
      seconds: 60,
      instructions:
          'Play each open string four times in time. Say the string name '
          'before each group, then check that the guitar has not moved.',
      tempoBpm: 60,
      repetitions: 6,
    ),
    demo: TechniqueDemo(
      title: 'Set up in sixty seconds',
      script: [
        'Show the tuner reading in tune for all six strings.',
        'Sit with both feet flat and rest the guitar on the same-side leg.',
        'Lift the headstock to shoulder height and check the shoulders.',
        'Play one open string, then freeze to show the guitar is balanced.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 2,
    title: 'Left-hand shape',
    area: TechniqueArea.leftHand,
    items: [
      'Place the thumb behind the neck, roughly opposite the index finger.',
      'Curl the fingers so each fingertip lands just behind its fret.',
      'Keep the wrist straight, with a small gap under the palm.',
    ],
    rubric: [
      'My thumb stayed behind the neck for the whole drill.',
      'My fingertips pressed the strings, not the flat finger pads.',
      'My wrist stayed straight and my hand did not cramp.',
    ],
    drill: TechniqueDrill(
      id: 'finger-arch-taps',
      title: 'Finger arch taps',
      seconds: 60,
      instructions:
          'On the first string, press frets 1-2-3-4 with one finger at a time. '
          'Keep the thumb still and land each fingertip just behind the fret.',
      tempoBpm: 50,
      repetitions: 6,
    ),
    demo: TechniqueDemo(
      title: 'Build the left-hand arch',
      script: [
        'Hold the neck up and show the thumb behind it.',
        'Tap each fingertip on a string just behind a fret.',
        'Show the straight wrist and the gap under the palm.',
        'Play frets 1-2-3-4 slowly with the thumb still.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 3,
    title: 'Right-hand stroke and alternation',
    area: TechniqueArea.rightHand,
    items: [
      'Rest the forearm on the guitar body without raising the shoulder.',
      'Play rest strokes with a loose wrist and let the finger follow through.',
      'Alternate index and middle fingers for even free strokes.',
    ],
    rubric: [
      'My picking hand stayed loose for the whole drill.',
      'Each rest stroke landed on the next string.',
      'My alternating fingers sounded even.',
    ],
    drill: TechniqueDrill(
      id: 'alternating-open-strings',
      title: 'Alternating open strings',
      seconds: 60,
      instructions:
          'Play the first string sixteen times at a steady pulse, alternating '
          'index and middle. Repeat on the second string without speeding up.',
      tempoBpm: 60,
      repetitions: 8,
    ),
    demo: TechniqueDemo(
      title: 'Rest, free, and alternate',
      script: [
        'Show the forearm resting on the guitar with a low shoulder.',
        'Play two rest strokes and point to the next string.',
        'Play four free strokes with index and middle alternating.',
        'Repeat the alternation without lifting the wrist.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 5,
    title: 'Damping unwanted strings',
    area: TechniqueArea.damping,
    items: [
      'Rest the side of the picking hand on the strings you are not playing.',
      'Lift a fretting finger only after the next note has sounded.',
      'Stop a ringing note by relaxing the hand, not by gripping the neck.',
    ],
    rubric: [
      'Unplayed strings stayed quiet for the whole drill.',
      'No note rang past its written value.',
      'My fretting hand stayed loose while muting.',
    ],
    drill: TechniqueDrill(
      id: 'two-string-mute',
      title: 'Two-string mute check',
      seconds: 60,
      instructions:
          'Play a note on the third string, then mute it with the picking hand '
          'before it rings past one beat. Repeat on the fourth string and '
          'listen for any open string that keeps ringing.',
      tempoBpm: 50,
      repetitions: 6,
    ),
    demo: TechniqueDemo(
      title: 'Quiet the strings you are not playing',
      script: [
        'Show the picking hand resting lightly across the unused strings.',
        'Play one note and mute it after one beat.',
        'Lift a fretting finger only after the next note sounds.',
        'Pause and point out that no open string is ringing.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 9,
    title: 'Silent position shifts',
    area: TechniqueArea.shifts,
    items: [
      'Lead the shift from the shoulder and keep the thumb behind the neck.',
      'Move on a rest or a held note so the shift is not heard.',
      'Land the target finger first, then place the others.',
    ],
    rubric: [
      'The shift stayed silent.',
      'My thumb did not leave the back of the neck.',
      'I landed the target finger without hunting for it.',
    ],
    drill: TechniqueDrill(
      id: 'silent-shift-ladder',
      title: 'Silent shift ladder',
      seconds: 60,
      instructions:
          'Play frets 1-2-3-4 in first position, then shift to fifth position '
          'and play frets 5-6-7-8. Move during the last note so the shift makes '
          'no sound, then repeat back to first position.',
      tempoBpm: 50,
      repetitions: 4,
    ),
    demo: TechniqueDemo(
      title: 'Shift without a squeak',
      script: [
        'Play a four-note group in first position.',
        'Shift to fifth position while the last note still rings.',
        'Show the thumb staying behind the neck.',
        'Land the index finger first and place the rest.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 10,
    title: 'Clean hammer-ons and pull-offs',
    area: TechniqueArea.slurs,
    items: [
      'Hammer on with a quick, firm fingertip and keep the hand close.',
      'Pull off with a sideways flick that keeps the string ringing.',
      'Keep the left thumb quiet while the fingers do the work.',
    ],
    rubric: [
      'Hammer-ons sounded clear, not thuddy.',
      'Pull-offs kept the same volume as the first note.',
      'My hand stayed quiet between slurs.',
    ],
    drill: TechniqueDrill(
      id: 'slur-pairs',
      title: 'Slur pairs',
      seconds: 60,
      instructions:
          'Play a hammer-on from fret 1 to fret 3, then a pull-off back to '
          'fret 1. Repeat four times, then move the pair to the next string.',
      tempoBpm: 60,
      repetitions: 8,
    ),
    demo: TechniqueDemo(
      title: 'Hammer-on and pull-off',
      script: [
        'Fret the first note and strike it once.',
        'Hammer the next fingertip down without plucking again.',
        'Flick sideways to pull off and keep the string ringing.',
        'Show the thumb staying still behind the neck.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 11,
    title: 'Exam-style run-through',
    area: TechniqueArea.performance,
    items: [
      'Tune, warm up, and check posture before the first run-through.',
      'Play the prepared scale and sight-reading example slowly, then at tempo.',
      'Stop at a mistake, fix one thing, and restart from the bar before it.',
    ],
    rubric: [
      'I completed one full run-through without stopping.',
      'I kept a steady pulse under pressure.',
      'I recovered from a mistake without restarting the whole piece.',
    ],
    drill: TechniqueDrill(
      id: 'run-through-reset',
      title: 'Run-through reset',
      seconds: 60,
      instructions:
          'Play one prepared piece or study from start to finish. If you stop, '
          'restart from the bar before the mistake, not the beginning. Keep the '
          'pulse going and finish the take.',
      tempoBpm: 60,
      repetitions: 1,
    ),
    demo: TechniqueDemo(
      title: 'Practice an exam-style run-through',
      script: [
        'Tune and warm up before the first take.',
        'Play a slow run-through with no stops.',
        'Make one correction, then restart from the bar before it.',
        'Finish the take and note one thing that improved.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
  TechniqueChecklist(
    stage: 12,
    title: 'Performance and recording',
    area: TechniqueArea.performance,
    items: [
      'Warm up for two minutes before the first take.',
      'Set the recording level and record one silent test take.',
      'Play one full run-through with no stops, then listen back once.',
    ],
    rubric: [
      'I warmed up before recording.',
      'My shoulders, jaw, and hands stayed relaxed.',
      'I kept going after a mistake.',
    ],
    drill: TechniqueDrill(
      id: 'one-take-run-through',
      title: 'One-take run-through',
      seconds: 60,
      instructions:
          'Record one full run-through at performance tempo. Keep playing '
          'through mistakes and stop only at the end. Listen back once and '
          'write down one thing to keep and one thing to change.',
      tempoBpm: 60,
      repetitions: 1,
    ),
    demo: TechniqueDemo(
      title: 'Record a calm one-take',
      script: [
        'Show the two-minute warm-up and a relaxed posture check.',
        'Set the level with a silent test take.',
        'Play one run-through without stopping.',
        'Listen back once and name one next step.',
      ],
    ),
    painWarning: techniquePainWarning,
  ),
];

/// The checklist for [stage], or null when V1 has no technique content there.
TechniqueChecklist? techniqueForStage(int stage) {
  for (final checklist in allTechniqueChecklists) {
    if (checklist.stage == stage) return checklist;
  }
  return null;
}
