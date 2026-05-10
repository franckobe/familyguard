# Sprint 3 — Connexions : Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implémenter le système de connexions de confiance (parent ↔ caregiver) avec invitation par email, bottom nav bar persistant, et les Cloud Functions associées.

**Architecture:** `StatefulShellRoute` (go_router) fournit le bottom nav à 3 branches (Enfants / Connexions / Gardes). La feature Connexions suit le même pattern que Children : model Freezed → repository → Riverpod providers → screens. Les Cloud Functions `onConnectionCreated`, `getInviteDetails`, `acceptInvite` gèrent l'invitation server-side. La route `/invite/:code` est publique (accessible sans auth).

**Tech Stack:** Flutter/Dart, Freezed, Riverpod, go_router StatefulShellRoute, Cloud Firestore, Cloud Functions (Node 20 + TypeScript), Jest, fake_cloud_firestore, mocktail.

---

## File Map

### Créer
- `lib/core/router/app_shell.dart` — widget shell avec bottom nav (StatefulNavigationShell)
- `lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart` — écran vide Sprint 4
- `lib/features/connections/models/connection.dart` — model Freezed + fromFirestore/toFirestore
- `lib/features/connections/models/connection.freezed.dart` — généré par build_runner
- `lib/features/connections/repository/connection_repository.dart` — CRUD Firestore + callables
- `lib/features/connections/providers/connection_providers.dart` — Riverpod providers
- `lib/features/connections/widgets/connection_card.dart` — card réutilisable dans les listes
- `lib/features/connections/screens/connections_list_screen.dart` — 2 onglets (babysitters / familles)
- `lib/features/connections/screens/invite_screen.dart` — formulaire email + message
- `lib/features/connections/screens/connection_detail_screen.dart` — détail + actions
- `lib/features/connections/screens/invitation_received_screen.dart` — route publique /invite/:code
- `test/features/connections/repository/connection_repository_test.dart` — tests unitaires repository
- `functions/src/connections/on_connection_created.ts` — trigger Firestore onCreate
- `functions/src/connections/accept_invite.ts` — callables getInviteDetails + acceptInvite
- `functions/src/connections/on_connection_updated.ts` — stub onConnectionUpdated
- `functions/src/connections/__tests__/on_connection_created.test.ts`
- `functions/src/connections/__tests__/accept_invite.test.ts`

### Modifier
- `lib/core/widgets/glass_tab_bar.dart` — tabs : Enfants / Connexions / Gardes
- `lib/core/router/app_router.dart` — StatefulShellRoute + /invite/:code public
- `firestore.rules` — ajouter règles /connections
- `firestore.indexes.json` — ajouter index connections
- `functions/src/index.ts` — exporter les nouvelles functions

### Supprimer
- `lib/core/router/home_placeholder_screen.dart` — remplacé par AppShell + branches

---

## Task 1 — Bottom nav : GlassTabBar + AppShell + router refactor

**Files:**
- Modify: `lib/core/widgets/glass_tab_bar.dart`
- Create: `lib/core/router/app_shell.dart`
- Modify: `lib/core/router/app_router.dart`
- Create: `lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart`

- [ ] **Step 1: Mettre à jour GlassTabBar avec les 3 onglets Sprint 3**

