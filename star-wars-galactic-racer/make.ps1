# Збирає інсталятор: свіжі паки → build\installer-payload → Inno Setup (ISCC) → build\SWGR-Ukrainian-<версія>-setup.exe
# Перед цим: python build.py (текст) і python vo_pack.py (озвучка).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force $pay | Out-Null
Copy-Item (Join-Path $root 'build\pakchunk99-Ukrainian_P.pak') $pay -Force
Copy-Item (Join-Path $root 'iostore-stub\stub.utoc') (Join-Path $pay 'pakchunk99-Ukrainian_P.utoc') -Force
Copy-Item (Join-Path $root 'iostore-stub\stub.ucas') (Join-Path $pay 'pakchunk99-Ukrainian_P.ucas') -Force
Get-ChildItem (Join-Path $root 'build\vo-pak\pakchunk98-UkrainianVO_P.*') | Copy-Item -Destination $pay -Force
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'swgr-ua.iss')
