import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ShortcutTapFunction = void Function(String path);

class ShortcutsListWidget extends ConsumerStatefulWidget {
  final ShortcutTapFunction? onTap;

  const ShortcutsListWidget({super.key, required this.onTap});

  @override
  ConsumerState<ShortcutsListWidget> createState() =>
      _ShortcutsListWidgetState();
}

class _ShortcutsListWidgetState extends ConsumerState<ShortcutsListWidget> {
  late Future<Map<String, String>> _future;
  late SharedPreferences _preferences;
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = SharedPreferences.getInstance().then((value) {
      _preferences = value;
      return _resetFuture();
    });
  }

  @override
  void dispose() {
    super.dispose();
    textController.dispose();
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
                // shrinkWrap: true,
                itemBuilder: (context, index) =>
                    _shortcutTile(context, index, map),
                findChildIndexCallback: (k) => (k as ValueKey<int>).value,
                itemCount: map.length,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints.loose(const Size.fromHeight(60)),
              child: _shortcutAddRow(),
            )
          ],
        );
      },
    );
  }

  Row _shortcutAddRow() {
    final fileBrowser = ref.watch(fileBrowserProvider);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // make text field take up
        Expanded(
          child: TextField(
            key: ValueKey(fileBrowser.address),
            controller: textController,
            decoration: const InputDecoration(
                border: UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2))),
                filled: true,
                labelText: 'Bookmark name',
                labelStyle: TextStyle(fontSize: 14)),
            onSubmitted: addShortcut,
          ),
        ),
        IconButton(
          onPressed: () {
            addShortcut(textController.text);
          },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            // make the button take all height
            fixedSize: const Size.fromHeight(1000),
          ),
          icon: const Icon(FluentIcons.add_28_regular),
        )
      ],
    );
  }

  ListTile _shortcutTile(
      BuildContext context, int index, Map<String, String> map) {
    final name = map.keys.toList(growable: false)[index];
    final path = map[name]!;

    var deleteButton = IconButton(
      iconSize: 20,
      splashRadius: 24,
      icon: const Icon(FluentIcons.delete_20_filled),
      onPressed: () {
        map.remove(name);
        _updateMap(map);
      },
    );
    return ListTile(
      key: ValueKey(index),
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 1,
      title: Wrap(
        alignment: WrapAlignment.spaceBetween,
        children: [Text(name), deleteButton],
      ),
      subtitle: Text(
        path,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (widget.onTap != null) widget.onTap!(path);
      },
    );
  }

  void addShortcut(String name) async {
    var map = await _future;

    final currentPath = ref.read(fileBrowserProvider).address;

    if (name.isEmpty) name = currentPath;
    if (name.isEmpty) return;

    map[name] = currentPath;
    _updateMap(map);
  }
}
