-- Arcanis: sinif buyuleri (modul "Training"). Hangi buyu/rutbe hangi seviyede ogrenilir: sinif egitmeninin
-- penceresinden okunur (oyunun kendi verisi). Hesap geneli saklanir: ayni siniftan ikinci karakter ilk ziyareti
-- beklemez. Egitmen hic ziyaret edilmediyse istemcinin tablolarindan cikarilmis liste (Data/TrainerSpells.lua) kullanilir.
--   db.classes[SINIF] = { spells = { ["Ad|rutbe"] = { name, rank, level, cost } }, at = "YYYY-MM-DD" }
-- Ziyaretler birlestirilir (portal egitmeni yalniz isinlanmalari listeler, digerlerini silmez).
-- Atlanir: meslek egitmeni (yalniz rutbe ucretleri okunur, db.profFees), silah ustasi (hepsi 1. seviye).
-- Dusuk rutbe denetimi: aksiyon cubugunda bilinen en yuksek rutbeden dusugu kalan buyuler (db.keepRank: bilerek
-- dusuk rutbe tutulan buyu kimlikleri).
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Training = ns:NewModule("Training", { defaults = { classes = {}, lowRank = true, keepRank = {}, profFees = {} } })
ns.Training = Training

Training.SLOTS = 120   -- aksiyon yuvalari (ana cubuk sayfalari + ek cubuklar + durus cubuklari)

local function classData(self, class)
  local all = self.db and self.db.classes
  return all and type(class) == "string" and all[class:upper()] or nil
end

local function recorded(self, class)
  local d = classData(self, class)
  return d ~= nil and next(d.spells or {}) ~= nil
end

local function shipped(class)
  return type(class) == "string" and ns.TrainerSpells and ns.TrainerSpells[class:upper()] or nil
end

function Training:HasData(class)
  return recorded(self, class) or shipped(class) ~= nil
end

-- Listenin kaynagi: "trainer" (egitmen penceresinden), "client" (istemci tablolari) ya da nil.
function Training:Source(class)
  if recorded(self, class) then return "trainer" end
  return shipped(class) and "client" or nil
end

function Training:LastRead(class)
  local d = classData(self, class)
  return d and d.at
end

local function has(list, v)
  for _, x in ipairs(list or {}) do if x == v then return true end end
  return false
end

-- Istemci satiri oyuncuya uyuyor mu: yetenekten gelen rutbe yok, irk / taraf, yetenegin ust rutbesi (yetenek
-- alinmissa). Baska sinifin listesinde irk ve yetenek bakilmaz.
local function shippedFits(r, mine, info)
  if r.t then return false end
  if not mine then return true end
  if r.races and not has(r.races, info.race) then return false end
  if r.faction and info.faction and r.faction ~= info.faction then return false end
  if r.req and not P.KnowsSpell(r.req) then return false end
  return true
end

local function sortSpells(out)
  table.sort(out, function(a, b)
    if a.level ~= b.level then return a.level < b.level end
    if a.name ~= b.name then return a.name < b.name end
    return (a.rank or 0) < (b.rank or 0)
  end)
  return out
end

