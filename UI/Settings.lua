-- Arcanis: ayarlar penceresi (modul "Settings"): sol menu + sag sayfa.
--
--   /wf            ayarlari acar (/wf settings, /wf config)
--   Ust sekmeler (PAGES): Guides, Route ve Helpers (ozellik sayfalari: her ozellik bir kart, ilk satiri
--             modulun anahtari; FEATURES tablosu), Appearance, Dynamic Hub, System (bakim, bolgeler, komutlar,
--             hakkinda alt sekmeleri). Eski sayfa adlari PAGE_ALIAS ile yonlenir.
--
-- Sabit metinler T(fontString, "anahtar") ile kaydedilir; dil degisince hepsi yeniden yazilir.
local _, ns = ...

local unpack = unpack or table.unpack
local P = ns.Provider
local L = ns.L
local Skin = ns.Skin
local C = Skin.Colors

local Settings = ns:NewModule("Settings", { defaults = { page = "modules", filter = "suitable" } })
ns.Settings = Settings

-- sayfalarin ilk olcusu; ana pencere boyutlaninca OnResized fluids/onResize ile gunceller
local BODY_W, BODY_H = 594, 484
local bodyWidth = BODY_W
Settings.bodyWidth = BODY_W   -- pencere buyudukce guncellenir (sayfa gecis mesafesi)

local WHITE = "Interface\\Buttons\\WHITE8x8"

-- Yardimcilar
local texts = {}   -- dil degisince yeniden yazilacak sabit metinler

