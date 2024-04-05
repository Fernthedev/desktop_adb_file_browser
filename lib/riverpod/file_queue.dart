import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_queue.g.dart';

@riverpod
class DownloadQueue extends _$DownloadQueue {
  @override
  Set<Future> build() => <Future>{};

  void addQueue(Future future) async {
    final newQueue = state.toSet();
    newQueue.add(future);
    state = newQueue;

    await future;
    removeQueue(future);
  }

  void removeQueue(Future future) {
    final newQueue = state.toSet();
    newQueue.remove(future);
    state = newQueue;
  }
}

@riverpod
class UploadQueue extends _$UploadQueue {
  @override
  Set<Future> build() => <Future>{};

  void addAllQueue(Iterable<Future> futures) {
    for (final future in futures) {
      addQueue(future);
    }
  }

  void addQueue(Future future) async {
    final newQueue = state.toSet();
    newQueue.add(future);
    state = newQueue;

    await future;
    removeQueue(future);
  }

  void removeQueue(Future future) {
    final newQueue = state.toSet();
    newQueue.remove(future);
    state = newQueue;
  }
}
