УКРАЇНІЗАТОР GTA IV: THE COMPLETE EDITION - ручне встановлення (без .exe)

Неофіційний безкоштовний фанатський переклад. Не продається.
Для основної гри, The Lost and Damned і The Ballad of Gay Tony (версія Steam, Complete Edition).

Що входить:
  • Текст - інтерфейс, субтитри, усі діалоги й повідомлення (понад 80 тис. рядків)
    і шрифти з українськими літерами (Ґ, Є, І, Ї).
  • Озвучка (за бажанням) - репліки персонажів у місіях, дзвінках і роликах українською
    (~38 700 реплік). Голоси синтетичні (нейромережа), а не записані акторами;
    голоси акторів оригіналу не копіювалися.

Офіційна сторінка й нові версії: https://gamerent.com.ua/ukrainizatory/grand-theft-auto-iv
Там само - звичайний інсталятор (.exe), якщо вам зручніше він.
Джерела інсталяторів і скриптів: https://github.com/vasyl-tihai/ua-game-localization-installers
Поширювати можна лише з посиланням на офіційну сторінку.

Встановлення:
  1. Розпакуйте архів ПОВНІСТЮ в будь-яку теку (не запускайте з вікна архіву). Потрібно ≈ 1,9 ГБ для розпаковки.
  2. Закрийте гру. Двічі клацніть install.bat.
     Скрипт сам знайде гру (Steam і бібліотеки Steam). Якщо не знайде - попросить вставити шлях до теки гри
     (у ній є GTAIV.exe), наприклад ...\steamapps\common\Grand Theft Auto IV\GTAIV.
     Якщо гра в «Program Files», Windows спитає дозвіл (UAC) - натисніть «Так».
  3. Оберіть «1» (текст і озвучка) або «2» (лише текст). Для озвучки потрібно ≈ 4,5 ГБ вільного місця
     на диску з грою; для «лише текст» - кілька десятків МБ.
  4. Зачекайте кілька хвилин: для кожного файлу скрипт показує відсотки. В кінці буде рядок «Готово».
  5. Мова: переклад замінює англійську, тому в Steam і в грі залиште англійську мову.

Що робить скрипт (усе видно в install.ps1 і common.ps1, це звичайний текст):
  • Файлів гри не поширює: в архіві лише «дельти» (delta\*.ua) - різниця між вашим оригіналом і українською версією.
  • Перед зміною кожен файл гри перейменовується в *.orig (лежить поруч). Потім скрипт будує новий файл з *.orig і дельти
    та перевіряє SHA-1 результату. Якщо щось не збіглося - файл лишається оригінальним.
  • Застосувач - це кількадесят рядків C# усередині install.ps1; Windows компілює їх на вашому ПК.
    В архіві немає жодного .exe чи .dll, тому й попередження SmartScreen тут не буде.
  • Скрипт нічого не завантажує з інтернету й нікуди не надсилає.

Оновлення: запустіть install.bat нової версії ще раз - оригінали з *.orig не затираються, дельта береться від них.
Після оновлення гри Steam може повернути англійські файли - тоді запустіть install.bat ще раз.
Якщо скрипт пише, що файли гри відрізняються, перевірте цілісність файлів гри в Steam
(Властивості - Встановлені файли - Перевірити цілісність файлів).

Видалення: двічі клацніть uninstall.bat. Він поверне кожен *.orig на місце (і після «лише текст», і після повної установки).

Якщо PowerShell заблоковано політикою системи або антивірусом: скористайтеся інсталятором (.exe) з офіційної сторінки.

Подяки:
  Озвучка - created with Boson AI's Higgs Audio (Higgs TTS 3, некомерційна ліцензія).
Підтримати розвиток українізаторів (добровільно): https://send.monobank.ua/jar/Ry1LdCDFF

---------------------------------------------------------------------------------------------------
UKRAINIAN LOCALIZATION FOR GTA IV: THE COMPLETE EDITION - manual install (no .exe)

Unofficial free fan translation, not for sale.
For the base game, The Lost and Damned and The Ballad of Gay Tony (Steam, Complete Edition).

What is included:
  • Text - interface, subtitles, all dialogue and messages (80,000+ lines) and fonts with the
    Ukrainian letters (Ґ, Є, І, Ї).
  • Voice-over (optional) - spoken lines in missions, phone calls and cutscenes in Ukrainian (~38,700 lines).
    The voices are AI-generated (synthetic); no actors recorded them and the original actors' voices were not cloned.

Official page and new versions: https://gamerent.com.ua/ukrainizatory/grand-theft-auto-iv
The regular installer (.exe) is available there too.
Installer and script sources: https://github.com/vasyl-tihai/ua-game-localization-installers
Redistribution is allowed only with a link to the official page.

Install:
  1. Extract the WHOLE archive to any folder (do not run it from inside the archive window). ~1.9 GB needed.
  2. Close the game. Double-click install.bat.
     The script finds the game on its own (Steam and Steam libraries). If it cannot, it asks you to paste the game
     folder path (the one containing GTAIV.exe), e.g. ...\steamapps\common\Grand Theft Auto IV\GTAIV.
     If the game is under "Program Files", Windows asks for permission (UAC) - click Yes.
  3. Choose "1" (text and voice-over) or "2" (text only). The voice-over needs ~4.5 GB of free space on the game
     drive; text only needs a few dozen MB.
  4. Wait a few minutes: the script prints the percentage for every file. At the end it prints "Done".
  5. Language: the translation replaces English, so keep the language set to English in Steam and in the game.

What the script does (everything is plain text in install.ps1 and common.ps1):
  • It does not redistribute game files: the archive holds only deltas (delta\*.ua) - the difference between
    your original file and the Ukrainian version.
  • Before changing a game file, the script renames it to *.orig (kept next to it). It then builds the new file from
    the *.orig and the delta and verifies the SHA-1 of the result. If anything does not match, the file stays original.
  • The applier is a few dozen lines of C# inside install.ps1, compiled by Windows on your PC.
    There is no .exe or .dll in this archive, so there is no SmartScreen warning.
  • The script downloads nothing and sends nothing anywhere.

Update: run install.bat of the new version again - the *.orig originals are never overwritten, the delta is applied to them.
After a game update Steam may restore the English files - just run install.bat again.
If the script says the game files differ, verify the game files in Steam
(Properties - Installed Files - Verify integrity of game files).

Uninstall: double-click uninstall.bat. It puts every *.orig back (after both "text only" and the full install).

If PowerShell is blocked by system policy or antivirus: use the installer (.exe) from the official page.

Credits:
  Voice-over - created with Boson AI's Higgs Audio (Higgs TTS 3, non-commercial license).
Support the project (optional): https://send.monobank.ua/jar/Ry1LdCDFF
