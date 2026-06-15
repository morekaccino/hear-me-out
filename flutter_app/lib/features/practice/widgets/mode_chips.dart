import 'package:flutter/material.dart';

class ModeChips extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeSelected;
  static const modes = ['Notes', 'Intervals', 'Chords', 'Rhythm'];

  const ModeChips({super.key, required this.selectedMode, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 4, children: modes.map((mode) {
      final isActive = mode == selectedMode;
      return GestureDetector(
        onTap: () => onModeSelected(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFA855F7) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? const Color(0xFFA855F7) : const Color(0xFF1E293B)),
          ),
          child: Text(mode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF94A3B8))),
        ),
      );
    }).toList());
  }
}
