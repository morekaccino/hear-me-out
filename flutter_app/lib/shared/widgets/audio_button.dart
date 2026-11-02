import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/music/sound_spec.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import 'duo_button.dart';

/// Replayable audio for ear-training questions.
class AudioPromptButton extends ConsumerWidget {
  const AudioPromptButton({
    super.key,
    required this.spec,
    this.label = 'PLAY SOUND',
  });

  final SoundSpec spec;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DuoButton(
      label: label,
      color: AppColors.blue,
      onPressed: () {
        unawaited(ref.read(audioEngineProvider).play(spec));
      },
    );
  }
}
