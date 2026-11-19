# Збирає інсталятор 007 First Light: патчі HDiffPatch для службових файлів (оригінал з work\ → наша збірка C:\flvo\build\mod)
# + наші chunk0patch1/chunk1patch1.rpkg → build\installer-payload → ISCC → build\007FirstLight-Ukrainian-<версія>-setup.exe.
# Перед цим: python tools\vo_build.py <фінали> --out C:\flvo\build\mod. Список файлів — installer\files.txt.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mod = 'C:\flvo\build\mod'
$hd = Join-Path $root '..\_спільне\hdiffpatch\bin\windows64'
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force (Join-Path $pay 'patches') | Out-Null
Copy-Item (Join-Path $hd 'hpatchz.exe') $pay -Force
foreach ($c in 0, 1) { Copy-Item (Join-Path $mod "Runtime\chunk${c}patch1.rpkg") $pay -Force }
$files = @(); $code = @(); $i = 0
foreach ($l in Get-Content (Join-Path $PSScriptRoot 'files.txt') -Encoding UTF8) {
    if ($l -match '^\s*(;|$)') { continue }
    $comp, $rel, $old, $new = $l.Split('|')
    $old = Join-Path $root $old
    $p = 'p{0:D2}.hdiff' -f $i
    $out = Join-Path $pay "patches\$p"
    & (Join-Path $hd 'hdiffz.exe') -f -c-zstd-19 $old $new $out | Out-Null
    if ($LASTEXITCODE) { throw "hdiffz: $rel" }
    $os = (Get-Item $old).Length; $ns = (Get-Item $new).Length; $sha = (Get-FileHash $new -Algorithm SHA1).Hash.ToLower()
    $osha = (Get-FileHash $old -Algorithm SHA1).Hash.ToLower()
    "{0,-6} {1,-34} {2,8:N0} → {3,8:N0}  патч {4,6:N0}" -f $comp, $rel, $os, $ns, (Get-Item $out).Length
    $files += "Source: ""{#Payload}\patches\$p""; DestDir: ""{tmp}\ua""; Components: $comp; Flags: ignoreversion nocompression deleteafterinstall"
    $code += "  Add('$comp', '$rel', '$p', $os, $ns, '$sha', '$osha');"
    $i++
}
$gen = @('[Files]') + $files + @('', '[Code]', 'procedure InitList;', 'begin') + $code + @('end;')
Set-Content (Join-Path $PSScriptRoot 'gen.iss') $gen -Encoding UTF8
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot '007fl-ua.iss')
if ($LASTEXITCODE) { throw "ISCC $LASTEXITCODE" }
