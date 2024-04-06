import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/widgets/progress_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_queue.g.dart';

@riverpod
class DownloadQueue extends _$DownloadQueue with QueueMixin {
  @override
  Set<Future> build() => <Future>{};

  Future<void> doDownload(String? serial, String src, String dest) async {
    final future = Adb.downloadFile(serial, src, dest);
    addQueue(future);
    await future;
  }
}

@riverpod
class UploadQueue extends _$UploadQueue with QueueMixin {
  @override
  Set<Future> build() => <Future>{};

  Future<void> doUpload(String? serial, String src, String dest) async {
    final future = Adb.uploadFile(serial, src, dest);
    addQueue(future);
    await future;
  }
}

mixin QueueMixin on AutoDisposeNotifier<Set<Future>> {
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

class DownloadQueueSnackbar extends ConsumerWidget {
  const DownloadQueueSnackbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futures = ref.watch(downloadQueueProvider);

    return ProgressSnackbar(
      futures: futures,
      widgetBuilder: ((totalFutures, remainingFutures) => Text(
            "Downloading ${(totalFutures - remainingFutures) / totalFutures * 100}%",
            textScaler: const TextScaler.linear(1.5),
          )),
    );
  }

  Widget oldWidgetBuilder(int totalFutures, int remainingFutures) {
    // set to null if tasks are waiting
    final onClick = remainingFutures > 0 ? null : () => OpenFile.open(null);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // divide into 3 spaces, use this as empty space
          const SizedBox(),
          Text(
              "Downloading: ${(totalFutures - remainingFutures) / totalFutures * 100}"),
          SizedBox(
            height: 40,
            width: 100,
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: onClick,
              icon: const Icon(Icons.edit),
              label: const Text("Open"),
            ),
          )
        ],
      ),
    );
  }
}

class UploadQueueSnackbar extends ConsumerWidget {
  const UploadQueueSnackbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futures = ref.watch(uploadQueueProvider);

    return ProgressSnackbar(
      futures: futures,
      widgetBuilder: ((totalFutures, remainingFutures) => Text(
            textScaler: const TextScaler.linear(1.5),
            "Uploading ${(totalFutures - remainingFutures) / totalFutures * 100}%",
          )),
    );
  }
}
