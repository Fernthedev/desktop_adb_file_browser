import 'dart:async';

import 'package:desktop_adb_file_browser/utils/file_sort.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/conditional.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

class FileDataTable extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final List<FileBrowserDataWrapper> originalFileData;
  final ScrollController scrollController;
  const FileDataTable({
    super.key,
    required this.originalFileData,
    required this.scrollController,
  });

  @override
  State<FileDataTable> createState() => _FileDataTableState();
}

final defaultDateFormat = DateFormat("yyyy-MM-dd hh:mm aa");

enum SortingMethod { name, date, fileSize }

class _FileDataTableState extends State<FileDataTable> {
  static const sortDefault = SortingMethod.name;
  static const ascendingDefault = true;

  SortingMethod sort = sortDefault;
  bool ascending = ascendingDefault;
  List<FileBrowserDataWrapper>? sortedFileData;

  final _headerRowKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    _onSort(sort, ascending);
  }

  @override
  Widget build(BuildContext context) {
    if (sortedFileData == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return ListView.separated(
      // + 1 for the header row
      controller: widget.scrollController,
      shrinkWrap: true,
      addAutomaticKeepAlives: true,
      itemCount: sortedFileData!.length + 1,
      separatorBuilder: (c, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header row
          return TableHeaderRow(
            key: _headerRowKey,
            onSort: _onSort,
            ascending: ascending,
            selectedSort: sort,
          );
        }

        // Data rows
        final file = sortedFileData![index - 1];
        return DataRow(
          file: file,
          key: ValueKey(file.friendlyFileName),
          onLongPress: () {
            setState(() {
              file.editable = !file.editable;
              _renameDialog(file);
            });
          },
          onTap: () => file.navigateToDir(),
        );
      },
    );
  }

  void _onSort(SortingMethod s, bool a) async {
    var tempSorted = await _sortList(s, a);
    // var tempSorted = await SchedulerBinding.instance.scheduleTask(
    //   () => _sortList(s, a),
    //   Priority.idle,
    // );

    if (!mounted) return;

    setState(() {
      sort = s;
      ascending = a;

      sortedFileData = tempSorted;
    });
  }

  Future<List<FileBrowserDataWrapper>> _sortList(
      SortingMethod sortingMethod, bool ascending) async {
    var tempSorted = widget.originalFileData.toList(growable: false);
    var sortMethod = switch (sortingMethod) {
      SortingMethod.name => _sortByName,
      SortingMethod.date => _sortByDate,
      SortingMethod.fileSize => _sortBySize,
    };
    tempSorted = await sortMethod(tempSorted);

    // Reverse
    if (!ascending) {
      tempSorted = tempSorted.reversed.toList(growable: false);
    }

    return tempSorted;
  }

  Future<List<FileBrowserDataWrapper>> _sortByName(
      List<FileBrowserDataWrapper> l) async {
    l.sort((a, b) => fileSort(a.fullFilePath, b.fullFilePath));

    return l;
  }

  Future<List<FileBrowserDataWrapper>> _sortByDate(
      List<FileBrowserDataWrapper> l) async {
    var datesFutures = l
        .map((e) =>
            e.fileData.modifiedTime.then((dateTime) => Tuple2(e, dateTime)))
        .toList(growable: false);

    var dateSorted = await Future.wait(datesFutures);
    dateSorted.sort((a, b) {
      if (a.item2 == null || b.item2 == null) {
        return 0;
      }

      return a.item2!.compareTo(b.item2!);
    });

    return dateSorted.map((e) => e.item1).toList(growable: false);
  }

  Future<List<FileBrowserDataWrapper>> _sortBySize(
      List<FileBrowserDataWrapper> l) async {
    var sizeFutures = l
        .map((e) => e.fileData.fileSize.then((fileSize) => Tuple2(e, fileSize)))
        .toList(growable: false);

    var sizeSorted = await Future.wait(sizeFutures);
    sizeSorted.sort((a, b) {
      if (a.item2 == null || b.item2 == null) {
        return 0;
      }

      return a.item2!.compareTo(b.item2!);
    });

    return sizeSorted.map((e) => e.item1).toList(growable: false);
  }

  String? _validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
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

class TableHeaderRow extends StatelessWidget {
  final Function(SortingMethod, bool) onSort;
  final bool ascending;
  final SortingMethod selectedSort;

