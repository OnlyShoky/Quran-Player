import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/mock_data.dart';
import '../../core/data/surah_filter_data.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/providers/playlist_provider.dart';
import '../../shared/providers/player_provider.dart';
import '../../shared/providers/view_mode_provider.dart';
import '../../shared/widgets/surah_tile.dart';
import '../../shared/widgets/mosaic_grid_view.dart';
import '../../shared/widgets/reciter_selector_sheet.dart';
import '../../shared/widgets/view_mode_tutorial_overlay.dart';
import '../../shared/utils/app_snackbar.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _searchController = TextEditingController();
  final _juzController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final GlobalKey _viewModeButtonKey = GlobalKey();
  OverlayEntry? _tutorialOverlayEntry;
  bool _tutorialScheduled = false;
  String _query = '';
  bool _showFilters = false;
  bool _isReversed = false;

  bool get _hasActiveFilters =>
      _juzController.text.trim().isNotEmpty ||
      _fromController.text.trim().isNotEmpty ||
      _toController.text.trim().isNotEmpty ||
      _isReversed;

  void _clearFilters() {
    setState(() {
      _juzController.clear();
      _fromController.clear();
      _toController.clear();
      _isReversed = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowTutorial());
  }

  @override
  void dispose() {
    _removeTutorialOverlay();
    _searchController.dispose();
    _juzController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _removeTutorialOverlay() {
    _tutorialOverlayEntry?.remove();
    _tutorialOverlayEntry = null;
  }

  void _checkAndShowTutorial() {
    if (!mounted || _tutorialOverlayEntry != null) return;
    final viewMode = context.read<ViewModeProvider>();
    if (!viewMode.shouldShowTutorial) return;

    final renderBox =
        _viewModeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      if (!_tutorialScheduled) {
        _tutorialScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tutorialScheduled = false;
          _checkAndShowTutorial();
        });
      }
      return;
    }

    final targetOffset = renderBox.localToGlobal(Offset.zero);
    final targetRect = targetOffset & renderBox.size;

    _tutorialOverlayEntry = OverlayEntry(
      builder: (ctx) => ViewModeTutorialOverlay(
        targetRect: targetRect,
        isMosaic: viewMode.mode == ViewMode.mosaic,
        onDismiss: () {
          _removeTutorialOverlay();
          viewMode.completeTutorial();
        },
        onToggleMode: () {
          _removeTutorialOverlay();
          viewMode.toggle();
          viewMode.completeTutorial();
        },
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_tutorialOverlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final viewMode = context.watch<ViewModeProvider>();
    final surahs = MockData.surahs;
    final isMosaic = viewMode.mode == ViewMode.mosaic;

    if (viewMode.shouldShowTutorial &&
        _tutorialOverlayEntry == null &&
        !_tutorialScheduled) {
      _tutorialScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tutorialScheduled = false;
        _checkAndShowTutorial();
      });
    }

    final int? juz = int.tryParse(_juzController.text.trim());
    final int? from = int.tryParse(_fromController.text.trim());
    final int? to = int.tryParse(_toController.text.trim());

    final Set<int>? juzSurahIds = (juz != null && juz >= 1 && juz <= 30)
        ? SurahFilterData.surahIdsForJuz(juz)
        : null;

    final baseFiltered = surahs.where((s) {
      // 1. Text query filter
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchesText = s.nameEn.toLowerCase().contains(q) ||
            s.nameEnTranslation.toLowerCase().contains(q) ||
            s.nameAr.contains(q) ||
            '${s.id}'.contains(q);
        if (!matchesText) return false;
      }

      // 2. Juz filter: if a valid Juz number is entered (1-30), show only surahs in that Juz
      if (juzSurahIds != null && !juzSurahIds.contains(s.id)) {
        return false;
      }

      // 3. From / To surah range filter
      if (from != null && to != null) {
        final minId = math.min(from, to);
        final maxId = math.max(from, to);
        if (s.id < minId || s.id > maxId) return false;
      } else if (from != null) {
        if (s.id < from) return false;
      } else if (to != null) {
        if (s.id > to) return false;
      }

      return true;
    }).toList();

    final filtered =
        _isReversed ? baseFiltered.reversed.toList() : baseFiltered;

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
                key: _viewModeButtonKey,
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
                tooltip: isMosaic
                    ? context.tr('tooltip_list_view')
                    : context.tr('tooltip_mosaic_view'),
                onPressed: viewMode.toggle,
              ),
              // --- Settings button ---
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 22),
                tooltip: context.tr('tooltip_settings'),
                onPressed: () => context.push('/settings'),
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
                  hintText: context.tr('search_surahs'),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          tooltip: context.tr('clear_all'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: _hasActiveFilters,
                          smallSize: 8,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            _showFilters
                                ? Icons.filter_list_rounded
                                : Icons.tune_rounded,
                            size: 20,
                            color: (_showFilters || _hasActiveFilters)
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? AppColors.mutedDark
                                    : AppColors.mutedLight),
                          ),
                        ),
                        tooltip: context.tr('filters'),
                        onPressed: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                    ],
                  ),
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

          // --- Collapsible filter panel ---
          if (_showFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.outlineDark.withValues(alpha: 0.5)
                          : AppColors.outlineLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Title + Clear
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    context.tr('filters'),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_hasActiveFilters)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: _clearFilters,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.restart_alt_rounded,
                                      size: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.tr('filter_clear'),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filter 1: Juz (1-30)
                      TextField(
                        controller: _juzController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.bodyMedium,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: '${context.tr('filter_juz')} (1 - 30)',
                          hintText: '1 - 30',
                          prefixIcon: const Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                          ),
                          suffixIcon: _juzController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 16),
                                  onPressed: () {
                                    _juzController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.outlineDark
                                  : AppColors.outlineLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.outlineDark.withValues(alpha: 0.5)
                                  : AppColors.outlineLight.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter 2 & 3: Surah Range (From ... To ...)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fromController,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.bodyMedium,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: context.tr('filter_from'),
                                hintText: '1',
                                prefixIcon: const Icon(
                                  Icons.tag_rounded,
                                  size: 18,
                                ),
                                suffixIcon: _fromController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            size: 16),
                                        onPressed: () {
                                          _fromController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.outlineDark
                                        : AppColors.outlineLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.outlineDark.withValues(alpha: 0.5)
                                        : AppColors.outlineLight
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _toController,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.bodyMedium,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: context.tr('filter_to'),
                                hintText: '114',
                                prefixIcon: const Icon(
                                  Icons.tag_rounded,
                                  size: 18,
                                ),
                                suffixIcon: _toController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            size: 16),
                                        onPressed: () {
                                          _toController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.outlineDark
                                        : AppColors.outlineLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.outlineDark.withValues(alpha: 0.5)
                                        : AppColors.outlineLight
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Reverse order toggle inside filter panel
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _isReversed = !_isReversed),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_vert_rounded,
                                      size: 20,
                                      color: _isReversed
                                          ? theme.colorScheme.primary
                                          : (isDark
                                              ? AppColors.mutedDark
                                              : AppColors.mutedLight),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        context.tr('reverse_order'),
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isReversed ? '(114 → 1)' : '(1 → 114)',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isDark
                                            ? AppColors.mutedDark
                                            : AppColors.mutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch.adaptive(
                                value: _isReversed,
                                onChanged: (v) =>
                                    setState(() => _isReversed = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Surah count & quick reverse ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (!_hasActiveFilters && _query.isEmpty)
                        ? '114 chapters'
                        : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _isReversed = !_isReversed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 16,
                            color: _isReversed
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? AppColors.mutedDark
                                    : AppColors.mutedLight),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isReversed ? '114 → 1' : '1 → 114',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _isReversed
                                  ? theme.colorScheme.primary
                                  : (isDark
                                      ? AppColors.mutedDark
                                      : AppColors.mutedLight),
                              fontWeight: _isReversed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- List or Mosaic view ---
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color:
                            isDark ? AppColors.mutedDark : AppColors.mutedLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('no_surahs_found'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isMosaic)
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
                showAppSnackBar(context, 'All 114 surahs added to playlist');
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
    final player = context.read<PlayerProvider>();
    final selectedReciter = playlist.selectedReciter;
    final pinnedReciters = playlist.pinnedReciters;

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
            Expanded(
              child: Text(
                'Loading reciters from API...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildMainCard({required bool isCompact}) {
      return Material(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => showReciterSelectorModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 14,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('reciter_label').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                          letterSpacing: 0.8,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        selectedReciter?.name ?? context.tr('select_reciter'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          context.tr('change_reciter'),
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
                ] else ...[
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (pinnedReciters.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: buildMainCard(isCompact: false),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Main bar on left
          Expanded(
            flex: 5,
            child: buildMainCard(isCompact: true),
          ),
          const SizedBox(width: 8),

          // Quick-select pinned reciter buttons on right
          ...pinnedReciters.map((r) {
            final isSelected = playlist.selectedReciterId == r.id;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: r.name,
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLight),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      playlist.selectReciter(r.id);
                      if (player.currentSurah != null) {
                        player.loadAndPlay(
                          surah: player.currentSurah!,
                          reciter: r,
                          index: player.currentIndex,
                        );
                      }
                    },
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      constraints: const BoxConstraints(minWidth: 52),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.shortName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : (isDark
                                      ? AppColors.onSurfaceDark
                                      : AppColors.onSurfaceLight),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
