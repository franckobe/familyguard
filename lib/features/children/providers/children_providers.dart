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
