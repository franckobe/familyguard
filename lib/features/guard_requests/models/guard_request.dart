import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'guard_request.freezed.dart';

enum GuardRequestType { hourly, halfDay, daily, night, weekend }
enum GuardRequestStatus { open, accepted, done, cancelled, expired }
enum RecurrenceType { none, custom }

class ChildSnapshot {
  const ChildSnapshot({
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final DateTime birthDate;

  factory ChildSnapshot.fromMap(Map<String, dynamic> m) => ChildSnapshot(
        firstName: m['firstName'] as String,
        lastName: m['lastName'] as String,
        avatarUrl: m['avatarUrl'] as String?,
        birthDate: (m['birthDate'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'birthDate': Timestamp.fromDate(birthDate),
      };
}

@freezed
class GuardRequest with _$GuardRequest {
  const GuardRequest._();

  const factory GuardRequest({
    required String id,
    required String parentId,
    required List<String> childIds,
    required List<ChildSnapshot> childSnapshots,
    required GuardRequestType type,
    required DateTime startAt,
    required DateTime endAt,
    String? location,
    String? notes,
    required GuardRequestStatus status,
    required RecurrenceType recurrenceType,
    required List<String> recipientIds,
    String? confirmedId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GuardRequest;

  factory GuardRequest.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;

    // Support both old (single child) and new (multi-child) documents
    final List<String> childIds = d['childIds'] != null
        ? List<String>.from(d['childIds'] as List)
        : [d['childId'] as String];
    final List<ChildSnapshot> childSnapshots = d['childSnapshots'] != null
        ? (d['childSnapshots'] as List)
            .map((m) => ChildSnapshot.fromMap(m as Map<String, dynamic>))
            .toList()
        : [ChildSnapshot.fromMap(d['childSnapshot'] as Map<String, dynamic>)];

    return GuardRequest(
      id: doc.id,
      parentId: d['parentId'] as String,
      childIds: childIds,
      childSnapshots: childSnapshots,
      type: GuardRequestType.values.byName(d['type'] as String),
      startAt: (d['startAt'] as Timestamp).toDate(),
      endAt: (d['endAt'] as Timestamp).toDate(),
      location: d['location'] as String?,
      notes: d['notes'] as String?,
      status: GuardRequestStatus.values.byName(d['status'] as String),
      recurrenceType: RecurrenceType.values.byName(d['recurrenceType'] as String),
      recipientIds: List<String>.from(d['recipientIds'] as List),
      confirmedId: d['confirmedId'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'parentId': parentId,
    'childIds': childIds,
    'childSnapshots': childSnapshots.map((s) => s.toMap()).toList(),
    'type': type.name,
    'startAt': Timestamp.fromDate(startAt),
    'endAt': Timestamp.fromDate(endAt),
    'location': location,
    'notes': notes,
    'status': status.name,
    'recurrenceType': recurrenceType.name,
    'recipientIds': recipientIds,
    'confirmedId': confirmedId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  String get childNamesLabel =>
      childSnapshots.map((s) => s.firstName).join(', ');

  /// Computes guard type from duration between start and end.
  static GuardRequestType typeFromDuration(DateTime start, DateTime end) {
    final hours = end.difference(start).inHours;
    if (hours <= 6) return GuardRequestType.hourly;
    if (hours <= 12) return GuardRequestType.halfDay;
    if (hours <= 30) return GuardRequestType.daily;
    if (hours <= 72) return GuardRequestType.night;
    return GuardRequestType.weekend;
  }

  String get typeLabel => switch (type) {
    GuardRequestType.hourly  => 'Quelques heures',
    GuardRequestType.halfDay => 'Demi-journée',
    GuardRequestType.daily   => 'Journée',
    GuardRequestType.night   => 'Nuit',
    GuardRequestType.weekend => 'Week-end',
  };
}
