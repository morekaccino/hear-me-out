import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(ProgressState progress) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore(progress)),
        pitchSourceFactoryProvider.overrideWithValue(
          FakePitchSourceFactory(permission: false).call,
        ),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
      ],
      child: const HearMeOutApp(),
    );
  }

  AppSettings settingsWith(AppThemeMode mode) => AppSettings(
    onboardingComplete: true,
    answerMode: AnswerMode.name,
    themeMode: mode,
  );

  test('each unit gets a distinct path color and cycles', () {
    final faces = [
      for (var unit = 1; unit <= duoUnitColors.length; unit++)
        duoUnitColor(unit).face,
    ];
    expect(faces.toSet().length, duoUnitColors.length);
    expect(duoUnitColor(7).face, duoUnitColor(1).face);
  });

  test('theme mode round-trips and defaults to system', () {
    expect(const AppSettings().themeMode, AppThemeMode.system);
    expect(
      AppSettings.fromJson(const {'themeMode': 'dark'}).themeMode,
      AppThemeMode.dark,
    );
    expect(
      AppSettings.fromJson(const {'themeMode': 'nonsense'}).themeMode,
      AppThemeMode.system,
    );
    expect(
      AppSettings(themeMode: AppThemeMode.dark).toJson()['themeMode'],
      'dark',
    );
  });

  testWidgets('explicit dark mode applies the Duo dark palette', (
    tester,
  ) async {
    addTearDown(() => AppColors.applyBrightness(Brightness.light));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        ProgressState.fresh(settings: settingsWith(AppThemeMode.dark)),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeShell));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      const Color(0xFF131F24),
    );
    expect(AppColors.isDark, isTrue);
    expect(AppColors.text, const Color(0xFFF1F7FB));
  });

  testWidgets('system mode follows the platform brightness', (tester) async {
    addTearDown(() => AppColors.applyBrightness(Brightness.light));
    addTearDown(
      tester.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        ProgressState.fresh(settings: settingsWith(AppThemeMode.system)),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeShell));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('appearance setting cycles and persists', (tester) async {
    addTearDown(() => AppColors.applyBrightness(Brightness.light));
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryProgressStore(
      ProgressState.fresh(settings: settingsWith(AppThemeMode.system)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressStoreProvider.overrideWithValue(store),
          pitchSourceFactoryProvider.overrideWithValue(
            FakePitchSourceFactory(permission: false).call,
          ),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
        child: const HearMeOutApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Appearance'));
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(store.value?.settings.themeMode, AppThemeMode.light);
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(store.value?.settings.themeMode, AppThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(HomeShell))).brightness,
      Brightness.dark,
    );
  });
}
