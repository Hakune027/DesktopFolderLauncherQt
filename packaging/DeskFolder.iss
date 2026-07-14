#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#ifndef MyOutputDir
  #define MyOutputDir "."
#endif
#ifndef MyOutputName
  #define MyOutputName "DeskFolder-Setup"
#endif

#define MyAppName "DeskFolder"
#define MyAppExeName "DesktopFolderLauncher.exe"
#define MyAppPublisher "DeskFolder"
#define MyAppDataDir "DesktopFolderLauncher"

[Setup]
AppId={{0F252019-1D64-4E4A-BB44-D30AA9051D45}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#MyOutputDir}
OutputBaseFilename={#MyOutputName}
SetupIconFile=..\assets\app.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
ChangesAssociations=yes

[Languages]
Name: "chinesesimp"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加快捷方式："; Flags: unchecked

[Files]
Source: "..\package\DeskFolder\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "DesktopFolderLauncher"; Flags: uninsdeletevalue

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\{#MyAppDataDir}"; Check: ShouldDeleteUserData

[Code]
var
  KeepUserData: Boolean;

function InitializeUninstall(): Boolean;
var
  Choice: Integer;
begin
  Choice := MsgBox(
    '是否保留 DeskFolder 的文件夹配置？' + #13#10 + #13#10 +
    '选择“是”将保留文件夹、布局、外观设置和自定义封面。' + #13#10 +
    '选择“否”将删除全部用户配置。',
    mbConfirmation, MB_YESNOCANCEL);
  if Choice = IDCANCEL then
  begin
    Result := False;
    exit;
  end;
  KeepUserData := Choice = IDYES;
  Result := True;
end;

function ShouldDeleteUserData(): Boolean;
begin
  Result := not KeepUserData;
end;
