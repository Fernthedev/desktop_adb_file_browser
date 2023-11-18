import 'dart:async';

import 'package:desktop_adb_file_browser/main.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/file_browser.dart';
import 'package:desktop_adb_file_browser/utils/file_sort.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_table.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_widget.dart';
import 'package:desktop_adb_file_browser/widgets/browser/new_file_dialog.dart';
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
import 'package:tuple/tuple.dart';

@immutable
class DeviceBrowser extends StatefulWidget {
  final String serial;

  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = AdjustableScrollController(60);
  final FileBrowser _fileBrowser;

  DeviceBrowser(
      {super.key, required String initialAddress, required this.serial})
      : _fileBrowser = FileBrowser(
            addressBar: TextEditingController(
                text: Adb.fixPath(initialAddress, addQuotes: false)));

  @override
  State<DeviceBrowser> createState() => _DeviceBrowserState();
}

// ignore: constant_identifier_names
enum FileCreation { File, Folder }

// TODO: Gestures
// TODO: Add download progress snackbar (similar to upload progress)
// TODO: Make snackbar progress animation ease exponential because it looks
// TODO: File details page
// TODO: Modularize widget into smaller widgets
class _DeviceBrowserState extends State<DeviceBrowser> {
  bool list = true;
  bool _dragging = false;
  late Future<List<String>?> _fileListingFuture;
  // late Future<SharedPreferences> preferences;
  Map<String, FileBrowserDataWrapper> fileCache = {}; // date time cache

  late ListenableHolder<void> onForwardClick;
  late ListenableHolder<void> onBackClick;

  final EventListenable<Tuple2<HostPath, QuestPath>> onWatchAdd =
      EventListenable();

