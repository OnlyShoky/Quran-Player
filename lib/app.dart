import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/playlist_provider.dart';
import 'shared/providers/player_provider.dart';
import 'features/surah_list/surah_list_screen.dart';
import 'features/playlist/playlist_screen.dart';
import 'features/player/player_screen.dart';
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
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProxyProvider<PlaylistProvider, PlayerProvider>(
          create: (_) => PlayerProvider(),
          update: (_, playlist, player) {
            player!.updatePlaylistProvider(playlist);
            return player;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Quran Player',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Surahs',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music_rounded),
                label: 'Playlist',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
