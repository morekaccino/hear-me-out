import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/core/media/media_store.dart';

void main() {
  final fileExclusion = '<exclude domain="file" path="$mediaDirectoryName/"';

  group('Android backup rules', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final backupRules = File('android/app/src/main/res/xml/backup_rules.xml');
    final extractionRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    );

    test('the manifest points at both rule files', () {
      expect(manifest.existsSync(), isTrue);
      final source = manifest.readAsStringSync();

      expect(source, contains('android:fullBackupContent="@xml/backup_rules"'));
      expect(
        source,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(
        source,
        contains('android:name="android.permission.RECORD_AUDIO"'),
      );
    });

    test('legacy Auto Backup excludes filesDir/media', () {
      expect(backupRules.existsSync(), isTrue);
      final source = backupRules.readAsStringSync();

      expect(source, contains('<full-backup-content>'));
      expect(source, contains(fileExclusion));
    });

    test(
      'Android 12+ cloud backup and device transfer exclude filesDir/media',
      () {
        expect(extractionRules.existsSync(), isTrue);
        final source = extractionRules.readAsStringSync();

        expect(source, contains('<data-extraction-rules>'));
        expect(_section(source, 'cloud-backup'), contains(fileExclusion));
        expect(_section(source, 'device-transfer'), contains(fileExclusion));
      },
    );
  });

  group('iOS backup exclusion', () {
    test('the microphone usage string says recordings stay on the device', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final description = _plistString(plist, 'NSMicrophoneUsageDescription');

      expect(description, isNotNull);
      final lower = description!.toLowerCase();
      expect(lower, isNot(contains('never recorded')));
      expect(lower, contains('analyzed on this device'));
      expect(lower, contains('stored only on this device'));
      expect(lower, contains('excluded from icloud backup'));
      expect(lower, contains('nothing is uploaded'));
    });

    test('AppDelegate sets the resource value through the Dart channel', () {
      final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      final dart = File('lib/core/media/backup_exclusion.dart')
          .readAsStringSync();
      const channelName = mediaBackupExclusionChannelName;

      expect(dart, contains(channelName));
      expect(swift, contains(channelName));
      expect(swift, contains('excludeFromBackup'));
      expect(swift, contains('FlutterMethodChannel'));
      expect(swift, contains('didInitializeImplicitFlutterEngine'));
      expect(swift, contains('NSURLIsExcludedFromBackupKey'));
      expect(swift, contains('isExcludedFromBackup'));
      expect(swift, contains('setResourceValues'));
    });
  });

  group('privacy copy', () {
    test('docs describe local recordings and backup exclusion', () {
      final readme = _flatten(
        File('../README.md').readAsStringSync(),
      ).toLowerCase();
      final design = _flatten(
        File('../docs/DESIGN.md').readAsStringSync(),
      ).toLowerCase();
      final architecture = _flatten(
        File('../docs/ARCHITECTURE.md').readAsStringSync(),
      ).toLowerCase();

      for (final source in [readme, design, architecture]) {
        expect(source, contains('cloud backup'));
      }
      expect(readme, contains('android auto backup'));
      expect(readme, contains('android device transfer'));
      expect(readme, contains('icloud backup'));
      expect(readme, contains('when you record a take'));
      expect(readme, isNot(contains('nothing is recorded or uploaded')));
      expect(design, isNot(contains('analyzed in memory and discarded')));
      expect(architecture, contains('filesdir/media'));
      expect(architecture, contains('nsurlisexcludedfrombackupkey'));
      expect(architecture, contains('t4.2'));
    });

    test('in-app privacy copy does not claim audio is never recorded', () {
      final profile = File('lib/features/profile/profile_screen.dart')
          .readAsStringSync()
          .toLowerCase();

      expect(profile, isNot(contains('never recorded')));
      expect(profile, contains('excluded from cloud backup'));
      expect(profile, contains('when you record a take'));
    });
  });
}

String _flatten(String source) => source.replaceAll(RegExp(r'\s+'), ' ');

String _section(String source, String tag) {
  final start = source.indexOf('<$tag>');
  final end = source.indexOf('</$tag>', start + 1);
  if (start == -1 || end == -1) {
    throw StateError('missing <$tag> section');
  }
  return source.substring(start, end);
}

String? _plistString(String plist, String key) {
  final match = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<string>(.*?)</string>',
    dotAll: true,
  ).firstMatch(plist);
  return match?.group(1)?.trim();
}
