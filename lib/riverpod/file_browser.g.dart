// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_browser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceFileListingHash() => r'63ccb62464afb8fa7420307e788fa6156ed778c8';

/// See also [deviceFileListing].
@ProviderFor(deviceFileListing)
final deviceFileListingProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  deviceFileListing,
  name: r'deviceFileListingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceFileListingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DeviceFileListingRef = AutoDisposeFutureProviderRef<List<String>>;
String _$filteredFileListingHash() =>
    r'bd77fe22ff453cad5be0e2233aafcf01f08b7f6e';

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

/// See also [filteredFileListing].
@ProviderFor(filteredFileListing)
const filteredFileListingProvider = FilteredFileListingFamily();

/// See also [filteredFileListing].
class FilteredFileListingFamily extends Family<AsyncValue<List<String>>> {
  /// See also [filteredFileListing].
  const FilteredFileListingFamily();

  /// See also [filteredFileListing].
  FilteredFileListingProvider call(
    String filter,
  ) {
    return FilteredFileListingProvider(
      filter,
    );
  }

  @override
  FilteredFileListingProvider getProviderOverride(
    covariant FilteredFileListingProvider provider,
  ) {
    return call(
      provider.filter,
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
  String? get name => r'filteredFileListingProvider';
}

/// See also [filteredFileListing].
class FilteredFileListingProvider
    extends AutoDisposeFutureProvider<List<String>> {
  /// See also [filteredFileListing].
  FilteredFileListingProvider(
    String filter,
  ) : this._internal(
          (ref) => filteredFileListing(
            ref as FilteredFileListingRef,
            filter,
          ),
          from: filteredFileListingProvider,
          name: r'filteredFileListingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredFileListingHash,
          dependencies: FilteredFileListingFamily._dependencies,
          allTransitiveDependencies:
              FilteredFileListingFamily._allTransitiveDependencies,
          filter: filter,
        );

  FilteredFileListingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final String filter;

  @override
  Override overrideWith(
    FutureOr<List<String>> Function(FilteredFileListingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredFileListingProvider._internal(
        (ref) => create(ref as FilteredFileListingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filter: filter,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<String>> createElement() {
    return _FilteredFileListingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredFileListingProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FilteredFileListingRef on AutoDisposeFutureProviderRef<List<String>> {
  /// The parameter `filter` of this provider.
  String get filter;
}

class _FilteredFileListingProviderElement
    extends AutoDisposeFutureProviderElement<List<String>>
    with FilteredFileListingRef {
  _FilteredFileListingProviderElement(super.provider);

  @override
  String get filter => (origin as FilteredFileListingProvider).filter;
}

String _$fileInfoHash() => r'6dbfc863524cc52ddb87dc3f198b4e847afd5d83';

/// See also [fileInfo].
@ProviderFor(fileInfo)
const fileInfoProvider = FileInfoFamily();

/// See also [fileInfo].
class FileInfoFamily extends Family<AsyncValue<FileBrowserMetadata>> {
  /// See also [fileInfo].
  const FileInfoFamily();

  /// See also [fileInfo].
  FileInfoProvider call(
    String path,
  ) {
    return FileInfoProvider(
      path,
    );
  }

  @override
  FileInfoProvider getProviderOverride(
    covariant FileInfoProvider provider,
  ) {
    return call(
      provider.path,
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
  String? get name => r'fileInfoProvider';
}

/// See also [fileInfo].
class FileInfoProvider extends AutoDisposeFutureProvider<FileBrowserMetadata> {
  /// See also [fileInfo].
  FileInfoProvider(
    String path,
  ) : this._internal(
          (ref) => fileInfo(
            ref as FileInfoRef,
            path,
          ),
          from: fileInfoProvider,
          name: r'fileInfoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fileInfoHash,
          dependencies: FileInfoFamily._dependencies,
          allTransitiveDependencies: FileInfoFamily._allTransitiveDependencies,
          path: path,
        );

  FileInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.path,
  }) : super.internal();

  final String path;

  @override
  Override overrideWith(
    FutureOr<FileBrowserMetadata> Function(FileInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FileInfoProvider._internal(
        (ref) => create(ref as FileInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        path: path,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FileBrowserMetadata> createElement() {
    return _FileInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FileInfoProvider && other.path == path;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, path.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FileInfoRef on AutoDisposeFutureProviderRef<FileBrowserMetadata> {
  /// The parameter `path` of this provider.
  String get path;
}

class _FileInfoProviderElement
    extends AutoDisposeFutureProviderElement<FileBrowserMetadata>
    with FileInfoRef {
  _FileInfoProviderElement(super.provider);

  @override
  String get path => (origin as FileInfoProvider).path;
}

String _$fileBrowserHash() => r'998143e802b3e248e0c2da7400bb1e894b141167';

/// See also [FileBrowser].
@ProviderFor(FileBrowser)
final fileBrowserProvider =
    AutoDisposeNotifierProvider<FileBrowser, FileBrowserState>.internal(
  FileBrowser.new,
  name: r'fileBrowserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fileBrowserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FileBrowser = AutoDisposeNotifier<FileBrowserState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