-- Seviye araligindaki buyuler, seviye sonra ad sonra rutbe sirasiyla: { { level, name, rank, id, cost } }.
function Training:Spells(class, fromLevel, toLevel)
  local out = {}
  local lo, hi = math.max(1, fromLevel or 1), toLevel or 999
  local d = classData(self, class)
  if d and next(d.spells or {}) then
    for _, s in pairs(d.spells) do
      if s.level and s.level >= lo and s.level <= hi then
        out[#out + 1] = { level = s.level, name = s.name, rank = s.rank, cost = s.cost }
      end
    end
    return sortSpells(out)
  end
  local list = shipped(class)
  if not list then return out end
  local info = P.PlayerInfo()
  local mine = P.PlayerClassToken and P.PlayerClassToken() == class:upper()
  for _, r in ipairs(list) do
    local lv = r[1]
    if lv >= lo and lv <= hi and shippedFits(r, mine, info) then
      out[#out + 1] = { level = lv, name = r[2], rank = r[3], id = r[4] }
    end
  end
  return sortSpells(out)
end

-- Bir sonraki egitmen seviyesi (oyuncunun seviyesinden sonra) ve o seviyenin buyuleri; yoksa nil.
function Training:NextLevel(class, level)
  for _, s in ipairs(self:Spells(class, (level or 1) + 1)) do
    return s.level, self:Spells(class, s.level, s.level)
  end
  return nil
end

-- Acik pencere bir sinif egitmeni mi? Sinif buyuleri ya da nil (meslek egitmeni, silah ustasi, liste bos).
-- Mentor ve rehberin trainer adimi ayni kurali kullanir: yalniz sinif egitmeni "ziyaret" sayilir.
local function classRows()
  if P.IsTradeskillTrainer() then return nil end
  local services = P.TrainerServices()
  if not services or #services == 0 then return nil end
  local rows, aboveOne = {}, false
  for _, s in ipairs(services) do
    if s.level and not P.IsWeaponSkillName(s.name) then
      rows[#rows + 1] = s
      if s.level > 1 then aboveOne = true end
    end
  end
  -- silah ustasi (yerellestirilmis adlarla da): tum hizmetler 1. seviye; sinif egitmeni her zaman ust seviye listeler
  if #rows == 0 or not aboveOne then return nil end
  return rows
end

function Training:IsClassTrainerOpen() return classRows() ~= nil end

-- Acik egitmen penceresini oku. Dondurur: eklenen/guncellenen satir sayisi (atlandiysa 0).
function Training:Capture()
  local rows = classRows()
  if not rows then return 0 end
  local class = P.PlayerClassToken and P.PlayerClassToken()
  if not class then return 0 end
  self.db.classes = self.db.classes or {}
  local d = self.db.classes[class] or { spells = {} }
  self.db.classes[class] = d
  d.spells = d.spells or {}
  local n = 0
  for _, s in ipairs(rows) do
    local key = s.name .. "|" .. tostring(s.rank or "")
    local old = d.spells[key]
    if not old or old.level ~= s.level then n = n + 1 end
    d.spells[key] = { name = s.name, rank = s.rank, level = s.level, cost = s.cost or (old and old.cost) }
  end
  local fmt = date or (os and os.date)   -- oyunda global "date"
  d.at = fmt and fmt("%Y-%m-%d") or d.at
  if n > 0 then ns:Send("ARCANIS_TRAINING_CHANGED", class) end
  return n
end

-- Meslek rutbeleri (Ingilizce hizmet adlari); ucret rutbe adina gore saklanir (rutbe ucreti meslekten bagimsiz).
Training.PROF_RANKS = { "Apprentice", "Journeyman", "Expert", "Artisan" }

-- Acik meslek egitmeninden rutbe ucretlerini oku. Dondurur: okunan ucret sayisi.
function Training:CaptureFees()
  if not P.IsTradeskillTrainer() then return 0 end
  local n = 0
  for _, s in ipairs(P.TrainerServices() or {}) do
    local text = (s.name or "") .. " " .. (s.sub or "")
    for _, rank in ipairs(self.PROF_RANKS) do
      if s.cost and text:find(rank, 1, true) then
        self.db.profFees[rank] = s.cost
        n = n + 1
        break
      end
    end
  end
  return n
end

-- Rutbe ucreti (bakir) ya da nil (henuz bir meslek egitmeninde gorulmedi). rank: "Journeyman"...
function Training:ProfFee(rank)
  return self.db and self.db.profFees and self.db.profFees[rank] or nil
end

function Training:OnTrainer()
  self:CaptureFees()
  -- liste ayni karede dolmayabilir: bos ise TRAINER_UPDATE'te bir kez daha denenir
  self.retry = self:Capture() == 0 and not recorded(self, P.PlayerClassToken and P.PlayerClassToken())
end

function Training:OnTrainerUpdate()
  self:CaptureFees()
  if not self.retry then return end
  self.retry = false
  self:Capture()
end

-- ===== Dusuk rutbe denetimi =====

-- Sinifin rutbe tablosu (istemci verisi; yetenekten gelen rutbeler dahil): byId[id] = { name, rank }, byName[ad] = { id... }
local rankCache = {}
function Training:RankIndex(class)
  class = type(class) == "string" and class:upper() or nil
  if not class then return nil end
  if rankCache[class] then return rankCache[class] end
  local list = shipped(class)
  if not list then return nil end
  local idx = { byId = {}, byName = {} }
  for _, r in ipairs(list) do
    idx.byId[r[4]] = { name = r[2], rank = r[3] }
    local ranks = idx.byName[r[2]] or {}
    idx.byName[r[2]] = ranks
    ranks[r[3]] = r[4]
  end
  rankCache[class] = idx
  return idx
end

-- Aksiyon cubugunda bilinen en yuksek rutbeden dusuk kalan buyuler:
-- { { slot, id, name, rank, best, bestRank, kept } } (kept = bilerek tutuluyor, db.keepRank). withKept: onlar da.
function Training:LowRanks(withKept)
  local out = {}
  local idx = self:RankIndex(P.PlayerClassToken and P.PlayerClassToken())
  if not idx then return out end
  local keep = self.db.keepRank or {}
  local bestOf = {}
  for slot = 1, self.SLOTS do
    local id = P.ActionSpell(slot)
    local e = id and idx.byId[id]
    if e and (withKept or not keep[id]) then
      local best = bestOf[e.name]
      if best == nil then
        best = false
        local ranks = idx.byName[e.name]
        for r = table.maxn(ranks), 1, -1 do
          if ranks[r] and P.KnowsSpell(ranks[r]) then best = { id = ranks[r], rank = r } break end
        end
        bestOf[e.name] = best
      end
      if best and best.rank > e.rank then
        out[#out + 1] = { slot = slot, id = id, name = e.name, rank = e.rank, best = best.id, bestRank = best.rank,
          kept = keep[id] and true or nil }
      end
    end
  end
  return out
end

function Training:SetKeep(id, value)
  self.db.keepRank[id] = value and true or nil
end

-- Hepsini en yuksek rutbeye cevir (tutulanlar haric). Savasta: savas bitince yapilir. Dondurur: degisen yuva sayisi.
function Training:UpdateRanks()
  if P.InLockdown() then
    self.pendingUpdate = true
    ns:Print(L["Spell ranks will be updated after combat."])
    return 0
  end
  local n = 0
  for _, e in ipairs(self:LowRanks()) do
    if P.PlaceSpell(e.slot, e.best) then n = n + 1 end
  end
  if n > 0 then ns:Print(L["Updated %d action bar spells to their best rank."]:format(n)) end
  return n
end

-- Denetim: dusuk rutbe varsa tek bildirim (tiklayinca hepsini cevirir). Ayni sayi tekrar bildirilmez.
function Training:CheckRanks()
  if not self.db.lowRank then return 0 end
  local list = self:LowRanks()
  if #list == 0 then self.lastLow = 0 return 0 end
  if self.lastLow ~= #list and ns.Toast then
    ns.Toast:Show(L["Low spell ranks on your bars: %d. Click to update them."]:format(#list), "info", nil,
      function() Training:UpdateRanks() end, { cat = "level", key = "lowrank" })
  end
  self.lastLow = #list
  return #list
end

function Training:OnEnable()
  ns:On("TRAINER_SHOW", self, "OnTrainer")
  ns:On("TRAINER_UPDATE", self, "OnTrainerUpdate")
  -- egitmenden sonra / yeni buyu ogrenince: liste ayni anda guncellenmeyebilir, biraz sonra bakilir
  local function later() P.After(1, function() if Training:IsEnabled() then Training:CheckRanks() end end) end
  ns:On("TRAINER_CLOSED", self, later)
  ns:On("LEARNED_SPELL_IN_SKILL_LINE", self, later)
  ns:On("PLAYER_REGEN_ENABLED", self, function(o)
    if o.pendingUpdate then o.pendingUpdate = nil; o:UpdateRanks() end
  end)
end

ns:RegisterCommand("ranks", function(args)
  if (args or ""):lower():match("update") then Training:UpdateRanks() return end
  local list = Training:LowRanks()
  if #list == 0 then ns:Print(L["No low spell ranks on your action bars."]) return end
  for _, e in ipairs(list) do
    ns:Print(L["%s: rank %d on your bar, rank %d known"]:format(e.name, e.rank, e.bestRank))
  end
  ns:Print(L["Type /wf ranks update to swap them."])
end, "[update] action bar spells below your best rank")
