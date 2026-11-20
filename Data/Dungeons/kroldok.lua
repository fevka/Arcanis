local _, ns = ...
ns.DungeonExtra("kroldok", {
  quests = {
    { id = 94973, name = "Krol'dok Moulding", level = 41, req = 38, side = "Horde", giver = "Starts from Krol'dok Moulding (drops inside Krol'dok Stronghold)", turnin = "Kreza Darkthorn, Rog'mar, Riverglades (59.9, 46.0)", note = { enUS = "The mould drops inside the stronghold; ask in Rog'mar who knows about it.", trTR = "Kalıp kalenin içinde düşer; Rog'mar'da onu bilen birini bul." }, verify = true },
    { id = 94974, name = "Key Ingredients", level = 41, req = 38, side = "Horde", giver = "Kreza Darkthorn, Rog'mar, Riverglades (59.9, 46.0)", turnin = "Kreza Darkthorn, Rog'mar, Riverglades (59.9, 46.0)", note = { enUS = "Gather what Kreza Darkthorn needs to cast a key from the Krol'dok mould.", trTR = "Kreza Darkthorn'un Krol'dok kalıbından anahtar dökmesi için gerekenleri topla." } },
    { id = 94980, name = "Krol'dok Moulding", level = 41, req = 38, side = "Alliance", giver = "Starts from Krol'dok Moulding (drops inside Krol'dok Stronghold)", turnin = "Alphonse Dumas, Farholde Keep, Riverglades (64.5, 82.0)", note = { enUS = "The mould drops inside the stronghold; ask in Farholde Keep who knows about it.", trTR = "Kalıp kalenin içinde düşer; Farholde Keep'te onu bilen birini bul." }, verify = true },
    { id = 94981, name = "Key Ingredients", level = 41, req = 38, side = "Alliance", giver = "Alphonse Dumas, Farholde Keep, Riverglades (64.5, 82.0)", turnin = "Alphonse Dumas, Farholde Keep, Riverglades (64.5, 82.0)", note = { enUS = "Gather what Alphonse Dumas needs to cast a key from the Krol'dok mould.", trTR = "Alphonse Dumas'ın Krol'dok kalıbından anahtar dökmesi için gerekenleri topla." } },
    { id = 94975, name = "A Token of Vengeance", level = 42, req = 38, side = "Horde", giver = "Da'grosh, Riverglades (33.5, 37.9)", turnin = "Da'grosh, Riverglades (33.5, 37.9)", note = { enUS = "Bring Da'grosh proof of vengeance from inside Krol'dok Stronghold.", trTR = "Krol'dok Stronghold'un içinden Da'grosh'a intikamın kanıtını getir." }, verify = true },
    { id = 94983, name = "Twilight Mementos", level = 42, req = 38, side = "Alliance", giver = "Sergeant Riftan, Riverglades (30.7, 49.1)", turnin = "Sergeant Riftan, Riverglades (30.7, 49.1)", note = { enUS = "Collect 8 Cultist Bangles from the Twilight's Hammer in the stronghold.", trTR = "Kaledeki Twilight's Hammer'dan 8 Cultist Bangle topla." } },
    { id = 94998, name = "Curios of Curiosity", level = 42, req = 38, side = "Alliance", giver = "Ashe Amberhall, Farholde Keep, Riverglades (66.8, 81.1)", turnin = "Melanie Sable, Farholde Keep, Riverglades (66.2, 83.4)", note = { enUS = "Bring curios from the stronghold to Melanie Sable in Farholde Keep.", trTR = "Kaleden topladığın tuhaf eşyaları Farholde Keep'teki Melanie Sable'a götür." } },
    { id = 94972, name = "Tome of Twilight", level = 44, req = 39, side = "Horde", giver = "Tran'gul, Rog'mar, Riverglades (59.5, 44.0)", turnin = "Tran'gul, Rog'mar, Riverglades (59.5, 44.0)", note = { enUS = "Recover the Tome of Twilight from Twilight Commander Zarmok.", trTR = "Tome of Twilight'ı Twilight Commander Zarmok'tan geri al." } },
    { id = 94984, name = "Tome of Twilight", level = 44, req = 39, side = "Alliance", giver = "Ashe Amberhall, Farholde Keep, Riverglades (66.8, 81.1)", turnin = "Ashe Amberhall, Farholde Keep, Riverglades (66.8, 81.1)", note = { enUS = "Recover the Tome of Twilight from Twilight Commander Zarmok.", trTR = "Tome of Twilight'ı Twilight Commander Zarmok'tan geri al." } },
    { id = 94968, name = "Eye of Mugg", level = 45, req = 40, side = "Horde", giver = "Krom'rosh, Rog'mar, Riverglades (59.4, 45.6)", turnin = "Krom'rosh, Rog'mar, Riverglades (59.4, 45.6)", note = { enUS = "Kill Overlord Mugg and bring back his eye.", trTR = "Overlord Mugg'ı öldür ve gözünü getir." } },
    { id = 94982, name = "Eye of Mugg", level = 45, req = 40, side = "Alliance", giver = "Demar Brant, Farholde Keep, Riverglades (66.7, 81.0)", turnin = "Demar Brant, Farholde Keep, Riverglades (66.7, 81.0)", note = { enUS = "Kill Overlord Mugg and bring back his eye.", trTR = "Overlord Mugg'ı öldür ve gözünü getir." } },
    { id = 96771, name = "Vengeance of the Highborne", level = 45, req = 37, side = "Alliance", giver = "Ranath Nightstride, Dalaran, Alterac Mountains (17.8, 66.0)", turnin = "Ranath Nightstride, Dalaran, Alterac Mountains (17.8, 66.0)", note = { enUS = "Ranath Nightstride in Dalaran wants revenge on someone inside Krol'dok Stronghold.", trTR = "Dalaran'daki Ranath Nightstride, Krol'dok Stronghold'un içindeki birinden intikam istiyor." }, verify = true },
  },
  loot = {
    { boss = "Slavecrusher Grox", items = {
      { id = 274996, n = "Resistance Breaker Spaulder", q = 3, s = "Shoulder, Mail", c = "36", a = "12" },
      { id = 274995, n = "Slavecrusher Scepter", q = 3, s = "One-Hand, Mace", c = "124695" },
      { id = 274997, n = "Chain of Binding", q = 3, s = "Waist, Mail", c = "36", a = "12" },
    } },
    { boss = "Twilight Commander Zarmok", items = {
      { id = 274998, n = "Shadowlight Athame", q = 3, s = "Main Hand, Dagger", c = "14356789" },
      { id = 274999, n = "Shadecaster's Leggings", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
      { id = 275000, n = "Zarmok's Plated Signet", q = 3, s = "Finger", c = "123456789" },
    } },
    { boss = "War Handler Ashka", items = {
      { id = 275001, n = "Bloodied Gutslicer", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 275002, n = "War Handler's Gaze", q = 3, s = "Head, Leather", c = "49", a = "36" },
      { id = 275003, n = "Worgbinder's Treads", q = 3, s = "Feet, Plate", c = "12" },
    } },
    { boss = "Nar'gurk", items = {
      { id = 275004, n = "Chain of the Corruptor", q = 3, s = "Neck", c = "123456789" },
      { id = 275005, n = "Krol'dok Warplate Chest", q = 3, s = "Chest, Plate", c = "12" },
      { id = 275006, n = "Krol'dok Warplate Helmet", q = 3, s = "Head, Plate", c = "12" },
    } },
    { boss = "Overlord Mugg", items = {
      { id = 275009, n = "Emblem of Slamming", q = 3, s = "Trinket", c = "123456789" },
      { id = 275007, n = "Mugg's Jabber", q = 3, s = "One-Hand, Fist Weapon", c = "14693" },
      { id = 275008, n = "Mugg's Crosser", q = 3, s = "One-Hand, Fist Weapon", c = "14693" },
      { id = 275010, n = "Strongly Scented Hood", q = 3, s = "Head, Cloth", c = "578", a = "926" },
    } },
    { boss = "Bossman Toof", items = {
      { id = 286429, n = "Big-Belly Belt", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
      { id = 286428, n = "Band of Bossman", q = 3, s = "Finger", c = "123456789" },
      { id = 286430, n = "Toofbreaker", q = 3, s = "One-Hand, Mace", c = "124695" },
    } },
    { boss = "Kroog", items = {
      { id = 279857, n = "Kroog's Backscratcher", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 279863, n = "Black Horn Necklace", q = 3, s = "Neck", c = "123456789" },
    } },
    { boss = "Trash Drops", items = {
      { id = 287007, n = "Stretched Footpads", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 287008, n = "Ogre Magi's Mantle", q = 3, s = "Shoulder, Cloth", c = "578", a = "926" },
      { id = 287009, n = "Twilight Enforcer's Legs", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 287010, n = "Outrider's Gloves", q = 3, s = "Hands, Leather", c = "49", a = "36" },
      { id = 287011, n = "Guise of Battle", q = 3, s = "Head, Mail", c = "36", a = "12" },
      { id = 287012, n = "Krol'dok Warplate Gauntlets", q = 3, s = "Hands, Plate", c = "12" },
      { id = 287013, n = "Krol'dok Warplate Legplates", q = 3, s = "Legs, Plate", c = "12" },
      { id = 287014, n = "Krol'dok Warplate Pauldrons", q = 3, s = "Shoulder, Plate", c = "12" },
      { id = 287015, n = "Supreme Smasher", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 287016, n = "Shadow-Seer Orb", q = 3, s = "Held In Off-hand", c = "123456789" },
    } },
  },
})
