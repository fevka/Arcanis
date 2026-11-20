local _, ns = ...
ns.DungeonExtra("stockade", {
  quests = {
    { id = 386, name = "What Comes Around...", level = 25, req = 22, side = "Alliance", giver = "Guard Berton, Lakeshire, Redridge Mountains (21.2, 46.6)", turnin = "Guard Berton, Lakeshire, Redridge Mountains (21.2, 46.6)", note = { enUS = "Kill Targorr the Dread in The Stockade and bring his head to Guard Berton.", trTR = "The Stockade'de Targorr the Dread'i öldür ve kafasını Guard Berton'a götür." } },
    { id = 377, name = "Crime and Punishment", level = 26, req = 22, side = "Alliance", giver = "Councilman Millstipe, Darkshire, Duskwood (71.9, 47.8)", turnin = "Councilman Millstipe, Darkshire, Duskwood (71.9, 47.8)", note = { enUS = "Kill Dextren Ward in The Stockade and bring his hand to Councilman Millstipe.", trTR = "The Stockade'de Dextren Ward'ı öldür ve elini Councilman Millstipe'a götür." } },
    { id = 387, name = "Quell The Uprising", level = 26, req = 22, side = "Alliance", giver = "Warden Thelwater, outside The Stockade, Stormwind City (51.5, 69.4)", turnin = "Warden Thelwater, outside The Stockade, Stormwind City (51.5, 69.4)", note = { enUS = "Kill 10 Defias Prisoners, 8 Defias Convicts and 8 Defias Insurgents inside The Stockade.", trTR = "The Stockade içinde 10 Defias Prisoner, 8 Defias Convict ve 8 Defias Insurgent öldür." } },
    { id = 388, name = "The Color of Blood", level = 26, req = 22, side = "Alliance", giver = "Nikova Raskol, Old Town, Stormwind City (73.8, 54.6)", turnin = "Nikova Raskol, Old Town, Stormwind City (73.8, 54.6)", note = { enUS = "Collect 10 Red Wool Bandanas from Defias prisoners in The Stockade.", trTR = "The Stockade'deki Defias mahkumlarından 10 Red Wool Bandana topla." } },
    { id = 378, name = "The Fury Runs Deep", level = 27, req = 22, side = "Alliance", giver = "Motley Garmason, Dun Modr, Wetlands (49.7, 18.2)", turnin = "Motley Garmason, Dun Modr, Wetlands (49.7, 18.2)", note = { enUS = "Kill Kam Deepfury in The Stockade and bring his head to Motley Garmason. Requires The Dark Iron War first.", trTR = "The Stockade'de Kam Deepfury'yi öldür ve kafasını Motley Garmason'a götür. Önce The Dark Iron War gerekir." } },
    { id = 391, name = "The Stockade Riots", level = 29, req = 16, side = "Alliance", giver = "Warden Thelwater, outside The Stockade, Stormwind City (51.5, 69.4)", turnin = "Warden Thelwater, outside The Stockade, Stormwind City (51.5, 69.4)", note = { enUS = "Kill Bazil Thredd in The Stockade and bring his head to Warden Thelwater. Requires Bazil Thredd first.", trTR = "The Stockade'de Bazil Thredd'i öldür ve kafasını Warden Thelwater'a götür. Önce Bazil Thredd gerekir." } },
  },
  loot = {
    { boss = "Targorr the Dread", items = {
      { id = 273805, n = "Blackrock Harness", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 273804, n = "Executioner Mantle", q = 3, s = "Shoulder, Leather", c = "49", a = "36" },
      { id = 273806, n = "Dark Horde Band", q = 3, s = "Finger", c = "123456789" },
      { id = 251380, n = "Plans: Veteran's Silvered Chain Helm", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 251382, n = "Plans: Protector's Silvered Chain Helm", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 253942, n = "Pattern: Filigreed Flame Leggings", q = 3, s = "Recipe, Tailoring", c = "123456789" },
    } },
    { boss = "Kam Deepfury", items = {
      { id = 2280, n = "Kam's Walking Stick", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 273807, n = "Demolition Girdle", q = 3, s = "Waist, Leather", c = "49", a = "36" },
      { id = 273808, n = "Bridgebreaker Bindings", q = 3, s = "Wrist, Cloth", c = "578", a = "926" },
      { id = 251379, n = "Plans: Crusader's Silvered Chain Leggings", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 252825, n = "Pattern: Wisdom's Leather Leggings", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Hamhock", items = {
      { id = 273809, n = "Hamhock's Cleaver", q = 3, s = "Main Hand, Axe", c = "1236" },
      { id = 273810, n = "Ogre Grips", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 273811, n = "Repurposed Rack", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 251377, n = "Plans: Protector's Silvered Chain Leggings", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
    } },
    { boss = "Dextren Ward", items = {
      { id = 273817, n = "Graverobber's Shovel", q = 3, s = "Two-Hand, Mace", c = "124695" },
      { id = 273819, n = "Boneslicer", q = 3, s = "Two-Hand, Polearm", c = "1239" },
      { id = 273820, n = "Nightskulker Ring", q = 3, s = "Finger", c = "123456789" },
      { id = 251375, n = "Plans: Veteran's Silvered Chain Leggings", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 251376, n = "Plans: Guard's Silvered Chain Leggings", q = 3, s = "Recipe, Blacksmithing", c = "123456789" },
      { id = 252820, n = "Pattern: Brawler's Leather Legguards", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
      { id = 252821, n = "Pattern: Trapper's Leather Legguards", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
    } },
    { boss = "Bazil Thredd", items = {
      { id = 273827, n = "Debt Collector", q = 3, s = "Main Hand, Sword", c = "124378" },
      { id = 273824, n = "Defias Jailbreakers", q = 3, s = "Hands, Leather", c = "49", a = "36" },
      { id = 273825, n = "Red Wool Cloak", q = 3, s = "Back, Cloth", c = "123456789" },
      { id = 273829, n = "Concealed Hand Crossbow", q = 3, s = "Ranged, Crossbow", c = "143" },
      { id = 252824, n = "Pattern: Stormrider's Leather Kilt", q = 3, s = "Recipe, Leatherworking", c = "49", a = "36" },
      { id = 253976, n = "Pattern: Filigreed Pristine Circlet", q = 3, s = "Recipe, Tailoring", c = "123456789" },
      { id = 253986, n = "Pattern: Filigreed Shining Circlet", q = 3, s = "Recipe, Tailoring", c = "123456789" },
    } },
    { boss = "Bruegal Ironknuckle", items = {
      { id = 3228, n = "Jimmied Handcuffs", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 2941, n = "Prison Shank", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 2942, n = "Iron Knuckles", q = 3, s = "One-Hand, Fist Weapon", c = "14693" },
    } },
    { boss = "Trash Drops", items = {
      { id = 274092, n = "Sharpened Cutlery", q = 3, s = "Thrown", c = "143" },
      { id = 1076, n = "Defias Renegade Ring", q = 3, s = "Finger", c = "123456789" },
    } },
  },
})
