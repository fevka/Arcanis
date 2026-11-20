-- Arcanis: yedek bolge adi -> uiMapID eslemesi.
-- Classic haritalari (1411 = Durotar ... 1458 = Undercity). Yalniz Zones:Resolve adi bulamazsa kullanilir.
-- Yanlis cikan varsa: /wf zonemap <bolge> clear ya da yeniden ata.
local _, ns = ...

ns.Zones:SetDefaults({
  -- Kitalar (rotada kita haritasina verilen nokta, ornegin Blackfathom Deeps girisi)
  ["Kalimdor"] = 1414, ["Eastern Kingdoms"] = 1415,
  -- Kalimdor
  ["Durotar"] = 1411, ["Mulgore"] = 1412, ["The Barrens"] = 1413, ["Teldrassil"] = 1438, ["Darkshore"] = 1439,
  ["Ashenvale"] = 1440, ["Thousand Needles"] = 1441, ["Stonetalon Mountains"] = 1442, ["Desolace"] = 1443,
  ["Feralas"] = 1444, ["Dustwallow Marsh"] = 1445, ["Tanaris"] = 1446, ["Azshara"] = 1447, ["Felwood"] = 1448,
  ["Un'Goro Crater"] = 1449, ["Moonglade"] = 1450, ["Silithus"] = 1451, ["Winterspring"] = 1452,
  ["Mount Hyjal"] = 2482,   -- Forever bolgesi (istemcinin UiMap tablosu; Data/MapOverlays.lua ayni kimlik)
  -- Dogu Kralliklari
  ["Alterac Mountains"] = 1416, ["Arathi Highlands"] = 1417, ["Badlands"] = 1418, ["Blasted Lands"] = 1419,
  ["Tirisfal Glades"] = 1420, ["Silverpine Forest"] = 1421, ["Western Plaguelands"] = 1422,
  ["Eastern Plaguelands"] = 1423, ["Hillsbrad Foothills"] = 1424, ["The Hinterlands"] = 1425, ["Dun Morogh"] = 1426,
  ["Searing Gorge"] = 1427, ["Burning Steppes"] = 1428, ["Elwynn Forest"] = 1429, ["Deadwind Pass"] = 1430,
  ["Duskwood"] = 1431, ["Loch Modan"] = 1432, ["Redridge Mountains"] = 1433, ["Stranglethorn Vale"] = 1434,
  ["Swamp of Sorrows"] = 1435, ["Westfall"] = 1436, ["Wetlands"] = 1437,
  -- Sehirler
  ["Stormwind City"] = 1453, ["Orgrimmar"] = 1454, ["Ironforge"] = 1455, ["Thunder Bluff"] = 1456,
  ["Darnassus"] = 1457, ["Undercity"] = 1458,
  -- WoW Forever'a ozel bolgeler
  ["Zephras Isle"] = 2521, ["Riverglades"] = 2548,
})
