/// One item in the user's playlist.
class PlaylistItem {
  final int surahId;
  final String reciterId;
  final bool isDownloaded;

  const PlaylistItem({
    required this.surahId,
    required this.reciterId,
    this.isDownloaded = false,
  });

  PlaylistItem copyWith({
    int? surahId,
    String? reciterId,
    bool? isDownloaded,
  }) {
    return PlaylistItem(
      surahId: surahId ?? this.surahId,
      reciterId: reciterId ?? this.reciterId,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
