#ifndef AppVersion
  #error AppVersion must be supplied by the build workflow.
#endif
#ifndef AppRoot
  #error AppRoot must be supplied by the build workflow.
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif

[Setup]
AppId={{6e6cae95-c504-4d9a-b9c8-6d292fc37743}
AppName=Scarlett
AppVersion={#AppVersion}
AppPublisher=Basskiller
AppPublisherURL=https://github.com/spadxz/scarlett
AppSupportURL=https://github.com/spadxz/scarlett/issues
AppUpdatesURL=https://github.com/spadxz/scarlett/releases
DefaultDirName={localappdata}\Programs\Scarlett
DefaultGroupName=Scarlett
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\bin\scarlett.exe
SetupIconFile=..\icons\scarlett.ico
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
OutputDir={#OutputDir}
OutputBaseFilename=scarlett-{#AppVersion}-windows-x86_64-setup
SetupLogging=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked

[Files]
Source: "{#AppRoot}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Scarlett"; Filename: "{app}\bin\scarlett.exe"
Name: "{autodesktop}\Scarlett"; Filename: "{app}\bin\scarlett.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\scarlett.exe"; Description: "Launch Scarlett"; Flags: nowait postinstall skipifsilent
