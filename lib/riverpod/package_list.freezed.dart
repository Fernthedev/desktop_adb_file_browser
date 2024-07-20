// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'package_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PackageMetadata {
  String get packageName => throw _privateConstructorUsedError;
  String get packageId => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PackageMetadataCopyWith<PackageMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PackageMetadataCopyWith<$Res> {
  factory $PackageMetadataCopyWith(
          PackageMetadata value, $Res Function(PackageMetadata) then) =
      _$PackageMetadataCopyWithImpl<$Res, PackageMetadata>;
  @useResult
  $Res call({String packageName, String packageId, String version});
}

/// @nodoc
class _$PackageMetadataCopyWithImpl<$Res, $Val extends PackageMetadata>
    implements $PackageMetadataCopyWith<$Res> {
  _$PackageMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packageName = null,
    Object? packageId = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      packageName: null == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      packageId: null == packageId
          ? _value.packageId
          : packageId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PackageMetadataImplCopyWith<$Res>
    implements $PackageMetadataCopyWith<$Res> {
  factory _$$PackageMetadataImplCopyWith(_$PackageMetadataImpl value,
          $Res Function(_$PackageMetadataImpl) then) =
      __$$PackageMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String packageName, String packageId, String version});
}

/// @nodoc
class __$$PackageMetadataImplCopyWithImpl<$Res>
    extends _$PackageMetadataCopyWithImpl<$Res, _$PackageMetadataImpl>
    implements _$$PackageMetadataImplCopyWith<$Res> {
  __$$PackageMetadataImplCopyWithImpl(
      _$PackageMetadataImpl _value, $Res Function(_$PackageMetadataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packageName = null,
    Object? packageId = null,
    Object? version = null,
  }) {
    return _then(_$PackageMetadataImpl(
      packageName: null == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      packageId: null == packageId
          ? _value.packageId
          : packageId // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PackageMetadataImpl implements _PackageMetadata {
  const _$PackageMetadataImpl(
      {required this.packageName,
      required this.packageId,
      required this.version});

  @override
  final String packageName;
  @override
  final String packageId;
  @override
  final String version;

  @override
  String toString() {
    return 'PackageMetadata(packageName: $packageName, packageId: $packageId, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackageMetadataImpl &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.packageId, packageId) ||
                other.packageId == packageId) &&
            (identical(other.version, version) || other.version == version));
  }

  @override
  int get hashCode => Object.hash(runtimeType, packageName, packageId, version);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackageMetadataImplCopyWith<_$PackageMetadataImpl> get copyWith =>
      __$$PackageMetadataImplCopyWithImpl<_$PackageMetadataImpl>(
          this, _$identity);
}

abstract class _PackageMetadata implements PackageMetadata {
  const factory _PackageMetadata(
      {required final String packageName,
      required final String packageId,
      required final String version}) = _$PackageMetadataImpl;

  @override
  String get packageName;
  @override
  String get packageId;
  @override
  String get version;
  @override
  @JsonKey(ignore: true)
  _$$PackageMetadataImplCopyWith<_$PackageMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
