import 'package:desktop_adb_file_browser/riverpod/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    var multipleADBLimit = SizedBox(
      width: 200,
      child: TextFormField(
        initialValue: settings.multipleAdbInstances.toString(),
        keyboardType: const TextInputType.numberWithOptions(
            signed: false, decimal: false),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ], // Only numbers can be entered
        decoration:
            const InputDecoration(label: Text("Multiple ADB Instance Limit")),
        onChanged: (v) => updateSettings(
          settings.copyWith(
              multipleAdbInstances:
                  (double.tryParse(v) ?? settings.multipleAdbInstances)
                      .toInt()),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Tooltip(
              message:
                  "Specifies the limit of ADB instances that can run simultaneously",
              waitDuration: const Duration(milliseconds: 500),
              child: multipleADBLimit,
            )
          ],
        ),
      ),
    );
  }

  void updateSettings(SettingsData settings) {
    var notifier = ref.read(settingsProvider.notifier);
    notifier.update(settings);
  }
}
