import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

// Hopefully the release build omits this
void main() async {



  InnoSetup(
    app: InnoSetupApp(
      name: 'Desktop Adb File Browser',
      version: Version.parse("0.1.0"),
      publisher: 'Fernthedev',
      urls: InnoSetupAppUrls(
        homeUrl: Uri.parse('https://github.com/Fernthedev/desktop_adb_file_browser'),
      ),
    ),
    files: InnoSetupFiles(
      executable: File('build/windows/runner/release/desktop_adb_file_browser.exe'),
      location: Directory('build/windows/runner/release/'),
    ),
    name: const InnoSetupName('windows_installer'),
    location: InnoSetupInstallerDirectory(
      Directory('build/windows/runner/release'),
    ),
    icon: InnoSetupIcon(
      File('assets/icon.ico'),
    ),
  ).make();
}
