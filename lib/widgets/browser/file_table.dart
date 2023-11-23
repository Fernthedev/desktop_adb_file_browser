import 'dart:async';

import 'package:desktop_adb_file_browser/utils/file_sort.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/conditional.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FileDataTable extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final List<FileBrowserMetadata> originalFileData;
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
  List<FileBrowserMetadata>? sortedFileData;

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
      // shrinkWrap: true,
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
        );
      },
    );
  }

  void _onSort(SortingMethod s, bool a) async {
    var tempSorted = _sortList(s, a);

    if (!mounted) return;

    setState(() {
      sort = s;
      ascending = a;

      sortedFileData = tempSorted;
    });
  }

  List<FileBrowserMetadata> _sortList(
      SortingMethod sortingMethod, bool ascending) {
    var sortMethod = switch (sortingMethod) {
      SortingMethod.name => _sortByName,
      SortingMethod.date => _sortByDate,
      SortingMethod.fileSize => _sortBySize,
    };

    var tempSorted = widget.originalFileData.toList(growable: false);
    // Reverse
    if (!ascending) {
      var oldSortMethod = sortMethod;
      sortMethod =
          (FileBrowserMetadata a, FileBrowserMetadata b) => oldSortMethod(b, a);
    }

    tempSorted.sort(sortMethod);

    return tempSorted;
  }

  int _sortByName(FileBrowserMetadata a, FileBrowserMetadata b) {
    return fileSort(a.fullFilePath, b.fullFilePath);
  }

  int _sortByDate(FileBrowserMetadata a, FileBrowserMetadata b) {
    var modifiedTime1 = a.fileData.modifiedTime;
    var modifiedTime2 = b.fileData.modifiedTime;
    if (modifiedTime1 == null || modifiedTime2 == null) {
      return 0;
    }
    return modifiedTime1.compareTo(modifiedTime2);
  }

  int _sortBySize(FileBrowserMetadata a, FileBrowserMetadata b) {
    var modifiedSize1 = a.fileData.fileSize;
    var modifiedSize2 = b.fileData.fileSize;
    if (modifiedSize1 == null || modifiedSize2 == null) {
      return 0;
    }
    return modifiedSize1.compareTo(modifiedSize2);
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
  final FileBrowserMetadata file;

  const DataRow({
    super.key,
    required this.file,
  });

  @override
  State<DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<DataRow> {
  bool downloading = false;
  bool editable = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        setState(() {
          editable = !editable;
          _renameDialog(widget.file);
        });
      },
      onTap: () => widget.file.navigateToDir(),
      child: SizedBox(
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _nameCell(widget.file)),
            Expanded(child: _dateCell(widget.file)),
            Expanded(child: _fileSizeCell(widget.file)),
            Expanded(child: _actionsCell(widget.file)),
          ],
        ),
      ),
    );
  }

  Widget _nameCell(FileBrowserMetadata e) {
    Widget text = Text(
      e.friendlyFileName,
      overflow: TextOverflow.ellipsis,
    );
    
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
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

  Widget _dateCell(FileBrowserMetadata e) {
    String text = "...";

    var date = e.fileData.modifiedTime?.toLocal();

    if (date != null) {
      text = defaultDateFormat.format(date);
    }

    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  Widget _fileSizeCell(FileBrowserMetadata e) {
    var fileSize = e.fileData.fileSize;
    final text = fileSize != null ? filesize(fileSize) : "...";
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
      textAlign: TextAlign.left,
    );
  }

  Widget _actionsCell(FileBrowserMetadata e) {
    return _ActionsCell(fileData: e);
  }

  Future<void> _renameDialog(FileBrowserMetadata fileDataWrapper) async {
    var fileData = fileDataWrapper.fileData;
    String path = fileData.fullFilePath;
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
      editable = false;
    });
  }

  String? _validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
  }
}

class _ActionsCell extends StatefulWidget {
  const _ActionsCell({
    super.key,
    required this.fileData,
  });

  final FileBrowserMetadata fileData;

  @override
  State<_ActionsCell> createState() => _ActionsCellState();
}

class _ActionsCellState extends State<_ActionsCell> {
  @override
  Widget build(BuildContext context) {
    const tooltipDuration = Duration(milliseconds: 500);

    final actions = <Widget>[
      // icons
      ConditionalWidget(
        size: null,
        show: !widget.fileData.fileData.isDirectory,
        child: () {
          return Tooltip(
            message: "Watch changes (desktop -> device)",
            waitDuration: tooltipDuration,
            child: IconButton(
              icon: const Icon(FluentIcons.glasses_24_filled, size: 24),
              onPressed: () async {
                await widget.fileData.watchFile();
              },
              splashRadius: FileDataTable._iconSplashRadius,
            ),
          );
        },
      ),
      ConditionalWidget(
          show: !widget.fileData.fileData.isDirectory,
          size: null,
          child: () => Tooltip(
                message: "Open (temp)",
                waitDuration: tooltipDuration,
                child: IconButton(
                  icon: const Icon(FluentIcons.open_24_filled, size: 24),
                  onPressed: widget.fileData.openTempFile,
                  splashRadius: FileDataTable._iconSplashRadius,
                ),
              )),
      Tooltip(
        waitDuration: tooltipDuration,
        message: "Download",
        child: IconButton(
          icon: const Icon(Icons.download_rounded, size: 24),
          onPressed: () async {
            await widget.fileData.saveFileToDesktop();
          },
          enableFeedback: false,
          splashRadius: FileDataTable._iconSplashRadius,
        ),
      ),

      Tooltip(
        message: "Copy to clipboard",
        waitDuration: tooltipDuration,
        child: IconButton(
          // TODO: Add user feedback when this occurs
          icon: const Icon(Icons.copy),
          onPressed: widget.fileData.copyPathToClipboard,
          splashRadius: FileDataTable._iconSplashRadius,
        ),
      ),

      Tooltip(
        message: "Delete",
        waitDuration: tooltipDuration,
        child: IconButton(
          icon: const Icon(Icons.delete_forever),
          onPressed: () => widget.fileData.removeFileDialog(context),
          splashRadius: FileDataTable._iconSplashRadius,
        ),
      ),
    ].reversed.toList(growable: false);

    //download indicator
    // TODO: Center
    var downloadingIndicator = ConditionalWidget(
      size: 20,
      show: false,
      child: () => const CircularProgressIndicator.adaptive(
        value: null,
      ),
    );

    return Wrap(
      children: actions + [downloadingIndicator],
    );
  }
}
