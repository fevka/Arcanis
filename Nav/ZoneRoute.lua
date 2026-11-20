-- Arcanis: bolgeler arasi yol (Data/ZoneGates.lua). Ok hedefi oyuncunun bolgesinden baska bir bolgedeyse (ayni
-- kitada) harita izi ve ok dagin ustunden duz cizgi yerine bolge gecitlerinden gecer: gecit grafiginde en kisa yol
-- (Dijkstra; ayni bolgeye dokunan iki gecit arasi duz mesafe). Gecitler oyunun arazisinden: yuruyerek gecilen
-- sinirlar (tools/build_zone_gates.py). Grafikte yol yoksa (kopru / tunel gibi WMO gecisleri okunmuyor) nil:
-- ok eskisi gibi dogrudan gider.
local _, ns = ...

local P = ns.Provider
local ZR = {}
ns.ZoneRoute = ZR

-- dunya yardi -> haritanin 0-1 koordinati (harita disina tasabilir; ok ve iz ayni haritadan okur)
local function toMap(map, wx, wy)
  local r = P.MapWorldRect(map)
  if not r then return nil end
  return (wy - r.wy0) / (r.wy1 - r.wy0), (wx - r.wx0) / (r.wx1 - r.wx0)
end
ZR.ToMap = toMap

local function dist(ax, ay, bx, by) return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2) end

-- Tehlikeli bolge: en dusuk seviyesi oyuncunun HAZARD_GAP ustunde. Icinden gecen yol HAZARD_COST kat pahali sayilir
-- (secimde; gosterilen mesafe gercek). Baslangic ve hedef bolgesi sayilmaz (zaten oradasin / oraya gidiyorsun).
ZR.HAZARD_GAP, ZR.HAZARD_COST = 4, 4
local minCache = {}
function ZR.ZoneMin(ui)
  if minCache[ui] == nil then
    local min = false
    for name, id in pairs(ns.Zones and ns.Zones.defaults or {}) do   -- Ingilizce ad (ZoneInfo verisi Ingilizce)
      if id == ui then
        local d = ns.ZoneInfo and ns.ZoneInfo:Get(name)
        if d and d.min then min = d.min break end
      end
    end
    minCache[ui] = min
  end
  return minCache[ui] or nil
end

