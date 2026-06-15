import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final int level;
  final double progress;
  final bool isPro;
  final bool isLocked;
  final int completedItems;
  final int totalItems;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.description,
    required this.level,
    required this.progress,
    required this.isPro,
    required this.isLocked,
    this.completedItems = 0,
    this.totalItems = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Level $level · ${isPro ? "Pro" : "Free"}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPro ? const Color(0xFFF59E0B) : const Color(0xFFA855F7), letterSpacing: 1)),
                const Spacer(),
                if (isLocked) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]), borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(height: 10),
              if (progress > 0 || !isLocked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFF1E293B), valueColor: AlwaysStoppedAnimation<Color>(isPro ? const Color(0xFFF59E0B) : const Color(0xFFA855F7)), minHeight: 3),
                ),
              if (progress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${(progress * 100).toInt()}% complete${!isLocked ? " · $completedItems/$totalItems" : ""}', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
