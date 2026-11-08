# Збирає інсталятор: свіжі файли з build\ → build\installer-payload → Inno Setup (ISCC) → build\PhantomBladeZero-Ukrainian-<версія>-setup.exe
# Перед цим: python tools\build_text.py (pak) і python tools\vo_build.py (utoc/ucas).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force $pay | Out-Null
foreach ($e in 'pak', 'utoc', 'ucas') { Copy-Item (Join-Path $root "build\zz_UkrainianText_P.$e") $pay -Force }
Copy-Item (Join-Path $root 'fonts-uk\OFL-AlegreyaSans.txt') $pay -Force
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'pbz-ua.iss')
