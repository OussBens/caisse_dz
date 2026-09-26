; Script Inno Setup pour CaisseDZ (desktop Windows).
;
; Prérequis avant de compiler :
;   1. flutter build windows --release   (build\windows\x64\runner\Release\ à jour)
;   2. Inno Setup 6 installé (https://jrsoftware.org/isinfo.php)
;
; Compilation : ouvrir ce fichier dans Inno Setup Compiler, ou en ligne de
; commande :  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\caisse_dz.iss
; L'installeur généré est déposé dans installer\output\.

#define MyAppName "CaisseDZ"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "BENS-DS"
#define MyAppExeName "caisse_dz.exe"
#define MyReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{6E8B9C2D-6E36-4B7B-9C0B-6E7B9C6B0B10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=CaisseDZ-Setup-{#MyAppVersion}
SetupIconFile=setup_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; Installation dans Program Files -> nécessite les droits admin (standard).
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
; Ferme l'app si elle tourne encore lors d'une mise à jour, au lieu d'échouer.
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer une icône sur le Bureau"; GroupDescription: "Icônes supplémentaires:"

[Files]
; Copie tout le contenu du build Release (exe, DLLs dont sqlite3.dll, dossier data\).
Source: "{#MyReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Désinstaller {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Lancer {#MyAppName}"; Flags: nowait postinstall skipifsilent

; Note : les données de l'application (base de données chiffrée, photos,
; token de session, etc.) sont stockées dans %APPDATA%\Caisse DZ\ — hors de
; {app} — et ne sont donc jamais touchées par une réinstallation/mise à jour
; ni supprimées par la désinstallation (voir DBCreate.getLocalFolder()).
