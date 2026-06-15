import 'package:flutter/material.dart';

class DailyChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeLeft;
  final String rank;
  final VoidCallback onTap;

  const DailyChallengeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timeLeft,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('⚡ DAILY CHALLENGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B), letterSpacing: 1)),
                ),
                const Spacer(),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(timeLeft, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('🏆 $rank', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
