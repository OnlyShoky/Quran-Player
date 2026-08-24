import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/reciter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/widgets/surah_tile.dart';

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
    final surahs = MockData.surahs;

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
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {},
                tooltip: 'Search',
              ),
            ],
          ),

          // --- Reciter selector ---
          SliverToBoxAdapter(
            child: _ReciterSelector(),
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

          // --- List ---
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

class _ReciterSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final reciters = MockData.reciters;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: reciters.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final reciter = reciters[i];
          final selected = playlist.selectedReciterId == reciter.id;
          return _ReciterChip(
            reciter: reciter,
            selected: selected,
            onTap: () => playlist.selectReciter(reciter.id),
          );
        },
      ),
    );
  }
}

class _ReciterChip extends StatelessWidget {
  final Reciter reciter;
  final bool selected;
  final VoidCallback onTap;

  const _ReciterChip({
    required this.reciter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.badgeDark : AppColors.badgeLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          reciter.name.split(' ').take(2).join(' '),
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
