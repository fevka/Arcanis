-- Arcanis: sinif/uzmanlik stat agirliklari (ns.StatWeights). Helpers/Gear.lua puanlamada kullanir.
--
-- AMAC: seviye atlama (1-60); sayilar goreli agirliktir.
--
-- OLCEK: her uzmanligin ana stati = 1.0 puan / stat puani.
--   str agi sta int spi : 1 stat puani basina
--   ap rap              : 1 saldiri gucu (yakin / uzak) basina
--   sp                  : +1 buyu hasari (hasar+iyilestirme veren esyada sp ve heal ikisi de sayilir)
--   heal                : +1 yalniz iyilestirme
--   crit hit            : %1 yakin/uzak kritik / isabet       spellcrit spellhit : %1 buyu kritik / isabet
--   mp5                 : 5 saniyede 1 mana
--   armor defense block : 1 zirh / 1 savunma becerisi / 1 blok degeri
--   mh oh th ranged wand: 1 silah DPS'i (ana el ya da tek el / yan el / iki el / yay-tufek-arbalet-firlatma / asa-degnek)
--   shield              : kalkan takmanin sabit degeri (kalkanin kendi zirhi ayrica "armor" ile sayilir)
--
-- MANTIK (Classic 1.12 kurallari): 14 AP = +1 DPS; seviye atlarken silah DPS'i en buyuk yukseltmedir.
--   Erken seviyede (levels) wand/spi yukari cekilir; yan el mh'nin yarisi sayilir.
--
-- BICIM:
--   ns.StatWeights[SINIF] = { default = specId, specs = { { id, name = { enUS, trTR }, w = {...},
--                             wants = { twoHand, dualWield, shield, ranged, wand }, levels = { { upTo = N, set = {...} } } } } }
--   id: oyunun uzmanlik kimligi (Retail SpecID; Classic agacinin sirasiyla ayni). levels: oyuncu seviyesi <= upTo ise
--   "set" icindeki degerler w uzerine yazilir (ilk eslesen degil, hepsi sirayla uygulanir).
local _, ns = ...

local SW = {}
ns.StatWeights = SW

SW.WARRIOR = {
  default = 71,
  specs = {
    { id = 71, name = { enUS = "Arms", trTR = "Silah" }, wants = { twoHand = true },
      w = { str = 1, agi = 0.6, sta = 0.5, spi = 0.05, ap = 0.5, crit = 12, hit = 10, armor = 0.025, defense = 0.2,
            th = 7, mh = 5.5, oh = 2, ranged = 0.3, shield = 0 },
      levels = { { upTo = 19, set = { sta = 0.6, mh = 6, shield = 2 } } } },
    { id = 72, name = { enUS = "Fury", trTR = "Öfke" }, wants = { dualWield = true },
      w = { str = 1, agi = 0.6, sta = 0.45, spi = 0.05, ap = 0.5, crit = 12, hit = 14, armor = 0.02, defense = 0.2,
            th = 6.5, mh = 7, oh = 3.5, ranged = 0.3, shield = 0 },
      levels = { { upTo = 19, set = { th = 7, oh = 0 } } } },
    { id = 73, name = { enUS = "Protection", trTR = "Koruma" }, wants = { shield = true },
      w = { sta = 1, str = 0.6, agi = 0.5, ap = 0.3, crit = 5, hit = 8, armor = 0.08, defense = 1.5, block = 0.3,
            th = 2, mh = 3.5, oh = 1, ranged = 0.3, shield = 10 } },
  },
}

SW.PALADIN = {
  default = 70,
  specs = {
    { id = 65, name = { enUS = "Holy", trTR = "Kutsal" }, wants = { shield = true },
      w = { int = 1, spi = 0.35, sta = 0.35, str = 0.2, heal = 0.7, sp = 0.2, spellcrit = 9, mp5 = 1.8, armor = 0.01,
            th = 0.6, mh = 0.6, shield = 3 },
      levels = { { upTo = 29, set = { str = 0.5, sta = 0.45, th = 3, mh = 2.5 } } } },
    { id = 66, name = { enUS = "Protection", trTR = "Koruma" }, wants = { shield = true },
      w = { sta = 1, str = 0.6, agi = 0.4, int = 0.5, sp = 0.6, mp5 = 1, armor = 0.06, defense = 1.2, block = 0.3,
            crit = 4, hit = 6, th = 1.5, mh = 3, shield = 10 } },
    { id = 70, name = { enUS = "Retribution", trTR = "Cezalandırma" }, wants = { twoHand = true },
      w = { str = 1, agi = 0.5, sta = 0.55, int = 0.4, spi = 0.15, ap = 0.5, sp = 0.3, crit = 10, hit = 10, mp5 = 0.8,
            armor = 0.025, th = 7, mh = 5, shield = 1 },
      levels = { { upTo = 19, set = { sta = 0.6, shield = 2 } } } },
  },
}