Remplacer entièrement le contenu de `lib/core/widgets/glass_tab_bar.dart` :

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    (icon: LucideIcons.baby,     label: 'Enfants'),
    (icon: LucideIcons.users,    label: 'Connexions'),
    (icon: LucideIcons.calendar, label: 'Gardes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primarySurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: isActive
                          ? Border.all(color: AppColors.glassPurpleBorder, width: 0.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 20,
                          color: isActive ? const Color(0xFFC4B5FD) : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: AppTextStyles.tabLabel.copyWith(
                            color: isActive ? const Color(0xFFC4B5FD) : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Créer le widget AppShell**

Créer `lib/core/router/app_shell.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_tab_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: GlassTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Créer le placeholder guard_requests**

Créer `lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';

class GuardRequestsPlaceholderScreen extends StatelessWidget {
  const GuardRequestsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Gardes')),
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorder, width: 0.5),
                ),
                child: const Icon(LucideIcons.calendar, size: 32, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text('Bientôt disponible', style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text('Sprint 4', style: AppTextStyles.cardSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Refactoriser app_router.dart avec StatefulShellRoute**

Remplacer entièrement `lib/core/router/app_router.dart` :

```dart
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
import '../../features/guard_requests/screens/guard_requests_placeholder_screen.dart';
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
        // Placeholder — remplacé à Task 9 quand InvitationReceivedScreen existe
        builder: (_, state) => Scaffold(
          body: Center(child: Text('Code : ${state.pathParameters['code']}')),
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
              builder: (_, __) => const GuardRequestsPlaceholderScreen(),
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
```

- [ ] **Step 5: Supprimer home_placeholder_screen.dart**

```bash
rm lib/core/router/home_placeholder_screen.dart
```

- [ ] **Step 6: Vérifier la compilation**

```bash
flutter analyze
```

Attendu : pas d'erreurs (juste des avertissements possibles sur les imports manquants des screens qui n'existent pas encore).

> Note : `ConnectionsListScreen`, `InviteScreen`, `ConnectionDetailScreen` n'existent pas encore — créer des stubs vides temporaires si nécessaire pour que `flutter analyze` passe, ou ignorer cette étape jusqu'à la Task 6.

- [ ] **Step 7: Commit**

```bash
git add lib/core/widgets/glass_tab_bar.dart \
        lib/core/router/app_shell.dart \
        lib/core/router/app_router.dart \
        lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart
git rm lib/core/router/home_placeholder_screen.dart
git commit -m "feat(nav): replace home placeholder with StatefulShellRoute bottom nav"
```

---

## Task 2 — Connection model

**Files:**
- Create: `lib/features/connections/models/connection.dart`
- Generate: `lib/features/connections/models/connection.freezed.dart`

- [ ] **Step 1: Créer connection.dart**

Créer `lib/features/connections/models/connection.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';

enum ConnectionStatus { pending, active, declined, blocked }

@freezed
class Connection with _$Connection {
  const Connection._();

  const factory Connection({
    required String id,
    required String parentId,
    String? caregiverId,
    required ConnectionStatus status,
    String? inviteCode,
    required String inviteEmail,
    String? message,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Connection;

  factory Connection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Connection(
      id: doc.id,
      parentId: data['parentId'] as String,
      caregiverId: data['caregiverId'] as String?,
      status: ConnectionStatus.values.byName(data['status'] as String),
      inviteCode: data['inviteCode'] as String?,
      inviteEmail: data['inviteEmail'] as String,
      message: data['message'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'parentId': parentId,
    'caregiverId': caregiverId,
    'status': status.name,
    'inviteCode': inviteCode,
    'inviteEmail': inviteEmail,
    'message': message,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
```

- [ ] **Step 2: Générer le fichier Freezed**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Attendu : `lib/features/connections/models/connection.freezed.dart` créé.

- [ ] **Step 3: Commit**

```bash
git add lib/features/connections/models/
git commit -m "feat(connections): add Connection model with Freezed"
```

---

## Task 3 — ConnectionRepository + tests

**Files:**
- Create: `lib/features/connections/repository/connection_repository.dart`
- Create: `test/features/connections/repository/connection_repository_test.dart`

- [ ] **Step 1: Écrire les tests**

Créer `test/features/connections/repository/connection_repository_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyguard/features/connections/models/connection.dart';
import 'package:familyguard/features/connections/repository/connection_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ConnectionRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ConnectionRepository(firestore: fakeFirestore);
  });

  group('streamAsParent', () {
    test('returns connections where parentId matches', () async {
      await fakeFirestore.collection('connections').add({
        'parentId': 'parent-1',
        'caregiverId': null,
        'status': 'pending',
        'inviteCode': null,
        'inviteEmail': 'caregiver@example.com',
        'message': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });
      await fakeFirestore.collection('connections').add({
        'parentId': 'parent-2',
        'caregiverId': null,
        'status': 'pending',
        'inviteCode': null,
        'inviteEmail': 'other@example.com',
        'message': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });

      final result = await repo.streamAsParent('parent-1').first;

      expect(result.length, 1);
      expect(result.first.parentId, 'parent-1');
      expect(result.first.inviteEmail, 'caregiver@example.com');
      expect(result.first.status, ConnectionStatus.pending);
    });
  });

  group('streamAsCaregiver', () {
    test('returns connections where caregiverId matches', () async {
      await fakeFirestore.collection('connections').add({
        'parentId': 'parent-1',
        'caregiverId': 'caregiver-1',
        'status': 'active',
        'inviteCode': 'abc-123',
        'inviteEmail': 'caregiver@example.com',
        'message': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });

      final result = await repo.streamAsCaregiver('caregiver-1').first;

      expect(result.length, 1);
      expect(result.first.caregiverId, 'caregiver-1');
      expect(result.first.status, ConnectionStatus.active);
    });
  });

  group('createInvite', () {
    test('writes pending connection to Firestore', () async {
      await repo.createInvite(
        parentId: 'parent-1',
        email: 'test@example.com',
        message: 'Bonjour !',
      );

      final snap = await fakeFirestore.collection('connections').get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['parentId'], 'parent-1');
      expect(data['inviteEmail'], 'test@example.com');
      expect(data['message'], 'Bonjour !');
      expect(data['status'], 'pending');
      expect(data['caregiverId'], isNull);
      expect(data['inviteCode'], isNull);
    });

    test('message null when omitted', () async {
      await repo.createInvite(parentId: 'parent-1', email: 'x@x.com');

      final snap = await fakeFirestore.collection('connections').get();
      expect(snap.docs.first.data()['message'], isNull);
    });
  });

  group('updateStatus', () {
    test('updates status field on the document', () async {
      final ref = await fakeFirestore.collection('connections').add({
        'parentId': 'parent-1',
        'caregiverId': 'caregiver-1',
        'status': 'active',
        'inviteCode': 'abc',
        'inviteEmail': 'x@x.com',
        'message': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });

      await repo.updateStatus(ref.id, ConnectionStatus.blocked);

      final doc = await fakeFirestore.collection('connections').doc(ref.id).get();
      expect(doc.data()!['status'], 'blocked');
    });
  });
}
```

- [ ] **Step 2: Exécuter les tests — vérifier qu'ils échouent**

```bash
flutter test test/features/connections/repository/connection_repository_test.dart
```

Attendu : FAIL (ConnectionRepository n'existe pas encore).

- [ ] **Step 3: Implémenter ConnectionRepository**

Créer `lib/features/connections/repository/connection_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/connection.dart';

class ConnectionRepository {
  const ConnectionRepository({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  FirebaseFunctions get _ff => _functions ?? FirebaseFunctions.instance;

  Stream<List<Connection>> streamAsParent(String parentId) {
    return _firestore
        .collection('connections')
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Connection.fromFirestore).toList());
  }

  Stream<List<Connection>> streamAsCaregiver(String caregiverId) {
    return _firestore
        .collection('connections')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Connection.fromFirestore).toList());
  }

  Future<void> createInvite({
    required String parentId,
    required String email,
    String? message,
  }) async {
    final now = DateTime.now();
    await _firestore.collection('connections').add({
      'parentId': parentId,
      'caregiverId': null,
      'status': 'pending',
      'inviteCode': null,
      'inviteEmail': email,
      'message': message,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateStatus(String connectionId, ConnectionStatus status) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<Map<String, dynamic>> getInviteDetails(String inviteCode) async {
    final result = await _ff
        .httpsCallable('getInviteDetails')
        .call({'inviteCode': inviteCode});
    return result.data as Map<String, dynamic>;
  }

  Future<String> acceptInvite(String inviteCode) async {
    final result = await _ff
        .httpsCallable('acceptInvite')
        .call({'inviteCode': inviteCode});
    return (result.data as Map<String, dynamic>)['connectionId'] as String;
  }
}
```

- [ ] **Step 4: Exécuter les tests — vérifier qu'ils passent**

```bash
flutter test test/features/connections/repository/connection_repository_test.dart
```

Attendu : PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/connections/repository/ test/features/connections/
git commit -m "feat(connections): add ConnectionRepository with tests"
```

---

## Task 4 — Connection providers

**Files:**
- Create: `lib/features/connections/providers/connection_providers.dart`

- [ ] **Step 1: Créer connection_providers.dart**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/connection.dart';
import '../repository/connection_repository.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => ConnectionRepository(firestore: FirebaseFirestore.instance),
);

final connectionsAsParentProvider = StreamProvider<List<Connection>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(connectionRepositoryProvider).streamAsParent(user.uid);
});

final connectionsAsCaregiverProvider = StreamProvider<List<Connection>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(connectionRepositoryProvider).streamAsCaregiver(user.uid);
});

final inviteDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, inviteCode) =>
      ref.read(connectionRepositoryProvider).getInviteDetails(inviteCode),
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/connections/providers/
git commit -m "feat(connections): add Riverpod providers"
```

---

## Task 5 — ConnectionCard widget

**Files:**
- Create: `lib/features/connections/widgets/connection_card.dart`

- [ ] **Step 1: Créer connection_card.dart**

Le widget affiche : avatar (initiales ou photo), nom (ou email si pas encore inscrit), badge de statut, et navigue vers le détail au tap.

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/connection.dart';

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key, required this.connection});

  final Connection connection;

  BadgeStatus get _badge => switch (connection.status) {
    ConnectionStatus.pending  => BadgeStatus.waiting,
    ConnectionStatus.active   => BadgeStatus.accepted,
    ConnectionStatus.declined => BadgeStatus.declined,
    ConnectionStatus.blocked  => BadgeStatus.declined,
  };

  @override
  Widget build(BuildContext context) {
    final label = connection.inviteEmail;

    return GestureDetector(
      onTap: () => context.push('/connections/${connection.id}', extra: connection),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            AvatarInitials(
              initials: label.isNotEmpty ? label[0].toUpperCase() : '?',
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
            ),
            StatusBadge(status: _badge),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/connections/widgets/
git commit -m "feat(connections): add ConnectionCard widget"
```

---

## Task 6 — ConnectionsListScreen

**Files:**
- Create: `lib/features/connections/screens/connections_list_screen.dart`

- [ ] **Step 1: Créer connections_list_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/section_label.dart';
import '../providers/connection_providers.dart';
import '../widgets/connection_card.dart';

class ConnectionsListScreen extends ConsumerStatefulWidget {
  const ConnectionsListScreen({super.key});

  @override
  ConsumerState<ConnectionsListScreen> createState() => _ConnectionsListScreenState();
}

class _ConnectionsListScreenState extends ConsumerState<ConnectionsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asParentAsync = ref.watch(connectionsAsParentProvider);
    final asCaregiverAsync = ref.watch(connectionsAsCaregiverProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Connexions'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFC4B5FD),
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.cardTitle,
          tabs: const [
            Tab(text: 'Mes babysitters'),
            Tab(text: 'Mes familles'),
          ],
        ),
      ),
      body: AppBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Onglet Mes babysitters (user = parent)
            asParentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle)),
              data: (connections) {
                if (connections.isEmpty) {
                  return _EmptyState(
                    icon: LucideIcons.userPlus,
                    message: 'Aucun babysitter',
                    subtitle: 'Invitez un proche pour commencer',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
                  itemCount: connections.length,
                  itemBuilder: (_, i) => ConnectionCard(connection: connections[i]),
                );
              },
            ),
            // Onglet Mes familles (user = caregiver)
            asCaregiverAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle)),
              data: (connections) {
                if (connections.isEmpty) {
                  return _EmptyState(
                    icon: LucideIcons.users,
                    message: 'Pas encore de famille',
                    subtitle: 'Acceptez une invitation pour apparaître ici',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
                  itemCount: connections.length,
                  itemBuilder: (_, i) => ConnectionCard(connection: connections[i]),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/connections/invite'),
        child: const Icon(LucideIcons.userPlus),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  final IconData icon;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Icon(icon, size: 32, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/connections/screens/connections_list_screen.dart
git commit -m "feat(connections): add ConnectionsListScreen with 2-tab layout"
```

---

## Task 7 — InviteScreen

**Files:**
- Create: `lib/features/connections/screens/invite_screen.dart`

- [ ] **Step 1: Créer invite_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/connection_providers.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(connectionRepositoryProvider).createInvite(
        parentId: uid,
        email: _emailCtrl.text.trim(),
        message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Inviter un proche')),
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Email *'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Message (optionnel)',
                      hintText: 'Bonjour, j\'aimerais t\'ajouter à mon réseau…',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Envoyer l\'invitation'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/connections/screens/invite_screen.dart
git commit -m "feat(connections): add InviteScreen"
```

---

## Task 8 — ConnectionDetailScreen

**Files:**
- Create: `lib/features/connections/screens/connection_detail_screen.dart`

- [ ] **Step 1: Créer connection_detail_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/connection.dart';
import '../providers/connection_providers.dart';
import '../widgets/connection_card.dart';

class ConnectionDetailScreen extends ConsumerWidget {
  const ConnectionDetailScreen({super.key, required this.connectionId});

  final String connectionId;

  // Retrouve la connexion depuis les providers déjà chargés
  Connection? _findConnection(WidgetRef ref, String id) {
    final asParent = ref.watch(connectionsAsParentProvider).valueOrNull ?? [];
    final asCaregiver = ref.watch(connectionsAsCaregiverProvider).valueOrNull ?? [];
    final all = [...asParent, ...asCaregiver];
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmAction(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    bool isParent,
  ) async {
    final title = isParent ? 'Bloquer cette connexion ?' : 'Quitter cette connexion ?';
    final body = isParent
        ? 'Le babysitter ne pourra plus recevoir vos demandes de garde.'
        : 'Vous ne recevrez plus de demandes de cette famille.';
    final newStatus = isParent ? ConnectionStatus.blocked : ConnectionStatus.declined;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
            child: Text(isParent ? 'Bloquer' : 'Quitter'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(connectionRepositoryProvider).updateStatus(connection.id, newStatus);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = _findConnection(ref, connectionId);
    if (connection == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isParent = connection.parentId == uid;
    final label = connection.inviteEmail;
    final initials = label.isNotEmpty ? label[0].toUpperCase() : '?';

    final badgeStatus = switch (connection.status) {
      ConnectionStatus.pending  => BadgeStatus.waiting,
      ConnectionStatus.active   => BadgeStatus.accepted,
      ConnectionStatus.declined => BadgeStatus.declined,
      ConnectionStatus.blocked  => BadgeStatus.declined,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Connexion')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                AvatarInitials(initials: initials, size: 96),
                const SizedBox(height: 12),
                Text(label, style: AppTextStyles.screenTitle, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                StatusBadge(status: badgeStatus),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Détails'),
                      const SizedBox(height: 8),
                      _Row('Rôle', isParent ? 'Votre babysitter' : 'Votre famille'),
                      if (connection.message != null) ...[
                        const SizedBox(height: 8),
                        _Row('Message', connection.message!),
                      ],
                    ],
                  ),
                ),
                if (connection.status == ConnectionStatus.active ||
                    connection.status == ConnectionStatus.pending) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAction(context, ref, connection, isParent),
                      icon: Icon(
                        isParent ? LucideIcons.ban : LucideIcons.logOut,
                        size: 18,
                        color: const Color(0xFFF87171),
                      ),
                      label: Text(
                        isParent ? 'Bloquer' : 'Quitter',
                        style: const TextStyle(color: Color(0xFFF87171)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.cardTitle),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/connections/screens/connection_detail_screen.dart
git commit -m "feat(connections): add ConnectionDetailScreen"
```

---

## Task 9 — InvitationReceivedScreen + route publique

**Files:**
- Create: `lib/features/connections/screens/invitation_received_screen.dart`
- Modify: `lib/core/router/app_router.dart` (remplacer le placeholder /invite/:code)

- [ ] **Step 1: Créer invitation_received_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/connection_providers.dart';
import '../repository/connection_repository.dart';

class InvitationReceivedScreen extends ConsumerStatefulWidget {
  const InvitationReceivedScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  ConsumerState<InvitationReceivedScreen> createState() => _InvitationReceivedScreenState();
}

class _InvitationReceivedScreenState extends ConsumerState<InvitationReceivedScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref.read(connectionRepositoryProvider).acceptInvite(widget.inviteCode);
      if (mounted) context.go('/connections');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(authStateProvider).valueOrNull != null;
    final detailsAsync = ref.watch(inviteDetailsProvider(widget.inviteCode));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Invitation')),
      body: AppBackground(
        child: SafeArea(
          child: detailsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Invitation invalide ou expirée',
                      style: AppTextStyles.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ce lien a peut-être déjà été utilisé.',
                      style: AppTextStyles.cardSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (details) {
              final parentFirstName = details['parentFirstName'] as String? ?? '';
              final inviteEmail = details['inviteEmail'] as String? ?? '';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    AvatarInitials(
                      initials: parentFirstName.isNotEmpty ? parentFirstName[0] : '?',
                      size: 96,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$parentFirstName vous invite\nsur FamilyGuard',
                      style: AppTextStyles.screenTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DESTINATAIRE', style: AppTextStyles.sectionLabel),
                          const SizedBox(height: 4),
                          Text(inviteEmail, style: AppTextStyles.cardTitle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isAuthenticated) ...[
                      Text(
                        'Connectez-vous pour accepter l\'invitation',
                        style: AppTextStyles.cardSubtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Se connecter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Créer un compte'),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _accepting ? null : _accept,
                          child: _accepting
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Accepter l\'invitation'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Mettre à jour app_router.dart — remplacer le placeholder /invite/:code**

Remplacer dans `lib/core/router/app_router.dart` :

```dart
// Avant (placeholder de Task 1) :
GoRoute(
  path: '/invite/:code',
  builder: (_, state) => Scaffold(
    body: Center(child: Text('Code : ${state.pathParameters['code']}')),
  ),
),

// Après :
GoRoute(
  path: '/invite/:code',
  builder: (_, state) => InvitationReceivedScreen(
    inviteCode: state.pathParameters['code']!,
  ),
),
```

Ajouter l'import en haut du fichier :
```dart
import '../../features/connections/screens/invitation_received_screen.dart';
```

- [ ] **Step 3: Vérifier que l'app compile et les routes fonctionnent**

```bash
flutter analyze
```

Attendu : pas d'erreurs.

- [ ] **Step 4: Commit**

```bash
git add lib/features/connections/screens/invitation_received_screen.dart \
        lib/core/router/app_router.dart
git commit -m "feat(connections): add InvitationReceivedScreen and public /invite/:code route"
```

---

## Task 10 — Cloud Function : onConnectionCreated + tests

**Files:**
- Create: `functions/src/connections/on_connection_created.ts`
- Create: `functions/src/connections/__tests__/on_connection_created.test.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Écrire le test**

Créer `functions/src/connections/__tests__/on_connection_created.test.ts` :

```typescript
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockDoc = jest.fn().mockReturnValue({ update: mockUpdate, get: mockGet });
const mockAdd = jest.fn().mockResolvedValue(undefined);
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockCollection = jest.fn().mockReturnValue({
  doc: mockDoc,
  add: mockAdd,
  where: mockWhere,
});
mockWhere.mockReturnValue({ limit: mockLimit });
mockLimit.mockReturnValue({ get: jest.fn() });

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn().mockReturnValue({ collection: mockCollection }),
}));

jest.mock('firebase-admin/firestore', () => ({
  FieldValue: { serverTimestamp: jest.fn().mockReturnValue('SERVER_TIMESTAMP') },
  Timestamp: { now: jest.fn().mockReturnValue('TIMESTAMP_NOW') },
}));

const testEnv = require('firebase-functions-test')();

import { onConnectionCreated } from '../on_connection_created';

describe('onConnectionCreated', () => {
  beforeEach(() => {
    mockUpdate.mockClear();
    mockGet.mockClear();
    mockDoc.mockClear();
    mockCollection.mockClear();
    mockAdd.mockClear();
    // parent user doc
    mockGet.mockResolvedValue({ data: () => ({ firstName: 'Franck' }) });
  });

  afterAll(() => testEnv.cleanup());

  it('generates inviteCode and updates the connection document', async () => {
    const snap = testEnv.firestore.makeDocumentSnapshot(
      {
        parentId: 'uid-parent',
        inviteEmail: 'caregiver@example.com',
        inviteCode: null,
        message: null,
      },
      'connections/conn-1',
    );

    await testEnv.wrap(onConnectionCreated)(snap);

    expect(mockCollection).toHaveBeenCalledWith('connections');
    expect(mockDoc).toHaveBeenCalledWith('conn-1');
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        inviteCode: expect.stringMatching(
          /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
        ),
      }),
    );
  });

  it('is idempotent — skips if inviteCode already set', async () => {
    const snap = testEnv.firestore.makeDocumentSnapshot(
      {
        parentId: 'uid-parent',
        inviteEmail: 'x@x.com',
        inviteCode: 'already-set',
        message: null,
      },
      'connections/conn-2',
    );

    await testEnv.wrap(onConnectionCreated)(snap);

    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('writes to /mail collection with correct email', async () => {
    const snap = testEnv.firestore.makeDocumentSnapshot(
      {
        parentId: 'uid-parent',
        inviteEmail: 'caregiver@example.com',
        inviteCode: null,
        message: null,
      },
      'connections/conn-3',
    );

    await testEnv.wrap(onConnectionCreated)(snap);

    expect(mockCollection).toHaveBeenCalledWith('mail');
    expect(mockAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'caregiver@example.com',
        message: expect.objectContaining({
          subject: expect.stringContaining('Franck'),
          html: expect.stringContaining('/invite/'),
        }),
      }),
    );
  });
});
```

- [ ] **Step 2: Exécuter les tests — vérifier l'échec**

```bash
cd functions && npm test -- --testPathPattern="on_connection_created"
```

Attendu : FAIL.

- [ ] **Step 3: Implémenter onConnectionCreated**

Créer `functions/src/connections/on_connection_created.ts` :

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { randomUUID } from 'crypto';

const APP_URL = process.env.APP_URL ?? 'https://familyguard.app';

export const onConnectionCreated = functions.firestore
  .document('connections/{connectionId}')
  .onCreate(async (snap) => {
    const data = snap.data();

    if (data.inviteCode) return; // idempotent

    const inviteCode = randomUUID();
    const db = admin.firestore();

    // Update connection with inviteCode
    await db.collection('connections').doc(snap.id).update({
      inviteCode,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Fetch parent first name for email
    const parentDoc = await db.collection('users').doc(data.parentId).get();
    const parentFirstName = (parentDoc.data()?.firstName as string | undefined) ?? '';

    // Write to /mail for Trigger Email extension
    await db.collection('mail').add({
      to: data.inviteEmail,
      message: {
        subject: `${parentFirstName} vous invite sur FamilyGuard`,
        html: `
          <p>Bonjour,</p>
          <p><strong>${parentFirstName}</strong> vous invite à rejoindre son réseau FamilyGuard.</p>
          <p>
            <a href="${APP_URL}/invite/${inviteCode}" style="
              display:inline-block;padding:12px 24px;background:#7C3AED;
              color:#fff;border-radius:8px;text-decoration:none;font-weight:600;
            ">Accepter l'invitation</a>
          </p>
          <p style="color:#666;font-size:12px;">
            Si vous n'attendiez pas cette invitation, ignorez cet email.
          </p>
        `,
      },
    });
  });
```

- [ ] **Step 4: Exécuter les tests — vérifier le succès**

```bash
cd functions && npm test -- --testPathPattern="on_connection_created"
```

Attendu : PASS (3 tests).

- [ ] **Step 5: Exporter depuis index.ts**

Dans `functions/src/index.ts`, ajouter :

```typescript
export { onConnectionCreated } from './connections/on_connection_created';
```

- [ ] **Step 6: Compiler TypeScript**

```bash
cd functions && npm run build
```

Attendu : pas d'erreurs.

- [ ] **Step 7: Commit**

```bash
git add functions/src/connections/on_connection_created.ts \
        functions/src/connections/__tests__/on_connection_created.test.ts \
        functions/src/index.ts \
        functions/lib/
git commit -m "feat(functions): add onConnectionCreated — generate inviteCode + send email"
```

---

## Task 11 — Cloud Functions : getInviteDetails + acceptInvite + tests

**Files:**
- Create: `functions/src/connections/accept_invite.ts`
- Create: `functions/src/connections/__tests__/accept_invite.test.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Écrire les tests**

Créer `functions/src/connections/__tests__/accept_invite.test.ts` :

```typescript
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockDocRef = { update: mockUpdate, get: mockGet };
const mockDoc = jest.fn().mockReturnValue(mockDocRef);
const mockDocs: any[] = [];
const mockQueryGet = jest.fn().mockResolvedValue({ docs: mockDocs, empty: true });
const mockLimit = jest.fn().mockReturnValue({ get: mockQueryGet });
const mockWhere = jest.fn().mockReturnValue({ limit: mockLimit });
const mockCollection = jest.fn().mockReturnValue({ doc: mockDoc, where: mockWhere });

jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn().mockReturnValue({ collection: mockCollection }),
}));

jest.mock('firebase-admin/firestore', () => ({
  FieldValue: { serverTimestamp: jest.fn().mockReturnValue('SERVER_TIMESTAMP') },
}));

const testEnv = require('firebase-functions-test')();

import { getInviteDetails, acceptInvite } from '../accept_invite';

const makeContext = (uid?: string) => ({
  auth: uid ? { uid } : undefined,
});

describe('getInviteDetails', () => {
  beforeEach(() => {
    mockDocs.length = 0;
    mockWhere.mockClear();
    mockQueryGet.mockClear();
  });

  afterAll(() => testEnv.cleanup());

  it('returns parentFirstName, inviteEmail, status for a pending invite', async () => {
    mockDocs.push({
      id: 'conn-1',
      data: () => ({
        parentId: 'uid-parent',
        inviteEmail: 'caregiver@example.com',
        status: 'pending',
        caregiverId: null,
      }),
    });
    mockQueryGet.mockResolvedValueOnce({ docs: mockDocs, empty: false });

    // Mock parent user fetch
    mockGet.mockResolvedValueOnce({ data: () => ({ firstName: 'Franck' }) });

    const wrapped = testEnv.wrap(getInviteDetails);
    const result = await wrapped({ inviteCode: 'abc-123' }, makeContext());

    expect(result).toEqual({
      parentFirstName: 'Franck',
      inviteEmail: 'caregiver@example.com',
      status: 'pending',
    });
  });

  it('throws not-found when inviteCode does not match', async () => {
    mockQueryGet.mockResolvedValueOnce({ docs: [], empty: true });

    const wrapped = testEnv.wrap(getInviteDetails);
    await expect(wrapped({ inviteCode: 'bad-code' }, makeContext())).rejects.toThrow('not-found');
  });

  it('throws already-used when status is not pending', async () => {
    mockDocs.push({
      id: 'conn-2',
      data: () => ({ parentId: 'uid-p', inviteEmail: 'x@x.com', status: 'active', caregiverId: 'uid-c' }),
    });
    mockQueryGet.mockResolvedValueOnce({ docs: mockDocs, empty: false });

    const wrapped = testEnv.wrap(getInviteDetails);
    await expect(wrapped({ inviteCode: 'used' }, makeContext())).rejects.toThrow('already-used');
  });
});

describe('acceptInvite', () => {
  beforeEach(() => {
    mockDocs.length = 0;
    mockUpdate.mockClear();
    mockWhere.mockClear();
    mockQueryGet.mockClear();
  });

  it('throws unauthenticated when called without auth', async () => {
    const wrapped = testEnv.wrap(acceptInvite);
    await expect(wrapped({ inviteCode: 'abc' }, makeContext())).rejects.toThrow('unauthenticated');
  });

  it('updates caregiverId and status to active', async () => {
    mockDocs.push({
      id: 'conn-3',
      data: () => ({
        parentId: 'uid-parent',
        inviteEmail: 'c@c.com',
        status: 'pending',
        caregiverId: null,
      }),
    });
    mockQueryGet.mockResolvedValueOnce({ docs: mockDocs, empty: false });

    const wrapped = testEnv.wrap(acceptInvite);
    const result = await wrapped({ inviteCode: 'abc-xyz' }, makeContext('uid-caregiver'));

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        caregiverId: 'uid-caregiver',
        status: 'active',
      }),
    );
    expect(result).toEqual({ connectionId: 'conn-3' });
  });

  it('throws already-claimed when caregiverId is already set', async () => {
    mockDocs.push({
      id: 'conn-4',
      data: () => ({
        status: 'pending',
        caregiverId: 'someone-else',
        inviteEmail: 'x@x.com',
        parentId: 'uid-p',
      }),
    });
    mockQueryGet.mockResolvedValueOnce({ docs: mockDocs, empty: false });

    const wrapped = testEnv.wrap(acceptInvite);
    await expect(wrapped({ inviteCode: 'abc' }, makeContext('uid-new'))).rejects.toThrow('already-claimed');
  });
});
```

- [ ] **Step 2: Exécuter les tests — vérifier l'échec**

```bash
cd functions && npm test -- --testPathPattern="accept_invite"
```

Attendu : FAIL.

- [ ] **Step 3: Implémenter getInviteDetails + acceptInvite**

Créer `functions/src/connections/accept_invite.ts` :

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const getInviteDetails = functions.https.onCall(async (data) => {
  const { inviteCode } = data as { inviteCode: string };
  const db = admin.firestore();

  const snap = await db
    .collection('connections')
    .where('inviteCode', '==', inviteCode)
    .limit(1)
    .get();

  if (snap.empty) {
    throw new functions.https.HttpsError('not-found', 'Invitation introuvable.');
  }

  const conn = snap.docs[0].data();

  if (conn.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'already-used');
  }

  const parentDoc = await db.collection('users').doc(conn.parentId).get();
  const parentFirstName = (parentDoc.data()?.firstName as string | undefined) ?? '';

  return {
    parentFirstName,
    inviteEmail: conn.inviteEmail as string,
    status: conn.status as string,
  };
});

export const acceptInvite = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentification requise.');
  }

  const { inviteCode } = data as { inviteCode: string };
  const db = admin.firestore();

  const snap = await db
    .collection('connections')
    .where('inviteCode', '==', inviteCode)
    .limit(1)
    .get();

  if (snap.empty) {
    throw new functions.https.HttpsError('not-found', 'Invitation introuvable.');
  }

  const doc = snap.docs[0];
  const conn = doc.data();

  if (conn.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'already-used');
  }

  if (conn.caregiverId != null) {
    throw new functions.https.HttpsError('failed-precondition', 'already-claimed');
  }

  await db.collection('connections').doc(doc.id).update({
    caregiverId: context.auth.uid,
    status: 'active',
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { connectionId: doc.id };
});
```

