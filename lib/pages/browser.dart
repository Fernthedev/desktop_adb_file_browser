import 'dart:async';

import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:desktop_adb_file_browser/widgets/file_widget.dart';
import 'package:drag_and_drop_windows/drag_and_drop_windows.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:routemaster/routemaster.dart';

@immutable
class DeviceBrowser extends StatefulWidget {
  final String serial;
  final TextEditingController _addressBar;

  DeviceBrowser(
      {Key? key, required String initialAddress, required this.serial})
      : _addressBar = TextEditingController(text: Adb.fixPath(initialAddress)),
        super(key: key);

  @override
  State<DeviceBrowser> createState() => _DeviceBrowserState();
}

// TODO: Add forward
// TODO: Add mouse button for back/forward
// TODO: Add shortcuts (sidebar?)
// TODO: Make new file have a file name dialog
// TODO: Add download progress snackbar (similar to upload progress)
// TODO: Make snackbar progress animation ease exponential because it looks
// TODO: Pressing enter when editing a file does NOT close file rename mode.
// TODO: File details page
// TODO: Search?

class _DeviceBrowserState extends State<DeviceBrowser> {
  bool list = true;
  final TextEditingController _filterController = TextEditingController();
  late Future<List<String>?> _fileListingFuture;
  Map<String, FileData> fileCache = {}; // date time cache
  late StreamSubscription dragReceiveSubscription;
  final ScrollController _scrollController = AdjustableScrollController(60);

  StackCollection<String> paths = StackCollection();

  @override
  void initState() {
    super.initState();
    dragReceiveSubscription = dropEventStream.listen(_uploadFiles);
    _refreshFiles(updateState: false, pushToHistory: false);
  }

  @override
  void dispose() {
    super.dispose();
    dragReceiveSubscription.cancel();
  }

  String get _currentPath => widget._addressBar.text;

  void _refreshFiles(
      {String? path,
      bool pushToHistory = true,
      bool updateState = true,
      bool refetch = true}) {
    var oldAddressText = _currentPath;

    if (path != null) {
      if (pushToHistory) {
        paths.push(_currentPath);
      }
      widget._addressBar.text = path;
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
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Row(
          children: [_navigationActions(), _addressBar(), _filterBar()],
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
      body: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(dividerThickness: 5.5),
        child: MultiSplitView(
          initialAreas: [Area(weight: 0.15)],
          children: [const ShortcutsListWidget(), Center(child: _fileView())],
          dividerBuilder:
              (axis, index, resizable, dragging, highlighted, themeData) =>
                  Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 0.5,
                      color: Colors.black),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewFileDialog();
        },
        tooltip: 'Add new file',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
            _refreshFiles(path: paths.pop(), pushToHistory: false);
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
        controller: _filterController,
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

  Iterable<String> _filteredFiles(Iterable<String> files) {
    var filter = _filterController.text.toLowerCase();
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

  GridView _viewAsGrid(List<String> files) {
    return GridView.extent(
        key: ValueKey(files),
        controller: _scrollController,
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
            onClick: isDir ? () => _directoryClick(file) : () {},
            downloadFile: _saveFileToDesktop,
            renameFileCallback: _renameFile,
            modifiedTime: Future.value(null),
            fileSize: Future.value(null),
            onDelete: _removeFileDialog,
          ));
        }).toList(growable: false));
  }

  ListView _viewAsList(List<String> files) {
    return ListView.builder(
      key: ValueKey(files),
      addAutomaticKeepAlives: true,
      controller: _scrollController,
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
          onClick: isDir ? () => _directoryClick(file) : () {},
          downloadFile: _saveFileToDesktop,
          renameFileCallback: _renameFile,
          onDelete: _removeFileDialog,
        );
      },
      itemCount: files.length,
    );
  }

  void _directoryClick(String directory) {
    _refreshFiles(path: directory);
  }

  Future<void> _saveFileToDesktop(
      String source, String friendlyFilename) async {
    final path = await getSavePath(suggestedName: friendlyFilename);

    if (path == null) return;

    await Adb.downloadFile(widget.serial, source, path);
  }

  void _uploadFiles(List<String> paths) async {
    debugPrint("Uploading $paths");
    List<Future> tasks = [];

    for (String path in paths) {
      String dest = Adb.adbPathContext.join(
          Adb.adbPathContext.dirname(_currentPath), // adb file path
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
                    if (file) {
                      Adb.removeFile(widget.serial, path);
                    } else {
                      Adb.removeDirectory(widget.serial, path);
                    }
                    _refreshFiles(refetch: true);
                    Navigator.of(context).pop();
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

              switch (fileCreation.value) {
                case FileCreation.file:
                  Adb.createFile(widget.serial, path);

                  break;
                case FileCreation.folder:
                  Adb.createDirectory(widget.serial, path);
                  break;
              }

              _refreshFiles(refetch: true);

              Navigator.of(context).pop();
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

class ShortcutsListWidget extends StatelessWidget {
  final double initialWidth;
  final double? maxWidth;
  final double? minWidth;

  const ShortcutsListWidget(
      {Key? key,
      this.initialWidth = 240,
      this.maxWidth = 500,
      this.minWidth = 100})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: ListView.builder(
        itemBuilder: ((context, index) => ListTile(
              title: Text("Hi! $index"),
            )),
        itemCount: 4,
      ),
    );
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
