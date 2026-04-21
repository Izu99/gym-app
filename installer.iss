[Setup]
AppName=Gym App
AppVersion=1.0
DefaultDirName={autopf}\GymApp
DefaultGroupName=Gym App
OutputDir=installer_output
OutputBaseFilename=GymApp_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.iss"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "client\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Gym App"; Filename: "{app}\gym_app.exe"
Name: "{commondesktop}\Gym App"; Filename: "{app}\gym_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\gym_app.exe"; Description: "Launch Gym App"; Flags: nowait postinstall skipifsilent
