# Українська озвучка «Відьмак 3: Дике полювання» (Remastered) - встановлення без інсталятора.
# Скрипт збирає content\content0\brpc.w3speech (слот бразильської португальської) з вашого англійського
# enpc.w3speech і нашого звуку ua_vo.bin, а в Documents\The Witcher 3\*.settings вмикає озвучку BR і текст UA.
# Файлів гри ми не поширюємо; жодних .exe/.dll в архіві немає. C#-код нижче компілюється на вашому ПК (Add-Type).
# Офіційна сторінка: https://gamerent.com.ua/ukrainizatory/the-witcher-3
#
# Ukrainian voice-over for The Witcher 3: Wild Hunt (Remastered) - script-based install (no .exe/.dll).
# Builds content\content0\brpc.w3speech (Brazilian-Portuguese speech slot) from YOUR English enpc.w3speech and our
# audio ua_vo.bin, then sets speech BR + text UA in Documents\The Witcher 3\*.settings.
param(
    [string]$GameDir = '',
    [string]$DocsDir = '',
    [switch]$Elevated,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

# Збирач із W3UaVo.cs: enpc.w3speech гри + ua_vo.bin -> brpc.w3speech.
# Формат w3speech: "CPSW"; ua_vo.bin: "UAVO", u32 версія 1, u32 n, далі n x (u32 id, f32 тривалість, u32 len, wem).
# Сумісно з C# 5 (Windows PowerShell 5.1).
$CSharp = @'
using System;
using System.Collections.Generic;
using System.IO;

public static class W3UaVo
{
    static long Vlq(BinaryReader r)
    {
        int c = r.ReadByte(); long v = c & 0x3f; int sh = 6;
        if ((c & 0x40) != 0)
            while (true) { c = r.ReadByte(); v |= (long)(c & 0x7f) << sh; sh += 7; if ((c & 0x80) == 0) break; }
        return v;
    }

    static void Copy(Stream src, long off, long len, Stream dst, byte[] buf)
    {
        src.Position = off;
        while (len > 0)
        {
            int k = src.Read(buf, 0, (int)Math.Min(buf.Length, len));
            if (k <= 0) throw new EndOfStreamException();
            dst.Write(buf, 0, k); len -= k;
        }
    }

    // Повертає кількість замінених реплік; при помилці кидає Exception.
    // Буфер потоків читання 4 КБ (а не 1 МБ): Copy() читає короткі шматки з довільних місць, великий буфер уповільнював збірку в рази.
    public static int Build(string srcPath, string uaPath, string dstPath)
    {
        using (var src = new FileStream(srcPath, FileMode.Open, FileAccess.Read, FileShare.Read, 4096))
        using (var ua = new FileStream(uaPath, FileMode.Open, FileAccess.Read, FileShare.Read, 4096))
        {
            var r = new BinaryReader(src);
            if (new string(r.ReadChars(4)) != "CPSW") throw new Exception("enpc.w3speech: не CPSW");
            src.Position = 10;
            long n = Vlq(r);
            long tableStart = src.Position, tableEnd = tableStart + n * 40;
            var id = new uint[n]; var pad = new uint[n]; var wo = new long[n]; var ws = new long[n]; var lo = new long[n]; var ls = new long[n];
            for (long i = 0; i < n; i++)
            {
                id[i] = r.ReadUInt32(); pad[i] = r.ReadUInt32();
                wo[i] = r.ReadInt64(); ws[i] = r.ReadInt64(); lo[i] = r.ReadInt64(); ls[i] = r.ReadInt64();
            }

            var ur = new BinaryReader(ua);
            if (new string(ur.ReadChars(4)) != "UAVO" || ur.ReadUInt32() != 1) throw new Exception("ua_vo.bin: невідомий формат");
            uint un = ur.ReadUInt32();
            var map = new Dictionary<uint, long[]>();      // id -> {зсув wem, довжина, біти f32 тривалості}
            for (uint k = 0; k < un; k++)
            {
                uint uid = ur.ReadUInt32(); uint dur = ur.ReadUInt32(); uint len = ur.ReadUInt32();
                map[uid] = new long[] { ua.Position, len, dur };
                ua.Position += len;
            }

            string tmp = dstPath + ".tmp";
            int hit = 0;
            var buf = new byte[1 << 20];
            using (var o = new FileStream(tmp, FileMode.Create, FileAccess.Write, FileShare.None, 1 << 20))
            {
                var w = new BinaryWriter(o);
                Copy(src, 0, tableEnd + 2, o, buf);          // заголовок + таблиця (перепишемо) + 2 байти
                var row = new long[n * 3];
                long p = tableEnd + 2;
                for (long i = 0; i < n; i++)
                {
                    long wlen;
                    long[] e;
                    if (map.TryGetValue(id[i], out e))
                    {
                        w.Write((uint)e[1]); w.Flush();
                        Copy(ua, e[0], e[1], o, buf);
                        w.Write((uint)e[2]); w.Write((uint)1); w.Flush();
                        wlen = 4 + e[1] + 8; hit++;
                    }
                    else { Copy(src, wo[i], ws[i], o, buf); wlen = ws[i]; }
                    if (ls[i] > 0) Copy(src, lo[i], ls[i], o, buf);
                    row[i * 3] = p; row[i * 3 + 1] = wlen; row[i * 3 + 2] = ls[i] > 0 ? p + wlen : 0;
                    p += wlen + ls[i];
                    if (i % 5000 == 0) Console.WriteLine("{0}/{1}", i, n);
                }
                o.Position = tableStart;
                for (long i = 0; i < n; i++)
                {
                    w.Write(id[i]); w.Write(pad[i]); w.Write(row[i * 3]); w.Write(row[i * 3 + 1]); w.Write(row[i * 3 + 2]); w.Write(ls[i]);
                }
                w.Flush();
            }
            if (hit < un * 9 / 10) { File.Delete(tmp); throw new Exception(string.Format("збіглося лише {0} з {1} реплік — інша версія гри?", hit, un)); }
            if (File.Exists(dstPath)) File.Delete(dstPath);
            File.Move(tmp, dstPath);
            return hit;
        }
    }
}
'@

$code = 0
try {
    $ua = Join-Path $PSScriptRoot 'ua_vo.bin'
    if (-not (Test-Path -LiteralPath $ua -PathType Leaf)) {
        throw 'Не знайдено ua_vo.bin поруч зі скриптом. Спершу розпакуйте архів повністю (не запускайте з вікна архіву). / ua_vo.bin not found next to the script - extract the whole archive first.'
    }

    $game = Resolve-GameDir $GameDir $PSScriptRoot
    $docs = Get-DocsDir $DocsDir
    $c0   = Join-Path $game 'content\content0'
    $enpc = Join-Path $c0 'enpc.w3speech'
    $brpc = Join-Path $c0 'brpc.w3speech'
    $orig = $brpc + '.orig'
    $ukDir = Join-Path $game 'UkrainianVO'
    $built = Join-Path $ukDir 'built.txt'
    $prevIni = Join-Path $ukDir 'prev.ini'

    Write-Host ('Гра / Game: ' + $game)
    Write-Host ('Налаштування / Settings: ' + $docs)

    # Права: якщо в теку гри писати не можна (Program Files) - перезапуск з підвищенням.
    if (-not (Test-CanWrite $c0)) {
        if ($Elevated -or (Test-IsAdmin)) { throw 'Немає доступу на запис у теку гри. / No write access to the game folder.' }
        $code = Invoke-Elevated $PSCommandPath $game $docs
        exit $code
    }

    if (Test-GameRunning) { throw 'Гра запущена. Закрийте The Witcher 3 і запустіть скрипт ще раз. / The game is running - close it and run the script again.' }

    # Вільне місце: нова збірка ≈ розміру enpc.w3speech (старий brpc.w3speech замінюється після збірки)
    $need = (Get-Item -LiteralPath $enpc).Length + 300MB
    try {
        $root = [IO.Path]::GetPathRoot($game)
        if ($root -and $root.Length -ge 2 -and $root[1] -eq ':') {
            $free = (New-Object IO.DriveInfo($root.Substring(0, 1))).AvailableFreeSpace
            if ($free -lt $need) {
                throw ('Мало місця на диску {0}: потрібно ~{1:N1} ГБ, є {2:N1} ГБ. / Not enough free space.' -f $root, ($need / 1GB), ($free / 1GB))
            }
        }
    } catch [System.IO.IOException] { } catch [System.ArgumentException] { }

    New-Item -ItemType Directory -Force -Path $ukDir | Out-Null

    # чужий brpc.w3speech (справжня бразильська озвучка) - у *.orig, один раз
    $renamed = $false
    if ((Test-Path -LiteralPath $brpc -PathType Leaf) -and -not (Test-Path -LiteralPath $orig) -and -not (Test-Path -LiteralPath $built)) {
        Move-Item -LiteralPath $brpc -Destination $orig
        $renamed = $true
    }

    Write-Host 'Збираю озвучку (кілька хвилин, ~4,5 ГБ)... / Building the voice-over (a few minutes, ~4.5 GB)...'
    try {
        Add-Type -TypeDefinition $CSharp -Language CSharp
        $hit = [W3UaVo]::Build($enpc, $ua, $brpc)
    } catch {
        if ($renamed -and -not (Test-Path -LiteralPath $brpc) -and (Test-Path -LiteralPath $orig)) {
            Move-Item -LiteralPath $orig -Destination $brpc   # збірка не вдалась - повертаємо файл гравця
        }
        $m = $_.Exception.Message
        if ($_.Exception.InnerException) { $m = $_.Exception.InnerException.Message }
        throw ('Не вдалося зібрати озвучку: {0}. Закрийте гру, перевірте вільне місце (~5 ГБ на диску з грою) і запустіть скрипт ще раз. / Build failed.' -f $m)
    }
    Write-Host ('OK {0} українських реплік' -f $hit)
    [IO.File]::WriteAllText($built, $script:AppVer, (New-Object Text.UTF8Encoding($false)))

    # Налаштування мов: якщо жодного .settings ще немає - створюємо обидва
    $dx = Join-Path $docs 'dx12user.settings'
    $us = Join-Path $docs 'user.settings'
    if (-not (Test-Path -LiteralPath $dx) -and -not (Test-Path -LiteralPath $us)) {
        New-Item -ItemType Directory -Force -Path $docs | Out-Null
        Set-GameLanguages $dx $prevIni
        Set-GameLanguages $us $prevIni
    } else {
        if (Test-Path -LiteralPath $dx) { Set-GameLanguages $dx $prevIni }
        if (Test-Path -LiteralPath $us) { Set-GameLanguages $us $prevIni }
    }

    Write-Host ''
    Write-Host 'Озвучку ввімкнено. У меню гри вона називається «Português do Brasil».'
    Write-Host 'Done. In the game menu the Ukrainian voice-over is named "Português do Brasil".'
    Write-Host ''
    Write-Host ('Офіційна сторінка й нові версії / Official page: ' + $script:SiteUrl)
} catch {
    $code = 1
    Write-Host ''
    Write-Host ('ПОМИЛКА / ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Офіційна сторінка / Official page: ' + $script:SiteUrl)
}
if ($Elevated -and -not $NoPause) { Read-Host 'Натисніть Enter / Press Enter' | Out-Null }
exit $code
