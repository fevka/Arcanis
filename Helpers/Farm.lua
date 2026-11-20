-- Arcanis: farm pusulasi (modul "Farm"; sahibin istegi, 13 Kasim 2026). Toplanan her damarin / bitkinin / yuzulen
-- derinin / tutulan baligin yeri hesap geneline kaydedilir; ayni yerdekiler birlesir (sayi artar). Toplama
-- oturumlari (bolge + meslek, sure, adet, AH degeri) kaydedilir; bolge basina saatlik adet ve altin bunlardan.
-- Meslekler sayfasi (Modules/ProfessionsPage.lua) gosterir, harita isaretleri (UI/MapMarkers.lua "farm") isaretler.
-- Disa / ice aktarma duz metin (ARCFARM1): arkadasla paylasilir, iceri alinan kayitlar birlesir.
-- Veriler ProfActivity'nin mesajlarindan (ARCANIS_GATHERED, ARCANIS_GATHER_LOOT); korumali eylem yok.
local _, ns = ...

local P = ns.Provider

local Farm = ns:NewModule("Farm", { defaults = { spots = {}, log = {} } })
ns.Farm = Farm

Farm.KINDS = { "Mining", "Herbalism", "Skinning", "Fishing" }
local KIND_OF = { ["Mining"] = "Mining", ["Herb Gathering"] = "Herbalism", ["Skinning"] = "Skinning" }
local MERGE = 0.015      -- harita kesri: bu kadar yakin ayni turden yerler tek kayit
local PER_MAP = 80       -- harita basina en cok yer (en az toplanan atilir)
local LOG_MAX = 60       -- en cok oturum kaydi
local IDLE = 600         -- sn: bu kadar toplama olmazsa oturum biter
local MIN_NODES = 3      -- daha az toplanan oturum kaydedilmez

-- harita isaretleri: yalniz "farm" turunun onbellegi silinir (yeni yer hemen gorunsun)
local function markersDirty()
  local MM = ns.MapMarkers
  if MM and MM.cache then MM.cache.farm = nil end
  if MM then MM.miniBuckets = nil end
end

