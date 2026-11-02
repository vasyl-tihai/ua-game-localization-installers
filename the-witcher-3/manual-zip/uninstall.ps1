# Видалення української озвучки «Відьмак 3»: повертає мову озвучки/тексту в налаштуваннях (з UkrainianVO\prev.ini),
# видаляє зібраний brpc.w3speech і повертає ваш попередній (brpc.w3speech.orig), якщо він був.
# Офіційна сторінка: https://gamerent.com.ua/ukrainizatory/the-witcher-3
#
# Uninstall of the Ukrainian voice-over for The Witcher 3: restores the language settings (from UkrainianVO\prev.ini),
# deletes the built brpc.w3speech and restores your previous one (brpc.w3speech.orig) if there was one.
param(
    [string]$GameDir = '',
    [string]$DocsDir = '',
    [switch]$Elevated,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$code = 0
try {
    $game = Resolve-GameDir $GameDir $PSScriptRoot
    $docs = Get-DocsDir $DocsDir
    $c0   = Join-Path $game 'content\content0'
    $brpc = Join-Path $c0 'brpc.w3speech'
    $orig = $brpc + '.orig'
    $ukDir = Join-Path $game 'UkrainianVO'
    $prevIni = Join-Path $ukDir 'prev.ini'

    Write-Host ('Гра / Game: ' + $game)
    Write-Host ('Налаштування / Settings: ' + $docs)

    if (-not (Test-CanWrite $c0)) {
        if ($Elevated -or (Test-IsAdmin)) { throw 'Немає доступу на запис у теку гри. / No write access to the game folder.' }
        $code = Invoke-Elevated $PSCommandPath $game $docs
        exit $code
    }
    if (Test-GameRunning) { throw 'Гра запущена. Закрийте The Witcher 3 і запустіть скрипт ще раз. / The game is running - close it and run the script again.' }

    Restore-GameLanguages (Join-Path $docs 'dx12user.settings') $prevIni
    Restore-GameLanguages (Join-Path $docs 'user.settings') $prevIni

    foreach ($f in @($brpc, ($brpc + '.tmp'), (Join-Path $c0 'ua_vo.bin'))) {
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }
    }
    if (Test-Path -LiteralPath $orig) { Move-Item -LiteralPath $orig -Destination $brpc }
    foreach ($f in @($prevIni, (Join-Path $ukDir 'built.txt'))) {
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }
    }
    if ((Test-Path -LiteralPath $ukDir) -and -not (Get-ChildItem -LiteralPath $ukDir -Force)) {
        Remove-Item -LiteralPath $ukDir -Force
    }

    Write-Host ''
    Write-Host 'Готово: мову озвучки й тексту повернуто, українську озвучку видалено.'
    Write-Host 'Done: the language settings are restored and the Ukrainian voice-over is removed.'
    Write-Host ''
    Write-Host ('Офіційна сторінка / Official page: ' + $script:SiteUrl)
} catch {
    $code = 1
    Write-Host ''
    Write-Host ('ПОМИЛКА / ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Офіційна сторінка / Official page: ' + $script:SiteUrl)
}
if ($Elevated -and -not $NoPause) { Read-Host 'Натисніть Enter / Press Enter' | Out-Null }
exit $code
