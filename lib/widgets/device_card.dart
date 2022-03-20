import 'dart:ui';

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
        onTap: () => {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: ListTile(
                leading: const Icon(
                  FluentIcons.phone_24_regular,
                  size: 24 * 1.6,
                ),
                title: Text(deviceName),
                subtitle: Text(deviceManufacturer),
              ),
              flex: 2,
            ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(5),
                  child:
                      TextButton(onPressed: () => {}, child: Text(serialName))),
            )
          ],
        ),
      ),
    );
  }
}
