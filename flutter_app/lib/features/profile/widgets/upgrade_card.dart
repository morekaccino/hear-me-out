import 'package:flutter/material.dart';

class UpgradeCard extends StatelessWidget {
  final VoidCallback onUpgrade;
  const UpgradeCard({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withValues(alpha: 0.1), const Color(0xFFEF4444).withValues(alpha: 0.1)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]), borderRadius: BorderRadius.circular(8)),
            child: const Text('UPGRADE TO PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          const Text('Unlock all courses · No ads · Offline mode', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ]),
      ),
    );
  }
}