-- Yuruyusle gecilmeyen baglantilar (ayni kitada): portal ve Deeprun Tram uclari istemcinin kendi AreaTrigger
-- tablosundaki tetikleyici konumlari (#527 Darnassus <-> #542 Rut'theran, #2173 Stormwind <-> #2175 Ironforge);
-- t: gecis suresi (sn, tram icin ortalama bekleme + yolculuk). Ayni kitadaki gemi hatlari Data/Transit.lua'dan.
-- kind / na / nb: harita isaretleri (UI/MapMarkers.lua "transport") icin tur ve uclarin yer adi.
ZR.LINKS = {
  { c = 1, a = { 9947.5, 2630.0 }, b = { 8799.0, 970.0 }, t = 5,       -- Darnassus <-> Rut'theran portali
    kind = "portal", na = "Darnassus", nb = "Rut'theran Village" },
  { c = 0, a = { -8346.0, 514.0 }, b = { -4840.0, -1330.0 }, t = 130,  -- Deeprun Tram
    kind = "tram", na = "Stormwind", nb = "Ironforge" },
}

-- Noktanin bolge haritasi (oyunun bolge adindan; onbellekli) ya da nil.
local zoneAt = {}
function ZR.ZoneOf(c, x, y)
  local key = ("%d:%.0f:%.0f"):format(c, x, y)
  if zoneAt[key] == nil then
    local name = P.ZoneAtWorld and P.ZoneAtWorld(c, x, y)
    zoneAt[key] = (name and ns.Zones and ns.Zones:Resolve(name)) or false
  end
  return zoneAt[key] or nil
end

-- Kitanin baglanti uclari (dugum listesine eklenir): her uc { bolge, bolge, x, y, link = karsi ucun sirasi
-- (gecit listesinin ardindan), cost = yard }. Gemi: zeplin yalniz Horde; bekleme yarim donem + yolculuk.
function ZR:LinkNodes(c)
  local nodes, base = {}, #((ns.ZoneGates and ns.ZoneGates[c]) or {})   -- uclar gecitlerin ardina eklenir
  local speed = (ns.Travel and ns.Travel.Speed and ns.Travel:Speed()) or 7
  local function add(ax, ay, bx, by, sec, both)
    local za, zb = ZR.ZoneOf(c, ax, ay), ZR.ZoneOf(c, bx, by)
    if not (za and zb) then return end
    local i = base + #nodes + 1
    nodes[#nodes + 1] = { za, za, ax, ay, link = i + 1, cost = sec * speed }
    nodes[#nodes + 1] = { zb, zb, bx, by, link = both and i or nil, cost = sec * speed }
  end
  for _, l in ipairs(ZR.LINKS) do
    if l.c == c then add(l.a[1], l.a[2], l.b[1], l.b[2], l.t, true) end
  end
  local T = ns.Transit
  local horde = (P.PlayerInfo() or {}).faction == "Horde"
  for _, r in pairs(T and T.routes or {}) do
    if r.kind ~= "zeppelin" or horde then
      for k, s in ipairs(r.stops) do
        local e = r.stops[k % #r.stops + 1]
        local d, f = T.docks[s[1]], T.docks[e[1]]
        if d and f and d[1] == c and f[1] == c and s ~= e then
          add(d[2], d[3], f[2], f[3], (r.period / 2 + (e[2] - s[3]) % r.period) / 1000, false)
        end
      end
    end
  end
  return nodes
end

-- Oyuncudan hedefe (map, x, y 0-1) gecit noktalari: { {x, y}, ... } hedefin haritasinda, ya da nil.
function ZR:Route(map, tx, ty)
  local pm, px, py = P.PlayerMapPosition()
  if not (map and pm and px) or pm == map then return nil end
  local c1, ax, ay = P.WorldPos(pm, px, py)
  local c2, bx, by = P.WorldPos(map, tx, ty)
  local data = c1 and c1 == c2 and ns.ZoneGates and ns.ZoneGates[c1]
  if not data then return nil end
  -- dugumler: gecitler { bolgeA, bolgeB, x, y } + baglanti uclari { bolge, bolge, x, y, link = karsi uc, cost }
  local gates = {}
  for i, g in ipairs(data) do gates[i] = g end
  for _, e in ipairs(ZR:LinkNodes(c1)) do gates[#gates + 1] = e end
  local n = #gates
  local function touches(g, z) return g[1] == z or g[2] == z end
  local level = P.PlayerLevel() or 1
  local function factor(z)   -- bu bolgenin icinden yurumenin agirligi
    if z == pm or z == map then return 1 end
    local min = ZR.ZoneMin(z)
    return (min and min >= level + ZR.HAZARD_GAP) and ZR.HAZARD_COST or 1
  end
  -- iki gecit arasi: ortak bolgeden gecilir (iki ortak bolge varsa ucuz olani)
  local function through(g, h)
    local f
    for _, z in ipairs({ g[1], g[2] }) do
      if touches(h, z) then local k = factor(z); if not f or k < f then f = k end end
    end
    return f
  end
  -- Dijkstra: dugumler gecitler; baslangic oyuncunun bolgesine dokunan gecitlere baglanir
  local d, from, done = {}, {}, {}
  for i = 1, n do if touches(gates[i], pm) then d[i] = dist(ax, ay, gates[i][3], gates[i][4]) end end
  local best, bestEnd
  while true do
    local u, du
    for i = 1, n do if d[i] and not done[i] and (not du or d[i] < du) then u, du = i, d[i] end end
    if not u or (best and du >= best) then break end
    done[u] = true
    local g = gates[u]
    if touches(g, map) then
      local total = du + dist(g[3], g[4], bx, by)
      if not best or total < best then best, bestEnd = total, u end
    end
    for v = 1, n do
      local h = gates[v]
      local f = not done[v] and through(g, h)
      if f then
        local nd = du + dist(g[3], g[4], h[3], h[4]) * f
        if not d[v] or nd < d[v] then d[v], from[v] = nd, u end
      end
    end
    -- bagliysa karsi uca (portal, tram, gemi): sure yuruyus mesafesine cevrilmis bedel
    local w = g.link and gates[g.link]
    if w and not done[g.link] then
      local nd = du + g.cost
      if not d[g.link] or nd < d[g.link] then d[g.link], from[g.link] = nd, u end
    end
  end
  if not bestEnd then return nil end
  local chain, k = {}, bestEnd
  while k do table.insert(chain, 1, k); k = from[k] end
  local out = {}
  for _, i in ipairs(chain) do
    local mx, my = toMap(map, gates[i][3], gates[i][4])
    if not mx then return nil end
    out[#out + 1] = { mx, my }
  end
  return out
end
