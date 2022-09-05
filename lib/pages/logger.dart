import 'dart:io';

import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class LogPage extends StatelessWidget {
  LogPage({Key? key, required String serial})
      : logFuture = Adb.logcat(serial),
        super(key: key);

  final Future<Stream<String>> logFuture;
  final List<String> logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logcat"),
        leading: IconButton(
          icon: const Icon(
            FluentIcons.arrow_left_24_filled,
            size: 24,
          ),
          onPressed: () {
            Routemaster.of(context).history.back();
          },
        ),
        actions: [
          IconButton(
              onPressed: _saveLog,
              icon: const Icon(
                FluentIcons.save_28_regular,
                size: 28,
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: Theme.of(context).backgroundColor,
          child: FutureBuilder<Stream<String>>(
            future: logFuture,
            builder: buildStream,
          ),
        ),
      ),
    );
  }

  Widget buildStream(
      BuildContext context, AsyncSnapshot<Stream<String>> snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    return StreamBuilder<String>(
      stream: snapshot.data!,
      builder: buildList,
    );
  }

  Widget buildList(BuildContext context, AsyncSnapshot<String> snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      showDialog<AlertDialog>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("Error while streaming logcat"),
                content: Text(snapshot.error.toString()),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Back"))
                ],
              ));
    }

    final newString = snapshot.data;
    if (newString != null) {
      logs.add(newString);
    }

    return ListView.builder(
      key: ValueKey(logs.length),
      shrinkWrap: true,
      controller: AdjustableScrollController(),
      itemBuilder: ((context, index) => SelectableText(
            logs[index],
            key: ValueKey(index),
          )),
      itemCount: logs.length,
    );
  }

  void _saveLog() async {
    const String fileName = 'log.txt';
    final String? path = await getSavePath(suggestedName: fileName);

    if (path == null) return;

    var file = File(path);
    var writer = file.openWrite();

    writer.writeAll(logs, Adb.hostPath.separator);
    await writer.flush();
    await writer.close();
  
    // TODO: user feedback when finished
  }
}
