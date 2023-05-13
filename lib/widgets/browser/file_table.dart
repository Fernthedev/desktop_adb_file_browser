import 'dart:math';

import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/conditional.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class FileDataTable extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final List<FileBrowserDataWrapper> fileData;
  const FileDataTable({super.key, required this.fileData});

  @override
  State<FileDataTable> createState() => _FileDataTableState();
}

// TODO: Optimize and lazy loading
class _FileDataTableState extends State<FileDataTable> {
  int sort = 0;
  bool ascending = true;

  @override
  Widget build(BuildContext context) {
    onSort(int c, bool a) => setState(() {
          sort = c;
          ascending = a;
        });

    final sortedFiles = widget.fileData.toList(growable: false);
    sortedFiles.sort((a, b) {
      final sortMultiplier = ascending ? 1 : -1;
      // name
      if (sort == 0) {
        return sortMultiplier *
            a.friendlyFileName.compareTo(b.friendlyFileName);
      }

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

    //
    return DataTable(
        // return BetterLazyTable(
        sortAscending: ascending,
        sortColumnIndex: sort,
        columns: [
          DataColumn(label: const Text("Name"), onSort: onSort),
          DataColumn(label: const Text("Date"), numeric: true, onSort: onSort),
          DataColumn(label: const Text("Size"), numeric: true, onSort: onSort),
          const DataColumn(label: Text("Actions"))
        ],
        rows: sortedFiles
            .map((e) => DataRow(cells: [
                  DataCell(
                    _nameCell(e),
                    showEditIcon: !e.editable,
                    onLongPress: () => setState(() {
                      e.editable = !e.editable;
                      _renameDialog(e);
                    }),
                    onDoubleTap: () => setState(() {
                      e.editable = !e.editable;
                    }),
                    onTap: () => e.navigateToDir(),
                  ),
                  DataCell(_dateCell(e)),
                  DataCell(_fileSizeCell(e)),
                  DataCell(_actionsRow(e))
                ]))
            .toList(growable: false));
  }

  Widget _nameCell(FileBrowserDataWrapper e) {
    Widget text;
    if (e.editable && false) {
      text = TextFormField(
        initialValue: e.friendlyFileName,
        onFieldSubmitted: (value) {
          setState(() {
            e.editable = false;
            e.renameFile(value);
          });
        },
        onTapOutside: (_) => setState(() {
          e.editable = false;
        }),
        validator: _validateNewName,
        maxLines: 1,
        enableSuggestions: false,
        autocorrect: false,
        decoration: const InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          focusedErrorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(),
          border: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          fillColor: null,
          filled: false,
        ),
      );

      return text;
    } else {
      text = Text(e.friendlyFileName);
      return Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
                e.fileData.isDirectory
                    ? Icons.folder
                    : FluentIcons.document_24_regular, // document
                size: 24),
          ),
          text
        ],
      );
    }
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
          var year = date.year;

          var day = date.day.toString().padLeft(2, '0');

          var month = date.month.toString().padLeft(2, '0');

          var hour = max(date.hour % 12, 1).toString().padLeft(2, '0');

          var minute = date.minute.toString().padLeft(2, '0');

          var second = date.second.toString().padLeft(2, '0');

          text = "$year-$month-$day $hour:$minute:$second";
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
    return Wrap(
      children: [
        //download indicator
        ConditionalWidget(
          size: 24,
          show: e.downloading,
          child: const SizedBox(
            width: 24,
            child: CircularProgressIndicator.adaptive(
              value: null,
            ),
          ),
        ),
        // icons
        ConditionalWidget(
          size: 24,
          show: !e.fileData.isDirectory,
          child: IconButton(
            icon: const Icon(Icons.download_rounded, size: 24),
            onPressed: e.saveFileToDesktop,
            enableFeedback: false,
            splashRadius: FileDataTable._iconSplashRadius,
          ),
        ),
        ConditionalWidget(
          size: 24,
          show: !e.fileData.isDirectory,
          child: IconButton(
            icon: const Icon(FluentIcons.glasses_24_filled, size: 24),
            onPressed: e.watchFile,
            splashRadius: FileDataTable._iconSplashRadius,
            tooltip: "Watch",
          ),
        ),
        ConditionalWidget(
            show: !e.fileData.isDirectory,
            size: 24,
            child: IconButton(
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
                TextFormField(
                  controller: controller,
                  validator: _validateNewName,
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
