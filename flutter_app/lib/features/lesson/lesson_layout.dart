import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/settle_in.dart';

/// One focused column, like Duolingo's web lesson.
///
/// The lesson is deliberately narrow at every width: the question and its
/// answers stay in one reading order. Width beyond [columnWidth] is margin, not
/// extra panels.
///
/// - Compact (< 900): answers sit in a bottom thumb zone so they are reachable.
/// - Wide (>= 900): answers sit inline under the question, and only the
///   feedback bar is pinned to the bottom.
class LessonLayout extends StatelessWidget {
  const LessonLayout({
    super.key,
    required this.header,
    required this.question,
    required this.questionKey,
    this.answers,
    this.feedback,
  });

  final Widget header;
  final Widget question;

  /// Changes whenever the exercise changes, which replays the settle animation.
  final Object questionKey;

  /// Answer surface. Null means the question already contains it.
  final Widget? answers;

  /// When set, replaces the compact answers and pins to the bottom.
  final Widget? feedback;

  static const double wideBreakpoint = 900;
  static const double columnWidth = 640;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;

        final column = SettleIn(
          slideKey: questionKey,
          child: question,
        );

        final bottom = feedback ?? answers;
        Widget? bottomSlot;
        if (bottom != null) {
          bottomSlot = KeyedSubtree(
            key: ValueKey(feedback != null ? 'feedback' : 'answers'),
            child: feedback != null
                ? feedback!
                : _AnswersDock(
                    maxHeight: constraints.maxHeight * 0.62,
                    child: answers!,
                  ),
          );
        }

        return Column(
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 24 : 16,
                  wide ? 28 : 8,
                  wide ? 24 : 16,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: columnWidth),
                    child: column,
                  ),
                ),
              ),
            ),
            if (bottomSlot != null)
              SettleIn(
                slideKey: feedback != null ? 'feedback' : 'answers',
                offset: const Offset(0, 24),
                child: bottomSlot,
              ),
          ],
        );
      },
    );
  }
}

/// The bottom action area. Only this part of the lesson respects the iPhone
/// home indicator, so the rest of the page can use the full height.
class _AnswersDock extends StatelessWidget {
  const _AnswersDock({required this.child, required this.maxHeight});

  final Widget child;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LessonLayout.columnWidth,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
