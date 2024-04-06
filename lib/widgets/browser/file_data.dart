import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:desktop_adb_file_browser/riverpod/file_queue.dart';
import 'package:desktop_adb_file_browser/riverpod/selected_device.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';

typedef WatchFileCallback = Future<void> Function(FileListingData fileData);

extension FileDataState on FileListingData {
  bool get isDirectory => path.endsWith("/");

  /// Just the file name
  String get friendlyFileName => Adb.adbPathContext.basename(path);

  Future<void> copyPathToClipboard() {
    return FlutterClipboard.copy(path);
  }

  IconData getIcon() {
    return isDirectory ? Icons.folder : FluentIcons.document_48_regular;
  }

  Future<void> openTempFile(WidgetRef ref) async {
    String questPath = path;
    String fileName = friendlyFileName;

    var temp = await getTemporaryDirectory();
    var randomName = "${Random().nextInt(10000)}$fileName";

    var dest = Adb.hostPath.join(temp.path, randomName);
    await ref
        .read(downloadQueueProvider.notifier)
        .doDownload(serial, questPath, dest);

    StreamSubscription? subscription;
    subscription = Watcher(dest).events.listen((event) async {
      if (event.type == ChangeType.REMOVE || !(await File(dest).exists())) {
        await subscription!.cancel();
      }

      if (event.type == ChangeType.MODIFY) {
        await ref
            .read(uploadQueueProvider.notifier)
            .doUpload(serial, dest, questPath);
      }
    });

    OpenFile.open(dest);
  }

  Future<void> renameFileDialog(BuildContext context) async {
    await showDialog<void>(
        context: context,
        builder: ((context) => _RenameFileDialog(file: this)));
  }

  Future<void> removeFileDialog(BuildContext context) async {
    await showDialog<void>(
        context: context,
        builder: ((context) => _RemoveFileDialog(file: this)));
  }

  Future<String?> saveFileToDesktop(WidgetRef ref) async {
    String source = path;

    final savePath = await getSaveLocation(suggestedName: friendlyFileName);

    if (savePath == null) return null;

    await ref
        .read(downloadQueueProvider.notifier)
        .doDownload(serial, source, savePath.path);

    return savePath.path;
  }

  /// return true if modified
  Future<bool> renameFile(String newName) async {
    String source = path;
    var task = Adb.moveFile(serial, source,
        Adb.adbPathContext.join(Adb.adbPathContext.dirname(source), newName));

    await task;

    return newName != friendlyFileName;
  }
}

class _RemoveFileDialog extends ConsumerWidget {
  final FileBrowserMetadata file;

  const _RemoveFileDialog({
    required this.file,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serial = file.serial;
    final isFile = !file.isDirectory;

    return AlertDialog(
      title: const Text("Confirm?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Are you sure you want to delete this file/folder?"),
          Text(file.friendlyFileName)
        ],
      ),
      actions: [
        TextButton(
          autofocus: true,
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
            child: const Text('Ok'),
            onPressed: () async {
              if (isFile) {
                await Adb.removeFile(serial, file.path);
              } else {
                await Adb.removeDirectory(serial, file.path);
              }

              // refresh
              ref.invalidate(deviceFileListingProvider);

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }),
      ],
    );
  }
}

class _RenameFileDialog extends ConsumerWidget {
  _RenameFileDialog({required this.file})
      : controller = TextEditingController(text: file.friendlyFileName);

  final FileBrowserMetadata file;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text("Rename"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Renaming: ${file.friendlyFileName}"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: controller,
              canRequestFocus: true,
              autofocus: true,
              onFieldSubmitted: (s) => _submitRename(context, ref),
              validator: _validateNewName,
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          child: const Text('Ok'),
          onPressed: () => _submitRename(context, ref),
        ),
      ],
    );
  }

  String? _validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
  }

  void _submitRename(BuildContext context, WidgetRef ref) async {
    await file.renameFile(controller.text);

    // refresh
    ref.invalidate(deviceFileListingProvider);
    ;

    // False positive
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
