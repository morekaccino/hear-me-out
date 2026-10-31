import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'shared/audio/sound_service.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/mascot.dart';
import 'state/app_controller.dart';
import 'state/providers.dart';

class HearMeOutApp extends StatelessWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hear Me Out',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RootGate(),
    );
  }
}

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appControllerProvider);
    return async.when(
      loading: () => const _SplashScreen(),
      error: (error, stack) => _StartupError(error: error),
      data: (data) {
        unawaited(ref.read(soundServiceProvider).preload());
        if (!data.progress.settings.onboardingComplete) {
          return const OnboardingScreen();
        }
        return const HomeShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Mascot(size: 140),
            SizedBox(height: 16),
            Text(
              'Hear Me Out',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends ConsumerWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Mascot(size: 110, mood: MascotMood.thinking),
            const SizedBox(height: 20),
            const Text(
              'Could not start',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                unawaited(
                  ref
                      .read(soundServiceProvider)
                      .play(Sfx.uiTapPrimary),
                );
                ref.invalidate(appControllerProvider);
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
