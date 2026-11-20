local _, ns = ...
ns.DungeonExtra("rfd", {
  quests = {
    { id = 6521, name = "An Unholy Alliance", level = 36, req = 28, side = "Horde", giver = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", turnin = "Varimathras, Royal Quarter, Undercity (56.2, 92.2)", note = { enUS = "Bring Ambassador Malcin's Head to Varimathras in the Undercity.", trTR = "Ambassador Malcin's Head'i Undercity'deki Varimathras'a götür." } },
    { id = 6626, name = "A Host of Evil", level = 35, req = 28, giver = "Myriam Moonsinger, outside the Razorfen Downs portal, Northern Barrens (49.0, 94.9)", turnin = "Myriam Moonsinger, outside the Razorfen Downs portal, Northern Barrens (49.0, 94.9)", note = { enUS = "Kill 8 Razorfen Battleguards, 8 Razorfen Thornweavers and 8 Death's Head Cultists in Razorfen Downs.", trTR = "Razorfen Downs'da 8 Razorfen Battleguards, 8 Razorfen Thornweavers ve 8 Death's Head Cultists öldür." } },
    { id = 3523, name = "Scourge of the Downs", level = 37, req = 32, giver = "Belnistrasz, Murder Pens, Razorfen Downs", turnin = "Belnistrasz, Murder Pens, Razorfen Downs", note = { enUS = "To agree to help Belnistrasz, speak to him again and hand back the Oathstone he gave you.", trTR = "Belnistrasz'a yardım etmeyi kabul etmek için onunla tekrar konuş ve sana verdiği Oathstone'u geri ver." } },
    { id = 3525, name = "Extinguishing the Idol", level = 37, req = 32, giver = "Belnistrasz, Murder Pens, Razorfen Downs", turnin = "Belnistrasz, Murder Pens, Razorfen Downs", note = { enUS = "Escort Belnistrasz to the quilboar idol and protect him while he performs the ritual to shut it down. Requires Scourge of the Downs first.", trTR = "Belnistrasz'a quilboar idolüne kadar eşlik et ve idolü kapatmak için ritüeli yaparken onu koru. Önce Scourge of the Downs gerekir." } },
    { id = 3341, name = "Bring the End", level = 42, req = 37, side = "Horde", giver = "Andrew Brownell, Magic Quarter, Undercity (74.0, 33.3)", turnin = "Andrew Brownell, Magic Quarter, Undercity (74.0, 33.3)", note = { enUS = "Kill Amnennar the Coldbringer in Razorfen Downs and bring his skull to Andrew Brownell.", trTR = "Razorfen Downs'da Amnennar the Coldbringer'ı öldür ve kafatasını Andrew Brownell'e götür." } },
    { id = 3636, name = "Bring the Light", level = 42, req = 39, side = "Alliance", giver = "Archbishop Benedictus, Cathedral, Stormwind City (50.3, 45.5)", turnin = "Archbishop Benedictus, Cathedral, Stormwind City (50.3, 45.5)", note = { enUS = "Kill Amnennar the Coldbringer in Razorfen Downs.", trTR = "Razorfen Downs'da Amnennar the Coldbringer'ı öldür." } },
  },
  loot = {
    { boss = "Tuten'kash", items = {
      { id = 10776, n = "Silky Spider Cape", q = 3, s = "Back, Cloth", c = "578", a = "926" },
      { id = 10775, n = "Carapace of Tuten'kash", q = 3, s = "Chest, Plate", c = "123456789" },
      { id = 10777, n = "Arachnid Gloves", q = 3, s = "Hands, Leather", c = "49", a = "36" },
    } },
    { boss = "Mordresh Fire Eye", items = {
      { id = 10769, n = "Glowing Eye of Mordresh", q = 3, s = "Neck, Trinket", c = "123456789" },
      { id = 10771, n = "Deathmage Sash", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
      { id = 10770, n = "Mordresh's Lifeless Skull", q = 3, s = "Held In Off-hand, Trinket", c = "578926" },
    } },
    { boss = "Glutton", items = {
      { id = 10774, n = "Fleshhide Shoulders", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 10772, n = "Glutton's Cleaver", q = 3, s = "One-Hand, Axe", c = "1236" },
    } },
    { boss = "Ragglesnout", items = {
      { id = 10768, n = "Boar Champion's Belt", q = 3, s = "Waist, Mail", c = "36", a = "12" },
      { id = 10767, n = "Savage Boar's Guard", q = 3, s = "Shield, Shield", c = "123456789" },
      { id = 10758, n = "X'caliboar", q = 3, s = "Two-Hand, Sword", c = "124378" },
    } },
    { boss = "Amnennar the Coldbringer", items = {
      { id = 10763, n = "Icemetal Barbute", q = 3, s = "Head, Plate", c = "123456789" },
      { id = 10762, n = "Robes of the Lich", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 10764, n = "Deathchill Armor", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 10761, n = "Coldrage Dagger", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 10765, n = "Bonefingers", q = 2, s = "Hands, Leather", c = "49", a = "36" },
    } },
    { boss = "Plaguemaw the Rotting", items = {
      { id = 10766, n = "Plaguerot Sprig", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 10760, n = "Swine Fists", q = 2, s = "Hands, Leather", c = "49", a = "36" },
    } },
    { boss = "Trash Drops", items = {
      { id = 10574, n = "Corpseshroud", q = 3, s = "Head, Cloth", c = "578", a = "926" },
      { id = 10581, n = "Death's Head Vestment", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 10583, n = "Quillward Harness", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 10584, n = "Stormgale Fists", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 10578, n = "Thoughtcast Boots", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 10582, n = "Briar Tredders", q = 3, s = "Feet, Leather", c = "49", a = "36" },
      { id = 10572, n = "Freezing Shard", q = 3, s = "Ranged, Wand", c = "578" },
      { id = 10567, n = "Quillshooter", q = 3, s = "Ranged, Bow", c = "143" },
      { id = 10571, n = "Ebony Boneclub", q = 3, s = "One-Hand, Mace", c = "124695" },
      { id = 10570, n = "Manslayer", q = 3, s = "Two-Hand, Axe", c = "1236" },
      { id = 10573, n = "Boneslasher", q = 3, s = "Two-Hand, Sword", c = "124378" },
    } },
  },
})
