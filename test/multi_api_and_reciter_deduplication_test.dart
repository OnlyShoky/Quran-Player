import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_player/core/models/audio_api_source.dart';
import 'package:quran_player/core/models/reciter.dart';
import 'package:quran_player/core/services/reciter_normalizer.dart';
import 'package:quran_player/shared/providers/settings_provider.dart';
import 'package:quran_player/shared/providers/player_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReciterNormalizer Tests', () {
    test('Cleans titles, prefixes, and brackets', () {
      expect(ReciterNormalizer.cleanRawName('Sheikh Abdul Rahman Al-Sudais'), 'Abdul Rahman Al-Sudais');
      expect(ReciterNormalizer.cleanRawName('Dr. Ahmed Al-Ajmi'), 'Ahmed Al-Ajmi');
      expect(ReciterNormalizer.cleanRawName('Qari Abdul Basit [128Kbps]'), 'Abdul Basit');
      expect(ReciterNormalizer.cleanRawName('Mahmoud Khalil Al-Husary (Murattal)'), 'Mahmoud Khalil Al-Husary');
      expect(ReciterNormalizer.cleanRawName('Imam Saud Al-Shuraim'), 'Saud Al-Shuraim');
    });

    test('Standardizes variants of Abdul Rahman Al-Sudais including MP3Quran Alsudaes', () {
      const expected = 'Abdul Rahman Al-Sudais';
      expect(ReciterNormalizer.getCanonicalName('Abdulrahman Alsudaes'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdul Rahman Al-Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdur-Rahman as-Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Sheikh Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Al Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Alsudaes'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdulrahman Al-Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdel Rahman as-Sudais'), expected);
    });

    test('Standardizes variants of Yasser Al-Dosari and ensures identical group key', () {
      const expected = 'Yasser Al-Dosari';
      expect(ReciterNormalizer.getCanonicalName('Yasser Al-Dosari'), expected);
      expect(ReciterNormalizer.getCanonicalName('Yasser ad-Dossari'), expected);
      expect(ReciterNormalizer.getCanonicalName('Yasser ad-Dussary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Yasser Aldosari'), expected);

      // Verify group key parity for deduplication
      final key1 = '${ReciterNormalizer.getMatchKey(ReciterNormalizer.getCanonicalName("Yasser Al-Dosari"))}:murattal';
      final key2 = '${ReciterNormalizer.getMatchKey(ReciterNormalizer.getCanonicalName("Yasser ad-Dussary"))}:murattal';
      final key3 = '${ReciterNormalizer.getMatchKey(ReciterNormalizer.getCanonicalName("Yasser ad-Dossari"))}:murattal';

      expect(key1, key2);
      expect(key2, key3);
    });

    test('Standardizes variants of Mishary Rashid Alafasy', () {
      const expected = 'Mishary Rashid Alafasy';
      expect(ReciterNormalizer.getCanonicalName('Mishari Rashid al-`Afasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mishary Rashid Alafasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Alafasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mishari Alafasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mishari Alafasi'), expected);
    });

    test('Standardizes variants of Saud Al-Shuraim', () {
      const expected = 'Saud Al-Shuraim';
      expect(ReciterNormalizer.getCanonicalName('Sa`ud ash-Shuraym'), expected);
      expect(ReciterNormalizer.getCanonicalName('Saud Al-Shuraim'), expected);
      expect(ReciterNormalizer.getCanonicalName('Shuraim'), expected);
      expect(ReciterNormalizer.getCanonicalName('Saood Ash-Shuraym'), expected);
      expect(ReciterNormalizer.getCanonicalName('Saud Alshuraim'), expected);
    });

    test('Standardizes variants of Mahmoud Khalil Al-Husary', () {
      const expected = 'Mahmoud Khalil Al-Husary';
      expect(ReciterNormalizer.getCanonicalName('Mahmoud Khalil Al-Husary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mahmoud Khaleel Al-Husary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mahmoud Khalil Al-Hussary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Husary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Al-Husari'), expected);
    });

    test('Standardizes variants of Mohamed Siddiq Al-Minshawi', () {
      const expected = 'Mohamed Siddiq Al-Minshawi';
      expect(ReciterNormalizer.getCanonicalName('Mohamed Siddiq al-Minshawi'), expected);
      expect(ReciterNormalizer.getCanonicalName('Muhammad Siddiq al-Minshawi'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mohammed Siddiq Al-Minshawi'), expected);
      expect(ReciterNormalizer.getCanonicalName('Minshawi'), expected);
      expect(ReciterNormalizer.getCanonicalName('Minshawy'), expected);
    });
  });

  group('Multi-Source Reciter & Fallback Tests', () {
    test('Reciter merged across 3 sources provides candidate URLs in order', () {
      final reciterMp3Quran = Reciter(
        id: 1,
        name: 'Abdul Rahman Al-Sudais',
        style: 'Murattal',
        serverUrl: 'https://server11.mp3quran.net/sds/',
        audioSources: const [
          ReciterAudioSource(
            apiSource: AudioApiSource.mp3Quran,
            baseUrlOrPattern: 'https://server11.mp3quran.net/sds/',
          ),
        ],
      );

      final reciterQuranicAudio = Reciter(
        id: 2,
        name: 'Abdur-Rahman as-Sudais',
        style: 'Murattal',
        serverUrl: 'https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays/',
        audioSources: const [
          ReciterAudioSource(
            apiSource: AudioApiSource.quranicAudio,
            baseUrlOrPattern: 'abdurrahmaan_as-sudays/',
          ),
        ],
      );

      final reciterAlQuranCloud = Reciter(
        id: 3,
        name: 'Sudais',
        style: 'Murattal',
        serverUrl: 'https://cdn.islamic.network/quran/audio-surah/128/ar.abdurrahmaansudais/',
        audioSources: const [
          ReciterAudioSource(
            apiSource: AudioApiSource.alQuranCloud,
            baseUrlOrPattern: 'ar.abdurrahmaansudais',
          ),
        ],
      );

      // Merge them
      final merged = reciterMp3Quran
          .mergeWith(reciterQuranicAudio)
          .mergeWith(reciterAlQuranCloud);

      expect(merged.audioSources.length, 3);
      expect(merged.audioSources[0].apiSource, AudioApiSource.mp3Quran);
      expect(merged.audioSources[1].apiSource, AudioApiSource.quranicAudio);
      expect(merged.audioSources[2].apiSource, AudioApiSource.alQuranCloud);

      // Verify all candidate URLs for Surah 1 (Al-Fatiha)
      final candidates = merged.getAllCandidateAudioUrls(1);
      expect(candidates.length, 3);
      expect(candidates[0], 'https://server11.mp3quran.net/sds/001.mp3');
      expect(candidates[1], 'https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays/001.mp3');
      expect(candidates[2], 'https://cdn.islamic.network/quran/audio-surah/128/ar.abdurrahmaansudais/1.mp3');

      // Verify CandidateAudioSource paired with AudioApiSource
      final candidateSources = merged.getAllCandidateAudioSources(1);
      expect(candidateSources.length, 3);
      expect(candidateSources[0].apiSource, AudioApiSource.mp3Quran);
      expect(candidateSources[1].apiSource, AudioApiSource.quranicAudio);
      expect(candidateSources[2].apiSource, AudioApiSource.alQuranCloud);

      // Verify primary URL
      expect(merged.getAudioUrl(1), 'https://server11.mp3quran.net/sds/001.mp3');
    });
  });

  group('SettingsProvider API Sources Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to all 3 audio API sources active and player badge enabled', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(settings.activeApiSources.length, 3);
      expect(settings.isApiSourceEnabled(AudioApiSource.mp3Quran), isTrue);
      expect(settings.isApiSourceEnabled(AudioApiSource.quranicAudio), isTrue);
      expect(settings.isApiSourceEnabled(AudioApiSource.alQuranCloud), isTrue);
      expect(settings.showApiSourceInPlayer, isTrue);
    });

    test('Can toggle showApiSourceInPlayer setting', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(settings.showApiSourceInPlayer, isTrue);
      await settings.setShowApiSourceInPlayer(false);
      expect(settings.showApiSourceInPlayer, isFalse);

      await settings.setShowApiSourceInPlayer(true);
      expect(settings.showApiSourceInPlayer, isTrue);
    });

    test('Can toggle source off and on', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final toggled = await settings.toggleApiSource(AudioApiSource.mp3Quran);
      expect(toggled, isTrue);
      expect(settings.isApiSourceEnabled(AudioApiSource.mp3Quran), isFalse);
      expect(settings.activeApiSources.length, 2);

      final toggledBack = await settings.toggleApiSource(AudioApiSource.mp3Quran);
      expect(toggledBack, isTrue);
      expect(settings.isApiSourceEnabled(AudioApiSource.mp3Quran), isTrue);
      expect(settings.activeApiSources.length, 3);
    });

    test('Prevents disabling the last remaining audio source', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Disable 2 sources
      await settings.toggleApiSource(AudioApiSource.mp3Quran);
      await settings.toggleApiSource(AudioApiSource.quranicAudio);
      expect(settings.activeApiSources.length, 1);
      expect(settings.isApiSourceEnabled(AudioApiSource.alQuranCloud), isTrue);

      // Attempting to disable the 3rd source must fail
      final result = await settings.toggleApiSource(AudioApiSource.alQuranCloud);
      expect(result, isFalse);
      expect(settings.activeApiSources.length, 1);
      expect(settings.isApiSourceEnabled(AudioApiSource.alQuranCloud), isTrue);
    });
  });

  group('Moshaf Selection & Reciter Switching Tests', () {
    test('Reciter.fromJson prioritizes 114-surah Hafs moshaf over incomplete moshafs', () {
      final json = {
        'id': 123,
        'name': 'Mishary Alafasi',
        'moshaf': [
          {
            'id': 1,
            'name': "Rewayat AlDorai A'n Al-Kisa'ai - Murattal",
            'server': 'https://server8.mp3quran.net/afs/Rewayat-AlDorai-A-n-Al-Kisa-ai/',
            'surah_total': 6,
          },
          {
            'id': 2,
            'name': "Rewayat Hafs A'n Assem - Murattal",
            'server': 'https://server8.mp3quran.net/afs/',
            'surah_total': 114,
          },
        ],
      };

      final reciter = Reciter.fromJson(json);
      expect(reciter.serverUrl, 'https://server8.mp3quran.net/afs/');
      expect(reciter.getAudioUrl(1), 'https://server8.mp3quran.net/afs/001.mp3');
      expect(reciter.style, 'Murattal');
    });

    test('PlayerProvider.selectReciter updates active reciter', () {
      final player = PlayerProvider();
      const reciter1 = Reciter(
        id: 1,
        name: 'Abdul Rahman Al-Sudais',
        style: 'Murattal',
        serverUrl: 'https://server11.mp3quran.net/sds/',
      );
      const reciter2 = Reciter(
        id: 2,
        name: 'Mishary Rashid Alafasy',
        style: 'Murattal',
        serverUrl: 'https://server8.mp3quran.net/afs/',
      );

      player.selectReciter(reciter1);
      expect(player.currentReciter?.name, 'Abdul Rahman Al-Sudais');

      player.selectReciter(reciter2);
      expect(player.currentReciter?.name, 'Mishary Rashid Alafasy');
    });
  });
}

