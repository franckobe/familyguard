import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyguard/features/auth/models/app_user.dart';

void main() {
  group('AppUser', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('fromFirestore parses a Firestore document correctly', () async {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      await fakeFirestore.collection('users').doc('uid123').set({
        'uid': 'uid123',
        'email': 'test@example.com',
        'firstName': 'Alice',
        'lastName': 'Dupont',
        'phone': '+33612345678',
        'avatarUrl': null,
        'fcmToken': null,
        'createdAt': Timestamp.fromDate(now),
      });

      final doc = await fakeFirestore.collection('users').doc('uid123').get();
      final user = AppUser.fromFirestore(doc);

      expect(user.uid, 'uid123');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Alice');
      expect(user.lastName, 'Dupont');
      expect(user.phone, '+33612345678');
      expect(user.avatarUrl, isNull);
      expect(user.createdAt, now);
    });

    test('toFirestore produces correct map', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final user = AppUser(
        uid: 'uid123',
        email: 'test@example.com',
        firstName: 'Alice',
        lastName: 'Dupont',
        phone: null,
        avatarUrl: null,
        fcmToken: null,
        createdAt: now,
      );

      final map = user.toFirestore();

      expect(map['uid'], 'uid123');
      expect(map['email'], 'test@example.com');
      expect(map['firstName'], 'Alice');
      expect(map['phone'], isNull);
      expect(map['createdAt'], Timestamp.fromDate(now));
    });

    test('equality: two AppUsers with same data are equal', () {
      final now = DateTime(2026, 1, 1);
      final a = AppUser(
        uid: 'u1',
        email: 'a@b.com',
        firstName: 'A',
        lastName: 'B',
        createdAt: now,
      );
      final b = AppUser(
        uid: 'u1',
        email: 'a@b.com',
        firstName: 'A',
        lastName: 'B',
        createdAt: now,
      );
      expect(a, equals(b));
    });
  });
}
