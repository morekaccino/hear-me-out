import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/music/curriculum.dart';
import '../../shared/theme/app_theme.dart';
import 'path_layout.dart';

/// A single lesson on the path.
///
/// The face is an ellipse with a hard 8 px base, a glossy top edge, and a
/// custom glyph. Current nodes breathe, completed nodes show a check, and
/// checkpoints switch to the reward gold palette.
class LessonNode extends StatefulWidget {
  const LessonNode({
    super.key,
    required this.lesson,
    required this.completed,
    required this.current,
    required this.unitNumber,
    required this.onTap,
    this.index = 0,
  });

  final LessonDefinition lesson;
  final bool completed;
  final bool current;
  final int unitNumber;
  final VoidCallback onTap;
  final int index;

  @override
  State<LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<LessonNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  bool _hovered = false;
  bool _pressed = false;
  bool _motionEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (enabled == _motionEnabled && _idle.isAnimating) return;
    _motionEnabled = enabled;
    if (enabled && widget.current) {
      _idle.repeat(reverse: true, count: 2);
    } else {
      _idle.stop();
      _idle.value = 0.35;
    }
  }

  @override
  void didUpdateWidget(covariant LessonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.current == oldWidget.current) return;
    if (widget.current && _motionEnabled) {
      _idle.repeat(reverse: true, count: 2);
    } else if (!widget.current) {
      _idle.stop();
      _idle.value = 0;
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = duoUnitColor(widget.unitNumber);
    final reached = widget.completed || widget.current;
    final palette = _NodePalette.resolve(
      reached: reached,
      current: widget.current,
      review: widget.lesson.isReview,
      unit: unit,
    );
    final glyph = _glyphFor();
    final iconSize = switch (glyph) {
      _NodeGlyph.star => 39.0,
      _NodeGlyph.check => 34.0,
      _NodeGlyph.trophy => 37.0,
      _NodeGlyph.note => 38.0,
    };
    final state = widget.completed
        ? 'completed'
        : widget.current
        ? 'current'
        : 'locked';
    final semanticLabel =
        '${widget.lesson.isReview ? 'Checkpoint' : 'Lesson'}: '
        'Unit ${widget.unitNumber}, ${widget.lesson.title}, $state';

    // No per-node entrance animation: nodes are rebuilt as they scroll into
    // the cache extent, and starting an opacity animation mid-scroll is what
    // made the path feel heavy on mobile Safari.
    return SizedBox(
      width: PathLayout.nodeSize,
      height: PathLayout.nodeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (widget.current) _halo(palette),
          _bobbing(_face(palette, glyph, iconSize, semanticLabel)),
          if (widget.current) _startBubble(unit.face, unit.dark),
        ],
      ),
    );
  }

  _NodeGlyph _glyphFor() {
    if (widget.lesson.isReview) return _NodeGlyph.trophy;
    if (widget.completed) return _NodeGlyph.check;
    if (widget.current) return _NodeGlyph.star;
    return _NodeGlyph.note;
  }

  Widget _halo(_NodePalette palette) {
    return Positioned(
      top: -10,
      left: -12,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _idle,
          builder: (context, child) {
            final t = _motionEnabled
                ? Curves.easeInOut.transform(_idle.value)
                : 0.45;
            // Scale only. Animating opacity would force a saveLayer every
            // frame on the halo, which is exactly what stutters on Safari.
            return Transform.scale(scale: 1 + 0.06 * t, child: child);
          },
          child: Container(
            width: PathLayout.nodeSize + 24,
            height: PathLayout.faceHeight + 20,
            decoration: BoxDecoration(
              color: palette.faceBottom.withValues(alpha: 0.14),
              borderRadius: BorderRadius.all(
                Radius.elliptical(
                  (PathLayout.nodeSize + 24) / 2,
                  (PathLayout.faceHeight + 20) / 2,
                ),
              ),
              border: Border.all(
                color: palette.faceBottom.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bobbing(Widget child) {
    if (!widget.current) return child;
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          _motionEnabled ? -2.5 * Curves.easeInOut.transform(_idle.value) : 0,
        ),
        child: child,
      ),
      child: child,
    );
  }

  Widget _face(
    _NodePalette palette,
    _NodeGlyph glyph,
    double iconSize,
    String semanticLabel,
  ) {
    final current = widget.current;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: current ? const ValueKey('current-lesson-node') : null,
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed
                ? 0.97
                : _hovered
                ? 1.02
                : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              key: ValueKey('lesson-face-${widget.lesson.id}'),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: PathLayout.nodeSize,
              height: PathLayout.faceHeight,
              transform: Matrix4.translationValues(
                0,
                _pressed
                    ? 3
                    : _hovered
                    ? -2
                    : 0,
                0,
              ),
              transformAlignment: Alignment.topCenter,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(
                    PathLayout.nodeSize / 2,
                    PathLayout.faceHeight / 2,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.faceTop, palette.faceBottom],
                ),
                border: Border.all(color: palette.rim, width: current ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: palette.base,
                    offset: Offset(0, _pressed ? 4 : 8),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppColors.isDark ? 0.22 : 0.08,
                    ),
                    offset: const Offset(0, 11),
                    // Hard shadow on purpose: a blurred shadow per node is
                    // re-rasterised on every scroll frame and is the main
                    // source of path jank on iOS Safari.
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 8,
                    left: 14,
                    child: Transform.rotate(
                      angle: -0.18,
                      child: Container(
                        width: 28,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: current ? 0.30 : 0.18,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.7,
                            end: 1,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: CustomPaint(
                        key: ValueKey(glyph),
                        isComplex: true,
                        size: Size.square(iconSize),
                        painter: _GlyphPainter(
                          glyph: glyph,
                          color: palette.glyph,
                          shadow: palette.glyphShadow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _startBubble(Color face, Color base) {
    return Positioned(
      top: -48,
      left: -40,
      right: -40,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _idle,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              _motionEnabled
                  ? -1.5 * Curves.easeInOut.transform(_idle.value)
                  : 0,
            ),
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DuoSpacing.md,
                  vertical: DuoSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: face,
                  borderRadius: BorderRadius.circular(DuoSpacing.sm),
                  boxShadow: [
                    BoxShadow(
                      color: base,
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
              CustomPaint(
                isComplex: true,
                size: const Size(16, 8),
                painter: _StartTailPainter(face),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NodeGlyph { note, star, check, trophy }

class _NodePalette {
  const _NodePalette({
    required this.faceTop,
    required this.faceBottom,
    required this.base,
    required this.rim,
    required this.glyph,
    this.glyphShadow = true,
  });

  final Color faceTop;
  final Color faceBottom;
  final Color base;
  final Color rim;
  final Color glyph;
  final bool glyphShadow;

  static _NodePalette resolve({
    required bool reached,
    required bool current,
    required bool review,
    required DuoUnitColor unit,
  }) {
    if (!reached) {
      return _NodePalette(
        faceTop: AppColors.surface,
        faceBottom: AppColors.border,
        base: AppColors.borderStrong,
        rim: AppColors.borderStrong,
        glyph: AppColors.textMuted,
        glyphShadow: false,
      );
    }
    if (review) {
      return _NodePalette(
        faceTop: const Color(0xFFFFD84D),
        faceBottom: AppColors.yellow,
        base: const Color(0xFFC68F00),
        rim: const Color(0xFFFFE58A),
        glyph: const Color(0xFF5C4300),
        glyphShadow: false,
      );
    }
    return _NodePalette(
      faceTop: Color.lerp(
        unit.face,
        Colors.white,
        AppColors.isDark ? 0.10 : 0.12,
      )!,
      faceBottom: unit.face,
      base: unit.dark,
      rim: Colors.white.withValues(alpha: current ? 0.95 : 0.72),
      glyph: Colors.white,
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.glyph,
    required this.color,
    required this.shadow,
  });

  final _NodeGlyph glyph;
  final Color color;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 40;
    canvas.save();
    canvas.scale(scale);
    if (shadow) {
      canvas.save();
      canvas.translate(0, 1.6);
      _paint(canvas, color.withValues(alpha: 0.28));
      canvas.restore();
    }
    _paint(canvas, color);
    canvas.restore();
  }

  void _paint(Canvas canvas, Color paintColor) {
    final fill = Paint()
      ..color = paintColor
      ..isAntiAlias = true;
    switch (glyph) {
      case _NodeGlyph.note:
        canvas.save();
        canvas.translate(10.8, 28.5);
        canvas.rotate(-0.28);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 16.5, height: 12),
          fill,
        );
        canvas.restore();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(19.2, 4, 4.2, 24.8),
            const Radius.circular(2.1),
          ),
          fill,
        );
        final flag = Path()
          ..moveTo(21.6, 5)
          ..cubicTo(30.5, 6.5, 32.2, 13.5, 28.8, 19)
          ..cubicTo(29.6, 13.8, 27.4, 11.4, 21.6, 12)
          ..close();
        canvas.drawPath(flag, fill);
      case _NodeGlyph.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final radius = i.isEven ? 17.5 : 7.4;
          final angle = -math.pi / 2 + i * math.pi / 5;
          final point = Offset(
            20 + math.cos(angle) * radius,
            20.5 + math.sin(angle) * radius,
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(
          path,
          Paint()
            ..color = paintColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeJoin = StrokeJoin.round,
        );
      case _NodeGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(8.5, 20.5)
            ..lineTo(16.5, 28.5)
            ..lineTo(31.5, 11.5),
          Paint()
            ..color = paintColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case _NodeGlyph.trophy:
        final cup = Path()
          ..moveTo(11, 7)
          ..lineTo(29, 7)
          ..lineTo(29, 16.5)
          ..cubicTo(29, 24, 25, 26, 20, 26)
          ..cubicTo(15, 26, 11, 24, 11, 16.5)
          ..close();
        canvas.drawPath(cup, fill);
        final handle = Paint()
          ..color = paintColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(9, 13), width: 9, height: 11),
          math.pi / 2,
          math.pi,
          false,
          handle,
        );
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(31, 13), width: 9, height: 11),
          -math.pi / 2,
          math.pi,
          false,
          handle,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 25, 4, 5.5),
            const Radius.circular(1.5),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12.5, 29.5, 15, 4.5),
            const Radius.circular(2),
          ),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.shadow != shadow;
}

class _StartTailPainter extends CustomPainter {
  const _StartTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StartTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The one chest per unit. It shares the path's hard-shadow depth language.
class ChestNode extends StatefulWidget {
  const ChestNode({
    super.key,
    required this.chest,
    required this.unlocked,
    required this.opened,
    required this.onTap,
  });

  final ChestDefinition chest;
  final bool unlocked;
  final bool opened;
  final VoidCallback? onTap;

  @override
  State<ChestNode> createState() => _ChestNodeState();
}

class _ChestNodeState extends State<ChestNode> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.opened
          ? 'Chest opened'
          : widget.unlocked
          ? 'Open chest'
          : 'Locked chest',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: widget.onTap == null
              ? null
              : () => setState(() => _pressed = false),
          onTapUp: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed
                ? 0.94
                : _hovered
                ? 1.04
                : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: CustomPaint(
              isComplex: true,
              size: const Size.square(PathLayout.chestSize),
              painter: _ChestPainter(
                opened: widget.opened,
                unlocked: widget.unlocked,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter({required this.opened, required this.unlocked});

  final bool opened;
  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final face = unlocked ? AppColors.yellow : AppColors.surface;
    final light = unlocked ? const Color(0xFFFFE066) : AppColors.background;
    final dark = unlocked ? AppColors.yellowDark : AppColors.borderStrong;
    final edge = unlocked ? const Color(0xFFB47A00) : AppColors.textLight;
    final bodyRect = Rect.fromLTWH(
      width * 0.15,
      height * 0.34,
      width * 0.7,
      height * 0.32,
    );
    final lidRect = Rect.fromLTWH(
      width * 0.12,
      height * 0.22,
      width * 0.76,
      height * 0.24,
    );

    // Two hard ellipses instead of MaskFilter.blur: the blur filter is very
    // expensive on CanvasKit and this chest is redrawn while scrolling.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.80),
        width: width * 0.74,
        height: height * 0.16,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.05),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.79),
        width: width * 0.58,
        height: height * 0.10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.09),
    );

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, face, dark],
      ).createShader(bodyRect);
    final lidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, face],
      ).createShader(lidRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bodyRect.shift(const Offset(0, 4)),
        Radius.circular(width * 0.08),
      ),
      Paint()..color = edge,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(width * 0.08)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        lidRect.shift(const Offset(0, 4)),
        Radius.circular(width * 0.09),
      ),
      Paint()..color = edge,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, Radius.circular(width * 0.09)),
      lidPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(width * 0.47, height * 0.23, width * 0.06, height * 0.43),
      Paint()..color = edge.withValues(alpha: 0.55),
    );

    if (opened) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.21,
            height * 0.36,
            width * 0.58,
            height * 0.18,
          ),
          Radius.circular(width * 0.04),
        ),
        Paint()..color = AppColors.background,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(width * 0.27, height * 0.4, width * 0.1, height * 0.13),
          Radius.circular(width * 0.025),
        ),
        Paint()..color = edge,
      );
      canvas.drawCircle(
        Offset(width * 0.32, height * 0.455),
        width * 0.018,
        Paint()..color = unlocked ? AppColors.yellow : AppColors.borderStrong,
      );
    }

    if (unlocked) {
      final glint = Path()
        ..moveTo(width * 0.24, height * 0.16)
        ..lineTo(width * 0.28, height * 0.22)
        ..lineTo(width * 0.24, height * 0.28)
        ..lineTo(width * 0.2, height * 0.22)
        ..close();
      canvas.drawPath(
        glint,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChestPainter oldDelegate) =>
      oldDelegate.opened != opened || oldDelegate.unlocked != unlocked;
}
