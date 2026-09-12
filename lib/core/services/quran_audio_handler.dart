import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  static QuranAudioHandler? _instance;

  static QuranAudioHandler get instance => _instance ??= QuranAudioHandler();

  final AudioPlayer player = AudioPlayer();
  late final StreamSubscription<SequenceState?> _sequenceSubscription;
  late final StreamSubscription<PlayerState> _playerSubscription;
  late final StreamSubscription<Duration> _positionSubscription;

  QuranAudioHandler() {
    _sequenceSubscription = player.sequenceStateStream.listen(_syncQueue);
    _playerSubscription = player.playerStateStream.listen((_) {
      _broadcastPlaybackState();
    });
    _positionSubscription = player.positionStream.listen((_) {
      _broadcastPlaybackState();
    });
  }

  static Future<void> initialize({
    required String androidNotificationChannelId,
    required String androidNotificationChannelName,
    required String androidNotificationIcon,
  }) async {
    _instance = await AudioService.init(
      builder: QuranAudioHandler.new,
      config: AudioServiceConfig(
        androidNotificationChannelId: androidNotificationChannelId,
        androidNotificationChannelName: androidNotificationChannelName,
        androidNotificationIcon: androidNotificationIcon,
      ),
    );
  }

  void _syncQueue(SequenceState? sequenceState) {
    if (sequenceState == null) return;

    final mediaItems = sequenceState.sequence
        .map((source) => source.tag)
        .whereType<MediaItem>()
        .toList(growable: false);
    queue.add(mediaItems);

    final currentSource = sequenceState.currentSource;
    final currentMediaItem = currentSource?.tag;
    if (currentMediaItem is MediaItem) {
      mediaItem.add(currentMediaItem.copyWith(
        duration: player.duration,
      ));
    }
    _broadcastPlaybackState();
  }

  void _broadcastPlaybackState() {
    final processingState = player.processingState;
    final controls = <MediaControl>[
      if (player.hasPrevious) MediaControl.skipToPrevious,
      if (player.playing) MediaControl.pause else MediaControl.play,
      if (player.hasNext) MediaControl.skipToNext,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: List<int>.generate(
        controls.length,
        (index) => index,
      ),
      processingState: switch (processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: player.currentIndex,
    ));
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await super.onTaskRemoved();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'stop') {
      await stop();
    }
  }

  Future<void> dispose() async {
    await _sequenceSubscription.cancel();
    await _playerSubscription.cancel();
    await _positionSubscription.cancel();
    await player.dispose();
  }
}
