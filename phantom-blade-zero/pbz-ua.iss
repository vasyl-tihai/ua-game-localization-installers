; Інсталятор українізатора Phantom Blade Zero (Inno Setup 6). Збірка: installer\make.ps1
; Ставить у <гра>\ProjectPBZ\Content\Paks\~mods: текст (zz_UkrainianText_P.pak — en-US і ru locres + шрифти) і, за бажанням,
; озвучку (zz_UkrainianText_P.utoc/.ucas — IoStore з тим самим ім'ям, що й pak; замість англійської).
; Файли гри не змінюються; видалення прибирає лише наші файли.
#define AppVer "1.0"
; Сайт — головна сторінка (Василь 18.10). Підтримка — добровільна, не покупка.
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"
#define Mods "{app}\ProjectPBZ\Content\Paks\~mods"

[Setup]
AppId={{C169DED8-C590-4159-9BFC-31D62E7D226B}
AppName=Українізатор Phantom Blade Zero
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
OutputBaseFilename=PhantomBladeZero-Ukrainian-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українізатор Phantom Blade Zero
UninstallFilesDir={#Mods}\UkrainianUninstall
InfoBeforeFile=readme-uk.txt

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є підтека ProjectPBZ).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver].%n%nОфіційна сторінка й нові версії українізатора: {#SiteUrl}%n%nУкраїнізатор безкоштовний.

[Types]
Name: "full"; Description: "Текст і озвучка"
Name: "text"; Description: "Лише текст (субтитри й інтерфейс)"

[Components]
Name: "text"; Description: "Текст: інтерфейс, діалоги, субтитри, записи (7 МБ)"; Types: full text; Flags: fixed
Name: "voice"; Description: "Українська озвучка замість англійської (1,2 ГБ, синтетичні голоси)"; Types: full

[InstallDelete]
; перевстановлення «лише текст» поверх повного — прибрати стару озвучку
Type: files; Name: "{#Mods}\zz_UkrainianText_P.utoc"; Components: not voice
Type: files; Name: "{#Mods}\zz_UkrainianText_P.ucas"; Components: not voice

[Files]
Source: "{#Payload}\zz_UkrainianText_P.pak"; DestDir: "{#Mods}"; Components: text; Flags: ignoreversion
Source: "{#Payload}\OFL-AlegreyaSans.txt"; DestDir: "{#Mods}\UkrainianUninstall"; Components: text; Flags: ignoreversion
Source: "{#Payload}\zz_UkrainianText_P.utoc"; DestDir: "{#Mods}"; Components: voice; Flags: ignoreversion
Source: "{#Payload}\zz_UkrainianText_P.ucas"; DestDir: "{#Mods}"; Components: voice; Flags: ignoreversion nocompression

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '4115450';
  GameSub = 'steamapps\common\PBZ';

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'ProjectPBZ\Content\Paks\ProjectPBZ-Windows.utoc');
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
    MsgBox('У цій теці гри не знайдено (немає ProjectPBZ\Content\Paks\ProjectPBZ-Windows.utoc). ' +
           'Оберіть теку Phantom Blade Zero (у Steam вона називається PBZ).', mbError, MB_OK);
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
  L.Caption := 'У налаштуваннях гри лишіть мову тексту й озвучки English — українська стоїть на її місці.';
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
