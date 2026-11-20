-- Arcanis: ana pencere "Arcanis Path" (modul "PathWindow"). Sol menu + sayfalar:
--   Leveling Guide : rehber secici, adim ilerlemesi, adim kartlari, rota haritasi, siradaki adimlar
--   Dungeon Guide  : zindan gunlugu (Settings.BuildDungeons)
--   Professions    : bolgedeki toplama bilgisi
--   Quests         : rehberin gunlukteki gorevleri
--   Talents        : sinif build'i
--   Settings       : ayar penceresini acar
-- Acma: /wf path, adim penceresi menusu, /arcanis > Path paneli.
local _, ns = ...

local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack

local Win = ns:NewModule("PathWindow", { defaults = { w = 1060, h = 660, point = "CENTER", x = 0, y = 0, page = "level", mapZoom = 1 } })
ns.PathWindow = Win

local MIN_W, MIN_H, MAX_W, MAX_H = 900, 580, 1500, 1000
local HEADER_H, NAV_W, FOOT_H, GAP = 66, 178, 30, 10
local ROUTE = { 0.35, 0.65, 0.95, 1 }
local OBJECTIVE = { 0.40, 0.85, 0.50, 1 }
local OPTIONAL = { 0.96, 0.75, 0.34, 1 }

local TYPE_ICON = {
  accept = "exclaim", turnin = "question", complete = "current", kill = "sword", collect = "bag", use = "bag",
  talk = "bubble", fly = "wing", hearth = "house", ["goto"] = "arrow", level = "star", note = "current",
}

-- Sayfa kaydi: ana pencere bir "kabuk"tur; sayfalari moduller kaydeder (Path kendi sayfalarini, kardes
-- addon kopruleri kendi sayfalarini). def = { id, icon, title = fn, build = fn(page), order = n,
-- available = fn -> bool (false ise menude gorunmez) }. Disaridan: ArcanisPath.RegisterPage(def).
local PAGES = {}
local BUILDERS = {}

local REGISTER_ERR = "PathWindow:RegisterPage needs id and build"
function Win:RegisterPage(def)
  if not (type(def) == "table" and def.id and def.build) then error(REGISTER_ERR, 2) end
  for i, d in ipairs(PAGES) do if d.id == def.id then table.remove(PAGES, i) break end end
  def.order = def.order or 50
  PAGES[#PAGES + 1] = def
  table.sort(PAGES, function(a, b) return a.order < b.order end)
  BUILDERS[def.id] = def.build
  if self.frame then self:AddPageFrame(def) end
  return def
end

function Win:IsPageAvailable(def)
  if not def.available then return true end
  local ok, v = pcall(def.available)
  return ok and v and true or false
end

-- Kucuk yardimcilar
local function fstr(parent, size, color, justify, flags)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f, size or 12, flags or "")
  f:SetTextColor(unpack(color or C.text))
  f:SetJustifyH(justify or "LEFT")
  return f
end

local function panel(parent, bg, border)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  Skin:ApplyBackdrop(f, bg or C.card, border or C.border)
  return f
end

local function icon(parent, name, size, color, layer)
  local t = parent:CreateTexture(nil, layer or "OVERLAY")
  t:SetSize(size, size)
  t:SetTexture(Skin.Icons[name] or name)
  t:SetVertexColor(unpack(color or C.text))
  return t
end

-- Yuvarlak rozet: dolgu + halka + sayi.
local function badge(parent, size)
  local b = CreateFrame("Frame", nil, parent)
  b:SetSize(size, size)
  b.fill = icon(b, "roundrect", size, { 0.06, 0.07, 0.09, 1 }, "BACKGROUND")
  b.fill:SetPoint("CENTER")
  b.ring = icon(b, "roundring", size, C.accent, "BORDER")
  b.ring:SetPoint("CENTER")
  -- numara kutunun tam ortasinda: tum kutuyu kaplayan, yatay+dikey ortali yazi (golgesiz, kenarsiz)
  b.num = fstr(b, size > 24 and 12 or 10, C.text, "CENTER", "")
  b.num:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 1)
  b.num:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 1)
  b.num:SetJustifyV("MIDDLE")
  b.num:SetWordWrap(false)
  if b.num.SetShadowOffset then b.num:SetShadowOffset(0, 0) end
  function b:Set(text, color) self.num:SetText(text or ""); self.ring:SetVertexColor(unpack(color or C.accent)); self.num:SetTextColor(unpack(color or C.accent)) end
  return b
end

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

local function safe(fn) return function(...) ns.SafeCall(fn, ...) end end

