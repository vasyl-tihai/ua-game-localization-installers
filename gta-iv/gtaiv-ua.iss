; Інсталятор українізатора GTA IV: The Complete Edition (IV + TLAD + TBoGT), Inno Setup 6. Збірка: installer\make.ps1
; Файли гри в інсталяторі НЕМАЄ: лише патчі HDiffPatch (оригінал → українська версія), застосовуються на ПК гравця.
; Оригінал кожного зміненого файлу лишається поруч як *.orig; видалення повертає все як було.
#define AppVer "1.0"
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"

[Setup]
AppId={{3D7A9C41-8E2B-4F6D-B1A3-6C0E5F92D847}
AppName=Українізатор GTA IV: The Complete Edition
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
OutputBaseFilename=GTAIV-Ukrainian-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
DiskSpanning=yes
DiskSliceSize=max
ExtraDiskSpaceRequired=4400000000
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українізатор GTA IV: The Complete Edition
UninstallFilesDir={app}\UkrainianUninstall
InfoBeforeFile=readme-uk.txt

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку GTAIV (у ній є GTAIV.exe), наприклад …\steamapps\common\Grand Theft Auto IV\GTAIV.
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver] для основної гри, The Lost and Damned і The Ballad of Gay Tony.%n%nОфіційна сторінка й нові версії українізатора: {#SiteUrl}%n%nУкраїнізатор безкоштовний.

[Types]
Name: "full"; Description: "Текст і озвучка"
Name: "text"; Description: "Лише текст (субтитри й інтерфейс)"

[Components]
Name: "text"; Description: "Текст: інтерфейс і субтитри, українські шрифти"; Types: full text; Flags: fixed
Name: "voice"; Description: "Українська озвучка (синтетичні голоси, ~38 700 реплік)"; Types: full

[Files]
Source: "{#Payload}\hpatchz.exe"; DestDir: "{tmp}\ua"; Flags: ignoreversion deleteafterinstall
Source: "readme-uk.txt"; DestDir: "{app}\UkrainianUninstall"; Flags: ignoreversion

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сайт українізаторів"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '12210';
  GameSub = 'steamapps\common\Grand Theft Auto IV\GTAIV';

var
  LComp, LRel, LPatch, LSha: TArrayOfString;
  LOld, LNew: array of Integer;

procedure Add(Comp, Rel, Patch: String; OldSize, NewSize: Integer; Sha: String);
var
  N: Integer;
begin
  N := GetArrayLength(LRel);
  SetArrayLength(LComp, N + 1); SetArrayLength(LRel, N + 1); SetArrayLength(LPatch, N + 1); SetArrayLength(LSha, N + 1);
  SetArrayLength(LOld, N + 1); SetArrayLength(LNew, N + 1);
  LComp[N] := Comp; LRel[N] := Rel; LPatch[N] := Patch; LOld[N] := OldSize; LNew[N] := NewSize; LSha[N] := Sha;
end;

#include "gen.iss"

[Code]
function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'GTAIV.exe') and FileExists(AddBackslash(Dir) + 'common\text\american.gxt');
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
                         'InstallLocation', S) then
  begin
    if IsGame(S) then begin Result := S; Exit; end;
    if IsGame(S + '\GTAIV') then begin Result := S + '\GTAIV'; Exit; end;
  end;
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
    MsgBox('У цій теці гри не знайдено (немає GTAIV.exe). Оберіть теку ...\Grand Theft Auto IV\GTAIV.', mbError, MB_OK);
    Result := False;
  end;
end;

function SizeOf(Path: String): Integer;
begin
  if not FileSize(Path, Result) then Result := -1;
end;

{ Розмір оригіналу: *.orig (українізатор уже ставили) або сам файл }
function OrigSize(I: Integer): Integer;
var
  T: String;
begin
  T := ExpandConstant('{app}\') + LRel[I];
  if FileExists(T + '.orig') then Result := SizeOf(T + '.orig') else Result := SizeOf(T);
end;

{ До копіювання: усі потрібні оригінали на місці й тієї самої версії (Steam, Complete Edition) }
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  I: Integer;
  Bad: String;
begin
  Result := '';
  InitList;
  Bad := '';
  for I := 0 to GetArrayLength(LRel) - 1 do
    if WizardIsComponentSelected(LComp[I]) and (OrigSize(I) <> LOld[I]) then
      Bad := Bad + #13#10 + '  ' + LRel[I];
  if Bad <> '' then
    Result := 'Ці файли гри відрізняються від версії, під яку зроблено українізатор ' +
              '(GTA IV: The Complete Edition у Steam, оновлена):' + Bad + #13#10#13#10 +
              'Перевірте цілісність файлів гри в Steam (Властивості → Встановлені файли → Перевірити) і запустіть інсталятор ще раз.';
end;

procedure ApplyPatches;
var
  I, Code: Integer;
  T, O, Hp, Failed: String;
  Made: Boolean;
begin
  Hp := ExpandConstant('{tmp}\ua\hpatchz.exe');
  Failed := '';
  for I := 0 to GetArrayLength(LRel) - 1 do
  begin
    if not WizardIsComponentSelected(LComp[I]) then Continue;
    T := ExpandConstant('{app}\') + LRel[I];
    O := T + '.orig';
    WizardForm.StatusLabel.Caption := 'Застосування: ' + LRel[I];
    WizardForm.ProgressGauge.Position := WizardForm.ProgressGauge.Max * I div GetArrayLength(LRel);
    Made := False;
    if not FileExists(O) then
    begin
      if not RenameFile(T, O) then begin Failed := Failed + #13#10 + '  ' + LRel[I]; Continue; end;
      Made := True;
    end;
    DeleteFile(T + '.ua_tmp');
    if Exec(Hp, '-f "' + O + '" "' + ExpandConstant('{tmp}\ua\') + LPatch[I] + '" "' + T + '.ua_tmp"', '',
            SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0) and (SizeOf(T + '.ua_tmp') = LNew[I]) and (GetSHA1OfFile(T + '.ua_tmp') = LSha[I]) then
    begin
      DeleteFile(T);
      RenameFile(T + '.ua_tmp', T);
    end
    else
    begin
      DeleteFile(T + '.ua_tmp');
      if Made then RenameFile(O, T);   { повертаємо оригінал на місце }
      Failed := Failed + #13#10 + '  ' + LRel[I];
    end;
  end;
  if Failed <> '' then
    MsgBox('Не вдалося застосувати до файлів:' + Failed + #13#10#13#10 +
           'Ці файли лишилися оригінальними. Перевірте цілісність файлів гри в Steam і місце на диску, ' +
           'потім встановіть українізатор ще раз.', mbError, MB_OK);
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
  B.Caption := 'Сайт українізаторів';
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
  if CurStep = ssPostInstall then ApplyPatches;
end;

{ Видалення: кожен *.orig повертається на місце (і після «лише текст», і після повної установки) }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  I: Integer;
  T: String;
begin
  if CurUninstallStep <> usUninstall then Exit;
  InitList;
  for I := 0 to GetArrayLength(LRel) - 1 do
  begin
    T := ExpandConstant('{app}\') + LRel[I];
    if FileExists(T + '.orig') then
    begin
      DeleteFile(T);
      RenameFile(T + '.orig', T);
    end;
  end;
end;
