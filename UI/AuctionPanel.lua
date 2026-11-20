-- Arcanis: Auction House paneli (modul "AuctionPanel"). Auction House penceresinin sagina yapisir; AH penceresinin
-- ustundeki tek Arcanis logosuyla acilip kapanir (durum hatirlanir).
--   ust: son tarama (tarama surerken yerinde yuzdeli cubuk) + ikonlu "Scan" dugmesi
--   liste: cantadaki satilabilir esyalar (Gold:SellAdvice), fiyat ve fiyatin tazeligi (renkli nokta)
--   alt: secili esya: piyasa fiyati ve kaynagi, en dusuk ilan, o fiyattaki ilan sayisi, toplam ilan, fiyatin yasi,
--        14 gunluk en dusuk fiyat cubuklari; birim fiyat (oyuncu belirler), sure, deposit, "Post".
-- Tiklamak ilan koymaz: yalniz secer. Ilan yalniz "Post" ile (donanim olayi) konur.
local _, ns = ...

local P = ns.Provider
local L = ns.L
local Skin = ns.Skin
local C = Skin.Colors
local unpack = unpack or table.unpack

local Panel = ns:NewModule("AuctionPanel", { defaults = { open = false, duration = 2 } })
ns.AuctionPanel = Panel

local W, ROW_H, DETAIL_H = 320, 30, 236
local FRESH, TODAY = 3600, 86400

local function money(c) return c and ns.Suite.FormatMoney(c) or "-" end

-- "az once", "12 min ago", "5 h ago", "3 days ago"
function Panel.AgeText(sec)
  if not sec then return nil end
  if sec < 60 then return L["just now"] end
  if sec < FRESH then return L["%d min ago"]:format(math.floor(sec / 60)) end
  if sec < TODAY then return L["%d h ago"]:format(math.floor(sec / 3600)) end
  return L["%d days ago"]:format(math.floor(sec / TODAY))
end

local function ageColor(sec)
  if not sec then return C.textOff end
  if sec < FRESH then return { 0.30, 0.85, 0.40, 1 } end
  if sec < TODAY then return C.accent end
  return { 0.85, 0.35, 0.30, 1 }
end

