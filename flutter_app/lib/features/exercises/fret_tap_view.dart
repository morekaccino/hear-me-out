import 'package:flutter/material.dart';

import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../shared/theme/app_theme.dart';

/// Laid-out geometry for a first-position neck, shared by the painter and the
/// tap targets so a dot always sits exactly on its fret.
class FretboardGeometry {
  FretboardGeometry({required this.size, required this.maxFret});

  static const double labelWidth = 28;
  static const double openWidth = 34;
  static const double topPadding = 22;
  static const double bottomPadding = 12;
  static const double rightPadding = 10;

  final Size size;
  final int maxFret;

  double get boardLeft => labelWidth;
  double get boardRight => size.width - rightPadding;
  double get nutX => boardLeft + openWidth;
  double get fretWidth => (boardRight - nutX) / maxFret;
  double get boardTop => topPadding;
  double get boardBottom => size.height - bottomPadding;

  double yForString(int string) {
    final row = string - 1; // 1 = high e on top, 6 = low E on the bottom
    final gap = (boardBottom - boardTop) / 5;
    return boardTop + row * gap;
  }

  double xForFret(int fret) =>
      fret == 0 ? (boardLeft + nutX) / 2 : nutX + (fret - 0.5) * fretWidth;

  Rect cellFor(int string, int fret) {
    final gap = (boardBottom - boardTop) / 5;
    final left = fret == 0 ? boardLeft : nutX + (fret - 1) * fretWidth;
    final width = fret == 0 ? openWidth : fretWidth;
    return Rect.fromLTWH(left, yForString(string) - gap / 2, width, gap);
  }
}

