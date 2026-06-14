import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/parent/parent_home_screen.dart';
import '../../features/child/child_home_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/ai_check/ai_check_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/wallet/wallet_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash',       builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/parent',       builder: (_, __) => const ParentHomeScreen()),
      GoRoute(path: '/child',        builder: (_, __) => const ChildHomeScreen()),
      GoRoute(path: '/focus',        builder: (_, __) => const FocusScreen()),
      GoRoute(path: '/ai-check',     builder: (_, __) => const AiCheckScreen()),
      GoRoute(path: '/wallet',       builder: (_, __) => const WalletScreen()),
      GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('404: ${state.error}')),
    ),
  );
});