local function fstr(parent, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  Skin:SetFont(fs, size or 11, "")
  fs:SetTextColor(unpack(color or C.text))
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(false)
  return fs
end

-- Veri
-- Satilabilir esyalar: { id, link, icon, count, bag, slot, stack, price, source, age, scan }
function Panel:Items()
  local G, PR = ns.Gold, ns.Prices
  if not G then return {} end
  local out = {}
  for _, e in ipairs((G:SellAdvice())) do
    -- eski istemcide "ruhuna bagli" bilgisi yok: gizli ipucundan bakilir (bilinmiyorsa listelenir)
    if e.bag and e.slot and P.IsSoulbound(e.bag, e.slot) ~= true then
      local price, source
      if PR then price, source = PR:Get(e.id, e.link) end
      out[#out + 1] = { id = e.id, link = e.link, icon = e.icon, count = e.count, bag = e.bag, slot = e.slot,
        stack = e.stack or 1, price = price, source = source, vendor = e.vendor,
        age = PR and source and PR:Age(e.id, source), scan = PR and PR:ScanInfo(e.id) }
    end
  end
  table.sort(out, function(a, b)
    if (a.price ~= nil) ~= (b.price ~= nil) then return a.price ~= nil end
    return (a.price or 0) * a.count > (b.price or 0) * b.count
  end)
  return out
end

-- Birim fiyat kutulari -> bakir (bos/gecersiz = 0)
function Panel.Copper(g, s, c)
  local function n(v) return math.max(0, math.floor(tonumber(v) or 0)) end
  return n(g) * 10000 + n(s) * 100 + n(c)
end

-- Cerceve
local function host() return _G.AuctionHouseFrame or _G.AuctionFrame end

function Panel:Build()
  if self.frame then return self.frame end
  local h = host()
  if not h then return nil end
  local f = CreateFrame("Frame", "ArcanisAuctionPanel", h, "BackdropTemplate")
  f:SetSize(W, math.max(420, (h.GetHeight and h:GetHeight()) or 440))
  f:SetPoint("TOPLEFT", h, "TOPRIGHT", 4, 0)
  Skin:ApplyBackdrop(f)
  Skin:RegisterRoot(f)
  f:EnableMouse(true)
  f:Hide()
  self.frame = f

  -- ust: baslik, son tarama, tarama dugmesi
  f.title = fstr(f, 12, C.accentHover)
  f.title:SetPoint("TOPLEFT", 12, -10)
  f.title:SetText("Arcanis")
  f.close = Skin:CreateButton(f, "x", 22, 22)
  f.close:SetPoint("TOPRIGHT", -10, -9)
  f.close:SetScript("OnClick", function() Panel:SetOpen(false) end)
  -- tarama dugmesi: ikon + "Scan" (yazi degismez); ilerleme soldaki cubukta
  f.scan = Skin:CreateButton(f, L["Scan"], 76, 22, true)
  f.scan:SetPoint("TOPRIGHT", f.close, "TOPLEFT", -8, 0)
  f.scan.icon = f.scan:CreateTexture(nil, "OVERLAY")
  f.scan.icon:SetSize(14, 14)
  f.scan.icon:SetPoint("LEFT", 8, 0)
  f.scan.icon:SetTexture(Skin.Icons["repeat"])
  f.scan:SetScript("OnClick", function(b)
    if b:IsEnabled() and ns.Prices then ns.SafeCall(ns.Prices.StartScan, ns.Prices) end
  end)
  f.last = fstr(f, 10, C.textDim)
  f.last:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
  f.last:SetPoint("RIGHT", f.scan, "LEFT", -8, 0)
  -- tarama suruyorken "Last scan" satirinin yerinde yuzdeli cubuk
  f.bar = CreateFrame("Frame", nil, f)
  f.bar:SetHeight(14)
  f.bar:SetPoint("LEFT", f.last, "LEFT", 0, 0)
  f.bar:SetPoint("RIGHT", f.scan, "LEFT", -8, 0)
  f.bar.bg = f.bar:CreateTexture(nil, "BACKGROUND")
  f.bar.bg:SetAllPoints()
  Skin:Fill(f.bar.bg, C.row)
  f.bar.fill = f.bar:CreateTexture(nil, "ARTWORK")
  f.bar.fill:SetPoint("TOPLEFT")
  f.bar.fill:SetPoint("BOTTOMLEFT")
  Skin:Fill(f.bar.fill, C.accent)
  f.bar.text = fstr(f.bar, 10, C.text, "CENTER")
  f.bar.text:SetPoint("CENTER")
  f.bar:Hide()
  if ns.Prices then
    table.insert(ns.Prices.statusHooks, function(text, frac) Panel:ShowProgress(text, frac) end)
  end

  -- liste
  f.list = Skin:CreateScrollArea(f, W - 16, 200)
  f.list:SetPoint("TOPLEFT", 8, -52)
  f.list:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, DETAIL_H + 8)
  f.rows = {}
  f.empty = fstr(f.list.content, 11, C.textDim)
  f.empty:SetPoint("TOPLEFT", 8, -8)

  -- alt: secili esya
  local d = CreateFrame("Frame", nil, f, "BackdropTemplate")
  d:SetPoint("BOTTOMLEFT", 8, 8)
  d:SetPoint("BOTTOMRIGHT", -8, 8)
  d:SetHeight(DETAIL_H)
  Skin:ApplyBackdrop(d, C.card, C.border)
  f.detail = d
  d.hint = fstr(d, 11, C.textDim)
  d.hint:SetPoint("TOPLEFT", 12, -12)
  d.name = fstr(d, 12, C.text)
  d.name:SetPoint("TOPLEFT", 12, -10)
  d.name:SetPoint("RIGHT", -80, 0)
  d.bags = fstr(d, 10, C.textDim, "RIGHT")
  d.bags:SetPoint("TOPRIGHT", -12, -12)
  d.market = fstr(d, 11, C.text)
  d.market:SetPoint("TOPLEFT", d.name, "BOTTOMLEFT", 0, -8)
  d.market:SetPoint("RIGHT", -12, 0)
  d.lowest = fstr(d, 10, C.textDim)
  d.lowest:SetPoint("TOPLEFT", d.market, "BOTTOMLEFT", 0, -4)
  d.lowest:SetPoint("RIGHT", -12, 0)
  d.age = fstr(d, 10, C.textDim)
  d.age:SetPoint("TOPLEFT", d.lowest, "BOTTOMLEFT", 0, -4)
  d.age:SetPoint("RIGHT", -12, 0)
  -- 14 gunluk en dusuk fiyat cubuklari: etiketin altina hizali, yukari 24 px buyur (ustteki satira tasmaz)
  d.histLabel = fstr(d, 9, C.textOff)
  d.histLabel:SetPoint("TOPLEFT", d.age, "BOTTOMLEFT", 0, -28)
  d.bars = {}
  for i = 1, 14 do
    local b = d:CreateTexture(nil, "ARTWORK")
    b:SetWidth(12)
    b:SetPoint("BOTTOMLEFT", d.histLabel, "BOTTOMLEFT", 120 + (i - 1) * 12, 0)
    d.bars[i] = b
  end
  -- birim fiyat: altin / gumus / bakir
  d.priceLabel = fstr(d, 10, C.textDim)
  d.priceLabel:SetPoint("TOPLEFT", d.histLabel, "BOTTOMLEFT", 0, -16)
  d.priceLabel:SetText(L["Unit price"])
  local function box(w) local e = Skin:CreateEditBox(d, w, 22, function() Panel:UpdateTotal() end); e:SetNumeric(true); return e end
  d.g, d.s, d.c = box(56), box(36), box(36)
  d.g:SetPoint("LEFT", d.priceLabel, "RIGHT", 8, 0)
  d.gl = fstr(d, 10, { 1, 0.82, 0.2, 1 }); d.gl:SetPoint("LEFT", d.g, "RIGHT", 4, 0); d.gl:SetText("g")
  d.s:SetPoint("LEFT", d.gl, "RIGHT", 8, 0)
  d.sl = fstr(d, 10, { 0.8, 0.8, 0.85, 1 }); d.sl:SetPoint("LEFT", d.s, "RIGHT", 4, 0); d.sl:SetText("s")
  d.c:SetPoint("LEFT", d.sl, "RIGHT", 8, 0)
  d.cl = fstr(d, 10, { 0.85, 0.55, 0.3, 1 }); d.cl:SetPoint("LEFT", d.c, "RIGHT", 4, 0); d.cl:SetText("c")
  d.total = fstr(d, 10, C.textDim)
  d.total:SetPoint("TOPLEFT", d.priceLabel, "BOTTOMLEFT", 0, -12)
  d.total:SetPoint("RIGHT", -12, 0)
  -- sure + deposit + ilan
  local labels = P.AHDurationLabels()
  local items = {}
  for i, t in ipairs(labels) do items[i] = { value = i, text = t } end
  d.duration = Skin:CreateDropdown(d, 120, items, self.db.duration or 2, function(v) Panel.db.duration = v; Panel:UpdateTotal() end)
  d.duration:SetPoint("BOTTOMLEFT", 12, 12)
  d.post = Skin:CreateButton(d, L["Post"], 90, 24, true)
  d.post:SetPoint("BOTTOMRIGHT", -12, 12)
  d.post:SetScript("OnClick", function() ns.SafeCall(Panel.Post, Panel) end)
  d.deposit = fstr(d, 10, C.textDim, "RIGHT")
  d.deposit:SetPoint("RIGHT", d.post, "LEFT", -8, 0)
  d.deposit:SetPoint("LEFT", d.duration, "RIGHT", 8, 0)
  return f
