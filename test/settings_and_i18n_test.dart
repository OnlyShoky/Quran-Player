import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:quran_player/core/localization/app_localizations.dart';
import 'package:quran_player/shared/providers/settings_provider.dart';
import 'package:quran_player/shared/providers/view_mode_provider.dart';
import 'package:quran_player/shared/providers/player_provider.dart';
import 'package:quran_player/shared/providers/playlist_provider.dart';
import 'package:quran_player/features/settings/settings_screen.dart';
import 'package:quran_player/shared/widgets/playback_mode_button.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLocalizations Translations', () {
    test('resolves translation keys across all 4 languages', () {
      final en = AppLocalizations(const Locale('en'));
      final es = AppLocalizations(const Locale('es'));
      final fr = AppLocalizations(const Locale('fr'));
      final ar = AppLocalizations(const Locale('ar'));

      // Check settings title
      expect(en.translate('settings_title'), 'Settings');
      expect(es.translate('settings_title'), 'Configuración');
      expect(fr.translate('settings_title'), 'Paramètres');
      expect(ar.translate('settings_title'), 'الإعدادات');

      // Check view mode keys
      expect(en.translate('view_list'), 'List');
      expect(es.translate('view_list'), 'Lista');
      expect(fr.translate('view_list'), 'Liste');
      expect(ar.translate('view_list'), 'قائمة');

      // Check parameterized verses count
      expect(en.translate('verses_count', {'count': '7'}), '7 Ayahs');
      expect(es.translate('verses_count', {'count': '7'}), '7 aleyas');
      expect(fr.translate('verses_count', {'count': '7'}), '7 versets');
      expect(ar.translate('verses_count', {'count': '7'}), '7 آية');
    });
  });

  group('SettingsProvider State & Persistence', () {
    test('default values are system theme, null locale (system), and next playback', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.locale, isNull);
      expect(settings.playbackCompletion, PlaybackCompletionAction.next);
    });

    test('updates theme mode and persists to SharedPreferences', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');

      await settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('updates locale and persists', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await settings.setLocale(const Locale('ar'));
      expect(settings.locale?.languageCode, 'ar');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'ar');

      await settings.setLocale(null);
      expect(settings.locale, isNull);
      expect(prefs.getString('app_locale'), 'system');
    });

    test('updates playback completion action and persists', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await settings.setPlaybackCompletion(PlaybackCompletionAction.repeat);
      expect(settings.playbackCompletion, PlaybackCompletionAction.repeat);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_playback_completion'), 'repeat');
    });
  });

  group('PlayerProvider Stop & Dismiss Behavior', () {
    test('stop() resets playback state, sets isDismissed, and resets position', () {
      final player = PlayerProvider();
      player.stop();

      expect(player.state, PlaybackState.stopped);
      expect(player.isDismissed, isTrue);
      expect(player.position, Duration.zero);
      expect(player.progress, 0.0);
    });

    test('adding surah to playlist un-dismisses and prepares queued surah', () {
      final playlist = PlaylistProvider();
      final player = PlayerProvider();
      player.updatePlaylistProvider(playlist);

      // Initially empty playlist, dismissed
      player.stop();
      expect(player.isDismissed, isTrue);

      // Add a surah (e.g. Al-Fatihah, id 1)
      playlist.addSurah(1);
      player.updatePlaylistProvider(playlist);

      // Now un-dismissed and resolves Al-Fatihah
      expect(player.isDismissed, isFalse);
      expect(player.currentSurah?.id, 1);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all settings sections and allows changing settings',
        (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      final viewModeProvider = ViewModeProvider();

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: viewModeProvider),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section headers in English
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Playback'), findsNothing); // Playback was moved to player bars
      expect(find.text('Tutorial & Help'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Check languages are listed
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);

      // Tap on Español to switch language
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(settingsProvider.locale?.languageCode, 'es');

      // Tap Reset Tutorial button
      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(viewModeProvider.hasSeenTutorial, isFalse);
    });

    testWidgets('PlaybackModeButton toggles between Next and Repeat on tap',
        (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settingsProvider,
          child: const MaterialApp(
            locale: Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Center(
                child: PlaybackModeButton(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state: next
      expect(settingsProvider.playbackCompletion, PlaybackCompletionAction.next);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

      // Tap to switch to repeat
      await tester.tap(find.byType(PlaybackModeButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(settingsProvider.playbackCompletion, PlaybackCompletionAction.repeat);
      expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);

      // Tap to toggle back to next
      await tester.tap(find.byType(PlaybackModeButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(settingsProvider.playbackCompletion, PlaybackCompletionAction.next);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    });
  });
}
