// flutter_app/lib/app.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'core/router.dart';

class HearMeOutApp extends StatelessWidget {
  const HearMeOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    return ProviderScope(
      child: isIOS
          ? CupertinoApp.router(
              title: 'Hear Me Out',
              theme: AppTheme.cupertinoTheme,
              routerConfig: goRouter,
              debugShowCheckedModeBanner: false,
            )
          : MaterialApp.router(
              title: 'Hear Me Out',
              theme: AppTheme.darkMaterialTheme,
              routerConfig: goRouter,
              debugShowCheckedModeBanner: false,
            ),
    );
  }
}
