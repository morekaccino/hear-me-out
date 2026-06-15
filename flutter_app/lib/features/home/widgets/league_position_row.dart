import 'package:flutter/material.dart';

class LeaguePositionRow extends StatelessWidget {
  final String leagueName;
  final int rank;
  final int xp;

  const LeaguePositionRow({super.key, required this.leagueName, required this.rank, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(leagueName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$xp XP', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ])),
        Text('#$rank', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF06B6D4))),
      ]),
    );
  }
}
