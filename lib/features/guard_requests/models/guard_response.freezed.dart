// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guard_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GuardResponse {
  String get caregiverId => throw _privateConstructorUsedError;
  CaregiverSnapshot get caregiverSnapshot => throw _privateConstructorUsedError;
  GuardResponseStatus get status => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  DateTime get respondedAt => throw _privateConstructorUsedError;

  /// Create a copy of GuardResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GuardResponseCopyWith<GuardResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GuardResponseCopyWith<$Res> {
  factory $GuardResponseCopyWith(
    GuardResponse value,
    $Res Function(GuardResponse) then,
  ) = _$GuardResponseCopyWithImpl<$Res, GuardResponse>;
  @useResult
  $Res call({
    String caregiverId,
    CaregiverSnapshot caregiverSnapshot,
    GuardResponseStatus status,
    String? message,
    DateTime respondedAt,
  });
}

/// @nodoc
class _$GuardResponseCopyWithImpl<$Res, $Val extends GuardResponse>
    implements $GuardResponseCopyWith<$Res> {
  _$GuardResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GuardResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? caregiverId = null,
    Object? caregiverSnapshot = null,
    Object? status = null,
    Object? message = freezed,
    Object? respondedAt = null,
  }) {
    return _then(
      _value.copyWith(
            caregiverId:
                null == caregiverId
                    ? _value.caregiverId
                    : caregiverId // ignore: cast_nullable_to_non_nullable
                        as String,
            caregiverSnapshot:
                null == caregiverSnapshot
                    ? _value.caregiverSnapshot
                    : caregiverSnapshot // ignore: cast_nullable_to_non_nullable
                        as CaregiverSnapshot,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as GuardResponseStatus,
            message:
                freezed == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String?,
            respondedAt:
                null == respondedAt
                    ? _value.respondedAt
                    : respondedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GuardResponseImplCopyWith<$Res>
    implements $GuardResponseCopyWith<$Res> {
  factory _$$GuardResponseImplCopyWith(
    _$GuardResponseImpl value,
    $Res Function(_$GuardResponseImpl) then,
  ) = __$$GuardResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String caregiverId,
    CaregiverSnapshot caregiverSnapshot,
    GuardResponseStatus status,
    String? message,
    DateTime respondedAt,
  });
}

/// @nodoc
class __$$GuardResponseImplCopyWithImpl<$Res>
    extends _$GuardResponseCopyWithImpl<$Res, _$GuardResponseImpl>
    implements _$$GuardResponseImplCopyWith<$Res> {
  __$$GuardResponseImplCopyWithImpl(
    _$GuardResponseImpl _value,
    $Res Function(_$GuardResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GuardResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? caregiverId = null,
    Object? caregiverSnapshot = null,
    Object? status = null,
    Object? message = freezed,
    Object? respondedAt = null,
  }) {
    return _then(
      _$GuardResponseImpl(
        caregiverId:
            null == caregiverId
                ? _value.caregiverId
                : caregiverId // ignore: cast_nullable_to_non_nullable
                    as String,
        caregiverSnapshot:
            null == caregiverSnapshot
                ? _value.caregiverSnapshot
                : caregiverSnapshot // ignore: cast_nullable_to_non_nullable
                    as CaregiverSnapshot,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as GuardResponseStatus,
        message:
            freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String?,
        respondedAt:
            null == respondedAt
                ? _value.respondedAt
                : respondedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$GuardResponseImpl extends _GuardResponse {
  const _$GuardResponseImpl({
    required this.caregiverId,
    required this.caregiverSnapshot,
    required this.status,
    this.message,
    required this.respondedAt,
  }) : super._();

  @override
  final String caregiverId;
  @override
  final CaregiverSnapshot caregiverSnapshot;
  @override
  final GuardResponseStatus status;
  @override
  final String? message;
  @override
  final DateTime respondedAt;

  @override
  String toString() {
    return 'GuardResponse(caregiverId: $caregiverId, caregiverSnapshot: $caregiverSnapshot, status: $status, message: $message, respondedAt: $respondedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GuardResponseImpl &&
            (identical(other.caregiverId, caregiverId) ||
                other.caregiverId == caregiverId) &&
            (identical(other.caregiverSnapshot, caregiverSnapshot) ||
                other.caregiverSnapshot == caregiverSnapshot) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    caregiverId,
    caregiverSnapshot,
    status,
    message,
    respondedAt,
  );

  /// Create a copy of GuardResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GuardResponseImplCopyWith<_$GuardResponseImpl> get copyWith =>
      __$$GuardResponseImplCopyWithImpl<_$GuardResponseImpl>(this, _$identity);
}

abstract class _GuardResponse extends GuardResponse {
  const factory _GuardResponse({
    required final String caregiverId,
    required final CaregiverSnapshot caregiverSnapshot,
    required final GuardResponseStatus status,
    final String? message,
    required final DateTime respondedAt,
  }) = _$GuardResponseImpl;
  const _GuardResponse._() : super._();

  @override
  String get caregiverId;
  @override
  CaregiverSnapshot get caregiverSnapshot;
  @override
  GuardResponseStatus get status;
  @override
  String? get message;
  @override
  DateTime get respondedAt;

  /// Create a copy of GuardResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GuardResponseImplCopyWith<_$GuardResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
