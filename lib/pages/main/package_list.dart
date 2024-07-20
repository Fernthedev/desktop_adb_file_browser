import 'package:desktop_adb_file_browser/riverpod/file_queue.dart';
import 'package:desktop_adb_file_browser/riverpod/package_list.dart';
import 'package:desktop_adb_file_browser/riverpod/selected_device.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/widgets/adb_queue_indicator.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PackageList extends ConsumerStatefulWidget {
  const PackageList({super.key, required this.serial});

  final String serial;

  @override
  ConsumerState<PackageList> createState() => _PackageListState();
}

class _PackageListState extends ConsumerState<PackageList> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final packageListFuture = ref.watch(packageListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Packages"),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
              onPressed: () async {
                final file = await openFile();
                if (file == null) return;

                await uploadAndInstallAPK(file.path);
              },
              icon: const Icon(FluentIcons.arrow_upload_32_regular))
        ],
      ),
      body: ADBQueueIndicator(
        child: Container(
          color:
              _dragging ? Theme.of(context).focusColor.withOpacity(0.4) : null,
          child: DropTarget(
            onDragDone: (details) async {
              for (final file in details.files) {
                await uploadAndInstallAPK(file.path);
              }
            },
            onDragEntered: (detail) {
              setState(() {
                _dragging = true;
              });
            },
            onDragExited: (detail) {
              setState(() {
                _dragging = false;
              });
            },
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
            IconButton(
                onPressed: () =>
                    _downloadPackage(selectedDevice!.serialName, packageId),
                icon: const Icon(Icons.download)),
            IconButton(
              onPressed: () =>
                  _deletePackage(selectedDevice!.serialName, packageId),
              icon: const Icon(Icons.delete),
            ),
            IconButton(
                onPressed: () => _copyPath(packageMetadata),
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

  Future<void> uploadAndInstallAPK(String apkPath) async {
    var notifier = ref.read(uploadQueueProvider.notifier);
    var device = ref.read(selectedDeviceProvider);

    var uuid = const Uuid();
    var randomPath = "/tmp/${uuid.v8()}.apk";

    await notifier.doUpload(device?.serialName, apkPath, randomPath);
    await Adb.installPackage(device?.serialName, randomPath);

    if (!context.mounted) return;
    final snackBar = SnackBar(
      content:
          Text('Installed package ${Adb.adbPathContext.basename(apkPath)}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // cleanup
    await Adb.removeFile(device?.serialName, randomPath);
  }

  void _deletePackage(String serialName, String packageId) async {
    await Adb.uninstallPackage(serialName, packageId);
    if (!context.mounted) return;
    const snackBar = SnackBar(
      content: Text('Uninstalled package'),
      showCloseIcon: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _downloadPackage(String serialName, String packageId) async {
    var destPath = await getSaveLocation(suggestedName: "$packageId.apk");
    if (destPath == null) return;

    var apkPath = await Adb.getPackagePath(serialName, packageId);
    var notifier = ref.read(downloadQueueProvider.notifier);

    await notifier.doDownload(serialName, apkPath, destPath.path);

    if (!context.mounted) return;
    final snackBar = SnackBar(
      content: Text('Downloaded apk to ${destPath.path}'),
      showCloseIcon: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _copyPath(PackageMetadata packageMetadata) async {
    await Clipboard.setData(ClipboardData(text: packageMetadata.packageId));

    if (!context.mounted) return;
    const snackBar = SnackBar(
      content: Text('Copied package id to clipboard'),
      showCloseIcon: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
