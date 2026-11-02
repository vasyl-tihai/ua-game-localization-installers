# Спільні функції install.ps1 / uninstall.ps1: пошук гри GTA IV, список файлів, права адміністратора.
# Shared helpers for install.ps1 / uninstall.ps1: GTA IV game lookup, file list, administrator rights.
$script:SteamAppId = '12210'
$script:GameSub    = 'steamapps\common\Grand Theft Auto IV\GTAIV'
$script:SiteUrl    = 'https://gamerent.com.ua/ukrainizatory/grand-theft-auto-iv'
$script:AppVer     = '1.0'

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# Тека гри = та, де лежать GTAIV.exe і common\text\american.gxt (Steam, Complete Edition).
function Test-IsGame([string]$Dir) {
    if ([string]::IsNullOrWhiteSpace($Dir)) { return $false }
    try {
        return ((Test-Path -LiteralPath (Join-Path $Dir 'GTAIV.exe') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $Dir 'common\text\american.gxt') -PathType Leaf))
    } catch { return $false }
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
        if ($s -and (Test-IsGame (Join-Path $s 'GTAIV'))) { return (Join-Path $s 'GTAIV') }
    }
    # 2. SteamPath + бібліотеки Steam / Steam path + library folders
    $steam = Get-RegValue 'CurrentUser' 'Default' 'Software\Valve\Steam' 'SteamPath'
    if ($steam) {
        $steam = $steam.Replace('/', '\')
        $cand = Join-Path $steam $script:GameSub
        if (Test-IsGame $cand) { return $cand }
        $cand = Find-InLibraries $steam
        if ($cand) { return $cand }
    }
    # 3. стандартне місце / default location
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
        throw ("У теці '{0}' гри не знайдено (немає GTAIV.exe). / Game not found there (no GTAIV.exe)." -f $GameDir)
    }
    $found = Find-GameDir $ScriptDir
    if ($found) { return $found.TrimEnd('\') }
    Write-Host 'Теку гри не знайдено автоматично. / The game folder was not found automatically.'
    Write-Host 'Вставте шлях до теки GTAIV (у ній є GTAIV.exe), наприклад ...\steamapps\common\Grand Theft Auto IV\GTAIV. Порожній рядок - вихід.'
    Write-Host 'Paste the path to the GTAIV folder (it contains GTAIV.exe), e.g. ...\steamapps\common\Grand Theft Auto IV\GTAIV. Empty line = quit.'
    for ($try = 0; $try -lt 5; $try++) {
        $p = Read-Host 'Шлях / Path'
        if ([string]::IsNullOrWhiteSpace($p)) { break }
        $p = $p.Trim().Trim('"').TrimEnd('\')
        if (Test-IsGame $p) { return $p }
        if (Test-IsGame (Join-Path $p 'GTAIV')) { return (Join-Path $p 'GTAIV') }
        Write-Host 'Тут гри не знайдено (немає GTAIV.exe та common\text\american.gxt). / Game not found there.'
    }
    throw 'Теку гри не вказано. / No game folder given.'
}

# Список файлів: delta\manifest.txt, рядки  компонент|шлях у теці GTAIV|файл дельти|розмір оригіналу|розмір результату|sha1 результату
function Get-Manifest([string]$DeltaDir) {
    $mf = Join-Path $DeltaDir 'manifest.txt'
    if (-not (Test-Path -LiteralPath $mf -PathType Leaf)) {
        throw 'Не знайдено delta\manifest.txt. Розпакуйте архів повністю. / delta\manifest.txt not found - extract the whole archive.'
    }
    $list = @()
    foreach ($l in (Get-Content -LiteralPath $mf -Encoding UTF8)) {
        if ($l -match '^\s*(;|$)') { continue }
        $p = $l.Trim().Split('|')
        if ($p.Length -ne 6) { continue }
        $list += New-Object PSObject -Property @{
            Comp = $p[0]; Rel = $p[1]; Delta = $p[2]
            OrigSize = [int64]$p[3]; NewSize = [int64]$p[4]; Sha = $p[5]
        }
    }
    return ,$list
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CanWrite([string]$Dir) {
    try {
        $f = Join-Path $Dir ('.gtaiv-ua-write-test-' + [Guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText($f, 'x')
        Remove-Item -LiteralPath $f -Force
        return $true
    } catch { return $false }
}

# Перезапуск із правами адміністратора (UAC), якщо в теку гри не можна писати.
function Invoke-Elevated([string]$ScriptPath, [string]$Game, [int]$Mode) {
    Write-Host 'Тека гри потребує прав адміністратора - зараз зʼявиться запит Windows (UAC), натисніть «Так».'
    Write-Host 'The game folder needs administrator rights - a Windows UAC prompt will appear, click Yes.'
    $ps = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath),
           '-GameDir', ('"{0}"' -f $Game), '-Mode', $Mode, '-Elevated')
    try {
        $p = Start-Process -FilePath $ps -ArgumentList $a -Verb RunAs -Wait -PassThru
        return $p.ExitCode
    } catch {
        Write-Host 'Запит прав скасовано або не вдався. / Elevation was cancelled or failed.'
        return 1
    }
}

function Test-GameRunning {
    return [bool](Get-Process -Name 'GTAIV', 'LaunchGTAIV', 'EFLC' -ErrorAction SilentlyContinue)
}
