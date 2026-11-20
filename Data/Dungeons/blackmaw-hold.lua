local _, ns = ...
ns.DungeonExtra("blackmaw-hold", {
  quests = {
    { id = 92343, name = "Get to the Roots of It", level = 55, req = 45, side = "Horde", giver = "Nara Wildmane, Elder Rise, Thunder Bluff (75.7, 31.6)", turnin = "Nara Wildmane, Elder Rise, Thunder Bluff (75.7, 31.6)", note = { enUS = "Find out what corrupts the Blackmaw and report to Nara Wildmane.", trTR = "Blackmaw'ı neyin bozduğunu bul ve Nara Wildmane'e bildir." } },
    { id = 92344, name = "Get to the Roots of It", level = 55, req = 45, side = "Alliance", giver = "Mathrengyl Bearwalker, Cenarion Enclave, Darnassus (35.4, 8.4)", turnin = "Mathrengyl Bearwalker, Cenarion Enclave, Darnassus (35.4, 8.4)", note = { enUS = "Find out what corrupts the Blackmaw and report to Mathrengyl Bearwalker.", trTR = "Blackmaw'ı neyin bozduğunu bul ve Mathrengyl Bearwalker'a bildir." } },
    { id = 97173, name = "Blackmaw Magic", level = 59, req = 52, side = "Alliance", giver = "Archmage Timear, Dalaran, Alterac Mountains (15.4, 74.1)", turnin = "Archmage Timear, Dalaran, Alterac Mountains (15.4, 74.1)", note = { enUS = "Bring Archmage Timear a sample of the furbolgs' magic from Blackmaw Hold.", trTR = "Archmage Timear'a Blackmaw Hold'daki furbolg büyüsünden bir örnek getir." } },
    { id = 97198, name = "Blackmaw Magic", level = 59, req = 52, side = "Horde", giver = "Muln Earthfury, Mulgore (33.4, 22.6)", note = { enUS = "Bring Muln Earthfury a sample of the furbolgs' magic from Blackmaw Hold.", trTR = "Muln Earthfury'ye Blackmaw Hold'daki furbolg büyüsünden bir örnek getir." }, verify = true },
    { id = 92069, name = "Claws That Rend, Tusks that Gore", level = 58, giver = "Ogtinc, Azshara (42.4, 42.6)", turnin = "Ogtinc, Azshara (42.4, 42.6)", note = { enUS = "Hunt the beasts Ogtinc names inside Blackmaw Hold.", trTR = "Ogtinc'in söylediği hayvanları Blackmaw Hold'un içinde avla." } },
    { id = 92070, name = "A Lost Memento", level = 55, giver = "Starts from Feathered Charm Necklace (dropped by Legashi satyrs)", turnin = "Unele, Azshara (43.0, 18.2)", note = { enUS = "Return the feathered necklace to its owner, Unele.", trTR = "Tüylü kolyeyi sahibi Unele'ye geri götür." }, verify = true },
    { id = 92066, name = "The Twin Bears", level = 55, req = 55, giver = "Lorekeeper Nok, Azshara (41.4, 20.0)", turnin = "Lorekeeper Nok, Azshara (41.4, 20.0)", note = { enUS = "Deal with the twin bears in Blackmaw Hold for Lorekeeper Nok.", trTR = "Lorekeeper Nok için Blackmaw Hold'daki ikiz ayıların icabına bak." }, verify = true },
    { id = 97327, name = "Blackmaw Pouches", level = 60, req = 60, giver = "Ekkal, Azshara (42.0, 38.9)", turnin = "Ekkal, Azshara (42.0, 38.9)", note = { enUS = "Bring Ekkal the pouches the Blackmaw carry.", trTR = "Ekkal'a Blackmaw'ın taşıdığı keseleri getir." } },
  },
  loot = {
    { boss = "Withermaw", items = {
      { id = 280062, n = "Cloak of the Fleshborer", q = 3, s = "Back", c = "123456789" },
      { id = 280063, n = "Bloodfur Bulwark", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 280064, n = "Withering Grips", q = 3, s = "Hands, Leather", c = "49", a = "36" },
    } },
    { boss = "Impaan the Imprisoner", items = {
      { id = 280056, n = "Flameslash Crescent", q = 3, s = "Two-Hand, Axe", c = "1236" },
      { id = 280057, n = "Robes of Dark Summons", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 280058, n = "Impish Chain Hood", q = 3, s = "Head, Mail", c = "36", a = "12" },
    } },
    { boss = "Elder Shaman Bloodmane", items = {
      { id = 280068, n = "Bloody Claws of Attack", q = 3, s = "One-Hand, Fist Weapon", c = "14693" },
      { id = 280070, n = "Veilpiercer Girdle", q = 3, s = "Waist, Leather", c = "49", a = "36" },
      { id = 280069, n = "Shamanic Wristguards", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
    } },
    { boss = "Bonesnout the Unbroken", items = {
      { id = 280059, n = "Tuskblade Halberd", q = 3, s = "Two-Hand, Polearm", c = "1239" },
      { id = 280060, n = "Lucky Shovelnose Tuft", q = 3, s = "Trinket", c = "123456789" },
      { id = 280061, n = "Spike Crested Bracers", q = 3, s = "Wrist, Plate", c = "12" },
    } },
    { boss = "Varrox Bleakhoof", items = {
      { id = 280074, n = "Scalding Flamehoof", q = 3, s = "Trinket", c = "123456789" },
      { id = 280075, n = "Bleak Eye Shoulderplates", q = 3, s = "Shoulder, Plate", c = "12" },
      { id = 280076, n = "Horns of Varrox", q = 3, s = "Head, Leather", c = "49", a = "36" },
    } },
    { boss = "Blackmaw Behemoth", items = {
      { id = 280065, n = "Behemoth Bones", q = 3, s = "Trinket", c = "123456789" },
      { id = 280066, n = "Trousers of the Ebon Giant", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
      { id = 280067, n = "Blackmaw Chain Belt", q = 3, s = "Waist, Mail", c = "36", a = "12" },
    } },
    { boss = "Unbound Spirit", items = {
      { id = 280071, n = "Flamebreak Talisman", q = 3, s = "Trinket", c = "123456789" },
      { id = 280072, n = "Cowl of Dark Ambition", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 280073, n = "Burnished Pridescales", q = 3, s = "Chest, Plate", c = "12" },
    } },
    { boss = "Moontouched Wanderer", items = {
      { id = 280079, n = "Lunarlight Robe", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 280080, n = "Claymore of Two Moons", q = 3, s = "Two-Hand, Sword", c = "124378" },
    } },
    { boss = "Gortek the Apprentice", items = {
      { id = 280077, n = "Fist of Revelation", q = 3, s = "One-Hand, Fist Weapon", c = "14693" },
    } },
    { boss = "Tunnelweb Matriarch", items = {
      { id = 280085, n = "Tunnelweb Pincer", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 280086, n = "Octofinger Gauntlets", q = 3, s = "Hands, Plate", c = "12" },
    } },
    { boss = "Trash Drops", items = {
      { id = 287028, n = "Tormented Cuffs", q = 3, s = "Wrist, Cloth", c = "578", a = "926" },
      { id = 287029, n = "Nature Guardian's Legguards", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 287030, n = "Blackmaw Bindings", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 287031, n = "Spearfisher's Waders", q = 3, s = "Legs, Mail", c = "36", a = "12" },
      { id = 287032, n = "Den Champion's Binding", q = 3, s = "Waist, Plate", c = "12" },
      { id = 287033, n = "Furbolg Berserker's Boots", q = 3, s = "Feet, Plate", c = "12" },
      { id = 287034, n = "Grove Subjugator's Blade", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 287035, n = "Demon Worshipper's Necklace", q = 3, s = "Neck", c = "123456789" },
      { id = 287036, n = "Satyr's Touch", q = 3, s = "Ranged, Wand", c = "578" },
    } },
  },
})
