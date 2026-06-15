import 'package:flutter/material.dart';

class StreakRing extends StatelessWidget {
  final int streakDays;
  final double size;

  const StreakRing({super.key, required this.streakDays, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final progress = (streakDays % 7) / 7.0;
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size, height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          Container(
            width: size * 0.72, height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF14141F),
              border: Border.all(color: const Color(0xFF1E293B), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B), height: 1,
                  ),
                ),
                const Text(
                  'day streak',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
