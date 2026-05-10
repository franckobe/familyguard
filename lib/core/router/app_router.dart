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
import '../../features/connections/screens/connections_list_screen.dart';
import '../../features/connections/screens/invite_screen.dart';
import '../../features/connections/screens/connection_detail_screen.dart';
import '../../features/connections/screens/invitation_received_screen.dart';
import '../../features/guard_requests/models/guard_request.dart';
import '../../features/guard_requests/screens/guard_requests_list_screen.dart';
import '../../features/guard_requests/screens/create_guard_request_screen.dart';
import '../../features/guard_requests/screens/guard_request_detail_screen.dart';
import '../../features/guard_requests/screens/incoming_request_detail_screen.dart';
import 'app_shell.dart';

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

      const publicPaths = ['/login', '/register', '/forgot-password', '/splash'];
      final isInvitePath = loc.startsWith('/invite/');

      if (!isAuthenticated && !publicPaths.contains(loc) && !isInvitePath) return '/login';
      if (isAuthenticated && (publicPaths.contains(loc))) return '/children';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(
        path: '/invite/:code',
        builder: (_, state) => InvitationReceivedScreen(
          inviteCode: state.pathParameters['code']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/children',
              builder: (_, __) => const ChildrenListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) => ChildDetailScreen(childId: s.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, s) => EditChildScreen(child: s.extra! as Child),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/connections',
              builder: (_, __) => const ConnectionsListScreen(),
              routes: [
                GoRoute(path: 'invite', builder: (_, __) => const InviteScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, s) => ConnectionDetailScreen(connectionId: s.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/guard-requests',
              builder: (_, __) => const GuardRequestsListScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (_, __) => const CreateGuardRequestScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, s) => GuardRequestDetailScreen(
                    requestId: s.pathParameters['id']!,
                    request: s.extra as GuardRequest?,
                  ),
                ),
                GoRoute(
                  path: ':id/incoming',
                  builder: (_, s) => IncomingRequestDetailScreen(
                    requestId: s.pathParameters['id']!,
                    request: s.extra as GuardRequest?,
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
