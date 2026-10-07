import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/reciter.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../utils/app_snackbar.dart';
import 'reciter_type_badge.dart';

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

// ---------------------------------------------------------------------------
// Compact filter button next to the search bar
// ---------------------------------------------------------------------------
class _FilterButton extends StatelessWidget {
  final bool isActive;
  final String? activeLabel;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterButton({
    required this.isActive,
    required this.onTap,
    this.activeLabel,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isActive
        ? theme.colorScheme.primaryContainer
        : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight);
    final fgColor = isActive
        ? theme.colorScheme.primary
        : (isDark ? AppColors.mutedDark : AppColors.mutedLight);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.filter_alt_rounded : Icons.tune_rounded,
              size: 20,
              color: fgColor,
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 16, color: fgColor),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: fgColor),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scrollable filter bottom sheet
// ---------------------------------------------------------------------------
class _FilterBottomSheet extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final List<String> sortedRiwayatList;
  final Map<String, int> countsByRiwayah;
  final String selectedRiwayah;
  final ValueChanged<String> onSelected;
  final String titleLabel;
  final String allLabel;

  const _FilterBottomSheet({
    required this.isDark,
    required this.theme,
    required this.sortedRiwayatList,
    required this.countsByRiwayah,
    required this.selectedRiwayah,
    required this.onSelected,
    required this.titleLabel,
    required this.allLabel,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight;
    final sheetBg =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final allOptions = ['All', ...sortedRiwayatList];

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.50,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    titleLabel,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: allOptions.length,
                itemBuilder: (context, index) {
                  final option = allOptions[index];
                  final isSelected =
                      selectedRiwayah.toLowerCase() == option.toLowerCase();
                  final count = countsByRiwayah[option] ?? 0;
                  final isAll = option == 'All';
                  final displayLabel = isAll ? allLabel : option;

                  return InkWell(
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: isAll
                                ? Icon(
                                    Icons.all_inclusive_rounded,
                                    size: 16,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isDark
                                            ? AppColors.mutedDark
                                            : AppColors.mutedLight),
                                  )
                                : ReciterTypeBadge(riwayah: option),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.12)
                                  : (isDark
                                      ? surfaceColor
                                      : AppColors.outlineLight
                                          .withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                        ? AppColors.mutedDark
                                        : AppColors.mutedLight),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: isSelected
                                ? Icon(Icons.check_rounded,
                                    size: 18, color: theme.colorScheme.primary)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Random mode chip button
// ---------------------------------------------------------------------------
class _RandomModeChip extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _RandomModeChip({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    if (!isEnabled) {
      bgColor = isDark
          ? AppColors.surfaceContainerDark.withValues(alpha: 0.5)
          : AppColors.surfaceContainerLight.withValues(alpha: 0.5);
      fgColor = isDark
          ? AppColors.mutedDark.withValues(alpha: 0.4)
          : AppColors.mutedLight.withValues(alpha: 0.4);
      borderColor = Colors.transparent;
    } else if (isActive) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.12);
      fgColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
    } else {
      bgColor = isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLight;
      fgColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
      borderColor = Colors.transparent;
    }

    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: fgColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: fgColor,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: fgColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main reciter selector sheet
// ---------------------------------------------------------------------------
class ReciterSelectorSheet extends StatefulWidget {
  const ReciterSelectorSheet({super.key});

  @override
  State<ReciterSelectorSheet> createState() => _ReciterSelectorSheetState();
}

class _ReciterSelectorSheetState extends State<ReciterSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRiwayahFilter = 'All';

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

    final availableRiwayat = <String>{};
    for (final r in allReciters) {
      if (r.riwayah.isNotEmpty) availableRiwayat.add(r.riwayah);
    }
    final sortedRiwayatList = availableRiwayat.toList()
      ..sort((a, b) {
        const priority = ['Hafs', 'Warsh', 'Al-Duri'];
        final ai = priority.indexOf(a);
        final bi = priority.indexOf(b);
        if (ai != -1 && bi != -1) return ai.compareTo(bi);
        if (ai != -1) return -1;
        if (bi != -1) return 1;
        return a.compareTo(b);
      });

    final isFilterActive = _selectedRiwayahFilter != 'All';

    final countsByRiwayah = <String, int>{'All': allReciters.length};
    for (final r in allReciters) {
      if (r.riwayah.isNotEmpty) {
        countsByRiwayah[r.riwayah] = (countsByRiwayah[r.riwayah] ?? 0) + 1;
      }
    }

    final filteredReciters = allReciters.where((r) {
      if (isFilterActive &&
          r.riwayah.toLowerCase() != _selectedRiwayahFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return r.name.toLowerCase().contains(q) ||
            r.style.toLowerCase().contains(q) ||
            r.riwayah.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final sortedReciters = List<Reciter>.from(filteredReciters)
      ..sort((a, b) {
        final aPin = playlist.isPinned(a.id);
        final bPin = playlist.isPinned(b.id);
        if (aPin && !bPin) return -1;
        if (!aPin && bPin) return 1;

        final aFav = playlist.isFavorite(a.id);
        final bFav = playlist.isFavorite(b.id);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;

        final nameCmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (nameCmp != 0) return nameCmp;
        return a.riwayah.compareTo(b.riwayah);
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(context.tr('select_reciter'),
                      style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.trim()),
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    isActive: isFilterActive,
                    activeLabel:
                        isFilterActive ? _selectedRiwayahFilter : null,
                    onTap: () => _showFilterSheet(
                      context: context,
                      isDark: isDark,
                      theme: theme,
                      sortedRiwayatList: sortedRiwayatList,
                      countsByRiwayah: countsByRiwayah,
                    ),
                    onClear: isFilterActive
                        ? () => setState(() => _selectedRiwayahFilter = 'All')
                        : null,
                  ),
                ],
              ),
            ),

            if (isFilterActive) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_rounded,
                        size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${filteredReciters.length} reciters · $_selectedRiwayahFilter',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRiwayahFilter = 'All'),
                      child: Text(
                        'Clear',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Random reciter mode buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _RandomModeChip(
                      label: context.tr('random_reciter'),
                      tooltip: context.tr('random_reciter_desc'),
                      icon: Icons.casino_rounded,
                      isActive: playlist.isRandomReciterMode,
                      isEnabled: true,
                      onTap: () => playlist.toggleRandomReciterMode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RandomModeChip(
                      label: context.tr('random_fav_reciter'),
                      tooltip: playlist.canEnableRandomFavReciterMode
                          ? context.tr('random_fav_reciter_desc')
                          : context.tr('random_fav_reciter_disabled'),
                      icon: Icons.favorite_rounded,
                      isActive: playlist.isRandomFavReciterMode,
                      isEnabled: playlist.canEnableRandomFavReciterMode,
                      onTap: () => playlist.toggleRandomFavReciterMode(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

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
                          separatorBuilder: (_, _) => Divider(
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
                                  Flexible(
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ReciterTypeBadge(riwayah: reciter.riwayah),
                                ],
                              ),
                              subtitle: reciter.style.isNotEmpty
                                  ? Text(
                                      reciter.style,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: isDark
                                            ? AppColors.mutedDark
                                            : AppColors.mutedLight,
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                    onPressed: () => playlist
                                        .toggleFavoriteReciter(reciter.id),
                                  ),
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
                                      final success = await playlist
                                          .togglePinReciter(reciter.id);
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
                                player.selectReciter(reciter);
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

  void _showFilterSheet({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required List<String> sortedRiwayatList,
    required Map<String, int> countsByRiwayah,
  }) {
    // Capture translated strings here, where context has localizations
    final titleLabel = context.tr('filter_by_type');
    final allLabel = context.tr('tab_all');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        isDark: isDark,
        theme: theme,
        sortedRiwayatList: sortedRiwayatList,
        countsByRiwayah: countsByRiwayah,
        selectedRiwayah: _selectedRiwayahFilter,
        onSelected: (val) => setState(() => _selectedRiwayahFilter = val),
        titleLabel: titleLabel,
        allLabel: allLabel,
      ),
    );
  }
}
