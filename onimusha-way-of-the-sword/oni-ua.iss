; Інсталятор українізатора Onimusha: Way of the Sword (Inno Setup 6). Збірка: installer\make.ps1
; Ставить у <гра>: dinput8.dll (REFramework, MIT — без нього гра ігнорує pak_mods), pak_mods\re_chunk_000.pak.patch_002.pak (текст
; у RU-слоті) і, за бажанням, patch_003.pak (озвучка в RU-слоті). Файли гри не змінюються; видалення прибирає лише наші файли.
#define AppVer "1.0"
; Сайт — головна сторінка (Василь 18.10). Підтримка — добровільна, не покупка.
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"
#define Mods "{app}\pak_mods"

[Setup]
AppId={{FF5EA2B0-0599-4AED-98F7-51E93C11F2CD}
AppName=Українізатор Onimusha: Way of the Sword
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
OutputBaseFilename=OnimushaWotS-Ukrainian-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українізатор Onimusha: Way of the Sword
UninstallFilesDir={#Mods}\UkrainianUninstall
InfoBeforeFile=readme-uk.txt
CloseApplications=no

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є OnimushaWotS.exe).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver].%n%nОфіційна сторінка й нові версії українізатора: {#SiteUrl}%n%nУкраїнізатор безкоштовний.

[Types]
Name: "full"; Description: "Текст і озвучка"
Name: "text"; Description: "Лише текст (субтитри й інтерфейс)"

[Components]
Name: "text"; Description: "Текст: інтерфейс, діалоги, субтитри, записи + REFramework (40 МБ)"; Types: full text; Flags: fixed
Name: "voice"; Description: "Українська озвучка (1,1 ГБ, синтетичні голоси)"; Types: full

[InstallDelete]
; перевстановлення «лише текст» поверх повного — прибрати стару озвучку
Type: files; Name: "{#Mods}\re_chunk_000.pak.patch_003.pak"; Components: not voice

[Files]
Source: "{#Payload}\dinput8.dll"; DestDir: "{app}"; Components: text; Flags: ignoreversion
Source: "{#Payload}\re_chunk_000.pak.patch_002.pak"; DestDir: "{#Mods}"; Components: text; Flags: ignoreversion
Source: "{#Payload}\LICENSE-REFramework.txt"; DestDir: "{#Mods}\UkrainianUninstall"; Components: text; Flags: ignoreversion
Source: "{#Payload}\re_chunk_000.pak.patch_003.pak"; DestDir: "{#Mods}"; Components: voice; Flags: ignoreversion nocompression

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '2638890';
  GameSub = 'steamapps\common\OnimushaWotS';

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'OnimushaWotS.exe') and FileExists(AddBackslash(Dir) + 're_chunk_000.pak');
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
    MsgBox('У цій теці гри не знайдено (немає OnimushaWotS.exe і re_chunk_000.pak). ' +
           'Оберіть теку Onimusha: Way of the Sword (у Steam вона називається OnimushaWotS).', mbError, MB_OK);
    Result := False;
  end;
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
  L.Top := WizardForm.FinishedPage.Height - ScaleY(100);
  L.Width := WizardForm.FinishedLabel.Width;
  L.WordWrap := True;
  L.AutoSize := True;
  L.Caption := 'У налаштуваннях гри оберіть мову тексту й озвучки «Русский» — українська стоїть на її місці.';
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
