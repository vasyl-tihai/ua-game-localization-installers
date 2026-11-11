# ZIP без інсталятора для Nexus: dinput8.dll (REFramework) у корінь гри, переклад — у <гра>\pak_mods.
# python -I tools/make_manual_zip.py <вихідна тека>
#   → gamerent.com.ua-OnimushaWotS-Ukrainian-manual.zip (текст + озвучка)
#   → gamerent.com.ua-OnimushaWotS-Ukrainian-text-only.zip (лише текст)
import os, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(ROOT, "build", "installer-payload")
SITE = "https://gamerent.com.ua/ukrainizatory/onimusha-way-of-the-sword"

README = """УКРАЇНІЗАТОР ONIMUSHA: WAY OF THE SWORD {ver} — ВАРІАНТ БЕЗ ІНСТАЛЯТОРА
{what}

Встановлення:
  1. Steam → правою кнопкою по грі → Керувати → Переглянути локальні файли (тека з OnimushaWotS.exe).
  2. Розпакуйте цей архів У ЦЮ ТЕКУ: dinput8.dll ляже поруч з OnimushaWotS.exe,
     переклад — у теку pak_mods (архів створить її сам).
  3. У налаштуваннях гри оберіть мову тексту «Русский»{voice_ru} — замість неї буде українська.

dinput8.dll — це REFramework (praydog, відкритий код, MIT, текст ліцензії — LICENSE-REFramework.txt).
Гра перевіряє свої файли й без нього ігнорує теку pak_mods. Файли гри не змінюються.
Видалення: видаліть dinput8.dll і файли re_chunk_000.pak.patch_002.pak / patch_003.pak з теки pak_mods.
Якщо у вас уже стоять інші моди в pak_mods з тими самими номерами patch_002/003 — вони конфліктують.
Після оновлення гри, якщо щось зламалось, — поставте свіжу версію з офіційної сторінки.

Голоси синтетичні (Google Gemini TTS), а не записані акторами; голоси акторів не клонувалися.
Офіційна сторінка й нові версії: {site}
Неофіційний безкоштовний фанатський переклад, не продається. Поширювати — лише з посиланням на офіційну сторінку.
Підтримати (добровільно): https://send.monobank.ua/jar/Ry1LdCDFF

---
ONIMUSHA: WAY OF THE SWORD UKRAINIAN {ver} — MANUAL INSTALL (no installer)
{what_en}
Install: extract into the game folder (Steam → Manage → Browse local files): dinput8.dll goes next to
OnimushaWotS.exe, the translation into the pak_mods folder. In the game settings set text language to Russian{voice_en} —
Ukrainian replaces it. dinput8.dll is REFramework (praydog, MIT) — the game ignores pak_mods without it.
Uninstall: delete dinput8.dll and re_chunk_000.pak.patch_002/003.pak from pak_mods.
Synthetic AI voices (Google Gemini TTS); no real actor voices were cloned.
Official page: {site}
"""


def make(out, name, voice, what, what_en, ver="1.0"):
    p = os.path.join(out, name)
    with zipfile.ZipFile(p, "w") as z:
        txt = README.format(ver=ver, what=what, what_en=what_en, site=SITE,
                            voice_ru=" і мову озвучки «Русский»" if voice else " (мову озвучки лишіть English)",
                            voice_en=" and voice language to Russian" if voice else " (keep voice language English)")
        z.writestr("README-uk.txt", b"\xef\xbb\xbf" + txt.replace("\n", "\r\n").encode("utf-8"), zipfile.ZIP_DEFLATED)
        z.write(os.path.join(P, "LICENSE-REFramework.txt"), "LICENSE-REFramework.txt", zipfile.ZIP_DEFLATED)
        z.write(os.path.join(P, "dinput8.dll"), "dinput8.dll", zipfile.ZIP_DEFLATED)
        z.write(os.path.join(P, "re_chunk_000.pak.patch_002.pak"), "pak_mods/re_chunk_000.pak.patch_002.pak", zipfile.ZIP_DEFLATED)
        if voice:
            z.write(os.path.join(P, "re_chunk_000.pak.patch_003.pak"), "pak_mods/re_chunk_000.pak.patch_003.pak", zipfile.ZIP_STORED)
    print(name, os.path.getsize(p))


out = sys.argv[1]
os.makedirs(out, exist_ok=True)
make(out, "gamerent.com.ua-OnimushaWotS-Ukrainian-text-only.zip", False,
     "Лише текст: інтерфейс, субтитри, діалоги, записи. Озвучка лишається англійською.",
     "Text only: UI, subtitles, dialogue, lore. Voice-over stays English.")
make(out, "gamerent.com.ua-OnimushaWotS-Ukrainian-manual.zip", True,
     "Текст і українська озвучка (синтетичні голоси).",
     "Ukrainian text and voice-over (synthetic voices).")
