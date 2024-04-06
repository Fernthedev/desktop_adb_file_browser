import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:open_file/open_file.dart';
import 'package:routemaster/routemaster.dart';
import 'package:trace/trace.dart';
import 'package:tuple/tuple.dart';

import 'package:desktop_adb_file_browser/main.dart';
import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:desktop_adb_file_browser/riverpod/file_queue.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_table.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_widget.dart';
import 'package:desktop_adb_file_browser/widgets/progress_snackbar.dart';
import 'package:desktop_adb_file_browser/widgets/shortcuts.dart';
import 'package:desktop_adb_file_browser/widgets/watchers.dart';

@immutable
class DeviceBrowserPage extends ConsumerStatefulWidget {
  final String serial;

  const DeviceBrowserPage(
      {super.key, required this.serial});

  @override
  ConsumerState<DeviceBrowserPage> createState() => _DeviceBrowserPageState();
}

// ignore: constant_identifier_names
enum FileCreation { File, Folder }

// TODO: Gestures
// TODO: Add download progress snackbar (similar to upload progress)
// TODO: Make snackbar progress animation ease exponential because it looks
// TODO: File details page
class _DeviceBrowserPageState extends ConsumerState<DeviceBrowserPage> {
  bool _viewAsListMode = true;
  bool _dragging = false;

  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();

