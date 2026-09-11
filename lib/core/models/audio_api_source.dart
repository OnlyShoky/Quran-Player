import 'package:flutter/foundation.dart';

/// Supported Quran audio API providers.
enum AudioApiSource {
  mp3Quran,
  quranicAudio,
  alQuranCloud,
}

extension AudioApiSourceExtension on AudioApiSource {
  String get id {
    switch (this) {
      case AudioApiSource.mp3Quran:
        return 'mp3quran';
      case AudioApiSource.quranicAudio:
        return 'quranicaudio';
      case AudioApiSource.alQuranCloud:
        return 'alquran_cloud';
    }
  }

  String get displayName {
    switch (this) {
      case AudioApiSource.mp3Quran:
        return 'MP3Quran.net';
      case AudioApiSource.quranicAudio:
        return 'QuranicAudio.com';
      case AudioApiSource.alQuranCloud:
        return 'AlQuran Cloud';
    }
  }

  String get description {
    switch (this) {
      case AudioApiSource.mp3Quran:
        return 'Extensive catalog with multiple riwayat and servers';
      case AudioApiSource.quranicAudio:
        return 'High-fidelity audio by Quran Foundation';
      case AudioApiSource.alQuranCloud:
        return 'Fast global CDN by Islamic Network';
    }
  }

  static AudioApiSource? fromId(String id) {
    switch (id.toLowerCase()) {
      case 'mp3quran':
        return AudioApiSource.mp3Quran;
      case 'quranicaudio':
        return AudioApiSource.quranicAudio;
      case 'alquran_cloud':
        return AudioApiSource.alQuranCloud;
      default:
        return null;
    }
  }
}

/// An audio source endpoint for a specific reciter from one API provider.
@immutable
class ReciterAudioSource {
  final AudioApiSource apiSource;
  final String baseUrlOrPattern; // Server url, relative path, or identifier

  const ReciterAudioSource({
    required this.apiSource,
    required this.baseUrlOrPattern,
  });

  /// Constructs the full audio URL for a given surah (1-114).
  String getAudioUrl(int surahId) {
    switch (apiSource) {
      case AudioApiSource.mp3Quran:
        var s = baseUrlOrPattern.trim();
        if (!s.endsWith('/')) s = '$s/';
        final num3 = surahId.toString().padLeft(3, '0');
        return '$s$num3.mp3';

      case AudioApiSource.quranicAudio:
        var path = baseUrlOrPattern.trim();
        if (path.startsWith('/')) path = path.substring(1);
        if (!path.endsWith('/')) path = '$path/';
        final num3 = surahId.toString().padLeft(3, '0');
        return 'https://download.quranicaudio.com/quran/$path$num3.mp3';

      case AudioApiSource.alQuranCloud:
        final identifier = baseUrlOrPattern.trim().replaceAll('-surah', '');
        return 'https://cdn.islamic.network/quran/audio-surah/128/$identifier/$surahId.mp3';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReciterAudioSource &&
          runtimeType == other.runtimeType &&
          apiSource == other.apiSource &&
          baseUrlOrPattern == other.baseUrlOrPattern;

  @override
  int get hashCode => apiSource.hashCode ^ baseUrlOrPattern.hashCode;
}
