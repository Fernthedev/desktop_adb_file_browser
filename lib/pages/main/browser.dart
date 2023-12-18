import 'dart:async';

import 'package:desktop_adb_file_browser/main.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/file_browser.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_table.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_widget.dart';
import 'package:desktop_adb_file_browser/widgets/browser/upload_file.dart';
import 'package:desktop_adb_file_browser/widgets/shortcuts.dart';
import 'package:desktop_adb_file_browser/widgets/watchers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:routemaster/routemaster.dart';
import 'package:trace/trace.dart';
import 'package:tuple/tuple.dart';

@immutable
class DeviceBrowserPage extends StatefulWidget {
  final String serial;
  final String initialAddress;

  const DeviceBrowserPage(
      {super.key, required this.initialAddress, required this.serial});

  @override
  State<DeviceBrowserPage> createState() => _DeviceBrowserPageState();
}

// ignore: constant_identifier_names
enum FileCreation { File, Folder }

// TODO: Gestures
// TODO: Add download progress snackbar (similar to upload progress)
// TODO: Make snackbar progress animation ease exponential because it looks
// TODO: File details page
class _DeviceBrowserPageState extends State<DeviceBrowserPage> {
  bool _viewAsListMode = true;
  bool _dragging = false;
  late Future<List<FileBrowserMetadata>?> _fileListingFuture;

  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late final FileBrowser _fileBrowser =
      FileBrowser(addressBar: _addressController);

  @override
  void initState() {
    super.initState();

    _addressController.text =
        Adb.fixPath(widget.initialAddress, addQuotes: false);

    _fileBrowser.navigateEvent = _onNavigate;

    onForwardClick = native2flutter.mouseForwardClick
        .addListener((_) => _fileBrowser.forward());
    onBackClick =
        native2flutter.mouseBackClick.addListener((_) => _fileBrowser.back());
    _onNavigate(_fileBrowser.currentPath);
  }

  @override
  void dispose() {
    super.dispose();
    onForwardClick.dispose();
    onBackClick.dispose();

    _addressController.dispose();
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
              fileBrowser: _fileBrowser,
              filterController: _filterController,
              serial: widget.serial,
              onUpload: _uploadFiles,
            ),
            leading: conditionalExitButton,
            automaticallyImplyLeading: true,
            actions: [listViewButton],
          ),
          body: _buildBody(context),
          bottomNavigationBar: SizedBox(
            height: Theme.of(context).buttonTheme.height,
            child: _PathBreadCumbs(
              fileBrowser: _fileBrowser,
              key: ValueKey(_fileBrowser.currentPath),
            ),
          ),
        ),
      ),
    );
  }

  MultiSplitViewTheme _buildBody(BuildContext context) {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(dividerThickness: 5.5),
      child: MultiSplitView(
        initialAreas: [Area(weight: 0.15)],
        children: [
          _ShortcutsColumn(
            fileBrowser: _fileBrowser,
            serial: widget.serial,
            onWatchAdd: onWatchAdd,
          ),
          Center(child: _fileListContainer(context))
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

  KeyEventResult _onKeyHandler(node, event) {
    if (!event.repeat && event.isAltPressed) {
      if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
        _fileBrowser.back();
        return KeyEventResult.handled;
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
        _fileBrowser.forward();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  DropTarget _fileListContainer(BuildContext context) {
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
        child: _fileView(),
      ),
    );
  }

  FutureBuilder<List<FileBrowserMetadata>?> _fileView() {
    return FutureBuilder(
      future: _fileListingFuture,
      key: ValueKey(_fileListingFuture),
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.error != null) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          var list = snapshot.data!;

          return _FilteredListContainer(
            files: list,
            key: ValueKey(list),
            filterController: _filterController,
            builder: (context, filteredFiles) => _viewAsListMode
                ? _viewAsList(filteredFiles)
                : _viewAsGrid(filteredFiles),
          );
        }

        // Loading
        return const Center(
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
        );
      },
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
    Trace.verbose("Uploading $paths");
    var tasks = paths.map((path) {
      String dest = Adb.adbPathContext.join(
          _fileBrowser.currentPath, // adb file path
          Adb.hostPath.basename(path) // host file name
          );

      // C:\Users\foo.txt -> currentPath/foo.txt
      return Adb.uploadFile(widget.serial, path, dest);
    });

    // this is so scuffed
    // I do this to automatically update the snack bar progress
    var tasksDone = 0;
    var notifier = ValueNotifier<double>(0);

    Future.forEach(tasks, (e) async {
      tasksDone++;
      notifier.value = tasksDone / tasks.length;
    });

    // Snack bar
    var snackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: UploadingFilesWidget(
          progressIndications: notifier,
          taskAmount: tasks.length,
        ),
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

    await Future.wait(tasks);
    _fileBrowser.refresh(); // update UI

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }

  void _onNavigate(String newPath) {
    if (!context.mounted) return;

    Trace.verbose("Loading $newPath");
    // final token = ServicesBinding.rootIsolateToken;
    // var future = compute((message) {
    //   // why is this necessary?
    //   BackgroundIsolateBinaryMessenger.ensureInitialized(message.item3!);

    //   return Adb.getFilesInDirectory(message.item1, message.item2);
    // }, Tuple3(widget.serial, newPath, token));
    var future = Adb.getFilesInDirectory(widget.serial, newPath);

    var filesFuture = future.then((list) => list.map((e) {
          return FileBrowserMetadata(
            browser: _fileBrowser,
            modifiedTime: e.date,
            fileSize: e.size,
            fullFilePath: e.path,
            isDirectory: e.path.endsWith("/"),
            serial: widget.serial,
          );
        }).toList(growable: false));

    setState(() {
      _fileListingFuture = filesFuture;
    });
  }

  Future<void> _watchFile(FileBrowserMetadata fileData) async {
    String? savePath = await fileData.saveFileToDesktop();
    if (savePath == null) {
      return;
    }

    var source = fileData.fullFilePath;

    onWatchAdd.invoke(Tuple2(savePath, source));
  }
}

