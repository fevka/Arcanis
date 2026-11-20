-- Arcanis: kolay ama guclu esyalar (Data/EasyItems.lua). Mentor modulunun parcasi (ayri modul degil):
-- seviyene, tarafina, irkina ve sinifina uyan, henuz sahip olmadigin / gorevini bitirmedigin esyalar.
-- Mentor > Items sekmesi, "Now" onerileri (en cok 2, `Mentor.db.easyItems`) ve seviye atlayinca tek satir.
local _, ns = ...

local P = ns.Provider
local L = ns.L
local Mentor = ns.Mentor

local KIND_ORDER = { bag = 1, rest = 2, weapon = 3, wand = 3, armor = 4 }

local function listHas(list, v)
  if not list then return true end
  for _, x in ipairs(list) do if x == v then return true end end
  return false
end

-- Taraf / irk / sinif uyuyor mu?
function Mentor:EasyItemFits(e, info)
  info = info or P.PlayerInfo()
  if e.faction and info.faction and e.faction ~= info.faction then return false end
  if e.races and not listHas(e.races, info.race) then return false end
  if e.classes and not listHas(e.classes, info.class) then return false end
  return true
end

-- Canta yuvalarindan biri (1..son) bu cantadan kucuk ya da bos mu? (0 = sirt cantasi, degismez)
function Mentor:BagWouldHelp(slots)
  for bag = 1, P.LastBag() do
    if (P.ContainerSlots(bag) or 0) < slots then return true end
  end
  return false
end

-- Artik onerilmez: sahipsin (canta / takili / cantada), gorevi bitti ya da "done" isaretledin.
-- Canta ise: hicbir yuvaya buyuk gelmiyorsa da gizlenir (dondurulen ikinci deger "nobetter").
function Mentor:EasyItemDone(e)
  if self.char.easyDone[e.id] then return true, "marked" end
  if e.item and (P.ItemCount(e.item) or 0) > 0 then return true, "owned" end
  for _, q in ipairs(e.quests or {}) do
    if P.IsQuestFlaggedCompleted(q) then return true, "quest" end
  end
  if e.kind == "bag" and e.slots and not self:BagWouldHelp(e.slots) then return true, "nobetter" end
  return false
end

function Mentor:MarkEasyItem(id, value)
  self.char.easyDone[id] = value ~= false or nil
end

