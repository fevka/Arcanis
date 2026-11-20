-- Arcanis: bolge adi -> uiMapID eslemesi (ns.Zones).
-- Rehber adimlari konumu "zone" (Ingilizce bolge adi) + x,y olarak tasiyabilir; bu katman
-- adimi harita ID'sine cevirir. Eslemeler iki yerden gelir:
--   Data/ZoneMaps.lua  varsayilanlar (kod ile gelir)
--   /wf zonemap        oyuncunun oyun icinde duzelttigi/eklediği eslemeler (ArcanisCoreDB.zoneMaps)
-- Esleme bilinmiyorsa adimin konumu yoktur: ok gosterilmez, adim elle ilerletilir.
local _, ns = ...

local P = ns.Provider

local Zones = { defaults = {} }
ns.Zones = Zones

function Zones:SetDefaults(map)
  for zone, id in pairs(map) do self.defaults[zone] = id end
end

-- Oyundaki bolge haritalari: ad -> uiMapID (bir kez taranir). Istemci hangi ID'leri kullaniyorsa
-- onu bulur; yalniz istemci dilindeki ad rehberdeki Ingilizce adla eslesirse ise yarar.
local MAX_MAP_ID = 2500
function Zones:ScanNames()
  if self.byName then return self.byName end
  local names = {}
  local zoneType = P.ZoneMapType()
  for id = 1, MAX_MAP_ID do
    local info = P.MapInfo(id)
    -- ayni adli haritalardan en yuksek ID kullanilir (Classic haritalari 14xx)
    if info and info.name and info.mapType == zoneType then
      names[info.name] = id
    end
  end
  self.byName = names
  return names
end

function Zones:Resolve(zone)
  local user = ns.db and ns.db.zoneMaps
  if user and user[zone] then return user[zone] end
  return self:ScanNames()[zone] or self.defaults[zone]
end

-- Adimin konumu: map, x, y (x,y 0-1) ya da konum yoksa/cozulemiyorsa nil.
function Zones:Location(step)
  -- hedef: Forever verisindeki en iyi canavar/obje alani (yogunluk + yakinlik, harita isaretiyle dogrulanir)
  local map = step.x ~= nil and (step.map or (step.zone and self:Resolve(step.zone))) or nil
  -- hedefsiz yolculuk quest'i: oyunun isareti teslimi (baska kita) gosterir, adim iskeleye gider
  if map and ns.Engine and ns.Engine.TravelObjective and ns.Engine:TravelObjective(step) then return map, step.x, step.y end
  -- meslek toplama adimi: seviyeye uyan toplama alani (Guide/ProfGuides.lua PG.GatherSpot)
  if step.type == "prof" and step.act == "gather" and ns.ProfGuides and ns.ProfGuides.GatherSpot then
    local spot = ns.ProfGuides.GatherSpot(step)
    if spot and spot.moved then
      local m = self:Resolve(spot.zone)
      if m then return m, spot.x, spot.y end
    end
  end
  -- eskort / "getir-goturu" basladi (Engine:NoteEscort): alan verisi NPC'nin dogdugu yeri gosterir; artik
  -- varis yeri gerekir = adimin kendi koordinati (yoksa asagida oyunun isareti / teslim)
  local escort = step.type == "complete" and step.quest and ns.Engine and ns.Engine.EscortActive
    and ns.Engine:EscortActive(step.quest)
  if escort and map then return map, step.x, step.y end
  if step.type == "complete" and step.quest and ns.Areas and not escort then
    local m, x, y = ns.Areas:Best(step)
    if m then return m, x, y end
  end
  -- NPC'nin oyunda ogrenilmis gercek yeri (Engine:LearnNpc) rehber koordinatindan ve oyunun isaretinden once
  local NPC_STEP = step.type == "accept" or step.type == "turnin" or step.type == "talk"
  local spot = NPC_STEP and step.npc and ns.Engine and ns.Engine.NpcSpot and ns.Engine:NpcSpot(step.npc)
  -- ayni NPC rotada baska yerlerde de durur (Valennia Stormfist: Valanaar, sonra Shrine of Akir): ogrenilen yer
  -- yalniz rehber noktasina yakinsa bu adimin yeridir; uzaksa NPC tasinmistir, rehber noktasi gecerli
  if spot then
    local d = map and P.PointDistance(spot[1], spot[2], spot[3], map, step.x, step.y)
    if not map or (d and d <= Zones.SPOT_TRUST) then return spot[1], spot[2], spot[3] end
  end
  -- hedef / teslim: oyunun harita isareti (quest gunlukteyse). Teslimde isaret bolgenin ortasini gosterebilir
  -- ("su kisiyle konus" gorevleri): rehberdeki NPC noktasi isarete yakinsa NPC'nin kendisi hedeflenir.
  -- cok hedefli quest'te oyunun tek isareti hedefi degil quest'i gosterir (A Last Request: not bitince isaret
  -- hala notun yerinde): belirli bir hedefin adimi kendi koordinatina gider
  if step.type == "complete" and step.objective and map then
    local objs = P.GetObjectives and P.GetObjectives(step.quest)
    if objs and #objs > 1 then return map, step.x, step.y end
  end
  if (step.type == "complete" or step.type == "turnin") and step.quest and P.QuestMapPos then
    local m, x, y, alt = P.QuestMapPos(step.quest)
    -- isaretin cercevesi belirsiz (P.QuestMapPos): ikinci okuma rehber noktasina daha yakinsa o dogrudur
    if m and alt and map then
      local d1 = P.PointDistance(map, step.x, step.y, m, x, y)
      local d2 = P.PointDistance(map, step.x, step.y, alt, x, y)
      if d2 and (not d1 or d2 < d1) then m = alt end
    end
    if m then
      if step.type == "turnin" and step.npc and map then
        local d = P.PointDistance(map, step.x, step.y, m, x, y)
        if d and d <= Zones.NPC_TRUST then return map, step.x, step.y end
      end
      return m, x, y
    end
  end
  if not map then return nil end
  return map, step.x, step.y
