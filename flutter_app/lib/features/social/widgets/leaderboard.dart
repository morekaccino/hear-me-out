import 'package:flutter/material.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String instrument;
  final int xp;
  final bool isCurrentUser;
  const LeaderboardEntry({required this.rank, required this.name, required this.instrument, required this.xp, this.isCurrentUser = false});
}

class Leaderboard extends StatelessWidget {
  final String leagueName;
  final String endsIn;
  final List<LeaderboardEntry> entries;
  const Leaderboard({super.key, required this.leagueName, required this.endsIn, required this.entries});

  Color _rankColor(int rank) {
    return switch (rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFD97706),
      _ => const Color(0xFF94A3B8),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E293B))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(leagueName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('Ends in $endsIn', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ]),
        ),
        ...entries.map((entry) => _LeaderboardRow(entry: entry, rankColor: _rankColor(entry.rank))),
      ]),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color rankColor;
  const _LeaderboardRow({required this.entry, required this.rankColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? const Color(0xFFA855F7).withValues(alpha: 0.08) : null,
        border: const Border(top: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Row(children: [
        SizedBox(width: 24, child: Text('${entry.rank}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: rankColor))),
        const SizedBox(width: 10),
        Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFA855F7).withValues(alpha: 0.2)), alignment: Alignment.center, child: Text(entry.instrument == 'guitar' ? '🎸' : entry.instrument == 'piano' ? '🎹' : '🎵', style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 10),
        Expanded(child: Text(entry.isCurrentUser ? 'You' : entry.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: entry.isCurrentUser ? const Color(0xFFA855F7) : null))),
        Text('${entry.xp} XP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFA855F7))),
      ]),
    );
  }
}
