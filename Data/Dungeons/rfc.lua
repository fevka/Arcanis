local _, ns = ...
ns.DungeonExtra("rfc", {
  quests = {
    { id = 5723, name = "Testing an Enemy's Strength", level = 15, req = 9, side = "Horde", giver = "Rahauro, Elder Rise, Thunder Bluff (70.1, 29.5)", turnin = "Rahauro, Elder Rise, Thunder Bluff (70.1, 29.5)", note = { enUS = "Kill 8 Ragefire Troggs and 8 Ragefire Shamans inside Ragefire Chasm.", trTR = "Ragefire Chasm içinde 8 Ragefire Troggs ve 8 Ragefire Shamans öldür." } },
    { id = 5722, name = "Searching for the Lost Satchel", level = 16, req = 9, side = "Horde", giver = "Rahauro, Elder Rise, Thunder Bluff (70.1, 29.5)", turnin = "Maur Grimtotem, small side room off the right-hand tunnel, Ragefire Chasm", note = { enUS = "From the first three-way junction, take the right-hand tunnel uphill and search Maur Grimtotem's corpse in the small side room on the left.", trTR = "İlk üç yollu kavşaktan sağdaki tünelden yokuş yukarı çık ve soldaki küçük yan odada Maur Grimtotem'in cesedini ara." } },
    { id = 5724, name = "Returning the Lost Satchel", level = 16, req = 9, side = "Horde", giver = "Starts from Grimtotem Satchel, taken from Maur Grimtotem's corpse in Ragefire Chasm.", turnin = "Rahauro, Elder Rise, Thunder Bluff (70.1, 29.5)", note = { enUS = "Take the Grimtotem Satchel to Rahauro in Thunder Bluff.", trTR = "Grimtotem Satchel'ı Thunder Bluff'taki Rahauro'ya götür." } },
    { id = 5725, name = "The Power to Destroy...", level = 16, req = 9, side = "Horde", giver = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", turnin = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", note = { enUS = "Collect the books Spells of Shadow and Incantations from the Nether inside Ragefire Chasm.", trTR = "Ragefire Chasm içinde Spells of Shadow ve Incantations from the Nether kitaplarını topla." } },
    { id = 5728, name = "Hidden Enemies", level = 16, req = 9, side = "Horde", giver = "Thrall, Valley of Wisdom, Orgrimmar (31.7, 37.8)", turnin = "Thrall, Valley of Wisdom, Orgrimmar (31.7, 37.8)", note = { enUS = "Kill Bazzalan and Jergosh the Invoker inside Ragefire Chasm.", trTR = "Ragefire Chasm içinde Bazzalan ve Jergosh the Invoker'ı öldür." } },
    { id = 5761, name = "Slaying the Beast", level = 16, req = 9, side = "Horde", giver = "Neeru Fireblade, Cleft of Shadow, Orgrimmar (49.5, 50.6)", turnin = "Neeru Fireblade, Cleft of Shadow, Orgrimmar (49.5, 50.6)", note = { enUS = "Kill Taragaman the Hungerer in Ragefire Chasm and bring his heart to Neeru Fireblade.", trTR = "Ragefire Chasm'da Taragaman the Hungerer'ı öldür ve kalbini Neeru Fireblade'e götür." } },
  },
  loot = {
    { boss = "Oggleflint", items = {
      { id = 272999, n = "Barbaric Crossbow", q = 3, s = "Ranged, Crossbow", c = "143" },
      { id = 272996, n = "Trogg Scepter", q = 3, s = "Main Hand, Mace", c = "124695" },
      { id = 272998, n = "Bone Knuckles", q = 3, s = "Main Hand, Fist Weapon", c = "14693" },
      { id = 252781, n = "Pattern: Stormrider's Leather Gloves", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
      { id = 252782, n = "Pattern: Wisdom's Leather Gloves", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Taragaman the Hungerer", items = {
      { id = 14149, n = "Subterranean Cape", q = 3, s = "Back, Cloth", c = "123456789" },
      { id = 14148, n = "Crystalline Cuffs", q = 3, s = "Wrist, Cloth", c = "578", a = "926" },
      { id = 14145, n = "Cursed Felblade", q = 3, s = "Main Hand, Sword", c = "124378" },
      { id = 251361, n = "Plans: Guard's Gloves", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 251362, n = "Plans: Protector's Gloves", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 251363, n = "Plans: Acolyte's Gloves", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 252782, n = "Pattern: Wisdom's Leather Gloves", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Jergosh the Invoker", items = {
      { id = 14150, n = "Robe of Evocation", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 14147, n = "Cavedweller Bracers", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 14151, n = "Chanting Blade", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 251360, n = "Plans: Veteran's Gloves", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 253906, n = "Pattern: Filigreed Flame Gown", q = 3, s = "Recipe, Tailoring", c = "123456789" },
    } },
    { boss = "Bazzalan", items = {
      { id = 273003, n = "Searing Dagger", q = 3, s = "Main Hand, Dagger", c = "14356789" },
      { id = 273007, n = "Chasm Walkers", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 273005, n = "Satyrskin Cloak", q = 3, s = "Back, Cloth", c = "123456789" },
      { id = 252780, n = "Pattern: Totemic Leather Gloves", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
      { id = 252782, n = "Pattern: Wisdom's Leather Gloves", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
      { id = 253908, n = "Pattern: Filigreed Shadow Gown", q = 3, s = "Recipe, Tailoring", c = "123456789" },
      { id = 253910, n = "Pattern: Filigreed Pearly Gown", q = 3, s = "Recipe, Tailoring", c = "123456789" },
    } },
  },
})
