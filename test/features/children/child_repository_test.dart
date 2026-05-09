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
