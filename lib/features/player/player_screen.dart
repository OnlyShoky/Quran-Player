import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/reciter.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/providers/player_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final player = context.watch<PlayerProvider>();

    if (playlist.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'No playlist yet.\nAdd surahs from the Surahs tab.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
        ),
      );
    }

    final currentIndex =
        player.currentIndex.clamp(0, playlist.items.length - 1);
    final currentItem = playlist.items[currentIndex];
    final surah = playlist.surahById(currentItem.surahId);
    if (surah == null) return const Scaffold();

    final reciter = playlist.reciters.firstWhere(
      (r) => r.id == currentItem.reciterId,
      orElse: () => playlist.reciters.isNotEmpty 
          ? playlist.reciters.first 
          : const Reciter(id: -1, name: 'Unknown', style: '', serverUrl: ''),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Top bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  Text(
                    'Now Playing',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),

            const Spacer(flex: 2),

            // --- Arabic surah name ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                surah.nameAr,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- English name ---
            Text(
              surah.nameEn,
              style: theme.textTheme.headlineMedium,
            ),

            // --- Translation ---
            const SizedBox(height: 4),
            Text(
              surah.nameEnTranslation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),

            const SizedBox(height: 8),

            // --- Reciter name ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reciter.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // --- Playlist position ---
            Text(
              '${currentIndex + 1} of ${playlist.items.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),

            const Spacer(flex: 1),

            // --- Progress ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SliderTheme(
                    data: Theme.of(context).sliderTheme,
                    child: Slider(
                      value: player.progress,
                      onChanged: player.seekTo,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(player.position),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                          ),
                        ),
                        Text(
                          _formatDuration(player.duration),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Controls ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  size: 36,
                  color: currentIndex > 0
                      ? theme.colorScheme.onSurface
                      : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                  onTap: () => player.skipPrevious(playlist.items.length),
                ),
                const SizedBox(width: 16),

                // Play / Pause
                GestureDetector(
                  onTap: player.togglePlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Next
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  size: 36,
                  color: currentIndex < playlist.items.length - 1
                      ? theme.colorScheme.onSurface
                      : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                  onTap: () => player.skipNext(playlist.items.length),
                ),
              ],
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: color),
    );
  }
}
