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
