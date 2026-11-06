import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/technique/technique_content.dart';
import '../../core/learning/technique.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';

/// A per-stage technique self-check with a 60-second drill.
///
/// Nothing on this screen is scored, persisted, or fed to the skill scheduler.
/// Checklist ticks and rubric ratings last only while the screen is open.
class TechniqueScreen extends StatefulWidget {
  const TechniqueScreen({super.key});

  @override
  State<TechniqueScreen> createState() => _TechniqueScreenState();
}

class _TechniqueScreenState extends State<TechniqueScreen> {
  int _stage = allTechniqueChecklists.first.stage;
  int _remainingSeconds = allTechniqueChecklists.first.drill.seconds;
  bool _drillComplete = false;
  Timer? _drillTimer;

  final Map<int, Set<int>> _checked = {
    for (final checklist in allTechniqueChecklists) checklist.stage: <int>{},
  };
  final Map<int, List<int>> _ratings = {
    for (final checklist in allTechniqueChecklists)
      checklist.stage: List<int>.filled(3, 0),
  };

  TechniqueChecklist get _checklist => techniqueForStage(_stage)!;

  Set<int> get _checkedForStage => _checked[_stage]!;

  List<int> get _ratingsForStage => _ratings[_stage]!;

  @override
  void dispose() {
    _drillTimer?.cancel();
    _drillTimer = null;
    super.dispose();
  }

  void _selectStage(int stage) {
    if (stage == _stage) return;
    final next = techniqueForStage(stage);
    if (next == null) return;
    _cancelDrill();
    setState(() {
      _stage = stage;
      _remainingSeconds = next.drill.seconds;
      _drillComplete = false;
    });
  }

  void _toggleItem(int index) {
    final checked = _checkedForStage;
    setState(() {
      if (!checked.remove(index)) checked.add(index);
    });
  }

  void _rateItem(int index, int rating) {
    final ratings = _ratingsForStage;
    setState(() {
      ratings[index] = ratings[index] == rating ? 0 : rating;
    });
  }

  void _toggleDrill() {
    if (_drillTimer != null) {
      _stopDrill();
      return;
    }
    setState(() {
      _remainingSeconds = _checklist.drill.seconds;
      _drillComplete = false;
    });
    _drillTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds <= 1) {
          _remainingSeconds = 0;
          _drillComplete = true;
          timer.cancel();
          _drillTimer = null;
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _stopDrill() {
    _cancelDrill();
    setState(() {
      _remainingSeconds = _checklist.drill.seconds;
      _drillComplete = false;
    });
  }

  void _cancelDrill() {
    _drillTimer?.cancel();
    _drillTimer = null;
  }

  String get _timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final checklist = _checklist;
    final running = _drillTimer != null;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Header(stage: _stage, onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 12),
              Text(
                'The mic cannot see your hands. Use this checklist with a '
                'mirror or a teacher. It is not automated hand assessment.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              _PainWarning(text: checklist.painWarning),
              const SizedBox(height: 16),
              _StagePicker(selected: _stage, onSelected: _selectStage),
              const SizedBox(height: 16),
              _ChecklistCard(
                checklist: checklist,
                checked: _checkedForStage,
                onToggle: _toggleItem,
              ),
              const SizedBox(height: 16),
              _RubricCard(
                checklist: checklist,
                ratings: _ratingsForStage,
                onRate: _rateItem,
              ),
              const SizedBox(height: 16),
              _DrillCard(
                checklist: checklist,
                remainingSeconds: _remainingSeconds,
                timerText: _timerText,
                running: running,
                complete: _drillComplete,
                onToggle: _toggleDrill,
              ),
              const SizedBox(height: 16),
              _DemoCard(demo: checklist.demo),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stage, required this.onBack});

