import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/data/mock_data.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/providers/view_mode_provider.dart';
import '../../shared/widgets/surah_tile.dart';
import '../../shared/widgets/mosaic_grid_view.dart';
import '../../shared/widgets/reciter_selector_sheet.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
    final viewMode = context.watch<ViewModeProvider>();
    final surahs = MockData.surahs;
    final isMosaic = viewMode.mode == ViewMode.mosaic;

    final filtered = _query.isEmpty
        ? surahs
        : surahs.where((s) {
            final q = _query.toLowerCase();
            return s.nameEn.toLowerCase().contains(q) ||
                s.nameEnTranslation.toLowerCase().contains(q) ||
                s.nameAr.contains(q) ||
                '${s.id}'.contains(q);
          }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- App Bar ---
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Al-Quran', style: theme.textTheme.titleLarge),
                Text(
                  'القرآن الكريم',
                  style: GoogleFonts.amiri(
                    fontSize: 13,
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                ),
              ],
            ),
            actions: [
              // --- View mode toggle ---
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    isMosaic
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    key: ValueKey(isMosaic),
                    size: 22,
                  ),
                ),
                tooltip: isMosaic ? 'Switch to list view' : 'Switch to mosaic view',
                onPressed: viewMode.toggle,
              ),
              const SizedBox(width: 4),
            ],
          ),

          // --- Reciter selector card ---
          SliverToBoxAdapter(
            child: _ReciterSelectorHeader(),
          ),

          // --- Search bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search surahs…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
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
          ),

          // --- Surah count ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _query.isEmpty
                    ? '114 chapters'
                    : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                ),
              ),
            ),
          ),

          // --- List or Mosaic view ---
          if (isMosaic)
            MosaicGridView(surahs: filtered)
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final surah = filtered[index];
                  return Column(
                    children: [
                      SurahTile(surah: surah),
                      if (index < filtered.length - 1)
                        Divider(
                          indent: 70,
                          endIndent: 16,
                          height: 1,
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                        ),
                    ],
                  );
                },
                childCount: filtered.length,
              ),
            ),

          // Bottom padding so mini-player doesn't hide last item
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: playlist.items.length < surahs.length
          ? FloatingActionButton.extended(
              onPressed: () {
                playlist.addAllSurahs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All 114 surahs added to playlist'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('Add all'),
            )
          : null,
    );
  }
}

class _ReciterSelectorHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final selectedReciter = playlist.selectedReciter;

    if (playlist.isLoadingReciters) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading reciters from API...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => showReciterSelectorModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECITER',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedReciter?.name ?? 'Select Reciter',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Change',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.unfold_more_rounded,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
