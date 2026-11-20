-- Arcanis: ulasim yardimcisi (modul "Transport"). Veri: Data/Transit.lua (tools/import_transit.py).
--   * Ceset oku: hayaletken ok cesede doner; dirilince onceki hedef geri gelir.
--   * Gemi / zeplin saatleri: bir kez binince (hiz + rota uzerinde) hattin evresi sunucu saatine baglanir;
--     sonra iskele yakininda bir sonraki kalkis adada canli geri sayim olarak gorunur (Island.LIVE "boat").
--   * Rota uyarisi: oka giden duz cizgi seviyenin cok ustunde bir bolgeden ya da dusman kasabasindan geciyorsa uyarir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Transport = ns:NewModule("Transport", {
  defaults = { enabled = true, corpse = true, boats = true, hazards = true, anchors = {} },
})
ns.Transport = Transport

local function hypot(dx, dy) return math.sqrt(dx * dx + dy * dy) end

-- Ceset oku
local CORPSE_LOOKS = 10   -- olunce ceset konumu bir an sonra gelir; saniyede bir bu kadar denenir

function Transport:PointCorpse(tries)
  if not (self.db.corpse and P.IsGhost() and ns.Nav) then return end
  local map, x, y = P.CorpsePosition()
  if not map then
    tries = (tries or 0) + 1
    if tries <= CORPSE_LOOKS and P.After then P.After(1, function() Transport:PointCorpse(tries) end) end
    return
  end
  local t = ns.Nav:GetTarget()
  if not (t and t.source == "corpse") then self.before = t end
  ns.Nav:SetTarget(map, x, y, L["Your corpse"], "corpse", 20)
end

function Transport:OnLife()
  if P.IsGhost() then return self:PointCorpse() end
  local t = ns.Nav and ns.Nav:GetTarget()
  if not (t and t.source == "corpse") then return end
  local b = self.before
  self.before = nil
  if b then ns.Nav:SetTarget(b.map, b.x, b.y, b.label, b.source, b.radius, b.path, b.hint, b.entrance) else ns.Nav:ClearTarget() end
end

-- hayaletken rehber oku degistirirse (yeni adim) ok yine cesede doner; rehber hedefi sonra geri gelir
function Transport:OnTarget(_, t)
  if t and t.source ~= "corpse" and self.db.corpse and P.IsGhost() then
    self.before = t
    self:PointCorpse()
  elseif t and t.source ~= "corpse" and ns.Nav and ns.Nav:IsEnabled() then   -- kapali ok icin rota uyarisi yok
    self:CheckRoute()
  end
end

-- Gemi / zeplin saatleri
local MIN_SPEED, MAX_SPEED = 18, 45   -- yd/s: gemi ~30; kosan oyuncu 7, binekli en fazla 14
local ON_ROUTE = 40                   -- yard: rota cizgisine bu kadar yakinsa gemidesin
local NEAR_DOCK = 200                 -- yard: iskeleye bu kadar yakinken siradaki kalkis gosterilir
local STALE = 12 * 3600               -- sn: bundan eski olcum "~" ile yaklasik gosterilir (sunucu yeniden baslamis olabilir)

local function anchors()
  local realm = (GetRealmName and GetRealmName()) or "?"
  Transport.db.anchors[realm] = Transport.db.anchors[realm] or {}
  return Transport.db.anchors[realm]
end

-- Noktanin hattaki evresi (ms) ya da nil: hareket yonune uyan en yakin rota parcasi.
function Transport.Phase(route, c, x, y, mx, my)
  local f, best, bestD = route.frames, nil, ON_ROUTE
  for i = 1, #f - 4, 4 do
    local t1, c1, x1, y1, t2, c2, x2, y2 = f[i], f[i + 1], f[i + 2], f[i + 3], f[i + 4], f[i + 5], f[i + 6], f[i + 7]
    if c1 == c and c2 == c then
      local sx, sy = x2 - x1, y2 - y1
      local len2 = sx * sx + sy * sy
      if len2 > 0 and (mx * sx + my * sy) > 0 then
        local u = math.max(0, math.min(1, ((x - x1) * sx + (y - y1) * sy) / len2))
        local d = hypot(x - (x1 + u * sx), y - (y1 + u * sy))
        if d < bestD then best, bestD = t1 + u * (t2 - t1), d end
      end
    end
  end
  return best
end

