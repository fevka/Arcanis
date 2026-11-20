-- Arcanis: sinif Codex'i (modul "Codex"): sinif build verisi (Data/Codex/*.lua), Talents sayfasi kullanir.
--   ns.Codex:RegisterBuild(sinif, kategori, ad, agac1, agac2, agac3, veri)
--   ns.Codex:Get(sinif, kategori) -> { build, ... }      kategori: "Leveling" | "PVE" | "PVP"
local _, ns = ...

-- enchants: Character sayfasinda buyu onerileri; repRecord / repItems: Helpers/RepRewards.lua (itibar saticilari)
local Codex = ns:NewModule("Codex", { defaults = { enchants = true, repRecord = true, repItems = {} } })
ns.Codex = Codex
Codex.builds = {}

local CATEGORIES = { Leveling = true, PVE = true, PVP = true }

function Codex:RegisterBuild(class, category, shortname, tree1, tree2, tree3, data)
  if type(class) ~= "string" or not CATEGORIES[category] or type(data) ~= "table" then return end
  class = class:upper()
  self.builds[class] = self.builds[class] or {}
  self.builds[class][category] = self.builds[class][category] or {}
  data.shortname, data.tree1, data.tree2, data.tree3 = shortname, tree1, tree2, tree3
  for _, key in ipairs({ "DESC", "PROS", "CONS", "ROT" }) do
    if type(data[key]) == "string" then data[key] = data[key]:gsub("\t", "   ") end
  end
  table.insert(self.builds[class][category], data)
  return data
end

-- Forever leveling yetenek siralari (Data/TalentOrders.lua): ayni ana agactaki bizim leveling build'imizin TALENTS'i
-- puan puan siraya doner (PERPOINT; aciklama / rotasyon bizim kalir); eslesmeyen uzmanlik yeni leveling build'i olur.
local function mainTree(a, b, c)
  if a >= b and a >= c then return 1 elseif b >= c then return 2 end
  return 3
end

function Codex:ApplyOrders(orders)
  for class, list in pairs(orders or {}) do
    local mine = self:Get(class, "Leveling")
    local used = {}
    for _, b in ipairs(mine) do
      local tree = mainTree(b.tree1 or 0, b.tree2 or 0, b.tree3 or 0)
      for i, o in ipairs(list) do
        if not used[i] and mainTree(o.trees[1], o.trees[2], o.trees[3]) == tree then
          used[i] = true
          b.TALENTS, b.PERPOINT = o.order, true
          b.tree1, b.tree2, b.tree3 = o.trees[1], o.trees[2], o.trees[3]
          break
        end
      end
    end
    for i, o in ipairs(list) do
      if not used[i] then
        self:RegisterBuild(class, "Leveling", o.spec .. " Leveling", o.trees[1], o.trees[2], o.trees[3], {
          TALENTS = o.order, PERPOINT = true,
          DESC = ("%s leveling on the Forever talent tree, one point at a time from level 10."):format(o.spec),
        })
      end
    end
  end
end

function Codex:Get(class, category)
  local c = class and self.builds[class:upper()]
  return (c and c[category]) or {}
end
