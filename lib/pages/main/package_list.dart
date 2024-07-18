import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// part 'package_list.g.dart';
part 'package_list.freezed.dart';

@freezed
class PackageMetadata with _$PackageMetadata {
  const factory PackageMetadata({
    required String packageName,
    required String packageId,
    required String version,
    required String groupId,
  }) = _PackageMetadata;
}

class PackageList extends StatefulWidget {
  const PackageList({super.key, required this.serial});

  final String serial;

  @override
  State<PackageList> createState() => _PackageListState();
}

class _PackageListState extends State<PackageList> {
  final packageList = [
    const PackageMetadata(
        groupId: "flamingo",
        packageId: "wen",
        packageName: "hoodie",
        version: "1.0.0"),
    const PackageMetadata(
        groupId: "flamingo",
        packageId: "wen",
        packageName: "hoodie",
        version: "1.0.0"),
    const PackageMetadata(
        groupId: "flamingo",
        packageId: "wen",
        packageName: "hoodie",
        version: "1.0.0"),
    const PackageMetadata(
        groupId: "flamingo",
        packageId: "wen",
        packageName: "hoodie",
        version: "1.0.0"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Packages"),
        automaticallyImplyLeading: true,
      ),
      body: ListView.separated(
        itemBuilder: itemBuilder,
        itemCount: packageList.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(),
      ),
    );
  }

  Widget? itemBuilder(BuildContext context, int index) {
    final item = packageList[index];
    return ListTile(
      title: Text(item.packageName),
      subtitle: Text(item.packageId),
      leading: const Icon(Icons.apps),
      dense: true,
      onTap: () {},
      trailing: Wrap(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.download)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }
}
