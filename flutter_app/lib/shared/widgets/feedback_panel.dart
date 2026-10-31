import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'duo_button.dart';

class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.title,
    required this.subtitle,
    required this.onContinue,
    this.continueLabel = 'CONTINUE',
    this.detail,
  });

  final bool correct;
  final String title;
  final String subtitle;
  final String? detail;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final background = correct ? AppColors.greenSoft : AppColors.redSoft;
    final accent = correct ? AppColors.greenDark : AppColors.redDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    correct ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accent.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (detail != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  detail!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DuoButton(
              label: continueLabel,
              onPressed: onContinue,
              color: accent,
              height: 54,
            ),
          ],
        ),
      ),
    );
  }
}

class AnswerOption extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final (background, border, text) = switch (state) {
      AnswerOptionState.idle => (
        AppColors.background,
        AppColors.borderStrong,
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
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
            boxShadow: state == AnswerOptionState.idle
                ? const [
                    BoxShadow(
                      color: AppColors.border,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ),
      ),
    );
  }
}

enum AnswerOptionState { idle, correct, wrong, dimmed }
