import 'dart:async';

import 'package:desktop_adb_file_browser/main.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:desktop_adb_file_browser/widgets/file_widget.dart';
import 'package:desktop_adb_file_browser/widgets/shortcuts.dart';
import 'package:desktop_adb_file_browser/widgets/watchers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:routemaster/routemaster.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

@immutable
class DeviceBrowser extends StatefulWidget {
  final String serial;
  final TextEditingController _addressBar;
  final TextEditingController _filterController = TextEditingController();

  final ScrollController _scrollController = AdjustableScrollController(60);

  final StackCollection<String> _paths = StackCollection();
  final StackCollection<String> _forwardPaths = StackCollection();

  DeviceBrowser(
      {Key? key, required String initialAddress, required this.serial})
      : _addressBar = TextEditingController(
            text: Adb.fixPath(initialAddress, addQuotes: false)),
        super(key: key);

  @override
  State<DeviceBrowser> createState() => _DeviceBrowserState();
}

// TODO: Gestures
// TODO: Add shortcuts (sidebar?)
// TODO: A text field which on save adds an entry to the shortcut list
// TODO: Add download progress snackbar (similar to upload progress)
// TODO: Make snackbar progress animation ease exponential because it looks
// TODO: File details page
// TODO: Modularize widget into smaller widgets
class _DeviceBrowserState extends State<DeviceBrowser> {
  bool list = true;
  bool _dragging = false;
  late Future<List<String>?> _fileListingFuture;
  late Future<SharedPreferences> preferences;
  Map<String, FileData> fileCache = {}; // date time cache

  late ListenableHolder<void> onForwardClick;
  late ListenableHolder<void> onBackClick;

  final EventListenable<Tuple2<HostPath, QuestPath>> onWatchAdd =
      EventListenable();

  @override
  void initState() {
    super.initState();
    onForwardClick =
        native2flutter.mouseForwardClick.addListener((_) => forward());
    onBackClick = native2flutter.mouseBackClick.addListener((_) => back());
    _refreshFiles(updateState: false, pushToHistory: false);
  }

  @override
  void dispose() {
    super.dispose();
    onForwardClick.dispose();
    onBackClick.dispose();
  }

  String get _currentPath => widget._addressBar.text;

  void back() {
    if (widget._paths.isEmpty) return;
    debugPrint("Pushed back $_currentPath");

    widget._forwardPaths.push(_currentPath);
    _refreshFiles(
        path: widget._paths.pop(),
        pushToHistory: false,
        clearForwardHistory: false);
  }

  void forward() {
    if (widget._forwardPaths.isEmpty) return;
    debugPrint("Pushed forward ${widget._forwardPaths.isNotEmpty}");

    _refreshFiles(
        path: widget._forwardPaths.pop(),
        pushToHistory: true,
        clearForwardHistory: false);
  }

  void _refreshFiles(
      {String? path,
      bool pushToHistory = true,
      bool clearForwardHistory = true,
      bool updateState = true,
      bool refetch = true}) {
    var oldAddressText = _currentPath;

    path = path == null
        ? null
        : Adb.adbPathContext.canonicalize(Adb.fixPath(path, addQuotes: false));

    if (path != null) {
      if (pushToHistory) {
        widget._paths.push(_currentPath);
      }
      widget._addressBar.text = path;
    }

    if (clearForwardHistory) {
      widget._forwardPaths.clear();
      debugPrint("clear forward");
    }

    /// Don't refresh unnecessarily
    /// This will still allow refreshes when pressing enter
    /// on the address bar because the address bar passes [path] as null
    if (path != null && oldAddressText == path) return;

    if (refetch) {
      fileCache = {};
      _fileListingFuture =
          Adb.getFilesInDirectory(widget.serial, path ?? _currentPath);
    }
    if (updateState) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Row(
            children: [
              _navigationActions(),
              _addressBar(),
              _filterBar(),
              _fileActions()
            ],
          ),
          leading: IconButton(
            icon: const Icon(FluentIcons.folder_24_regular),
            onPressed: () {
              Routemaster.of(context).history.back();
            },
          ),
          actions: [
            //
            IconButton(
              icon: Icon(list ? Icons.list : Icons.grid_3x3),
              onPressed: () {
                setState(() {
                  list = !list;
                });
              },
            )
          ],
        ),
        body: Focus(
          key: const ValueKey("Focus"),
          autofocus: true,
          canRequestFocus: true,
          descendantsAreFocusable: true,
          skipTraversal: true,
          onKey: (node, event) {
            if (!event.repeat) {
              // TODO: Figure out how to allow lower focus take control
              // if (event.isKeyPressed(LogicalKeyboardKey.backspace)) {
              //   back();
              //   return KeyEventResult.handled;
              // }

              if (event.isAltPressed) {
                if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                  back();
                  return KeyEventResult.handled;
                }
                if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                  forward();
                  return KeyEventResult.handled;
                }
              }
            }

