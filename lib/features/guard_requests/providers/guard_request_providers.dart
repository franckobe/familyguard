import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/guard_request.dart';
import '../models/guard_response.dart';
import '../repository/guard_request_repository.dart';

final guardRequestRepositoryProvider = Provider<GuardRequestRepository>(
  (ref) => GuardRequestRepository(firestore: FirebaseFirestore.instance),
);

final guardRequestsAsParentProvider = StreamProvider<List<GuardRequest>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(guardRequestRepositoryProvider).streamAsParent(user.uid);
});

final guardRequestsAsCaregiverProvider = StreamProvider<List<GuardRequest>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(guardRequestRepositoryProvider).streamAsCaregiver(user.uid);
});

final guardResponsesProvider =
    StreamProvider.family<List<GuardResponse>, String>((ref, requestId) {
  return ref.read(guardRequestRepositoryProvider).streamResponses(requestId);
});
