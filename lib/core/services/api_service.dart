import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/reciter_blacklist.dart';
import '../models/audio_api_source.dart';
import '../models/reciter.dart';
import '../data/quranic_audio_data.dart';
import 'reciter_normalizer.dart';

class ApiService {
  static const String _mp3QuranBaseUrl = 'https://mp3quran.net/api/v3';
  static const String _quranicAudioBaseUrl = 'https://quranicaudio.com/api';
  static const String _alQuranCloudBaseUrl = 'https://api.alquran.cloud/v1';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Detects the recitation type (Riwayah) or language from name and metadata.
  static String detectRiwayah(String name, {int? rewayaId, String? moshafName}) {
    if (rewayaId != null) {
      switch (rewayaId) {
        case 1:
        case 21:
        case 22:
          return 'Hafs';
        case 2:
        case 10:
        case 18:
          return 'Warsh';
        case 3:
          return 'Khalaf';
        case 4:
        case 11:
          return 'Al-Bazzi';
        case 5:
        case 8:
          return 'Qaloon';
        case 6:
          return 'Qunbul';
        case 7:
          return 'Al-Sousi';
        case 9:
          return 'Rawh';
        case 12:
        case 13:
          return 'Al-Duri';
        case 15:
          return "Shu'bah";
        case 16:
          return 'Ibn Thakwan';
        case 19:
          return 'Hesham';
        case 20:
          return 'Ibn Jammaz';
      }
    }

    final lower = '${moshafName ?? ''} $name'.toLowerCase();
    if (lower.contains('english') || lower.contains('translation')) return 'English';
    if (lower.contains('spanish') || lower.contains('español') || lower.contains('espanol')) return 'Spanish';
    if (lower.contains('warsh') || lower.contains('warch')) return 'Warsh';
    if (lower.contains('qaloon') || lower.contains('qalon') || lower.contains('qalun')) return 'Qaloon';
    if (lower.contains('al-duri') || lower.contains('alduri') || lower.contains('doori') || lower.contains('duri') || lower.contains('dorai')) {
      return 'Al-Duri';
    }
    if (lower.contains('khalaf')) return 'Khalaf';
    if (lower.contains("shu'bah") || lower.contains('shubah') || lower.contains("sho'bah") || lower.contains('shoubah')) {
      return "Shu'bah";
    }
    if (lower.contains('sousi') || lower.contains('sosi') || lower.contains('soosi')) return 'Al-Sousi';
    if (lower.contains('bazzi')) return 'Al-Bazzi';
    if (lower.contains('qunbul') || lower.contains('qunbol')) return 'Qunbul';
    if (lower.contains('hesham')) return 'Hesham';
    if (lower.contains('thakwan')) return 'Ibn Thakwan';
    if (lower.contains('jammaz')) return 'Ibn Jammaz';
    if (lower.contains('rawh') || lower.contains('ruwais') || lower.contains('rowis')) return 'Rawh';
    return 'Hafs';
  }

  /// Fetches and merges reciters from all specified active audio API sources.
  Future<List<Reciter>> fetchReciters({
    Set<AudioApiSource>? enabledSources,
  }) async {
    final active = enabledSources ??
        {
          AudioApiSource.mp3Quran,
          AudioApiSource.quranicAudio,
          AudioApiSource.alQuranCloud,
        };

    if (active.isEmpty) {
      return [];
    }

    final futures = <Future<List<Reciter>>>[];

    if (active.contains(AudioApiSource.mp3Quran)) {
      futures.add(_fetchMp3QuranReciters());
    }
    if (active.contains(AudioApiSource.quranicAudio)) {
      futures.add(_fetchQuranicAudioReciters());
    }
    if (active.contains(AudioApiSource.alQuranCloud)) {
      futures.add(_fetchAlQuranCloudReciters());
    }

    try {
      final results = await Future.wait(futures);
      final rawList = results.expand((list) => list).toList();
      return _deduplicateAndSortReciters(rawList);
    } catch (e) {
      debugPrint('ApiService.fetchReciters error: $e');
      return [];
    }
  }

