import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  final _hizbController = TextEditingController();
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
      _hizbController.text.trim().isNotEmpty ||
      _fromController.text.trim().isNotEmpty ||
      _toController.text.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _juzController.clear();
      _hizbController.clear();
      _fromController.clear();
      _toController.clear();
    });
  }

  void _onJuzChanged(String val) {
    if (val.trim().isNotEmpty) {
      if (_hizbController.text.isNotEmpty) _hizbController.clear();
      if (_fromController.text.isNotEmpty) _fromController.clear();
      if (_toController.text.isNotEmpty) _toController.clear();
    }
  }

  void _onHizbChanged(String val) {
    if (val.trim().isNotEmpty) {
      if (_juzController.text.isNotEmpty) _juzController.clear();
      if (_fromController.text.isNotEmpty) _fromController.clear();
      if (_toController.text.isNotEmpty) _toController.clear();
    }
  }

  void _onFromChanged(String val) {
    if (val.trim().isNotEmpty) {
      if (_juzController.text.isNotEmpty) _juzController.clear();
      if (_hizbController.text.isNotEmpty) _hizbController.clear();
    }
  }

  void _onToChanged(String val) {
    if (val.trim().isNotEmpty) {
      if (_juzController.text.isNotEmpty) _juzController.clear();
      if (_hizbController.text.isNotEmpty) _hizbController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndShowTutorial(),
    );
  }

  @override
  void dispose() {
    _removeTutorialOverlay();
    _searchController.dispose();
    _juzController.dispose();
    _hizbController.dispose();
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
    final int? hizb = int.tryParse(_hizbController.text.trim());
    final int? from = int.tryParse(_fromController.text.trim());
    final int? to = int.tryParse(_toController.text.trim());

    final isJuzActive = _juzController.text.trim().isNotEmpty;
    final isHizbActive = _hizbController.text.trim().isNotEmpty;
    final isFromActive = _fromController.text.trim().isNotEmpty;
    final isToActive = _toController.text.trim().isNotEmpty;

    final Set<int>? juzSurahIds = (juz != null && juz >= 1 && juz <= 30)
        ? SurahFilterData.surahIdsForJuz(juz)
        : null;
    final Set<int>? hizbSurahIds = (hizb != null && hizb >= 1 && hizb <= 60)
        ? SurahFilterData.surahIdsForHizb(hizb)
        : null;

    final bool isFromValid = from != null && from >= 1 && from <= 114;
    final bool isToValid = to != null && to >= 1 && to <= 114;

    final baseFiltered = surahs.where((s) {
      // 1. Text query filter
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchesText =
            s.nameEn.toLowerCase().contains(q) ||
            s.nameEnTranslation.toLowerCase().contains(q) ||
            s.localizedTranslation(context).toLowerCase().contains(q) ||
            s.nameAr.contains(q) ||
            '${s.id}'.contains(q);
        if (!matchesText) return false;
      }

      // 2. Juz filter: if active, must be in that Juz (invalid number yields no match)
      if (isJuzActive) {
        if (juzSurahIds == null || !juzSurahIds.contains(s.id)) return false;
      }

      // 3. Hizb filter: if active, must be in that Hizb (invalid number yields no match)
      if (isHizbActive) {
        if (hizbSurahIds == null || !hizbSurahIds.contains(s.id)) return false;
      }

      // 4. From / To surah range filter (invalid number yields no match)
      if (isFromActive && !isFromValid) return false;
      if (isToActive && !isToValid) return false;

      if (isFromValid && isToValid) {
        final minId = math.min(from, to);
        final maxId = math.max(from, to);
        if (s.id < minId || s.id > maxId) return false;
      } else if (isFromValid) {
        if (s.id < from) return false;
      } else if (isToValid) {
        if (s.id > to) return false;
      }

      return true;
    }).toList();

    final filtered = _isReversed
        ? baseFiltered.reversed.toList()
        : baseFiltered;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- App Bar ---
          SliverAppBar(
            floating: true,
            snap: true,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  isDark ? 'assets/sukun_logo_dark.png' : 'assets/sukun_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('sukun', style: theme.textTheme.titleLarge),
                Text(
                  "Qur'an, without distractions.",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
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
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
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
              IconButton(
                icon: const Icon(Icons.volunteer_activism_outlined, size: 22),
                tooltip: context.tr('contribute'),
                onPressed: () => context.push('/settings'),
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
          SliverToBoxAdapter(child: _ReciterSelectorHeader()),

          // --- Search bar & inline filter boxes ---
          // --- Search bar & filter button ---
          // --- Search bar & inline filter boxes ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(
                          minHeight: 46,
                          maxHeight: 46,
                        ),
                        hintText: context.tr('search_surahs'),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 46,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                tooltip: context.tr('clear_all'),
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),

                  // Small filter boxes next to search bar
                  if (_showFilters) ...[
                    const SizedBox(width: 5),
                    _buildSmallFilterBox(
                      controller: _juzController,
                      hint: 'Juz',
                      tooltip: '${context.tr('filter_juz')} (1 - 30)',
                      minVal: 1,
                      maxVal: 30,
                      maxLength: 2,
                      width: 40,
                      isDark: isDark,
                      theme: theme,
                      onChanged: _onJuzChanged,
                    ),
                    const SizedBox(width: 3),
                    _buildSmallFilterBox(
                      controller: _hizbController,
                      hint: 'Hzb',
                      tooltip: '${context.tr('filter_hizb')} (1 - 60)',
                      minVal: 1,
                      maxVal: 60,
                      maxLength: 2,
                      width: 40,
                      isDark: isDark,
                      theme: theme,
                      onChanged: _onHizbChanged,
                    ),
                    const SizedBox(width: 3),
                    _buildSmallFilterBox(
                      controller: _fromController,
                      hint: '1',
                      tooltip: '${context.tr('filter_from')} (1 - 114)',
                      minVal: 1,
                      maxVal: 114,
                      maxLength: 3,
                      width: 38,
                      isDark: isDark,
                      theme: theme,
                      onChanged: _onFromChanged,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Text(
                        '–',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildSmallFilterBox(
                      controller: _toController,
                      hint: '114',
                      tooltip: '${context.tr('filter_to')} (1 - 114)',
                      minVal: 1,
                      maxVal: 114,
                      maxLength: 3,
                      width: 38,
                      isDark: isDark,
                      theme: theme,
                      onChanged: _onToChanged,
                    ),
                  ],

                  const SizedBox(width: 5),

                  // Filter toggle button
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: (_showFilters || _hasActiveFilters)
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : (isDark
                                ? AppColors.surfaceContainerDark
                                : AppColors.surfaceContainerLight),
                      borderRadius: BorderRadius.circular(12),
                      border: (_showFilters || _hasActiveFilters)
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
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
                  ),
                ],
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
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            (!_hasActiveFilters && _query.isEmpty)
                                ? '114 chapters'
                                : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _clearFilters,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    context.tr('filter_clear'),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _isReversed = !_isReversed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 24,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.mutedLight,
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
              delegate: SliverChildBuilderDelegate((context, index) {
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
              }, childCount: filtered.length),
            ),

          // Bottom padding so mini-player doesn't hide last item
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: () {
        final isFiltered = _hasActiveFilters || _query.isNotEmpty;
        final unaddedFilteredCount = filtered
            .where((s) => !playlist.containsSurah(s.id))
            .length;
        final canAddAll = playlist.items.length < surahs.length;

        if (isFiltered && unaddedFilteredCount > 0) {
          return FloatingActionButton.extended(
            heroTag: 'add_filtered',
            onPressed: () {
              final added = playlist.addSurahs(filtered.map((s) => s.id));
              showAppSnackBar(
                context,
                '$added surah${added == 1 ? '' : 's'} added to playlist',
              );
            },
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: Text('Add all (${filtered.length})'),
          );
        }

        if (canAddAll) {
          return FloatingActionButton.extended(
            heroTag: 'add_all',
            onPressed: () {
              playlist.addAllSurahs();
              showAppSnackBar(context, 'All 114 surahs added to playlist');
            },
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text('Add all'),
          );
        }

        return null;
      }(),
    );
  }

  Widget _buildSmallFilterBox({
    required TextEditingController controller,
    required String hint,
    required String tooltip,
    required int minVal,
    required int maxVal,
    required int maxLength,
    double width = 64,
    required bool isDark,
    required ThemeData theme,
    ValueChanged<String>? onChanged,
  }) {
    final text = controller.text.trim();
    final hasValue = text.isNotEmpty;
    final val = int.tryParse(text);
    final bool isValid =
        hasValue && val != null && val >= minVal && val <= maxVal;
    final bool isInvalid = hasValue && !isValid;

    final Color? stateColor = isInvalid
        ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
        : (isValid ? theme.colorScheme.primary : null);

    final Color fillColor = stateColor != null
        ? stateColor.withValues(alpha: 0.14)
        : (isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight);

    final BorderSide borderSide = stateColor != null
        ? BorderSide(color: stateColor, width: 1.5)
        : BorderSide.none;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: width,
        height: 46,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          maxLength: maxLength,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: stateColor,
            fontSize: 13,
          ),
          onChanged: (v) {
            onChanged?.call(v);
            setState(() {});
          },
          decoration: InputDecoration(
            constraints: const BoxConstraints(minHeight: 46, maxHeight: 46),
            hintText: hint,
            counterText: '',
            hintStyle: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              fontSize: 12,
            ),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: borderSide,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: borderSide,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: stateColor != null
                  ? BorderSide(color: stateColor, width: 2)
                  : BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 19),
            isDense: true,
          ),
        ),
      ),
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
                      horizontal: 10,
                      vertical: 6,
                    ),
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
          Expanded(flex: 5, child: buildMainCard(isCompact: true)),
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
                      player.selectReciter(r);
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