    onForwardClick = native2flutter.mouseForwardClick
        .addListener((_) => ref.read(fileBrowserProvider.notifier).forward());
    onBackClick = native2flutter.mouseBackClick
        .addListener((_) => ref.read(fileBrowserProvider.notifier).back());
  }

  @override
  void dispose() {
    super.dispose();
    onForwardClick.dispose();
    onBackClick.dispose();

    _filterController.dispose();
  }

  late ListenableHolder<void> onForwardClick;
  late ListenableHolder<void> onBackClick;

  final EventListenable<Tuple2<HostPath, QuestPath>> onWatchAdd =
      EventListenable();

  @override
  Widget build(BuildContext context) {
    // Download Snackbar
    ref.listen(downloadQueueProvider, _showDownloadSnackbar);
    // Upload Snackbar
    ref.listen(uploadQueueProvider, _showUploadSnackbar);

    var listViewButton = IconButton(
      icon: Icon(_viewAsListMode ? Icons.list : Icons.grid_3x3),
      onPressed: () {
        setState(() {
          _viewAsListMode = !_viewAsListMode;
        });
      },
    );

    var exitButton = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Ink(
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          shape: const CircleBorder(),
        ),
        child: IconButton(
          icon: const Icon(FluentIcons.cube_24_regular),
          onPressed: () {
            Routemaster.of(context).history.back();
          },
        ),
      ),
    );

    var conditionalExitButton =
        Routemaster.of(context).history.canGoBack ? exitButton : null;

    return Focus(
      autofocus: true,
      canRequestFocus: false,
      descendantsAreFocusable: true,
      skipTraversal: true,
      onKey: _onKeyHandler,
      child: DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            elevation: 2.8,
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: _AppBarActions(
              serial: widget.serial,
              onUpload: _uploadFiles,
              filterController: _filterController,
            ),
            leading: conditionalExitButton,
            automaticallyImplyLeading: true,
            actions: [listViewButton],
          ),
          body: _buildBody(),
          bottomNavigationBar: SizedBox(
            height: Theme.of(context).buttonTheme.height,
            child: const _PathBreadCumbs(),
          ),
        ),
      ),
    );
  }

  MultiSplitViewTheme _buildBody() {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(dividerThickness: 5.5),
      child: MultiSplitView(
        initialAreas: [Area(weight: 0.15)],
        children: [
          _ShortcutsColumn(
            serial: widget.serial,
            onWatchAdd: onWatchAdd,
          ),
          Center(child: _fileListContainer())
        ],
        dividerBuilder:
            (axis, index, resizable, dragging, highlighted, themeData) =>
                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 0.5,
                    color: Colors.black),
      ),
    );
  }

  KeyEventResult _onKeyHandler(FocusNode node, RawKeyEvent event) {
    final fileBrowser = ref.read(fileBrowserProvider.notifier);
    if (!event.repeat && event.isAltPressed) {
      if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
        fileBrowser.back();
        return KeyEventResult.handled;
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
        fileBrowser.forward();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  DropTarget _fileListContainer() {
    return DropTarget(
      onDragDone: (detail) => _uploadFiles(detail.files.map((e) => e.path)),
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        color:
            _dragging ? Theme.of(context).primaryColor.withOpacity(0.4) : null,
        child: _FilteredListContainer(
          filterController: _filterController,
          builder: (context, filteredFiles) => _viewAsListMode
              ? _viewAsList(filteredFiles)
              : _viewAsGrid(filteredFiles),
        ),
      ),
    );
  }

  Widget _viewAsList(List<FileBrowserMetadata> files) {
    return Align(
      alignment: Alignment.topCenter,
      child: FileDataTable(
        key: ValueKey(files),
        onWatch: _watchFile,
        files: files,
      ),
    );
  }

  Widget _viewAsGrid(List<FileBrowserMetadata> files) {
    return GridView.builder(
        key: ValueKey(files),
        shrinkWrap: true,
        padding: const EdgeInsets.all(4.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          childAspectRatio: 17.0 / 9.0,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
          maxCrossAxisExtent: 280,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          var file = files[index];

          return GridTile(
              child: FileCardWidget(
            key: ValueKey(file),
            onWatch: () => _watchFile(file),
            isCard: true,
            fileData: file,
          ));
        });
  }

  void _uploadFiles(Iterable<String> paths) async {
    final fileBrowser = ref.read(fileBrowserProvider);
    final uploadQueue = ref.read(uploadQueueProvider.notifier);

    Trace.verbose("Uploading $paths");
    var tasks = paths.map((path) {
      String dest = Adb.adbPathContext.join(
          fileBrowser.address, // adb file path
          Adb.hostPath.basename(path) // host file name
          );

      final future = ref
          .read(uploadQueueProvider.notifier)
          .doUpload(widget.serial, path, dest);

      // C:\Users\foo.txt -> currentPath/foo.txt
      return future;
    });

    uploadQueue.addAllQueue(tasks);
  }

  Future<void> _watchFile(FileBrowserMetadata fileData) async {
    String? savePath = await fileData.saveFileToDesktop(ref);
    if (savePath == null) {
      return;
    }

    var source = fileData.path;

    onWatchAdd.invoke(Tuple2(savePath, source));
  }

  // TODO: Make this a widget ancestor
  void _showDownloadSnackbar(Set<Future>? previous, Set<Future> next) async {
    if (next.isEmpty) return;
    if (previous != null && previous.isNotEmpty) {
      return;
    }

    // Snack bar
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const DownloadQueueSnackbar(),
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

    await Future.wait(next);
    ref.invalidate(deviceFileListingProvider);

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }

  // TODO: Make this a widget ancestor
  void _showUploadSnackbar(Set<Future>? previous, Set<Future> next) async {
    if (next.isEmpty) return;
    if (previous != null && previous.isNotEmpty) {
      return;
    }

    // Snack bar
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const UploadQueueSnackbar(),
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

    await Future.wait(next);
    ref.invalidate(deviceFileListingProvider);

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }
}

class _FilteredListContainer extends ConsumerStatefulWidget {
  const _FilteredListContainer({
    super.key,
    required this.filterController,
    required this.builder,
  });

  final TextEditingController filterController;

  final Widget Function(
      BuildContext context, List<FileBrowserMetadata> filteredFiles) builder;

  @override
  ConsumerState<_FilteredListContainer> createState() =>
      _FilteredListContainerState();
}