-- Rehberin gorunur adimlari (Engine:IsVisible) -> { adimNo, ... } ve aktif adimin konumu.
local function visibleSteps()
  local E = ns.Engine
  local list, cur = {}, nil
  if not (E and E.guide) then return list, nil end
  local player = P.PlayerInfo()
  for i, step in ipairs(E.guide.steps) do
    if not step.sticky and E:IsVisible(step, player) then
      list[#list + 1] = i
      if i == E.index then cur = #list end
    end
  end
  if not cur then cur = (E.index > #E.guide.steps) and #list + 1 or 1 end
  return list, cur
end

local function stepSubtitle(step)
  local parts = {}
  if step.npc then parts[#parts + 1] = step.npc end
  local zone = step.zone
  if not zone and step.map and C_Map and C_Map.GetMapInfo then
    local ok, info = pcall(C_Map.GetMapInfo, step.map)
    zone = ok and info and info.name or nil
  end
  if zone then
    local loc = zone
    if step.x then loc = ("%s (%d, %d)"):format(zone, math.floor(step.x * 100 + 0.5), math.floor(step.y * 100 + 0.5)) end
    parts[#parts + 1] = loc
  end
  return table.concat(parts, "  -  ")
end

-- Adim hedefi ilerlemesi: kazanilan, gereken (yoksa nil).
local function stepProgress(step)
  if not (step and step.quest) then return nil end
  local objs = P.GetObjectives(step.quest)
  if type(objs) ~= "table" or #objs == 0 then return nil end
  local have, need = 0, 0
  for _, o in ipairs(objs) do
    have = have + (tonumber(o.numFulfilled) or (o.finished and 1 or 0))
    need = need + (tonumber(o.numRequired) or 1)
  end
  if need <= 0 then return nil end
  return have, need
end

-- Sayfa: Leveling Guide
local function buildLevel(page)
  local lv = { cards = {}, pins = {}, lines = {}, nextRows = {} }
  page.lv = lv

  -- ust serit: rehber karti + adim karti
  lv.guideCard = Skin:CreateField(page, 400, 58, "compass")
  lv.guideCard.icon:SetSize(22, 22)
  lv.guideCard.icon:ClearAllPoints()
  lv.guideCard.icon:SetPoint("LEFT", 14, 0)
  lv.guideTitle = lv.guideCard.text
  Skin:SetFont(lv.guideTitle, 14, "")
  lv.guideTitle:ClearAllPoints()
  lv.guideTitle:SetPoint("TOPLEFT", lv.guideCard, "TOPLEFT", 48, -13)
  lv.guideTitle:SetPoint("RIGHT", lv.guideCard, "RIGHT", -30, 0)
  lv.guideSub = fstr(lv.guideCard, 11, C.textDim)
  lv.guideSub:SetPoint("TOPLEFT", lv.guideTitle, "BOTTOMLEFT", 0, -4)
  lv.guideCard:SetScript("OnClick", safe(function() Win:ShowGuideMenu(lv.guideCard) end))

  lv.stepCard = panel(page)
  lv.stepLabel = fstr(lv.stepCard, 12, C.accent, "LEFT", "OUTLINE")
  lv.stepLabel:SetPoint("TOPLEFT", 14, -10)
  lv.stepCount = fstr(lv.stepCard, 12, C.text, "RIGHT", "OUTLINE")
  lv.stepCount:SetPoint("TOPRIGHT", -14, -10)
  lv.stepTrack = CreateFrame("Frame", nil, lv.stepCard, "BackdropTemplate")
  Skin:ApplyBackdrop(lv.stepTrack, C.barTrack, C.border)
  lv.stepTrack:SetPoint("BOTTOMLEFT", 14, 12)
  lv.stepTrack:SetPoint("BOTTOMRIGHT", -14, 12)
  lv.stepTrack:SetHeight(8)
  lv.stepFill = lv.stepTrack:CreateTexture(nil, "ARTWORK")
  Skin:Fill(lv.stepFill, C.accent)
  lv.stepFill:SetPoint("TOPLEFT", 1, -1)
  lv.stepFill:SetPoint("BOTTOMLEFT", 1, 1)
  lv.stepFill:SetWidth(1)

  -- sol sutun: adim kartlari. Tekerlek ya da sagdaki cubuk listeyi kaydirir; yeni adima gecince
  -- liste yine o adima doner (lv.scroll otomatik konumdan sapma).
  lv.column = CreateFrame("Frame", nil, page)
  lv.scroll = 0
  lv.column:EnableMouseWheel(true)
  lv.column:SetScript("OnMouseWheel", function(_, delta)
    lv.scroll = (lv.scroll or 0) - delta
    Win:RefreshLevel()
  end)
  lv.bar = CreateFrame("Frame", nil, lv.column)
  lv.bar:SetWidth(4)
  lv.barBg = lv.bar:CreateTexture(nil, "BACKGROUND")
  lv.barBg:SetAllPoints()
  Skin:Fill(lv.barBg, C.barTrack)
  lv.thumb = CreateFrame("Button", nil, lv.bar)
  lv.thumb:SetWidth(4)
  lv.thumbTex = lv.thumb:CreateTexture(nil, "ARTWORK")
  lv.thumbTex:SetAllPoints()
  Skin:Fill(lv.thumbTex, C.accent)
  lv.thumb:SetScript("OnMouseDown", function()
    if not GetCursorPosition then return end
    local _, y = GetCursorPosition()
    lv.drag = { y = y, start = lv.start or 1, scale = lv.bar:GetEffectiveScale() or 1 }
  end)
  lv.thumb:SetScript("OnMouseUp", function() lv.drag = nil end)
  lv.thumb:SetScript("OnUpdate", function()
    local d = lv.drag
    if not d or not lv.room or lv.room <= 0 then return end
    local _, y = GetCursorPosition()
    local steps = math.floor(((d.y - y) / d.scale) / lv.room * lv.span + 0.5)
    local want = d.start + steps
    if want ~= lv.start then lv.scroll = (lv.scroll or 0) + (want - lv.start); Win:RefreshLevel() end
  end)

  -- sag sutun: rota + siradaki adimlar
  lv.map = panel(page, { 0.04, 0.06, 0.08, 1 }, C.border)
  lv.canvas = CreateFrame("Frame", nil, lv.map)
  lv.canvas:SetPoint("TOPLEFT", 1, -1)
  lv.canvas:SetPoint("BOTTOMRIGHT", -1, 1)
  lv.canvas:SetClipsChildren(true)
  lv.tiles = {}
  lv.tileHolder = CreateFrame("Frame", nil, lv.canvas)
  lv.tileHolder:SetAllPoints()
  lv.shade = lv.tileHolder:CreateTexture(nil, "BORDER")
  lv.shade:SetAllPoints()
  lv.shade:SetColorTexture(0, 0, 0, 0.18)
  lv.shade:Hide()
  lv.pinHolder = CreateFrame("Frame", nil, lv.canvas)
  lv.pinHolder:SetAllPoints()
  lv.pinHolder:SetFrameLevel((lv.canvas:GetFrameLevel() or 1) + 3)
  lv.overlay = CreateFrame("Frame", nil, lv.map)
  lv.overlay:SetAllPoints()
  lv.overlay:SetFrameLevel((lv.canvas:GetFrameLevel() or 1) + 6)

  -- yakinlastirma / kaydirma: tekerlek, +/- dugmeleri, surukleme; ortala dugmesi sifirlar
  lv.zoom = Win.db.mapZoom or 1
  local function redraw()
    if lv.lastList then ns.SafeCall(Win.RefreshRoute, Win, lv.lastList, lv.lastPos) end
  end
  local function setZoom(z)
    lv.zoom = math.max(0.25, math.min(8, z))
    Win.db.mapZoom = lv.zoom
    redraw()
  end
  lv.setZoom = setZoom
  lv.zoomIn = Skin:CreateIconButton(lv.overlay, "plus", 22, 24, 24)
  lv.zoomIn:SetPoint("TOPRIGHT", lv.map, "TOPRIGHT", -8, -8)
  lv.zoomIn:SetScript("OnClick", function() setZoom((lv.zoom or 1) * 1.4) end)
  lv.zoomOut = Skin:CreateIconButton(lv.overlay, "minus", 22, 24, 24)
  lv.zoomOut:SetPoint("TOP", lv.zoomIn, "BOTTOM", 0, -4)
  lv.zoomOut:SetScript("OnClick", function() setZoom((lv.zoom or 1) / 1.4) end)
  lv.recenter = Skin:CreateIconButton(lv.overlay, "current", 22, 24, 24)
  lv.recenter:SetPoint("TOP", lv.zoomOut, "BOTTOM", 0, -4)
  lv.recenter:SetScript("OnClick", function() lv.panX, lv.panY = 0, 0; setZoom(1) end)
  lv.map:EnableMouseWheel(true)
  lv.map:SetScript("OnMouseWheel", function(_, delta) setZoom((lv.zoom or 1) * (delta > 0 and 1.25 or 0.8)) end)
  lv.map:EnableMouse(true)
  lv.map:SetScript("OnMouseDown", function(m, button)
    if button ~= "LeftButton" or not GetCursorPosition then return end
    local x, y = GetCursorPosition()
    m.dragFrom = { x = x, y = y, px = lv.panX or 0, py = lv.panY or 0, scale = (m.GetEffectiveScale and m:GetEffectiveScale()) or 1 }
  end)
  lv.map:SetScript("OnMouseUp", function(m) m.dragFrom = nil end)
  lv.map:SetScript("OnUpdate", function(m)
    local d = m.dragFrom
    if not d then return end
    local x, y = GetCursorPosition()
    lv.panX = d.px + (x - d.x) / d.scale
    lv.panY = d.py - (y - d.y) / d.scale
    redraw()
  end)
  lv.mapZone = fstr(lv.overlay, 22, { 0.96, 0.85, 0.55, 0.85 }, "LEFT", "OUTLINE")
  lv.mapZone:SetPoint("BOTTOMLEFT", 14, 12)
  lv.mapEmpty = fstr(lv.overlay, 11, C.textDim, "CENTER")
  lv.mapEmpty:SetPoint("CENTER")
  lv.player = lv.overlay:CreateTexture(nil, "OVERLAY")
  lv.player:SetSize(12, 12)
  lv.player:SetTexture(Skin.Icons.disc)
  lv.player:SetVertexColor(1, 1, 1, 1)
  lv.player:Hide()

  lv.nextPanel = panel(page)
  lv.nextTitle = fstr(lv.nextPanel, 12, C.text, "LEFT", "OUTLINE")
  lv.nextTitle:SetPoint("TOPLEFT", 12, -9)
  lv.nextTitle:SetText(L["Next Steps"])
  for i = 1, 3 do
    local row = CreateFrame("Frame", nil, lv.nextPanel)
    row:SetHeight(26)
    row.badge = badge(row, 22)
    row.badge:SetPoint("LEFT", 12, 0)
    row.icon = icon(row, "arrow", 18, C.accent)
    row.icon:SetPoint("LEFT", row.badge, "RIGHT", 10, 0)
    row.text = fstr(row, 11, C.text)
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row.text:SetWordWrap(false)
    lv.nextRows[i] = row
  end

  local function layout()
    local w, h = page:GetWidth(), page:GetHeight()
    if type(w) ~= "number" or w < 100 then w = 860 end
    if type(h) ~= "number" or h < 100 then h = 500 end
    local stripH = 58
    local leftW = math.floor((w - GAP) * 0.55)
    lv.guideCard:ClearAllPoints()
    lv.guideCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    lv.guideCard:SetSize(leftW, stripH)
    lv.stepCard:ClearAllPoints()
    lv.stepCard:SetPoint("TOPLEFT", page, "TOPLEFT", leftW + GAP, 0)
    lv.stepCard:SetSize(w - leftW - GAP, stripH)

    local bodyTop = stripH + GAP
    local bodyH = h - bodyTop
    local colW = math.floor((w - GAP) * 0.50)
    lv.column:ClearAllPoints()
    lv.column:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -bodyTop)
    lv.column:SetSize(colW, bodyH)
    local n = math.max(3, math.min(8, math.floor((bodyH + GAP) / (56 + GAP))))
    local cardH = math.floor((bodyH - (n - 1) * 8) / n)
    lv.cardCount, lv.cardH = n, cardH
    lv.bar:ClearAllPoints()
    lv.bar:SetPoint("TOPRIGHT", lv.column, "TOPRIGHT", 0, 0)
    lv.bar:SetPoint("BOTTOMRIGHT", lv.column, "TOPRIGHT", 0, -(n * cardH + (n - 1) * 8))
    lv.barH = n * cardH + (n - 1) * 8
    for i = 1, n do
      local card = lv.cards[i]
      if not card then
        card = Win:MakeStepCard(lv.column)
        lv.cards[i] = card
      end
      card:ClearAllPoints()
      card:SetPoint("TOPLEFT", lv.column, "TOPLEFT", 0, -(i - 1) * (cardH + 8))
      card:SetSize(colW - 12, cardH)   -- sagda kaydirma cubugu (4) ve 8 bosluk
    end
    for i = n + 1, #lv.cards do lv.cards[i]:Hide() end

    local rx, rw = colW + GAP, w - colW - GAP
    local mapH = math.floor(bodyH * 0.62)
    lv.map:ClearAllPoints()
    lv.map:SetPoint("TOPLEFT", page, "TOPLEFT", rx, -bodyTop)
    lv.map:SetSize(rw, mapH)
    lv.nextPanel:ClearAllPoints()
    lv.nextPanel:SetPoint("TOPLEFT", page, "TOPLEFT", rx, -(bodyTop + mapH + GAP))
    lv.nextPanel:SetSize(rw, bodyH - mapH - GAP)
    for i, row in ipairs(lv.nextRows) do
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", lv.nextPanel, "TOPLEFT", 0, -(28 + (i - 1) * 28))
      row:SetPoint("RIGHT", lv.nextPanel, "RIGHT", 0, 0)
    end
    lv.stepFill.max = (w - leftW - GAP) - 14 - 14 - 2
  end
  lv.layout = layout
  page:SetScript("OnSizeChanged", function() layout(); if page.refresh then page.refresh() end end)
  layout()
end

-- Adim karti (havuzdan).
function Win:MakeStepCard(parent)
  local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
  Skin:ApplyBackdrop(card, C.card, C.border)
  card.badge = badge(card, 26)
  card.badge:SetPoint("LEFT", 10, 0)
  card.icon = icon(card, "arrow", 24, C.accent)
  card.icon:SetPoint("LEFT", card.badge, "RIGHT", 10, 0)
  card.title = fstr(card, 13, C.text, "LEFT", "OUTLINE")
  card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 76, -11)
  card.title:SetPoint("RIGHT", card, "RIGHT", -40, 0)
  card.title:SetWordWrap(false)
  card.sub = fstr(card, 11, C.textDim)
  card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -3)
  card.sub:SetPoint("RIGHT", card, "RIGHT", -40, 0)
  card.sub:SetWordWrap(false)
  card.status = icon(card, "check", 20, OBJECTIVE)
  card.status:SetPoint("RIGHT", -12, 0)
  card.track = CreateFrame("Frame", nil, card, "BackdropTemplate")
  Skin:ApplyBackdrop(card.track, C.barTrack, C.border)
  card.track:SetHeight(6)
  card.track:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 76, 7)
  card.track:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -70, 7)
  card.fill = card.track:CreateTexture(nil, "ARTWORK")
  card.fill:SetColorTexture(unpack(ROUTE))
  card.fill:SetPoint("TOPLEFT", 1, -1)
  card.fill:SetPoint("BOTTOMLEFT", 1, 1)
  card.fill:SetWidth(1)
  card.count = fstr(card, 11, C.text, "RIGHT")
  card.count:SetPoint("BOTTOMRIGHT", -40, 4)
  card:SetScript("OnEnter", function(c) if not c.isCurrent then c:SetBackdropBorderColor(unpack(C.borderLit)) end end)
  card:SetScript("OnLeave", function(c) if not c.isCurrent then c:SetBackdropBorderColor(unpack(C.border)) end end)
  card:SetScript("OnClick", safe(function(c)
    local E = ns.Engine
    if E and E.guide and c.stepIndex then E:SetGuide(E.guide.id, c.stepIndex) end
  end))
  return card
