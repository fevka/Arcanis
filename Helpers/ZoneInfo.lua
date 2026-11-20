-- Arcanis: bolge bilgisi (modul "ZoneInfo"). Veri: Data/ZoneInfo.lua (seviye, bitki/maden, zindanlar).
-- Bolgeye girince seviyeni, bolgedeki seni ilgilendiren zindani ve toplanabilir malzemeyi hatirlatir. Komut: /wf zoneinfo [bolge]
local _, ns = ...

local P = ns.Provider
local L = ns.L

local ZoneInfo = ns:NewModule("ZoneInfo", { defaults = { toast = true } })
ns.ZoneInfo = ZoneInfo

function ZoneInfo:Get(zone)
  if not zone then return nil end
  local data = ns.ZoneInfoData and ns.ZoneInfoData[zone]
  if data then return data, zone end
  zone = zone:lower()
  for name, d in pairs(ns.ZoneInfoData or {}) do
    if name:lower() == zone or name:lower():find(zone, 1, true) then return d, name end
  end
end

local function names(list, skillTable, skill)
  local out = {}
  for _, n in ipairs(list) do
    local need = skillTable and skillTable[n]
    local text = need and ("%s (%d)"):format(n, need) or n
    if need and skill and skill < need then text = "|cff888888" .. text .. "|r" end
    out[#out + 1] = text
  end
  return table.concat(out, ", ")
end

-- Bolge icin gosterilecek satirlar (oyuncunun toplama becerisine gore soluk/normal).
function ZoneInfo:Lines(zone, player)
  local d, name = self:Get(zone)
  if not d then return nil end
  local lines = { L["%s - level %d-%d"]:format(name, d.min, d.max) }
  local herb, mine = P.GatherSkill and P.GatherSkill() or nil, nil
  if type(herb) == "table" then herb, mine = herb.herbs, herb.ore end
  if #d.herbs > 0 then lines[#lines + 1] = L["Herbs: %s"]:format(names(d.herbs, ns.GatherSkill and ns.GatherSkill.herbs, herb)) end
  if #d.ore > 0 then lines[#lines + 1] = L["Ore: %s"]:format(names(d.ore, ns.GatherSkill and ns.GatherSkill.ore, mine)) end
  local J = ns.Journal
  for _, e in ipairs(d.dungeons) do
    local dungeon = J and J:Get(e.id)
    lines[#lines + 1] = L["Dungeon: %s (%d-%d)"]:format(dungeon and dungeon.name or e.id, e.min, e.max)
  end
  return lines
end

-- Bolgedeki, oyuncunun seviyesine uyan (ya da 3 seviye icinde) zindanlar.
function ZoneInfo:DungeonsFor(zone, level)
  local d = self:Get(zone)
  local out = {}
  if not d then return out end
  for _, e in ipairs(d.dungeons) do
    if level >= e.min - 3 and level <= e.max then out[#out + 1] = e end
  end
  return out
end

function ZoneInfo:OnZone()
  if not self.db.toast or not ns.Toast then return end
  local zone = P.ZoneText()
  local d, name = self:Get(zone)
  if not d then return end
  local level = P.PlayerLevel()
  local J = ns.Journal
  for _, e in ipairs(self:DungeonsFor(name, level)) do
    local dungeon = J and J:Get(e.id)
    if dungeon then
      ns.Toast:Show(L["%s is here (%d-%d)."]:format(dungeon.name, e.min, e.max), "info", nil, nil, { prio = "low", cat = "dungeon" })
    end
  end
end

function ZoneInfo:OnEnable()
  ns:On("ZONE_CHANGED_NEW_AREA", self, "OnZone")
end

ns:RegisterCommand("zoneinfo", function(args)
  local zone = (args and args:match("%S") and args) or P.ZoneText()
  local lines = ZoneInfo:Lines(zone)
  if not lines then ns:Print(L["No info for this zone."]) return end
  for _, line in ipairs(lines) do ns:Print(line) end
end, "[zone] zone level, gathering and dungeons")
