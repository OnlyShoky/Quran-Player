import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../core/models/surah.dart';
import '../../core/models/reciter.dart';
import '../../core/models/audio_api_source.dart';
import '../../core/services/audio_output_device_listener.dart';
import '../../core/services/media_artwork_service.dart';
import '../../core/services/quran_audio_handler.dart';
import 'playlist_provider.dart';
import 'settings_provider.dart';

enum PlaybackState { stopped, playing, paused, buffering }

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = QuranAudioHandler.instance.player;

  PlaybackState _state = PlaybackState.stopped;
  int _currentIndex = 0;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Surah? _currentSurah;
  Reciter? _currentReciter;
  String? _currentAudioUrl;
  String? _pendingAudioUrl;
  AudioApiSource? _currentAudioSource;
  String? _errorMessage;
  String? _fallbackMessage; // Transient info shown when fallback kicks in
  final Set<int> _failedReciterIds = {}; // reciters that errored on the current surah

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _sequenceStateSub;
  StreamSubscription? _currentIndexSub;
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _becomingNoisySub;
  late final AudioOutputDeviceListener _audioOutputDeviceListener;

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
  /// Non-error informational message when a fallback reciter was used.
  String? get fallbackMessage => _fallbackMessage;

  /// Called by UI to dismiss the fallback banner.
  void clearFallbackMessage() {
    if (_fallbackMessage != null) {
      _fallbackMessage = null;
      notifyListeners();
    }
  }

  PlayerProvider() {
    final audioHandler = QuranAudioHandler.instance;
    audioHandler.onCurrentMediaItemChanged = _syncCurrentMediaItem;
    audioHandler.onSkipToNext = () async => skipNext();
    audioHandler.onSkipToPrevious = () async => skipPrevious();
    audioHandler.hasNextCheck = () {
      final playlist = _playlistProvider;
      if (playlist == null || playlist.items.isEmpty) return false;
      final mode =
          _settingsProvider?.playbackCompletion ?? PlaybackCompletionAction.next;
      if (mode == PlaybackCompletionAction.randomSurah ||
          mode == PlaybackCompletionAction.loopPlaylist) {
        return playlist.items.length > 1;
      }
      return _currentIndex < playlist.items.length - 1;
    };
    audioHandler.hasPreviousCheck = () {
      final playlist = _playlistProvider;
      if (playlist == null || playlist.items.isEmpty) return false;
      return _currentIndex > 0 || _position.inSeconds > 3;
    };
    _audioOutputDeviceListener = AudioOutputDeviceListener(_handleAudioOutputDeviceChanged);
    _initAudioSession();
    _initAudioListeners();
  }

  void _syncCurrentMediaItem(MediaItem mediaItem) {
    final playlist = _playlistProvider;
    if (playlist == null) return;
    if (_pendingAudioUrl != null && mediaItem.id != _pendingAudioUrl) return;

    final surahId = mediaItem.extras?['surahId'] as int?;
    if (surahId == null) return;
    final index = playlist.items.indexWhere((item) => item.surahId == surahId);
    if (index < 0) return;
    final surah = playlist.surahById(surahId);
    if (surah == null) return;

    _currentIndex = index;
    _currentSurah = surah;
    _currentAudioUrl = mediaItem.id;
    _currentAudioSource = _audioSourceFromUrl(mediaItem.id);
    notifyListeners();
  }

  void _handleAudioOutputDeviceChanged() {
    if (!_audioPlayer.playing) return;

    final position = _audioPlayer.position;
    _audioPlayer.setWebSinkId('').then((_) {
      if (_audioPlayer.playing) return;
      _audioPlayer.seek(position);
      _audioPlayer.play();
    }).catchError((_) {});
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

    void syncMediaItem(MediaItem? mediaItem, [int? sequenceIndex]) {
      final playlist = _playlistProvider;
      if (playlist == null || mediaItem is! MediaItem) {
        return;
      }

      final surahId = mediaItem.extras?['surahId'] as int?;
      final index = surahId == null
          ? sequenceIndex
          : playlist.items.indexWhere((item) => item.surahId == surahId);
      if (index == null || index < 0 || index >= playlist.items.length) {
        return;
      }

      final surah = playlist.surahById(playlist.items[index].surahId);
      if (surah == null) return;

      _currentIndex = index;
      _currentSurah = surah;
      _currentAudioUrl = mediaItem.id;
      _currentAudioSource = _audioSourceFromUrl(mediaItem.id);
      notifyListeners();
    }

    _sequenceStateSub = _audioPlayer.sequenceStateStream.listen((sequenceState) {
      final source = sequenceState.currentSource;
      syncMediaItem(
        source?.tag as MediaItem?,
        sequenceState.currentIndex,
      );
    });
    _currentIndexSub = _audioPlayer.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _audioPlayer.sequence.length) {
        return;
      }
      final source = _audioPlayer.sequence[index];
      syncMediaItem(
        source.tag as MediaItem?,
        index,
      );
    });
    _mediaItemSub = QuranAudioHandler.instance.mediaItem.listen(syncMediaItem);
  }

  AudioApiSource? _audioSourceFromUrl(String url) {
    if (url.contains('mp3quran.net')) return AudioApiSource.mp3Quran;
    if (url.contains('quranicaudio.com')) return AudioApiSource.quranicAudio;
    if (url.contains('islamic.network')) return AudioApiSource.alQuranCloud;
    return null;
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
        extras: {'surahId': surah.id},
        artUri: MediaArtworkService.uri,
      ),
    );
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
      case PlaybackCompletionAction.loopPlaylist:
        // When playlist ends, wrap around to the first track
        if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
          if (_currentIndex < _playlistProvider!.items.length - 1) {
            playIndex(_currentIndex + 1);
          } else {
            // Last track finished → loop back to beginning
            playIndex(0);
          }
        } else {
          _state = PlaybackState.stopped;
          notifyListeners();
        }
        break;
      case PlaybackCompletionAction.randomSurah:
        // Like loopPlaylist but pick a random index from the playlist
        if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
          final count = _playlistProvider!.items.length;
          if (count == 1) {
            playIndex(0);
          } else {
            int nextIndex;
            do {
              nextIndex = Random().nextInt(count);
            } while (nextIndex == _currentIndex);
            playIndex(nextIndex);
          }
        } else {
          _state = PlaybackState.stopped;
          notifyListeners();
        }
        break;
      case PlaybackCompletionAction.next:
        if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
          if (_currentIndex < _playlistProvider!.items.length - 1) {
            playIndex(_currentIndex + 1);
          } else {
            // End of playlist reached, stop
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

  /// Returns true if audio was loaded and playback started, false on total failure.
  Future<bool> loadAndPlay({
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

    // Mark the requested track before stopping the current one so stale
    // sequence events cannot move the UI back to the previous surah.
    _pendingAudioUrl = candidates.isNotEmpty ? candidates.first.url : null;

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
      _pendingAudioUrl = candidate.url;
      _currentAudioUrl = candidate.url;
      _currentAudioSource = candidate.apiSource;
      notifyListeners();

      try {
        final source = _audioSourceFor(
          url: candidate.url,
          surah: surah,
          reciter: reciter,
        );

        await _audioPlayer.setAudioSource(
          source,
          preload: true,
        );
        await _audioPlayer.play();
        _pendingAudioUrl = null;
        _currentIndex = index;
        _currentSurah = surah;
        _currentAudioUrl = candidate.url;
        _currentAudioSource = candidate.apiSource;
        succeeded = true;
        QuranAudioHandler.instance.broadcastPlaybackState();
        notifyListeners();
        break;
      } catch (e) {
        lastError = e.toString();
        debugPrint('Candidate audio source $i failed (${candidate.url}): $e. Attempting fallback if available.');
      }
    }

    if (!succeeded) {
      _pendingAudioUrl = null;
      _currentAudioSource = null;
      _errorMessage = 'Failed to load audio: $lastError';
      _state = PlaybackState.stopped;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> playIndex(int index) async {
    _isDismissed = false;
    if (_playlistProvider == null || _playlistProvider!.items.isEmpty) return;
    if (index < 0 || index >= _playlistProvider!.items.length) return;

    final item = _playlistProvider!.items[index];
    final surah = _playlistProvider!.surahById(item.surahId);
    if (surah == null) return;

    _currentIndex = index;
    _currentSurah = surah;
    notifyListeners();

    // Reset per-surah failed reciter tracking when we move to a new surah.
    _failedReciterIds.clear();
    _fallbackMessage = null;

    await _playIndexWithFallback(index: index, surah: surah);
  }

  /// Internal method that picks a reciter, attempts playback, and retries
  /// with alternate reciters when in random mode or falls back gracefully
  /// in fixed-reciter mode. Avoids infinite loops via [_failedReciterIds].
  Future<void> _playIndexWithFallback({
    required int index,
    required Surah surah,
    int retryCount = 0,
  }) async {
    // Safety cap: never retry more than 10 times total per surah
    const maxRetries = 10;

    final playlist = _playlistProvider!;
    final isRandomFav = playlist.isRandomFavReciterMode;
    final isRandom = playlist.isRandomReciterMode;

    // Pick the reciter for this attempt
    Reciter? reciter;
    if (isRandomFav) {
      reciter = playlist.pickRandomFavReciter(
        excludeId: _currentReciter?.id,
        excludeIds: _failedReciterIds,
        surahId: surah.id,
      ) ?? playlist.selectedReciter ?? _currentReciter;
    } else if (isRandom) {
      reciter = playlist.pickRandomReciter(
        excludeId: _currentReciter?.id,
        excludeIds: _failedReciterIds,
        surahId: surah.id,
      ) ?? playlist.selectedReciter ?? _currentReciter;
    } else {
      reciter = playlist.selectedReciter ?? _currentReciter;
    }

    if (reciter == null) {
      _state = PlaybackState.stopped;
      notifyListeners();
      return;
    }

    // Update UI to show the chosen reciter immediately
    _currentReciter = reciter;
    playlist.selectReciter(reciter.id);

    final succeeded = await loadAndPlay(surah: surah, reciter: reciter, index: index);

    if (!succeeded) {
      // Mark this reciter as failed for the current surah
      _failedReciterIds.add(reciter.id);
      _errorMessage = null; // Clear the stopped-state error; we'll handle it

      if ((isRandom || isRandomFav) && retryCount < maxRetries) {
        // In random modes: silently pick a different reciter and retry
        debugPrint('[Fallback] Reciter ${reciter.name} failed surah ${surah.id}. Retrying (attempt ${retryCount + 1})…');
        _fallbackMessage = 'audio_unavailable_retrying:${reciter.name}';
        notifyListeners();
        await _playIndexWithFallback(
          index: index,
          surah: surah,
          retryCount: retryCount + 1,
        );
      } else if (!isRandom && !isRandomFav) {
        // Fixed reciter mode: skip to the next surah automatically so
        // playback doesn't get stuck. Show a transient message.
        _fallbackMessage = 'audio_unavailable_skip:${reciter.name}';
        _state = PlaybackState.stopped;
        notifyListeners();
        // Auto-advance after a short delay so the user sees what happened
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (!_isDismissed) {
          _onTrackCompleted();
        }
      } else {
        // Exhausted all retries in random mode — stop gracefully.
        debugPrint('[Fallback] Exhausted all reciters for surah ${surah.id}. Stopping.');
        _fallbackMessage = null;
        _state = PlaybackState.stopped;
        _errorMessage = 'Audio unavailable for ${surah.nameEn} with any reciter';
        notifyListeners();
      }
    } else {
      // Clear any stale fallback message on success
      if (_fallbackMessage != null) {
        _fallbackMessage = null;
        notifyListeners();
      }
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
    _pendingAudioUrl = null;
    _state = PlaybackState.stopped;
    _currentSurah = null;
    _currentReciter = null;
    _currentAudioUrl = null;
    _currentAudioSource = null;
    _isDismissed = true;
    _position = Duration.zero;
    _progress = 0.0;
    _playlistProvider?.clear();
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
    final playlist = _playlistProvider;
    if (playlist == null || playlist.items.isEmpty) return;

    final completionAction =
        _settingsProvider?.playbackCompletion ?? PlaybackCompletionAction.next;

    if (completionAction == PlaybackCompletionAction.randomSurah) {
      final count = playlist.items.length;
      if (count <= 1) {
        playIndex(0);
      } else {
        int nextIndex;
        do {
          nextIndex = Random().nextInt(count);
        } while (nextIndex == _currentIndex);
        playIndex(nextIndex);
      }
    } else if (completionAction == PlaybackCompletionAction.loopPlaylist) {
      if (_currentIndex < playlist.items.length - 1) {
        playIndex(_currentIndex + 1);
      } else {
        playIndex(0);
      }
    } else {
      // next, repeat, or stop: clicking "next" explicitly moves to the next surah
      if (_currentIndex < playlist.items.length - 1) {
        playIndex(_currentIndex + 1);
      } else if (completionAction == PlaybackCompletionAction.repeat) {
        playIndex(0);
      }
    }
  }

  void skipPrevious() {
    final playlist = _playlistProvider;
    if (playlist == null || playlist.items.isEmpty) return;

    if (_position.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
      return;
    }

    final completionAction =
        _settingsProvider?.playbackCompletion ?? PlaybackCompletionAction.next;

    if (completionAction == PlaybackCompletionAction.randomSurah) {
      final count = playlist.items.length;
      if (count <= 1) {
        _audioPlayer.seek(Duration.zero);
      } else {
        int prevIndex;
        do {
          prevIndex = Random().nextInt(count);
        } while (prevIndex == _currentIndex);
        playIndex(prevIndex);
      }
    } else if (_currentIndex > 0) {
      playIndex(_currentIndex - 1);
    } else if (completionAction == PlaybackCompletionAction.loopPlaylist) {
      playIndex(playlist.items.length - 1);
    } else {
      _audioPlayer.seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    QuranAudioHandler.instance.onCurrentMediaItemChanged = null;
    QuranAudioHandler.instance.onSkipToNext = null;
    QuranAudioHandler.instance.onSkipToPrevious = null;
    QuranAudioHandler.instance.hasNextCheck = null;
    QuranAudioHandler.instance.hasPreviousCheck = null;
    _audioOutputDeviceListener.dispose();
    _becomingNoisySub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _sequenceStateSub?.cancel();
    _currentIndexSub?.cancel();
    _mediaItemSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