end
-- yd: rehberdeki teslim NPC'si oyunun isaretine bu kadar yakinsa NPC noktasi kullanilir. 150 idi; referans rotalarin
-- NPC koordinati onlarca yard sapabiliyor (Skyborne: Missionary Jasaan, Constable Aonda) ve teslim isareti NPC'nin
-- kendisini gosteriyor. Yalniz cok kucuk farkta rehber noktasi (daha kesin olabilir) secilir.
Zones.NPC_TRUST = 25
Zones.SPOT_TRUST = 150   -- yd: ogrenilen NPC yeri rehber noktasina bu kadar yakinsa kullanilir (sapma onlarca yard)

-- Yuklu rehberlerde gecen bolgeler: { [zone] = adimSayisi }.
function Zones:Used()
  local used = {}
  for _, id in ipairs(ns.Guides.order) do
    for _, step in ipairs(ns.Guides.byId[id].steps) do
      if step.zone and step.x ~= nil and not step.map then
        used[step.zone] = (used[step.zone] or 0) + 1
      end
    end
  end
  return used
end

local function mapName(id)
  local info = P.MapInfo(id)
  return info and info.name or nil
end

-- /wf zonemap                    kullanilan bolgeleri ve durumlarini listeler
-- /wf zonemap <bolge>            bulundugun haritayi bu bolgeye atar
-- /wf zonemap <bolge> <mapID>    verilen haritayi atar
-- /wf zonemap <bolge> clear      kendi eslemeni siler (varsayilana doner)
ns:RegisterCommand("zonemap", function(args)
  args = (args or ""):match("^%s*(.-)%s*$")
  local used = Zones:Used()

  if args == "" then
    local zones = {}
    for zone in pairs(used) do zones[#zones + 1] = zone end
    table.sort(zones, function(a, b)
      local ra, rb = Zones:Resolve(a) ~= nil, Zones:Resolve(b) ~= nil
      if ra ~= rb then return not ra end   -- cozulmemisler once
      return a < b
    end)
    ns:Print("Zones used by loaded guides (steps / map):")
    for _, zone in ipairs(zones) do
      local id = Zones:Resolve(zone)
      local label
      if id then
        local custom = ns.db.zoneMaps and ns.db.zoneMaps[zone]
        label = ("%d%s%s"):format(id, mapName(id) and (" (" .. mapName(id) .. ")") or "", custom and " [yours]" or "")
      else
        label = "|cffff4040unresolved|r"
      end
      print(("  %-28s %5d   %s"):format(zone, used[zone], label))
    end
    print("  Stand in the zone and type |cffffff00/wf zonemap <zone name>|r to assign it.")
    return
  end

  local name, rest = args, nil
  local head, tail = args:match("^(.-)%s+(%S+)$")
  if head and (tail == "clear" or tonumber(tail)) then name, rest = head, tail end

  local zone
  for candidate in pairs(used) do
    if candidate:lower() == name:lower() then zone = candidate end
  end
  if not zone then
    ns:Print(("Unknown zone '%s'. Type /wf zonemap to list the zones."):format(name))
    return
  end

  ns.db.zoneMaps = ns.db.zoneMaps or {}
  if rest == "clear" then
    ns.db.zoneMaps[zone] = nil
    ns:Print(("%s: reset to default."):format(zone))
  else
    local id = tonumber(rest)
    if not id then
      id = P.PlayerMapPosition()
      if not id then
        ns:Print("Could not read your map position (indoors or no map data).")
        return
      end
    end
    ns.db.zoneMaps[zone] = id
    ns:Print(("%s -> map %d%s"):format(zone, id, mapName(id) and (" (" .. mapName(id) .. ")") or ""))
  end
  if ns.Engine then ns.Engine:MarkDirty() end
  if ns.Nav and ns.Engine and ns.Engine:GetStep() then ns.Nav:OnStepChanged(nil, nil, nil, ns.Engine:GetStep()) end
end, "[zone] [mapID|clear] list or assign zone maps")
