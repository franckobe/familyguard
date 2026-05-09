# Sprint 2 — Children Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** CRUD complet pour les profils enfants — modèle Firestore, repository, 4 écrans (liste, détail, ajout bottom sheet, édition), navigation et règles Firestore.

**Architecture:** `ChildRepository` (classe Dart pure, injectable via Riverpod) encapsule toutes les opérations Firestore/Storage. Les écrans consomment `childrenProvider` (StreamProvider temps réel) et appellent le repo pour les mutations. Navigation push-based via go_router, pas de ShellRoute à ce stade.

**Tech Stack:** Flutter, Riverpod 2, Cloud Firestore, Firebase Storage, freezed, go_router, image_picker, cached_network_image, fake_cloud_firestore (tests), mocktail (tests), intl.

---

## File Map

**New files:**
- `lib/features/children/models/child.dart`
- `lib/features/children/models/child.freezed.dart` ← généré par build_runner
- `lib/features/children/repository/child_repository.dart`
- `lib/features/children/providers/children_providers.dart`
- `lib/features/children/screens/children_list_screen.dart`
- `lib/features/children/screens/child_detail_screen.dart`
- `lib/features/children/screens/edit_child_screen.dart`
- `lib/features/children/widgets/child_card.dart`
- `lib/features/children/widgets/add_child_bottom_sheet.dart`
- `test/features/children/child_model_test.dart`
- `test/features/children/child_repository_test.dart`

**Modified files:**
- `lib/main.dart` — ajouter `initializeDateFormatting('fr')`
- `lib/core/router/app_router.dart` — ajouter routes `/children`, `/children/:id`, `/children/:id/edit`
- `lib/core/router/home_placeholder_screen.dart` — ajouter bouton "Mes enfants"
- `firestore.rules` — ajouter règles `/children`
- `firestore.indexes.json` — ajouter index composite pour `watchChildren`

---

### Task 1: Child model (freezed) + unit tests

**Files:**
- Create: `lib/features/children/models/child.dart`
- Create: `lib/features/children/models/child.freezed.dart` (généré)
- Create: `test/features/children/child_model_test.dart`

- [ ] **Step 1: Écrire les tests en premier**