end

function Win:RefreshStepCard(card, ordinal, stepIndex, pos)
  local E = ns.Engine
  local step = E.guide.steps[stepIndex]
  card.stepIndex = stepIndex
  card:Show()
  local state = ordinal < pos and "done" or (ordinal == pos and "current" or "todo")
  card.isCurrent = state == "current"
  local tcol = Skin.TypeColors[step.type] or C.accent
  card.badge:Set(tostring(stepIndex), state == "done" and OBJECTIVE or (state == "current" and C.accent or C.textDim))
  card.icon:SetTexture(Skin.Icons[TYPE_ICON[step.type] or "arrow"])
  card.icon:SetVertexColor(unpack(state == "todo" and C.textDim or tcol))
  card.title:SetText(E:Describe(step))
  card.title:SetTextColor(unpack(state == "done" and C.textDim or C.text))
  card.sub:SetText(stepSubtitle(step))
  if card.isCurrent then
    Skin:ApplyBackdrop(card, C.accentSoft, C.accent)
  else
    Skin:ApplyBackdrop(card, C.card, C.border)
  end
  -- durum simgesi
  if state == "done" then
    card.status:SetTexture(Skin.Icons.check); card.status:SetVertexColor(unpack(OBJECTIVE)); card.status:Show()
  elseif state == "current" then
    card.status:SetTexture(Skin.Icons.next); card.status:SetVertexColor(unpack(C.accentHover)); card.status:Show()
  else
    card.status:SetTexture(Skin.Icons.ring); card.status:SetVertexColor(unpack(C.textOff)); card.status:Show()
  end
  -- hedef ilerleme cubugu (yalnizca aktif karttta)
  local have, need = nil, nil
  if card.isCurrent then have, need = stepProgress(step) end
  if have and need then
    card.track:Show(); card.count:Show()
    card.count:SetText(("%d / %d"):format(have, need))
    local w = (card.track:GetWidth() or 100) - 2
    if type(w) ~= "number" or w < 4 then w = 100 end
    card.fill:SetWidth(math.max(1, w * math.min(1, have / need)))
  else
    card.track:Hide(); card.count:Hide()
  end
