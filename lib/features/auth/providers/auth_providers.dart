import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
});

final userByIdProvider = FutureProvider.family<AppUser?, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return doc.exists ? AppUser.fromFirestore(doc) : null;
});
