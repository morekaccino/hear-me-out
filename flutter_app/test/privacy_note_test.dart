import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/features/profile/privacy_note.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    AsyncValue<BackupExclusionResult> backup,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MediaPrivacyCard(backup: backup)),
      ),
    );
  }

  testWidgets('the privacy card does not claim exclusion when it failed', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const AsyncData<BackupExclusionResult>(
        BackupExclusionResult.failed('denied'),
      ),
    );

    expect(find.textContaining('could not confirm'), findsOneWidget);
    expect(
      find.textContaining('may be included in device backup'),
      findsOneWidget,
    );
    expect(
      find.textContaining('excluded from cloud backup by default'),
      findsNothing,
    );
  });

  testWidgets('the privacy card claims exclusion only when confirmed', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const AsyncData<BackupExclusionResult>(BackupExclusionResult.excluded()),
    );

    expect(
      find.textContaining('excluded from cloud backup by default'),
      findsOneWidget,
    );
    expect(find.textContaining('could not confirm'), findsNothing);
  });

  testWidgets('Android manifest rules count as confirmation', (tester) async {
    await pumpCard(
      tester,
      const AsyncData<BackupExclusionResult>(
        BackupExclusionResult.excludedByRules(),
      ),
    );

    expect(
      find.textContaining('excluded from cloud backup by default'),
      findsOneWidget,
    );
    expect(find.textContaining('could not confirm'), findsNothing);
  });

  testWidgets('the privacy card avoids a claim while checking', (tester) async {
    await pumpCard(tester, const AsyncLoading<BackupExclusionResult>());

    expect(find.textContaining('is checking'), findsOneWidget);
    expect(
      find.textContaining('excluded from cloud backup by default'),
      findsNothing,
    );
    expect(find.textContaining('could not confirm'), findsNothing);
  });

  testWidgets('a status provider error is treated as unconfirmed', (
    tester,
  ) async {
    await pumpCard(
      tester,
      AsyncError<BackupExclusionResult>(
        StateError('no directory'),
        StackTrace.empty,
      ),
    );

    expect(find.textContaining('could not confirm'), findsOneWidget);
    expect(
      find.textContaining('may be included in device backup'),
      findsOneWidget,
    );
  });
}
