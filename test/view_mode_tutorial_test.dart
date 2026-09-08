import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:quran_player/shared/providers/view_mode_provider.dart';
import 'package:quran_player/shared/providers/playlist_provider.dart';
import 'package:quran_player/shared/providers/player_provider.dart';
import 'package:quran_player/features/surah_list/surah_list_screen.dart';
import 'package:quran_player/shared/widgets/view_mode_tutorial_overlay.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ViewModeProvider Tutorial State', () {
    test('initially shows tutorial when pref is absent', () async {
      final provider = ViewModeProvider();
      // wait for async _load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.shouldShowTutorial, isTrue);
      expect(provider.hasSeenTutorial, isFalse);
    });

    test('completeTutorial marks tutorial as seen and persists', () async {
      final provider = ViewModeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.completeTutorial();
      expect(provider.shouldShowTutorial, isFalse);
      expect(provider.hasSeenTutorial, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_view_mode_tutorial'), isTrue);
    });

    test('resetTutorial enables tutorial again', () async {
      final provider = ViewModeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.completeTutorial();

      await provider.resetTutorial();
      expect(provider.shouldShowTutorial, isTrue);
      expect(provider.hasSeenTutorial, isFalse);
    });
  });

  group('SurahListScreen Tutorial Integration', () {
    testWidgets('shows tutorial overlay on first launch and allows dismissal',
        (WidgetTester tester) async {
      final viewModeProvider = ViewModeProvider();
      final playlistProvider = PlaylistProvider();
      final playerProvider = PlayerProvider();

      // Wait for provider to load initial prefs
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: viewModeProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
            ChangeNotifierProvider.value(value: playerProvider),
          ],
          child: const MaterialApp(
            home: SurahListScreen(),
          ),
        ),
      );

      // Settle frames and post frame callbacks
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Check tutorial overlay is displayed
      expect(find.byType(ViewModeTutorialOverlay), findsOneWidget);
      expect(find.text('¡Alterna el modo de visualización!'), findsOneWidget);
      expect(find.text('¡Entendido!'), findsOneWidget);

      // Tap "¡Entendido!"
      await tester.tap(find.text('¡Entendido!'));
      await tester.pumpAndSettle();

      // Tutorial should now be dismissed and marked as completed
      expect(find.byType(ViewModeTutorialOverlay), findsNothing);
      expect(viewModeProvider.hasSeenTutorial, isTrue);
    });

    testWidgets('Probar Mosaico button toggles view mode and dismisses tutorial',
        (WidgetTester tester) async {
      final viewModeProvider = ViewModeProvider();
      final playlistProvider = PlaylistProvider();
      final playerProvider = PlayerProvider();

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: viewModeProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
            ChangeNotifierProvider.value(value: playerProvider),
          ],
          child: const MaterialApp(
            home: SurahListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Probar Mosaico'), findsOneWidget);
      expect(viewModeProvider.mode, ViewMode.list);

      // Tap "Probar Mosaico"
      await tester.tap(find.text('Probar Mosaico'));
      await tester.pumpAndSettle();

      // View mode toggled to mosaic
      expect(viewModeProvider.mode, ViewMode.mosaic);
      expect(viewModeProvider.hasSeenTutorial, isTrue);
      expect(find.byType(ViewModeTutorialOverlay), findsNothing);
    });
  });
}