end

function Win:RefreshLevel()
  local page = self.pages and self.pages.level
  local lv = page and page.lv
  if not lv then return end
  local E = ns.Engine
  local guide = E and E.guide
  if not guide then
    lv.guideTitle:SetText(L["No guide selected"])
    lv.guideSub:SetText(L["Pick a guide to begin."])
    lv.stepLabel:SetText(L["Current Step"]); lv.stepCount:SetText("")
    lv.stepFill:SetWidth(1)
    for _, card in ipairs(lv.cards) do card:Hide() end
    return
  end
  lv.guideTitle:SetText(ns.Guides:TitleOf(guide))
  lv.guideSub:SetText(L["Level %d - %d"]:format(guide.minLevel, guide.maxLevel))
  local list, pos = visibleSteps()
  local total = #list
  local rawIndex, rawTotal = E:GetProgress()
  lv.stepLabel:SetText(L["Current Step"])
  lv.stepCount:SetText(("%d / %d"):format(rawIndex, rawTotal))
  local fraction = rawTotal > 0 and math.min(1, math.max(0, (rawIndex - 1) / rawTotal)) or 0
  lv.stepFill:SetWidth(math.max(1, (lv.stepFill.max or 200) * fraction))

  local n = lv.cardCount or 6
  local last = math.max(1, total - n + 1)
  local auto = math.max(1, math.min(pos - 2, last))
  if lv.scrollPos ~= pos then lv.scroll, lv.scrollPos = 0, pos end   -- yeni adim: listeyi ona dondur
  local start = math.max(1, math.min(last, auto + (lv.scroll or 0)))
  lv.scroll, lv.start = start - auto, start
  -- kaydirma cubugu: yalniz adimlar karta sigmiyorsa
  local barH = lv.barH or 0
  if total > n and barH > 0 then
    local thumbH = math.max(20, math.floor(barH * n / total))
    lv.span, lv.room = last - 1, barH - thumbH
    lv.thumb:SetHeight(thumbH)
    lv.thumb:ClearAllPoints()
    lv.thumb:SetPoint("TOP", lv.bar, "TOP", 0, -math.floor(lv.room * (start - 1) / math.max(1, last - 1) + 0.5))
    lv.bar:Show()
  else
    lv.span, lv.room = 0, 0
    lv.bar:Hide()
  end
  for i = 1, n do
    local card = lv.cards[i]
    local ordinal = start + i - 1
    if card and list[ordinal] then self:RefreshStepCard(card, ordinal, list[ordinal], pos)
    elseif card then card:Hide() end
  end

  -- siradaki adimlar
  for i, row in ipairs(lv.nextRows) do
    local idx = list[pos + i]
    local step = idx and E.guide.steps[idx]
    if step then
      row:Show()
      row.badge:Set(tostring(idx), C.textDim)
      row.icon:SetTexture(Skin.Icons[TYPE_ICON[step.type] or "arrow"])
      row.icon:SetVertexColor(unpack(Skin.TypeColors[step.type] or C.accent))
      row.text:SetText(E:Describe(step))
    else
      row:Hide()
    end
  end
  lv.lastList, lv.lastPos = list, pos
  self:RefreshRoute(list, pos)
end

-- Oyunun harita resmi (C_Map art katmani): katman bilgisi + doku listesi ya da nil.
local artCache = {}
local function mapArt(map)
  if artCache[map] ~= nil then return artCache[map] or nil end
  local art = false
  if C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayerTextures then
    local ok, layers = pcall(C_Map.GetMapArtLayers, map)
    local layer = ok and type(layers) == "table" and layers[1] or nil
    if layer and layer.layerWidth and layer.tileWidth and layer.tileWidth > 0 then
      local ok2, textures = pcall(C_Map.GetMapArtLayerTextures, map, 1)
      if ok2 and type(textures) == "table" and #textures > 0 then
        art = {
          w = layer.layerWidth, h = layer.layerHeight, tw = layer.tileWidth, th = layer.tileHeight,
          cols = math.ceil(layer.layerWidth / layer.tileWidth), rows = math.ceil(layer.layerHeight / layer.tileHeight),
          textures = textures,
        }
      end
    end
  end
  artCache[map] = art
  return art or nil
end

local function mapName(map)
  if not (map and C_Map and C_Map.GetMapInfo) then return nil end
  local ok, info = pcall(C_Map.GetMapInfo, map)
  return ok and info and info.name or nil
end

