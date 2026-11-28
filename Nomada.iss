; Instalador de Nómada para Inno Setup 6.
; Antes de compilar, genera dist\Nomada con PyInstaller (ver README).
; Compilar: ISCC Nomada.iss  ->  dist\NomadaSetup-<versión>.exe

#define AppName "Nómada"
#define AppVersion "1.2.0"
#define AppExe "Nomada.exe"

[Setup]
; AppId identifica la app para actualizar/desinstalar: no lo cambies entre versiones
AppId={{5874B634-9359-4BA7-950D-542AE5B513CE}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=gimi34
AppPublisherURL=https://github.com/gimi34/Nomada
DefaultDirName={autopf}\Nomada
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\nomada.ico
SetupIconFile=iconos\nomada.ico
OutputDir=dist
OutputBaseFilename=NomadaSetup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Permite instalar solo para el usuario actual, sin permisos de administrador
PrivilegesRequiredOverridesAllowed=dialog
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\Nomada\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; El logo va como .ico aparte y no dentro del .exe: incrustarlo cambia la huella del .exe
; y Smart App Control lo bloquea (sin incrustar, conserva la del lanzador de PyInstaller).
Source: "iconos\nomada.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\nomada.ico"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\nomada.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
