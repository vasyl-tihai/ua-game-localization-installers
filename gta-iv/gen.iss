[Files]
Source: "{#Payload}\patches\p00.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p01.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p02.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p03.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p04.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p05.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p06.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p07.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p08.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p09.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p10.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p11.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p12.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p13.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p14.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p15.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p16.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p17.hdiff"; DestDir: "{tmp}\ua"; Components: text; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p18.hdiff"; DestDir: "{tmp}\ua"; Components: voice; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p19.hdiff"; DestDir: "{tmp}\ua"; Components: voice; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p20.hdiff"; DestDir: "{tmp}\ua"; Components: voice; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p21.hdiff"; DestDir: "{tmp}\ua"; Components: voice; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p22.hdiff"; DestDir: "{tmp}\ua"; Components: voice; Flags: ignoreversion nocompression deleteafterinstall
Source: "{#Payload}\patches\p23.hdiff"; DestDir: "{tmp}\ua"; Components: voice; Flags: ignoreversion nocompression deleteafterinstall

[Code]
procedure InitList;
begin
  Add('text', 'common\text\american.gxt', 'p00.hdiff', 5218454, 4954934, '7933c35cdb56e68307a5061abee24874363c9908');
  Add('text', 'common\text\russian.gxt', 'p01.hdiff', 5293202, 4954572, 'ed9cc86276d898a5f67a212cfe9df6757343ae6d');
  Add('text', 'common\data\fonts.dat', 'p02.hdiff', 10850, 12281, '55cdfdc261156aa603526d5c5d874304f80d72ef');
  Add('text', 'common\data\fonts_r.dat', 'p03.hdiff', 12285, 12281, '55cdfdc261156aa603526d5c5d874304f80d72ef');
  Add('text', 'pc\textures\fonts.wtd', 'p04.hdiff', 101044, 126133, '859b99d9a2cdf28eea5b565b1b22407f58009c80');
  Add('text', 'pc\textures\fonts_r.wtd', 'p05.hdiff', 125940, 126133, '859b99d9a2cdf28eea5b565b1b22407f58009c80');
  Add('text', 'pc\textures\fonts_streamed_1.wtd', 'p06.hdiff', 56841, 48228, '463d0806fb393b23c4b67558f2013336861c5bdd');
  Add('text', 'pc\textures\fonts_r_streamed_1.wtd', 'p07.hdiff', 48457, 48228, '463d0806fb393b23c4b67558f2013336861c5bdd');
  Add('text', 'TLAD\common\text\american.gxt', 'p08.hdiff', 1437362, 1372652, '4745295164295f90ba9983f9df6b3ae365a2c265');
  Add('text', 'TLAD\common\text\russian.gxt', 'p09.hdiff', 1408334, 1373226, '955cecd0705b36958b162f7deacdfbefbeb17e96');
  Add('text', 'TLAD\common\data\fonts.dat', 'p10.hdiff', 10337, 12281, '55cdfdc261156aa603526d5c5d874304f80d72ef');
  Add('text', 'TLAD\pc\textures\fonts.wtd', 'p11.hdiff', 316763, 305760, '00c5f6291c685fd0d23a9ebec7b521bb50e70e37');
  Add('text', 'TLAD\pc\textures\fonts_r.wtd', 'p12.hdiff', 310693, 305760, '00c5f6291c685fd0d23a9ebec7b521bb50e70e37');
  Add('text', 'TBoGT\common\text\american.gxt', 'p13.hdiff', 1812250, 1728418, '92136f96cf825cfcd4372d3374e9942b64551c74');
  Add('text', 'TBoGT\common\text\russian.gxt', 'p14.hdiff', 1758242, 1728460, '4ef29c8b05c947e28b58e9e304eb5508d576af17');
  Add('text', 'TBoGT\common\data\fonts.dat', 'p15.hdiff', 10685, 12334, '9fc8799e8d4a9fcfd2bd156a52396b89446565df');
  Add('text', 'TBoGT\pc\textures\fonts.wtd', 'p16.hdiff', 120302, 128185, 'ba5b610c9a7f801e078f5a8863318f0cdcf2ee8e');
  Add('text', 'TBoGT\pc\textures\fonts_r.wtd', 'p17.hdiff', 127995, 128185, 'ba5b610c9a7f801e078f5a8863318f0cdcf2ee8e');
  Add('voice', 'pc\audio\sfx\scripted_speech.rpf', 'p18.hdiff', 778319872, 1049161728, '4669b76cbc66d3473c09fd071d362ae4d581f4e9');
  Add('voice', 'pc\audio\sfx\cutscenes.rpf', 'p19.hdiff', 847894528, 847894528, '7970ed46b0bcf470941ca5be36a2e04b80090a7f');
  Add('voice', 'TLAD\pc\audio\sfx\EP1_SCRIPTED_SPEECH.rpf', 'p20.hdiff', 260165632, 326653952, '7ea4f84c76cbbd60f513a45d99f92f56c86c4ca4');
  Add('voice', 'TLAD\pc\audio\sfx\EP1_SFX.rpf', 'p21.hdiff', 999360512, 999360512, '2d74cfabb345854edb35a37f514acb4f3d55457b');
  Add('voice', 'TBoGT\pc\audio\sfx\EP2_SCRIPTED_SPEECH.rpf', 'p22.hdiff', 309843968, 383971328, 'cb9660f4fa6b240b77f71326230374f491ce46a7');
  Add('voice', 'TBoGT\pc\audio\sfx\EP2_SFX.rpf', 'p23.hdiff', 913936384, 913936384, '7a480694cd9025c2ea1ef767d26ba0b3d242e772');
end;
