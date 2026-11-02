# Українська озвучка CONTROL Resonant: встановлення без .exe (PowerShell).
# Збирає озвучку так само, як інсталятор: найменший архів гри копіюється під новою назвою (...-uNN.rmdblob),
# до нього дописується наш звук із ua_vo.bin, італійські індекси *.rmdtoc перебудовуються (оригінали -> *.rmdtoc.orig).
param(
    [string]$GamePath,
    [switch]$Elevated
)
#COMMON#

Write-Host ''
Say 'Українська озвучка CONTROL Resonant: встановлення' 'Ukrainian voice-over for CONTROL Resonant: install'
Write-Host ''

$bin = Join-Path $PSScriptRoot 'ua_vo.bin'
if (-not (Test-Path -LiteralPath $bin -PathType Leaf)) {
    Say 'Не знайдено ua_vo.bin поруч зі скриптом. Спершу розпакуйте весь архів у теку, потім запускайте install.bat.' 'ua_vo.bin is not next to the script. Extract the whole archive into a folder first, then run install.bat.'
    Finish 1
}

$game = Resolve-Game $GamePath
if (-not $game) { Finish 1 }
Ensure-Admin $game
$pc = Join-Path $game 'data_pack2\pc'

if (Test-GameRunning $game) {
    Say 'Гра запущена. Закрийте CONTROL Resonant і запустіть install.bat ще раз.' 'The game is running. Close CONTROL Resonant and run install.bat again.'
    Finish 1
}

# місце: ~1 ГБ копій архівів + наш звук (як ExtraDiskSpaceRequired в інсталяторі)
try {
    $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($game))
    if ($drive.AvailableFreeSpace -lt 1100000000) {
        Say ('Мало вільного місця на диску ' + $drive.Name + ' (потрібно ~1,1 ГБ, є ' + [math]::Round($drive.AvailableFreeSpace / 1MB) + ' МБ).') ('Low free space on ' + $drive.Name + ' (~1.1 GB needed, ' + [math]::Round($drive.AvailableFreeSpace / 1MB) + ' MB free).')
        $a = Read-Host 'Продовжити попри це? y/N / Continue anyway? y/N'
        if ($a -ne 'y' -and $a -ne 'Y') { Finish 1 }
    }
} catch { }

Say 'Готую збирач...' 'Preparing the builder...'
Load-Tool
Say 'Збираю озвучку (кілька хвилин, не закривайте вікно)...' 'Building the voice-over (a few minutes, do not close the window)...'
$code = [CrUaVo]::Run([string[]]@($pc, $bin))
Write-Host ''
if ($code -eq 0) {
    Say 'Готово. Озвучку встановлено.' 'Done. The voice-over is installed.'
    Say 'У грі: Налаштування -> Мова: озвучка «Italiano» (це наша українська), субтитри «Українська».' 'In game: Settings > Language: voice-over "Italiano" (this is our Ukrainian), subtitles "Ukrainian".'
    Finish 0
} else {
    Say ('Не вдалося зібрати озвучку (код ' + $code + '). Закрийте гру, перевірте вільне місце (потрібно ~2 ГБ на диску з грою) і запустіть ще раз. Якщо гру щойно оновлено, можливо, потрібна нова версія озвучки.') ('Could not build the voice-over (code ' + $code + '). Close the game, check free disk space (~2 GB on the game drive) and run again. If the game was just updated, a new version of the voice-over may be needed.')
    Finish 1
}
