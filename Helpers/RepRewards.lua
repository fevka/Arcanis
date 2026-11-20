-- Arcanis: itibar odulleri, oyunda kaydedilir (modul "Codex"; ayar Codex.db.repRecord). Istemcide itibar odulu
-- tablosu yok (Faction / FactionTemplate yalniz taraf yapisi), bu yuzden satici penceresi acilinca itibar isteyen
-- esyalar oyunun ipucundan okunur (P.MerchantRepItems) ve hesap geneli Codex.db.repItems[taraf][esya] = { seviye,
-- satici, bolge, fiyat } olarak yazilir. Liste Class Codex > Character "Reputation rewards" gruplarinda.
local _, ns = ...

local P = ns.Provider
local Codex = ns.Codex
local RR = {}
ns.RepRewards = RR

-- Acik saticidan kaydet; dondurur: yeni kaydedilen esya sayisi.
function RR:Record()
  local db = Codex and Codex.db
  if not (db and db.repRecord ~= false and Codex:IsEnabled()) then return 0 end
  db.repItems = db.repItems or {}
  local vendor, zone, n = P.NpcName(), P.ZoneText(), 0
  for _, it in ipairs(P.MerchantRepItems()) do
    local list = db.repItems[it.faction] or {}
    db.repItems[it.faction] = list
    if not list[it.id] then n = n + 1 end
    list[it.id] = { standing = it.standing, vendor = vendor, zone = zone, price = it.price }
  end
  return n
end

-- Taraflar ve esyalari: { { faction, items = { { id, standing, vendor, zone, price } } } } (ada gore).
function RR:List()
  local out = {}
  for fac, items in pairs(Codex and Codex.db and Codex.db.repItems or {}) do
    local e = { faction = fac, items = {} }
    for id, it in pairs(items) do
      e.items[#e.items + 1] = { id = id, standing = it.standing, vendor = it.vendor, zone = it.zone, price = it.price }
    end
    table.sort(e.items, function(a, b) return a.id < b.id end)
    if #e.items > 0 then out[#out + 1] = e end
  end
  table.sort(out, function(a, b) return a.faction < b.faction end)
  return out
end

-- satici listesi acildiktan sonra ipucu verisi hazir olsun diye kisa gecikme
ns:On("MERCHANT_SHOW", "RepRewards", function() P.After(0.3, function() ns.SafeCall(RR.Record, RR) end) end)
