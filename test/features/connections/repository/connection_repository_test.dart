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
