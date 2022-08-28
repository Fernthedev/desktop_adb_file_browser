import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

import 'package:path/path.dart' as path;

// Hopefully the release build omits this
void main() async {
  InnoSetup(
    compression: const InnoSetupCompression("lzma"),
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
      Directory('build/windows/runner'),
    ),
    icon: InnoSetupIcon(
      File('assets/icon.ico'),
    ),
  ).fixedMake();
}

extension Fix on InnoSetup {
  void fixedMake() {
    final fixedExec = path.basename(files.executable.path);

    final iss = StringBuffer('''
[Setup]
AppId={{A1C2E38F-D907-4F41-ADDB-751FE07ADAEF}
$compression
SolidCompression=yes
$icon
$name
$location
${license ?? ''}
AppName=${app.name}
AppVersion=${app.version}
DefaultDirName={autopf}\\${app.name}
DefaultGroupName=${app.name}
DisableProgramGroupPage=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64

; Uncomment the following line to run in non administrative install mode (install for current user only.)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

${InnoSetupLanguagesBuilder(languages)}

$files

[UninstallRun]
Filename: "taskkill.exe"; Parameters: "/im adb.exe /f /t"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Icons]
Name: "{autoprograms}\\${app.name}"; Filename: "{app}\\$fixedExec"

${runAfterInstall ? '''
[Run]
Filename: "{app}\\$fixedExec"; Description: "{cm:LaunchProgram,${app.name}}"; Flags: nowait postinstall skipifsilent
''' : ''}
''');

    File('innosetup.iss').writeAsStringSync('$iss');
  }
}
