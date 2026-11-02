# Українізатор GTA IV: The Complete Edition (IV + The Lost and Damned + The Ballad of Gay Tony) - встановлення без інсталятора.
# Файлів гри в архіві немає: для кожного змінюваного файлу є лише «дельта» (різниця між вашим оригіналом і українською версією).
# Скрипт зберігає ваш файл як *.orig, застосовує дельту і перевіряє SHA-1 результату. Жодних .exe/.dll в архіві немає.
# C#-код нижче компілюється на вашому ПК (Add-Type). Нічого не завантажує з інтернету й нікуди не надсилає.
# Офіційна сторінка: https://gamerent.com.ua/ukrainizatory/grand-theft-auto-iv
#
# Ukrainian localization for GTA IV: The Complete Edition (IV + TLAD + TBoGT) - script-based install (no .exe/.dll).
# The archive has no game files, only deltas (difference between YOUR original file and the Ukrainian version).
# The script keeps your file as *.orig, applies the delta and verifies the SHA-1 of the result.
param(
    [string]$GameDir = '',
    [int]$Mode = 0,          # 1 = text and voice-over, 2 = text only, 0 = ask
    [switch]$Elevated,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

# Застосовувач дельти формату UAD1 (опис формату - у tools\delta_make.py на GitHub).
# Заголовок 60 байт: "UAD1", u64 розмір оригіналу, u64 розмір результату, SHA-1 оригіналу (нулі = не перевіряти), SHA-1 результату;
# далі raw Deflate з операціями: 0 COPY(зсув, довжина) | 1 INSERT(довжина, дані) | 2 END; числа - LEB128.
# Сумісно з C# 5 (Windows PowerShell 5.1).
$CSharp = @'
using System;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;

public static class UaDelta
{
    static ulong ReadVarint(Stream s)
    {
        ulong v = 0; int shift = 0;
        while (true)
        {
            int b = s.ReadByte();
            if (b < 0) throw new InvalidDataException("Delta is truncated.");
            v |= (ulong)(b & 0x7F) << shift;
            if ((b & 0x80) == 0) return v;
            shift += 7;
            if (shift > 63) throw new InvalidDataException("Bad delta (varint).");
        }
    }

    static void ReadExact(Stream s, byte[] buf, int n)
    {
        int got = 0;
        while (got < n)
        {
            int k = s.Read(buf, got, n - got);
            if (k <= 0) throw new InvalidDataException("Delta is truncated.");
            got += k;
        }
    }

    static bool IsZero(byte[] b, int from, int n)
    {
        for (int i = 0; i < n; i++) if (b[from + i] != 0) return false;
        return true;
    }

    static bool Same(byte[] a, int ao, byte[] b, int bo, int n)
    {
        for (int i = 0; i < n; i++) if (a[ao + i] != b[bo + i]) return false;
        return true;
    }

    static string Hex(byte[] b)
    {
        var sb = new System.Text.StringBuilder();
        foreach (byte x in b) sb.Append(x.ToString("x2"));
        return sb.ToString();
    }

    // Будує outPath із origPath за дельтою. Кидає Exception, якщо оригінал не той або результат не збігається.
    public static void Apply(string origPath, string deltaPath, string outPath)
    {
        byte[] head = new byte[60];
        using (var df = new FileStream(deltaPath, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
        {
            ReadExact(df, head, 60);
            if (head[0] != 'U' || head[1] != 'A' || head[2] != 'D' || head[3] != '1') throw new InvalidDataException("Not a UAD1 delta: " + deltaPath);
            long origSize = BitConverter.ToInt64(head, 4);
            long newSize = BitConverter.ToInt64(head, 12);
            byte[] newSha = new byte[20];
            Array.Copy(head, 40, newSha, 0, 20);

            using (var orig = new FileStream(origPath, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
            {
                if (orig.Length != origSize)
                    throw new InvalidDataException("The original file has a different size (" + orig.Length + " instead of " + origSize + "). Verify the game files in Steam.");
                if (!IsZero(head, 20, 20))
                {
                    byte[] want = new byte[20];
                    Array.Copy(head, 20, want, 0, 20);
                    using (var sha0 = SHA1.Create())
                    {
                        byte[] got0 = sha0.ComputeHash(orig);
                        if (!Same(got0, 0, want, 0, 20))
                            throw new InvalidDataException("The original file differs from the expected one (SHA-1). Verify the game files in Steam.");
                    }
                    orig.Position = 0;
                }

                byte[] buf = new byte[1 << 20];
                long produced = 0;
                int lastPct = -1;
                using (var sha = SHA1.Create())
                using (var ds = new DeflateStream(df, CompressionMode.Decompress, true))
                using (var rd = new BufferedStream(ds, 1 << 20))
                using (var o = new FileStream(outPath, FileMode.Create, FileAccess.Write, FileShare.None, 1 << 20))
                {
                    bool done = false;
                    while (!done)
                    {
                        int op = rd.ReadByte();
                        if (op < 0) throw new InvalidDataException("Delta is truncated.");
                        if (op == 0)
                        {
                            ulong off = ReadVarint(rd);
                            ulong len = ReadVarint(rd);
                            if (off > (ulong)origSize || len > (ulong)origSize - off || len > (ulong)(newSize - produced))
                                throw new InvalidDataException("Bad delta (COPY range).");
                            orig.Position = (long)off;
                            long left = (long)len;
                            while (left > 0)
                            {
                                int n = (int)Math.Min((long)buf.Length, left);
                                ReadExact(orig, buf, n);
                                o.Write(buf, 0, n);
                                sha.TransformBlock(buf, 0, n, null, 0);
                                left -= n; produced += n;
                            }
                        }
                        else if (op == 1)
                        {
                            ulong len = ReadVarint(rd);
                            if (len > (ulong)(newSize - produced)) throw new InvalidDataException("Bad delta (INSERT length).");
                            long left = (long)len;
                            while (left > 0)
                            {
                                int n = (int)Math.Min((long)buf.Length, left);
                                ReadExact(rd, buf, n);
                                o.Write(buf, 0, n);
                                sha.TransformBlock(buf, 0, n, null, 0);
                                left -= n; produced += n;
                            }
                        }
                        else if (op == 2) done = true;
                        else throw new InvalidDataException("Bad delta (unknown op).");

                        if (newSize > 1048576)
                        {
                            int pct = (int)(produced * 100 / newSize);
                            if (pct != lastPct && (pct % 5 == 0))
                            {
                                lastPct = pct;
                                Console.Write("\r    " + pct + "%   ");
                            }
                        }
                    }
                    if (produced != newSize) throw new InvalidDataException("Result size mismatch.");
                    sha.TransformFinalBlock(buf, 0, 0);
                    o.Flush();
                    if (!Same(sha.Hash, 0, newSha, 0, 20))
                        throw new InvalidDataException("SHA-1 of the result does not match (expected " + Hex(newSha) + ", got " + Hex(sha.Hash) + ").");
                }
                if (newSize > 1048576) Console.Write("\r    100%   \r");
            }
        }
    }
}
'@

function Pause-IfElevated { if ($Elevated -and -not $NoPause) { Read-Host 'Натисніть Enter / Press Enter' | Out-Null } }

$code = 0
try {
    $deltaDir = Join-Path $PSScriptRoot 'delta'
    $manifest = Get-Manifest $deltaDir
    if ($manifest.Count -eq 0) { throw 'Порожній delta\manifest.txt. / Empty delta\manifest.txt.' }

    $game = Resolve-GameDir $GameDir $PSScriptRoot
    Write-Host ('Гра / Game: ' + $game)

    # Що ставимо: текст і озвучка / лише текст
    if ($Mode -ne 1 -and $Mode -ne 2) {
        Write-Host ''
        Write-Host 'Що встановити? / What to install?'
        Write-Host '  1 - Текст і озвучка (~4,5 ГБ вільного місця) / Text and voice-over (~4.5 GB free space)  [за замовчуванням / default]'
        Write-Host '  2 - Лише текст: інтерфейс, субтитри, шрифти / Text only: interface, subtitles, fonts'
        $ans = Read-Host 'Вибір / Choice (1/2)'
        if ($ans.Trim() -eq '2') { $Mode = 2 } else { $Mode = 1 }
    }
    $sel = @($manifest | Where-Object { $_.Comp -eq 'text' -or $Mode -eq 1 })
    Write-Host ('Режим / Mode: ' + $(if ($Mode -eq 1) { 'текст і озвучка / text and voice-over' } else { 'лише текст / text only' }) + (' ({0} files)' -f $sel.Count))

    # Права: якщо в теку гри писати не можна (Program Files) - перезапуск з підвищенням.
    if (-not (Test-CanWrite $game)) {
        if ($Elevated -or (Test-IsAdmin)) { throw 'Немає доступу на запис у теку гри. / No write access to the game folder.' }
        $code = Invoke-Elevated $PSCommandPath $game $Mode
        exit $code
    }
    if (Test-GameRunning) { throw 'Гра запущена. Закрийте GTA IV і запустіть скрипт ще раз. / The game is running - close it and run the script again.' }

    # Перевірка: оригінали на місці й тієї самої версії (розмір). Якщо гра вже українізована - беремо *.orig.
    $bad = @()
    foreach ($e in $sel) {
        $t = Join-Path $game $e.Rel
        $src = $(if (Test-Path -LiteralPath ($t + '.orig') -PathType Leaf) { $t + '.orig' } else { $t })
        $size = -1
        if (Test-Path -LiteralPath $src -PathType Leaf) { $size = (Get-Item -LiteralPath $src).Length }
        if ($size -ne $e.OrigSize) { $bad += ('  {0}  ({1} / {2})' -f $e.Rel, $size, $e.OrigSize) }
    }
    if ($bad.Count -gt 0) {
        Write-Host ($bad -join "`r`n")
        throw ("Ці файли гри відрізняються від версії, під яку зроблено українізатор (GTA IV: The Complete Edition у Steam, оновлена). " +
               "Перевірте цілісність файлів гри в Steam (Властивості - Встановлені файли - Перевірити) і запустіть скрипт ще раз. / " +
               "These game files differ from the version this localization was made for (Steam, Complete Edition, latest). " +
               "Verify the game files in Steam and run the script again.")
    }

    # Вільне місце: нові файли ≈ сума розмірів (оригінали лишаються поруч як *.orig)
    $need = [int64]300MB; $maxOld = [int64]0
    foreach ($e in $sel) {
        if (Test-Path -LiteralPath ((Join-Path $game $e.Rel) + '.orig') -PathType Leaf) { if ($e.NewSize -gt $maxOld) { $maxOld = $e.NewSize } }
        else { $need += $e.NewSize }
    }
    $need += $maxOld
    try {
        $root = [IO.Path]::GetPathRoot($game)
        if ($root -and $root.Length -ge 2 -and $root[1] -eq ':') {
            $free = (New-Object IO.DriveInfo($root.Substring(0, 1))).AvailableFreeSpace
            if ($free -lt $need) {
                throw ('Мало місця на диску {0}: потрібно ~{1:N1} ГБ, є {2:N1} ГБ. / Not enough free space on {0}: need ~{1:N1} GB, have {2:N1} GB.' -f $root, ($need / 1GB), ($free / 1GB))
            }
        }
    } catch [System.IO.IOException] { } catch [System.ArgumentException] { }

    try { Add-Type -TypeDefinition $CSharp -Language CSharp } catch {
        throw ('Не вдалося скомпілювати застосувач (антивірус або політика системи?): ' + $_.Exception.Message + ' / Could not compile the helper.')
    }

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $failed = @(); $done = 0; $i = 0
    foreach ($e in $sel) {
        $i++
        $t = Join-Path $game $e.Rel
        $o = $t + '.orig'
        $tmp = $t + '.ua_tmp'
        $made = $false
        Write-Host ('[{0}/{1}] {2}' -f $i, $sel.Count, $e.Rel)
        try {
            if (-not (Test-Path -LiteralPath $o)) {
                Move-Item -LiteralPath $t -Destination $o        # оригінал -> *.orig
                $made = $true
            }
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
            [UaDelta]::Apply($o, (Join-Path $deltaDir $e.Delta), $tmp)
            if ((Get-Item -LiteralPath $tmp).Length -ne $e.NewSize) { throw 'Result size mismatch.' }
            if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force }
            Move-Item -LiteralPath $tmp -Destination $t
            $done++
        } catch {
            $m = $_.Exception.Message
            if ($_.Exception.InnerException) { $m = $_.Exception.InnerException.Message }
            Write-Host ('    ПОМИЛКА / ERROR: ' + $m) -ForegroundColor Red
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
            if ($made -and (Test-Path -LiteralPath $o) -and -not (Test-Path -LiteralPath $t)) { Move-Item -LiteralPath $o -Destination $t }   # повертаємо оригінал на місце
            $failed += $e.Rel
        }
    }

    Write-Host ''
    if ($failed.Count -gt 0) {
        $code = 1
        Write-Host ('Не вдалося застосувати до файлів / Failed for: ' + ($failed -join ', ')) -ForegroundColor Red
        Write-Host 'Ці файли лишилися оригінальними. Перевірте цілісність файлів гри в Steam і місце на диску, потім запустіть скрипт ще раз.'
        Write-Host 'These files were left original. Verify the game files in Steam and the free disk space, then run the script again.'
    } else {
        Write-Host ('Готово: змінено файлів {0}, {1:N0} с. Оригінали збережено поруч як *.orig.' -f $done, $sw.Elapsed.TotalSeconds)
        Write-Host ('Done: {0} files, {1:N0} s. Your originals are kept next to them as *.orig.' -f $done, $sw.Elapsed.TotalSeconds)
        Write-Host 'Мову в Steam і в грі залиште англійською (переклад замінює англійську). / Keep the game language set to English (the translation replaces it).'
    }
    Write-Host ''
    Write-Host ('Офіційна сторінка й нові версії / Official page and new versions: ' + $script:SiteUrl)
} catch {
    $code = 1
    Write-Host ''
    Write-Host ('ПОМИЛКА / ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Офіційна сторінка / Official page: ' + $script:SiteUrl)
}
Pause-IfElevated
exit $code
