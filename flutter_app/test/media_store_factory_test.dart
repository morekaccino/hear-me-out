import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/file_media_store.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/media_store_factory.dart';
import 'package:hear_me_out/state/providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hmo_media_factory_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('createMediaStore returns a file store on the VM', () async {
    final store = await createMediaStore(directory: tempDir.path);

    expect(store, isA<FileMediaStore>());

    final bytes = Uint8List.fromList([1, 2, 3]);
    final ref = await store.put(bytes, mimeType: 'audio/wav', id: 'take-1');
    expect(await store.get(ref.id), bytes);
  });

  test('a missing directory is rejected with a clear error', () async {
    await expectLater(
      createMediaStore(),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('media directory is required'),
        ),
      ),
    );
    await expectLater(createMediaStore(directory: '  '), throwsArgumentError);
  });

  test(
    'the media store provider is overridable with MemoryMediaStore',
    () async {
      final memoryStore = MemoryMediaStore();
      final container = ProviderContainer(
        overrides: [
          mediaStoreProvider.overrideWithValue(
            AsyncData<MediaStore>(memoryStore),
          ),
        ],
      );
      addTearDown(container.dispose);

      final store = await container.read(mediaStoreProvider.future);

      expect(store, same(memoryStore));
    },
  );
}
