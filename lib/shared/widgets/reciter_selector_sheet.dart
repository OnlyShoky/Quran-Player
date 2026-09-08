import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/reciter.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../utils/app_snackbar.dart';

void showReciterSelectorModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ReciterSelectorSheet(),
  );
}

class ReciterSelectorSheet extends StatefulWidget {
  const ReciterSelectorSheet({super.key});

  @override
  State<ReciterSelectorSheet> createState() => _ReciterSelectorSheetState();
}

class _ReciterSelectorSheetState extends State<ReciterSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final player = context.read<PlayerProvider>();

    final allReciters = playlist.reciters;
    final filteredReciters = _searchQuery.isEmpty
        ? allReciters
        : allReciters.where((r) {
            final q = _searchQuery.toLowerCase();
            return r.name.toLowerCase().contains(q) ||
                r.style.toLowerCase().contains(q);
          }).toList();

    // Sort so favorited reciters appear at the top
    final sortedReciters = List<Reciter>.from(filteredReciters)
      ..sort((a, b) {
        final aFav = playlist.isFavorite(a.id);
        final bFav = playlist.isFavorite(b.id);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return 0;
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Sheet drag handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('select_reciter'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: context.tr('search_reciter'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // List of reciters
            Expanded(
              child: playlist.isLoadingReciters
                  ? const Center(child: CircularProgressIndicator())
                  : sortedReciters.isEmpty
                      ? Center(
                          child: Text(
                            'No reciters found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: sortedReciters.length,
                          separatorBuilder: (context, i) => Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: isDark
                                ? AppColors.outlineDark
                                : AppColors.outlineLight,
                          ),
                          itemBuilder: (context, index) {
                            final reciter = sortedReciters[index];
                            final isSelected =
                                playlist.selectedReciterId == reciter.id;
                            final isFav = playlist.isFavorite(reciter.id);
                            final isPin = playlist.isPinned(reciter.id);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reciter.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : null,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: reciter.style.isNotEmpty
                                  ? Text(
                                      reciter.style,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.mutedDark
                                            : AppColors.mutedLight,
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Favorite Button
                                  IconButton(
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_outline_rounded,
                                      size: 20,
                                      color: isFav
                                          ? Colors.redAccent
                                          : (isDark
                                              ? AppColors.mutedDark
                                              : AppColors.mutedLight),
                                    ),
                                    tooltip: isFav
                                        ? 'Remove from favorites'
                                        : 'Add to favorites',
                                    onPressed: () {
                                      playlist.toggleFavoriteReciter(reciter.id);
                                    },
                                  ),
                                  // Pin Button
                                  IconButton(
                                    icon: Icon(
                                      isPin
                                          ? Icons.push_pin_rounded
                                          : Icons.push_pin_outlined,
                                      size: 20,
                                      color: isPin
                                          ? theme.colorScheme.primary
                                          : (isDark
                                              ? AppColors.mutedDark
                                              : AppColors.mutedLight),
                                    ),
                                    tooltip: isPin
                                        ? 'Unpin reciter'
                                        : 'Pin reciter (max 3)',
                                    onPressed: () async {
                                      final success =
                                          await playlist.togglePinReciter(reciter.id);
                                      if (!success && context.mounted) {
                                         showAppSnackBar(
                                           context,
                                           context.tr('max_pins_reached'),
                                         );
                                      }
                                    },
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                playlist.selectReciter(reciter.id);

                                // If player is currently playing a surah, reload with new reciter
                                if (player.currentSurah != null) {
                                  player.loadAndPlay(
                                    surah: player.currentSurah!,
                                    reciter: reciter,
                                    index: player.currentIndex,
                                  );
                                }

                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
