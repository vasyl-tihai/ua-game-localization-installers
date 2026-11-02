# Видалення українізатора GTA IV: The Complete Edition - повертає ваші оригінальні файли з *.orig (і після «лише текст», і після повної установки).
# Офіційна сторінка: https://gamerent.com.ua/ukrainizatory/grand-theft-auto-iv
#
# Uninstall of the GTA IV: The Complete Edition Ukrainian localization: puts your original files back from *.orig
# (after both "text only" and the full install).
param(
    [string]$GameDir = '',
    [int]$Mode = 0,          # not used; kept so the elevated relaunch can pass the same arguments
    [switch]$Elevated,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$code = 0
try {
    $manifest = Get-Manifest (Join-Path $PSScriptRoot 'delta')
    $game = Resolve-GameDir $GameDir $PSScriptRoot
    Write-Host ('Гра / Game: ' + $game)

    if (-not (Test-CanWrite $game)) {
        if ($Elevated -or (Test-IsAdmin)) { throw 'Немає доступу на запис у теку гри. / No write access to the game folder.' }
        $code = Invoke-Elevated $PSCommandPath $game 0
        exit $code
    }
    if (Test-GameRunning) { throw 'Гра запущена. Закрийте GTA IV і запустіть скрипт ще раз. / The game is running - close it and run the script again.' }

    $restored = 0; $failed = @()
    foreach ($e in $manifest) {
        $t = Join-Path $game $e.Rel
        $o = $t + '.orig'
        if (Test-Path -LiteralPath ($t + '.ua_tmp')) { Remove-Item -LiteralPath ($t + '.ua_tmp') -Force -ErrorAction SilentlyContinue }
        if (-not (Test-Path -LiteralPath $o -PathType Leaf)) { continue }
        try {
            if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force }
            Move-Item -LiteralPath $o -Destination $t
            $restored++
            Write-Host ('  ' + $e.Rel)
        } catch {
            $failed += $e.Rel
            Write-Host ('  ПОМИЛКА / ERROR: ' + $e.Rel + ' - ' + $_.Exception.Message) -ForegroundColor Red
        }
    }

    Write-Host ''
    if ($failed.Count -gt 0) {
        $code = 1
        Write-Host ('Не вдалося повернути / Could not restore: ' + ($failed -join ', ')) -ForegroundColor Red
    } else {
        Write-Host ('Готово: повернуто оригінальних файлів: {0}.' -f $restored)
        Write-Host ('Done: {0} original files restored.' -f $restored)
    }
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
