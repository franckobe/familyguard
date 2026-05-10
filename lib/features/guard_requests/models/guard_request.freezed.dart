// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guard_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GuardRequest {
  String get id => throw _privateConstructorUsedError;
  String get parentId => throw _privateConstructorUsedError;
  List<String> get childIds => throw _privateConstructorUsedError;
  List<ChildSnapshot> get childSnapshots => throw _privateConstructorUsedError;
  GuardRequestType get type => throw _privateConstructorUsedError;
  DateTime get startAt => throw _privateConstructorUsedError;
  DateTime get endAt => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  GuardRequestStatus get status => throw _privateConstructorUsedError;
  RecurrenceType get recurrenceType => throw _privateConstructorUsedError;
  List<String> get recipientIds => throw _privateConstructorUsedError;
  String? get confirmedId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of GuardRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuardRequestCopyWith<GuardRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuardRequestCopyWith<$Res> {
  factory $GuardRequestCopyWith(
    GuardRequest value,
    $Res Function(GuardRequest) then,
  ) = _$GuardRequestCopyWithImpl<$Res, GuardRequest>;
  @useResult
  $Res call({
    String id,
    String parentId,
    List<String> childIds,
    List<ChildSnapshot> childSnapshots,
    GuardRequestType type,
    DateTime startAt,
    DateTime endAt,
    String? location,
    String? notes,
    GuardRequestStatus status,
    RecurrenceType recurrenceType,
    List<String> recipientIds,
    String? confirmedId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$GuardRequestCopyWithImpl<$Res, $Val extends GuardRequest>
    implements $GuardRequestCopyWith<$Res> {
  _$GuardRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuardRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = null,
    Object? childIds = null,
    Object? childSnapshots = null,
    Object? type = null,
    Object? startAt = null,
    Object? endAt = null,
    Object? location = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? recurrenceType = null,
    Object? recipientIds = null,
    Object? confirmedId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            parentId:
                null == parentId
                    ? _value.parentId
                    : parentId // ignore: cast_nullable_to_non_nullable
                        as String,
            childIds:
                null == childIds
                    ? _value.childIds
                    : childIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            childSnapshots:
                null == childSnapshots
                    ? _value.childSnapshots
                    : childSnapshots // ignore: cast_nullable_to_non_nullable
                        as List<ChildSnapshot>,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as GuardRequestType,
            startAt:
                null == startAt
                    ? _value.startAt
                    : startAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            endAt:
                null == endAt
                    ? _value.endAt
                    : endAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            location:
                freezed == location
                    ? _value.location
                    : location // ignore: cast_nullable_to_non_nullable
                        as String?,
            notes:
                freezed == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as GuardRequestStatus,
            recurrenceType:
                null == recurrenceType
                    ? _value.recurrenceType
                    : recurrenceType // ignore: cast_nullable_to_non_nullable
                        as RecurrenceType,
            recipientIds:
                null == recipientIds
                    ? _value.recipientIds
                    : recipientIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            confirmedId:
                freezed == confirmedId
                    ? _value.confirmedId
                    : confirmedId // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuardRequestImplCopyWith<$Res>
    implements $GuardRequestCopyWith<$Res> {
  factory _$$GuardRequestImplCopyWith(
    _$GuardRequestImpl value,
    $Res Function(_$GuardRequestImpl) then,
  ) = __$$GuardRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String parentId,
    List<String> childIds,
    List<ChildSnapshot> childSnapshots,
    GuardRequestType type,
    DateTime startAt,
    DateTime endAt,
    String? location,
    String? notes,
    GuardRequestStatus status,
    RecurrenceType recurrenceType,
    List<String> recipientIds,
    String? confirmedId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$GuardRequestImplCopyWithImpl<$Res>
    extends _$GuardRequestCopyWithImpl<$Res, _$GuardRequestImpl>
    implements _$$GuardRequestImplCopyWith<$Res> {
  __$$GuardRequestImplCopyWithImpl(
    _$GuardRequestImpl _value,
    $Res Function(_$GuardRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuardRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = null,
    Object? childIds = null,
    Object? childSnapshots = null,
    Object? type = null,
    Object? startAt = null,
    Object? endAt = null,
    Object? location = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? recurrenceType = null,
    Object? recipientIds = null,
    Object? confirmedId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$GuardRequestImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        parentId:
            null == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                    as String,
        childIds:
            null == childIds
                ? _value._childIds
                : childIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        childSnapshots:
            null == childSnapshots
                ? _value._childSnapshots
                : childSnapshots // ignore: cast_nullable_to_non_nullable
                    as List<ChildSnapshot>,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as GuardRequestType,
        startAt:
            null == startAt
                ? _value.startAt
                : startAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        endAt:
            null == endAt
                ? _value.endAt
                : endAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        location:
            freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                    as String?,
        notes:
            freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as GuardRequestStatus,
        recurrenceType:
            null == recurrenceType
                ? _value.recurrenceType
                : recurrenceType // ignore: cast_nullable_to_non_nullable
                    as RecurrenceType,
        recipientIds:
            null == recipientIds
                ? _value._recipientIds
                : recipientIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        confirmedId:
            freezed == confirmedId
                ? _value.confirmedId
                : confirmedId // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$GuardRequestImpl extends _GuardRequest {
  const _$GuardRequestImpl({
    required this.id,
    required this.parentId,
    required final List<String> childIds,
    required final List<ChildSnapshot> childSnapshots,
    required this.type,
    required this.startAt,
    required this.endAt,
    this.location,
    this.notes,
    required this.status,
    required this.recurrenceType,
    required final List<String> recipientIds,
    this.confirmedId,
    required this.createdAt,
    required this.updatedAt,
  }) : _childIds = childIds,
       _childSnapshots = childSnapshots,
       _recipientIds = recipientIds,
       super._();

  @override
  final String id;
  @override
  final String parentId;
  final List<String> _childIds;
  @override
  List<String> get childIds {
    if (_childIds is EqualUnmodifiableListView) return _childIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_childIds);
  }

  final List<ChildSnapshot> _childSnapshots;
  @override
  List<ChildSnapshot> get childSnapshots {
    if (_childSnapshots is EqualUnmodifiableListView) return _childSnapshots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_childSnapshots);
  }

  @override
  final GuardRequestType type;
  @override
  final DateTime startAt;
  @override
  final DateTime endAt;
  @override
  final String? location;
  @override
  final String? notes;
  @override
  final GuardRequestStatus status;
  @override
  final RecurrenceType recurrenceType;
  final List<String> _recipientIds;
  @override
  List<String> get recipientIds {
    if (_recipientIds is EqualUnmodifiableListView) return _recipientIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipientIds);
  }

  @override
  final String? confirmedId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'GuardRequest(id: $id, parentId: $parentId, childIds: $childIds, childSnapshots: $childSnapshots, type: $type, startAt: $startAt, endAt: $endAt, location: $location, notes: $notes, status: $status, recurrenceType: $recurrenceType, recipientIds: $recipientIds, confirmedId: $confirmedId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuardRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            const DeepCollectionEquality().equals(other._childIds, _childIds) &&
            const DeepCollectionEquality().equals(
              other._childSnapshots,
              _childSnapshots,
            ) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.endAt, endAt) || other.endAt == endAt) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.recurrenceType, recurrenceType) ||
                other.recurrenceType == recurrenceType) &&
            const DeepCollectionEquality().equals(
              other._recipientIds,
              _recipientIds,
            ) &&
            (identical(other.confirmedId, confirmedId) ||
                other.confirmedId == confirmedId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    parentId,
    const DeepCollectionEquality().hash(_childIds),
    const DeepCollectionEquality().hash(_childSnapshots),
    type,
    startAt,
    endAt,
    location,
    notes,
    status,
    recurrenceType,
    const DeepCollectionEquality().hash(_recipientIds),
    confirmedId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of GuardRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuardRequestImplCopyWith<_$GuardRequestImpl> get copyWith =>
      __$$GuardRequestImplCopyWithImpl<_$GuardRequestImpl>(this, _$identity);
}

abstract class _GuardRequest extends GuardRequest {
  const factory _GuardRequest({
    required final String id,
    required final String parentId,
    required final List<String> childIds,
    required final List<ChildSnapshot> childSnapshots,
    required final GuardRequestType type,
    required final DateTime startAt,
    required final DateTime endAt,
    final String? location,
    final String? notes,
    required final GuardRequestStatus status,
    required final RecurrenceType recurrenceType,
    required final List<String> recipientIds,
    final String? confirmedId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$GuardRequestImpl;
  const _GuardRequest._() : super._();

  @override
  String get id;
  @override
  String get parentId;
  @override
  List<String> get childIds;
  @override
  List<ChildSnapshot> get childSnapshots;
  @override
  GuardRequestType get type;
  @override
  DateTime get startAt;
  @override
  DateTime get endAt;
  @override
  String? get location;
  @override
  String? get notes;
  @override
  GuardRequestStatus get status;
  @override
  RecurrenceType get recurrenceType;
  @override
  List<String> get recipientIds;
  @override
  String? get confirmedId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of GuardRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuardRequestImplCopyWith<_$GuardRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
