; Інсталятор української озвучки Відьмака 3 Remastered (Inno Setup 6). Збірка: installer\make.ps1
; Файлів гри не поширюємо: W3UaVo.exe на ПК гравця збирає content0\brpc.w3speech (слот BR) з його enpc.w3speech
; і нашого звуку ua_vo.bin, потім ua_vo.bin видаляється. У Documents\The Witcher 3\*.settings → озвучка BR, текст UA
; (попередні значення — у UkrainianVO\prev.ini). Видалення повертає мову й попередній brpc.w3speech (*.orig), якщо він був.
#define AppVer "1.0"
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"

[Setup]
AppId={{4F7A2C91-6B3E-4D58-A0F1-8E2D5C7B9A36}
AppName=Українська озвучка Відьмак 3
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
OutputBaseFilename=Witcher3-Ukrainian-Voice-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українська озвучка Відьмак 3
UninstallFilesDir={app}\UkrainianVO
InfoBeforeFile=readme-uk.txt
; збірка brpc.w3speech (~4,5 ГБ) поряд із тимчасовим ua_vo.bin
ExtraDiskSpaceRequired=4700000000

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є підтека content\content0).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver].%n%nОфіційна сторінка й нові версії: {#SiteUrl}%n%nОзвучка безкоштовна. Перед встановленням закрийте гру.

[Files]
Source: "{#Payload}\W3UaVo.exe"; DestDir: "{app}\UkrainianVO"; Flags: ignoreversion
Source: "{#Payload}\ua_vo.bin"; DestDir: "{app}\content\content0"; Flags: ignoreversion nocompression deleteafterinstall

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '292030';
  GameSub = 'steamapps\common\The Witcher 3';

var
  BuildOk: Boolean;

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'content\content0\enpc.w3speech');
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
  if RegQueryStringValue(HKLM32, 'SOFTWARE\GOG.com\Games\1495134320', 'path', S) and IsGame(S) then begin Result := S; Exit; end;
  if RegQueryStringValue(HKLM32, 'SOFTWARE\GOG.com\Games\1207664663', 'path', S) and IsGame(S) then begin Result := S; Exit; end;
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
    MsgBox('У цій теці гри не знайдено (немає content\content0\enpc.w3speech). ' +
           'Оберіть теку The Witcher 3. Потрібна англійська озвучка гри (вона є завжди).', mbError, MB_OK);
    Result := False;
  end;
end;

function C0: String;
begin
  Result := ExpandConstant('{app}\content\content0\');
end;

function PrevIni: String;
begin
  Result := ExpandConstant('{app}\UkrainianVO\prev.ini');
end;

{ Мова в одному файлі налаштувань: попереднє значення запам'ятовуємо один раз (перевстановлення його не затирає) }
procedure SetLang(Settings, Key, Value: String);
begin
  if not IniKeyExists(ExtractFileName(Settings), Key, PrevIni) then
    SetIniString(ExtractFileName(Settings), Key, GetIniString('Localization', Key, '', Settings), PrevIni);
  SetIniString('Localization', Key, Value, Settings);
end;

procedure SetSettings(Settings: String);
begin
  SetLang(Settings, 'RequestedSpeechLanguage', 'BR');
  SetLang(Settings, 'SpeechLanguage', 'BR');
  SetLang(Settings, 'RequestedTextLanguage', 'UA');
  SetLang(Settings, 'TextLanguage', 'UA');
end;

procedure RestoreLang(Settings, Key: String);
var
  V: String;
begin
  if not IniKeyExists(ExtractFileName(Settings), Key, PrevIni) then Exit;
  V := GetIniString(ExtractFileName(Settings), Key, '', PrevIni);
  if V = '' then V := 'EN';
  if FileExists(Settings) then SetIniString('Localization', Key, V, Settings);
end;

procedure RestoreSettings(Settings: String);
begin
  RestoreLang(Settings, 'RequestedSpeechLanguage');
  RestoreLang(Settings, 'SpeechLanguage');
  RestoreLang(Settings, 'RequestedTextLanguage');
  RestoreLang(Settings, 'TextLanguage');
end;

function Docs: String;
begin
  Result := ExpandConstant('{userdocs}\The Witcher 3\');
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
  L.Top := WizardForm.FinishedPage.Height - ScaleY(110);
  L.Width := WizardForm.FinishedLabel.Width;
  L.WordWrap := True;
  L.AutoSize := True;
  if BuildOk then
    L.Caption := 'Озвучку ввімкнено. У меню гри вона називається «Português do Brasil».'
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
    { чужий brpc.w3speech (справжня бразильська озвучка) — у *.orig, один раз }
    if FileExists(C0 + 'brpc.w3speech') and not FileExists(C0 + 'brpc.w3speech.orig')
       and not FileExists(ExpandConstant('{app}\UkrainianVO\built.txt')) then
      RenameFile(C0 + 'brpc.w3speech', C0 + 'brpc.w3speech.orig');
    WizardForm.StatusLabel.Caption := 'Збираю озвучку (кілька хвилин, ~4,5 ГБ)...';
    WizardForm.ProgressGauge.Style := npbstMarquee;
    BuildOk := Exec(ExpandConstant('{app}\UkrainianVO\W3UaVo.exe'),
                    '"' + C0 + 'enpc.w3speech" "' + C0 + 'ua_vo.bin" "' + C0 + 'brpc.w3speech"',
                    '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0);
    WizardForm.ProgressGauge.Style := npbstNormal;
    if BuildOk then
    begin
      SaveStringToFile(ExpandConstant('{app}\UkrainianVO\built.txt'), '{#AppVer}', False);
      ForceDirectories(Docs);
      if not FileExists(Docs + 'dx12user.settings') and not FileExists(Docs + 'user.settings') then
      begin
        SetSettings(Docs + 'dx12user.settings');
        SetSettings(Docs + 'user.settings');
      end
      else
      begin
        if FileExists(Docs + 'dx12user.settings') then SetSettings(Docs + 'dx12user.settings');
        if FileExists(Docs + 'user.settings') then SetSettings(Docs + 'user.settings');
      end;
    end
    else
      MsgBox('Не вдалося зібрати озвучку (код ' + IntToStr(Code) + '). Закрийте гру, перевірте вільне місце ' +
             '(потрібно ~5 ГБ на диску з грою) і запустіть інсталятор ще раз.', mbError, MB_OK);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    RestoreSettings(Docs + 'dx12user.settings');
    RestoreSettings(Docs + 'user.settings');
    DeleteFile(C0 + 'brpc.w3speech');
    DeleteFile(C0 + 'brpc.w3speech.tmp');
    DeleteFile(C0 + 'ua_vo.bin');
    if FileExists(C0 + 'brpc.w3speech.orig') then
      RenameFile(C0 + 'brpc.w3speech.orig', C0 + 'brpc.w3speech');
    DeleteFile(PrevIni);
    DeleteFile(ExpandConstant('{app}\UkrainianVO\built.txt'));
  end;
end;