-- Saniyede bir: oyuncu gemi hiziyla bir rota uzerinde ilerliyorsa hattin evresi kaydedilir.
function Transport:Sample()
  if not self.db.boats then self.last = nil return end
  local c, x, y = P.PlayerWorldPos()
  local now = P.ServerNow()
  local prev = self.last
  self.last = c and now and { c = c, x = x, y = y, t = P.Now() } or nil
  if not (prev and self.last and prev.c == c) or P.OnTaxi() then return end
  local dt = self.last.t - prev.t
  if dt <= 0 then return end
  local speed = hypot(x - prev.x, y - prev.y) / dt
  if speed < MIN_SPEED or speed > MAX_SPEED then return end
  -- iki hat ayni yoldan cikabilir (Menethil): nokta birden cok hatta uyuyorsa hangisinde oldugun belli
  -- degil, kaydedilmez; yollar ayrilinca dogru hat ogrenilir
  local hits, n, hitId, hitPh = {}, 0, nil, nil
  for id, r in pairs(ns.Transit and ns.Transit.routes or {}) do
    local ph = Transport.Phase(r, c, x, y, x - prev.x, y - prev.y)
    if ph then hits[id] = ph; n = n + 1; hitId, hitPh = id, ph end
  end
  -- gemideyken ok baska kitadaki adimi beklemeye alir (Nav.FlyFirst): ortak yolda hangi hat oldugu fark etmez
  if n > 0 then self.riding = { at = P.Now(), hits = hits } end
  if n == 1 then anchors()[hitId] = { epoch = now - hitPh / 1000, seen = now } end
end

local RIDE_FRESH = 4   -- sn: son gemi ornegi bundan eskiyse gemide sayilmaz (iskelede durdu, indi)

-- Gemideysen ve siradaki iskele c kitasindaysa { kind, dest } ya da nil. Siradaki iskele bu kitadaysa
-- (Menethil -> Southshore -> Auberdine) nil: orada inilir, plan oradan yeniden kurulur.
function Transport:RidingTo(c)
  local r, T = self.riding, ns.Transit
  if not (r and T and c) or P.OnTaxi() or (P.Now() - r.at) > RIDE_FRESH then return nil end
  for id, ph in pairs(r.hits) do
    local route = T.routes[id]
    -- siradaki varis: evreden sonraki ilk varis (donem basa sarar)
    local nextStop, bestWait
    for _, s in ipairs(route and route.stops or {}) do
      local wait = (s[2] - ph) % route.period
      if not bestWait or wait < bestWait then nextStop, bestWait = s, wait end
    end
    local d = nextStop and T.docks[nextStop[1]]
    if d and d[1] == c then return { kind = route.kind, dest = d[4], id = id } end
  end
  return nil
end

