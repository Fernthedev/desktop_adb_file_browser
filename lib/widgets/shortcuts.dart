import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ShortcutTapFunction = void Function(String path);

class ShortcutsListWidget extends StatefulWidget {
  final ShortcutTapFunction? onTap;
  final String currentPath;

  const ShortcutsListWidget(
      {Key? key, required this.onTap, required this.currentPath})
      : super(key: key);

  @override
  State<ShortcutsListWidget> createState() => _ShortcutsListWidgetState();
}

class _ShortcutsListWidgetState extends State<ShortcutsListWidget> {
  late Future<Map<String, String>> _future;
  late SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _future = SharedPreferences.getInstance().then((value) {
      _preferences = value;
      return _resetFuture();
    });
  }

  Future<Map<String, String>> _resetFuture() {
    return _future = _preferences.getShortcutsMap();
  }

  void _updateMap(Map<String, String> map) {
    _preferences.setShortcutsMap(map).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Got error ${snapshot.error.toString()}");
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var map = snapshot.data!;

        return Column(
          children: [
            Expanded(
              flex: 2,
              child: ListView.builder(
                  controller: AdjustableScrollController(),
                  // shrinkWrap: true,
                  itemBuilder: (context, index) =>
                      _shortcutTile(context, index, map),
                  itemCount: map.length),
            ),
            TextField(
                key: ValueKey(widget.currentPath),
                onSubmitted: (value) {
                  map[value] = widget.currentPath;
                  _updateMap(map);
                }),
          ],
        );
      },
    );
  }

  ListTile _shortcutTile(
      BuildContext context, int index, Map<String, String> map) {
    final name = map.keys.toList(growable: false)[index];
    final path = map[name]!;

    return ListTile(
      title: Text(name),
      subtitle: Text(path),
      onTap: () {
        if (widget.onTap != null) widget.onTap!(path);
      },
      trailing: IconButton(
        iconSize: 20,
        splashRadius: 24,
        icon: const Icon(FluentIcons.delete_20_filled),
        onPressed: () {
          map.remove(name);
          _updateMap(map);
        },
      ),
    );
  }
}
