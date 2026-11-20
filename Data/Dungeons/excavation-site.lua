local _, ns = ...
ns.DungeonExtra("excavation-site", {
  quests = {
    { id = 98815, name = "Highland Hides", level = 28, req = 24, side = "Alliance", giver = "James Halloran, Menethil Harbor, Wetlands (8.6, 55.7)", turnin = "James Halloran, Menethil Harbor, Wetlands (8.6, 55.7)", note = { enUS = "Collect 4 Thicket Raptor Hides in the Excavation Site and return them to James Halloran.", trTR = "Excavation Site'ta 4 Thicket Raptor Hide topla ve James Halloran'a geri götür." } },
    { id = 95646, name = "Horrors in the Highland", level = 31, req = 24, side = "Alliance", giver = "Rethiel the Greenwarden, Wetlands (56.4, 40.4)", turnin = "Rethiel the Greenwarden, Wetlands (56.4, 40.4)", note = { enUS = "Kill a Highland Horror in the Excavation Site and bring its root core to Rethiel the Greenwarden.", trTR = "Excavation Site'ta bir Highland Horror öldür ve kök çekirdeğini Rethiel the Greenwarden'a götür." } },
    { id = 95682, name = "Open the Maw", level = 31, req = 24, side = "Horde", giver = "Deathstalker Agent, just outside Excavation Site, Wetlands", turnin = "Deathstalker Agent, just outside Excavation Site, Wetlands", note = { enUS = "Kill 2 Dragonmaw Saboteurs and 4 Dragonmaw Warders inside, recover the Dragonmaw Dispatch and report to the Deathstalker Agent outside.", trTR = "İçeride 2 Dragonmaw Saboteur ve 4 Dragonmaw Warder öldür, Dragonmaw Dispatch'i geri al ve dışarıdaki Deathstalker Agent'a rapor ver." } },
    { id = 95697, name = "Changing Tastes", level = 31, req = 24, side = "Horde", giver = "Borstan, The Drag, Orgrimmar (57.2, 53.3)", turnin = "Borstan, The Drag, Orgrimmar (57.2, 53.3)", note = { enUS = "Enter the Excavation Sites in the Wetlands and bring back 4 Thicket Raptor Meat.", trTR = "Wetlands'teki Excavation Sites'a gir ve 4 Thicket Raptor Meat getir." } },
    { id = 95772, name = "Songblade Search", level = 31, req = 24, side = "Alliance", giver = "Dorin Songblade, Redridge Mountains (25.8, 46.4)", turnin = "Daewyn Songblade, inside Excavation Site, Wetlands", note = { enUS = "Find Dorin Songblade's brother, Daewyn, in Whelgar's Excavation Site.", trTR = "Whelgar's Excavation Site'ta Dorin Songblade'in kardeşi Daewyn'i bul." } },
    { id = 95795, name = "Fallen in the Fen", level = 31, req = 24, side = "Alliance", giver = "Daewyn Songblade, inside Excavation Site, Wetlands", turnin = "Dorin Songblade, Lakeshire, Redridge Mountains (25.8, 46.4)", note = { enUS = "Report Daewyn's fate to Dorin Songblade in Lakeshire.", trTR = "Daewyn'in akıbetini Lakeshire'daki Dorin Songblade'e bildir." } },
    { id = 95809, name = "Heartwoven", level = 31, req = 24, side = "Alliance", giver = "Ardin Grassman, inside Excavation Site, Wetlands", turnin = "Caitlin Grassman, Menethil Harbor, Wetlands (11.9, 58.8)", note = { enUS = "Take the Reed-woven Heart to Caitlin Grassman in Menethil Harbor.", trTR = "Reed-woven Heart'ı Menethil Harbor'daki Caitlin Grassman'a götür." } },
    { id = 98823, name = "Earthen Echo", level = 31, req = 24, side = "Horde", giver = "Bashana Runetotem, Elder Rise, Thunder Bluff (71.1, 34.2)", turnin = "Muln Earthfury, Skywatcher Plateau, Mulgore", note = { enUS = "Bring the Titan Relic to Muln Earthfury on the Skywatcher Plateau in northwest Mulgore.", trTR = "Titan Relic'i Mulgore'un kuzeybatısındaki Skywatcher Plateau'da Muln Earthfury'ye götür." } },
    { id = 98824, name = "Prehistoric Prism", level = 31, req = 24, side = "Alliance", giver = "Prospector Whelgar, Whelgar's Excavation Site, Wetlands (38.8, 52.4)", turnin = "High Explorer Magellas, Hall of Explorers, Ironforge (69.9, 18.6)", note = { enUS = "Bring the Titan Relic to High Explorer Magellas in Ironforge's Hall of Explorers.", trTR = "Titan Relic'i Ironforge'daki Hall of Explorers'da High Explorer Magellas'a götür." } },
  },
  loot = {
    { boss = "Saltspine", items = {
      { id = 273024, n = "Glinteye Slippers", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 273022, n = "Supple Bellyskin Leggings", q = 3, s = "Legs, Leather", c = "49", a = "36" },
      { id = 273023, n = "Saltscale Girdle", q = 3, s = "Waist, Mail", c = "36", a = "12" },
    } },
    { boss = "Shadetooth", items = {
      { id = 273025, n = "Raptorclaw Greaves", q = 3, s = "Feet, Mail", c = "36", a = "12" },
      { id = 273027, n = "Raptor's Gaze", q = 3, s = "Held In Off-hand", c = "578926" },
      { id = 273106, n = "Blueprint: Greenhouse", q = 2, s = "Blueprint" },
    } },
    { boss = "Relic Guardian", items = {
      { id = 273028, n = "Reliquary Mantle", q = 3, s = "Shoulder, Mail", c = "36", a = "12" },
      { id = 273029, n = "Golemsight Long Gun", q = 3, s = "Ranged, Gun", c = "143" },
      { id = 273030, n = "Ring of Power Regulation", q = 3, s = "Finger", c = "123456789" },
      { id = 270866, n = "Titan Relic", q = 1, s = "Quest Item" },
      { id = 273097, n = "Blueprint: Rock Garden", q = 2, s = "Blueprint" },
    } },
  },
})
