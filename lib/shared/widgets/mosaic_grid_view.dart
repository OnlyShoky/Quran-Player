import 'package:flutter/material.dart';

import '../../core/models/surah.dart';
import 'mosaic_tile.dart';

/// A fluid, responsive grid of [MosaicTile] widgets.
///
/// =========================================================================
/// 🛠 PARAMETERS YOU CAN CUSTOMIZE FOR GRID SIZE & DENSITY:
/// =========================================================================
/// 1. `_columnCount(double width)` below:
///    - Return `4` for 4 tiles per row on mobile screens (< 400px wide)
///    - Return `5` for 5 tiles per row
///    - Return `6` or `7` for even smaller, denser tiles
/// 2. `gridSpacing`: gap between tiles in pixels (e.g., 4.0, 6.0, 8.0, 10.0)
/// 3. `gridPadding`: outer margin around the entire grid
/// =========================================================================
class MosaicGridView extends StatelessWidget {
  final List<Surah> surahs;

  // ⚙️ TWEAK THESE PARAMETERS:
  static const double gridSpacing = 6.0; // Space between tiles
  static const double gridPadding = 8.0; // Outer margin

  const MosaicGridView({super.key, required this.surahs});

  /// ⚙️ TWEAK COLUMN COUNTS HERE:
  int _columnCount(double width) {
    if (width < 360) return 4; // Mobile narrow: 4 columns
    if (width < 500) return 5; // Mobile standard: 5 columns
    if (width < 750) return 6; // Tablet / Wide: 6 columns
    if (width < 1080) return 6; // Tablet / Wide: 6 columns
    return 19; // Large desktop: 8 columns
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = _columnCount(screenWidth);

    return SliverPadding(
      padding: const EdgeInsets.all(gridPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: gridSpacing,
          crossAxisSpacing: gridSpacing,
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
