# Збирає інсталятор GTA IV: патчі HDiffPatch (оригінал гри *.orig → наша збірка) → build\installer-payload → ISCC
# → build\GTAIV-Ukrainian-<версія>-setup.exe. Файли гри в інсталятор не потрапляють — лише різниця (патчі).
# Перед цим: tools\tr.py build build\font (текст+шрифти), vo_build (build\audio_v3 місії, build\audio_v4 ролики).
# Список файлів і джерел — installer\files.txt. Оригінали беремо з <гра>\…\*.orig (якщо нема — сам файл, він ще оригінальний).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = 'C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto IV\GTAIV'
$hd = Join-Path $root '..\_спільне\hdiffpatch\bin\windows64'
$pay = Join-Path $root 'build\installer-payload'
New-Item -ItemType Directory -Force (Join-Path $pay 'patches') | Out-Null
Copy-Item (Join-Path $hd 'hpatchz.exe') $pay -Force
$files = @(); $code = @(); $i = 0
foreach ($l in Get-Content (Join-Path $PSScriptRoot 'files.txt') -Encoding UTF8) {
    if ($l -match '^\s*(;|$)') { continue }
    $comp, $rel, $src = $l.Split('|')
    $old = Join-Path $game ($rel + '.orig'); if (-not (Test-Path $old)) { $old = Join-Path $game $rel }
    $new = Join-Path (Join-Path $root $src) $rel
    $p = 'p{0:D2}.hdiff' -f $i
    $out = Join-Path $pay "patches\$p"
    if (-not (Test-Path $out) -or (Get-Item $out).LastWriteTime -lt (Get-Item $new).LastWriteTime) {
        & (Join-Path $hd 'hdiffz.exe') -f -s-64 -c-zstd-19 -p-4 $old $new $out
        if ($LASTEXITCODE) { throw "hdiffz: $rel" }
    }
    $os = (Get-Item $old).Length; $ns = (Get-Item $new).Length; $sha = (Get-FileHash $new -Algorithm SHA1).Hash.ToLower()
    "{0,-6} {1,-48} {2,12:N0} → {3,12:N0}  патч {4,12:N0}" -f $comp, $rel, $os, $ns, (Get-Item $out).Length
    $files += "Source: ""{#Payload}\patches\$p""; DestDir: ""{tmp}\ua""; Components: $comp; Flags: ignoreversion nocompression deleteafterinstall"
    $code += "  Add('$comp', '$rel', '$p', $os, $ns, '$sha');"
    $i++
}
# згенерований include: [Files] з патчами + список для [Code]
$gen = @('[Files]') + $files + @('', '[Code]', 'procedure InitList;', 'begin') + $code + @('end;')
Set-Content (Join-Path $PSScriptRoot 'gen.iss') $gen -Encoding UTF8
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
          "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 не встановлено' }
& $iscc (Join-Path $PSScriptRoot 'gtaiv-ua.iss')
