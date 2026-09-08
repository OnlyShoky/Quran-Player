import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/providers/player_provider.dart';
import '../../shared/widgets/reciter_selector_sheet.dart';
import '../../shared/utils/app_snackbar.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final player = context.watch<PlayerProvider>();

    final reciter = playlist.selectedReciter;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('playlist_title'), style: theme.textTheme.titleLarge),
                InkWell(
                  onTap: () => showReciterSelectorModal(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reciter?.name ?? context.tr('select_reciter'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (playlist.items.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClear(context, playlist),
                  child: Text(
                    context.tr('clear_all'),
                    style: TextStyle(
                      color: isDark ? AppColors.errorDark : AppColors.errorLight,
                    ),
                  ),
                ),
            ],
          ),

          if (playlist.items.isEmpty)
            SliverFillRemaining(
              child: _EmptyPlaylist(),
            )
          else ...[
            // Summary header & Play action
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${playlist.items.length} surah${playlist.items.length == 1 ? '' : 's'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        if (player.isPlaying) {
                          player.pause();
                        } else {
                          player.playIndex(player.currentIndex);
                        }
                      },
                      icon: Icon(
                        player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      label: Text(
                        player.isPlaying
                            ? context.tr('pause')
                            : context.tr('play'),
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Playlist items
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = playlist.items[index];
                  final surah = playlist.surahById(item.surahId);
                  if (surah == null) return const SizedBox.shrink();

                  final isCurrentlyPlaying =
                      player.currentIndex == index && player.isPlaying;

                  return Dismissible(
                    key: ValueKey('playlist-${surah.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: isDark
                          ? AppColors.errorDark.withValues(alpha: 0.15)
                          : AppColors.errorLight.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: isDark ? AppColors.errorDark : AppColors.errorLight,
                      ),
                    ),
                    onDismissed: (_) {
                      final idx = playlist.indexOfSurah(surah.id);
                      final removed = playlist.removeSurah(surah.id);
                      if (removed != null && context.mounted) {
                        showAppSnackBar(
                          context,
                          '${surah.nameEn} removed',
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () =>
                                playlist.undoRemove(removed, idx),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        _PlaylistItemTile(
                          index: index,
                          surahNameEn: surah.nameEn,
                          surahNameAr: surah.nameAr,
                          surahId: surah.id,
                          isPlaying: isCurrentlyPlaying,
                          onTap: () {
                            if (reciter != null) {
                              player.loadAndPlay(
                                surah: surah,
                                reciter: reciter,
                                index: index,
                              );
                              context.go('/player');
                            }
                          },
                        ),
                        Divider(
                          indent: 56,
                          endIndent: 16,
                          height: 1,
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                        ),
                      ],
                    ),
                  );
                },
                childCount: playlist.items.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      bottomNavigationBar: playlist.items.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  onPressed: () {
                    if (reciter != null) {
                      final targetIndex = player.currentIndex < playlist.items.length
                          ? player.currentIndex
                          : 0;
                      final targetItem = playlist.items[targetIndex];
                      final surah = playlist.surahById(targetItem.surahId);

                      if (surah != null) {
                        if (!player.isPlaying) {
                          player.loadAndPlay(
                            surah: surah,
                            reciter: reciter,
                            index: targetIndex,
                          );
                        }
                        context.go('/player');
                      }
                    }
                  },
                  icon: Icon(player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(player.isPlaying
                      ? context.tr('pause')
                      : context.tr('play')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _confirmClear(BuildContext context, PlaylistProvider playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('clear_all')),
        content: Text(context.tr('playlist_empty_subtitle')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              playlist.clear();
            },
            child: Text(context.tr('clear_all')),
          ),
        ],
      ),
    );
  }
}

class _PlaylistItemTile extends StatelessWidget {
  final int index;
  final String surahNameEn;
  final String surahNameAr;
  final int surahId;
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlaylistItemTile({
    required this.index,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.surahId,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Index or playing indicator
            SizedBox(
              width: 32,
              child: isPlaying
                  ? Icon(Icons.graphic_eq_rounded,
                      color: theme.colorScheme.primary, size: 20)
                  : Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            isDark ? AppColors.mutedDark : AppColors.mutedLight,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                surahNameEn,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isPlaying ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            Text(
              surahNameAr,
              style: GoogleFonts.amiri(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaylist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 72,
            color: isDark
                ? AppColors.outlineDark
                : AppColors.outlineLight,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('playlist_empty_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('playlist_empty_subtitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
