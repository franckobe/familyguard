import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';

enum ConnectionStatus { pending, active, declined, blocked }

@freezed
class Connection with _$Connection {
  const Connection._();

  const factory Connection({
    required String id,
    required String parentId,
    String? caregiverId,
    required ConnectionStatus status,
    String? inviteCode,
    required String inviteEmail,
    String? message,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Connection;

  factory Connection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Connection(
      id: doc.id,
      parentId: data['parentId'] as String,
      caregiverId: data['caregiverId'] as String?,
      status: ConnectionStatus.values.byName(data['status'] as String),
      inviteCode: data['inviteCode'] as String?,
      inviteEmail: data['inviteEmail'] as String,
      message: data['message'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'parentId': parentId,
    'caregiverId': caregiverId,
    'status': status.name,
    'inviteCode': inviteCode,
    'inviteEmail': inviteEmail,
    'message': message,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
