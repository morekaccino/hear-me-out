import 'package:flutter/material.dart';
import 'widgets/streak_ring.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/league_position_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Good morning 👋', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
            const SizedBox(height: 2),
            const Text('Musician', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(children: [
              const StreakRing(streakDays: 7),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Level 4', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('420 / 500 XP', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: 0.70, backgroundColor: const Color(0xFF1E293B), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)), minHeight: 4),
                ),
              ])),
            ]),
            const SizedBox(height: 20),
            DailyChallengeCard(title: 'Speed Round: C Major', subtitle: 'Identify 10 notes in 60s • +50 XP bonus', timeLeft: '14h left', rank: 'Top 12%', onTap: () {}),
            const SizedBox(height: 14),
            const LeaguePositionRow(leagueName: 'Sapphire League', rank: 4, xp: 2120),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA855F7), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('▶ Continue Learning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _QuickStat(value: '12', label: 'Mastered', color: const Color(0xFFA855F7)),
              _QuickStat(value: '5', label: 'Learning', color: const Color(0xFF06B6D4)),
              _QuickStat(value: '94%', label: 'Accuracy', color: const Color(0xFF10B981)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _QuickStat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
    ]);
  }
}
