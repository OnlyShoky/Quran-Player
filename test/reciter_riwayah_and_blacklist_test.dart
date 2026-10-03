import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukun/core/constants/reciter_blacklist.dart';
import 'package:sukun/core/models/reciter.dart';
import 'package:sukun/core/models/audio_api_source.dart';
import 'package:sukun/core/services/api_service.dart';
import 'package:sukun/shared/providers/playlist_provider.dart';

void main() {
  group('ReciterBlacklist Tests', () {
    test('Zakaria Hamamah and known 404 servers are correctly identified as broken', () {
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server9.mp3quran.net/zakariya/'), isTrue);
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server8.mp3quran.net/3zazi/'), isTrue);
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server6.mp3quran.net/muamr/'), isTrue);
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server11.mp3quran.net/wasel/Rewayat-Hafs-A-n-Assem/'), isTrue);
    });

    test('Valid servers are not blacklisted', () {
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server6.mp3quran.net/akdr/'), isFalse);
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server11.mp3quran.net/sds/'), isFalse);
      expect(ReciterBlacklist.isMp3QuranServerBroken('https://server8.mp3quran.net/afs/'), isFalse);
    });

    test('QuranicAudio broken relative paths are identified as broken', () {
      expect(ReciterBlacklist.isQuranicAudioPathBroken('sa3d_al-ghaamidi/hidayah/'), isTrue);
      expect(ReciterBlacklist.isQuranicAudioPathBroken('khalid_alghamdi/'), isTrue);
      expect(ReciterBlacklist.isQuranicAudioPathBroken('dr.shawqy_7amed/mujawwad/'), isTrue);
    });

    test('QuranicAudio valid relative paths are not broken', () {
      expect(ReciterBlacklist.isQuranicAudioPathBroken('sa3d_al-ghaamidi/complete/'), isFalse);
      expect(ReciterBlacklist.isQuranicAudioPathBroken('mahmood_khaleel_al-husaree/'), isFalse);
      expect(ReciterBlacklist.isQuranicAudioPathBroken('abdulbaset_warsh/'), isFalse);
    });
  });

  group('Riwayah Detection Tests', () {
    test('Detects Warsh by rewaya_id and text', () {
      expect(ApiService.detectRiwayah('Abdulbasit', rewayaId: 2), 'Warsh');
      expect(ApiService.detectRiwayah('AbdulBaset AbdulSamad Warsh'), 'Warsh');
      expect(ApiService.detectRiwayah('Rewayat Warsh A\'n Nafi\'', moshafName: 'Rewayat Warsh A\'n Nafi\''), 'Warsh');
    });

    test('Detects Hafs as standard default', () {
      expect(ApiService.detectRiwayah('Mishary Alafasy'), 'Hafs');
      expect(ApiService.detectRiwayah('Abdur-Rahman as-Sudais', rewayaId: 1), 'Hafs');
    });

    test('Detects Al-Duri, Qaloon, Shu\'bah, Khalaf', () {
      expect(ApiService.detectRiwayah('Mahmoud Khalil Al-Husary Doori'), 'Al-Duri');
      expect(ApiService.detectRiwayah('Some Reciter', rewayaId: 12), 'Al-Duri');
      expect(ApiService.detectRiwayah('Ali Al-Hudhaify Qaloon'), 'Qaloon');
      expect(ApiService.detectRiwayah('Some Reciter', rewayaId: 5), 'Qaloon');
      expect(ApiService.detectRiwayah('Reciter Shu\'bah'), "Shu'bah");
      expect(ApiService.detectRiwayah('Reciter Khalaf', rewayaId: 3), 'Khalaf');
    });

    test('Detects English translation', () {
      expect(ApiService.detectRiwayah('English — Ibrahim Walk'), 'English');
      expect(ApiService.detectRiwayah('Reciter with English translation'), 'English');
    });
  });

  group('Reciter Model with Riwayah', () {
    test('Reciter defaults to Hafs and retains specific riwayah', () {
      const rHafs = Reciter(
        id: 1,
        name: 'Mishary Alafasy',
        style: 'Murattal',
        serverUrl: 'https://server8.mp3quran.net/afs/',
      );
      expect(rHafs.riwayah, 'Hafs');

      const rWarsh = Reciter(
        id: 2,
        name: 'Abdulbasit Abdulsamad',
        style: 'Murattal',
        riwayah: 'Warsh',
        serverUrl: 'https://server7.mp3quran.net/basit/warsh/',
      );
      expect(rWarsh.riwayah, 'Warsh');
    });

    test('Reciter mergeWith keeps specific riwayah', () {
      const r1 = Reciter(
        id: 1,
        name: 'Abdulbasit',
        style: 'Murattal',
        riwayah: 'Warsh',
        serverUrl: 'https://mp3quran/server/',
        audioSources: [
          ReciterAudioSource(apiSource: AudioApiSource.mp3Quran, baseUrlOrPattern: 'pattern1'),
        ],
      );

      const r2 = Reciter(
        id: 2,
        name: 'Abdulbasit',
        style: 'Murattal',
        riwayah: 'Hafs',
        serverUrl: 'https://quranicaudio/server/',
        audioSources: [
          ReciterAudioSource(apiSource: AudioApiSource.quranicAudio, baseUrlOrPattern: 'pattern2'),
        ],
      );

      final merged = r1.mergeWith(r2);
      expect(merged.riwayah, 'Warsh');
      expect(merged.audioSources.length, 2);
    });
  });

  group('Reciter Pinning & Favorites Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Pinning a reciter automatically adds them to favorites', () async {
      final provider = PlaylistProvider();
      await Future.delayed(const Duration(milliseconds: 20));

      final success = await provider.togglePinReciter(101);
      expect(success, isTrue);
      expect(provider.isPinned(101), isTrue);
      expect(provider.isFavorite(101), isTrue);
    });

    test('Unpinning a reciter keeps them in favorites but removes the pin', () async {
      final provider = PlaylistProvider();
      await Future.delayed(const Duration(milliseconds: 20));

      await provider.togglePinReciter(101);
      expect(provider.isPinned(101), isTrue);
      expect(provider.isFavorite(101), isTrue);

      final unpinSuccess = await provider.togglePinReciter(101);
      expect(unpinSuccess, isTrue);
      expect(provider.isPinned(101), isFalse);
      expect(provider.isFavorite(101), isTrue); // Retains favorite
    });

    test('Enforces maximum of 3 pinned reciters', () async {
      final provider = PlaylistProvider();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(await provider.togglePinReciter(1), isTrue);
      expect(await provider.togglePinReciter(2), isTrue);
      expect(await provider.togglePinReciter(3), isTrue);
      expect(await provider.togglePinReciter(4), isFalse); // Reached limit 3

      expect(provider.pinnedReciterIds.length, 3);
    });

    test('Prunes ghost/stale IDs so users are not blocked by obsolete pins', () async {
      SharedPreferences.setMockInitialValues({
        'pinned_reciter_ids': ['9991', '9992', '9993'],
      });

      final mockReciters = [
        const Reciter(id: 101, name: 'Reciter 1', style: 'Murattal', serverUrl: 'https://test/1/'),
        const Reciter(id: 102, name: 'Reciter 2', style: 'Murattal', serverUrl: 'https://test/2/'),
      ];

      final provider = PlaylistProvider(apiService: _FakeApiService(mockReciters));
      await Future.delayed(const Duration(milliseconds: 20));

      // Trigger fetch which will load mockReciters and prune ghost IDs
      await provider.refreshReciters();

      expect(provider.pinnedReciterIds, isEmpty);

      // Now user can pin new valid reciters without hitting max limit
      expect(await provider.togglePinReciter(101), isTrue);
      expect(provider.isPinned(101), isTrue);
      expect(provider.isFavorite(101), isTrue);
    });
  });
}

class _FakeApiService extends ApiService {
  final List<Reciter> mockReciters;
  _FakeApiService(this.mockReciters);

  @override
  Future<List<Reciter>> fetchReciters({Set<AudioApiSource>? enabledSources}) async {
    return mockReciters;
  }
}