-- fs: FontString/Button/nav; key: L anahtari ya da fonksiyon (L'ye bagimli metin uretir).
-- Anahtar -> gosterilecek metin: islev ise cagrilir, degilse L[anahtar]; nil -> nil.
function Settings.Text(key)
  if key == nil then return nil end
  if type(key) == "function" then return key() end
  return L[key]
end

local function T(widget, key, setter)
  local function apply()
    local value = Settings.Text(key)
    if setter then setter(widget, value) else widget:SetText(value) end
  end
  texts[#texts + 1] = apply
  apply()
  return widget
end

local function label(parent, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(fs, size or 11, "")
  fs:SetTextColor(unpack(color or C.text))
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

-- Bolum basligi: kehribar isaret + baslik + ince cizgi. Dondurur: bitis y (negatif olmayan offset).
local function section(page, titleKey, y)
  local tick = page:CreateTexture(nil, "ARTWORK")
  Skin:Fill(tick, C.accent)
  tick:SetSize(3, 14)
  tick:SetPoint("TOPLEFT", 0, -y)
  local fs = label(page, 12, C.text)
  fs:SetPoint("LEFT", tick, "RIGHT", 8, 0)
  T(fs, titleKey)
  local line = page:CreateTexture(nil, "ARTWORK")
  Skin:Fill(line, C.border)
  ns.Skin:Hairline(line, "h")
  line:SetPoint("TOPLEFT", 0, -(y + 20))
  line:SetPoint("TOPRIGHT", 0, -(y + 20))
  return y + 30
end

-- Liste satiri: tikla-sec. row.a (sol metin), row.b (sag/alt metin), row:SetSelected(v).
local function makeRow(parent, width, height)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(width, height)
  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.bg:SetTexture(WHITE)
  row.bg:SetVertexColor(unpack(C.card))
  row.tick = row:CreateTexture(nil, "ARTWORK")
  Skin:Fill(row.tick, C.border)
  row.tick:SetSize(3, height)
  row.tick:SetPoint("LEFT", 0, 0)
  row.mark = row:CreateTexture(nil, "ARTWORK")
  Skin:Fill(row.mark, C.accent)
  row.mark:SetSize(2, height)
  row.mark:SetPoint("RIGHT", 0, 0)
  row.mark:Hide()
  row.a = label(row, 11, C.text)
  row.b = label(row, 10, C.textDim)
  function row:SetTick(color)
    Skin:Fill(self.tick, color)
  end
  function row:SetSelected(v)
    self.selected = v and true or false
    if self.selected then
      self.bg:SetVertexColor(unpack(C.accentSoft))
      self.mark:Show()
    else
      self.bg:SetVertexColor(unpack(C.card))
      self.mark:Hide()
    end
  end
  row:SetScript("OnEnter", function(r) if not r.selected then r.bg:SetVertexColor(unpack(C.buttonHover)) end end)
  row:SetScript("OnLeave", function(r) r:SetSelected(r.selected) end)
  return row
end

-- Satiri kaydirma alaninin icerigine yukaridan y kadar (negatif) uzakliga, iki yana gerili olarak yerlestirir.
local function stretchRow(row, content, y)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
  row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
end

-- Duyarli yerlesim: x ve width sayi ya da f(bodyWidth) olabilir; pencere boyutu degisince yeniden uygulanir.
local function val(v, bw) if type(v) == "function" then return v(bw) end return v end
local function place(page, w, y, x, width)
  page.fluids = page.fluids or {}
  local function apply(bw)
    w:ClearAllPoints()
    w:SetPoint("TOPLEFT", page, "TOPLEFT", val(x, bw), -y)
    if width then w:SetWidth(val(width, bw)) end
  end
  page.fluids[#page.fluids + 1] = apply
  apply(Settings.bodyWidth or BODY_W)
end
local function half(bw) return math.floor(bw / 2) end

-- Sinif simgeleri (Blizzard sinif atlasi); sinif simgesi koordinatlari yoksa yedek tablo kullanilir.
local CLASS_TEX = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local CLASS_FALLBACK = {
  WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 }, ROGUE = { 0.5, 0.75, 0, 0.25 }, DRUID = { 0.75, 1, 0, 0.25 },
  HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.5, 0.25, 0.5 }, PRIEST = { 0.5, 0.75, 0.25, 0.5 }, WARLOCK = { 0.75, 1, 0.25, 0.5 },
  PALADIN = { 0, 0.25, 0.5, 0.75 },
}
local function setClassIcon(tex, token)
  local c = (CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]) or CLASS_FALLBACK[token]
  tex:SetTexture(CLASS_TEX)
  if c then tex:SetTexCoord(c[1], c[2], c[3], c[4]) end
end

local function press(fn)   -- guvenli cagri
  return function(...) ns.SafeCall(fn, ...) end
end

-- Sayfa: Guides (rehber + adim secici)
local LIST_W = 270
local ROW_H = 44
local STEP_H = 24

local FACTION_COLOR = { Alliance = { 0.30, 0.52, 0.95, 1 }, Horde = { 0.86, 0.27, 0.27, 1 } }
local TYPE_COLOR = Skin.TypeColors

local function guideMatches(guide, mode, player, search)
  local G = ns.Guides
  if mode == "suitable" then
    if not (player.level >= guide.minLevel and player.level <= guide.maxLevel and G:IsEligible(guide, player)) then return false end
  elseif mode == "eligible" then
    if not G:IsEligible(guide, player) then return false end
  elseif mode == "alliance" then
    if guide.faction ~= "Alliance" then return false end
  elseif mode == "horde" then
    if guide.faction ~= "Horde" then return false end
  end
  if search and search ~= "" then
    local hay = (G:TitleOf(guide) .. " " .. guide.id):lower()
    if not hay:find(search:lower(), 1, true) then return false end
  end
  return true
end

local function buildGuides(page)
  local st = { listRows = {}, stepRows = {}, selected = nil, selectedStep = nil }
  page.st = st
  local rightX = LIST_W + 16
  local rightW = BODY_W - rightX

  st.filter = Skin:CreateDropdown(page, LIST_W, nil, Settings.db.filter, press(function(v)
    Settings.db.filter = v
    page.refreshList()
  end))
  st.filter:SetPoint("TOPLEFT", 0, 0)

  st.search = Skin:CreateEditBox(page, LIST_W, 24, press(function(_, user)
    if user then page.refreshList() end
  end))
  st.search:SetPoint("TOPLEFT", 0, -30)
  st.searchHint = label(st.search, 10, C.textOff)
  st.searchHint:SetPoint("LEFT", 8, 0)
  T(st.searchHint, "Search guides...")

  st.listArea = Skin:CreateScrollArea(page, LIST_W, BODY_H - 64)
  st.listArea:SetPoint("TOPLEFT", 0, -62)
  st.listArea:SetPoint("BOTTOMLEFT", 0, 0)

  st.title = label(page, 13, C.accent)
  st.title:SetPoint("TOPLEFT", rightX, 0)
  st.title:SetWidth(rightW)
  st.info = label(page, 10, C.textDim)
  st.info:SetPoint("TOPLEFT", rightX, -20)
  st.info:SetWidth(rightW)

  st.stepArea = Skin:CreateScrollArea(page, rightW, BODY_H - 50 - 34)
  st.stepArea:SetPoint("TOPLEFT", rightX, -44)
  st.stepArea:SetPoint("BOTTOMRIGHT", 0, 40)

  local startW = math.floor((rightW - 8) * 0.52)
  st.start = Skin:CreateButton(page, "", startW, 28, true)
  st.start:SetPoint("BOTTOMLEFT", rightX, 0)
  st.start:SetScript("OnClick", press(function()
    local guide = st.selected and ns.Engine:RouteOf(st.selected)
    if not guide then return end
    -- bilerek baslatma: "su anki adim" (cephe) de secilen adima iner
    ns.Engine:StartAt(guide.id, st.selectedStep or 1)
    ns:Print(L["Started: %s"]:format(ns.Guides:TitleOf(guide)))
    page.refreshList()
    page.refreshSteps()
  end))

  st.current = Skin:CreateButton(page, "", rightW - 8 - startW, 28)
  st.current:SetPoint("LEFT", st.start, "RIGHT", 8, 0)
  function page.onResize(bw)
    local rw = bw - rightX
    local sw = math.floor((rw - 8) * 0.52)
    st.start:SetWidth(sw)
    st.current:SetWidth(rw - 8 - sw)
    st.title:SetWidth(rw)
    st.info:SetWidth(rw)
  end
  T(st.current, "Show current guide")
  st.current:SetScript("OnClick", press(function()
    local g = ns.Engine.guide
    if g then
      st.selected, st.selectedStep = g.id, nil
      page.refreshList()
      page.refreshSteps()
    end
  end))

  function page.retext()
    st.filter:SetItems({
      { value = "suitable", text = L["Suitable for me"] },
      { value = "eligible", text = L["My faction and class"] },
      { value = "all", text = L["All guides"] },
      { value = "alliance", text = L["Alliance"] },
      { value = "horde", text = L["Horde"] },
    })
  end

  function page.refreshList()
    local player = ns.Guides:GetPlayerInfo()
    local text = st.search:GetText() or ""
    if text == "" then st.searchHint:Show() else st.searchHint:Hide() end
    local list = ns.Guides:List(function(g) return guideMatches(g, Settings.db.filter, player, text) end, true)
    local current = ns.Engine.guide and ns.Engine.guide.id
    local content = st.listArea.content
    for i, guide in ipairs(list) do
      local row = st.listRows[i]
      if not row then
        row = makeRow(content, LIST_W - 8, ROW_H)
        row.a:SetPoint("TOPLEFT", 12, -7)
        row.a:SetPoint("RIGHT", row, "RIGHT", -64, 0)
        row.a:SetWordWrap(false)
        Skin:SetFont(row.a, 12, "OUTLINE")
        row.b:SetPoint("TOPLEFT", row.a, "BOTTOMLEFT", 0, -4)
        row.badge = label(row, 10, C.accent, "RIGHT")
        row.badge:SetPoint("TOPRIGHT", -8, -8)
        row.pbar = row:CreateTexture(nil, "ARTWORK")
        Skin:Fill(row.pbar, C.accent)
        row.pbar:SetHeight(2)
        row.pbar:SetPoint("BOTTOMLEFT", 3, 0)
        row.pbar:Hide()
        row:SetScript("OnClick", press(function(r)
          st.selected, st.selectedStep = r.guideId, nil
          page.refreshList()
          page.refreshSteps()
        end))
        st.listRows[i] = row
      end
      row.guideId = guide.id
            stretchRow(row, content, -(i - 1) * (ROW_H + 2))
      local title = ns.Guides:ShortTitle(guide)   -- seviye araligi sagdaki rozette
      row.a:SetText((guide.id == current and "> " or "") .. title)
      row.a:SetTextColor(unpack(guide.id == current and C.accent or C.text))
      row.b:SetText(L["%d steps"]:format(#guide.steps) .. (guide.faction and ("  -  " .. L[guide.faction]) or ""))
      row.badge:SetText(("%d-%d"):format(guide.minLevel, guide.maxLevel))
      row:SetTick(FACTION_COLOR[guide.faction] or C.border)
      if guide.id == current and ns.Engine.index then
        row.pbar:SetWidth(math.max(1, (LIST_W - 8 - 3) * math.min(1, (ns.Engine.index - 1) / #guide.steps)))
        row.pbar:Show()
      else
        row.pbar:Hide()
      end
      row:SetSelected(guide.id == st.selected)
      row:Show()
    end
    for i = #list + 1, #st.listRows do st.listRows[i]:Hide() end
    st.listArea:SetContentHeight(#list * (ROW_H + 2))
    st.visibleCount = #list
  end

  function page.refreshSteps()
    local guide = st.selected and ns.Engine:RouteOf(st.selected)
    local content = st.stepArea.content
    if not guide then
      st.title:SetText(L["Select a guide on the left."])
      st.info:SetText("")
      for i = 1, #st.stepRows do st.stepRows[i]:Hide() end
      st.stepArea:SetContentHeight(10)
      st.start:SetText(L["Start guide"])
      st.start:Disable()
      return
    end
    st.title:SetText(ns.Guides:TitleOf(guide))
    st.info:SetText(L["Level %d-%d, %d steps"]:format(guide.minLevel, guide.maxLevel, #guide.steps))
    local player = ns.Guides:GetPlayerInfo()
    local currentIndex = ns.Engine.guide and ns.Engine.guide.id == guide.id and ns.Engine.index or nil
    for i, step in ipairs(guide.steps) do
      local row = st.stepRows[i]
      if not row then
        row = makeRow(content, rightW - 10, STEP_H)
        row.a:SetPoint("LEFT", 12, 0)
        row.a:SetPoint("RIGHT", row, "RIGHT", -120, 0)
        row.a:SetWordWrap(false)
        row.b:SetPoint("RIGHT", -8, 0)
        row.b:SetJustifyH("RIGHT")
        row:SetScript("OnClick", press(function(r)
          st.selectedStep = r.index
          page.refreshSteps()
        end))
        st.stepRows[i] = row
      end
      row.index = i
            stretchRow(row, content, -(i - 1) * (STEP_H + 1))
      local visible = ns.Engine:IsVisible(step, player)
      row.a:SetText(("%d. %s"):format(i, ns.Engine:Describe(step)))
      local done = currentIndex and i < currentIndex
      row.a:SetTextColor(unpack(i == currentIndex and C.accent or ((visible and not done) and C.text or C.textOff)))
      row:SetTick(visible and (TYPE_COLOR[step.type] or C.border) or C.border)
      row.b:SetText(step.x and ("%s %.0f, %.0f"):format(step.zone or "", step.x * 100, step.y * 100) or "")
      row:SetSelected(i == st.selectedStep)
      row:Show()
    end
    for i = #guide.steps + 1, #st.stepRows do st.stepRows[i]:Hide() end
    st.stepArea:SetContentHeight(#guide.steps * (STEP_H + 1))
    st.start:Enable()
    st.start:SetText(st.selectedStep and L["Start at step %d"]:format(st.selectedStep) or L["Start guide"])
  end

  function page.refresh()
    page.retext()
    if not st.selected and ns.Engine.guide then st.selected = ns.Engine.guide.id end
    st.filter:SetValue(Settings.db.filter, true)
    page.refreshList()
    page.refreshSteps()
  end
end

-- Secenek listesi (TEK STANDART): her ayar bir satir kartidir: solda baslik + kisa aciklama, sagda kontrol.
-- Bolumler baslik + bir cumlelik aciklamayla ayrilir. Satirlar kaydirma alaninda iki yana gerilir.
local OPT_H_SHORT, OPT_H_DESC, OPT_GAP = 34, 44, 4   -- aciklamali satir iki satir metin tasir

-- Aciklama kac satir tutar (yaklasik: ortalama harf genisligi yazi boyunun ~yarisi); kart yuksekligi buna gore
local function textLines(text, width, px)
  local w = #(text or "") * px * 0.52
  return math.max(1, math.min(3, math.ceil(w / math.max(120, width))))
end

-- Satir kurucu: content icine alt alta kartlar. ob:Section acilir-kapanir bolum (akordeon) acar; bolumun icine ayni
-- kurucuyla satir eklenir. Bir ogenin yuksekligi degisince (ob:Resize, bolum acilip kapaninca) alttakiler kayar.
-- flat: bolum govdesi (tek kart); satirlarin kendi kutusu yok, aralarinda ince ayrac cizgisi
local function newBuilder(content, refreshers, flat)
  local ob = { y = 0, refreshers = refreshers, placed = {} }
  local GAP = flat and 0 or OPT_GAP

  local function grew() if ob.onGrow then ob.onGrow() end end
  -- Her yerlesen oge kendi y'si ve yeniden konumlama islevi ile kaydedilir.
  local function place(f, at, h)
    local e = { f = f, y = ob.y, at = at, h = h }
    at(e.y)
    ob.placed[#ob.placed + 1] = e
    return e
  end
  local function fullWidth(f)
    return function(y)
      f:ClearAllPoints()
      f:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
      f:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, -y)
    end
  end
  -- her ayar kendi satirinda: etiket solda, kontrol sagda (yan yana satir yok)
  local function row(h)
    local r = CreateFrame("Frame", nil, content, "BackdropTemplate")
    if flat then
      r.line = r:CreateTexture(nil, "ARTWORK")
      Skin:Fill(r.line, C.border, 0.5)
      ns.Skin:Hairline(r.line, "h")
      r.line:SetPoint("BOTTOMLEFT", 12, 0); r.line:SetPoint("BOTTOMRIGHT", -12, 0)
      r.hl = r:CreateTexture(nil, "BACKGROUND")
      r.hl:SetAllPoints(); Skin:Fill(r.hl, C.accent, 0.05); r.hl:Hide()
    else
      Skin:ApplyBackdrop(r, C.card, C.border)
    end
    r:SetHeight(h)
    place(r, fullWidth(r), h)
    ob.y = ob.y + h + GAP
    grew()
    return r
  end

  -- Bir kartin yuksekligi degisir; altindaki her sey kayar (icerigi degisen liste, acilan bolum).
  function ob:Resize(f, h)
    local delta, after = 0, false
    for _, e in ipairs(self.placed) do
      if after then
        e.y = e.y + delta; e.at(e.y)
      elseif e.f == f then
        delta = h - e.h
        if delta == 0 then return end
        e.h = h; f:SetHeight(h); after = true
      end
    end
    self.y = self.y + delta
    grew()
  end
  -- Baslik solda; aciklama hemen altinda soluk tek satir (sigmazsa tamami ipucunda).
  local function texts(r, titleKey, descKey, rightPad)
    r.title = label(r, 12, C.text)
    r.title:SetWordWrap(false)
    T(r.title, titleKey)
    if descKey then
      r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 12, -8)
      r.title:SetPoint("RIGHT", r, "RIGHT", -rightPad, 0)
      r.desc = label(r, 10, C.textDim)
      r.desc:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -4)
      r.desc:SetPoint("RIGHT", r, "RIGHT", -rightPad, 0)
      r.desc:SetWordWrap(false)
      T(r.desc, descKey)
    else
      r.title:SetPoint("LEFT", r, "LEFT", 12, 0)
      r.title:SetPoint("RIGHT", r, "RIGHT", -rightPad, 0)
    end
    if descKey then
      r.descKey = descKey
      r:EnableMouse(true)
      r:SetScript("OnEnter", function(x)
        if x.hl then x.hl:Show() else x:SetBackdropBorderColor(unpack(C.borderLit)) end
        if GameTooltip then
          GameTooltip:SetOwner(x, "ANCHOR_TOPLEFT")
          -- anahtar metin ya da metin donduren islev olabilir (Tuslar sayfasi): T() ile ayni cozum
          GameTooltip:SetText(Settings.Text(titleKey) or "")
          GameTooltip:AddLine(Settings.Text(descKey) or "", 1, 1, 1, true)
          GameTooltip:Show()
        end
      end)
      r:SetScript("OnLeave", function(x)
        if x.hl then x.hl:Hide() else x:SetBackdropBorderColor(unpack(C.border)) end
        if GameTooltip then GameTooltip:Hide() end
      end)
    end
  end
  local function track(fn) ob.refreshers[#ob.refreshers + 1] = fn end

  function ob:Header(titleKey, descKey)
    if self.y > 0 then self.y = self.y + 14 end
    local t = label(content, 14, C.accentHover)
    place(t, function(y) t:ClearAllPoints(); t:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -y) end, 0)
    T(t, titleKey)
    self.y = self.y + 19
    if descKey then
      local d = label(content, 10, C.textDim)
      place(d, function(y)
        d:ClearAllPoints()
        d:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -y)
        d:SetPoint("RIGHT", content, "RIGHT", -6, 0)
      end, 0)
      d:SetWordWrap(true)
      T(d, descKey)
      self.y = self.y + 16
    end
    self.y = self.y + 6
    grew()
  end

  -- Acilir-kapanir bolum. Govde tek kart (flat kurucu). Doner: bolumun kendi kurucusu ve akordeon.
  -- descKey: basligin ustune gelince ipucu.
  function ob:Section(titleKey, open, descKey)
    local acc = Skin:CreateAccordion(content, BODY_W - 2, 30)
    T(acc.a, titleKey)
    acc.a:SetTextColor(unpack(C.accentHover))
    acc.tick:Hide()
    acc.cardBg = acc.body:CreateTexture(nil, "BACKGROUND")
    acc.cardBg:SetAllPoints()
    Skin:Fill(acc.cardBg, C.card)
    if descKey and acc.header.HookScript then
      acc.header:HookScript("OnEnter", function(x)
        if not GameTooltip then return end
        GameTooltip:SetOwner(x, "ANCHOR_TOPLEFT"); GameTooltip:SetText(Settings.Text(titleKey) or "")
        GameTooltip:AddLine(Settings.Text(descKey) or "", 1, 1, 1, true); GameTooltip:Show()
      end)
      acc.header:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    place(acc, fullWidth(acc), 30)
    self.y = self.y + 30 + OPT_GAP
    local sub = newBuilder(acc.body, self.refreshers, true)
    sub.onGrow = function() acc:SetBodyHeight(sub.y) end
    acc.onAnimate = function() ob:Resize(acc, acc.h) end
    acc:SetExpanded(open, true)
    grew()
    return sub, acc
  end

  -- Kart: yuvarlak koseli, vurgu tonunda ince kenar ve cok hafif vurgu yikamasi. Basligin altinda kisa vurgu
  -- cizgisi (26x2) ve ince ayrac; aciklama alti satira kadar sarar. Altinda satirlar tek sutunda.
  -- Sag ust yuva (-10, -9) ozellik anahtarina ayrilir. Doner: kartin kurucusu.
  function ob:Group(titleKey, descKey)
    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    Skin:ApplyRound(card, C.card, C.accent, 10)
    card:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.35)
    card.wash = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    card.wash:SetPoint("TOPLEFT", 3, -3); card.wash:SetPoint("BOTTOMRIGHT", -3, 3)
    Skin:Fill(card.wash, C.accent, 0.025)
    card.title = label(card, 14, C.text)
    card.title:SetPoint("TOPLEFT", 12, -16)
    card.title:SetPoint("RIGHT", card, "RIGHT", -70, 0)
    card.title:SetWordWrap(false)
    T(card.title, titleKey)
    card.bar = card:CreateTexture(nil, "ARTWORK")
    Skin:Fill(card.bar, C.accent)
    card.bar:SetSize(26, 2)
    card.bar:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -8)
    card.rule = card:CreateTexture(nil, "ARTWORK")
    Skin:Fill(card.rule, C.border, 0.6)
    ns.Skin:Hairline(card.rule, "h")
    card.rule:SetPoint("LEFT", card.bar, "RIGHT", 8, 0)
    card.rule:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    local top = 52   -- 16 ust bosluk + baslik + 8 + cizgi + 12
    if descKey then
      card.desc = label(card, 11, C.textDim)
      card.desc:SetPoint("TOPLEFT", card.bar, "BOTTOMLEFT", 0, -12)
      card.desc:SetPoint("RIGHT", card, "RIGHT", -12, 0)
      card.desc:SetWordWrap(true)
      T(card.desc, descKey)
      local w = (content.GetWidth and content:GetWidth() or 0)
      local n = textLines(Settings.Text(descKey), (w > 0 and w or BODY_W) - 26, 11)
      if card.desc.SetMaxLines then card.desc:SetMaxLines(n) end
      top = top + 8 + n * 14
    end
    place(card, fullWidth(card), top + 2)
    card:SetHeight(top + 2)
    self.y = self.y + top + 2 + 10
    local sub = newBuilder(card, self.refreshers, true)
    sub.y, sub.card = top, card
    sub.onGrow = function() ob:Resize(card, sub.y + 4) end
    grew()
    return sub
  end

  -- Ozellik karti: modulun anahtari kartin sag ust yuvasinda; kapaliyken baslik ve kartin satirlari soluk
  -- (ayarlar yine degistirilebilir: ozelligi acmadan once hazirlamak icin).
  -- f = { modul, baslik, aciklama, onSwitch = fn(v) }; body(sub) kartin kalanini kurar. Modul yoksa nil.
  function ob:Feature(f, body)
    local mod = ns:GetModule(f[1])
    if not mod then return end
    local sub = self:Group(f[2], f[3])
    local function dim()
      local on = mod:IsEnabled()
      sub.card.title:SetTextColor(unpack(on and C.text or C.textDim))
      for _, e in ipairs(sub.placed) do e.f:SetAlpha(on and 1 or 0.45) end
    end
    local sw = Skin:CreateSwitch(sub.card, "", mod:IsEnabled(), press(function(v)
      mod:SetEnabled(v)
      if f.onSwitch then f.onSwitch(v) end
      dim()
    end))
    sw:SetLabelLeft()
    sw:SetPoint("TOPRIGHT", sub.card, "TOPRIGHT", -10, -12)   -- baslikla ayni dikey orta (ust bosluk 16)
    sub.switch = sw
    if sw.track.HookScript then
      sw.track:HookScript("OnEnter", function(x)
        if not GameTooltip then return end
        GameTooltip:SetOwner(x, "ANCHOR_TOPRIGHT"); GameTooltip:SetText(L["Enabled"]); GameTooltip:Show()
      end)
      sw.track:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    track(function() sw:SetChecked(mod:IsEnabled(), true) end)
    body(sub)
    dim()
    track(dim)
    return sub
  end

  function ob:Switch(titleKey, descKey, get, set)
    local r = row(descKey and OPT_H_DESC or OPT_H_SHORT)
    texts(r, titleKey, descKey, 70)
    local sw = Skin:CreateSwitch(r, "", get(), press(function(v) set(v) end))
    sw:SetLabelLeft()   -- 46x22 ve ray saga dayali: diger sag kontrollerle ayni x (-12)
    sw:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    track(function() sw:SetChecked(get(), true) end)
    return sw, r
  end

  function ob:Slider(titleKey, descKey, min, max, step, get, set, fmt)
    local r = row(descKey and OPT_H_DESC or OPT_H_SHORT)
    texts(r, titleKey, descKey, 250)
    local sl = Skin:CreateSlider(r, min, max, step, get(), press(function(v) set(v) end), 220, fmt or "%d")
    sl:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    track(function() sl:Set(get(), true) end)
    return sl, r
  end

  function ob:Dropdown(titleKey, descKey, itemsFn, get, set)
    local r = row(descKey and OPT_H_DESC or OPT_H_SHORT)
    texts(r, titleKey, descKey, 250)
    local dd = Skin:CreateDropdown(r, 220, itemsFn(), get(), press(function(v) set(v) end))
    dd:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    track(function() dd:SetItems(itemsFn()); dd:SetValue(get(), true) end)
    return dd, r
  end

  -- Sagda bir ya da birkac dugme: buttons = { { key, fn [, primary] }, ... }
  function ob:Buttons(titleKey, descKey, buttons)
    local r = row(descKey and OPT_H_DESC or OPT_H_SHORT)
    local list, w = {}, 0
    for i = #buttons, 1, -1 do
      local b = buttons[i]
      local btn = Skin:CreateButton(r, "", 130, 22, b[3])
      if #list == 0 then btn:SetPoint("RIGHT", r, "RIGHT", -12, 0) else btn:SetPoint("RIGHT", list[#list], "LEFT", -6, 0) end
      T(btn, b[1])
      btn:SetScript("OnClick", press(b[2]))
      list[#list + 1] = btn
      w = w + 136
    end
    texts(r, titleKey, descKey, w + 16)
    -- tek dugme basligiyla ayni adi tasiyorsa ("Reset position" / "Reset position") baslik yazilmaz
    if #buttons == 1 and buttons[1][1] == titleKey then r.title:Hide() end
    return list, r
  end

  -- Ozel kontrol: build(r) sagdaki kontrolu kurar, genislik soldaki metinlere birakilan payi belirler.
  function ob:Custom(titleKey, descKey, width, build)
    local r = row(descKey and OPT_H_DESC or OPT_H_SHORT)
    texts(r, titleKey, descKey, width + 24)
    build(r)
    return r
  end

  -- Basliksiz serbest kart (onizleme vb.)
  function ob:Block(h)
    return row(h)
  end
  return ob
end

local function optionList(page)
  local area = Skin:CreateScrollArea(page, BODY_W, BODY_H)
  area:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
  area:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
  local ob = newBuilder(area.content, {})
  ob.area = area
  ob.onGrow = function() if ob.finished then area:SetContentHeight(ob.y + 10) end end

  function ob:Finish(extra)
    self.finished = true
    area:SetContentHeight(self.y + 10)
    page.refresh = function()
      for _, fn in ipairs(self.refreshers) do ns.SafeCall(fn) end
      if extra then ns.SafeCall(extra) end
    end
  end
  return ob
end

Settings.OptionList = optionList   -- diger sayfalar (Keys...) ayni satir duzenini kullanir


-- Ozellik sayfalari (Route, Helpers): her ozellik bir acilir bolum, basliginda modulun acma/kapama anahtari.
-- Ayari olmayan ozellikler sayfanin sonunda iki sutun anahtar olarak durur.
local STYLE_NAMES = { ["3D"] = "3D", Chevron = "Chevron", Dart = "Dart", Needle = "Needle" }
local SWATCHES = {
  { 0.86, 0.62, 0.20 }, { 1, 1, 1 }, { 0.30, 0.85, 0.50 }, { 0.35, 0.65, 0.95 },
  { 0.90, 0.32, 0.32 }, { 0.72, 0.52, 0.92 }, { 0.30, 0.78, 0.78 }, { 0.95, 0.85, 0.30 },
}
local TEXT_SWATCHES = {
  { 1, 0.82, 0 }, { 1, 1, 1 }, { 0.86, 0.62, 0.20 }, { 0.30, 0.85, 0.50 },
  { 0.35, 0.65, 0.95 }, { 0.90, 0.32, 0.32 }, { 0.72, 0.52, 0.92 }, { 0.70, 0.70, 0.70 },
}

-- Ozellik govdeleri: body(s, page). s bolumun kurucusu; page sayfa cercevesi (testler icin alanlar).
local function windowBody(s, page)
  local W = ns.Window
  local function applyWindow() W:ApplyPosition(); W:Update() end
  local lock = s:Switch("Lock position", "Stops the panel from being dragged by accident.", function() return W.db.locked end, function(v) W.db.locked = v end)
  local scale = s:Slider("Scale", "Size of the panel.", 0.5, 2, 0.1, function() return W.db.scale end, function(v) W.db.scale = v; applyWindow() end, "%.1f")
  page.controls = { { mod = W, lock = lock, slider = scale } }
  page.alpha = s:Slider("Opacity", "Background transparency. Texts stay fully readable.", 0.2, 1, 0.05,
    function() return W.db.alpha or 0.95 end, function(v) W.db.alpha = v; W:ApplyAlpha(); W:Update() end, "%.2f")
  page.zoneSw = s:Switch("Zone info (herbs, ore, dungeons)", "Adds a small section about the zone you are in under your quest.",
    function() return W.db.zoneInfo end, function(v) W.db.zoneInfo = v; W:Update() end)
  page.tabsSw = s:Switch("Guide tabs", "Keeps several guides open as tabs at the top of the panel (for example leveling and a dungeon guide). Each keeps its own place. Off: a new guide replaces the current one.",
    function() return W.db.guideTabs ~= false end, function(v) W.db.guideTabs = v; W:Update() end)
  s:Buttons("Reset position", "Moves the panel back to its default place and size.", {
    { "Reset position", function()
      local d = W.defaults
      W.db.point, W.db.relPoint, W.db.x, W.db.y, W.db.scale = d.point, d.relPoint, d.x, d.y, d.scale
      W.db.hidden = false
      applyWindow()
      page.refresh()
    end },
  })
end

-- Adim penceresi, ileri ayarlar: alttaki XP ve altin cubuklari
local function windowAdvanced(s, page)
  local W = ns.Window
  page.xpBarSw = s:Switch("XP bar", "A bar above the guide progress with your XP, rested XP and XP per hour.",
    function() return W.db.xpBar ~= false end, function(v) W.db.xpBar = v; W:Update() end)
  page.goldBarSw = s:Switch("Gold bar", "A bar with your gold toward the next riding goal and gold per hour.",
    function() return W.db.goldBar ~= false end, function(v) W.db.goldBar = v; W:Update() end)
end

local function arrowBody(s, page)
  local Nav = ns.Nav
  local db = Nav.db
  -- canli onizleme: ok ortada doner
  local card = s:Block(150)
  local preview = card:CreateTexture(nil, "ARTWORK")
  preview:SetPoint("CENTER", card, "CENTER", 0, 18)
  local pdist = label(card, 14, C.text, "CENTER")
  pdist:SetPoint("TOP", preview, "BOTTOM", 0, -8)
  local plabel = label(card, 11, C.textDim, "CENTER")
  plabel:SetPoint("TOP", pdist, "BOTTOM", 0, -4)
  plabel:SetPoint("LEFT", card, "LEFT", 12, 0)
  plabel:SetPoint("RIGHT", card, "RIGHT", -12, 0)
  T(plabel, "Complete quest: %s", function(fs, v) fs:SetText(v:format("Cutting Teeth")) end)
  page.preview = preview
  preview._skinFixed, pdist._skinFixed, plabel._skinFixed = true, true, true
  local function refreshPreview()
    local size = math.min(db.size or 64, 90)
    preview:SetTexture(Nav:StylePath(db.style))
    preview:SetSize(size, size)
    local c = db.color or SWATCHES[1]
    preview:SetVertexColor(c[1], c[2], c[3])
    preview:SetAlpha(db.alpha or 1)
    Skin:SetFont(pdist, db.textSize or 14, "OUTLINE")
    local dc, lc = db.distColor or TEXT_SWATCHES[1], db.labelColor or TEXT_SWATCHES[2]
    pdist:SetTextColor(dc[1], dc[2], dc[3])
    plabel:SetTextColor(lc[1], lc[2], lc[3])
    pdist:SetText("120 yd")
    if db.showDistance then pdist:Show() else pdist:Hide() end
    if db.showLabel then plabel:Show() else plabel:Hide() end
  end
  page.refreshPreview = refreshPreview
  local angle = 0
  card:SetScript("OnUpdate", function(_, elapsed)
    angle = (angle + elapsed * 0.9) % (math.pi * 2)
    Nav.SetHeading(preview, db.style, angle)
  end)
  local function apply() Nav:ApplyStyle(); refreshPreview() end

  s:Switch("Lock position", "Stops the arrow from being dragged by accident.", function() return db.locked end, function(v) db.locked = v end)
  local function styleItems()
    local items = {}
    for _, name in ipairs(Nav.styles) do items[#items + 1] = { value = name, text = L[STYLE_NAMES[name] or name] } end
    return items
  end
  s:Dropdown("Style", nil, styleItems, function() return db.style end, function(v) db.style = v; apply() end)
  s:Slider("Size", nil, 24, 160, 2, function() return db.size end, function(v) db.size = v; apply() end, "%d")
  s:Slider("Opacity", nil, 0.2, 1, 0.05, function() return db.alpha end, function(v) db.alpha = v; apply() end, "%.2f")
  s:Slider("Scale", "Size of the whole arrow, including its texts.", 0.5, 2, 0.1, function() return db.scale end,
    function(v) db.scale = v; Nav:ApplyPosition() end, "%.1f")
  s:Slider("Text size", nil, 9, 24, 1, function() return db.textSize end, function(v) db.textSize = v; apply() end, "%d")
  page.colors = {}
  local function arrowColor(titleKey, field, default)
    s:Custom(titleKey, nil, 20, function(r)
      local btn = Skin:CreateColorButton(r, function() return db[field] or default end, press(function(c)
        db[field] = { c[1], c[2], c[3] }; apply()
      end))
      btn:SetPoint("RIGHT", r, "RIGHT", -12, 0)
      page.colors[field] = btn
    end)
  end
  arrowColor("Arrow colour", "color", SWATCHES[1])
  arrowColor("Distance colour", "distColor", TEXT_SWATCHES[1])
  arrowColor("Text colour", "labelColor", TEXT_SWATCHES[2])
  s:Switch("Show distance", nil, function() return db.showDistance end, function(v) db.showDistance = v; apply() end)
  s:Switch("Show step text", nil, function() return db.showLabel end, function(v) db.showLabel = v; apply() end)
  s:Switch("Turn green on arrival", "The arrow turns green when you reach the target.", function() return db.arriveColor end,
    function(v) db.arriveColor = v; apply() end)
  s:Buttons("Reset position", "Moves the arrow back to its default place and size.", {
    { "Reset position", function()
      local d = Nav.defaults
      db.point, db.relPoint, db.x, db.y, db.scale = d.point, d.relPoint, d.x, d.y, d.scale
      db.hidden = false
      Nav:ApplyPosition()
      Nav:Update(true)
      page.refresh()
    end },
  })
end

local function pinsBody(s, page)
  page.pins = {}
  local PIN = {
    { "minimap", "Minimap pin", "Shows the next step on the minimap." },
    { "worldmap", "World map pin", "Shows the next step on the world map." },
    { "trail", "Trail to target", "Draws dots from you to the target on the minimap." },
  }
  for _, e in ipairs(PIN) do
    local flag = e[1]
    page.pins[flag] = s:Switch(e[2], e[3], function() return ns.Pins.db[flag] end, function(v) ns.Pins.db[flag] = v; ns.Pins:Refresh() end)
  end
  local PD = ns.Pins.db
  s:Switch("Fade trail", "Dots get brighter and bigger towards the target.", function() return PD.fade ~= false end,
    function(v) PD.fade = v; ns.Pins:Refresh() end)
  s:Slider("Trail dot size", "Size of the trail dots.", 3, 10, 1, function() return PD.dotSize or 5 end,
    function(v) PD.dotSize = v; ns.Pins:Refresh() end, "%d")
  s:Slider("Trail spacing", "Distance between the trail dots.", 6, 24, 1, function() return PD.spacing or 12 end,
    function(v) PD.spacing = v; ns.Pins:Refresh() end, "%d")
  s:Custom("Trail colour", "Colour of the trail and the target pin.", 20 + 8 + 90, function(r)
    local def = Skin:CreateButton(r, "", 90, 20)
    def:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    T(def, "Theme colour")
    page.trailColor = Skin:CreateColorButton(r, function() return PD.trailColor or C.accent end, press(function(c)
      PD.trailColor = { c[1], c[2], c[3] }; ns.Pins:Refresh()
    end))
    page.trailColor:SetPoint("RIGHT", def, "LEFT", -8, 0)
    def:SetScript("OnClick", press(function() PD.trailColor = nil; ns.Pins:Refresh(); page.trailColor:Refresh() end))
  end)
end

local function revealBody(s, page)
  local R = ns.MapReveal
  local RD = R.db
  local DEFAULT_TINT = { 0.55, 0.65, 0.85 }
  s:Switch("Tint unexplored areas", "Unexplored areas get a colour tone, so you can still see where you have not been.",
    function() return RD.tint ~= false end, function(v) RD.tint = v; R:Refresh() end)
  s:Slider("Unexplored opacity", "How strongly unexplored areas are drawn on the map.", 20, 100, 5,
    function() return math.floor((RD.alpha or 1) * 100 + 0.5) end, function(v) RD.alpha = v / 100; R:Refresh() end, "%d%%")
  s:Custom("Tint colour", "Colour tone of unexplored areas.", 20 + 8 + 90, function(r)
    local def = Skin:CreateButton(r, "", 90, 20)
    def:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    T(def, "Default")
    page.revealColor = Skin:CreateColorButton(r, function() return RD.color or DEFAULT_TINT end, press(function(c)
      RD.color = { c[1], c[2], c[3] }; R:Refresh()
    end))
    page.revealColor:SetPoint("RIGHT", def, "LEFT", -8, 0)
    def:SetScript("OnClick", press(function()
      RD.color = { DEFAULT_TINT[1], DEFAULT_TINT[2], DEFAULT_TINT[3] }; R:Refresh(); page.revealColor:Refresh()
    end))
  end)
end

-- Ozellik listesi (tek kaynak): modul, baslik, aciklama, sekme, govde (yoksa yalniz anahtar).
-- Sira sayfadaki siradir. Govdedeki sw/sl yardimcilari sayfa uzerinde page.switches'a kaydeder.
local function sw(s, page, titleKey, descKey, db, field)
  local x = s:Switch(titleKey, descKey, function() return db[field] end, function(v) db[field] = v end)
  page.switches[#page.switches + 1] = { sw = x, db = db, field = field }
  return x
end
local function sl(s, page, titleKey, descKey, db, field, min, max, step, fmt)
  local x = s:Slider(titleKey, descKey, min, max, step, function() return db[field] end, function(v) db[field] = v end, fmt)
  page.switches[#page.switches + 1] = { slider = x, db = db, field = field }
  return x
end

local FEATURES = {
  -- onSwitch: tek anahtar eski "Show ..." ayarini da kapsar (acilinca /wf ile gizlenmis pencere de gorunur)
  { "Window", "Step window", "The compact route panel with your active quest.", group = "route", body = windowBody,
    advanced = windowAdvanced,
    onSwitch = function(v) if v then ns.Window.db.hidden = false; ns.Window:ApplyPosition(); ns.Window:Update() end end },
  { "Nav", "Direction arrow", "An arrow on screen that points to your next step.", group = "route", body = arrowBody,
    onSwitch = function(v) if v then ns.Nav.db.hidden = false; ns.Nav:Update(true) end end },
  { "Pins", "Map pins", "Marks the next step on the world map and the minimap.", group = "route", body = pinsBody },
  { "GuideBrowser", "Guide browser", "A page with your guides by level, suggested guides, class quests, professions, and recent and favorite guides.", group = "route" },
  { "MapReveal", "Reveal map", "Shows the areas you have not explored yet on the world map.", group = "route", body = revealBody },
  { "Rares", "Rare recorder", "Remembers where you see rare creatures and marks them on your maps (/wf rares).", group = "route",
    body = function(s, page)
      sw(s, page, "Tell me about a new rare", "Shows a notice the first time you see a rare.", ns.RareSpawns.db, "announce")
    end },
  { "MapMarkers", "Map markers", "Dungeon entrances, your class trainers, profession trainers, flight masters, rares and special hunter pets on the world map and the minimap.", group = "route",
    body = function(s, page)
      local MM = ns.MapMarkers
      local function sw(title, desc, key)   -- yerel: harita anahtari (ust sw'yi golgeler)
        s:Switch(title, desc, function() return MM.db.world[key] end, function(v) MM:SetShown("world", key, v) end)
      end
      sw("Dungeons on the map", "Dungeon entrances, coloured by how well they fit your level.", "dungeons")
      sw("Class trainers on the map", "The trainers of your class.", "classTrainers")
      sw("Profession trainers on the map", "Profession trainers of your faction.", "profTrainers")
      sw("Flight masters on the map", "Flight points of your faction.", "flights")
      sw("Rares on the map", "Known rare spawn spots; the ones you have seen say so.", "rares")
      s:Switch("Quests on the map", "! marks quests you can take now, ? marks quests ready to turn in. Gold: in your guide, blue: not in it.",
        function() return MM.db.world.quests end, function(v) MM.db.world.turnins = v; MM:SetShown("world", "quests", v) end)
    end,
    advanced = function(s, page)
      local MM = ns.MapMarkers
      s:Switch("Button on the world map", "An Arcanis button on the world map: tick each kind of marker for the map and the minimap.",
        function() return MM.db.button end, function(v) MM.db.button = v; MM:RefreshAll() end)
      s:Switch("Boats and portals on the map", "Docks with where their boats and zeppelins go and the next departure, the Deeprun Tram and portals.",
        function() return MM.db.world.transport end, function(v) MM:SetShown("world", "transport", v) end)
      s:Switch("Zone borders on the map", "Signposts where a road leads into the next zone, with its name and level range. Click one to open that zone.",
        function() return MM.db.world.gates end, function(v) MM:SetShown("world", "gates", v) end)
      s:Switch("Zone level range", "Shows the level range of the zone at the top of the world map.",
        function() return MM.db.zoneLevel end, function(v) MM.db.zoneLevel = v; MM:RefreshWorld() end)
      s:Switch("Quests in NPC tooltips", "When you point at an NPC, lists the quests it has for you now and the ones you can turn in to it.",
        function() return MM.db.npcTooltip end, function(v) MM.db.npcTooltip = v end)
      local hunter = (P.PlayerInfo() or {}).class == "HUNTER"   -- hunter petleri ayarlari yalniz hunter'da
      if hunter then
        s:Switch("Hunter pets on the map", "Rare and fast-attacking beasts you can tame (hunters only).",
          function() return MM:Shown("world", "pets") end, function(v) MM:SetShown("world", "pets", v) end)
      end
      local function sw(title, desc, key)   -- yerel: harita anahtari (ust sw'yi golgeler)
        if key == "pets" and not hunter then return end
        s:Switch(title, desc, function() return MM:Shown("mini", key) end, function(v) MM:SetShown("mini", key, v) end)
      end
      sw("Dungeons on the minimap", "Nearby dungeon entrances on the minimap.", "dungeons")
      sw("Class trainers on the minimap", "Nearby trainers of your class on the minimap.", "classTrainers")
      sw("Profession trainers on the minimap", "Nearby profession trainers on the minimap.", "profTrainers")
      sw("Flight masters on the minimap", "Nearby flight points on the minimap.", "flights")
      sw("Rares on the minimap", "Nearby rare spawn spots on the minimap.", "rares")
      sw("Hunter pets on the minimap", "Nearby rare and fast-attacking beasts you can tame (hunters only).", "pets")
      sw("Quest givers on the minimap", "Nearby quests you can take now.", "quests")
      sw("Quest turn-ins on the minimap", "Nearby places to turn in finished quests.", "turnins")
      sw("Boats and portals on the minimap", "Nearby docks, the tram and portals.", "transport")
      sw("Zone borders on the minimap", "Nearby roads into the next zone.", "gates")
      if hunter then s:Switch("Pet details in the tooltip", "Hunters only: what a special pet teaches, its attack speed and its family's strengths, diet and abilities.",
        function() return MM.db.petDetails end, function(v) MM.db.petDetails = v end) end
      s:Switch("Only my professions", "Profession trainer markers show only the professions you know.",
        function() return MM.db.myProfs end, function(v) MM.db.myProfs = v; MM:Invalidate(); MM:RefreshAll() end)
    end },
  { "QuestAuto", "Quest automation", "Accepts and turns in quests for you. Hold Shift at an NPC to pause automation.", group = "quests",
    body = function(s, page)
      local Q = ns.QuestAuto
      page.modeDD = s:Dropdown("Automation", "Accepts and turns in quests: off, only the quests of your current guide, or every quest.", function()
        return {
          { value = "off", text = L["Off"] },
          { value = "guide", text = L["Guide quests only"] },
          { value = "all", text = L["All quests"] },
        }
      end, function() return Q.db.mode end, function(v) Q.db.mode = v end)
      page.rewardDD = s:Dropdown("Reward choice", "How the reward is chosen: best upgrade for your class, vendor price or auction value.", function()
        return {
          { value = "upgrade", text = L["Best upgrade for my class"] },
          { value = "vendor", text = L["Highest vendor price"] },
          { value = "auction", text = L["Highest auction value (ArcanisVault)"] },
        }
      end, function() return Q.db.rewardMode end, function(v) Q.db.rewardMode = v end)
      page.rewardSwitch = sw(s, page, "Choose the reward for me",
        "When a quest offers several rewards, takes the best one for your class, spec and level. The recommended reward is always marked.",
        Q.db, "rewardBest")
      sw(s, page, "Mark the recommended reward", "Marks the best reward in the quest window, also when you take the quest; an arrow shows an upgrade.", Q.db, "markRewards")
    end },
  -- Rehber motorunun davranisi: motor kapatilamaz (anahtarsiz satir, yalniz ayar)
  { "Engine", "Guide behaviour", "How the guide picks and orders steps.", group = "quests", noSwitch = true,
    body = function(s, page)
      sw(s, page, "Skip low-level quests", "Skips guide steps of grey quests you have not taken yet.", ns.Engine.db, "skipGray")
      sw(s, page, "Strict guide order", "The guide always shows the first unfinished step you can do now, counted from the start of the guide. It never moves the step or the arrow to other work. Steps you skip with Shift + click stay skipped.", ns.Engine.db, "strict")
      sw(s, page, "Pin guide order", "Never changes the step order automatically, also not for a forgotten turn-in nearby.", ns.Engine.db, "pinOrder")
      sw(s, page, "Class quest help", "Reminds you of class quests you can take, and guides the arrow for class quests in your log.", ns.Engine.db, "classQuests")
      sw(s, page, "Add missing quest chains", "When you skipped an earlier guide, adds its quests that quests here need. Off: those quests wait.", ns.Engine.db, "feed")
      sw(s, page, "Dungeon quests in leveling guides", "Shows the guide's steps for quests done inside a dungeon. Off: the guide does not send you to them unless the quest is already in your log. Dungeon guides in the journal list them too.", ns.Engine.db, "dungeonSteps")
      sw(s, page, "Group quests", "Shows the guide's steps for quests meant for a group (strong enemies). Off: the guide does not send you to them unless the quest is already in your log.", ns.Engine.db, "groupSteps")
    end,
    advanced = function(s, page)
      sw(s, page, "Profession camping reminder", "Reminds you of the camping quest for a profession you know, without changing the route.", ns.Engine.db, "campReminder")
      sw(s, page, "Campfire sit button", "When a campfire buff is on you, shows a campfire icon beside the step window that sits you down: camp buffs need you to sit by the fire.", ns.Engine.db, "campSit")
    end },
  { "QuestItem", "Quest item button", "Shows a button for the item your quest needs. Bind a key in Key Bindings > Arcanis Path or with /wf itemkey.", group = "quests",
    onSwitch = function(v) ns.QuestItem.db.enabled = v; if v then ns.QuestItem:Update() end end,
    body = function(s, page)
      page.itemDockSw = s:Switch("Attach quest items to the step window", "The quest item panel sits on the right of the step window. Off: drag it anywhere by its top edge; drop it next to the window to attach it again.",
        function() return ns.QuestItem.db.docked ~= false end, function(v) ns.QuestItem.db.docked = v; ns.QuestItem:Place() end)
    end },
  { "ItemNeeds", "Quest item hints", "Shows in item tooltips which quests still need the item, and keeps it from being sold.", group = "quests",
    body = function(s, page)
      sw(s, page, "Quest hints in item tooltips", "Names the quests that still need an item, or the quest it starts.", ns.ItemNeeds.db, "tooltip")
      sw(s, page, "Never sell quest items", "Items an open quest still needs are kept when selling junk.", ns.ItemNeeds.db, "protect")
      sw(s, page, "Upgrade line in item tooltips", "Compares wearable items with what you wear, using your spec's stat weights.", ns.ItemNeeds.db, "upgradeTip")
      page.bagArrowSw = s:Switch("Upgrade arrow on bag items", "A green arrow on bag items that are better than what you wear.",
        function() return ns.ItemNeeds.db.bagArrow ~= false end,
        function(v) ns.ItemNeeds.db.bagArrow = v; if ns.GearMarks then ns.GearMarks:Refresh() end end)
      sw(s, page, "Marks on loot rolls", "On the Need / Greed window: an arrow on upgrades and a star on items you track in the Dungeon journal.", ns.ItemNeeds.db, "rollMarks")
    end,
    advanced = function(s, page)
      sw(s, page, "Quest reward upgrades", "Remembers the rewards of quests you open and shows which coming quests give you an upgrade (Class Codex and Mentor).", ns.ItemNeeds.db, "questUps")
      sw(s, page, "Set bonuses", "Counts the set bonus an item completes or breaks in its upgrade value, and shows the set pieces you wear in its tooltip.", ns.ItemNeeds.db, "setBonus")
    end },
  { "Travel", "Travel helper", "Completes flight and hearthstone steps and reminds you where to fly.", group = "route",
    body = function(s, page)
      sw(s, page, "Flight map reminder", "Tells you which flight to take when the flight map opens.", ns.Travel.db, "remind")
      sw(s, page, "Flight times on the flight map", "Pointing at a flight point shows how long the flight takes (~ when it is not measured yet).", ns.Travel.db, "flightTimes")
      sw(s, page, "Open the flight map at once", "Talking to a flight master who has no quest for you opens the flight map directly. Hold Shift to talk instead.", ns.Travel.db, "autoTaxi")
    end },
  { "Transport", "Corpse, boats and route warnings", "Points the arrow to your corpse, times boats and zeppelins, and warns when a route crosses danger.", group = "route",
    body = function(s, page)
      sw(s, page, "Arrow to your corpse", "While you are a ghost the arrow points to your body; the guide target comes back after.", ns.Transport.db, "corpse")
      sw(s, page, "Boat and zeppelin times", "Learns each line's timetable the first time you ride it.", ns.Transport.db, "boats")
      sw(s, page, "Route warnings", "Warns when the way to the arrow crosses a zone far above your level or an enemy town.", ns.Transport.db, "hazards")
    end },
  { "Brain", "Smart suggestions", "Suggests what to do together: nearby turn-ins, quests at the same NPC and objectives in the same area. The guide order does not change.", group = "quests",
    body = function(s, page)
      page.brainDD = s:Dropdown("Route changes", "Suggestions only: shows what to do together. Reorder the route: after a step is done, does a nearby turn-in, objective or accept first, then returns to the route.", function()
        return {
          { value = "suggest", text = L["Suggestions only"] },
          { value = "full", text = L["Reorder the route"] },
        }
      end, function() return ns.Brain.db.mode end, function(v)
        local was = ns.Brain.db.mode
        ns.Brain.db.mode = v
        if v == was then return end
        -- secimin ne degistirdigi ve riski: oyuncu neden okun sirayi biraktigini (ya da birakmadigini) bilsin
        local title = v == "full" and L["Reorder the route"] or L["Suggestions only"]
        local note = v == "full"
          and L["The arrow may leave the guide order for a nearby turn-in, objective or accept, then come back. Risk: it can switch target while you walk; use Pause or Prev if you want the plain order."]
          or L["The arrow keeps the guide order; nearby jobs only show as Next. Risk: you may walk past work a few yards away and come back for it later. Click the Next line to go there."]
        ns:Print(title .. ": " .. note)
        if ns.Toast then ns.Toast:Show(title, "warn", note, nil, { key = "routemode" }) end
      end)
      sw(s, page, "Missed quest alert", "Flashes a notice on the Dynamic Hub when you pass the giver of a quest the guide wanted you to take.", ns.Brain.db, "missedAlert")
      sw(s, page, "Planner", "Weighs the suggestions by time and shows the one that saves the most as Next, only when it clearly beats going to the guide step first.", ns.Planner.db, "enabled")
    end },
  { "Leveling", "Leveling stats", "XP per hour, time to next level and how long each level took.", group = "route",
    body = function(s, page)
      sw(s, page, "Show XP per hour", "Shows XP per hour and time to level in the step window.", ns.Leveling.db, "show")
      sw(s, page, "Show quest XP", "Shows on turn-in steps how much XP the quest gives at your level (Forever beta values).", ns.Leveling.db, "questXP")
      sw(s, page, "Quest XP on the XP bars", "A lighter part of the XP bar (step window and Dynamic Hub) shows the XP of quests ready to turn in; point at the bar for the list.", ns.Leveling.db, "readyXP")
    end },
  { "Build", "Talent tips", "Suggests your next talent from the ArcanisOracle leveling build.", group = "class",
    body = function(s, page) sw(s, page, "Talent point tips", "When you level up, names the next talent of your build.", ns.Build.db, "tips") end },

  { "Vendor", "Vendor helper", "Sells grey items and repairs your gear at merchants.", group = "gold",
    body = function(s, page)
      local V = ns.Vendor
      sw(s, page, "Sell gray items", "Sells all grey (worthless) items automatically.", V.db, "sellGrey")
      sw(s, page, "Sell my junk list", "Also sells the items on your junk list (/wf junk, then shift-click an item). Items a quest needs are kept.", V.db, "sellJunk")
      sw(s, page, "Repair automatically", "Repairs all your gear when the merchant can repair.", V.db, "repair")
      sw(s, page, "Use guild funds when possible", "Pays repairs from the guild bank if you are allowed to.", V.db, "guildRepair")
      sw(s, page, "Report in chat", "Writes what was sold and what the repair cost.", V.db, "report")
    end },
  { "Alerts", "Alerts", "Short notices: full bags, low durability, low health, danger.", group = "hub",
    body = function(s, page)
      local A = ns.Alerts
      -- butun bildirimler icin tek duzey (UI/Toast.lua ns.NoticeAllowed); Alerts kapaliyken de gecerli
      local dd = s:Dropdown("Notification level", "Few: only warnings and notices you can click. Normal: also useful news. Many: every tip, zone and level note. Custom: you choose each kind below.", function()
        return {
          { value = "few", text = L["Few"] }, { value = "normal", text = L["Normal"] }, { value = "many", text = L["Many"] },
          { value = "custom", text = L["Custom"] },
        }
      end, function() return ns.db.noticeLevel or "normal" end, function(v) ns.db.noticeLevel = v end)
      -- Custom: tur basina anahtar (ns.NoticeAllowed); birini degistirmek duzeyi "custom" yapar
      local cs = s:Section("Custom notices", ns.db.noticeLevel == "custom",
        function() return L["Choose each kind of notice yourself. Changing one sets the level to Custom."] end)
      local function toggle(titleKey, cat)   -- adi locale_check icin "toggle"
        cs:Switch(titleKey, nil, function()
          local c = ns.db.noticeCustom
          return not (c and c[cat] == false)
        end, function(v)
          ns.db.noticeCustom = ns.db.noticeCustom or {}
          ns.db.noticeCustom[cat] = v and nil or false
          ns.db.noticeLevel = "custom"
          if dd and dd.SetValue then dd:SetValue("custom", true) end
        end)
      end
      toggle("Warnings", "warn")
      toggle("Gear upgrades", "upgrade")
      toggle("Enemy players nearby", "enemy")
      toggle("Whispers", "whisper")
      toggle("New mail", "mail")
      toggle("Quest and route notices", "quest")
      toggle("Zone notices", "zone")
      toggle("Level and talent notices", "level")
      toggle("Mentor tips", "mentor")
      toggle("Profession notices", "profession")
      toggle("Dungeon notices", "dungeon")
      toggle("Travel notices", "travel")
      toggle("Rares found", "rare")
      toggle("Feature suggestions", "discover")
      toggle("Declined invites and duels", "social")
      sw(s, page, "Bags almost full", "Warns when few bag slots are left.", A.db, "bags")
      sw(s, page, "Low durability", "Warns when your gear needs repair.", A.db, "durability")
      sw(s, page, "Gear upgrades", "When an item you get is better than what you wear, says so on the Dynamic Hub. Click the notice to equip it.", A.db, "upgrades")
      sw(s, page, "Guide for the zone", "When you enter a zone or log in, suggests a guide for that zone that fits your level. Click the notice on the Dynamic Hub to start it.", A.db, "zoneGuide")
      sw(s, page, "New mail", "Tells you when mail arrives and who sent it.", A.db, "mail")
      sw(s, page, "Enemy players nearby", "When a player of the other faction shows up (name plate, target or mouse), the Dynamic Hub shows the class and level. Green: lower level, yellow: about yours, red: much higher or unknown (??).", A.db, "enemy")
    end,
    advanced = function(s, page)
      local A = ns.Alerts
      sl(s, page, "Free slots", "Warn at this many free slots.", A.db, "bagFree", 1, 12, 1)
      sl(s, page, "Below %", "Warn below this durability.", A.db, "durPct", 5, 50, 5)
      sw(s, page, "Zone alerts", "Tells you the zone when you enter it and if your next step is elsewhere.", A.db, "zone")
      sw(s, page, "Level-up tips", "Suggests a new guide when you outlevel the current one.", A.db, "levelUp")
      sw(s, page, "Low health warning", "Warns once in combat when your health gets low.", A.db, "lowHealth")
      sw(s, page, "Dangerous target warning", "Warns when you target an elite, a boss or a much higher level enemy.", A.db, "danger")
      s:Buttons("Test alert", "Shows two sample alerts.", { { "Test alert", function() SlashCmdList.ARCANIS("alerts test") end } })
      -- karsi taraftan oyuncu: tekrar suresi ve uc tehlike icin ayri ses
      sl(s, page, "Enemy repeat (min)", "The same enemy player is announced again only after this many minutes.", A.db, "enemyRepeat", 1, 15, 1)
      local function sounds()
        local names = { none = L["No sound"], ping = L["Ping"], bell = L["Bell"], warning = L["Warning"], alarm = L["Alarm"] }
        local out = {}
        for _, v in ipairs(A.ENEMY_SOUNDS) do out[#out + 1] = { value = v.value, text = names[v.value] or v.value } end
        return out
      end
      -- secince bir kez calar
      s:Dropdown("Sound: lower level enemy", "Played for a green enemy (3 or more levels below you).", sounds,
        function() return A.db.enemySoundLow end, function(v) A.db.enemySoundLow = v; A:PlayEnemySound("low") end)
      s:Dropdown("Sound: enemy near your level", "Played for a yellow enemy (within 2 levels of you).", sounds,
        function() return A.db.enemySoundEven end, function(v) A.db.enemySoundEven = v; A:PlayEnemySound("even") end)
      s:Dropdown("Sound: dangerous enemy", "Played for a red enemy (3 or more levels above you, or ??).", sounds,
        function() return A.db.enemySoundHigh end, function(v) A.db.enemySoundHigh = v; A:PlayEnemySound("high") end)
      s:Buttons("Test enemy alert", "Shows the three danger colours and plays the dangerous enemy sound.",
        { { "Test enemy alert", function() SlashCmdList.ARCANIS("alerts enemy") end } })
    end },
  { "ProfActivity", "Profession activity", "A cast bar on the Dynamic Hub while you gather, fish or craft, skill-up notices and a gathering session.", group = "gold",
    body = function(s, page)
      local PA = ns.ProfActivity
      sw(s, page, "Skill-up notices", "Shows each skill point and when you can learn the next rank from a trainer.", PA.db, "skillUps")
      sw(s, page, "Full bags while gathering", "Warns when a node or a catch no longer fits in your bags.", PA.db, "bagWarn")
      sw(s, page, "Lure running out", "Warns one minute before your fishing lure ends.", PA.db, "lureWarn")
      sw(s, page, "Profession cooldowns", "Tells you when Mooncloth, a transmute or the Salt Shaker is ready again.", PA.db, "cooldowns")
      sw(s, page, "Gathering tracking reminder", "Reminds you when Find Minerals or Find Herbs is off while a gathering guide step is active or you are gathering.", PA.db, "trackWarn")
      s:Buttons("Reset gathering session", "Starts the nodes, catches and gold per hour from zero.",
        { { "Reset gathering session", function() PA:ResetSession() end } })
    end },
  { "Farm", "Farm compass", "Remembers every spot where you gather, skin or fish, measures each farming session and marks your spots on the map. Share them on the Professions page.", group = "gold" },
  { "Prices", "Auction prices", "Prices from your auction addon or the Arcanis scan, in tooltips and on the Gold page.", group = "gold",
    body = function(s, page)
      local PR = ns.Prices
      page.priceSource = s:Dropdown("Price source", "Auto uses TSM, Auctionator, Auctioneer, ArcanisVault, the Arcanis scan, then the bundled list.",
        function() return PR:SourceItems() end, function() return PR.db.source or "auto" end, function(v) PR:SetSource(v) end)
      local TSM_KEYS = { "DBMarket", "DBMinBuyout", "DBRecent", "DBRegionMarketAvg", "DBRegionSaleAvg", "DBHistorical" }
      s:Dropdown("TSM price", "Which TradeSkillMaster price to use when TSM is the source.", function()
        local items = {}
        for _, k in ipairs(TSM_KEYS) do items[#items + 1] = { value = k, text = k } end
        return items
      end, function() return PR.db.tsmKey or "DBMarket" end, function(v) PR.db.tsmKey = v end)
      sw(s, page, "Price in item tooltips", "Adds the auction price from the chosen source to item tooltips.", PR.db, "tooltip")
      local scanBtn = s:Buttons("Arcanis scan", "Scans every auction at the auction house and saves prices (about every 15 minutes).", {
        { "Scan now", function() PR:StartScan() end, true },
      })[1]
      -- yalniz muzayede evindeyken (ve tarama surmuyorken) basilabilir
      local function scanState() scanBtn:SetEnabled(PR:AtAuctionHouse() and not PR.scanning) end
      scanState()
      ns:Listen("ARCANIS_PRICES_CHANGED", scanBtn, scanState)
    end },
  { "Bags", "Bag helper", "Finds junk in your bags.", group = "gold",
    body = function(s, page)
      s:Buttons("Scan bags", "Lists junk items in your bags in chat.", { { "Scan bags", function() SlashCmdList.ARCANIS("bags") end } })
      sw(s, page, "Help when bags are full", "When your bags are full or loot does not fit, offers your cheapest junk or plain item on the Dynamic Hub: click to sell it at a merchant, or to destroy it after you confirm. Quest items and items a quest needs are never offered.", ns.Bags.db, "fullHelper")
      s:Buttons("Clear junk list", "Empties your junk list (/wf junk lists it).", { { "Clear junk list", function() SlashCmdList.ARCANIS("junk clear") end } })
    end },
  { "AuctionPanel", "Auction House panel", "A panel next to the Auction House: scan, your sellable items with how fresh each price is, and posting at your own price.", group = "gold" },
  { "Mentor", "Mentor", "Advice on what to do next: quests nearby, talents, training, bags, gold.", group = "hub",
    body = function(s, page)
      -- kolay ama guclu esyalar (Helpers/EasyItems.lua): tam liste Mentor > Items sekmesinde, bu yalniz onerileri acar/kapatir
      sw(s, page, "Easy item tips", "Up to two easy, strong items for your level (bags, quest rewards, early weapons) in the Now list, and a short note when you level up. The full list is on Mentor > Items.", ns.Mentor.db, "easyItems")
      sw(s, page, "Pet ability teachers", "Hunters: when you target or see a beast that teaches a higher rank of an ability than your pet knows, says so once.", ns.Mentor.db, "petTeach")
    end },
  -- Dynamic Hub: ayarlari genis surukle-birak listeleri istedigi icin kendi sayfasinda (dislisi onu acar)
  { "Island", "Dynamic Hub", "The strip at the top of the screen: live info, notices and the hub with cards.", group = "hub", page = "island" },
  { "Discover", "Feature suggestions", "When a module you have turned off would help, suggests it once on the Dynamic Hub. Never in combat or in dungeons.", group = "hub" },
  { "Messenger", "Messages", "Whispers as conversations on the Dynamic Hub: click a whisper notice or the hub to read and reply, click a message to copy it.", group = "hub",
    body = function(s, page)
      local Ms = ns.Messenger
      -- fisilti bildirimi Messenger'in ayari: Alerts kapaliyken de calisir (Alerts aciksa bildirimi o gosterir)
      sw(s, page, "Whispers", "Shows whispers and Battle.net messages with the sender and the text.", Ms.db, "notify")
      sw(s, page, "Keep message history", "Saves whispers for this character between sessions. Off: only this session. Battle.net messages are never saved.", Ms.db, "history")
      s:Buttons("Delete all messages", "Removes every conversation of this character.", { { "Delete all messages", function() Ms:ClearAll() end } })
    end },
  { "Gold", "Gold tracker", "Gold this session, gold per hour, bag value and loot (ArcanisVault prices when installed).", group = "gold",
    body = function(s, page)
      sw(s, page, "Skill-up plan", "On Gold > Professions: what to craft up to the next rank and what to buy, from your known recipes.", ns.Gold.db, "skillPlan")
      sw(s, page, "Disenchant value", "On the sell list: what disenchanting an item would give and what that is worth, when you or another character of yours knows Enchanting.", ns.Gold.db, "deValue")
    end },
  { "Codex", "Class codex", "Stat priority, bag upgrades, talent builds, trainers, class quests and hunter pets for your class.", group = "class",
    body = function(s, page)
      sw(s, page, "Enchant suggestions", "On Class Codex > Character: the best stat enchant for each item you wear, for your spec.", ns.Codex.db, "enchants")
      sw(s, page, "Record reputation rewards", "At vendors that ask for reputation, remembers their items, listed by faction on Class Codex > Character.", ns.Codex.db, "repRecord")
    end },
  -- sinif egitimi (Helpers/Training.lua): kapatilamaz (egitmen listesi Mentor'un ve rehberin kaynagi), yalniz denetim ayari
  { "Training", "Class training", "What your class learns at each level, and spells on your action bars below your best rank.", group = "class", noSwitch = true,
    body = function(s, page)
      sw(s, page, "Low spell ranks", "After a trainer visit, says when action bar spells are below the best rank you know. Click the notice or use Class Codex > Trainers to update them.", ns.Training.db, "lowRank")
      s:Buttons("Check action bars", "Lists low ranks in chat.", { { "Check action bars", function() SlashCmdList.ARCANIS("ranks") end } })
    end },
  -- Rotasyon yardimcisi (Rotation/): ayar listesi kendi verisinden (Rotation/Options.lua, Options_Body)
  { "Rotation", "Rotation helper", "Shows your next spell, lights it on the action bar and marks the next talent.", group = "class",
    body = function(s) if ns.RF and ns.RF.Options_Body then ns.RF.Options_Body(s, true) end end,
    advanced = function(s) if ns.RF and ns.RF.Options_Body then ns.RF.Options_Body(s, false) end end,
    reset = function() if ns.RF and ns.RF.ResetAll then ns.RF.ResetAll() end end,
    -- ayarlar acikken ikonlar pencerenin ustunde, yer tutucularla: her degisiklik aninda gorulur
    onOpen = function() if ns.RF and ns.RF.UI_SetPreview then ns.RF.UI_SetPreview(true) end end,
    onClose = function() if ns.RF and ns.RF.UI_SetPreview then ns.RF.UI_SetPreview(false) end end },
  { "Journal", "Dungeon journal", "Dungeon suggestions, loot and quests for every dungeon.", group = "dungeons",
    body = function(s, page)
      sw(s, page, "Return to my guide when done", "When a dungeon quest guide is finished, the guide you left starts again.", ns.Journal.db, "autoReturn")
      sw(s, page, "Learn boss types", "When you target a dungeon boss, remembers its creature type (Undead, Beast...) and shows it next to the boss in the journal.", ns.Journal.db, "bossTypes")
    end },
  { "ZoneInfo", "Zone info", "Herbs, ore and dungeons of the zone you are in.", group = "dungeons" },
  { "Keys", "Keybinds and macros", "Key bindings and ready-made macros for Arcanis Path.", group = "class" },
  { "Recorder", "Route recorder", "Records your quests while you play and turns them into a guide (/wf rec).", group = "dev" },
  { "QuestScan", "Quest scan", "A page that asks the server which quest IDs exist (developer tool).", group = "dev" },
  { "Suite", "Arcanis suite links", "Uses ArcanisVault prices and ArcanisBinder macros when they are installed.", group = "dev" },
  -- isim levhasinda gorev isareti (Helpers/QuestPlates.lua)
  { "QuestPlates", "Quest marks on name plates", "A small sword next to the name plate of creatures your quests ask you to kill, read from the game's own tooltip.", group = "quests",
    body = function(s, page)
      sw(s, page, "Show progress", "Writes the count next to the mark, for example 3/10.", ns.QuestPlates.db, "progress")
    end },
  -- zindanda gorev paylasimi (Helpers/QuestShare.lua)
  { "QuestShare", "Dungeon quest sharing", "In a party inside or near a dungeon, lists your quests for it that your group lacks and shares them with one click.", group = "dungeons",
    body = function(s, page)
      sw(s, page, "Offer to share", "Shows a notice on the Dynamic Hub when party members lack your quests for the dungeon.", ns.QuestShare.db, "notify")
      s:Buttons("Share dungeon quests now", "Shares every quest you have for this dungeon (also /wf share).",
        { { "Share now", function() ns.QuestShare:ShareAll() end } })
    end },
  -- buff hatirlatici (Helpers/Buffs.lua): sinif varsayilanlari tek tek kapatilir, kendi buyuler /wf buffs add
  { "Buffs", "Buff reminder", "Out of combat, shows an icon when one of your own buffs is missing or about to end. Click the icon to cast it.", group = "class",
    body = function(s, page)
      local B = ns.Buffs
      sw(s, page, "Quiet in cities and inns", "No reminder while you rest in an inn or a capital city.", B.db, "quietResting")
      -- sinifin varsayilan buff'lari: ad oyunun dilinde (buyu adi), kapali olan hatirlatilmaz
      for _, g in ipairs(B.CLASS[P.PlayerClassToken() or ""] or {}) do
        local name = P.SpellName(g[1]) or ("#" .. g[1])
        s:Switch(name, nil, function() return not B.char.off[g[1]] end,
          function(v) B.char.off[g[1]] = (not v) or nil; B:Queue() end)
      end
      s:Buttons("Your own buffs", "Add more with /wf buffs add <spell ID or shift-clicked spell>; /wf buffs lists them.",
        { { "List my buffs", function() SlashCmdList.ARCANIS("buffs") end } })
    end },
  -- kucuk kolayliklar (Helpers/QoL.lua): her anahtar kapaninca oyunun onceki ayari geri gelir
  { "QoL", "Small conveniences", "Game settings made easy: fewer red error messages, farther camera, auto loot, free bag slots, item compare. Each switch puts your old setting back when you turn it off.", group = "hub",
    body = function(s, page)
      local Q = ns.QoL
      local function get(key) return function() return Q.db[key] end end
      local function set(key) return function(v) Q:Set(key, v) end end
      s:Switch("Hide error spam", "Hides the red messages that repeat in combat (not ready yet, not enough energy, no target). Other errors stay.", get("hideErrors"), set("hideErrors"))
      s:Switch("Farther camera", "Lets you zoom the camera out further.", get("camera"), set("camera"))
      s:Switch("Auto loot", "Loots without holding the auto loot key.", get("autoLoot"), set("autoLoot"))
      s:Switch("Faster looting", "With auto loot, takes everything the moment the loot window opens.", get("fastLoot"), set("fastLoot"))
      s:Switch("Free bag slots on the backpack", "Shows how many bag slots are free on the backpack button.", get("bagSlots"), set("bagSlots"))
      s:Switch("Compare items with Shift", "Item tooltips compare with your gear only while you hold Shift.", get("compareShift"), set("compareShift"))
    end },
  -- oyun arayuzu: pencere tasima, ipucu, sohbet (Helpers/UITweaks.lua)
  { "UITweaks", "Interface tweaks", "Move Blizzard windows, tooltips at the mouse, and helpers for the chat windows. Each part has its own switch.", group = "hub",
    body = function(s, page)
      local U = ns.UITweaks
      local function get(key) return function() return U.db[key] end end
      local function set(key) return function(v) U:Set(key, v) end end
      s:Switch("Move Blizzard windows", "Drag the character, spellbook, quest log, merchant and other windows. Ctrl + mouse wheel changes their size. Not in combat.", get("moveFrames"), set("moveFrames"))
      s:Switch("Tooltip at the mouse", "Tooltips appear next to the mouse instead of the corner of the screen.", get("tooltipMouse"), set("tooltipMouse"))
      s:Switch("Hide tooltips in combat", "No tooltips while you fight. Hold Shift to see them anyway.", get("tooltipCombat"), set("tooltipCombat"))
      s:Switch("Copy chat button", "A small button on each chat window shows its recent lines so you can copy them.", get("chatCopy"), set("chatCopy"))
      s:Switch("Clickable web links", "Web addresses in chat become links; click one to copy it.", get("chatUrls"), set("chatUrls"))
    end,
    advanced = function(s, page)
      local U = ns.UITweaks
      s:Switch("Fade idle chat", "Chat windows fade out when no new message comes in, and come back with the next message or when you point at them.", function() return U.db.chatFade end, function(v) U:Set("chatFade", v) end)
      s:Slider("Fade after", "Seconds without a new message before the chat fades.", 10, 120, 5, function() return U.db.chatFadeSecs end, function(v) U.db.chatFadeSecs = v end)
      s:Buttons("Window positions", "Forgets where you moved and how you sized the Blizzard windows.", { { "Reset positions", function() U:ResetFrames() end } })
    end },
  -- davet / duello suzgeci (Helpers/Social.lua)
  { "Social", "Invite and duel filter", "Declines group invites from strangers and duel requests for you. Friends, Battle.net friends and guild members can always invite you.", group = "hub",
    body = function(s, page)
      local So = ns.Social
      sw(s, page, "Decline invites from strangers", "Group invites from anyone who is not a friend or in your guild are declined.", So.db, "invites")
      sw(s, page, "Decline duels", "Every duel request is declined.", So.db, "duels")
      sw(s, page, "Tell me", "A short notice each time something is declined.", So.db, "notify")
      s:Custom("Declined so far", nil, 120, function(r)
        local t = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        Skin:SetFont(t, 11, "")
        t:SetTextColor(unpack(C.textDim))
        t:SetPoint("RIGHT", r, "RIGHT", -12, 0)
        local function upd() t:SetText(L["%d invites, %d duels"]:format(So.db.blocked.invites or 0, So.db.blocked.duels or 0)) end
        upd()
        r:SetScript("OnShow", upd)
      end)
    end },
  -- minimap: dugme toplayici, kare minimap (UI/MinimapTools.lua)
  { "MinimapTools", "Minimap tools", "Gathers addon minimap buttons behind one button and can make the minimap square.", group = "hub",
    body = function(s, page)
      local M = ns.MinimapTools
      s:Switch("Collect minimap buttons", "Addon buttons around the minimap move into a drawer that opens from one button. Turning it off needs /reload.", function() return M.db.collect end, function(v) M:Set("collect", v) end)
      s:Switch("Square minimap", "A square minimap with a thin edge. Turning it off needs /reload.", function() return M.db.square end, function(v) M:Set("square", v) end)
    end },

  -- yetenek planlayicisi (Helpers/TalentPlanner.lua): Class Codex > Talents > Planner
  { "TalentPlanner", "Talent planner", "Plan your talents point by point in Class Codex > Talents > Planner, keep named plans, share them as text and let the next talent marker follow one.", group = "class" },
  -- tarif tarayicisi (Helpers/Recipes.lua): Professions > Recipes
  { "Recipes", "Recipe browser", "Recipes you have not learned yet on the Professions page, with the skill they need and where they come from.", group = "gold",
    body = function(s, page)
      sw(s, page, "Record recipe sellers", "When a vendor sells a recipe item, saves the vendor and the place so the arrow can lead you there.", ns.Recipes.db, "record")
    end },
  -- kutuphane kitaplari (Helpers/LibraryBooks.lua): Mentor > Books
  { "LibraryBooks", "Library books", "Tracks the library books on Mentor > Books: which you turned in, where you found them, and an arrow.", group = "hub" },
}
Settings.FEATURES = FEATURES

function Settings.Feature(name)
  for _, f in ipairs(FEATURES) do if f[1] == name then return f end end
  return nil
end

-- Modul gruplari (Settings > Modules). Gelistirici araclari kapali bir bolumde.
local GROUPS = {
  { id = "route", title = "Route" }, { id = "quests", title = "Quests" }, { id = "class", title = "Class and combat" },
  { id = "gold", title = "Gold and trade" }, { id = "dungeons", title = "Dungeons" }, { id = "hub", title = "Hub and social" },
  { id = "dev", title = "Developer tools" },
}

-- Hazir kurulumlar: hangi moduller acik (listede olmayan kapanir). Gelistirici araclarina ve anahtarsiz
-- satirlara (rehber motoru) dokunulmaz. "all": hepsi acik.
local PRESETS = {
  minimal = { Window = true, Nav = true, Pins = true, GuideBrowser = true, Island = true, Discover = true },
  leveling = {
    Window = true, Nav = true, Pins = true, GuideBrowser = true, MapReveal = true, Travel = true, Transport = true,
    Leveling = true, MapMarkers = true, Rares = true, QuestAuto = true, QuestItem = true, ItemNeeds = true, Brain = true, Build = true, Codex = true,
    Vendor = true, Alerts = true, Journal = true, Island = true, Mentor = true, Discover = true,
  },
  full = "all",
}
Settings.PRESETS = PRESETS

function Settings:ApplyPreset(id)
  local on = PRESETS[id]
  if not on then return false end
  self.applyingPreset = true   -- Discover: kurulumun kapattigi modul "oyuncu kapatti" sayilmaz
  for _, f in ipairs(FEATURES) do
    local mod = not f.noSwitch and f.group ~= "dev" and ns:GetModule(f[1])
    if mod then
      local want = on == "all" or on[f[1]] == true
      if mod:IsEnabled() ~= want then
        mod:SetEnabled(want)
        if f.onSwitch then ns.SafeCall(f.onSwitch, want) end
      end
    end
  end
  self.applyingPreset = nil
  ns.db.onboarded = true
  ns:Send("ARCANIS_PRESET_APPLIED", id)
  local mp = self.pages and self.pages.modules
  if mp and mp.built and mp.frame.refresh then ns.SafeCall(mp.frame.refresh) end
  return true
end

-- Modulun ayarlarini varsayilana dondurur: yalniz defaults'taki duz degerler ve renkler (tablo verisi, ogrenilmis
-- kayitlar ve pencere konumu kalir), sonra modulun kendi uygulayicilariyla (ApplyStyle, ApplyAlpha...) ekrana
-- yansir. Modul kapatilip acilmaz: oturum verisi (XP/saat, gezinilen adim) ve Discover kayitlari bozulmaz.
local APPLIERS = { "ApplyStyle", "ApplyAlpha", "ApplyPosition", "Refresh", "Update" }
local KEEP_ON_RESET = { point = true, relPoint = true, x = true, y = true, w = true, h = true, page = true }
local RESET_NIL = { Pins = { "trailColor" } }   -- modul -> varsayilani nil olan ayar anahtarlari
local function isColor(v) return type(v) == "table" and #v >= 3 and #v <= 4 and type(v[1]) == "number" end
function Settings:ResetModule(name)
  local f = self.Feature(name)
  if f and f.reset then ns.SafeCall(f.reset); return true end
  local mod = ns:GetModule(name)
  if not (mod and mod.db) then return false end
  for k, def in pairs(mod.defaults or {}) do
    if not KEEP_ON_RESET[k] then
      if type(def) ~= "table" then mod.db[k] = def
      elseif isColor(def) then mod.db[k] = { unpack(def) } end
    end
  end
  -- varsayilani nil olan ayarlar defaults'ta gorunmez (pairs atlar): RESET_NIL listesi ve defaults'ta olmayan
  -- renkler (ornek: Pins.db.trailColor, nil = tema rengi) silinir. Diger kayitli anahtarlar (surum isaretleri,
  -- ogrenilmis veri, disabled) kalir.
  local defs = mod.defaults or {}
  for _, k in ipairs(RESET_NIL[name] or {}) do
    if defs[k] == nil then mod.db[k] = nil end
  end
  for k, v in pairs(mod.db) do
    if defs[k] == nil and not KEEP_ON_RESET[k] and isColor(v) then mod.db[k] = nil end
  end
  if mod:IsEnabled() then
    for _, fn in ipairs(APPLIERS) do
      if type(mod[fn]) == "function" then ns.SafeCall(mod[fn], mod) end
    end
  end
  ns:Send("ARCANIS_MODULE_RESET", name)
  return true
end

local function hasOptions(f) return f.body or f.advanced or f.page end

-- Cekmece konumu: x kadar saga kaymis (0 = yerinde)
local DRAWER_TIME = 0.28
local function placeDrawer(d, x)
  local mp = d:GetParent()
  d:ClearAllPoints()
  d:SetPoint("TOPLEFT", mp, "TOPLEFT", x, 0)
  d:SetPoint("BOTTOMRIGHT", mp, "BOTTOMRIGHT", x, 0)
end

-- Kayma animasyonu: acilirken sagdan iceri, kapanirken saga disari (hafif solma ile)
function Settings:SlideDrawer(d, opening)
  local travel = Settings.bodyWidth or BODY_W
  Skin:CancelTween("settings-drawer")
  d:Show()
  local function at(p)   -- p: 0 -> 1
    local k = opening and (1 - p) or p
    placeDrawer(d, travel * k)
    d:SetAlpha(1 - 0.26 * k)
  end
  at(0)
  Skin:Tween("settings-drawer", DRAWER_TIME, at, function()
    if opening then placeDrawer(d, 0); d:SetAlpha(1) else d:Hide(); placeDrawer(d, 0); d:SetAlpha(1) end
  end)
end

-- Bolum ayarlari (sahibin karari, 13 Kasim 2026): ana pencerenin her bolumu (Quest Tracker, Rotation, Maps, Hub,
-- Gold...) kendi modullerinin ayarlarini kendi icinde tasir. Verilen modullerin kartlari (anahtar + govde) ve her
-- birinin "Advanced"i tek kaydirilabilir listede; Settings > Modules cekmecesiyle ayni kurucular. Doner: frame.
function Settings:BuildSection(frame, names)
  local ob = optionList(frame)
  frame.switches = frame.switches or {}
  for _, name in ipairs(names) do
    local f = self.Feature(name)
    if f and not f.page then
      local mod = ns:GetModule(name)
      if f.noSwitch or not mod then
        local g = ob:Group(f[2], f[3])
        if f.body then f.body(g, frame) end
      else
        ob:Feature(f, function(g) if f.body then f.body(g, frame) end end)
      end
      if f.advanced then
        local a = ob:Section(L["%s: more settings"]:format(L[f[2]]), false, "Less used settings.")
        f.advanced(a, frame)
      end
    end
  end
  ob:Finish(function()
    if frame.colors then for _, b in pairs(frame.colors) do b:Refresh() end end
    if frame.refreshPreview then frame.refreshPreview() end
  end)
  return frame
end

-- Bir modulun ayarlari: Modules sayfasinin ustune acilan cekmece (geri, varsayilana don, modul karti ve kapali
-- "Advanced" bolumu). Ayari kendi sayfasinda olan modul (Dynamic Hub) o sayfayi acar. Doner: cekmece (test).
function Settings:OpenOptions(name)
  local f = self.Feature(name)
  if not (f and hasOptions(f)) then return nil end
  if f.page then self:Open(f.page); return self.pages[f.page].frame end
  self:Open("modules", true)
  local mp = self.pages.modules.frame
  mp.drawers = mp.drawers or {}
  local d = mp.drawers[name]
  if not d then
    d = CreateFrame("Frame", nil, mp)
    mp.drawers[name] = d   -- hemen: kurulum hata verse de Back / CloseOptions onu gizleyebilsin
    d:SetAllPoints(mp)
    d:SetFrameLevel((mp:GetFrameLevel() or 1) + 20)
    d:EnableMouse(true)
    d.bg = d:CreateTexture(nil, "BACKGROUND")
    d.bg:SetAllPoints()
    Skin:Fill(d.bg, C.panel)
    d.switches = {}
    local ob = optionList(d)
    local armed
    d.resetBtn = ob:Buttons(f[2], nil, {
      { "Back", function() Settings:CloseOptions() end },
      { "Reset to defaults", function()
        -- iki adim: yanlislikla basilmasin
        if not armed or (P.Now() - armed) > 4 then
          local at = P.Now()
          armed = at
          d.resetBtn:SetText(L["Click again to reset"])
          -- sure dolunca yazi geri doner: "yeniden tikla" yazarken tiklamak yalniz yeniden kurmasin
          P.After(4, function()
            if armed == at then armed = nil; d.resetBtn:SetText(L["Reset to defaults"]) end
          end)
          return
        end
        armed = nil
        d.resetBtn:SetText(L["Reset to defaults"])
        Settings:ResetModule(name)
        if d.refresh then ns.SafeCall(d.refresh) end
      end },
    })[1]
    local mod = ns:GetModule(name)
    if f.noSwitch or not mod then
      local g = ob:Group(f[2], f[3])
      if f.body then f.body(g, d) end
    else
      d.feature = ob:Feature(f, function(g) if f.body then f.body(g, d) end end)
    end
    if f.advanced then
      local a = ob:Section("Advanced", false, "Less used settings.")
      f.advanced(a, d)
    end
    ob:Finish(function()
      if d.colors then for _, b in pairs(d.colors) do b:Refresh() end end
      if d.refreshPreview then d.refreshPreview() end
    end)
    mp.drawers[name] = d
  end
  -- cekmece gorunurken / gizlenince (pencere kapansa da) modulun onizlemesi (Rotation: ikonlar pencerenin ustunde)
  if (f.onOpen or f.onClose) and not d.previewHooked then
    d.previewHooked = true
    d:SetScript("OnShow", function() if f.onOpen then ns.SafeCall(f.onOpen) end end)
    d:SetScript("OnHide", function() if f.onClose then ns.SafeCall(f.onClose) end end)
  end
  for k, other in pairs(mp.drawers) do if k == name then other:Show() else other:Hide() end end
  if f.onOpen then ns.SafeCall(f.onOpen) end
  local wasOpen = mp.openDrawer
  mp.openDrawer = name
  if d.refresh then ns.SafeCall(d.refresh) end
  -- sayfa gecisleri gibi sagdan kayarak gelir (pencere gorunurken; baska cekmeceden geciste animasyon yok)
  if not wasOpen and self.frame and self.frame:IsShown() then
    self:SlideDrawer(d, true)
  else
    Skin:CancelTween("settings-drawer"); placeDrawer(d, 0); d:SetAlpha(1)
  end
  return d
end

function Settings:CloseOptions()
  local entry = self.pages and self.pages.modules
  local mp = entry and entry.frame
  if not mp then return end
  local open = mp.openDrawer and mp.drawers and mp.drawers[mp.openDrawer]
  local f = mp.openDrawer and self.Feature(mp.openDrawer)
  if f and f.onClose then ns.SafeCall(f.onClose) end   -- onizleme hemen biter (cekmece kayarak cikarken de)
  mp.openDrawer = nil
  if open and self.frame and self.frame:IsShown() and self.current == "modules" then
    self:SlideDrawer(open, false)   -- saga kayarak cikar, sonra gizlenir
  else
    for _, d in pairs(mp.drawers or {}) do d:Hide() end
  end
  if mp.refresh then ns.SafeCall(mp.refresh) end
end

-- Sayfa: Modules. Ustte hazir kurulum ve arama; altinda gruplar halinde her modul tek satir: ad, tek satir
-- aciklama, disli (ayarlari) ve anahtar. Ayarlar satira ya da disliye tiklayinca cekmecede acilir.
local function buildModules(page)
  local ob = optionList(page)
  page.rows, page.groups = {}, {}

  local q = ob:Group("Quick setup", "Turns modules on or off in one go. You can change each one afterwards.")
  q:Buttons("Pick a setup", "Minimal: only the route. Leveling: route, quests and helpers. Everything: all modules.", {
    { "Minimal", function() Settings:ApplyPreset("minimal") end },
    { "Leveling", function() Settings:ApplyPreset("leveling") end },
    { "Everything", function() Settings:ApplyPreset("full") end, true },
  })
  q:Buttons("Choose what to use", "Opens the first-start setup again: tick the parts of Arcanis you want.", {
    { "Open setup", function() if ns.Setup then ns.Setup:Open() end end },
  })
  q:Custom("Search", "Filters the modules below by name and description.", 220, function(r)
    local eb = Skin:CreateEditBox(r, 220, 24, function() if page.filter then page.filter(page.search:GetText()) end end)
    eb:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    page.search = eb
  end)

  for _, grp in ipairs(GROUPS) do
    local list = {}
    for _, f in ipairs(FEATURES) do
      if f.group == grp.id and (f.noSwitch or ns:GetModule(f[1])) then list[#list + 1] = f end
    end
    if #list > 0 then
      local g, card
      if grp.id == "dev" then
        local acc
        g, acc = ob:Section(grp.title, false)
        card = acc
      else
        g = ob:Group(grp.title)
        card = g.card
      end
      local entry = { g = g, card = card, rows = {}, acc = grp.id == "dev" and card or nil }
      for _, f in ipairs(list) do
        local mod = not f.noSwitch and ns:GetModule(f[1])
        local r = g:Custom(f[2], f[3], 110, function(r)
          local right = -12
          if mod then
            local sw = Skin:CreateSwitch(r, "", mod:IsEnabled(), press(function(v)
              mod:SetEnabled(v)
              if f.onSwitch then f.onSwitch(v) end
              if r.dim then r.dim() end
            end))
            sw:SetLabelLeft()
            sw:SetPoint("RIGHT", r, "RIGHT", -12, 0)
            r.switch = sw
            right = -12 - 46 - 8
          end
          if hasOptions(f) then
            local gear = Skin:CreateIconButton(r, "gear", 22, 30, 30)
            gear:SetPoint("RIGHT", r, "RIGHT", right, 0)
            gear:SetScript("OnClick", press(function() Settings:OpenOptions(f[1]) end))
            r.gear = gear
          end
        end)
        function r.dim()
          local on = not mod or mod:IsEnabled()
          r.title:SetTextColor(unpack(on and C.text or C.textDim))
        end
        r.dim()
        if hasOptions(f) then
          r:EnableMouse(true)
          r:SetScript("OnMouseUp", press(function() Settings:OpenOptions(f[1]) end))
        end
        ob.refreshers[#ob.refreshers + 1] = function()
          if r.switch and mod then r.switch:SetChecked(mod:IsEnabled(), true) end
          r.dim()
        end
        entry.rows[#entry.rows + 1] = { r = r, h = r:GetHeight() or OPT_H_DESC, f = f }
        page.rows[f[1]] = r
      end
      page.groups[#page.groups + 1] = entry
    end
  end

  -- arama: eslesmeyen satir 0 yukseklige iner (altindakiler kayar), bos grup tamamen kalkar
  function page.filter(text)
    text = (text or ""):lower()
    for _, e in ipairs(page.groups) do
      local any = false
      for _, row in ipairs(e.rows) do
        local f = row.f
        local hay = ((Settings.Text(f[2]) or "") .. " " .. (Settings.Text(f[3]) or "") .. " " .. f[1]):lower()
        local hit = text == "" or hay:find(text, 1, true) ~= nil
        if hit then row.r:Show() else row.r:Hide() end
        e.g:Resize(row.r, hit and row.h or 0)
        any = any or hit
      end
      if any then e.card:Show() else e.card:Hide(); ob:Resize(e.card, 0) end
      -- kapali bolumdeki (gelistirici araclari) eslesme gorunsun
      if any and text ~= "" and e.acc and e.acc.SetExpanded then e.acc:SetExpanded(true) end
    end
  end

  ob:Finish(function()
    -- cekmece aciksa onu da yenile
    local d = page.openDrawer and page.drawers and page.drawers[page.openDrawer]
    if d and d.refresh then ns.SafeCall(d.refresh) end
  end)
end

-- Sayfa: Appearance (tema, renk, yazi, dil, simge) — tek kart
local function buildAppearance(page)
  local ob = optionList(page)
  local s = ob:Group("Appearance")
  local function themeItems()
    local items = {}
    for _, t in ipairs(Skin.Themes) do items[#items + 1] = { value = t.id, text = t.name } end
    return items
  end
  page.theme = s:Dropdown("Theme", "Arcanis (amber), Astral (blue), Blood Orange (orange on slate blue with frost white text) or Minimal (black and white).", themeItems,
    function() return ns.db.theme or "arcanis" end,
    function(v) ns.db.theme = v; Skin:ApplyTheme(ns.db.theme, ns.db.accent) end)
  local function fontItems()
    local items = {}
    for _, f in ipairs(Skin:CollectFonts()) do items[#items + 1] = { value = f.id, text = f.name } end
    return items
  end
  page.font = s:Dropdown("Font", "Typeface of all Arcanis Path windows (step window, main window, arrow).", fontItems,
    function() return ns.db.font or Skin.DEFAULT_FONT end,
    function(v) ns.db.font = v; Skin:ApplyFont(ns.db.font, ns.db.fontScale) end)
  local function langItems()
    local items = { { value = "auto", text = L["Automatic (client language)"] } }
    for _, code in ipairs(ns:GetLocales()) do items[#items + 1] = { value = code, text = ns:GetLocaleName(code) } end
    return items
  end
  page.langDropdown = s:Dropdown("Language", "Language of all Arcanis Path texts. Automatic follows your game client.", langItems,
    function() return ns.db.locale and ns:ResolveLocale(ns.db.locale) or "auto" end,
    function(value)
      if value == "auto" then
        ns.db.locale = nil
        ns:SetLocale("auto")
      elseif ns:SetLocale(value) then
        ns.db.locale = ns.localeCode
      end
    end)
  page.fontScale = s:Slider("Font size", "Makes every Arcanis Path text larger or smaller.", 0.8, 1.4, 0.05,
    function() return ns.db.fontScale or 1 end,
    function(v) ns.db.fontScale = v; Skin:ApplyFont(ns.db.font, ns.db.fontScale) end, "%.2f")
  -- vurgu rengi: renk secici; "Theme colour" temanin kendi vurgusuna doner
  s:Custom("Accent", "Overrides the theme's highlight colour.", 20 + 8 + 90, function(r)
    local def = Skin:CreateButton(r, "", 90, 20)
    def:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    T(def, "Theme colour")
    page.accent = Skin:CreateColorButton(r, function() return ns.db.accent or C.accent end, press(function(c)
      ns.db.accent = { c[1], c[2], c[3] }
      Skin:ApplyTheme(ns.db.theme, ns.db.accent)
    end))
    page.accent:SetPoint("RIGHT", def, "LEFT", -8, 0)
    def:SetScript("OnClick", press(function()
      ns.db.accent = nil; Skin:ApplyTheme(ns.db.theme, nil); page.accent:Refresh()
    end))
  end)
  page.minimapSw = s:Switch("Minimap button", "Left click: step window. Right click: settings. Shift: dungeons, Ctrl: gold, Alt: mentor.",
    function() return ns.MinimapButton and not ns.MinimapButton.db.hide end,
    function(v) if ns.MinimapButton then ns.MinimapButton.db.hide = not v; ns.MinimapButton:Apply() end end)
  if ns.WhatsNew then ns.WhatsNew:BuildSettings(s, page) end
  if ns.Profiles then ns.Profiles:BuildSettings(ob, page) end
  ob:Finish()
end

-- System > Maintenance: hata ayiklama ve sifirlama
local function buildMaintenance(page)
  local ob = optionList(page)
  local s = ob:Group("Maintenance")
  page.debug = s:Switch("Debug messages", "Prints technical messages to chat. Leave off unless you report a bug.",
    function() return ns.debug end, function(v) ns.debug = v end)
  local buttons = s:Buttons("Reset all settings", "Restores every option to its default. Type /reload afterwards.", {
    { "Reset all settings", function()
      local btn = page.reset
      if page.confirmUntil and GetTime and GetTime() < page.confirmUntil then
        page.confirmUntil = nil
        ns:ResetDatabase()
        ns:Print(L["Settings reset. Type /reload to refresh the interface."])
        btn:SetText(L["Reset all settings"])
        return
      end
      page.confirmUntil = (GetTime and GetTime() or 0) + 4
      btn:SetText(L["Click again to confirm"])
      if C_Timer and C_Timer.After then
        C_Timer.After(4, function()
          if page.confirmUntil then page.confirmUntil = nil; btn:SetText(L["Reset all settings"]) end
        end)
      end
    end },
  })
  page.reset = buttons[1]
  ob:Finish()
end

-- Sayfa: Zones
local ZONE_H = 26

local function buildZones(page)
  local st = { rows = {} }
  page.st = st

  st.hint = label(page, 10, C.textDim)
  place(page, st.hint, 0, 0, function(bw) return bw end)
  T(st.hint, "Stand in a zone and press 'Use my map' to link it to your current map.")

  st.only = Skin:CreateSwitch(page, "", false, press(function() page.refresh() end))
  st.only:SetPoint("TOPLEFT", 0, -34)
  T(st.only, "Only unresolved zones")

  st.area = Skin:CreateScrollArea(page, BODY_W, BODY_H - 68)
  st.area:SetPoint("TOPLEFT", 0, -66)
  st.area:SetPoint("BOTTOMRIGHT", 0, 0)

  local function command(text)
    SlashCmdList.ARCANIS(text)
    page.refresh()
  end

  function page.refresh()
    local used = ns.Zones:Used()
    local zones = {}
    for zone in pairs(used) do
      local id = ns.Zones:Resolve(zone)
      if not (st.only.checked and id) then zones[#zones + 1] = zone end
    end
    table.sort(zones, function(a, b)
      local ra, rb = ns.Zones:Resolve(a) ~= nil, ns.Zones:Resolve(b) ~= nil
      if ra ~= rb then return not ra end
      return a < b
    end)
    local content = st.area.content
    for i, zone in ipairs(zones) do
      local row = st.rows[i]
      if not row then
        row = makeRow(content, BODY_W - 10, ZONE_H)
        row.a:SetPoint("LEFT", 8, 0)
        row.count = label(row, 10, C.textDim)
        row.count:SetPoint("LEFT", row, "LEFT", 210, 0)
        row.map = label(row, 10, C.text)
        row.map:SetPoint("LEFT", row, "LEFT", 290, 0)
        row.reset = Skin:CreateButton(row, "", 54, 20)
        row.reset:SetPoint("RIGHT", -4, 0)
        T(row.reset, "Reset")
        row.assign = Skin:CreateButton(row, "", 100, 20)
        row.assign:SetPoint("RIGHT", row.reset, "LEFT", -4, 0)
        T(row.assign, "Use my map")
        row.assign:SetScript("OnClick", press(function() command("zonemap " .. row.zone) end))
        row.reset:SetScript("OnClick", press(function() command("zonemap " .. row.zone .. " clear") end))
        st.rows[i] = row
      end
      row.zone = zone
            stretchRow(row, content, -(i - 1) * (ZONE_H + 2))
      row.a:SetText(zone)
      row.count:SetText(L["%d steps"]:format(used[zone]))
      local id = ns.Zones:Resolve(zone)
      if id then
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        row.map:SetText(("%d%s"):format(id, info and info.name and ("  " .. info.name) or ""))
        row.map:SetTextColor(unpack(C.text))
      else
        row.map:SetText(L["not set"])
        row.map:SetTextColor(1, 0.35, 0.35, 1)
      end
      row:Show()
    end
    for i = #zones + 1, #st.rows do st.rows[i]:Hide() end
    st.area:SetContentHeight(#zones * (ZONE_H + 2))
  end
end

-- Sayfa: Dungeons (zindan gunlugu: afis, gorevler, akordeon boss/loot, takip listesi, rehber baslat)
local DUNGEON_H = 44
local DLIST_W = 210
local BANNER_H = 112
local QUALITY_COLOR = {
  [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd", [4] = "a335ee", [5] = "ff8000",
}
local STATUS_COLOR = {
  now = { 0.30, 0.85, 0.50, 1 }, soon = { 0.95, 0.75, 0.25, 1 }, over = { 0.40, 0.40, 0.40, 1 }, later = { 0.55, 0.55, 0.55, 1 },
}
local TRACKED = "__tracked"
local ART_DIR = "Interface\\AddOns\\Arcanis\\Media\\Dungeons\\"

local function hexColor(hex)
  return { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, 1 }
end

local function buildDungeons(page)
  local J = ns.Journal
  local st = { rows = {}, lines = {}, groups = {}, open = {}, selected = nil }
  page.st = st
  local rightX = DLIST_W + 16
  local rightW = BODY_W - rightX

  st.search = Skin:CreateEditBox(page, DLIST_W, 24, press(function(_, user)
    if user then page.refreshList() end
  end))
  st.search:SetPoint("TOPLEFT", 0, 0)
  st.searchHint = label(st.search, 10, C.textOff)
  st.searchHint:SetPoint("LEFT", 8, 0)
  T(st.searchHint, "Search dungeons...")

  st.area = Skin:CreateScrollArea(page, DLIST_W, BODY_H - 30)
  st.area:SetPoint("TOPLEFT", 0, -30)
  st.area:SetPoint("BOTTOMLEFT", 0, 0)

  st.banner = Skin:CreateBanner(page, rightW, BANNER_H)
  st.banner:SetPoint("TOPLEFT", rightX, 0)
  st.banner:SetPoint("TOPRIGHT", 0, 0)

  -- Afis (DESIGN.md "Hizalama"): zindan adi + aciklama ustte; alt yari karartilmis serit (56 px) kontrollere ayrilir:
  -- baslat dugmesi solda (12) ve seridin ortasinda, iki anahtar sag kenara (-12) dayali ust uste, etiketler solda.
  st.banner:SetTextAtTop()
  local SHADE_MID = BANNER_H * 0.25   -- alt seridin dikey ortasi (alt kenardan)
  st.mine = Skin:CreateSwitch(st.banner, "", J.db.onlyMine, press(function(v)
    J.db.onlyMine = v
    page.renderDetail()
  end))
  st.mine:SetLabelLeft()
  st.mine:SetPoint("RIGHT", st.banner, "BOTTOMRIGHT", -12, SHADE_MID + 13)
  T(st.mine, "Only my class")

  st.suggest = Skin:CreateSwitch(st.banner, "", J.db.suggest, press(function(v) J.db.suggest = v end))
  st.suggest:SetLabelLeft()
  st.suggest:SetPoint("RIGHT", st.banner, "BOTTOMRIGHT", -12, SHADE_MID - 13)
  T(st.suggest, "Ask me when my level fits")

  st.startBtn = Skin:CreateButton(st.banner, "", 170, 24, true)
  st.startBtn:SetPoint("LEFT", st.banner, "BOTTOMLEFT", 12, SHADE_MID)
  T(st.startBtn, "Start dungeon guide")
  -- bu zindanin gorev rehberi calisiyorsa ayni dugme birakilan rehbere dondurur
  st.startBtn:SetScript("OnClick", press(function()
    local sel = st.selected
    if not sel or sel == TRACKED then return end
    if J:GuideActive(sel) then J:ReturnToGuide() else J:StartGuide(sel) end
    page.renderDetail()
  end))

  -- Dugme metne gore genisler (dil / yazi olcegi); anahtar etiketleri dugmeye 16 px'ten fazla yaklasamaz,
  -- sigmazsa "..." ile kisalir. Yazi olculeri ancak cizimden sonra dogru oldugu icin her cizimde yeniden hesaplanir.
  local function placeControls()
    local btn = st.startBtn
    local tw = btn.text.GetStringWidth and btn.text:GetStringWidth()
    local bw = math.max(170, (type(tw) == "number" and tw or 0) + 24)
    btn:SetWidth(bw)
    local w = st.banner:GetWidth()
    if type(w) ~= "number" or w < 100 then w = rightW end
    local labelW = math.max(40, w - 12 - 40 - 8 - (12 + bw + 16))
    for _, sw in ipairs({ st.mine, st.suggest }) do
      sw.label:SetWidth(labelW)
      sw.label:SetWordWrap(false)
    end
  end
  page.placeControls = placeControls
  function page.onResize() placeControls() end

  local top = BANNER_H + 8
  st.detail = Skin:CreateScrollArea(page, rightW, BODY_H - top)
  st.detail:SetPoint("TOPLEFT", rightX, -top)
  st.detail:SetPoint("BOTTOMRIGHT", 0, 0)

  local function questTooltip(row)
    local q = row.quest
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(q.name, 1, 0.82, 0.2)
    if q.level then GameTooltip:AddLine(L["Level %d"]:format(q.level), 1, 1, 1) end
    if q.req then GameTooltip:AddLine(L["Requires level %d"]:format(q.req), 0.7, 0.7, 0.7) end
    if q.giver then GameTooltip:AddLine(L["Start: %s"]:format(q.giver), 0.8, 0.8, 0.8, true) end
    if q.note then GameTooltip:AddLine(ns:LocalizedText(q.note), 1, 1, 1, true) end
    local b = st.summary and st.summary.before[q.id]
    if b then GameTooltip:AddLine(L["Quests before it: %d (%d done)"]:format(b.n, b.done), 0.35, 0.65, 0.95, true) end
    if q.turnin then GameTooltip:AddLine(L["Turn in: %s"]:format(q.turnin), 0.8, 0.8, 0.8, true) end
    if q.rew then GameTooltip:AddLine(q.rew, 0.4, 0.85, 0.5, true) end
    GameTooltip:Show()
  end
  local function prereqTooltip(row)
    local pq = row.prereq
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(pq.name, 1, 0.82, 0.2)
    if pq.lv then GameTooltip:AddLine(L["Level %d"]:format(pq.lv), 1, 1, 1) end
    if pq.npc then GameTooltip:AddLine(L["Start: %s"]:format(pq.npc .. (pq.zone and (", " .. pq.zone) or "")), 0.8, 0.8, 0.8, true) end
    if pq.item then GameTooltip:AddLine(L["Starts from an item drop"], 0.8, 0.8, 0.8, true) end
    GameTooltip:AddLine(pq.key and L["Part of the way to get the key."] or L["Needed before the dungeon quest above can be taken."], 0.35, 0.65, 0.95, true)
    if pq.zone and pq.x then GameTooltip:AddLine(L["Click: point the arrow to the quest giver"], 0.6, 0.6, 0.6) end
    GameTooltip:Show()
  end
  local function tooltip(row)
    if GameTooltip and row.quest then questTooltip(row) return end
    if GameTooltip and row.prereq then prereqTooltip(row) return end
    if GameTooltip and row.keyItem then
      GameTooltip:SetOwner(row, "ANCHOR_LEFT")
      GameTooltip:SetHyperlink("item:" .. row.keyItem)
      GameTooltip:Show()
      return
    end
    if GameTooltip and row.route then
      GameTooltip:SetOwner(row, "ANCHOR_LEFT")
      GameTooltip:SetText(row.route.d.name, 1, 0.82, 0.2)
      GameTooltip:AddLine(L["Click: point the arrow to the entrance"], 0.7, 0.7, 0.7)
      GameTooltip:Show()
      return
    end
    if not (GameTooltip and row.itemId) then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetHyperlink("item:" .. row.itemId)
    local priceLine = ns.Suite and ns.Suite:PriceLine(row.itemId)
    if priceLine then GameTooltip:AddLine(priceLine, 1, 0.82, 0.2) end
    if row.classList and #row.classList > 0 then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(ns.Gear:Summary(row.classList), 1, 1, 1, true)
    end
    if st.selected == TRACKED and row.dungeonRef then
      GameTooltip:AddLine(L["Click to open this dungeon"], 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
  end
  local function hideTooltip() if GameTooltip then GameTooltip:Hide() end end

  local function getLine(i)
    local row = st.lines[i]
    if not row then
      row = makeRow(st.detail.content, rightW - 24, 36)
      row.a:SetPoint("TOPLEFT", 12, -5)
      row.a:SetPoint("RIGHT", row, "RIGHT", -6, 0)
      row.a:SetWordWrap(false)
      row.b:SetPoint("TOPLEFT", 12, -20)
      row.b:SetPoint("RIGHT", row, "RIGHT", -6, 0)
      row.b:SetWordWrap(false)
      -- takip kutusu (sol) ve "Tracked" rozeti (sag)
      row.check = row:CreateTexture(nil, "OVERLAY")
      row.check:SetSize(16, 16)
      row.check:SetPoint("LEFT", 10, 0)
      row.icon = row:CreateTexture(nil, "ARTWORK")
      row.icon:SetSize(26, 26)
      row.icon:SetPoint("LEFT", 32, 0)
      row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      row.iconBorder = row:CreateTexture(nil, "BACKGROUND")
      row.iconBorder:SetTexture(WHITE)
      row.iconBorder:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -1, 1)
      row.iconBorder:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 1, -1)
      row.classIcons = {}
      for ci = 1, 9 do
        local ic = row:CreateTexture(nil, "OVERLAY")
        ic:SetSize(16, 16)
        ic:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8 - (ci - 1) * 19, 3)
        ic:Hide()
        row.classIcons[ci] = ic
      end
      row.badge = label(row, 9, C.accent, "RIGHT")
      row.badge:SetPoint("TOPRIGHT", -8, -6)
      -- gorev satiri: sag yuvada web ikonu (dikeyde ortali); tiklayinca gorev linki kopyalama kutusunda
      row.web = Skin:CreateIconButton(row, "web", 24)
      row.web:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      row.web:Hide()
      row.web:HookScript("OnEnter", function(b)
        if GameTooltip then
          GameTooltip:SetOwner(b, "ANCHOR_LEFT")
          GameTooltip:SetText(b:GetParent().route and L["Show on the world map"] or L["Copy Wowhead link"])
          GameTooltip:Show()
        end
      end)
      row.web:HookScript("OnLeave", hideTooltip)
      row.web:SetScript("OnClick", press(function(b)
        local rt = b:GetParent().route
        if rt then J:ShowOnMap(rt.d, rt.e) return end
        local q = b:GetParent().quest
        local url = q and J:QuestURL(q.id)
        if url then Skin:ShowCopyBox(q.name, url) end
      end))
      row:SetScript("OnEnter", function(r) tooltip(r) end)
      row:SetScript("OnLeave", hideTooltip)
      row:SetScript("OnClick", press(function(r)
        if r.route then J:PointTo(r.route.d, r.route.e) return end
        local pq = r.prereq
        if pq then
          local map = pq.zone and ns.Zones and ns.Zones:Resolve(pq.zone)
          if map and pq.x and pq.y and ns.Nav then
            ns.Nav:SetTarget(map, pq.x / 100, pq.y / 100, pq.npc and (pq.name .. " - " .. pq.npc) or pq.name, "journal")
          end
          return
        end
        if not r.itemId then return end
        if st.selected == TRACKED and r.dungeonRef then
          -- Takip listesinde tiklama esyayi birakmaz; ait oldugu zindani acar (oradan baslatilir/birakilir).
          -- arama kutusu zindani gizliyorsa listede secili gorunmez; once filtreyi temizle
          st.search:SetText("")
          J.focus = r.dungeonRef.id
          page.refresh()
        else
          J:Track(r.itemId)
          page.renderDetail()
          page.refreshList()
        end
      end))
      st.lines[i] = row
    end
    return row
  end

  -- Akordeon gruplari yukaridan asagi dizilir; bir grup acilip kapanirken (animasyon) alttakiler kayar.
  local function layout()
    local y = st.notesHeight or 0
    for _, g in ipairs(st.groups) do
      if g.active then
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", st.detail.content, "TOPLEFT", 0, -y)
        g:SetPoint("TOPRIGHT", st.detail.content, "TOPRIGHT", 0, -y)
        y = y + g:GetCurrentHeight() + 4
      end
    end
    st.detail:SetContentHeight(y)
  end
  local function getGroup(i)
    local g = st.groups[i]
    if not g then
      g = Skin:CreateAccordion(st.detail.content, rightW - 16, 30)
      g.onAnimate = layout
      g.onToggle = function(acc) st.open[acc.key] = acc.expanded end
      st.groups[i] = g
    end
    return g
  end

  local function itemSpec(e)
    return { kind = "item", e = e }
  end
  local function groupSpec(key, title, right, tick, rows)
    return { key = key, title = title, right = right, tick = tick, rows = rows }
  end
  local function itemGroup(group, key, title)
    local rows, mineCount = {}, 0
    for _, e in ipairs(group.items) do
      rows[#rows + 1] = itemSpec(e)
      if e.mine then mineCount = mineCount + 1 end
    end
    local right = L["%d items"]:format(#group.items) .. (mineCount > 0 and ("  |  " .. L["%d for you"]:format(mineCount)) or "")
    return groupSpec(key, title, right, C.accent, rows)
  end

  -- satir icerigini doldur (not / gorev / esya)
  local function placeText(row, left, rightInset)
    row.a:ClearAllPoints()
    row.a:SetPoint("TOPLEFT", left, -5)
    row.a:SetPoint("RIGHT", row, "RIGHT", -rightInset, 0)
    row.b:ClearAllPoints()
    row.b:SetPoint("TOPLEFT", left, -20)
    row.b:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  end

  local function fillRow(row, en)
    row.itemId, row.classList, row.quest, row.dungeonRef, row.route, row.prereq = nil, nil, nil, nil, nil, nil
    row.keyItem = nil
    row.check:Hide(); row.badge:SetText("")
    for _, ic in ipairs(row.classIcons) do ic:Hide() end
    row.icon:Hide(); row.iconBorder:Hide(); row.web:Hide()
    placeText(row, 12, 6)
    row.b:SetTextColor(unpack(C.textDim))
    row:SetSelected(false)
    row.a:SetWordWrap(false)
    if en.kind == "note" or en.kind == "how" then
      row:SetTick(C.border)
      row.a:SetWordWrap(true)
      row.a:SetText(en.a)
      row.b:SetText("")
    elseif en.kind == "route" then
      row:SetTick(en.step and C.border or C.accent)
      row.a:SetText(en.a)
      row.b:SetText(en.b or "")
      row.route = en
      -- giris satiri: sag yuvada harita ikonu (dunya haritasini o bolgede acar)
      if not en.step then
        row.web:SetIcon("map")
        row.web:Show()
        placeText(row, 12, 40)
        row.b:SetPoint("RIGHT", row, "RIGHT", -40, 0)
      end
    elseif en.kind == "prereq" then
      local pq = en.p
      local lvl = pq.lv and ("[%d] "):format(pq.lv) or ""
      local tick = ("|T%s:12:12:0:0:64:64:0:64:0:64:77:217:128|t "):format(Skin.Icons.check)
      local head = (en.keyStep and L["Key quest %d/%d: "] or L["Pre-quest %d/%d: "]):format(en.i, en.n)
      row:SetTick(pq.done and { 0.30, 0.85, 0.50, 0.6 } or { 0.35, 0.65, 0.95, 0.45 })
      placeText(row, 28, 6)
      if pq.done then
        row.a:SetText("|cff8c8c8c" .. tick .. head .. lvl .. pq.name .. "  (" .. L["done"] .. ")|r")
      elseif pq.taken then
        row.a:SetText("|cff4dd980" .. head .. lvl .. pq.name .. "  (" .. L["in your log"] .. ")|r")
      else
        row.a:SetText(head .. lvl .. pq.name)
      end
      local where
      if pq.item then where = L["Starts from an item drop"]
      elseif pq.npc and pq.zone and pq.x then where = ("%s, %s (%.1f, %.1f)"):format(pq.npc, pq.zone, pq.x, pq.y)
      elseif pq.npc or pq.zone then where = pq.npc or pq.zone end
      if pq.dungeon then where = (where and (where .. "  ·  ") or "") .. L["also a dungeon quest"] end
      row.b:SetText(where or "")
      row.prereq = pq
    elseif en.kind == "key" then
      -- anahtar satiri: esya ikonu, ad, sende mi; altinda ne actigi
      local ky = en.k
      placeText(row, 66, 6)
      row.icon:SetTexture(P.ItemIcon(ky.key.item) or "Interface\\Icons\\INV_Misc_Key_03")
      row.icon:Show()
      local have = ky.have and { 0.30, 0.85, 0.50, 1 } or C.accent
      row.iconBorder:SetVertexColor(unpack(have))
      row.iconBorder:Show()
      row:SetTick(have)
      local state = ky.have and ("  |cff4dd980(" .. L["you have it"] .. ")|r") or ""
      row.a:SetText(ky.name .. state)
      row.b:SetText(ns:LocalizedText(ky.key.note) or "")
      row.keyItem = ky.key.item
    elseif en.kind == "quest" then
      local q = en.q
      -- bitmis (teslim edilmis): yaninda tik, soluk; gunlukte (alinmis): yesil, teslime hazirsa "ready"; digerleri normal
      local done = P.IsQuestFlaggedCompleted(q.id)
      local taken = not done and P.IsQuestInLog(q.id)
      local ready = taken and P.IsQuestComplete and P.IsQuestComplete(q.id)
      local lvl = q.level and ("[%d] "):format(q.level) or ""
      local tick = ("|T%s:12:12:0:0:64:64:0:64:0:64:77:217:128|t "):format(Skin.Icons.check)
      row:SetTick((done or taken) and { 0.30, 0.85, 0.50, 1 } or { 0.35, 0.65, 0.95, 1 })
      if done then
        row.a:SetText(tick .. "|cff8c8c8c" .. lvl .. q.name .. "  (" .. L["done"] .. ")|r")
      elseif taken then
        row.a:SetText("|cff4dd980" .. lvl .. q.name .. "  (" .. (ready and L["Ready to turn in"] or L["in your log"]) .. ")|r")
      else
        row.a:SetText(lvl .. q.name)
      end
      row.b:SetText(q.giver or (q.note and ns:LocalizedText(q.note)) or "")
      row.quest = q
      -- web ikonu sag yuvada (8 + 24 + 8): iki satir da ikondan 8 px once biter
      if J:QuestURL(q.id) then
        row.web:SetIcon("web")
        row.web:Show()
        placeText(row, 12, 40)
        row.b:SetPoint("RIGHT", row, "RIGHT", -40, 0)
      end
    else
      local e = en.e
      local token = P.PlayerClassToken()
      local item = e.item
      local color = QUALITY_COLOR[(item and item.quality) or e.q or 1] or "ffffff"
      local nameText = item and item.name or e.n or ("#" .. e.id)
      local sub = ""
      if not item and e.s then sub = e.s end
      if item then
        local slot = item.equipLoc and _G[item.equipLoc]
        sub = (slot and slot ~= "" and (slot .. " ") or "") .. (item.subType or "")
        if item.minLevel and item.minLevel > 1 then sub = sub .. "  |  " .. L["Requires level %d"]:format(item.minLevel) end
      end
      local shown = 0
      if e.classes and #e.classes > 0 then
        if #e.classes >= #ns.Gear.CLASSES then
          sub = sub .. "  |  " .. L["All classes"]
        else
          row.classList = e.classes
          for ci, ce in ipairs(e.classes) do
            local ic = row.classIcons[ci]
            if not ic then break end
            setClassIcon(ic, ce.class)
            ic:SetAlpha((e.mine and ce.class ~= token) and 0.45 or 1)
            ic:Show()
            shown = shown + 1
          end
        end
      end
      local tracked = J:IsTracked(e.id)
      placeText(row, 66, tracked and 84 or 6)
      row.icon:SetTexture((item and item.icon) or P.ItemIcon(e.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.icon:Show()
      local qc = color
      local qr, qg, qb = hexColor(qc)[1], hexColor(qc)[2], hexColor(qc)[3]
      row.iconBorder:SetVertexColor(qr, qg, qb, 1)
      row.iconBorder:Show()
      row.b:ClearAllPoints()
      row.b:SetPoint("TOPLEFT", 66, -20)
      row.b:SetPoint("RIGHT", row, "RIGHT", -(shown > 0 and (shown * 19 + 14) or 6), 0)
      row.check:SetTexture(tracked and Skin.Icons.check or Skin.Icons.box)
      row.check:SetVertexColor(unpack(tracked and C.accent or C.textOff))
      row.check:Show()
      row.badge:SetText(tracked and L["TRACKED"] or "")
      row.a:SetText(("|cff%s%s|r"):format(color, nameText))
      row.b:SetText(sub)
      row:SetTick(hexColor(color))
      row:SetSelected(tracked)
      if e.mine then row.b:SetTextColor(unpack(C.text)) end
      row.itemId = e.id
      row.dungeonRef = e.dungeon
    end
  end

  function page.renderDetail()
    local sel = st.selected
    -- ayni zindan yeniden cizilirken (esya bilgisi geldi, takip vb.) kaydirma konumu korunur
    local keepScroll = (st.lastRendered == sel) and (st.detail.scrollPos or 0) or 0
    st.lastRendered = sel
    for _, r in ipairs(st.lines) do r:Hide() end
    for _, g in ipairs(st.groups) do g:Hide(); g.active = false end
    local player, level, token = P.PlayerInfo(), P.PlayerLevel(), P.PlayerClassToken()
    local notes, specs = {}, {}

    if sel == TRACKED then
      st.banner:SetArt(ART_DIR .. "tracked.png")
      st.banner.title:SetText(L["Tracked items"])
      -- afis alt yazisi tek kisa satir; uzun aciklama icerikte not satiri olarak durur
      st.banner.sub:SetText(L["%d items"]:format(#J:Tracked()))
      notes[#notes + 1] = { kind = "note", a = L["Click an item in a dungeon to track it. You get a reminder when your level allows it."] }
      st.startBtn:Disable()
      local byDungeon, order = {}, {}
      for _, t in ipairs(J:Tracked()) do
        local g = byDungeon[t.dungeon.id]
        if not g then g = { items = {}, d = t.dungeon }; byDungeon[t.dungeon.id] = g; order[#order + 1] = g end
        local classes = J:EntryClasses(t.entry, t.item)
        g.items[#g.items + 1] = { id = t.id, n = t.entry.n, q = t.entry.q, s = t.entry.s, item = t.item, classes = classes, boss = t.boss, dungeon = t.dungeon }
      end
      for _, g in ipairs(order) do
        local key = "tr:" .. g.d.id
        if st.open[key] == nil then st.open[key] = true end
        specs[#specs + 1] = itemGroup(g, key, g.d.name)
      end
      if #order == 0 then notes[#notes + 1] = { kind = "note", a = L["No tracked items yet."] } end
    elseif sel then
      st.banner:SetArt(ART_DIR .. (sel.art or sel.id) .. ".png", ART_DIR .. "tracked.png")
      st.banner.title:SetText(sel.name)
      local status = J:Status(sel, level)
      local statusText = ({ now = L["Recommended now"], soon = L["Soon"], over = L["Outleveled"], later = "" })[status]
      st.banner.sub:SetText(("%s  |  %d-%d  |  %s"):format(sel.zone, sel.minLevel, sel.maxLevel, statusText))
      local back = J:GuideActive(sel) and J:ReturnGuide()
      if back then
        st.startBtn:SetText(L["Back to %s"]:format(ns.Guides:TitleOf(back)))
        st.startBtn:Enable()
      else
        st.startBtn:SetText(L["Start dungeon guide"])
        if J:HasGuide(sel, player) then st.startBtn:Enable() else st.startBtn:Disable() end
      end

      local text = sel.notes and ns:LocalizedText(sel.notes)
      if text and text ~= "" then notes[#notes + 1] = { kind = "note", a = text } end

      -- nasil gidilir: giris(ler), uzaklik, yaklasma yolu; satira tikla -> ok, harita ikonu -> dunya haritasi
      local entrances = J:Entrances(sel)
      if #entrances > 0 then
        local rows = {}
        local how = sel.how and ns:LocalizedText(sel.how)
        if how and how ~= "" then rows[#rows + 1] = { kind = "how", a = how } end
        local firstDist
        for _, e in ipairs(entrances) do
          local yards, other = J:Distance(e)
          local dist = yards and L["%d yd away"]:format(math.floor(yards + 0.5))
            or (other and L["Other continent"]) or ""
          if not firstDist then firstDist = dist end
          rows[#rows + 1] = { kind = "route", d = sel, e = e, a = L["Entrance: %s (%.1f, %.1f)"]:format(
            (e.name and (e.name .. " - ") or "") .. (e.zone or "?"), e.x, e.y), b = dist }
          for i, p in ipairs(e.path or {}) do
            rows[#rows + 1] = { kind = "route", d = sel, e = e, step = true,
              a = ("%d. %s"):format(i, J:StepText(p[3])), b = ("(%.1f, %.1f)"):format(p[1], p[2]) }
          end
        end
        if st.open["route"] == nil then st.open["route"] = true end
        specs[#specs + 1] = groupSpec("route", L["Getting there"], firstDist, C.accent, rows)
      end

      -- anahtarlar (Data/DungeonKeys.lua): sende mi; yoksa adimlar (zincir gorevine tikla -> ok verene)
      local keys = J.Keys and J:Keys(sel, player) or {}
      if #keys > 0 then
        local rows, missing = {}, 0
        for _, ky in ipairs(keys) do
          rows[#rows + 1] = { kind = "key", k = ky }
          if not ky.have then
            missing = missing + 1
            local quests = {}
            for _, ks in ipairs(ky.steps) do if ks.q then quests[#quests + 1] = ks end end
            for i, ks in ipairs(quests) do
              ks.key = true
              if not ks.done then rows[#rows + 1] = { kind = "prereq", p = ks, i = i, n = #quests, keyStep = true } end
            end
            for _, ks in ipairs(ky.steps) do
              if not ks.q then rows[#rows + 1] = { kind = "how", a = ks.text } end
            end
          end
        end
        if st.open["keys"] == nil then st.open["keys"] = missing > 0 end
        specs[#specs + 1] = groupSpec("keys", L["Keys"], missing > 0 and L["%d needed"]:format(missing) or L["you have it"], C.accent, rows)
      end

      -- gorev rehberi ozeti: kac zindan gorevi, once kac zincir gorevi, kaci bitti
      local DG = ns.DungeonGuides
      st.summary = DG and DG:Summary(sel, player)
      if st.summary then notes[#notes + 1] = { kind = "note", a = L["Quest guide: %s"]:format(DG:SummaryText(st.summary)) } end
      local quests = J:Quests(sel, player)
      if #quests > 0 then
        if st.open["quests"] == nil then st.open["quests"] = true end
        local rows = {}
        -- on gorevi olan gorevin altinda zinciri sirayla (en eskisi once): kimden, nerede, bitti mi; tikla -> ok verene
        local plan = DG and DG:Plan(sel, player)
        -- bitmis (teslim edilmis) gorevler ve on gorevler gizli; sayac kalanlari sayar
        local left = 0
        for _, q in ipairs(quests) do
          if not P.IsQuestFlaggedCompleted(q.id) then
            left = left + 1
            rows[#rows + 1] = { kind = "quest", q = q }
            local pre = plan and DG:Prereqs(sel, q.id, player, plan) or {}
            for i, pq in ipairs(pre) do
              if not pq.done then rows[#rows + 1] = { kind = "prereq", p = pq, i = i, n = #pre, for_ = q } end
            end
          end
        end
        if left > 0 then
          specs[#specs + 1] = groupSpec("quests", L["Quests"], L["%d quests"]:format(left), { 0.35, 0.65, 0.95, 1 }, rows)
        end
      end
      local loot = J:Loot(sel, token, J.db.onlyMine)
      for i, group in ipairs(loot) do
        local key = sel.id .. ":" .. group.boss
        if st.open[key] == nil then st.open[key] = (i == 1) end
        specs[#specs + 1] = itemGroup(group, key, J:BossTitle(group.boss))
      end
      if #quests == 0 and #loot == 0 then notes[#notes + 1] = { kind = "note", a = L["No quest or loot data for this dungeon yet."] } end
    end

    local content, nl = st.detail.content, 0
    local y = 0
    -- uzun not / "nasil gidilir" satiri sarar: satir yuksekligi metne gore (alttaki satirin ustune binmesin)
    local function fit(row, en, base)
      if en.kind ~= "note" and en.kind ~= "how" then return base end
      local th = row.a.GetStringHeight and row.a:GetStringHeight()
      local hgt = (type(th) == "number" and th > 0) and math.max(base, math.ceil(th) + 14) or base
      if hgt ~= base then row:SetHeight(hgt); row.tick:SetHeight(hgt); row.mark:SetHeight(hgt) end
      return hgt
    end
    for _, en in ipairs(notes) do
      nl = nl + 1
      local row = getLine(nl)
      row:SetParent(content)
      row:SetHeight(40); row.tick:SetHeight(40); row.mark:SetHeight(40)
            stretchRow(row, content, -y)
      fillRow(row, en)
      row:Show()
      y = y + fit(row, en, 40) + 4
    end
    st.notesHeight = y

    for gi, spec in ipairs(specs) do
      local g = getGroup(gi)
      g.key, g.active = spec.key, true
      g:Show()
      g:SetTick(spec.tick)
      g.a:SetText(spec.title)
      g.b:SetText(spec.right or "")
      local by = 0
      for _, en in ipairs(spec.rows) do
        nl = nl + 1
        local row = getLine(nl)
        row:SetParent(g.body)
        row:SetHeight(36); row.tick:SetHeight(36); row.mark:SetHeight(36)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", g.body, "TOPLEFT", 0, -by)
        row:SetPoint("TOPRIGHT", g.body, "TOPRIGHT", 0, -by)
        fillRow(row, en)
        row:Show()
        by = by + fit(row, en, 36) + 4
      end
      g:SetBodyHeight(by)
      g:SetExpanded(st.open[spec.key], true)
    end
    layout()
    st.detail:ScrollTo(keepScroll, true)
    placeControls()
  end

  local function select(d)
    st.selected = d
    for _, row in ipairs(st.rows) do row:SetSelected(row.dungeon == d) end
    page.renderDetail()
  end

  function page.refreshList()
    local player, level = P.PlayerInfo(), P.PlayerLevel()
    local list = J:List(player)
    local order = { now = 1, soon = 2, later = 3, over = 4 }
    table.sort(list, function(a, b)
      local sa, sb = order[J:Status(a, level)], order[J:Status(b, level)]
      if sa ~= sb then return sa < sb end
      return a.minLevel < b.minLevel
    end)
    local text = (st.search:GetText() or ""):lower()
    if text == "" then st.searchHint:Show() else st.searchHint:Hide() end
    local entries = { TRACKED }
    for _, d in ipairs(list) do
      local hay = (d.name .. " " .. (d.zone or "") .. " " .. table.concat(d.bosses or {}, " ")):lower()
      if text == "" or hay:find(text, 1, true) then entries[#entries + 1] = d end
    end
    local content = st.area.content
    for i, d in ipairs(entries) do
      local row = st.rows[i]
      if not row then
        row = makeRow(content, DLIST_W - 10, DUNGEON_H)
        row.thumb = row:CreateTexture(nil, "ARTWORK")
        row.thumb:SetSize(64, 32)
        row.thumb:SetPoint("LEFT", 8, 0)
        row.thumb:SetTexCoord(0.25, 0.75, 0, 1)   -- 4:1 afisin ortasi = 2:1
        row.a:SetPoint("TOPLEFT", 80, -7)
        row.a:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.a:SetWordWrap(false)
        row.b:SetPoint("TOPLEFT", 80, -24)
        row.b:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.b:SetWordWrap(false)
        row:SetScript("OnClick", press(function(r) select(r.dungeon) end))
        st.rows[i] = row
      end
      row.dungeon = d
            stretchRow(row, content, -(i - 1) * (DUNGEON_H + 2))
      if d == TRACKED then
        row.thumb:SetTexture(ART_DIR .. "tracked.png")
        row:SetTick(C.accent)
        row.a:SetText(L["Tracked items"])
        row.b:SetText(L["%d items"]:format(#J:Tracked()))
      else
        if row.thumb:SetTexture(ART_DIR .. (d.art or d.id) .. ".png") == false then row.thumb:SetTexture(ART_DIR .. "tracked.png") end
        row:SetTick(STATUS_COLOR[J:Status(d, level)])
        row.a:SetText(d.name)
        row.b:SetText(("%d-%d  |  %s"):format(d.minLevel, d.maxLevel, d.zone))
      end
      row:SetSelected(row.dungeon == st.selected)
      row:Show()
    end
    for i = #entries + 1, #st.rows do st.rows[i]:Hide(); st.rows[i].dungeon = nil end
    st.area:SetContentHeight(#entries * (DUNGEON_H + 2))
    return list
  end

  function page.refresh()
    local list = page.refreshList()
    st.mine:SetChecked(J.db.onlyMine, true)
    st.suggest:SetChecked(J.db.suggest, true)
    if J.focus then
      local d = J:Get(J.focus)
      J.focus = nil
      if d then
        st.selected = d
        -- sol listede o zindanin satirini gorunur yap
        for i, row in ipairs(st.rows) do
          if row.dungeon == d and row:IsShown() then st.area:ScrollTo((i - 1) * (DUNGEON_H + 2)) break end
        end
      end
    end
    local keep = st.selected
    if keep == TRACKED then select(TRACKED) return end
    for _, d in ipairs(list) do if d == keep then select(d) return end end
    select(list[1])
  end

  -- Esya bilgisi sonradan yuklenince listeyi tazele (olaylar arka arkaya gelir; tek karede topla).
  local pending
  ns:On("GET_ITEM_INFO_RECEIVED", page, function()
    -- IsVisible: pencere kapaliyken sayfanin kendi "gorunur" bayragi acik kalir (arka planda yeniden cizmesin)
    if pending or not (page.IsVisible and page:IsVisible()) then return end
    pending = true
    local function run() pending = false; if page:IsVisible() then page.renderDetail() end end
    if C_Timer and C_Timer.After then C_Timer.After(0.3, run) else run() end
  end)
end

-- Sayfa: Commands (konsol + komut listesi)
local CMD_H = 28

local function buildCommands(page)
  local st = { rows = {} }
  page.st = st

  st.hint = label(page, 10, C.textDim)
  place(page, st.hint, 0, 0, function(bw) return bw end)
  T(st.hint, "Type a command, e.g. help or guide list. Output appears in chat.")

  local function run()
    local text = (st.box:GetText() or ""):gsub("^%s*/?%s*[wW][fF]%s*", ""):gsub("^%s+", "")
    if text == "" then return end
    SlashCmdList.ARCANIS(text)
    st.box:SetText("")
  end

  st.box = Skin:CreateEditBox(page, BODY_W - 96, 26)
  st.box:SetPoint("TOPLEFT", 0, -24)
  function page.onResize(bw) st.box:SetWidth(bw - 96) end
  st.box:SetScript("OnEnterPressed", press(function() run() end))
  st.run = Skin:CreateButton(page, "", 88, 26)
  st.run:SetPoint("LEFT", st.box, "RIGHT", 8, 0)
  T(st.run, "Run")
  st.run:SetScript("OnClick", press(run))

  st.listHint = label(page, 10, C.textDim)
  st.listHint:SetPoint("TOPLEFT", 0, -62)
  T(st.listHint, "Click a command to put it in the console.")

  st.area = Skin:CreateScrollArea(page, BODY_W, BODY_H - 82)
  st.area:SetPoint("TOPLEFT", 0, -82)
  st.area:SetPoint("BOTTOMRIGHT", 0, 0)

  function page.refresh()
    local list = ns:ListCommands()
    local content = st.area.content
    for i, cmd in ipairs(list) do
      local row = st.rows[i]
      if not row then
        row = makeRow(content, BODY_W - 10, CMD_H)
        row.a:SetPoint("LEFT", 8, 0)
        row.b:SetPoint("LEFT", row, "LEFT", 130, 0)
        row.b:SetPoint("RIGHT", -6, 0)
        row.b:SetWordWrap(false)
        row:SetScript("OnClick", press(function(r)
          st.box:SetText(r.command .. " ")
          st.box:SetFocus()
        end))
        st.rows[i] = row
      end
      row.command = cmd.name
            stretchRow(row, content, -(i - 1) * (CMD_H + 2))
      row.a:SetText("/wf " .. cmd.name)
      row.a:SetTextColor(unpack(C.accent))
      row.b:SetText(L[cmd.help])
      row:Show()
    end
    for i = #list + 1, #st.rows do st.rows[i]:Hide() end
    st.area:SetContentHeight(#list * (CMD_H + 2))
  end
end

-- Sayfa: About
local function buildAbout(page)
  local y = section(page, "About", 0)
  page.lines = {}
  for i = 1, 3 do
    local fs = label(page, 12, C.text)
    fs:SetPoint("TOPLEFT", 0, -(y + (i - 1) * 24))
    page.lines[i] = fs
  end
  -- lisanslar: paketlenen ucuncu taraf dosyalari (yalniz font)
  local ly = section(page, "Licenses", y + 3 * 24 + 12)
  page.license = label(page, 11, C.textDim)
  page.license:SetPoint("TOPLEFT", 0, -ly)
  page.license:SetPoint("RIGHT", page, "RIGHT", -12, 0)
  page.license:SetJustifyH("LEFT")
  page.license:SetWordWrap(true)
  function page.refresh()
    page.lines[1]:SetText(L["Version: %s"]:format(ns.version))
    page.lines[2]:SetText(L["Active language: %s"]:format(ns:GetLocaleName(ns.localeCode)))
    page.lines[3]:SetText(L["Guides loaded: %d"]:format(#ns.Guides.order))
    page.license:SetText(L["Font: Righteous, Copyright (c) 2011 Brian J. Bonislawsky DBA Astigmatic (AOETI), Reserved Font Name \"Righteous\". Licensed under the SIL Open Font License 1.1 (Media/Fonts/LICENSE.txt)."])
  end
end

-- Pencere
Settings.BuildDungeons = buildDungeons   -- UI/DungeonWindow.lua kullanir
-- Sayfa: Top bar (ust ada) renkleri ve ortak hayalet etiket.
local ISLAND_BG = {
  { 0, 0, 0 }, { 0.08, 0.08, 0.10 }, { 0.05, 0.08, 0.16 }, { 0.12, 0.05, 0.16 },
  { 0.16, 0.04, 0.04 }, { 0.04, 0.12, 0.07 }, { 0.16, 0.12, 0.04 },
}

-- Ayni gezgin hayalet etiket iki duzenleyici icin
local islandGhost
local function ghostFrame()
  if islandGhost then return islandGhost end
  local g = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  g:SetFrameStrata("TOOLTIP")
  g:SetSize(140, 24)
  Skin:ApplyBackdrop(g, C.accentSoft, C.accent)
  g.text = label(g, 11, C.accentHover, "CENTER")
  g.text:SetPoint("CENTER")
  g:Hide()
  g:SetScript("OnUpdate", function(f)
    if not GetCursorPosition then return end
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale() or 1
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    if f.onMove then f.onMove() end
  end)
  islandGhost = g
  return g
end

-- Hub ogesinin genisligi: dort dik cubuk; satirdan kapladigi pay kadari dolu (tam 4, yarim 2, ceyrek 1).
local SIZE_FRACTION = { full = 1, half = 0.5, third = 1 / 3 }
local SIZE_TEXT = { full = "Full row", half = "Half a row", third = "Small tile" }
local BADGE_W, BADGE_BARS = 22, 4

local function sizeBadge(parent)
  local track = CreateFrame("Frame", nil, parent)
  track:SetSize(BADGE_W, 10)
  local b = { track = track, bars = {}, on = C.accent, off = C.border }
  for k = 1, BADGE_BARS do
    local t = track:CreateTexture(nil, "OVERLAY")
    t:SetSize(4, 10)
    t:SetPoint("LEFT", track, "LEFT", (k - 1) * 6, 0)
    b.bars[k] = t
  end
  function b:Paint()
    for k, t in ipairs(self.bars) do Skin:Fill(t, k <= (self.filled or 0) and self.on or self.off) end
  end
  function b:Set(size)
    local n = size and ns.Island.Hub and ns.Island.Hub.PerRow(size)
    self.size = size
    self.track:SetShown(n ~= nil)
    self.filled = n and math.max(1, math.floor(BADGE_BARS / n + 0.5)) or 0
    self:Paint()
  end
  function b:SetColors(on, off) self.on, self.off = on, off; self:Paint() end
  return b
end

-- Ekleme dugmeleri: tikla ekle, tekrar tikla cikar. Listede olan dugme vurgu
-- rengiyle dolu, olmayan koyu. Kart zemini yok; dugmeler bolumun icinde dogrudan durur.
-- items = { {id, name}, ... }; changed() iki listeyi ve tum dugmeleri yeniden boyar.
local ADD_COLS = 5
local function addGrid(b, list, items, changed)
  local I = ns.Island
  local rows = math.max(1, math.ceil(#items / ADD_COLS))
  local r = b:Block(rows * 30 + 8)
  r:SetBackdrop(nil)
  local grid = { buttons = {} }
  for k, d in ipairs(items) do
    local btn = CreateFrame("Button", nil, r, "BackdropTemplate")
    btn:SetHeight(24)
    btn.text = label(btn, 11, C.text, "CENTER")
    Skin:SetFont(btn.text, 11, "OUTLINE")
    btn.text:SetWordWrap(false)
    T(btn.text, d.name)
    btn.id = d.id
    -- hub dugmeleri satirdan kapladiklari payi da yazar (1/1, 1/2, 1/4...)
    local def = list == "hub" and I.HUB_DEFS[d.id]
    if def then
      btn.badge = sizeBadge(btn)
      btn.badge.track:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
      btn.text:SetPoint("LEFT", BADGE_W + 4, 0); btn.text:SetPoint("RIGHT", -BADGE_W - 4, 0)
    else
      btn.text:SetPoint("LEFT", 4, 0); btn.text:SetPoint("RIGHT", -4, 0)
    end
    btn:SetScript("OnClick", press(function()
      if I:Has(list, d.id) then
        for i, id in ipairs(I.db[list]) do if id == d.id then I:Remove(list, i) break end end
      else
        I:Insert(list, d.id)
      end
      changed()
    end))
    btn:SetScript("OnEnter", function(x) x:SetBackdropBorderColor(unpack(C.accentHover)) end)
    btn:SetScript("OnLeave", function() grid.paint() end)
    grid.buttons[k] = btn
  end
  local function layout()
    local w = r:GetWidth() or 0
    if w <= 0 then w = BODY_W - 2 end
    local cw = math.floor((w - (ADD_COLS - 1) * 8) / ADD_COLS)
    for k, btn in ipairs(grid.buttons) do
      local col, row = (k - 1) % ADD_COLS, math.floor((k - 1) / ADD_COLS)
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", r, "TOPLEFT", col * (cw + 8), -(4 + row * 30))
      btn:SetWidth(cw)
    end
  end
  function grid.paint()
    for _, btn in ipairs(grid.buttons) do
      local on = I:Has(list, btn.id)
      Skin:ApplyBackdrop(btn, on and C.accent or C.titleBg, on and C.accentHover or C.border)
      btn.text:SetTextColor(1, 1, 1, 1)
      if btn.badge then
        btn.badge.on, btn.badge.off = on and { 1, 1, 1, 1 } or C.accent, on and { 0, 0, 0, 0.35 } or C.border
        btn.badge:Set(I.HUB_DEFS[btn.id].size)
      end
    end
  end
  r:SetScript("OnSizeChanged", layout)
  layout()
  grid.paint()
  return grid
end

-- Sirali liste: ogeyi baska ogenin ustune surukle (sira degisir), kutunun disina birak ya da sag tikla (cikar).
-- sizeOf verilirse (hub) ogeler hub'daki satirlar gibi dizilir, her satirin arkasinda soluk serit olur ve bolum
-- basliklari adlarini kendi satirlarinda yazdiran bir kutu tasir. names: { [id] = ad }.
-- Dondurur: duzenleyici (paint, begin, drop, rows testler icin).
local function orderList(ob, list, names, sizeOf, changed)
  local I = ns.Island
  local count = 0
  for _ in pairs(names) do count = count + 1 end
  local TOP = sizeOf and 30 or 12
  local box = ob:Block(TOP + 36)
  local ed = { chips = {}, rowBg = {} }
  local g = ghostFrame()

  if sizeOf then
    ed.legend = {}
    local right
    local order = {}
    for size in pairs(SIZE_FRACTION) do order[#order + 1] = size end
    table.sort(order, function(a, b) return SIZE_FRACTION[a] < SIZE_FRACTION[b] end)   -- sagdan: kutucuk, yarim, tam
    for _, size in ipairs(order) do
      local t = label(box, 9, C.textDim, "RIGHT")
      if right then t:SetPoint("RIGHT", right.track, "LEFT", -10, 0) else t:SetPoint("TOPRIGHT", box, "TOPRIGHT", -12, -12) end
      T(t, SIZE_TEXT[size])
      local b = sizeBadge(box)
      b.track:SetPoint("RIGHT", t, "LEFT", -4, 0)
      b:Set(size)
      ed.legend[size] = b
      right = b
    end
  end
  ed.area = CreateFrame("Frame", nil, box)
  ed.area:SetPoint("TOPLEFT", 8, -(TOP - 4)); ed.area:SetPoint("TOPRIGHT", -8, -(TOP - 4))
  ed.empty = label(box, 10, C.textDim)
  ed.empty:SetPoint("TOPLEFT", 12, -(TOP + 5))
  T(ed.empty, "Empty. Add items from the sections above.")

  local function groupOf(id) return id and tonumber(id:match("^group(%d)$")) end
  local layout
  function ed.paint()
    local t = I.db[list]
    for i, ch in ipairs(ed.chips) do
      local id = t[i]
      local n = groupOf(id)
      if ch.badge then ch.badge:Set(id and sizeOf(id)) end
      if id then
        ch.text:SetText(n and ("%d. %s"):format(i, L["Section"]) or ("%d. %s"):format(i, L[names[id] or id]))
        if n or not sizeOf then ch.text:SetJustifyH("LEFT") else ch.text:SetJustifyH("CENTER") end
        ch:SetBackdropBorderColor(unpack(ed.drag and ch:IsMouseOver() and C.accent or C.border))
        ch:Show()
      else
        ch:Hide()
      end
      if ch.nameBox then
        ch.nameBox:SetShown(n ~= nil)
        if n and not (ch.nameBox.HasFocus and ch.nameBox:HasFocus()) then ch.nameBox:SetText(I.db.groupNames[n] or "") end
      end
      if ch.paintStyle and id then ch.paintStyle(I.db.itemStyle[id] or {}) end
    end
    ed.empty:SetShown(#t == 0)
    layout()
  end

  -- surukleme sirasinda yalniz kenarlar boyanir; yerlesim her karede yeniden kurulmaz
  local function hover()
    for _, ch in ipairs(ed.chips) do
      if ch:IsShown() then ch:SetBackdropBorderColor(unpack(ed.drag and ch:IsMouseOver() and C.accent or C.border)) end
    end
  end
  function ed.begin(state, text)
    ed.drag = state
    g.text:SetText(text)
    g.onMove = hover
    g:Show()
  end
  -- target: { index = i } (bir ogenin ustu), { after = i } (satirin bos yeri: o satirin son ogesi i'nin arkasi),
  -- "area" (listenin bos yeri) ya da nil (kutunun disi)
  function ed.drop(target)
    local d = ed.drag
    ed.drag = nil
    g:Hide(); g.onMove = nil
    if not d then return end
    local t = I.db[list]
    local at = type(target) == "table" and (target.index or target.after + 1) or nil
    if d.index then
      if at then
        if target.after and d.index <= target.after then at = at - 1 end   -- cikarilinca arkasindakiler bir kayar
        I:Move(list, d.index, at)
      elseif target == "area" then I:Move(list, d.index, #t)
      else I:Remove(list, d.index) end
    elseif d.id and target then
      I:Insert(list, d.id, at)
    end
    changed()
  end
  local function under()
    for i, ch in ipairs(ed.chips) do if ch:IsShown() and ch:IsMouseOver() then return { index = i } end end
    for j, bg in ipairs(ed.rowBg) do
      if bg:IsShown() and bg.IsMouseOver and bg:IsMouseOver() and ed.rowLast[j] then return { after = ed.rowLast[j] } end
    end
    if ed.area:IsMouseOver() then return "area" end
  end
  ed.under = under

  for i = 1, count do
    local ch = CreateFrame("Button", nil, box, "BackdropTemplate")
    ch:SetHeight(22)
    Skin:ApplyBackdrop(ch, C.card, C.border)
    ch.text = label(ch, 10, C.text, "CENTER")
    ch.text:SetWordWrap(false)
    ch.text:SetPoint("LEFT", ch, "LEFT", 8, 0)
    -- x: ogeyi listeden cikarir
    ch.del = Skin:CreateIconButton(ch, "close", 18)
    ch.del:SetPoint("RIGHT", ch, "RIGHT", -2, 0)
    ch.del:SetScript("OnClick", press(function() I:Remove(list, i); changed() end))
    if sizeOf then
      ch.badge = sizeBadge(ch)
      ch.badge.track:SetPoint("RIGHT", ch.del, "LEFT", -4, 0)
      ch.text:SetPoint("RIGHT", ch, "RIGHT", -BADGE_W - 30, 0)
      -- bolum basligi: adi bu satirda yazilir
      ch.nameBox = Skin:CreateEditBox(ch, 200, 18, function(text, user)
        local n = groupOf(I.db[list][i])
        if user and n then I.db.groupNames[n] = text; I:Changed() end
      end)
      ch.nameBox:SetPoint("LEFT", ch, "LEFT", 110, 0)
      ch.nameBox:SetPoint("RIGHT", ch, "RIGHT", -BADGE_W - 34, 0)
      ch.nameBox:Hide()
    else
      -- serit listesi: tam genislik numarali satir, sagda tutamak (surukle) ve x
      ch.grip = ch:CreateTexture(nil, "OVERLAY")
      ch.grip:SetSize(12, 12)
      ch.grip:SetPoint("RIGHT", ch.del, "LEFT", -8, 0)
      ch.grip:SetTexture(Skin.Icons.menu)
      ch.grip:SetVertexColor(unpack(C.accent))
      ch.text:SetJustifyH("LEFT")
      -- oge basina yazi ayarlari (db.itemStyle[id]): renk (tikla: sonraki renk), boyut (- / +), kenar cizgisi
      local function style()
        local id = I.db[list][i]
        I.db.itemStyle[id] = I.db.itemStyle[id] or {}
        return I.db.itemStyle[id]
      end
      local function set(fn) return press(function(...) fn(style(), ...); I:Changed(); ed.paint() end) end
      -- renk: secici acilir; sag tik genel yazi rengine dondurur
      ch.color = Skin:CreateColorButton(ch, function()
        local id = I.db[list][i]
        return I:ColorOf((I.db.itemStyle[id] or {}).color, I:TextColor())
      end, set(function(s, c) s.color = { c[1], c[2], c[3] } end), 18, 18)
      ch.color:SetPoint("RIGHT", ch.grip, "LEFT", -12, 0)
      ch.color:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      local pick = ch.color:GetScript("OnClick")
      ch.color:SetScript("OnClick", function(b, button)
        if button == "RightButton" then set(function(s) s.color = nil end)() else pick(b, button) end
      end)
      ch.plus = Skin:CreateIconButton(ch, "plus", 18)
      ch.plus:SetPoint("RIGHT", ch.color, "LEFT", -10, 0)
      ch.sizeText = label(ch, 10, C.text, "CENTER")
      ch.sizeText:SetWidth(20)
      ch.sizeText:SetPoint("RIGHT", ch.plus, "LEFT", -2, 0)
      ch.minus = Skin:CreateIconButton(ch, "minus", 18)
      ch.minus:SetPoint("RIGHT", ch.sizeText, "LEFT", -2, 0)
      local function step(d)
        return set(function(s) s.size = math.max(8, math.min(18, (s.size or I.db.fontSize or 11) + d)) end)
      end
      ch.plus:SetScript("OnClick", step(1)); ch.minus:SetScript("OnClick", step(-1))
      ch.outline = Skin:CreateCheckbox(ch, "", false, set(function(s, on) s.outline = on or nil end), 16)
      T(ch.outline.label, "Outline")
      ch.outline:SetSize(90, 18)
      ch.outline:SetPoint("RIGHT", ch.minus, "LEFT", -12, 0)
      ch.text:SetPoint("RIGHT", ch.outline, "LEFT", -8, 0)
      function ch.paintStyle(s)
        ch.color:Refresh()
        ch.sizeText:SetText(tostring(s.size or I.db.fontSize or 11))
        ch.outline:SetChecked(s.outline, true)
      end
    end
    ch:RegisterForDrag("LeftButton")
    ch:RegisterForClicks("RightButtonUp")
    ch:SetScript("OnDragStart", function()
      local id = I.db[list][i]
      if id then ed.begin({ index = i }, groupOf(id) and L["Section"] or L[names[id] or id]) end
    end)
    ch:SetScript("OnDragStop", function() ed.drop(under()) end)
    ch:SetScript("OnClick", press(function() I:Remove(list, i); changed() end))
    ch:SetScript("OnEnter", function(x)
      x:SetBackdropBorderColor(unpack(C.accent))
      local size = x.badge and x.badge.size
      if size and GameTooltip then
        GameTooltip:SetOwner(x, "ANCHOR_TOP")
        GameTooltip:SetText(L[SIZE_TEXT[size]])
        GameTooltip:Show()
      end
    end)
    ch:SetScript("OnLeave", function(x)
      x:SetBackdropBorderColor(unpack(C.border))
      if GameTooltip then GameTooltip:Hide() end
    end)
    ed.chips[i] = ch
  end

  local function boxWidth()
    local w = box:GetWidth() or 0
    return w > 0 and w or BODY_W - 2
  end
  -- serit listesi: satir basina bir oge; hub listesi: hub'daki gibi genislige gore dolan satirlar (Hub.Pack),
  -- her oge kapladigi pay kadar genis. ed.rowLast[j]: j. satirin son ogesi (satirin bos yerine birakmak icin).
  local function place()
    local w, t = boxWidth(), I.db[list]
    local rows
    if sizeOf then
      rows = ns.Island.Hub.Pack(t, function(id) return sizeOf(id) or "full" end)
    else
      rows = {}
      for i, id in ipairs(t) do rows[i] = { { index = i, id = id, at = 0, frac = 1 } } end
    end
    local unit = w - 24 + 8
    ed.rowLast = {}
    for r, row in ipairs(rows) do
      for _, s in ipairs(row) do
        local ch = ed.chips[s.index]
        if ch then
          ch:ClearAllPoints()
          ch:SetPoint("TOPLEFT", box, "TOPLEFT", 12 + math.floor(s.at * unit + 0.5), -(TOP + (r - 1) * 26))
          ch:SetWidth(math.floor(s.frac * unit - 8))
        end
        ed.rowLast[r] = s.index
      end
    end
    return #rows
  end
  layout = function()
    local rows = place()
    if sizeOf then
      for j = 1, math.max(rows, #ed.rowBg) do
        local bg = ed.rowBg[j]
        if not bg then
          -- cerceve (doku degil): satirin bos yerine birakilinca IsMouseOver ile bulunur; fareyi tutmaz
          bg = CreateFrame("Frame", nil, box)
          bg:SetFrameLevel(box:GetFrameLevel())
          bg.fill = bg:CreateTexture(nil, "BACKGROUND")
          bg.fill:SetAllPoints()
          Skin:Fill(bg.fill, C.border)
          bg.fill:SetAlpha(0.35)
          ed.rowBg[j] = bg
        end
        bg:ClearAllPoints()
        bg:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -(TOP - 2 + (j - 1) * 26))
        bg:SetPoint("TOPRIGHT", box, "TOPRIGHT", -8, -(TOP - 2 + (j - 1) * 26))
        bg:SetHeight(24)
        bg:SetShown(j <= rows)
      end
    end
    ed.rows = rows
    local shown = math.max(1, rows)
    ed.area:SetHeight(shown * 26 + 8)
    ob:Resize(box, TOP + shown * 26 + 10)
  end
  box:SetScript("OnSizeChanged", layout)
  ed.paint()
  return ed
end

local function nameMap(...)
  local m = {}
  for _, defs in ipairs({ ... }) do
    for _, d in ipairs(defs) do if not m[d.id] then m[d.id] = d.name end end   -- kart kimligi kutucugunkini gizler (gold)
  end
  return m
end

-- Sayfa: Top bar. Iki sekme: Bar (serit) ve Hub. Her sekmede kapali ayar bolumleri, kategorilere ayrilmis ekleme
-- dugmeleri ve en altta sirali liste.
local function buildIsland(page)
  local I = ns.Island
  local editors, grids = {}, {}
  local function changed()
    for _, ed in pairs(editors) do ed.paint() end
    for _, gr in ipairs(grids) do gr.paint() end
    I:Changed()
  end

  -- renk: tek dugme (tiklayinca renk secici) ve yaninda varsayilana donus. I.db[field] secilen {r,g,b} olur;
  -- resolve() su anki rengi verir (hazir kimlik ya da tablo). rebuild: hub kartlari yeniden kurulur (yazi rengi).
  page.colors = {}
  local function colorRow(b, titleKey, descKey, field, resolve, default, rebuild)
    local out
    b:Custom(titleKey, descKey, 20 + 8 + 22, function(r)
      out = Skin:CreateColorButton(r, resolve, press(function(c)
        I.db[field] = { c[1], c[2], c[3] }; I:Changed(rebuild)
      end))
      out.reset = Skin:CreateIconButton(r, "repeat", 22)
      out.reset:SetTooltip(L["Reset"])
      out.reset:SetPoint("RIGHT", r, "RIGHT", -12, 0)
      out:SetPoint("RIGHT", out.reset, "LEFT", -8, 0)
      out.reset:SetScript("OnClick", press(function()
        I.db[field] = type(default) == "table" and { default[1], default[2], default[3] } or default
        I:Changed(rebuild); out:Refresh()
      end))
    end)
    page.colors[field] = out
    return out
  end

  local panes = {}
  local tabs = Skin:CreateTabBar(page, { { id = "bar", text = L["Bar"] }, { id = "hub", text = L["Hub"] },
    { id = "chat", text = L["Chat"] } }, function(id)
    for k, p in pairs(panes) do p:SetShown(k == id) end
    page.tab = id
  end)
  T(tabs.tabs.bar.text, "Bar"); T(tabs.tabs.hub.text, "Hub"); T(tabs.tabs.chat.text, "Chat")
  tabs:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0); tabs:SetPoint("TOPRIGHT", page, "TOPRIGHT", -2, 0)
  for id in pairs({ bar = true, hub = true, chat = true }) do
    local p = CreateFrame("Frame", nil, page)
    p:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40); p:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    panes[id] = p
  end
  page.tabs = tabs

  -- ----- Bar -----
  local ob = optionList(panes.bar)
  -- ozelligin ana anahtari (eski Features listesinden)
  local island = ns:GetModule("Island")
  if island then
    page.master = ob:Switch("Dynamic Hub", "A small bar at the top of the screen with your zone, step, level and gold. It grows to show notices; click it for zone info.",
      function() return island:IsEnabled() end, function(v) island:SetEnabled(v) end)
  end
  local s = ob:Section("Bar settings")
  local function visibleItems()
    local items = { { value = "all", text = L["All"] }, { value = 0, text = L["Only the eyes"] } }
    for n = 1, 5 do items[#items + 1] = { value = n, text = tostring(n) } end
    return items
  end
  s:Dropdown("Shown when closed", "The rest slide out when you point at the bar. With Only the eyes, two eyes watch you until you do.",
    visibleItems, function() return I.db.visible end, function(v) I.db.visible = v; I:Changed() end)
  colorRow(s, "Background", "Colour of the bar and the hub.", "bg", function() return I.db.bg end, ISLAND_BG[1])
  s:Slider("Opacity", "How see-through the bar and the hub are.", 30, 100, 5,
    function() return math.floor((I.db.alpha or 0.92) * 100 + 0.5) end,
    function(v) I.db.alpha = v / 100; I:Changed() end, "%d%%")
  local function sepItems()
    local items = {}
    for _, sp in ipairs(I.SEPARATORS) do
      local t = sp.text
      if sp.id == "none" then t = L["None"] elseif sp.id == "custom" then t = L["Custom"] end
      items[#items + 1] = { value = sp.id, text = t }
    end
    return items
  end
  s:Dropdown("Separator", "Mark between bar items.", sepItems, function() return I.db.sep end,
    function(v) I.db.sep = v; I:Changed() end)
  s:Custom("Custom separator", "Your own mark, used when Separator is Custom.", 120, function(r)
    page.sepBox = Skin:CreateEditBox(r, 120, 22, function(t, user)
      if user then I.db.sepText = t:sub(1, 8); I:Changed() end
    end)
    page.sepBox:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    page.sepBox:SetText(I.db.sepText or "")
  end)
  s:Slider("Text size", nil, 9, 15, 1, function() return I.db.fontSize end,
    function(v) I.db.fontSize = v; I:Changed() end, "%d")
  colorRow(s, "Text colour", nil, "textColor", function() return I:TextColor() end, "theme")
  s:Switch("Highlight the first item", nil, function() return I.db.accentFirst end,
    function(v) I.db.accentFirst = v; I:Changed() end)

  local e = ob:Section("Eyes")
  e:Dropdown("Eye style", "Glow: soft glowing ovals that doze off when nothing happens. Classic: drawn eyes with pupils and brows.",
    function() return { { value = "glow", text = L["Glow"] }, { value = "classic", text = L["Classic"] } } end,
    function() return I.db.eyeStyle end, function(v) I.db.eyeStyle = v; changed() end)
  colorRow(e, "Eye colour", nil, "eyeColor", function() return I:PickColor(I.EYE_COLORS, I.db.eyeColor) end, "white")
  e:Slider("Eye height", "Lower values make the eyes flatter.", 60, 130, 5,
    function() return I.db.eyeHeight end, function(v) I.db.eyeHeight = v end, "%d%%")
  e:Switch("Pupils", "Pupils that follow your cursor and close when the eyes blink.",
    function() return I.db.pupils end, function(v) I.db.pupils = v end)
  colorRow(e, "Pupil colour", nil, "pupilColor", function() return I:PickColor(I.PUPIL_COLORS, I.db.pupilColor) end, "black")
  e:Slider("Pupil size", nil, 50, 180, 10,
    function() return I.db.pupilSize end, function(v) I.db.pupilSize = v end, "%d%%")
  e:Switch("Eyebrows", "Straight brows over the eyes of an empty bar.", function() return I.db.brows end,
    function(v) I.db.brows = v end)
  colorRow(e, "Brow colour", nil, "browColor", function() return I:PickColor(I.EYE_COLORS, I.db.browColor) end, "white")
  e:Slider("Brow angle", "Above 0 the inner ends tilt down (grumpy), below 0 they tilt up (worried).", -30, 30, 5,
    function() return I.db.browAngle end, function(v) I.db.browAngle = v end, "%d°")

  local la = ob:Section("Live activities")
  la:Switch("Live activities", "Small timers beside the bar while something is running.",
    function() return I.db.live end, function(v) I.db.live = v; changed() end)
  la:Switch("Flight", "Time left on a flight path you have flown before; on a new one, time in the air.",
    function() return I.db.liveFlight end, function(v) I.db.liveFlight = v; changed() end)
  la:Switch("Hearthstone", "Counts down the last 5 minutes of the cooldown and tells you when it is ready.",
    function() return I.db.liveHearth end, function(v) I.db.liveHearth = v; changed() end)
  la:Switch("Timed quest", "Time left on a timed quest.",
    function() return I.db.liveQuest end, function(v) I.db.liveQuest = v; changed() end)
  la:Switch("Fishing lure", "Time left on your fishing lure while you fish.",
    function() return I.db.liveLure end, function(v) I.db.liveLure = v; changed() end)
  la:Switch("Boats and zeppelins", "Near a dock, time to the next departure. Ride a line once so its times are known.",
    function() return I.db.liveBoat end, function(v) I.db.liveBoat = v; changed() end)
  la:Switch("Profession cast bar", "While you gather, fish or craft, the bar shows the cast, its time and what you got.",
    function() return I.db.castBar end, function(v) I.db.castBar = v; changed() end)

  local n = ob:Section("Notices and animation")
  n:Switch("Show notices in the Dynamic Hub", "Alerts appear in the bar instead of a separate box.",
    function() return I.db.toasts end, function(v) I.db.toasts = v end)
  n:Switch("Peek on hover", "Rest the cursor on the bar to see your current guide step under it.",
    function() return I.db.peek end, function(v) I.db.peek = v; changed() end)
  n:Switch("Hide in combat", "The bar disappears while you are fighting.",
    function() return I.db.hideCombat end, function(v) I.db.hideCombat = v; changed() end)
  n:Switch("Hide during cinematics", "The bar disappears while a cinematic or movie plays.",
    function() return I.db.hideCinematic end, function(v) I.db.hideCinematic = v; changed() end)
  n:Switch("Mail icon", "A small envelope at the end of the bar while you have unread mail.",
    function() return I.db.badgeMail end, function(v) I.db.badgeMail = v; changed() end)
  n:Switch("Whisper icon", "A chat bubble at the end of the bar after a whisper, until you open the hub.",
    function() return I.db.badgeWhisper end, function(v) I.db.badgeWhisper = v; changed() end)
  n:Switch("Zone entry", "Shows the zone and its level range when you enter it.",
    function() return I.db.zone end, function(v) I.db.zone = v end)
  n:Switch("Hub on click", "Click the bar to open the hub. Right-click opens these settings.",
    function() return I.db.card end, function(v) I.db.card = v end)
  n:Slider("Notice time", "How long a notice stays before the bar shrinks.", 2, 8, 1,
    function() return I.db.hold end, function(v) I.db.hold = v end, "%ds")
  n:Slider("Jelly", "How much the bar wobbles when it changes size.", 0, 100, 5,
    function() return I.db.jelly end, function(v) I.db.jelly = v end, "%d%%")
  n:Buttons("Preview", "Shows a sample notice.", { { "Preview", function() I:Preview() end, true } })

  ob:Header("Add to the bar", "Click an item to add it, click it again to remove it. Filled items are on the bar.")
  local byId, listed, other = {}, {}, {}
  for _, el in ipairs(I.ELEMENTS) do byId[el.id] = el end
  for _, cat in ipairs(I.CATEGORIES) do
    local items = {}
    for _, id in ipairs(cat.ids) do
      if byId[id] then items[#items + 1] = byId[id]; listed[id] = true end
    end
    local c = ob:Section(cat.name)
    grids[#grids + 1] = addGrid(c, "strip", items, changed)
  end
  for _, el in ipairs(I.ELEMENTS) do if not listed[el.id] then other[#other + 1] = el end end
  if #other > 0 then
    local c = ob:Section("Other")
    grids[#grids + 1] = addGrid(c, "strip", other, changed)
  end
  ob:Header("On the bar", "Left to right on the bar. Drag a row onto another to move it; × removes it.")
  page.stripEditor = orderList(ob, "strip", nameMap(I.ELEMENTS), nil, changed)
  editors.strip = page.stripEditor
  ob:Finish()

  -- ----- Hub -----
  local hob = optionList(panes.hub)
  local hs = hob:Section("Hub settings")
  hs:Switch("Pages", "The hub shows one page at a time. Change pages with the arrows or the mouse wheel; each group starts a page.",
    function() return I.db.hubPages end, function(v) I.db.hubPages = v; I.Hub.page = 1; changed() end)
  hs:Switch("Shortcut bar", "A row at the bottom of the hub with buttons for the guide, dungeons, gold and settings.",
    function() return I.db.hubShortcuts end, function(v) I.db.hubShortcuts = v; changed() end)
  hs:Dropdown("Card style", "Gradient: each card fades into its own colour at the bottom.",
    function() return { { value = "flat", text = L["Flat"] }, { value = "gradient", text = L["Gradient"] } } end,
    function() return I.db.cardStyle end, function(v) I.db.cardStyle = v; changed() end)
  hs:Dropdown("Gauges", "How progress cards (durability, quests, guide, Hearthstone, reputation) are drawn: a ring with the value in the middle, or a flat bar.",
    function() return { { value = "ring", text = L["Ring"] }, { value = "bar", text = L["Bar"] } } end,
    function() return I.db.gaugeStyle end, function(v) I.db.gaugeStyle = v; changed() end)
  hs:Slider("Hub width", nil, 380, 560, 20, function() return I.db.width end,
    function(v) I.db.width = v; I:Changed() end, "%d")
  hs:Slider("Items per row", "How many small tiles sit side by side in the hub. Half cards always pair up.", 2, 4, 1,
    function() return I.db.hubCols end, function(v)
      I.db.hubCols = v; I:Changed()
      page.hubEditor.paint()
      page.hubEditor.legend.third:Set("third")
      for _, gr in ipairs(page.grids or {}) do gr.paint() end
    end, "%d")
  hs:Slider("Hub text size", nil, 9, 14, 1, function() return I.db.hubFont end,
    function(v) I.db.hubFont = v; I:Changed(true) end, "%d")
  colorRow(hs, "Card colour", "Fill and edge colour of the hub cards.", "cardColor", function() return I:CardColor() end, "white")
  hs:Slider("Card fill", "How strong the card colour is behind the text.", 0, 60, 1,
    function() return I.db.cardAlpha end, function(v) I.db.cardAlpha = v; I:Changed() end, "%d%%")
  hs:Slider("Card edge", "How visible the card outline is. 0 hides it.", 0, 100, 2,
    function() return I.db.cardBorder end, function(v) I.db.cardBorder = v; I:Changed() end, "%d%%")
  colorRow(hs, "Card title colour", "Small titles such as SESSION or FPS.", "cardTitle",
    function() return I.Hub.TitleColor() end, "theme", true)
  colorRow(hs, "Card value colour", "The numbers and names inside the cards.", "cardValue",
    function() return I:ColorOf(I.db.cardValue, C.text) end, "theme", true)
  colorRow(hs, "XP bar colour", nil, "xpColor", function() return I.Hub.XPColor() end, "purple")

  hob:Header("Add to the hub", "Click an item to add it, click it again to remove it. Filled items are in the hub.")
  local cards = hob:Section("Cards", true)
  grids[#grids + 1] = addGrid(cards, "hub", I.CARDS, changed)
  -- kucuk kutucuklar bardaki gibi kategorilere ayrilir
  local isTile = function(id) return I.HUB_DEFS[id] and I.HUB_DEFS[id].tile end
  local tileListed, tileOther = {}, {}
  for _, cat in ipairs(I.CATEGORIES) do
    local items = {}
    for _, id in ipairs(cat.ids) do
      if byId[id] and isTile(id) then items[#items + 1] = byId[id]; tileListed[id] = true end
    end
    if #items > 0 then grids[#grids + 1] = addGrid(hob:Section(cat.name), "hub", items, changed) end
  end
  for _, el in ipairs(I.ELEMENTS) do if isTile(el.id) and not tileListed[el.id] then tileOther[#tileOther + 1] = el end end
  if #tileOther > 0 then grids[#grids + 1] = addGrid(hob:Section("Other"), "hub", tileOther, changed) end
  page.addSection = hob:Buttons("Section title", "A heading line between hub cards, up to four. Type its name in its row below.",
    { { "Add section title", function()
      for _, gr in ipairs(I.GROUPS) do
        if not I:Has("hub", gr.id) then I:Insert("hub", gr.id); break end
      end
      changed()
    end, true } })
  hob:Header("In the hub", "Top to bottom; each shaded strip is one row of the hub. Drag to move; × removes.")
  page.hubEditor = orderList(hob, "hub", nameMap(I.CARDS, I.GROUPS, I.ELEMENTS), function(id)
    local d = I.HUB_DEFS[id]
    return d and d.size
  end, changed)
  editors.hub = page.hubEditor
  hob:Finish()

  -- ----- Chat (fisilti sohbeti, Messenger ayarlari) -----
  local cob = optionList(panes.chat)
  local Ms = ns.Messenger
  local function chatChanged() if I.Chat then ns.SafeCall(I.Chat.Apply, I.Chat) end end
  local ms = ns:GetModule("Messenger")
  if ms then
    cob:Switch("Messages", "Whispers as conversations on the Dynamic Hub: click a whisper notice or the hub to read and reply, click a message to copy it.",
      function() return ms:IsEnabled() end, function(v) ms:SetEnabled(v) end)
  end
  local look = cob:Section("Look")
  look:Dropdown("Chat size", "How big the chat opens on the hub.",
    function() return { { value = "compact", text = L["Compact"] }, { value = "normal", text = L["Normal"] }, { value = "large", text = L["Large"] } } end,
    function() return Ms.db.chatSize end, function(v) Ms.db.chatSize = v; chatChanged() end)
  look:Slider("Message text size", nil, 10, 16, 1, function() return Ms.db.chatFont end,
    function(v) Ms.db.chatFont = v; chatChanged() end, "%d")
  look:Dropdown("Bubble style", "Light: light bubbles with dark text, the easiest to read. Accent: your messages in the theme colour. Whisper: the game's whisper tone. Minimal: light outlines only.",
    function() return { { value = "clear", text = L["Light"] }, { value = "accent", text = L["Accent"] }, { value = "whisper", text = L["Whisper"] }, { value = "minimal", text = L["Minimal"] } } end,
    function() return Ms.db.bubbleStyle end, function(v) Ms.db.bubbleStyle = v; chatChanged() end)
  look:Switch("Avatars", "A round badge with the first letter of each name, in the class colour.",
    function() return Ms.db.avatars ~= false end, function(v) Ms.db.avatars = v; chatChanged() end)
  look:Switch("Time in messages", "Shows the time inside each message bubble.",
    function() return Ms.db.times ~= false end, function(v) Ms.db.times = v; chatChanged() end)
  look:Switch("Emojis", "Shows smileys such as :) and emoji characters as small pictures, and adds a picker next to the message box.",
    function() return Ms.db.emoji ~= false end, function(v) Ms.db.emoji = v; chatChanged() end)
  local beh = cob:Section("Behaviour")
  beh:Switch("Open on new whisper", "Opens the chat on the hub as soon as a whisper arrives (not in combat).",
    function() return Ms.db.openOnWhisper end, function(v) Ms.db.openOnWhisper = v end)
  beh:Switch("Keep message history", "Saves whispers for this character between sessions. Off: only this session. Battle.net messages are never saved.",
    function() return Ms.db.history end, function(v) Ms.db.history = v end)
  beh:Slider("Messages per conversation", "Older messages are removed beyond this.", 50, 500, 50,
    function() return Ms.db.maxMsgs end, function(v) Ms.db.maxMsgs = v end, "%d")
  beh:Slider("Conversations kept", "The oldest conversation is removed beyond this.", 10, 80, 10,
    function() return Ms.db.maxConvos end, function(v) Ms.db.maxConvos = v end, "%d")
  cob:Buttons("Delete all messages", "Removes every conversation of this character.", { { "Delete all messages", function() Ms:ClearAll() end } })
  cob:Finish()

  page.grids = grids
  tabs:Select(page.tab or "bar")
  page.refresh = function()
    if panes.bar.refresh then panes.bar.refresh() end
    if panes.hub.refresh then panes.hub.refresh() end
    if panes.chat.refresh then panes.chat.refresh() end
    for _, ed in pairs(editors) do ed.paint() end
    for _, gr in ipairs(grids) do gr.paint() end
  end
end

-- Sayfa: System. Alt sekmeler: bakim, bolgeler, komutlar, hakkinda (gunluk ayar degil).
local SYSTEM_TABS = {
  { id = "maintenance", title = "Maintenance", build = buildMaintenance },
  -- bakim araci, sekme cubugunda yok (sahibin karari, 15 Kasim 2026: kafa karistiriyordu); /wf settings zones acar
  { id = "zones", title = "Zones", build = buildZones, hidden = true },
  { id = "commands", title = "Commands", build = buildCommands },
  { id = "about", title = "About", build = buildAbout },
}
local function buildSystem(page)
  local panes, items = {}, {}
  for _, t in ipairs(SYSTEM_TABS) do
    if not t.hidden then items[#items + 1] = { id = t.id, text = L[t.title] } end
  end
  local tabs = Skin:CreateTabBar(page, items, function(id)
    for k, p in pairs(panes) do p:SetShown(k == id) end
    page.sub = id
    if panes[id] and panes[id].refresh then ns.SafeCall(panes[id].refresh) end
  end)
  for _, t in ipairs(SYSTEM_TABS) do if tabs.tabs[t.id] then T(tabs.tabs[t.id].text, t.title) end end
  tabs:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0); tabs:SetPoint("TOPRIGHT", page, "TOPRIGHT", -2, 0)
  for _, t in ipairs(SYSTEM_TABS) do
    local p = CreateFrame("Frame", nil, page)
    p:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40); p:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    panes[t.id] = p
    ns.SafeCall(t.build, p)
  end
  page.tabs, page.panes = tabs, panes
  page.refresh = function() local p = panes[page.sub]; if p and p.refresh then ns.SafeCall(p.refresh) end end
  page.onResize = function(bw)
    for _, p in pairs(panes) do
      for _, fn in ipairs(p.fluids or {}) do ns.SafeCall(fn, bw) end
      if p.onResize then ns.SafeCall(p.onResize, bw) end
    end
  end
  tabs:Select("maintenance")
end

-- Dynamic Hub ayarlari baska bir cerceveye (ana pencerenin Hub bolumu)
function Settings:BuildIslandInto(frame)
  return buildIsland(frame)
end

-- Ust sekmeler: Modules (modul ac/kapa + her modulun kendi ayarlari), General, System. Dynamic Hub ve Guides
-- sekmesiz (hidden): modulun dislisi / rehber listesi yedegi acar.
local PAGES = {
  { id = "modules",    title = "Modules",    build = buildModules },
  { id = "appearance", title = "General",    build = buildAppearance },
  { id = "system",     title = "System",     build = buildSystem },
  { id = "island",     title = "Dynamic Hub", build = buildIsland, hidden = true },
  { id = "guides",     title = "Guides",     build = buildGuides, hidden = true },
}
-- eski sayfa adlari (/wf settings <ad>, kayitli son sayfa): { sayfa, alt sekme }
local PAGE_ALIAS = {
  general = { "appearance" }, interface = { "modules" }, arrow = { "modules" }, window = { "modules" },
  pins = { "modules" }, quests = { "modules" }, route = { "modules" }, helpers = { "modules" },
  maintenance = { "system", "maintenance" }, zones = { "system", "zones" },
  commands = { "system", "commands" }, about = { "system", "about" },
}

-- Gomulu kurulum: ayarlar Arcanis Path ana penceresinin "Settings" sayfasina sekmeli olarak yerlesir
-- (ayri pencere acilmaz). host: o sayfanin cercevesi.
function Settings:BuildEmbedded(host)
  self.embedded = true
  self.frame = host
  self.nav, self.pages = {}, {}
  local tabs = CreateFrame("Frame", nil, host)
  tabs:SetPoint("TOPLEFT", 0, 0)
  tabs:SetPoint("TOPRIGHT", 0, 0)
  tabs:SetHeight(32)
  tabs.line = tabs:CreateTexture(nil, "ARTWORK")
  Skin:Fill(tabs.line, C.border)
  ns.Skin:Hairline(tabs.line, "h")
  tabs.line:SetPoint("BOTTOMLEFT"); tabs.line:SetPoint("BOTTOMRIGHT")
  self.tabs = tabs
  local body = CreateFrame("Frame", nil, host)
  body:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -44)
  body:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
  body:SetClipsChildren(true)
  self.body = body
  local x = 0
  for i, def in ipairs(PAGES) do
    local tab = CreateFrame("Button", nil, tabs, "BackdropTemplate")
    tab:SetHeight(32)
    tab.text = label(tab, 12, C.textDim, "CENTER")
    Skin:SetFont(tab.text, 12, "OUTLINE")
    tab.text:SetPoint("CENTER", 0, 1)
    tab.mark = tab:CreateTexture(nil, "OVERLAY")
    Skin:Fill(tab.mark, C.accent)
    tab.mark:SetHeight(2)
    tab.mark:SetPoint("BOTTOMLEFT", 0, 0); tab.mark:SetPoint("BOTTOMRIGHT", 0, 0)
    tab.mark:Hide()
    function tab:SetSelected(v)
      self.selected = v and true or false
      if self.selected then self.mark:Show(); self.text:SetTextColor(unpack(C.accentHover))
      else self.mark:Hide(); self.text:SetTextColor(unpack(C.textDim)) end
    end
    tab:SetScript("OnEnter", function(t) if not t.selected then t.text:SetTextColor(unpack(C.text)) end end)
    tab:SetScript("OnLeave", function(t) t:SetSelected(t.selected) end)
    tab:SetScript("OnClick", press(function()
      if def.id == "modules" then Settings:CloseOptions() end   -- sekmeye tiklamak cekmeceden listeye doner
      Settings:ShowPage(def.id)
    end))
    T(tab.text, def.title, function(fs, value)
      fs:SetText(value)
      local w = fs:GetStringWidth()
      tab:SetWidth(math.max(64, (type(w) == "number" and w or 60) + 26))
    end)
    tab:SetPoint("LEFT", tabs, "LEFT", x, 0)
    if def.hidden then tab:Hide() else x = x + (tab:GetWidth() or 90) + 2 end
    self.nav[def.id] = tab

    local page = CreateFrame("Frame", nil, body)
    page:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    page:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    page:Hide()
    self.pages[def.id] = { frame = page, def = def, built = false, index = i }
  end
  -- sekme genislikleri dil degisince degisir: konumlari yeniden diz
  function self.LayoutTabs()
    local tx = 0
    for _, def in ipairs(PAGES) do
      local tab = self.nav[def.id]
      if not def.hidden then
        tab:ClearAllPoints()
        tab:SetPoint("LEFT", tabs, "LEFT", tx, 0)
        tx = tx + (tab:GetWidth() or 90) + 2
      end
    end
  end
  self.LayoutTabs()
  -- sekmesiz sayfadan (Dynamic Hub, rehber listesi) Modules'a donus: sekme cubugunun saginda
  self.backButton = Skin:CreateButton(tabs, "", 110, 24)
  T(self.backButton, "Back")
  self.backButton:SetPoint("RIGHT", tabs, "RIGHT", -2, 2)
  self.backButton:SetScript("OnClick", press(function() Settings:Open("modules") end))
  self.backButton:Hide()
  host:SetScript("OnSizeChanged", function() Settings:OnResized() end)
  self:OnResized()
end

-- Ayarlar her zaman ana pencerenin "Settings" sayfasina gomulur (PathWindow toc'ta her zaman yuklu).
function Settings:BuildFrame()
  if self.frame then return end
  self:BuildEmbedded(ns.PathWindow:SettingsHost())
end

function Settings:OnResized()
  local f = self.frame
  if not f then return end
  local w = f:GetWidth()
  if type(w) ~= "number" or w < 300 then return end   -- gizli pencere henuz olculmedi: OnSizeChanged duzeltir
  bodyWidth = w
  self.bodyWidth = bodyWidth
  for _, entry in pairs(self.pages) do
    local page = entry.frame
    if entry.built then
      for _, fn in ipairs(page.fluids or {}) do ns.SafeCall(fn, bodyWidth) end
      if page.onResize then ns.SafeCall(page.onResize, bodyWidth) end
    end
  end
end

local function placePage(page, offset)
  page:ClearAllPoints()
  page:SetPoint("TOPLEFT", Settings.body, "TOPLEFT", offset, 0)
  page:SetPoint("BOTTOMRIGHT", Settings.body, "BOTTOMRIGHT", offset, 0)
end

local SLIDE_TIME = 0.28

-- Sayfa degisimi: yeni sayfa yandan kayarak girer, eskisi ters yone cikar (hafif solma ile).
-- animate: nil -> pencere aciksa animasyonlu; true/false ile zorlanabilir.
function Settings:ShowPage(id, animate)
  self:BuildFrame()
  local alias = PAGE_ALIAS[id]
  if alias then id = alias[1] end
  local entry = self.pages[id] or self.pages.modules
  id = entry.def.id
  if not entry.built then
    entry.built = true
    ns.SafeCall(entry.def.build, entry.frame)
  end
  if alias and alias[2] and entry.frame.tabs then entry.frame.tabs:Select(alias[2]) end
  local prev = self.current and self.pages[self.current]
  if animate == nil then animate = self.frame:IsShown() and true or false end
  animate = animate and prev and prev ~= entry

  for pid, other in pairs(self.pages) do
    self.nav[pid]:SetSelected(pid == id)
    if not animate and pid ~= id then other.frame:Hide() end
  end
  if not entry.def.hidden then self.db.page = id end   -- sekmesiz sayfa (hub, rehber listesi) son sayfa olmaz
  if self.backButton then
    if entry.def.hidden then self.backButton:Show() else self.backButton:Hide() end
  end
  self.current = id

  if animate then
    local dir = entry.index > prev.index and 1 or -1
    local travel = bodyWidth
    -- onceki gecis bitmemisse eski sayfalari temizle
    for pid, other in pairs(self.pages) do
      if other ~= entry and other ~= prev then other.frame:Hide() end
    end
    placePage(prev.frame, 0); prev.frame:SetAlpha(1); prev.frame:Show()
    placePage(entry.frame, dir * travel); entry.frame:SetAlpha(0.74); entry.frame:Show()
    if entry.frame.refresh then ns.SafeCall(entry.frame.refresh) end
    Skin:Tween("settings-page", SLIDE_TIME, function(p)
      placePage(prev.frame, -dir * travel * p)
      prev.frame:SetAlpha(1 - 0.22 * p)
      placePage(entry.frame, dir * travel * (1 - p))
      entry.frame:SetAlpha(0.74 + 0.26 * p)
    end, function()
      prev.frame:Hide(); prev.frame:SetAlpha(1)
      placePage(entry.frame, 0); entry.frame:SetAlpha(1)
    end)
  else
    Skin:CancelTween("settings-page")
    placePage(entry.frame, 0)
    entry.frame:SetAlpha(1)
    entry.frame:Show()
    if entry.frame.refresh then ns.SafeCall(entry.frame.refresh) end
  end
end

-- keepDrawer: yalniz OpenOptions verir; baska her acilis (Modules sekmesi, /wf options, bildirim) acik cekmeceyi
-- kapatir, yoksa eski cekmece listenin ustunde kalir
function Settings:Open(id, keepDrawer)
  self:BuildFrame()
  if not keepDrawer then self:CloseOptions() end
  ns.PathWindow:Open("settings")
  self:ShowPage(id or self.db.page, false)
end

function Settings:Toggle()
  local W = ns.PathWindow
  if W:IsOpen() and W.db.page == "settings" then W:Close() else self:Open() end
end

function Settings:IsOpen()
  return ns.PathWindow:IsOpen() and ns.PathWindow.db.page == "settings"
end

function Settings:Retext()
  for _, apply in ipairs(texts) do apply() end
  if self.LayoutTabs then self.LayoutTabs() end
  local entry = self.pages and self.pages[self.db.page]
  if entry and entry.built and entry.frame.refresh then ns.SafeCall(entry.frame.refresh) end
end

function Settings:OnGuideEvent()
  if not (self.frame and self.frame:IsShown()) then return end
  local entry = self.pages[self.db.page]
  if entry and entry.built and entry.frame.refresh and self.db.page == "guides" then
    ns.SafeCall(entry.frame.refresh)
  end
end

function Settings:OnEnable()
  -- eski ilk sayfa (rehber listesi / Route / Helpers) artik Modules
  local old = self.db.page
  if old == "guides" or old == "route" or old == "helpers" then self.db.page = "modules" end
  self:BuildFrame()   -- tum moduller hazir (ana pencereye gomulur)
  ns:Listen("ARCANIS_LOCALE_CHANGED", self, "Retext")
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, "OnGuideEvent")
end

ns:RegisterCommand("settings", function(args)
  local id = (args or ""):lower():match("^(%S+)")
  Settings:Open(id)
end, "open the settings window")

-- /wf options <modul>: modulun ayarlari (ad ya da gorunen ad, buyuk-kucuk harf ve bosluk onemsiz)
function Settings:FindFeature(text)
  local want = (text or ""):lower():gsub("%s+", "")
  if want == "" then return nil end
  for _, f in ipairs(FEATURES) do
    if f[1]:lower() == want or ((Settings.Text(f[2]) or ""):lower():gsub("%s+", "")) == want then return f end
  end
  for _, f in ipairs(FEATURES) do
    local name = (Settings.Text(f[2]) or ""):lower():gsub("%s+", "")
    if f[1]:lower():find(want, 1, true) or name:find(want, 1, true) then return f end
  end
  return nil
end

ns:RegisterCommand("options", function(args)
  local f = Settings:FindFeature(args)
  if not f then Settings:Open("modules") return end
  if not Settings:OpenOptions(f[1]) then
    Settings:Open("modules")
    local mp = Settings.pages.modules.frame
    if mp.search then mp.search:SetText(Settings.Text(f[2]) or ""); mp.filter(Settings.Text(f[2])) end
  end
end, "[module] open the settings of a module")
