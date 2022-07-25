import 'package:desktop_adb_file_browser/routes.dart';
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
  static String selectedSerial;

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
                  child:
                      TextButton(onPressed: () { selectedSerial = serialName; }, child: Text(serialName))),
            )
          ],
        ),
      ),
    );
  }
}
