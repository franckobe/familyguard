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
    required List<String> childIds,
    required List<ChildSnapshot> childSnapshots,
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
      'childIds': childIds,
      'childSnapshots': childSnapshots.map((s) => s.toMap()).toList(),
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
