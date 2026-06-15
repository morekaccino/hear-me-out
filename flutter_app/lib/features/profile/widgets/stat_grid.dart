import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: const [
        _StatItem(value: '21', label: 'Notes\nMastered', color: Color(0xFFA855F7)),
        _StatItem(value: '94%', label: 'Accuracy', color: Color(0xFF06B6D4)),
        _StatItem(value: '7', label: 'Day\nStreak', color: Color(0xFFF59E0B)),
        _StatItem(value: '2.1k', label: 'Total\nXP', color: Color(0xFF10B981)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.2)),
      ]),
    );
  }
}
