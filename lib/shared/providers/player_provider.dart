import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/models/surah.dart';
import '../../core/models/reciter.dart';

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
  String? _errorMessage;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  PlaybackState get state => _state;
  int get currentIndex => _currentIndex;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isBuffering => _state == PlaybackState.buffering;
  Surah? get currentSurah => _currentSurah;
  Reciter? get currentReciter => _currentReciter;
  String? get errorMessage => _errorMessage;

  PlayerProvider() {
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        _state = PlaybackState.buffering;
      } else if (!playing) {
        _state = PlaybackState.paused;
      } else if (processingState != ProcessingState.completed) {
        _state = PlaybackState.playing;
      } else if (processingState == ProcessingState.completed) {
        _state = PlaybackState.stopped;
        _position = Duration.zero;
        _progress = 0.0;
        // Auto play next surah if available (handled via callback or external call)
        _onTrackCompleted();
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
  }

  Function(int completedIndex)? onTrackCompletedCallback;

  void _onTrackCompleted() {
    if (onTrackCompletedCallback != null) {
      onTrackCompletedCallback!(_currentIndex);
    }
  }

  /// Construct audio URL: serverUrl + 3-digit surah id + .mp3
  String getAudioUrl(Surah surah, Reciter reciter) {
    var server = reciter.serverUrl;
    if (!server.endsWith('/')) {
      server = '$server/';
    }
    final surahNum = surah.id.toString().padLeft(3, '0');
    return '$server$surahNum.mp3';
  }

  Future<void> loadAndPlay({
    required Surah surah,
    required Reciter reciter,
    required int index,
  }) async {
    _currentIndex = index;
    _currentSurah = surah;
    _currentReciter = reciter;
    _errorMessage = null;

    final url = getAudioUrl(surah, reciter);
    _currentAudioUrl = url;

    try {
      _state = PlaybackState.buffering;
      notifyListeners();

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = 'Failed to load audio: $e';
      _state = PlaybackState.stopped;
      notifyListeners();
    }
  }

  void play() {
    if (_currentAudioUrl != null) {
      _audioPlayer.play();
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seekTo(double progressValue) {
    if (_duration.inMilliseconds > 0) {
      final targetMs = (_duration.inMilliseconds * progressValue.clamp(0.0, 1.0)).round();
      _audioPlayer.seek(Duration(milliseconds: targetMs));
    }
  }

  void skipNext(int playlistLength, {Function(int nextIndex)? onSkip}) {
    if (_currentIndex < playlistLength - 1) {
      final nextIdx = _currentIndex + 1;
      if (onSkip != null) {
        onSkip(nextIdx);
      }
    }
  }

  void skipPrevious(int playlistLength, {Function(int prevIndex)? onSkip}) {
    if (_position.inSeconds > 5) {
      _audioPlayer.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      final prevIdx = _currentIndex - 1;
      if (onSkip != null) {
        onSkip(prevIdx);
      }
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
