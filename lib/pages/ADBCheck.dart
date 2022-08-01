import 'package:desktop_adb_file_browser/main.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class ADBCheck extends StatefulWidget {
  const ADBCheck({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<ADBCheck> createState() => _ADBCheckState();
}

class _ADBCheckState extends State<ADBCheck> {
  @override
  void initState() {
    super.initState();
    _showADBDownload(context);
  }

  Future<void> _showADBDownload(BuildContext context) async {
    try {
      await Adb.runAdbCommand(null, ["start-server"]);
    } catch (e) {
      await showDialog(
          builder: (context) => const ADBDownloadDialog(), context: context);
    }
    if (!mounted) return;
    Routemaster.of(context).replace("/devices");
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar:
          AppBar(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
