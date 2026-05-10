# Sprint 4 — Demandes de garde Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete guard-request flow — parents create requests via a 3-step stepper, caregivers receive and respond, parents confirm a caregiver, with Cloud Functions sending push notifications throughout.

**Architecture:** Flutter screens follow the existing `features/guard_requests/` structure (models → repository → providers → screens → widgets). Cloud Functions are Gen2 for Firestore triggers (eur3 multi-region database) and Gen1 for callables/scheduled. Firestore rules v4 gates all reads/writes by `parentId` or `recipientIds`.

**Tech Stack:** Flutter + Riverpod (StreamProvider) + Freezed models + go_router · Cloud Firestore · Cloud Functions v2 (triggers) / v1 (callables, cron) · Firebase Cloud Messaging (push)

---

## File Structure

```
lib/features/guard_requests/
├── models/
│   ├── guard_request.dart          ← GuardRequest freezed model + enums
│   └── guard_response.dart         ← GuardResponse freezed model
├── repository/
│   └── guard_request_repository.dart ← Firestore queries + callable wrappers
├── providers/
│   └── guard_request_providers.dart  ← StreamProviders, FutureProviders
├── screens/
│   ├── guard_requests_list_screen.dart    ← replaces placeholder; two tabs
│   ├── create_guard_request_screen.dart   ← 3-step stepper
│   ├── guard_request_detail_screen.dart   ← parent: responses + confirm + cancel
│   └── incoming_request_detail_screen.dart ← caregiver: accept / decline
└── widgets/
    ├── guard_request_card.dart     ← reusable list card
    └── response_card.dart          ← caregiver response row in detail

functions/src/guard_requests/
├── on_guard_request_created.ts     ← Gen2 trigger → push to each recipientId
├── on_guard_response_created.ts    ← Gen2 trigger → push to parent
├── on_guard_request_updated.ts     ← Gen2 trigger → push to confirmedId
├── guard_request_callables.ts      ← confirmCaregiver + cancelRequest (Gen1)
└── expire_guard_requests.ts        ← daily cron (Gen1 scheduled)

Modified:
  firestore.rules                   ← add guard_requests block (v4)
  firestore.indexes.json            ← add 2 composite indexes
  lib/core/router/app_router.dart   ← wire guard request routes
  functions/src/index.ts            ← export new functions
```

---

## Task 1: GuardRequest + GuardResponse models

**Files:**
- Create: `lib/features/guard_requests/models/guard_request.dart`
- Create: `lib/features/guard_requests/models/guard_response.dart`

- [ ] **Step 1: Create `guard_request.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'guard_request.freezed.dart';

enum GuardRequestType { hourly, halfDay, daily, night, weekend }
enum GuardRequestStatus { open, accepted, done, cancelled, expired }
enum RecurrenceType { none, custom }

class ChildSnapshot {
  const ChildSnapshot({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final DateTime birthDate;

  factory ChildSnapshot.fromMap(Map<String, dynamic> m) => ChildSnapshot(
        firstName: m['firstName'] as String,
        lastName: m['lastName'] as String,
        avatarUrl: m['avatarUrl'] as String?,
        birthDate: (m['birthDate'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'birthDate': Timestamp.fromDate(birthDate),
      };
}

@freezed
class GuardRequest with _$GuardRequest {
  const GuardRequest._();

  const factory GuardRequest({
    required String id,
    required String parentId,
    required String childId,
    required ChildSnapshot childSnapshot,
    required GuardRequestType type,
    required DateTime startAt,
    required DateTime endAt,
    String? location,
    String? notes,
    required GuardRequestStatus status,
    required RecurrenceType recurrenceType,
    required List<String> recipientIds,
    String? confirmedId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GuardRequest;

  factory GuardRequest.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return GuardRequest(
      id: doc.id,
      parentId: d['parentId'] as String,
      childId: d['childId'] as String,
      childSnapshot: ChildSnapshot.fromMap(d['childSnapshot'] as Map<String, dynamic>),
      type: GuardRequestType.values.byName(d['type'] as String),
      startAt: (d['startAt'] as Timestamp).toDate(),
      endAt: (d['endAt'] as Timestamp).toDate(),
      location: d['location'] as String?,
      notes: d['notes'] as String?,
      status: GuardRequestStatus.values.byName(d['status'] as String),
      recurrenceType: RecurrenceType.values.byName(d['recurrenceType'] as String),
      recipientIds: List<String>.from(d['recipientIds'] as List),
      confirmedId: d['confirmedId'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get typeLabel => switch (type) {
    GuardRequestType.hourly  => 'Quelques heures',
    GuardRequestType.halfDay => 'Demi-journée',
    GuardRequestType.daily   => 'Journée',
    GuardRequestType.night   => 'Nuit',
    GuardRequestType.weekend => 'Week-end',
  };
}
```

- [ ] **Step 2: Create `guard_response.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'guard_response.freezed.dart';

enum GuardResponseStatus { accepted, declined }

class CaregiverSnapshot {
  const CaregiverSnapshot({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String firstName;
  final String lastName;
  final String? avatarUrl;

  factory CaregiverSnapshot.fromMap(Map<String, dynamic> m) => CaregiverSnapshot(
        firstName: m['firstName'] as String,
        lastName: m['lastName'] as String,
        avatarUrl: m['avatarUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
      };
}

@freezed
class GuardResponse with _$GuardResponse {
  const GuardResponse._();

  const factory GuardResponse({
    required String caregiverId,
    required CaregiverSnapshot caregiverSnapshot,
    required GuardResponseStatus status,
    String? message,
    required DateTime respondedAt,
  }) = _GuardResponse;

  factory GuardResponse.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return GuardResponse(
      caregiverId: d['caregiverId'] as String,
      caregiverSnapshot: CaregiverSnapshot.fromMap(d['caregiverSnapshot'] as Map<String, dynamic>),
      status: GuardResponseStatus.values.byName(d['status'] as String),
      message: d['message'] as String?,
      respondedAt: (d['respondedAt'] as Timestamp).toDate(),
    );
  }
}
```

