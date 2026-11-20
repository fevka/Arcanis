local _, ns = ...
ns.DungeonExtra("alcaz-prison", {
  quests = {
    { id = 95262, name = "The Secret Prison", level = 53, req = 48, side = "Alliance", giver = "Sully McCleary, Theramore Isle, Dustwallow Marsh (63.5, 42.3)", note = { enUS = "Get into Alcaz Prison and find the prisoner Sully McCleary is after.", trTR = "Alcaz Prison'a gir ve Sully McCleary'nin aradığı mahkûmu bul." } },
    { id = 96381, name = "A Bit of Wet Work", level = 53, req = 48, side = "Alliance", giver = "Sully McCleary, Theramore Isle, Dustwallow Marsh (63.5, 42.3)", turnin = "Sully McCleary, Theramore Isle, Dustwallow Marsh (63.5, 42.3)", note = { enUS = "Kill the targets Sully McCleary names inside Alcaz Prison.", trTR = "Alcaz Prison'da Sully McCleary'nin söylediği hedefleri öldür." } },
    { id = 96772, name = "The Dragon's Journal", level = 53, req = 46, side = "Alliance", giver = "Archmage Lan'dalock, Dalaran, Alterac Mountains (15.3, 73.9)", turnin = "Archmage Lan'dalock, Dalaran, Alterac Mountains (15.3, 73.9)", note = { enUS = "Find the dragon's journal in Alcaz Prison for Archmage Lan'dalock.", trTR = "Archmage Lan'dalock için Alcaz Prison'daki ejderha günlüğünü bul." } },
    { id = 95309, name = "No Orc Left Behind", level = 53, req = 48, side = "Horde", giver = "Sergeant Ulka, Dustwallow Marsh (70.3, 18.9)", note = { enUS = "Enter Alcaz Prison and find Commander Folkar.", trTR = "Alcaz Prison'a gir ve Commander Folkar'ı bul." } },
    { id = 96332, name = "A Little Payback", level = 53, req = 48, side = "Horde", giver = "Sergeant Ulka, Dustwallow Marsh (70.3, 18.9)", turnin = "Sergeant Ulka, Dustwallow Marsh (70.3, 18.9)", note = { enUS = "Pay the prison guards back for what they did to the Kor'kron.", trTR = "Hapishane muhafızlarına Kor'kron'a yaptıklarının hesabını sor." } },
    { id = 96334, name = "Blood Red Bandanas", level = 53, req = 48, side = "Horde", giver = "Sergeant Ulka, Dustwallow Marsh (70.3, 18.9)", turnin = "Eitrigg, Valley of Wisdom, Orgrimmar (34.3, 39.4)", note = { enUS = "Collect red bandanas from the prison's gangs and take them to Eitrigg in Orgrimmar.", trTR = "Hapishanedeki çetelerden kırmızı bandanaları topla ve Orgrimmar'daki Eitrigg'e götür." } },
  },
  loot = {
    { boss = "Overseer Wrex", items = {
      { id = 276734, n = "Wrex's Pinky Ring", q = 3, s = "Finger", c = "123456789" },
      { id = 276732, n = "Alcaz Willcrusher", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 276733, n = "Grips of Control", q = 3, s = "Hands, Plate", c = "12" },
    } },
    { boss = "Tidemistress Ca'zass", items = {
      { id = 276737, n = "Cloak of the Tidemistress", q = 3, s = "Back", c = "123456789" },
      { id = 276735, n = "Tidesong Wand", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 276736, n = "Seascale Bracers", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
    } },
    { boss = "Katerina the Cleaner", items = {
      { id = 276740, n = "Sentimental Locket", q = 3, s = "Neck", c = "123456789" },
      { id = 276738, n = "Katerina's Shanker", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 276739, n = "Cutthroat Chestguard", q = 3, s = "Chest, Mail", c = "36", a = "12" },
    } },
    { boss = "The Questioner", items = {
      { id = 276742, n = "Girdle of Extracted Answers", q = 3, s = "Waist, Plate", c = "12" },
      { id = 276741, n = "Defias Enforcer's Shoulderpads", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 276743, n = "Fingerbreaker Stamp", q = 3, s = "Trinket", c = "123456789" },
    } },
    { boss = "Blazeroar", items = {
      { id = 276744, n = "Zarla's Snack Pouch", q = 3, s = "Trinket", c = "123456789" },
      { id = 276745, n = "Beastbond Robe", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 276746, n = "Defias Enforcer's Legguards", q = 3, s = "Legs, Leather", c = "49", a = "36" },
    } },
    { boss = "Trash Drops", items = {
      { id = 287017, n = "Chaplain's Mitre", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 287018, n = "Compound Gloves", q = 3, s = "Hands, Cloth", c = "578", a = "926" },
      { id = 287019, n = "Defias Enforcer's Mask", q = 3, s = "Head, Leather", c = "49", a = "36" },
      { id = 287020, n = "Defias Enforcer's Chest", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 287021, n = "Defias Enforcer's Prowlers", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 287022, n = "Spaulders of Containment", q = 3, s = "Shoulder, Mail", c = "36", a = "12" },
      { id = 287023, n = "Iron-Wrought Cuffs", q = 3, s = "Wrist, Plate", c = "12" },
      { id = 287024, n = "Mark of Captivity", q = 3, s = "Neck", c = "123456789" },
      { id = 287025, n = "Enchantresses' Spire", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 287026, n = "Escape Plan", q = 3, s = "Ranged, Gun", c = "143" },
    } },
  },
})