Créer `test/features/children/child_model_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyguard/features/children/models/child.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() => fakeFirestore = FakeFirebaseFirestore());

  Future<DocumentSnapshot> addDoc(String id, Map<String, dynamic> data) async {
    final ref = fakeFirestore.collection('children').doc(id);
    await ref.set(data);
    return ref.get();
  }

  final baseDate = DateTime(2020, 6, 15);
  final baseNow = DateTime(2024, 1, 1);

  Map<String, dynamic> baseData({bool archived = false}) => {
    'parentId': 'parent-1',
    'firstName': 'Alice',
    'lastName': 'Dupont',
    'birthDate': Timestamp.fromDate(baseDate),
    'avatarUrl': 'https://example.com/photo.jpg',
    'allergies': 'Cacahuètes',
    'medicalInfo': null,
    'notes': null,
    'archived': archived,
    'createdAt': Timestamp.fromDate(baseNow),
    'updatedAt': Timestamp.fromDate(baseNow),
  };

  group('Child.fromFirestore', () {
    test('parses all fields correctly', () async {
      final doc = await addDoc('child-1', baseData());
      final child = Child.fromFirestore(doc);

      expect(child.id, 'child-1');
      expect(child.parentId, 'parent-1');
      expect(child.firstName, 'Alice');
      expect(child.lastName, 'Dupont');
      expect(child.birthDate, baseDate);
      expect(child.avatarUrl, 'https://example.com/photo.jpg');
      expect(child.allergies, 'Cacahuètes');
      expect(child.medicalInfo, isNull);
      expect(child.archived, false);
      expect(child.createdAt, baseNow);
    });

    test('handles null optional fields', () async {
      final doc = await addDoc('child-2', {
        ...baseData(),
        'avatarUrl': null,
        'allergies': null,
      });
      final child = Child.fromFirestore(doc);
      expect(child.avatarUrl, isNull);
      expect(child.allergies, isNull);
    });
  });

  group('Child.toFirestore', () {
    test('produces correct map', () {
      final child = Child(
        id: 'child-1',
        parentId: 'parent-1',
        firstName: 'Alice',
        lastName: 'Dupont',
        birthDate: baseDate,
        archived: false,
        createdAt: baseNow,
        updatedAt: baseNow,
      );
      final map = child.toFirestore();
      expect(map['parentId'], 'parent-1');
      expect(map['firstName'], 'Alice');
      expect(map['archived'], false);
      expect(map['birthDate'], Timestamp.fromDate(baseDate));
      expect(map['avatarUrl'], isNull);
      expect(map['allergies'], isNull);
    });
  });

  group('Child.ageInYears', () {
    test('returns 0 for newborn', () {
      final child = Child(
        id: 't', parentId: 'p', firstName: 'T', lastName: 'T',
        birthDate: DateTime.now(), archived: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(child.ageInYears, 0);
    });

    test('returns correct age for multi-year-old', () {
      final fiveYearsAgo = DateTime(DateTime.now().year - 5, 1, 1);
      final child = Child(
        id: 't', parentId: 'p', firstName: 'T', lastName: 'T',
        birthDate: fiveYearsAgo, archived: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(child.ageInYears, greaterThanOrEqualTo(5));
    });
  });

  group('Child.ageLabel', () {
    test('returns "Nouveau-né" for newborn', () {
      final child = Child(
        id: 't', parentId: 'p', firstName: 'T', lastName: 'T',
        birthDate: DateTime.now(), archived: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(child.ageLabel, 'Nouveau-né');
    });

    test('returns "X mois" for child under 1 year', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 180));
      final child = Child(
        id: 't', parentId: 'p', firstName: 'T', lastName: 'T',
        birthDate: birthDate, archived: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(child.ageLabel, contains('mois'));
    });

    test('returns "X ans" for child over 1 year', () {
      final birthDate = DateTime(DateTime.now().year - 5, 1, 1);
      final child = Child(
        id: 't', parentId: 'p', firstName: 'T', lastName: 'T',
        birthDate: birthDate, archived: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(child.ageLabel, contains('ans'));
    });
  });
}
```

- [ ] **Step 2: Lancer les tests — vérifier qu'ils échouent**

```bash
flutter test test/features/children/child_model_test.dart
```
Attendu : erreur de compilation (`Child` non défini).

- [ ] **Step 3: Créer `lib/features/children/models/child.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'child.freezed.dart';

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

  factory Child.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Child(
      id: doc.id,
      parentId: data['parentId'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'] as String?,
      allergies: data['allergies'] as String?,
      medicalInfo: data['medicalInfo'] as String?,
      notes: data['notes'] as String?,
      archived: data['archived'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'parentId': parentId,
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': Timestamp.fromDate(birthDate),
    'avatarUrl': avatarUrl,
    'allergies': allergies,
    'medicalInfo': medicalInfo,
    'notes': notes,
    'archived': archived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  String get ageLabel {
    final now = DateTime.now();
    final months =
        (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (months < 1) return 'Nouveau-né';
    if (months < 12) return '$months mois';
    return '$ageInYears ans';
  }
}
```

- [ ] **Step 4: Générer le code freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Attendu : `lib/features/children/models/child.freezed.dart` créé.

- [ ] **Step 5: Lancer les tests — vérifier qu'ils passent**

```bash
flutter test test/features/children/child_model_test.dart
```
Attendu : `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/children/models/ test/features/children/child_model_test.dart
git commit -m "feat: add Child model (freezed) + unit tests"
```

---

### Task 2: ChildRepository + unit tests

**Files:**
- Create: `lib/features/children/repository/child_repository.dart`
- Create: `test/features/children/child_repository_test.dart`

- [ ] **Step 1: Écrire les tests en premier**

