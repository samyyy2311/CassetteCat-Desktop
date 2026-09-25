#ifndef AppVersion
#define AppVersion "0.7.0"
#endif

[Setup]
AppId={{A6DD1A4C-0C85-4BBA-B7B0-57D0A1AEAA2C}
AppName=CassetteCat
AppVersion={#AppVersion}
AppVerName=CassetteCat {#AppVersion}
AppPublisher=CassetteCat
AppPublisherURL=https://github.com/samyyy2311/CassetteCat-Desktop
AppSupportURL=https://github.com/samyyy2311/CassetteCat-Desktop/issues
AppUpdatesURL=https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest
AppComments=A local-first desktop music player
DefaultDirName={localappdata}\Programs\CassetteCat
DefaultGroupName=CassetteCat
SetupIconFile=..\assets\cassettecat_icon.ico
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
Name: "associateAudio"; Description: "Add CassetteCat to Open with for supported audio files"; Flags: unchecked
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "..\dist\CassetteCat\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\CassetteCat"; Filename: "{app}\bin\CassetteCat.exe"
Name: "{autodesktop}\CassetteCat"; Filename: "{app}\bin\CassetteCat.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\CassetteCat.exe"; Description: "Launch CassetteCat"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Classes\CassetteCat.Audio"; ValueType: string; ValueName: ""; ValueData: "CassetteCat Audio File"; Flags: uninsdeletekeyifempty; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\CassetteCat.Audio\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\bin\CassetteCat.exe,0"; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\CassetteCat.Audio\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\CassetteCat.exe"" ""%1"""; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.aac\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.aiff\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.alac\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.flac\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.m4a\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.mp3\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.ogg\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.opus\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.wav\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
Root: HKCU; Subkey: "Software\Classes\.wma\OpenWithProgids"; ValueType: none; ValueName: "CassetteCat.Audio"; Flags: uninsdeletevalue; Tasks: associateAudio
