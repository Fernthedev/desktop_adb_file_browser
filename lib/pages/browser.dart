import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:desktop_adb_file_browser/widgets/file_widget.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
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

    if (updateState) {
      setState(() {
        _fileListingFuture = Adb.getFilesInDirectory(
            "1WMHH8127B0362", path ?? widget._addressBar.text);
      });
    } else {
      _fileListingFuture = Adb.getFilesInDirectory(
          "1WMHH8127B0362", path ?? widget._addressBar.text);
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
            Wrap(
              children: [
                IconButton(
                  splashRadius: 20,
                  icon: const Icon(
                    FluentIcons.folder_arrow_up_24_regular,
                  ),
                  onPressed: () {
                    _refreshFiles(
                        path: Adb.adbPathContext
                            .dirname(widget._addressBar.text));
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
              ],
            ),
            Expanded(
              child: TextField(
                controller: widget._addressBar,
                autocorrect: false,
                onSubmitted: (s) {
                  _refreshFiles();
                },
                decoration: const InputDecoration(
                  // focusedBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  // ),

                  // cool animation border effect
                  // this makes it rectangular when not selected
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  hintText: 'Search',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  constraints: BoxConstraints.tightFor(height: 40),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(FluentIcons.folder_24_regular),
          onPressed: () {
            Routemaster.of(context).pop();
          },
        ),
        actions: [
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
      body: Center(child: _fileView()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshFiles();
        },
        tooltip: 'Add new file',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
            fileName: Adb.adbPathContext.basename(file),
            onClick: isDir ? () => _directoryClick(file) : () {},
          ));
        }).toList(growable: false));
  }

  ListView _viewAsList(List<String> files) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        var file = files[index];

        var isDir = file.endsWith("/");

        return FileFolderListTile(
          isDirectory: isDir,
          fileName: Adb.adbPathContext.basename(file),
          onClick: isDir ? () => _directoryClick(file) : () {},
        );
      },
      itemCount: files.length,
    );
  }

  void _directoryClick(String directory) {
    _refreshFiles(path: directory);
  }
}
