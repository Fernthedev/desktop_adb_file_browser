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
        homeUrl:
            Uri.parse('https://github.com/Fernthedev/desktop_adb_file_browser'),
      ),
    ),
    files: InnoSetupFiles(
      executable:
          File('build/windows/runner/Release/desktop_adb_file_browser.exe'),
      location: Directory('build/windows/runner/Release/'),
    ),
    name: const InnoSetupName('windows_installer'),
    location: InnoSetupInstallerDirectory(
      Directory('build/windows/runner/Release'),
    ),
    icon: InnoSetupIcon(
      File('assets/icon.ico'),
    ),
  ).fixedMake();
}

extension Fix on InnoSetup {
  void fixedMake() {
    final iss = StringBuffer('''
[Setup]
$compression
$icon
$name
$location
${license ?? ''}
AppName=${app.name}
AppVersion=${app.version}
DefaultDirName={autopf}\\${app.name}

${InnoSetupLanguagesBuilder(languages)}

$files

[Icons]
Name: "{autoprograms}\\${app.name}"; Filename: "{app}\\${app.name}"

${runAfterInstall ? InnoSetupRunBuilder(app) : ''}
''');

    File('innosetup.iss').writeAsStringSync('$iss');
  }
}
