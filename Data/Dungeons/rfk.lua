local _, ns = ...
ns.DungeonExtra("rfk", {
  quests = {
    { id = 1221, name = "Blueleaf Tubers", level = 26, req = 20, giver = "Mebok Mizzyrix, Ratchet, Northern Barrens (62.4, 37.6)", turnin = "Mebok Mizzyrix, Ratchet, Northern Barrens (62.4, 37.6)", note = { enUS = "In Razorfen Kraul, summon a Snufflenose Gopher with the Crate with Holes and have it find 6 Blueleaf Tubers. Bring the tubers, Command Stick and Crate back.", trTR = "Razorfen Kraul'da Crate with Holes ile bir Snufflenose Gopher çağır ve 6 Blueleaf Tubers bulmasını sağla. Yumruları, Command Stick'i ve Crate'i geri getir." } },
    { id = 1142, name = "Mortality Wanes", level = 30, req = 25, side = "Alliance", giver = "Heralath Fallowbrook, Razorfen Kraul", turnin = "Treshala Fallowbrook, Darnassus (69.5, 67.8)", note = { enUS = "Find Treshala's Pendant and return it to Treshala Fallowbrook in Darnassus.", trTR = "Treshala's Pendant'ı bul ve Darnassus'taki Treshala Fallowbrook'a geri götür." } },
    { id = 1144, name = "Willix the Importer", level = 30, req = 23, giver = "Willix the Importer, Razorfen Kraul", turnin = "Willix the Importer, Razorfen Kraul", note = { enUS = "Escort Willix the Importer out of Razorfen Kraul.", trTR = "Willix the Importer'a Razorfen Kraul'dan çıkana kadar eşlik et." } },
    { id = 1109, name = "Going, Going, Guano!", level = 33, req = 30, side = "Horde", giver = "Master Apothecary Faranell, Undercity (48.8, 69.3)", turnin = "Master Apothecary Faranell, Undercity (48.8, 69.3)", note = { enUS = "Collect 1 pile of Kraul Guano from the Kraul bats and bring it to Master Apothecary Faranell.", trTR = "Kraul yarasalarından 1 yığın Kraul Guano topla ve Master Apothecary Faranell'e götür." } },
    { id = 1101, name = "The Crone of the Kraul", level = 34, req = 29, side = "Alliance", giver = "Falfindel Waywarder, Thalanaar, Feralas (89.6, 46.6)", turnin = "Falfindel Waywarder, Thalanaar, Feralas (89.6, 46.6)", note = { enUS = "Bring Razorflank's Medallion to Falfindel Waywarder. Requires Lonebrow's Journal first.", trTR = "Razorflank's Medallion'ı Falfindel Waywarder'a götür. Önce Lonebrow's Journal gerekir." } },
    { id = 1102, name = "A Vengeful Fate", level = 34, req = 29, side = "Horde", giver = "Auld Stonespire, Thunder Bluff (36.0, 59.9)", turnin = "Auld Stonespire, Thunder Bluff (36.0, 59.9)", note = { enUS = "Bring Razorflank's Heart to Auld Stonespire.", trTR = "Razorflank's Heart'ı Auld Stonespire'a götür." } },
    { id = 6522, name = "An Unholy Alliance", level = 36, req = 28, side = "Horde", giver = "Starts from Small Scroll, dropped by Charlga Razorflank.", turnin = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", note = { enUS = "Take the Small Scroll to Varimathras in the Undercity.", trTR = "Small Scroll'u Undercity'deki Varimathras'a götür." } },
  },
  loot = {
    { boss = "Roogug", items = {
      { id = 274155, n = "Geomancer Headdress", q = 3, s = "Head, Leather", c = "49", a = "36" },
      { id = 274152, n = "Roogug's Severed Head", q = 3, s = "Trinket", c = "123456789" },
    } },
    { boss = "Aggem Thorncurse", items = {
      { id = 6681, n = "Thornspike", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 274158, n = "Death Prophet Spine", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 252820, n = "Pattern: Brawler's Leather Legguards", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Death Speaker Jargba", items = {
      { id = 2816, n = "Death Speaker Scepter", q = 3, s = "Main Hand, Mace", c = "124695" },
      { id = 6685, n = "Death Speaker Mantle", q = 3, s = "Shoulder, Cloth", c = "578", a = "926" },
      { id = 6682, n = "Death Speaker Robes", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
    } },
    { boss = "Overlord Ramtusk", items = {
      { id = 6687, n = "Corpsemaker", q = 3, s = "Two-Hand, Axe", c = "1236" },
      { id = 6686, n = "Tusken Helm", q = 3, s = "Head, Mail", c = "36", a = "12" },
      { id = 274161, n = "Quillord Mail Leggings", q = 3, s = "Legs, Mail", c = "36", a = "12" },
      { id = 251379, n = "Plans: Crusader's Silvered Chain Leggings", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 252821, n = "Pattern: Trapper's Leather Legguards", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Agathelos the Raging", items = {
      { id = 6691, n = "Swinetusk Shank", q = 3, s = "Main Hand, Dagger", c = "14356789" },
      { id = 6690, n = "Ferine Leggings", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 274160, n = "Quilrager Throwing Axe", q = 3, s = "Thrown", c = "143" },
      { id = 251378, n = "Plans: Acolyte's Silvered Chain Leggings", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
    } },
    { boss = "Charlga Razorflank", items = {
      { id = 6693, n = "Agamaggan's Clutch", q = 3, s = "Finger", c = "123456789" },
      { id = 6694, n = "Heart of Agamaggan", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 6692, n = "Pronged Reaver", q = 3, s = "One-Hand, Axe", c = "1236" },
      { id = 273103, n = "Blueprint: Arcane Salvager", q = 2, s = "Blueprint" },
    } },
    { boss = "Blind Hunter", items = {
      { id = 6695, n = "Stygian Bone Amulet", q = 3, s = "Neck", c = "123456789" },
      { id = 6697, n = "Batwing Mantle", q = 3, s = "Shoulder, Cloth", c = "578", a = "926" },
      { id = 6696, n = "Nightstalker Bow", q = 3, s = "Ranged, Bow", c = "143" },
    } },
    { boss = "Earthcaller Halmgar", items = {
      { id = 6689, n = "Wind Spirit Staff", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 6688, n = "Whisperwind Headdress", q = 3, s = "Head, Leather", c = "49", a = "36" },
    } },
    { boss = "Trash Drops", items = {
      { id = 776, n = "Vendetta", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 1727, n = "Sword of Decay", q = 3, s = "Main Hand, Sword", c = "124378" },
      { id = 1975, n = "Pysan's Old Greatsword", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 1976, n = "Slaghammer", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 2549, n = "Staff of the Shade", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 1978, n = "Wolfclaw Gloves", q = 3, s = "Hands, Leather", c = "49", a = "36" },
      { id = 2264, n = "Mantle of Thieves", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 4438, n = "Pugilist Bracers", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 2039, n = "Plains Ring", q = 3, s = "Finger", c = "123456789" },
    } },
  },
})