SW.HUNTER = {
  default = 253,
  specs = {
    { id = 253, name = { enUS = "Beast Mastery", trTR = "Hayvan Ustalığı" }, wants = { ranged = true },
      w = { agi = 1, rap = 0.45, int = 0.35, sta = 0.45, str = 0.05, ap = 0.1, spi = 0.1, crit = 9, hit = 10, mp5 = 1,
            armor = 0.02, ranged = 6, th = 0.5, mh = 0.3, oh = 0.2 },
      levels = { { upTo = 11, set = { th = 2.5, mh = 2, ranged = 4 } } } },
    { id = 254, name = { enUS = "Marksmanship", trTR = "Nişancılık" }, wants = { ranged = true },
      w = { agi = 1, rap = 0.45, int = 0.35, sta = 0.4, str = 0.05, ap = 0.1, spi = 0.1, crit = 10, hit = 11, mp5 = 1,
            armor = 0.015, ranged = 6.5, th = 0.4, mh = 0.3, oh = 0.2 },
      levels = { { upTo = 11, set = { th = 2.5, mh = 2, ranged = 4 } } } },
    { id = 255, name = { enUS = "Survival", trTR = "Hayatta Kalma" }, wants = { ranged = true },
      w = { agi = 1, rap = 0.4, int = 0.3, sta = 0.5, str = 0.1, ap = 0.2, spi = 0.1, crit = 10, hit = 10, mp5 = 0.9,
            armor = 0.02, ranged = 6, th = 1, mh = 0.6, oh = 0.3 },
      levels = { { upTo = 11, set = { th = 2.5, mh = 2, ranged = 4 } } } },
  },
}

SW.ROGUE = {
  default = 260,
  specs = {
    { id = 259, name = { enUS = "Assassination", trTR = "Suikast" }, wants = { dualWield = true },
      w = { agi = 1, str = 0.55, ap = 0.55, sta = 0.45, crit = 10, hit = 10, armor = 0.02, mh = 7, oh = 3.5, ranged = 0.3 } },
    { id = 260, name = { enUS = "Combat", trTR = "Dövüş" }, wants = { dualWield = true },
      w = { agi = 1, str = 0.55, ap = 0.55, sta = 0.45, crit = 9, hit = 11, armor = 0.02, mh = 7.5, oh = 4, ranged = 0.3 } },
    { id = 261, name = { enUS = "Subtlety", trTR = "Gizlilik" }, wants = { dualWield = true },
      w = { agi = 1, str = 0.55, ap = 0.55, sta = 0.45, crit = 9, hit = 10, armor = 0.02, mh = 7, oh = 3.5, ranged = 0.3 } },
  },
}

SW.PRIEST = {
  default = 258,
  specs = {
    { id = 256, name = { enUS = "Discipline", trTR = "Disiplin" }, wants = { wand = true },
      w = { int = 1, spi = 0.8, sta = 0.45, heal = 0.8, sp = 0.5, spellcrit = 6, spellhit = 6, mp5 = 1.8, armor = 0.01,
            wand = 2.5, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { spi = 1, wand = 4 } } } },
    { id = 257, name = { enUS = "Holy", trTR = "Kutsal" }, wants = { wand = true },
      w = { int = 1, spi = 0.8, sta = 0.4, heal = 0.9, sp = 0.4, spellcrit = 6, spellhit = 5, mp5 = 1.8, armor = 0.01,
            wand = 2.5, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { spi = 1, wand = 4 } } } },
    { id = 258, name = { enUS = "Shadow", trTR = "Gölge" }, wants = { wand = true },
      w = { int = 1, spi = 0.8, sta = 0.55, sp = 1, heal = 0.15, spellcrit = 4, spellhit = 10, mp5 = 1.5, armor = 0.01,
            wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { spi = 1, wand = 4 } } } },
  },
}

