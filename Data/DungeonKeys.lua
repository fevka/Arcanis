-- Arcanis: zindan anahtarlari ve nasil alinir (kendi cumlelerimiz). Esya kimlikleri istemcinin ItemSparse
-- tablosundan adla dogrulandi; gorev kimlikleri ve verenleri gorev grafigimizden (Data/Brain/QuestGraph.lua).
-- Upper Blackrock Spire'in Seal of Ascension'i (12344) Forever istemcisinde yok: alinmadi.
-- Alanlar:
--   id, item (anahtar esyasi), n (esya bilgisi gelmeden yedek ad), dungeons = { zindan kimlikleri (Data/Dungeons.lua) }, kind = "key" | "summon",
--   note = { enUS, trTR } ne acar, verify = true (oyunda dogrulanmali)
--   chain = { Alliance = { gorev, ... }, Horde = { ... }, all = { ... } }: sirayla yapilan gorevler; sonuncusu bitince
--     anahtar alinmis sayilir (esya bankada olabilir). Gorev adi oyundan, veren gorev grafiginden.
--   giver = { npc, zone, x?, y? }: grafikte vereni olmayan zincir gorevleri icin
--   steps = { { text = { enUS, trTR }, npc?, zone?, x?, y? (0-100) } }: gorev olmayan adimlar (dusen, sandik, kullan)
local _, ns = ...

ns.DungeonKeys = {
  { id = "scarlet-key", item = 7146, n = "The Scarlet Key", dungeons = { "sm-armory", "sm-cathedral" }, kind = "key", verify = true,
    note = { enUS = "Opens the doors of the Armory and the Cathedral.", trTR = "Armory ve Cathedral kapılarını açar." },
    steps = {
      { text = { enUS = "Clear the Library wing; the key lies in a chest in the last room, after Arcanist Doan.",
        trTR = "Library kanadını temizle; anahtar son odada, Arcanist Doan'dan sonraki sandıkta." } },
    } },
  { id = "skeleton-key", item = 13704, n = "Skeleton Key", dungeons = { "scholomance" }, kind = "key", verify = true,
    note = { enUS = "Opens the gate of Scholomance.", trTR = "Scholomance'ın kapısını açar." },
    chain = {
      Alliance = { 5092, 5097, 5533, 5537, 5538, 5801, 5803, 5505 },
      Horde = { 5096, 5098, 838, 964, 5514, 5802, 5804, 5511 },
    },
    steps = {
      { text = { enUS = "The chain sends you to Tanaris and the Plaguelands; the last step forges the key from the parts you gather.",
        trTR = "Zincir seni Tanaris'e ve Plaguelands'e gönderir; son adımda topladığın parçalardan anahtar dövülür." } },
    } },
  { id = "shadowforge-key", item = 11000, n = "Shadowforge Key", dungeons = { "brd" }, kind = "key", verify = true,
    note = { enUS = "Opens the Shadowforge gate inside Blackrock Depths, a shortcut to the deeper halls.",
      trTR = "Blackrock Depths içindeki Shadowforge kapısını açar; derin salonlara kestirme." },
    chain = { all = { 3801, 3802 } },
    giver = { npc = "Franclorn Forgewright", zone = "Blackrock Mountain" },
    steps = {
      { text = { enUS = "Franclorn's spirit stands in the middle of Blackrock Mountain and is only visible while you are a ghost. Kill Fineous Darkvire in the depths for Ironfel and place it at the Shrine of Thaurissan.",
        trTR = "Franclorn'un ruhu Blackrock Mountain'ın ortasında durur ve yalnız hayaletken görünür. Derinlerde Fineous Darkvire'ı öldürüp Ironfel'i al ve Shrine of Thaurissan'a koy." } },
    } },
  { id = "prison-cell-key", item = 11140, n = "Prison Cell Key", dungeons = { "brd" }, kind = "key", verify = true,
    note = { enUS = "Opens the cells in the Detention Block of Blackrock Depths.", trTR = "Blackrock Depths'in Detention Block bölümündeki hücreleri açar." },
    steps = {
      { text = { enUS = "Dropped by High Interrogator Gerstahn near the prison.", trTR = "Hapishanenin yanındaki High Interrogator Gerstahn düşürür." } },
    } },
  { id = "workshop-key", item = 6893, n = "Workshop Key", dungeons = { "gnomeregan" }, kind = "key", verify = true,
    note = { enUS = "Opens the workshop side door in Gnomeregan.", trTR = "Gnomeregan'daki atölyenin yan kapısını açar." },
    steps = {
      { text = { enUS = "Dropped by creatures inside Gnomeregan.", trTR = "Gnomeregan içindeki yaratıklardan düşer." } },
    } },
  { id = "crescent-key", item = 18249, n = "Crescent Key", dungeons = { "dm-west", "dm-north" }, kind = "key", verify = true,
    note = { enUS = "Opens the inner doors of Dire Maul West and North.", trTR = "Dire Maul West ve North'un iç kapılarını açar." },
    steps = {
      { text = { enUS = "Talk to Pusillin in Dire Maul East and chase him through the wing; he drops the key when you defeat him.",
        trTR = "Dire Maul East'te Pusillin ile konuş ve kanat boyunca onu kovala; yenince anahtarı düşürür." } },
    } },
  { id = "key-to-the-city", item = 12382, n = "Key to the City", dungeons = { "strat-undead" }, kind = "key", verify = true,
    note = { enUS = "Opens the service entrance of Stratholme, the back door to the undead side.",
      trTR = "Stratholme'un servis girişini açar; ölümsüzler tarafına arka kapı." },
    steps = {
      { text = { enUS = "Dropped by Magistrate Barthilas on the living side of Stratholme.", trTR = "Stratholme'un yaşayanlar tarafında Magistrate Barthilas düşürür." } },
    } },
  { id = "scepter-of-celebras", item = 17191, n = "Scepter of Celebras", dungeons = { "maraudon" }, kind = "key", verify = true,
    note = { enUS = "Opens a portal at the entrance to the inner halls of Maraudon on later visits.",
      trTR = "Sonraki ziyaretlerde girişte Maraudon'un iç salonlarına geçit açar." },
    chain = { all = { 7044, 7046 } },
    giver = { npc = "Celebras the Redeemed", zone = "Maraudon" },
    steps = {
      { text = { enUS = "Collect the two scepter parts from Noxxion and Lord Vyletongue, then free Celebras to have the scepter put together.",
        trTR = "Noxxion ve Lord Vyletongue'dan asanın iki parçasını topla, sonra Celebras'ı kurtar; asayı o birleştirir." } },
    } },
  { id = "mallet-of-zulfarrak", item = 9240, n = "Mallet of Zul'Farrak", dungeons = { "zf" }, kind = "summon", verify = true,
    note = { enUS = "Summons Gahz'rilla at the pool in Zul'Farrak.", trTR = "Zul'Farrak'taki havuzda Gahz'rilla'yı çağırır." },
    steps = {
      { text = { enUS = "Take the Sacred Mallet from Qiaga the Keeper in Jintha'Alor, The Hinterlands.",
        trTR = "Sacred Mallet'i The Hinterlands'deki Jintha'Alor'da Qiaga the Keeper'dan al." }, zone = "The Hinterlands" },
      { text = { enUS = "Use it at the Altar of Zul on top of Jintha'Alor to turn it into the Mallet of Zul'Farrak.",
        trTR = "Onu Jintha'Alor'un tepesindeki Altar of Zul'da kullanarak Mallet of Zul'Farrak'a dönüştür." }, zone = "The Hinterlands" },
    } },
}
