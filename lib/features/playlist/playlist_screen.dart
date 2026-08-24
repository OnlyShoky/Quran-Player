import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/reciter.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/providers/player_provider.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final player = context.watch<PlayerProvider>();

    final reciter = playlist.reciters.firstWhere(
      (r) => r.id == playlist.selectedReciterId,
      orElse: () => playlist.reciters.isNotEmpty 
          ? playlist.reciters.first 
          : const Reciter(id: -1, name: 'Unknown', style: '', serverUrl: ''),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Playlist', style: theme.textTheme.titleLarge),
                Text(
                  reciter.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            actions: [
              if (playlist.items.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClear(context, playlist),
                  child: Text(
                    'Clear',
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
            // Summary header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  '${playlist.items.length} surah${playlist.items.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
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
                      color: isDark ? AppColors.errorDark.withValues(alpha: 0.15) : AppColors.errorLight.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: isDark ? AppColors.errorDark : AppColors.errorLight,
                      ),
                    ),
                    onDismissed: (_) {
                      final idx = playlist.indexOfSurah(surah.id);
                      final removed = playlist.removeSurah(surah.id);
                      if (removed != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${surah.nameEn} removed'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () =>
                                  playlist.undoRemove(removed, idx),
                            ),
                            duration: const Duration(seconds: 4),
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
                            player.skipToIndex(index, playlist.items.length);
                            player.play();
                            context.go('/player');
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
                    if (!player.isPlaying) player.play();
                    context.go('/player');
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play'),
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
        title: const Text('Clear playlist?'),
        content: const Text('This will remove all surahs from your playlist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              playlist.clear();
            },
            child: const Text('Clear'),
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
            'Your playlist is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add surahs from the Surahs tab\nor tap "Add all" to include every chapter.',
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
