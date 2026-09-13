import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import 'playback_mode_button.dart';

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

    // Hide mini-player if explicitly dismissed via Stop or if no surah is available
    if (player.isDismissed) return const SizedBox.shrink();

    final surah = player.currentSurah;
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PlaybackModeButton(size: 18),
                _MiniPlayerIconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 20),
                  tooltip: context.tr('previous'),
                  onPressed: player.skipPrevious,
                ),
                _MiniPlayerIconButton(
                  icon: player.isBuffering
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          player.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                  tooltip: player.isPlaying
                      ? context.tr('pause')
                      : context.tr('play'),
                  onPressed: player.togglePlayPause,
                  color: theme.colorScheme.primary,
                ),
                _MiniPlayerIconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 20),
                  tooltip: context.tr('next'),
                  onPressed: player.skipNext,
                ),
                _MiniPlayerIconButton(
                  icon: const Icon(Icons.stop_rounded, size: 20),
                  tooltip: context.tr('stop'),
                  onPressed: player.stop,
                  color: (player.isPlaying ||
                          player.state == PlaybackState.paused ||
                          player.isBuffering)
                      ? (isDark ? AppColors.mutedDark : AppColors.mutedLight)
                      : (isDark
                          ? AppColors.outlineDark
                          : AppColors.outlineLight),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerIconButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _MiniPlayerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
