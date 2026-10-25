; Інсталятор української озвучки CONTROL Resonant (Inno Setup 6). Збірка: installer\make.ps1
; Файлів гри не поширюємо: CrUaVo.exe на ПК гравця копіює найменший архів самої гри (…-u01.rmdblob), дописує наш звук
; з ua_vo.bin і перебудовує індекси base-/stream0-it і base-/stream0-generic (оригінали → *.rmdtoc.orig).
; Звук стає в слот італійської озвучки. Видалення (CrUaVo.exe --restore) повертає оригінальні індекси.
#define AppVer "1.0"
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"

[Setup]
AppId={{AFC67AC6-76DE-4367-806B-097F4792DFE9}
AppName=Українська озвучка CONTROL Resonant
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
OutputBaseFilename=CONTROL-Resonant-Ukrainian-Voice-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українська озвучка CONTROL Resonant
UninstallFilesDir={app}\UkrainianVO
InfoBeforeFile=readme-uk.txt
; копії найменших архівів гри + наш звук (~0,9 ГБ) поряд із тимчасовим ua_vo.bin
ExtraDiskSpaceRequired=1100000000

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є підтека data_pack2\pc).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver].%n%nОфіційна сторінка й нові версії: {#SiteUrl}%n%nОзвучка безкоштовна. Перед встановленням закрийте гру.

[Files]
Source: "{#Payload}\CrUaVo.exe"; DestDir: "{app}\UkrainianVO"; Flags: ignoreversion
Source: "{#Payload}\ua_vo.bin"; DestDir: "{app}\UkrainianVO"; Flags: ignoreversion nocompression deleteafterinstall

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '3669870';
  GameSub = 'steamapps\common\CONTROL Resonant';

var
  BuildOk: Boolean;

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'data_pack2\pc\base-it.rmdtoc');
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
    MsgBox('У цій теці гри не знайдено (немає data_pack2\pc\base-it.rmdtoc). ' +
           'Оберіть теку CONTROL Resonant. Потрібна італійська озвучка гри (у Steam вона встановлюється разом із грою).',
           mbError, MB_OK);
    Result := False;
  end;
end;

function Tool: String;
begin
  Result := ExpandConstant('{app}\UkrainianVO\CrUaVo.exe');
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

procedure CurPageChanged(CurPageID: Integer);
var
  B: TNewButton;
  L: TNewStaticText;
begin
  if CurPageID <> wpFinished then Exit;
  L := TNewStaticText.Create(WizardForm);
  L.Parent := WizardForm.FinishedPage;
  L.Left := WizardForm.FinishedLabel.Left;
  L.Top := WizardForm.FinishedPage.Height - ScaleY(120);
  L.Width := WizardForm.FinishedLabel.Width;
  L.WordWrap := True;
  L.AutoSize := True;
  if BuildOk then
    L.Caption := 'Озвучку встановлено. У грі: Налаштування → Мова → озвучка «Italiano», субтитри «Українська».'
  else
    L.Caption := 'Озвучку не зібрано — див. повідомлення вище. Закрийте гру й запустіть інсталятор ще раз.';
  B := TNewButton.Create(WizardForm);
  B.Parent := WizardForm.FinishedPage;
  B.Left := WizardForm.FinishedLabel.Left;
  B.Top := WizardForm.FinishedPage.Height - ScaleY(56);
  B.Width := ScaleX(150);
  B.Height := ScaleY(26);
  B.Caption := 'Сайт українізатора';
  B.OnClick := @SiteClick;
  B := TNewButton.Create(WizardForm);
  B.Parent := WizardForm.FinishedPage;
  B.Left := WizardForm.FinishedLabel.Left + ScaleX(160);
  B.Top := WizardForm.FinishedPage.Height - ScaleY(56);
  B.Width := ScaleX(150);
  B.Height := ScaleY(26);
  B.Caption := 'Підтримати проєкт';
  B.OnClick := @DonateClick;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Code: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    WizardForm.StatusLabel.Caption := 'Збираю озвучку (до хвилини)...';
    WizardForm.ProgressGauge.Style := npbstMarquee;
    BuildOk := Exec(Tool, '"' + ExpandConstant('{app}\data_pack2\pc') + '" "' + ExpandConstant('{app}\UkrainianVO\ua_vo.bin') + '"',
                    '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0);
    WizardForm.ProgressGauge.Style := npbstNormal;
    if not BuildOk then
      MsgBox('Не вдалося зібрати озвучку (код ' + IntToStr(Code) + '). Закрийте гру, перевірте вільне місце ' +
             '(потрібно ~2 ГБ на диску з грою) і запустіть інсталятор ще раз. Якщо гру щойно оновлено — ' +
             'можливо, потрібна нова версія озвучки: {#SiteUrl}', mbError, MB_OK);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Code: Integer;
begin
  if CurUninstallStep = usUninstall then
    Exec(Tool, '--restore "' + ExpandConstant('{app}\data_pack2\pc') + '"', '', SW_HIDE, ewWaitUntilTerminated, Code);
end;
