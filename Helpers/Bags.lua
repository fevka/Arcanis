-- Arcanis: canta yardimcisi (modul "Bags"). Satilmayan, muhtemelen ise yaramaz esyalari ozetler. Komut: /wf bags
-- Hicbir sey satmaz ya da silmez; sadece bilgi verir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

-- fullHelper: canta dolunca en ucuz esyayi satma / yok etme onerisi; junk: oyuncunun kendi cop listesi (esya ID -> true),
-- satici yardimcisi (Vendor) bunlari da satar
local Bags = ns:NewModule("Bags", { defaults = { fullHelper = true, junk = {} } })
ns.Bags = Bags

local POOR, COMMON = 0, 1
local CLASS_WEAPON, CLASS_ARMOR = 2, 4

-- Dondurur: { free, grey = {count, value}, gear = {count, value, items = { {link, value} }} }
function Bags:Scan()
  local r = { free = P.FreeBagSlots(), grey = { count = 0, value = 0 }, gear = { count = 0, value = 0, items = {} } }
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local item = P.ContainerItem(bag, slot)
      if item and not item.noValue then
        local value = (P.ItemSellPrice(item.link) or 0) * (item.count or 1)
        if item.quality == POOR then
          r.grey.count = r.grey.count + 1
          r.grey.value = r.grey.value + value
        elseif item.quality == COMMON then
          local class = P.ItemClassId and P.ItemClassId(item.link)
          if class == CLASS_WEAPON or class == CLASS_ARMOR then
            r.gear.count = r.gear.count + 1
            r.gear.value = r.gear.value + value
            r.gear.items[#r.gear.items + 1] = { link = item.link, value = value }
          end
        end
      end
    end
  end
  return r
end

function Bags:Report()
  local r = self:Scan()
  ns:Print(L["Bags: %d free slots."]:format(r.free))
  ns:Print(L["Gray items: %d (worth %s)."]:format(r.grey.count, P.MoneyText(r.grey.value)))
  ns:Print(L["Plain weapons and armor: %d (worth %s) - usually safe to sell if you do not wear them."]:format(r.gear.count, P.MoneyText(r.gear.value)))
  table.sort(r.gear.items, function(a, b) return a.value > b.value end)
  for i = 1, math.min(5, #r.gear.items) do
    ns:Print(("  %s - %s"):format(r.gear.items[i].link or "?", P.MoneyText(r.gear.items[i].value)))
  end
  return r
end

ns:RegisterCommand("bags", function() Bags:Report() end, "bag summary: free slots, gray and plain gear")

-- ===== Canta dolu yardimcisi + cop listesi =====
local CLASS_CONTAINER, CLASS_QUEST = 1, 12

-- Cop listesinde mi (modul kapali olsa da liste gecerli: Vendor okur)
function Bags:IsJunk(id) return id ~= nil and self.db and self.db.junk and self.db.junk[id] == true end

-- Feda edilecek esya secimi (saf islev). items: { {bag, slot, id, link, quality, count, price, classId, noValue}, ... },
-- keep(id): gorevin istedigi esya (ItemNeeds:Keep). Asla secilmez: degersiz (hearthstone, anahtar, gorev esyasi),
-- gorev sinifi, canta, korunan esya; yalniz cop listesi, gri ya da beyaz. Once cop listesi + gri, sonra beyaz; ayni
-- grupta toplam satis degeri en dusuk olan. Dondurur: esya ya da nil.
function Bags.PickVictim(items, keep, junk)
  local best, bestRank, bestValue
  for _, it in ipairs(items) do
    local isJunk = junk and it.id and junk[it.id]
    local ok = not it.noValue and it.classId ~= CLASS_QUEST and it.classId ~= CLASS_CONTAINER
      and (isJunk or (it.quality or 9) <= COMMON) and not (keep and it.id and keep(it.id))
    if ok then
      local rank = (isJunk or it.quality == POOR) and 0 or 1
      local value = (it.price or 0) * (it.count or 1)
      if not best or rank < bestRank or (rank == bestRank and value < bestValue) then
        best, bestRank, bestValue = it, rank, value
      end
    end
  end
  if best then best.value = bestValue end
  return best
end

-- Meslek aletleri hic feda edilmez (ucuz beyaz silah olduklari icin en ucuz aday cikiyorlardi): Mentor.TOOLS
-- (kazma, bicak), ProfessionTools (cekic, rod, anahtar...) ve oltalar.
local FISHING_POLES = { 6256, 6365, 6366, 6367, 12225, 19022, 19970 }
local toolSet
function Bags.IsTool(id)
  if not toolSet then
    toolSet = {}
    for _, i in ipairs(FISHING_POLES) do toolSet[i] = true end
    for _, t in pairs(ns.Mentor and ns.Mentor.TOOLS or {}) do for _, i in ipairs(t.ids or {}) do toolSet[i] = true end end
    for _, list in pairs(ns.ProfessionTools or {}) do for _, t in ipairs(list) do toolSet[t.item] = true end end
  end
  return toolSet[id] == true
end

function Bags:Victim()
  local items = {}
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local it = P.ContainerItem(bag, slot)
      if it and it.link then
        it.bag, it.slot = bag, slot
        it.id = it.id or P.ItemIdFromLink(it.link)
        it.price = P.ItemSellPrice(it.link) or 0
        it.classId = P.ItemClassId(it.link)
        items[#items + 1] = it
      end
    end
  end
  local IN = ns.ItemNeeds
  return Bags.PickVictim(items, function(id) return Bags.IsTool(id) or (IN and IN:Keep(id)) end, self.db.junk)
end

-- Canta doldu (ya da ganimet sigmadi): en ucuz esyayi adada oner. Saticidaysa tikla = sat; degilse tikla = oyunun
-- onay penceresi, "Destroy" ile yok edilir. Kendiliginden hicbir sey silinmez.
local OFFER_GAP = 10
function Bags:Offer()
  if not self.db.fullHelper or P.InCombat() or (self.offeredAt and P.Now() - self.offeredAt < OFFER_GAP) then return end
  local v = self:Victim()
  if not v then return end
  self.offeredAt = P.Now()
  local worth = P.MoneyText(v.value or 0)
  local title, body
  if self.atMerchant then
    title, body = L["Bags full: sell %s?"]:format(v.link), L["Worth %s. Click to sell it."]:format(worth)
  else
    title, body = L["Bags full: destroy %s?"]:format(v.link), L["Worth %s. Click, then confirm to destroy it."]:format(worth)
  end
  ns.Toast:Show(title, "warn", body, function() Bags:Act(v) end, { cat = "warn", key = "bagsfull" })
end

function Bags:Act(v)
  local cur = P.ContainerItem(v.bag, v.slot)
  if not (cur and cur.link == v.link) then return false end   -- esya yer degistirdi: eski oneri gecersiz
  if self.atMerchant then P.UseContainerItem(v.bag, v.slot) return true end
  return P.Confirm(L["Destroy %s? This cannot be undone."]:format(v.link), function()
    if P.DestroyBagItem(v.bag, v.slot, v.link) then ns:Print(L["Destroyed %s."]:format(v.link)) end
  end, L["Destroy"])
end

-- Ganimet / esya alinamadi: oyunun "canta dolu" hatalari
local FULL_ERRORS = { "ERR_INV_FULL", "ERR_BAG_FULL", "ERR_LOOT_NO_SPACE" }
function Bags:OnError(_, _, msg)
  for _, name in ipairs(FULL_ERRORS) do
    if msg and msg == P.GlobalText(name) then return self:Offer() end
  end
end

function Bags:OnEnable()
  ns:On("UI_ERROR_MESSAGE", self, "OnError")
  ns:On("BAG_UPDATE_DELAYED", self, function(o)
    local free = P.FreeBagSlots()
    if free == 0 and not o.wasFull then o:Offer() end
    o.wasFull = free == 0
  end)
  ns:On("MERCHANT_SHOW", self, function(o) o.atMerchant = true end)
  ns:On("MERCHANT_CLOSED", self, function(o) o.atMerchant = false end)
end

-- /wf junk [esya baglantisi | clear]: cop listesine ekle / cikar, temizle ya da listele
function Bags:ToggleJunk(id)
  if not id then return nil end
  self.db.junk[id] = (not self.db.junk[id]) or nil
  return self.db.junk[id] == true
end

ns:RegisterCommand("junk", function(args)
  args = args or ""
  if args:lower():match("^%s*clear") then
    Bags.db.junk = {}
    ns:Print(L["Junk list cleared."])
    return
  end
  local id = tonumber(args:match("item:(%d+)") or args:match("^%s*(%d+)%s*$"))
  if id then
    local on = Bags:ToggleJunk(id)
    ns:Print((on and L["Added to your junk list: %s"] or L["Removed from your junk list: %s"]):format(P.ItemName(id) or ("#" .. id)))
    return
  end
  local n = 0
  for jid in pairs(Bags.db.junk) do n = n + 1; ns:Print("  " .. (P.ItemName(jid) or ("#" .. jid))) end
  ns:Print(L["Junk list: %d items. Shift-click an item after /wf junk to add or remove it."]:format(n))
end, "[item | clear] your junk list, sold with the gray items")
