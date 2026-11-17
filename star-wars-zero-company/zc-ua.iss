; Інсталятор українізатора STAR WARS Zero Company (Inno Setup 6). Збірка: installer\make.ps1
; Ставить у <гра>\SWZeroCompany\Content\Paks пак pakchunk99-Windows_P (.pak + stub .utoc/.ucas): текст у слоті en,
; шрифти, перебудовані банки Wwise і озвучка. Файли гри не змінюються; видалення прибирає пак.
#define AppVer "1.0"
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"

[Setup]
AppId={{1E32FB61-7C89-4C78-AB23-7D91606A7E7B}
AppName=Українізатор STAR WARS Zero Company
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
OutputBaseFilename=ZeroCompany-Ukrainian-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українізатор STAR WARS Zero Company
UninstallFilesDir={app}\SWZeroCompany\Content\Paks\UkrainianUninstall
InfoBeforeFile=readme-uk.txt

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є підтека SWZeroCompany).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver]: текст і озвучка (~390 МБ).%n%nОфіційна сторінка й нові версії українізатора: {#SiteUrl}%n%nУкраїнізатор безкоштовний.

[Files]
Source: "{#Payload}\pakchunk99-Windows_P.pak"; DestDir: "{app}\SWZeroCompany\Content\Paks"; Flags: ignoreversion nocompression
Source: "{#Payload}\pakchunk99-Windows_P.utoc"; DestDir: "{app}\SWZeroCompany\Content\Paks"; Flags: ignoreversion
Source: "{#Payload}\pakchunk99-Windows_P.ucas"; DestDir: "{app}\SWZeroCompany\Content\Paks"; Flags: ignoreversion

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '2075800';
  GameSub = 'steamapps\common\Star Wars Zero Company';

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'SWZeroCompany\Content\Paks\pakchunk0-Windows.pak');
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
    MsgBox('У цій теці гри не знайдено (немає SWZeroCompany\Content\Paks\pakchunk0-Windows.pak). ' +
           'Оберіть теку Star Wars Zero Company.', mbError, MB_OK);
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
  L.Caption := 'Мову в грі й у Steam лишіть англійською — переклад стоїть на її місці.';
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
