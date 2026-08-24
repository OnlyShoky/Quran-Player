import 'package:flutter_test/flutter_test.dart';
import 'package:quran_player/app.dart';

void main() {
  testWidgets('App smoke test - renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(QuranPlayerApp());
    // Just verify the app builds without throwing
    expect(find.byType(QuranPlayerApp), findsOneWidget);
  });
}
