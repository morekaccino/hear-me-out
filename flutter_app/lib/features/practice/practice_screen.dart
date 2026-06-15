import 'package:flutter/material.dart';
import 'widgets/mode_chips.dart';
import 'widgets/music_card.dart';
import 'widgets/mic_status_bar.dart';
import 'widgets/pitch_accuracy_bar.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String _selectedMode = 'Notes';
  String? _currentNote = 'C4';
  bool _isListening = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Practice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ModeChips(selectedMode: _selectedMode, onModeSelected: (mode) => setState(() => _selectedMode = mode)),
            const SizedBox(height: 20),
            MusicCard(noteValue: _currentNote),
            const SizedBox(height: 12),
            MicStatusBar(isListening: _isListening, latestNote: 'C4'),
            const SizedBox(height: 10),
            const PitchAccuracyBar(centsOffset: 4.2),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _SessionStat(icon: Icons.check_circle, value: '4', color: Color(0xFF10B981)),
                _SessionStat(icon: Icons.cancel, value: '1', color: Color(0xFFEF4444)),
                _SessionStat(icon: Icons.local_fire_department, value: '3', color: Color(0xFFF59E0B)),
                _SessionStat(icon: Icons.speed, value: '80%', color: Color(0xFF06B6D4)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _SessionStat({required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}
