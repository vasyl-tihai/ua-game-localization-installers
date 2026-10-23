# Збирає інсталятор: свіжі паки → build\installer-payload → Inno Setup (ISCC) → build\Dawnwalker-Ukrainian-<версія>-setup.exe
# Перед цим: python build.py (текст, також build\movies\*.srt) і python tools\vo_pack.py (озвучка).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force (Join-Path $pay 'movies') | Out-Null
Copy-Item (Join-Path $root 'build\zz_Ukrainian_P.pak') $pay -Force
# 2.0 (21.10): озвучка v2 (Higgs, з емоціями) — build\v2; пак 1.0 лишається в build\
Copy-Item (Join-Path $root 'build\v2\zz_UkrainianVO_P.pak') $pay -Force
Copy-Item (Join-Path $root 'build\movies\*.srt') (Join-Path $pay 'movies') -Force
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'dawnwalker-ua.iss')
