local _, ns = ...
ns.DungeonExtra("drowned-city", {
  quests = {
    { id = 95775, name = "The Drowned City", level = 40, req = 30, side = "Horde", giver = "Kin'weelay, Grom'gol Base Camp, Stranglethorn Vale (32.3, 27.7)", turnin = "Kin'weelay, Grom'gol Base Camp, Stranglethorn Vale (32.3, 27.7)", note = { enUS = "Make rubbings of the four I'lalai tablets inside the Drowned City and bring them to Kin'weelay.", trTR = "Drowned City'deki dört I'lalai tabletinin kopyasını çıkar ve Kin'weelay'e götür." } },
    { id = 96078, name = "A Tale Spun Around the Fire", level = 40, req = 30, side = "Horde", giver = "Kin'weelay, Grom'gol Base Camp, Stranglethorn Vale (32.3, 27.7)", turnin = "Master Gadrin, Sen'jin Village, Durotar (56.0, 74.7)", note = { enUS = "Carry the tablet rubbings to Master Gadrin in Sen'jin Village.", trTR = "Tablet kopyalarını Sen'jin Village'daki Master Gadrin'e götür." } },
    { id = 95776, name = "The Only Good Brinescale...", level = 38, req = 30, side = "Horde", giver = "Commander Aggro'gosh, Grom'gol Base Camp, Stranglethorn Vale (32.2, 28.9)", turnin = "Commander Aggro'gosh, Grom'gol Base Camp, Stranglethorn Vale (32.2, 28.9)", note = { enUS = "Kill the naga Var'Taka in the Drowned City.", trTR = "Drowned City'de naga Var'Taka'yı öldür." } },
    { id = 96774, name = "Ancient Gurubashi Idol", level = 40, req = 30, side = "Horde", giver = "Mazu'kon, Mulgore (32.5, 20.7)", turnin = "Mazu'kon, Mulgore (32.5, 20.7)", note = { enUS = "Take the Ancient Gurubashi Idol from the strongest troll priest in the city.", trTR = "Şehirdeki en güçlü trol rahibinin elindeki Ancient Gurubashi Idol'ü al." }, verify = true },
    { id = 95789, name = "Shady Saltseers", level = 40, req = 34, giver = "Krazek, Booty Bay, Stranglethorn Vale (26.9, 77.2)", turnin = "Krazek, Booty Bay, Stranglethorn Vale (26.9, 77.2)", note = { enUS = "Collect 10 Voodoo Infused Artifacts from the Saltseer pirates in the Drowned City.", trTR = "Drowned City'deki Saltseer korsanlarından 10 Voodoo Infused Artifact topla." } },
    { id = 95791, name = "The Saltseer Captain", level = 40, req = 34, giver = "Krazek, Booty Bay, Stranglethorn Vale (26.9, 77.2)", turnin = "Krazek, Booty Bay, Stranglethorn Vale (26.9, 77.2)", note = { enUS = "Kill 3 Saltseer Coroners and their leader, Captain Dreadrise.", trTR = "3 Saltseer Coroner'ı ve liderleri Captain Dreadrise'ı öldür." } },
    { id = 95787, name = "Take Two With Water", level = 40, req = 30, side = "Alliance", giver = "Loremaster Dibbs, Southshore, Hillsbrad Foothills (50.6, 57.1)", turnin = "Loremaster Dibbs, Southshore, Hillsbrad Foothills (50.6, 57.1)", note = { enUS = "Make rubbings of the I'lalai tablets in the Drowned City for Loremaster Dibbs.", trTR = "Drowned City'deki I'lalai tabletlerinin kopyasını Loremaster Dibbs için çıkar." } },
    { id = 95788, name = "Magics of the Drowned City", level = 40, req = 30, side = "Alliance", giver = "Loremaster Dibbs, Southshore, Hillsbrad Foothills (50.6, 57.1)", turnin = "Loremaster Dibbs, Southshore, Hillsbrad Foothills (50.6, 57.1)", note = { enUS = "Collect 5 I'lalai Fetishes from the trolls of the Drowned City.", trTR = "Drowned City'nin trollerinden 5 I'lalai Fetish topla." } },
    { id = 95798, name = "The Web of Magic", level = 40, req = 30, side = "Alliance", giver = "Loremaster Dibbs, Southshore, Hillsbrad Foothills (50.6, 57.1)", turnin = "Abra Cadabra, Dalaran, Alterac Mountains (12.0, 70.5)", note = { enUS = "Bring an I'lalai Fetish to Abra Cadabra in Dalaran.", trTR = "Bir I'lalai Fetish'i Dalaran'daki Abra Cadabra'ya götür." } },
    { id = 95799, name = "Findings for the Explorer's League", level = 40, req = 30, side = "Alliance", giver = "Loremaster Dibbs, Southshore, Hillsbrad Foothills (50.6, 57.1)", turnin = "Historian Karnik, Hall of Explorers, Ironforge (77.5, 11.8)", note = { enUS = "Take Loremaster Dibbs' translations to Historian Karnik in Ironforge.", trTR = "Loremaster Dibbs'in çevirilerini Ironforge'daki Historian Karnik'e götür." } },
    { id = 97130, name = "Ancient Gurubashi Secrets", level = 40, req = 34, side = "Alliance", giver = "Archmage Timear, Dalaran, Alterac Mountains (15.4, 74.1)", turnin = "Archmage Timear, Dalaran, Alterac Mountains (15.4, 74.1)", note = { enUS = "Recover an Ancient Gurubashi Idol from the Drowned City for Archmage Timear.", trTR = "Archmage Timear için Drowned City'den bir Ancient Gurubashi Idol getir." } },
  },
  loot = {
    { boss = "Zul'Alai", items = {
      { id = 274598, n = "Bloodslash Axe", q = 3, s = "One-Hand, Axe", c = "1236" },
      { id = 274599, n = "Oathbound Bracers", q = 3, s = "Wrist, Leather", c = "49", a = "36" },
      { id = 274600, n = "Berserker Shackles", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
    } },
    { boss = "Var'Taka", items = {
      { id = 274601, n = "Harpoon of Command", q = 3, s = "Two-Hand, Polearm", c = "1239" },
      { id = 274602, n = "Brinebelly Leggings", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 274613, n = "Priestess Cloak", q = 3, s = "Back", c = "123456789" },
    } },
    { boss = "Captain Dreadrise", items = {
      { id = 274603, n = "Dreadfrost Saber", q = 3, s = "Main Hand, Sword", c = "124378" },
      { id = 274604, n = "Frosty Blunderbuss", q = 3, s = "Ranged, Gun", c = "143" },
      { id = 274605, n = "Briny Sash", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
    } },
    { boss = "Deathless Marrow", items = {
      { id = 274607, n = "Viscera Spaulders", q = 3, s = "Shoulder, Mail", c = "36", a = "12" },
      { id = 274606, n = "Bloodspine Staff", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 274614, n = "Knucklebone Ring", q = 3, s = "Finger", c = "123456789" },
    } },
    { boss = "Gill", items = {
      { id = 286646, n = "Gill's Gills", q = 3, s = "Trinket", c = "123456789" },
      { id = 286649, n = "Tidebound Dagger", q = 3, s = "Main Hand, Dagger", c = "14356789" },
    } },
    { boss = "Primeval Elemental", items = {
      { id = 274611, n = "Robe of the Drowned", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 274612, n = "Waterlogged Burial Shroud", q = 3, s = "Back", c = "123456789" },
      { id = 274615, n = "Heart of the Primeval", q = 3, s = "Trinket", c = "123456789" },
    } },
    { boss = "Min'loth the Serpent", items = {
      { id = 274610, n = "Ritual-Binder's Gloves", q = 3, s = "Hands, Leather", c = "49", a = "36" },
      { id = 274608, n = "Maw of Min'loth", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 274609, n = "Serpentbane Crown", q = 3, s = "Head, Mail", c = "36", a = "12" },
    } },
    { boss = "Umbra", items = {
      { id = 286658, n = "Umbral Scaled Belt", q = 3, s = "Waist, Mail", c = "36", a = "12" },
      { id = 286662, n = "Deep-Dweller's Grips", q = 3, s = "Hands, Cloth", c = "578", a = "926" },
    } },
    { boss = "\"Pyromancer\" Braxton", items = {
      { id = 286650, n = "Pyromancer's Baton", q = 3, s = "One-Hand, Mace", c = "124695" },
      { id = 286651, n = "Flamestarter's Signet", q = 3, s = "Finger", c = "123456789" },
    } },
    { boss = "Trash Drops", items = {
      { id = 271718, n = "Linken's Boots of Iron", q = 3, s = "Feet, Mail", c = "36", a = "12" },
      { id = 286997, n = "Depth-Risen Leggings", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
      { id = 286998, n = "Deep Flora Bindings", q = 3, s = "Wrist, Cloth", c = "578", a = "926" },
      { id = 286999, n = "Deathcrawler's Chest", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 287000, n = "Skin-Flayed Footguards", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 287001, n = "Waterlogged Shoulderpads", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 287002, n = "Risen Sentry's Links", q = 3, s = "Legs, Mail", c = "36", a = "12" },
      { id = 287003, n = "Corroded Handguards", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 287004, n = "Touch of the Depths", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 287005, n = "Sword of Dismemberment", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 287006, n = "Resurged Axe", q = 3, s = "One-Hand, Axe", c = "1236" },
    } },
  },
})
