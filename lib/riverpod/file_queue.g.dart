// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloadQueueHash() => r'3d6f69799aff8cadf2b0ac539575b0475ae13bb0';

/// See also [DownloadQueue].
@ProviderFor(DownloadQueue)
final downloadQueueProvider =
    AutoDisposeStreamNotifierProvider<DownloadQueue, Future>.internal(
  DownloadQueue.new,
  name: r'downloadQueueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DownloadQueue = AutoDisposeStreamNotifier<Future>;
String _$uploadQueueHash() => r'b2030c9d5337e2e4eebe542265e038e8e7352e50';

/// See also [UploadQueue].
@ProviderFor(UploadQueue)
final uploadQueueProvider =
    AutoDisposeStreamNotifierProvider<UploadQueue, Future>.internal(
  UploadQueue.new,
  name: r'uploadQueueProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$uploadQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UploadQueue = AutoDisposeStreamNotifier<Future>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
