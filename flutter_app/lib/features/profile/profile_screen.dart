import 'package:flutter/material.dart';
import 'widgets/stat_grid.dart';
import 'widgets/upgrade_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 70, height: 70, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF06B6D4)])), child: const Center(child: Text('🎵', style: TextStyle(fontSize: 32)))),
            const SizedBox(height: 12),
            const Text('Sarah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Level 4 · Sapphire League', style: TextStyle(fontSize: 12, color: Color(0xFFA855F7))),
            const SizedBox(height: 24),
            const StatGrid(),
            const SizedBox(height: 24),
            _SettingRow(icon: Icons.music_note, label: 'Instrument', value: 'Guitar'),
            _SettingRow(icon: Icons.tune, label: 'Range', value: 'E2 – E5'),
            _SettingRow(icon: Icons.vibration, label: 'Haptics', value: 'On'),
            _SettingRow(icon: Icons.dark_mode, label: 'Theme', value: 'Dark'),
            _SettingRow(icon: Icons.share, label: 'Share Progress', value: '▸'),
            _SettingRow(icon: Icons.refresh, label: 'Reset', value: '▸', isDestructive: true),
            const SizedBox(height: 20),
            UpgradeCard(onUpgrade: () {}),
            const SizedBox(height: 20),
            const Text('Hear Me Out v2.0 · Made with 🎵', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ]),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDestructive;
  const _SettingRow({required this.icon, required this.label, required this.value, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDestructive ? const Color(0xFFEF4444) : null))),
        Text(value, style: TextStyle(fontSize: 13, color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8))),
      ]),
    );
  }
}