- [ ] **Step 3: Run code generation**

```bash
cd /path/to/familyguard
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: creates `guard_request.freezed.dart` and `guard_response.freezed.dart` with no errors.

- [ ] **Step 4: Verify no analysis errors**

```bash
flutter analyze lib/features/guard_requests/models/
```

Expected: `No issues found.`

- [ ] **Step 5: Commit**

```bash
git add lib/features/guard_requests/models/
git commit -m "feat(guard-requests): add GuardRequest and GuardResponse freezed models"
```

---

## Task 2: GuardRequestRepository

**Files:**
- Create: `lib/features/guard_requests/repository/guard_request_repository.dart`

- [ ] **Step 1: Create repository**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';

class GuardRequestRepository {
  const GuardRequestRepository({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore,
        _functions = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functions;

  FirebaseFunctions get _ff => _functions ?? FirebaseFunctions.instance;

  // --- Parent streams ---

  Stream<List<GuardRequest>> streamAsParent(String parentId) {
    return _db
        .collection('guard_requests')
        .where('parentId', isEqualTo: parentId)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(GuardRequest.fromFirestore).toList());
  }

  // --- Caregiver stream ---

  Stream<List<GuardRequest>> streamAsCaregiver(String caregiverId) {
    return _db
        .collection('guard_requests')
        .where('recipientIds', arrayContains: caregiverId)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(GuardRequest.fromFirestore).toList());
  }

  // --- Responses sub-collection ---

  Stream<List<GuardResponse>> streamResponses(String requestId) {
    return _db
        .collection('guard_requests')
        .doc(requestId)
        .collection('responses')
        .snapshots()
        .map((s) => s.docs.map(GuardResponse.fromFirestore).toList());
  }

  // --- Create ---

  Future<void> create({
    required String parentId,
    required String childId,
    required ChildSnapshot childSnapshot,
    required GuardRequestType type,
    required DateTime startAt,
    required DateTime endAt,
    String? location,
    String? notes,
    required RecurrenceType recurrenceType,
    required List<String> recipientIds,
    List<Map<String, dynamic>> occurrences = const [],
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _db.collection('guard_requests').add({
      'parentId': parentId,
      'childId': childId,
      'childSnapshot': childSnapshot.toMap(),
      'type': type.name,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'location': location,
      'notes': notes,
      'status': 'open',
      'recurrenceType': recurrenceType.name,
      'recipientIds': recipientIds,
      'confirmedId': null,
      'createdAt': now,
      'updatedAt': now,
    });
    for (final occ in occurrences) {
      await ref.collection('occurrences').add({
        ...occ,
        'status': 'planned',
        'createdAt': now,
      });
    }
  }

  // --- Callables ---

  Future<void> confirmCaregiver(String requestId, String caregiverId) async {
    await _ff.httpsCallable('confirmCaregiver').call({
      'requestId': requestId,
      'caregiverId': caregiverId,
    });
  }

  Future<void> cancelRequest(String requestId) async {
    await _ff.httpsCallable('cancelRequest').call({'requestId': requestId});
  }

  // --- Caregiver respond ---

  Future<void> respond({
    required String requestId,
    required String caregiverId,
    required CaregiverSnapshot caregiverSnapshot,
    required GuardResponseStatus status,
    String? message,
  }) async {
    await _db
        .collection('guard_requests')
        .doc(requestId)
        .collection('responses')
        .doc(caregiverId)
        .set({
      'caregiverId': caregiverId,
      'caregiverSnapshot': caregiverSnapshot.toMap(),
      'status': status.name,
      'message': message,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

- [ ] **Step 2: Check analysis**

```bash
flutter analyze lib/features/guard_requests/repository/
```

Expected: `No issues found.`

- [ ] **Step 3: Commit**

```bash
git add lib/features/guard_requests/repository/
git commit -m "feat(guard-requests): add GuardRequestRepository"
```

---

## Task 3: Providers

**Files:**
- Create: `lib/features/guard_requests/providers/guard_request_providers.dart`

- [ ] **Step 1: Create providers**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';
import '../repository/guard_request_repository.dart';

final guardRequestRepositoryProvider = Provider<GuardRequestRepository>(
  (ref) => GuardRequestRepository(firestore: FirebaseFirestore.instance),
);

final guardRequestsAsParentProvider = StreamProvider<List<GuardRequest>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(guardRequestRepositoryProvider).streamAsParent(user.uid);
});

final guardRequestsAsCaregiverProvider = StreamProvider<List<GuardRequest>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(guardRequestRepositoryProvider).streamAsCaregiver(user.uid);
});

final guardResponsesProvider =
    StreamProvider.family<List<GuardResponse>, String>((ref, requestId) {
  return ref.read(guardRequestRepositoryProvider).streamResponses(requestId);
});
```

- [ ] **Step 2: Check analysis**

```bash
flutter analyze lib/features/guard_requests/providers/
```

Expected: `No issues found.`

- [ ] **Step 3: Commit**

```bash
git add lib/features/guard_requests/providers/
git commit -m "feat(guard-requests): add Riverpod providers"
```

---

## Task 4: Firestore rules v4 + indexes

**Files:**
- Modify: `firestore.rules`
- Modify: `firestore.indexes.json`

- [ ] **Step 1: Update `firestore.rules` — add guard_requests block**

Add inside `match /databases/{database}/documents {` after the connections block:

```javascript
    match /guard_requests/{requestId} {
      allow read: if isAuth() &&
        (request.auth.uid == resource.data.parentId ||
         request.auth.uid in resource.data.recipientIds);
      allow create: if isAuth() &&
        isOwner(request.resource.data.parentId);
      allow update: if isAuth() &&
        isOwner(resource.data.parentId);

      match /occurrences/{occurrenceId} {
        allow read, write: if isAuth() &&
          isOwner(get(/databases/$(database)/documents/guard_requests/$(requestId)).data.parentId);
      }

      match /responses/{caregiverId} {
        allow read: if isAuth() &&
          (request.auth.uid == get(/databases/$(database)/documents/guard_requests/$(requestId)).data.parentId ||
           request.auth.uid == caregiverId);
        allow create, update: if isAuth() && isOwner(caregiverId);
      }

      match /recipients/{caregiverId} {
        allow read: if isAuth() &&
          (request.auth.uid == get(/databases/$(database)/documents/guard_requests/$(requestId)).data.parentId ||
           request.auth.uid == caregiverId);
        allow write: if false;
      }
    }
```

