import 'package:flutter_test/flutter_test.dart';

import 'package:pluma/main.dart';

void main() {
  testWidgets('Pluma app boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const PlumaApp());
    expect(find.byType(PlumaApp), findsOneWidget);
  });
}
