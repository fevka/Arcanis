-- Arcanis: meslek aletleri (uretilmis: tools/import_trainer_spells.py). Elle duzenleme.
-- Yalniz yapi, istemcinin SpellTotems tablosundan: meslek -> { { esya, ad, from = aleti isteyen ilk tarifin
-- sari esiginin 15 alti (yaklasik ilk gerektigi beceri) } }. Mining / Skinning toplama aleti ProfGuides'ta eklenir.
local _, ns = ...

ns.ProfessionTools = {
  ["Alchemy"] = { { item = 9149, name = "Philosopher's Stone", from = 225 } },
  ["Blacksmithing"] = { { item = 5956, name = "Blacksmith Hammer", from = 1 } },
  ["Enchanting"] = { { item = 6218, name = "Runed Copper Rod", from = 1 }, { item = 6339, name = "Runed Silver Rod", from = 85 }, { item = 11130, name = "Runed Golden Rod", from = 125 }, { item = 11145, name = "Runed Truesilver Rod", from = 210 }, { item = 16207, name = "Runed Arcanite Rod", from = 280 } },
  ["Engineering"] = { { item = 6219, name = "Arclight Spanner", from = 1 }, { item = 5956, name = "Blacksmith Hammer", from = 1 }, { item = 10498, name = "Gyromatic Micro-Adjustor", from = 110 } },
  ["Mining"] = { { item = 2901, name = "Mining Pick", from = 1 } },
}
