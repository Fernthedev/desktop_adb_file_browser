import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:desktop_adb_file_browser/riverpod/file_queue.dart';
import 'package:desktop_adb_file_browser/widgets/progress_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

class ADBQueueIndicator extends ConsumerStatefulWidget {
  const ADBQueueIndicator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ADBQueueIndicatorState();
}

class _ADBQueueIndicatorState extends ConsumerState<ADBQueueIndicator> {
  @override
  Widget build(BuildContext context) {
    // Download Snackbar
    ref.listen(downloadQueueProvider, _showDownloadSnackbar);
    // Upload Snackbar
    ref.listen(uploadQueueProvider, _showUploadSnackbar);

    return widget.child;
  }

  void _showDownloadSnackbar(
      AsyncValue<Future>? previous, AsyncValue<Future> next) async {
    final nextFuture = next.valueOrNull;
    if (nextFuture == null) return;

    // Snack bar
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DownloadQueueSnackbar(
          futures: {nextFuture},
        ),
        duration: const Duration(days: 365), // year old snackbar
        width: 680.0, // Width of the SnackBar.
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0, // Inner padding for SnackBar content.
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );

    await nextFuture;
    ref.invalidate(deviceFileListingProvider);

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }

  void _showUploadSnackbar(
      AsyncValue<Future>? previous, AsyncValue<Future> next) async {
    final nextFuture = next.valueOrNull;
    if (nextFuture == null) return;

    // Snack bar
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: UploadQueueSnackbar(
          futures: {nextFuture},
        ),
        duration: const Duration(days: 365), // year old snackbar
        width: 680.0, // Width of the SnackBar.
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0, // Inner padding for SnackBar content.
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );

    await nextFuture;
    ref.invalidate(deviceFileListingProvider);

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }
}

// class CombinedQueueSnackbar extends ConsumerStatefulWidget {
//   const CombinedQueueSnackbar({super.key, required this.snackBar});

//   final SnackBar snackBar;

//   @override
//   ConsumerState<CombinedQueueSnackbar> createState() =>
//       _CombinedQueueSnackbarState();
// }

// class _CombinedQueueSnackbarState extends ConsumerState<CombinedQueueSnackbar> {
//   // using this just to retain the snackbar open
//   // the indicators will use their own source of truth
//   Set<Future> downloadQueue = {};
//   Set<Future> uploadQueue = {};

//   @override
//   void initState() {
//     super.initState();

//     // setup state changes
//     downloadQueue = ref.listenManual(downloadQueueProvider, (previous, next) {
//       setState(() => downloadQueue = downloadQueue.union(next.toSet()));
//     }).read();
//     uploadQueue = ref.listenManual(uploadQueueProvider, (previous, next) {
//       setState(() => uploadQueue = uploadQueue.union(next.toSet()));
//     }).read();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (downloadQueue.isEmpty && uploadQueue.isEmpty) {}

//     // combined will stay true if already true
//     final combined = downloadQueue.isNotEmpty && uploadQueue.isNotEmpty;
//     if (combined) return _combinedSnackbars();

//     if (downloadQueue.isNotEmpty) return const DownloadQueueSnackbar();
//     if (uploadQueue.isNotEmpty) return const UploadQueueSnackbar();

//     // if both are empty, no clue
//     return const LinearProgressIndicator(
//       value: 1,
//     );
//   }

//   Widget _combinedSnackbars() {
//     return const Row(
//       mainAxisSize: MainAxisSize.max,
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [DownloadQueueSnackbar(), UploadQueueSnackbar()],
//     );
//   }
// }

class DownloadQueueSnackbar extends StatelessWidget {
  const DownloadQueueSnackbar({super.key, required this.futures});

  final Set<Future> futures;

  @override
  Widget build(BuildContext context) {
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

class UploadQueueSnackbar extends StatelessWidget {
  const UploadQueueSnackbar({super.key, required this.futures});

  final Set<Future> futures;

  @override
  Widget build(BuildContext context) {
    return ProgressSnackbar(
      futures: futures,
      widgetBuilder: ((totalFutures, remainingFutures) => Text(
            textScaler: const TextScaler.linear(1.5),
            "Uploading ${(totalFutures - remainingFutures) / totalFutures * 100}%",
          )),
    );
  }
}
