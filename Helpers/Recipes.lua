-- Arcanis: tarif tarayicisi (modul "Recipes"). Meslekler sayfasinin "Recipes" sekmesi oyuncunun mesleklerinde
-- henuz ogrenilmemis tarifleri listeler: gereken beceri / renk esikleri ve kaynagi. Liste Data/Recipes.lua
-- (istemcinin SkillLineAbility / ItemEffect tablolari): tarif esyasi yoksa egitmenden, varsa esyadan ogrenilir.
-- Tarif esyasinin saticisi istemcide yok: satici penceresinde tarif esyasi gorulunce NPC, bolge ve konum hesap
-- geneline kaydedilir (db.vendors[esya][npc]); ok oraya gider. Dusuren yaratiklar kaydedilmez.
-- Bilinen tarifler: meslek penceresinden okunan urunler (Gold:Char().recipes) ya da P.KnowsSpell.
local _, ns = ...

local P = ns.Provider

local R = ns:NewModule("Recipes", { defaults = { record = true, vendors = {} } })
ns.Recipes = R

R.NEAR = 40   -- "becerine yakin" suzgeci: sari esigi beceri + bu kadar

-- tarif esyasi -> { meslek, satir }
local byItem
local function itemIndex()
  if byItem then return byItem end
  byItem = {}
  for prof, rows in pairs(ns.RecipeList or {}) do
    for _, r in ipairs(rows) do if r[6] > 0 then byItem[r[6]] = { prof, r } end end
  end
  return byItem
end
function R.ResetIndex() byItem = nil end

-- Meslegin bilinen urunleri (meslek penceresi acildikca dolar)
local function knownProducts(prof)
  local G = ns.Gold
  local c = G and G.db and G:Char()
  return c and c.recipes and c.recipes[prof] or {}
end

-- Satici kaydi: { { npc, map, x, y, zone } }
function R:Vendors(item)
  local out = {}
  for npc, v in pairs(self.db.vendors[item] or {}) do
    out[#out + 1] = { npc = npc, map = v.map, x = v.x, y = v.y, zone = v.zone }
  end
  table.sort(out, function(a, b) return a.npc < b.npc end)
  return out
end

-- Ogrenilmemis tarifler: { { spell, name, yellow, grey, req, product, item, auto, vendors } } sari esik sirasinda.
-- rank verilirse ve all degilse yalniz sari esigi rank + NEAR'a kadar olanlar.
function R:Unlearned(prof, rank, all)
  local out = {}
  local products = knownProducts(prof)
  for _, r in ipairs((ns.RecipeList or {})[prof] or {}) do
    local spell, yellow, grey, req, product, item, auto = r[1], r[2], r[3], r[4], r[5], r[6], r[7]
    local known = (product > 0 and products[product] ~= nil) or P.KnowsSpell(spell)
    if not known and (all or not rank or yellow <= rank + R.NEAR) then
      out[#out + 1] = { spell = spell, name = P.SpellName(spell) or ("#" .. spell), yellow = yellow, grey = grey,
        req = req > 0 and req or nil, product = product > 0 and product or nil, item = item > 0 and item or nil,
        auto = auto == 1, vendors = item > 0 and self:Vendors(item) or {} }
    end
  end
  return out
end

-- Satici penceresi: tarif esyalarini kaydet. Doner: kaydedilen esya sayisi.
function R:RecordMerchant()
  if not self.db.record then return 0 end
  local npc = P.NpcName()
  local map, x, y = P.PlayerMapPosition()
  if not (npc and map) then return 0 end
  local index, n = itemIndex(), 0
  for _, id in ipairs(P.MerchantItemIds()) do
    if index[id] then
      self.db.vendors[id] = self.db.vendors[id] or {}
      self.db.vendors[id][npc] = { map = map, x = x, y = y, zone = P.ZoneText() }
      n = n + 1
    end
  end
  return n
end

-- Kayitli saticiya ok
function R:PointTo(v, label)
  if ns.Nav and v and v.map then ns.Nav:SetTarget(v.map, v.x, v.y, label or v.npc, "manual") end
end

function R:OnEnable()
  ns:On("MERCHANT_SHOW", self, function(o) ns.SafeCall(o.RecordMerchant, o) end)
end
