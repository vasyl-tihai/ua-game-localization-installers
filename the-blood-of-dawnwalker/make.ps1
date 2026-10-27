# Збирає інсталятор: свіжі паки → build\installer-payload → Inno Setup (ISCC) → build\Dawnwalker-Ukrainian-<версія>-setup.exe
# Перед цим: python build.py (текст, також build\movies\*.srt) і python tools\vo_pack.py (озвучка).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force (Join-Path $pay 'movies') | Out-Null
Copy-Item (Join-Path $root 'build\zz_Ukrainian_P.pak') $pay -Force
# 3.0 (25.10): озвучка v3 у слоті італійської — DW_OUT=D:\dwvo2 DW_SLOT=it DW_PAK=build\v3\zz_UkrainianVO_P.pak python tools\vo_pack.py
Copy-Item (Join-Path $root 'build\v3\zz_UkrainianVO_P.pak') $pay -Force
Copy-Item (Join-Path $root 'tools\repak.exe') $pay -Force   # для опції «замість англійської» (installer\slot_en.ps1)
Copy-Item (Join-Path $root 'build\movies\*.srt') (Join-Path $pay 'movies') -Force
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'dawnwalker-ua.iss')
