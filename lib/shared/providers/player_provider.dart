import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../../core/models/surah.dart';
import '../../core/models/reciter.dart';
import '../../core/models/audio_api_source.dart';
import 'playlist_provider.dart';
import 'settings_provider.dart';

enum PlaybackState { stopped, playing, paused, buffering }

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlaybackState _state = PlaybackState.stopped;
  int _currentIndex = 0;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Surah? _currentSurah;
  Reciter? _currentReciter;
  String? _currentAudioUrl;
  AudioApiSource? _currentAudioSource;
  String? _errorMessage;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _sequenceStateSub;
  StreamSubscription? _becomingNoisySub;

  PlaylistProvider? _playlistProvider;
  SettingsProvider? _settingsProvider;

  bool _isDismissed = false;
  int _lastKnownPlaylistLength = 0;
  bool _isHandlingCompletion = false;

  PlaybackState get state => _state;
  int get currentIndex => _currentIndex;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isBuffering => _state == PlaybackState.buffering;
  bool get isDismissed => _isDismissed;
  AudioApiSource? get currentAudioSource {
    if (_currentAudioSource != null) return _currentAudioSource;
    if (_currentAudioUrl != null) {
      if (_currentAudioUrl!.contains('mp3quran.net')) return AudioApiSource.mp3Quran;
      if (_currentAudioUrl!.contains('quranicaudio.com')) return AudioApiSource.quranicAudio;
      if (_currentAudioUrl!.contains('islamic.network')) return AudioApiSource.alQuranCloud;
    }
    return null;
  }

  Surah? get currentSurah {
    if (_currentSurah != null) return _currentSurah;
    if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
      final safeIndex = _currentIndex.clamp(0, _playlistProvider!.items.length - 1);
      return _playlistProvider!.surahById(_playlistProvider!.items[safeIndex].surahId);
    }
    return null;
  }

  Reciter? get currentReciter =>
      _currentReciter ?? _playlistProvider?.selectedReciter;

  String? get errorMessage => _errorMessage;

  PlayerProvider() {
    _initAudioSession();
    _initAudioListeners();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
        pause();
      });
    } catch (e) {
      debugPrint('AudioSession init error: $e');
    }
  }

  void updatePlaylistProvider(PlaylistProvider playlistProvider) {
    _playlistProvider = playlistProvider;
    _syncWithPlaylist();
  }

  void updateSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  void _syncWithPlaylist() {
    if (_playlistProvider == null) return;
    final items = _playlistProvider!.items;

    // If new items were added to the playlist, un-dismiss so the bar is ready
    if (items.length > _lastKnownPlaylistLength) {
      _isDismissed = false;
    }
    _lastKnownPlaylistLength = items.length;

    if (items.isEmpty) {
      if (_currentSurah != null || _state != PlaybackState.stopped) {
        _audioPlayer.stop();
        _currentSurah = null;
        _currentAudioUrl = null;
        _currentAudioSource = null;
        _state = PlaybackState.stopped;
        _currentIndex = 0;
        _position = Duration.zero;
        _progress = 0.0;
        _isDismissed = true;
        notifyListeners();
      }
      return;
    }

    if (_currentSurah != null) {
      final index = items.indexWhere((item) => item.surahId == _currentSurah!.id);
      if (index != -1) {
        _currentIndex = index;
      } else {
        // The currently playing/loaded surah was removed from the playlist
        _audioPlayer.stop();
        _currentSurah = null;
        _currentAudioUrl = null;
        _currentAudioSource = null;
        _state = PlaybackState.stopped;
        _currentIndex = 0;
        _position = Duration.zero;
        _progress = 0.0;
        notifyListeners();
      }
    } else {
      if (_currentIndex >= items.length) {
        _currentIndex = 0;
      }
      notifyListeners();
    }
  }

  void _initAudioListeners() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState != ProcessingState.completed) {
        _isHandlingCompletion = false;
      }

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        _state = PlaybackState.buffering;
      } else if (!playing && processingState != ProcessingState.completed) {
        _state = PlaybackState.paused;
      } else if (playing && processingState != ProcessingState.completed) {
        _state = PlaybackState.playing;
      } else if (processingState == ProcessingState.completed) {
        // Handle track completion once per track completion event
        if (!_isHandlingCompletion) {
          _isHandlingCompletion = true;
          _position = Duration.zero;
          _progress = 0.0;
          _onTrackCompleted();
        }
      }
      notifyListeners();
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      if (_duration.inMilliseconds > 0) {
        _progress = (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
      }
      notifyListeners();
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        if (_duration.inMilliseconds > 0) {
          _progress = (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
        }
        notifyListeners();
      }
    });

    _sequenceStateSub = _audioPlayer.sequenceStateStream.listen((sequenceState) {
      final index = sequenceState.currentIndex;
      final playlist = _playlistProvider;
      if (index == null || playlist == null || index >= playlist.items.length) {
        return;
      }

      final surah = playlist.surahById(playlist.items[index].surahId);
      if (surah == null) return;

      _currentIndex = index;
      _currentSurah = surah;
      _currentAudioSource = null;
      _currentAudioUrl = sequenceState.currentSource?.tag is MediaItem
          ? (sequenceState.currentSource!.tag as MediaItem).id
          : _currentAudioUrl;
      notifyListeners();
    });
  }

  AudioSource _audioSourceFor({
    required String url,
    required Surah surah,
    required Reciter reciter,
  }) {
    return AudioSource.uri(
      Uri.parse(url),
      tag: MediaItem(
        id: url,
        album: 'The Quran',
        title: surah.nameEn,
        artist: reciter.name,
      ),
    );
  }

  List<AudioSource> _sourcesForCandidate({
    required String currentUrl,
    required Surah currentSurah,
    required Reciter reciter,
  }) {
    final playlist = _playlistProvider;
    if (playlist == null || playlist.items.length <= 1) {
      return [
        _audioSourceFor(url: currentUrl, surah: currentSurah, reciter: reciter),
      ];
    }

    final sources = <AudioSource>[];
    for (var i = 0; i < playlist.items.length; i++) {
      final surah = playlist.surahById(playlist.items[i].surahId);
      if (surah == null) continue;

      final url = i == _currentIndex
          ? currentUrl
          : reciter.getAllCandidateAudioSources(surah.id).first.url;
      sources.add(_audioSourceFor(url: url, surah: surah, reciter: reciter));
    }

    return sources;
  }

  void _onTrackCompleted() {
    final completionAction =
        _settingsProvider?.playbackCompletion ?? PlaybackCompletionAction.next;

    switch (completionAction) {
      case PlaybackCompletionAction.repeat:
        if (_currentSurah != null && _currentReciter != null) {
          loadAndPlay(
            surah: _currentSurah!,
            reciter: _currentReciter!,
            index: _currentIndex,
          );
        } else {
          _state = PlaybackState.stopped;
          notifyListeners();
        }
        break;
      case PlaybackCompletionAction.stop:
        _state = PlaybackState.stopped;
        notifyListeners();
        break;
      case PlaybackCompletionAction.next:
        if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
          if (_currentIndex < _playlistProvider!.items.length - 1) {
            playIndex(_currentIndex + 1);
          } else {
            // End of playlist reached
            _state = PlaybackState.stopped;
            notifyListeners();
          }
        } else {
          _state = PlaybackState.stopped;
          notifyListeners();
        }
        break;
    }
  }

  /// Switch the active reciter. If a track is active or playing, reload it with the new reciter.
  void selectReciter(Reciter reciter) {
    _currentReciter = reciter;
    final activeSurah = currentSurah;
    if (activeSurah != null) {
      loadAndPlay(
        surah: activeSurah,
        reciter: reciter,
        index: _currentIndex,
      );
    } else {
      notifyListeners();
    }
  }

  /// Construct audio URL for primary source
  String getAudioUrl(Surah surah, Reciter reciter) {
    return reciter.getAudioUrl(surah.id);
  }

  Future<void> loadAndPlay({
    required Surah surah,
    required Reciter reciter,
    required int index,
  }) async {
    _isDismissed = false;
    _currentIndex = index;
    _currentSurah = surah;
    _currentReciter = reciter;
    _errorMessage = null;

    final candidates = reciter.getAllCandidateAudioSources(surah.id);
    if (candidates.isEmpty) {
      final defaultUrl = getAudioUrl(surah, reciter);
      if (defaultUrl.isNotEmpty) {
        candidates.add(CandidateAudioSource(
          apiSource: AudioApiSource.mp3Quran,
          url: defaultUrl,
        ));
      }
    }

    _state = PlaybackState.buffering;
    notifyListeners();

    // Cleanly stop any existing playback before setting a new audio source
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    String? lastError;
    bool succeeded = false;

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      _currentAudioUrl = candidate.url;
      _currentAudioSource = candidate.apiSource;
      notifyListeners();

      try {
        await _audioPlayer.setAudioSources(
          _sourcesForCandidate(
            currentUrl: candidate.url,
            currentSurah: surah,
            reciter: reciter,
          ),
          initialIndex: _currentIndex,
          preload: true,
        );
        await _audioPlayer.play();
        _currentAudioSource = candidate.apiSource;
        succeeded = true;
        notifyListeners();
        break;
      } catch (e) {
        lastError = e.toString();
        debugPrint('Candidate audio source $i failed (${candidate.url}): $e. Attempting fallback if available.');
      }
    }

    if (!succeeded) {
      _currentAudioSource = null;
      _errorMessage = 'Failed to load audio: $lastError';
      _state = PlaybackState.stopped;
      notifyListeners();
    }
  }

  Future<void> playIndex(int index) async {
    _isDismissed = false;
    if (_playlistProvider == null || _playlistProvider!.items.isEmpty) return;
    if (index < 0 || index >= _playlistProvider!.items.length) return;

    final item = _playlistProvider!.items[index];
    final surah = _playlistProvider!.surahById(item.surahId);
    final reciter = _playlistProvider!.selectedReciter ?? _currentReciter;

    if (surah != null && reciter != null) {
      await loadAndPlay(surah: surah, reciter: reciter, index: index);
    }
  }

  void play() {
    _isDismissed = false;
    if (_currentAudioUrl != null) {
      _audioPlayer.play();
    } else if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
      playIndex(_currentIndex);
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void stop() {
    _audioPlayer.stop();
    _audioPlayer.seek(Duration.zero);
    _state = PlaybackState.stopped;
    _currentSurah = null;
    _currentReciter = null;
    _currentAudioUrl = null;
    _currentAudioSource = null;
    _isDismissed = true;
    _position = Duration.zero;
    _progress = 0.0;
    notifyListeners();
  }

  void togglePlayPause() {
    _isDismissed = false;
    if (isPlaying) {
      pause();
    } else if (_state == PlaybackState.paused) {
      play();
    } else {
      playIndex(_currentIndex);
    }
  }

  void seekTo(double progressValue) {
    if (_duration.inMilliseconds > 0) {
      final targetMs = (_duration.inMilliseconds * progressValue.clamp(0.0, 1.0)).round();
      _audioPlayer.seek(Duration(milliseconds: targetMs));
    }
  }

  void skipNext() {
    if (_playlistProvider != null && _currentIndex < _playlistProvider!.items.length - 1) {
      playIndex(_currentIndex + 1);
    }
  }

  void skipPrevious() {
    if (_position.inSeconds > 5) {
      _audioPlayer.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      playIndex(_currentIndex - 1);
    }
  }

  @override
  void dispose() {
    _becomingNoisySub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _sequenceStateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
