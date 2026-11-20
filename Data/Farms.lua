-- Arcanis: altin kasma rehberi verisi (ns.FarmData).
-- Her kayit: id, title, min/max seviye, faction (nil = iki taraf), zone, method (kill/gather/skin),
-- prof = { "Mining", skill } gerekiyorsa, items = { { itemId, saatlikTahmin }, ... }, tip.
-- Saatlik miktarlar ortalama bir oyuncu icin kaba tahmindir; altin/saat canli fiyatla (tarama ya da
-- paket fiyat listesi) hesaplanir. Konumlar bolge adiyla verilir; tam rota icin /wf rec ile kayit alinabilir.
local _, ns = ...

ns.FarmData = {
  -- Kumas (her sinif)
  { id = "linen-westfall", title = { enUS = "Linen Cloth: Defias", trTR = "Linen Cloth: Defias" }, min = 11, max = 18, faction = "Alliance", zone = "Westfall",
    method = "kill", items = { { 2589, 60 } }, tip = { enUS = "Defias camps in the north and south of Westfall. Humanoids drop the most cloth.", trTR = "Westfall'un kuzeyindeki ve güneyindeki Defias kampları. Kumaşı en çok insansılar düşürür." } },
  { id = "linen-barrens", title = { enUS = "Linen Cloth: quilboars", trTR = "Linen Cloth: quilboar'lar" }, min = 11, max = 18, faction = "Horde", zone = "Northern Barrens",
    method = "kill", items = { { 2589, 55 } }, tip = { enUS = "Razormane quilboar camps. Pull two at a time.", trTR = "Razormane quilboar kampları. İkişer çek." } },
  { id = "wool-redridge", title = { enUS = "Wool Cloth: gnolls", trTR = "Wool Cloth: gnoll'lar" }, min = 18, max = 26, zone = "Redridge Mountains",
    method = "kill", items = { { 2592, 55 } }, tip = { enUS = "Redridge gnolls and Blackrock orcs. Pairs well with Skinning or Mining.", trTR = "Redridge gnoll'ları ve Blackrock orkları. Skinning veya Mining ile birlikte iyi gider." } },
  { id = "silk-stv", title = { enUS = "Silk Cloth: trolls", trTR = "Silk Cloth: troll'ler" }, min = 30, max = 40, zone = "Northern Stranglethorn",
    method = "kill", items = { { 4306, 70 } }, tip = { enUS = "Troll ruins are dense and respawn fast. Bring water.", trTR = "Troll harabeleri kalabalıktır ve hızlı yeniden doğar. Yanına su al." } },
  { id = "mageweave-badlands", title = { enUS = "Mageweave Cloth: Dark Iron dwarves", trTR = "Mageweave Cloth: Dark Iron dwarf'ları" }, min = 40, max = 48, zone = "Badlands",
    method = "kill", items = { { 4338, 65 }, { 7067, 3 } }, tip = { enUS = "Dark Iron dwarves; rock elementals nearby drop Elemental Earth.", trTR = "Dark Iron dwarf'ları; yakındaki kaya elementalleri Elemental Earth düşürür." } },
  { id = "runecloth-epl", title = { enUS = "Runecloth: Scourge undead", trTR = "Runecloth: Scourge ölümsüzleri" }, min = 52, max = 60, zone = "Eastern Plaguelands",
    method = "kill", items = { { 14047, 90 } }, tip = { enUS = "Undead around the towns. Runecloth sells steadily, and turn-ins give reputation.", trTR = "Kasabaların çevresindeki ölümsüzler. Runecloth sürekli satılır, teslimler reputasyon verir." } },
  { id = "felcloth-felwood", title = { enUS = "Felcloth: satyrs", trTR = "Felcloth: satyr'ler" }, min = 50, max = 56, zone = "Felwood",
    method = "kill", items = { { 14256, 6 }, { 14047, 45 } }, tip = { enUS = "Jadefire satyrs drop Felcloth. Demonic Runes are a bonus.", trTR = "Jadefire satyr'leri Felcloth düşürür. Demonic Rune bonus olarak düşer." } },
  -- Elementaller
  { id = "earth-badlands", title = { enUS = "Elemental Earth: Badlands", trTR = "Elemental Earth: Badlands" }, min = 38, max = 46, zone = "Badlands",
    method = "kill", items = { { 7067, 25 } }, tip = { enUS = "Rock and stone elementals across the zone.", trTR = "Bölgedeki kaya ve taş elementalleri." } },
  { id = "fire-searing", title = { enUS = "Elemental Fire: Searing Gorge", trTR = "Elemental Fire: Searing Gorge" }, min = 46, max = 54, zone = "Searing Gorge",
    method = "kill", items = { { 7068, 30 } }, tip = { enUS = "Fire elementals and lava creatures. Crafters want it a lot.", trTR = "Ateş elementalleri ve lav yaratıkları. Zanaatkârlar bunu çok arar." } },
  { id = "fire-burning", title = { enUS = "Elemental Fire: Burning Steppes", trTR = "Elemental Fire: Burning Steppes" }, min = 50, max = 58, zone = "Burning Steppes",
    method = "kill", items = { { 7068, 32 }, { 7077, 1 } }, tip = { enUS = "Blazing elementals; Essence of Fire drops rarely.", trTR = "Alevli elementaller; Essence of Fire nadiren düşer." } },
  { id = "water-dustwallow", title = { enUS = "Elemental Water: Dustwallow Marsh", trTR = "Elemental Water: Dustwallow Marsh" }, min = 36, max = 44, zone = "Dustwallow Marsh",
    method = "kill", items = { { 7070, 22 } }, tip = { enUS = "Water elementals along the coast.", trTR = "Kıyı boyunca su elementalleri." } },
  { id = "living-ungoro", title = { enUS = "Living Essence: Un'Goro Crater", trTR = "Living Essence: Un'Goro Crater" }, min = 52, max = 58, zone = "Un'Goro Crater",
    method = "kill", items = { { 12803, 10 } }, tip = { enUS = "Bloodpetal and other living plants; pairs well with Herbalism.", trTR = "Bloodpetal ve diğer canlı bitkiler; Herbalism ile iyi gider." } },
  -- Madencilik
  { id = "copper-tin", title = { enUS = "Copper and Tin Ore", trTR = "Copper ve Tin Ore" }, min = 8, max = 25, zone = "Redridge Mountains",
    method = "gather", prof = { "Mining", 1 }, items = { { 2770, 40 }, { 2771, 25 } }, tip = { enUS = "Circle the hills; Copper below 65 skill, Tin from 65.", trTR = "Tepelerin çevresinde dön; 65 skill'in altında Copper, 65'ten sonra Tin." } },
  { id = "iron-arathi", title = { enUS = "Iron and Gold Ore", trTR = "Iron ve Gold Ore" }, min = 25, max = 40, zone = "Arathi Highlands",
    method = "gather", prof = { "Mining", 125 }, items = { { 2772, 35 }, { 2776, 3 } }, tip = { enUS = "Follow the mountain edges.", trTR = "Dağ kenarlarını takip et." } },
  { id = "mithril-hinterlands", title = { enUS = "Mithril Ore", trTR = "Mithril Ore" }, min = 40, max = 50, zone = "The Hinterlands",
    method = "gather", prof = { "Mining", 175 }, items = { { 3858, 40 }, { 7911, 3 } }, tip = { enUS = "Troll ruins and cliffs; Truesilver is a rare bonus.", trTR = "Troll harabeleri ve uçurumlar; Truesilver nadir bir bonustur." } },
  { id = "thorium-ungoro", title = { enUS = "Thorium Ore: Un'Goro Crater", trTR = "Thorium Ore: Un'Goro Crater" }, min = 50, max = 60, zone = "Un'Goro Crater",
    method = "gather", prof = { "Mining", 245 }, items = { { 10620, 45 }, { 7911, 3 } }, tip = { enUS = "Run the crater walls clockwise.", trTR = "Krater duvarları boyunca saat yönünde koş." } },
  { id = "thorium-winterspring", title = { enUS = "Thorium Ore: Winterspring", trTR = "Thorium Ore: Winterspring" }, min = 55, max = 60, zone = "Winterspring",
    method = "gather", prof = { "Mining", 245 }, items = { { 10620, 50 } }, tip = { enUS = "Rich nodes in the caves and hills.", trTR = "Mağaralarda ve tepelerde zengin damarlar." } },
  -- Bitki
  { id = "herbs-low", title = { enUS = "Peacebloom, Silverleaf, Earthroot", trTR = "Peacebloom, Silverleaf, Earthroot" }, min = 5, max = 18, zone = "Elwynn Forest",
    method = "gather", prof = { "Herbalism", 1 }, items = { { 2447, 30 }, { 765, 30 }, { 2449, 15 } }, tip = { enUS = "Starting zones are full of herbs nobody picks.", trTR = "Başlangıç bölgeleri kimsenin toplamadığı otlarla dolu." } },
  { id = "herbs-stv", title = { enUS = "Liferoot, Kingsblood, Fadeleaf", trTR = "Liferoot, Kingsblood, Fadeleaf" }, min = 30, max = 40, zone = "Northern Stranglethorn",
    method = "gather", prof = { "Herbalism", 150 }, items = { { 3357, 12 }, { 3356, 15 }, { 3818, 12 } }, tip = { enUS = "Rivers for Liferoot, jungle floor for the rest.", trTR = "Liferoot için nehir kıyıları, diğerleri için orman zemini." } },
  { id = "herbs-feralas", title = { enUS = "Sungrass, Khadgar's Whisker", trTR = "Sungrass, Khadgar's Whisker" }, min = 40, max = 50, zone = "Feralas",
    method = "gather", prof = { "Herbalism", 230 }, items = { { 8838, 25 }, { 3358, 10 } }, tip = { enUS = "Feralas is the best herb zone for the 40s.", trTR = "40'lı seviyeler için en iyi ot bölgesi Feralas." } },
  { id = "herbs-felwood", title = { enUS = "Gromsblood, Plaguebloom", trTR = "Gromsblood, Plaguebloom" }, min = 50, max = 58, zone = "Felwood",
    method = "gather", prof = { "Herbalism", 250 }, items = { { 8846, 15 }, { 13466, 12 } }, tip = { enUS = "Plaguebloom sells well for flasks.", trTR = "Plaguebloom, flask yapımı için iyi satılır." } },
  { id = "herbs-epl", title = { enUS = "Dreamfoil, Golden Sansam", trTR = "Dreamfoil, Golden Sansam" }, min = 55, max = 60, zone = "Eastern Plaguelands",
    method = "gather", prof = { "Herbalism", 270 }, items = { { 13463, 20 }, { 13464, 15 } }, tip = { enUS = "Pairs with Runecloth farming.", trTR = "Runecloth kasmayla birlikte yapılır." } },
  -- Yuzme
  { id = "leather-thick", title = { enUS = "Thick Leather", trTR = "Thick Leather" }, min = 38, max = 48, zone = "Feralas",
    method = "skin", prof = { "Skinning", 200 }, items = { { 4304, 50 } }, tip = { enUS = "Yetis and beasts all over the zone.", trTR = "Bölgenin her yerinde yetiler ve hayvanlar." } },
  { id = "leather-rugged", title = { enUS = "Rugged Leather", trTR = "Rugged Leather" }, min = 50, max = 60, zone = "Winterspring",
    method = "skin", prof = { "Skinning", 250 }, items = { { 8170, 60 } }, tip = { enUS = "Bears and cats; Chillwind Chimaeras give extra.", trTR = "Ayılar ve kediler; ek olarak Chillwind Chimaera'lar." } },
}
