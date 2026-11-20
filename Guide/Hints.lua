-- Arcanis: quest ipuclari. Veri kategori kodudur (Data/Brain/QuestHints.lua); metin Locales'ten.
-- a = quest'i veren NPC, t = teslim NPC'si, o[hedef] = hedef.
--   Hints:Text(q, kind, obj) -> "Upstairs in the building  ·  Moves around: check nearby" ya da nil
--   Hints:For(step)          -> adimin turune gore ayni metin
local _, ns = ...

local L = ns.L

local Hints = {}
ns.Hints = Hints

local PHRASE = {
  building = "Inside the building", upstairs = "Upstairs in the building", downstairs = "Downstairs in the building",
  tent = "Inside the tent", cave = "In the cave", mine = "In the mine", crypt = "In the crypt",
  mountain = "On top of the mountain", underwater = "Underwater", wander = "Moves around: check nearby",
  elite = "Elite: bring help", group = "Needs a group", escort = "Escort: stay close",
  respawn = "Not there? Wait for the respawn", stealth = "Watch for stealthed enemies",
  sharedtag = "Shared tag: any kill counts", multiple = "Several spots",
  outside = "Just outside the building", cliff = "Up on the cliff", ambush = "Ambush: expect an attack",
}

-- Tek kod -> yerellestirilmis kisa cumle (bilinmeyen kod gosterilmez).
function Hints.Phrase(code)
  if type(code) ~= "string" then return nil end
  local key, arg = code:match("^(%a+):(.+)$")
  if key == "elite" then return L["Elite (level %s): bring help"]:format(arg) end
  if key == "place" then return L["Inside %s"]:format(arg) end
  return PHRASE[code] and L[PHRASE[code]] or nil
end

function Hints:Text(q, kind, obj)
  local h = q and ns.BrainData and ns.BrainData.hints and ns.BrainData.hints[q]
  -- hedef ipucu yoksa h.o (hedef tablosu) kod listesi sanilmasin
  local codes = h and (kind == "o" and (h.o and h.o[obj or 1]) or (kind ~= "o" and h[kind]) or nil)
  if not codes then return nil end
  local out = {}
  for _, c in ipairs(codes) do
    local p = Hints.Phrase(c)
    if p then out[#out + 1] = p end
  end
  if #out > 0 then return table.concat(out, "  ·  ") end
end

local KIND = { accept = "a", turnin = "t", complete = "o", kill = "o", collect = "o", use = "o" }
function Hints:For(step)
  local kind = step and KIND[step.type]
  return kind and self:Text(step.quest, kind, step.objective)
end
