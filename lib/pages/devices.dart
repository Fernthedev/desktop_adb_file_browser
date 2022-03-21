import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/widgets/device_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// TODO: Add wireless connection 
// TODO: Add button for toggling device into wireless

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  static const String title = "Devices";

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Future<List<Device>> _deviceListFuture =
      Future.delayed(const Duration(seconds: 2), Adb.getDevices);

  void _refreshDevices() {
    _deviceListFuture =
        Future.delayed(const Duration(seconds: 2), Adb.getDevices);
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text(DevicesPage.title),
      ),
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: _loadDevices()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshDevices();
          setState(() {});
        },
        tooltip: 'Refresh',
        // TODO: Animate easeInOut spin
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  FutureBuilder<List<Device>?> _loadDevices() {
    return FutureBuilder(
      future: _deviceListFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Device>?> snapshot) {
        //  TODO: Error handling
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          return _deviceGridView(snapshot.data!);
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

  GridView _deviceGridView(List<Device> devices) {
    return GridView.extent(
        childAspectRatio: 16.0 / 8.0,
        padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        maxCrossAxisExtent: 250,
        children: devices
            .map((e) => DeviceCard(
                deviceName: e.modelName,
                deviceManufacturer:
                    e.deviceManufacturer ?? "Unknown Manufacturer",
                serialName: e.serialName))
            .toList(growable: false));
  }
}
