import 'package:desktop_adb_file_browser/riverpod/package_list.dart';
import 'package:desktop_adb_file_browser/riverpod/selected_device.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/widgets/adb_queue_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PackageList extends ConsumerStatefulWidget {
  const PackageList({super.key, required this.serial});

  final String serial;

  @override
  ConsumerState<PackageList> createState() => _PackageListState();
}

class _PackageListState extends ConsumerState<PackageList> {
  @override
  Widget build(BuildContext context) {
    final packageListFuture = ref.watch(packageListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Packages"),
        automaticallyImplyLeading: true,
      ),
      body: ADBQueueIndicator(
        child: packageListFuture.when(
          data: (packageList) => ListView.separated(
            itemBuilder: (c, i) => itemBuilder(c, i, packageList),
            itemCount: packageList.length,
            shrinkWrap: true,
            separatorBuilder: (context, index) => const Divider(),
          ),
          error: (error, stackTrace) {
            debugPrint(error.toString());
            debugPrint(stackTrace.toString());
            return Center(
              child: Text("Error: $error"),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget? itemBuilder(
      BuildContext context, int index, List<String> packageList) {
    final packageId = packageList[index];
    final packageMetadataFuture = ref.watch(packageInfoProvider(packageId));
    final selectedDevice = ref.watch(selectedDeviceProvider);

    return packageMetadataFuture.when(
      data: (packageMetadata) => ListTile(
        title: Text(packageMetadata.packageName),
        subtitle:
            Text("${packageMetadata.packageId} - ${packageMetadata.version}"),
        dense: true,
        onTap: () {},
        trailing: Wrap(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.download)),
            IconButton(
                onPressed: () async {
                  await Adb.uninstallPackage(
                      selectedDevice!.serialName, packageId);
                  if (!context.mounted) return;
                  const snackBar = SnackBar(
                    content: Text('Uninstalled package'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                icon: const Icon(Icons.delete)),
            IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: packageMetadata.packageId));

                  if (!context.mounted) return;
                  const snackBar = SnackBar(
                    content: Text('Copied package id to clipboard'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                icon: const Icon(Icons.copy))
          ],
        ),
      ),
      error: (error, stackTrace) => ListTile(
        title: Text(packageId),
        subtitle: Text("Suffered error: $error"),
      ),
      loading: () => ListTile(
        title: Text(packageId),
        leading: const CircularProgressIndicator(),
      ),
    );
  }
}