  /// 1. MP3Quran.net
  Future<List<Reciter>> _fetchMp3QuranReciters() async {
    try {
      final response = await _client.get(
        Uri.parse('$_mp3QuranBaseUrl/reciters?language=eng'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['reciters'] as List? ?? [];
        final reciters = <Reciter>[];

        for (final item in list) {
          final moshafList = item['moshaf'] as List? ?? [];
          if (moshafList.isEmpty) continue;

          final validMoshafs = moshafList.whereType<Map<String, dynamic>>().toList();
          if (validMoshafs.isEmpty) continue;

          final rawName = item['name'] as String? ?? '';
          if (rawName.isEmpty) continue;

          final rawId = (item['id'] as num?)?.toInt() ?? 0;

          // Group available moshafs by (riwayah, style) to capture all recitations
          final Map<String, List<Map<String, dynamic>>> moshafsByGroup = {};

          for (final m in validMoshafs) {
            final server = m['server'] as String? ?? '';
            if (server.isEmpty || ReciterBlacklist.isMp3QuranServerBroken(server)) {
              continue;
            }

            final moshafName = m['name'] as String? ?? '';
            final rewayaId = (m['rewaya_id'] as num?)?.toInt();
            final riwayah = detectRiwayah(rawName, rewayaId: rewayaId, moshafName: moshafName);
            final isMujawwad = moshafName.toLowerCase().contains('mujawwad');
            final style = isMujawwad ? 'Mujawwad' : 'Murattal';

            final key = '$riwayah:$style';
            moshafsByGroup.putIfAbsent(key, () => []).add(m);
          }

          if (moshafsByGroup.isEmpty) continue;

          int variantIndex = 0;
          for (final entry in moshafsByGroup.entries) {
            final groupMoshafs = entry.value;

            // Sort: highest surah_total first
            groupMoshafs.sort((a, b) {
              final aTotal = (a['surah_total'] as num?)?.toInt() ?? 0;
              final bTotal = (b['surah_total'] as num?)?.toInt() ?? 0;
              return bTotal.compareTo(aTotal);
            });

            final primaryMoshaf = groupMoshafs.first;
            final serverUrl = primaryMoshaf['server'] as String? ?? '';
            if (serverUrl.isEmpty) continue;

            final parts = entry.key.split(':');
            final riwayah = parts[0];
            final style = parts[1];

            final audioSources = <ReciterAudioSource>[
              ReciterAudioSource(
                apiSource: AudioApiSource.mp3Quran,
                baseUrlOrPattern: serverUrl,
              ),
            ];

            // Add alternative server if available for fallback
            for (var m = 1; m < groupMoshafs.length; m++) {
              final altServer = groupMoshafs[m]['server'] as String? ?? '';
              final altTotal = (groupMoshafs[m]['surah_total'] as num?)?.toInt() ?? 0;
              if (altServer.isNotEmpty && altServer != serverUrl && altTotal >= 114) {
                audioSources.add(ReciterAudioSource(
                  apiSource: AudioApiSource.mp3Quran,
                  baseUrlOrPattern: altServer,
                ));
                break;
              }
            }

            reciters.add(Reciter(
              id: rawId + (variantIndex * 1000000),
              name: rawName,
              style: style,
              riwayah: riwayah,
              serverUrl: serverUrl,
              audioSources: audioSources,
            ));
            variantIndex++;
          }
        }

        return reciters;
      }
    } catch (e) {
      debugPrint('MP3Quran fetch error: $e');
    }
    return [];
  }

  /// 2. QuranicAudio.com
  Future<List<Reciter>> _fetchQuranicAudioReciters() async {
    List? list;
    if (!kIsWeb) {
      try {
        final response = await _client.get(
          Uri.parse('$_quranicAudioBaseUrl/qaris'),
        );

        if (response.statusCode == 200) {
          list = json.decode(response.body) as List?;
        }
      } catch (e) {
        debugPrint('QuranicAudio live fetch unavailable: $e — using bundled data');
      }
    }

    // On Web (browser CORS restricts direct API fetch) or when offline on mobile,
    // use the curated bundled dataset.
    final source = list ?? kQuranicAudioQaris;
    final reciters = <Reciter>[];

    for (final item in source) {
      final relPath = item['relative_path'] as String? ?? '';
      if (relPath.isEmpty || ReciterBlacklist.isQuranicAudioPathBroken(relPath)) {
        continue;
      }

      final rawName = item['name'] as String? ?? '';
      if (rawName.isEmpty) continue;

      // Exclude multi-imam / Taraweeh compilations and joint translations
      final lower = rawName.toLowerCase();
      if (lower.contains('taraweeh') ||
          lower.contains('translation') ||
          lower.contains(' with ') ||
          lower.contains(' and ')) {
        continue;
      }

      final isMujawwad = lower.contains('mujawwad');
      final style = isMujawwad ? 'Mujawwad' : 'Murattal';
      final riwayah = detectRiwayah(rawName);

      final arabicName = item['arabic_name'] as String?;
      final rawId = (item['id'] as num?)?.toInt() ?? 0;

      reciters.add(Reciter(
        id: 100000 + rawId, // offset ID to avoid collision before deduplication
        name: rawName,
        style: style,
        riwayah: riwayah,
        serverUrl: 'https://download.quranicaudio.com/quran/$relPath',
        arabicName: arabicName,
        audioSources: [
          ReciterAudioSource(
            apiSource: AudioApiSource.quranicAudio,
            baseUrlOrPattern: relPath,
          ),
        ],
      ));
    }

    return reciters;
  }

  /// 3. AlQuran Cloud
  Future<List<Reciter>> _fetchAlQuranCloudReciters() async {
    try {
      final response = await _client.get(
        Uri.parse('$_alQuranCloudBaseUrl/edition?format=audio'),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final list = body['data'] as List? ?? [];
        final reciters = <Reciter>[];

        int syntheticId = 200000;
        for (final item in list) {
          final type = item['type'] as String? ?? '';
          final format = item['format'] as String? ?? '';
          final lang = item['language'] as String? ?? '';

          // Only whole-surah Arabic audio recitations
          if (type != 'surahbysurah' || format != 'audio' || lang != 'ar') {
            continue;
          }

          final identifier = item['identifier'] as String? ?? '';
          if (identifier.isEmpty) continue;

          final rawName = item['englishName'] as String? ?? '';
          if (rawName.isEmpty) continue;

          // Exclude translations
          if (rawName.toLowerCase().contains('translation') ||
              rawName.toLowerCase().contains('traduit')) {
            continue;
          }

          final arabicName = item['name'] as String?;
          final isMujawwad = rawName.toLowerCase().contains('mujawwad') ||
              identifier.toLowerCase().contains('mujawwad');
          final style = isMujawwad ? 'Mujawwad' : 'Murattal';
          final riwayah = detectRiwayah('$rawName $identifier');

          final cleanId = identifier.replaceAll('-surah', '');
          final serverUrl = 'https://cdn.islamic.network/quran/audio-surah/128/$cleanId/';

          reciters.add(Reciter(
            id: ++syntheticId,
            name: rawName,
            style: style,
            riwayah: riwayah,
            serverUrl: serverUrl,
            arabicName: arabicName,
            audioSources: [
              ReciterAudioSource(
                apiSource: AudioApiSource.alQuranCloud,
                baseUrlOrPattern: cleanId,
              ),
            ],
          ));
        }

        return reciters;
      }
    } catch (e) {
      debugPrint('AlQuran Cloud fetch error: $e');
    }
    return [];
  }

  /// Deduplicate reciters from multiple sources, normalize names, and aggregate audio fallback sources.
  List<Reciter> _deduplicateAndSortReciters(List<Reciter> rawReciters) {
    final Map<String, Reciter> mergedMap = {};

    for (final r in rawReciters) {
      final canonicalName = ReciterNormalizer.getCanonicalName(r.name);
      final canonicalKey = ReciterNormalizer.getMatchKey(canonicalName);
      if (canonicalKey.isEmpty) continue;

      // Group strictly by canonical identity + riwayah + style
      final groupKey = '$canonicalKey:${r.riwayah.toLowerCase()}:${r.style.toLowerCase()}';

      if (mergedMap.containsKey(groupKey)) {
        final existing = mergedMap[groupKey]!;
        mergedMap[groupKey] = existing.mergeWith(r);
      } else {
        // Generate a stable numeric ID derived from canonicalKey + riwayah + style hash
        final stableId = _generateStableId(groupKey);
        mergedMap[groupKey] = Reciter(
          id: stableId,
          name: canonicalName,
          style: r.style,
          riwayah: r.riwayah,
          serverUrl: r.serverUrl,
          arabicName: r.arabicName,
          audioSources: List<ReciterAudioSource>.from(r.audioSources),
        );
      }
    }

    final list = mergedMap.values.toList();
    list.sort((a, b) {
      final nameCmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (nameCmp != 0) return nameCmp;
      return a.riwayah.compareTo(b.riwayah);
    });
    return list;
  }

  /// Generate a positive 32-bit stable integer hash for a string key compatible with web (JS)
  int _generateStableId(String key) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < key.length; i++) {
      hash ^= key.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }
}
