-- Arcanis: ekipman uygunlugu (ns.Gear, modul degil). Bir esyanin hangi siniflara uydugunu zirh tipi,
-- silah yetenegi ve ana statlardan hesaplar. Sonuc bir REHBERDIR (tahmini kural tablosu), kesin hukum degil.
local _, ns = ...

local Gear = {}
ns.Gear = Gear
local L = ns.L

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
Gear.CLASSES = CLASSES

-- Zirh alt siniflari: 1 kumas, 2 deri, 3 zincir, 4 plaka, 6 kalkan. Seviye esiginden sonra daha agir zirh giyilir.
local ARMOR = {
  WARRIOR = { 3, 4, 40 }, PALADIN = { 3, 4, 40 }, HUNTER = { 2, 3, 40 }, SHAMAN = { 2, 3, 40 },
  ROGUE = { 2, 2, 1 }, DRUID = { 2, 2, 1 }, PRIEST = { 1, 1, 1 }, MAGE = { 1, 1, 1 }, WARLOCK = { 1, 1, 1 },
}
local SHIELD = { WARRIOR = true, PALADIN = true, SHAMAN = true }
-- Yalniz bu ekipman yuvalarinda zirh tipi aranir; yuzuk, kolye, pelerin, mazeret vb. herkese uyar.
local ARMOR_SLOTS = {
  INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true, INVTYPE_WAIST = true,
  INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true, INVTYPE_HAND = true,
}

-- Silah alt siniflari: 0 balta, 1 2e balta, 2 yay, 3 tufek, 4 gurz, 5 2e gurz, 6 mizrak(polearm), 7 kilic,
-- 8 2e kilic, 10 asa, 13 yumruk, 15 hancer, 16 firlatilan, 18 tatar yayi, 19 degnek.
local WEAPONS = {
  WARRIOR = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18 },
  PALADIN = { 0, 1, 4, 5, 6, 7, 8 },
  HUNTER = { 0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18 },
  ROGUE = { 2, 3, 4, 7, 13, 15, 16, 18 },
  PRIEST = { 4, 10, 15, 19 },
  SHAMAN = { 0, 1, 4, 5, 10, 13, 15 },
  MAGE = { 7, 10, 15, 19 },
  WARLOCK = { 7, 10, 15, 19 },
  DRUID = { 4, 5, 6, 10, 13, 15 },
}
local WEAPON_SET = {}
for class, list in pairs(WEAPONS) do
  WEAPON_SET[class] = {}
  for _, sc in ipairs(list) do WEAPON_SET[class][sc] = true end
end

-- Ana stat ilgisi (1 = ise yarar). Primer statlari olan esya, hicbir ilgisi olmayan siniflara onerilmez.
local STAT_KEYS = {
  strength = "ITEM_MOD_STRENGTH_SHORT", agility = "ITEM_MOD_AGILITY_SHORT", intellect = "ITEM_MOD_INTELLECT_SHORT",
  spirit = "ITEM_MOD_SPIRIT_SHORT",
}
local AFFINITY = {
  WARRIOR = { strength = 1, agility = 1 }, PALADIN = { strength = 1, intellect = 1, spirit = 1 },
  HUNTER = { agility = 1, intellect = 1 }, ROGUE = { agility = 1, strength = 1 },
  PRIEST = { intellect = 1, spirit = 1 }, SHAMAN = { strength = 1, agility = 1, intellect = 1, spirit = 1 },
  MAGE = { intellect = 1, spirit = 1 }, WARLOCK = { intellect = 1, spirit = 1 },
  DRUID = { strength = 1, agility = 1, intellect = 1, spirit = 1 },
}

local function armorTypeFor(class, level)
  local a = ARMOR[class]
  return level >= a[3] and a[2] or a[1]
end