- [ ] **Step 4: Exécuter les tests — vérifier le succès**

```bash
cd functions && npm test -- --testPathPattern="accept_invite"
```

Attendu : PASS (6 tests).

- [ ] **Step 5: Exporter depuis index.ts**

Dans `functions/src/index.ts`, ajouter :

```typescript
export { getInviteDetails, acceptInvite } from './connections/accept_invite';
```

- [ ] **Step 6: Compiler TypeScript**

```bash
cd functions && npm run build
```

Attendu : pas d'erreurs.

- [ ] **Step 7: Commit**

```bash
git add functions/src/connections/accept_invite.ts \
        functions/src/connections/__tests__/accept_invite.test.ts \
        functions/src/index.ts \
        functions/lib/
git commit -m "feat(functions): add getInviteDetails and acceptInvite callables"
```

---

## Task 12 — Cloud Function : onConnectionUpdated (stub)

**Files:**
- Create: `functions/src/connections/on_connection_updated.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Créer le stub onConnectionUpdated**

Créer `functions/src/connections/on_connection_updated.ts` :

```typescript
import * as functions from 'firebase-functions';

export const onConnectionUpdated = functions.firestore
  .document('connections/{connectionId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === 'pending' && after.status === 'active') {
      // TODO Sprint 5 : envoyer push notification au parent
      functions.logger.info('Connection activated', {
        connectionId: change.after.id,
        parentId: after.parentId,
        caregiverId: after.caregiverId,
      });
    }
  });
