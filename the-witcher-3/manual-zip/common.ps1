# Спільні функції install.ps1 / uninstall.ps1: пошук гри, налаштування мов (логіка інсталятора Inno Setup, переписана на PowerShell).
# Shared helpers for install.ps1 / uninstall.ps1: game lookup and language settings (same logic as the Inno Setup installer).
$script:SteamAppId = '292030'
$script:GameSub    = 'steamapps\common\The Witcher 3'
$script:SiteUrl    = 'https://gamerent.com.ua/ukrainizatory/the-witcher-3'
$script:AppVer     = '1.0'

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Test-IsGame([string]$Dir) {
    if ([string]::IsNullOrWhiteSpace($Dir)) { return $false }
    try { return (Test-Path -LiteralPath (Join-Path $Dir 'content\content0\enpc.w3speech') -PathType Leaf) } catch { return $false }
}

function Get-RegValue([string]$Hive, [string]$View, [string]$SubKey, [string]$Name) {
    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]$Hive, [Microsoft.Win32.RegistryView]$View)
        $k = $base.OpenSubKey($SubKey)
        if ($k -eq $null) { return $null }
        $v = $k.GetValue($Name)
        $k.Close()
        if ($v -eq $null) { return $null }
        return [string]$v
    } catch { return $null }
}

