// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloadQueueHash() => r'c9c39fa576ef82d7a3021ab69a1fba006dd28193';

/// See also [DownloadQueue].
@ProviderFor(DownloadQueue)
final downloadQueueProvider =
    AutoDisposeNotifierProvider<DownloadQueue, Set<Future>>.internal(
  DownloadQueue.new,
  name: r'downloadQueueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DownloadQueue = AutoDisposeNotifier<Set<Future>>;
String _$uploadQueueHash() => r'5a646c707defb6cb30ea5eafe404ab0dc1d04476';

/// See also [UploadQueue].
@ProviderFor(UploadQueue)
final uploadQueueProvider =
    AutoDisposeNotifierProvider<UploadQueue, Set<Future>>.internal(
  UploadQueue.new,
  name: r'uploadQueueProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$uploadQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UploadQueue = AutoDisposeNotifier<Set<Future>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
