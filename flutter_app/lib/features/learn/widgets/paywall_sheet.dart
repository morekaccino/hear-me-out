import 'package:flutter/material.dart';

class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF14141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Unlock Full Access', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Get all courses, unlimited practice, offline mode, and more.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        const SizedBox(height: 24),
        _PlanCard(isPopular: true, title: 'Pro', price: '\$4.99', period: '/month', features: const ['All courses & levels', 'Unlimited daily sessions', 'Offline mode', 'Detailed analytics & pitch accuracy', 'No ads'], onTap: () => Navigator.pop(context)),
        const SizedBox(height: 12),
        _PlanCard(title: 'Teacher', price: '\$9.99', period: '/month', features: const ['Everything in Pro', 'Manage up to 30 students', 'Assign exercises', 'Student progress dashboard'], onTap: () => Navigator.pop(context)),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe later', style: TextStyle(color: Color(0xFF94A3B8)))),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({required this.title, required this.price, required this.period, required this.features, this.isPopular = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPopular ? const Color(0xFFA855F7) : const Color(0xFF1E293B), width: isPopular ? 2 : 1),
          boxShadow: isPopular ? [BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.1), blurRadius: 20)] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isPopular)
            Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFA855F7), borderRadius: BorderRadius.circular(6)), child: const Text('BEST VALUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), Text(period, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))]),
          ]),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)), const SizedBox(width: 8), Text(f, style: const TextStyle(fontSize: 12))]))),
        ]),
      ),
    );
  }
}
