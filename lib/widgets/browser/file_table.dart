import 'dart:math';

import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/conditional.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FileDataTable extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final List<FileBrowserDataWrapper> fileData;
  const FileDataTable({super.key, required this.fileData});

  @override
  State<FileDataTable> createState() => _FileDataTableState();
}

final defaultDateFormat = DateFormat("yyyy-MM-dd hh:mm aa");

// TODO: Optimize and lazy loading
class _FileDataTableState extends State<FileDataTable> {
  int sort = sortDefault;
  bool ascending = ascendingDefault;

  static const sortDefault = 0;
  static const ascendingDefault = true;

  @override
  Widget build(BuildContext context) {
    onSort(int c, bool a) => setState(() {
          sort = c;
          ascending = a;
        });

    final sortedFiles = widget.fileData.toList(growable: false);

    if (sort != sortDefault) {
      sortedFiles.sort((a, b) {
        return 0;
        // TODO:
        // Date
        // if (sort == 1) {
        //   final aSize = (a.fileData.time) ?? 0;
        //   final bSize = (await b.fileData.fileSize) ?? 0;
        //   return sortMultiplier * aSize.compareTo(bSize);
        // }
        // Size
        // if (sort == 2) {
        //   return sortMultiplier *
        //       a.friendlyFileName.compareTo(b.friendlyFileName);
        // }
      });
    }

    final iterableFiles = ascending ? sortedFiles : sortedFiles.reversed;

    //
    return DataTable(
        // return BetterLazyTable(
        sortAscending: ascending,
        sortColumnIndex: sort,
        key: ValueKey(widget.fileData),
        columns: [
          DataColumn(label: const Text("Name"), onSort: onSort),
          DataColumn(label: const Text("Date"), numeric: true, onSort: onSort),
          DataColumn(label: const Text("Size"), numeric: true, onSort: onSort),
          const DataColumn(label: Text("Actions"))
        ],
        rows: iterableFiles
            .map((e) => DataRow(
                  key: ValueKey(e),
                  cells: [
                    DataCell(
                      _nameCell(e),
                      showEditIcon: !e.editable,
                      onLongPress: () => setState(() {
                        e.editable = !e.editable;
                        _renameDialog(e);
                      }),
                      // TODO: Increases delay by 300ms, reduce
                      // onDoubleTap: () => setState(() {
                      //   e.editable = !e.editable;
                      //   _renameDialog(e);
                      // }),
                      onTap: () => e.navigateToDir(),
                    ),
                    DataCell(_dateCell(e)),
                    DataCell(_fileSizeCell(e)),
                    DataCell(_actionsRow(e))
                  ],
                ))
            .toList(growable: false));
  }

  Widget _nameCell(FileBrowserDataWrapper e) {
    Widget text = Text(e.friendlyFileName);
    return Wrap(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            e.getIcon(), // document
            size: 24,
          ),
        ),
        text
      ],
    );
  }

  // I hate this
  // Form _fileNameForm() {
  //   return Form(
  //     key: _formKey,
  //     child: TextFormField(
  //       controller: _fileNameController,
  //       validator: _validateNewName,
  //       onEditingComplete: () {
  //         _renameFile();
  //         _exitEditMode(save: false);
  //       },
  //       // onSaved: (s) => _renameFile(),
  //       focusNode: _focusNode,
  //       decoration: const InputDecoration(
  //         floatingLabelBehavior: FloatingLabelBehavior.never,
  //         focusedErrorBorder: InputBorder.none,
  //         enabledBorder: InputBorder.none,
  //         focusedBorder: UnderlineInputBorder(),
  //         border: InputBorder.none,
  //         disabledBorder: InputBorder.none,
  //         errorBorder: InputBorder.none,
  //         fillColor: null,
  //         filled: false,
  //       ),
  //       enabled: true,
  //       autofocus: false,
  //       maxLines: 1,
  //       autocorrect: false,
  //       enableSuggestions: false,
  //       maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
  //     ),
  //   );
  // }

  String? _validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
  }

  FutureBuilder<DateTime?> _dateCell(FileBrowserDataWrapper e) {
    return FutureBuilder<DateTime?>(
      future: e.fileData.modifiedTime,
      builder: ((context, snapshot) {
        String text = snapshot.error?.toString() ?? "...";

        var date = snapshot.data?.toLocal();

        if (date != null) {
          text = defaultDateFormat.format(date);
        }

        return Text(
          text,
          style: Theme.of(context).textTheme.titleSmall,
        );
      }),
    );
  }

  FutureBuilder<int?> _fileSizeCell(FileBrowserDataWrapper e) {
    return FutureBuilder<int?>(
        future: e.fileData.fileSize,
        builder: ((context, snapshot) {
          final text = snapshot.error?.toString() ??
              (snapshot.data != null ? filesize(snapshot.data) : "...");
          return Text(
            text,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.left,
          );
        }));
  }

  Wrap _actionsRow(FileBrowserDataWrapper e) {
    final actions = [
      // icons
      ConditionalWidget(
        size: null,
        show: !e.fileData.isDirectory,
        child: () => IconButton(
          icon: const Icon(Icons.download_rounded, size: 24),
          onPressed: () async {
            setState(() {
              e.downloading = true;
            });
            await e.saveFileToDesktop();
            setState(() {
              e.downloading = false;
            });
          },
          enableFeedback: false,
          splashRadius: FileDataTable._iconSplashRadius,
        ),
      ),
      ConditionalWidget(
        size: null,
        show: !e.fileData.isDirectory,
        child: () => IconButton(
          icon: const Icon(FluentIcons.glasses_24_filled, size: 24),
          onPressed: e.watchFile,
          splashRadius: FileDataTable._iconSplashRadius,
          tooltip: "Watch",
        ),
      ),
      ConditionalWidget(
          show: !e.fileData.isDirectory,
          size: null,
          child: () => IconButton(
                icon: const Icon(FluentIcons.open_24_filled, size: 24),
                onPressed: e.openTempFile,
                splashRadius: FileDataTable._iconSplashRadius,
                tooltip: "Open (temp)",
              )),

      IconButton(
        // TODO: Add user feedback when this occurs
        icon: const Icon(Icons.copy),
        onPressed: e.copyPathToClipboard,
        splashRadius: FileDataTable._iconSplashRadius,
        tooltip: "Copy to clipboard",
      ),

      IconButton(
        icon: const Icon(Icons.delete_forever),
        onPressed: () => e.removeFileDialog(context),
        splashRadius: FileDataTable._iconSplashRadius,
        tooltip: "Delete",
      ),
    ].reversed.toList(growable: false);

    return Wrap(
      children: actions +
          [
            //download indicator
            // TODO: Center
            ConditionalWidget(
              size: 20,
              show: e.downloading,
              child: () => const CircularProgressIndicator.adaptive(
                value: null,
              ),
            ),
          ],
    );
  }

  Future<void> _renameDialog(FileBrowserDataWrapper fileDataWrapper) async {
    var fileData = fileDataWrapper.fileData;
    String path = fileData.initialFilePath;
    await showDialog<void>(
        context: context,
        builder: ((context) {
          TextEditingController controller =
              TextEditingController(text: fileDataWrapper.friendlyFileName);

          return AlertDialog(
            title: const Text("Rename"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Renaming: $path"),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: controller,
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
              TextButton(
                child: const Text('Ok'),
                onPressed: () async {
                  await fileDataWrapper.renameFile(controller.text);

                  // False positive
                  // ignore: use_build_context_synchronously
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  fileData.browser.refresh();
                },
              ),
            ],
          );
        }));
    setState(() {
      fileDataWrapper.editable = false;
    });
  }
}
