import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesRetentionStore', () {
    test('missing data is opted out and gets a local install id', () async {
      final data = await SharedPreferencesRetentionStore().load();

      expect(data.optIn, isFalse);
      expect(data.log.events, isEmpty);
      expect(
        RegExp(r'^[0-9a-f]{32}$').hasMatch(data.log.installId),
        isTrue,
        reason: data.log.installId,
      );
    });

    test('save and load round trip opt-in, id, and events', () async {
      final log = RetentionLog(installId: 'install-1')
          .record(RetentionEventName.appOpen, at: DateTime.utc(2026, 1, 1, 9))
          .record(
            RetentionEventName.sessionStart,
            at: DateTime.utc(2026, 1, 1, 9, 5),
          );
      final store = SharedPreferencesRetentionStore();
      await store.save(RetentionStoredData(optIn: true, log: log));

      final reloaded = await SharedPreferencesRetentionStore().load();
      expect(reloaded.optIn, isTrue);
      expect(reloaded.log.installId, 'install-1');
      expect(reloaded.log.events, hasLength(2));
      expect(reloaded.log.events.first.name, RetentionEventName.appOpen);
      expect(
        reloaded.log.events.last.timestamp,
        DateTime.utc(2026, 1, 1, 9, 5),
      );
    });

    test('corrupt JSON is ignored', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesRetentionStore.storageKey: '{not valid json',
      });

      final data = await SharedPreferencesRetentionStore().load();
      expect(data.optIn, isFalse);
      expect(data.log.events, isEmpty);
    });

    test('a future schema is ignored and left untouched', () async {
      final future = jsonEncode({
        'schemaVersion': 2,
        'optIn': true,
        'installId': 'future-install',
        'events': [
          {
            'name': 'app_open',
            'at': '2026-01-01T09:00:00.000Z',
            'installId': 'future-install',
          },
        ],
      });
      SharedPreferences.setMockInitialValues({
        SharedPreferencesRetentionStore.storageKey: future,
      });

      final data = await SharedPreferencesRetentionStore().load();
      expect(data.optIn, isFalse);
      expect(data.log.events, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SharedPreferencesRetentionStore.storageKey),
        future,
      );
    });

    test('bad event entries are dropped, valid ones kept', () async {
      final raw = jsonEncode({
        'schemaVersion': 1,
        'optIn': true,
        'installId': 'install-1',
        'events': [
          {
            'name': 'app_open',
            'at': '2026-01-01T09:00:00.000Z',
            'installId': 'install-1',
          },
          {'name': 'unknown_event', 'at': '2026-01-01T09:01:00.000Z'},
          {'name': 'session_start', 'at': 'not-a-date'},
          {
            'name': 'session_start',
            'at': '2026-01-01T09:02:00.000Z',
            'installId': 'install-1',
          },
          {
            'name': 'session_complete',
            'at': '2026-01-01T09:03:00.000Z',
            'installId': 'someone-else',
          },
          'not an object',
        ],
      });
      SharedPreferences.setMockInitialValues({
        SharedPreferencesRetentionStore.storageKey: raw,
      });

      final data = await SharedPreferencesRetentionStore().load();
      expect(data.optIn, isTrue);
      expect(data.log.events.map((event) => event.name), [
        RetentionEventName.appOpen,
        RetentionEventName.sessionStart,
      ]);
    });

    test('load enforces the event bound', () async {
      final start = DateTime.utc(2026, 1, 1);
      final events = [
        for (var index = 0; index < retentionEventLimit + 100; index++)
          RetentionEvent(
            name: RetentionEventName.sessionStart,
            timestamp: start.add(Duration(minutes: index)),
            installId: 'install-1',
          ),
      ];
      SharedPreferences.setMockInitialValues({
        SharedPreferencesRetentionStore.storageKey: jsonEncode({
          'schemaVersion': 1,
          'optIn': true,
          'installId': 'install-1',
          'events': [for (final event in events) event.toJson()],
        }),
      });

      final data = await SharedPreferencesRetentionStore().load();
      expect(data.log.events, hasLength(retentionEventLimit));
      expect(data.log.events.first.timestamp, events[100].timestamp);
      expect(data.log.events.last.timestamp, events.last.timestamp);
    });

    test('clear removes the document but a reload starts opted out', () async {
      final store = SharedPreferencesRetentionStore();
      await store.save(
        RetentionStoredData(
          optIn: true,
          log: RetentionLog(installId: 'install-1')
              .record(RetentionEventName.appOpen, at: DateTime.utc(2026, 1, 1)),
        ),
      );
      await store.clear();

      final data = await SharedPreferencesRetentionStore().load();
      expect(data.optIn, isFalse);
      expect(data.log.events, isEmpty);
    });
  });
}
