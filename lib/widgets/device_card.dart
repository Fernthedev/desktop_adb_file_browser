import 'package:desktop_adb_file_browser/routes.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

@immutable
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    Key? key,
    required this.deviceName,
    required this.deviceManufacturer,
    required this.serialName,
  }) : super(key: key);

  final String deviceName;
  final String deviceManufacturer;
  final String serialName;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Routes.browse(context, serialName),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: ListTile(
                leading: const Icon(
                  FluentIcons.phone_24_regular,
                  size: 24 * 1.6,
                ),
                title: Text(deviceName),
                subtitle: Text(deviceManufacturer),
              ),
            ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(5),
                  // TODO: Make this copy to clipboard or something
                  // maybe device details page?
                  child: TextButton(onPressed: () {}, child: Text(serialName))),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () => Routes.log(context, serialName),
                        icon: const Icon(
                          FluentIcons.notepad_24_filled,
                          size: 24,
                        )),
                    IconButton(
                        onPressed: () => _enableWireless(context),
                        icon: const Icon(
                          FluentIcons.wifi_1_24_filled,
                          size: 24,
                        ))
                  ],
                ),
              ),
            )
          ],
        ),
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
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Adb.enableWireless(serialName);
            },
          ),
        ],
      ),
    );
  }
}