            return KeyEventResult.ignored;
          },
          child: MultiSplitViewTheme(
            data: MultiSplitViewThemeData(dividerThickness: 5.5),
            child: MultiSplitView(
              initialAreas: [Area(weight: 0.15)],
              children: [
                Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        children: [
                          ShortcutsListWidget(
                            currentPath: _currentPath,
                            onTap: _navigateToDirectory,
                          ),
                          FileWatcherList(
                              serial: widget.serial, onUpdate: onWatchAdd)
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
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showNewFileDialog();
          },
          tooltip: 'Add new file',
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar:
            _locationsRow(), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  Wrap _navigationActions() {
    return Wrap(
      children: [
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.folder_arrow_up_24_regular,
          ),
          onPressed: () {
            _refreshFiles(
                path: Adb.adbPathContext.dirname(widget._addressBar.text));
          },
        ),
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.arrow_left_20_regular,
          ),
          onPressed: () {
            back();
          },
        ),
        IconButton(
          splashRadius: 20,
          icon: const Icon(FluentIcons.arrow_clockwise_28_regular),
          onPressed: () {
            _refreshFiles();
          },
        ),
      ],
    );
  }

  Expanded _addressBar() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: widget._addressBar,
          autocorrect: false,
          onSubmitted: (s) {
            _refreshFiles();
          },
          decoration: const InputDecoration(
            // cool animation border effect
            // this makes it rectangular when not selected
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            hintText: 'Path',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            constraints: BoxConstraints.tightFor(height: 40),
          ),
        ),
      ),
    );
  }

  Expanded _filterBar() {
    return Expanded(
      child: TextField(
        controller: widget._filterController,
        autocorrect: false,
        onChanged: (s) {
          _refreshFiles(refetch: false);
        },
        onSubmitted: (s) {
          _refreshFiles(refetch: false);
        },
        decoration: const InputDecoration(
          // cool animation border effect
          // this makes it rectangular when not selected
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          hintText: 'Search',
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          constraints: BoxConstraints.tightFor(height: 40),
        ),
      ),
    );
  }

  Wrap _fileActions() {
    return Wrap(
      children: [
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.folder_add_20_regular,
          ),
          onPressed: () {
            openFiles().then((value) {
              if (value.isEmpty) return;
              _uploadFiles(value.map((e) => e.path));
            });
          },
        ),
      ],
    );
  }

  Iterable<String> _filteredFiles(Iterable<String> files) {
    var filter = widget._filterController.text.toLowerCase();
    return files.where((element) => element.toLowerCase().contains(filter));
  }

  FutureBuilder<List<String>?> _fileView() {
    return FutureBuilder(
      future: _fileListingFuture,
      key: ValueKey(_fileListingFuture),
      builder: (BuildContext context, AsyncSnapshot<List<String>?> snapshot) {
        //  TODO: Error handling
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          var filteredList =
              _filteredFiles(snapshot.data!).toList(growable: false);

          filteredList = filteredList
              .where((value) => value.endsWith("/"))
              .followedBy(filteredList.where((value) => !value.endsWith("/")))
              .toList(growable: false);
          return list ? _viewAsList(filteredList) : _viewAsGrid(filteredList);
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
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

  GridView _viewAsGrid(List<String> files) {
    return GridView.extent(
        key: ValueKey(files),
        controller: widget._scrollController,
        shrinkWrap: true,
        childAspectRatio: 17.0 / 9.0,
        padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        maxCrossAxisExtent: 280,
        children: files.map((file) {
          var isDir = file.endsWith("/");

          return GridTile(
              child: FileWidgetUI(
            key: ValueKey(file),
            isCard: true,
            isDirectory: isDir,
            fullFilePath: file,
            onClick: isDir ? () => _navigateToDirectory(file) : () {},
            downloadFile: _saveFileToDesktop,
            renameFileCallback: _renameFile,
            modifiedTime: Future.value(null),
            fileSize: Future.value(null),
            onDelete: _removeFileDialog,
            onWatch: _watchFile,
          ));
        }).toList(growable: false));
  }

  ListView _viewAsList(List<String> files) {
    return ListView.builder(
      key: ValueKey(files),
      addAutomaticKeepAlives: true,
      controller: widget._scrollController,
      itemBuilder: (BuildContext context, int index) {
        var file = files[index];
        var fileData = fileCache.putIfAbsent(
            file, () => FileData(serialName: widget.serial, file: file));

        var isDir = file.endsWith("/");

        return FileWidgetUI(
          key: ValueKey(file),
          modifiedTime: fileData.lastModifiedTime,
          fileSize: fileData.fileSize,
          isCard: false,
          isDirectory: isDir,
          fullFilePath: file,
          onClick: isDir ? () => _navigateToDirectory(file) : () {},
          downloadFile: _saveFileToDesktop,
          renameFileCallback: _renameFile,
          onDelete: _removeFileDialog,
          onWatch: _watchFile,
        );
      },
      itemCount: files.length,
    );
  }

  Widget _locationsRow() {
    var locations = _currentPath.split("/");

    if (locations.isNotEmpty && locations.first.isEmpty) {
      locations.removeAt(0);
    }

    for (int i = 1; i < locations.length; i++) {
      locations[i] = Adb.adbPathContext.join(locations[i - 1], locations[i]);
    }

    return SizedBox(
      height: Theme.of(context).buttonTheme.height - 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView(
            shrinkWrap: true,
            key: ValueKey(_currentPath),
            scrollDirection: Axis.horizontal,
            children: locations
                .map((e) => [
                      const Text("/"),
                      TextButton(
                          onPressed: () => _navigateToDirectory(e),
                          child: Text(Adb.adbPathContext.basename(e)))
                    ])
                .expand<Widget>((element) => element)
                .toList(growable: false)),
      ),
    );
  }

  void _navigateToDirectory(String directory) {
    _refreshFiles(path: directory);
  }

  Future<void> _saveFileToDesktop(
      String source, String friendlyFilename) async {
    final savePath = await getSavePath(suggestedName: friendlyFilename);

    if (savePath == null) return;

    await Adb.downloadFile(widget.serial, source, savePath);
  }

  Future<void> _watchFile(String source, String friendlyFilename) async {
    final savePath = await getSavePath(suggestedName: friendlyFilename);

    if (savePath == null) return;

    await Adb.downloadFile(widget.serial, source, savePath);
    onWatchAdd.invoke(Tuple2(savePath, source));
  }

  void _uploadFiles(Iterable<String> paths) async {
    debugPrint("Uploading $paths");
    List<Future> tasks = [];

    for (String path in paths) {
      String dest = Adb.adbPathContext.join(
          _currentPath, // adb file path
          Adb.hostPath.basename(path) // host file name
          );

      // C:\Users\foo.txt -> currentPath/foo.txt
      tasks.add(Adb.uploadFile(widget.serial, path, dest));
    }

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
    _refreshFiles(); // update UI

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }

  Future<void> _renameFile(String source, String newName) async {
    await Adb.moveFile(widget.serial, source,
        Adb.adbPathContext.join(Adb.adbPathContext.dirname(source), newName));
  }

  Future<void> _removeFileDialog(String path, bool file) async {
    await showDialog<void>(
        context: context,
        builder: ((context) => AlertDialog(
              title: const Text("Confirm?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Are you sure you want to delete this file/folder?"),
                  Text(path)
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
                  onPressed: () {
                    Future task;
                    if (file) {
                      task = Adb.removeFile(widget.serial, path);
                    } else {
                      task = Adb.removeDirectory(widget.serial, path);
                    }

                    task.then((_) {
                      Navigator.of(context).pop();
                      _refreshFiles(refetch: true);
                    });
                  },
                ),
              ],
            )));
  }

  Future<void> _showNewFileDialog() async {
    final TextEditingController fileNameController = TextEditingController();
    final ValueNotifier<FileCreation> fileCreation =
        ValueNotifier(FileCreation.file);

    await showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Create new file'),
        content: NewFileDialog(
          fileNameController: fileNameController,
          fileCreation: fileCreation,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              var path = Adb.adbPathContext
                  .join(_currentPath, fileNameController.text);

              Future task;

              switch (fileCreation.value) {
                case FileCreation.file:
                  task = Adb.createFile(widget.serial, path);

                  break;
                case FileCreation.folder:
                  task = Adb.createDirectory(widget.serial, path);
                  break;
              }

              task.then((_) {
                _refreshFiles(refetch: true);

                Navigator.of(context).pop();
              });
            },
          ),
        ],
      ),
    );

    fileNameController.dispose();
    fileCreation.dispose();
  }
}

