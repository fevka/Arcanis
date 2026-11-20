-- Arcanis: sinif rehberi verisi (ns.ClassGuide). Sinif dosyalari Data/ClassGuide/<Sinif>.lua icinden kaydolur.
-- Taban: Classic Era (1.12) kurallari; WoW Forever (16001) ayni sinif icerigini kullanir.
--
-- SEMA (her sinif dosyasi ClassGuide:Register("TOKEN", veri) cagirir; TOKEN = UnitClass 2. donus)
-- Ortak kurallar
--   * Aciklayici metin alanlari (note, reward, text, strengths, tips) DAIMA { enUS = "...", trTR = "..." }.
--     Oyunda ns:LocalizedText(t) ya da ClassGuide:Text(t) ile okunur.
--   * NPC, bolge, buyu ve esya adlari Ingilizce duz metindir.
--   * faction: "Alliance" | "Horde" | "Both" (nil = Both).
--   * Irk belirteci: UnitRace 2. donusu -> Human, Dwarf, NightElf, Gnome, Orc, Troll, Tauren, Scourge.
--   * x, y: 0-100 harita yuzdesi; zone: haritanin adi (sehir ya da bolge), mapHint: alt bolge / tarif.
--   * verify = true: makul ama dogrulanmamis deger (oyunda kontrol edilmeli).
--   * cost: bakir (copper). 10000 = 1 altin.
--
-- data = {
--   role    = { enUS, trTR }                          -- tek satir sinif ozeti (istege bagli)
--   armor   = { { type = "Cloth"|"Leather"|"Mail"|"Plate"|"Shield", fromLevel = 1,
--                 note = {..}, learn = { cost = 0, at = {..} } (istege bagli: trainer'dan ogrenilir) } }
--   weapons = { { skill = "Two-Handed Swords", startsKnownBy = "all" | { "Human", ... } | nil,
--                 note = {..} (istege bagli) } }
--               -> learnAt listesi ortak WeaponMasters tablosundan otomatik uretilir (asagida).
--   trainers = { { npc, faction, zone, mapHint, x, y, kind = "class"|"pet"|"portal"|"other",
--                  tier = 1 (baslangic koyu) | 2 (ilk kasaba) | 3 (baskent) | 4 (ozel/uzak),
--                  races = { ... } (istege bagli), note = {..} (istege bagli), verify } }
--   quests  = { { level, id (biliniyorsa), name, faction, races = { ... } (istege bagli),
--                 giver, turnIn (istege bagli; x,y o zaman teslim NPC'sinin), zone, x, y, reward = {..}, note = {..},
--                 chain = { "Quest A", ... } (istege bagli),
--                 verify } }
--   milestones = { { level, spells = { "Charge", ... }, note = {..} (istege bagli), quest = true (gorevle) } }
--   tips    = { {..}, {..} }
--   -- yalniz HUNTER:
--   pets    = { { name, family, minLevel, maxLevel, zone, x, y, faction (bolgeye erisim, istege bagli),
--                 learn = { "Bite 3", ... }, rare = true (istege bagli), note = {..}, verify } }
--   petFamilies = { { family, diet = { "Meat", ... }, strengths = {..}, abilities = { "Bite", ... } } }
-- }
--
-- ERISIM (UI icin; donen listeler yeni tablodur, ogeler veri referansidir — degistirmeyin)
--   ClassGuide:Get(class)                       -> ham veri ya da nil
--   ClassGuide:Classes()                        -> kayitli sinif belirteclerinin sirali listesi
--   ClassGuide:Text(t)                          -> yerel metin (ns:LocalizedText)
--   ClassGuide:Armor(class)                     -> fromLevel'e gore sirali { type, fromLevel, note, learn }
--   ClassGuide:ArmorAt(class, level)            -> o seviyede giyilebilen en agir zirh tipi (Shield haric)
--   ClassGuide:Weapons(class, faction)          -> skill'e gore sirali { skill, startsKnownBy, note,
--                                                  learnAt = { { faction, npc, city, mapHint, x, y, cost, minLevel, verify } } }
--   ClassGuide:Trainers(class, faction, kind)   -> tier, sonra zone, sonra npc'ye gore sirali; kind nil = hepsi
--   ClassGuide:Quests(class, faction, level, race) -> level'e gore sirali; level verilirse q.level <= level olanlar
--   ClassGuide:Milestones(class, fromLevel, toLevel) -> level'e gore sirali
--   ClassGuide:Tips(class)                      -> { {enUS,trTR}, ... }
--   ClassGuide:Pets(level, faction)             -> HUNTER evcil onerileri, minLevel'e gore sirali;
--                                                  level verilirse minLevel <= level olanlar (ehlilestirilebilir)
--   ClassGuide:PetFamilies()                    -> aileye gore sirali { family, diet, strengths, abilities }
--   ClassGuide:Validate()                       -> sorun listesi (bos = gecerli); testler kullanir
local _, ns = ...

local ClassGuide = ns.ClassGuide or {}
ns.ClassGuide = ClassGuide
ClassGuide.classes = ClassGuide.classes or {}

local ALL_CLASSES = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }
ClassGuide.ALL = ALL_CLASSES

ClassGuide.ARMOR_RANK = { Cloth = 1, Leather = 2, Mail = 3, Plate = 4 }

-- Ortak Weapon Master tablosu (Classic Era). Silah becerisi 1. seviyede 10 gumus; Polearms 20. seviye, 1 altin.
local SKILL_COST, POLEARM_COST, POLEARM_LEVEL = 1000, 10000, 20

ClassGuide.WeaponMasters = {
  { npc = "Woo Ping", faction = "Alliance", city = "Stormwind City", mapHint = "Weller's Arsenal, Trade District",
    x = 63.9, y = 69.1,   -- Forever'in Stormwind haritasi Classic'ten farkli (Classic: 57.1, 57.7)
    skills = { "One-Handed Swords", "Two-Handed Swords", "Daggers", "Polearms", "Staves", "Crossbows" } },
  { npc = "Buliwyf Stonehand", faction = "Alliance", city = "Ironforge", mapHint = "Timberline Arms, Military Ward",
    x = 62.2, y = 89.6,
    skills = { "One-Handed Axes", "Two-Handed Axes", "One-Handed Maces", "Two-Handed Maces", "Fist Weapons", "Guns" } },
  { npc = "Bixi Wobblebonk", faction = "Alliance", city = "Ironforge", mapHint = "Timberline Arms, Military Ward",
    x = 62.2, y = 89.6,
    skills = { "Daggers", "Crossbows", "Thrown" } },
  { npc = "Ilyenia Moonfire", faction = "Alliance", city = "Darnassus", mapHint = "Warrior's Terrace",
    x = 57.6, y = 46.7,
    skills = { "Daggers", "Fist Weapons", "Staves", "Bows", "Thrown" } },
  { npc = "Hanashi", faction = "Horde", city = "Orgrimmar", mapHint = "Arms of Legend, Valley of Honor",
    x = 81.5, y = 19.6,
    skills = { "One-Handed Axes", "Two-Handed Axes", "Staves", "Bows", "Thrown" } },
  { npc = "Sayoc", faction = "Horde", city = "Orgrimmar", mapHint = "Arms of Legend, Valley of Honor",
    x = 81.5, y = 19.6,
    skills = { "One-Handed Axes", "Two-Handed Axes", "Daggers", "Fist Weapons", "Bows", "Thrown" } },
  { npc = "Ansekhwa", faction = "Horde", city = "Thunder Bluff", mapHint = "Lower rise",
    x = 40.9, y = 62.7,
    skills = { "One-Handed Maces", "Two-Handed Maces", "Staves", "Guns" } },
  { npc = "Archibald", faction = "Horde", city = "Undercity", mapHint = "War Quarter",
    x = 57.3, y = 32.8,
    skills = { "One-Handed Swords", "Two-Handed Swords", "Daggers", "Polearms", "Crossbows" } },
}

-- Kayit ve yardimcilar
function ClassGuide:Register(class, data)
  if type(class) ~= "string" or type(data) ~= "table" then return end
  data.class = class:upper()
  self.classes[data.class] = data
  return data
end

function ClassGuide:Get(class)
  return type(class) == "string" and self.classes[class:upper()] or nil
end

function ClassGuide:Classes()
  local out = {}
  for token in pairs(self.classes) do out[#out + 1] = token end
  table.sort(out)
  return out
end

function ClassGuide:Text(t)
  if ns.LocalizedText then return ns:LocalizedText(t) end
  return type(t) == "table" and (t.enUS or t.trTR) or t
end

local function factionOK(entryFaction, want)
  if not want or want == "Both" then return true end
  return entryFaction == nil or entryFaction == "Both" or entryFaction == want
end
ClassGuide.FactionMatches = factionOK

local function raceOK(races, want)
  if not want or not races then return true end
  for _, r in ipairs(races) do if r == want then return true end end
  return false
end

ClassGuide.RaceMatches = raceOK

local function list(class, field)
  local data = ClassGuide:Get(class)
  return data and data[field] or {}
end

local function copy(src, keep)
  local out = {}
  for _, e in ipairs(src) do
    if not keep or keep(e) then out[#out + 1] = e end
  end
  return out
end

-- kararli siralama: once anahtar, esitlikte veri sirasi
local function stableSort(t, less)
  local idx = {}
  for i, v in ipairs(t) do idx[v] = i end
  table.sort(t, function(a, b)
    if less(a, b) then return true end
    if less(b, a) then return false end
    return idx[a] < idx[b]
  end)
  return t
end

-- Erisim fonksiyonlari
function ClassGuide:Armor(class)
  return stableSort(copy(list(class, "armor")), function(a, b) return (a.fromLevel or 1) < (b.fromLevel or 1) end)
end

function ClassGuide:ArmorAt(class, level)
  local best, rank = nil, 0
  for _, a in ipairs(list(class, "armor")) do
    local r = self.ARMOR_RANK[a.type]
    if r and (a.fromLevel or 1) <= (level or 60) and r > rank then best, rank = a.type, r end
  end
  return best
end

function ClassGuide:WeaponMastersFor(skill, faction)
  local out = {}
  for _, m in ipairs(self.WeaponMasters) do
    if factionOK(m.faction, faction) then
      for _, s in ipairs(m.skills) do
        if s == skill then
          local polearm = skill == "Polearms"
          out[#out + 1] = { faction = m.faction, npc = m.npc, city = m.city, mapHint = m.mapHint, x = m.x, y = m.y,
                            cost = polearm and POLEARM_COST or SKILL_COST, minLevel = polearm and POLEARM_LEVEL or 1,
                            verify = m.verify }
          break
        end
      end
    end
  end
  return out
end

function ClassGuide:Weapons(class, faction)
  local out = {}
  for _, w in ipairs(list(class, "weapons")) do
    out[#out + 1] = { skill = w.skill, startsKnownBy = w.startsKnownBy, note = w.note, verify = w.verify,
                      learnAt = self:WeaponMastersFor(w.skill, faction) }
  end
  table.sort(out, function(a, b) return a.skill < b.skill end)
  return out
end

function ClassGuide:Trainers(class, faction, kind)
  local out = copy(list(class, "trainers"), function(t)
    return factionOK(t.faction, faction) and (not kind or (t.kind or "class") == kind)
  end)
  return stableSort(out, function(a, b)
    if (a.tier or 3) ~= (b.tier or 3) then return (a.tier or 3) < (b.tier or 3) end
    if (a.zone or "") ~= (b.zone or "") then return (a.zone or "") < (b.zone or "") end
    return (a.npc or "") < (b.npc or "")
  end)
end

function ClassGuide:Quests(class, faction, level, race)
  local out = copy(list(class, "quests"), function(q)
    return factionOK(q.faction, faction) and (not level or (q.level or 1) <= level) and raceOK(q.races, race)
  end)
  return stableSort(out, function(a, b) return (a.level or 1) < (b.level or 1) end)
end

-- Sinif quest zincirinin ID'leri: girisin ilk quest'inden gorev grafiginde ileri (`nx` ve onkosulu bu olanlar).
-- Yalniz sinif maskeli quest'ler zincire katilir (givers'ta sinif maskesi > 0), en cok 20.
function ClassGuide:ChainIds(entry)
  local givers = ns.BrainData and ns.BrainData.givers or {}
  local B = ns.Brain
  local ids, queue = {}, { entry and entry.id }
  local i = 1
  while queue[i] and #ids < 20 do
    local id = queue[i]
    i = i + 1
    if not ids[id] then
      ids[#ids + 1] = id; ids[id] = true
      for _, f in ipairs(B and B.Followers and B:Followers(id) or {}) do
        local g = givers[f]
        if not ids[f] and g and (g[5] or 0) > 0 then queue[#queue + 1] = f end
      end
    end
  end
  return ids
end

-- Bu quest bir sinif quest zincirinde mi? Zincirin girisi (ClassGuide quests kaydi) ya da nil.
function ClassGuide:QuestFor(class, questId)
  if not (class and questId) then return nil end
  self.chainCache = self.chainCache or {}
  local map = self.chainCache[class]
  if not map then
    map = {}
    for _, e in ipairs(list(class, "quests")) do
      for _, id in ipairs(self:ChainIds(e)) do map[id] = map[id] or e end
    end
    self.chainCache[class] = map
  end
  return map[questId]
end

function ClassGuide:Milestones(class, fromLevel, toLevel)
  local out = copy(list(class, "milestones"), function(m)
    return (not fromLevel or m.level >= fromLevel) and (not toLevel or m.level <= toLevel)
  end)
  return stableSort(out, function(a, b) return a.level < b.level end)
end

function ClassGuide:Tips(class)
  return copy(list(class, "tips"))
end

-- Egitmenden ogrenilen buyuler: sinif egitmeninin penceresinden okunur (Helpers/Training.lua, hesap geneli).
-- Dondurur: seviyeye gore { level, name, rank }; egitmen henuz ziyaret edilmediyse bos.
function ClassGuide:Spells(class, fromLevel, toLevel)
  return ns.Training and ns.Training:Spells(class, fromLevel, toLevel) or {}
end

function ClassGuide:HasSpellData(class)
  return ns.Training ~= nil and ns.Training:HasData(class)
end

function ClassGuide:Pets(level, faction)
  local out = copy(list("HUNTER", "pets"), function(p)
    return factionOK(p.faction, faction) and (not level or (p.minLevel or 1) <= level)
  end)
  return stableSort(out, function(a, b)
    if (a.minLevel or 1) ~= (b.minLevel or 1) then return (a.minLevel or 1) < (b.minLevel or 1) end
    return (a.name or "") < (b.name or "")
  end)
end

function ClassGuide:PetFamilies()
  local out = copy(list("HUNTER", "petFamilies"))
  table.sort(out, function(a, b) return a.family < b.family end)
  return out
end

-- Dogrulama (testler ve /wf hata ayiklama icin)
local LOCALIZED = { note = true, reward = true, strengths = true, role = true, text = true }
local FACTIONS = { Alliance = true, Horde = true, Both = true }

local function checkText(problems, where, t)
  if type(t) ~= "table" or type(t.enUS) ~= "string" or t.enUS == "" or type(t.trTR) ~= "string" or t.trTR == "" then
    problems[#problems + 1] = where .. ": localized text needs enUS and trTR"
  end
end

local function checkEntry(problems, where, e)
  for k, v in pairs(e) do
    if LOCALIZED[k] then checkText(problems, where .. "." .. k, v) end
  end
  if e.faction ~= nil and not FACTIONS[e.faction] then
    problems[#problems + 1] = where .. ": bad faction " .. tostring(e.faction)
  end
  for _, axis in ipairs({ "x", "y" }) do
    local v = e[axis]
    if v ~= nil and (type(v) ~= "number" or v < 0 or v > 100) then
      problems[#problems + 1] = where .. ": bad " .. axis
    end
  end
end

function ClassGuide:Validate()
  local problems = {}
  for _, token in ipairs(ALL_CLASSES) do
    local d = self.classes[token]
    if not d then
      problems[#problems + 1] = token .. ": not registered"
    else
      if d.role then checkText(problems, token .. ".role", d.role) end
      for _, field in ipairs({ "armor", "weapons", "trainers", "quests", "milestones", "pets", "petFamilies" }) do
        for i, e in ipairs(d[field] or {}) do checkEntry(problems, token .. "." .. field .. "[" .. i .. "]", e) end
      end
      for i, t in ipairs(d.tips or {}) do checkText(problems, token .. ".tips[" .. i .. "]", t) end
    end
  end
  return problems
end
