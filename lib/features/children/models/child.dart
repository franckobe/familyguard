import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'child.freezed.dart';

@freezed
class Child with _$Child {
  const Child._();

  const factory Child({
    required String id,
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    String? avatarUrl,
    String? allergies,
    String? medicalInfo,
    String? notes,
    required bool archived,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Child;

  factory Child.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Child(
      id: doc.id,
      parentId: data['parentId'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'] as String?,
      allergies: data['allergies'] as String?,
      medicalInfo: data['medicalInfo'] as String?,
      notes: data['notes'] as String?,
      archived: data['archived'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'parentId': parentId,
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': Timestamp.fromDate(birthDate),
    'avatarUrl': avatarUrl,
    'allergies': allergies,
    'medicalInfo': medicalInfo,
    'notes': notes,
    'archived': archived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  String get ageLabel {
    final now = DateTime.now();
    final months =
        (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (months < 1) return 'Nouveau-né';
    if (months < 12) return '$months mois';
    return '$ageInYears ans';
  }
}