```

- [ ] **Step 2: Exporter depuis index.ts**

Dans `functions/src/index.ts`, ajouter :

```typescript
export { onConnectionUpdated } from './connections/on_connection_updated';
```

- [ ] **Step 3: Compiler**

```bash
cd functions && npm run build
```

- [ ] **Step 4: Commit**

```bash
git add functions/src/connections/on_connection_updated.ts \
        functions/src/index.ts \
        functions/lib/
git commit -m "feat(functions): add onConnectionUpdated stub (push notifs Sprint 5)"
```

---

## Task 13 — Firestore rules v3 + indexes

**Files:**
- Modify: `firestore.rules`
- Modify: `firestore.indexes.json`

- [ ] **Step 1: Mettre à jour firestore.rules**

Remplacer le contenu de `firestore.rules` :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuth() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    match /users/{userId} {
      allow read: if isAuth();
      allow write: if isOwner(userId);
    }

    match /children/{childId} {
      allow read, update, delete: if isAuth() && isOwner(resource.data.parentId);
      allow create: if isAuth() && isOwner(request.resource.data.parentId);
    }

    match /connections/{connectionId} {
      allow read: if isAuth() &&
        (request.auth.uid == resource.data.parentId ||
         request.auth.uid == resource.data.caregiverId);

      allow create: if isAuth() &&
        isOwner(request.resource.data.parentId);

      allow update: if isAuth() &&
        (request.auth.uid == resource.data.parentId ||
         request.auth.uid == resource.data.caregiverId);
    }
  }
}
```

