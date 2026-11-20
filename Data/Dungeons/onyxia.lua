local _, ns = ...
ns.DungeonExtra("onyxia", {
  quests = {
    { id = 6502, name = "Drakefire Amulet", level = 60, req = 50, side = "Alliance", giver = "Haleh, Mazthoril, Winterspring (54.5, 51.2)", turnin = "Haleh, Mazthoril, Winterspring (54.5, 51.2)", note = { enUS = "The last step of the Alliance attunement: Haleh gives you the Drakefire Amulet.", trTR = "Alliance giriş zincirinin son adımı: Haleh sana Drakefire Amulet'i verir." } },
    { id = 6602, name = "Blood of the Black Dragon Champion", level = 60, req = 55, side = "Horde", giver = "Rexxar, Feralas (46.4, 18.2)", turnin = "Rexxar, Feralas (46.4, 18.2)", note = { enUS = "The last step of the Horde attunement: bring the champion's blood to Rexxar for the Drakefire Amulet. Rexxar walks the road between Desolace and Feralas.", trTR = "Horde giriş zincirinin son adımı: Drakefire Amulet için şampiyonun kanını Rexxar'a götür. Rexxar, Desolace ile Feralas arasındaki yolda dolaşır." } },
    { id = 7495, name = "Victory for the Alliance", level = 60, req = 60, side = "Alliance", giver = "Starts from Head of Onyxia (drops from Onyxia)", turnin = "Highlord Bolvar Fordragon, Stormwind Keep, Stormwind City (80.2, 38.4)", note = { enUS = "Take Onyxia's head to Highlord Bolvar Fordragon in Stormwind.", trTR = "Onyxia'nın kafasını Stormwind'deki Highlord Bolvar Fordragon'a götür." } },
    { id = 7490, name = "Victory for the Horde", level = 60, req = 60, side = "Horde", giver = "Starts from Head of Onyxia (drops from Onyxia)", turnin = "Thrall, Grommash Hold, Orgrimmar (31.7, 37.8)", note = { enUS = "Take Onyxia's head to Thrall in Orgrimmar.", trTR = "Onyxia'nın kafasını Orgrimmar'daki Thrall'a götür." } },
  },
  loot = {
    { boss = "Onyxia", items = {
      { id = 17064, n = "Shard of the Scale", q = 4, s = "Trinket", c = "123456789" },
      { id = 17068, n = "Deathbringer", q = 4, s = "One-Hand, Axe", c = "1236" },
      { id = 17075, n = "Vis'kag the Bloodletter", q = 4, s = "One-Hand, Sword", c = "124378" },
      { id = 17966, n = "Onyxia Hide Backpack", q = 2, s = "Bag", c = "123456789" },
      { id = 18423, n = "Head of Onyxia", q = 4, s = "Quest Item", c = "123456789" },
      { id = 18705, n = "Mature Black Dragon Sinew", q = 4, s = "Quest Item", c = "123456789" },
      { id = 21108, n = "Draconic for Dummies", q = 4, s = "Miscellaneous", c = "123456789" },
    } },
  },
})