Créer `test/features/children/child_repository_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:familyguard/features/children/models/child.dart';
import 'package:familyguard/features/children/repository/child_repository.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockReference extends Mock implements Reference {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;
  late ChildRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();
    when(() => mockStorage.ref(any())).thenReturn(mockRef);
    when(() => mockRef.delete()).thenAnswer((_) async {});
    repo = ChildRepository(firestore: fakeFirestore, storage: mockStorage);
  });

  Future<void> seedChild(
    String id,
    String parentId, {
    bool archived = false,
  }) async {
    final now = DateTime(2024, 1, 1);
    await fakeFirestore.collection('children').doc(id).set({
      'parentId': parentId,
      'firstName': 'Alice',
      'lastName': 'Dupont',
      'birthDate': Timestamp.fromDate(DateTime(2020, 1, 1)),
      'avatarUrl': null,
      'allergies': null,
      'medicalInfo': null,
      'notes': null,
      'archived': archived,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  group('watchChildren', () {
    test('returns only non-archived children for given parentId', () async {
      await seedChild('c1', 'parent-1');
      await seedChild('c2', 'parent-1', archived: true);
      await seedChild('c3', 'parent-2');

      final children = await repo.watchChildren('parent-1').first;
      expect(children.length, 1);
      expect(children.first.id, 'c1');
    });

    test('returns empty list when no children', () async {
      final children = await repo.watchChildren('parent-1').first;
      expect(children, isEmpty);
    });
  });

  group('watchChild', () {
    test('returns null when document does not exist', () async {
      final child = await repo.watchChild('nonexistent').first;
      expect(child, isNull);
    });

    test('returns child when document exists', () async {
      await seedChild('c1', 'parent-1');
      final child = await repo.watchChild('c1').first;
      expect(child, isNotNull);
      expect(child!.id, 'c1');
    });
  });

  group('addChild', () {
    test('creates Firestore document with correct fields', () async {
      await repo.addChild(
        parentId: 'parent-1',
        firstName: 'Bob',
        lastName: 'Martin',
        birthDate: DateTime(2021, 3, 15),
        allergies: 'Gluten',
      );

      final snap = await fakeFirestore.collection('children').get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['firstName'], 'Bob');
      expect(data['lastName'], 'Martin');
      expect(data['parentId'], 'parent-1');
      expect(data['allergies'], 'Gluten');
      expect(data['archived'], false);
      expect(data['avatarUrl'], isNull);
    });
  });

  group('updateChild', () {
    test('updates firstName and updatedAt', () async {
      await seedChild('c1', 'parent-1');
      final doc = await fakeFirestore.collection('children').doc('c1').get();
      final child = Child.fromFirestore(doc);

      await repo.updateChild(child.copyWith(firstName: 'Alicia'));

      final updated = await fakeFirestore.collection('children').doc('c1').get();
      expect(updated.data()!['firstName'], 'Alicia');
    });
  });

  group('deleteChild', () {
    test('hard-deletes when no guard_requests exist', () async {
      await seedChild('c1', 'parent-1');

      await repo.deleteChild('c1');

      final doc = await fakeFirestore.collection('children').doc('c1').get();
      expect(doc.exists, false);
    });

    test('soft-deletes (archived=true) when guard_requests exist', () async {
      await seedChild('c1', 'parent-1');
      await fakeFirestore
          .collection('guard_requests')
          .add({'childId': 'c1'});

      await repo.deleteChild('c1');

      final doc = await fakeFirestore.collection('children').doc('c1').get();
      expect(doc.exists, true);
      expect(doc.data()!['archived'], true);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests — vérifier qu'ils échouent**

```bash
flutter test test/features/children/child_repository_test.dart
```
Attendu : erreur de compilation (`ChildRepository` non défini).

- [ ] **Step 3: Créer `lib/features/children/repository/child_repository.dart`**

```dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/child.dart';

class ChildRepository {
  const ChildRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<Child>> watchChildren(String parentId) {
    return _firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .where('archived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Child.fromFirestore).toList());
  }

  Stream<Child?> watchChild(String id) {
    return _firestore
        .collection('children')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Child.fromFirestore(doc) : null);
  }