class UploadingFilesWidget extends StatefulWidget {
  const UploadingFilesWidget(
      {Key? key, required this.taskAmount, required this.progressIndications})
      : super(key: key);

  final int taskAmount;
  final ValueListenable<double> progressIndications;

  @override
  State<UploadingFilesWidget> createState() => _UploadingFilesWidgetState();
}

class _UploadingFilesWidgetState extends State<UploadingFilesWidget> {
  @override
  Widget build(BuildContext context) {
    var progressIndications = widget.progressIndications;
    var taskAmount = widget.taskAmount;

    return ValueListenableBuilder<double>(
        valueListenable: progressIndications,
        builder: (BuildContext context, double progress, _) {
          var theme = Theme.of(context);

          return SizedBox(
            height: 50,
            child: Column(
              children: [
                // Reverse calculation because less data needed to be passed!
                Text(
                  "Uploading ${(progress * taskAmount).round()}/$taskAmount (${(progress * 100).round()}%)",
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.snackBarTheme.contentTextStyle?.color),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: progress,
                  color: Theme.of(context).colorScheme.secondary,
                )
              ],
            ),
          );
        });
  }
}

class FileData {
  final String file;
  final String serialName;

  Future<DateTime?> lastModifiedTime;
  Future<int?> fileSize;

  FileData({required this.serialName, required this.file})
      : lastModifiedTime = Adb.getFileModifiedDate(serialName, file),
        fileSize = Adb.getFileSize(serialName, file);
}

enum FileCreation { file, folder }

class NewFileDialog extends StatefulWidget {
  const NewFileDialog(
      {Key? key, required this.fileNameController, required this.fileCreation})
      : super(key: key);

  final TextEditingController fileNameController;
  final ValueNotifier<FileCreation> fileCreation;

  @override
  State<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.fileNameController,
          autocorrect: false,
          autofocus: true,
          decoration: const InputDecoration(hintText: "New file"),
        ),
        Row(
          children: [
            _fileRadio(FileCreation.file),
            _fileRadio(FileCreation.folder)
          ],
        )
      ],
    );
  }

  Row _fileRadio(FileCreation f) {
    return Row(
      children: [
        Text(f.name),
        Radio<FileCreation>(
            value: f,
            groupValue: widget.fileCreation.value,
            onChanged: ((value) {
              setState(() {
                widget.fileCreation.value = value ?? FileCreation.file;
              });
            })),
      ],
    );
  }
}
