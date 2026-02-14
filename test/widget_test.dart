// Basic widget test for SkinTermo AI app.
import 'package:flutter_test/flutter_test.dart';
import 'package:skin_termo_ai/main.dart';

void main() {
  testWidgets('SkinTermo AI app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SkinTermoApp());
    await tester.pumpAndSettle();

    // Verify the app renders without crashing.
    expect(find.byType(SkinTermoApp), findsOneWidget);
  });
}
