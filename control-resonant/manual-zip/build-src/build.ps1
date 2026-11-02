# Збирає install.ps1 / uninstall.ps1 (вбудовує C# з CrUaVo.cs) у теку OutDir.
param(
    [string]$Cs = 'D:\Cloud Terminal\Українізатори\control-resonant\installer\CrUaVo.cs',
    [string]$OutDir = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($true)
function ReadU([string]$p) { [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }

$code = (ReadU $Cs).TrimStart([char]0xFEFF)
# єдині зміни в C#: клас і точка входу публічні, щоб викликати з PowerShell
$a = 'class CrUaVo' ; $a2 = 'public class CrUaVo'
$b = 'static int Main(string[] a)' ; $b2 = 'public static int Run(string[] a)'
if (-not $code.Contains("`n$a`n") -and -not $code.Contains("`r`n$a`r`n")) { throw 'class marker' }
if (-not $code.Contains($b)) { throw 'Main marker' }
$code = $code.Replace("$a`r`n", "$a2`r`n").Replace("$a`n", "$a2`n").Replace($b, $b2)
if ($code.Contains("`n'@") -or $code.Contains("`r'@")) { throw "here-string terminator in C#" }
$code = $code.TrimEnd()

$common = (ReadU (Join-Path $PSScriptRoot 'common.ps1')).Replace('#CSHARP#', $code)
foreach ($n in 'install', 'uninstall') {
    $main = ReadU (Join-Path $PSScriptRoot "$n-main.ps1")
    $text = $main.Replace('#COMMON#', $common)
    $text = ($text -replace "`r`n", "`n") -replace "`n", "`r`n"
    [IO.File]::WriteAllText((Join-Path $OutDir "$n.ps1"), $text, $enc)
}
"built into $OutDir"
