// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_browser.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FileBrowserState {
  String get address => throw _privateConstructorUsedError;
  Queue<String> get historyPaths => throw _privateConstructorUsedError;
  Queue<String> get forwardPaths => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String address, Queue<String> historyPaths,
            Queue<String> forwardPaths)
        def,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String address, Queue<String> historyPaths,
            Queue<String> forwardPaths)?
        def,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String address, Queue<String> historyPaths,
            Queue<String> forwardPaths)?
        def,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_FileBrowserState value) def,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_FileBrowserState value)? def,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_FileBrowserState value)? def,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FileBrowserStateCopyWith<FileBrowserState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileBrowserStateCopyWith<$Res> {
  factory $FileBrowserStateCopyWith(
          FileBrowserState value, $Res Function(FileBrowserState) then) =
      _$FileBrowserStateCopyWithImpl<$Res, FileBrowserState>;
  @useResult
  $Res call(
      {String address, Queue<String> historyPaths, Queue<String> forwardPaths});
}

/// @nodoc
class _$FileBrowserStateCopyWithImpl<$Res, $Val extends FileBrowserState>
    implements $FileBrowserStateCopyWith<$Res> {
  _$FileBrowserStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? historyPaths = null,
    Object? forwardPaths = null,
  }) {
    return _then(_value.copyWith(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      historyPaths: null == historyPaths
          ? _value.historyPaths
          : historyPaths // ignore: cast_nullable_to_non_nullable
              as Queue<String>,
      forwardPaths: null == forwardPaths
          ? _value.forwardPaths
          : forwardPaths // ignore: cast_nullable_to_non_nullable
              as Queue<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileBrowserStateImplCopyWith<$Res>
    implements $FileBrowserStateCopyWith<$Res> {
  factory _$$FileBrowserStateImplCopyWith(_$FileBrowserStateImpl value,
          $Res Function(_$FileBrowserStateImpl) then) =
      __$$FileBrowserStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String address, Queue<String> historyPaths, Queue<String> forwardPaths});
}

/// @nodoc
class __$$FileBrowserStateImplCopyWithImpl<$Res>
    extends _$FileBrowserStateCopyWithImpl<$Res, _$FileBrowserStateImpl>
    implements _$$FileBrowserStateImplCopyWith<$Res> {
  __$$FileBrowserStateImplCopyWithImpl(_$FileBrowserStateImpl _value,
      $Res Function(_$FileBrowserStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? historyPaths = null,
    Object? forwardPaths = null,
  }) {
    return _then(_$FileBrowserStateImpl(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      historyPaths: null == historyPaths
          ? _value.historyPaths
          : historyPaths // ignore: cast_nullable_to_non_nullable
              as Queue<String>,
      forwardPaths: null == forwardPaths
          ? _value.forwardPaths
          : forwardPaths // ignore: cast_nullable_to_non_nullable
              as Queue<String>,
    ));
  }
}

/// @nodoc

class _$FileBrowserStateImpl implements _FileBrowserState {
  const _$FileBrowserStateImpl(
      {required this.address,
      required this.historyPaths,
      required this.forwardPaths});

  @override
  final String address;
  @override
  final Queue<String> historyPaths;
  @override
  final Queue<String> forwardPaths;

  @override
  String toString() {
    return 'FileBrowserState.def(address: $address, historyPaths: $historyPaths, forwardPaths: $forwardPaths)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileBrowserStateImpl &&
            (identical(other.address, address) || other.address == address) &&
            const DeepCollectionEquality()
                .equals(other.historyPaths, historyPaths) &&
            const DeepCollectionEquality()
                .equals(other.forwardPaths, forwardPaths));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      address,
      const DeepCollectionEquality().hash(historyPaths),
      const DeepCollectionEquality().hash(forwardPaths));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FileBrowserStateImplCopyWith<_$FileBrowserStateImpl> get copyWith =>
      __$$FileBrowserStateImplCopyWithImpl<_$FileBrowserStateImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String address, Queue<String> historyPaths,
            Queue<String> forwardPaths)
        def,
  }) {
    return def(address, historyPaths, forwardPaths);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String address, Queue<String> historyPaths,
            Queue<String> forwardPaths)?
        def,
  }) {
    return def?.call(address, historyPaths, forwardPaths);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String address, Queue<String> historyPaths,
            Queue<String> forwardPaths)?
        def,
    required TResult orElse(),
  }) {
    if (def != null) {
      return def(address, historyPaths, forwardPaths);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_FileBrowserState value) def,
  }) {
    return def(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_FileBrowserState value)? def,
  }) {
    return def?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_FileBrowserState value)? def,
    required TResult orElse(),
  }) {
    if (def != null) {
      return def(this);
    }
    return orElse();
  }
}

abstract class _FileBrowserState implements FileBrowserState {
  const factory _FileBrowserState(
      {required final String address,
      required final Queue<String> historyPaths,
      required final Queue<String> forwardPaths}) = _$FileBrowserStateImpl;

  @override
  String get address;
  @override
  Queue<String> get historyPaths;
  @override
  Queue<String> get forwardPaths;
  @override
  @JsonKey(ignore: true)
  _$$FileBrowserStateImplCopyWith<_$FileBrowserStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
