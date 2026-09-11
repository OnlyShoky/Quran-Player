import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/providers/player_provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/reciter_selector_sheet.dart';
import '../../shared/widgets/playback_mode_button.dart';

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
    final settings = context.watch<SettingsProvider>();

    if (playlist.items.isEmpty && player.currentSurah == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/surahs');
              }
            },
          ),
        ),
        body: Center(
          child: Text(
            'No playlist or track active.\nSelect a surah to play.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
        ),
      );
    }

    final currentIndex = player.currentIndex.clamp(
      0,
      playlist.items.isEmpty ? 0 : playlist.items.length - 1,
    );

    final surah = player.currentSurah ??
        (playlist.items.isNotEmpty
            ? playlist.surahById(playlist.items[currentIndex].surahId)
            : null);

    if (surah == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/surahs');
              }
            },
          ),
        ),
      );
    }

    final reciter = player.currentReciter ?? playlist.selectedReciter;

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
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/surahs');
                      }
                    },
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  Text(
                    context.tr('now_playing'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded, size: 26),
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    tooltip: context.tr('nav_playlist'),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                      context.go('/playlist');
                    },
                  ),
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
              surah.localizedTranslation(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),

            const SizedBox(height: 12),

            // --- Reciter name chip ---
            GestureDetector(
              onTap: () => showReciterSelectorModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      reciter?.name ?? context.tr('select_reciter'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.unfold_more_rounded, size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),



            const SizedBox(height: 8),

            // --- Playlist position ---
            if (playlist.items.isNotEmpty)
              Text(
                '${currentIndex + 1} of ${playlist.items.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                ),
              ),

            // Error message display if any
            if (player.errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  player.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const Spacer(flex: 1),

            // --- Progress Slider ---
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

            // --- Playback Controls ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Playback Mode (Repeat: One / Next)
                  const PlaybackModeButton(
                    size: 26,
                    showBackgroundOnActive: true,
                  ),

                  // Previous Track
                  _ControlButton(
                    icon: Icons.skip_previous_rounded,
                    size: 36,
                    color: currentIndex > 0
                        ? theme.colorScheme.onSurface
                        : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                    tooltip: context.tr('previous'),
                    onTap: player.skipPrevious,
                  ),

                  // Play / Pause / Loading
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
                      child: player.isBuffering
                          ? Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 40,
                            ),
                    ),
                  ),

                  // Next Track
                  _ControlButton(
                    icon: Icons.skip_next_rounded,
                    size: 36,
                    color: currentIndex < playlist.items.length - 1
                        ? theme.colorScheme.onSurface
                        : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                    tooltip: context.tr('next'),
                    onTap: player.skipNext,
                  ),

                  // Dedicated Stop & Dismiss Button
                  _ControlButton(
                    icon: Icons.stop_rounded,
                    size: 34,
                    color: (player.isPlaying ||
                            player.state == PlaybackState.paused ||
                            player.isBuffering)
                        ? theme.colorScheme.onSurface
                        : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                    tooltip: context.tr('stop'),
                    onTap: () {
                      player.stop();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/surahs');
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // --- Bottom bar with API indicator tucked into bottom-left ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  if (settings.showApiSourceInPlayer && player.currentAudioSource != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            size: 13,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            player.currentAudioSource!.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),
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
  final String? tooltip;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: size, color: color),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
