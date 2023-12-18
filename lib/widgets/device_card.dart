import 'package:desktop_adb_file_browser/routes.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

@immutable
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.selected,
    this.showLogButton = true,
  });

  final Device device;
  final void Function(Device device) onTap;
  final bool showLogButton;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    var logButton = Visibility(
      visible: showLogButton,
      child: IconButton(
          onPressed: () => Routes.log(context, device.serialName),
          icon: const Icon(
            FluentIcons.notepad_24_filled,
            size: 24,
          )),
    );

    var wirelessButton = IconButton(
        onPressed: () => _enableWireless(context),
        icon: const Icon(
          FluentIcons.wifi_1_24_filled,
          size: 24,
        ));

    const icon = Icon(
      FluentIcons.phone_24_regular,
      size: 24 * 1.6,
    );


    return ListTile(
      selected: selected ?? false,
      leading: icon,
      isThreeLine: true,
      onTap: () => onTap(device),
      title: Text(device.modelName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(device.deviceManufacturer ?? "Unknown Manufacturer"),
          TextButton(
            child: Text(device.serialName),
            onPressed: () {},
          ),
        ],
      ),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [logButton, wirelessButton],
      ),
    );
  }

  Future<void> _enableWireless(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Wireless'),
        content: const Text("Enable wireless mode on device?"),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FilledButton(
            autofocus: true,
            child: const Text('Ok'),
            onPressed: () {
              Adb.enableWireless(device.serialName);
            },
          ),
        ],
      ),
    );
  }
}
