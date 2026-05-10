import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/connection.dart';
import '../repository/connection_repository.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => ConnectionRepository(firestore: FirebaseFirestore.instance),
);

final connectionsAsParentProvider = StreamProvider<List<Connection>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(connectionRepositoryProvider).streamAsParent(user.uid);
});

final connectionsAsCaregiverProvider = StreamProvider<List<Connection>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(connectionRepositoryProvider).streamAsCaregiver(user.uid);
});

final inviteDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, inviteCode) =>
      ref.read(connectionRepositoryProvider).getInviteDetails(inviteCode),
);