/// A drawn neck. Pass [positions] to highlight them; pass [selected] to mark a
/// learner's tap that missed.
class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.maxFret,
    this.positions = const [],
    this.selected,
    this.hovered,
    this.height = 196,
  });

  final int maxFret;
  final List<GuitarPosition> positions;
  final ({int string, int fret})? selected;
  final ({int string, int fret})? hovered;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _FretboardPainter(
          maxFret: maxFret,
          positions: positions,
          selected: selected,
          hovered: hovered,
        ),
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
  const _FretboardPainter({
    required this.maxFret,
    required this.positions,
    required this.selected,
    required this.hovered,
  });

  final int maxFret;
  final List<GuitarPosition> positions;
  final ({int string, int fret})? selected;
  final ({int string, int fret})? hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = FretboardGeometry(size: size, maxFret: maxFret);
    final board = Rect.fromLTRB(
      geometry.boardLeft,
      geometry.boardTop - 6,
      geometry.boardRight,
      geometry.boardBottom + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(10)),
      Paint()..color = AppColors.fretboard,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(10)),
      Paint()
        ..color = AppColors.fretboardLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    _paintInlays(canvas, geometry);
    _paintFrets(canvas, geometry);
    _paintStrings(canvas, geometry);
    _paintLabels(canvas, geometry);
    _paintHover(canvas, geometry);
    _paintMarkers(canvas, geometry);
  }

  void _paintHover(Canvas canvas, FretboardGeometry geometry) {
    final cell = hovered;
    if (cell == null) return;
    final rect = geometry.cellFor(cell.string, cell.fret).deflate(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = AppColors.blueSoft,
    );
  }

  void _paintInlays(Canvas canvas, FretboardGeometry geometry) {
    final y = (geometry.yForString(3) + geometry.yForString(4)) / 2;
    final paint = Paint()..color = AppColors.fretboardInlay;
    for (final fret in [3, 5, 7, 9]) {
      if (fret > maxFret) continue;
      canvas.drawCircle(Offset(geometry.xForFret(fret), y), 4, paint);
    }
  }

  void _paintFrets(Canvas canvas, FretboardGeometry geometry) {
    final wire = Paint()
      ..color = AppColors.fretboardLine
      ..strokeWidth = 1.8;
    for (var fret = 1; fret <= maxFret; fret++) {
      final x = geometry.nutX + fret * geometry.fretWidth;
      canvas.drawLine(
        Offset(x, geometry.boardTop - 6),
        Offset(x, geometry.boardBottom + 6),
        wire,
      );
    }
    // The nut is heavier than a fret wire.
    canvas.drawLine(
      Offset(geometry.nutX, geometry.boardTop - 6),
      Offset(geometry.nutX, geometry.boardBottom + 6),
      Paint()
        ..color = AppColors.textMuted
        ..strokeWidth = 4,
    );
  }

  void _paintStrings(Canvas canvas, FretboardGeometry geometry) {
    for (var string = 1; string <= 6; string++) {
      final thickness = 3.0 - (string - 1) * 0.34;
      canvas.drawLine(
        Offset(geometry.boardLeft + 4, geometry.yForString(string)),
        Offset(geometry.boardRight - 2, geometry.yForString(string)),
        Paint()
          ..color = AppColors.textMuted
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintLabels(Canvas canvas, FretboardGeometry geometry) {
    const labels = ['e', 'B', 'G', 'D', 'A', 'E'];
    for (var string = 1; string <= 6; string++) {
      _text(
        canvas,
        labels[string - 1],
        Offset(4, geometry.yForString(string) - 7),
        AppColors.textMuted,
        11,
      );
    }
    for (var fret = 1; fret <= maxFret; fret++) {
      _text(
        canvas,
        '$fret',
        Offset(geometry.xForFret(fret) - 4, 2),
        AppColors.textLight,
        10,
      );
    }
  }

  void _paintMarkers(Canvas canvas, FretboardGeometry geometry) {
    for (final position in positions) {
      final center = Offset(
        geometry.xForFret(position.fret),
        geometry.yForString(position.string.number),
      );
      canvas.drawCircle(center, 11, Paint()..color = AppColors.green);
      canvas.drawCircle(
        center,
        11,
        Paint()
          ..color = AppColors.greenDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final selection = selected;
    if (selection == null) return;
    final hit = positions.any(
      (position) =>
          position.string.number == selection.string &&
          position.fret == selection.fret,
    );
    if (hit) return;

    final center = Offset(
      geometry.xForFret(selection.fret),
      geometry.yForString(selection.string),
    );
    final paint = Paint()
      ..color = AppColors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-7, -7),
      center.translate(7, 7),
      paint,
    );
    canvas.drawLine(
      center.translate(7, -7),
      center.translate(-7, 7),
      paint,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Nunito',
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_FretboardPainter oldDelegate) =>
      oldDelegate.maxFret != maxFret ||
      oldDelegate.selected != selected ||
      oldDelegate.hovered != hovered ||
      oldDelegate.positions.length != positions.length;
}

/// A tappable first-position neck.
class FretTapView extends StatefulWidget {
  const FretTapView({
    super.key,
    required this.maxFret,
    required this.onTapFret,
    this.positions = const [],
    this.selected,
    this.enabled = true,
    this.height = 196,
  });

  final int maxFret;
  final void Function(int string, int fret) onTapFret;
  final List<GuitarPosition> positions;
  final ({int string, int fret})? selected;
  final bool enabled;
  final double height;

  @override
  State<FretTapView> createState() => _FretTapViewState();
}

class _FretTapViewState extends State<FretTapView> {
  ({int string, int fret})? _hovered;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Guitar neck. Tap a string and fret.',
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, widget.height);
            final geometry = FretboardGeometry(
              size: size,
              maxFret: widget.maxFret,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: FretboardDiagram(
                    maxFret: widget.maxFret,
                    positions: widget.positions,
                    selected: widget.selected,
                    hovered: widget.enabled ? _hovered : null,
                    height: widget.height,
                  ),
                ),
                for (var string = 1; string <= 6; string++)
                  for (var fret = 0; fret <= widget.maxFret; fret++)
                    Positioned.fromRect(
                      rect: geometry.cellFor(string, fret),
                      child: MouseRegion(
                        cursor: widget.enabled
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        onEnter: (_) => setState(
                          () => _hovered = (string: string, fret: fret),
                        ),
                        onExit: (_) => setState(() => _hovered = null),
                        child: Semantics(
                          button: true,
                          label: 'String $string fret $fret',
                          child: GestureDetector(
                            key: ValueKey('fret-$string-$fret'),
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.enabled
                                ? () => widget.onTapFret(string, fret)
                                : null,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Convenience list of every position a written note can be played at.
List<GuitarPosition> positionsFor(Note note, int maxFret) =>
    Guitar.positionsFor(note, maxFret: maxFret);
