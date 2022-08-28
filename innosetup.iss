[Setup]
AppId={{A1C2E38F-D907-4F41-ADDB-751FE07ADAEF}
Compression=lzma
SolidCompression=yes
SetupIconFile=E:\SSDUse\ProgrammingProjects\FlutterProjects\desktop_adb_file_browser\assets/icon.ico
OutputBaseFilename=windows_installer
OutputDir=E:\SSDUse\ProgrammingProjects\FlutterProjects\desktop_adb_file_browser\build/windows/runner

AppName=Desktop Adb File Browser
AppVersion=0.1.0
DefaultDirName={autopf}\Desktop Adb File Browser
DefaultGroupName=Desktop Adb File Browser
DisableProgramGroupPage=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64

; Uncomment the following line to run in non administrative install mode (install for current user only.)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"


[Files]
Source: "E:\SSDUse\ProgrammingProjects\FlutterProjects\desktop_adb_file_browser\build/windows/runner/Release/desktop_adb_file_browser.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "E:\SSDUse\ProgrammingProjects\FlutterProjects\desktop_adb_file_browser\build/windows/runner/Release/\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs


[UninstallRun]
Filename: "taskkill.exe"; Parameters: "/im adb.exe /f /t"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Icons]
Name: "{autoprograms}\Desktop Adb File Browser"; Filename: "{app}\desktop_adb_file_browser.exe"

[Run]
Filename: "{app}\desktop_adb_file_browser.exe"; Description: "{cm:LaunchProgram,Desktop Adb File Browser}"; Flags: nowait postinstall skipifsilent

