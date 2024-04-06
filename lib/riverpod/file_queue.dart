import 'dart:async';

import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_queue.g.dart';

@riverpod
class DownloadQueue extends _$DownloadQueue with QueueMixin {
  @override
  Stream<Future> build() {
    _controller = StreamController.broadcast();

    return _controller.stream;
  }

  Future<void> doDownload(String? serial, String src, String dest) async {
    final future = Adb.downloadFile(serial, src, dest);
    addQueue(future);
    await future;
  }
}

@riverpod
class UploadQueue extends _$UploadQueue with QueueMixin {
  @override
  Stream<Future> build() {
    _controller = StreamController.broadcast();

    return _controller.stream;
  }

  Future<void> doUpload(String? serial, String src, String dest) async {
    final future = Adb.uploadFile(serial, src, dest);
    addQueue(future);
    await future;
  }
}

mixin QueueMixin on AutoDisposeStreamNotifier<Future> {
  late StreamController<Future> _controller;

  void addAllQueue(Iterable<Future> futures) {
    for (final future in futures) {
      addQueue(future);
    }
  }

  void addQueue(Future future) async {
    _controller.add(future);
    future.onError(
        (error, stackTrace) => _controller.addError(error ?? "Error!"));
  }
}
