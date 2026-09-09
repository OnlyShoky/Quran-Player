import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_player/core/data/mock_data.dart';
import 'package:quran_player/core/data/surah_filter_data.dart';
import 'package:quran_player/core/localization/app_localizations.dart';
import 'package:quran_player/shared/providers/player_provider.dart';
import 'package:quran_player/shared/providers/playlist_provider.dart';
import 'package:quran_player/shared/providers/settings_provider.dart';
import 'package:quran_player/shared/providers/view_mode_provider.dart';
import 'package:quran_player/shared/widgets/surah_tile.dart';
import 'package:quran_player/features/surah_list/surah_list_screen.dart';

Widget createTestWidget(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => ViewModeProvider()),
      ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ChangeNotifierProvider(create: (_) => PlayerProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_view_mode_tutorial': true, // Skip tutorial in tests
    });
  });

  group('SurahFilterData Tests', () {
    test('all 30 Juz are mapped and return valid surah IDs', () {
      for (int i = 1; i <= 30; i++) {
        final surahs = SurahFilterData.surahIdsForJuz(i);
        expect(surahs, isNotNull, reason: 'Juz $i should not be null');
        expect(surahs!.isNotEmpty, isTrue, reason: 'Juz $i should contain surahs');
      }
    });

    test('Juz 1 contains Al-Fatihah and Al-Baqarah', () {
      final juz1 = SurahFilterData.surahIdsForJuz(1);
      expect(juz1, containsAll([1, 2]));
    });

    test('Juz 30 contains surahs 78 to 114', () {
      final juz30 = SurahFilterData.surahIdsForJuz(30);
      expect(juz30, isNotNull);
      expect(juz30!.length, 37);
      expect(juz30.contains(78), isTrue);
      expect(juz30.contains(114), isTrue);
      expect(juz30.contains(98), isTrue);
    });

    test('invalid Juz numbers return null', () {
      expect(SurahFilterData.surahIdsForJuz(0), isNull);
      expect(SurahFilterData.surahIdsForJuz(31), isNull);
      expect(SurahFilterData.surahIdsForJuz(-5), isNull);
    });
  });

  group('SurahTile 360px Width Overflow Test', () {
    testWidgets('renders surah tile on 360px wide screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Surah with longest English name and translation
      final testSurah = MockData.surahs.firstWhere((s) => s.id == 2); // Al-Baqarah, 286 verses

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: SizedBox(
              width: 360,
              child: SurahTile(surah: testSurah),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'No layout overflow exceptions should occur');
      expect(find.text('Al-Baqarah'), findsOneWidget);
    });
  });

  group('SurahListScreen Filter & Reverse UI Tests', () {
    testWidgets('filter icon toggles filter panel', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Find filter icon in search bar
      final filterButton = find.byTooltip('Filters');
      expect(filterButton, findsOneWidget);

      // Initially small filter boxes are not shown
      expect(find.widgetWithText(TextField, 'Juz'), findsNothing);

      // Tap filter button to open
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Small filter boxes are now visible next to search bar
      expect(find.widgetWithText(TextField, 'Juz'), findsOneWidget);
      expect(find.widgetWithText(TextField, '1'), findsOneWidget);
      expect(find.widgetWithText(TextField, '114'), findsOneWidget);
      // Reverse order is NOT in the filter menu
      expect(find.text('Reverse order'), findsNothing);
    });

    testWidgets('Juz filter shows only surahs in specified Juz', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Open filter boxes
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      // Enter Juz 1
      final juzField = find.widgetWithText(TextField, 'Juz');
      await tester.enterText(juzField, '1');
      await tester.pumpAndSettle();

      // Should show 2 results
      expect(find.text('2 results'), findsOneWidget);
      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('Al-Baqarah'), findsOneWidget);
      expect(find.text('Ali \'Imran'), findsNothing);
    });

    testWidgets('From and To range filters surahs', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Open filter boxes
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      // Enter From: 110, To: 114
      final fromField = find.widgetWithText(TextField, '1');
      final toField = find.widgetWithText(TextField, '114');
      await tester.enterText(fromField, '110');
      await tester.enterText(toField, '114');
      await tester.pumpAndSettle();

      // Should show 5 results (110, 111, 112, 113, 114)
      expect(find.text('5 results'), findsOneWidget);
      expect(find.text('An-Nasr'), findsOneWidget); // 110
      expect(find.text('An-Nas'), findsOneWidget); // 114
      expect(find.text('Al-Fatihah'), findsNothing); // 1
    });

    testWidgets('Reverse order button reverses the surah list order', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Initially order is 1 → 114
      expect(find.text('1 → 114'), findsOneWidget);

      // Tap quick reverse
      await tester.tap(find.text('1 → 114'));
      await tester.pumpAndSettle();

      // Order indicator should now show 114 → 1
      expect(find.text('114 → 1'), findsOneWidget);

      // First item visible in reversed list should be An-Nas (114)
      expect(find.text('An-Nas'), findsOneWidget);
    });

    testWidgets('Clear filters resets all filters', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Open filter boxes
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      // Enter Juz 30
      final juzField = find.widgetWithText(TextField, 'Juz');
      await tester.enterText(juzField, '30');
      await tester.pumpAndSettle();

      expect(find.text('37 results'), findsOneWidget);

      // Tap Clear filters button in count bar
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      // Should be back to 114 chapters
      expect(find.text('114 chapters'), findsOneWidget);
    });
  });
}
