# Українська озвучка CONTROL Resonant: видалення (повертає оригінальні *.rmdtoc, прибирає наші -uNN.rmdblob).
param(
    [string]$GamePath,
    [switch]$Elevated
)
#COMMON#

Write-Host ''
Say 'Українська озвучка CONTROL Resonant: видалення' 'Ukrainian voice-over for CONTROL Resonant: uninstall'
Write-Host ''

$game = Resolve-Game $GamePath
if (-not $game) { Finish 1 }
Ensure-Admin $game
$pc = Join-Path $game 'data_pack2\pc'

if (Test-GameRunning $game) {
    Say 'Гра запущена. Закрийте CONTROL Resonant і запустіть uninstall.bat ще раз.' 'The game is running. Close CONTROL Resonant and run uninstall.bat again.'
    Finish 1
}

$found = $false
foreach ($t in @('base-it', 'stream0-it', 'base-generic', 'stream0-generic')) {
    if (Test-Path -LiteralPath (Join-Path $pc ($t + '.rmdtoc.uavo'))) { $found = $true }
}
if (-not $found) {
    Say 'Озвучку не встановлено (немає файлів стану *.rmdtoc.uavo), відновлювати нічого.' 'The voice-over is not installed (no *.rmdtoc.uavo state files), nothing to restore.'
    Finish 0
}

Load-Tool
$code = [CrUaVo]::Run([string[]]@('--restore', $pc))
Write-Host ''
if ($code -eq 0) {
    Say 'Готово. Оригінальні індекси повернено, італійська озвучка знову італійська.' 'Done. Original index files restored; the Italian voice-over is Italian again.'
    Finish 0
} else {
    Say ('Не вдалося видалити озвучку (код ' + $code + '). У Steam: Властивості гри -> Установлені файли -> Перевірити цілісність файлів.') ('Could not remove the voice-over (code ' + $code + '). In Steam: game Properties > Installed Files > Verify integrity of game files.')
    Finish 1
}
