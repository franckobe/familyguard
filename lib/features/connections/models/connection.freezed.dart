// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Connection {
  String get id => throw _privateConstructorUsedError;
  String get parentId => throw _privateConstructorUsedError;
  String? get caregiverId => throw _privateConstructorUsedError;
  ConnectionStatus get status => throw _privateConstructorUsedError;
  String? get inviteCode => throw _privateConstructorUsedError;
  String get inviteEmail => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionCopyWith<Connection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionCopyWith<$Res> {
  factory $ConnectionCopyWith(
    Connection value,
    $Res Function(Connection) then,
  ) = _$ConnectionCopyWithImpl<$Res, Connection>;
  @useResult
  $Res call({
    String id,
    String parentId,
    String? caregiverId,
    ConnectionStatus status,
    String? inviteCode,
    String inviteEmail,
    String? message,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ConnectionCopyWithImpl<$Res, $Val extends Connection>
    implements $ConnectionCopyWith<$Res> {
  _$ConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = null,
    Object? caregiverId = freezed,
    Object? status = null,
    Object? inviteCode = freezed,
    Object? inviteEmail = null,
    Object? message = freezed,
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
            caregiverId:
                freezed == caregiverId
                    ? _value.caregiverId
                    : caregiverId // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as ConnectionStatus,
            inviteCode:
                freezed == inviteCode
                    ? _value.inviteCode
                    : inviteCode // ignore: cast_nullable_to_non_nullable
                        as String?,
            inviteEmail:
                null == inviteEmail
                    ? _value.inviteEmail
                    : inviteEmail // ignore: cast_nullable_to_non_nullable
                        as String,
            message:
                freezed == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ConnectionImplCopyWith<$Res>
    implements $ConnectionCopyWith<$Res> {
  factory _$$ConnectionImplCopyWith(
    _$ConnectionImpl value,
    $Res Function(_$ConnectionImpl) then,
  ) = __$$ConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String parentId,
    String? caregiverId,
    ConnectionStatus status,
    String? inviteCode,
    String inviteEmail,
    String? message,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ConnectionImplCopyWithImpl<$Res>
    extends _$ConnectionCopyWithImpl<$Res, _$ConnectionImpl>
    implements _$$ConnectionImplCopyWith<$Res> {
  __$$ConnectionImplCopyWithImpl(
    _$ConnectionImpl _value,
    $Res Function(_$ConnectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = null,
    Object? caregiverId = freezed,
    Object? status = null,
    Object? inviteCode = freezed,
    Object? inviteEmail = null,
    Object? message = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ConnectionImpl(
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
        caregiverId:
            freezed == caregiverId
                ? _value.caregiverId
                : caregiverId // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as ConnectionStatus,
        inviteCode:
            freezed == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                    as String?,
        inviteEmail:
            null == inviteEmail
                ? _value.inviteEmail
                : inviteEmail // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
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

class _$ConnectionImpl extends _Connection {
  const _$ConnectionImpl({
    required this.id,
    required this.parentId,
    this.caregiverId,
    required this.status,
    this.inviteCode,
    required this.inviteEmail,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();

  @override
  final String id;
  @override
  final String parentId;
  @override
  final String? caregiverId;
  @override
  final ConnectionStatus status;
  @override
  final String? inviteCode;
  @override
  final String inviteEmail;
  @override
  final String? message;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Connection(id: $id, parentId: $parentId, caregiverId: $caregiverId, status: $status, inviteCode: $inviteCode, inviteEmail: $inviteEmail, message: $message, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.caregiverId, caregiverId) ||
                other.caregiverId == caregiverId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviteEmail, inviteEmail) ||
                other.inviteEmail == inviteEmail) &&
            (identical(other.message, message) || other.message == message) &&
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
    caregiverId,
    status,
    inviteCode,
    inviteEmail,
    message,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionImplCopyWith<_$ConnectionImpl> get copyWith =>
      __$$ConnectionImplCopyWithImpl<_$ConnectionImpl>(this, _$identity);
}

abstract class _Connection extends Connection {
  const factory _Connection({
    required final String id,
    required final String parentId,
    final String? caregiverId,
    required final ConnectionStatus status,
    final String? inviteCode,
    required final String inviteEmail,
    final String? message,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ConnectionImpl;
  const _Connection._() : super._();

  @override
  String get id;
  @override
  String get parentId;
  @override
  String? get caregiverId;
  @override
  ConnectionStatus get status;
  @override
  String? get inviteCode;
  @override
  String get inviteEmail;
  @override
  String? get message;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionImplCopyWith<_$ConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
