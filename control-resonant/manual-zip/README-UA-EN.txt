УКРАЇНСЬКА ОЗВУЧКА «CONTROL RESONANT» — ручне встановлення (ZIP, без .exe)
UKRAINIAN VOICE-OVER FOR «CONTROL RESONANT» — manual install (ZIP, no .exe)

=====================================  УКРАЇНСЬКОЮ  =====================================

Неофіційна безкоштовна фанатська озвучка. Не продається.
Український текст у грі офіційний, ця озвучка додає до нього голоси.
Голоси синтетичні (нейромережа), актори їх не записували, і їхні голоси не копіювали.

У цьому архіві немає жодного .exe чи .dll: лише скрипти PowerShell (відкриваються в Блокноті),
звукові дані ua_vo.bin (~800 МБ) і цей файл. Файлів гри в архіві немає.

Встановлення:
  1. Закрийте гру. Розпакуйте ВЕСЬ архів у будь-яку теку (не запускайте з-під архіву).
  2. Двічі клацніть install.bat. Скрипт сам знайде гру в Steam (реєстр і бібліотеки Steam);
     якщо не знайде, запитає шлях до теки гри (у ній є підтека data_pack2\pc).
     Якщо гра в «Program Files», Windows запитає права адміністратора.
  3. Зачекайте кілька хвилин, поки з'явиться «Готово». Потрібно ≈ 2 ГБ вільного місця
     на диску з грою під час встановлення і ≈ 1 ГБ після нього.
  4. У грі: Налаштування → Мова: озвучка «Italiano» (це наша українська), субтитри «Українська».
  Потрібна італійська озвучка гри (у Steam вона встановлюється разом із грою).
  Якщо Windows показує «Windows захистила ваш ПК» для .bat: «Докладніше» → «Виконати в будь-якому разі».
  Скрипти — звичайний текст: за бажанням прочитайте install.ps1 перед запуском.

Видалення:
  Закрийте гру й двічі клацніть uninstall.bat. Він поверне оригінальні файли *.rmdtoc
  і прибере наші копії архівів (-uNN.rmdblob). Італійська озвучка стане знову італійською.

Що робить скрипт (так само, як інсталятор на сайті):
  • Для чотирьох індексів італійської озвучки (base-it, stream0-it, base-generic, stream0-generic)
    бере найменший архів гри, копіює його під новою назвою (…-uNN.rmdblob) і дописує наш звук з ua_vo.bin.
  • Перебудовує індекси *.rmdtoc; оригінали зберігаються як *.rmdtoc.orig, стан — *.rmdtoc.uavo.
  • Решту файлів гри не змінює. Звук ставиться в слот італійської озвучки.
  • Нічого не завантажує з інтернету. Код збирача — C# усередині install.ps1 (Add-Type).

Після оновлення гри: якщо озвучка зникла або гра не запускається, «Перевірити цілісність файлів»
у Steam (Властивості → Установлені файли), потім знову запустіть install.bat.
Скрипт сам розпізнає оновлену гру й візьме нові оригінальні індекси.

Що входить: понад 13 900 звукових файлів (діалоги, ролики, аудіозаписи, оголошення, бойові вигуки).
Задовгі фрази подекуди скорочено за змістом, щоб вони вміщалися в час оригіналу, тож озвучка
може трохи відрізнятися від субтитрів. Рухи губ лишаються з оригінальної версії.

Офіційна сторінка й нові версії: https://gamerent.com.ua/ukrainizatory/control-resonant
Джерела інсталяторів (GitHub): https://github.com/vasyl-tihai/ua-game-localization-installers
Поширювати можна лише з посиланням на офіційну сторінку.

Подяки:
  Голоси — Google Gemini 2.5 Pro TTS. Текст — офіційна українська локалізація Remedy Entertainment.

Підтримати розвиток українізаторів (добровільно): https://send.monobank.ua/jar/Ry1LdCDFF

-----------------------------------------  ENGLISH  -------------------------------------------

Unofficial free fan-made Ukrainian voice-over. Not for sale.
The Ukrainian text in the game is official; this adds voices to it.
The voices are synthetic (AI); no actors recorded them and no actor voices were cloned.

This archive contains no .exe or .dll files: only PowerShell scripts (readable in Notepad),
the audio data file ua_vo.bin (~800 MB) and this file. No game files are included.

Install:
  1. Close the game. Extract the WHOLE archive to any folder (do not run from inside the archive).
  2. Double-click install.bat. It finds the game in Steam by itself (registry and Steam libraries);
     if it cannot, it asks for the game folder (the one that contains data_pack2\pc).
     If the game is under "Program Files", Windows asks for administrator rights.
  3. Wait a few minutes until "Done" appears. About 2 GB of free space is needed on the game drive
     during install and about 1 GB afterwards.
  4. In game: Settings > Language: voice-over "Italiano" (this is our Ukrainian), subtitles "Ukrainian".
  The game's Italian voice pack must be installed (Steam installs it together with the game).
  If Windows shows "Windows protected your PC" for the .bat: More info > Run anyway.
  The scripts are plain text: read install.ps1 before running it if you like.

Uninstall:
  Close the game and double-click uninstall.bat. It restores the original *.rmdtoc files and removes
  our archive copies (-uNN.rmdblob). The Italian voice-over becomes Italian again.

What the script does (the same as the installer on the website):
  - For the four Italian voice indexes (base-it, stream0-it, base-generic, stream0-generic) it takes the
    smallest game archive, copies it under a new name (...-uNN.rmdblob) and appends our audio from ua_vo.bin.
  - It rebuilds the *.rmdtoc indexes; originals are kept as *.rmdtoc.orig, state in *.rmdtoc.uavo.
  - Other game files are not touched. The audio goes into the Italian voice-over slot.
  - Nothing is downloaded from the internet. The builder is C# code inside install.ps1 (Add-Type).

After a game update: if the voice-over disappeared or the game does not start, use "Verify integrity of
game files" in Steam (Properties > Installed Files), then run install.bat again. The script detects
the updated game and takes the new original indexes.

Included: over 13,900 audio files (dialogue, cutscenes, audio logs, announcements, combat barks).
Overly long lines are occasionally shortened in meaning to fit the original timing, so the voice-over
may differ slightly from the subtitles. Lip movements remain those of the original version.

Official page and new versions: https://gamerent.com.ua/ukrainizatory/control-resonant
Installer sources (GitHub): https://github.com/vasyl-tihai/ua-game-localization-installers
Redistribution is allowed only with a link to the official page.

Credits:
  Voices: Google Gemini 2.5 Pro TTS. Text: the official Ukrainian localization by Remedy Entertainment.

Support the project (optional): https://send.monobank.ua/jar/Ry1LdCDFF
