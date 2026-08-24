import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/models/surah.dart';
import '../../core/constants/app_colors.dart';
import '../providers/playlist_provider.dart';

/// A single row in the surah list.
class SurahTile extends StatelessWidget {
  final Surah surah;

  const SurahTile({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final inPlaylist = playlist.containsSurah(surah.id);

    final isMeccan = surah.revelationType == RevelationType.meccan;
    final tagBg = isMeccan
        ? (isDark ? AppColors.meccanDark : AppColors.meccanLight)
        : (isDark ? AppColors.medinanDark : AppColors.medinanLight);
    final tagFg = isMeccan
        ? (isDark ? const Color(0xFF8EC9A8) : const Color(0xFF2D6B4A))
        : (isDark ? const Color(0xFFC4976A) : const Color(0xFF6B4A1E));

    return InkWell(
      onTap: () {}, // reserved for navigation in later phases
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // --- Number badge ---
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.badgeDark : AppColors.badgeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${surah.id}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // --- Names & metadata ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        surah.nameEn,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMeccan ? 'Meccan' : 'Medinan',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tagFg,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        surah.nameEnTranslation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${surah.ayahCount} verses',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.mutedDark
                              : AppColors.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Arabic name ---
            Text(
              surah.nameAr,
              style: GoogleFonts.amiri(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // --- Add/remove button ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: inPlaylist
                  ? IconButton(
                      key: const ValueKey('check'),
                      icon: Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      onPressed: () {
                        final index = playlist.indexOfSurah(surah.id);
                        final removed = playlist.removeSurah(surah.id);
                        if (removed != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${surah.nameEn} removed'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () =>
                                    playlist.undoRemove(removed, index),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    )
                  : IconButton(
                      key: const ValueKey('add'),
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: isDark
                            ? AppColors.mutedDark
                            : AppColors.mutedLight,
                        size: 24,
                      ),
                      onPressed: () => playlist.addSurah(surah.id),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