  Future<void> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    String? allergies,
    String? medicalInfo,
    String? notes,
    File? photo,
  }) async {
    final ref = _firestore.collection('children').doc();
    final now = DateTime.now();
    String? avatarUrl;
    if (photo != null) {
      avatarUrl = await _uploadPhoto(ref.id, photo);
    }
    await ref.set({
      'parentId': parentId,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': Timestamp.fromDate(birthDate),
      'avatarUrl': avatarUrl,
      'allergies': allergies,
      'medicalInfo': medicalInfo,
      'notes': notes,
      'archived': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateChild(Child child, {File? photo}) async {
    String? avatarUrl = child.avatarUrl;
    if (photo != null) {
      avatarUrl = await _uploadPhoto(child.id, photo);
    }
    await _firestore.collection('children').doc(child.id).update({
      'firstName': child.firstName,
      'lastName': child.lastName,
      'birthDate': Timestamp.fromDate(child.birthDate),
      'avatarUrl': avatarUrl,
      'allergies': child.allergies,
      'medicalInfo': child.medicalInfo,
      'notes': child.notes,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteChild(String childId) async {
    final guardReqs = await _firestore
        .collection('guard_requests')
        .where('childId', isEqualTo: childId)
        .limit(1)
        .get();

    if (guardReqs.docs.isNotEmpty) {
      await _firestore.collection('children').doc(childId).update({
        'archived': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      await _firestore.collection('children').doc(childId).delete();
      try {
        await _storage.ref('avatars/children/$childId.jpg').delete();
      } catch (_) {}
    }
  }

  Future<String> _uploadPhoto(String childId, File photo) async {
    final ref = _storage.ref('avatars/children/$childId.jpg');
    await ref.putFile(photo);
    return ref.getDownloadURL();
  }
}
```

- [ ] **Step 4: Lancer les tests — vérifier qu'ils passent**

```bash
flutter test test/features/children/child_repository_test.dart
```
Attendu : `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/children/repository/ test/features/children/child_repository_test.dart
git commit -m "feat: add ChildRepository + unit tests"
```

---

### Task 3: Children providers + Firestore index

**Files:**
- Create: `lib/features/children/providers/children_providers.dart`
- Modify: `firestore.indexes.json`

- [ ] **Step 1: Créer `lib/features/children/providers/children_providers.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/child.dart';
import '../repository/child_repository.dart';

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

- [ ] **Step 2: Mettre à jour `firestore.indexes.json`**

La requête `watchChildren` (parentId + archived + orderBy createdAt) nécessite un index composite en production.

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
    }
  ],
  "fieldOverrides": []
}
```

- [ ] **Step 3: Vérifier l'analyse statique**

```bash
dart analyze lib/features/children/providers/
```
Attendu : `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/children/providers/ firestore.indexes.json
git commit -m "feat: add children providers + Firestore composite index"
```

---

### Task 4: ChildCard widget

**Files:**
- Create: `lib/features/children/widgets/child_card.dart`

- [ ] **Step 1: Créer `lib/features/children/widgets/child_card.dart`**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/child.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: child.avatarUrl != null
            ? CachedNetworkImageProvider(child.avatarUrl!)
            : null,
        child: child.avatarUrl == null
            ? Text(
                '${child.firstName[0]}${child.lastName[0]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text('${child.firstName} ${child.lastName}'),
      subtitle: Text(child.ageLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/children/${child.id}'),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

```bash
dart analyze lib/features/children/widgets/child_card.dart
```
Attendu : `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/children/widgets/child_card.dart
git commit -m "feat: add ChildCard widget"
```

---

### Task 5: AddChildBottomSheet

**Files:**
- Create: `lib/features/children/widgets/add_child_bottom_sheet.dart`

- [ ] **Step 1: Créer `lib/features/children/widgets/add_child_bottom_sheet.dart`**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/children_providers.dart';

class AddChildBottomSheet extends ConsumerStatefulWidget {
  const AddChildBottomSheet({super.key});

  @override
  ConsumerState<AddChildBottomSheet> createState() =>
      _AddChildBottomSheetState();
}

class _AddChildBottomSheetState extends ConsumerState<AddChildBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicalInfoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _birthDate;
  File? _photo;
  bool _loading = false;
  bool _showOptional = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicalInfoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile != null) setState(() => _photo = File(xFile.path));
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime(DateTime.now().year - 18),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de naissance'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull!;
      await ref.read(childRepositoryProvider).addChild(
        parentId: user.uid,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        birthDate: _birthDate!,
        allergies: _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.trim(),
        medicalInfo: _medicalInfoCtrl.text.trim().isEmpty
            ? null
            : _medicalInfoCtrl.text.trim(),
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        photo: _photo,
      );
      if (mounted) Navigator.of(context).pop();
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        _photo != null ? FileImage(_photo!) : null,
                    child: _photo == null
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Prénom *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Nom *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _birthDate == null
                      ? 'Date de naissance *'
                      : DateFormat('d MMMM yyyy', 'fr').format(_birthDate!),
                  style: _birthDate == null
                      ? TextStyle(color: Colors.grey[600])
                      : null,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthDate,
              ),
              const Divider(),
              TextButton(
                onPressed: () =>
                    setState(() => _showOptional = !_showOptional),
                child: Text(
                  _showOptional
                      ? 'Masquer les détails'
                      : 'Ajouter des détails (allergies, notes…)',
                ),
              ),
              if (_showOptional) ...[
                TextFormField(
                  controller: _allergiesCtrl,
                  decoration: const InputDecoration(labelText: 'Allergies'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _medicalInfoCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Informations médicales'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ajouter'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

```bash
dart analyze lib/features/children/widgets/add_child_bottom_sheet.dart
```
Attendu : `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/children/widgets/add_child_bottom_sheet.dart
git commit -m "feat: add AddChildBottomSheet"
```

---

### Task 6: ChildrenListScreen

**Files:**
- Create: `lib/features/children/screens/children_list_screen.dart`

- [ ] **Step 1: Créer `lib/features/children/screens/children_list_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/children_providers.dart';
import '../widgets/add_child_bottom_sheet.dart';
import '../widgets/child_card.dart';

class ChildrenListScreen extends ConsumerWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes enfants')),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (children) {
          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun enfant',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier enfant',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (_, i) => ChildCard(child: children[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AddChildBottomSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

```bash
dart analyze lib/features/children/screens/children_list_screen.dart
```
Attendu : `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/children/screens/children_list_screen.dart
git commit -m "feat: add ChildrenListScreen"
```

---

### Task 7: ChildDetailScreen

**Files:**
- Create: `lib/features/children/screens/child_detail_screen.dart`

- [ ] **Step 1: Créer `lib/features/children/screens/child_detail_screen.dart`**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/child.dart';
import '../providers/children_providers.dart';

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Child child,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${child.firstName} ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(childRepositoryProvider).deleteChild(child.id);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(childDetailProvider(childId));

    return childAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (child) {
        if (child == null) {
          return const Scaffold(
            body: Center(child: Text('Enfant introuvable')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${child.firstName} ${child.lastName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.push('/children/${child.id}/edit', extra: child),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: child.avatarUrl != null
                      ? CachedNetworkImageProvider(child.avatarUrl!)
                      : null,
                  child: child.avatarUrl == null
                      ? Text(
                          '${child.firstName[0]}${child.lastName[0]}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  child.ageLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (child.allergies != null) ...[
                  _InfoTile(label: 'Allergies', value: child.allergies!),
                  const SizedBox(height: 8),
                ],
                if (child.medicalInfo != null) ...[
                  _InfoTile(
                    label: 'Informations médicales',
                    value: child.medicalInfo!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (child.notes != null) ...[
                  _InfoTile(label: 'Notes', value: child.notes!),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref, child),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

```bash
dart analyze lib/features/children/screens/child_detail_screen.dart
```
Attendu : `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/children/screens/child_detail_screen.dart
git commit -m "feat: add ChildDetailScreen"
```

---

### Task 8: EditChildScreen

**Files:**
- Create: `lib/features/children/screens/edit_child_screen.dart`

- [ ] **Step 1: Créer `lib/features/children/screens/edit_child_screen.dart`**

```dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/child.dart';
import '../providers/children_providers.dart';

class EditChildScreen extends ConsumerStatefulWidget {
  const EditChildScreen({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends ConsumerState<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _medicalInfoCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _birthDate;
  File? _newPhoto;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.child;
    _firstNameCtrl = TextEditingController(text: c.firstName);
    _lastNameCtrl = TextEditingController(text: c.lastName);
    _allergiesCtrl = TextEditingController(text: c.allergies ?? '');
    _medicalInfoCtrl = TextEditingController(text: c.medicalInfo ?? '');
    _notesCtrl = TextEditingController(text: c.notes ?? '');
    _birthDate = c.birthDate;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicalInfoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile != null) setState(() => _newPhoto = File(xFile.path));
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(DateTime.now().year - 18),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final updated = widget.child.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        birthDate: _birthDate,
        allergies: _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.trim(),
        medicalInfo: _medicalInfoCtrl.text.trim().isEmpty
            ? null
            : _medicalInfoCtrl.text.trim(),
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await ref
          .read(childRepositoryProvider)
          .updateChild(updated, photo: _newPhoto);
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
    final currentAvatarUrl = widget.child.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _newPhoto != null
                        ? FileImage(_newPhoto!) as ImageProvider
                        : currentAvatarUrl != null
                            ? CachedNetworkImageProvider(currentAvatarUrl)
                            : null,
                    child: (_newPhoto == null && currentAvatarUrl == null)
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Prénom'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  DateFormat('d MMMM yyyy', 'fr').format(_birthDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthDate,
              ),
              const Divider(),
              TextFormField(
                controller: _allergiesCtrl,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medicalInfoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Informations médicales',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier l'analyse statique**

```bash
dart analyze lib/features/children/screens/edit_child_screen.dart
```
Attendu : `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/children/screens/edit_child_screen.dart
git commit -m "feat: add EditChildScreen"
```

---

### Task 9: Router, HomePlaceholder et intl

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/core/router/home_placeholder_screen.dart`

- [ ] **Step 1: Mettre à jour `lib/main.dart` — initialiser les locales intl**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr');
  runApp(const ProviderScope(child: FamilyGuardApp()));
}

class FamilyGuardApp extends ConsumerWidget {
  const FamilyGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FamilyGuard',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Mettre à jour `lib/core/router/app_router.dart` — ajouter les 3 routes children**

Ajouter les imports en haut du fichier (après les imports existants) :

```dart
import '../../features/children/models/child.dart';
import '../../features/children/screens/child_detail_screen.dart';
import '../../features/children/screens/children_list_screen.dart';
import '../../features/children/screens/edit_child_screen.dart';
```

Ajouter dans la liste `routes:` (après la route `/profile/edit`) :

```dart
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
```

- [ ] **Step 3: Mettre à jour `lib/core/router/home_placeholder_screen.dart` — ajouter bouton navigation**

Remplacer le `Text('Sprint 2 à venir — Gestion des enfants')` par :

```dart
ElevatedButton.icon(
  onPressed: () => context.push('/children'),
  icon: const Icon(Icons.child_care),
  label: const Text('Mes enfants'),
),
```

- [ ] **Step 4: Vérifier l'analyse statique globale**

```bash
dart analyze lib/
```
Attendu : `No issues found!`

- [ ] **Step 5: Lancer tous les tests**

```bash
flutter test
```
Attendu : `All tests passed!` (tests Dart uniquement : 3 AppUser + ~8 child_model + ~8 child_repository = ~19 tests. Les tests TS Cloud Functions se lancent séparément via `npm test` dans `functions/`)

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/core/router/app_router.dart lib/core/router/home_placeholder_screen.dart
git commit -m "feat: wire children routes + intl locale init"
```

---

### Task 10: Firestore rules + déploiement

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Mettre à jour `firestore.rules`**

Remplacer le contenu complet :

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
  }
}
```

- [ ] **Step 2: Déployer les règles et index**

```bash
firebase deploy --only firestore:rules,firestore:indexes --project familyguard-app-e2b30
```
Attendu : `Deploy complete!`

- [ ] **Step 3: Commit**

```bash
git add firestore.rules
git commit -m "feat: add Firestore rules and index for children collection"
```

---

### Task 11: Vérification finale

- [ ] **Step 1: Lancer tous les tests Dart**

```bash
flutter test
```
Attendu : tous les tests passent.

- [ ] **Step 2: Analyse statique complète**

```bash
dart analyze lib/
```
Attendu : `No issues found!`

- [ ] **Step 3: Build web**

```bash
flutter build web
```
Attendu : `✓ Built build/web`

- [ ] **Step 4: Commit final**

```bash
git add -A
git commit -m "feat: Sprint 2 complete — Children CRUD (list, detail, add, edit)"
```