  const TableHeaderRow(
      {super.key,
      required this.onSort,
      required this.ascending,
      required this.selectedSort});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        HeaderCell(
            label: "Name",
            selected: selectedSort == SortingMethod.name,
            ascending: ascending,
            onSort: () => onSort(SortingMethod.name, !ascending)),
        HeaderCell(
            label: "Modified Date",
            numeric: true,
            selected: selectedSort == SortingMethod.date,
            ascending: ascending,
            onSort: () => onSort(SortingMethod.date, !ascending)),
        HeaderCell(
            label: "Size",
            numeric: true,
            selected: selectedSort == SortingMethod.fileSize,
            ascending: ascending,
            onSort: () => onSort(SortingMethod.fileSize, !ascending)),
        const HeaderCell(label: "Actions"),
      ],
    );
  }
}

class HeaderCell extends StatelessWidget {
  final String label;
  final bool numeric;
  final VoidCallback? onSort;
  final bool selected;
  final bool ascending;

  const HeaderCell({
    super.key,
    required this.label,
    this.numeric = false,
    this.onSort,
    this.ascending = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final arrowIcon = ascending
        ? FluentIcons.arrow_up_24_regular
        : FluentIcons.arrow_down_24_regular;

    return Expanded(
      child: InkWell(
        onTap: onSort,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
              ),
              Visibility(
                visible: selected,
                child: Icon(
                  arrowIcon,
                  size: 20,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DataRow extends StatefulWidget {
  final FileBrowserDataWrapper file;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const DataRow({
    super.key,
    required this.file,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  State<DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<DataRow> {
  bool downloading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: InkWell(
          onLongPress: widget.onLongPress,
          onTap: widget.onTap,
          child: _nameCell(widget.file),
        )),
        Expanded(child: _dateCell(widget.file)),
        Expanded(child: _fileSizeCell(widget.file)),
        Expanded(child: _actionsCell(widget.file)),
      ],
    );
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

  Widget _dateCell(FileBrowserDataWrapper e) {
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

  Widget _fileSizeCell(FileBrowserDataWrapper e) {
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

  Widget _actionsCell(FileBrowserDataWrapper e) {
    return _ActionsCell(fileData: e);
  }
}

class _ActionsCell extends StatefulWidget {
  const _ActionsCell({
    super.key,
    required this.fileData,
  });

  final FileBrowserDataWrapper fileData;

  @override
  State<_ActionsCell> createState() => _ActionsCellState();
}

class _ActionsCellState extends State<_ActionsCell> {
  @override
  Widget build(BuildContext context) {
    final actions = [
      // icons
      ConditionalWidget(
        size: null,
        show: !widget.fileData.fileData.isDirectory,
        child: () => IconButton(
          icon: const Icon(Icons.download_rounded, size: 24),
          onPressed: () async {
            setState(() {
              widget.fileData.downloading = true;
            });
            await widget.fileData.saveFileToDesktop();
            setState(() {
              widget.fileData.downloading = false;
            });
          },
          enableFeedback: false,
          splashRadius: FileDataTable._iconSplashRadius,
        ),
      ),
      ConditionalWidget(
        size: null,
        show: !widget.fileData.fileData.isDirectory,
        child: () => IconButton(
          icon: const Icon(FluentIcons.glasses_24_filled, size: 24),
          onPressed: () async {
            setState(() {
              widget.fileData.downloading = true;
            });
            await widget.fileData.watchFile();
            setState(() {
              widget.fileData.downloading = false;
            });
          },
          splashRadius: FileDataTable._iconSplashRadius,
          tooltip: "Watch",
        ),
      ),
      ConditionalWidget(
          show: !widget.fileData.fileData.isDirectory,
          size: null,
          child: () => IconButton(
                icon: const Icon(FluentIcons.open_24_filled, size: 24),
                onPressed: widget.fileData.openTempFile,
                splashRadius: FileDataTable._iconSplashRadius,
                tooltip: "Open (temp)",
              )),

      IconButton(
        // TODO: Add user feedback when this occurs
        icon: const Icon(Icons.copy),
        onPressed: widget.fileData.copyPathToClipboard,
        splashRadius: FileDataTable._iconSplashRadius,
        tooltip: "Copy to clipboard",
      ),

      IconButton(
        icon: const Icon(Icons.delete_forever),
        onPressed: () => widget.fileData.removeFileDialog(context),
        splashRadius: FileDataTable._iconSplashRadius,
        tooltip: "Delete",
      ),
    ].reversed.toList(growable: false);

    //download indicator
    // TODO: Center
    var downloadingIndicator = ConditionalWidget(
      size: 20,
      show: widget.fileData.downloading,
      child: () => const CircularProgressIndicator.adaptive(
        value: null,
      ),
    );

    return Wrap(
      children: actions + [downloadingIndicator],
    );
  }
}
