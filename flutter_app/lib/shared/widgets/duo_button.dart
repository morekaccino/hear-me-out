import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../audio/sound_service.dart';
import '../theme/app_theme.dart';

class DuoButton extends ConsumerStatefulWidget {
  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.green,
    this.textColor = Colors.white,
    this.icon,
    this.expanded = true,
    this.height = 56,
    this.fontSize = 16,
    this.sound,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool expanded;
  final double height;
  final double fontSize;
  final Sfx? sound;

  @override
  ConsumerState<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends ConsumerState<DuoButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final color = _enabled ? widget.color : AppColors.border;
    final dark = Color.lerp(color, Colors.black, 0.18)!;
    final foreground = _enabled ? widget.textColor : AppColors.textLight;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                unawaited(
                  ref
                      .read(soundServiceProvider)
                      .play(widget.sound ?? Sfx.uiTapPrimary),
                );
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
          height: widget.height,
          width: widget.expanded ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 20 : 26),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(color: dark, width: _pressed ? 2 : 4),
            ),
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: foreground, size: widget.fontSize + 5),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutlineDuoButton extends ConsumerWidget {
  const OutlineDuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.blue,
    this.expanded = true,
    this.sound,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool expanded;
  final Sfx? sound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onPressed == null
          ? null
          : () {
              unawaited(
                ref
                    .read(soundServiceProvider)
                    .play(sound ?? Sfx.uiTapSecondary),
              );
              onPressed?.call();
            },
      child: Container(
        height: 52,
        width: expanded ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStrong, width: 2),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
