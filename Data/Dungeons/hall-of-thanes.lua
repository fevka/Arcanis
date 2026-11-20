local _, ns = ...
ns.DungeonExtra("hall-of-thanes", {
  quests = {
    { id = 96394, name = "The Restless Dead", level = 15, req = 10, side = "Alliance", giver = "Afadra Dunwall, Ironforge (32.4, 47.8)", turnin = "Afadra Dunwall, Ironforge (32.4, 47.8)", note = { enUS = "Kill 15 Enraged Apparitions and 10 Tormented Souls, then put Anvilmar's spirit to rest.", trTR = "15 Enraged Apparitions ve 10 Tormented Souls öldür, sonra Anvilmar'ın ruhunu huzura kavuştur." }, rew = "Choose: Dusty Belt or Cryptwalker Bracers\\n3,570 XP • 7s • Ironforge +100" },
    { id = 96395, name = "An Ancient Grudge", level = 15, req = 10, giver = "Ghostly Attendant, Hall of Thanes, after the first room", turnin = "Ghostly Attendant, Hall of Thanes", note = { enUS = "Put the spirit of Faldrim Anvilmar to rest.", trTR = "Faldrim Anvilmar'ın ruhunu huzura kavuştur." }, rew = "Choose: Catacomb Cloak or Deepgrave Trousers\\n3,570 XP" },
    { id = 96403, name = "Important Heirlooms", level = 15, req = 10, giver = "Thom Filch, by the bridge and vault entrance, Ironforge (31.4, 45.4)", turnin = "Thom Filch, near the dungeon entrance, Ironforge (31.4, 45.4)", note = { enUS = "Collect 8 Dwarven Heirlooms from the Hall of Thanes.", trTR = "Hall of Thanes'den 8 Dwarven Heirlooms topla." }, rew = "Choose: Dwarven Tome or Tomb Robber's Gloves\\n4,590 XP • 7s • Gadgetzan +100" },
    { id = 96393, name = "Old Ironforge Incursion", level = 16, req = 9, side = "Alliance", giver = "Earthseer Farsen, Dun Morogh", turnin = "King Magni Bronzebeard, Ironforge (39.1, 56.2)", note = { enUS = "Enter the Hall of Thanes and claim the Head of Durgen Dirgehammer. Requires Underground Map first.", trTR = "Hall of Thanes'e gir ve Head of Durgen Dirgehammer'ı al. Önce Underground Map gerekir." }, rew = "Choose: Calibrated Blunderbuss, Ironforge Greathammer or Deepblaze\\n4,930 XP • 8s • Ironforge +100 • Gnomeregan Exiles +100" },
    { id = 98423, name = "The Treaty of Understanding", level = 16, req = 9, side = "Alliance", giver = "Stone Tablet, vault in the Reliquary of Kings (Durgen Dirgehammer's room), Hall of Thanes", turnin = "King Magni Bronzebeard, Ironforge (39.1, 56.2)", note = { enUS = "Take the Treaty of Understanding to King Magni Bronzebeard in Ironforge.", trTR = "Treaty of Understanding'i Ironforge'daki King Magni Bronzebeard'e götür." }, rew = "3,900 XP • 16s • Ironforge +100 • Gnomeregan Exiles +100" },
  },
  loot = {
    { boss = "Faldrim Anvilmar", items = {
      { id = 270227, n = "Ephemeral Choker", q = 3, s = "Neck", c = "123456789" },
      { id = 271096, n = "Aetherwisp Bracers", q = 3, s = "Wrist, Cloth", c = "578", a = "926" },
      { id = 271097, n = "Spiritwraith Drape", q = 3, s = "Back, Cloth", c = "123456789" },
    } },
    { boss = "Magmatus", items = {
      { id = 270230, n = "Kindlegem Girdle", q = 3, s = "Waist, Mail", c = "36", a = "12" },
      { id = 270231, n = "Flamefist Grips", q = 3, s = "Hands, Leather", c = "49", a = "36" },
      { id = 271095, n = "Fang of Magmatus", q = 3, s = "Main Hand, Dagger", c = "14356789" },
    } },
    { boss = "Plunder", items = {
      { id = 270228, n = "Golemheart Stave", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 271098, n = "Golemguard Chest", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 270229, n = "Treads of the Protector Golem", q = 3, s = "Feet, Mail", c = "36", a = "12" },
    } },
    { boss = "Durgen Dirgehammer", items = {
      { id = 270256, n = "Durgen's Crescent Axe", q = 3, s = "Main Hand, Axe", c = "1236" },
      { id = 270260, n = "Direhammer Leggings", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 270261, n = "Robes of the Disgraced Thane", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 274286, n = "Durgen Dirgehammer's Head", q = 1, s = "Quest Item" },
    } },
  },
})