-- item: P.ItemDetails sonucu; level: oyuncu seviyesi (varsayilan esyanin gerekli seviyesi).
-- Dondurur: uygun sinif listesi (sirali, her biri { class, wearsAt = seviye? }), ve nedenini aciklayan ozet.
function Gear:ClassesFor(item, level)
  local out = {}
  if not item then return out end
  level = level or math.max(item.minLevel or 1, 1)
  local isArmor = item.classId == 4
  local isWeapon = item.classId == 2
  local slot = item.equipLoc
  -- Esya ana stat tasiyor mu?
  local hasPrimary, wanted = false, {}
  for stat, key in pairs(STAT_KEYS) do
    if (item.stats[key] or 0) > 0 then hasPrimary = true; wanted[stat] = true end
  end
  for _, class in ipairs(CLASSES) do
    local ok = true
    local late
    if isArmor then
      if item.subClassId == 6 then ok = SHIELD[class]
      elseif ARMOR_SLOTS[slot] and item.subClassId and item.subClassId >= 1 and item.subClassId <= 4 then
        local best = armorTypeFor(class, level)
        ok = item.subClassId == best
        -- henuz giyilemiyor ama ileride giyilecek bir tur
        if not ok and item.subClassId == ARMOR[class][2] and level < ARMOR[class][3] then ok, late = true, ARMOR[class][3] end
      end
    elseif isWeapon then
      ok = WEAPON_SET[class][item.subClassId] and true or false
    end
    if ok and hasPrimary then
      local fits = false
      for stat in pairs(wanted) do if AFFINITY[class][stat] then fits = true break end end
      ok = fits
    end
    if ok then out[#out + 1] = { class = class, wearsAt = late } end
  end
  return out
end

function Gear:ClassName(token)
  local map = LOCALIZED_CLASS_NAMES_MALE
  if map and map[token] then return map[token] end
  return token:sub(1, 1) .. token:sub(2):lower()
end

local COLORS = {
  WARRIOR = "c79c6e", PALADIN = "f58cba", HUNTER = "abd473", ROGUE = "fff569", PRIEST = "ffffff",
  SHAMAN = "0070de", MAGE = "69ccf0", WARLOCK = "9482c9", DRUID = "ff7d0a",
}
function Gear:ClassColored(token)
  return ("|cff%s%s|r"):format(COLORS[token] or "ffffff", self:ClassName(token))
end

-- Kisa metin: "Warrior, Paladin" (cok sinif varsa "All classes").
function Gear:Summary(classes, playerToken)
  if #classes == 0 then return "" end
  if #classes >= #CLASSES then return ns.L["All classes"] end
  local names = {}
  for _, e in ipairs(classes) do
    local n = self:ClassColored(e.class)
    if e.wearsAt then n = n .. ("(%d)"):format(e.wearsAt) end
    names[#names + 1] = n
  end
  return table.concat(names, ", ")
end

function Gear:FitsPlayer(classes, token)
  for _, e in ipairs(classes) do if e.class == token then return true end end
  return false
end


-- Esya puani: sum(stat * agirlik) + silah DPS'i * yuva agirligi (Data/StatWeights.lua); giyilemeyen esya 0.
-- Genel API:
--   Gear:GetSpec(token)                         -> specId, specName, source ("override" | "talents" | "default")
--   Gear:SetSpecOverride(specId|nil)            -> true/false (karakter basina; nil = otomatik)
--   Gear:Specs(token)                           -> { { id, name }, ... } agac sirasiyla
--   Gear:Weights(token, specId, level)          -> { [statKey] = agirlik }, specTablosu
--   Gear:Score(item, token, specId, level)      -> puan, usable
--   Gear:ScoreBreakdown(item, token, specId, level) -> { { key, label, value, weight, points }, ... }, toplam, usable
--   Gear:UpgradeDelta(item, token, level, specId) -> fark ya da nil (giyilemez)
--   Gear:Compare(item, token, specId, level)    -> fark, slot, takiliBaglanti, yeniPuan
--   Gear:Upgrades(limit)                        -> { { slot, slotName, link, itemId, equippedLink, delta, score, bag, bagSlot }, ... }
--   Gear:PlayerStats()                          -> { str, agi, sta, int, spi, ap, rap, crit, rangedCrit, spellCrit, spellDamage, healing, hit, spellHit, armor, manaRegen, health, mana, level, class, spec }
--   Gear:ArmorPlan(token, level)                -> { current, currentLabel, next = { type, label, level } | nil }
-- statKey: str agi sta int spi ap rap sp heal crit hit spellcrit spellhit mp5 armor defense block mh oh th ranged wand shield
local P = ns.Provider

-- Takma yeri -> slot kimlikleri (esya ayrinti verisindeki equipLoc'a gore).
local SLOTS = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
  INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
  INVTYPE_WEAPON = { 16, 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 },
}
Gear.SLOTS = SLOTS

-- Slot kimligi -> oyunun yerel adi (GlobalStrings) ve Ingilizce yedek.
local SLOT_NAMES = {
  [1] = { "HEADSLOT", "Head" }, [2] = { "NECKSLOT", "Neck" }, [3] = { "SHOULDERSLOT", "Shoulder" }, [4] = { "SHIRTSLOT", "Shirt" },
  [5] = { "CHESTSLOT", "Chest" }, [6] = { "WAISTSLOT", "Waist" }, [7] = { "LEGSSLOT", "Legs" }, [8] = { "FEETSLOT", "Feet" },
  [9] = { "WRISTSLOT", "Wrist" }, [10] = { "HANDSSLOT", "Hands" }, [11] = { "FINGER0SLOT", "Finger" }, [12] = { "FINGER1SLOT", "Finger" },
  [13] = { "TRINKET0SLOT", "Trinket" }, [14] = { "TRINKET1SLOT", "Trinket" }, [15] = { "BACKSLOT", "Back" },
  [16] = { "MAINHANDSLOT", "Main Hand" }, [17] = { "SECONDARYHANDSLOT", "Off Hand" }, [18] = { "RANGEDSLOT", "Ranged" },
}
function Gear:SlotName(slot)
  local e = SLOT_NAMES[slot]
  if not e then return tostring(slot) end
  local g = _G[e[1]]
  return type(g) == "string" and g or e[2]
end

local OFFHAND_LOCS = { INVTYPE_WEAPONOFFHAND = true, INVTYPE_SHIELD = true, INVTYPE_HOLDABLE = true }
local RANGED_LOCS = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true }
local DW_LEVEL = { WARRIOR = 20, HUNTER = 20, ROGUE = 10 }   -- Classic: cift silah egitimi
local ARMOR_NAMES = { "Cloth", "Leather", "Mail", "Plate" }
local EMPTY = -5   -- bos yuva: her esya en az bu kadar iyidir
local NO_UPGRADE_LOCS = { INVTYPE_BODY = true, INVTYPE_TABARD = true }   -- Upgrades() listesine girmez

-- GetItemStats anahtari -> bizim stat anahtarlarimiz.
local STAT_MAP = {
  ITEM_MOD_STRENGTH_SHORT = { "str" }, ITEM_MOD_AGILITY_SHORT = { "agi" }, ITEM_MOD_STAMINA_SHORT = { "sta" },
  ITEM_MOD_INTELLECT_SHORT = { "int" }, ITEM_MOD_SPIRIT_SHORT = { "spi" },
  ITEM_MOD_ATTACK_POWER_SHORT = { "ap" }, ITEM_MOD_MELEE_ATTACK_POWER_SHORT = { "ap" }, ITEM_MOD_RANGED_ATTACK_POWER_SHORT = { "rap" },
  ITEM_MOD_SPELL_POWER_SHORT = { "sp", "heal" }, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = { "sp" }, ITEM_MOD_SPELL_HEALING_DONE_SHORT = { "heal" },
  ITEM_MOD_CRIT_RATING_SHORT = { "crit" }, ITEM_MOD_CRIT_MELEE_RATING_SHORT = { "crit" }, ITEM_MOD_CRIT_RANGED_RATING_SHORT = { "crit" },
  ITEM_MOD_CRIT_SPELL_RATING_SHORT = { "spellcrit" },
  ITEM_MOD_HIT_RATING_SHORT = { "hit" }, ITEM_MOD_HIT_MELEE_RATING_SHORT = { "hit" }, ITEM_MOD_HIT_RANGED_RATING_SHORT = { "hit" },
  ITEM_MOD_HIT_SPELL_RATING_SHORT = { "spellhit" },
  ITEM_MOD_POWER_REGEN0_SHORT = { "mp5" }, ITEM_MOD_MANA_REGENERATION_SHORT = { "mp5" },
  RESISTANCE0_NAME = { "armor" }, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = { "defense" }, ITEM_MOD_BLOCK_VALUE_SHORT = { "block" },
  ITEM_MOD_DAMAGE_PER_SECOND_SHORT = { "dps" },
}

-- Dokum sirasi ve etiketler (oyunun yerel adi; yoksa Ingilizce).
local ORDER = { "str", "agi", "sta", "int", "spi", "ap", "rap", "sp", "heal", "crit", "hit", "spellcrit", "spellhit", "mp5",
                "armor", "defense", "block" }
local LABELS = {
  str = { "ITEM_MOD_STRENGTH_SHORT", "Strength" }, agi = { "ITEM_MOD_AGILITY_SHORT", "Agility" },
  sta = { "ITEM_MOD_STAMINA_SHORT", "Stamina" }, int = { "ITEM_MOD_INTELLECT_SHORT", "Intellect" },
  spi = { "ITEM_MOD_SPIRIT_SHORT", "Spirit" }, ap = { "ITEM_MOD_ATTACK_POWER_SHORT", "Attack Power" },
  rap = { "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", "Ranged Attack Power" }, sp = { "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "Bonus Damage" },
  heal = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "Bonus Healing" }, crit = { "ITEM_MOD_CRIT_RATING_SHORT", "Critical Strike" },
  hit = { "ITEM_MOD_HIT_RATING_SHORT", "Hit" }, spellcrit = { "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "Spell Critical Strike" },
  spellhit = { "ITEM_MOD_HIT_SPELL_RATING_SHORT", "Spell Hit" }, mp5 = { "ITEM_MOD_POWER_REGEN0_SHORT", "Mana Per 5 Sec." },
  armor = { "RESISTANCE0_NAME", "Armor" }, defense = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "Defense" },
  block = { "ITEM_MOD_BLOCK_VALUE_SHORT", "Block Value" }, dps = { "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "Damage Per Second" },
}
local WEAPON_SLOT_LABEL = {
  mh = { "INVTYPE_WEAPONMAINHAND", "Main Hand" }, oh = { "INVTYPE_WEAPONOFFHAND", "Off Hand" }, th = { "INVTYPE_2HWEAPON", "Two-Hand" },
  ranged = { "INVTYPE_RANGED", "Ranged" }, wand = { "INVTYPE_RANGEDRIGHT", "Ranged" },
}
local function global(e)
  local g = e and _G[e[1]]
  return type(g) == "string" and g or (e and e[2]) or "?"
end
function Gear:StatLabel(key)
  if key == "shield" then return ns.L["Shield"] end
  if key == "armorType" then return ns.L["Lighter armor type"] end
  if WEAPON_SLOT_LABEL[key] then return global(LABELS.dps) .. " (" .. global(WEAPON_SLOT_LABEL[key]) .. ")" end
  return global(LABELS[key])
end

-- Yedek agirliklar (StatWeights'te olmayan sinif icin).
local FALLBACK = { str = 0.5, agi = 0.5, sta = 0.5, int = 0.5, spi = 0.3, armor = 0.02, mh = 3, th = 3, ranged = 1, wand = 1 }

local function playerToken() return P.PlayerClassToken and P.PlayerClassToken() or nil end
local function defaultLevel(token)
  if token and token == playerToken() then return P.PlayerLevel() end
  return 60
end

local function charStore()
  local c = ns.char
  if type(c) ~= "table" then return {} end
  c.gear = c.gear or {}
  return c.gear
end

-- Seviyeye gore derecelendirme (rating) -> yuzde. Classic'te esyalar yuzde verir; buyuk deger derecelendirmedir.
-- Donusum yaklasiktir (60. seviyede ~14 derece = %1).
local function toPercent(v, level)
  if v <= 5 then return v end
  return v / math.max(1, 14 * (level or 60) / 60)
end

local function maxArmor(token, level)
  local a = ARMOR[token]
  if not a then return 1 end
  return armorTypeFor(token, level)
end

local function canDualWield(token, level)
  if token == playerToken() and P.CanDualWield then
    local v = P.CanDualWield()
    if v ~= nil then return v end
  end
  return DW_LEVEL[token] ~= nil and level >= DW_LEVEL[token]
end

-- Uzmanlik
local function classData(token)
  local SW = ns.StatWeights
  return SW and token and SW[token] or nil
end

function Gear:SpecData(token, specId)
  local cls = classData(token)
  if not (cls and specId) then return nil end
  local alias = ns.StatWeights.ALIASES
  specId = alias and alias[specId] or specId
  for i, s in ipairs(cls.specs) do
    if s.id == specId then return s, i end
  end
  return nil
end

-- Uzmanlik adi: Turkce/Ingilizce veri tablosundan; diger dillerde (kendi sinifinda) oyunun yetenek agaci adi.
function Gear:SpecName(token, specId)
  local s, index = self:SpecData(token, specId)
  if not s then return nil end
  local code = ns.localeCode
  if code ~= "enUS" and code ~= "trTR" and token == playerToken() and P.TalentTabs then
    local ok, tabs = pcall(P.TalentTabs)
    if ok and tabs and tabs[index] and tabs[index].name then return tabs[index].name end
  end
  return ns:LocalizedText(s.name)
end

function Gear:Specs(token)
  token = token or playerToken()
  local out = {}
  local cls = classData(token)
  if not cls then return out end
  for _, s in ipairs(cls.specs) do out[#out + 1] = { id = s.id, name = self:SpecName(token, s.id) } end
  return out
end

-- Etkin uzmanlik: kullanici secimi > yetenek puanlari (en cok puanli agac) > Retail uzmanligi > sinifin seviye varsayilani.
function Gear:GetSpec(token)
  token = token or playerToken()
  local cls = classData(token)
  if not cls then return nil, nil, "default" end
  local mine = token == playerToken()
  if mine then
    local store = charStore()
    local o = store.specOverride
    if o and store.specClass == token and self:SpecData(token, o) then
      return o, self:SpecName(token, o), "override"
    end
    local ok, tabs = pcall(P.TalentTabs or function() return nil end)
    if ok and type(tabs) == "table" then
      local best, bestPts = nil, 0
      for i, t in ipairs(tabs) do
        if (t.points or 0) > bestPts and cls.specs[i] then best, bestPts = i, t.points end
      end
      if best then
        local id = cls.specs[best].id
        return id, self:SpecName(token, id), "talents"
      end
    end
    local retail = P.ActiveSpecID and P.ActiveSpecID()
    local s = retail and self:SpecData(token, retail)
    if s then return s.id, self:SpecName(token, s.id), "talents" end
  end
  return cls.default, self:SpecName(token, cls.default), "default"
end

-- Karakter icin uzmanlik secimi (nil: otomatik). Yalniz oyuncunun kendi sinifinin uzmanligi kabul edilir.
function Gear:SetSpecOverride(specId)
  local store = charStore()
  local token = playerToken()
  if specId == nil then
    store.specOverride, store.specClass = nil, nil
  else
    if not self:SpecData(token, specId) then return false end
    local alias = ns.StatWeights.ALIASES
    store.specOverride, store.specClass = (alias and alias[specId]) or specId, token
  end
  if ns.Send then ns:Send("ARCANIS_GEAR_SPEC_CHANGED", store.specOverride) end
  return true
end

-- Agirliklar: uzmanlik tablosu + seviye araligi duzeltmeleri. Yeni tablo doner (degistirilebilir).
function Gear:Weights(token, specId, level)
  token = token or playerToken()
  level = level or defaultLevel(token)
  local cls = classData(token)
  local spec = cls and (self:SpecData(token, specId or (self:GetSpec(token))) or self:SpecData(token, cls.default))
  local out = {}
  for k, v in pairs(spec and spec.w or FALLBACK) do out[k] = v end
  if spec and spec.levels then
    for _, b in ipairs(spec.levels) do
      if level <= b.upTo then for k, v in pairs(b.set) do out[k] = v end end
    end
  end
  -- oyuncunun kendi sinifi icin: disaridan alinan agirliklar (varsa) her seviyede (birkac seviye sonra giyilecek
  -- zindan esyasi da ayni agirlikla puanlanir); statlarina gore sinirlar yalniz simdiki seviyede
  if token == playerToken() then
    local custom = spec and self:CustomWeights(spec.id)
    if custom then for k, v in pairs(custom.w) do out[k] = v end end
    if level == P.PlayerLevel() then self:ApplyCaps(out, level) end
  end
  return out, spec
end

-- Oyuncunun stat blogu ~30 API cagrisi; canta taramasi ve zindan yukseltmeleri Weights'i yuzlerce kez cagirir.
-- Kisa sure (1 sn) saklanir, stat / ekipman / seviye degisince silinir. Saat yoksa (P.Now 0) saklanmaz.
-- Donen tablo yalniz okunur.
local STAT_TTL = 1
local statCache, statAt, statFn
local function statBlock()
  local fn = P.PlayerStatBlock
  if not fn then return {} end
  local now = P.Now and P.Now() or 0
  if statCache and statFn == fn and now > 0 and now - statAt < STAT_TTL then return statCache end
  statCache, statAt, statFn = fn() or {}, now, fn
  return statCache
end
function Gear:InvalidateStats() statCache = nil end
if ns.On then
  for _, e in ipairs({ "UNIT_STATS", "COMBAT_RATING_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP" }) do
    ns:On(e, "GearStats", function() statCache = nil end)   -- ayri sahip: modul kapat/ac olaylari silmesin
  end
end

-- Isabet sinirlari (Classic 1.12): seviye atlarken ayni seviye hedefe yakin dovus %5, buyu %4; 60'ta boss
-- (+3 seviye) icin yakin dovus %9, buyu %16. Sinira ulasan isabetin degeri neredeyse sifir.
local function hitCaps(level)
  if (level or 1) >= 60 then return 9, 16 end
  return 5, 4
end
Gear.HitCaps = hitCaps

-- Agirliklari oyuncunun statlarina gore duzeltir; neden degistigi Gear.capNotes'ta (Class Codex gosterir).
function Gear:ApplyCaps(w, level)
  local notes = {}
  local s = statBlock()
  local melee, spell = hitCaps(level)
  local function cap(key, have, limit)
    if type(have) ~= "number" or not w[key] then return end
    notes[key] = { have = have, cap = limit }
    if have >= limit then notes[key].capped = true; w[key] = w[key] * 0.1 end
  end
  cap("hit", s.hit, melee)
  cap("spellhit", s.spellHit, spell)
  self.capNotes = notes
  return w
end

-- Disaridan alinan agirliklar (uzmanlik basina, karakter kaydi): { w = {...}, at = sunucu saati }
function Gear:CustomWeights(specId)
  local c = charStore().weights
  return c and specId and c[specId] or nil
end

function Gear:ClearCustomWeights(specId)
  local c = charStore().weights
  if c and specId then c[specId] = nil end
  if ns.Send then ns:Send("ARCANIS_GEAR_SPEC_CHANGED", specId) end
end

-- Stat adlari (Ad=deger) -> bizim anahtarlar. Derece (Rating) degerleri %1'e cevrilir.
local WEIGHT_NAMES = {
  strength = { "str" }, agility = { "agi" }, stamina = { "sta" }, intellect = { "int" }, spirit = { "spi" },
  ap = { "ap" }, attackpower = { "ap" }, rap = { "rap" }, rangedattackpower = { "rap" },
  spelldamage = { "sp" }, spellpower = { "sp" }, healing = { "heal" },
  crit = { "crit" }, critrating = { "crit" }, critpercent = { "crit" },
  hit = { "hit" }, hitrating = { "hit" }, hitpercent = { "hit" },
  spellcrit = { "spellcrit" }, spellcritrating = { "spellcrit" }, spellcritpercent = { "spellcrit" },
  spellhit = { "spellhit" }, spellhitrating = { "spellhit" }, spellhitpercent = { "spellhit" },
  mp5 = { "mp5" }, armor = { "armor" }, defense = { "defense" }, defenserating = { "defense" },
  blockvalue = { "block" },
  dps = { "mh", "th" }, meleedps = { "mh", "th" }, mainhanddps = { "mh" }, offhanddps = { "oh" },
  rangeddps = { "ranged" },
}

-- "Class=Warrior, Spec=Arms, Strength=2.1, Ap=1, ..." bicimli metin (parantezli basliklar yok sayilir).
-- Ana stat (uzmanligin 1.0 agirlikli stati, yoksa str/agi/int'in en buyugu) 1.0 olacak sekilde olceklenir.
-- Kontroller (yanlis metin kaydedilmesin): sinif yaziyorsa oyuncunun sinifi, uzmanlik yaziyorsa taninan bir
-- uzmanlik, en az 3 taninan stat, bir ana stat (str/agi/int/sp) pozitif, degerler sayi ve 0..1000 araliginda.
-- Doner: specId, agirliklar | nil, hata anahtari ("empty", "class", "spec", "few", "main", "value").
local CLASS_NAMES = {
  warrior = "WARRIOR", paladin = "PALADIN", hunter = "HUNTER", rogue = "ROGUE", priest = "PRIEST",
  shaman = "SHAMAN", mage = "MAGE", warlock = "WARLOCK", druid = "DRUID",
}
local WEIGHTS_MIN_STATS = 3

function Gear:ParseWeights(text, token, level)
  if type(text) ~= "string" or not text:find("%S") then return nil, "empty" end
  token = token or playerToken()
  level = level or P.PlayerLevel()
  local className = text:match("[Cc]lass%s*=%s*([%a]+)")
  if className then
    local want = CLASS_NAMES[className:lower()]
    if want ~= token then return nil, "class" end
  end
  local specName = text:match("[Ss]pec%s*=%s*([%a ]+)")
  local specId
  if specName then
    specName = specName:gsub("%s+$", ""):lower()
    local cls = classData(token)
    for _, sp in ipairs(cls and cls.specs or {}) do
      local n = type(sp.name) == "table" and sp.name.enUS or sp.name
      if type(n) == "string" and n:lower() == specName then specId = sp.id end
    end
    if not specId then return nil, "spec" end
  end
  specId = specId or (self:GetSpec(token))
  local raw, n = {}, 0
  for key, val in text:gmatch("([%a]+)%s*=%s*(%-?[%d%.]+)") do
    local k = key:lower()
    local map = WEIGHT_NAMES[k]
    local v = tonumber(val)
    if map then
      if not v or v < 0 or v > 1000 then return nil, "value" end
      -- derece agirligi -> %1 agirligi (toPercent ile ayni donusum: %1 = 14 * seviye / 60 derece)
      if k:find("rating") then v = v * math.max(1, 14 * level / 60) end
      if raw[map[1]] == nil then n = n + 1 end
      for _, ours in ipairs(map) do raw[ours] = v end
    end
  end
  if n < WEIGHTS_MIN_STATS then return nil, "few" end
  if raw.mh and raw.oh == nil then raw.oh = raw.mh * 0.5 end
  local base = self:Weights(token, specId, level)
  local main
  for _, k in ipairs({ "str", "agi", "int", "sp" }) do
    if base[k] == 1 and raw[k] and raw[k] > 0 then main = k break end
  end
  local scale = main and raw[main]
  if not scale then scale = math.max(raw.str or 0, raw.agi or 0, raw.int or 0, raw.sp or 0) end
  if not scale or scale <= 0 then return nil, "main" end
  local w = {}
  for k, v in pairs(raw) do w[k] = math.floor(v / scale * 1000 + 0.5) / 1000 end
  return specId, w
end

-- Ice aktarma sonucu icin sohbet metni: hata nedeni ya da alinan ilk agirliklar
function Gear:ImportMessage(specId, errOrW)
  if not specId then
    local why = {
      empty = L["The text is empty."],
      class = L["Those weights are for another class."],
      spec = L["Unknown spec in the text."],
      few = L["Too few stats in the text: paste the whole Pawn string."],
      main = L["No main stat (Strength, Agility, Intellect or spell power) in the text."],
      value = L["A weight in the text is not a valid number."],
    }
    return L["Not imported: %s"]:format(why[errOrW] or "?")
  end
  local list = {}
  for k, v in pairs(errOrW or {}) do list[#list + 1] = { k = k, v = v } end
  table.sort(list, function(a, b) if a.v ~= b.v then return a.v > b.v end return a.k < b.k end)
  local parts = {}
  for i = 1, math.min(5, #list) do parts[i] = ("%s %s"):format(self:StatLabel(list[i].k) or list[i].k, list[i].v) end
  return L["SimC weights saved for %s: %s"]:format(self:SpecName(nil, specId) or "?", table.concat(parts, ", "))
end

-- Ice aktar: dogru ayristirildiysa uzmanligin agirliklari olarak kaydeder. Doner: specId | nil, hata.
function Gear:ImportWeights(text)
  local specId, w = self:ParseWeights(text)
  if not specId then return nil, w end
  local store = charStore()
  store.weights = store.weights or {}
  store.weights[specId] = { w = w, at = P.ServerNow and P.ServerNow() or 0 }
  if ns.Send then ns:Send("ARCANIS_GEAR_SPEC_CHANGED", specId) end
  return specId, w
end

-- Karakter profili (metin): sinif, ad, seviye, irk, uzmanlik, takili esyalar (buyuleriyle).
local PROFILE_SLOTS = {
  { 1, "head" }, { 2, "neck" }, { 3, "shoulder" }, { 15, "back" }, { 5, "chest" }, { 9, "wrist" }, { 10, "hands" },
  { 6, "waist" }, { 7, "legs" }, { 8, "feet" }, { 11, "finger1" }, { 12, "finger2" }, { 13, "trinket1" },
  { 14, "trinket2" }, { 16, "main_hand" }, { 17, "off_hand" }, { 18, "ranged" },
}
local PROFILE_RACE = { Scourge = "undead", NightElf = "night_elf" }

function Gear:CharacterProfile()
  local info = P.PlayerInfo() or {}
  local token = info.class or playerToken() or "WARRIOR"
  local name = (UnitName and UnitName("player")) or "Player"
  local sd = self:SpecData(token, (self:GetSpec(token)))
  local specName = (sd and sd.name and (sd.name.enUS or sd.name)) or ""
  if type(specName) ~= "string" then specName = "" end
  local race = info.race and (PROFILE_RACE[info.race] or info.race:gsub("(%l)(%u)", "%1_%2"):lower()) or "human"
  local lines = {
    ("%s=\"%s\""):format(token:lower(), name),
    ("level=%d"):format(P.PlayerLevel()),
    ("race=%s"):format(race),
    ("spec=%s"):format((specName:lower():gsub("%s+", "_"))),
    "",
  }
  for _, s in ipairs(PROFILE_SLOTS) do
    local _, link = P.EquippedItemFull(s[1])
    local id, enchant
    if type(link) == "string" then id, enchant = link:match("item:(%d+):(%d*)") end   -- "a and f()" ikinciyi atar
    if id then
      local line = ("%s=,id=%s"):format(s[2], id)
      if enchant and enchant ~= "" and enchant ~= "0" then line = line .. ",enchant_id=" .. enchant end
      lines[#lines + 1] = line
    end
  end
  return table.concat(lines, "\n")
end

-- Giyilebilirlik
-- Sinif bu esyayi bu seviyede takabilir mi (yetenek + seviye)? Dondurur: true | false, neden.
function Gear:CanEquip(item, token, level)
  if not item then return false, "item" end
  token = token or playerToken()
  level = level or defaultLevel(token)
  if not SLOTS[item.equipLoc] then return false, "slot" end
  if (item.minLevel or 0) > level then return false, "level" end
  if item.classId == 4 then
    if item.subClassId == 6 then
      if not SHIELD[token] then return false, "shield" end
    elseif ARMOR_SLOTS[item.equipLoc] and item.subClassId and item.subClassId >= 1 and item.subClassId <= 4 then
      if item.subClassId > maxArmor(token, level) then return false, "armor" end
    end
  elseif item.classId == 2 then
    local set = WEAPON_SET[token]
    if not (set and set[item.subClassId]) then return false, "weapon" end
    if item.equipLoc == "INVTYPE_WEAPONOFFHAND" and not canDualWield(token, level) then return false, "dualwield" end
  end
  return true
end

-- Sinifin bu seviyedeki asil zirh turu mu? Yalniz zirh yuvalari (kafa, omuz, gogus, bel, bacak, ayak, bilek, el;
-- pelerin kumastir, sayilmaz). Kural: zirh turu sinifin giyebildigi en agir tur (warrior 40'a kadar mail, sonra
-- plate); 40'tan sonra bir alt tur da kabul (plate dusene kadar mail). Daha hafif zirh (warrior'a cloth / leather)
-- oneri listelerinde gosterilmez. Zirh olmayan esyada true.
function Gear:ProperArmor(item, token, level)
  if not (item and item.classId == 4 and ARMOR_SLOTS[item.equipLoc]) then return true end
  local sub = item.subClassId
  if not (sub and sub >= 1 and sub <= 4) then return true end
  token = token or playerToken()
  level = level or defaultLevel(token)
  local top = maxArmor(token, level)
  return sub >= top - (level >= 40 and 1 or 0)
end

-- Oyuncu bu esyayi simdi giyebilir mi (seviye + sinif yetenegi)?
function Gear:Usable(item, token, level)
  return (self:CanEquip(item, token, level))
end

-- Puan
local function weaponKey(item, asOff)
  local loc = item.equipLoc
  if loc == "INVTYPE_2HWEAPON" then return "th" end
  if RANGED_LOCS[loc] then return item.subClassId == 19 and "wand" or "ranged" end
  if loc == "INVTYPE_WEAPONOFFHAND" then return "oh" end
  if loc == "INVTYPE_WEAPON" then return asOff and "oh" or "mh" end
  if loc == "INVTYPE_WEAPONMAINHAND" then return "mh" end
  return nil
end

-- Esyanin statlari bizim anahtarlarla: GetItemStats + (eksikse) ipucu satirlari.
local function itemStats(item, level)
  local out = {}
  for k, v in pairs(item.stats or {}) do
    local map = STAT_MAP[k]
    if map and type(v) == "number" then
      for _, key in ipairs(map) do out[key] = (out[key] or 0) + v end
    end
  end
  local extra = item.extra
  if extra == nil and item.link and P.ItemExtraStats then
    local ok, e = pcall(P.ItemExtraStats, item.link)
    extra = ok and e or nil
  end
  if type(extra) == "table" then
    for k, v in pairs(extra) do if out[k] == nil and type(v) == "number" then out[k] = v end end
  end
  if out.dps == nil and type(item.dps) == "number" then out.dps = item.dps end
  for _, k in ipairs({ "crit", "hit", "spellcrit", "spellhit" }) do
    if out[k] then out[k] = toPercent(out[k], level) end
  end
  return out
end

local function evaluate(self, item, token, specId, level, asOff)
  token = token or playerToken()
  level = level or defaultLevel(token)
  local rows, total = {}, 0
  if not self:CanEquip(item, token, level) then return 0, rows, false end
  local w = self:Weights(token, specId, level)
  local st = itemStats(item, level)
  local function add(key, label, value, weight)
    local pts = value * weight
    rows[#rows + 1] = { key = key, label = label, value = value, weight = weight, points = pts }
    total = total + pts
  end
  for _, key in ipairs(ORDER) do
    local v = st[key]
    if v and v ~= 0 then add(key, self:StatLabel(key), v, w[key] or 0) end
  end
  local wk = weaponKey(item, asOff)
  if wk and st.dps and st.dps > 0 then add(wk, self:StatLabel(wk), st.dps, w[wk] or 0) end
  if item.classId == 4 and item.subClassId == 6 and (w.shield or 0) ~= 0 then add("shield", self:StatLabel("shield"), 1, w.shield) end
  -- Zirh tipi: sinifin bu seviyede giyebildigi en agir tipten hafifse ceza (tip basina %25, en az %40 kalir).
  if item.classId == 4 and ARMOR_SLOTS[item.equipLoc] and item.subClassId and item.subClassId >= 1 and item.subClassId <= 4 then
    local gap = maxArmor(token, level) - item.subClassId
    if gap > 0 and total > 0 then
      local factor = math.max(0.4, 1 - 0.25 * gap)
      rows[#rows + 1] = { key = "armorType", label = self:StatLabel("armorType"), value = factor, weight = nil,
                          points = -(total * (1 - factor)) }
      total = total * factor
    end
  end
  return total, rows, true
end

-- Puan (yuksek = iyi). specId/level verilmezse oyuncunun uzmanligi/seviyesi. asOff (ic kullanim): yan elde degerlendir.
function Gear:Score(item, token, specId, level, asOff)
  if not item then return 0, false end
  local total, _, usable = evaluate(self, item, token, specId, level, asOff)
  return total, usable
end

function Gear:ScoreBreakdown(item, token, specId, level)
  if not item then return {}, 0, false end
  local total, rows, usable = evaluate(self, item, token, specId, level)
  return rows, total, usable
end

-- Karsilastirma
-- Upgrades() taramasi boyunca takili esyalar bir kez okunur (her aday icin yeniden GetItemStats cagirmasin).
local eqCache

local function equipped(slot)
  if eqCache and eqCache[slot] then return eqCache[slot][1], eqCache[slot][2] end
  local fn = P.EquippedItemFull
  if not fn then return nil end
  local ok, d, link = pcall(fn, slot)
  if not ok then return nil end
  link = link or (type(d) == "table" and d.link) or nil
  if eqCache then eqCache[slot] = { d, link } end
  return d, link
end

-- Esya takili olana gore ne kadar iyi (set bonusu haric; Gear:Compare ekler).
local function compareRaw(self, item, token, specId, level)
  token = token or playerToken()
  level = level or defaultLevel(token)
  if not self:CanEquip(item, token, level) then return nil end
  specId = specId or (self:GetSpec(token))
  local function sc(it, asOff) return it and (self:Score(it, token, specId, level, asOff)) or 0 end
  local loc = item.equipLoc
  local new = sc(item)

  if loc == "INVTYPE_2HWEAPON" then
    local mh, mhLink = equipped(16)
    local oh = equipped(17)
    local cur
    if not mh and not oh then cur = EMPTY
    elseif mh and mh.equipLoc == "INVTYPE_2HWEAPON" then cur = sc(mh)
    else cur = sc(mh) + sc(oh, true) end
    return new - cur, 16, mhLink, new
  end

  if OFFHAND_LOCS[loc] then
    local mh = equipped(16)
    if mh and mh.equipLoc == "INVTYPE_2HWEAPON" then return nil end   -- once iki el silah birakilmali
    local oh, ohLink = equipped(17)
    local newOff = sc(item, true)
    return newOff - (oh and sc(oh, true) or EMPTY), 17, ohLink, newOff
  end

  if loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONMAINHAND" then
    local mh, mhLink = equipped(16)
    local best, bestSlot, bestLink, bestScore = new - (mh and sc(mh) or EMPTY), 16, mhLink, new
    if loc == "INVTYPE_WEAPON" and canDualWield(token, level) and not (mh and mh.equipLoc == "INVTYPE_2HWEAPON") then
      local oh, ohLink = equipped(17)
      local newOff = sc(item, true)
      local d = newOff - (oh and sc(oh, true) or EMPTY)
      if d > best then best, bestSlot, bestLink, bestScore = d, 17, ohLink, newOff end
    end
    return best, bestSlot, bestLink, bestScore
  end

  local slots = SLOTS[loc]
  local worst, worstSlot, worstLink
  for _, slot in ipairs(slots) do
    local eq, link = equipped(slot)
    local s = eq and sc(eq) or EMPTY
    if worst == nil or s < worst then worst, worstSlot, worstLink = s, slot, link end
  end
  return new - (worst or 0), worstSlot, worstLink, new
end

-- Set bonuslari (Data/ItemSets.lua: [set] = { parcalar, b = { { parca sayisi, { stat = deger } } } }).
-- Kapatilabilir: Ayarlar > Quest item hints > Advanced "Set bonuses" (ItemNeeds.db.setBonus).
local setOf
local function setIndex()
  if not setOf then
    setOf = {}
    for id, s in pairs(ns.ItemSets or {}) do for _, it in ipairs(s) do setOf[it] = id end end
  end
  return setOf
end
function Gear:SetOf(itemId) return itemId and setIndex()[itemId] or nil end
function Gear:SetBonusOn()
  local IN = ns.ItemNeeds
  return not (IN and IN.db and IN.db.setBonus == false)
end

-- Takili parca sayisi (ayni esya iki yuvada bir sayilir); skipSlot sayilmaz. Set: parca sayisi ve toplam.
function Gear:SetCount(setId, skipSlot)
  local s = ns.ItemSets and ns.ItemSets[setId]
  if not s then return 0, 0 end
  local seen, n = {}, 0
  for slot = 1, 18 do
    local id = slot ~= skipSlot and P.EquippedItemId and P.EquippedItemId(slot) or nil
    if id and not seen[id] and setIndex()[id] == setId then seen[id] = true; n = n + 1 end
  end
  return n, #s
end

-- n parcanin acik bonuslarinin puani (agirliklarla; crit / hit % birimiyle ayni).
function Gear:SetBonusValue(setId, n, w)
  local s, v = ns.ItemSets and ns.ItemSets[setId], 0
  for _, b in ipairs(s and s.b or {}) do
    if n >= b[1] then for k, x in pairs(b[2]) do v = v + x * (w[k] or 0) end end
  end
  return v
end

-- Esya bu yuvaya takilinca set bonusu puaninin degisimi: yeni esyanin seti bir parca kazanir, cikan esyanin seti
-- bir parca kaybeder. shortcut: iki el silah yan eldeki set parcasini da cikarir, o sayilmaz (silah setleri nadir).
function Gear:SetBonusDelta(item, slot, token, specId, level)
  if not (item and slot and ns.ItemSets and self:SetBonusOn()) then return 0 end
  local newSet = self:SetOf(item.id)
  local oldSet = self:SetOf(P.EquippedItemId and P.EquippedItemId(slot))
  if newSet == oldSet then return 0 end
  local w = self:Weights(token, specId, level)
  local d = 0
  if newSet then
    local n = self:SetCount(newSet, slot)
    d = d + self:SetBonusValue(newSet, n + 1, w) - self:SetBonusValue(newSet, n, w)
  end
  if oldSet then
    local n = self:SetCount(oldSet, slot)
    d = d + self:SetBonusValue(oldSet, n, w) - self:SetBonusValue(oldSet, n + 1, w)
  end
  return d
end

-- Esya takili olana gore ne kadar iyi? Dondurur: fark, slot, takili esyanin baglantisi, yeni puan; giyilemezse nil.
-- Set bonusu tamamlanir ya da bozulursa fark ve yeni puan ona gore degisir.
function Gear:Compare(item, token, specId, level)
  token = token or playerToken()
  level = level or defaultLevel(token)
  specId = specId or (self:GetSpec(token))
  local delta, slot, eqLink, new = compareRaw(self, item, token, specId, level)
  if delta and slot then
    local s = self:SetBonusDelta(item, slot, token, specId, level)
    if s ~= 0 then delta, new = delta + s, (new or 0) + s end
  end
  return delta, slot, eqLink, new
end

-- Buyu (enchant) onerileri (Data/Enchants.lua): takili her yuva icin uzmanligina gore en iyi stat buyusu, takili
-- buyudan iyiyse. Seviye siniri: tarifin sari esigi seviye x 5 + 25'i gecmez (o seviyedeki bir buyucunun becerisi;
-- bilinen tarif her zaman sayilir). Bilinmeyen (proc, zirh kiti) buyulu yuva atlanir: degerini olcemeyiz.
local WEAPON_LOCS = { INVTYPE_WEAPON = true, INVTYPE_2HWEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true }
local WDMG_SPEED = 2.6   -- silah hasari buyusu: +N hasar ~ N / ortalama hiz DPS

function Gear:EnchantValue(stats, w, wkey)
  local v = 0
  for k, x in pairs(stats or {}) do
    if k == "wdmg" then v = v + x / WDMG_SPEED * (wkey and w[wkey] or 0)
    else v = v + x * (w[k] or 0) end
  end
  return v
end

local function enchantFits(kind, slot, item)
  if type(kind) == "number" then return kind == slot end
  if kind == "shield" then return slot == 17 and item.classId == 4 and item.subClassId == 6 end
  if kind == "2h" then return slot == 16 and item.equipLoc == "INVTYPE_2HWEAPON" end
  return (slot == 16 or slot == 17) and WEAPON_LOCS[item.equipLoc] == true   -- "weapon": tek el ya da iki el silah
end

-- Dondurur: { { slot, slotName, link, spell, name, stats, gain, known, yellow, mats } } (kazanca gore).
function Gear:EnchantOptions(token, specId, level)
  token = token or playerToken()
  level = level or defaultLevel(token)
  specId = specId or (self:GetSpec(token))
  local list = ns.Enchants or {}
  local w = self:Weights(token, specId, level)
  local cap = level * 5 + 25
  local byEnchant, knows = {}, {}
  for _, e in ipairs(list) do byEnchant[e[3]] = e; knows[e] = P.KnowsSpell and P.KnowsSpell(e[1]) or false end
  local out = {}
  for slot = 1, 18 do
    local item, link = equipped(slot)
    local cur = item and P.EquippedEnchant and P.EquippedEnchant(slot)
    if item and cur and (cur == 0 or byEnchant[cur]) then
      local wkey = weaponKey(item, slot == 17)
      local have = cur ~= 0 and self:EnchantValue(byEnchant[cur][5], w, wkey) or 0
      local best, bestV
      for _, e in ipairs(list) do
        if (knows[e] or e[4] <= cap) and enchantFits(e[2], slot, item) then
          local v = self:EnchantValue(e[5], w, wkey)
          if v > (bestV or 0) then best, bestV = e, v end
        end
      end
      if best and bestV - have > 0.3 then
        out[#out + 1] = { slot = slot, slotName = self:SlotName(slot), link = link, spell = best[1],
          name = (P.SpellName and P.SpellName(best[1])) or ("#" .. best[1]), stats = best[5], gain = bestV - have,
          known = knows[best], yellow = best[4], mats = best.mats }
      end
    end
  end
  table.sort(out, function(a, b) return a.gain > b.gain end)
  return out
end

-- Yukseltme farki (eski imza korunur; specId istege bagli). Giyilemezse nil.
function Gear:UpgradeDelta(item, token, level, specId)
  return (self:Compare(item, token, specId, level))
end

-- Bir kaynaktaki esya (zindan loot'u, gorev odulu) yukseltme mi? Esya en cok `ahead` seviye sonra giyilebilir (o
-- seviyede puanlanir), sinifin asil zirh turu olmali (warrior'a cloth yok), bos yuvaya puansiz esya sayilmaz.
-- Dondurur: fark, yuva, puanlandigi seviye; yukseltme degilse nil.
function Gear:SourceUpgrade(item, token, specId, level, ahead)
  if not (item and SLOTS[item.equipLoc]) or (item.minLevel or 0) > level + (ahead or 0) then return nil end
  local at = math.max(level, item.minLevel or 0)
  if not self:ProperArmor(item, token, at) then return nil end
  local ok, delta, slot, eqLink, score = pcall(self.Compare, self, item, token, specId, at)
  if ok and type(delta) == "number" and delta > 0.5 and slot and (eqLink or (type(score) == "number" and score > 0)) then
    return delta, slot, at
  end
  return nil
end

-- Cantadaki yukseltmeler, en buyuk farktan baslayarak.
function Gear:Upgrades(limit)
  local token, level = playerToken(), P.PlayerLevel()
  local specId = self:GetSpec(token)
  local out = {}
  eqCache = {}
  local scanned, scanErr = pcall(function()
  for bag = 0, P.LastBag() do
    for bagSlot = 1, P.ContainerSlots(bag) do
      local it = P.ContainerItem(bag, bagSlot)
      if it and (it.link or it.id) then
        local d = (it.link and P.ItemDetailsFromLink and P.ItemDetailsFromLink(it.link)) or (it.id and P.ItemDetails(it.id))
        -- gomlek / tabard stat tasimaz: "bos yuvaya +5" gurultusu olmasin
        if d and SLOTS[d.equipLoc] and not NO_UPGRADE_LOCS[d.equipLoc] then
          local ok, delta, slot, eqLink, score = pcall(self.Compare, self, d, token, specId, level)
          local sameItem = eqLink ~= nil and eqLink == (it.link or d.link)        -- takili esyanin kopyasi
          local emptyJunk = eqLink == nil and not (type(score) == "number" and score > 0)
          if ok and type(delta) == "number" and delta > 0.5 and not sameItem and not emptyJunk then
            out[#out + 1] = { slot = slot, slotName = self:SlotName(slot), link = it.link or d.link, itemId = d.id or it.id,
                              equippedLink = eqLink, delta = delta, score = score, bag = bag, bagSlot = bagSlot }
          end
        end
      end
    end
  end
  end)
  eqCache = nil   -- hata olsa da onbellek birakilmaz (Compare baska yerden de cagrilir)
  if not scanned then error(scanErr, 0) end
  table.sort(out, function(a, b) return a.delta > b.delta end)
  limit = limit or 10
  for i = #out, limit + 1, -1 do out[i] = nil end
  return out
end

-- /wf simc: SimulationCraft profili (kopyala, SimC'ye yapistir); /wf simc import: SimC agirliklarini yapistir
ns:RegisterCommand("simc", function(args)
  local Skin = ns.Skin
  if (args or ""):lower():match("^%s*import") then
    Skin:ShowTextBox(L["Import SimC weights"], "", L["Paste the Pawn string, e.g. ( Pawn: v1: \"name\": Class=Warrior, Spec=Arms, Strength=2.1, ... )"], function(text)
      ns:Print(Gear:ImportMessage(Gear:ImportWeights(text)))
    end)
  else
    Skin:ShowTextBox(L["SimulationCraft profile"], Gear:CharacterProfile(), L["Press Ctrl+A, Ctrl+C and paste it into SimulationCraft. Turn on scale factors there."])
  end
end, "[import] SimulationCraft profile of your character, or paste SimC stat weights")

-- Karakter statlari (gizli/okunamayan deger nil).
function Gear:PlayerStats()
  local s = (P.PlayerStatBlock and P.PlayerStatBlock()) or {}
  s.level = P.PlayerLevel()
  s.class = playerToken()
  s.spec = (self:GetSpec(s.class))
  return s
end

-- Zirh plani: simdi giyilecek en agir tip ve (varsa) sonraki tip + seviyesi.
function Gear:ArmorPlan(token, level)
  token = token or playerToken()
  level = level or defaultLevel(token)
  local a = ARMOR[token]
  if not a then return nil end
  local cur = armorTypeFor(token, level)
  local plan = { current = ARMOR_NAMES[cur], currentLabel = (P.ItemSubClassName and P.ItemSubClassName(4, cur)) or ARMOR_NAMES[cur] }
  if a[2] ~= a[1] and level < a[3] then
    plan.next = { type = ARMOR_NAMES[a[2]], label = (P.ItemSubClassName and P.ItemSubClassName(4, a[2])) or ARMOR_NAMES[a[2]], level = a[3] }
  end
  return plan
end
