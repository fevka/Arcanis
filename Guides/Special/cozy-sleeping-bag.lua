-- Arcanis: Cozy Sleeping Bag (ozel gorev serisi, elle yazildi).
-- Yapi (quest ID, nesne, koordinat) Forever veri setinden ve rota verisinden; metinler ozgun.
-- special = true: seviye onerisi ve rehber zincirine girmez, Guide Browser > Special'da listelenir.
local _, ns = ...

local DESC = {
  enUS = "A hidden trail of notes and caches across both continents. Rewards: Old Toolbox (12-slot bag) on the way, "
    .. "and the Cozy Sleeping Bag: a bedroll you lay down anywhere for rested XP and a stacking experience bonus.",
  trTR = "Iki kitaya yayilmis gizli notlar ve saklanmis cantalar. Odul: yolda Old Toolbox (12 yuvali canta), "
    .. "sonunda Cozy Sleeping Bag: her yere serilen, rested XP ve ust uste binen deneyim bonusu veren yatak.",
}
local HORDE_DESC = {
  enUS = DESC.enUS .. " The Horde route runs through Westfall and Loch Modan: level 30 or more is much safer.",
  trTR = DESC.trTR .. " Horde rotasi Westfall ve Loch Modan'dan gecer: 30 ve ustu seviye cok daha guvenli.",
}

local T = {
  farm = { enUS = "Burned-Out Remains in the ruined farmhouse.", trTR = "Yikik ciftlik evindeki Burned-Out Remains." },
  tower = { enUS = "Burned-Out Remains at the foot of the burnt watchtower.", trTR = "Yanmis gozetleme kulesinin dibindeki Burned-Out Remains." },
  litter = { enUS = "Pocket Litter at the camp on the ledge. Take the hill path up from the east; the camp is not reachable from below.",
    trTR = "Cikintidaki kampta Pocket Litter. Yamac yolundan doguyla cik; kampa asagidan ulasilmaz." },
  -- Rekindle (80001) ayri adim degil: Simple Wood odul secimine bagli, rotayi bekletmesin
  fire = { enUS = "Pocket Litter again. If you have Simple Wood and Flint and Tinder, you can also light the cold firepit beside it (Rekindle, optional).",
    trTR = "Yine Pocket Litter. Simple Wood ve Flint and Tinder'in varsa yanindaki sonmus ates cukurunu da yakabilirsin (Rekindle, istege bagli)." },
  mound = { enUS = "Mound of Dirt on the slope just north, watch your step.", trTR = "Hemen kuzeydeki yamacta Mound of Dirt; dusmemeye dikkat." },
  dam = { enUS = "Carved Figurine on the lower ledge of the dam.", trTR = "Barajin alt cikintisindaki Carved Figurine." },
  wall = { enUS = "Messenger Bag on top of Thoradin's Wall.", trTR = "Thoradin's Wall'un ustundeki Messenger Bag." },
  satchel = { enUS = "Hastily Rolled-Up Satchel beside the bag.", trTR = "Cantanin yanindaki Hastily Rolled-Up Satchel." },
}

-- Yollar oyunun arazisinden (tools/build_trail.py): yokus basi oyunda olculdu (50.54, 52.56), kampa kivrimlariyla;
-- barajin kavisi boyunca cikintiya (--drop 25). Mound of Dirt inisi ve Thoradin's Wall (arabaya tirmanma, M2)
-- arazi izgarasinda bulunamadi: eski noktalar.
local HILL = { { 50.54, 52.56 }, { 50.36, 53.23 }, { 49.91, 53.75 }, { 49.24, 53.90 }, { 48.01, 53.93 }, { 46.78, 53.93 },
  { 46.06, 53.87 }, { 45.67, 53.72 }, { 44.44, 53.69 }, { 43.54, 53.87 }, { 42.31, 53.90 }, { 41.60, 53.84 } }
local DAM = { { 41.07, 12.53 }, { 41.68, 12.29 }, { 43.06, 10.87 }, { 43.79, 11.04 }, { 45.63, 13.05 }, { 47.30, 14.02 },
  { 48.86, 14.02 } }