- [ ] **Step 2: Mettre à jour firestore.indexes.json**

Remplacer le contenu de `firestore.indexes.json` :

```json
{
  "indexes": [
    {
      "collectionGroup": "children",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "parentId", "order": "ASCENDING" },
        { "fieldPath": "archived", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "connections",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "parentId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "connections",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "caregiverId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

- [ ] **Step 3: Déployer les règles et indexes**

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Attendu : "Deploy complete!"

- [ ] **Step 4: Commit**

```bash
git add firestore.rules firestore.indexes.json
git commit -m "feat(firestore): add rules and indexes for connections (v3)"
```

---

## Tests de bout en bout (vérification manuelle)

Après la Task 13, tester le flux complet dans l'app :

1. **Connexion comme parent** → onglet Connexions → FAB → saisir un email → Envoyer → connexion apparaît dans "Mes babysitters" avec badge "Attente"
2. **Email reçu** → lien `https://familyguard.app/invite/{code}` dans l'email
3. **Ouvrir le lien** (non authentifié) → `InvitationReceivedScreen` affiche le prénom du parent + boutons Se connecter / Créer un compte
4. **Après connexion** → bouton "Accepter l'invitation" → connexion passe à "Actif" → redirection vers `/connections`
5. **Bottom nav** → navigation Enfants / Connexions / Gardes fonctionne avec état préservé par branche
