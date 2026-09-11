import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class ViewModeTutorialOverlay extends StatefulWidget {
  final Rect targetRect;
  final VoidCallback onDismiss;
  final VoidCallback onToggleMode;
  final bool isMosaic;

  const ViewModeTutorialOverlay({
    super.key,
    required this.targetRect,
    required this.onDismiss,
    required this.onToggleMode,
    required this.isMosaic,
  });

  @override
  State<ViewModeTutorialOverlay> createState() => _ViewModeTutorialOverlayState();
}

class _ViewModeTutorialOverlayState extends State<ViewModeTutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _entranceController.reverse();
    widget.onDismiss();
  }

  void _handleToggle() async {
    await _entranceController.reverse();
    widget.onToggleMode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final screenSize = MediaQuery.of(context).size;

    final targetCenter = widget.targetRect.center;
    final targetRadius = (math.max(widget.targetRect.width, widget.targetRect.height) / 2) + 6;

    // Calculate vertical position for the card
    final cardTop = widget.targetRect.bottom + 12;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Stack(
            children: [
              // 1. Semi-transparent backdrop with spotlight cut-out
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleDismiss,
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      targetCenter: targetCenter,
                      targetRadius: targetRadius,
                      pulseOffset: _pulseAnimation.value,
                      primaryColor: primaryColor,
                    ),
                  ),
                ),
              ),

              // 2. Clickable active area directly over the target button
              Positioned(
                left: targetCenter.dx - targetRadius,
                top: targetCenter.dy - targetRadius,
                width: targetRadius * 2,
                height: targetRadius * 2,
                child: GestureDetector(
                  onTap: _handleToggle,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),

              // 3. Pointer arrow pointing upwards to the target button
              Positioned(
                top: cardTop - 9,
                left: (targetCenter.dx - 10).clamp(24.0, screenSize.width - 44.0),
                child: CustomPaint(
                  size: const Size(20, 10),
                  painter: _ArrowPainter(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                    borderColor: isDark
                        ? AppColors.outlineDark
                        : AppColors.outlineLight,
                  ),
                ),
              ),

              // 4. Tutorial Card
              Positioned(
                top: cardTop,
                left: 16,
                right: 16,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment(
                    (targetCenter.dx / screenSize.width) * 2 - 1,
                    -1.0,
                  ),
                  child: Material(
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header badge & close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      context.tr('tutorial_badge'),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _handleDismiss,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.mutedDark
                                        : AppColors.mutedLight,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Title
                          Text(
                            context.tr('tutorial_title'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Description
                          Text(
                            widget.isMosaic
                                ? context.tr('tutorial_body_to_list')
                                : context.tr('tutorial_body_to_mosaic'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.mutedDark
                                  : AppColors.mutedLight,
                              height: 1.4,
                              fontSize: 13.5,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Visual explanation cards
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight)
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (isDark
                                        ? AppColors.outlineDark
                                        : AppColors.outlineLight)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _ModePreviewItem(
                                    icon: Icons.view_list_rounded,
                                    title: context.tr('view_list'),
                                    description: 'Classic & sorted',
                                    isActive: !widget.isMosaic,
                                    activeColor: primaryColor,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: isDark
                                      ? AppColors.outlineDark
                                      : AppColors.outlineLight,
                                ),
                                Expanded(
                                  child: _ModePreviewItem(
                                    icon: Icons.grid_view_rounded,
                                    title: context.tr('view_mosaic'),
                                    description: 'Modern & visual',
                                    isActive: widget.isMosaic,
                                    activeColor: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleToggle,
                                  icon: Icon(
                                    widget.isMosaic
                                        ? Icons.view_list_rounded
                                        : Icons.grid_view_rounded,
                                    size: 17,
                                    color: primaryColor,
                                  ),
                                  label: Text(
                                    widget.isMosaic
                                        ? context.tr('tutorial_try_list')
                                        : context.tr('tutorial_try_mosaic'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    side: BorderSide(
                                      color: primaryColor.withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _handleDismiss,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('tutorial_got_it'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModePreviewItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;
  final Color activeColor;

  const _ModePreviewItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? activeColor
                  : (isDark ? AppColors.mutedDark : AppColors.mutedLight)
                      .withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isActive
                ? activeColor
                : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? (isDark
                          ? AppColors.onSurfaceDark
                          : AppColors.onSurfaceLight)
                      : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset targetCenter;
  final double targetRadius;
  final double pulseOffset;
  final Color primaryColor;

  _SpotlightPainter({
    required this.targetCenter,
    required this.targetRadius,
    required this.pulseOffset,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Semi-transparent backdrop
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;

    // Create path with cut-out hole
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path()
      ..addOval(
        Rect.fromCircle(
          center: targetCenter,
          radius: targetRadius,
        ),
      );

    final resultPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(resultPath, backgroundPaint);

    // 2. Pulsing spotlight halo ring around hole
    final pulsePaint = Paint()
      ..color = primaryColor.withValues(
        alpha: (0.4 - (pulseOffset / 20.0)).clamp(0.08, 0.4),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + (pulseOffset * 0.5);

    canvas.drawCircle(
      targetCenter,
      targetRadius + 2 + pulseOffset,
      pulsePaint,
    );

    // 3. Crisp inner ring around target
    final innerRingPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      targetCenter,
      targetRadius + 1,
      innerRingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetCenter != targetCenter ||
        oldDelegate.targetRadius != targetRadius ||
        oldDelegate.pulseOffset != pulseOffset ||
        oldDelegate.primaryColor != primaryColor;
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _ArrowPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, fillPaint);
    // Draw top 2 edges of arrow border
    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}
