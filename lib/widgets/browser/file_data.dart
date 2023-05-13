import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/file_browser.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';

typedef WatchFileCallback = Future<void> Function(
    String source, String savePath);

@immutable
class FileBrowserMetadata {
  final Future<DateTime?> modifiedTime;
  final Future<int?> fileSize;
  final String initialFilePath;
  final bool isDirectory;
  final FileBrowser browser;
  final String serial;
  final WatchFileCallback onWatch;

  const FileBrowserMetadata({
    Key? key,
    required this.initialFilePath,
    required this.isDirectory,
    required this.browser,
    required this.modifiedTime,
    required this.fileSize,
    required this.serial,
    required this.onWatch,
  });
}

mixin FileDataState {
  FileBrowserMetadata get fileData;

  // Set in constructor or initState
  late String fullFilePath;
  bool editable = false;

  String get friendlyFileName => Adb.adbPathContext.basename(fullFilePath);

  Future<void> copyPathToClipboard() {
    return FlutterClipboard.copy(fileData.initialFilePath);
  }

  IconData getIcon() {
    return fileData.isDirectory
        ? Icons.folder
        : FluentIcons.document_48_regular;
  }

  void navigateToDir() {
    if (!fileData.isDirectory) {
      return;
    }

    fileData.browser.navigateToDirectory(fullFilePath);
  }

  Future<void> openTempFile() async {
    String questPath = fileData.initialFilePath;
    String fileName = friendlyFileName;

    var temp = await getTemporaryDirectory();
    var randomName = "${Random().nextInt(10000)}$fileName";

    var dest = Adb.hostPath.join(temp.path, randomName);
    await Adb.downloadFile(fileData.serial, questPath, dest);

    StreamSubscription? subscription;
    subscription = Watcher(dest).events.listen((event) async {
      if (event.type == ChangeType.REMOVE || !(await File(dest).exists())) {
        await subscription!.cancel();
      }

      if (event.type == ChangeType.MODIFY) {
        await Adb.uploadFile(fileData.serial, dest, questPath);
      }
    });

    OpenFile.open(dest);
  }

  Future<void> removeFileDialog(BuildContext context) async {
    String path = fileData.initialFilePath;
    bool file = !fileData.isDirectory;
    await showDialog<void>(
        context: context,
        builder: ((context) => AlertDialog(
              title: const Text("Confirm?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Are you sure you want to delete this file/folder?"),
                  Text(path)
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Future task;
                    if (file) {
                      task = Adb.removeFile(fileData.serial, path);
                    } else {
                      task = Adb.removeDirectory(fileData.serial, path);
                    }

                    task.then((_) {
                      Navigator.of(context).pop();
                      fileData.browser.refresh();
                    });
                  },
                ),
              ],
            )));
  }

  Future<String?> saveFileToDesktop() async {
    String source = fileData.initialFilePath;

    final savePath = await getSavePath(suggestedName: friendlyFileName);

    if (savePath == null) return savePath;

    await Adb.downloadFile(fileData.serial, source, savePath);
    return savePath;
  }

  Future<void> watchFile() async {
    String? savePath = await saveFileToDesktop();
    if (savePath == null) {
      return;
    }
    return fileData.onWatch(fileData.initialFilePath, savePath);
  }

  /// return true if modified
  Future<bool> renameFile(String newName) async {
    String source = fullFilePath;
    var task = Adb.moveFile(fileData.serial, source,
        Adb.adbPathContext.join(Adb.adbPathContext.dirname(source), newName));

    if (newName != friendlyFileName) {
      fullFilePath = Adb.adbPathContext
          .join(Adb.adbPathContext.dirname(fullFilePath), newName);
    }
    await task;

    return newName != friendlyFileName;
  }
}

final class FileBrowserDataWrapper with FileDataState {
  @override
  final FileBrowserMetadata fileData;

  bool downloading = false;

  FileBrowserDataWrapper(this.fileData) {
    fullFilePath = fileData.initialFilePath;
  }
}
