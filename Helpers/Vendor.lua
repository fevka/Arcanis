-- Arcanis: satici yardimcisi (modul "Vendor"): gri esyalari ve cop listesini sat, otomatik onar.
-- Satici acilinca calisir. Shift basili tutulursa atlanir. Varsayilan: kapali.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Vendor = ns:NewModule("Vendor", {
  defaults = { sellGrey = false, sellJunk = true, repair = false, guildRepair = false, report = true },
})
ns.Vendor = Vendor

local POOR = 0

-- Gri (dusuk kalite) esyalari ve oyuncunun cop listesini (Bags.db.junk, /wf junk) satar; noGrey / noJunk birini atlar.
-- Dondurur: satilan adet, kazanc (bakir).
function Vendor:SellGrey(noGrey, noJunk)
  local count, earned = 0, 0
  local B = ns.Bags
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local item = P.ContainerItem(bag, slot)
      local id = item and (item.id or P.ItemIdFromLink(item.link))
      local want = item and ((item.quality == POOR and not noGrey) or (not noJunk and B and B:IsJunk(id)))
      -- hala bir goreve yarayan esya satilmaz (Gorev Beyni: ItemNeeds); pahali kontrol yalniz satilacak esyada
      if want and not item.noValue and not (ns.ItemNeeds and ns.ItemNeeds:Keep(id)) then
        earned = earned + (P.ItemSellPrice(item.link) or 0) * (item.count or 1)
        count = count + 1
        P.UseContainerItem(bag, slot)
      end
    end
  end
  return count, earned
end

function Vendor:Repair()
  local cost, can = P.RepairCost()
  if not cost or cost <= 0 then return 0 end
  if not can then return 0 end
  -- lonca tamiri yalniz gercekten mumkunse (loncasiz / lonca bankasi bos: kendi parasiyla odenir)
  local guild = self.db.guildRepair and P.CanGuildRepair()
  -- lonca bankasi bu tamiri karsilamiyorsa (cekme siniri / bakiye) kendi parasiyla
  local allowance = guild and P.GuildRepairAllowance and P.GuildRepairAllowance()
  if guild and allowance and allowance < cost then guild = false end
  if P.Money() < cost and not guild then
    ns:Print(L["Not enough gold to repair (%s)."]:format(P.MoneyText(cost)))
    return 0
  end
  P.RepairAll(guild)
  return cost
end

function Vendor:OnMerchant()
  if P.IsShiftDown() then return end
  if self.db.sellGrey or self.db.sellJunk then
    local count, earned = self:SellGrey(not self.db.sellGrey, not self.db.sellJunk)
    if count > 0 and self.db.report then
      ns:Print(L["Sold %d junk items for %s."]:format(count, P.MoneyText(earned)))
    end
  end
  if self.db.repair then
    local cost = self:Repair()
    if cost > 0 and self.db.report then
      ns:Print(L["Repaired for %s."]:format(P.MoneyText(cost)))
    end
  end
end

function Vendor:OnEnable()
  ns:On("MERCHANT_SHOW", self, "OnMerchant")
end
