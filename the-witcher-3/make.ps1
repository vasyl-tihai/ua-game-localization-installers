# Збирає інсталятор: W3UaVo.exe (csc .NET 4) + build\installer-payload\ua_vo.bin → ISCC → build\Witcher3-Ukrainian-Voice-<версія>-setup.exe
# Перед цим: python -X utf8 tools\vo_reencode.py (wem Quality 48) і python -X utf8 tools\vo_payload.py (ua_vo.bin).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force $pay | Out-Null
if (-not (Test-Path (Join-Path $pay 'ua_vo.bin'))) { throw 'немає ua_vo.bin — спершу tools\vo_payload.py' }
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" -nologo -optimize "-out:$pay\W3UaVo.exe" (Join-Path $PSScriptRoot 'W3UaVo.cs')
if ($LASTEXITCODE) { throw 'csc' }
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'witcher3-ua-vo.iss')
