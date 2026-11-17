"""ZIP для Nexus (лише дані, без exe/скриптів — Nexus такі пропускає): SWZeroCompany/Content/Paks/pakchunk99-Windows_P.{pak,utoc,ucas} + README.
python tools/make_manual_zip.py → build/ZeroCompany-Ukrainian-1.0-manual.zip"""
import os, zipfile
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
V = '1.0'
README = '''УКРАЇНІЗАТОР STAR WARS ZERO COMPANY {v} — встановлення вручну (без інсталятора)

Інсталятор (exe, в один клік) і нові версії: https://gamerent.com.ua/ukrainizatory/star-wars-zero-company

1. Розпакуйте архів.
2. Скопіюйте теку SWZeroCompany з архіву в теку гри й погодьтеся об'єднати теки.
   Теку гри в Steam: правою кнопкою по грі → Керувати → Переглянути локальні файли.
   Мають з'явитися файли SWZeroCompany/Content/Paks/pakchunk99-Windows_P.pak, .utoc, .ucas.
3. Мову в Steam і в грі лишіть англійською — переклад стоїть на її місці.

Що входить: текст (інтерфейс, субтитри, діалоги, брифінги, підказки) і шрифт з Ґ Є І Ї;
озвучка ~17 700 реплік (ролики, розмови, бій). Голоси синтетичні (нейромережа), голоси акторів не копіювалися.
Видалення: видаліть три файли pakchunk99-Windows_P.* з SWZeroCompany/Content/Paks.
Після оновлення гри, якщо повернулась англійська або щось зламалось, — поставте свіжу версію.

Подяки: озвучка — created with Boson AI's Higgs Audio (Higgs TTS 3, некомерційна ліцензія); шрифт Roboto (Apache 2.0).
Неофіційний безкоштовний фанатський переклад. Поширювати лише з посиланням на офіційну сторінку.
Підтримати (добровільно): https://send.monobank.ua/jar/Ry1LdCDFF

----------------------------------------------------------------------------------------------------
UKRAINIAN LOCALIZATION FOR STAR WARS ZERO COMPANY {v} — manual install

Installer (exe, one click) and updates: https://gamerent.com.ua/en/ukrainizatory/star-wars-zero-company

1. Extract the archive.
2. Copy the SWZeroCompany folder from the archive into the game folder and merge
   (Steam: right-click the game → Manage → Browse local files).
3. Keep English as the game/Steam language — the translation replaces it.

Includes: UI, subtitles, dialogue, briefings, tips + font with Ukrainian letters; ~17,700 voiced lines
(cutscenes, conversations, combat). Voices are synthetic (AI), no actor voices were cloned.
Uninstall: delete pakchunk99-Windows_P.* from SWZeroCompany/Content/Paks.
Credits: voice-over created with Boson AI's Higgs Audio (Higgs TTS 3, non-commercial license); font Roboto (Apache 2.0).
'''.format(v=V)
out = os.path.join(HERE, 'build', f'ZeroCompany-Ukrainian-{V}-manual.zip')
with zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as z:
    for e in ('pak', 'utoc', 'ucas'):
        z.write(os.path.join(HERE, 'build', 'pak', f'pakchunk99-Windows_P.{e}'), f'SWZeroCompany/Content/Paks/pakchunk99-Windows_P.{e}')
    z.writestr('README-UA-EN.txt', '﻿' + README.replace('\n', '\r\n'))
print(out, os.path.getsize(out))
