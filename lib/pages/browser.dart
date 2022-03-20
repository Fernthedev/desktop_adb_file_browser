import 'package:desktop_adb_file_browser/widgets/file_widget.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class DeviceBrowser extends StatefulWidget {
  final String serial;
  final TextEditingController _addressBar;

  DeviceBrowser(
      {Key? key, required String initialAddress, required this.serial})
      : _addressBar = TextEditingController(text: initialAddress),
        super(key: key);

  @override
  State<DeviceBrowser> createState() => _DeviceBrowserState();
}

class _DeviceBrowserState extends State<DeviceBrowser> {
  bool list = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget._addressBar,
                autocorrect: false,
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
      body: Center(child: list ? _viewAsList() : _viewAsGrid()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Add new file',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  GridView _viewAsGrid() {
    return GridView.extent(
        childAspectRatio: 17.0 / 9.0,
        padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        maxCrossAxisExtent: 280,
        children: List.generate(
            40,
            (index) => GridTile(
                    child: FileFolderCard(
                  isDirectory: index % 2 == 0,
                  fileName: "some folder $index",
                ))));
  }

  ListView _viewAsList() {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) => FileFolderListTile(
        isDirectory: index % 2 == 0,
        fileName: "some folder $index",
      ),
      itemCount: 20,
    );
  }
}
