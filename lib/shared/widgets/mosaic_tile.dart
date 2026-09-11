import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/models/surah.dart';
import '../../core/constants/app_colors.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';

/// A fluid square mosaic tile representing one surah in the Fluid Mosaic grid.
///
/// =========================================================================
/// 🛠 PARAMETERS YOU CAN CUSTOMIZE FOR TILE & TEXT SIZES:
/// =========================================================================
/// Edit the constants in `_MosaicTileState.build` inside LayoutBuilder:
///  - `numSize`: Surah number size (top-left)
///  - `arabicSize`: Arabic text size (center)
///  - `nameSize`: English name size (bottom)
///  - `tileBorderRadius`: Roundness of tile corners (e.g. 10.0, 14.0)
/// =========================================================================
class MosaicTile extends StatefulWidget {
  final Surah surah;

  const MosaicTile({super.key, required this.surah});

  @override
  State<MosaicTile> createState() => _MosaicTileState();
}

class _MosaicTileState extends State<MosaicTile> {
  bool _pressed = false;

  void _togglePlaylist(BuildContext context) {
    final playlist = context.read<PlaylistProvider>();
    final surahId = widget.surah.id;

    if (playlist.containsSurah(surahId)) {
      playlist.removeSurah(surahId);
    } else {
      playlist.addSurah(surahId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playlist = context.watch<PlaylistProvider>();
    final player = context.watch<PlayerProvider>();

    final inPlaylist = playlist.containsSurah(widget.surah.id);
    final isCurrentlyPlaying =
        player.currentSurah?.id == widget.surah.id && player.isPlaying;

    final isActive = inPlaylist || isCurrentlyPlaying;

    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    final tileBg = isActive
        ? null
        : (isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _togglePlaylist(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? null : tileBg,
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12), // ⚙️ Tile corner radius
              border: Border.all(
                color: isActive
                    ? primaryColor
                    : (isDark
                          ? AppColors.outlineDark.withValues(alpha: 0.3)
                          : AppColors.outlineLight.withValues(alpha: 0.5)),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = constraints.maxWidth;

                // =========================================================
                // ⚙️ TWEAK FONT SIZES HERE:
                // `(tileSize * multiplier).clamp(minSize, maxSize)`
                // =========================================================
                final numSize = (tileSize * 0.15).clamp(9.0, 13.0);
                final arabicSize = (tileSize * 0.26).clamp(20.0, 34.0);
                final nameSize = (tileSize * 0.095).clamp(11.0, 15.0);

                return Stack(
                  children: [
                    // --- Surah number (top-left) ---
                    Positioned(
                      top: tileSize * 0.06,
                      left: tileSize * 0.08,
                      child: Text(
                        '${widget.surah.id}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: numSize,
                          fontWeight: FontWeight.w900,
                          color: isActive
                              ? onPrimaryColor.withValues(alpha: 0.85)
                              : primaryColor,
                        ),
                      ),
                    ),

                    // --- Active indicator dot (top-right) ---
                    if (isActive)
                      Positioned(
                        top: tileSize * 0.06,
                        right: tileSize * 0.08,
                        child: Container(
                          width: (tileSize * 0.10).clamp(5.0, 8.0),
                          height: (tileSize * 0.10).clamp(5.0, 8.0),
                          decoration: BoxDecoration(
                            color: onPrimaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: onPrimaryColor.withValues(alpha: 0.7),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // --- Centered content (Arabic + English name) ---
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: tileSize * 0.19,
                          left: tileSize * 0.06,
                          right: tileSize * 0.06,
                          bottom: tileSize * 0.07,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          // Arabic name (Center)
                          Text(
                            widget.surah.nameAr,
                            style: GoogleFonts.amiri(
                              fontSize: arabicSize,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? onPrimaryColor
                                  : (isDark
                                        ? AppColors.onSurfaceDark
                                        : AppColors.onSurfaceLight),
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                          SizedBox(height: tileSize * 0.02),
                          // English name (Bottom)
                          Flexible(
                            child: Text(
                              widget.surah.nameEn.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: nameSize,
                                fontWeight: FontWeight.w800,
                                color: isActive
                                    ? onPrimaryColor.withValues(alpha: 0.9)
                                    : (isDark
                                          ? AppColors.mutedDark
                                          : AppColors.mutedLight),
                                letterSpacing: 0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
