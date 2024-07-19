// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$packageInfoHash() => r'cdbf2040ce8eef2bc5c4b4228d8f219382d101c0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [packageInfo].
@ProviderFor(packageInfo)
const packageInfoProvider = PackageInfoFamily();

/// See also [packageInfo].
class PackageInfoFamily extends Family<AsyncValue<PackageMetadata>> {
  /// See also [packageInfo].
  const PackageInfoFamily();

  /// See also [packageInfo].
  PackageInfoProvider call(
    String id,
  ) {
    return PackageInfoProvider(
      id,
    );
  }

  @override
  PackageInfoProvider getProviderOverride(
    covariant PackageInfoProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'packageInfoProvider';
}

/// See also [packageInfo].
class PackageInfoProvider extends AutoDisposeFutureProvider<PackageMetadata> {
  /// See also [packageInfo].
  PackageInfoProvider(
    String id,
  ) : this._internal(
          (ref) => packageInfo(
            ref as PackageInfoRef,
            id,
          ),
          from: packageInfoProvider,
          name: r'packageInfoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$packageInfoHash,
          dependencies: PackageInfoFamily._dependencies,
          allTransitiveDependencies:
              PackageInfoFamily._allTransitiveDependencies,
          id: id,
        );

  PackageInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<PackageMetadata> Function(PackageInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PackageInfoProvider._internal(
        (ref) => create(ref as PackageInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PackageMetadata> createElement() {
    return _PackageInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PackageInfoProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PackageInfoRef on AutoDisposeFutureProviderRef<PackageMetadata> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PackageInfoProviderElement
    extends AutoDisposeFutureProviderElement<PackageMetadata>
    with PackageInfoRef {
  _PackageInfoProviderElement(super.provider);

  @override
  String get id => (origin as PackageInfoProvider).id;
}

String _$packageListHash() => r'9df7f95c5786ef7fc1b05d9864f0b065b34eae9f';

/// See also [PackageList].
@ProviderFor(PackageList)
final packageListProvider =
    AutoDisposeAsyncNotifierProvider<PackageList, List<String>>.internal(
  PackageList.new,
  name: r'packageListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$packageListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PackageList = AutoDisposeAsyncNotifier<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