-- Rota haritasi: aktif adimdan itibaren ayni haritadaki konumlu adimlar; arkada oyunun bolge haritasi
-- (rotaya yakinlastirilmis). Harita resmi alinamazsa duz zemine cizer.
function Win:RefreshRoute(list, pos)
  local page = self.pages.level
  local lv = page.lv
  local E = ns.Engine
  for _, pin in ipairs(lv.pins) do pin:Hide() end
  for _, ln in ipairs(lv.lines) do ln:Hide() end
  for _, t in ipairs(lv.tiles) do t:Hide() end
  lv.player:Hide()
  local pts, baseMap, zone = {}, nil, nil
  for ordinal = pos, math.min(#list, pos + 6) do
    local step = E.guide.steps[list[ordinal]]
    local map, x, y = ns.Zones:Location(step)
    if map then
      baseMap = baseMap or map
      zone = zone or step.zone
      if map == baseMap then pts[#pts + 1] = { x = x, y = y, n = list[ordinal], step = step } end
    end
  end
  if not baseMap then baseMap = P.PlayerMapPosition() end
  lv.mapZone:SetText(zone or mapName(baseMap) or P.ZoneText() or "")
  local px, py
  if baseMap then px, py = P.PlayerPosOn(baseMap) end
  local cw, ch = lv.canvas:GetWidth(), lv.canvas:GetHeight()
  if type(cw) ~= "number" or cw < 50 then cw = 400 end
  if type(ch) ~= "number" or ch < 50 then ch = 260 end

  -- gorunum: rota + oyuncu kutusu, en az haritanin %30'u, kenarlarda bosluk
  local minx, maxx, miny, maxy = 2, -1, 2, -1
  local function grow(x, y) minx, maxx = math.min(minx, x), math.max(maxx, x); miny, maxy = math.min(miny, y), math.max(maxy, y) end
  for _, p in ipairs(pts) do grow(p.x, p.y) end
  if px then grow(px, py) end
  if maxx < minx then minx, maxx, miny, maxy = 0, 1, 0, 1 end
  local art = baseMap and mapArt(baseMap)
  local mw, mh = art and art.w or 1000, art and art.h or 667
  local spanx = math.max(0.30, (maxx - minx) * 1.35)
  local spany = math.max(0.30, (maxy - miny) * 1.35)
  local cover = math.max(cw / mw, ch / mh)
  local auto = math.max(cover, math.min(cw / (spanx * mw), ch / (spany * mh)))
  -- kullanici yakinlastirmasi (fare tekerlegi / +-) ve kaydirma (surukle)
  local zoom = lv.zoom or 1
  local scale = math.max(cover, math.min(auto * zoom, cover * 12))
  lv.zoomMinReached = scale <= cover + 1e-6
  local cx = (minx + maxx) / 2 * mw * scale
  local cy = (miny + maxy) / 2 * mh * scale
  local ox = cw / 2 - cx + (lv.panX or 0)
  local oy = ch / 2 - cy + (lv.panY or 0)
  local cox = math.min(0, math.max(cw - mw * scale, ox))
  local coy = math.min(0, math.max(ch - mh * scale, oy))
  -- kenara dayaninca kaydirma birikmesin
  lv.panX = (lv.panX or 0) + (cox - ox)
  lv.panY = (lv.panY or 0) + (coy - oy)
  ox, oy = cox, coy
  local function at(x, y) return ox + x * mw * scale, oy + y * mh * scale end

  if art then
    local i = 0
    for r = 1, art.rows do
      for c = 1, art.cols do
        i = i + 1
        local tex = art.textures[(r - 1) * art.cols + c]
        if tex then
          local t = lv.tiles[i]
          if not t then
            t = lv.tileHolder:CreateTexture(nil, "BACKGROUND")
            lv.tiles[i] = t
          end
          t:SetTexture(tex)
          t:SetSize(art.tw * scale, art.th * scale)
          t:ClearAllPoints()
          t:SetPoint("TOPLEFT", lv.tileHolder, "TOPLEFT", ox + (c - 1) * art.tw * scale, -(oy + (r - 1) * art.th * scale))
          t:Show()
        end
      end
    end
    lv.shade:Show()
  else
    lv.shade:Hide()
  end

  if #pts == 0 then
    lv.mapEmpty:SetText(art and "" or L["No map data for this step."])
    lv.mapEmpty:Show()
  else
    lv.mapEmpty:Hide()
  end

  local prevX, prevY
  if px then
    local ax, ay = at(px, py)
    lv.player:ClearAllPoints()
    lv.player:SetPoint("CENTER", lv.canvas, "TOPLEFT", ax, -ay)
    lv.player:Show()
    prevX, prevY = ax, ay
  end
  for i, p in ipairs(pts) do
    local ax, ay = at(p.x, p.y)
    local pin = lv.pins[i]
    if not pin then
      pin = badge(lv.pinHolder, 24)
      lv.pins[i] = pin
    end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", lv.canvas, "TOPLEFT", ax, -ay)
    pin:Set(tostring(p.n), i == 1 and C.accent or (Skin.TypeColors[p.step.type] or ROUTE))
    pin:Show()
    if prevX and lv.pinHolder.CreateLine then
      local ln = lv.lines[i]
      if not ln then
        ln = lv.pinHolder:CreateLine(nil, "ARTWORK")
        lv.lines[i] = ln
      end
      if ln then
        ln:SetThickness(3)
        ln:SetColorTexture(ROUTE[1], ROUTE[2], ROUTE[3], 0.9)
        ln:SetStartPoint("TOPLEFT", lv.canvas, prevX, -prevY)
        ln:SetEndPoint("TOPLEFT", lv.canvas, ax, -ay)
        ln:Show()
      end
    end
    prevX, prevY = ax, ay
  end
end

-- Rehber menusu: oyuncuya uygun, seviyesine yakin rehberler.
-- Rehber listesi: Rehber Tarayicisi aciksa o, degilse Ayarlar'daki eski liste
function Win:OpenGuideList(tab)
  if ns.GuideBrowser and ns.GuideBrowser:IsEnabled() then ns.GuideBrowser:Open(tab or "leveling")
  elseif ns.Settings then ns.Settings:Open("guides") end
end

function Win:ShowGuideMenu(anchor)
  local E = ns.Engine
  local G = ns.Guides
  local player = P.PlayerInfo()
  local items = {}
  for _, guide in ipairs(G:List(function(g)
    return G:IsEligible(g, player) and g.maxLevel >= player.level - 3 and g.minLevel <= player.level + 12
  end)) do
    items[#items + 1] = {
      text = ("%s  (%d-%d)"):format(G:ShortTitle(guide), guide.minLevel, guide.maxLevel),
      checked = E.guide and E.guide.id == guide.id,
      onClick = function() E:SetGuide(guide.id) end,
    }
    if #items >= 16 then break end
  end
  items[#items + 1] = { text = L["All guides..."], onClick = function() Win:OpenGuideList() end }
  if E.guide then items[#items + 1] = { text = L["Stop guide"], onClick = function() E:StopGuide() end } end
  local w = anchor.GetWidth and anchor:GetWidth()
  Skin:ShowMenu(anchor, items, (type(w) == "number" and w > 120) and w or 240)
end

local function buildDungeon(page)
  if ns.Settings and ns.Settings.BuildDungeons then ns.SafeCall(ns.Settings.BuildDungeons, page) end
end

local function buildSettings(page)
  local S = ns.Settings
  if not S then return end
  S:BuildFrame()
  if not S.embedded then return end
  function page.refresh() S:ShowPage(S.current or S.db.page, false) end
end

Win:RegisterPage({ id = "level", order = 10, icon = "compass", title = function() return L["Quest Tracker"] end, build = buildLevel })
-- Ayarlari sayfanin kendisi olan bolumler (kendi yerleri; modul kapaliysa kart anahtariyla acilir)
local function feature(name) return ns.Settings and ns.Settings.Feature and ns.Settings.Feature(name) end
Win:RegisterPage({ id = "maps", order = 25, icon = "pin", title = function() return L["Maps"] end,
  build = function(page) Win.SectionPage({ "MapMarkers", "MapReveal", "Rares" })(page) end })
Win:RegisterPage({ id = "rotation", order = 62, icon = "sword", title = function() return L["Rotation"] end,
  build = function(page)
    local f = feature("Rotation") or {}
    Win.SectionPage({ "Rotation" }, f.onOpen, f.onClose)(page)   -- sayfa acikken ikonlarin onizlemesi
  end })
Win:RegisterPage({ id = "hub", order = 90, icon = "bubble", title = function() return L["Hub"] end,
  build = function(page)
    local S = ns.Settings
    if not S then return end
    local panes = {}
    local bar = Skin:CreateTabBar(page, { { id = "island", text = L["Dynamic Hub"] }, { id = "alerts", text = L["Alerts and messages"] },
      { id = "ui", text = L["Interface"] } },
      function(tab) for k, p in pairs(panes) do if k == tab then p:Show() else p:Hide() end end end)
    bar:SetPoint("TOPLEFT", 12, -6); bar:SetPoint("TOPRIGHT", -12, -6)
    for _, k in ipairs({ "island", "alerts", "ui" }) do
      local p = CreateFrame("Frame", nil, page)
      p:SetPoint("TOPLEFT", 0, -40); p:SetPoint("BOTTOMRIGHT", 0, 0)
      panes[k] = p
    end
    if S.BuildIslandInto then ns.SafeCall(S.BuildIslandInto, S, panes.island) end
    S:BuildSection(panes.alerts, { "Alerts", "Messenger", "Discover" })
    S:BuildSection(panes.ui, { "UITweaks", "MinimapTools", "Social", "QoL" })
    page.panes, page.tabs = panes, bar
    if bar.Select then bar:Select("island") else panes.alerts:Hide(); panes.ui:Hide() end
    function page.refresh()
      for _, p in pairs(panes) do if p:IsShown() and p.refresh then ns.SafeCall(p.refresh) end end
    end
  end })
Win:RegisterPage({ id = "dungeon", order = 20, icon = "shield", title = function() return L["Dungeon Guide"] end, build = buildDungeon,
  available = function() return not ns.Journal or ns.Journal:IsEnabled() end })
-- Meslekler sayfasi Modules/ProfessionsPage.lua'da (Mesleklerim / Farm pusulasi / Paylas)
Win:RegisterPage({ id = "settings", order = 100, icon = "gear", title = function() return L["Settings"] end, build = buildSettings })

-- Diger modullerin sayfa yaparken kullandigi ortak parcalar (ayni gorunum).
Win.UI = {
  fstr = fstr, panel = panel, icon = icon, badge = badge, setClassIcon = setClassIcon, safe = safe,
  colors = { route = ROUTE, objective = OBJECTIVE, optional = OPTIONAL },
}

-- Genel API: baska modullerin kendi sayfasini eklemesi icin.
_G.ArcanisPath = _G.ArcanisPath or {}
_G.ArcanisPath.RegisterPage = function(def) return Win:RegisterPage(def) end
_G.ArcanisPath.Open = function(id) Win:Open(id) end
_G.ArcanisPath.Skin = Skin
_G.ArcanisPath.UI = Win.UI

-- Ayarlar sayfasinin cercevesi (Settings bu sayfaya gomulur).
function Win:SettingsHost()
  self:BuildFrame()
  return self.pages.settings
end

-- Cerceve
function Win:BuildFrame()
  if self.frame then return end
  local db = self.db
  local f = CreateFrame("Frame", "ArcanisPathWindow", UIParent, "BackdropTemplate")
  ns.Skin:RegisterRoot(f)
  f:SetSize(math.max(MIN_W, math.min(MAX_W, db.w or 1060)), math.max(MIN_H, math.min(MAX_H, db.h or 660)))
  f:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)
  if f.SetResizeBounds then f:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
  elseif f.SetMinResize then f:SetMinResize(MIN_W, MIN_H); if f.SetMaxResize then f:SetMaxResize(MAX_W, MAX_H) end end
  f:EnableMouse(true)
  self.chrome = Skin:ApplyWindowChrome(f, HEADER_H, 8)
  self.chrome:SetColors(C.panel, C.frameBorder)
  f:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisPathWindow") end
  self.frame = f

  -- ust bar (surukleme alani)
  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", 0, 0)
  header:SetHeight(HEADER_H)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() f:StartMoving() end)
  header:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    local point, _, _, x, y = f:GetPoint()
    if point then db.point, db.x, db.y = point, x, y end
  end)

  -- marka: yalnizca ARCANIS yazi logosu (ikon yok)
  self.logo = header:CreateTexture(nil, "ARTWORK")
  self.logo:SetTexture("Interface\\AddOns\\Arcanis\\Media\\UI\\ArcanisWordmark")
  self.logo:SetTexCoord(0, 1, 0, 166 / 256)
  self.logo:SetSize(172, 28)
  self.logo:SetPoint("TOPLEFT", header, "TOPLEFT", 20, -14)
  self.logo._skinFixed = true
  self.tagline = fstr(header, 10, C.textDim, "LEFT")
  self.tagline:SetPoint("TOPLEFT", self.logo, "BOTTOMLEFT", 1, -6)
  self.tagline:SetText(L["LEVEL  -  EXPLORE  -  MASTER"])
  self.chrome:SetTitle(L["Arcanis Path"])

  self.closeButton = Skin:CreateCloseButton(header, 16)
  self.closeButton:SetPoint("RIGHT", header, "RIGHT", -12, 0)
  self.closeButton:SetScript("OnClick", function() f:Hide() end)

  self.charCard = panel(header, { 0.07, 0.08, 0.10, 1 }, C.border)
  self.charCard:SetSize(200, 40)
  self.charCard:SetPoint("RIGHT", self.closeButton, "LEFT", -14, 0)

  -- sayfanin modul ayarlari: disli, Ayarlar > Modules'taki o modulun cekmecesini acar (ayari yoksa modul satiri)
  self.optionsButton = Skin:CreateIconButton(header, "gear", 24, 34, 34)
  self.optionsButton:SetPoint("RIGHT", self.charCard, "LEFT", -10, 0)
  self.optionsButton:SetScript("OnClick", safe(function() Win:OpenPageOptions() end))
  -- ipucu dugmenin kendi uzerine gelme boyamasini bozmasin: Skin ipucu alani (Refresh'te dile gore)
  if self.optionsButton.SetTooltip then self.optionsButton:SetTooltip(L["Settings of this page"]) end
  self.optionsButton:Hide()
  self.charIcon = self.charCard:CreateTexture(nil, "ARTWORK")
  self.charIcon:SetSize(28, 28)
  self.charIcon:SetPoint("LEFT", 8, 0)
  self.charName = fstr(self.charCard, 12, C.text, "LEFT", "OUTLINE")
  self.charName:SetPoint("TOPLEFT", self.charIcon, "TOPRIGHT", 8, -1)
  self.charName:SetPoint("RIGHT", self.charCard, "RIGHT", -8, 0)
  self.charSub = fstr(self.charCard, 10, C.textDim)
  self.charSub:SetPoint("TOPLEFT", self.charName, "BOTTOMLEFT", 0, -2)

  -- sol menu
  local nav = CreateFrame("Frame", nil, f)
  nav:SetPoint("TOPLEFT", 0, -HEADER_H)
  nav:SetPoint("BOTTOMLEFT", 0, FOOT_H)
  nav:SetWidth(NAV_W)
  local nline = nav:CreateTexture(nil, "ARTWORK")
  Skin:Fill(nline, C.border)
  ns.Skin:Hairline(nline, "w")
  nline:SetPoint("TOPRIGHT"); nline:SetPoint("BOTTOMRIGHT")
  self.navButtons = {}
  self.nav = nav

  -- icerik alani
  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", f, "TOPLEFT", NAV_W + 14, -(HEADER_H + 12))
  content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, FOOT_H + 10)
  self.content = content
  self.pages = {}
  for _, def in ipairs(PAGES) do self:AddPageFrame(def) end
  self:LayoutNav()

  -- alt bilgi cubugu
  local foot = CreateFrame("Frame", nil, f)
  foot:SetPoint("BOTTOMLEFT", 0, 0)
  foot:SetPoint("BOTTOMRIGHT", 0, 0)
  foot:SetHeight(FOOT_H)
  local fline = foot:CreateTexture(nil, "ARTWORK")
  Skin:Fill(fline, C.border)
  ns.Skin:Hairline(fline, "h")
  fline:SetPoint("TOPLEFT"); fline:SetPoint("TOPRIGHT")
  self.footIcon = icon(foot, "compass", 18, C.accent)
  self.footIcon:SetPoint("LEFT", 16, 0)
  self.footText = fstr(foot, 11, C.textDim)
  self.footText:SetPoint("LEFT", self.footIcon, "RIGHT", 10, 0)
  self.footText:SetText(L["Keep going! You're on the right path."])
  local prev
  for _, e in ipairs({ { L["Optional"], OPTIONAL }, { L["Objective"], OBJECTIVE }, { L["Route"], ROUTE } }) do
    local label = fstr(foot, 11, C.textDim, "RIGHT")
    if prev then label:SetPoint("RIGHT", prev, "LEFT", -16, 0) else label:SetPoint("RIGHT", foot, "RIGHT", -34, 0) end
    label:SetText(e[1])
    local dot = icon(foot, "disc", 9, e[2])
    dot:SetPoint("RIGHT", label, "LEFT", -6, 0)
    dot._skinFixed = true
    prev = dot
  end

  -- boyutlandirma tutamagi
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(18, 18)
  grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  grip:SetFrameLevel((f:GetFrameLevel() or 1) + 10)
  grip.tex = icon(grip, "resize", 18, C.textDim)
  grip.tex:SetAllPoints()
  grip:SetScript("OnEnter", function(g) g.tex:SetVertexColor(unpack(C.accent)) end)
  grip:SetScript("OnLeave", function(g) if not g.sizing then g.tex:SetVertexColor(unpack(C.textDim)) end end)
  grip:SetScript("OnMouseDown", function(g) g.sizing = true; f:StartSizing("BOTTOMRIGHT") end)
  grip:SetScript("OnMouseUp", function(g)
    g.sizing = false
    f:StopMovingOrSizing()
    g.tex:SetVertexColor(unpack(C.textDim))
    local w, h = f:GetWidth(), f:GetHeight()
    if type(w) == "number" and type(h) == "number" then db.w, db.h = math.floor(w + 0.5), math.floor(h + 0.5) end
    -- StartSizing cerceveyi yeniden baglar: konum da kaydedilir (reload'da pencere kaymasin)
    local point, _, _, x, y = f:GetPoint()
    if point then db.point, db.x, db.y = point, x, y end
  end)
  self.grip = grip

  -- ilerleme/hedef sayaclari icin hafif periyodik yenileme
  local acc = 0
  f:SetScript("OnUpdate", function(_, dt)
    acc = acc + (dt or 0)
    if acc >= 0.7 then
      acc = 0
      local id = Win.db.page
      if id == "level" then ns.SafeCall(Win.Refresh, Win) end
    end
  end)
  -- Win:Open disinda gosterilirse (or. /run ArcanisPathWindow:Show()) kayitli sayfa kurulur
  f:SetScript("OnShow", function() if not Win.opening then ns.SafeCall(Win.ShowPage, Win, Win.db.page) end end)
end

-- Kayitli sayfa icin menu ogesi + bos sayfa cercevesi (sayfa ilk acilista kurulur).
function Win:AddPageFrame(def)
  if not self.content or self.pages[def.id] then return end
  local b = Skin:CreateMenuItem(self.nav, NAV_W - 20, 42, def.icon)
  b.def = def
  b:SetScript("OnClick", safe(function() Win:ShowPage(def.id) end))
  self.navButtons[def.id] = b
  local page = CreateFrame("Frame", nil, self.content)
  page:SetAllPoints()
  page:Hide()
  self.pages[def.id] = page
  self:LayoutNav()
end

-- Menu: kullanilabilir sayfalar sirayla (kardes addon yoksa onun sayfasi gizlenir).
function Win:LayoutNav()
  if not self.navButtons then return end
  -- bolum sayisi arttikca (12+) menu pencereye sigmali: aralik yuksekliğe gore 48'den en cok 34'e iner
  local count = 0
  for _, def in ipairs(PAGES) do if self.navButtons[def.id] and self:IsPageAvailable(def) then count = count + 1 end end
  local navH = self.nav.GetHeight and self.nav:GetHeight() or 0
  local step = 48
  if type(navH) == "number" and navH > 0 and count > 0 then step = math.max(34, math.min(48, math.floor((navH - 16) / count))) end
  local i = 0
  for _, def in ipairs(PAGES) do
    local b = self.navButtons[def.id]
    if b then
      if self:IsPageAvailable(def) then
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", self.nav, "TOPLEFT", 10, -12 - i * step)
        if b.SetHeight then b:SetHeight(step - 6) end
        b:Show()
        i = i + 1
      else
        b:Hide()
      end
    end
  end
end

function Win:BuildPage(id)
  local page = self.pages and self.pages[id]
  if not page or page.built then return page end
  page.built = true
  local builder = BUILDERS[id]
  if builder then ns.SafeCall(builder, page) end
  return page
end

function Win:RefreshHeader()
  if not self.charName then return end
  local name = UnitName and UnitName("player") or "?"
  local className = UnitClass and select(1, UnitClass("player")) or ""
  self.charName:SetText(name or "?")
  self.charSub:SetText(("%d  |  %s"):format(P.PlayerLevel(), className or ""))
  if self.optionsButton and self.optionsButton.SetTooltip then self.optionsButton:SetTooltip(L["Settings of this page"]) end
  setClassIcon(self.charIcon, P.PlayerClassToken())
end

function Win:Refresh()
  if not self.frame then return end
  self:RefreshHeader()
  self:LayoutNav()
  local id = self.db.page
  for pid, b in pairs(self.navButtons) do
    b:SetSelected(pid == id)
    b.label:SetText(b.def.title())
  end
  if id == "level" then self:RefreshLevel()
  else
    local page = self.pages[id]
    if page and page.refresh then ns.SafeCall(page.refresh) end
  end
end

-- Sayfa -> o bolumun modulleri (ayarlari sayfanin icinde, disli dugmesiyle acilan panelde; sahibin karari,
-- 13 Kasim 2026: her ana bolum kendi ayarlarini tasir, Settings sayfasinda yalniz genel ayarlar). Ilk modul
-- PageOptions'in (eski: tek sahip) cevabidir. def.section ile de verilebilir.
local PAGE_SECTIONS = {
  level = { "Engine", "Window", "Nav", "Pins", "QuestAuto", "Brain", "QuestItem", "ItemNeeds", "Travel", "Transport", "Leveling", "QuestPlates" },
  guides = { "GuideBrowser" }, dungeon = { "Journal", "QuestShare" }, professions = { "ProfActivity", "Farm", "ZoneInfo", "Recipes" },
  gold = { "Gold", "Prices", "AuctionPanel", "Vendor", "Bags" }, mentor = { "Mentor", "LibraryBooks" }, keys = { "Keys" },
  talents = { "Codex", "Build", "Buffs", "Training", "TalentPlanner" },
}
Win.PAGE_SECTIONS = PAGE_SECTIONS
function Win:PageSection(id)
  for _, d in ipairs(PAGES) do if d.id == id and d.section then return d.section end end
  return PAGE_SECTIONS[id]
end
function Win:PageOptions(id)
  for _, d in ipairs(PAGES) do if d.id == id and d.options then return d.options end end
  local s = self:PageSection(id)
  return s and s[1] or nil
end

-- Sayfanin ustunde acilan ayar paneli: baslik + geri, altinda bolumun butun modullerinin ayarlari
-- (Settings:BuildSection). Ikinci basis kapatir. Doner: panel.
function Win:OpenPageOptions()
  local id, S = self.db.page, ns.Settings
  local names = self:PageSection(id)
  if not (names and S and S.BuildSection and self.content) then return nil end
  self.optionPanels = self.optionPanels or {}
  local p = self.optionPanels[id]
  if p and p.open then p.open = false; p:Hide() return p end
  if not p then
    p = CreateFrame("Frame", nil, self.content)
    p:SetAllPoints()
    p:SetFrameLevel((self.content:GetFrameLevel() or 1) + 30)
    p:EnableMouse(true)
    p.bg = p:CreateTexture(nil, "BACKGROUND")
    p.bg:SetAllPoints()
    Skin:Fill(p.bg, C.panel)
    p.title = fstr(p, 14, C.accentHover)
    p.title:SetPoint("TOPLEFT", 16, -12)
    p.back = Skin:CreateButton(p, L["Back"], 90, 22)
    p.back:SetPoint("TOPRIGHT", -12, -8)
    p.back:SetScript("OnClick", safe(function() p.open = false; p:Hide() end))
    p.body = CreateFrame("Frame", nil, p)
    p.body:SetPoint("TOPLEFT", 0, -40)
    p.body:SetPoint("BOTTOMRIGHT", 0, 0)
    S:BuildSection(p.body, names)
    self.optionPanels[id] = p
  end
  local def
  for _, d in ipairs(PAGES) do if d.id == id then def = d end end
  p.title:SetText(L["%s settings"]:format(def and def.title() or ""))
  p.open = true
  p:Show()
  if p.body.refresh then ns.SafeCall(p.body.refresh) end
  return p
end

-- Ayarlari sayfanin kendisi olan bolumler (Rotation, Maps, Hub): kurucu
local function sectionPage(names, onShow, onHide)
  return function(page)
    local S = ns.Settings
    if not (S and S.BuildSection) then return end
    S:BuildSection(page, names)
    page:HookScript("OnShow", function() if onShow then ns.SafeCall(onShow) end end)
    page:HookScript("OnHide", function() if onHide then ns.SafeCall(onHide) end end)
  end
end
Win.SectionPage = sectionPage

function Win:ShowPage(id)
  local def
  for _, d in ipairs(PAGES) do if d.id == id then def = d end end
  if def and not self:IsPageAvailable(def) then id = "level" end
  if not self.pages or not self.pages[id] then id = "level" end
  self:BuildFrame()
  self.db.page = id
  if self.optionsButton then
    if self:PageSection(id) then self.optionsButton:Show() else self.optionsButton:Hide() end
  end
  for _, op in pairs(self.optionPanels or {}) do op.open = false; op:Hide() end   -- baska sayfaya gecince ayar paneli kapanir
  for pid, page in pairs(self.pages) do
    if pid == id then self:BuildPage(pid); page:Show() else page:Hide() end
  end
  Skin:HideMenu()
  self:Refresh()
end

function Win:Open(id)
  self:BuildFrame()
  if id then self.db.page = id end
  -- OnShow burada atlanir: once eski sayfa kurulup cizilmesin, istenen sayfa bir kez kurulsun
  self.opening = true
  self.frame:Show()
  self.opening = nil
  self:ShowPage(self.db.page)
end

function Win:Close()
  if self.frame then self.frame:Hide() end
end

function Win:Toggle()
  self:BuildFrame()
  if self.frame:IsShown() then self.frame:Hide() else self:Open() end
end

function Win:IsOpen()
  return self.frame and self.frame:IsShown() and true or false
end

local function onChange(owner) if owner.frame and owner.frame:IsShown() then ns.SafeCall(owner.Refresh, owner) end end

function Win:OnEnable()
  ns:Listen("ARCANIS_LOCALE_CHANGED", self, onChange)
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, onChange)
  ns:Listen("ARCANIS_STEP_CHANGED", self, onChange)
  ns:Listen("ARCANIS_GUIDE_FINISHED", self, onChange)
  ns:Listen("ARCANIS_GUIDE_BLOCKED", self, onChange)
  ns:Listen("ARCANIS_SKIN_CHANGED", self, onChange)
  -- ozellik acilip kapaninca menu guncellenir; acik sayfa kapandiysa Leveling'e donulur
  local function modulesChanged(w)
    if not w.frame then return end
    ns.SafeCall(w.LayoutNav, w)
    if w.frame:IsShown() then ns.SafeCall(w.ShowPage, w, w.db.page) end
  end
  ns:Listen("ARCANIS_MODULE_ENABLED", self, modulesChanged)
  ns:Listen("ARCANIS_MODULE_DISABLED", self, modulesChanged)
end

ns:RegisterCommand("path", function(args)
  local id = (args or ""):lower():match("^(%S+)")
  Win:Open(id)
end, "Open the Arcanis Path window")
