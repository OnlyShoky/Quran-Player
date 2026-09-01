import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/surah.dart';
import '../../core/constants/app_colors.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';

/// A square mosaic tile representing one surah in the Fluid Mosaic grid.
/// Faithfully adapted from the Fluid Mosaic HTML prototype.
class MosaicTile extends StatefulWidget {
  final Surah surah;

  const MosaicTile({super.key, required this.surah});

  @override
  State<MosaicTile> createState() => _MosaicTileState();
}

class _MosaicTileState extends State<MosaicTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _playSurah(BuildContext context) {
    final playlist = context.read<PlaylistProvider>();
    final player = context.read<PlayerProvider>();

    final reciter = playlist.selectedReciter;
    if (reciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reciter first')),
      );
      return;
    }

    final index = playlist.ensureSurahInPlaylist(widget.surah.id);
    if (index != -1) {
      player.loadAndPlay(surah: widget.surah, reciter: reciter, index: index);
      context.go('/player');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final player = context.watch<PlayerProvider>();

    final isCurrentlyPlaying =
        player.currentSurah?.id == widget.surah.id && player.isPlaying;
    final isActive = isCurrentlyPlaying;

    final tileBg = isActive
        ? null // Uses gradient decoration instead
        : (isDark ? AppColors.mosaicTileDark : AppColors.mosaicTileLight);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _playSurah(context);
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
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.mosaicActive,
                        AppColors.mosaicActiveEnd,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? AppColors.mosaicActiveGlow
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.black.withValues(alpha: 0.04)),
                width: 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: AppColors.mosaicActiveGlow.withValues(alpha: 0.2),
                    blurRadius: 15,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = constraints.maxWidth;

                // Responsive font sizes based on tile size
                final numSize = (tileSize * 0.14).clamp(9.0, 13.0);
                final arabicSize = (tileSize * 0.35).clamp(18.0, 36.0);
                final nameSize = (tileSize * 0.11).clamp(7.0, 11.0);

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
                              ? AppColors.mosaicActiveMuted
                              : (isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight),
                        ),
                      ),
                    ),

                    // --- Active indicator dot (top-right) ---
                    if (isActive)
                      Positioned(
                        top: tileSize * 0.06,
                        right: tileSize * 0.08,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // --- Centered content (Arabic + English name) ---
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: tileSize * 0.08),
                          // Arabic name
                          Text(
                            widget.surah.nameAr,
                            style: GoogleFonts.amiri(
                              fontSize: arabicSize,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
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
                          // English name
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: tileSize * 0.05),
                            child: Text(
                              widget.surah.nameEn.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: nameSize,
                                fontWeight: FontWeight.w800,
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFF94a3b8)
                                        : AppColors.mutedLight),
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
