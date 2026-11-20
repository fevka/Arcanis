-- Arcanis: parcalama (disenchant) tablosu, elle yazildi (oyun mekanigi; Helpers/Gold.lua Gold:Disenchant kullanir).
-- Esya seviyesi araliklari istemcinin ItemDisenchantLoot tablosuyla ayni (silah/zirh, kalite 2-4); malzemeler
-- sunucuda, istemcide yok: bilinen Classic oranlari. Beceri esigi istemcide 0, Classic kurali (yaklasik).
--   uncommon[i] = { en dusuk, en yuksek esya seviyesi, toz, oz, kirik }: { esya, en az, en cok }
--     zirh: toz %75 / oz %20 / kirik %5 (ilk aralikta kirik yok: %80 / %20); silahta toz ile oz yer degistirir.
--   rare / epic[i] = { en dusuk, en yuksek, { { esya, en az, en cok, sans } } }
local _, ns = ...

ns.Disenchant = {
  uncommon = {
    { 5, 15, { 10940, 1, 2 }, { 10938, 1, 2 } },
    { 16, 20, { 10940, 2, 3 }, { 10939, 1, 2 }, { 10978, 1, 1 } },
    { 21, 25, { 10940, 4, 6 }, { 10998, 1, 2 }, { 10978, 1, 1 } },
    { 26, 30, { 11083, 1, 2 }, { 11082, 1, 2 }, { 11084, 1, 1 } },
    { 31, 35, { 11083, 2, 5 }, { 11134, 1, 2 }, { 11138, 1, 1 } },
    { 36, 40, { 11137, 1, 2 }, { 11135, 1, 2 }, { 11139, 1, 1 } },
    { 41, 45, { 11137, 2, 5 }, { 11174, 1, 2 }, { 11177, 1, 1 } },
    { 46, 50, { 11176, 1, 2 }, { 11175, 1, 2 }, { 11178, 1, 1 } },
    { 51, 55, { 11176, 2, 5 }, { 16202, 1, 2 }, { 14343, 1, 1 } },
    { 56, 60, { 16204, 1, 2 }, { 16203, 1, 2 }, { 14344, 1, 1 } },
    { 61, 99, { 16204, 2, 5 }, { 16203, 2, 3 }, { 14344, 1, 1 } },
  },
  rare = {
    { 5, 25, { { 10978, 1, 1, 1 } } },
    { 26, 30, { { 11084, 1, 1, 1 } } },
    { 31, 35, { { 11138, 1, 1, 1 } } },
    { 36, 40, { { 11139, 1, 1, 1 } } },
    { 41, 45, { { 11177, 1, 1, 1 } } },
    { 46, 50, { { 11178, 1, 1, 1 } } },
    { 51, 55, { { 14343, 1, 1, 1 } } },
    { 56, 99, { { 14344, 1, 1, 0.995 }, { 20725, 1, 1, 0.005 } } },
  },
  epic = {
    { 40, 45, { { 11177, 2, 4, 1 } } },
    { 46, 50, { { 11178, 2, 4, 1 } } },
    { 51, 55, { { 14343, 2, 4, 1 } } },
    { 56, 60, { { 20725, 1, 1, 1 } } },
    { 61, 99, { { 20725, 1, 2, 1 } } },
  },
  -- gereken Enchanting becerisi: { esya seviyesi en cok, beceri }
  skill = { { 20, 1 }, { 25, 25 }, { 30, 50 }, { 35, 75 }, { 40, 100 }, { 45, 125 }, { 50, 150 }, { 55, 175 },
            { 60, 200 }, { 99, 225 } },
}
