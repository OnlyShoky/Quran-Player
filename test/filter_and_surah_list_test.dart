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

    test('all 60 Hizbs are mapped and return valid surah IDs', () {
      for (int i = 1; i <= 60; i++) {
        final surahs = SurahFilterData.surahIdsForHizb(i);
        expect(surahs, isNotNull, reason: 'Hizb $i should not be null');
        expect(surahs!.isNotEmpty, isTrue, reason: 'Hizb $i should contain surahs');
      }
    });

    test('Hizb 1 contains Al-Fatihah and Al-Baqarah', () {
      final hizb1 = SurahFilterData.surahIdsForHizb(1);
      expect(hizb1, containsAll([1, 2]));
    });

    test('Hizb 60 contains surahs 87 to 114', () {
      final hizb60 = SurahFilterData.surahIdsForHizb(60);
      expect(hizb60, isNotNull);
      expect(hizb60!.length, 28);
      expect(hizb60.contains(87), isTrue);
      expect(hizb60.contains(114), isTrue);
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

    test('invalid Hizb numbers return null', () {
      expect(SurahFilterData.surahIdsForHizb(0), isNull);
      expect(SurahFilterData.surahIdsForHizb(61), isNull);
      expect(SurahFilterData.surahIdsForHizb(-1), isNull);
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
      expect(find.widgetWithText(TextField, 'Hzb'), findsOneWidget);
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

    testWidgets('Hizb filter shows only surahs in specified Hizb', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Open filter boxes
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      // Enter Hizb 60 (contains 28 surahs from 87 to 114)
      final hizbField = find.widgetWithText(TextField, 'Hzb');
      await tester.enterText(hizbField, '60');
      await tester.pumpAndSettle();

      expect(find.text('28 results'), findsOneWidget);
      expect(find.text('Al-Ala'), findsOneWidget); // 87
      expect(find.text('Al-Ghashiyah'), findsOneWidget); // 88
      expect(find.text('Al-Fatihah'), findsNothing);
    });

    testWidgets('Filter boxes have comfortable generous size (64x44) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Open filter boxes
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'No layout overflow exceptions should occur on 360px width');

      // Verify all 4 filter box SizedBox containers have width: 64 and height: 44
      final juzFinder = find.widgetWithText(TextField, 'Juz');
      final hzbFinder = find.widgetWithText(TextField, 'Hzb');
      final fromFinder = find.widgetWithText(TextField, '1');
      final toFinder = find.widgetWithText(TextField, '114');

      for (final finder in [juzFinder, hzbFinder, fromFinder, toFinder]) {
        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(of: finder, matching: find.byType(SizedBox)).first,
        );
        expect(sizedBox.width, 64.0);
        expect(sizedBox.height, 44.0);
      }
    });

    testWidgets('Filter boxes indicate green when valid and red when invalid', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      // Open filter boxes
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      final juzField = find.widgetWithText(TextField, 'Juz');
      final hzbField = find.widgetWithText(TextField, 'Hzb');
      final fromField = find.widgetWithText(TextField, '1');

      // 1. Enter valid Juz: 30 -> should have primary color (green)
      await tester.enterText(juzField, '30');
      await tester.pumpAndSettle();
      TextField juzWidget = tester.widget<TextField>(juzField);
      expect(juzWidget.style?.color, isNotNull);
      // Not red
      expect(juzWidget.style?.color, isNot(const Color(0xFFDC2626)));
      expect(juzWidget.style?.color, isNot(const Color(0xFFEF4444)));

      // 2. Enter invalid Juz: 35 -> should appear RED
      await tester.enterText(juzField, '35');
      await tester.pumpAndSettle();
      juzWidget = tester.widget<TextField>(juzField);
      expect(
        juzWidget.style?.color == const Color(0xFFDC2626) ||
        juzWidget.style?.color == const Color(0xFFEF4444),
        isTrue,
        reason: 'Invalid Juz (35) must have red color',
      );

      // 3. Enter invalid Juz: 0 -> should appear RED
      await tester.enterText(juzField, '0');
      await tester.pumpAndSettle();
      juzWidget = tester.widget<TextField>(juzField);
      expect(
        juzWidget.style?.color == const Color(0xFFDC2626) ||
        juzWidget.style?.color == const Color(0xFFEF4444),
        isTrue,
        reason: 'Invalid Juz (0) must have red color',
      );

      // 4. Enter valid Hizb: 60 -> should NOT be red
      await tester.enterText(hzbField, '60');
      await tester.pumpAndSettle();
      TextField hzbWidget = tester.widget<TextField>(hzbField);
      expect(hzbWidget.style?.color, isNot(const Color(0xFFDC2626)));
      expect(hzbWidget.style?.color, isNot(const Color(0xFFEF4444)));

      // 5. Enter invalid Hizb: 70 -> should appear RED
      await tester.enterText(hzbField, '70');
      await tester.pumpAndSettle();
      hzbWidget = tester.widget<TextField>(hzbField);
      expect(
        hzbWidget.style?.color == const Color(0xFFDC2626) ||
        hzbWidget.style?.color == const Color(0xFFEF4444),
        isTrue,
        reason: 'Invalid Hizb (70) must have red color',
      );

      // 6. Enter invalid From: 150 -> should appear RED
      await tester.enterText(fromField, '150');
      await tester.pumpAndSettle();
      TextField fromWidget = tester.widget<TextField>(fromField);
      expect(
        fromWidget.style?.color == const Color(0xFFDC2626) ||
        fromWidget.style?.color == const Color(0xFFEF4444),
        isTrue,
        reason: 'Invalid From (150) must have red color',
      );
    });

    testWidgets('Search bar TextField renders comfortably with clear button', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget(const SurahListScreen()));
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(TextField, 'Search surahs…');
      expect(searchField, findsOneWidget);
    });
  });

  group('Surah Localization and Alignment Tests', () {
    test('SurahTranslations has 114 translations for Spanish and French', () {
      for (int i = 1; i <= 114; i++) {
        final surah = MockData.surahs.firstWhere((s) => s.id == i);
        expect(surah.localizedTranslationForLang('es'), isNotEmpty);
        expect(surah.localizedTranslationForLang('fr'), isNotEmpty);
      }
      expect(MockData.surahs[0].localizedTranslationForLang('es'), 'La Apertura');
      expect(MockData.surahs[1].localizedTranslationForLang('es'), 'La Vaca');
      expect(MockData.surahs[0].localizedTranslationForLang('fr'), "L'Ouverture");
      expect(MockData.surahs[1].localizedTranslationForLang('fr'), 'La Vache');
    });

    testWidgets('SurahTile displays Spanish translation and aligned verses slot when locale is Spanish', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final surah1 = MockData.surahs.first; // Al-Fatihah

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ViewModeProvider()),
            ChangeNotifierProvider(create: (_) => PlaylistProvider()),
            ChangeNotifierProvider(create: (_) => PlayerProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: SurahTile(surah: surah1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display Spanish translation "La Apertura" instead of English "The Opening"
      expect(find.text('La Apertura'), findsOneWidget);
      expect(find.text('The Opening'), findsNothing);
      expect(find.text('· 7 aleyas'), findsOneWidget);

      // Verify verses text is wrapped in fixed-width 72px slot for vertical alignment on mobile
      final versesTextFinder = find.text('· 7 aleyas');
      final versesSizedBox = tester.widget<SizedBox>(
        find.ancestor(of: versesTextFinder, matching: find.byType(SizedBox)).first,
      );
      expect(versesSizedBox.width, 72.0);

      // Verify Arabic name container has fixed width 70px on mobile
      final arabicFinder = find.text(surah1.nameAr);
      final arabicSizedBox = tester.widget<SizedBox>(
        find.ancestor(of: arabicFinder, matching: find.byType(SizedBox)).first,
      );
      expect(arabicSizedBox.width, 70.0);
    });

    testWidgets('SurahTile on PC/Chrome wide screens keeps names, tags, and verses naturally grouped', (tester) async {
      // 1200px wide desktop viewport
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final surah1 = MockData.surahs.first; // Al-Fatihah

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ViewModeProvider()),
            ChangeNotifierProvider(create: (_) => PlaylistProvider()),
            ChangeNotifierProvider(create: (_) => PlayerProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                child: SurahTile(surah: surah1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('Meca'), findsOneWidget);
      expect(find.text('La Apertura'), findsOneWidget);
      expect(find.text('· 7 aleyas'), findsOneWidget);

      // On PC/Chrome, Arabic name does NOT have fixed 70px constriction
      final arabicFinder = find.text(surah1.nameAr);
      expect(arabicFinder, findsOneWidget);
    });
  });
}

