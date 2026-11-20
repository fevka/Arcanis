-- Arcanis: Arcanis paketi koprusu (modul "Suite"). Kardes addon'lara (Engine, Oracle, Vault, Binder) hepsi
-- opsiyonel baglanir; yoksa ilgili ozellik sessizce kapali kalir. Tum cagrilar pcall icindedir.
--   Vault  : esya piyasa degeri (AH) -> ipucu satiri, odul secimi "Auction value"
--   Binder : Arcanis makrolari (/wf macros) -> Binder makro listesine kurulur
--   Oracle : build / yetenek onerisi (Helpers/Build.lua)
--   Engine : /arcanis konsoluna kayit (Suite.lua)
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Suite = ns:NewModule("Suite", { defaults = { showPrice = true } })
ns.Suite = Suite

local ADDONS = { "ArcanisEngine", "ArcanisOracle", "ArcanisVault", "ArcanisBinder" }

-- Kardes addon yuklu mu (global tablosuna bakar; yuklenme sirasindan bagimsiz).
function Suite:Has(name)
  return _G[name] ~= nil
end

-- Vault piyasa fiyati (bakir). Veri yok / Vault yoksa nil.
function Suite:Price(itemId)
  if not itemId then return nil end
  -- kullanicinin sectigi kaynak (TSM, Auctionator, Auctioneer, Vault, kendi tarama, paket listesi)
  if ns.Prices and ns.Prices.db then
    return (ns.Prices:Get(itemId))
  end
  local pc = _G.VaultPC
  if not pc then
    local v = _G.ArcanisVault
    if v and v.GetModule then
      local ok, mod = pcall(v.GetModule, v, "PriceCheck")
      pc = ok and mod or nil
    end
  end
  if pc and pc.GetPrice then
    local ok, price = pcall(pc.GetPrice, itemId)
    if ok and type(price) == "number" and price > 0 then return price end
  end
  -- tarama yoksa: paketle gelen varsayilan fiyatlar
  local p = ns.PriceData and ns.PriceData[itemId]
  return (p and p > 0) and p or nil
end

function Suite.FormatMoney(copper)
  copper = math.floor(copper or 0)
  local g, s, c = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
  if g > 0 then return ("%dg %ds"):format(g, s) end
  if s > 0 then return ("%ds %dc"):format(s, c) end
  return ("%dc"):format(c)
end

-- Ipucu satiri: "AH value: 1g 20s" (fiyat yoksa nil).
function Suite:PriceLine(itemId)
  if not self.db.showPrice then return nil end
  local price = self:Price(itemId)
  if not price then return nil end
  return L["AH value: %s"]:format(self.FormatMoney(price))
end

-- Binder makrolari ---------------------------------------------------------
Suite.macros = {
  WfNext = { body = "/wf next" },
  WfPrev = { body = "/wf prev" },
  WfStep = { body = "/wf step" },
}
local MACRO_ORDER = { "WfNext", "WfPrev", "WfStep" }

-- Makrolari Binder'a kaydeder ve kurar. Dondurur: kurulan adet, hata kodu ("nobinder" | "space").
function Suite:InstallMacros()
  local b = _G.ArcanisBinder
  if not (b and b.RegisterMacros and b.InstallMacro) then return 0, "nobinder" end
  pcall(b.RegisterMacros, self.macros)
  local n = 0
  for _, title in ipairs(MACRO_ORDER) do
    local ok, res = pcall(b.InstallMacro, title)
    if ok and type(res) == "number" then
      if res == -2 then return n, "space" end
      if res >= 0 then n = n + 1 end
    end
  end
  return n
end

function Suite:Status()
  local out = {}
  for _, name in ipairs(ADDONS) do out[#out + 1] = { name = name, loaded = self:Has(name) } end
  return out
end

ns:RegisterCommand("suite", function()
  for _, e in ipairs(Suite:Status()) do
    ns:Print(("%s: %s"):format(e.name, e.loaded and L["connected"] or L["not found"]))
  end
end, "Show linked Arcanis addons")

ns:RegisterCommand("macros", function()
  local n, err = Suite:InstallMacros()
  if err == "nobinder" then ns:Print(L["ArcanisBinder is not loaded."]) return end
  if err == "space" then ns:Print(L["No free macro slots."]) end
  ns:Print(L["Installed %d macros (I_WfNext, I_WfPrev, I_WfStep)."]:format(n))
end, "Install Arcanis macros via ArcanisBinder")
