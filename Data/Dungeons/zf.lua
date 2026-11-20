local _, ns = ...
ns.DungeonExtra("zf", {
  quests = {
    { id = 2768, name = "Divino-matic Rod", level = 47, req = 40, giver = "Chief Engineer Bilgewhizzle, Gadgetzan, Tanaris (52.5, 28.5)", turnin = "Chief Engineer Bilgewhizzle, Gadgetzan, Tanaris (52.5, 28.5)", note = { enUS = "Find the Divino-matic Rod in Zul'Farrak and bring it to Chief Engineer Bilgewhizzle in Gadgetzan.", trTR = "Zul'Farrak'ta Divino-matic Rod'u bul ve Gadgetzan'daki Chief Engineer Bilgewhizzle'a götür." } },
    { id = 2770, name = "Gahz'rilla", level = 50, req = 40, giver = "Wizzle Brassbolts, Shimmering Flats, Thousand Needles (78.1, 77.1)", turnin = "Wizzle Brassbolts, Shimmering Flats, Thousand Needles (78.1, 77.1)", note = { enUS = "Kill Gahz'rilla in Zul'Farrak and bring his Electrified Scale to Wizzle Brassbolts.", trTR = "Zul'Farrak'ta Gahz'rilla'yı öldür ve Electrified Scale'ini Wizzle Brassbolts'a götür." } },
    { id = 2846, name = "Tiara of the Deep", level = 46, req = 40, giver = "Tabetha, north of Stonemaul Ruins, Dustwallow Marsh (46.1, 57.1)", turnin = "Tabetha, north of Stonemaul Ruins, Dustwallow Marsh (46.1, 57.1)", note = { enUS = "Find the Tiara of the Deep in Zul'Farrak and bring it to Tabetha.", trTR = "Zul'Farrak'ta Tiara of the Deep'i bul ve Tabetha'ya götür." } },
    { id = 2865, name = "Scarab Shells", level = 45, req = 40, giver = "Tran'rek, Gadgetzan, Tanaris (51.6, 26.8)", turnin = "Tran'rek, Gadgetzan, Tanaris (51.6, 26.8)", note = { enUS = "Collect 5 Uncracked Scarab Shells in Zul'Farrak. Requires Tran'rek first.", trTR = "Zul'Farrak'ta 5 Uncracked Scarab Shell topla. Önce Tran'rek gerekir." } },
    { id = 2936, name = "The Spider God", level = 45, req = 40, side = "Horde", giver = "Master Gadrin, Sen'jin Village, Durotar (56.0, 74.7)", turnin = "Master Gadrin, Sen'jin Village, Durotar (56.0, 74.7)", note = { enUS = "Read the Tablet of Theka in Zul'Farrak to learn the name of the Witherbark spider god. Requires Consult Master Gadrin first.", trTR = "Witherbark örümcek tanrısının adını öğrenmek için Zul'Farrak'taki Tablet of Theka'yı oku. Önce Consult Master Gadrin gerekir." } },
    { id = 2991, name = "Nekrum's Medallion", level = 47, req = 40, giver = "Thadius Grimshade, Nethergarde Keep, Blasted Lands (66.9, 19.5)", turnin = "Thadius Grimshade, Nethergarde Keep, Blasted Lands (66.9, 19.5)", note = { enUS = "Find Nekrum's Medallion in Zul'Farrak. Requires Thadius Grimshade first.", trTR = "Zul'Farrak'ta Nekrum's Medallion'ı bul. Önce Thadius Grimshade gerekir." } },
    { id = 3042, name = "Troll Temper", level = 45, req = 40, giver = "Trenton Lighthammer, Gadgetzan, Tanaris (51.4, 28.8)", turnin = "Trenton Lighthammer, Gadgetzan, Tanaris (51.4, 28.8)", note = { enUS = "Collect 20 Vials of Troll Temper in Zul'Farrak.", trTR = "Zul'Farrak'ta 20 şişe Troll Temper topla." } },
    { id = 3527, name = "The Prophecy of Mosh'aru", level = 47, req = 40, giver = "Yeh'kinya, Steamwheedle Port, Tanaris (67.0, 22.4)", turnin = "Yeh'kinya, Steamwheedle Port, Tanaris (67.0, 22.4)", note = { enUS = "Collect the First and Second Mosh'aru Tablets in Zul'Farrak. Requires Screecher Spirits first.", trTR = "Zul'Farrak'ta First Mosh'aru Tablet ve Second Mosh'aru Tablet'i topla. Önce Screecher Spirits gerekir." } },
  },
  loot = {
    { boss = "Antu'sul", items = {
      { id = 9640, n = "Vice Grips", q = 3, s = "Hands, Plate", c = "123456789" },
      { id = 9641, n = "Lifeblood Amulet", q = 3, s = "Neck, Trinket", c = "123456789" },
      { id = 9639, n = "The Hand of Antu'sul", q = 3, s = "Main Hand, Mace", c = "124695" },
      { id = 9379, n = "Sang'thraze the Deflector", q = 3, s = "One-Hand, Sword", c = "124378" },
    } },
    { boss = "Witch Doctor Zum'rah", items = {
      { id = 18083, n = "Jumanza Grips", q = 3, s = "Hands, Cloth", c = "578", a = "926" },
      { id = 18082, n = "Zum'rah's Vexing Cane", q = 3, s = "Two-Hand, Staff", c = "5789632" },
    } },
    { boss = "Shadowpriest Sezz'ziz", items = {
      { id = 9470, n = "Bad Mojo Mask", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 9473, n = "Jinxed Hoodoo Skin", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 9474, n = "Jinxed Hoodoo Kilt", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 9475, n = "Diabolic Skiver", q = 3, s = "Two-Hand, Polearm", c = "1239" },
    } },
    { boss = "Dustwraith", items = {
      { id = 12471, n = "Desertwalker Cane", q = 3, s = "Held In Off-hand, Trinket", c = "578926" },
    } },
    { boss = "Sergeant Bly", items = {
      { id = 5616, n = "Gutwrencher", q = 3, s = "One-Hand, Dagger", c = "14356789" },
    } },
    { boss = "Gahz'rilla", items = {
      { id = 9469, n = "Gahz'rilla Scale Armor", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 9467, n = "Gahz'rilla Fang", q = 2, s = "One-Hand, Dagger", c = "14356789" },
    } },
    { boss = "Chief Ukorz Sandscalp", items = {
      { id = 9479, n = "Embrace of the Lycan", q = 3, s = "Head, Leather", c = "49", a = "36" },
      { id = 9476, n = "Big Bad Pauldrons", q = 3, s = "Shoulder, Plate", c = "123456789" },
      { id = 9478, n = "Ripsaw", q = 3, s = "Main Hand, Axe", c = "1236" },
      { id = 9477, n = "The Chief's Enforcer", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 11086, n = "Jang'thraze the Protector", q = 3, s = "Main Hand, Sword", c = "124378" },
    } },
    { boss = "Zerillis", items = {
      { id = 12470, n = "Sandstalker Ankleguards", q = 3, s = "Feet, Leather", c = "49", a = "36" },
    } },
    { boss = "Trash Drops", items = {
      { id = 9512, n = "Blackmetal Cape", q = 3, s = "Back, Cloth", c = "578", a = "926" },
      { id = 9484, n = "Spellshock Leggings", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
      { id = 862, n = "Runed Ring", q = 3, s = "Finger, Trinket", c = "123456789" },
      { id = 6440, n = "Brainlash", q = 3, s = "Finger, Trinket", c = "123456789" },
      { id = 9483, n = "Flaming Incinerator", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 2040, n = "Troll Protector", q = 3, s = "Shield, Shield", c = "123456789" },
      { id = 5616, n = "Gutwrencher", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 9511, n = "Bloodletter Scalpel", q = 3, s = "One-Hand, Sword", c = "124378" },
      { id = 9481, n = "The Minotaur", q = 3, s = "Two-Hand, Axe", c = "1236" },
      { id = 9480, n = "Eyegouger", q = 3, s = "Two-Hand, Polearm", c = "1239" },
      { id = 9482, n = "Witch Doctor's Cane", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 9243, n = "Shriveled Heart", q = 2, s = "Neck, Trinket", c = "123456789" },
    } },
  },
})
