#ifndef AppVersion
#define AppVersion "0.1.0"
#endif

[Setup]
AppId={{A6DD1A4C-0C85-4BBA-B7B0-57D0A1AEAA2C}
AppName=CassetteCat
AppVersion={#AppVersion}
AppPublisher=CassetteCat
DefaultDirName={localappdata}\Programs\CassetteCat
DefaultGroupName=CassetteCat
UninstallDisplayIcon={app}\bin\CassetteCat.exe
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=CassetteCat-{#AppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
ChangesAssociations=yes

[Tasks]
Name: "associateAudio"; Description: "Associate supported audio files with CassetteCat"; Flags: unchecked
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "..\dist\CassetteCat\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\CassetteCat"; Filename: "{app}\bin\CassetteCat.exe"
Name: "{autodesktop}\CassetteCat"; Filename: "{app}\bin\CassetteCat.exe"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Classes\CassetteCat.Audio"; ValueType: string; ValueName: ""; ValueData: "CassetteCat Audio File"; Flags: uninsdeletekeyifempty; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\CassetteCat.Audio\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\CassetteCat.exe,0"; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\CassetteCat.Audio\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\CassetteCat.exe"" ""%1"""; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.mp3"; ValueType: string; ValueName: ""; ValueData: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.flac"; ValueType: string; ValueName: ""; ValueData: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.m4a"; ValueType: string; ValueName: ""; ValueData: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.ogg"; ValueType: string; ValueName: ""; ValueData: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.wav"; ValueType: string; ValueName: ""; ValueData: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
