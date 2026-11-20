-- Arcanis: acik artirma fiyatlari (modul "Prices").
-- Fiyat kaynagi kullanici secimidir (Ayarlar > Helpers > Auction prices):
--   auto         asagidaki sirayla ilk bulunan
--   tsm          TradeSkillMaster (TSM_API, secilebilir fiyat: DBMarket, DBMinBuyout, DBRegionMarketAvg...)
--   auctionator  Auctionator (Auctionator.API.v1)
--   auctioneer   Auctioneer (AucAdvanced.API)
--   vault        harici tarama verisi
--   scan         Arcanis Path'in kendi AH taramasi (acik artirmada "Scan" ile)
--   bundled      paketle gelen sabit liste (tarama yok)
-- Kendi tarama: tek seferde tum ilanlar (modern C_AuctionHouse.ReplicateItems ya da eski QueryAuctionItems getAll),
-- parca parca islenir (oyun donmaz). Tam tarama 15 dakikada bir; arada (ya da sunucu 15 sn cevap vermezse)
-- bos aramayla sayfa sayfa gezinme taramasi (esya basina en dusuk fiyat + adet). Durum ve ilerleme cubugu
-- tarama dugmelerinde (Prices:AddScanButton). Her esya icin gunluk en dusuk birim fiyat saklanir; piyasa degeri son
-- gunlerin medyanidir. Veri hesap genelinde, sunucu-taraf basina tutulur.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Prices = ns:NewModule("Prices", {
  defaults = { source = "auto", tsmKey = "DBMarket", tooltip = true, scans = {} },
})
ns.Prices = Prices

local HISTORY_DAYS = 14
local PRUNE_AFTER = 90 * 86400   -- 90 gundur ilani gorulmeyen esya
local CHUNK = 400

local function realmKey()
  local realm = GetRealmName and GetRealmName() or "?"
  local faction = UnitFactionGroup and UnitFactionGroup("player") or "?"
  return realm .. "-" .. faction
end

local function today() return date and date("%Y-%m-%d") or "today" end

function Prices:Store()
  local k = realmKey()
  local s = self.db.scans[k]
  if not s then s = { items = {}, last = nil }; self.db.scans[k] = s end
  return s
end

local function median(list)
  local t = {}
  for _, v in ipairs(list) do t[#t + 1] = v end
  table.sort(t)
  local n = #t
  if n == 0 then return nil end
  if n % 2 == 1 then return t[(n + 1) / 2] end
  return math.floor((t[n / 2] + t[n / 2 + 1]) / 2)
end

-- Kendi tarama: { min = son taramadaki en dusuk birim, market = gunluk en dusuklerin medyani, qty = toplam adet,
-- n = ilan sayisi, atMin = en dusuk fiyattaki ilan sayisi, t = tarama zamani, days, seen, hist = { {gun, min} } }
function Prices:ScanInfo(id)
  local e = self:Store().items[id]
  if not e then return nil end
  local mins = {}
  for _, h in ipairs(e.h or {}) do mins[#mins + 1] = h[2] end
  return { min = e.min, qty = e.qty, market = median(mins) or e.min, days = #mins, seen = e.day,
           n = e.n, atMin = e.atMin, t = e.t, hist = e.h or {} }
end

-- Fiyatin yasi (saniye) ya da nil: kendi taramada tarama zamani; Auctionator gun cinsinden verir.
function Prices:Age(id, source)
  if source == "scan" then
    local e = self:Store().items[id]
    local now = time and time()
    if not (e and now) then return nil end
    local t = e.t
    if not t and type(e.day) == "string" then   -- eski kayit: yalniz gun (YYYY-MM-DD) var, gun ortasi sayilir
      local y, m, d = e.day:match("^(%d+)-(%d+)-(%d+)$")
      if y then t = time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }) end
    end
    return t and math.max(0, now - t) or nil
  end
  if source == "auctionator" then
    local A = _G.Auctionator
    local fn = A and A.API and A.API.v1 and A.API.v1.GetAuctionAgeByItemID
    if fn then
      local ok, days = pcall(fn, "ArcanisPath", id)
      if ok and type(days) == "number" then return days * 86400 end
    end
  end
  return nil