class _FilteredListContainerState
    extends ConsumerState<_FilteredListContainer> {
  String? filter;

  @override
  void initState() {
    super.initState();

    widget.filterController.addListener(_doFilterFiles);
  }

  @override
  void dispose() {
    super.dispose();

    widget.filterController.removeListener(_doFilterFiles);
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(filteredFileInfoListingProvider(filter));

    return filesAsync.when(
      data: (files) => widget.builder(context, files),
      error: (e, s) => Center(
        child: Text("Error loading file: $e"),
      ),
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            )
          ],
        ),
      ),
    );
  }

  void _doFilterFiles() {
    final newFilter = widget.filterController.text.trim();

    if (filter == newFilter || (newFilter.isEmpty == (filter == null))) return;

    setState(() {
      if (newFilter.isEmpty) {
        filter = null;
      } else {
        filter = newFilter;
      }
    });
  }
}

class _PathBreadCumbs extends ConsumerWidget {
  const _PathBreadCumbs({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileBrowser = ref.watch(fileBrowserProvider);

    var currentPath = fileBrowser.address;
    var locations = currentPath.split("/");

    if (locations.isNotEmpty && locations.first.isEmpty) {
      locations.removeAt(0);
    }

// prepend previous directory to location
    for (int i = 1; i < locations.length; i++) {
      locations[i] = Adb.adbPathContext.join(locations[i - 1], locations[i]);
    }

    return Container(
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      child: BreadCrumb(
        key: ValueKey(fileBrowser.address),
        items: locations
            .map((e) => BreadCrumbItem(
                  borderRadius: BorderRadius.circular(4),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      Adb.adbPathContext.basename(e),
                    ),
                  ),
                  onTap: () => ref
                      .read(fileBrowserProvider.notifier)
                      .navigateToDirectory(e),
                ))
            .toList(growable: false),
        divider: const Icon(
          FluentIcons.chevron_right_28_regular,
          size: 28,
        ),
        overflow: ScrollableOverflow(
          keepLastDivider: false,
          reverse: false,
          direction: Axis.horizontal,
        ),
        // divider: Icon(Icons.chevron_right),
      ),
    );
  }
}

class _AppBarActions extends ConsumerStatefulWidget {
  const _AppBarActions({
    super.key,
    required this.serial,
    required this.onUpload,
    required this.filterController,
  });

  final String serial;
  final void Function(Iterable<String> paths) onUpload;
  final TextEditingController filterController;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppBarActionsState();
}

class _AppBarActionsState extends ConsumerState<_AppBarActions> {
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _addressController.text = ref.read(fileBrowserProvider).address;
  }

  @override
  void dispose() {
    super.dispose();
    _addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileBrowserProvider, (previous, next) {
      _addressController.text = next.address;
    });

    return Row(
      children: [
        _navigationActions(ref),
        _addressBar(ref),
        _filterBar(),
        _fileActions(context)
      ],
    );
  }

  Widget _navigationActions(WidgetRef ref) {
    var backButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_left_20_regular),
      onPressed: () {
        ref.read(fileBrowserProvider.notifier).back();
      },
    );

    var forwardButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_right_20_regular),
      onPressed: () {
        ref.read(fileBrowserProvider.notifier).forward();
      },
    );

    var topLevelButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.folder_arrow_up_20_regular),
      onPressed: () {
        final currentPath = ref.read(fileBrowserProvider).address;
        ref
            .read(fileBrowserProvider.notifier)
            .navigateToDirectory(Adb.adbPathContext.dirname(currentPath));
      },
    );
    var refreshButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
      onPressed: () {
        ref.invalidate(deviceFileListingProvider);
      },
    );
    return Wrap(
      children: [
        backButton,
        forwardButton,
        topLevelButton,
        refreshButton,
      ],
    );
  }

  Widget _addressBar(WidgetRef ref) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _addressController,
          autocorrect: false,
          onSubmitted: (s) {
            final fileBrowser = ref.read(fileBrowserProvider);
            if (s == fileBrowser.address) {
              ref.invalidate(deviceFileListingProvider);
            } else {
              ref.read(fileBrowserProvider.notifier).navigateToDirectory(s);
            }
          },
          decoration: const InputDecoration(
            // cool animation border effect
            // this makes it rectangular when not selected
            border: OutlineInputBorder(),
            isDense: true,
            hintText: 'Path',
            constraints: BoxConstraints.tightFor(height: 40),
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: widget.filterController,
          autocorrect: false,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
            constraints: BoxConstraints.tightFor(height: 40),
            hintText: 'Search',
          ),
        ),
      ),
    );
  }

  Wrap _fileActions(BuildContext context) {
    var uploadButton = IconButton(
      splashRadius: 20,
      icon: const Icon(
        FluentIcons.folder_add_20_regular,
      ),
      tooltip: "Upload file or folder",
      onPressed: () {
        openFiles().then((value) {
          if (value.isEmpty) return;
          widget.onUpload(value.map((e) => e.path));
        });
      },
    );

    var createFile = IconButton(
      splashRadius: 20,
      icon: const Icon(
        FluentIcons.add_20_regular,
      ),
      tooltip: "Add new file",
      onPressed: () {
        _showNewFileDialog(context);
      },
    );

    return Wrap(
      children: [
        uploadButton,
        createFile,
      ],
    );
  }

  Future<void> _showNewFileDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return NewFileDialog(
          serial: widget.serial,
        );
      },
    );
  }
}

