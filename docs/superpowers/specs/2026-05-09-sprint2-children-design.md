# Sprint 2 — Children Feature Design

Date: 2026-05-09
Status: Approved

---

## Context

Sprint 1 delivered a complete auth flow (Firebase Auth, Riverpod, go_router). Sprint 2 adds the Children feature: parents can add, view, edit, and delete their children's profiles. Children are stored in `/children/{childId}` in Firestore with optional photo in Firebase Storage.

---

## UX Decisions

- **Creation**: bottom sheet (quick add), not a full-screen form
- **List card**: minimal — photo/avatar + full name + calculated age
- **Tap on card**: opens `ChildDetailScreen` (read view)
- **Deletion**: only from `ChildDetailScreen`, with confirmation dialog
- **Navigation**: push-based (no ShellRoute yet — only 1 feature tab at this stage)

---

## Section 1 — Model & Repository

### `Child` model

Freezed, same pattern as `AppUser`. Stored fields mirror Firestore schema from CLAUDE.md.

```dart
@freezed
class Child with _$Child {
  const Child._();
  const factory Child({
    required String id,
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    String? avatarUrl,
    String? allergies,
    String? medicalInfo,
    String? notes,
    required bool archived,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Child;

  factory Child.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }

  int get ageInYears => ...;   // calculated from birthDate to today
  String get ageLabel => ...;  // "3 ans" / "8 mois" / "Nouveau-né"
}
```

Firestore field mapping: snake_case keys (`first_name` etc. → no, CLAUDE.md uses camelCase for Firestore fields based on the schema). Fields: `parentId`, `firstName`, `lastName`, `birthDate`, `avatarUrl`, `allergies`, `medicalInfo`, `notes`, `archived`, `createdAt`, `updatedAt`.

### `ChildRepository`

Pure Dart class, injected via Riverpod. Holds `FirebaseFirestore` and `FirebaseStorage` instances.

| Method | Description |
|---|---|
| `Stream<List<Child>> watchChildren(String parentId)` | Firestore stream, filters `archived == false`, ordered by `createdAt DESC` |
| `Future<void> addChild({required fields}, File? photo)` | Auto-generates Firestore ID, uploads photo if provided, writes doc |
| `Future<void> updateChild(Child child, File? photo)` | Updates doc fields + `updatedAt`, replaces photo if provided |
| `Future<void> deleteChild(String childId)` | Checks for guard_requests → soft or hard delete (see below) |

**Photo storage path**: `avatars/children/{childId}.jpg`

**Soft delete logic** (`deleteChild`):
1. Query `guard_requests` where `childId == id` (limit 1)
2. If any found → `update({archived: true, updatedAt: now})`
3. If none → delete Firestore doc + delete Storage file (best-effort, ignore 404)

Note: at Sprint 2, `guard_requests` collection is empty so all deletes are physical. The logic is correct from day 1 and will work transparently in Sprint 4.

---

## Section 2 — Providers & Navigation

### Providers

```dart
// lib/features/children/providers/children_providers.dart

final childRepositoryProvider = Provider<ChildRepository>(
  (ref) => ChildRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  ),
);

final childrenProvider = StreamProvider<List<Child>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(childRepositoryProvider).watchChildren(user.uid);
});

final childDetailProvider = StreamProvider.family<Child?, String>((ref, childId) {
  return ref.read(childRepositoryProvider).watchChild(childId);
});
```

`watchChild(String id)` added to repository — single-doc stream used by `ChildDetailScreen`.

### Routes added to `app_router.dart`

```
/children              → ChildrenListScreen
/children/:id          → ChildDetailScreen
/children/:id/edit     → EditChildScreen
```

`AddChildBottomSheet` has no route — opened via `showModalBottomSheet` from `ChildrenListScreen`.

### Navigation from `HomePlaceholderScreen`

Add a "Mes enfants" button/card that pushes to `/children`. Will be replaced by a proper bottom nav ShellRoute in a later sprint (Sprint 3 or 4 once multiple tabs exist).

### Firestore rules

Update `firestore.rules` with children rules (as specified in CLAUDE.md) and deploy with `firebase deploy --only firestore:rules`.

```js
match /children/{childId} {
  allow read, write: if isAuth() && isOwner(resource.data.parentId);
  allow create: if isAuth() && isOwner(request.resource.data.parentId);
}
```

---

## Section 3 — Screens & Widgets

### `ChildrenListScreen` (`/children`)

- `AppBar`: "Mes enfants", back arrow to Home
- Body: `ref.watch(childrenProvider)` → three states:
  - Loading: `CircularProgressIndicator`
  - Empty: centered illustration + "Ajoutez votre premier enfant"
  - List: `ListView` of `ChildCard`
- FAB `+` → `showModalBottomSheet(context, builder: (_) => AddChildBottomSheet())`

### `AddChildBottomSheet`

- `DraggableScrollableSheet` or fixed height
- Required fields: photo picker (optional), prénom*, nom*, date de naissance* (DatePicker)
- Optional section (collapsed by default): allergies, infos médicales, notes
- "Ajouter" button → calls `childRepository.addChild(...)` → closes sheet on success
- Error handling: SnackBar on failure

### `ChildDetailScreen` (`/children/:id`)

- Header: `CircleAvatar` large (120px) with photo or initials
- Body: full name (H5), age label, sections for allergies / infos médicales / notes (only if non-null/non-empty)
- Actions (bottom or AppBar): "Modifier" → push `/children/:id/edit`, "Supprimer" → confirmation dialog → `deleteChild`
- Confirmation dialog: "Supprimer [prénom] ?" with destructive red button

### `EditChildScreen` (`/children/:id/edit`)

- Pre-populated form with current child data
- Same fields as `AddChildBottomSheet` but full-screen
- Photo: shows current photo, tap to replace
- "Enregistrer" button → `updateChild` → pop on success

### `ChildCard` (widget)

```
[ CircleAvatar 48px ] [ Prénom Nom ]
                       [ 3 ans      ]
```

- Photo or initials fallback (first letters of firstName + lastName)
- Tap → `context.push('/children/${child.id}')`

---

## Section 4 — Tests

### Unit tests (`test/features/children/`)

**`child_model_test.dart`**
- `fromFirestore` parses all fields correctly
- `toFirestore` produces correct map
- `ageInYears` correct for various birthdates
- `ageLabel` returns "X ans" / "X mois" / "Nouveau-né"

**`child_repository_test.dart`** (using `fake_cloud_firestore`)
- `watchChildren` returns only non-archived children for the given parentId
- `addChild` creates doc with correct fields
- `updateChild` updates fields and `updatedAt`
- `deleteChild` soft-deletes when guard_request exists, hard-deletes when none

---

## File Structure

```
lib/features/children/
├── models/
│   ├── child.dart
│   └── child.freezed.dart          # generated
├── providers/
│   └── children_providers.dart
├── repository/
│   └── child_repository.dart
├── screens/
│   ├── children_list_screen.dart
│   ├── child_detail_screen.dart
│   └── edit_child_screen.dart
└── widgets/
    ├── child_card.dart
    └── add_child_bottom_sheet.dart

test/features/children/
├── child_model_test.dart
└── child_repository_test.dart
```

---

## Out of Scope (Sprint 2)

- Bottom nav ShellRoute (Sprint 3+)
- `childSnapshot` denormalization update when profile changes (Sprint 4, Cloud Function)
- Child avatar shown in guard_request cards (Sprint 4)