SW.SHAMAN = {
  default = 263,
  specs = {
    { id = 262, name = { enUS = "Elemental", trTR = "Element" }, wants = { shield = true },
      w = { int = 1, sp = 1, sta = 0.5, spi = 0.4, str = 0.15, spellcrit = 8, spellhit = 10, mp5 = 1.6, armor = 0.015,
            th = 0.8, mh = 0.8, shield = 3 },
      levels = { { upTo = 20, set = { str = 0.5, th = 3, mh = 2.5 } } } },
    { id = 263, name = { enUS = "Enhancement", trTR = "Güçlendirme" }, wants = { twoHand = true },
      w = { str = 1, agi = 0.55, sta = 0.5, int = 0.4, spi = 0.15, ap = 0.5, sp = 0.2, crit = 11, hit = 10, mp5 = 0.8,
            armor = 0.025, th = 7, mh = 5.5, shield = 1 },
      levels = { { upTo = 19, set = { shield = 2 } } } },
    { id = 264, name = { enUS = "Restoration", trTR = "Onarım" }, wants = { shield = true },
      w = { int = 1, heal = 0.9, sp = 0.3, mp5 = 2, spi = 0.4, sta = 0.4, str = 0.15, spellcrit = 6, armor = 0.015,
            th = 0.5, mh = 0.5, shield = 4 },
      levels = { { upTo = 20, set = { str = 0.5, th = 3, mh = 2.5 } } } },
  },
}

SW.MAGE = {
  default = 64,
  specs = {
    { id = 62, name = { enUS = "Arcane", trTR = "Gizem" }, wants = { wand = true },
      w = { int = 1, spi = 0.7, sta = 0.5, sp = 1, spellcrit = 7, spellhit = 10, mp5 = 1.4, armor = 0.01, wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { spi = 0.85, wand = 4 } } } },
    { id = 63, name = { enUS = "Fire", trTR = "Ateş" }, wants = { wand = true },
      w = { int = 1, spi = 0.6, sta = 0.5, sp = 1.1, spellcrit = 9, spellhit = 11, mp5 = 1.3, armor = 0.01, wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { spi = 0.8, wand = 4 } } } },
    { id = 64, name = { enUS = "Frost", trTR = "Buz" }, wants = { wand = true },
      w = { int = 1, spi = 0.6, sta = 0.55, sp = 1, spellcrit = 6, spellhit = 10, mp5 = 1.3, armor = 0.012, wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { spi = 0.8, wand = 4 } } } },
  },
}

SW.WARLOCK = {
  default = 265,
  specs = {
    { id = 265, name = { enUS = "Affliction", trTR = "Lanet" }, wants = { wand = true },
      w = { sta = 1, int = 0.8, spi = 0.3, sp = 1.1, spellcrit = 3, spellhit = 10, mp5 = 1, armor = 0.012, wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { wand = 4, spi = 0.4 } } } },
    { id = 266, name = { enUS = "Demonology", trTR = "Şeytan Bilimi" }, wants = { wand = true },
      w = { sta = 1, int = 0.75, spi = 0.15, sp = 1, spellcrit = 3, spellhit = 9, mp5 = 1, armor = 0.012, wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { wand = 4, spi = 0.3 } } } },
    { id = 267, name = { enUS = "Destruction", trTR = "Yıkım" }, wants = { wand = true },
      w = { sta = 0.8, int = 0.9, spi = 0.3, sp = 1.2, spellcrit = 9, spellhit = 10, mp5 = 1, armor = 0.012, wand = 3, th = 0.1, mh = 0.1 },
      levels = { { upTo = 20, set = { wand = 4, spi = 0.4 } } } },
  },
}

SW.DRUID = {
  default = 103,
  specs = {
    { id = 102, name = { enUS = "Balance", trTR = "Denge" }, wants = {},
      w = { int = 1, sp = 1, spi = 0.6, sta = 0.5, spellcrit = 7, spellhit = 10, mp5 = 1.4, armor = 0.02, str = 0.1,
            th = 0.3, mh = 0.3 },
      levels = { { upTo = 15, set = { str = 0.5, th = 2.5, mh = 2 } } } },
    { id = 103, name = { enUS = "Feral Combat", trTR = "Vahşi Dövüş" }, wants = {},
      w = { str = 1, agi = 0.9, sta = 0.55, ap = 0.5, int = 0.2, spi = 0.15, crit = 10, hit = 10, armor = 0.03, defense = 0.3,
            th = 0.3, mh = 0.3 },
      levels = { { upTo = 15, set = { th = 3, mh = 2.5, int = 0.4 } } } },
    { id = 105, name = { enUS = "Restoration", trTR = "Onarım" }, wants = {},
      w = { int = 1, heal = 0.9, sp = 0.3, spi = 0.7, mp5 = 1.8, sta = 0.4, spellcrit = 5, armor = 0.015, str = 0.1,
            th = 0.3, mh = 0.3 },
      levels = { { upTo = 15, set = { str = 0.5, th = 2.5, mh = 2 } } } },
  },
}

-- Retail uzmanlik kimligi -> bu tablodaki kimlik (Retail druidinde Guardian ayri: Feral'e esler).
SW.ALIASES = { [104] = 103 }

return "OK"