end

-- Saglayicilar
local function itemString(id) return "i:" .. tostring(id) end

Prices.PROVIDERS = {
  {
    id = "tsm", name = "TradeSkillMaster",
    available = function() return _G.TSM_API and _G.TSM_API.GetCustomPriceValue ~= nil end,
    get = function(id)
      local ok, v = pcall(_G.TSM_API.GetCustomPriceValue, Prices.db.tsmKey or "DBMarket", itemString(id))
      return ok and v or nil
    end,
  },
  {
    id = "auctionator", name = "Auctionator",
    available = function()
      local A = _G.Auctionator
      return A and A.API and A.API.v1 and A.API.v1.GetAuctionPriceByItemID ~= nil
    end,
    get = function(id)
      local ok, v = pcall(_G.Auctionator.API.v1.GetAuctionPriceByItemID, "ArcanisPath", id)
      return ok and v or nil
    end,
  },
  {
    id = "auctioneer", name = "Auctioneer",
    available = function() return _G.AucAdvanced and _G.AucAdvanced.API and _G.AucAdvanced.API.GetMarketValue ~= nil end,
    get = function(id, link)
      local ok, v = pcall(_G.AucAdvanced.API.GetMarketValue, link or ("item:" .. id))
      return ok and v or nil
    end,
  },
  {
    id = "vault", name = "ArcanisVault",
    available = function() return _G.VaultPC ~= nil or (_G.ArcanisVault ~= nil and _G.ArcanisVault.GetModule ~= nil) end,
    get = function(id)
      local pc = _G.VaultPC
      if not pc and _G.ArcanisVault and _G.ArcanisVault.GetModule then
        local ok, mod = pcall(_G.ArcanisVault.GetModule, _G.ArcanisVault, "PriceCheck")
        pc = ok and mod or nil
      end
      if not (pc and pc.GetPrice) then return nil end
      local ok, v = pcall(pc.GetPrice, id)
      return ok and v or nil
    end,
  },
  {
    id = "scan", name = "Arcanis scan",
    available = function() return next(Prices:Store().items) ~= nil end,
    get = function(id)
      local i = Prices:ScanInfo(id)
      return i and i.market or nil
    end,
  },
  {
    id = "bundled", name = "Bundled list",
    available = function() return ns.PriceData ~= nil end,
    get = function(id) return ns.PriceData and ns.PriceData[id] end,
  },
}

function Prices:Provider(id)
  for _, p in ipairs(self.PROVIDERS) do if p.id == id then return p end end
end

-- Fiyat (bakir) ve kaynak kimligi. Secili kaynakta deger yoksa otomatik sira denenir.
function Prices:Get(id, link)
  if not id then return nil end
  local function try(p)
    if not p or not p.available() then return nil end
    local v = p.get(id, link)
    if type(v) == "number" and v > 0 then return math.floor(v) end
  end
  local src = self.db and self.db.source or "auto"
  if src ~= "auto" then
    local v = try(self:Provider(src))
    if v then return v, src end
  end
  for _, p in ipairs(self.PROVIDERS) do
    local v = try(p)
    if v then return v, p.id end
  end
  return nil
end

function Prices:SourceName(id)
  local p = self:Provider(id or "")
  if not p then return L["Auto"] end
  return p.id == "scan" and L["Arcanis scan"] or p.id == "bundled" and L["Bundled list"] or p.name
end

-- Etkin kaynak (otomatikte ilk kullanilabilir).
function Prices:ActiveSource()
  local src = self.db.source or "auto"
  if src ~= "auto" then
    local p = self:Provider(src)
    if p and p.available() then return src end
  end
  for _, p in ipairs(self.PROVIDERS) do if p.available() then return p.id end end
  return nil
end

