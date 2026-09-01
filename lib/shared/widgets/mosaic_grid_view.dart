import 'package:flutter/material.dart';
import '../../core/models/surah.dart';
import 'mosaic_tile.dart';

/// A responsive grid of [MosaicTile] widgets.
/// Adapts column count based on screen width, matching the
/// Fluid Mosaic HTML prototype's responsive behavior.
class MosaicGridView extends StatelessWidget {
  final List<Surah> surahs;

  const MosaicGridView({super.key, required this.surahs});

  int _columnCount(double width) {
    if (width < 360) return 4;
    if (width < 500) return 5;
    if (width < 700) return 6;
    if (width < 900) return 7;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = _columnCount(screenWidth);
    const spacing = 8.0;

    return SliverPadding(
      padding: const EdgeInsets.all(spacing),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => MosaicTile(surah: surahs[index]),
          childCount: surahs.length,
        ),
      ),
    );
  }
}
