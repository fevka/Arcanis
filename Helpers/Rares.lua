-- Arcanis: rare kaydedici (modul "Rares"). Bir rare'i hedef aldiginda, fareyle ustune geldiginde ya da isim levhasi
-- gorundugunde konumu (oyuncunun o anki yeri; levha menzili ~40 yd) ve seviyesi hesap genelinde kaydedilir. Harita
-- isaretleri (UI/MapMarkers.lua "rares") hazir veriyi (Data/Rares.lua: bilinen dogma noktalari) ve verinin disinda
-- kalan gorulen rare'leri cizer; gorulenler isaretlenir. Komut: /wf rares [bolge]
local _, ns = ...

local P = ns.Provider
local L = ns.L

local R = ns:NewModule("Rares", {
  defaults = { seen = {}, announce = true },
})
ns.RareSpawns = R

R.NEAR = 1.5          -- ayni noktada sayilan uzaklik (harita %)
R.MAX_POINTS = 12     -- harita basina en cok nokta
R.THROTTLE = 20       -- ayni rare icin en sik kayit (sn)

-- seen[npcId] = { name, lv, elite, last (sunucu saati), spots = { [uiMapID] = { { x, y }, ... } } }  (x,y 0-100)
function R:Record(info, map, x, y, now)
  if not (info and info.id and map and x and y) then return false end
  now = now or P.ServerNow() or 0
  self.lastAt = self.lastAt or {}
  local last = self.lastAt[info.id]
  local clock = P.Now()
  if last and clock - last < self.THROTTLE then return false end
  self.lastAt[info.id] = clock
  local e = self.db.seen[info.id]
  local isNew = e == nil
  if isNew then
    e = { spots = {} }
    self.db.seen[info.id] = e
  end
  e.name = info.name or e.name
  e.lv = info.level or e.lv
  e.elite = info.elite or nil
  e.last = now
  local px, py = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
  local list = e.spots[map] or {}
  e.spots[map] = list
  for _, p in ipairs(list) do
    if math.abs(p[1] - px) < self.NEAR and math.abs(p[2] - py) < self.NEAR then
      if isNew then self:Changed(e, true) end
      return isNew
    end
  end
  if #list >= self.MAX_POINTS then table.remove(list, 1) end
  list[#list + 1] = { px, py }
  self:Changed(e, isNew)
  return true
end

function R:Changed(e, isNew)
  if ns.MapMarkers then ns.MapMarkers:Invalidate(); ns.MapMarkers:RefreshAll() end
  if isNew and self.db.announce and ns.Toast then
    local lv = e.lv and (" (" .. L["Level %d"]:format(e.lv) .. ")") or ""
    ns.Toast:Show(L["Rare found: %s"]:format((e.name or "?") .. lv), "info", nil, nil, { cat = "rare" })
  end
end

function R:Check(unit)
  local info = P.UnitRare(unit)
  if not info then return end
  local map, x, y = P.PlayerMapPosition()
  if map then self:Record(info, map, x, y) end
end

-- Harita noktalari: hazir veri (Data/Rares.lua) dunya yardi { c, wx, wy } olarak; oyunda gorulup verinin disinda
-- kalan rare'ler (yeni / Forever'da degismis) harita noktasi { map, x, y (0-1) } olarak.
function R:Points()
  local out = {}
  for _, r in ipairs(ns.RareData or {}) do
    for _, p in ipairs(r.pts) do
      out[#out + 1] = { id = r.id, name = r.name, lv = r.lv, lvMax = r.lvMax, skull = r.skull, elite = r.elite, tame = r.tame,
        seen = self.db.seen[r.id] ~= nil, c = r.c, wx = p[1], wy = p[2] }
    end
  end
  local known = {}
  for _, r in ipairs(ns.RareData or {}) do known[r.id] = true end
  for id, e in pairs(self.db.seen) do
    if not known[id] then
      for map, list in pairs(e.spots or {}) do
        for _, p in ipairs(list) do
          out[#out + 1] = { id = id, name = e.name, lv = e.lv, elite = e.elite, seen = true, map = map,
            x = p[1] / 100, y = p[2] / 100 }
        end
      end
    end
  end
  return out
end

-- Bolgenin rare'leri (hazir veriden): gorulen ve gorulmeyen adlar. zone: Ingilizce bolge adi.
function R:ZoneStatus(zone)
  local seen, unseen, done = {}, {}, {}
  for _, r in ipairs(ns.RareData or {}) do
    if r.zone == zone and not done[r.id] then
      done[r.id] = true
      if self.db.seen[r.id] then seen[#seen + 1] = r.name else unseen[#unseen + 1] = r.name end
    end
  end
  table.sort(seen); table.sort(unseen)
  return seen, unseen
end

-- Gosterilen haritanin bolge adi (ZoneMaps ters eslemesi).
function R:ZoneName(map)
  if not map then return nil end
  for name, id in pairs(ns.Zones and ns.Zones.defaults or {}) do if id == map then return name end end
end

function R:OnEnable()
  ns:On("PLAYER_TARGET_CHANGED", self, function() R:Check("target") end)
  ns:On("UPDATE_MOUSEOVER_UNIT", self, function() R:Check("mouseover") end)
  ns:On("NAME_PLATE_UNIT_ADDED", self, function(_, _, unit) if unit then R:Check(unit) end end)
end

ns:RegisterCommand("rares", function(args)
  local zone = (args or ""):match("^%s*(.-)%s*$")
  if zone == "" then
    local map = P.PlayerMapPosition()
    zone = R:ZoneName(map) or ""
  end
  local seen, unseen = R:ZoneStatus(zone)
  if #seen + #unseen == 0 then ns:Print(L["No rares listed for %s."]:format(zone)) return end
  ns:Print(L["Rares in %s: %d of %d seen."]:format(zone, #seen, #seen + #unseen))
  if #unseen > 0 then ns:Print(L["Not seen yet: %s"]:format(table.concat(unseen, ", "))) end
end)
