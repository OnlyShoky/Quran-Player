import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/audio_api_source.dart';
import '../models/reciter.dart';
import 'reciter_normalizer.dart';

class ApiService {
  static const String _mp3QuranBaseUrl = 'https://mp3quran.net/api/v3';
  static const String _quranicAudioBaseUrl = 'https://quranicaudio.com/api';
  static const String _alQuranCloudBaseUrl = 'https://api.alquran.cloud/v1';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

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

          // Prioritize:
          // 1. Full 114 surahs
          // 2. Standard Hafs recitation
          // 3. Highest surah count
          validMoshafs.sort((a, b) {
            final aTotal = (a['surah_total'] as num?)?.toInt() ?? 0;
            final bTotal = (b['surah_total'] as num?)?.toInt() ?? 0;
            final aName = (a['name'] as String? ?? '').toLowerCase();
            final bName = (b['name'] as String? ?? '').toLowerCase();
            final aHafs = aName.contains('hafs');
            final bHafs = bName.contains('hafs');

            if (aTotal == 114 && bTotal != 114) return -1;
            if (bTotal == 114 && aTotal != 114) return 1;
            if (aHafs && !bHafs && aTotal > 0) return -1;
            if (!aHafs && bHafs && bTotal > 0) return 1;
            return bTotal.compareTo(aTotal);
          });

          final moshaf = validMoshafs.first;
          final serverUrl = moshaf['server'] as String? ?? '';
          if (serverUrl.isEmpty) continue;

          final moshafName = moshaf['name'] as String? ?? '';
          final isMujawwad = moshafName.toLowerCase().contains('mujawwad');
          final style = isMujawwad ? 'Mujawwad' : 'Murattal';

          final rawName = item['name'] as String? ?? '';
          if (rawName.isEmpty) continue;

          final id = (item['id'] as num?)?.toInt() ?? 0;

          final audioSources = <ReciterAudioSource>[
            ReciterAudioSource(
              apiSource: AudioApiSource.mp3Quran,
              baseUrlOrPattern: serverUrl,
            ),
          ];

          // Add any alternative complete server (114 surahs) as fallback
          for (var m = 1; m < validMoshafs.length; m++) {
            final altServer = validMoshafs[m]['server'] as String? ?? '';
            final altTotal = (validMoshafs[m]['surah_total'] as num?)?.toInt() ?? 0;
            if (altServer.isNotEmpty && altServer != serverUrl && altTotal >= 114) {
              audioSources.add(ReciterAudioSource(
                apiSource: AudioApiSource.mp3Quran,
                baseUrlOrPattern: altServer,
              ));
              break;
            }
          }

          reciters.add(Reciter(
            id: id,
            name: rawName,
            style: style,
            serverUrl: serverUrl,
            audioSources: audioSources,
          ));
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
    try {
      final response = await _client.get(
        Uri.parse('$_quranicAudioBaseUrl/qaris'),
      );

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List? ?? [];
        final reciters = <Reciter>[];

        for (final item in list) {
          final relPath = item['relative_path'] as String? ?? '';
          if (relPath.isEmpty) continue;

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

          final arabicName = item['arabic_name'] as String?;
          final rawId = (item['id'] as num?)?.toInt() ?? 0;

          reciters.add(Reciter(
            id: 100000 + rawId, // offset ID to avoid collision before deduplication
            name: rawName,
            style: style,
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
    } catch (e) {
      debugPrint('QuranicAudio fetch error: $e');
    }
    return [];
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

          final cleanId = identifier.replaceAll('-surah', '');
          final serverUrl = 'https://cdn.islamic.network/quran/audio-surah/128/$cleanId/';

          reciters.add(Reciter(
            id: ++syntheticId,
            name: rawName,
            style: style,
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

      // Group strictly by canonical identity + style (Murattal vs Mujawwad)
      final groupKey = '$canonicalKey:${r.style.toLowerCase()}';

      if (mergedMap.containsKey(groupKey)) {
        final existing = mergedMap[groupKey]!;
        mergedMap[groupKey] = existing.mergeWith(r);
      } else {
        // Generate a stable numeric ID derived from canonicalKey + style hash
        final stableId = _generateStableId(groupKey);
        mergedMap[groupKey] = Reciter(
          id: stableId,
          name: canonicalName,
          style: r.style,
          serverUrl: r.serverUrl,
          arabicName: r.arabicName,
          audioSources: List<ReciterAudioSource>.from(r.audioSources),
        );
      }
    }

    final list = mergedMap.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
