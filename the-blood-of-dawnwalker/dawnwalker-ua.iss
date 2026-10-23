; Інсталятор українізатора The Blood of Dawnwalker (Inno Setup 6). Збірка: installer\make.ps1
; Ставить у <гра>\Dawnwalker\Content\Paks\~mods: текст (zz_Ukrainian_P, слот чеської «Čeština» → «Українська») і озвучку
; (zz_UkrainianVO_P, компонент, замінює англійську). Ролики слота cs: попередження — копії англійських із самої гри,
; субтитри інтро/титрів — наші; оригінали → *.orig. Видалення повертає все як було.
#define AppVer "2.0"
; Сайт — головна сторінка (Василь 18.10). Підтримка — добровільна, не покупка.
#define SiteUrl "https://gamerent.com.ua"
#define DonateUrl "https://send.monobank.ua/jar/Ry1LdCDFF"
#define Payload "..\build\installer-payload"

[Setup]
AppId={{9C4E2B71-3A8D-4F15-B6E0-5D7A1C93F2E8}
AppName=Українізатор The Blood of Dawnwalker
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
OutputBaseFilename=Dawnwalker-Ukrainian-{#AppVer}-setup
Compression=lzma2/fast
SolidCompression=no
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Українізатор The Blood of Dawnwalker
UninstallFilesDir={app}\Dawnwalker\Content\Paks\~mods\UkrainianUninstall
InfoBeforeFile=readme-uk.txt

[Languages]
Name: "uk"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Messages]
SelectDirLabel3=Оберіть теку, де встановлено гру (у ній є підтека Dawnwalker).
SelectDirBrowseLabel=Якщо теку знайдено неправильно, натисніть «Огляд».
WelcomeLabel2=Буде встановлено [name/ver].%n%nОфіційна сторінка й нові версії українізатора: {#SiteUrl}%n%nУкраїнізатор безкоштовний.

[Types]
Name: "full"; Description: "Текст і озвучка"
Name: "text"; Description: "Лише текст (субтитри й інтерфейс)"

[Components]
Name: "text"; Description: "Текст: інтерфейс, діалоги, субтитри (12 МБ)"; Types: full text; Flags: fixed
Name: "voice"; Description: "Українська озвучка (1,2 ГБ, синтетичні голоси)"; Types: full

[Files]
Source: "{#Payload}\zz_Ukrainian_P.pak"; DestDir: "{app}\Dawnwalker\Content\Paks\~mods"; Components: text; Flags: ignoreversion
Source: "{#Payload}\zz_UkrainianVO_P.pak"; DestDir: "{app}\Dawnwalker\Content\Paks\~mods"; Components: voice; Flags: ignoreversion nocompression
Source: "{#Payload}\movies\*.srt"; DestDir: "{tmp}\movies"; Components: text; Flags: ignoreversion

[Run]
Filename: "{#SiteUrl}"; Description: "Відкрити сторінку українізатора"; Flags: postinstall shellexec nowait skipifsilent unchecked

[Code]
const
  SteamAppId = '3751260';
  GameSub = 'steamapps\common\The Blood of Dawnwalker';

function IsGame(Dir: String): Boolean;
begin
  Result := FileExists(AddBackslash(Dir) + 'Dawnwalker\Content\Paks\Dawnwalker-Windows.pak');
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
    MsgBox('У цій теці гри не знайдено (немає Dawnwalker\Content\Paks\Dawnwalker-Windows.pak). ' +
           'Оберіть теку The Blood of Dawnwalker.', mbError, MB_OK);
    Result := False;
  end;
end;

function Movies: String;
begin
  Result := ExpandConstant('{app}\Dawnwalker\Content\Movies\');
end;

{ Файл слота cs → *.orig (один раз, оригінал не видаляємо), на його місце — Src }
procedure Replace(Name, Src: String);
begin
  if not FileExists(Src) then Exit;
  if FileExists(Movies + Name) and not FileExists(Movies + Name + '.orig') then
    RenameFile(Movies + Name, Movies + Name + '.orig');
  CopyFile(Src, Movies + Name, False);
end;

procedure Restore(Name: String);
begin
  if FileExists(Movies + Name + '.orig') then
  begin
    DeleteFile(Movies + Name);
    RenameFile(Movies + Name + '.orig', Movies + Name);
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
  L.Caption := 'У налаштуваннях гри оберіть мову тексту «Українська» (замість «Čeština»).';
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
    { попередження про епілепсію/вміст у слоті cs — чеською → англійські ролики самої гри }
    Replace('epilepsy_cs.bk2', Movies + 'epilepsy_en.bk2');
    Replace('contentwarning_cs.bk2', Movies + 'contentwarning_en.bk2');
    Replace('intro_cgi_cs.srt', ExpandConstant('{tmp}\movies\intro_cgi_cs.srt'));
    Replace('PostCreditsCGITeaser_cs.srt', ExpandConstant('{tmp}\movies\PostCreditsCGITeaser_cs.srt'));
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    Restore('epilepsy_cs.bk2');
    Restore('contentwarning_cs.bk2');
    Restore('intro_cgi_cs.srt');
    Restore('PostCreditsCGITeaser_cs.srt');
  end;
end;
