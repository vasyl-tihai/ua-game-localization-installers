# Опція інсталятора «замість англійської»: пак озвучки зібрано в слот італійської (ExternalSourceStaging/it/<KEY>_it.wem);
# тут на ПК гравця його перепаковуємо в слот англійської. repak.exe (MIT/Apache) іде в інсталяторі поруч.
#   slot_en.ps1 <тека ~mods> <тимчасова тека>
param([string]$Mods, [string]$Tmp)
$ErrorActionPreference = 'Stop'
$repak = Join-Path $PSScriptRoot 'repak.exe'
$pak = Join-Path $Mods 'zz_UkrainianVO_P.pak'
$work = Join-Path $Tmp 'vo'
& $repak unpack -q -f -o $work $pak
if ($LASTEXITCODE) { exit 2 }
$stage = Join-Path $work 'Dawnwalker\Content\ExternalSourceStaging'
Rename-Item (Join-Path $stage 'it') 'en'
Get-ChildItem (Join-Path $stage 'en') -Recurse -Filter '*_it.wem' | ForEach-Object {
    Rename-Item $_.FullName ($_.Name.Substring(0, $_.Name.Length - 7) + '_en.wem') }
& $repak pack -q --version V11 $work "$pak.new"
if ($LASTEXITCODE) { exit 3 }
Move-Item "$pak.new" $pak -Force
Remove-Item $work -Recurse -Force
