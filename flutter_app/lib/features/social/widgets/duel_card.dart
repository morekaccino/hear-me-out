import 'package:flutter/material.dart';

class DuelCard extends StatelessWidget {
  final VoidCallback onChallenge;
  const DuelCard({super.key, required this.onChallenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E293B))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Text('⚔️', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('Friend Duel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 6),
        const Text('Challenge a friend to identify 20 notes faster', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: onChallenge, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA855F7), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Challenge a Friend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}
