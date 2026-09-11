import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'shared/providers/playlist_provider.dart';
import 'shared/providers/player_provider.dart';
import 'shared/providers/view_mode_provider.dart';
import 'shared/providers/settings_provider.dart';
import 'features/surah_list/surah_list_screen.dart';
import 'features/playlist/playlist_screen.dart';
import 'features/player/player_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/mini_player.dart';

class QuranPlayerApp extends StatelessWidget {
  QuranPlayerApp({super.key});

  final _router = GoRouter(
    initialLocation: '/surahs',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/surahs',
            builder: (ctx, state) => const SurahListScreen(),
          ),
          GoRoute(
            path: '/playlist',
            builder: (ctx, state) => const PlaylistScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        builder: (ctx, state) => const PlayerScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (ctx, state) => const SettingsScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ViewModeProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, PlaylistProvider>(
          create: (_) => PlaylistProvider(),
          update: (_, settings, playlist) {
            playlist!.updateSettingsProvider(settings);
            return playlist;
          },
        ),
        ChangeNotifierProxyProvider2<PlaylistProvider, SettingsProvider, PlayerProvider>(
          create: (_) => PlayerProvider(),
          update: (_, playlist, settings, player) {
            player!.updatePlaylistProvider(playlist);
            player.updateSettingsProvider(settings);
            return player;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();

          return MaterialApp.router(
            title: 'Quran Player',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const _AppShell({required this.child, required this.location});

  int _tabIndex(String loc) {
    if (loc.startsWith('/playlist')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/surahs');
                case 1:
                  context.go('/playlist');
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: context.tr('nav_surahs'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon: const Icon(Icons.queue_music_rounded),
                label: context.tr('nav_playlist'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
