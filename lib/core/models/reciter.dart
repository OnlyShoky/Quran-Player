import 'audio_api_source.dart';

/// Represents a Quran reciter, possibly aggregated across multiple audio providers.
class Reciter {
  final int id;
  final String name;
  final String style; // e.g. "Murattal", "Mujawwad"
  final String serverUrl;
  final String? arabicName;
  final List<ReciterAudioSource> audioSources;

  const Reciter({
    required this.id,
    required this.name,
    required this.style,
    required this.serverUrl,
    this.arabicName,
    this.audioSources = const [],
  });

  String get shortName {
    final clean = name.replaceAll(RegExp(r'^(Dr\.|Sheikh|Shaykh|Qari|Imam)\s+', caseSensitive: false), '').trim();
    final parts = clean.split(' ');
    if (parts.isEmpty) return name;
    if (parts.length == 1) return parts[0];
    if ((parts[0].toLowerCase() == 'abdul' || parts[0].toLowerCase() == 'abdel' || parts[0].toLowerCase() == 'abu') && parts.length > 1) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts[0];
  }

  String get initials {
    final clean = name.replaceAll(RegExp(r'^(Dr\.|Sheikh|Shaykh|Qari|Imam)\s+', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'[\s\-]+'));
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Get primary audio URL for a given surah.
  String getAudioUrl(int surahId, [int sourceIndex = 0]) {
    if (audioSources.isNotEmpty) {
      final safeIndex = sourceIndex.clamp(0, audioSources.length - 1);
      return audioSources[safeIndex].getAudioUrl(surahId);
    }
    var server = serverUrl.trim();
    if (!server.endsWith('/')) {
      server = '$server/';
    }
    final surahNum = surahId.toString().padLeft(3, '0');
    return '$server$surahNum.mp3';
  }

  /// Returns candidate audio URLs across all integrated providers for fallback playback.
  List<String> getAllCandidateAudioUrls(int surahId) {
    if (audioSources.isEmpty) {
      final defaultUrl = getAudioUrl(surahId);
      return defaultUrl.isNotEmpty ? [defaultUrl] : [];
    }

    final urls = <String>[];
    for (final src in audioSources) {
      final u = src.getAudioUrl(surahId);
      if (u.isNotEmpty && !urls.contains(u)) {
        urls.add(u);
      }
    }
    return urls;
  }

  /// Copies this reciter with additional or updated audio sources.
  Reciter copyWith({
    int? id,
    String? name,
    String? style,
    String? serverUrl,
    String? arabicName,
    List<ReciterAudioSource>? audioSources,
  }) {
    return Reciter(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      serverUrl: serverUrl ?? this.serverUrl,
      arabicName: arabicName ?? this.arabicName,
      audioSources: audioSources ?? this.audioSources,
    );
  }

  /// Merge another instance of the same reciter (from a different API provider).
  Reciter mergeWith(Reciter other) {
    final mergedSources = List<ReciterAudioSource>.from(audioSources);
    for (final src in other.audioSources) {
      if (!mergedSources.any((s) => s.apiSource == src.apiSource)) {
        mergedSources.add(src);
      }
    }

    return Reciter(
      id: id,
      name: name, // Keep canonical name
      style: style.isNotEmpty ? style : other.style,
      serverUrl: serverUrl.isNotEmpty ? serverUrl : other.serverUrl,
      arabicName: arabicName ?? other.arabicName,
      audioSources: mergedSources,
    );
  }

  factory Reciter.fromJson(Map<String, dynamic> json) {
    String serverUrl = '';
    String style = '';

    if (json['moshaf'] != null && (json['moshaf'] as List).isNotEmpty) {
      final moshaf = json['moshaf'][0];
      serverUrl = moshaf['server'] ?? '';
      final moshafName = moshaf['name'] as String? ?? '';
      if (moshafName.toLowerCase().contains('mujawwad')) {
        style = 'Mujawwad';
      } else {
        style = 'Murattal';
      }
    }

    final reciterId = json['id'] as int;
    final name = json['name'] as String;

    return Reciter(
      id: reciterId,
      name: name,
      style: style,
      serverUrl: serverUrl,
      audioSources: serverUrl.isNotEmpty
          ? [
              ReciterAudioSource(
                apiSource: AudioApiSource.mp3Quran,
                baseUrlOrPattern: serverUrl,
              )
            ]
          : const [],
    );
  }
}
