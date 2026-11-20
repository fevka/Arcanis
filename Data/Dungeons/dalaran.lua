local _, ns = ...
ns.DungeonExtra("dalaran", {
  quests = {
    { id = 92456, name = "A Green Sample", level = 33, req = 24, side = "Alliance", giver = "Shylamiir, Stormwind City (31.5, 62.6)", turnin = "Shylamiir, Stormwind City (31.5, 62.6)", note = { enUS = "Collect a Fel Infused Blossom from Dalaran's central garden.", trTR = "Dalaran'ın merkez bahçesinden bir Fel Infused Blossom topla." }, rew = "Choose: Vine Pruner's Cloak or Thorn Protecting Girdle\\n3950 XP" },
    { id = 92489, name = "Power Overwhelming", level = 33, req = 24, side = "Alliance", giver = "High Sorcerer Andromath, Stormwind City (48.7, 87.6)", turnin = "High Sorcerer Andromath, Stormwind City (48.7, 87.6)", note = { enUS = "Kill Arcanic Enigma, the Mana Elemental, in the City of Dalaran.", trTR = "City of Dalaran'da Mana Elemental Arcanic Enigma'yı öldür." }, rew = "Choose: Violet Sash or Runebound Gloves\\n1g\\n3950 XP" },
    { id = 96986, name = "The Grave Knight", level = 33, req = 24, side = "Horde", giver = "Melisara, Tarren Mill, Hillsbrad Foothills (62.6, 20.6)", turnin = "Melisara, Tarren Mill, Hillsbrad Foothills (62.6, 20.6)", note = { enUS = "Defeat Atrexis the Grave Knight in the Dalaran Underbelly.", trTR = "Dalaran Underbelly'de Grave Knight Atrexis'i yen." }, rew = "Choose: Gravewalker Boots or Undead Knight's Bracers\\n1g\\n3950 XP" },
    { id = 96987, name = "Opportunistic Education", level = 33, req = 24, side = "Horde", giver = "Rexxie Copperclutch, near the Dalaran sewer entrance", turnin = "Rexxie Copperclutch, near the Dalaran sewer entrance", note = { enUS = "Recover The Founding of Dalaran and deliver it to Rexxie Copperclutch.", trTR = "The Founding of Dalaran'ı geri al ve Rexxie Copperclutch'a götür." }, rew = "Choose: Item 279845 or Item 279846\\n3950 XP" },
    { id = 96988, name = "Source of Power", level = 33, req = 24, side = "Horde", giver = "Doctor Martin Felben, Undercity (46.6, 74.1)", turnin = "Doctor Martin Felben, Undercity (46.6, 74.1)", note = { enUS = "Collect 6 Cracked Sentry Cores from the constructs in Dalaran.", trTR = "Dalaran'daki konstrüktlerden 6 Cracked Sentry Core topla." }, rew = "Choose: Unstable Power Core or Construct Cloak\\n3950 XP" },
  },
  loot = {
    { boss = "Unstable Sentinel", items = {
      { id = 273046, n = "Guardian's Dualblade", q = 3, s = "Weapon", c = "123456789" },
    } },
    { boss = "Shade of the Archmage", items = {
      { id = 273052, n = "Ponderous Orb", q = 3, s = "Held In Off-hand", c = "578926" },
    } },
  },
})