ns.Guides:Register{
  id = "alliance-cozy-sleeping-bag", title = "Cozy Sleeping Bag", faction = "Alliance", special = true,
  description = DESC,
  minLevel = 14, maxLevel = 60,
  steps = {
    { type = "accept", quest = 79008, name = "...and that note you found", zone = "Westfall", x = 37.33, y = 50.74, tip = T.farm },
    { type = "turnin", quest = 79008, name = "...and that note you found", zone = "The Barrens", x = 46.35, y = 74.0, tip = T.tower },
    { type = "accept", quest = 79192, name = "Stepping Stones", zone = "The Barrens", x = 46.37, y = 73.9 },
    { type = "turnin", quest = 79192, name = "Stepping Stones", zone = "Stonetalon Mountains", x = 40.74, y = 52.56, path = HILL, tip = T.litter },
    { type = "accept", quest = 79980, name = "Scramble", zone = "Stonetalon Mountains", x = 40.74, y = 52.56, tip = T.fire },
    { type = "turnin", quest = 79980, name = "Scramble", zone = "Stonetalon Mountains", x = 39.61, y = 49.77, path = { { 40.18, 50.79 } }, tip = T.mound },
    { type = "accept", quest = 79974, name = "Wet Job", zone = "Stonetalon Mountains", x = 39.61, y = 49.77 },
    { type = "turnin", quest = 79974, name = "Wet Job", zone = "Loch Modan", x = 49.48, y = 12.85, path = DAM, tip = T.dam },
    { type = "accept", quest = 79975, name = "Eagle's Fist", zone = "Loch Modan", x = 49.48, y = 12.85 },
    { type = "turnin", quest = 79975, name = "Eagle's Fist", zone = "Arathi Highlands", x = 22.46, y = 24.11, path = { { 24.13, 21.45 } }, tip = T.wall },
    { type = "accept", quest = 79976, name = "This Must Be The Place", zone = "Arathi Highlands", x = 22.46, y = 24.11 },
    { type = "turnin", quest = 79976, name = "This Must Be The Place", zone = "Arathi Highlands", x = 22.46, y = 24.11, tip = T.satchel },
  },
}

ns.Guides:Register{
  id = "horde-cozy-sleeping-bag", title = "Cozy Sleeping Bag", faction = "Horde", special = true,
  description = HORDE_DESC,
  minLevel = 14, maxLevel = 60,
  steps = {
    { type = "accept", quest = 79007, name = "...and that note you found", zone = "The Barrens", x = 46.36, y = 73.9, tip = T.tower },
    { type = "turnin", quest = 79007, name = "...and that note you found", zone = "Westfall", x = 37.41, y = 50.7, tip = T.farm },
    { type = "accept", quest = 79192, name = "Stepping Stones", zone = "Westfall", x = 37.41, y = 50.7 },
    { type = "turnin", quest = 79192, name = "Stepping Stones", zone = "Stonetalon Mountains", x = 40.73, y = 52.58, path = HILL, tip = T.litter },
    { type = "accept", quest = 79980, name = "Scramble", zone = "Stonetalon Mountains", x = 40.73, y = 52.58, tip = T.fire },
    { type = "turnin", quest = 79980, name = "Scramble", zone = "Stonetalon Mountains", x = 39.61, y = 49.78, path = { { 40.19, 50.8 } }, tip = T.mound },
    { type = "accept", quest = 79974, name = "Wet Job", zone = "Stonetalon Mountains", x = 39.61, y = 49.78 },
    { type = "turnin", quest = 79974, name = "Wet Job", zone = "Loch Modan", x = 49.45, y = 12.67, path = DAM, tip = T.dam },
    { type = "accept", quest = 79975, name = "Eagle's Fist", zone = "Loch Modan", x = 49.45, y = 12.67 },
    { type = "turnin", quest = 79975, name = "Eagle's Fist", zone = "Arathi Highlands", x = 22.47, y = 24.13, path = { { 24.13, 21.47 } }, tip = T.wall },
    { type = "accept", quest = 79976, name = "This Must Be The Place", zone = "Arathi Highlands", x = 22.47, y = 24.13 },
    { type = "turnin", quest = 79976, name = "This Must Be The Place", zone = "Arathi Highlands", x = 22.47, y = 24.13, tip = T.satchel },
  },
}
