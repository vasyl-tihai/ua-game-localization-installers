# Збирає інсталятор: build\pak\pakchunk99-Windows_P.* → build\installer-payload → Inno Setup (ISCC) → build\ZeroCompany-Ukrainian-<версія>-setup.exe
# Перед цим: python tools\build_text.py --vo work\vo\final (текст + озвучка в одному паку).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force $pay | Out-Null
foreach ($e in 'pak', 'utoc', 'ucas') { Copy-Item (Join-Path $root "build\pak\pakchunk99-Windows_P.$e") $pay -Force }
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'zc-ua.iss')
if ($LASTEXITCODE) { throw "ISCC $LASTEXITCODE" }
