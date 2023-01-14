import 'package:desktop_adb_file_browser/utils/adb.dart';

class FileData {
  final String file;
  final String serialName;

  Future<DateTime?> lastModifiedTime;
  Future<int?> fileSize;

  FileData({required this.serialName, required this.file})
      : lastModifiedTime = Adb.getFileModifiedDate(serialName, file),
        fileSize = Adb.getFileSize(serialName, file);
}
