-- Arcanis: quest hedeflerinin canavar/obje alanlari. Veri: Data/Brain/QuestAreas.lua.
--   Areas:Ranked(q, i, text) -> { { map, x, y, n, yards, dir, name } } yogunluk/mesafe sirasiyla
--   Areas:Best(step)         -> map, x, y: hedef adimi icin en iyi alan (oku buraya cevirir)
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Areas = {}
ns.Areas = Areas

local PIN_YARDS = 100   -- oyunun harita isaretine bu kadar yakin alan "dogrulanmis" sayilir
Areas.POI_TRUST = 400   -- yd: hicbir alanimiz oyunun isaretine bu kadar yakin degilse isaret kullanilir
local DIRS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

local function data() return ns.BrainData and ns.BrainData.areas end

-- Oyundaki hedefe karsilik gelen veri satiri: hedef metninde ad geciyorsa o, yoksa ayni sira, tek satirsa o.
function Areas:Entry(q, i, text)
  local list = data() and data()[q]
  if not list then return nil end
  if type(text) == "string" then
    local low = text:lower()
    for _, e in ipairs(list) do
      if low:find(e[1]:lower(), 1, true) then return e end
    end
  end
  return list[i] or (#list == 1 and list[1]) or nil
end

-- Yon: dogu/guney bileseninden 8 yonlu kisaltma (yerellestirilmis).
function Areas.Dir(east, south)
  if not (east and south) then return nil end
  local a = math.deg(math.atan2(east, -south)) % 360   -- 0 = kuzey, saat yonunde
  return L[DIRS[math.floor((a + 22.5) / 45) % 8 + 1]]
end

function Areas:Ranked(q, i, text)
  local e = self:Entry(q, i, text)
  if not (e and ns.Zones) then return nil end
  local pmap, px, py
  if P.QuestMapPos then pmap, px, py = P.QuestMapPos(q) end
  local pinW = pmap and { P.WorldPos(pmap, px, py) }
  local out = {}
  for k = 2, #e do
    local c = e[k]
    local map = ns.Zones:Resolve(c[1])
    if map then
      local yards, east, south = P.VectorTo(map, c[2], c[3])
      local score = c[4] / (1 + (yards or 1000) / 200)
      if pinW and pinW[1] then
        local cc, wx, wy = P.WorldPos(map, c[2], c[3])
        local d = cc and P.WorldDistance(cc, wx, wy, pinW[1], pinW[2], pinW[3])
        if d and d <= PIN_YARDS then score = score * 2 end
      end
      out[#out + 1] = { map = map, x = c[2], y = c[3], n = c[4], yards = yards, dir = Areas.Dir(east, south),
        name = e[1], score = score }
    end
  end
  table.sort(out, function(a, b) return a.score > b.score end)
  return out
end

-- Hedef adimi icin en iyi alan: adimin hedefi (bittiyse ilk bitmemis hedef). Yoksa nil.
function Areas:Best(step)
  local q = step and step.quest
  if not (q and data() and data()[q]) then return nil end
  local objs = P.GetObjectives(q) or {}
  local i = step.objective
  if not i or (objs[i] and objs[i].finished) then
    i = nil
    for k, o in ipairs(objs) do if not o.finished then i = k break end end
    if not i and #objs > 0 then return nil end   -- hepsi bitti: alan yok (teslim yeri haritadan gelir)
  end
  local r = self:Ranked(q, i or step.objective or 1, objs[i or 0] and objs[i or 0].text)
  local best = r and r[1]
  if not best then return nil end
  -- oyunun gorev isareti (sunucunun quest_poi alani) var ve hicbir alanimiz ona yakin degil: verimiz yanlis
  -- (Dormant Shade Tirisfal yerine Stranglethorn, Keeper of the Flame Westfall yerine Wetlands): isaret kullanilir
  if P.QuestMapPos then
    local pm, px, py = P.QuestMapPos(q)
    local pw = pm and { P.WorldPos(pm, px, py) }
    if pw and pw[1] then
      local near = false
      for _, a in ipairs(r) do
        local c, wx, wy = P.WorldPos(a.map, a.x, a.y)
        local d = c and P.WorldDistance(c, wx, wy, pw[1], pw[2], pw[3])
        if d and d <= Areas.POI_TRUST then near = true break end
      end
      if not near then return pm, px, py end
    end
  end
  -- histerezis: ayni hedef icin onceki secim, yenisi en az %30 daha iyi olmadikca korunur
  self.lastBest = self.lastBest or {}
  local key = q .. ":" .. tostring(i or step.objective or 1)
  local prev = self.lastBest[key]
  if prev and (prev.x ~= best.x or prev.y ~= best.y or prev.map ~= best.map) then
    for _, a in ipairs(r) do
      if a.map == prev.map and a.x == prev.x and a.y == prev.y then
        if best.score < a.score * 1.3 then best = a end
        break
      end
    end
  end
  self.lastBest[key] = { map = best.map, x = best.x, y = best.y }
  return best.map, best.x, best.y
end
