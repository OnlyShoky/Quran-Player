import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_player/core/models/audio_api_source.dart';
import 'package:quran_player/core/models/reciter.dart';
import 'package:quran_player/core/services/reciter_normalizer.dart';
import 'package:quran_player/shared/providers/settings_provider.dart';

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

    test('Standardizes variants of Abdul Rahman Al-Sudais', () {
      const expected = 'Abdul Rahman Al-Sudais';
      expect(ReciterNormalizer.getCanonicalName('Abdul Rahman Al-Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdur-Rahman as-Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Sheikh Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Al Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdulrahman Al-Sudais'), expected);
      expect(ReciterNormalizer.getCanonicalName('Abdel Rahman as-Sudais'), expected);
    });

    test('Standardizes variants of Mishary Rashid Alafasy', () {
      const expected = 'Mishary Rashid Alafasy';
      expect(ReciterNormalizer.getCanonicalName('Mishari Rashid al-`Afasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mishary Rashid Alafasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Alafasy'), expected);
      expect(ReciterNormalizer.getCanonicalName('Mishari Alafasy'), expected);
    });

    test('Standardizes variants of Saud Al-Shuraim', () {
      const expected = 'Saud Al-Shuraim';
      expect(ReciterNormalizer.getCanonicalName('Sa`ud ash-Shuraym'), expected);
      expect(ReciterNormalizer.getCanonicalName('Saud Al-Shuraim'), expected);
      expect(ReciterNormalizer.getCanonicalName('Shuraim'), expected);
      expect(ReciterNormalizer.getCanonicalName('Saood Ash-Shuraym'), expected);
    });

    test('Standardizes variants of Mahmoud Khalil Al-Husary', () {
      const expected = 'Mahmoud Khalil Al-Husary';
      expect(ReciterNormalizer.getCanonicalName('Mahmoud Khalil Al-Husary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Husary'), expected);
      expect(ReciterNormalizer.getCanonicalName('Al-Husari'), expected);
    });

    test('Standardizes variants of Mohamed Siddiq Al-Minshawi', () {
      const expected = 'Mohamed Siddiq Al-Minshawi';
      expect(ReciterNormalizer.getCanonicalName('Mohamed Siddiq al-Minshawi'), expected);
      expect(ReciterNormalizer.getCanonicalName('Muhammad Siddiq al-Minshawi'), expected);
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

      // Verify primary URL
      expect(merged.getAudioUrl(1), 'https://server11.mp3quran.net/sds/001.mp3');
    });
  });

  group('SettingsProvider API Sources Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to all 3 audio API sources active', () async {
      final settings = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(settings.activeApiSources.length, 3);
      expect(settings.isApiSourceEnabled(AudioApiSource.mp3Quran), isTrue);
      expect(settings.isApiSourceEnabled(AudioApiSource.quranicAudio), isTrue);
      expect(settings.isApiSourceEnabled(AudioApiSource.alQuranCloud), isTrue);
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
}