class NewFileDialog extends ConsumerStatefulWidget {
  const NewFileDialog({
    super.key,
    required this.serial,
  });

  final String serial;

  @override
  ConsumerState<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends ConsumerState<NewFileDialog> {
  final TextEditingController fileNameController = TextEditingController();
  FileCreation fileCreation = FileCreation.File;

  @override
  void dispose() {
    super.dispose();
    fileNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileBrowser = ref.watch(fileBrowserProvider);

    var cancelButton = TextButton(
      child: const Text('Cancel'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    var confirmButton = FilledButton(
      child: const Text('Ok'),
      onPressed: () {
        var path = Adb.adbPathContext
            .join(fileBrowser.address, fileNameController.text);

        Future task = switch (fileCreation) {
          FileCreation.File => Adb.createFile(widget.serial, path),
          FileCreation.Folder => Adb.createDirectory(widget.serial, path)
        };

        task.then((_) {
          ref.invalidate(deviceFileListingProvider);
          Navigator.of(context).pop();
        });
      },
    );

    return AlertDialog(
      title: const Text('Create new file'),
      content: _contentDialog(),
      actions: <Widget>[
        cancelButton,
        confirmButton,
      ],
    );
  }

  Widget _contentDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: fileNameController,
          autocorrect: false,
          autofocus: true,
          decoration: const InputDecoration(hintText: "New file"),
        ),
        const SizedBox(
          height: 20,
        ),
        _fileSegmentButton()
      ],
    );
  }

  Widget _fileSegmentButton() {
    return SegmentedButton<FileCreation>(
      segments: const [
        ButtonSegment(
          value: FileCreation.File,
          label: Text("File"),
          icon: Icon(FluentIcons.document_24_regular),
        ),
        ButtonSegment(
          value: FileCreation.Folder,
          label: Text("Folder"),
          icon: Icon(FluentIcons.folder_24_regular),
        ),
      ],
      selected: {fileCreation},
      onSelectionChanged: (newSelection) => setState(() {
        fileCreation = newSelection.firstOrNull ?? fileCreation;
      }),
    );
  }
}

class _ShortcutsColumn extends ConsumerWidget {
  const _ShortcutsColumn({
    super.key,
    required this.serial,
    required this.onWatchAdd,
  });

  final String serial;
  final EventListenable<Tuple2<HostPath, QuestPath>> onWatchAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            children: [
              ShortcutsListWidget(
                onTap: (s) => ref
                    .read(fileBrowserProvider.notifier)
                    .navigateToDirectory(s),
              ),
              FileWatcherList(serial: serial, onUpdate: onWatchAdd)
            ],
          ),
        ),
        const TabBar(tabs: [
          Tab(
              icon: Tooltip(
            message: "Bookmarks",
            child: Icon(
              FluentIcons.bookmark_20_filled,
              size: 20,
            ),
          )),
          Tab(
              icon: Tooltip(
            message: "Watched files",
            child: Icon(
              FluentIcons.glasses_20_filled,
              size: 20,
            ),
          ))
        ]),
      ],
    );
  }
}
