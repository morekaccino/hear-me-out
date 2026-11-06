import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/core/media/file_media_store.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(mediaBackupExclusionChannelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('the channel sends the media path and reports confirmation', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });

    final result = await const PlatformMediaBackupExclusion().excludeFromBackup(
      r'C:\app\support\media',
    );

    expect(result.status, BackupExclusionStatus.excluded);
    expect(result.isConfirmed, isTrue);
    expect(result.error, isNull);
    expect(calls, hasLength(1));
    expect(calls.single.method, PlatformMediaBackupExclusion.method);
    expect(calls.single.arguments, {'path': r'C:\app\support\media'});
  });

  test(
    'a platform error becomes a failed result instead of throwing',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'exclusion_failed', message: 'nope');
          });

      final result = await const PlatformMediaBackupExclusion()
          .excludeFromBackup('/app/support/media');

      expect(result.status, BackupExclusionStatus.failed);
      expect(result.isConfirmed, isFalse);
      expect(
        result.error,
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'exclusion_failed',
        ),
      );
    },
  );

  test('false from the platform is a failure, not a success', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);

    final result = await const PlatformMediaBackupExclusion().excludeFromBackup(
      '/app/support/media',
    );

    expect(result.status, BackupExclusionStatus.failed);
    expect(result.isConfirmed, isFalse);
    expect(result.error, isA<PlatformException>());
  });

  test('an empty path is rejected before the platform call', () async {
    var called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          called = true;
          return true;
        });

    final result = await const PlatformMediaBackupExclusion().excludeFromBackup(
      '  ',
    );

    expect(result.status, BackupExclusionStatus.failed);
    expect(result.error, isA<ArgumentError>());
    expect(called, isFalse);
  });

  test('createMediaBackupExclusion selects the iOS channel', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(createMediaBackupExclusion(), isA<PlatformMediaBackupExclusion>());
  });

  test('createMediaBackupExclusion uses Android manifest rules', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final exclusion = createMediaBackupExclusion();

    expect(exclusion, isA<PlatformRulesMediaBackupExclusion>());
  });

  test('createMediaBackupExclusion is a no-op on desktop', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final exclusion = createMediaBackupExclusion();

    expect(exclusion, isA<NoopMediaBackupExclusion>());
  });

  test('Android manifest rules count as a confirmed exclusion', () async {
    final result = await const PlatformRulesMediaBackupExclusion()
        .excludeFromBackup('/app/support/media');

    expect(result.status, BackupExclusionStatus.excludedByRules);
    expect(result.isConfirmed, isTrue);
  });

  test('the media path ends with the shared directory name', () {
    expect(mediaDirectoryName, 'media');
    expect(mediaDirectoryFor(r'C:\app\support'), endsWith('/media'));
  });

  test(
    'the provider excludes the store directory before creating it',
    () async {
      final fake = _RecordingBackupExclusion(
        const BackupExclusionResult.excluded(),
      );
      final container = _container(fake, r'C:\app\support');
      addTearDown(container.dispose);

      final store = await container.read(mediaStoreProvider.future);

      expect(store, isA<FileMediaStore>());
      expect(fake.directories, [r'C:\app\support/media']);
    },
  );

  test('the status provider exposes a confirmed exclusion', () async {
    final fake = _RecordingBackupExclusion(
      const BackupExclusionResult.excluded(),
    );
    final container = _container(fake, r'C:\app\support');
    addTearDown(container.dispose);

    final status = await container.read(mediaBackupStatusProvider.future);

    expect(status.isConfirmed, isTrue);
    expect(fake.directories, [r'C:\app\support/media']);
  });

  test('the status provider exposes a failed exclusion to the UI', () async {
    final fake = _RecordingBackupExclusion(
      const BackupExclusionResult.failed('denied'),
    );
    final container = _container(fake, r'C:\app\support');
    addTearDown(container.dispose);

    final status = await container.read(mediaBackupStatusProvider.future);

    expect(status.status, BackupExclusionStatus.failed);
    expect(status.isConfirmed, isFalse);
    expect(status.error, 'denied');
  });

  test('the store reuses the status result instead of asking twice', () async {
    final fake = _RecordingBackupExclusion(
      const BackupExclusionResult.excluded(),
    );
    final container = _container(fake, '/app/support');
    addTearDown(container.dispose);

    await container.read(mediaBackupStatusProvider.future);
    await container.read(mediaStoreProvider.future);

    expect(fake.directories, hasLength(1));
  });

  test('a failed exclusion is logged and does not block the store', () async {
    final fake = _RecordingBackupExclusion(
      const BackupExclusionResult.failed('denied'),
    );
    final logs = _captureDebugPrint();
    addTearDown(logs.restore);

    final container = _container(fake, r'C:\app\support');
    addTearDown(container.dispose);

    final store = await container.read(mediaStoreProvider.future);

    expect(store, isA<FileMediaStore>());
    expect(fake.directories, hasLength(1));
    expect(logs.messages, hasLength(1));
    expect(logs.messages.single, contains('backup exclusion failed'));
    expect(logs.messages.single, contains('denied'));
  });

  test(
    'a thrown exclusion error is reported and does not crash the provider',
    () async {
      final logs = _captureDebugPrint();
      addTearDown(logs.restore);

      final container = _container(_ThrowingBackupExclusion(), '/app/support');
      addTearDown(container.dispose);

      final store = await container.read(mediaStoreProvider.future);

      expect(store, isA<FileMediaStore>());
      expect(logs.messages, hasLength(1));
      expect(logs.messages.single, contains('backup exclusion failed'));
      expect(logs.messages.single, contains('Bad state'));
    },
  );

  test('a required exclusion does not log a false failure', () async {
    final logs = _captureDebugPrint();
    addTearDown(logs.restore);

    final container = _container(const NoopMediaBackupExclusion(), '/app');
    addTearDown(container.dispose);

    final store = await container.read(mediaStoreProvider.future);

    expect(store, isA<FileMediaStore>());
    expect(logs.messages, isEmpty);
  });
}

ProviderContainer _container(
  MediaBackupExclusion exclusion,
  String supportPath,
) {
  return ProviderContainer(
    overrides: [
      mediaDirectoryProvider.overrideWithValue(
        AsyncData<String>(mediaDirectoryFor(supportPath)),
      ),
      mediaBackupExclusionProvider.overrideWithValue(exclusion),
    ],
  );
}

_CapturedDebugPrint _captureDebugPrint() {
  final messages = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null) messages.add(message);
  };
  return _CapturedDebugPrint(messages, () => debugPrint = original);
}

class _CapturedDebugPrint {
  const _CapturedDebugPrint(this.messages, this.restore);

  final List<String> messages;
  final void Function() restore;
}

class _RecordingBackupExclusion implements MediaBackupExclusion {
  _RecordingBackupExclusion(this.result);

  final BackupExclusionResult result;
  final List<String> directories = [];

  @override
  Future<BackupExclusionResult> excludeFromBackup(String directory) async {
    directories.add(directory);
    return result;
  }
}

class _ThrowingBackupExclusion implements MediaBackupExclusion {
  @override
  Future<BackupExclusionResult> excludeFromBackup(String directory) async {
    throw StateError('platform channel unavailable');
  }
}
