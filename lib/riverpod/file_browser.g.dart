// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_browser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceFileListingHash() => r'fa6c8c03fed896c861c994e0ab45b25b6526eb0d';

/// See also [deviceFileListing].
@ProviderFor(deviceFileListing)
final deviceFileListingProvider =
    AutoDisposeFutureProvider<List<FileListingData>>.internal(
  deviceFileListing,
  name: r'deviceFileListingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceFileListingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DeviceFileListingRef
    = AutoDisposeFutureProviderRef<List<FileListingData>>;
String _$filteredFileInfoListingHash() =>
    r'4423120e2ce105dc8aa0987c2a29dab9e33d10b5';

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

/// See also [filteredFileInfoListing].
@ProviderFor(filteredFileInfoListing)
const filteredFileInfoListingProvider = FilteredFileInfoListingFamily();

/// See also [filteredFileInfoListing].
class FilteredFileInfoListingFamily
    extends Family<AsyncValue<List<FileListingData>>> {
  /// See also [filteredFileInfoListing].
  const FilteredFileInfoListingFamily();

  /// See also [filteredFileInfoListing].
  FilteredFileInfoListingProvider call([
    String? filter,
  ]) {
    return FilteredFileInfoListingProvider(
      filter,
    );
  }

  @override
  FilteredFileInfoListingProvider getProviderOverride(
    covariant FilteredFileInfoListingProvider provider,
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
  String? get name => r'filteredFileInfoListingProvider';
}

/// See also [filteredFileInfoListing].
class FilteredFileInfoListingProvider
    extends AutoDisposeFutureProvider<List<FileListingData>> {
  /// See also [filteredFileInfoListing].
  FilteredFileInfoListingProvider([
    String? filter,
  ]) : this._internal(
          (ref) => filteredFileInfoListing(
            ref as FilteredFileInfoListingRef,
            filter,
          ),
          from: filteredFileInfoListingProvider,
          name: r'filteredFileInfoListingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredFileInfoListingHash,
          dependencies: FilteredFileInfoListingFamily._dependencies,
          allTransitiveDependencies:
              FilteredFileInfoListingFamily._allTransitiveDependencies,
          filter: filter,
        );

  FilteredFileInfoListingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final String? filter;

  @override
  Override overrideWith(
    FutureOr<List<FileListingData>> Function(
            FilteredFileInfoListingRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredFileInfoListingProvider._internal(
        (ref) => create(ref as FilteredFileInfoListingRef),
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
  AutoDisposeFutureProviderElement<List<FileListingData>> createElement() {
    return _FilteredFileInfoListingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredFileInfoListingProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FilteredFileInfoListingRef
    on AutoDisposeFutureProviderRef<List<FileListingData>> {
  /// The parameter `filter` of this provider.
  String? get filter;
}

class _FilteredFileInfoListingProviderElement
    extends AutoDisposeFutureProviderElement<List<FileListingData>>
    with FilteredFileInfoListingRef {
  _FilteredFileInfoListingProviderElement(super.provider);

  @override
  String? get filter => (origin as FilteredFileInfoListingProvider).filter;
}

String _$fileInfoHash() => r'3b490c9fe56bdc993118b829a15c45610210ee44';

/// See also [fileInfo].
@ProviderFor(fileInfo)
const fileInfoProvider = FileInfoFamily();

/// See also [fileInfo].
class FileInfoFamily extends Family<AsyncValue<FileListingData>> {
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
class FileInfoProvider extends AutoDisposeFutureProvider<FileListingData> {
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
    FutureOr<FileListingData> Function(FileInfoRef provider) create,
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
  AutoDisposeFutureProviderElement<FileListingData> createElement() {
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

mixin FileInfoRef on AutoDisposeFutureProviderRef<FileListingData> {
  /// The parameter `path` of this provider.
  String get path;
}

class _FileInfoProviderElement
    extends AutoDisposeFutureProviderElement<FileListingData> with FileInfoRef {
  _FileInfoProviderElement(super.provider);

  @override
  String get path => (origin as FileInfoProvider).path;
}

String _$fileBrowserHash() => r'e678f5b7a069e4fc8e099f74feb2801f7ed5ed0f';

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
