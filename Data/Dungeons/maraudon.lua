local _, ns = ...
ns.DungeonExtra("maraudon", {
  quests = {
    { id = 7066, name = "Seed of Life", level = 51, req = 45, giver = "Zaetar's Spirit, middle of the ring after Princess Theradras, Maraudon", turnin = "Keeper Remulos, Moonglade (36.2, 41.8)", note = { enUS = "Kill Princess Theradras, then take the Seed of Life to Keeper Remulos in Moonglade.", trTR = "Princess Theradras'ı öldür, sonra Seed of Life'ı Moonglade'deki Keeper Remulos'a götür." } },
    { id = 7067, name = "The Pariah's Instructions", level = 48, req = 39, giver = "Centaur Pariah, south of Mannoroc Coven, Desolace (50.4, 86.7)", turnin = "Centaur Pariah, south of Mannoroc Coven, Desolace (50.4, 86.7)", note = { enUS = "Read the Pariah's Instructions, get the Amulet of Union in Maraudon and return it to the Centaur Pariah. He patrols the area.", trTR = "Pariah's Instructions'ı oku, Maraudon'da Amulet of Union'ı al ve Centaur Pariah'a geri götür. Bölgede devriye gezer." } },
    { id = 7068, name = "Shadowshard Fragments", level = 42, req = 38, side = "Horde", giver = "Uthel'nay, Valley of Spirits, Orgrimmar (39.2, 86.3)", turnin = "Uthel'nay, Valley of Spirits, Orgrimmar (39.2, 86.3)", note = { enUS = "Collect 10 Shadowshard Fragments in Maraudon.", trTR = "Maraudon'da 10 Shadowshard Fragments topla." } },
    { id = 7070, name = "Shadowshard Fragments", level = 42, req = 38, giver = "Archmage Tervosh, Theramore, Dustwallow Marsh (66.4, 49.3)", turnin = "Archmage Tervosh, Theramore, Dustwallow Marsh (66.4, 49.3)", note = { enUS = "Collect 10 Shadowshard Fragments in Maraudon.", trTR = "Maraudon'da 10 Shadowshard Fragments topla." } },
    { id = 7028, name = "Twisted Evils", level = 47, req = 41, giver = "Willow, southeast of Thunderaxe Fortress, Desolace (62.2, 39.6)", turnin = "Willow, southeast of Thunderaxe Fortress, Desolace (62.2, 39.6)", note = { enUS = "Collect 15 Theradric Crystal Carvings in Maraudon.", trTR = "Maraudon'da 15 Theradric Crystal Carvings topla." } },
    { id = 7029, name = "Vyletongue Corruption", level = 47, req = 41, giver = "Vark Battlescar, Shadowprey Village, Desolace (23.2, 70.3)", turnin = "Vark Battlescar, Shadowprey Village, Desolace (23.2, 70.3)", note = { enUS = "Fill the Coated Cerulean Vial at the orange crystal pool, use it on Vylestem Vines, and kill 8 Noxxious Scion.", trTR = "Coated Cerulean Vial'ı turuncu kristal havuzunda doldur, Vylestem Vines üzerinde kullan ve 8 Noxxious Scion öldür." } },
    { id = 7041, name = "Vyletongue Corruption", level = 47, req = 41, giver = "Talendria, Nijel's Point, Desolace (68.5, 8.9)", turnin = "Talendria, Nijel's Point, Desolace (68.5, 8.9)", note = { enUS = "Fill the Coated Cerulean Vial at the orange crystal pool, use it on Vylestem Vines, and kill 8 Noxxious Scion.", trTR = "Coated Cerulean Vial'ı turuncu kristal havuzunda doldur, Vylestem Vines üzerinde kullan ve 8 Noxxious Scion öldür." } },
    { id = 7044, name = "Legends of Maraudon", level = 49, req = 41, giver = "Cavindra, outside the orange entrance of Maraudon, Desolace (32.1, 64.0)", turnin = "Celebras the Redeemed, Maraudon, Maraudon", note = { enUS = "Recover the Celebrian Rod and the Celebrian Diamond, then speak with Celebras the Redeemed.", trTR = "Celebrian Rod'u ve Celebrian Diamond'ı geri al, sonra Celebras the Redeemed ile konuş." } },
    { id = 7046, name = "The Scepter of Celebras", level = 49, req = 41, giver = "Celebras the Redeemed, purple side, Maraudon", turnin = "Celebras the Redeemed, purple side, Maraudon", note = { enUS = "Assist Celebras while he creates the Scepter of Celebras, then speak with him. Requires Legends of Maraudon first.", trTR = "Celebras, Scepter of Celebras'ı yaparken ona yardım et, sonra onunla konuş. Önce Legends of Maraudon gerekir." } },
    { id = 7064, name = "Corruption of Earth and Seed", level = 51, req = 45, giver = "Selendra, south of Shadowprey Village, Desolace (26.9, 77.7)", turnin = "Selendra, south of Shadowprey Village, Desolace (26.9, 77.7)", note = { enUS = "Kill Princess Theradras in Maraudon.", trTR = "Maraudon'da Princess Theradras'ı öldür." } },
    { id = 7065, name = "Corruption of Earth and Seed", level = 51, req = 45, giver = "Keeper Marandis, Nijel's Point, Desolace (63.8, 10.7)", turnin = "Keeper Marandis, Nijel's Point, Desolace (63.8, 10.7)", note = { enUS = "Kill Princess Theradras in Maraudon.", trTR = "Maraudon'da Princess Theradras'ı öldür." } },
  },
  loot = {
    { boss = "Noxxion", items = {
      { id = 17746, n = "Noxxion's Shackles", q = 3, s = "Wrist, Plate", c = "123456789" },
      { id = 17744, n = "Heart of Noxxion", q = 3, s = "Trinket, Trinket", c = "123456789" },
      { id = 17745, n = "Noxious Shooter", q = 3, s = "Ranged, Wand", c = "578" },
    } },
    { boss = "Razorlash", items = {
      { id = 17749, n = "Phytoskin Spaulders", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 17748, n = "Vinerot Sandals", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 17750, n = "Chloromesh Girdle", q = 2, s = "Waist, Cloth", c = "578", a = "926" },
      { id = 17751, n = "Brusslehide Leggings", q = 2, s = "Legs, Leather", c = "49", a = "36" },
    } },
    { boss = "Lord Vyletongue", items = {
      { id = 17755, n = "Satyrmane Sash", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
      { id = 17754, n = "Infernal Trickster Leggings", q = 3, s = "Legs, Mail", c = "36", a = "12" },
      { id = 17752, n = "Satyr's Lash", q = 3, s = "One-Hand, Dagger", c = "14356789" },
    } },
    { boss = "Meshlok the Harvester", items = {
      { id = 17767, n = "Bloomsprout Headpiece", q = 3, s = "Head, Mail", c = "36", a = "12" },
      { id = 17741, n = "Nature's Embrace", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 17742, n = "Fungus Shroud Armor", q = 3, s = "Chest, Leather", c = "49", a = "36" },
    } },
    { boss = "Celebras the Cursed", items = {
      { id = 17740, n = "Soothsayer's Headdress", q = 3, s = "Head, Leather", c = "49", a = "36" },
      { id = 17739, n = "Grovekeeper's Drape", q = 3, s = "Back, Cloth", c = "578", a = "926" },
      { id = 17738, n = "Claw of Celebras", q = 3, s = "Off Hand, Fist Weapon", c = "14693" },
    } },
    { boss = "Landslide", items = {
      { id = 17734, n = "Helm of the Mountain", q = 3, s = "Head, Plate", c = "123456789" },
      { id = 17736, n = "Rockgrip Gauntlets", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 17737, n = "Cloud Stone", q = 3, s = "Held In Off-hand, Trinket", c = "578926" },
      { id = 17943, n = "Fist of Stone", q = 3, s = "Main Hand, Mace", c = "124695" },
    } },
    { boss = "Tinkerer Gizlock", items = {
      { id = 17718, n = "Gizlock's Hypertech Buckler", q = 3, s = "Shield, Shield", c = "123456789" },
      { id = 17717, n = "Megashot Rifle", q = 3, s = "Ranged, Gun", c = "143" },
      { id = 17719, n = "Inventor's Focal Sword", q = 3, s = "One-Hand, Sword", c = "124378" },
    } },
    { boss = "Rotgrip", items = {
      { id = 17732, n = "Rotgrip Mantle", q = 3, s = "Shoulder, Cloth", c = "578", a = "926" },
      { id = 17728, n = "Albino Crocscale Boots", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 17730, n = "Gatorbite Axe", q = 3, s = "Two-Hand, Axe", c = "1236" },
    } },
    { boss = "Princess Theradras", items = {
      { id = 17780, n = "Blade of Eternal Darkness", q = 4, s = "Main Hand, Dagger", c = "14356789" },
      { id = 17715, n = "Eye of Theradras", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 17707, n = "Gemshard Heart", q = 3, s = "Neck, Trinket", c = "123456789" },
      { id = 17714, n = "Bracers of the Stone Princess", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 17711, n = "Elemental Rockridge Leggings", q = 3, s = "Legs, Plate", c = "123456789" },
      { id = 17713, n = "Blackstone Ring", q = 3, s = "Finger, Trinket", c = "123456789" },
      { id = 17710, n = "Charstone Dirk", q = 3, s = "Main Hand, Dagger", c = "14356789" },
      { id = 17766, n = "Princess Theradras' Scepter", q = 3, s = "Two-Hand, Mace", c = "124695" },
    } },
  },
})
