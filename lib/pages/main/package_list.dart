import 'package:desktop_adb_file_browser/riverpod/package_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
      body: packageListFuture.when(
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
    );
  }

  Widget? itemBuilder(
      BuildContext context, int index, List<String> packageList) {
    final packageId = packageList[index];
    final packageMetadataFuture = ref.watch(packageInfoProvider(packageId));

    return packageMetadataFuture.when(
      data: (packageMetadata) => ListTile(
        title: Text(packageMetadata.packageName),
            Text("${packageMetadata.packageId} - ${packageMetadata.version}"),
        leading: const Icon(Icons.apps),
        dense: true,
        onTap: () {},
        trailing: Wrap(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.download)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
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
