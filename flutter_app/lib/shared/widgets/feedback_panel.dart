import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'duo_button.dart';
import 'hover_region.dart';

class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.title,
    required this.subtitle,
    required this.onContinue,
    this.continueLabel = 'CONTINUE',
    this.detail,
    this.indeterminate = false,
  }) : assert(
         !(correct && indeterminate),
         'An indeterminate attempt is not a correct answer.',
       );

  final bool correct;

  /// True when the app could not tell what happened. This uses the calm blue
  /// tone, never the red error tone.
  final bool indeterminate;
  final String title;
  final String subtitle;
  final String? detail;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final accent = indeterminate
        ? AppColors.blue
        : correct
        ? AppColors.green
        : AppColors.red;
    final accentDark = indeterminate
        ? AppColors.blueDark
        : correct
        ? AppColors.greenDark
        : AppColors.redDark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _mark(accentDark),
                            const SizedBox(width: 14),
                            Expanded(child: _text(accentDark)),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 200,
                              child: _PoppedButton(
                                label: continueLabel,
                                onPressed: onContinue,
                                accentDark: accentDark,
                                height: 52,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _mark(accentDark),
                                const SizedBox(width: 12),
                                Expanded(child: _text(accentDark)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _PoppedButton(
                              label: continueLabel,
                              onPressed: onContinue,
                              accentDark: accentDark,
                              height: 56,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mark(Color accentDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        indeterminate
            ? Icons.hearing_rounded
            : correct
            ? Icons.check_rounded
            : Icons.close_rounded,
        color: accentDark,
        size: 30,
      ),
    );
  }

  Widget _text(Color accentDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.3,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              detail!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PoppedButton extends StatelessWidget {
  const _PoppedButton({
    required this.label,
    required this.onPressed,
    required this.accentDark,
    required this.height,
  });

  final String label;
  final VoidCallback onPressed;
  final Color accentDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: DuoMotion.base,
      curve: DuoMotion.overshoot,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: DuoButton(
        label: label,
        onPressed: onPressed,
        color: Colors.white,
        textColor: accentDark,
        height: height,
      ),
    );
  }
}

class AnswerOption extends StatefulWidget {
  const AnswerOption({
    super.key,
    required this.label,
    required this.onTap,
    this.state = AnswerOptionState.idle,
  });

  final String label;
  final VoidCallback? onTap;
  final AnswerOptionState state;

  @override
  State<AnswerOption> createState() => _AnswerOptionState();
}

class _AnswerOptionState extends State<AnswerOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.onTap != null && widget.state == AnswerOptionState.idle;
    return HoverRegion(
      enabled: interactive,
      builder: (context, hovered) {
        final (background, border, text) = switch (widget.state) {
          AnswerOptionState.idle => (
            hovered ? AppColors.surface : AppColors.background,
            hovered ? AppColors.blue : AppColors.borderStrong,
            AppColors.text,
          ),
          AnswerOptionState.correct => (
            AppColors.greenSoft,
            AppColors.green,
            AppColors.greenDark,
          ),
          AnswerOptionState.wrong => (
            AppColors.redSoft,
            AppColors.red,
            AppColors.redDark,
          ),
          AnswerOptionState.dimmed => (
            AppColors.surface,
            AppColors.border,
            AppColors.textLight,
          ),
        };

        return Semantics(
          button: true,
          label: widget.label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: interactive
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapCancel: interactive
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: interactive
                ? (_) => setState(() => _pressed = false)
                : null,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: DuoMotion.fast,
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: DuoMotion.fast,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 2),
                  boxShadow: widget.state == AnswerOptionState.idle
                      ? [
                          BoxShadow(
                            color: hovered
                                ? AppColors.borderStrong
                                : AppColors.border,
                            offset: Offset(0, hovered ? 4 : 3),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum AnswerOptionState { idle, correct, wrong, dimmed }
