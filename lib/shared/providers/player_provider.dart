import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../core/models/surah.dart';
import '../../core/models/reciter.dart';
import 'playlist_provider.dart';

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
  StreamSubscription? _becomingNoisySub;

  PlaylistProvider? _playlistProvider;

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

  void _syncWithPlaylist() {
    if (_playlistProvider == null) return;
    final items = _playlistProvider!.items;

    if (items.isEmpty) {
      if (_currentSurah != null || _state != PlaybackState.stopped) {
        _audioPlayer.stop();
        _currentSurah = null;
        _currentAudioUrl = null;
        _state = PlaybackState.stopped;
        _currentIndex = 0;
        _position = Duration.zero;
        _progress = 0.0;
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
        _state = PlaybackState.stopped;
        _currentIndex = 0;
        _position = Duration.zero;
        _progress = 0.0;
        notifyListeners();
      }
    }
  }

  void _initAudioListeners() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        _state = PlaybackState.buffering;
      } else if (!playing && processingState != ProcessingState.completed) {
        _state = PlaybackState.paused;
      } else if (playing && processingState != ProcessingState.completed) {
        _state = PlaybackState.playing;
      } else if (processingState == ProcessingState.completed) {
        _state = PlaybackState.stopped;
        _position = Duration.zero;
        _progress = 0.0;
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

  void _onTrackCompleted() {
    if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
      if (_currentIndex < _playlistProvider!.items.length - 1) {
        playIndex(_currentIndex + 1);
      }
    }
  }

  /// Construct audio URL: serverUrl + 3-digit surah id + .mp3
  String getAudioUrl(Surah surah, Reciter reciter) {
    var server = reciter.serverUrl.trim();
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

      // Reset previous playback and set new AudioSource
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
        preload: true,
      );
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = 'Failed to load audio: $e';
      _state = PlaybackState.stopped;
      notifyListeners();
    }
  }

  Future<void> playIndex(int index) async {
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
    if (_currentAudioUrl != null) {
      _audioPlayer.play();
    } else if (_playlistProvider != null && _playlistProvider!.items.isNotEmpty) {
      playIndex(0);
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void togglePlayPause() {
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
    _audioPlayer.dispose();
    super.dispose();
  }
}
