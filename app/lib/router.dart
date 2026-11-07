import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/around/around_screen.dart';
import 'features/chats/chat_screen.dart';
import 'features/chats/chats_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/splash/splash_screen.dart';
import 'features/you/you_screen.dart';

/// The app's routes. Navigation is declarative so the Android back button and
/// the desktop rail behave the same way.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    ShellRoute(
      builder: (_, GoRouterState state, Widget child) =>
          HomeShell(location: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(path: '/around', builder: (_, _) => const AroundScreen()),
        GoRoute(path: '/chats', builder: (_, _) => const ChatsScreen()),
        GoRoute(path: '/you', builder: (_, _) => const YouScreen()),
      ],
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (_, GoRouterState state) =>
          ChatScreen(peerId: state.pathParameters['id'] ?? 'axmed'),
    ),
  ],
);
