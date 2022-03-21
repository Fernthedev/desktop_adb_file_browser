import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:desktop_adb_file_browser/widgets/file_widget.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:routemaster/routemaster.dart';

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

class _DeviceBrowserState extends State<DeviceBrowser> {
  bool list = true;
  late Future<List<String>?> _fileListingFuture;

  StackCollection<String> paths = StackCollection();

  @override
  void initState() {
    super.initState();
    _refreshFiles(updateState: false, pushToHistory: false);
  }

  void _refreshFiles(
      {String? path, bool pushToHistory = true, bool updateState = true}) {
    var oldAddressText = widget._addressBar.text;

    if (path != null) {
      if (pushToHistory) {
        paths.push(widget._addressBar.text);
      }
      widget._addressBar.text = path;
    }

    /// Don't refresh unnecessarily
    /// This will still allow refreshes when pressing enter
    /// on the address bar because the address bar passes [path] as null
    if (path != null && oldAddressText == path) return;

    _fileListingFuture =
        Adb.getFilesInDirectory(widget.serial, path ?? widget._addressBar.text);
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
          children: [
            _navigationActions(),
            _addressBar(),
          ],
        ),
        leading: IconButton(
          icon: const Icon(FluentIcons.folder_24_regular),
          onPressed: () {
            Routemaster.of(context).pop();
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
          initialWeights: const [0.15],
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
          _refreshFiles();
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
          hintText: 'Search',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          constraints: BoxConstraints.tightFor(height: 40),
        ),
      ),
    );
  }

  FutureBuilder<List<String>?> _fileView() {
    return FutureBuilder(
      future: _fileListingFuture,
      builder: (BuildContext context, AsyncSnapshot<List<String>?> snapshot) {
        //  TODO: Error handling
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          return list
              ? _viewAsList(snapshot.data!)
              : _viewAsGrid(snapshot.data!);
        } else {
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
        }
      },
    );
  }

  GridView _viewAsGrid(List<String> files) {
    return GridView.extent(
        childAspectRatio: 17.0 / 9.0,
        padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        maxCrossAxisExtent: 280,
        children: files.map((file) {
          var isDir = file.endsWith("/");

          return GridTile(
              child: FileFolderCard(
                  isDirectory: isDir,
                  friendlyFileName: Adb.adbPathContext.basename(file),
                  fullFilePath: file,
                  onClick: isDir ? () => _directoryClick(file) : () {},
                  downloadFile: _saveFileToDesktop,
                  renameFileCallback: _renameFile,));
        }).toList(growable: false));
  }

  ListView _viewAsList(List<String> files) {
    return ListView.builder(
      controller: AdjustableScrollController(60),
      itemBuilder: (BuildContext context, int index) {
        var file = files[index];

        var isDir = file.endsWith("/");

        return FileFolderListTile(
          isDirectory: isDir,
          fullFilePath: file,
          friendlyFileName: Adb.adbPathContext.basename(file),
          onClick: isDir ? () => _directoryClick(file) : () {},
          downloadFile: _saveFileToDesktop,
          renameFileCallback: _renameFile,
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

  Future<void> _renameFile(String source, String newName) async {
    await Adb.moveFile(widget.serial, source,
        Adb.adbPathContext.join(Adb.adbPathContext.dirname(source), newName));
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
