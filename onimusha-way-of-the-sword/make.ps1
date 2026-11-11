# Збирає інсталятор: build\re_chunk_000.pak.patch_002/003.pak + REFramework → build\installer-payload → ISCC
# → build\OnimushaWotS-Ukrainian-<версія>-setup.exe. Перед цим: msg_build.py (002) і ree-pak-cli pack (003).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force $pay | Out-Null
foreach ($n in '002', '003') { Copy-Item (Join-Path $root "build\re_chunk_000.pak.patch_$n.pak") $pay -Force }
Copy-Item 'C:\owvo\dl\refw\x\dinput8.dll' $pay -Force
Copy-Item (Join-Path $PSScriptRoot 'LICENSE-REFramework.txt') $pay -Force
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'oni-ua.iss')
