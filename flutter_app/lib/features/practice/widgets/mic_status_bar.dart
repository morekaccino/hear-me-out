import 'package:flutter/material.dart';

class MicStatusBar extends StatelessWidget {
  final bool isListening;
  final String latestNote;
  const MicStatusBar({super.key, required this.isListening, this.latestNote = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1E293B))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isListening ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        ),
        const SizedBox(width: 10),
        Text(isListening ? 'Listening... \u{1F3A4}' : 'Mic off', style: TextStyle(fontSize: 12, color: isListening ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w500)),
        if (latestNote.isNotEmpty) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(latestNote, style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }
}
