import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A badge tag displaying a reciter's recitation type (Riwayah) or language,
/// styled identically to the Meccan / Medinan Surah badge tags.
class ReciterTypeBadge extends StatelessWidget {
  final String riwayah;
  final double fontSize;

  const ReciterTypeBadge({
    super.key,
    required this.riwayah,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (riwayah.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final lower = riwayah.toLowerCase().trim();

    Color tagBg;
    Color tagFg;

    if (lower.contains('warsh')) {
      // Warm amber (matches Medinan tag style)
      tagBg = isDark ? AppColors.medinanDark : AppColors.medinanLight;
      tagFg = isDark ? const Color(0xFFC4976A) : const Color(0xFF6B4A1E);
    } else if (lower.contains('english') ||
        lower.contains('spanish') ||
        lower.contains('español') ||
        lower.contains('french') ||
        lower.contains('urdu')) {
      // Soft violet for languages / translations
      tagBg = isDark ? const Color(0xFF2B1D38) : const Color(0xFFEBDCF5);
      tagFg = isDark ? const Color(0xFFC48EE0) : const Color(0xFF652A80);
    } else if (lower.contains('duri') ||
        lower.contains('qaloon') ||
        lower.contains('qalon') ||
        lower.contains('khalaf') ||
        lower.contains('shubah') ||
        lower.contains("shu'bah") ||
        lower.contains('sousi') ||
        lower.contains('bazzi') ||
        lower.contains('qunbul') ||
        lower.contains('rawh')) {
      // Cool indigo/blue for other classical riwayat
      tagBg = isDark ? const Color(0xFF1B2838) : const Color(0xFFDAE7F5);
      tagFg = isDark ? const Color(0xFF84B0E0) : const Color(0xFF225180);
    } else {
      // Hafs (default) — soft sage green (matches Meccan tag style)
      tagBg = isDark ? AppColors.meccanDark : AppColors.meccanLight;
      tagFg = isDark ? const Color(0xFF8EC9A8) : const Color(0xFF2D6B4A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        riwayah,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tagFg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
