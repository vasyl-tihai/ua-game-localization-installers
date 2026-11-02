УКРАЇНСЬКА ОЗВУЧКА «ВІДЬМАК 3: ДИКЕ ПОЛЮВАННЯ» (REMASTERED) - ручне встановлення (без .exe)

Неофіційна безкоштовна фанатська озвучка. Не продається.
Український текст у грі офіційний, ця озвучка додає до нього голоси.
Голоси синтетичні (нейромережа), актори їх не записували, і їхні голоси не копіювали.
Усі 64 478 реплік основної гри та доповнень «Серця з каменю» й «Кров і вино». Рухи губ лишаються з англійської версії.

Офіційна сторінка й нові версії: https://gamerent.com.ua/ukrainizatory/the-witcher-3
Там само - звичайний інсталятор (.exe), якщо вам зручніше він.
Джерела інсталяторів і скриптів: https://github.com/vasyl-tihai/ua-game-localization-installers

Встановлення:
  1. Розпакуйте архів ПОВНІСТЮ в будь-яку теку (не запускайте з вікна архіву). Потрібно ≈ 1,6 ГБ для розпаковки.
  2. Закрийте гру. Двічі клацніть install.bat.
     Скрипт сам знайде гру (Steam, бібліотеки Steam, GOG). Якщо не знайде - попросить вставити шлях до теки гри
     (у ній є content\content0). Якщо гра в «Program Files», Windows спитає дозвіл (UAC) - натисніть «Так».
  3. Зачекайте кілька хвилин, поки збереться озвучка. Потрібно ≈ 5 ГБ вільного місця на диску з грою.
  4. У грі мова озвучки називатиметься «Português do Brasil» - це наша українська озвучка. Мова тексту - українська (UA).
     Скрипт вмикає їх сам; якщо в меню вибрати іншу озвучку, поверніть «Português do Brasil».

Що робить скрипт (усе видно в install.ps1 і common.ps1, це звичайний текст):
  • Файлів гри не змінює і не поширює. Бере ваш англійський content\content0\enpc.w3speech і наш звук ua_vo.bin
    та збирає новий content\content0\brpc.w3speech (слот бразильської португальської озвучки).
    Рухи губ і решту реплік бере з вашого англійського файлу.
  • Ваш попередній brpc.w3speech, якщо він був, зберігає як brpc.w3speech.orig.
  • У Документи\The Witcher 3\dx12user.settings і user.settings ставить озвучку BR і текст UA.
    Попередні значення запамʼятовує в <тека гри>\UkrainianVO\prev.ini.
  • Збирач - це кілька десятків рядків C# усередині install.ps1; Windows компілює їх на вашому ПК.
    В архіві немає жодного .exe чи .dll, тому й попередження SmartScreen тут не буде.
  • Скрипт нічого не завантажує з інтернету й нікуди не надсилає.

Оновлення: запустіть install.bat нової версії ще раз - попередні налаштування не затираються.

Видалення: двічі клацніть uninstall.bat. Він поверне мову озвучки й тексту такою, як була, видалить зібраний
brpc.w3speech і поверне ваш попередній (brpc.w3speech.orig), якщо він був.
Якщо після оновлення гри щось не так: видаліть озвучку й встановіть її знову.

Якщо PowerShell заблоковано політикою системи або антивірусом: скористайтеся інсталятором (.exe) з офіційної сторінки.

Подяки: голоси - Google Gemini 2.5 Pro TTS. Текст - офіційна українська локалізація CD PROJEKT RED.
Підтримати розвиток українізаторів (добровільно): https://send.monobank.ua/jar/Ry1LdCDFF

---------------------------------------------------------------------------------------------------
UKRAINIAN VOICE-OVER FOR THE WITCHER 3: WILD HUNT (REMASTERED) - manual install (no .exe)

Unofficial free fan project, not for sale. The Ukrainian text in the game is official; this adds the voices.
Voices are AI-generated (synthetic); no actors recorded them and no actor voices were cloned.
All 64,478 lines of the base game plus Hearts of Stone and Blood and Wine. Lip-sync stays from the English version.

Official page and new versions: https://gamerent.com.ua/ukrainizatory/the-witcher-3
The regular installer (.exe) is available there too.
Installer and script sources: https://github.com/vasyl-tihai/ua-game-localization-installers

Install:
  1. Extract the WHOLE archive to any folder (do not run it from inside the archive window). ~1.6 GB needed.
  2. Close the game. Double-click install.bat.
     The script finds the game on its own (Steam, Steam libraries, GOG). If it cannot, it asks you to paste the game
     folder path (the one containing content\content0). If the game is under "Program Files", Windows asks for
     permission (UAC) - click Yes.
  3. Wait a few minutes while the voice-over is built. You need ~5 GB of free space on the game drive.
  4. In the game the speech language is named "Português do Brasil" - that slot holds our Ukrainian voice-over.
     Text language is Ukrainian (UA). The script sets both; if you pick another speech language in the menu,
     switch back to "Português do Brasil".

What the script does (everything is plain text in install.ps1 and common.ps1):
  • It does not modify or redistribute game files. It reads your English content\content0\enpc.w3speech and our audio
    ua_vo.bin and builds a new content\content0\brpc.w3speech (the Brazilian-Portuguese speech slot).
    Lip-sync data and any other lines come from your own English file.
  • Your previous brpc.w3speech, if any, is kept as brpc.w3speech.orig.
  • In Documents\The Witcher 3\dx12user.settings and user.settings it sets speech BR and text UA.
    The previous values are saved to <game folder>\UkrainianVO\prev.ini.
  • The builder is a few dozen lines of C# inside install.ps1, compiled by Windows on your PC.
    There is no .exe or .dll in this archive, so there is no SmartScreen warning.
  • The script downloads nothing and sends nothing anywhere.

Update: run install.bat of the new version again; your previous settings are not overwritten.

Uninstall: double-click uninstall.bat. It restores your previous speech/text language, deletes the built brpc.w3speech
and restores your previous one (brpc.w3speech.orig) if there was one.
If something breaks after a game update: uninstall, then install again.

If PowerShell is blocked by system policy or antivirus: use the installer (.exe) from the official page.

Credits: voices - Google Gemini 2.5 Pro TTS. Text - official Ukrainian localization by CD PROJEKT RED.
Support the project (optional): https://send.monobank.ua/jar/Ry1LdCDFF
