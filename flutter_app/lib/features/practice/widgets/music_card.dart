import 'package:flutter/material.dart';
import '../../../core/notation/note_renderer.dart';

class MusicCard extends StatelessWidget {
  final String? noteValue;
  const MusicCard({super.key, this.noteValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF161625)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.08), blurRadius: 30, offset: Offset.zero)],
      ),
      child: Column(children: [
        const Text('Play this note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        NoteRenderer(noteValue: noteValue, height: 120),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.volume_up, size: 16, color: Color(0xFF06B6D4)),
          label: const Text('Listen to reference', style: TextStyle(fontSize: 11, color: Color(0xFF06B6D4))),
        ),
      ]),
    );
  }
}
