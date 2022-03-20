import 'package:desktop_adb_file_browser/widgets/device_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({Key? key}) : super(key: key);

  static const String title = "Devices";

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text(title),
      ),
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: GridView.extent(
              childAspectRatio: 16.0 / 8.0,
              padding: const EdgeInsets.all(4.0),
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              maxCrossAxisExtent: 250,
              children: const [
            DeviceCard("Android Phone", "Google", "WBN23B1I3N1KNNEWJ"),
            DeviceCard("Android Phone", "Google", "WBN23B1I3N1KNNEWJ")
          ])),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Refresh',
        // TODO: Animate easeInOut spin
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