-- ===== Yerler =====
-- Doner: kayit { x, y, k, n, t }
function Farm:AddSpot(map, x, y, kind, count, at)
  if not (map and x and y and kind) then return nil end
  self.db.spots[map] = self.db.spots[map] or {}
  local list = self.db.spots[map]
  for _, s in ipairs(list) do
    if s.k == kind and math.abs(s.x - x) <= MERGE and math.abs(s.y - y) <= MERGE then
      -- agirlikli ortalama: siklikla toplanan yerin merkezi
      local n = s.n + (count or 1)
      s.x = (s.x * s.n + x * (count or 1)) / n
      s.y = (s.y * s.n + y * (count or 1)) / n
      s.n, s.t = n, math.max(s.t or 0, at or 0)
      return s
    end
  end
  local s = { x = x, y = y, k = kind, n = count or 1, t = at or 0 }
  list[#list + 1] = s
  markersDirty()
  if #list > PER_MAP then
    table.sort(list, function(a, b) return a.n > b.n end)
    for i = #list, PER_MAP + 1, -1 do list[i] = nil end
  end
  return s
end

-- Butun yerler: { { map, x, y, k, n }, ... } (istege bagli tur suzgeci)
function Farm:Spots(kind)
  local out = {}
  for map, list in pairs(self.db.spots or {}) do
    for _, s in ipairs(list) do
      if not kind or s.k == kind then out[#out + 1] = { map = map, x = s.x, y = s.y, k = s.k, n = s.n } end
    end
  end
  return out
end

-- Oyuncunun haritasindaki en yakin yer (istege bagli tur): kayit, uzaklik (yd)
function Farm:Nearest(kind)
  local best, bd
  for _, s in ipairs(self:Spots(kind)) do
    local d = P.DistanceTo and P.DistanceTo(s.map, s.x, s.y)
    if d and (not bd or d < bd) then best, bd = s, d end
  end
  return best, bd
end

-- ===== Oturumlar =====
function Farm:Current() return self.session end

function Farm:Touch(kind)
  local now = P.Now()
  local zone = P.ZoneText and P.ZoneText() or "?"
  local s = self.session
  if s and (s.zone ~= zone or s.k ~= kind or now - s.last > IDLE) then self:EndSession(); s = nil end
  if not s then
    s = { zone = zone, k = kind, start = now, last = now, nodes = 0, value = 0, at = time and time() or 0 }
    self.session = s
  end
  s.last = now
  return s
end

-- Oturumu kapatir: yeterince toplandiysa kayda gecer. Doner: kayit ya da nil.
function Farm:EndSession()
  local s = self.session
  self.session = nil
  if not s or s.nodes < MIN_NODES then return nil end
  local e = { zone = s.zone, k = s.k, secs = math.max(60, math.floor(s.last - s.start)), nodes = s.nodes,
    value = math.floor(s.value), at = s.at }
  local log = self.db.log
  log[#log + 1] = e
  while #log > LOG_MAX do table.remove(log, 1) end
  return e
end

-- Bolge + meslek basina toplam: { { zone, k, secs, nodes, value, perHour, goldHour, runs }, ... } altin/saate gore
function Farm:Stats(kind)
  local by = {}
  for _, e in ipairs(self.db.log or {}) do
    if not kind or e.k == kind then
      local key = e.zone .. "|" .. e.k
      local t = by[key] or { zone = e.zone, k = e.k, secs = 0, nodes = 0, value = 0, runs = 0 }
      by[key] = t
      t.secs, t.nodes, t.value, t.runs = t.secs + e.secs, t.nodes + e.nodes, t.value + e.value, t.runs + 1
    end
  end
  local out = {}
  for _, t in pairs(by) do
    t.perHour = t.nodes / t.secs * 3600
    t.goldHour = t.value / t.secs * 3600
    out[#out + 1] = t
  end
  table.sort(out, function(a, b)
    if a.goldHour ~= b.goldHour then return a.goldHour > b.goldHour end
    return a.perHour > b.perHour
  end)
  return out
end

-- ===== Olaylar =====
function Farm:OnGathered(_, castName)
  local kind = KIND_OF[castName or ""]
  if not kind then return end
  local map, x, y = P.PlayerMapPosition()
  if map then self:AddSpot(map, x, y, kind, 1, time and time() or 0) end
  local s = self:Touch(kind)
  s.nodes = s.nodes + 1
end

function Farm:OnLoot(_, fishing, gained)
  if fishing then
    local map, x, y = P.PlayerMapPosition()
    if map then self:AddSpot(map, x, y, "Fishing", 1, time and time() or 0) end
    local s = self:Touch("Fishing")
    s.nodes = s.nodes + 1
  end
  if self.session and type(gained) == "number" then self.session.value = self.session.value + gained end
end

function Farm:OnEnable()
  ns:Listen("ARCANIS_GATHERED", self, "OnGathered")
  ns:Listen("ARCANIS_GATHER_LOOT", self, "OnLoot")
  ns:On("PLAYER_LOGOUT", self, function(o) o:EndSession() end)
  ns:On("ZONE_CHANGED_NEW_AREA", self, function(o)
    local s = o.session
    if s and s.zone ~= (P.ZoneText and P.ZoneText()) then o:EndSession() end
  end)
end

function Farm:OnDisable()
  ns:Unlisten("ARCANIS_GATHERED", self)
  ns:Unlisten("ARCANIS_GATHER_LOOT", self)
  self:EndSession()
end

-- ===== Disa / ice aktarma =====
-- ARCFARM1|map,x,y,k,n;...|zone~k~secs~nodes~value~at;...   (x, y 0-1, 4 basamak; tur ilk harf: M H S F)
local K2 = { Mining = "M", Herbalism = "H", Skinning = "S", Fishing = "F" }
local K1 = { M = "Mining", H = "Herbalism", S = "Skinning", F = "Fishing" }

function Farm:Export()
  local spots, logs = {}, {}
  for _, s in ipairs(self:Spots()) do
    spots[#spots + 1] = ("%d,%.4f,%.4f,%s,%d"):format(s.map, s.x, s.y, K2[s.k] or "M", s.n)
  end
  for _, e in ipairs(self.db.log or {}) do
    local zone = (e.zone or "?"):gsub("[|;~]", " ")
    logs[#logs + 1] = ("%s~%s~%d~%d~%d~%d"):format(zone, K2[e.k] or "M", e.secs, e.nodes, e.value, e.at or 0)
  end
  return "ARCFARM1|" .. table.concat(spots, ";") .. "|" .. table.concat(logs, ";")
end

-- Doner: eklenen / birlesen yer sayisi, eklenen oturum sayisi; gecersiz metinde nil, hata
function Farm:Import(text)
  if type(text) ~= "string" then return nil, "empty" end
  -- yalniz satir sonlari ve bastaki / sondaki bosluk atilir (bolge adlarinda bosluk var: "Elwynn Forest")
  text = text:gsub("[\r\n]", ""):gsub("^%s+", ""):gsub("%s+$", "")
  local head, spotPart, logPart = text:match("^(ARCFARM1)|([^|]*)|?(.*)$")
  if not head then return nil, "format" end
  local nSpots, nLogs = 0, 0
  for item in spotPart:gmatch("[^;]+") do
    local map, x, y, k, n = item:match("^(%d+),([%d%.]+),([%d%.]+),(%a),(%d+)$")
    map, x, y, n = tonumber(map), tonumber(x), tonumber(y), tonumber(n)
    if map and x and y and K1[k] and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
      self:AddSpot(map, x, y, K1[k], math.min(n or 1, 999), 0)
      nSpots = nSpots + 1
    end
  end
  local have = {}
  for _, e in ipairs(self.db.log) do have[(e.at or 0) .. e.zone .. e.k] = true end
  for item in (logPart or ""):gmatch("[^;]+") do
    local zone, k, secs, nodes, value, at = item:match("^(.-)~(%a)~(%d+)~(%d+)~(%d+)~(%d+)$")
    secs, nodes, value, at = tonumber(secs), tonumber(nodes), tonumber(value), tonumber(at)
    if zone and K1[k] and secs and secs > 0 and not have[at .. zone .. K1[k]] then
      local log = self.db.log
      log[#log + 1] = { zone = zone, k = K1[k], secs = secs, nodes = nodes, value = value, at = at }
      have[at .. zone .. K1[k]] = true
      nLogs = nLogs + 1
    end
  end
  while #self.db.log > LOG_MAX do table.remove(self.db.log, 1) end
  if ns.MapMarkers and ns.MapMarkers.Invalidate then ns.MapMarkers:Invalidate() end
  return nSpots, nLogs
end

function Farm:Clear()
  self.db.spots, self.db.log, self.session = {}, {}, nil
  if ns.MapMarkers and ns.MapMarkers.Invalidate then ns.MapMarkers:Invalidate() end
end
