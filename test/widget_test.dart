import 'package:flutter_test/flutter_test.dart';
import 'package:blitz_tycoon/main.dart';

void main() {
  testWidgets('Blitz Tycoon smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BlitzTycoonApp());
    expect(find.byType(BlitzTycoonApp), findsOneWidget);
  });
}
