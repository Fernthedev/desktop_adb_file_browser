import 'dart:async';

import 'package:desktop_adb_file_browser/widgets/adb_queue_indicator.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:routemaster/routemaster.dart';
import 'package:trace/trace.dart';
import 'package:tuple/tuple.dart';

import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:desktop_adb_file_browser/riverpod/file_queue.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_table.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_widget.dart';
import 'package:desktop_adb_file_browser/widgets/shortcuts.dart';
import 'package:desktop_adb_file_browser/widgets/watchers.dart';

@immutable
class DeviceBrowserPage extends ConsumerStatefulWidget {
  final String serial;

  const DeviceBrowserPage({super.key, required this.serial});

  @override
  ConsumerState<DeviceBrowserPage> createState() => _DeviceBrowserPageState();
}

// TODO: Gestures
// TODO: File details page
class _DeviceBrowserPageState extends ConsumerState<DeviceBrowserPage> {
  bool _viewAsListMode = true;
  bool _dragging = false;

  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _filterController.dispose();
  }

  late ListenableHolder<void> onForwardClick;
  late ListenableHolder<void> onBackClick;

  final EventListenable<Tuple2<HostPath, QuestPath>> onWatchAdd =
      EventListenable();

  @override
  Widget build(BuildContext context) {
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

    return FocusableActionDetector(
      autofocus: true,
      descendantsAreFocusable: true,
      actions: <Type, Action<Intent>>{
        NavigateForwardIntent: CallbackAction<NavigateForwardIntent>(
            onInvoke: (intent) =>
                ref.read(fileBrowserProvider.notifier).forward()),
        NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (intent) =>
                ref.read(fileBrowserProvider.notifier).back()),
        NavigateTopIntent: CallbackAction<NavigateTopIntent>(
            onInvoke: (intent) =>
                ref.read(fileBrowserProvider.notifier).gotoTopDirectory()),
        RefreshListingIntent: CallbackAction<RefreshListingIntent>(
            onInvoke: (intent) => ref.invalidate(deviceFileListingProvider)),
      },
      shortcuts: <LogicalKeySet, Intent>{
        // back
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft):
            const NavigateBackIntent(),
        LogicalKeySet(
                LogicalKeyboardKey.control, LogicalKeyboardKey.browserBack):
            const NavigateBackIntent(),

        // forward
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight):
            const NavigateForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.browserForward):
            const NavigateBackIntent(),

        // top
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp):
            const NavigateTopIntent(),

        // refresh
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            const RefreshListingIntent(),
      },
      // use a builder so we can use Actions.handle<>
      // we need a content child of the actions
      child: Builder(builder: (context) {
        // handles mouse buttons
        return Listener(
          onPointerDown: (p) {
            if (p.kind != PointerDeviceKind.mouse) return;
            if (p.buttons & kBackMouseButton != 0) {
              Actions.invoke(context, const NavigateBackIntent());
            }
            if (p.buttons & kForwardMouseButton != 0) {
              Actions.invoke(context, const NavigateForwardIntent());
            }
          },
          // handles trackpad gestures
          child: GestureDetector(
            supportedDevices: const {PointerDeviceKind.trackpad},
            onHorizontalDragEnd: (dragEndDetails) {
              final velocity = dragEndDetails.primaryVelocity;
              if (velocity == null || velocity == 0) return;

              debugPrint("Drag velocity ${dragEndDetails.primaryVelocity}");

              if (velocity < 0) {
                Actions.invoke(context, const NavigateForwardIntent());
                return;
              }
              if (velocity > 0) {
                Actions.invoke(context, const NavigateBackIntent());
                return;
              }
            },
            child: ADBQueueIndicator(
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
            ),
          ),
        );
      }),
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

    Trace.verbose("Uploading $paths");

    for (final path in paths) {
      final devicePath = fileBrowser.address;
      final hostFilename = Adb.hostPath.basename(path);

      final dest = Adb.adbPathContext.join(devicePath, hostFilename);

      ref
          .read(uploadQueueProvider.notifier)
          .doUpload(widget.serial, path, dest);
    }
  }

  Future<void> _watchFile(FileBrowserMetadata fileData) async {
    String? savePath = await fileData.saveFileToDesktop(ref);
    if (savePath == null) {
      return;
    }

    var source = fileData.path;

    onWatchAdd.invoke(Tuple2(savePath, source));
  }
}

class _FilteredListContainer extends ConsumerStatefulWidget {
  const _FilteredListContainer({
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
  const _PathBreadCumbs();

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
  // This is just used to minimize state updates to only Text
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set initial address
    _addressController.text = ref.read(fileBrowserProvider).address;
  }

  @override
  void dispose() {
    super.dispose();
    _addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update address bar to source of truth
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
      onPressed: Actions.handler<NavigateBackIntent>(
        context,
        const NavigateBackIntent(),
      ),
    );

    var forwardButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_right_20_regular),
      onPressed: Actions.handler<NavigateForwardIntent>(
        context,
        const NavigateForwardIntent(),
      ),
    );

    var topLevelButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.folder_arrow_up_20_regular),
      onPressed: Actions.handler<NavigateTopIntent>(
        context,
        const NavigateTopIntent(),
      ),
    );
    var refreshButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
      onPressed: Actions.handler<RefreshListingIntent>(
        context,
        const RefreshListingIntent(),
      ),
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

enum FileCreation { file, folder }

class _NewFileDialogState extends ConsumerState<NewFileDialog> {
  final TextEditingController fileNameController = TextEditingController();
  FileCreation fileCreation = FileCreation.file;

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
          FileCreation.file => Adb.createFile(widget.serial, path),
          FileCreation.folder => Adb.createDirectory(widget.serial, path)
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
          value: FileCreation.file,
          label: Text("File"),
          icon: Icon(FluentIcons.document_24_regular),
        ),
        ButtonSegment(
          value: FileCreation.folder,
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

class NavigateForwardIntent extends Intent {
  const NavigateForwardIntent();
}

class NavigateBackIntent extends Intent {
  const NavigateBackIntent();
}

class NavigateTopIntent extends Intent {
  const NavigateTopIntent();
}

class RefreshListingIntent extends Intent {
  const RefreshListingIntent();
}
