import 'package:flutter/material.dart';
import 'widgets/course_card.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Learn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Structured curriculum', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            const SizedBox(height: 20),
            CourseCard(title: 'Note Basics', description: 'Identify single notes on the staff', level: 1, progress: 0.85, isPro: false, isLocked: false, completedItems: 18, totalItems: 21, onTap: () {}),
            CourseCard(title: 'Intervals I', description: 'Major & minor 2nds, 3rds', level: 2, progress: 0.30, isPro: false, isLocked: false, completedItems: 6, totalItems: 20, onTap: () {}),
            CourseCard(title: 'Chord Recognition', description: 'Major, minor, diminished triads', level: 3, progress: 0.0, isPro: true, isLocked: true, onTap: () {}),
            CourseCard(title: 'Sight Reading I', description: 'Play melodies from standard notation', level: 4, progress: 0.0, isPro: true, isLocked: true, onTap: () {}),
          ]),
        ),
      ),
    );
  }
}
