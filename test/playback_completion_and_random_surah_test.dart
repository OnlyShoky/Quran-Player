import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukun/shared/providers/player_provider.dart';
import 'package:sukun/shared/providers/playlist_provider.dart';
import 'package:sukun/shared/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_view_mode_tutorial': true,
    });
  });

  group('Random Surah and Skip Controls Tests', () {
    test('skipNext in randomSurah mode selects another surah randomly', () async {
      final settings = SettingsProvider();
      await settings.setPlaybackCompletion(PlaybackCompletionAction.randomSurah);

      final playlist = PlaylistProvider();
      playlist.addSurah(1); // Al-Fatihah (id: 1)
      playlist.addSurah(2); // Al-Baqarah (id: 2)
      playlist.addSurah(3); // Al-Imran (id: 3)
      playlist.addSurah(4); // An-Nisa (id: 4)

      final player = PlayerProvider();
      player.updatePlaylistProvider(playlist);
      player.updateSettingsProvider(settings);

      // Verify that calling skipNext chooses an index within range and different from current
      final initialIndex = player.currentIndex;
      player.skipNext();

      expect(player.currentIndex >= 0 && player.currentIndex < playlist.items.length, isTrue);
      // Since playlist has 4 items, next index must not be initialIndex
      expect(player.currentIndex, isNot(initialIndex));
    });

    test('skipNext in loopPlaylist mode wraps from last to first track', () async {
      final settings = SettingsProvider();
      await settings.setPlaybackCompletion(PlaybackCompletionAction.loopPlaylist);

      final playlist = PlaylistProvider();
      playlist.addSurah(1);
      playlist.addSurah(2);

      final player = PlayerProvider();
      player.updatePlaylistProvider(playlist);
      player.updateSettingsProvider(settings);

      // Advance to index 1 (the last item)
      player.skipNext();
      expect(player.currentIndex, 1);

      // Now skipNext should wrap back to 0
      player.skipNext();
      expect(player.currentIndex, 0);
    });

    test('skipNext in next mode does not advance beyond last track', () async {
      final settings = SettingsProvider();
      await settings.setPlaybackCompletion(PlaybackCompletionAction.next);

      final playlist = PlaylistProvider();
      playlist.addSurah(1);
      playlist.addSurah(2);

      final player = PlayerProvider();
      player.updatePlaylistProvider(playlist);
      player.updateSettingsProvider(settings);

      player.skipNext();
      expect(player.currentIndex, 1);

      // Tapping next at the end should stay at 1
      player.skipNext();
      expect(player.currentIndex, 1);
    });

    test('skipPrevious in loopPlaylist wraps to last track when at index 0', () async {
      final settings = SettingsProvider();
      await settings.setPlaybackCompletion(PlaybackCompletionAction.loopPlaylist);

      final playlist = PlaylistProvider();
      playlist.addSurah(1);
      playlist.addSurah(2);
      playlist.addSurah(3);

      final player = PlayerProvider();
      player.updatePlaylistProvider(playlist);
      player.updateSettingsProvider(settings);

      expect(player.currentIndex, 0);
      player.skipPrevious();
      expect(player.currentIndex, 2);
    });

    test('skipPrevious in randomSurah mode selects another surah randomly', () async {
      final settings = SettingsProvider();
      await settings.setPlaybackCompletion(PlaybackCompletionAction.randomSurah);

      final playlist = PlaylistProvider();
      playlist.addSurah(1);
      playlist.addSurah(2);
      playlist.addSurah(3);

      final player = PlayerProvider();
      player.updatePlaylistProvider(playlist);
      player.updateSettingsProvider(settings);

      expect(player.currentIndex, 0);
      player.skipPrevious();
      expect(player.currentIndex >= 0 && player.currentIndex < playlist.items.length, isTrue);
      expect(player.currentIndex, isNot(0));
    });
  });
}
