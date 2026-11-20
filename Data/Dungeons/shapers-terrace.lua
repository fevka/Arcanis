local _, ns = ...
ns.DungeonExtra("shapers-terrace", {
  quests = {
    { id = 95924, name = "Panic at the Digsite", level = 60, req = 55, side = "Alliance", giver = "Curator Thorius, Hall of Explorers, Ironforge (71.5, 15.7)", note = { enUS = "Find out what went wrong at the dig on Shaper's Terrace.", trTR = "Shaper's Terrace'teki kazıda neyin ters gittiğini öğren." } },
    { id = 95925, name = "Mapping the Way Forward", level = 60, req = 55, side = "Alliance", giver = "Curator Thorius, Hall of Explorers, Ironforge (71.5, 15.7)", note = { enUS = "Map the terraces for Curator Thorius.", trTR = "Curator Thorius için terasların haritasını çıkar." } },
    { id = 95926, name = "The Dark Crystal", level = 60, req = 55, side = "Horde", giver = "Master Apothecary Faranell, The Apothecarium, Undercity (48.8, 69.3)", note = { enUS = "Bring a dark crystal from Shaper's Terrace to Master Apothecary Faranell.", trTR = "Shaper's Terrace'ten Master Apothecary Faranell'e kara bir kristal getir." } },
    { id = 97049, name = "Essence of Seeping Slimes", level = 60, req = 55, side = "Horde", giver = "Chemist Fuely, The Apothecarium, Undercity (47.5, 73.4)", turnin = "Chemist Fuely, The Apothecarium, Undercity (47.5, 73.4)", note = { enUS = "Collect essence from the slimes on the terraces.", trTR = "Teraslardaki balçıklardan öz topla." } },
    { id = 95928, name = "Crystalline Elements", level = 60, req = 55, side = "Horde", giver = "Mayena Earthseeker, Mulgore (34.9, 22.1)", turnin = "Mayena Earthseeker, Mulgore (34.9, 22.1)", note = { enUS = "Gather crystals from the elementals of Shaper's Terrace.", trTR = "Shaper's Terrace'in elementallerinden kristal topla." }, verify = true },
  },
  loot = {
    { boss = "Titanosaur", items = {
      { id = 280009, n = "Titanosaur Scale Pendant", q = 3, s = "Neck", c = "123456789" },
      { id = 280010, n = "Gargantuan Wristguards", q = 3, s = "Wrist, Plate", c = "12" },
    } },
    { boss = "Ravasaur Hunters", items = {
      { id = 280012, n = "Talon of Tor'Rel", q = 3, s = "One-Hand, Sword", c = "124378" },
      { id = 280013, n = "Frostfang Mail Vest", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 280014, n = "Raptorscale Bulwark", q = 3, s = "Off Hand, Shield", c = "126" },
    } },
    { boss = "Thunderhoof", items = {
      { id = 280018, n = "Hammer of Thundering Hooves", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 280019, n = "Dinofrill Casque", q = 3, s = "Head, Mail", c = "36", a = "12" },
      { id = 280020, n = "Deep Jungle Rifle", q = 3, s = "Ranged, Gun", c = "143" },
    } },
    { boss = "Venomridge", items = {
      { id = 280015, n = "Venomvessel Ring", q = 3, s = "Finger", c = "123456789" },
      { id = 280016, n = "Spiderchitin Wrap", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 280017, n = "Octoclaw Chain Boots", q = 3, s = "Feet, Mail", c = "36", a = "12" },
    } },
    { boss = "Direhorn Matriarch", items = {
      { id = 280021, n = "Tooth of the Matriarch", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 280022, n = "Scaleguard Scimitar", q = 3, s = "One-Hand, Sword", c = "124378" },
      { id = 280045, n = "Regal Direhorn Drape", q = 3, s = "Back", c = "123456789" },
    } },
    { boss = "Cinder", items = {
      { id = 280028, n = "Heartflame Gauntlets", q = 3, s = "Hands, Plate", c = "12" },
      { id = 280029, n = "Cinderedge Crescent", q = 3, s = "One-Hand, Axe", c = "1236" },
    } },
    { boss = "Snowtalon", items = {
      { id = 280026, n = "Albinofur Grips", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 280027, n = "Crownroar Chestplate", q = 3, s = "Chest, Plate", c = "12" },
    } },
    { boss = "Bolt", items = {
      { id = 280031, n = "Sparklance Wand", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 280032, n = "Bolt's Charged Eyeball", q = 3, s = "Trinket", c = "123456789" },
    } },
    { boss = "Vitrix", items = {
      { id = 280026, n = "Albinofur Grips", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 280027, n = "Crownroar Chestplate", q = 3, s = "Chest, Plate", c = "12" },
      { id = 280032, n = "Bolt's Charged Eyeball", q = 3, s = "Trinket", c = "123456789" },
    } },
    { boss = "Nanaya", items = {
      { id = 280023, n = "Nanaya's Control Spire", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 280024, n = "Legplates of Reinforced Crystal", q = 3, s = "Legs, Plate", c = "12" },
      { id = 280025, n = "Leggings of Curation", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
    } },
    { boss = "Trash Drops", items = {
      { id = 287037, n = "Shaper's Robe", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 287038, n = "Naturopathy Footpads", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 287039, n = "Tattered Explorer's Cuffs", q = 3, s = "Wrist, Leather", c = "49", a = "36" },
      { id = 287040, n = "Dinosaur Hide Belt", q = 3, s = "Waist, Leather", c = "49", a = "36" },
      { id = 287041, n = "Time-Forgotten Bindings", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 287042, n = "Pauldrons of the Stone Guardian", q = 3, s = "Shoulder, Plate", c = "12" },
      { id = 287043, n = "Predaceous Band", q = 3, s = "Finger", c = "123456789" },
      { id = 287044, n = "Predator's Shroud", q = 3, s = "Back", c = "123456789" },
      { id = 287045, n = "Ancient Mattock", q = 3, s = "One-Hand, Axe", c = "1236" },
      { id = 287046, n = "Pylon Poker", q = 3, s = "Two-Hand, Staff", c = "5789632" },
    } },
  },
})