- [ ] **Step 2: Update `firestore.indexes.json` — add composite indexes**

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
    },
    {
      "collectionGroup": "guard_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "parentId", "order": "ASCENDING" },
        { "fieldPath": "startAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "guard_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "recipientIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "startAt", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

- [ ] **Step 3: Deploy rules and indexes**

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Expected: `✔  Deploy complete!`

- [ ] **Step 4: Commit**

```bash
git add firestore.rules firestore.indexes.json
git commit -m "feat(guard-requests): Firestore rules v4 + composite indexes"
```

---

## Task 5: Router + GuardRequestCard widget

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Create: `lib/features/guard_requests/widgets/guard_request_card.dart`
- Create: `lib/features/guard_requests/widgets/response_card.dart`

- [ ] **Step 1: Create `guard_request_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/guard_request.dart';

class GuardRequestCard extends StatelessWidget {
  const GuardRequestCard({super.key, required this.request, required this.isParent});

  final GuardRequest request;
  final bool isParent;

  BadgeStatus get _badge => switch (request.status) {
    GuardRequestStatus.open      => BadgeStatus.waiting,
    GuardRequestStatus.accepted  => BadgeStatus.accepted,
    GuardRequestStatus.done      => BadgeStatus.accepted,
    GuardRequestStatus.cancelled => BadgeStatus.declined,
    GuardRequestStatus.expired   => BadgeStatus.declined,
  };

  String get _statusLabel => switch (request.status) {
    GuardRequestStatus.open      => 'En attente',
    GuardRequestStatus.accepted  => 'Confirmée',
    GuardRequestStatus.done      => 'Terminée',
    GuardRequestStatus.cancelled => 'Annulée',
    GuardRequestStatus.expired   => 'Expirée',
  };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm', 'fr');
    final child = request.childSnapshot;
    final childName = '${child.firstName} ${child.lastName}'.trim();
    final route = isParent
        ? '/guard-requests/${request.id}'
        : '/guard-requests/${request.id}/incoming';

    return GestureDetector(
      onTap: () => context.push(route, extra: request),
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
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.calendar, size: 20, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isParent ? '${request.typeLabel} · $childName' : request.typeLabel,
                    style: AppTextStyles.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(request.startAt),
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: _badge),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `response_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/guard_response.dart';

class ResponseCard extends StatelessWidget {
  const ResponseCard({
    super.key,
    required this.response,
    this.isConfirmed = false,
    this.onConfirm,
  });

  final GuardResponse response;
  final bool isConfirmed;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final name = '${response.caregiverSnapshot.firstName} ${response.caregiverSnapshot.lastName}'.trim();
    final initials = '${response.caregiverSnapshot.firstName.isNotEmpty ? response.caregiverSnapshot.firstName[0] : ''}${response.caregiverSnapshot.lastName.isNotEmpty ? response.caregiverSnapshot.lastName[0] : ''}';
    final isAccepted = response.status == GuardResponseStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfirmed ? AppColors.glassPurpleBorder : AppColors.glassBorder,
          width: isConfirmed ? 0.8 : 0.5,
        ),
      ),
      child: Row(
        children: [
          AvatarInitials(initials: initials, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle),
                if (response.message != null && response.message!.isNotEmpty)
                  Text(response.message!, style: AppTextStyles.cardSubtitle,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isConfirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassPurpleSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Confirmé', style: AppTextStyles.badge.copyWith(color: AppColors.badgeNewText)),
            )
          else if (isAccepted && onConfirm != null)
            FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Confirmer', style: AppTextStyles.badge.copyWith(color: Colors.white)),
            )
          else
            StatusBadge(status: isAccepted ? BadgeStatus.accepted : BadgeStatus.declined),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update `app_router.dart`**

Replace the guard-requests branch and add routes. The full `StatefulShellBranch` for guard-requests becomes:

```dart
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
```

Add imports at the top of `app_router.dart`:
```dart
import '../../features/guard_requests/models/guard_request.dart';
import '../../features/guard_requests/screens/guard_requests_list_screen.dart';
import '../../features/guard_requests/screens/create_guard_request_screen.dart';
import '../../features/guard_requests/screens/guard_request_detail_screen.dart';
import '../../features/guard_requests/screens/incoming_request_detail_screen.dart';
```

Remove:
```dart
import '../../features/guard_requests/screens/guard_requests_placeholder_screen.dart';
```

- [ ] **Step 4: Check analysis**

```bash
flutter analyze lib/features/guard_requests/widgets/ lib/core/router/app_router.dart
```

Expected: `No issues found.`

- [ ] **Step 5: Commit**

```bash
git add lib/features/guard_requests/widgets/ lib/core/router/app_router.dart
git commit -m "feat(guard-requests): add GuardRequestCard, ResponseCard and router routes"
```

---

## Task 6: GuardRequestsListScreen

**Files:**
- Create: `lib/features/guard_requests/screens/guard_requests_list_screen.dart`
- Delete: `lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart`

- [ ] **Step 1: Create `guard_requests_list_screen.dart`**

This screen has two tabs: "Mes demandes" (as parent) and "Gardes reçues" (as caregiver). The parent tab has a `+` button in the AppBar.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../models/guard_request.dart';
import '../providers/guard_request_providers.dart';
import '../widgets/guard_request_card.dart';

class GuardRequestsListScreen extends ConsumerStatefulWidget {
  const GuardRequestsListScreen({super.key});

  @override
  ConsumerState<GuardRequestsListScreen> createState() => _GuardRequestsListScreenState();
}

class _GuardRequestsListScreenState extends ConsumerState<GuardRequestsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asParentAsync = ref.watch(guardRequestsAsParentProvider);
    final asCaregiverAsync = ref.watch(guardRequestsAsCaregiverProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Gardes'),
        actions: [
          IconButton(
            onPressed: () => context.push('/guard-requests/create'),
            icon: const Icon(LucideIcons.plus, size: 20, color: AppColors.primaryLight),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.badgeNewText,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.cardTitle,
          tabs: const [
            Tab(text: 'Mes demandes'),
            Tab(text: 'Gardes reçues'),
          ],
        ),
      ),
      body: AppBackground(
        child: TabBarView(
          controller: _tab,
          children: [
            _RequestsList(asyncValue: asParentAsync, isParent: true),
            _RequestsList(asyncValue: asCaregiverAsync, isParent: false),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.asyncValue, required this.isParent});

  final AsyncValue<List<GuardRequest>> asyncValue;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle)),
      data: (requests) {
        if (requests.isEmpty) {
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
                  child: const Icon(LucideIcons.calendar, size: 32, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                Text(
                  isParent ? 'Aucune demande' : 'Aucune garde reçue',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  isParent ? 'Créez votre première demande' : 'Les demandes apparaîtront ici',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 96),
          itemCount: requests.length,
          itemBuilder: (_, i) => GuardRequestCard(request: requests[i], isParent: isParent),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Delete the placeholder**

```bash
rm lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart
```

- [ ] **Step 3: Check analysis**

```bash
flutter analyze lib/features/guard_requests/screens/guard_requests_list_screen.dart
```

Expected: `No issues found.`

- [ ] **Step 4: Commit**

```bash
git add lib/features/guard_requests/screens/guard_requests_list_screen.dart
git rm lib/features/guard_requests/screens/guard_requests_placeholder_screen.dart
git commit -m "feat(guard-requests): add GuardRequestsListScreen with two tabs"
```

---

## Task 7: CreateGuardRequestScreen — Steps 1 & 2

**Files:**
- Create: `lib/features/guard_requests/screens/create_guard_request_screen.dart`

This is a 3-step stepper. This task covers steps 1 (child + type + dates) and 2 (occurrences if recurring).

- [ ] **Step 1: Create `create_guard_request_screen.dart` with the stepper shell and steps 1 + 2**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../children/models/child.dart';
import '../../children/providers/children_providers.dart';
import '../models/guard_request.dart';
import '../providers/guard_request_providers.dart';

class CreateGuardRequestScreen extends ConsumerStatefulWidget {
  const CreateGuardRequestScreen({super.key});

  @override
  ConsumerState<CreateGuardRequestScreen> createState() =>
      _CreateGuardRequestScreenState();
}

class _CreateGuardRequestScreenState
    extends ConsumerState<CreateGuardRequestScreen> {
  int _step = 0;

  // Step 1 state
  Child? _selectedChild;
  GuardRequestType _type = GuardRequestType.hourly;
  DateTime _startAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endAt = DateTime.now().add(const Duration(hours: 3));
  String _location = '';
  String _notes = '';
  RecurrenceType _recurrenceType = RecurrenceType.none;

  // Step 2 state
  final List<(DateTime start, DateTime end)> _occurrences = [];

  // Step 3 state — handled in Task 8

  bool _loading = false;

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startAt : _endAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startAt : _endAt),
    );
    if (time == null || !mounted) return;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startAt = result;
        if (_endAt.isBefore(_startAt)) _endAt = _startAt.add(const Duration(hours: 2));
      } else {
        _endAt = result;
      }
    });
  }

  Future<void> _pickOccurrence() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null || !mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (endTime == null || !mounted) return;
    setState(() {
      _occurrences.add((
        DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute),
        DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute),
      ));
    });
  }

  Widget _buildStep1(List<Child> children) {
    final fmt = DateFormat('d MMM HH:mm', 'fr');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Enfant', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        ...children.map((c) {
          final selected = _selectedChild?.id == c.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedChild = c),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Text(
                '${c.firstName} ${c.lastName}'.trim().isEmpty ? c.firstName : '${c.firstName} ${c.lastName}'.trim(),
                style: AppTextStyles.cardTitle,
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Text('Type de garde', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: GuardRequestType.values.map((t) {
            final selected = _type == t;
            final label = switch (t) {
              GuardRequestType.hourly  => 'Quelques heures',
              GuardRequestType.halfDay => 'Demi-journée',
              GuardRequestType.daily   => 'Journée',
              GuardRequestType.night   => 'Nuit',
              GuardRequestType.weekend => 'Week-end',
            };
            return GestureDetector(
              onTap: () => setState(() => _type = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(label, style: AppTextStyles.cardTitle.copyWith(
                  color: selected ? AppColors.badgeNewText : AppColors.textPrimary,
                )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Dates', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        _DateTile(label: 'Début', value: fmt.format(_startAt), onTap: () => _pickDateTime(isStart: true)),
        const SizedBox(height: 8),
        _DateTile(label: 'Fin', value: fmt.format(_endAt), onTap: () => _pickDateTime(isStart: false)),
        const SizedBox(height: 20),
        Text('Récurrence', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 8),
        Row(
          children: RecurrenceType.values.map((r) {
            final selected = _recurrenceType == r;
            final label = r == RecurrenceType.none ? 'Ponctuel' : 'Récurrent';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _recurrenceType = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(label, style: AppTextStyles.cardTitle.copyWith(
                    color: selected ? AppColors.badgeNewText : AppColors.textPrimary,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Lieu (optionnel)'),
          onChanged: (v) => _location = v,
        ),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
          maxLines: 3,
          onChanged: (v) => _notes = v,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final fmt = DateFormat('d MMM HH:mm', 'fr');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Occurrences récurrentes', style: AppTextStyles.cardTitle),
        const SizedBox(height: 4),
        Text('Ajoutez les dates supplémentaires.', style: AppTextStyles.cardSubtitle),
        const SizedBox(height: 16),
        ..._occurrences.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${fmt.format(e.value.$1)} → ${fmt.format(e.value.$2)}',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textTertiary),
                onPressed: () => setState(() => _occurrences.removeAt(e.key)),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickOccurrence,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Ajouter une date'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
      ],
    );
  }

  // Step 3 will be added in Task 8

  bool get _canProceedStep1 =>
      _selectedChild != null && _endAt.isAfter(_startAt);

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final children = childrenAsync.valueOrNull?.where((c) => !c.archived).toList() ?? [];

    final steps = [
      'Détails',
      if (_recurrenceType == RecurrenceType.custom) 'Occurrences',
      'Destinataires',
    ];
    final totalSteps = steps.length;
    final isLastStep = _step == totalSteps - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(steps[_step]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / totalSteps,
            backgroundColor: AppColors.glassSurface,
            color: AppColors.primaryLight,
            minHeight: 3,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentStep(children),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: const Text('Retour'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _canProceed() ? _onNext : null,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isLastStep ? 'Envoyer' : 'Suivant'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(List<Child> children) {
    if (_step == 0) return _buildStep1(children);
    if (_recurrenceType == RecurrenceType.custom && _step == 1) return _buildStep2();
    return _buildStep3(); // implemented in Task 8
  }

  bool _canProceed() {
    if (_step == 0) return _canProceedStep1;
    return true;
  }

  Future<void> _onNext() async {
    final totalSteps = _recurrenceType == RecurrenceType.custom ? 3 : 2;
    if (_step < totalSteps - 1) {
      setState(() => _step++);
    } else {
      await _submit();
    }
  }

  // _buildStep3 and _submit implemented in Task 8
  Widget _buildStep3() => const Center(child: CircularProgressIndicator());
  Future<void> _submit() async {}
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: AppColors.primaryLight),
            const SizedBox(width: 10),
            Text('$label : ', style: AppTextStyles.cardSubtitle),
            Text(value, style: AppTextStyles.cardTitle),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Check analysis**

```bash
flutter analyze lib/features/guard_requests/screens/create_guard_request_screen.dart
```

Expected: `No issues found.`

- [ ] **Step 3: Commit**

```bash
git add lib/features/guard_requests/screens/create_guard_request_screen.dart
git commit -m "feat(guard-requests): CreateGuardRequestScreen steps 1 and 2"
```

---

## Task 8: CreateGuardRequestScreen — Step 3 + Submit

**Files:**
- Modify: `lib/features/guard_requests/screens/create_guard_request_screen.dart`

Step 3 lets the parent pick recipients from their active connections.

- [ ] **Step 1: Add imports for connections providers**

At the top of `create_guard_request_screen.dart`, add:
```dart
import '../../connections/models/connection.dart';
import '../../connections/providers/connection_providers.dart';
```

- [ ] **Step 2: Add `_selectedRecipients` state variable**

Inside `_CreateGuardRequestScreenState`, add:
```dart
final Set<String> _selectedRecipients = {};
```

- [ ] **Step 3: Replace `_buildStep3()` stub with the real implementation**

```dart
Widget _buildStep3() {
  final connectionsAsync = ref.watch(connectionsAsParentProvider);
  final activeConnections = connectionsAsync.valueOrNull
          ?.where((c) => c.status == ConnectionStatus.active && c.caregiverId != null)
          .toList() ??
      [];

  if (activeConnections.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.users, size: 32, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Aucun babysitter actif', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text('Invitez des proches dans Connexions.', style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }

  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
    children: [
      Text('Envoyer à…', style: AppTextStyles.cardTitle),
      const SizedBox(height: 4),
      Text('Choisissez les babysitters à notifier.', style: AppTextStyles.cardSubtitle),
      const SizedBox(height: 16),
      ...activeConnections.map((c) {
        final uid = c.caregiverId!;
        final selected = _selectedRecipients.contains(uid);
        final userAsync = ref.watch(userByIdProvider(uid));
        final user = userAsync.valueOrNull;
        final name = user != null
            ? '${user.firstName} ${user.lastName}'.trim()
            : c.inviteEmail;

        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedRecipients.remove(uid);
            } else {
              _selectedRecipients.add(uid);
            }
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? AppColors.glassPurpleSurface : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.glassPurpleBorder : AppColors.glassBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 20,
                  color: selected ? AppColors.primaryLight : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Text(name, style: AppTextStyles.cardTitle),
              ],
            ),
          ),
        );
      }),
    ],
  );
}
```

- [ ] **Step 4: Replace `_submit()` stub with the real implementation**

```dart
Future<void> _submit() async {
  if (_selectedRecipients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélectionnez au moins un destinataire.')),
    );
    return;
  }
  setState(() => _loading = true);
  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final child = _selectedChild!;
    final snapshot = ChildSnapshot(
      firstName: child.firstName,
      lastName: child.lastName,
      avatarUrl: child.avatarUrl,
      birthDate: child.birthDate,
    );
    final occurrences = _occurrences.map((o) => {
      'startAt': Timestamp.fromDate(o.$1),
      'endAt': Timestamp.fromDate(o.$2),
      'notes': null,
    }).toList();

    await ref.read(guardRequestRepositoryProvider).create(
      parentId: uid,
      childId: child.id,
      childSnapshot: snapshot,
      type: _type,
      startAt: _startAt,
      endAt: _endAt,
      location: _location.trim().isEmpty ? null : _location.trim(),
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
      recurrenceType: _recurrenceType,
      recipientIds: _selectedRecipients.toList(),
      occurrences: occurrences,
    );

    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande envoyée !')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $e')),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

Add missing import at the top:
```dart
import '../../auth/providers/auth_providers.dart';
```

- [ ] **Step 5: Update `_canProceed()` to check recipients on last step**

```dart
bool _canProceed() {
  if (_step == 0) return _canProceedStep1;
  final totalSteps = _recurrenceType == RecurrenceType.custom ? 3 : 2;
  if (_step == totalSteps - 1) return _selectedRecipients.isNotEmpty;
  return true;
}
```

- [ ] **Step 6: Check analysis**

```bash
flutter analyze lib/features/guard_requests/screens/create_guard_request_screen.dart
```

Expected: `No issues found.`

- [ ] **Step 7: Commit**

```bash
git add lib/features/guard_requests/screens/create_guard_request_screen.dart
git commit -m "feat(guard-requests): CreateGuardRequestScreen step 3 (recipients) + submit"
```

---

## Task 9: GuardRequestDetailScreen (parent view)

**Files:**
- Create: `lib/features/guard_requests/screens/guard_request_detail_screen.dart`

The parent sees the request info, the list of responses (accepted/declined/pending), a "Confirmer" button on accepted responses, and a cancel button.

- [ ] **Step 1: Create `guard_request_detail_screen.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';
import '../providers/guard_request_providers.dart';
import '../widgets/response_card.dart';

class GuardRequestDetailScreen extends ConsumerWidget {
  const GuardRequestDetailScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  final String requestId;
  final GuardRequest? request;

  GuardRequest? _find(WidgetRef ref, String id) {
    return ref.watch(guardRequestsAsParentProvider).valueOrNull
        ?.firstWhere((r) => r.id == id, orElse: () => request!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final req = _find(ref, requestId) ?? request;
    if (req == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final responsesAsync = ref.watch(guardResponsesProvider(requestId));
    final responses = responsesAsync.valueOrNull ?? [];
    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'fr');
    final isOpen = req.status == GuardRequestStatus.open;
    final isAccepted = req.status == GuardRequestStatus.accepted;

    final badgeStatus = switch (req.status) {
      GuardRequestStatus.open      => BadgeStatus.waiting,
      GuardRequestStatus.accepted  => BadgeStatus.accepted,
      GuardRequestStatus.done      => BadgeStatus.accepted,
      GuardRequestStatus.cancelled => BadgeStatus.declined,
      GuardRequestStatus.expired   => BadgeStatus.declined,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Demande de garde')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(req.typeLabel, style: AppTextStyles.screenTitle),
                    ),
                    StatusBadge(status: badgeStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.childSnapshot.firstName} ${req.childSnapshot.lastName}'.trim(),
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),

                // Details card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(icon: LucideIcons.calendar, label: 'Début', value: fmt.format(req.startAt)),
                      const SizedBox(height: 12),
                      _InfoRow(icon: LucideIcons.calendarOff, label: 'Fin', value: fmt.format(req.endAt)),
                      if (req.location != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(icon: LucideIcons.mapPin, label: 'Lieu', value: req.location!),
                      ],
                      if (req.notes != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(icon: LucideIcons.messageSquare, label: 'Notes', value: req.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Responses
                Text('Réponses', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                if (responses.isEmpty)
                  Text('En attente de réponses…', style: AppTextStyles.cardSubtitle)
                else
                  ...responses.map((r) => ResponseCard(
                    response: r,
                    isConfirmed: req.confirmedId == r.caregiverId,
                    onConfirm: (isOpen && r.status == GuardResponseStatus.accepted)
                        ? () => _confirm(context, ref, req.id, r.caregiverId)
                        : null,
                  )),
                const SizedBox(height: 24),

                // Cancel button
                if (isOpen || isAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(context, ref, req.id),
                      icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFFF87171)),
                      label: const Text('Annuler la demande',
                          style: TextStyle(color: Color(0xFFF87171))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, String requestId, String caregiverId) async {
    try {
      await ref.read(guardRequestRepositoryProvider).confirmCaregiver(requestId, caregiverId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Garde confirmée !')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String requestId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Les babysitters seront notifiés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Retour')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(guardRequestRepositoryProvider).cancelRequest(requestId);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.cardTitle),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Check analysis**

```bash
flutter analyze lib/features/guard_requests/screens/guard_request_detail_screen.dart
```

Expected: `No issues found.`

- [ ] **Step 3: Commit**

```bash
git add lib/features/guard_requests/screens/guard_request_detail_screen.dart
git commit -m "feat(guard-requests): GuardRequestDetailScreen (parent view)"
```

---

## Task 10: IncomingRequestDetailScreen (caregiver view)

**Files:**
- Create: `lib/features/guard_requests/screens/incoming_request_detail_screen.dart`

The caregiver sees request details and can accept or decline with an optional message.

- [ ] **Step 1: Create `incoming_request_detail_screen.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';
import '../providers/guard_request_providers.dart';

class IncomingRequestDetailScreen extends ConsumerStatefulWidget {
  const IncomingRequestDetailScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  final String requestId;
  final GuardRequest? request;

  @override
  ConsumerState<IncomingRequestDetailScreen> createState() =>
      _IncomingRequestDetailScreenState();
}

class _IncomingRequestDetailScreenState
    extends ConsumerState<IncomingRequestDetailScreen> {
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  GuardRequest? _find(String id) {
    return ref.watch(guardRequestsAsCaregiverProvider).valueOrNull
        ?.firstWhere((r) => r.id == id, orElse: () => widget.request!);
  }

  Future<void> _respond(GuardRequest req, GuardResponseStatus status) async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = ref.read(currentUserProvider).valueOrNull;
      final snapshot = CaregiverSnapshot(
        firstName: user?.firstName ?? '',
        lastName: user?.lastName ?? '',
        avatarUrl: user?.avatarUrl,
      );
      await ref.read(guardRequestRepositoryProvider).respond(
        requestId: req.id,
        caregiverId: uid,
        caregiverSnapshot: snapshot,
        status: status,
        message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
      );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == GuardResponseStatus.accepted
              ? 'Demande acceptée !'
              : 'Demande refusée.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _find(widget.requestId) ?? widget.request;
    if (req == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'fr');
    final isOpen = req.status == GuardRequestStatus.open;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Demande de garde')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.typeLabel, style: AppTextStyles.screenTitle),
                const SizedBox(height: 4),
                Text(
                  '${req.childSnapshot.firstName} ${req.childSnapshot.lastName}'.trim(),
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(icon: LucideIcons.calendar, label: 'Début', value: fmt.format(req.startAt)),
                      const SizedBox(height: 12),
                      _InfoRow(icon: LucideIcons.calendarOff, label: 'Fin', value: fmt.format(req.endAt)),
                      if (req.location != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(icon: LucideIcons.mapPin, label: 'Lieu', value: req.location!),
                      ],
                      if (req.notes != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(icon: LucideIcons.messageSquare, label: 'Notes', value: req.notes!),
                      ],
                    ],
                  ),
                ),
                if (isOpen) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _messageCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Message (optionnel)',
                      hintText: 'Ajouter un message…',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _respond(req, GuardResponseStatus.declined),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                            ),
                            child: const Text('Refuser'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => _respond(req, GuardResponseStatus.accepted),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Accepter'),
                          ),
                        ),
                      ],
                    ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    req.status == GuardRequestStatus.accepted
                        ? 'Garde confirmée — à vous de jouer !'
                        : 'Cette demande n\'est plus disponible.',
                    style: AppTextStyles.cardSubtitle,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.cardTitle),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Check analysis**

```bash
flutter analyze lib/features/guard_requests/screens/incoming_request_detail_screen.dart
```

Expected: `No issues found.`

- [ ] **Step 3: Commit**

```bash
git add lib/features/guard_requests/screens/incoming_request_detail_screen.dart
git commit -m "feat(guard-requests): IncomingRequestDetailScreen (caregiver view)"
```

---

## Task 11: Cloud Functions — Firestore triggers

**Files:**
- Create: `functions/src/guard_requests/on_guard_request_created.ts`
- Create: `functions/src/guard_requests/on_guard_response_created.ts`
- Create: `functions/src/guard_requests/on_guard_request_updated.ts`
- Create: `functions/src/notifications/send_push_notification.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Create `send_push_notification.ts` helper**

```typescript
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';

export async function sendPushToUser(
  uid: string,
  title: string,
  body: string,
): Promise<void> {
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken as string | undefined;
  if (!fcmToken) {
    logger.info('No FCM token for user', { uid });
    return;
  }
  await admin.messaging().send({
    token: fcmToken,
    notification: { title, body },
    apns: { payload: { aps: { sound: 'default' } } },
    android: { notification: { sound: 'default' } },
  });
}
```

- [ ] **Step 2: Create `on_guard_request_created.ts`**

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPushToUser } from '../notifications/send_push_notification';

export const onGuardRequestCreated = onDocumentCreated(
  { document: 'guard_requests/{requestId}', region: 'europe-west1' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const recipientIds: string[] = data.recipientIds ?? [];
    const db = admin.firestore();

    const parentDoc = await db.collection('users').doc(data.parentId).get();
    const parentName = (parentDoc.data()?.firstName as string) || 'Un parent';
    const childName = (data.childSnapshot?.firstName as string) || 'votre enfant';
    const typeLabel = data.type as string;

    for (const uid of recipientIds) {
      await db
        .collection('guard_requests')
        .doc(snap.id)
        .collection('recipients')
        .doc(uid)
        .set({
          caregiverId: uid,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          readAt: null,
        });

      await sendPushToUser(
        uid,
        'Nouvelle demande de garde',
        `${parentName} cherche quelqu'un pour garder ${childName} (${typeLabel})`,
      );
    }

    logger.info('Guard request notifications sent', {
      requestId: snap.id,
      recipientCount: recipientIds.length,
    });
  },
);
```

- [ ] **Step 3: Create `on_guard_response_created.ts`**

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPushToUser } from '../notifications/send_push_notification';

export const onGuardResponseCreated = onDocumentCreated(
  {
    document: 'guard_requests/{requestId}/responses/{caregiverId}',
    region: 'europe-west1',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const requestId = event.params.requestId;

    const requestDoc = await admin
      .firestore()
      .collection('guard_requests')
      .doc(requestId)
      .get();
    const parentId = requestDoc.data()?.parentId as string;
    if (!parentId) return;

    const caregiverName =
      (data.caregiverSnapshot?.firstName as string) || 'Un babysitter';
    const statusLabel =
      data.status === 'accepted' ? 'a accepté' : 'a refusé';

    await sendPushToUser(
      parentId,
      'Réponse reçue',
      `${caregiverName} ${statusLabel} votre demande de garde`,
    );

    logger.info('Response notification sent', { requestId, caregiverId: data.caregiverId });
  },
);
```

- [ ] **Step 4: Create `on_guard_request_updated.ts`**

```typescript
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPushToUser } from '../notifications/send_push_notification';

export const onGuardRequestUpdated = onDocumentUpdated(
  { document: 'guard_requests/{requestId}', region: 'europe-west1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (
      before.confirmedId == null &&
      after.confirmedId != null &&
      after.status === 'accepted'
    ) {
      await sendPushToUser(
        after.confirmedId as string,
        'Garde confirmée !',
        'Vous avez été sélectionné pour cette garde.',
      );
      logger.info('Confirmation notification sent', {
        requestId: event.params.requestId,
        confirmedId: after.confirmedId,
      });
    }

    if (before.status !== 'cancelled' && after.status === 'cancelled') {
      const recipientIds: string[] = after.recipientIds ?? [];
      for (const uid of recipientIds) {
        await sendPushToUser(uid, 'Demande annulée', 'Une demande de garde a été annulée.');
      }
    }
  },
);
```

- [ ] **Step 5: Update `functions/src/index.ts`**

```typescript
import * as admin from 'firebase-admin';

admin.initializeApp();

export { onUserCreated } from './auth/on_user_created';
export { onConnectionCreated } from './connections/on_connection_created';
export { onConnectionUpdated } from './connections/on_connection_updated';
export { getInviteDetails, acceptInvite } from './connections/accept_invite';
export { onGuardRequestCreated } from './guard_requests/on_guard_request_created';
export { onGuardResponseCreated } from './guard_requests/on_guard_response_created';
export { onGuardRequestUpdated } from './guard_requests/on_guard_request_updated';
export { confirmCaregiver, cancelRequest } from './guard_requests/guard_request_callables';
export { expireGuardRequests } from './guard_requests/expire_guard_requests';
```

- [ ] **Step 6: Build to verify**

```bash
cd functions && npm run build
```

Expected: no TypeScript errors.

- [ ] **Step 7: Commit**

```bash
git add functions/src/
git commit -m "feat(guard-requests): Cloud Function triggers for push notifications"
```

---

## Task 12: Cloud Functions — Callables + Cron

**Files:**
- Create: `functions/src/guard_requests/guard_request_callables.ts`
- Create: `functions/src/guard_requests/expire_guard_requests.ts`

- [ ] **Step 1: Create `guard_request_callables.ts`**

```typescript
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const confirmCaregiver = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise.');
    }

    const { requestId, caregiverId } = data as { requestId: string; caregiverId: string };
    const db = admin.firestore();
    const ref = db.collection('guard_requests').doc(requestId);

    await db.runTransaction(async (tx) => {
      const doc = await tx.get(ref);
      if (!doc.exists) {
        throw new functions.https.HttpsError('not-found', 'Demande introuvable.');
      }
      const d = doc.data()!;
      if (d.parentId !== context.auth!.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Non autorisé.');
      }
      if (d.status !== 'open') {
        throw new functions.https.HttpsError('failed-precondition', 'Demande déjà traitée.');
      }
      tx.update(ref, {
        status: 'accepted',
        confirmedId: caregiverId,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return { ok: true };
  });

export const cancelRequest = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise.');
    }

    const { requestId } = data as { requestId: string };
    const db = admin.firestore();
    const ref = db.collection('guard_requests').doc(requestId);
    const doc = await ref.get();

    if (!doc.exists) {
      throw new functions.https.HttpsError('not-found', 'Demande introuvable.');
    }
    if (doc.data()!.parentId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Non autorisé.');
    }

    await ref.update({
      status: 'cancelled',
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true };
  });
```

- [ ] **Step 2: Create `expire_guard_requests.ts`**

```typescript
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export const expireGuardRequests = functions
  .region('europe-west1')
  .pubsub.schedule('every day 06:00')
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const snap = await db
      .collection('guard_requests')
      .where('status', '==', 'open')
      .where('endAt', '<', now)
      .get();

    if (snap.empty) {
      functions.logger.info('No expired requests.');
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'expired',
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();

    functions.logger.info(`Expired ${snap.size} guard requests.`);
  });
```

- [ ] **Step 3: Build**

```bash
cd functions && npm run build
```

Expected: no errors.

- [ ] **Step 4: Deploy all new functions**

```bash
firebase deploy --only functions
```

Expected: all functions deploy successfully. Note: Gen2 triggers may take 1-2 minutes for IAM propagation on first deploy.

- [ ] **Step 5: Commit**

```bash
git add functions/src/guard_requests/
git commit -m "feat(guard-requests): callables confirmCaregiver + cancelRequest + expireGuardRequests cron"
```

---

## Task 13: FCM token on login + Flutter build check

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart` (or wherever login completes)
- Check overall build

The `fcmToken` field exists in the user model but is never written from the app. Without it, push notifications don't reach the device.

- [ ] **Step 1: Find where login completes and user Firestore doc is updated**

Look in `lib/features/auth/screens/login_screen.dart` for the sign-in completion code. The FCM token should be saved to Firestore immediately after login.

- [ ] **Step 2: Add FCM token save after login**

In the login success callback (after `FirebaseAuth.instance.signInWithEmailAndPassword` succeeds), add:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// After successful login:
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'fcmToken': fcmToken,
  });
}
```

Do the same in `register_screen.dart` after account creation.

- [ ] **Step 3: Request notification permission (iOS/web)**

Add to `main.dart` after Firebase initialization:

```dart
await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

- [ ] **Step 4: Full Flutter build check**

```bash
flutter build web --no-pub 2>&1 | tail -5
```

Expected: `✓ Built build/web`

- [ ] **Step 5: Run code generation if needed**

If any freezed files are stale:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Commit**

```bash
git add lib/
git commit -m "feat(guard-requests): save FCM token on login for push notifications"
```

---

## Self-Review

**1. Spec coverage:**
- ✅ `GuardRequestsListScreen` — two tabs (parent + caregiver)
- ✅ `CreateGuardRequestScreen` — 3-step stepper (child+type+dates / occurrences / recipients)
- ✅ `GuardRequestDetailScreen` — responses + confirm + cancel
- ✅ `IncomingRequestDetailScreen` — accept / decline
- ✅ `onGuardRequestCreated` — push + recipients sub-collection
- ✅ `onGuardResponseCreated` — push to parent
- ✅ `onGuardRequestUpdated` — push to confirmed caregiver + cancel notify
- ✅ `confirmCaregiver` callable — atomic transaction
- ✅ `cancelRequest` callable
- ✅ `expireGuardRequests` cron — daily 06:00 Paris
- ✅ Firestore rules v4 — guard_requests + sub-collections
- ✅ Composite indexes — parentId+startAt, recipientIds+startAt
- ⚠️ `MyScheduleScreen` — the caregiver confirmed-guards view is folded into the "Gardes reçues" tab (filtered by status in the list) to avoid scope creep. Post-MVP can be a separate screen.

**2. Placeholder scan:** No TBD, TODO, or incomplete steps. All code blocks are complete.

**3. Type consistency:**
- `ChildSnapshot` defined in Task 1, used in Tasks 7, 8, 9 ✅
- `CaregiverSnapshot` defined in Task 1, used in Tasks 8, 10 ✅
- `GuardRequestRepository.create()` defined in Task 2, called in Task 8 ✅
- `GuardRequestRepository.respond()` defined in Task 2, called in Task 10 ✅
- `guardRequestRepositoryProvider` defined in Task 3, used in Tasks 8, 9, 10 ✅
- `guardResponsesProvider` defined in Task 3, used in Task 9 ✅
- Routes `/guard-requests/create`, `/guard-requests/:id`, `/guard-requests/:id/incoming` defined in Task 5, used in Tasks 6, 7, 8 ✅
