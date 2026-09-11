import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/audio_api_source.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/providers/view_mode_provider.dart';
import '../../shared/utils/app_snackbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final viewMode = context.watch<ViewModeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('settings_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ================= APPEARANCE =================
          _SectionHeader(
            title: context.tr('section_appearance'),
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              // Theme Mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('theme_mode'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(context.tr('theme_system')),
                          icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(context.tr('theme_light')),
                          icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(context.tr('theme_dark')),
                          icon: const Icon(Icons.nightlight_outlined, size: 18),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (newSet) {
                        settings.setThemeMode(newSet.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedBackgroundColor: theme.colorScheme.primaryContainer,
                        selectedForegroundColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              // View Mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('view_mode'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ViewMode>(
                      segments: [
                        ButtonSegment(
                          value: ViewMode.list,
                          label: Text(context.tr('view_list')),
                          icon: const Icon(Icons.view_list_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ViewMode.mosaic,
                          label: Text(context.tr('view_mosaic')),
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                        ),
                      ],
                      selected: {viewMode.mode},
                      onSelectionChanged: (newSet) {
                        viewMode.setMode(newSet.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedBackgroundColor: theme.colorScheme.primaryContainer,
                        selectedForegroundColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              SwitchListTile.adaptive(
                value: settings.showApiSourceInPlayer,
                onChanged: (val) => settings.setShowApiSourceInPlayer(val),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  context.tr('show_api_source_in_player'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.tr('show_api_source_in_player_desc'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                      height: 1.3,
                    ),
                  ),
                ),
                activeTrackColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ================= LANGUAGE =================
          _SectionHeader(
            title: context.tr('section_language'),
            icon: Icons.language_rounded,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _LanguageTile(
                title: context.tr('lang_system'),
                subtitle: 'Auto',
                isSelected: settings.locale == null,
                onTap: () => settings.setLocale(null),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _LanguageTile(
                title: 'English',
                subtitle: 'English (EN)',
                isSelected: settings.locale?.languageCode == 'en',
                onTap: () => settings.setLocale(const Locale('en')),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _LanguageTile(
                title: 'Español',
                subtitle: 'Spanish (ES)',
                isSelected: settings.locale?.languageCode == 'es',
                onTap: () => settings.setLocale(const Locale('es')),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _LanguageTile(
                title: 'Français',
                subtitle: 'French (FR)',
                isSelected: settings.locale?.languageCode == 'fr',
                onTap: () => settings.setLocale(const Locale('fr')),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _LanguageTile(
                title: 'العربية',
                subtitle: 'Arabic (AR)',
                isArabic: true,
                isSelected: settings.locale?.languageCode == 'ar',
                onTap: () => settings.setLocale(const Locale('ar')),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ================= AUDIO SOURCES & APIS =================
          _SectionHeader(
            title: context.tr('section_audio_sources'),
            icon: Icons.cloud_sync_rounded,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  context.tr('audio_sources_desc'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    height: 1.35,
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _AudioSourceTile(
                title: 'MP3Quran.net',
                description: context.tr('api_mp3quran_desc'),
                isEnabled: settings.isApiSourceEnabled(AudioApiSource.mp3Quran),
                onChanged: (val) async {
                  final ok = await settings.toggleApiSource(AudioApiSource.mp3Quran);
                  if (!ok && context.mounted) {
                    showAppSnackBar(context, context.tr('cannot_disable_all_sources'));
                  }
                },
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _AudioSourceTile(
                title: 'QuranicAudio.com',
                description: context.tr('api_quranicaudio_desc'),
                isEnabled: settings.isApiSourceEnabled(AudioApiSource.quranicAudio),
                onChanged: (val) async {
                  final ok = await settings.toggleApiSource(AudioApiSource.quranicAudio);
                  if (!ok && context.mounted) {
                    showAppSnackBar(context, context.tr('cannot_disable_all_sources'));
                  }
                },
              ),
              Divider(height: 1, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
              _AudioSourceTile(
                title: 'AlQuran Cloud',
                description: context.tr('api_alqurancloud_desc'),
                isEnabled: settings.isApiSourceEnabled(AudioApiSource.alQuranCloud),
                onChanged: (val) async {
                  final ok = await settings.toggleApiSource(AudioApiSource.alQuranCloud);
                  if (!ok && context.mounted) {
                    showAppSnackBar(context, context.tr('cannot_disable_all_sources'));
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ================= TUTORIAL & HELP =================
          _SectionHeader(
            title: context.tr('section_tutorial'),
            icon: Icons.help_outline_rounded,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A3D36) : const Color(0xFFE2EFEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restart_alt_rounded,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.tr('reset_tutorial_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.tr('reset_tutorial_desc'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await viewMode.resetTutorial();
                    if (context.mounted) {
                      showAppSnackBar(
                        context,
                        context.tr('reset_tutorial_success'),
                      );
                    }
                  },
                  child: Text(context.tr('reset')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ================= ABOUT =================
          _SectionHeader(
            title: context.tr('section_about'),
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Al-Quran Player',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${context.tr('version')} 1.0.0',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('app_description'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isArabic;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.isArabic = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: isArabic
            ? GoogleFonts.amiri(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              )
            : theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 22,
            )
          : null,
    );
  }
}

class _AudioSourceTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _AudioSourceTile({
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SwitchListTile.adaptive(
      value: isEnabled,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            height: 1.3,
          ),
        ),
      ),
      activeTrackColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
    );
  }
}

