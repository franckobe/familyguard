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
    bool hasGuardRequests = false;
    try {
      final guardReqs = await _firestore
          .collection('guard_requests')
          .where('childId', isEqualTo: childId)
          .limit(1)
          .get();
      hasGuardRequests = guardReqs.docs.isNotEmpty;
    } catch (_) {
      // guard_requests rules not deployed yet (Sprint 4) — treat as empty
    }

    if (hasGuardRequests) {
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
