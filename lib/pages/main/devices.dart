import 'package:desktop_adb_file_browser/pages/adb_check.dart';
import 'package:desktop_adb_file_browser/routes.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/widgets/device_card.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage(
      {super.key, this.serialSelector, required this.canNavigate});

  final ValueNotifier<String?>? serialSelector;
  final bool canNavigate;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Future<List<Device>>? _deviceListFuture;

  @override
  void initState() {
    super.initState();

    // Check if ADB is installed
    checkAndPromptADB(context).then((value) => _refreshDevices());
  }

  void _refreshDevices() {
    setState(() {
      _deviceListFuture = Adb.getDevices();
    });
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
        title: const Text("Devices"),
        automaticallyImplyLeading: Routemaster.of(context).history.canGoBack,
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.add_24_filled),
            onPressed: _connectDialog,
          )
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: _loadDevices(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshDevices();
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
        if (snapshot.hasError) {
          return Text("Error occurred: ${snapshot.error}");
        }

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
          return _deviceListView(snapshot.data!);
        }
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
      },
    );
  }

  Widget _deviceListView(Iterable<Device> devices) {
    if (devices.isEmpty) {
      return Center(
        child: Text("No devices found",
            style: Theme.of(context).textTheme.headlineLarge),
      );
    }

    return ListView(
        padding: const EdgeInsets.all(4.0),
        children: devices
            .map((e) => DeviceCard(
                  device: e,
                  onTap: _onDeviceSelect,
                  showLogButton: widget.canNavigate,
                  selected: widget.serialSelector?.value == e.serialName,
                ))
            .toList(growable: false));
  }

  void _onDeviceSelect(Device device) {
    widget.serialSelector?.value = device.serialName;

    if (widget.canNavigate) {
      Routes.browse(context, device.serialName);
    }
  }

  Future<void> _connectDialog() async {
    TextEditingController ipController = TextEditingController();
    TextEditingController portController = TextEditingController(text: "5555");

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => WirelessConnectDialog(
          ipController: ipController, portController: portController),
    );
  }
}

class WirelessConnectDialog extends StatefulWidget {
  WirelessConnectDialog({
    super.key,
    required this.ipController,
    required this.portController,
  });

  final TextEditingController ipController;
  final TextEditingController portController;
  final _formKey = GlobalKey<FormState>();

  @override
  State<WirelessConnectDialog> createState() => _WirelessConnectDialogState();
}

class _WirelessConnectDialogState extends State<WirelessConnectDialog> {
  Future<void>? connectFuture;

  @override
  Widget build(BuildContext context) {
    if (connectFuture == null) {
      return _connectPrompt();
    }

    return FutureBuilder(
      builder: (context, snapshot) {
        if (snapshot.error != null) {
          return _error(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _connectingWait();
        }

        return _success();
      },
      future: connectFuture?.timeout(const Duration(seconds: 30)),
    );
  }

  Widget _success() {
    return AlertDialog(
      title: const Text("Success"),
      content: Center(
        child: Text(
            "Successfully connected to ${widget.ipController.text}:${widget.portController.text}"),
      ),
    );
  }

  Widget _error(String error) {
    return AlertDialog(
      title: const Text("Error"),
      content: SizedBox.square(
        dimension: 80,
        child: Center(
          child: Text(error),
        ),
      ),
    );
  }

  Widget _connectingWait() {
    return const AlertDialog(
      title: Text("Connecting"),
      content: SizedBox.square(
        dimension: 80,
        child: Center(
          child: CircularProgressIndicator.adaptive(
            value: null,
          ),
        ),
      ),
    );
  }

  Widget _connectPrompt() {
    return AlertDialog(
      title: const Text('Connect device wirelessly'),
      content: Form(
        key: widget._formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.ipController,
                  autocorrect: false,
                  autofocus: true,
                  validator: (value) =>
                      value?.isEmpty == true ? "No value provided" : null,
                  decoration: const InputDecoration(hintText: "IP"),
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: TextFormField(
                  controller: widget.portController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty == true) {
                      return "No value provided";
                    }

                    if (int.tryParse(value) == null) {
                      return "Not a number";
                    }

                    return null;
                  },
                  autocorrect: false,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Port"),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: _connect,
          child: const Text('Ok'),
        ),
      ],
    );
  }

  void _connect() {
    if (!widget._formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      connectFuture = Adb.connectWireless(
          widget.ipController.text, int.parse(widget.portController.text));
    });
  }
}
