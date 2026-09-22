import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_preview/presets.dart';
import 'package:quran_player/shared/widgets/device_preview_switcher.dart';

void main() {
  test('DevicePresets contains iPhone and other devices', () {
    expect(DevicePresets.all.isNotEmpty, isTrue);
    final iphones =
        DevicePresets.all.where((p) => p.name.contains('iPhone')).toList();
    expect(iphones.isNotEmpty, isTrue);

    // Verify presence of popular preview devices requested
    expect(DevicePresets.iPhone16, isNotNull);
    expect(DevicePresets.iPhone16Pro, isNotNull);
    expect(DevicePresets.iPhone16ProMax, isNotNull);
    expect(DevicePresets.iPhoneSe3, isNotNull);
    expect(DevicePresets.pixel9, isNotNull);
    expect(DevicePresets.galaxyS25, isNotNull);
    expect(DevicePresets.iPad10, isNotNull);
  });

  testWidgets('DevicePreviewQuickSwitcher renders child without errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DevicePreviewQuickSwitcher(
          child: Scaffold(
            body: Text('Quran Player Screen'),
          ),
        ),
      ),
    );

    expect(find.text('Quran Player Screen'), findsOneWidget);
  });
}
