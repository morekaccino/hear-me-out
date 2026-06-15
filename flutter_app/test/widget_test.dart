import 'package:flutter_test/flutter_test.dart';

import 'package:hear_me_out/app.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const HearMeOutApp());
    expect(find.text('Home'), findsOneWidget);
  });
}
