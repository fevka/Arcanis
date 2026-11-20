local _, ns = ...
ns.DungeonExtra("sm-graveyard", {
  quests = {
    { id = 1048, name = "Into The Scarlet Monastery", level = 42, req = 33, side = "Horde", giver = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", turnin = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", note = { enUS = "Kill High Inquisitor Whitemane, Scarlet Commander Mograine, Herod and Houndmaster Loksey, then report to Varimathras.", trTR = "High Inquisitor Whitemane, Scarlet Commander Mograine, Herod ve Houndmaster Loksey'i öldür, sonra Varimathras'a rapor ver." } },
    { id = 1051, name = "Vorrel's Revenge", level = 33, req = 25, side = "Horde", giver = "Vorrel Sengutz, inside the Graveyard, Scarlet Monastery", turnin = "Monika Sengutz, Tarren Mill, Hillsbrad Foothills (62.7, 18.9)", note = { enUS = "Get Vorrel Sengutz's wedding ring from Nancy Vishas and return it to Monika Sengutz.", trTR = "Vorrel Sengutz'un alyansını Nancy Vishas'tan al ve Monika Sengutz'a götür." } },
    { id = 1113, name = "Hearts of Zeal", level = 33, req = 30, side = "Horde", giver = "Master Apothecary Faranell, Undercity (48.8, 69.3)", turnin = "Master Apothecary Faranell, Undercity (48.8, 69.3)", note = { enUS = "Bring 20 Hearts of Zeal from the Scarlet Monastery to Master Apothecary Faranell. Requires Going, Going, Guano! first.", trTR = "Scarlet Monastery'den Master Apothecary Faranell'e 20 Hearts of Zeal götür. Önce Going, Going, Guano! gerekir." } },
    { id = 1053, name = "In the Name of the Light", level = 40, req = 34, side = "Alliance", giver = "Raleigh the Devout, Southshore, Hillsbrad Foothills (51.5, 58.4)", turnin = "Raleigh the Devout, Southshore, Hillsbrad Foothills (51.5, 58.4)", note = { enUS = "Kill High Inquisitor Whitemane, Scarlet Commander Mograine, Herod and Houndmaster Loksey. Requires Down the Scarlet Path first.", trTR = "High Inquisitor Whitemane, Scarlet Commander Mograine, Herod ve Houndmaster Loksey'i öldür. Önce Down the Scarlet Path gerekir." } },
  },
  loot = {
    { boss = "Interrogator Vishas", items = {
      { id = 7682, n = "Torturing Poker", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 7683, n = "Bloody Brass Knuckles", q = 3, s = "One-Hand, Fist Weapon", c = "14693" },
      { id = 274290, n = "Painwalker Buckler", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 252513, n = "Trapper's Leather Helm", q = 3, s = "Head, Leather", c = "49", a = "36" },
    } },
    { boss = "Azshir the Sleepless", items = {
      { id = 7709, n = "Blighted Leggings", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
      { id = 7708, n = "Necrotic Wand", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 7731, n = "Ghostshard Talisman", q = 3, s = "Neck", c = "123456789" },
    } },
    { boss = "Fallen Champion", items = {
      { id = 7691, n = "Embalmed Shroud", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 7690, n = "Ebon Vise", q = 3, s = "Hands, Leather", c = "49", a = "36" },
      { id = 7689, n = "Morbid Dawn", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 252513, n = "Trapper's Leather Helm", q = 3, s = "Head, Leather", c = "49", a = "36" },
    } },
    { boss = "Ironspine", items = {
      { id = 7688, n = "Ironspine's Ribcage", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 7687, n = "Ironspine's Fist", q = 3, s = "One-Hand, Mace", c = "124695" },
      { id = 7686, n = "Ironspine's Eye", q = 3, s = "Finger", c = "123456789" },
    } },
    { boss = "Bloodmage Thalnos", items = {
      { id = 7685, n = "Orb of the Forgotten Seer", q = 3, s = "Held In Off-hand", c = "578926" },
      { id = 7684, n = "Bloodmage Mantle", q = 3, s = "Shoulder, Cloth", c = "578", a = "926" },
      { id = 274291, n = "Polished Skullcap", q = 3, s = "Head, Mail", c = "36", a = "12" },
      { id = 252822, n = "Pattern: Defender's Leather Kilt", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Trash Drops", items = {
      { id = 10328, n = "Scarlet Chestpiece", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 10329, n = "Scarlet Belt", q = 3, s = "Waist, Mail", c = "36", a = "12" },
      { id = 10330, n = "Scarlet Leggings", q = 3, s = "Legs, Mail", c = "36", a = "12" },
      { id = 10331, n = "Scarlet Gauntlets", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 10333, n = "Scarlet Wristguards", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 10332, n = "Scarlet Boots", q = 3, s = "Feet, Mail", c = "36", a = "12" },
      { id = 5819, n = "Sunblaze Coif", q = 3, s = "Head, Mail", c = "36", a = "12" },
      { id = 7730, n = "Cobalt Crusher", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 7761, n = "Steelclaw Reaver", q = 3, s = "Main Hand, Axe", c = "1236" },
      { id = 7787, n = "Resplendent Guardian", q = 3, s = "Off Hand, Shield", c = "126" },
    } },
  },
})
