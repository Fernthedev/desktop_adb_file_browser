import 'package:desktop_adb_file_browser/pages/main/browser.dart';
import 'package:desktop_adb_file_browser/pages/main/devices.dart';
import 'package:desktop_adb_file_browser/pages/main/logger.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

enum _Page {
  devices("Devices", FluentIcons.phone_48_regular),
  browser("Browser", FluentIcons.folder_48_regular),
  logger("Logger", FluentIcons.note_48_regular);

  const _Page(this.name, this.icon);

  final String name;
  final IconData icon;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  _Page _currentPage = _Page.devices;
  final ValueNotifier<String?> _selectedDevice = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    var dests = _Page.values
        .map((x) => NavigationRailDestination(
              icon: Icon(x.icon),
              label: Text(x.name),
            ))
        .toList();

    return Scaffold(
      body: Row(children: [
        NavigationRail(
            selectedIndex: _currentPage.index,
            destinations: dests,
            onDestinationSelected: (v) =>
                setState(() => _currentPage = v as _Page)),
        Expanded(
          child: _buildCurrentPage(_currentPage),
        )
      ]),
    );
  }

  Widget _buildCurrentPage(_Page p) => switch (p) {
        _Page.devices => DevicesPage(key: const ValueKey("devices"), _selectedDevice),
        _Page.browser => DeviceBrowserPage(
            key: const ValueKey("browser"),
            initialAddress: "/",
            serial: _selectedDevice.value!,
          ),
        _Page.logger => LogPage(
            key: const ValueKey("logger"),
            serial: _selectedDevice.value!,
          ),
      };
}
