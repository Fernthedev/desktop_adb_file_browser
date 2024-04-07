import 'dart:collection';

import 'package:desktop_adb_file_browser/riverpod/selected_device.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:trace/trace.dart';

part 'file_browser.g.dart';
part 'file_browser.freezed.dart';

typedef FileNavigateEvent = void Function(String newPath);

@freezed
class FileBrowserState with _$FileBrowserState {
  const factory FileBrowserState.def({
    required String address,
    required Queue<String> historyPaths,
    required Queue<String> forwardPaths,
  }) = _FileBrowserState;

  factory FileBrowserState({
    required String addressBar,
  }) =>
      FileBrowserState.def(
          address: addressBar, historyPaths: Queue(), forwardPaths: Queue());
}

@riverpod
class FileBrowser extends _$FileBrowser {
  @override
  FileBrowserState build() => FileBrowserState(addressBar: "/sdcard/");

  void back() {
    if (state.historyPaths.isEmpty) return;

    final newForwardPaths = Queue<String>.from(state.forwardPaths);
    final currentPath = state.address;
    newForwardPaths.push(currentPath);

    final newHistoryPaths = Queue<String>.from(state.historyPaths);
    final targetPath = newHistoryPaths.pop();

    state = state.copyWith(
        forwardPaths: newForwardPaths, historyPaths: newHistoryPaths);
    _refreshFiles(
        targetPath: targetPath, addToHistory: false, clearForward: false);
  }

  void forward() {
    if (state.forwardPaths.isEmpty) return;

    final newForwardPaths = Queue<String>.from(state.forwardPaths);
    String path = newForwardPaths.pop()!;
    state = state.copyWith(forwardPaths: newForwardPaths);

    _refreshFiles(targetPath: path, clearForward: false);
  }

  void gotoTopDirectory() {
    navigateToDirectory(Adb.adbPathContext.dirname(state.address));
  }

  void navigateToDirectory(String directory) {
    _refreshFiles(targetPath: directory, clearForward: true);
    Trace.verbose("clear forward");
  }

  void _refreshFiles(
      {String? targetPath,
      bool addToHistory = true,
      bool clearForward = true}) {
    final newHistoryPaths = Queue<String>.from(state.historyPaths);
    final newForwardPaths = Queue<String>.from(state.forwardPaths);
    String newCurrentPath = state.address;

    // final oldAddressText = state.address;

    targetPath = targetPath == null
        ? null
        : Adb.adbPathContext
            .canonicalize(Adb.fixPath(targetPath, addQuotes: false));

    if (targetPath != null) {
      if (addToHistory) {
        newHistoryPaths.push(state.address);
      }
      if (clearForward) {
        newForwardPaths.clear();
      }
      newCurrentPath = targetPath;
    }

    //TODO: Remove
    /// Don't refresh unnecessarily
    /// This will still allow refreshes when pressing enter
    /// on the address bar because the address bar passes [path] as null
    // if (newPath != null && oldAddressText == newPath) return;

    state = state.copyWith(
      historyPaths: newHistoryPaths,
      forwardPaths: newForwardPaths,
      address: newCurrentPath,
    );
  }
}

@riverpod
Future<List<FileListingData>> deviceFileListing(DeviceFileListingRef ref) {
  final address = ref.watch(fileBrowserProvider);
  final device = ref.watch(selectedDeviceProvider);

  return Adb.getFilesInDirectory(device?.serialName, address.address);
}

@riverpod
Future<List<FileListingData>> filteredFileInfoListing(
    FilteredFileInfoListingRef ref,
    [String? filter]) async {
  final list = await ref.watch(deviceFileListingProvider.future);

  final loweredFilter = filter?.toLowerCase();

  final targetList = loweredFilter == null
      ? list
      : list
          .where((x) =>
              Adb.adbPathContext.basename(x.path).contains(loweredFilter))
          .toList();

  return targetList;
}

@riverpod
Future<FileListingData> fileInfo(FileInfoRef ref, String path) async {
  // update if device file listing provider is updated
  ref.watch(deviceFileListingProvider);
  final device = ref.watch(selectedDeviceProvider);

  final size = Adb.getFileSize(device?.serialName, path);
  final date = Adb.getFileModifiedDate(device?.serialName, path);

  return FileListingData(
      size: await size ?? -1,
      path: path,
      date: await date ?? DateTime.fromMillisecondsSinceEpoch(0),
      serial: device?.serialName,
      permission: "N/A",
      user: "N/A");
}
