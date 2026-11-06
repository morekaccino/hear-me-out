import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:xml/xml.dart';

void main() {
  group('Android backup rules', () {
    test('the manifest wires both rule files on the application element', () {
      final document = _parse('android/app/src/main/AndroidManifest.xml');
      final application = _singleChild(document.rootElement, 'application');

      expect(
        application.getAttribute('android:fullBackupContent'),
        '@xml/backup_rules',
      );
      expect(
        application.getAttribute('android:dataExtractionRules'),
        '@xml/data_extraction_rules',
      );
      expect(
        document
            .findAllElements('uses-permission')
            .any(
              (element) =>
                  element.getAttribute('android:name') ==
                  'android.permission.RECORD_AUDIO',
            ),
        isTrue,
      );
    });

    test('legacy Auto Backup excludes filesDir/media', () {
      final document = _parse('android/app/src/main/res/xml/backup_rules.xml');

      expect(document.rootElement.name.local, 'full-backup-content');
      _expectMediaExclude(document.rootElement);
    });

    test(
      'Android 12+ cloud backup and device transfer exclude filesDir/media',
      () {
        final document = _parse(
          'android/app/src/main/res/xml/data_extraction_rules.xml',
        );
        expect(document.rootElement.name.local, 'data-extraction-rules');

        _expectMediaExclude(_singleChild(document.rootElement, 'cloud-backup'));
        _expectMediaExclude(
          _singleChild(document.rootElement, 'device-transfer'),
        );
      },
    );
  });

  group('iOS backup exclusion', () {
    test('the mic usage string says the app asks iOS to exclude a take', () {
      final plist = _parse('ios/Runner/Info.plist');
      final description = _plistString(plist, 'NSMicrophoneUsageDescription');

      expect(description, isNotNull);
      final lower = description!.toLowerCase();
      expect(lower, isNot(contains('never recorded')));
      expect(lower, contains('asks ios to exclude'));
      expect(lower, contains('if ios cannot confirm that'));
      expect(lower, contains('may be included in device backup'));
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
      expect(swift, contains('guard confirmed else'));
    });
  });

  group('privacy copy', () {
    test('docs use the honest mic scope and conditional backup wording', () {
      final readme = _flatten(File('../README.md').readAsStringSync())
          .toLowerCase();
      final design = _flatten(File('../docs/DESIGN.md').readAsStringSync())
          .toLowerCase();
      final architecture = _flatten(
        File('../docs/ARCHITECTURE.md').readAsStringSync(),
      ).toLowerCase();

      for (final source in [readme, design]) {
        expect(
          source,
          contains('during a lesson, practice, tuner, or recording session'),
        );
      }
      expect(readme, contains('asks ios to exclude'));
      expect(readme, contains('could not confirm'));
      expect(
        readme,
        contains(
          'the practice **recordings** screen owns record, play, delete, '
          'clear-all, and export',
        ),
      );
      expect(readme, contains('v1 stores wav, not aac'));
      expect(readme, contains('recording quality is not validated'));
      expect(readme, isNot(contains('the recording ui arrives in t4.2')));
      expect(readme, isNot(contains('nothing is recorded or uploaded')));
      expect(design, contains('could not confirm'));
      expect(design, isNot(contains('analyzed in memory and discarded')));
      expect(architecture, contains('mediabackupstatusprovider'));
      expect(architecture, contains('nsurlisexcludedfrombackupkey'));
      expect(architecture, contains('could not confirm'));
      expect(
        architecture,
        contains('0002-backup-exclusion-no-opt-in.md'),
      );
    });

    test('decision 0002 records no V1 opt-in and the T4.2 gate', () {
      final decision = _flatten(
        File('../docs/decisions/0002-backup-exclusion-no-opt-in.md')
            .readAsStringSync(),
      ).toLowerCase();

      expect(decision, contains('no opt-in'));
      expect(decision, contains('t4.2'));
      expect(decision, contains('mediabackupstatusprovider'));
    });

    test('the profile screen uses the backup status provider', () {
      final profile = File('lib/features/profile/profile_screen.dart')
          .readAsStringSync();

      expect(profile, contains('ref.watch(mediaBackupStatusProvider)'));
      expect(profile, contains('MediaPrivacyCard'));
      expect(profile, isNot(contains('never recorded')));
    });
  });
}

XmlDocument _parse(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing $path');
  return XmlDocument.parse(file.readAsStringSync());
}

XmlElement _singleChild(XmlElement parent, String name) {
  final matches = parent.childElements
      .where((element) => element.name.local == name)
      .toList();

  expect(
    matches,
    hasLength(1),
    reason: 'expected one <$name> under <${parent.name.local}>',
  );
  return matches.single;
}

void _expectMediaExclude(XmlElement parent) {
  final excludes = parent.childElements
      .where((element) => element.name.local == 'exclude')
      .toList();

  expect(
    excludes,
    hasLength(1),
    reason: 'expected one <exclude> under <${parent.name.local}>',
  );
  expect(excludes.single.getAttribute('domain'), 'file');
  expect(excludes.single.getAttribute('path'), '$mediaDirectoryName/');
}

String? _plistString(XmlDocument plist, String key) {
  final dict = _singleChild(plist.rootElement, 'dict');
  final children = dict.childElements.toList();

  for (var index = 0; index < children.length - 1; index++) {
    final current = children[index];
    if (current.name.local != 'key' || current.innerText != key) continue;

    final value = children[index + 1];
    if (value.name.local != 'string') return null;
    return value.innerText;
  }
  return null;
}

String _flatten(String source) => source.replaceAll(RegExp(r'\s+'), ' ');