class _FilteredListContainer extends StatefulWidget {
  const _FilteredListContainer({
    super.key,
    required this.filterController,
    required this.files,
    required this.builder,
  });

  final TextEditingController filterController;
  final List<FileBrowserMetadata> files;

  final Widget Function(
      BuildContext context, List<FileBrowserMetadata> filteredFiles) builder;

  @override
  State<_FilteredListContainer> createState() => _FilteredListContainerState();
}

class _FilteredListContainerState extends State<_FilteredListContainer> {
  List<FileBrowserMetadata> _filteredFiles = [];

  @override
  void initState() {
    super.initState();

    widget.filterController.addListener(_doFilterFiles);

    _doFilterFiles();
  }

  @override
  void didUpdateWidget(covariant _FilteredListContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files != widget.files) {
      _doFilterFiles();
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.filterController.removeListener(_doFilterFiles);
  }

  void _doFilterFiles() {
    var filter = widget.filterController.text.toLowerCase();

    var filteredFiles = filter.isEmpty
        ? widget.files
        : widget.files
            .where((element) =>
                element.fullFilePath.toLowerCase().contains(filter))
            .toList(growable: false);

    setState(() {
      _filteredFiles = filteredFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _filteredFiles);
  }
}

class _PathBreadCumbs extends StatelessWidget {
  const _PathBreadCumbs({
    super.key,
    required FileBrowser fileBrowser,
  }) : _fileBrowser = fileBrowser;

  final FileBrowser _fileBrowser;

  @override
  Widget build(BuildContext context) {
    var currentPath = _fileBrowser.currentPath;
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
        key: ValueKey(_fileBrowser.currentPath),
        items: locations
            .map((e) => BreadCrumbItem(
                  borderRadius: BorderRadius.circular(4),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      Adb.adbPathContext.basename(e),
                    ),
                  ),
                  onTap: () => _fileBrowser.navigateToDirectory(e),
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

class _AppBarActions extends StatelessWidget {
  const _AppBarActions({
    super.key,
    required this.fileBrowser,
    required this.filterController,
    required this.serial,
    required this.onUpload,
  });

  final FileBrowser fileBrowser;
  final TextEditingController filterController;
  final String serial;
  final void Function(Iterable<String> paths) onUpload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _navigationActions(),
        _addressBar(),
        _filterBar(),
        _fileActions(context)
      ],
    );
  }

  Widget _navigationActions() {
    var backButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_left_20_regular),
      onPressed: () {
        fileBrowser.back();
      },
    );

    var forwardButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_right_20_regular),
      onPressed: () {
        fileBrowser.forward();
      },
    );

    var topLevelButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.folder_arrow_up_20_regular),
      onPressed: () {
        fileBrowser.navigateToDirectory(
            Adb.adbPathContext.dirname(fileBrowser.currentPath));
      },
    );
    var refreshButton = IconButton(
      splashRadius: 20,
      icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
      onPressed: () {
        fileBrowser.refresh();
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

  Widget _addressBar() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: fileBrowser.addressBar,
          autocorrect: false,
          onSubmitted: (s) {
            if (s == fileBrowser.currentPath) {
              fileBrowser.refresh();
            } else {
              fileBrowser.navigateToDirectory(s);
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
          controller: filterController,
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
          onUpload(value.map((e) => e.path));
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
          fileBrowser: fileBrowser,
          serial: serial,
        );
      },
    );
  }
}

class NewFileDialog extends StatefulWidget {
  const NewFileDialog({
    super.key,
    required this.fileBrowser,
    required this.serial,
  });

  final FileBrowser fileBrowser;
  final String serial;

  @override
  State<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  final TextEditingController fileNameController = TextEditingController();
  FileCreation fileCreation = FileCreation.File;

  @override
  void dispose() {
    super.dispose();
    fileNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            .join(widget.fileBrowser.currentPath, fileNameController.text);

        Future task = switch (fileCreation) {
          FileCreation.File => Adb.createFile(widget.serial, path),
          FileCreation.Folder => Adb.createDirectory(widget.serial, path)
        };

        task.then((_) {
          widget.fileBrowser.refresh();
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

class _ShortcutsColumn extends StatelessWidget {
  const _ShortcutsColumn({
    super.key,
    required FileBrowser fileBrowser,
    required this.serial,
    required this.onWatchAdd,
  }) : _fileBrowser = fileBrowser;

  final FileBrowser _fileBrowser;
  final String serial;
  final EventListenable<Tuple2<HostPath, QuestPath>> onWatchAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            children: [
              ShortcutsListWidget(
                currentPath: _fileBrowser.currentPath,
                onTap: _fileBrowser.navigateToDirectory,
              ),
              FileWatcherList(serial: serial, onUpdate: onWatchAdd)
            ],
          ),
        ),
        const TabBar(tabs: [
          Tab(
              icon: Icon(
            FluentIcons.bookmark_20_filled,
            size: 20,
          )),
          Tab(
              icon: Icon(
            FluentIcons.glasses_20_filled,
            size: 20,
          ))
        ]),
      ],
    );
  }
}
