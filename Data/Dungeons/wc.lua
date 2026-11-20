local _, ns = ...
ns.DungeonExtra("wc", {
  quests = {
    { id = 1486, name = "Deviate Hides", level = 17, req = 13, giver = "Nalpak, above the entrance to Wailing Caverns, Northern Barrens (46.0, 35.7)", turnin = "Nalpak, above the entrance to Wailing Caverns, Northern Barrens (46.0, 35.7)", note = { enUS = "Bring 20 Deviate Hides to Nalpak.", trTR = "Nalpak'a 20 Deviate Hide götür." }, rew = "Choose: Slick Deviate Leggings or Deviate Hide Pack\\n4,640 XP • 18s" },
    { id = 959, name = "Trouble at the Docks", level = 18, req = 14, giver = "Crane Operator Bigglefuzz, Ratchet, Northern Barrens (63.1, 37.6)", turnin = "Crane Operator Bigglefuzz, Ratchet, Northern Barrens (63.1, 37.6)", note = { enUS = "Retrieve the bottle of 99-Year-Old Port from Mad Magglish in Wailing Caverns.", trTR = "Wailing Caverns'taki Mad Magglish'ten 99-Year-Old Port şişesini geri al." }, rew = "3,915 XP • 10s" },
    { id = 962, name = "Serpentbloom", level = 18, req = 14, side = "Horde", giver = "Apothecary Zamah, Thunder Bluff (22.8, 20.9)", turnin = "Apothecary Zamah, Thunder Bluff (22.8, 20.9)", note = { enUS = "Collect 10 Serpentbloom in Wailing Caverns.", trTR = "Wailing Caverns'ta 10 Serpentbloom topla." }, rew = "Choose: Apothecary Gloves, Heat Resistant Mitts or Safety Boots\\n4,930 XP • 10s" },
    { id = 1491, name = "Smart Drinks", level = 18, req = 13, giver = "Mebok Mizzyrix, Ratchet, Northern Barrens (62.4, 37.6)", turnin = "Mebok Mizzyrix, Ratchet, Northern Barrens (62.4, 37.6)", note = { enUS = "Bring 6 portions of Wailing Essence to Mebok Mizzyrix. Requires Raptor Horns first.", trTR = "Mebok Mizzyrix'e 6 porsiyon Wailing Essence götür. Önce Raptor Horns gerekir." }, rew = "3,915 XP • 10s" },
    { id = 1487, name = "Deviate Eradication", level = 21, req = 15, giver = "Ebru, above the entrance to Wailing Caverns, Northern Barrens (46.0, 35.7)", turnin = "Ebru, above the entrance to Wailing Caverns, Northern Barrens (46.0, 35.7)", note = { enUS = "Kill 7 Deviate Ravagers, 7 Deviate Vipers, 7 Deviate Shamblers and 7 Deviate Dreadfangs in Wailing Caverns.", trTR = "Wailing Caverns'ta 7 Deviate Ravager, 7 Deviate Viper, 7 Deviate Shambler ve 7 Deviate Dreadfang öldür." }, rew = "Choose: Pattern: Deviate Scale Belt, Sizzle Stick or Dagmire Gauntlets\\n5,945 XP • 25s" },
    { id = 914, name = "Leaders of the Fang", level = 22, req = 11, side = "Horde", giver = "Nara Wildmane, Thunder Bluff (75.7, 31.6)", turnin = "Nara Wildmane, Thunder Bluff (75.7, 31.6)", note = { enUS = "Bring the Gems of Cobrahn, Anacondra, Pythas and Serpentis to Nara Wildmane. Requires Nara Wildmane first.", trTR = "Cobrahn, Anacondra, Pythas ve Serpentis'in mücevherlerini Nara Wildmane'e götür. Önce Nara Wildmane gerekir." }, rew = "Choose: Crescent Staff, Wingblade or Hammerbone\\n6,380 XP • Thunder Bluff +150" },
    { id = 6981, name = "The Glowing Shard", level = 26, req = 15, giver = "Starts from Glowing Shard, dropped by Mutanus the Devourer.", turnin = "Falla Sagewind, Northern Barrens (48.2, 32.8)", note = { enUS = "Travel to Ratchet to learn more about the Glowing Shard, then deliver it as directed.", trTR = "Glowing Shard hakkında daha fazlasını öğrenmek için Ratchet'e git, sonra onu söylenen yere teslim et." }, rew = "7,685 XP" },
  },
  loot = {
    { boss = "Lord Cobrahn", items = {
      { id = 6460, n = "Cobrahn's Grasp", q = 3, s = "Waist, Mail", c = "36", a = "12" },
      { id = 10410, n = "Leggings of the Fang", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 6465, n = "Robe of the Moccasin", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
    } },
    { boss = "Lady Anacondra", items = {
      { id = 10412, n = "Belt of the Fang", q = 3, s = "Waist, Leather", c = "49", a = "36" },
      { id = 5404, n = "Serpent's Shoulders", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 6446, n = "Snakeskin Bag", q = 2, s = "Bag", c = "123456789" },
      { id = 273088, n = "Snake Eye Kaleidoscope", q = 3, s = "Neck", c = "123456789" },
    } },
    { boss = "Kresh", items = {
      { id = 13245, n = "Kresh's Back", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 6447, n = "Worn Turtle Shell Shield", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 273084, n = "Cloak of Hermitic Bliss", q = 3, s = "Back, Cloth", c = "123456789" },
    } },
    { boss = "Lord Pythas", items = {
      { id = 6472, n = "Stinging Viper", q = 3, s = "One-Hand, Mace", c = "124695" },
      { id = 6473, n = "Armor of the Fang", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 273089, n = "Slither Cord", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
    } },
    { boss = "Skum", items = {
      { id = 6449, n = "Glowing Lizardscale Cloak", q = 3, s = "Back, Cloth", c = "123456789" },
      { id = 6448, n = "Tail Spike", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 273137, n = "Skum's Bucket", q = 3, s = "Held In Off-hand", c = "578926" },
    } },
    { boss = "Lord Serpentis", items = {
      { id = 6469, n = "Venomstrike", q = 3, s = "Ranged, Bow", c = "143" },
      { id = 5970, n = "Serpent Gloves", q = 2, s = "Hands, Cloth", c = "578", a = "926" },
      { id = 10411, n = "Footpads of the Fang", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 6459, n = "Savage Trodders", q = 3, s = "Feet, Mail", c = "36", a = "12" },
    } },
    { boss = "Verdan the Everliving", items = {
      { id = 6630, n = "Seedcloud Buckler", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 6631, n = "Living Root", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 6629, n = "Sporid Cape", q = 2, s = "Back, Cloth", c = "123456789" },
    } },
    { boss = "Mutanus the Devourer", items = {
      { id = 6461, n = "Slime-encrusted Pads", q = 3, s = "Shoulder, Cloth", c = "578", a = "926" },
      { id = 6627, n = "Mutant Scale Breastplate", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 6463, n = "Deep Fathom Ring", q = 3, s = "Finger", c = "123456789" },
      { id = 10441, n = "Glowing Shard", q = 1, s = "Quest Item" },
    } },
    { boss = "Deviate Faerie Dragon", items = {
      { id = 5243, n = "Firebelcher", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 6632, n = "Feyscale Cloak", q = 3, s = "Back, Cloth", c = "123456789" },
      { id = 252781, n = "Pattern: Stormrider's Leather Gloves", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Trash Drops", items = {
      { id = 10413, n = "Gloves of the Fang", q = 3, s = "Hands, Leather", c = "49", a = "36" },
    } },
  },
})
