import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/edit_profile_screen.dart';
import '../../features/children/models/child.dart';
import '../../features/children/screens/child_detail_screen.dart';
import '../../features/children/screens/children_list_screen.dart';
import '../../features/children/screens/edit_child_screen.dart';
import 'home_placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isAuthenticated = authAsync.valueOrNull != null;
      final loc = state.matchedLocation;
      const authOnlyRoutes = ['/login', '/register', '/forgot-password', '/splash'];

      if (!isAuthenticated && !authOnlyRoutes.contains(loc)) return '/login';
      if (isAuthenticated && authOnlyRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomePlaceholderScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(path: '/children', builder: (_, __) => const ChildrenListScreen()),
      GoRoute(
        path: '/children/:id',
        builder: (_, state) =>
            ChildDetailScreen(childId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/children/:id/edit',
        builder: (_, state) =>
            EditChildScreen(child: state.extra! as Child),
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
