import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/app_snackbar.dart';

class PlaybackModeButton extends StatelessWidget {
  final double size;
  final bool showBackgroundOnActive;

  const PlaybackModeButton({
    super.key,
    this.size = 22.0,
    this.showBackgroundOnActive = false,
  });

  void _cycleMode(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final current = settings.playbackCompletion;

    final nextAction = switch (current) {
      PlaybackCompletionAction.repeat => PlaybackCompletionAction.next,
      _ => PlaybackCompletionAction.repeat,
    };

    settings.setPlaybackCompletion(nextAction);

    final msg = switch (nextAction) {
      PlaybackCompletionAction.repeat => context.tr('playback_repeat'),
      _ => context.tr('playback_next'),
    };

    showAppSnackBar(
      context,
      msg,
      duration: const Duration(milliseconds: 1400),
    );
  }

  void _showModePickerModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final settings = ctx.watch<SettingsProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    context.tr('on_track_completion'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildModalTile(
                  context,
                  title: context.tr('playback_next'),
                  icon: Icons.repeat_rounded,
                  action: PlaybackCompletionAction.next,
                  current: settings.playbackCompletion,
                  onSelect: (a) {
                    settings.setPlaybackCompletion(a);
                    Navigator.pop(ctx);
                  },
                ),
                _buildModalTile(
                  context,
                  title: context.tr('playback_repeat'),
                  icon: Icons.repeat_one_rounded,
                  action: PlaybackCompletionAction.repeat,
                  current: settings.playbackCompletion,
                  onSelect: (a) {
                    settings.setPlaybackCompletion(a);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required PlaybackCompletionAction action,
    required PlaybackCompletionAction current,
    required ValueChanged<PlaybackCompletionAction> onSelect,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = action == current;

    return ListTile(
      onTap: () => onSelect(action),
      leading: Icon(
        icon,
        color: isSelected
            ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
              : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 20,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final mode = settings.playbackCompletion;

    final (icon, tooltipKey, isActive) = switch (mode) {
      PlaybackCompletionAction.repeat => (
          Icons.repeat_one_rounded,
          'playback_repeat',
          true
        ),
      _ => (
          Icons.repeat_rounded,
          'playback_next',
          false
        ),
    };

    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Tooltip(
      message: context.tr(tooltipKey),
      child: Material(
        color: showBackgroundOnActive && isActive
            ? activeColor.withValues(alpha: 0.15)
            : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => _cycleMode(context),
          onLongPress: () => _showModePickerModal(context),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: size,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