-- Iskeleden siradaki kalkis: { kind, to (yer adi), wait (sn), boarding } ya da nil (hat henuz olculmedi).
function Transport:NextDeparture(dock)
  local T, now = ns.Transit, P.ServerNow()
  if not (T and now) then return nil end
  local best
  for id, r in pairs(T.routes) do
    local a = anchors()[id]
    local epoch = type(a) == "table" and a.epoch or a   -- eski kayit: yalniz sayi
    local stale = type(a) ~= "table" or now - a.seen > STALE
    for k, s in ipairs(epoch and r.stops or {}) do
      if s[1] == dock then
        local phase = ((now - epoch) * 1000) % r.period
        local wait = (s[3] - phase) % r.period
        local boarding
        if s[2] <= s[3] then boarding = phase >= s[2] and phase < s[3]
        else boarding = phase >= s[2] or phase < s[3] end
        local nextStop = r.stops[k % #r.stops + 1]
        if not best or wait < best.wait then
          best = { kind = r.kind, to = T.docks[nextStop[1]] and T.docks[nextStop[1]][4] or "?", wait = wait / 1000,
                   boarding = boarding, stale = stale }
        end
      end
    end
  end
  return best
end

-- Iskeleye `after` sn sonra varilirsa hattin bu durak kalkisini bekleme (sn), ya da nil (hat olculmedi / olcum eski:
-- plan o zaman yarim donem varsayar).
function Transport:DepartureWait(routeId, stop, after)
  local T, now = ns.Transit, P.ServerNow()
  local r = T and T.routes[routeId]
  local a = r and now and anchors()[routeId]
  if type(a) ~= "table" or now - a.seen > STALE then return nil end
  local phase = ((now + (after or 0) - a.epoch) * 1000) % r.period
  return ((stop[3] - phase) % r.period) / 1000
end

-- Oyuncunun yanindaki iskeleler (bir limanda birden cok iskele olur: Menethil, Orgrimmar kuleleri).
function Transport:NearDocks()
  local c, x, y = P.PlayerWorldPos()
  local out = {}
  for id, d in pairs(c and ns.Transit and ns.Transit.docks or {}) do
    if d[1] == c and hypot(d[2] - x, d[3] - y) < NEAR_DOCK then out[#out + 1] = id end
  end
  return out
end

-- Canli ada: "Boat to Ratchet 1:20" (iskele yakininda, hat olculduyse; en yakin kalkis).
function Transport:LiveText()
  if not (self:IsEnabled() and self.db.boats) then return nil end
  local d
  for _, dock in ipairs(self:NearDocks()) do
    local n = self:NextDeparture(dock)
    if n and (not d or (n.boarding and not d.boarding) or (n.boarding == d.boarding and n.wait < d.wait)) then d = n end
  end
  if not d then return nil end
  local label
  if d.to == "?" then label = d.kind == "zeppelin" and L["Next zeppelin"] or L["Next boat"]   -- adsiz iskele
  else label = (d.kind == "zeppelin" and L["Zeppelin to %s"] or L["Boat to %s"]):format(d.to) end
  if ns.Nav and ns.Nav.TravelIcon then label = ns.Nav.TravelIcon("boat", d.kind) .. label end
  local value = d.boarding and L["Boarding"] or ns.Island.Clock(d.wait)
  return label, d.stale and ("~" .. value) or value   -- eski olcum: yaklasik
end

-- Rota uyarisi
local LEVEL_GAP = 4                    -- bolgenin en dusuk seviyesi seninkinden bu kadar yuksekse
local SAMPLE = 150                     -- yard: cizgi boyunca bolge ornegi araligi
local TOWN_RADIUS, OWN_NEAR, ENDS = 150, 400, 300

local function segDist(px, py, x1, y1, x2, y2)
  local sx, sy = x2 - x1, y2 - y1
  local len2 = sx * sx + sy * sy
  local u = len2 > 0 and math.max(0, math.min(1, ((px - x1) * sx + (py - y1) * sy) / len2)) or 0
  return hypot(px - (x1 + u * sx), py - (y1 + u * sy))
end

-- Duz cizgi uzerindeki tehlike: { zone, min } ya da { town } ya da nil.
function Transport.Hazard(c, x1, y1, x2, y2, level, faction)
  local T = ns.Transit
  for _, n in pairs(T and T.nodes or {}) do
    if n[1] == c and n[5] ~= "" and n[5] ~= faction and n[5] ~= "Neutral"
      and segDist(n[2], n[3], x1, y1, x2, y2) < TOWN_RADIUS
      and hypot(n[2] - x1, n[3] - y1) > ENDS and hypot(n[2] - x2, n[3] - y2) > ENDS then
      local shared = false
      for _, o in pairs(T.nodes) do
        if o[1] == c and o[5] == faction and hypot(o[2] - n[2], o[3] - n[3]) < OWN_NEAR then shared = true end
      end
      if not shared then return { town = (n[4]:match("^([^,]+)") or n[4]) } end
    end
  end
  local here, there = P.ZoneAtWorld(c, x1, y1), P.ZoneAtWorld(c, x2, y2)
  local steps = math.floor(hypot(x2 - x1, y2 - y1) / SAMPLE)
  for i = 1, steps - 1 do
    local z = P.ZoneAtWorld(c, x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps)
    local d = z and z ~= here and z ~= there and ns.ZoneInfo and ns.ZoneInfo:Get(z)
    if d and d.min and d.min >= level + LEVEL_GAP then return { zone = z, min = d.min } end
  end
end

function Transport:CheckRoute()
  if not (self:IsEnabled() and self.db.hazards and ns.Nav) then return end
  local t = ns.Nav:GetTarget()
  if not t or t.source == "corpse" then return end
  local key = ("%s:%.3f:%.3f"):format(tostring(t.map), t.x or 0, t.y or 0)
  self.warned = self.warned or {}   -- hedef iki yer arasinda gidip gelse de ayni uyari bir kez
  if self.warned[key] then return end
  local c1, x1, y1 = P.PlayerWorldPos()
  local c2, x2, y2 = P.WorldPos(t.map, t.x, t.y)
  -- baska kitadaki hedef "uyarildi" sayilmaz: kitaya varinca yol yine denetlenir
  if not (c1 and c2 == c1) then return end
  self.warned[key] = true
  local h = Transport.Hazard(c1, x1, y1, x2, y2, P.PlayerLevel(), P.PlayerInfo().faction)
  if h and h.town then ns.Toast:Show(L["Your route passes %s, an enemy town."]:format(h.town), "warn", nil, nil, { cat = "travel" })
  elseif h then ns.Toast:Show(L["Your route crosses %s (level %d+)."]:format(h.zone, h.min), "warn", nil, nil, { cat = "travel" }) end
end

function Transport:OnEnable()
  ns:On("PLAYER_ALIVE", self, "OnLife")
  ns:On("PLAYER_UNGHOST", self, "OnLife")
  ns:On("PLAYER_DEAD", self, "OnLife")
  ns:On("PLAYER_ENTERING_WORLD", self, "OnLife")
  ns:Listen("ARCANIS_TARGET_CHANGED", self, "OnTarget")
  if C_Timer and C_Timer.NewTicker and not self.ticker then
    self.ticker = C_Timer.NewTicker(1, function() if Transport:IsEnabled() then Transport:Sample() end end)
  end
end