# Бібліотеки Steam: рядки  "path"  "D:\\SteamLibrary"  у libraryfolders.vdf
function Find-InLibraries([string]$Steam) {
    $vdf = Join-Path $Steam 'steamapps\libraryfolders.vdf'
    if (-not (Test-Path -LiteralPath $vdf -PathType Leaf)) { return $null }
    foreach ($line in (Get-Content -LiteralPath $vdf)) {
        if ($line -match '^\s*"path"\s+"(.*)"\s*$') {
            $lib = $Matches[1].Replace('\\', '\')
            $cand = Join-Path $lib $script:GameSub
            if (Test-IsGame $cand) { return $cand }
        }
    }
    return $null
}

function Find-GameDir([string]$ScriptDir) {
    # 0. скрипт лежить у теці гри (або поруч / вище) / the script sits inside the game folder
    $d = $ScriptDir
    for ($i = 0; $i -lt 4 -and $d; $i++) {
        if (Test-IsGame $d) { return $d }
        $d = Split-Path -Parent $d
    }
    if (Test-IsGame ((Get-Location).Path)) { return (Get-Location).Path }
    # 1. Steam (реєстр) / Steam uninstall entry
    foreach ($view in 'Registry64', 'Registry32') {
        $s = Get-RegValue 'LocalMachine' $view ('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ' + $script:SteamAppId) 'InstallLocation'
        if (Test-IsGame $s) { return $s }
    }
    # 2. GOG
    foreach ($id in '1495134320', '1207664663') {
        foreach ($view in 'Registry32', 'Registry64') {
            $s = Get-RegValue 'LocalMachine' $view ('SOFTWARE\GOG.com\Games\' + $id) 'path'
            if (Test-IsGame $s) { return $s }
        }
    }
    # 3. SteamPath + бібліотеки Steam / Steam path + library folders
    $steam = Get-RegValue 'CurrentUser' 'Default' 'Software\Valve\Steam' 'SteamPath'
    if ($steam) {
        $steam = $steam.Replace('/', '\')
        $cand = Join-Path $steam $script:GameSub
        if (Test-IsGame $cand) { return $cand }
        $cand = Find-InLibraries $steam
        if ($cand) { return $cand }
    }
    # 4. стандартне місце / default location
    $pf = ${env:ProgramFiles(x86)}
    if ($pf) {
        $cand = Join-Path $pf ('Steam\' + $script:GameSub)
        if (Test-IsGame $cand) { return $cand }
        $cand = Find-InLibraries (Join-Path $pf 'Steam')
        if ($cand) { return $cand }
    }
    return $null
}

# Гра: параметр -GameDir, автопошук або запит шляху.
function Resolve-GameDir([string]$GameDir, [string]$ScriptDir) {
    if ($GameDir) {
        $GameDir = $GameDir.Trim('"').TrimEnd('\')
        if (Test-IsGame $GameDir) { return $GameDir }
        throw ("У теці '{0}' гри не знайдено (немає content\content0\enpc.w3speech). / Game not found there." -f $GameDir)
    }
    $found = Find-GameDir $ScriptDir
    if ($found) { return $found.TrimEnd('\') }
    Write-Host 'Теку гри не знайдено автоматично. / The game folder was not found automatically.'
    Write-Host 'Вставте шлях до теки The Witcher 3 (у ній є content\content0). Порожній рядок - вихід.'
    Write-Host 'Paste the path to the The Witcher 3 folder (it contains content\content0). Empty line = quit.'
    for ($try = 0; $try -lt 5; $try++) {
        $p = Read-Host 'Шлях / Path'
        if ([string]::IsNullOrWhiteSpace($p)) { break }
        $p = $p.Trim().Trim('"').TrimEnd('\')
        if (Test-IsGame $p) { return $p }
        Write-Host 'Тут гри не знайдено (немає content\content0\enpc.w3speech). Потрібна англійська озвучка гри (вона є завжди).'
        Write-Host 'Game not found there (no content\content0\enpc.w3speech).'
    }
    throw 'Теку гри не вказано. / No game folder given.'
}

function Get-DocsDir([string]$DocsDir) {
    if ($DocsDir) { return $DocsDir.Trim('"').TrimEnd('\') }
    return (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'The Witcher 3')
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CanWrite([string]$Dir) {
    try {
        $f = Join-Path $Dir ('.w3ua-write-test-' + [Guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText($f, 'x')
        Remove-Item -LiteralPath $f -Force
        return $true
    } catch { return $false }
}

# Перезапуск із правами адміністратора (UAC), якщо в теку гри не можна писати.
function Invoke-Elevated([string]$ScriptPath, [string]$Game, [string]$Docs) {
    Write-Host 'Тека гри потребує прав адміністратора - зараз зʼявиться запит Windows (UAC), натисніть «Так».'
    Write-Host 'The game folder needs administrator rights - a Windows UAC prompt will appear, click Yes.'
    $ps = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath),
           '-GameDir', ('"{0}"' -f $Game), '-DocsDir', ('"{0}"' -f $Docs), '-Elevated')
    try {
        $p = Start-Process -FilePath $ps -ArgumentList $a -Verb RunAs -Wait -PassThru
        return $p.ExitCode
    } catch {
        Write-Host 'Запит прав скасовано або не вдався. / Elevation was cancelled or failed.'
        return 1
    }
}

function Test-GameRunning {
    return [bool](Get-Process -Name 'witcher3' -ErrorAction SilentlyContinue)
}

# ---------- Мінімальний редактор .ini (зберігає кодування й решту рядків файлу) ----------
function Get-IniFile([string]$Path) {
    $r = @{ Path = $Path; Lines = (New-Object 'System.Collections.Generic.List[string]'); Enc = [Text.Encoding]::GetEncoding(28591); Nl = "`r`n" }
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $b = [IO.File]::ReadAllBytes($Path)
        if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
            $r.Enc = New-Object Text.UTF8Encoding($true); $text = $r.Enc.GetString($b, 3, $b.Length - 3)
        } elseif ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) {
            $r.Enc = New-Object Text.UnicodeEncoding($false, $true); $text = $r.Enc.GetString($b, 2, $b.Length - 2)
        } else {
            $text = $r.Enc.GetString($b)   # Latin-1: байти без змін / byte-preserving
        }
        if ($text.IndexOf("`r`n") -lt 0 -and $text.IndexOf("`n") -ge 0) { $r.Nl = "`n" }
        if ($text.Length -gt 0) {
            $parts = $text -split "`r?`n"
            $n = $parts.Length
            if ($n -gt 0 -and $parts[$n - 1] -eq '') { $n-- }
            for ($i = 0; $i -lt $n; $i++) { $r.Lines.Add($parts[$i]) }
        }
    }
    return $r
}

function Find-IniSection($Ini, [string]$Section) {
    $start = -1
    for ($i = 0; $i -lt $Ini.Lines.Count; $i++) {
        if ($Ini.Lines[$i] -match '^\s*\[(.+?)\]\s*$') {
            if ($start -ge 0) { return @($start, $i) }
            if ($Matches[1].Trim() -ieq $Section) { $start = $i }
        }
    }
    if ($start -ge 0) { return @($start, $Ini.Lines.Count) }
    return $null
}

function Find-IniKey($Ini, [int]$From, [int]$To, [string]$Key) {
    for ($i = $From; $i -lt $To; $i++) {
        $l = $Ini.Lines[$i]
        $eq = $l.IndexOf('=')
        if ($eq -gt 0 -and $l.TrimStart()[0] -ne ';' -and $l.Substring(0, $eq).Trim() -ieq $Key) { return $i }
    }
    return -1
}

# $null - ключа немає; '' - ключ є, значення порожнє
function Get-IniValue($Ini, [string]$Section, [string]$Key) {
    $s = Find-IniSection $Ini $Section
    if (-not $s) { return $null }
    $i = Find-IniKey $Ini ($s[0] + 1) $s[1] $Key
    if ($i -lt 0) { return $null }
    $l = $Ini.Lines[$i]
    return $l.Substring($l.IndexOf('=') + 1).Trim()
}

function Set-IniValue($Ini, [string]$Section, [string]$Key, [string]$Value) {
    $line = $Key + '=' + $Value
    $s = Find-IniSection $Ini $Section
    if ($s) {
        $i = Find-IniKey $Ini ($s[0] + 1) $s[1] $Key
        if ($i -ge 0) { $Ini.Lines[$i] = $line; return }
        $at = $s[1]
        while ($at -gt ($s[0] + 1) -and $Ini.Lines[$at - 1].Trim() -eq '') { $at-- }
        $Ini.Lines.Insert($at, $line)
    } else {
        if ($Ini.Lines.Count -gt 0 -and $Ini.Lines[$Ini.Lines.Count - 1].Trim() -ne '') { $Ini.Lines.Add('') }
        $Ini.Lines.Add('[' + $Section + ']')
        $Ini.Lines.Add($line)
    }
}

function Save-IniFile($Ini) {
    $dir = Split-Path -Parent $Ini.Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $text = ''
    if ($Ini.Lines.Count -gt 0) { $text = ($Ini.Lines -join $Ini.Nl) + $Ini.Nl }
    $body = $Ini.Enc.GetBytes($text)
    $pre = $Ini.Enc.GetPreamble()
    $all = New-Object byte[] ($pre.Length + $body.Length)
    [Array]::Copy($pre, 0, $all, 0, $pre.Length)
    [Array]::Copy($body, 0, $all, $pre.Length, $body.Length)
    [IO.File]::WriteAllBytes($Ini.Path, $all)
}

$script:LangKeys = @('RequestedSpeechLanguage', 'SpeechLanguage', 'RequestedTextLanguage', 'TextLanguage')

# Озвучка BR (наш слот), текст UA; попередні значення - один раз у prev.ini (перевстановлення їх не затирає)
function Set-GameLanguages([string]$SettingsPath, [string]$PrevPath) {
    $want = @{ RequestedSpeechLanguage = 'BR'; SpeechLanguage = 'BR'; RequestedTextLanguage = 'UA'; TextLanguage = 'UA' }
    $set  = Get-IniFile $SettingsPath
    $prev = Get-IniFile $PrevPath
    $name = Split-Path -Leaf $SettingsPath
    foreach ($k in $script:LangKeys) {
        if ($null -eq (Get-IniValue $prev $name $k)) {
            $old = Get-IniValue $set 'Localization' $k
            if ($null -eq $old) { $old = '' }
            Set-IniValue $prev $name $k $old
        }
        Set-IniValue $set 'Localization' $k $want[$k]
    }
    Save-IniFile $prev
    Save-IniFile $set
}

function Restore-GameLanguages([string]$SettingsPath, [string]$PrevPath) {
    if (-not (Test-Path -LiteralPath $PrevPath -PathType Leaf)) { return }
    if (-not (Test-Path -LiteralPath $SettingsPath -PathType Leaf)) { return }
    $prev = Get-IniFile $PrevPath
    $set  = Get-IniFile $SettingsPath
    $name = Split-Path -Leaf $SettingsPath
    $changed = $false
    foreach ($k in $script:LangKeys) {
        $v = Get-IniValue $prev $name $k
        if ($null -eq $v) { continue }
        if ($v -eq '') { $v = 'EN' }
        Set-IniValue $set 'Localization' $k $v
        $changed = $true
    }
    if ($changed) { Save-IniFile $set }
}
