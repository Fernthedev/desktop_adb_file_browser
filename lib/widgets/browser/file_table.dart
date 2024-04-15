import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/file_sort.dart';
import 'package:desktop_adb_file_browser/widgets/adaptive/menu_context.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FileDataTable extends StatefulWidget {
  final List<FileBrowserMetadata> files;
  final ScrollController? scrollController;
  final void Function(FileBrowserMetadata) onWatch;

  const FileDataTable({
    super.key,
    required this.files,
    required this.onWatch,
    this.scrollController,
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
  void didUpdateWidget(covariant FileDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files != widget.files) {
      _onSort(sort, ascending);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sortedFileData == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return FocusTraversalGroup(
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      child: ListView.separated(
        // improve list reorder performance
        findChildIndexCallback: _childIndexFinder,
        controller: widget.scrollController,
        cacheExtent: 1,
        // shrinkWrap: true,
        // addAutomaticKeepAlives: true,
        // + 1 for the header row
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
            key: ValueKey(file.friendlyFileName),
            onWatch: () => widget.onWatch(file),
            file: file,
          );
        },
      ),
    );
  }

  int? _childIndexFinder(key) {
    // if key is header row, just return 0
    if (key is! ValueKey || key == _headerRowKey) {
      return 0;
    }

    return sortedFileData?.indexWhere((e) => e.friendlyFileName == key.value);
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

    var tempSorted = widget.files.toList(growable: false);
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
    return fileSort(a.path, b.path);
  }

  int _sortByDate(FileBrowserMetadata a, FileBrowserMetadata b) {
    var modifiedTime1 = a.date;
    var modifiedTime2 = b.date;
    return modifiedTime1.compareTo(modifiedTime2);
  }

  int _sortBySize(FileBrowserMetadata a, FileBrowserMetadata b) {
    var modifiedSize1 = a.size;
    var modifiedSize2 = b.size;
    return modifiedSize1.compareTo(modifiedSize2);
  }
}

class TableHeaderRow extends StatelessWidget {
  final Function(SortingMethod, bool) onSort;
  final bool ascending;
  final SortingMethod selectedSort;

  const TableHeaderRow({
    super.key,
    required this.onSort,
    required this.ascending,
    required this.selectedSort,
  });

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

class DataRow extends ConsumerStatefulWidget {
  final FileBrowserMetadata file;
  final void Function() onWatch;

  const DataRow({
    super.key,
    required this.file,
    required this.onWatch,
  });

  @override
  ConsumerState<DataRow> createState() => _DataRowState();
}

class _DataRowState extends ConsumerState<DataRow> {
  bool downloading = false;
  final MenuController _menuController = MenuController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();

    // if (_menuController.isOpen) {
    //   _menuController.close();
    // }
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActionsMenu(
      childFocusNode: _focusNode,
      fileData: widget.file,
      menuController: _menuController,
      onWatch: widget.onWatch,
      child: InkWell(
        focusNode: _focusNode,
        // onLongPress: _renameDialog,
        onTap: () {
          if (!widget.file.isDirectory) return;
          
          ref
              .read(fileBrowserProvider.notifier)
              .navigateToDirectory(widget.file.path);
        },
        child: SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _nameCell(widget.file)),
              Expanded(child: _dateCell(widget.file)),
              Expanded(child: _fileSizeCell(widget.file)),
            ],
          ),
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

    var date = e.date.toLocal();

    text = defaultDateFormat.format(date);

    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  Widget _fileSizeCell(FileBrowserMetadata e) {
    var fileSize = e.size;
    final String text = filesize(fileSize);
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall,
      textAlign: TextAlign.left,
    );
  }
}

class _ActionsMenu extends ConsumerWidget {
  const _ActionsMenu({
    required this.fileData,
    required this.child,
    required this.menuController,
    required this.childFocusNode,
    required this.onWatch,
  });

  final FileBrowserMetadata fileData;
  final Widget child;
  final MenuController menuController;
  final FocusNode childFocusNode;
  final void Function() onWatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFile = !fileData.isDirectory;

    var menus = [
      MenuItemButton(
        leadingIcon: const Icon(
          Icons.copy,
        ),
        // TODO: Add user feedback when this occurs
        onPressed: fileData.copyPathToClipboard,
        // TODO: Wait for autoFocus PR to merge https://github.com/flutter/flutter/pull/139396
        // autoFocus: true,
        child: const Text("Copy to clipboard"),
      ),
      MenuItemButton(
        leadingIcon: const Icon(
          Icons.download_rounded,
          size: 24,
        ),
        onPressed: () => fileData.saveFileToDesktop(ref),
        child: const Text("Download"),
      ),
      MenuItemButton(
        leadingIcon: const Icon(
          Icons.edit,
          size: 24,
        ),
        onPressed: () => fileData.renameFileDialog(context),
        child: const Text("Rename"),
      ),
    ];

    if (isFile) {
      final fileActions = [
        MenuItemButton(
            leadingIcon: const Icon(FluentIcons.glasses_24_filled, size: 24),
            onPressed: onWatch,
            child: const Text("Watch changes (desktop -> device)")),
        MenuItemButton(
            leadingIcon: const Icon(FluentIcons.open_24_filled, size: 24),
            onPressed: () => fileData.openTempFile(ref),
            child: const Text("Open (temp)")),
      ];

      menus += fileActions;
    }

    // Make delete last
    menus.add(MenuItemButton(
      leadingIcon: const Icon(Icons.delete_forever),
      onPressed: () => fileData.removeFileDialog(context),
      child: const Text("Delete"),
    ));

    return AdaptiveContextualMenu(
      menuChildren: menus,
      menuController: menuController,
      focusNode: childFocusNode,
      child: child,
    );
  }
}