  @override
  Widget build(BuildContext context) {
    return Focus(
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
              widget._fileBrowser.back();
              return KeyEventResult.handled;
            }
            if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
              widget._fileBrowser.forward();
              return KeyEventResult.handled;
            }
          }
        }

        return KeyEventResult.ignored;
      },
      child: DefaultTabController(
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
              icon: const Icon(FluentIcons.chevron_left_24_filled),
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
          body: MultiSplitViewTheme(
            data: MultiSplitViewThemeData(dividerThickness: 5.5),
            child: MultiSplitView(
              initialAreas: [Area(weight: 0.15)],
              children: [
                _leftPanel(),
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
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {
          //     _showNewFileDialog();
          //   },
          //   tooltip: 'Add new file',
          //   child: const Icon(Icons.add),
          // ),
          bottomNavigationBar: SizedBox(
            height: Theme.of(context).buttonTheme.height,
            child: _breadCumbs(),
          ),
        ),
      ),
    );
  }

  Widget _breadCumbs() {
    var currentPath = widget._fileBrowser.currentPath;
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
        key: ValueKey(widget._fileBrowser.currentPath),
        items: locations
            .map((e) => BreadCrumbItem(
                  borderRadius: BorderRadius.circular(4),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      Adb.adbPathContext.basename(e),
                    ),
                  ),
                  onTap: () => widget._fileBrowser.navigateToDirectory(e),
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
    // return _SplitRow(
    //         browser: widget._fileBrowser,
    //         key: ValueKey(widget._fileBrowser.currentPath),
    //       );
  }

  @override
  void dispose() {
    super.dispose();
    onForwardClick.dispose();
    onBackClick.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget._fileBrowser.navigateEvent = _onNavigate;
    onForwardClick = native2flutter.mouseForwardClick
        .addListener((_) => widget._fileBrowser.forward());
    onBackClick = native2flutter.mouseBackClick
        .addListener((_) => widget._fileBrowser.back());
    _onNavigate(widget._fileBrowser.currentPath);
  }

  Expanded _addressBar() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: widget._fileBrowser.addressBar,
          autocorrect: false,
          onSubmitted: (s) {
            if (s == widget._fileBrowser.currentPath) {
              _refresh();
            } else {
              widget._fileBrowser.navigateToDirectory(s);
            }
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

  Wrap _fileActions() {
    return Wrap(
      children: [
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.folder_add_20_regular,
          ),
          tooltip: "Upload file or folder",
          onPressed: () {
            openFiles().then((value) {
              if (value.isEmpty) return;
              _uploadFiles(value.map((e) => e.path));
            });
          },
        ),
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.add_20_regular,
          ),
          tooltip: "Add new file",
          onPressed: () {
            _showNewFileDialog();
          },
        ),
      ],
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

  FutureBuilder<List<String>?> _fileView() {
    return FutureBuilder(
      future: _fileListingFuture,
      key: ValueKey(_fileListingFuture),
      builder: (BuildContext context, AsyncSnapshot<List<String>?> snapshot) {
        if (snapshot.hasError && snapshot.error != null) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          var filteredList =
              _filteredFiles(snapshot.data!).toList(growable: false);

          // filteredList = filteredList
          //     .where((value) => value.endsWith("/"))
          //     .followedBy(filteredList.where((value) => !value.endsWith("/")))
          //     .toList(growable: false);
          return list ? _viewAsList(filteredList) : _viewAsGrid(filteredList);
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

  Expanded _filterBar() {
    return Expanded(
      child: TextField(
        controller: widget._filterController,
        autocorrect: false,
        onChanged: (s) {
          // Update UI to filter
          setState(() {});
        },
        onSubmitted: (s) {
          // Update UI to filter
          setState(() {});
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

  Iterable<String> _filteredFiles(Iterable<String> files) {
    var filter = widget._filterController.text.toLowerCase();
    if (filter.isEmpty) return files;
    return files.where((element) => element.toLowerCase().contains(filter));
  }

  Column _leftPanel() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            children: [
              ShortcutsListWidget(
                currentPath: widget._fileBrowser.currentPath,
                onTap: widget._fileBrowser.navigateToDirectory,
              ),
              FileWatcherList(serial: widget.serial, onUpdate: onWatchAdd)
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

  Wrap _navigationActions() {
    return Wrap(
      children: [
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.folder_arrow_up_20_regular,
          ),
          onPressed: () {
            widget._fileBrowser.navigateToDirectory(
                Adb.adbPathContext.dirname(widget._fileBrowser.currentPath));
          },
        ),
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.arrow_left_20_regular,
          ),
          onPressed: () {
            widget._fileBrowser.back();
          },
        ),
        IconButton(
          splashRadius: 20,
          icon: const Icon(
            FluentIcons.arrow_right_20_regular,
          ),
          onPressed: () {
            widget._fileBrowser.forward();
          },
        ),
        IconButton(
          splashRadius: 20,
          icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
          onPressed: () {
            _refresh();
          },
        ),
      ],
    );
  }

  void _onNavigate(String newPath) {
    debugPrint("Loading $newPath");

    setState(() {
      fileCache = {};

      _fileListingFuture =
          Adb.getFilesInDirectory(widget.serial, newPath).then((value) {
        debugPrint("Finished adb");
        return value;
      });
    });
  }

  void _refresh() {
    _onNavigate(widget._fileBrowser.currentPath);
  }

  Future<void> _showNewFileDialog() async {
    final TextEditingController fileNameController = TextEditingController();
    final ValueNotifier<FileCreation> fileCreation =
        ValueNotifier(FileCreation.File);

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
              var path = Adb.adbPathContext.join(
                  widget._fileBrowser.currentPath, fileNameController.text);

              Future task;

              switch (fileCreation.value) {
                case FileCreation.File:
                  task = Adb.createFile(widget.serial, path);

                  break;
                case FileCreation.Folder:
                  task = Adb.createDirectory(widget.serial, path);
                  break;
              }

              task.then((_) {
                _refresh();

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

  void _uploadFiles(Iterable<String> paths) async {
    debugPrint("Uploading $paths");
    var tasks = paths.map((path) {
      String dest = Adb.adbPathContext.join(
          widget._fileBrowser.currentPath, // adb file path
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
    _refresh(); // update UI

    await Future.delayed(const Duration(seconds: 4));
    snackBar.close();
  }

  GridView _viewAsGrid(List<String> files) {
    return GridView.builder(
        key: ValueKey(files),
        controller: widget._scrollController,
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
          var isDir = file.endsWith("/");
          var fileData = fileCache.putIfAbsent(
              file,
              () => FileBrowserDataWrapper(FileBrowserMetadata(
                    isDirectory: isDir,
                    initialFilePath: file,
                    modifiedTime: Adb.getFileModifiedDate(widget.serial, file),
                    fileSize: Adb.getFileSize(widget.serial, file),
                    onWatch: _watchFile,
                    browser: widget._fileBrowser,
                    serial: widget.serial,
                  )));

          return GridTile(
              child: FileCardWidget(
            key: ValueKey(file),
            isCard: true,
            fileWrapper: fileData,
          ));
        });
  }

  _viewAsList(List<String> files) {
    // var isDir = file.endsWith("/");

    debugPrint("Viewing");
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: widget._scrollController,
        child: SizedBox(
          width: double.infinity,
          child: FileDataTable(
              originalFileData: files.map((file) {
            final isDir = file.endsWith("/");

            return fileCache.putIfAbsent(
                file,
                () => FileBrowserDataWrapper(FileBrowserMetadata(
                      modifiedTime:
                          Adb.getFileModifiedDate(widget.serial, file),
                      fileSize: !isDir
                          ? Adb.getFileSize(widget.serial, file)
                          : Future.value(null),
                      isDirectory: isDir,
                      initialFilePath: file,
                      onWatch: _watchFile,
                      browser: widget._fileBrowser,
                      serial: widget.serial,
                    )));
          }).toList(growable: false)),
        ),
      ),
    );
    // return SizedBox(
    //   width: double.infinity,
    //   child: FileDataTable(
    //       fileData: files.map((file) {
    //     return fileCache.putIfAbsent(
    //         file,
    //         () => FileBrowserDataWrapper(FileBrowserData(
    //               modifiedTime: Adb.getFileModifiedDate(widget.serial, file),
    //               fileSize: Adb.getFileSize(widget.serial, file),
    //               isDirectory: file.endsWith("/"),
    //               initialFilePath: file,
    //               onWatch: _watchFile,
    //               browser: widget._fileBrowser,
    //               serial: widget.serial,
    //             )));
    //   }).toList(growable: false)),
    // );
  }

  Future<void> _watchFile(String source, String savePath) async {
    onWatchAdd.invoke(Tuple2(savePath, source));
  }
}