end

local function row(f, i)
  local r = f.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, f.list.content)
  r:SetHeight(ROW_H)
  r.bg = r:CreateTexture(nil, "BACKGROUND")
  r.bg:SetAllPoints()
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(22, 22)
  r.icon:SetPoint("LEFT", 4, 0)
  r.dot = r:CreateTexture(nil, "ARTWORK")
  r.dot:SetSize(8, 8)
  r.dot:SetPoint("RIGHT", -8, 0)
  r.price = fstr(r, 10, C.text, "RIGHT")
  r.price:SetPoint("RIGHT", r.dot, "LEFT", -8, 0)
  r.name = fstr(r, 11, C.text)
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
  r.name:SetPoint("RIGHT", r.price, "LEFT", -8, 0)
  r:SetScript("OnClick", function(b)
    if P.IsShiftDown() and b.item and Panel:SearchItem(b.item.link or b.item.id) then return end
    Panel:Select(b.item)
  end)
  r:SetScript("OnEnter", function(b)
    if not (GameTooltip and b.item) then return end
    GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
    if GameTooltip.SetBagItem then pcall(GameTooltip.SetBagItem, GameTooltip, b.item.bag, b.item.slot) end
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  f.rows[i] = r
  return r
end

-- Tarama durumu: suruyorsa (frac) cubuk + "Scanning 45%", bittiyse satirda sonuc ("Done: 412 items"), yoksa son tarama
function Panel:ShowProgress(text, frac)
  local f = self.frame
  if not f then return end
  local PR = ns.Prices
  if frac then
    local w = f.bar:GetWidth()
    if type(w) ~= "number" or w <= 1 then w = 160 end
    f.bar.fill:SetWidth(math.max(1, w * math.min(1, math.max(0, frac))))
    f.bar.text:SetText(text or "")
    f.bar:Show(); f.last:Hide()
  else
    f.bar:Hide(); f.last:Show()
    local last = PR and PR:Store().last
    f.last:SetText(text or L["Last scan: %s"]:format(last and self.AgeText(math.max(0, ((time and time()) or last) - last)) or L["never"]))
  end
  f.scan:SetEnabled(PR and PR:AtAuctionHouse() and not PR.scanning)
end

-- Yenileme
function Panel:Refresh()
  local f = self.frame
  if not (f and f:IsShown()) then return end
  local PR = ns.Prices
  self:ShowProgress(PR and PR.status, PR and PR.progress)
  self.items = self:Items()
  local y = 0
  for i, it in ipairs(self.items) do
    local r = row(f, i)
    r.item = it
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", f.list.content, "TOPLEFT", 0, -y)
    r:SetPoint("TOPRIGHT", f.list.content, "TOPRIGHT", 0, -y)
    r.icon:SetTexture(it.icon)
    r.name:SetText((it.link or ("#" .. it.id)) .. (it.count > 1 and ("  x" .. it.count) or ""))
    r.price:SetText(it.price and money(it.price) or L["no price"])
    Skin:Fill(r.dot, ageColor(it.age))
    Skin:Fill(r.bg, (self.selected and self.selected.id == it.id) and C.rowActive or C.row)
    r:Show()
    y = y + ROW_H + 2
  end
  for i = #self.items + 1, #f.rows do f.rows[i]:Hide() end
  f.empty:SetText(#self.items == 0 and L["Nothing to sell in your bags."] or "")
  f.list:SetContentHeight(y)
  -- secim yenilenir (satildiysa duser)
  local keep
  if self.selected then for _, it in ipairs(self.items) do if it.id == self.selected.id then keep = it end end end
  self:ShowDetail(keep)
end

function Panel:Select(item)
  -- baska esya: fiyat kutulari piyasa fiyatiyla dolar; ayni esyaya tekrar tiklamak yazilan fiyati silmez
  if not (self.selected and item and self.selected.id == item.id) then self.priceFor = nil end
  self:ShowDetail(item)
  for _, r in ipairs(self.frame.rows) do
    if r:IsShown() and r.item then Skin:Fill(r.bg, (item and r.item.id == item.id) and C.rowActive or C.row) end
  end
end

function Panel:ShowDetail(it)
  local d = self.frame.detail
  self.selected = it
  local show = it ~= nil
  for _, k in ipairs({ "name", "bags", "market", "lowest", "age", "histLabel", "priceLabel", "g", "s", "c", "gl", "sl", "cl",
                       "total", "duration", "post", "deposit" }) do
    if show then d[k]:Show() else d[k]:Hide() end
  end
  for _, b in ipairs(d.bars) do b:Hide() end
  d.hint:SetText(show and "" or L["Select an item to post it."])
  if not show then return end
  d.name:SetText(it.link or ("#" .. it.id))
  d.bags:SetText(L["In bags: %d"]:format(it.count))
  local PR = ns.Prices
  d.market:SetText(it.price and L["Market: %s (%s)"]:format(money(it.price), PR and PR:SourceName(it.source) or "?") or L["No price data"])
  local s = it.scan
  if s and s.min then
    local line = L["Lowest now: %s"]:format(money(s.min))
    if s.atMin and s.n then line = line .. "  -  " .. L["%d at this price, %d listed"]:format(s.atMin, s.n) end
    d.lowest:SetText(line)
  else
    d.lowest:SetText(L["Not in your last Arcanis scan."])
  end
  local age = it.age or (s and s.t and time and math.max(0, time() - s.t))
  d.age:SetText(age and L["Price from %s"]:format(self.AgeText(age)) or L["Price age unknown"])
  d.age:SetTextColor(unpack(ageColor(age)))
  -- gecmis cubuklari (en eski solda)
  local hist = s and s.hist or {}
  -- tek gunluk veride tek cubuk bir sey anlatmaz: grafik ikinci tarama gununden itibaren
  if #hist == 1 then
    d.histLabel:SetText(L["Price history: scan on another day to compare."])
    hist = {}
  else
    d.histLabel:SetText(#hist > 1 and L["Last %d days (lowest)"]:format(#hist) or "")
  end
  local hi = 0
  for _, h in ipairs(hist) do hi = math.max(hi, h[2] or 0) end
  for i, h in ipairs(hist) do
    local b = d.bars[i]
    if b and hi > 0 then
      b:SetHeight(math.max(2, 24 * (h[2] or 0) / hi))
      Skin:Fill(b, i == #hist and C.accentHover or C.accent)
      b:Show()
    end
  end
  -- fiyat kutulari: yeni secimde piyasa fiyati (oyuncu degistirebilir)
  if self.priceFor ~= it.id then
    self.priceFor = it.id
    local p = it.price or 0
    d.g:SetText(tostring(math.floor(p / 10000)))
    d.s:SetText(tostring(math.floor(p / 100) % 100))
    d.c:SetText(tostring(p % 100))
  end
  self:UpdateTotal()
end

function Panel:UnitPrice()
  local d = self.frame and self.frame.detail
  if not d then return 0 end
  return self.Copper(d.g:GetText(), d.s:GetText(), d.c:GetText())
end

function Panel:UpdateTotal()
  local it, d = self.selected, self.frame and self.frame.detail
  if not (it and d) then return end
  local unit = self:UnitPrice()
  d.total:SetText(L["Stack of %d: %s"]:format(it.stack, money(unit * it.stack)))
  local dep = P.AHDeposit(it.bag, it.slot, it.id, it.stack, self.db.duration or 2)
  d.deposit:SetText(dep and L["Deposit: %s"]:format(money(dep)) or "")
  -- Auction prices kapali olsa da ilan konabilir: AH durumu panelin kendisinde; gonderilen ilan sonrasi liste
  -- yenilenene kadar kapali (cift tiklama ayni yeri iki kez gondermesin)
  d.post:SetEnabled(unit > 0 and P.AHPostMode() ~= nil and self.atAH and not self.posting)
end

-- Secili esyanin en buyuk yiginini, oyuncunun yazdigi birim fiyatla ilana koy.
function Panel:Post()
  local it = self.selected
  if not it or self.posting then return false end
  local unit = self:UnitPrice()
  if unit <= 0 then ns:Print(L["Enter a price first."]) return false end
  if not P.AHPostMode() then ns:Print(L["Not posted: this client has no Auction House posting API."]) return false end
  -- secimden sonra canta degistiyse (yer degisimi, satis) o yerde baska esya olabilir: para harcanmadan dur
  local cur = P.ContainerItem(it.bag, it.slot)
  if not (cur and cur.id == it.id and (cur.count or 1) >= it.stack) then
    ns:Print(L["Your bags changed. Select the item again."])
    self:Refresh()
    return false
  end
  local ok, why, confirm = P.AHPost(it.bag, it.slot, it.stack, unit, self.db.duration or 2, it.id)
  local label = it.link or ("#" .. it.id)
  local function posted()
    self.posting = true
    ns:Print(L["Posting %s x%d for %s..."]:format(label, it.stack, money(unit * it.stack)))
    self:UpdateTotal()
  end
  if ok then
    posted()
  elseif why == "confirm" and confirm then
    -- sunucu fiyati supheli buldu (piyasanin cok altinda): oyuncu onaylamadan ilan acilmaz
    P.Confirm(L["The price looks very low. Post %s x%d for %s?"]:format(label, it.stack, money(unit * it.stack)),
      function()
        local okC, err = confirm()
        if okC then posted() else ns:Print(L["Could not post: %s"]:format(tostring(err))) end
      end)
  else
    ns:Print(L["Could not post: %s"]:format(tostring(why)))
  end
  return ok
end

-- Acma / kapama
function Panel:SetOpen(open)
  self.db.open = open and true or false
  local f = self:Build()
  if not f then return end
  if open then f:Show(); self:Refresh() else f:Hide() end
end

function Panel:Toggle() self:SetOpen(not (self.frame and self.frame:IsShown())) end

function Panel:OnAuctionShow()
  local h = host()
  if not h then return end
  self.atAH, self.posting = true, nil
  -- pencerenin ustunde tek dugme: Arcanis logosu, paneli acar/kapar (tarama panelin icinde)
  if not self.toggle then
    local b = Skin:CreateImageButton(h, "Interface\\AddOns\\Arcanis\\Media\\UI\\AddonIcon", 26)
    b:SetFrameStrata("HIGH")
    b:SetPoint("TOPRIGHT", h, "TOPRIGHT", -60, 0)
    b:SetTooltip("Arcanis")
    b:SetScript("OnClick", function() Panel:Toggle() end)
    self.toggle = b
  end
  self.toggle:Show()
  if self.db.open then self:SetOpen(true) end
end

function Panel:OnAuctionClosed()
  self.atAH, self.posting = false, nil
  if self.frame then self.frame:Hide() end
end

-- canta degisti: gonderilen ilan islendi (ya da baska degisiklik) -> Post yeniden basilabilir
function Panel:OnBags()
  self.posting = nil
  self:Refresh()
end

-- Shift + tik: esyanin adi AH arama kutusuna yazilir ve aranir (listeden ya da cantadan)
function Panel:SearchItem(linkOrId)
  local d = type(linkOrId) == "number" and P.ItemDetails(linkOrId) or P.ItemDetailsFromLink(linkOrId)
  local name = d and d.name
  return name and P.AHSearch(name) or false
end

function Panel:HookBagClicks()
  if self.bagHooked or not (hooksecurefunc and HandleModifiedItemClick) then return end
  self.bagHooked = true
  hooksecurefunc("HandleModifiedItemClick", function(link)
    if not (Panel:IsEnabled() and ns.Prices and ns.Prices:AtAuctionHouse()) then return end
    if not P.IsShiftDown() or P.ChatInputActive() then return end
    ns.SafeCall(Panel.SearchItem, Panel, link)
  end)
end

function Panel:OnEnable()
  self:HookBagClicks()
  ns:On("AUCTION_HOUSE_SHOW", self, "OnAuctionShow")
  ns:On("AUCTION_HOUSE_CLOSED", self, "OnAuctionClosed")
  ns:On("BAG_UPDATE_DELAYED", self, "OnBags")
  ns:Listen("ARCANIS_PRICES_CHANGED", self, "Refresh")
end

function Panel:OnDisable()
  if self.frame then self.frame:Hide() end
  if self.toggle then self.toggle:Hide() end
end