  final int stage;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DuoTappable(
          key: const ValueKey('technique-back'),
          onTap: onBack,
          child: Semantics(
            button: true,
            label: 'Back to practice',
            excludeSemantics: true,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Technique',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              Text(
                'Stage $stage self-check',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PainWarning extends StatelessWidget {
  const _PainWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: AppColors.redSoft,
      borderColor: AppColors.red,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.red,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stop if it hurts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.redDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.text,
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

class _StagePicker extends StatelessWidget {
  const _StagePicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stage focus',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final checklist in allTechniqueChecklists)
              DuoTappable(
                key: ValueKey('technique-stage-${checklist.stage}'),
                onTap: () => onSelected(checklist.stage),
                child: Semantics(
                  label: 'Stage ${checklist.stage}: ${checklist.title}',
                  selected: checklist.stage == selected,
                  button: true,
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: checklist.stage == selected
                          ? AppColors.teal
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: checklist.stage == selected
                            ? AppColors.tealDark
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Stage ${checklist.stage}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: checklist.stage == selected
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'V1 stages. Missing stage numbers have no technique content yet.',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.checklist,
    required this.checked,
    required this.onToggle,
  });

  final TechniqueChecklist checklist;
  final Set<int> checked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final done = checked.length == checklist.items.length;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AreaBadge(area: checklist.area),
              const Spacer(),
              Text(
                '${checked.length}/${checklist.items.length} checked',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: done ? AppColors.greenDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            checklist.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Check what you notice. This is not a pass or fail test.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < checklist.items.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == checklist.items.length - 1 ? 0 : 8,
              ),
              child: _CheckRow(
                stage: checklist.stage,
                index: index,
                text: checklist.items[index],
                checked: checked.contains(index),
                onTap: () => onToggle(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.stage,
    required this.index,
    required this.text,
    required this.checked,
    required this.onTap,
  });

  final int stage;
  final int index;
  final String text;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuoTappable(
      key: ValueKey('technique-item-$stage-$index'),
      onTap: onTap,
      child: Semantics(
        button: true,
        checked: checked,
        label: text,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: checked ? AppColors.greenSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: checked ? AppColors.greenDark : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: ValueKey('technique-check-$stage-$index'),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked
                        ? AppColors.greenDark
                        : AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RubricCard extends StatelessWidget {
  const _RubricCard({
    required this.checklist,
    required this.ratings,
    required this.onRate,
  });

  final TechniqueChecklist checklist;
  final List<int> ratings;
  final void Function(int index, int rating) onRate;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review_rounded, size: 19, color: AppColors.teal),
              SizedBox(width: 8),
              Text(
                'Self-rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '1 not yet · 2 getting there · 3 solid',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < checklist.rubric.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == checklist.rubric.length - 1 ? 0 : 8,
              ),
              child: _RubricRow(
                stage: checklist.stage,
                index: index,
                text: checklist.rubric[index],
                rating: ratings[index],
                onRate: (value) => onRate(index, value),
              ),
            ),
        ],
      ),
    );
  }
}

class _RubricRow extends StatelessWidget {
  const _RubricRow({
    required this.stage,
    required this.index,
    required this.text,
    required this.rating,
    required this.onRate,
  });

  final int stage;
  final int index;
  final String text;
  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          for (var value = 1; value <= 3; value++)
            Padding(
              padding: EdgeInsets.only(left: value == 1 ? 0 : 5),
              child: DuoTappable(
                key: ValueKey('technique-rating-$stage-$index-$value'),
                onTap: () => onRate(value),
                child: Semantics(
                  label: 'Rate "$text" as $value of 3',
                  selected: rating == value,
                  button: true,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rating == value
                              ? AppColors.teal
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: rating == value
                                ? AppColors.tealDark
                                : AppColors.borderStrong,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: rating == value
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrillCard extends StatelessWidget {
  const _DrillCard({
    required this.checklist,
    required this.remainingSeconds,
    required this.timerText,
    required this.running,
    required this.complete,
    required this.onToggle,
  });

  final TechniqueChecklist checklist;
  final int remainingSeconds;
  final String timerText;
  final bool running;
  final bool complete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final drill = checklist.drill;
    final progress = 1 - (remainingSeconds / drill.seconds);
    return SectionCard(
      borderColor: AppColors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 20,
                color: AppColors.blueDark,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '60-second drill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '60 SEC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            drill.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            drill.instructions,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(label: '${drill.tempoBpm} BPM'),
              _StatChip(label: '${drill.repetitions} reps'),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Drill timer',
            value: timerText,
            child: Center(
              child: Text(
                timerText,
                key: const ValueKey('technique-drill-time'),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: running ? AppColors.blueDark : AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          LessonProgressBar(
            value: progress.clamp(0.0, 1.0),
            color: AppColors.blue,
            height: 10,
          ),
          if (complete) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.greenDark,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Drill complete. Shake out your hands.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          DuoButton(
            key: const ValueKey('technique-drill-toggle'),
            label: running ? 'STOP DRILL' : 'START 60-SECOND DRILL',
            onPressed: onToggle,
            icon: running ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: running ? AppColors.textMuted : AppColors.blue,
            height: 48,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.demo});

  final TechniqueDemo demo;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline_rounded,
                size: 20,
                color: AppColors.purpleDark,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Demo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (!demo.hasVideo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.yellowDark, width: 1.5),
                  ),
                  child: const Text(
                    'VIDEO PENDING',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.yellowDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            demo.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (!demo.hasVideo)
            Container(
              key: const ValueKey('technique-demo-pending'),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam_off_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo video pending. Follow the cues below with a mirror '
                      'until the video is ready.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          for (var index = 0; index < demo.script.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == demo.script.length - 1 ? 0 : 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purpleSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purpleDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      demo.script[index],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: AppColors.text,
                      ),
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

class _AreaBadge extends StatelessWidget {
  const _AreaBadge({required this.area});

  final TechniqueArea area;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        area.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: AppColors.tealDark,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
