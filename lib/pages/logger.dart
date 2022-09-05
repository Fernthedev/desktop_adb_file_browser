import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/scroll.dart';
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
        leading: IconButton(
          icon: const Icon(
            FluentIcons.folder_24_regular,
            size: 24,
          ),
          onPressed: () {
            Routemaster.of(context).history.back();
          },
        ),
      ),
      body: FutureBuilder<Stream<String>>(
        future: logFuture,
        builder: ((context, snapshot) => StreamBuilder<String>(
              stream: snapshot.data!,
              builder: buildList,
            )),
      ),
    );
  }

  Widget buildList(BuildContext context, AsyncSnapshot<String> snapshot) {
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
      controller: AdjustableScrollController(),
      itemBuilder: ((context, index) => Text(logs[index])),
      itemCount: logs.length,
    );
  }
}
