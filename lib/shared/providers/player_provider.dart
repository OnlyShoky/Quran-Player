import 'package:flutter/foundation.dart';

enum PlaybackState { stopped, playing, paused }

/// Mock player state for Phase 1.
/// Phase 4 will replace this with real audio engine integration.
class PlayerProvider extends ChangeNotifier {
  PlaybackState _state = PlaybackState.stopped;
  int _currentIndex = 0; // index into the playlist
  double _progress = 0.0; // 0.0–1.0
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(minutes: 8, seconds: 30); // mock

  PlaybackState get state => _state;
  int get currentIndex => _currentIndex;
  double get progress => _progress;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _state == PlaybackState.playing;

  void play() {
    _state = PlaybackState.playing;
    notifyListeners();
  }

  void pause() {
    _state = PlaybackState.paused;
    notifyListeners();
  }

  void togglePlayPause() {
    if (_state == PlaybackState.playing) {
      pause();
    } else {
      play();
    }
  }

  void skipToIndex(int index, int playlistLength) {
    if (index < 0 || index >= playlistLength) return;
    _currentIndex = index;
    _progress = 0.0;
    _position = Duration.zero;
    notifyListeners();
  }

  void skipNext(int playlistLength) {
    if (_currentIndex < playlistLength - 1) {
      skipToIndex(_currentIndex + 1, playlistLength);
    }
  }

  void skipPrevious(int playlistLength) {
    if (_position.inSeconds > 5) {
      // restart current track
      _progress = 0.0;
      _position = Duration.zero;
      notifyListeners();
    } else if (_currentIndex > 0) {
      skipToIndex(_currentIndex - 1, playlistLength);
    }
  }

  void seekTo(double value) {
    _progress = value.clamp(0.0, 1.0);
    _position = Duration(
      milliseconds: (_duration.inMilliseconds * _progress).round(),
    );
    notifyListeners();
  }

  void reset() {
    _state = PlaybackState.stopped;
    _currentIndex = 0;
    _progress = 0.0;
    _position = Duration.zero;
    notifyListeners();
  }
}