-- Liste: showAll = seviye araligi disindakiler ve bitenler de (taraf/irk/sinif suzgeci hep).
-- Sira: once canta, sonra dinlenme, silah, zirh; ayni turde seviye sirasi.
function Mentor:EasyItems(level, info, showAll)
  info = info or P.PlayerInfo()
  level = level or P.PlayerLevel()
  local out = {}
  for _, e in ipairs(ns.EasyItems or {}) do
    if self:EasyItemFits(e, info) then
      local inRange = level >= (e.from or 1) and level <= (e.to or 60)
      if showAll or (inRange and not self:EasyItemDone(e)) then out[#out + 1] = e end
    end
  end
  table.sort(out, function(a, b)
    local ka, kb = KIND_ORDER[a.kind] or 9, KIND_ORDER[b.kind] or 9
    if ka ~= kb then return ka < kb end
    if (a.from or 1) ~= (b.from or 1) then return (a.from or 1) < (b.from or 1) end
    return a.id < b.id
  end)
  return out
end

local KIND_TEXT = {
  bag = function(e) return L["%d-slot bag"]:format(e.slots or 0) end,
  weapon = function() return L["Weapon"] end, wand = function() return L["Wand"] end,
  armor = function() return L["Armor"] end, rest = function() return L["Rested XP item"] end,
}

-- Baslik: "Book Bag - 6-slot bag (level 1-12)"
function Mentor:EasyItemTitle(e)
  local kind = KIND_TEXT[e.kind] and KIND_TEXT[e.kind](e) or ""
  return ("%s - %s (%s)"):format(e.name or "?", kind, L["level %d-%d"]:format(e.from or 1, e.to or 60))
end

local function dungeonName(id)
  local d = ns.Journal and ns.Journal.Get and ns.Journal:Get(id)
  return d and (ns:LocalizedText(d.name) or d.id) or id
end

-- Taraf saticisi: olculebilen en yakini, yoksa ilki.
function Mentor:EasyItemVendor(e, info)
  info = info or P.PlayerInfo()
  local best, bestD, first
  for _, v in ipairs(e.vendors or {}) do
    if not (v.faction and info.faction and v.faction ~= info.faction) then
      first = first or v
      local map = ns.Zones and ns.Zones:Resolve(v.zone)
      local d = map and P.DistanceTo(map, v.x / 100, v.y / 100)
      if d and (not bestD or d < bestD) then best, bestD = v, d end
    end
  end
  return best or first
end

-- Nasil alinir: tek satir + not.
function Mentor:EasyItemLine(e)
  local how
  if e.source == "vendor" then
    local v = self:EasyItemVendor(e)
    how = v and L["Sold by %s (%s) and most general goods vendors."]:format(v.npc, v.zone)
      or L["Sold by most general goods vendors."]
  elseif e.source == "drop" then
    how = L["Drops from %s in %s."]:format(e.boss or "?", dungeonName(e.dungeon))
  elseif e.guide then
    how = L["Quest reward on a special trail. Start its guide from here."]
  elseif e.npc then
    how = L["Quest reward: %s, %s (%d, %d)"]:format(e.npc, e.zone or "?", math.floor(e.x or 0), math.floor(e.y or 0))
  elseif e.dungeon then
    how = L["Quest reward from inside %s."]:format(dungeonName(e.dungeon))
  else
    how = L["Quest reward"]
  end
  local note = e.note and ns:LocalizedText(e.note)
  return note and (how .. "\n" .. note) or how
end

-- Dugme metni (nil: gidecek yer yok)
function Mentor:EasyItemActionText(e)
  if e.guide then return L["Start the guide"] end
  if e.npc or e.dungeon or e.vendors then return L["Arrow"] end
end

-- Kaynaga git: ozel rehberi ac, zindan girisine ok, NPC'ye ok ya da en yakin saticiya ok. Doner: true/false.
function Mentor:EasyItemGo(e)
  local info = P.PlayerInfo()
  if e.guide then
    local id = e.guide[info.faction or ""]
    if id and ns.Engine and ns.Engine.OpenGuide then ns.Engine:OpenGuide(id); return true end
  end
  if e.source == "vendor" then
    local v = self:EasyItemVendor(e, info)
    if v then return self:PointAt(v.zone, v.x, v.y, v.npc) end
  end
  if e.npc and e.zone and e.x then return self:PointAt(e.zone, e.x, e.y, e.npc) end
  if e.dungeon and ns.Journal then
    local d = ns.Journal:Get(e.dungeon)
    return d and ns.Journal:PointTo(d) or false
  end
  return false
end

-- Mentor "Now" listesine en cok 2 esya (ayar `db.easyItems`, varsayilan acik).
function Mentor:EasyItemAdvice(level, info)
  local out = {}
  if self.db.easyItems == false then return out end
  for _, e in ipairs(self:EasyItems(level, info)) do
    if #out >= 2 then break end
    out[#out + 1] = { id = "easy-" .. e.id, priority = 22, icon = e.kind == "bag" and "bag" or "shield",
      title = L["Easy upgrade: %s"]:format(e.name), detail = self:EasyItemLine(e),
      actionText = self:EasyItemActionText(e), action = self:EasyItemActionText(e) and function() Mentor:EasyItemGo(e) end or nil }
  end
  return out
end

-- Seviye atlayinca: araligi bu seviyede (ya da son 2 seviyede) baslayan yeni esyalar, karakterde esya basina bir kez.
-- Doner: bildirilen sayi.
function Mentor:EasyItemAlert(level)
  if not self.db.popups or self.db.easyItems == false then return 0 end
  level = level or P.PlayerLevel()
  local names = {}
  for _, e in ipairs(self:EasyItems(level)) do
    if not self.char.easyAlerted[e.id] and (e.from or 1) >= level - 2 then
      self.char.easyAlerted[e.id] = true
      names[#names + 1] = e.name
    end
  end
  if #names == 0 then return 0 end
  local text = L["Easy items for your level: %s. See Mentor > Items."]:format(table.concat(names, ", "))
  if ns.Toast then ns.Toast:Show(L["Mentor: %s"]:format(L["Easy items for your level"]), "info", nil, nil, { prio = "low", cat = "mentor" }) end
  ns:Print("|cffdb9e33" .. L["Mentor"] .. ":|r " .. text)
  return #names
end
