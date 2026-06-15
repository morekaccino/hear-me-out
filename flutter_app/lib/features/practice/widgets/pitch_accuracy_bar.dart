import 'package:flutter/material.dart';

class PitchAccuracyBar extends StatelessWidget {
  final double centsOffset;
  const PitchAccuracyBar({super.key, required this.centsOffset});

  @override
  Widget build(BuildContext context) {
    final absOffset = centsOffset.abs();
    final isInTune = absOffset < 5;
    final isSharp = centsOffset > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E293B))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          Text(isInTune ? 'In tune \u{2713}' : '${isSharp ? "+" : "-"}${absOffset.toStringAsFixed(1)}\u{00A2} ${isSharp ? "sharp" : "flat"}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isInTune ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(height: 5, child: Stack(children: [
            Container(color: const Color(0xFF1E293B)),
            Positioned(left: (0.45 * 200).clamp(0, 200), child: Container(width: 0.1 * 200, height: 5, color: const Color(0xFF10B981))),
          ])),
        ),
      ]),
    );
  }
}
