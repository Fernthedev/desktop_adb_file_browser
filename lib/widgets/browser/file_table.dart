import 'package:desktop_adb_file_browser/utils/file_sort.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/conditional.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class FileDataTable extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final List<FileBrowserDataWrapper> originalFileData;
  const FileDataTable({super.key, required this.originalFileData});

  @override
  State<FileDataTable> createState() => _FileDataTableState();
}

final defaultDateFormat = DateFormat("yyyy-MM-dd hh:mm aa");

enum SortingMethod { name, date, fileSize }

// TODO: Optimize and lazy loading
class _FileDataTableState extends State<FileDataTable> {
  static const sortDefault = SortingMethod.name;
  static const ascendingDefault = true;

  SortingMethod sort = sortDefault;
  bool ascending = ascendingDefault;
  late List<FileBrowserDataWrapper> sortedFileData;

  @override
  void initState() {
    super.initState();

    sortedFileData = widget.originalFileData;
    _onSort(sort, ascending);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: sortedFileData.length * 2,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          // Divider
          return const Divider(height: 1);
        }

        final contentIndex = index ~/ 2; // Adjust the index for actual content
        if (contentIndex == 0) {
          // Header row
          return TableHeaderRow(
            onSort: _onSort,
            ascending: ascending,
            selectedSort: sort,
          );
        }

        // Data rows
        final file = sortedFileData[contentIndex - 1];
        return DataRow(
          file: file,
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
    var tempSorted = _sortList(s, a);

    if (!mounted) return;

    setState(() {
      sort = s;
      ascending = a;

      sortedFileData = tempSorted;
    });
  }

  List<FileBrowserDataWrapper> _sortList(
      SortingMethod sortingMethod, bool ascending) {
    var sortMethod = switch (sortingMethod) {
      SortingMethod.name => _sortByName,
      SortingMethod.date => null,
      SortingMethod.fileSize => null,
    };
    sortMethod ??= _sortByName;

    var tempSorted = widget.originalFileData.toList(growable: false);
    // Reverse
    if (!ascending) {
      var oldSortMethod = sortMethod;
      sortMethod = (FileBrowserDataWrapper a, FileBrowserDataWrapper b) =>
          oldSortMethod(b, a);
    }

    tempSorted.sort(sortMethod);

    return tempSorted;
  }

  int _sortByName(FileBrowserDataWrapper a, FileBrowserDataWrapper b) {
    return fileSort(a.fullFilePath, b.fullFilePath);
  }

  // TODO: Await futures somehow
  int _sortByDate(FileBrowserDataWrapper a, FileBrowserDataWrapper b) {
    return 0;
  }

  int _sortBySize(FileBrowserDataWrapper a, FileBrowserDataWrapper b) {
    return 0;
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
            label: "Date",
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
            child: InkWell(
          // showEditIcon: !file.editable,
          onLongPress: widget.onLongPress,
          onTap: widget.onTap,
          child: _nameCell(widget.file),
        )),
        Expanded(child: InkWell(child: _dateCell(widget.file))),
        Expanded(child: InkWell(child: _fileSizeCell(widget.file))),
        Expanded(child: InkWell(child: _actionsRow(widget.file, context))),
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

  Widget _actionsRow(FileBrowserDataWrapper e, BuildContext context) {
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
          onPressed: () async {
            setState(() {
              e.downloading = true;
            });
            await e.watchFile();
            setState(() {
              e.downloading = false;
            });
          },
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
}
