local _, ns = ...
ns.DungeonExtra("gnomeregan", {
  quests = {
    { id = 2842, name = "Chief Engineer Scooty", level = 35, req = 25, side = "Horde", giver = "Sovik, Valley of Honor, Orgrimmar (75.5, 25.4)", turnin = "Scooty, Booty Bay, Northern Stranglethorn (27.6, 77.5)", note = { enUS = "Speak with Scooty in Booty Bay. Requires Rig Wars first.", trTR = "Booty Bay'deki Scooty ile konuş. Önce Rig Wars gerekir." } },
    { id = 2843, name = "Gnomer-gooooone!", level = 35, req = 20, giver = "Scooty, Booty Bay, Northern Stranglethorn (27.6, 77.5)", turnin = "Scooty, Booty Bay, Northern Stranglethorn (27.6, 77.5)", note = { enUS = "Wait for Scooty to calibrate the Goblin Transponder. Requires Chief Engineer Scooty first.", trTR = "Scooty'nin Goblin Transponder'ı ayarlamasını bekle. Önce Chief Engineer Scooty gerekir." } },
    { id = 2904, name = "A Fine Mess", level = 30, req = 24, giver = "Kernobee, room right of the Clean Room, Gnomeregan", turnin = "Scooty, Booty Bay, Northern Stranglethorn (27.6, 77.5)", note = { enUS = "Escort Kernobee to the Clockwerk Run exit, then report to Scooty in Booty Bay.", trTR = "Kernobee'ye Clockwerk Run çıkışına kadar eşlik et, sonra Booty Bay'deki Scooty'ye rapor ver." } },
    { id = 2922, name = "Save Techbot's Brain!", level = 26, req = 20, side = "Alliance", giver = "Tinkmaster Overspark, Tinkertown, Ironforge (69.5, 50.3)", turnin = "Tinkmaster Overspark, Tinkertown, Ironforge (69.5, 50.3)", note = { enUS = "Collect Techbot's Memory Core in Gnomeregan. Requires Tinkmaster Overspark first.", trTR = "Gnomeregan'da Techbot's Memory Core'u topla. Önce Tinkmaster Overspark gerekir." } },
    { id = 2926, name = "Gnogaine", level = 27, req = 20, giver = "Ozzie Togglevolt, Kharanos, Dun Morogh", turnin = "Ozzie Togglevolt, Kharanos, Dun Morogh", note = { enUS = "Use the Empty Leaden Collection Phial on Irradiated Invaders or Irradiated Pillagers. Requires The Day After first.", trTR = "Empty Leaden Collection Phial'ı Irradiated Invaders ya da Irradiated Pillagers üzerinde kullan. Önce The Day After gerekir." } },
    { id = 2928, name = "Gyrodrillmatic Excavationators", level = 30, req = 20, side = "Alliance", giver = "Shoni the Shilent, Dwarven Quarter, Stormwind City (62.6, 34.1)", turnin = "Shoni the Shilent, Dwarven Quarter, Stormwind City (62.6, 34.1)", note = { enUS = "Collect 24 Robo-mechanical Guts in Gnomeregan.", trTR = "Gnomeregan'da 24 Robo-mechanical Guts topla." } },
    { id = 2962, name = "The Only Cure is More Green Glow", level = 30, req = 20, giver = "Ozzie Togglevolt, Kharanos, Dun Morogh", turnin = "Ozzie Togglevolt, Kharanos, Dun Morogh", note = { enUS = "Collect High Potency Radioactive Fallout in Gnomeregan; it collapses quickly. Keep your Heavy Leaden Collection Phial. Requires Gnogaine first.", trTR = "Gnomeregan'da High Potency Radioactive Fallout topla; hızla bozulur. Heavy Leaden Collection Phial'ını sakla. Önce Gnogaine gerekir." } },
    { id = 2924, name = "Essential Artificials", level = 30, req = 24, side = "Alliance", giver = "Klockmort Spannerspan, Tinkertown, Ironforge (67.9, 46.1)", turnin = "Klockmort Spannerspan, Tinkertown, Ironforge (67.9, 46.1)", note = { enUS = "Collect 12 Essential Artificials in Gnomeregan.", trTR = "Gnomeregan'da 12 Essential Artificials topla." } },
    { id = 2841, name = "Rig Wars", level = 35, req = 25, side = "Horde", giver = "Nogg, Valley of Honor, Orgrimmar (76.0, 25.4)", turnin = "Nogg, Valley of Honor, Orgrimmar (76.0, 25.4)", note = { enUS = "Retrieve the Rig Blueprints and Thermaplugg's Safe Combination from Gnomeregan.", trTR = "Gnomeregan'dan Rig Blueprints ve Thermaplugg's Safe Combination'ı getir." } },
    { id = 2929, name = "The Grand Betrayal", level = 35, req = 25, side = "Alliance", giver = "High Tinker Mekkatorque, Tinkertown, Ironforge (68.8, 49.0)", turnin = "High Tinker Mekkatorque, Tinkertown, Ironforge (68.8, 49.0)", note = { enUS = "Kill Mekgineer Thermaplugg in Gnomeregan.", trTR = "Gnomeregan'da Mekgineer Thermaplugg'ı öldür." } },
    { id = 2930, name = "Data Rescue", level = 30, req = 25, side = "Alliance", giver = "Master Mechanic Castpipe, Tinkertown, Ironforge (69.8, 48.1)", turnin = "Master Mechanic Castpipe, Tinkertown, Ironforge (69.8, 48.1)", note = { enUS = "Collect a Prismatic Punch Card in Gnomeregan.", trTR = "Gnomeregan'da bir Prismatic Punch Card topla." } },
    { id = 2951, name = "The Sparklematic 5200!", level = 30, req = 25, giver = "The Sparklematic 5200, Gnomeregan", turnin = "The Sparklematic 5200, Gnomeregan", note = { enUS = "Insert a Grime-Encrusted Item into the Sparklematic 5200. Have three silver coins ready to start the machine.", trTR = "Sparklematic 5200'e bir Grime-Encrusted Item koy. Makineyi çalıştırmak için üç gümüş hazır tut." } },
    { id = 2945, name = "Grime-Encrusted Ring", level = 34, req = 28, giver = "Starts from the Grime-Encrusted Ring, dropped in Gnomeregan.", turnin = "Sparklematic 5200, Gnomeregan", note = { enUS = "Clean the Grime-Encrusted Ring in the Sparklematic 5200 inside Gnomeregan; the quest ends there.", trTR = "Grime-Encrusted Ring'i Gnomeregan içindeki Sparklematic 5200'de temizle; görev orada biter." } },
  },
  loot = {
    { boss = "Grubbis", items = {
      { id = 9445, n = "Grubbis Paws", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 274043, n = "Irradiated Shield", q = 3, s = "Shield, Shield", c = "123456789" },
      { id = 274042, n = "Skullduggery Belt", q = 3, s = "Waist, Leather", c = "49", a = "36" },
    } },
    { boss = "Viscous Fallout", items = {
      { id = 9454, n = "Acidic Walkers", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 9453, n = "Toxic Revenger", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 9452, n = "Hydrocane", q = 3, s = "Two-Hand, Staff", c = "5789632" },
    } },
    { boss = "Electrocutioner 6000", items = {
      { id = 9447, n = "Electrocutioner Lagnut", q = 3, s = "Finger, Trinket", c = "123456789" },
      { id = 9446, n = "Electrocutioner Leg", q = 3, s = "Main Hand, Sword", c = "124378" },
      { id = 9448, n = "Spidertank Oilrag", q = 3, s = "Wrist, Cloth", c = "578", a = "926" },
    } },
    { boss = "Crowd Pummeler 9-60", items = {
      { id = 9449, n = "Manual Crowd Pummeler", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 9450, n = "Gnomebot Operating Boots", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 274068, n = "Thermaplugg Medal of Honor", q = 3, s = "Neck, Trinket", c = "123456789" },
    } },
    { boss = "Dark Iron Ambassador", items = {
      { id = 9455, n = "Emissary Cuffs", q = 3, s = "Wrist, Leather", c = "49", a = "36" },
      { id = 9456, n = "Glass Shooter", q = 3, s = "Ranged, Gun", c = "143" },
      { id = 9457, n = "Royal Diplomatic Scepter", q = 3, s = "Main Hand, Mace", c = "124695" },
    } },
    { boss = "Mekgineer Thermaplugg", items = {
      { id = 9492, n = "Electromagnetic Gigaflux Reactivator", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 9461, n = "Charged Gear", q = 3, s = "Finger, Trinket", c = "123456789" },
      { id = 9458, n = "Thermaplugg's Central Core", q = 3, s = "Shield, Shield", c = "123456789" },
      { id = 9459, n = "Thermaplugg's Left Arm", q = 3, s = "Two-Hand, Axe", c = "1236" },
    } },
    { boss = "Trash Drops", items = {
      { id = 9508, n = "Mechbuilder's Overalls", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 9491, n = "Hotshot Pilot's Gloves", q = 3, s = "Hands, Cloth", c = "578", a = "926" },
      { id = 9509, n = "Petrolspill Leggings", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 9510, n = "Caverndeep Trudgers", q = 3, s = "Feet, Mail", c = "36", a = "12" },
      { id = 9487, n = "Hi-Tech Supergun", q = 3, s = "Ranged, Gun", c = "143" },
      { id = 9485, n = "Vibroblade", q = 3, s = "One-Hand, Axe", c = "1236" },
      { id = 9488, n = "Oscillating Power Hammer", q = 3, s = "One-Hand, Mace", c = "124695" },
      { id = 9486, n = "Supercharger Battle Axe", q = 3, s = "Two-Hand, Axe", c = "1236" },
      { id = 9490, n = "Gizmotron Megachopper", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 9489, n = "Gyromatic Icemaker", q = 3, s = "Ranged, Wand", c = "578" },
    } },
  },
})
