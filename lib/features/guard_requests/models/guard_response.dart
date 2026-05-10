import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'guard_response.freezed.dart';

enum GuardResponseStatus { accepted, declined }

class CaregiverSnapshot {
  const CaregiverSnapshot({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String firstName;
  final String lastName;
  final String? avatarUrl;

  factory CaregiverSnapshot.fromMap(Map<String, dynamic> m) => CaregiverSnapshot(
        firstName: m['firstName'] as String,
        lastName: m['lastName'] as String,
        avatarUrl: m['avatarUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
      };
}

@freezed
class GuardResponse with _$GuardResponse {
  const GuardResponse._();

  const factory GuardResponse({
    required String caregiverId,
    required CaregiverSnapshot caregiverSnapshot,
    required GuardResponseStatus status,
    String? message,
    required DateTime respondedAt,
  }) = _GuardResponse;

  factory GuardResponse.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return GuardResponse(
      caregiverId: d['caregiverId'] as String,
      caregiverSnapshot: CaregiverSnapshot.fromMap(d['caregiverSnapshot'] as Map<String, dynamic>),
      status: GuardResponseStatus.values.byName(d['status'] as String),
      message: d['message'] as String?,
      respondedAt: (d['respondedAt'] as Timestamp).toDate(),
    );
  }
}
