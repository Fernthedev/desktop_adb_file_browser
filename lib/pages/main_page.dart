import 'package:desktop_adb_file_browser/pages/main/browser.dart';
import 'package:desktop_adb_file_browser/pages/main/devices.dart';
import 'package:desktop_adb_file_browser/pages/main/logger.dart';
import 'package:desktop_adb_file_browser/pages/main/package_list.dart';
import 'package:desktop_adb_file_browser/pages/main/settings.dart';
import 'package:desktop_adb_file_browser/riverpod/selected_device.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Page {
  devices("Devices", FluentIcons.phone_48_regular, false),
  browser("Browser", FluentIcons.folder_48_regular, true),
  logger("Logger", FluentIcons.code_block_48_regular, true),
  packages("Packages", FluentIcons.apps_48_regular, true),
  settings("Settings", FluentIcons.settings_48_regular, false);

  const _Page(this.name, this.icon, this.requiresDevice);

  final String name;
  final IconData icon;
  final bool requiresDevice;
}

_Page _pageForIndex(int v) =>
    _Page.values.firstWhere((element) => element.index == v);

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  _Page _currentPage = _Page.devices;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDeviceSelect() {
    setState(() {});
  }

  Widget addDisabledTooltip(Widget widget) {
    final selectedDevice = ref.read(selectedDeviceProvider);
    if (selectedDevice != null) return widget;

    return Tooltip(
      message: "No device selected",
      child: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = ref.watch(selectedDeviceProvider);

    final dests = _Page.values
        .map((x) => NavigationRailDestination(
              icon: addDisabledTooltip(Icon(x.icon)),
              label: Text(x.name),
              disabled: x.requiresDevice && selectedDevice == null,
            ))
        .toList();

    return Scaffold(
      body: Row(children: [
        NavigationRail(
          backgroundColor: Theme.of(context).colorScheme.surface.darken(2),
          indicatorShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelType: NavigationRailLabelType.selected,
          selectedIndex: _currentPage.index,
          destinations: dests,
          onDestinationSelected: (v) => setState(
            () => _currentPage = _pageForIndex(v),
          ),
        ),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: _buildCurrentPage(_currentPage),
          ),
        )
      ]),
    );
  }

  Widget _buildCurrentPage(_Page p) {
    final selectedDevice = ref.watch(selectedDeviceProvider);

    return switch (p) {
      _Page.devices => const DevicesPage(
          key: ValueKey("devices"),
          canNavigate: false,
        ),
      _Page.browser => DeviceBrowserPage(
          key: const ValueKey("browser"),
          serial: selectedDevice!.serialName,
        ),
      _Page.logger => LogPage(
          key: const ValueKey("logger"),
          serial: selectedDevice!.serialName,
        ),
      _Page.packages => PackageList(
          key: const ValueKey("packages"),
          serial: selectedDevice!.serialName,
        ),
      _Page.settings => const SettingsPage(),
    };
  }
}
