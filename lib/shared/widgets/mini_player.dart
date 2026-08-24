import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';

/// Persistent mini-player bar shown above the bottom nav when
/// the playlist has at least one item or audio is active.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final player = context.watch<PlayerProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surah = player.currentSurah ??
        (playlist.items.isNotEmpty
            ? playlist.surahById(
                playlist.items[player.currentIndex.clamp(0, playlist.items.length - 1)].surahId,
              )
            : null);

    if (surah == null) return const SizedBox.shrink();

    final currentIndex = player.currentIndex.clamp(
      0,
      playlist.items.isEmpty ? 0 : playlist.items.length - 1,
    );

    return GestureDetector(
      onTap: () => context.go('/player'),
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            // Surah number badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${surah.id}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Names
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameEn,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    playlist.items.isNotEmpty
                        ? '${currentIndex + 1} of ${playlist.items.length}'
                        : surah.nameAr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
            // Prev
            IconButton(
              onPressed: player.skipPrevious,
              icon: const Icon(Icons.skip_previous_rounded, size: 22),
              color: theme.colorScheme.onSurface,
            ),
            // Play/Pause/Buffering
            IconButton(
              onPressed: player.togglePlayPause,
              icon: player.isBuffering
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 28,
                    ),
              color: theme.colorScheme.primary,
            ),
            // Next
            IconButton(
              onPressed: player.skipNext,
              icon: const Icon(Icons.skip_next_rounded, size: 22),
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
