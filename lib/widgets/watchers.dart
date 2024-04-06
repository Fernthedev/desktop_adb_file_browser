import 'dart:async';

import 'package:desktop_adb_file_browser/riverpod/file_queue.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:desktop_adb_file_browser/utils/storage.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/trace.dart';
import 'package:tuple/tuple.dart';
import 'package:watcher/watcher.dart';

class FileWatcherList extends ConsumerStatefulWidget {
  const FileWatcherList(
      {super.key, required this.serial, required this.onUpdate});

  final String serial;

  // todo: figure this out
  final EventListenable<Tuple2<HostPath, QuestPath>> onUpdate;

  @override
  ConsumerState<FileWatcherList> createState() => _FileWatcherListState();
}

class _FileWatcherListState extends ConsumerState<FileWatcherList> {
  late Future<Map<HostPath, QuestPath>> _future;
  late SharedPreferences _preferences;
  late ListenableHolder<void> _listenableHolder;

  final Map<HostPath, Tuple2<Watcher, StreamSubscription>> _watchers = {};

  @override
  void initState() {
    super.initState();
    _future = SharedPreferences.getInstance().then((value) {
      _preferences = value;
      return _resetFuture();
    });

    _listenableHolder = widget.onUpdate.addListener((item) async {
      var map = await _future;
      map[item.item1] = item.item2;
      await _updateMap(map);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _listenableHolder.dispose();
    for (final watcher in _watchers.values) {
      watcher.item2.cancel();
    }
    _watchers.clear();
  }

  void _handleChange(WidgetRef ref, String src, WatchEvent event) async {
    var map = await _future;
    if (!map.containsKey(src)) return;

    var dest = map[src]!;

    if (event.type == ChangeType.REMOVE) {
      Adb.removeFile(widget.serial, dest);
    }

    if (event.type == ChangeType.MODIFY) {
      Trace.verbose("Uploading changes");
      ref.read(uploadQueueProvider.notifier).doUpload(widget.serial, src, dest);
    }
  }

  Future<Map<String, String>> _resetFuture() async {
    _future = _preferences.getWatchersMap();

    await update();

    return _future;
  }

  Future<void> _updateMap(Map<String, String> map) async {
    await _preferences.setWatchersMap(map);
    setState(() {});
  }

  Future<void> update() async {
    var newMap = await _future;
    for (var watcher in _watchers.entries
        .where((element) => !newMap.containsKey(element.key))) {
      watcher.value.item2.cancel();
    }

    // Remove unused keys
    _watchers.removeWhere((key, value) => !newMap.containsKey(key));

    // Add new keys
    final newFiles = newMap.map((key, value) {
      final watcher = Watcher(key);
      return MapEntry(
          key,
          Tuple2(watcher,
              watcher.events.listen((e) => _handleChange(ref, key, e))));
    });
    newFiles.removeWhere((key, value) => newMap.containsKey(key));

    _watchers.addAll(newFiles);
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
            Flexible(
              child: ListView.builder(
                  controller: AdjustableScrollController(),
                  // shrinkWrap: true,
                  itemBuilder: (context, index) =>
                      _watcherTile(context, index, map),
                  itemCount: map.length),
            ),
          ],
        );
      },
    );
  }

  ListTile _watcherTile(
      BuildContext context, int index, Map<String, String> map) {
    final name = map.keys.toList(growable: false)[index];
    final path = map[name]!;

    return ListTile(
      title: Text(name),
      subtitle: Text(path),
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
