# Ukrainian localization installers (gamerent)

Source code of the Windows installers for our free fan Ukrainian localizations published on Nexus Mods:

| Game | Nexus Mods | Installer version |
|---|---|---|
| The Witcher 3: Wild Hunt (Remastered) — Ukrainian voice-over | https://www.nexusmods.com/witcher3/mods/14738 | 1.0 |
| The Blood of Dawnwalker — Ukrainian text + voice-over | https://www.nexusmods.com/thebloodofdawnwalker/mods/766 | 3.0 |
| STAR WARS Galactic Racer — Ukrainian text + voice-over | https://www.nexusmods.com/starwarsgalacticracer/mods/68 | 1.0 |
| CONTROL Resonant — Ukrainian voice-over | https://www.nexusmods.com/controlresonant/mods/208 | 1.0 |

Each installer is a plain [Inno Setup 6](https://jrsoftware.org/isinfo.php) script (`*.iss`, Pascal Script in the `[Code]`
section). Comments in the scripts are in Ukrainian; a summary of what each one does is below.

## What the installers do

**The Blood of Dawnwalker** (`the-blood-of-dawnwalker/dawnwalker-ua.iss`)
- Finds the game folder (Steam libraries) or asks for it.
- Copies `zz_Ukrainian_P.pak` (text) and optionally `zz_UkrainianVO_P.pak` (voice) to `<game>\Dawnwalker\Content\Paks\~mods`.
- Since 3.0 the voice pak fills the Italian voice slot (English stays untouched). The optional "instead of English"
  component runs `slot_en.ps1`, which uses repak (MIT/Apache-2.0) to repack the voice files into the English slot.
- In `<game>\Dawnwalker\Content\Movies`, puts our Ukrainian subtitles (`*.srt`) for the intro/credits into the Czech
  slot and copies the game's own English warning movies into that slot; replaced originals are kept as `*.orig`.
- Uninstall removes the paks and restores the `*.orig` files.

**STAR WARS Galactic Racer** (`star-wars-galactic-racer/swgr-ua.iss`)
- Copies `pakchunk99-Ukrainian_P.pak/.utoc/.ucas` (text) and optionally `pakchunk98-UkrainianVO_P.pak/.utoc/.ucas` (voice)
  to `<game>\Griffin\Content\Paks`.
- Sets `GameLanguage=uk` in `%LOCALAPPDATA%\StarWarsGalacticRacer\Saved\Config\Windows\GameUserSettings.ini`.
- If the Russian fan localization `pakchunk99-Russian_P.*` is present (it would override our text), renames it to
  `*.off` while installed; uninstall renames it back.

**The Witcher 3** (`the-witcher-3/witcher3-ua-vo.iss` + `W3UaVo.cs`)
- We do not redistribute game files. The installer ships only our audio (`ua_vo.bin`) and a small helper `W3UaVo.exe`
  built from `W3UaVo.cs` (≈100 lines of C#, no dependencies besides .NET Framework 4).
- `W3UaVo.exe <enpc.w3speech> <ua_vo.bin> <brpc.w3speech>` reads the player's own English speech file and writes the
  Brazilian-Portuguese speech slot (`content\content0\brpc.w3speech`) with our Ukrainian audio; lip-sync data and any
  lines we did not replace are taken from the player's English file. The previous `brpc.w3speech` is kept as `*.orig`.
- Sets the speech language to BR and the text language to UA in `Documents\The Witcher 3\*.settings`
  (previous values saved to `<game>\UkrainianVO\prev.ini`). Uninstall restores the language and the original file.
- `ua_vo.bin` format: `"UAVO"`, u32 version (1), u32 count, then count × (u32 line id, f32 duration, u32 length, wem bytes).
  `tools/w3speech.py` documents the `.w3speech` container format.

**CONTROL Resonant** (`control-resonant/control-resonant-ua-vo.iss` + `CrUaVo.cs`)
- We do not redistribute game files. The installer ships only our audio (`ua_vo.bin`) and a small helper `CrUaVo.exe`
  built from `CrUaVo.cs` (C#, .NET Framework 4, no other dependencies).
- `CrUaVo.exe <game>\data_pack2\pc <ua_vo.bin>` copies the smallest of the game's own archives under a new name
  (`…-u01.rmdblob`), appends our Ukrainian audio to it and rebuilds the Italian voice indexes (`*.rmdtoc`, LZ4-compressed
  logical index). The original indexes are kept as `*.rmdtoc.orig`; other archives are not touched. Our audio takes the
  Italian voice slot, so in game the player picks voice "Italiano" and subtitles "Українська".
- A state file `*.rmdtoc.uavo` (length + CRC of our index) detects game updates: if the index changed, the current one
  becomes the new `.orig`. `CrUaVo.exe --restore <data_pack2\pc>` (run on uninstall) restores the original indexes and
  removes our archives.
- `ua_vo.bin` format: `"UAVO"`, u32 version (1), u32 index count, then per index its name and entries — see the header
  comment in `CrUaVo.cs`.

No installer downloads anything, runs anything from the internet, or touches files outside the game folder and the
game's own settings files listed above. The only external program run is `W3UaVo.exe` (Witcher 3, built from this repo). On the finish page there are two optional buttons that open our website and a
voluntary donation page in the default browser.

## How to build

Requirements: Windows, [Inno Setup 6](https://jrsoftware.org/isdl.php), PowerShell 5+; for The Witcher 3 also
.NET Framework 4 (`csc.exe` ships with Windows at `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\`).

The data files (localized `.pak/.utoc/.ucas`, `ua_vo.bin`, `.srt`) are binary game assets and are not stored here.
For The Blood of Dawnwalker and STAR WARS Galactic Racer the exact same data files are also published on the mod pages
as a plain ZIP ("Manual install (ZIP - no installer)"), so they can be inspected without running anything.
Note: the installers are built with Inno Setup 6.5, which innoextract 1.9 cannot unpack yet; to see what an installer
writes, install it into an empty folder that contains the stub file checked by `IsGame()` in the `.iss`
(e.g. `Griffin\Content\Paks\pakchunk0-Windows.pak`) using `/VERYSILENT /DIR="<folder>"`.

Layout expected by the build scripts (each `make.ps1` lives in `<game>\installer\` in our working tree):

```
<game>\
  installer\   <- files from this repository's <game>\ folder
  build\installer-payload\   <- data files (see the [Files] section of the .iss)
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File <game>\installer\make.ps1
```

`make.ps1` copies the data files into `build\installer-payload` (Witcher 3: compiles `W3UaVo.exe` with `csc.exe`) and
calls `ISCC.exe` on the `.iss`. The result is `build\<Name>-<version>-setup.exe`. You can also compile any `.iss`
directly in the Inno Setup IDE once `build\installer-payload` contains the files listed in its `[Files]` section.

## License

Installer scripts and `W3UaVo.cs`: MIT (see `LICENSE`). Game names and assets belong to their respective owners.
