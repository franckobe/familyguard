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
        .snapshots()
        .map((s) => s.docs.map(Connection.fromFirestore).toList());
  }

  Stream<List<Connection>> streamAsCaregiver(String caregiverId) {
    return _firestore
        .collection('connections')
        .where('caregiverId', isEqualTo: caregiverId)
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

  Future<void> updateStatus(
      String connectionId, ConnectionStatus status) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<Connection>> streamPendingByEmail(String email) {
    return _firestore
        .collection('connections')
        .where('inviteEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map(Connection.fromFirestore).toList());
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
