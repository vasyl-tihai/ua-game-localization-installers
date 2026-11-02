$ErrorActionPreference = 'Stop'
$SiteUrl = 'https://gamerent.com.ua/ukrainizatory/control-resonant'
$SteamAppId = '3669870'
$GameSub = 'steamapps\common\CONTROL Resonant'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Say([string]$uk, [string]$en) {
    Write-Host $uk
    if ($en) { Write-Host $en -ForegroundColor DarkGray }
}

function Finish([int]$code) {
    Write-Host ''
    Write-Host ('Офіційна сторінка / Official page: ' + $SiteUrl)
    if ($Elevated) { Read-Host 'Натисніть Enter, щоб закрити це вікно / Press Enter to close' | Out-Null }
    exit $code
}

# Гра: є data_pack2\pc\base-it.rmdtoc (так само перевіряє інсталятор)
function Test-Game([string]$dir) {
    if (-not $dir) { return $false }
    try { return (Test-Path -LiteralPath (Join-Path $dir 'data_pack2\pc\base-it.rmdtoc') -PathType Leaf) } catch { return $false }
}

# Бібліотеки Steam: рядки  "path"  "D:\\SteamLibrary"  у libraryfolders.vdf
function Find-InLibraries([string]$steam) {
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (-not (Test-Path -LiteralPath $vdf)) { return $null }
    foreach ($line in (Get-Content -LiteralPath $vdf -Encoding UTF8)) {
        $s = $line.Trim()
        if ($s.StartsWith('"path"')) {
            $s = $s.Substring(6).Trim()
            if ($s.Length -gt 2) {
                $s = $s.Substring(1, $s.Length - 2).Replace('\\', '\')
                $cand = Join-Path $s $GameSub
                if (Test-Game $cand) { return $cand }
            }
        }
    }
    return $null
}

function Find-Game {
    foreach ($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
        try {
            $p = (Get-ItemProperty -LiteralPath ($root + '\Steam App ' + $SteamAppId) -ErrorAction Stop).InstallLocation
            if (Test-Game $p) { return $p }
        } catch { }
    }
    $steams = @()
    try {
        $sp = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($sp) { $steams += $sp.Replace('/', '\') }
    } catch { }
    $pf = ${env:ProgramFiles(x86)}
    if ($pf) { $steams += (Join-Path $pf 'Steam') }
    foreach ($st in $steams) {
        $c = Join-Path $st $GameSub
        if (Test-Game $c) { return $c }
        $c = Find-InLibraries $st
        if ($c) { return $c }
    }
    return $null
}

function Resolve-Game([string]$given) {
    if ($given) {
        $g = $given.Trim().Trim('"').TrimEnd('\')
        if (Test-Game $g) { return $g }
        Say ('У теці "' + $g + '" гри не знайдено, шукаю автоматично.') ('Game not found in "' + $g + '", searching automatically.')
    }
    $g = Find-Game
    if ($g) {
        $g = $g.TrimEnd('\')
        Say ('Знайдено гру: ' + $g) ('Game found: ' + $g)
        return $g
    }
    Say 'Гру CONTROL Resonant у Steam не знайдено автоматично.' 'CONTROL Resonant was not found in Steam automatically.'
    while ($true) {
        $in = Read-Host 'Шлях до теки гри (Enter - вийти) / Game folder path (Enter to quit)'
        if (-not $in) { return $null }
        $in = $in.Trim().Trim('"').TrimEnd('\')
        if (Test-Game $in) { return $in }
        Say 'У цій теці гри не знайдено (немає data_pack2\pc\base-it.rmdtoc). Потрібна італійська озвучка гри (у Steam вона встановлюється разом із грою).' 'Game not found there (data_pack2\pc\base-it.rmdtoc is missing). The Italian voice pack of the game is required (Steam installs it with the game).'
    }
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Writable([string]$dir) {
    $f = Join-Path $dir ('.uavo-write-test-' + [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($f, 'x')
        Remove-Item -LiteralPath $f -Force
        return $true
    } catch { return $false }
}

# Гра в Program Files або тека недоступна для запису: перезапуск від адміністратора
function Ensure-Admin([string]$game) {
    if ($Elevated -or (Test-Admin)) { return }
    $pf1 = $env:ProgramFiles
    $pf2 = ${env:ProgramFiles(x86)}
    $inPf = ($pf1 -and $game.StartsWith($pf1, [StringComparison]::OrdinalIgnoreCase)) -or ($pf2 -and $game.StartsWith($pf2, [StringComparison]::OrdinalIgnoreCase))
    if (-not $inPf -and (Test-Writable (Join-Path $game 'data_pack2\pc'))) { return }
    Say 'Потрібні права адміністратора (гра в захищеній теці). Підтвердіть запит Windows.' 'Administrator rights are needed (the game is in a protected folder). Please confirm the Windows prompt.'
    $argl = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -GamePath "{1}" -Elevated' -f $PSCommandPath, $game
    try {
        $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $argl -Verb RunAs -Wait -PassThru
        exit $p.ExitCode
    } catch {
        Say 'Не вдалося отримати права адміністратора. Запустіть файл від імені адміністратора (ПКМ → Запуск від імені адміністратора).' 'Could not get administrator rights. Run the .bat as administrator (right click > Run as administrator).'
        exit 1
    }
}

# Гра має бути закрита
function Test-GameRunning([string]$game) {
    $prefix = $game.TrimEnd('\') + '\'
    foreach ($proc in (Get-Process -ErrorAction SilentlyContinue)) {
        $path = $null
        try { $path = $proc.Path } catch { }
        if ($path -and $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Load-Tool {
    if (-not ('CrUaVo' -as [type])) { Add-Type -TypeDefinition $script:CSharp -Language CSharp }
}

$CSharp = @'
#CSHARP#
'@
