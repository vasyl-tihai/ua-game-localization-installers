; Інсталятор українізатора STAR WARS Galactic Racer (Inno Setup 6). Збірка: installer\make.ps1
; Ставить у <гра>\Griffin\Content\Paks: текст (pakchunk99-Ukrainian_P) і озвучку (pakchunk98-UkrainianVO_P, компонент),
; вимикає русифікатор (*.off), перемикає GameLanguage=uk (українська множина). Видалення повертає все як було.
#define AppVer "1.0"
; Посилання вставляє Василь. Порожній DonateUrl — кнопки «Підтримати» не буде.
#define SiteUrl "https://gamerent.com.ua/ukrainizatory/star-wars-galactic-racer"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"

[Setup]
AppId={{6B1F3E2A-5C1D-4E7B-9A55-3B2F0C7D9E14}
AppName=Українізатор STAR WARS Galactic Racer
AppVersion={#AppVer}
AppPublisher=Українізатори ігор (неофіційно, безкоштовно)
AppPublisherURL={#SiteUrl}
AppSupportURL={#SiteUrl}
AppUpdatesURL={#SiteUrl}
DefaultDirName={code:GameDir}
DirExistsWarning=no
AppendDefaultDirName=no
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
OutputDir=..\build
OutputBaseFilename=SWGR-Ukrainian-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українізатор STAR WARS Galactic Racer
UninstallFilesDir={app}\Griffin\Content\Paks\UkrainianUninstall
InfoBeforeFile=readme-uk.txt

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є підтека Griffin).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».

[Types]
Name: "full"; Description: "Текст і озвучка"
Name: "text"; Description: "Лише текст (субтитри й інтерфейс)"

[Components]
Name: "text"; Description: "Текст: інтерфейс і субтитри (8 МБ)"; Types: full text; Flags: fixed
Name: "voice"; Description: "Українська озвучка (530 МБ, синтетичні голоси)"; Types: full

[Files]
Source: "{#Payload}\pakchunk99-Ukrainian_P.pak"; DestDir: "{app}\Griffin\Content\Paks"; Components: text; Flags: ignoreversion
Source: "{#Payload}\pakchunk99-Ukrainian_P.utoc"; DestDir: "{app}\Griffin\Content\Paks"; Components: text; Flags: ignoreversion
Source: "{#Payload}\pakchunk99-Ukrainian_P.ucas"; DestDir: "{app}\Griffin\Content\Paks"; Components: text; Flags: ignoreversion
Source: "{#Payload}\pakchunk98-UkrainianVO_P.pak"; DestDir: "{app}\Griffin\Content\Paks"; Components: voice; Flags: ignoreversion
Source: "{#Payload}\pakchunk98-UkrainianVO_P.utoc"; DestDir: "{app}\Griffin\Content\Paks"; Components: voice; Flags: ignoreversion
Source: "{#Payload}\pakchunk98-UkrainianVO_P.ucas"; DestDir: "{app}\Griffin\Content\Paks"; Components: voice; Flags: ignoreversion nocompression

[Messages]
WelcomeLabel2=Буде встановлено [name/ver].%n%nОфіційна сторінка й нові версії українізатора: {#SiteUrl}%n%nУкраїнізатор безкоштовний.

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '4078430';
  GameSub = 'steamapps\common\STAR WARS Galactic Racer';
  RuPak = 'pakchunk99-Russian_P';

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'Griffin\Content\Paks\pakchunk0-Windows.pak');
end;

{ Бібліотеки Steam: рядки  "path"  "D:\\SteamLibrary"  у libraryfolders.vdf }
function FromLibraries(Steam: String): String;
var
  Lines: TArrayOfString;
  I, P: Integer;
  S: String;
begin
  Result := '';
  if not LoadStringsFromFile(Steam + '\steamapps\libraryfolders.vdf', Lines) then Exit;
  for I := 0 to GetArrayLength(Lines) - 1 do
  begin
    S := Trim(Lines[I]);
    if Pos('"path"', S) = 1 then
    begin
      Delete(S, 1, 6);
      S := Trim(S);
      P := Length(S);
      if (P > 2) then
      begin
        S := Copy(S, 2, P - 2);
        StringChangeEx(S, '\\', '\', True);
        if IsGame(S + '\' + GameSub) then
        begin
          Result := S + '\' + GameSub;
          Exit;
        end;
      end;
    end;
  end;
end;

function GameDir(Param: String): String;
var
  S: String;
begin
  if RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ' + SteamAppId,
                         'InstallLocation', S) and IsGame(S) then begin Result := S; Exit; end;
  if RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath', S) then
  begin
    StringChangeEx(S, '/', '\', True);
    if IsGame(S + '\' + GameSub) then begin Result := S + '\' + GameSub; Exit; end;
    Result := FromLibraries(S);
    if Result <> '' then Exit;
  end;
  Result := ExpandConstant('{commonpf32}\Steam\') + GameSub;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) and not IsGame(WizardDirValue) then
  begin
    MsgBox('У цій теці гри не знайдено (немає Griffin\Content\Paks\pakchunk0-Windows.pak). ' +
           'Оберіть теку STAR WARS Galactic Racer.', mbError, MB_OK);
    Result := False;
  end;
end;

function IniPath: String;
begin
  Result := ExpandConstant('{localappdata}\StarWarsGalacticRacer\Saved\Config\Windows\GameUserSettings.ini');
end;

{ GameLanguage=<код> у налаштуваннях гри (якщо гру вже запускали) }
procedure SetLanguage(Code: String);
var
  Lines: TArrayOfString;
  I: Integer;
begin
  if not LoadStringsFromFile(IniPath, Lines) then Exit;
  for I := 0 to GetArrayLength(Lines) - 1 do
    if Pos('GameLanguage=', Lines[I]) = 1 then Lines[I] := 'GameLanguage=' + Code;
  SaveStringsToFile(IniPath, Lines, False);
end;

procedure RenameAll(Paks, FromSuffix, ToSuffix: String);
var
  Ext: array[0..2] of String;
  I: Integer;
begin
  Ext[0] := '.pak'; Ext[1] := '.utoc'; Ext[2] := '.ucas';
  for I := 0 to 2 do
    if FileExists(Paks + RuPak + Ext[I] + FromSuffix) then
      RenameFile(Paks + RuPak + Ext[I] + FromSuffix, Paks + RuPak + Ext[I] + ToSuffix);
end;

procedure OpenUrl(Url: String);
var
  Code: Integer;
begin
  ShellExec('open', Url, '', '', SW_SHOWNORMAL, ewNoWait, Code);
end;

procedure SiteClick(Sender: TObject);
begin
  OpenUrl('{#SiteUrl}');
end;

procedure DonateClick(Sender: TObject);
begin
  OpenUrl('{#DonateUrl}');
end;

{ Остання сторінка: підтримка без тиску — кнопки, нічого не відкривається само }
procedure CurPageChanged(CurPageID: Integer);
var
  B: TNewButton;
  L: TNewStaticText;
begin
  if CurPageID <> wpFinished then Exit;
  L := TNewStaticText.Create(WizardForm);
  L.Parent := WizardForm.FinishedPage;
  L.Left := WizardForm.FinishedLabel.Left;
  L.Top := WizardForm.FinishedPage.Height - ScaleY(80);
  L.Caption := 'Українізатор безкоштовний. Якщо сподобався — можна підтримати нові переклади.';
  B := TNewButton.Create(WizardForm);
  B.Parent := WizardForm.FinishedPage;
  B.Left := WizardForm.FinishedLabel.Left;
  B.Top := WizardForm.FinishedPage.Height - ScaleY(56);
  B.Width := ScaleX(150);
  B.Height := ScaleY(26);
  B.Caption := 'Сайт українізатора';
  B.OnClick := @SiteClick;
  if '{#DonateUrl}' <> '' then
  begin
    B := TNewButton.Create(WizardForm);
    B.Parent := WizardForm.FinishedPage;
    B.Left := WizardForm.FinishedLabel.Left + ScaleX(160);
    B.Top := WizardForm.FinishedPage.Height - ScaleY(56);
    B.Width := ScaleX(150);
    B.Height := ScaleY(26);
    B.Caption := 'Підтримати проєкт';
    B.OnClick := @DonateClick;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    RenameAll(ExpandConstant('{app}\Griffin\Content\Paks\'), '', '.off');  { русифікатор перекриває наш текст }
    SetLanguage('uk');
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    RenameAll(ExpandConstant('{app}\Griffin\Content\Paks\'), '.off', '');
    SetLanguage('en');
  end;
end;