-- Flip firsatlari kendi taramadan: bugunku en dusuk, medyanin %60'inin altinda ve en az 3 gunluk gecmis.
function Prices:Flips(limit)
  local out = {}
  for id, e in pairs(self:Store().items) do
    local info = self:ScanInfo(id)
    if info and info.days >= 3 and info.min and info.market and info.seen == today() and info.min < info.market * 0.6 then
      out[#out + 1] = { id = id, min = info.min, median = info.market, profit = math.floor(info.market * 0.95 - info.min) }
    end
  end
  table.sort(out, function(a, b) return a.profit > b.profit end)
  while limit and #out > limit do table.remove(out) end
  return out
end

-- Kendi tarama
local function modernAH() return C_AuctionHouse and C_AuctionHouse.ReplicateItems and C_AuctionHouse.GetNumReplicateItems end
local function classicAH() return QueryAuctionItems and GetNumAuctionItems and GetAuctionItemInfo end

function Prices:AtAuctionHouse() return self.atAH == true end

function Prices:CanScan()
  if not self.atAH then return false, L["Open the auction house first."] end
  if self.scanning then return false, L["A scan is already running."] end
  if modernAH() then return true end
  if classicAH() then
    if CanSendAuctionQuery then
      local _, canAll = CanSendAuctionQuery()
      if not canAll then return false, L["A full scan is possible every 15 minutes. Try again later."] end
    end
    return true
  end
  return false, L["This client has no auction scan API."]
end

-- Tarama durumu dugmenin uzerinde (sohbet satiri gozden kacabiliyor); nil = normal ad
-- frac (0..1) verilirse dugmelerin altindaki ince cubuk dolar; nil = cubuk gizli.
Prices.scanButtons = {}
function Prices:AddScanButton(b)
  if not b.progress then
    b.progress = b:CreateTexture(nil, "OVERLAY")
    b.progress:SetPoint("BOTTOMLEFT", 1, 1)
    b.progress:SetHeight(3)
    if ns.Skin then ns.Skin:Fill(b.progress, ns.Skin.Colors.accent) end
    b.progress._skinFixed = true
    b.progress:Hide()
  end
  self.scanButtons[#self.scanButtons + 1] = b
end

Prices.statusHooks = {}   -- fn(text, frac): durumu kendi cizen yerler (AH paneli ilerleme cubugu)
function Prices:SetStatus(text, frac)
  self.status, self.progress = text, frac
  for _, fn in ipairs(self.statusHooks) do ns.SafeCall(fn, text, frac) end
  for _, b in ipairs(self.scanButtons) do
    b:SetText(text or L["Arcanis scan"])
    if b.progress then
      if frac then
        local w = b:GetWidth()
        if type(w) ~= "number" or w <= 2 then w = 120 end
        b.progress:SetWidth(math.max(1, (w - 2) * math.min(1, math.max(0, frac))))
        b.progress:Show()
      else
        b.progress:Hide()
      end
    end
  end
end

-- Tam tarama (ReplicateItems) sunucuda 15 dakikada bir; arada sayfa sayfa gezinme taramasi kullanilir.
local FULL_EVERY = 15 * 60
local function now() return time and time() or 0 end

function Prices:StartScan()
  local ok, why = self:CanScan()
  if not ok then ns:Print(why); self:SetStatus(why == L["A scan is already running."] and self.status or nil, self.progress) return false end
  self.scanning = true
  self.scanId = (self.scanId or 0) + 1   -- eski taramanin geciken parcalari yenisine karismaz
  self.buffer = {}
  ns:Print(L["Scanning the auction house..."])
  self:SetStatus(L["Waiting for server..."], 0)
  if modernAH() then
    local store = self:Store()
    if C_AuctionHouse.SendBrowseQuery and store.lastFull and now() - store.lastFull < FULL_EVERY then
      self:StartBrowse()
    else
      self.mode = "modern"
      store.lastFull = now()
      pcall(C_AuctionHouse.ReplicateItems)
      -- sunucu tam taramaya cevap vermezse (kisitlama) gezinme taramasina gecilir
      local this = self
      if P.After then
        P.After(15, function()
          if this.scanning and this.mode == "modern" and not this.collecting then
            if C_AuctionHouse.SendBrowseQuery then this:StartBrowse() else this:StopScan(L["No answer, try later"]) end
          end
        end)
      end
    end
  else
    self.mode = "classic"
    pcall(QueryAuctionItems, "", nil, nil, 0, false, 0, true)
  end
  ns:Send("ARCANIS_PRICES_CHANGED", "scan-start")
  return true
end

-- Ilanlari parcalar halinde oku (getInfo(i) -> count, buyout, itemId)
-- Pencere kapanirsa ya da yeni tarama baslarsa (scanId) kalan parcalar okunmaz ve sonuc yazilmaz.
function Prices:Collect(first, last, getInfo)
  local i = first
  local id, buf = self.scanId, self.buffer
  local function step()
    if not (self.scanning and self.scanId == id and self.buffer == buf) then return end
    local stop = math.min(last, i + CHUNK - 1)
    for k = i, stop do
      local ok, count, buyout, itemId = pcall(getInfo, k)
      if ok and itemId and buyout and buyout > 0 and count and count > 0 then
        local unit = math.floor(buyout / count)
        local b = buf[itemId]
        if not b then buf[itemId] = { min = unit, qty = count, n = 1, atMin = 1 }
        else
          if unit < b.min then b.min, b.atMin = unit, 1 elseif unit == b.min then b.atMin = b.atMin + 1 end
          b.qty, b.n = b.qty + count, b.n + 1
        end
      end
    end
    i = stop + 1
    if last >= first then
      local frac = (i - first) / (last - first + 1)
      self:SetStatus(L["Scanning %d%%"]:format(math.floor(frac * 100)), frac)
    end
    if i <= last then
      if C_Timer and C_Timer.After then C_Timer.After(0, step) else step() end
    else
      self:FinishScan()
    end
  end
  step()
end

function Prices:OnReplicate()
  if not (self.scanning and self.mode == "modern") or self.collecting then return end
  self.collecting = true
  local n = C_AuctionHouse.GetNumReplicateItems() or 0
  self:Collect(0, n - 1, function(k)
    local r = { C_AuctionHouse.GetReplicateItemInfo(k) }
    return r[3], r[10], r[17]
  end)
end

-- Gezinme taramasi: bos arama tum esyalari en dusuk fiyat + toplam adetle sayfa sayfa getirir.
-- Ilan sayisi (n, atMin) bu yolla gelmez. Ilerleme: gelen esya / son taramadaki esya sayisi (bilinmiyorsa 3000).
function Prices:StartBrowse()
  self.mode, self.collecting, self.buffer = "browse", false, {}
  self.browseAt = now()
  local q = { searchString = "", sorts = {}, filters = {} }
  if not pcall(C_AuctionHouse.SendBrowseQuery, q) then return self:StopScan(L["No answer, try later"]) end
  self:SetStatus(L["Scanning %d%%"]:format(0), 0)
  self:WatchBrowse()
end

-- Sunucu sayfa gondermeyi keserse (kisitlama) 20 sn sonra eldekiyle bitir
function Prices:WatchBrowse()
  if not P.After then return end
  local this, mark = self, self.browseAt
  P.After(20, function()
    if not (this.scanning and this.mode == "browse") then return end
    if this.browseAt ~= mark then return this:WatchBrowse() end
    if next(this.buffer or {}) then this:FinishScan() else this:StopScan(L["No answer, try later"]) end
  end)
end

function Prices:OnBrowse()
  if not (self.scanning and self.mode == "browse") then return end
  self.browseAt = now()
  local list = C_AuctionHouse.GetBrowseResults and C_AuctionHouse.GetBrowseResults() or {}
  -- GetBrowseResults birikimli liste doner (her sayfada bastan): tampon her seferinde yeniden kurulur, adetler
  -- sayfa sayisi kadar katlanmaz (ayni esyanin varyantlari yine toplanir)
  self.buffer = {}
  local buf = self.buffer
  for _, r in ipairs(list) do
    local id = r.itemKey and r.itemKey.itemID
    local price, qty = r.minPrice, r.totalQuantity
    if id and type(price) == "number" and not (issecretvalue and issecretvalue(price)) and price > 0 then
      local b = buf[id]
      if not b then buf[id] = { min = price, qty = qty or 0, n = nil, atMin = nil }
      else b.min = math.min(b.min, price); b.qty = b.qty + (qty or 0) end
    end
  end
  local expected = math.max(self:Store().lastCount or 3000, #list + 1)
  local frac = math.min(0.99, #list / expected)
  self:SetStatus(L["Scanning %d%%"]:format(math.floor(frac * 100)), frac)
  if C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults() then
    self:FinishScan()
  else
    pcall(C_AuctionHouse.RequestMoreBrowseResults)
  end
end

function Prices:StopScan(status)
  self.scanning, self.collecting, self.buffer = false, false, nil
  if status then ns:Print(L["A full scan is possible every 15 minutes. Try again later."]) end
  self:SetStatus(status)
  ns:Send("ARCANIS_PRICES_CHANGED", "scan-end")
end

function Prices:OnListUpdate()
  if not (self.scanning and self.mode == "classic") or self.collecting then return end
  local n = GetNumAuctionItems("list") or 0
  if n == 0 then return end
  self.collecting = true
  self:Collect(1, n, function(k)
    local r = { GetAuctionItemInfo("list", k) }
    return r[3], r[10], r[17]
  end)
end

function Prices:FinishScan()
  if not self.scanning then return end
  local store = self:Store()
  local day, count, now = today(), 0, time and time() or 0
  for id, b in pairs(self.buffer or {}) do
    local e = store.items[id]
    if not e then e = { h = {} }; store.items[id] = e end
    e.min, e.qty, e.day, e.n, e.atMin, e.t = b.min, b.qty, day, b.n, b.atMin, now
    local h = e.h
    if h[#h] and h[#h][1] == day then
      h[#h][2] = math.min(h[#h][2], b.min)
    else
      h[#h + 1] = { day, b.min }
    end
    while #h > HISTORY_DAYS do table.remove(h, 1) end
    count = count + 1
  end
  store.last = time and time() or 0
  if count > 0 then store.lastCount = count end
  -- uzun suredir hic ilani gorulmeyen esyalar kayittan dusulur (kayit sinirsiz buyumesin)
  for id, e in pairs(store.items) do
    if e.t and now - e.t > PRUNE_AFTER then store.items[id] = nil end
  end
  self.scanning, self.collecting, self.buffer = false, false, nil
  ns:Print(L["Auction scan done: %d items priced."]:format(count))
  self:SetStatus(L["Done: %d items"]:format(count))
  ns:Send("ARCANIS_PRICES_CHANGED", "scan-done")
end

function Prices:LastScanText()
  local last = self:Store().last
  if not last then return L["never"] end
  return date and date("%Y-%m-%d %H:%M", last) or tostring(last)
end

-- Acik artirma penceresinde kucuk "Arcanis scan" dugmesi; AH paneli aciksa gerekmez (pencerenin ustunde yalniz
-- panelin Arcanis ikonu durur, tarama panelin icinde)
function Prices:AttachButton()
  local host = _G.AuctionHouseFrame or _G.AuctionFrame
  if ns.AuctionPanel and ns.AuctionPanel:IsEnabled() then
    if self.ahButton then self.ahButton:Hide() end
    return
  end
  if not host or self.ahButton then
    if self.ahButton then self.ahButton:Show() end
    return
  end
  local b = ns.Skin:CreateButton(host, L["Arcanis scan"], 120, 22, true)
  b:SetPoint("TOPRIGHT", host, "TOPRIGHT", -60, -2)
  b:SetFrameStrata("HIGH")
  b:SetScript("OnClick", function() ns.SafeCall(Prices.StartScan, Prices) end)
  b:SetScript("OnEnter", function(x)
    if not GameTooltip then return end
    GameTooltip:SetOwner(x, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L["Arcanis scan"], 1, 1, 1)
    GameTooltip:AddLine(L["Scans all auctions and saves prices for Arcanis Path. Last scan: %s"]:format(Prices:LastScanText()), nil, nil, nil, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  self.ahButton = b
  self:AddScanButton(b)
end

-- Ipucu satiri
function Prices:TooltipLine(tt, id, link, fresh)
  if not (self:IsEnabled() and self.db.tooltip and tt and id) then return end
  if not fresh and tt.__arcanisPriced == id then return end
  local v, src = self:Get(id, link)
  if not v then return end
  tt.__arcanisPriced = id
  tt:AddDoubleLine("|cffdb9e33Arcanis|r " .. L["AH"] .. " |cff888888(" .. self:SourceName(src) .. ")|r",
    "|cffffffff" .. ns.Suite.FormatMoney(v) .. "|r")
  if not fresh then tt:Show() end
end

function Prices:HookTooltips()
  if self.hooked then return end
  self.hooked = true
  local function idFrom(link) return link and tonumber(tostring(link):match("item:(%d+)")) end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
      if tt ~= GameTooltip and tt ~= _G.ItemRefTooltip then return end
      local id = data and data.id
      ns.SafeCall(Prices.TooltipLine, Prices, tt, id, nil, true)
    end)
  elseif GameTooltip and GameTooltip.HookScript then
    for _, tt in ipairs({ GameTooltip, _G.ItemRefTooltip }) do
      if tt then
        tt:HookScript("OnTooltipSetItem", function(t)
          local _, link = t:GetItem()
          ns.SafeCall(Prices.TooltipLine, Prices, t, idFrom(link), link)
        end)
        tt:HookScript("OnTooltipCleared", function(t) t.__arcanisPriced = nil end)
      end
    end
  end
  if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnHide", function(t) t.__arcanisPriced = nil end)
  end
end

-- Fiyat kaynagi secenekleri (Ayarlar ve Altin sayfasi ayni listeyi kullanir).
function Prices:SourceItems()
  local items = { { value = "auto", text = L["Auto (first available)"] } }
  for _, p in ipairs(self.PROVIDERS) do
    local name = self:SourceName(p.id)
    if not p.available() then name = name .. "  |cff888888(" .. L["not installed"] .. ")|r" end
    items[#items + 1] = { value = p.id, text = name }
  end
  return items
end

function Prices:SetSource(id)
  self.db.source = id
  ns:Send("ARCANIS_PRICES_CHANGED", "source")
end

function Prices:OnEnable()
  -- durum ayarlandiktan SONRA haber verilir: tarama dugmeleri (Altin sayfasi, Ayarlar) acilip kapanir
  ns:On("AUCTION_HOUSE_SHOW", self, function(o)
    o.atAH = true
    ns.SafeCall(o.AttachButton, o)
    ns:Send("ARCANIS_PRICES_CHANGED", "ah-open")
  end)
  ns:On("AUCTION_HOUSE_CLOSED", self, function(o)
    o.atAH = false
    if o.scanning then o.scanning, o.collecting, o.buffer = false, false, nil end
    o:SetStatus(nil)
    ns:Send("ARCANIS_PRICES_CHANGED", "ah-closed")
  end)
  -- Yalniz istemcide var olan AH API'sinin olayini kaydet; digeri bilinmeyen olay hatasi verir.
  if modernAH() then
    ns:On("REPLICATE_ITEM_LIST_UPDATE", self, "OnReplicate")
    ns:On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", self, "OnBrowse")
    ns:On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", self, "OnBrowse")
    -- kisitlama kalkinca bekleyen sayfayi yeniden iste
    ns:On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", self, function(o)
      if o.scanning and o.mode == "browse" then pcall(C_AuctionHouse.RequestMoreBrowseResults) end
    end)
  end
  if classicAH() then ns:On("AUCTION_ITEM_LIST_UPDATE", self, "OnListUpdate") end
  self:HookTooltips()
end

ns:RegisterCommand("prices", function(args)
  local cmd = (args or ""):lower():match("^(%S*)")
  if cmd == "scan" then Prices:StartScan() return end
  local active = Prices:ActiveSource()
  ns:Print(L["Price source: %s (setting: %s). Last Arcanis scan: %s"]:format(
    active and Prices:SourceName(active) or L["none"], Prices:SourceName(Prices.db.source), Prices:LastScanText()))
  for _, p in ipairs(Prices.PROVIDERS) do
    print(("  %s: %s"):format(Prices:SourceName(p.id), p.available() and L["available"] or L["not installed"]))
  end
end, "[scan] auction price sources; scan the auction house")
