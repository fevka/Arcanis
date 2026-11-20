-- Arcanis: adim penceresi (modul "Window") - "Arcanis Path" kompakt rota paneli.
--
--   [menu]          <logo> Arcanis Path              [x]
--   [ (ikon) Rehber adi            v ] [+]
--   [ <-  3/8  ->   xp/saat     [gorev] [su anki] [harita] ]
--   [ aktif adim karti (gorev disi adimlarda)   ]
--   [ gorev akordeonlari: aktif acik, digerleri kapali ]
--   [=========== genel ilerleme ===========      ]
--
-- Rehber yokken ya da bittiginde satirlar yerine tek bir eylem dugmesi gosterir (oner / sonraki rehber).
local _, ns = ...

local unpack = unpack or table.unpack
local P = ns.Provider
local L = ns.L
local Skin = ns.Skin
local C = Skin.Colors

local Window = ns:NewModule("Window", {
  defaults = { locked = false, hidden = false, scale = 1, alpha = 0.95, zoneInfo = true, guideTabs = true, xpBar = true, goldBar = true, zoneOpen = false, tab = "guide", point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -40, y = -220 },
})
ns.Window = Window

local WIDTH = 330
local PAD = 8
local ROW_H, ROW_GAP = 36, 3
local HEADER_H = 32
local SELECT_Y, NAV_Y, LIST_Y = -34, -62, -90
local BAR_H = 14   -- ilerleme cubugu: icinde "Guide progress  %24" yazisi

-- Renkler temadan gelir (Skin:ApplyTheme tablolari yerinde gunceller).
local PANEL, ROW_BG, ROW_ACTIVE = C.panel, C.row, C.rowActive
local BLUE, GREEN, FRAME = C.highlight, C.progress, C.frameBorder
local DANGER_BG = { 0.36, 0.07, 0.07, 0.92 }
local DANGER = { 1.00, 0.36, 0.32, 1 }

-- Arka plan saydamligi (Window.db.alpha) uygulanmis renk.
local function fade(c)
  local a = (Window.db and Window.db.alpha) or 1
  return { c[1], c[2], c[3], (c[4] or 1) * a }
end

local TYPE_ICON = {
  accept = "exclaim", turnin = "question", complete = "current", kill = "sword", collect = "bag", use = "bag",
  talk = "bubble", fly = "wing", hearth = "house", ["goto"] = "arrow", level = "star", note = "current",
}
Window.TYPE_ICON = TYPE_ICON

Window.action = nil   -- eylem dugmesinin yapacagi is (fonksiyon)

-- Kucuk yardimcilar
local function fstr(parent, size, color, justify, flags)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f, size or 12, flags or "")
  f:SetTextColor(unpack(color or C.text))
  f:SetJustifyH(justify or "LEFT")
  return f
end

local function tex(parent, name, size, color, layer)
  local t = parent:CreateTexture(nil, layer or "OVERLAY")
  t:SetSize(size, size)
  t:SetTexture(Skin.Icons[name] or name)
  t:SetVertexColor(unpack(color or C.text))
  return t
end

-- Cercevesiz ikon dugmesi (ust bar): uzerine gelince kehribar.
local function flatButton(parent, iconName, size)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size + 8, size + 8)
  b.icon = tex(b, iconName, size, C.text)
  b.icon:SetPoint("CENTER")
  b:SetScript("OnEnter", function(x) x.icon:SetVertexColor(unpack(C.accentHover)) end)
  b:SetScript("OnLeave", function(x) x.icon:SetVertexColor(unpack(C.text)) end)
  return b
end

local function isDanger(step)
  return step and (step.elite or step.danger or step.boss) and true or false
end

local function zoneName(step)
  if step.zone then return step.zone end
  if step.map and C_Map and C_Map.GetMapInfo then
    local ok, info = pcall(C_Map.GetMapInfo, step.map)
    if ok and info then return info.name end
  end
  return nil
end

-- Adim hedef ilerlemesi: kazanilan, gereken, ilk bitmemis hedef metni (yoksa nil).
local function progressOf(step)
  if not (step and step.quest) then return nil end
  local objs = P.GetObjectives(step.quest)
  if type(objs) ~= "table" or #objs == 0 then return nil end
  local list = objs
  if step.objective and objs[step.objective] then list = { objs[step.objective] } end
  local have, need, text = 0, 0, nil
  for _, o in ipairs(list) do
    have = have + (tonumber(o.numFulfilled) or (o.finished and 1 or 0))
    need = need + (tonumber(o.numRequired) or 1)
    if not o.finished and not text then text = o.text end
  end
  if need <= 0 then return nil end
  return have, need, text
end

local function rightIcon(step)
  local t = step.type
  if t == "kill" then return isDanger(step) and "skull" or "sword" end
  if t == "collect" or t == "use" then return "bag" end
  if t == "fly" then return "wing" end
  if t == "hearth" then return "house" end
  if t == "level" then return "star" end
  if step.x then return "pin" end
  return nil
end

-- Hub gorunumu: gorev kutulari tek parca yuvarlak cam kart
local function accStyle() return "glass" end

-- Adim karti zemini: hub karti gibi yuvarlak cam, durum rengiyle hafif tonlu (simdiki / tehlike / bitti);
-- ikonun arkasinda ayni tonda yuvarlak rozet. (bg, edge: eski cagrilarla uyum; kullanilmaz)
local function paintCard(row, bg, edge, tint)
  row.tint = tint
  -- adim bandi (gorev satirlariyla ayni): tur renginin koyu tonu; renksiz kart seffaf, fare ustunde hafif
  if tint then
    Skin:ApplyRounded(row, { tint[1] * 0.55, tint[2] * 0.55, tint[3] * 0.55, row.hover and 0.95 or 0.85 }, 5)
  else
    Skin:ApplyRounded(row, { 1, 1, 1, row.hover and 0.06 or 0 }, 5)
  end
  if row.badge then row.badge:Hide() end
end
Window.PaintCard = paintCard

-- Yapi
function Window:MakeRow(i)
  local row = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
  row:SetHeight(ROW_H)
  row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PAD, LIST_Y - (i - 1) * (ROW_H + ROW_GAP))
  row:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -PAD, LIST_Y - (i - 1) * (ROW_H + ROW_GAP))
  row.icon = tex(row, "arrow", 18, C.accent)
  row.icon:SetPoint("LEFT", 9, 0)
  row.badge = tex(row, "disc", 28, { 1, 1, 1, 0.08 }, "ARTWORK")
  row.badge:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
  paintCard(row, fade(ROW_BG), C.border, nil)
  row.title = fstr(row, 12, C.text, "LEFT", "")
  row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 36, -5)
  row.title:SetPoint("RIGHT", row, "RIGHT", -70, 0)
  row.title:SetWordWrap(false)
  row.sub = fstr(row, 10, C.textDim)
  row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
  row.sub:SetPoint("RIGHT", row, "RIGHT", -70, 0)
  row.sub:SetWordWrap(false)
  row.count = fstr(row, 11, C.textDim, "RIGHT", "")
  row.count:SetPoint("RIGHT", row, "RIGHT", -8, 0)
  row.kind = tex(row, "pin", 15, C.textDim)
  row.kind:SetPoint("RIGHT", row, "RIGHT", -44, 0)
  row:SetScript("OnEnter", function(r)
    r.hover = true; paintCard(r, nil, nil, r.tint)
  end)
  row:SetScript("OnLeave", function(r)
    r.hover = false; paintCard(r, nil, nil, r.tint)
  end)
  row:SetScript("OnClick", function(r)
    local E = ns.Engine
    if r.stepIndex and E.guide and r.stepIndex ~= E.index then E:SetGuide(E.guide.id, r.stepIndex) end
  end)
  return row
end

function Window:BuildFrame()
  if self.frame then return end
  local f = CreateFrame("Frame", "ArcanisStepFrame", UIParent, "BackdropTemplate")
  ns.Skin:RegisterRoot(f)
  f:SetSize(WIDTH, 300)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  self.chrome = Skin:ApplyWindowChrome(f, HEADER_H)
  self.chrome:SetColors(fade(PANEL), FRAME)
  self.frame = f

  -- ust bar: menu | logo + Arcanis Path | kapat
  self.menuButton = flatButton(f, "menu", 16)
  self.menuButton:SetPoint("TOPLEFT", f, "TOPLEFT", PAD - 4, -5)
  self.menuButton:SetScript("OnClick", function(btn)
    local items = {
      { text = L["Arcanis Path"], onClick = function() if ns.PathWindow then ns.PathWindow:Open("level") end end },
      { text = L["Guides"], onClick = function() if ns.PathWindow then ns.PathWindow:OpenGuideList("suggested") end end },
      { text = L["Dungeons"], onClick = function() if ns.PathWindow then ns.PathWindow:Open("dungeon") end end },
      { text = L["Settings"], onClick = function() if ns.Settings then ns.Settings:Open() end end },
    }
    if ns.Engine.guide then items[#items + 1] = { text = L["Stop guide"], onClick = function() ns.Engine:StopGuide() end } end
    -- istemedigin quest: butun rehberlerde gecilir (bagli quest'leri de); geri almak icin ayni satir
    local E, step = ns.Engine, ns.Engine:GetStep()
    local q = step and step.quest
    if q then
      local skipped = E:QuestSkipped(q)
      local qn = P.QuestName(q, step.name) or step.name or ("#" .. q)
      items[#items + 1] = { text = (skipped and L["Restore quest: %s"] or L["Skip this quest: %s"]):format(qn),
        onClick = function() E:SkipQuest(q, not skipped) end }
    end
    local D = ns.Island and ns.Island.Dock
    if D and D:Active() then
      items[#items + 1] = { text = L["Hub cards"], onClick = function() D:Collapse(); ns.Island:OpenHub() end }
      items[#items + 1] = { text = L["Detach from the hub"], onClick = function() D:Undock() end }
    end
    items[#items + 1] = { text = L["Lock position"], checked = Window.db.locked, onClick = function() Window.db.locked = not Window.db.locked end }
    Skin:ShowMenu(btn, items, 180)
  end)

  -- marka: yalnizca yazi; tiklanmaz, pencere buradan da surukelenir (fare olaylari pencereye gecer)
  self.brand = fstr(f, 14, C.accentHover, "CENTER", "")
  self.brand:SetPoint("TOP", f, "TOP", 0, -10)
  self.brand:SetText("Arcanis Path")

  self.closeButton = Skin:CreateCloseButton(f, 13)
  self.closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD + 4, -5)
  self.closeButton:SetScript("OnClick", function()
    Window.db.hidden = true
    Window:Update()
    ns:Print(L["Step window hidden. Type /wf window to show it again."])
  end)

  -- yukari ok: rehber ustteki adaya tasinir (UI/IslandGuide.lua); adadaki asagi ok geri getirir
  self.dockButton = Skin:CreateIconButton(f, "chevdown", 14, 20, 20)
  if self.dockButton.icon.SetRotation then self.dockButton.icon:SetRotation(math.pi) end
  self.dockButton:SetPoint("RIGHT", self.closeButton, "LEFT", -4, 0)
  self.dockButton:SetTooltip(L["Move to the Dynamic Hub"],
    L["The guide moves into the bar at the top of the screen. Click the bar for the full view."])
  -- tek dugme: hub'da degilken yukari ok (adaya tasi), hub'dayken asagi ok (pencere eski yerine doner)
  self.dockButton:SetScript("OnClick", function()
    local D = ns.Island and ns.Island.Dock
    if not D then return end
    if D:Active() then D:Undock() else D:DockWindow() end
  end)

  -- rehber secici + yeni rehber
  self.selector = Skin:CreateField(f, WIDTH - 2 * PAD - 30, 24, "compass")
  self.selector:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, SELECT_Y)
  self.title = self.selector.text
  local function guideMenu(anchor)
    if ns.PathWindow and ns.PathWindow.ShowGuideMenu then ns.PathWindow:ShowGuideMenu(anchor) end
  end
  self.selector:SetScript("OnClick", function(b) guideMenu(b) end)
  self.addButton = Skin:CreateIconButton(f, "plus", 22, 24, 24)
  self.addButton:SetPoint("LEFT", self.selector, "RIGHT", 6, 0)
  self.addButton:SetScript("OnClick", function() if ns.PathWindow then ns.PathWindow:OpenGuideList("suggested") end end)

  -- gezinme seridi: <- 3/8 ->  xp  ....  [gorev] [su anki] [harita]
  -- Tum ikon dugmeleri 24x20; kenarlardan 2 px, aralarinda 4 px (sol ve sag blok simetrik).
  self.nav = CreateFrame("Frame", nil, f, "BackdropTemplate")
  self.nav:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, NAV_Y)
  self.nav:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, NAV_Y)
  self.nav:SetHeight(24)
  Window:StyleNav()

  -- Oklar: sol tik bir adim, sag tik su anki (aktif) adima doner.
  local function arrowClick(move)
    return function(_, button)
      if button == "RightButton" then ns.Engine:JumpToCurrent() else move() end
    end
  end
  self.prevButton = Skin:CreateIconButton(self.nav, "larrow", 18, 24, 20)
  self.prevButton:SetPoint("LEFT", self.nav, "LEFT", 2, 0)
  self.prevButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self.prevButton:SetScript("OnClick", arrowClick(function() ns.Engine:Prev() end))
  self.prevButton:SetTooltip(L["Previous step"], L["Left-click: one step back"], L["Right-click: go to the current step"])
  self.progress = fstr(self.nav, 12, C.text, "CENTER", "")
  self.progress:SetWidth(56)
  self.progress:SetPoint("LEFT", self.prevButton, "RIGHT", 2, 0)
  self.nextButton = Skin:CreateIconButton(self.nav, "rarrow", 18, 24, 20)
  self.nextButton:SetPoint("LEFT", self.progress, "RIGHT", 2, 0)
  self.nextButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  -- sol tik ileri BAKAR (ilerleme degismez); Shift + tik adimi bilerek atlar
  self.nextButton:SetScript("OnClick", arrowClick(function()
    if P.IsShiftDown() then ns.Engine:Next() else ns.Engine:Browse() end
  end))
  self.nextButton:SetTooltip(L["Next step"], L["Left-click: one step forward"], L["Shift-click: skip this step"],
    L["Right-click: go to the current step"])

  -- sagdaki ikon grubu sik (1 px aralik): en yakin gorev | su anki adim | quest'i atla | harita
  self.flagButton = Skin:CreateIconButton(self.nav, "map", 18, 22, 20)
  self.flagButton:SetPoint("RIGHT", self.nav, "RIGHT", -2, 0)
  self.flagButton:SetActive(true)
  self.flagButton:SetScript("OnClick", function() Window:ShowOnMap() end)
  self.flagButton:SetTooltip(L["Show this step on the map"])

  -- adimin quest'ini atla / geri al (menudeki "Skip this quest" ile ayni; aktif = atlanmis)
  self.skipButton = Skin:CreateIconButton(self.nav, "skip", 18, 22, 20)
  self.skipButton:SetPoint("RIGHT", self.flagButton, "LEFT", -1, 0)
  self.skipButton:SetScript("OnClick", function()
    local E, step = ns.Engine, ns.Engine:GetStep()
    local q = step and step.quest
    if q then E:SkipQuest(q, not E:QuestSkipped(q)) end
  end)

  -- su anki adima don (oklarin sag tikiyla ayni is)
  self.jumpButton = Skin:CreateIconButton(self.nav, "flag", 18, 22, 20)
  self.jumpButton:SetPoint("RIGHT", self.skipButton, "LEFT", -1, 0)
  self.jumpButton:SetScript("OnClick", function() ns.Engine:JumpToCurrent() end)
  self.jumpButton:SetTooltip(L["Go to the current step"])

  -- en soldaki: en yakin goreve git
  self.currentButton = Skin:CreateIconButton(self.nav, "current", 18, 22, 20)
  self.currentButton:SetPoint("RIGHT", self.jumpButton, "LEFT", -1, 0)
  self.currentButton:SetScript("OnClick", function() Window:GoRecommended() end)
  self.currentButton:SetTooltip(L["Go to the nearest quest"])

  self.xpText = fstr(self.nav, 10, C.textDim)
  self.xpText:SetPoint("LEFT", self.nextButton, "RIGHT", 8, 0)
  self.xpText:SetPoint("RIGHT", self.currentButton, "LEFT", -8, 0)
  self.xpText:SetWordWrap(false)
  self.xpText:Hide()   -- XP / saat alttaki istatistik seridinde; ortada Auto / Pause dugmeleri
  self:NavToggles()

  -- adim satirlari
  -- aktif adim karti (gorev disi adimlar ve mesajlar) + gorev akordeonlari
  self.rows = { self:MakeRow(1) }
  self.card = self.rows[1]
  self.stepText = self.card.title
  self.accs, self.open = {}, {}
  self.advice = fstr(f, 10, C.textDim)
  self.advice:SetWordWrap(false)

  -- Gorev Beyni onerisi (yalniz oneri): tek satir; tiklayinca ok ilk oneriye doner, ipucunda hepsi + nedenleri
  -- kestirme satiri (Tips shortcut): quest kutusu kapaliyken de gorunur
  self.shortcut = fstr(f, 10, Skin.StatusColors.current)
  self.shortcut:SetWordWrap(true)
  self.shortcut:SetJustifyH("LEFT")
  self.brain = CreateFrame("Button", nil, f)
  self.brain:SetHeight(14)
  self.brain.text = fstr(self.brain, 10, C.accent)
  self.brain.text:SetAllPoints()
  self.brain.text:SetWordWrap(false)
  self.brain:Hide()
  self.brain:SetScript("OnClick", function()
    if Window.brainDetour then return end   -- sapmada ok zaten sapma adimini gosterir
    -- rehber disi (istege bagli) gorev oku rehberden almaz: ana gorevler her zaman once (sahibin karari, 15 Kasim 2026)
    local first = Window.plannerPick and Window.plannerPick.item
    for _, s in ipairs(not first and Window.brainList or {}) do
      if s.kind ~= "giver" then first = s break end
    end
    if first and ns.Brain then ns.SafeCall(ns.Brain.Point, ns.Brain, first) end
  end)
  self.brain:SetScript("OnEnter", function(b)
    if not (GameTooltip and Window.brainList and ns.Brain) then return end
    GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
    if Window.brainDetour then
      GameTooltip:SetText(L["Detour"], 1, 0.82, 0.2)
      GameTooltip:AddLine(Window.brainDetour, 1, 1, 1, true)
      GameTooltip:AddLine(L["After this step the guide returns to the route. \"Go to the current step\" returns now."], 0.5, 0.8, 1, true)
      GameTooltip:Show()
      return
    end
    local pick = Window.plannerPick
    if pick then
      GameTooltip:SetText(L["Next"], 1, 0.82, 0.2)
      GameTooltip:AddLine(ns.Brain:Label(pick.item), 1, 1, 1, true)
      if pick.item.reason then GameTooltip:AddLine(pick.item.reason, 0.7, 0.7, 0.7, true) end
      GameTooltip:AddLine(pick.reason, 0.4, 0.9, 0.5, true)
      if #Window.brainList > 1 then GameTooltip:AddLine(" ") end
    end
    if not pick or #Window.brainList > 1 then GameTooltip:AddLine(L["Do together"], 1, 0.82, 0.2) end
    for _, s in ipairs(Window.brainList) do
      if not (pick and s.kind == pick.item.kind and s.index == pick.item.index) then
      GameTooltip:AddLine(ns.Brain:Label(s), 1, 1, 1, true)
      if s.reason then GameTooltip:AddLine(s.reason, 0.7, 0.7, 0.7, true) end
      end
    end
    local onlyOptional = not pick
    for _, s in ipairs(Window.brainList) do if s.kind ~= "giver" then onlyOptional = false end end
    if onlyOptional then
      GameTooltip:AddLine(L["Optional quests do not move the arrow: the guide comes first. Their givers show a ! on the map."], 0.5, 0.8, 1, true)
    else
      GameTooltip:AddLine(L["Click: point the arrow at the first one. The guide order does not change."], 0.5, 0.8, 1, true)
    end
    GameTooltip:Show()
  end)
  self.brain:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  -- uzak hedef ipucu
  self.hintText = fstr(f, 10, C.textDim)
  self.hintText:SetWidth(WIDTH - 2 * PAD)

  -- genel ilerleme cubugu
  self.barBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
  self.barBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD)
  self.barBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD)
  self.barBg:SetHeight(BAR_H)
  Skin:ApplyBackdrop(self.barBg, { 0.10, 0.12, 0.16, 1 }, FRAME)
  self.barFill = self.barBg:CreateTexture(nil, "ARTWORK")
  self.barFill:SetPoint("TOPLEFT", 1, -1)
  self.barFill:SetPoint("BOTTOMLEFT", 1, 1)
  self.barFill:SetWidth(1)
  self.barFill:SetColorTexture(GREEN[1], GREEN[2], GREEN[3], 0.55)
  self.barText = fstr(self.barBg, 10, C.text, "CENTER", "OUTLINE")
  self.barText:SetPoint("CENTER", self.barBg, "CENTER", 0, 0)

  self.actionButton = Skin:CreateButton(f, "", WIDTH - 2 * PAD, 24, true)
  self.actionButton:SetScript("OnClick", function()
    if Window.action then Window.action() end
  end)

  -- mesafeler degistikce siralama ve oneri tazelenir (saniyede bir, yalnizca birden cok gorev varken)
  local acc = 0
  f:SetScript("OnUpdate", function(_, dt)
    acc = acc + (dt or 0)
    if acc < 1.2 then return end
    acc = 0
    -- Gorev Beyni aciksa tek gorevle yururken de tazelenir (oyuncunun yakinindaki hazir teslimler)
    local brainOn = ns.Brain and ns.Brain:IsEnabled() and ns.Brain.db.show
    if ((Window.plan and #Window.plan >= 2) or brainOn) and not Window.actionMode then ns.SafeCall(Window.Update, Window) end
  end)

  f:SetScript("OnDragStart", function(frame)
    local D = ns.Island and ns.Island.Dock
    if D and D:Expanded() then D:TearOff(frame) end   -- adanin altindan surukle: adadan ayrilir
    if not Window.db.locked then frame:StartMoving() end
  end)
  f:SetScript("OnDragStop", function(frame)
    frame:StopMovingOrSizing()
    local D = ns.Island and ns.Island.Dock
    if D and D:Expanded() then return end   -- hub'daki konum kaydedilmez
    -- hub'a birakildi: rehber adaya girer; birakilan yer kaydedilmez (asagi ok eski yere goturur)
    if D and not D:Active() and D:OverHub(frame) and D:DropIn() then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    if point then
      Window.db.point, Window.db.relPoint, Window.db.x, Window.db.y = point, relPoint, x, y
    end
    if ns.QuestItem and ns.QuestItem.Place then ns.QuestItem:Place() end
  end)
end

-- Gezinme seridinin ortasi: "Auto" (rehberin gorevlerini kendiliginden al / teslim et: QuestAuto "guide" modu)
-- ve "Pause" (rehber duraklar: kendiliginden ilerleme ve ok yok, Engine:SetPaused). Kucuk yuvarlak hap dugmeler.
local function pill(parent, w)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, 18)
  b.text = fstr(b, 10, C.textDim, "CENTER", "")
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  function b:Paint(on)
    self.on = on
    local c = on and C.accent or { 1, 1, 1 }
    Skin:ApplyRounded(self, { c[1], c[2], c[3], on and 0.30 or (self.hover and 0.12 or 0.07) }, 6)
    self.text:SetTextColor(unpack(on and C.text or (self.hover and C.text or C.textDim)))
  end
  b:SetScript("OnEnter", function(x)
    x.hover = true; x:Paint(x.on)
    if GameTooltip and x.tip then
      GameTooltip:SetOwner(x, "ANCHOR_BOTTOM"); GameTooltip:SetText(x.tip[1], 1, 0.82, 0.2)
      GameTooltip:AddLine(x.tip[2], 1, 1, 1, true); GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function(x) x.hover = false; x:Paint(x.on); if GameTooltip then GameTooltip:Hide() end end)
  b:Paint(false)
  return b
end
Window.Pill = pill   -- adadaki rehber karti (UI/IslandGuide.lua) ayni Auto / Pause dugmesini kullanir

function Window:NavToggles()
  if self.autoButton then return end
  self.autoButton = pill(self.nav, 40)
  self.autoButton:SetPoint("LEFT", self.nextButton, "RIGHT", 8, 0)
  self.autoButton.text:SetText(L["Auto"])
  self.autoButton.tip = { L["Auto quests"], L["Accepts and turns in the guide's quests for you. Hold Shift at a quest giver to do it by hand."] }
  self.autoButton:SetScript("OnClick", function() Window:ToggleAuto() end)
  self.pauseButton = pill(self.nav, 48)
  self.pauseButton:SetPoint("LEFT", self.autoButton, "RIGHT", 4, 0)
  self.pauseButton.tip = { L["Pause guide"], L["Stops the guide from moving on by itself and hides the arrow. The step arrows still work."] }
  self.pauseButton:SetScript("OnClick", function()
    local E = ns.Engine
    E:SetPaused(not E:IsPaused())
    Window:Update()
  end)
  self:UpdateNavToggles()
end

-- Auto: QuestAuto "off" <-> son secilen mod (yoksa "guide"); modul kapaliysa acilir
function Window:ToggleAuto()
  local Q = ns.QuestAuto
  if not Q then return end
  if Q.db.mode ~= "off" and Q:IsEnabled() then
    Q.db.lastMode = Q.db.mode
    Q.db.mode = "off"
  else
    if not Q:IsEnabled() and Q.SetEnabled then Q:SetEnabled(true) end
    Q.db.mode = (Q.db.lastMode and Q.db.lastMode ~= "off") and Q.db.lastMode or "guide"
  end
  self:UpdateNavToggles()
end

function Window:UpdateNavToggles()
  if not self.autoButton then return end
  local Q, E = ns.QuestAuto, ns.Engine
  self.autoButton:Paint(Q ~= nil and Q:IsEnabled() and Q.db.mode ~= "off")
  local paused = E and E.IsPaused and E:IsPaused()
  self.pauseButton.text:SetText(paused and L["Resume"] or L["Pause"])
  self.pauseButton:Paint(paused and true or false)
end

-- Rehber sekmeleri (baslik altindaki serit): acik rehberler (Engine:TabList) pencereye yapisik
-- gercek sekmeler. Etkin sekme alttaki sayfayla (cam zemin) ayni tonda ve onunla birlesir; ustunde vurgu cizgisi
-- sekmeler arasinda kayar. Etkin sekmeye tik rehber menusu (secicinin isi), digerine tik o rehbere gecer; fare
-- ustundeyken kapat; sag tik menu, orta tik kapatir. Sondaki "+" rehber listesi, sigmayanlar sagdaki ok menusunde.
-- Sekmeler aciksa eski secici satiri gizlenir ve serit onun yerini alir (dikey duzen degismez).
local GTAB_H, GTAB_MIN, GTAB_MAX, GTAB_R = 24, 64, 150, 6
local GLASS = { 1, 1, 1, 0.07 }           -- etkin sekme + hemen altindaki gezinme seridi (ayni ton, birlesik)
local GLASS_EDGE = { 1, 1, 1, 0.09 }
local HOVER = { 1, 1, 1, 0.03 }

local function guideIcon(g)
  if g.dungeon then return "dungeon" end
  if type(g.id) == "string" and g.id:match("^prof%-") then return "hammer" end
  return "compass"
end

local function flat(parent, layer, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetTexture("Interface\\Buttons\\WHITE8x8")
  t._skinFixed = true
  return t
end

-- Ust koseleri yuvarlak zemin (sekme): :Paint(renk [, alfa])
local function topRound(b)
  local r = GTAB_R
  local p = {}
  p.top = flat(b, "BACKGROUND", 1)
  p.top:SetPoint("TOPLEFT", b, "TOPLEFT", r, 0); p.top:SetPoint("BOTTOMRIGHT", b, "TOPRIGHT", -r, -r)
  p.mid = flat(b, "BACKGROUND", 1)
  p.mid:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -r); p.mid:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
  p.tl = b:CreateTexture(nil, "BACKGROUND", nil, 1); p.tl:SetTexture(Skin.Icons.corner); p.tl._skinFixed = true
  p.tl:SetSize(r, r); p.tl:SetPoint("TOPLEFT")
  p.tr = b:CreateTexture(nil, "BACKGROUND", nil, 1); p.tr:SetTexture(Skin.Icons.corner); p.tr._skinFixed = true
  p.tr:SetSize(r, r); p.tr:SetPoint("TOPRIGHT"); p.tr:SetTexCoord(1, 0, 0, 1)
  function p:Paint(c, a)
    for _, t in ipairs({ self.top, self.mid, self.tl, self.tr }) do t:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1) end
  end
  return p
end

function Window:GuideTabBar()
  local s = self.guideTabs
  if s then return s end
  local f = self.frame
  s = CreateFrame("Frame", nil, f)
  s:SetHeight(GTAB_H)
  s:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, SELECT_Y)
  s:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, SELECT_Y)
  s.buttons = {}
  -- sayfa: sekmelerin altindan pencerenin dibine cam zemin; ust kenar cizgisi etkin sekmenin altinda acik
  s.sheet = CreateFrame("Frame", nil, f)
  s.sheet:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, 0)
  s.sheet:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD - 4)
  s.sheet.fill = flat(s.sheet, "BACKGROUND", 0)
  s.sheet.fill:SetAllPoints()
  s.lineL = flat(s.sheet, "BORDER", 0); ns.Skin:Hairline(s.lineL, "h")
  s.lineR = flat(s.sheet, "BORDER", 0); ns.Skin:Hairline(s.lineR, "h")
  -- kayan vurgu: etkin sekmenin ustunde ince cizgi + yumusak parlama
  s.glow = s:CreateTexture(nil, "ARTWORK"); s.glow:SetTexture(Skin.Icons.glow); s.glow._skinFixed = true
  s.glow:SetHeight(14); s.glow:SetBlendMode("ADD")
  s.mark = flat(s, "OVERLAY", 2); s.mark:SetHeight(2)
  s.add = Skin:CreateIconButton(s, "plus", 14, 22, GTAB_H)
  s.add:SetScript("OnClick", function() if ns.PathWindow then ns.PathWindow:OpenGuideList("suggested") end end)
  s.add:SetTooltip(L["Open another guide"])
  s.more = Skin:CreateIconButton(s, "chevdown", 14, 20, GTAB_H)
  s.more:SetPoint("RIGHT", s, "RIGHT", 0, 0)
  s.more:SetScript("OnClick", function(b) Window:GuideTabMenu(b) end)
  s.more:SetTooltip(L["All open guides"])
  s:Hide(); s.sheet:Hide()
  self.guideTabs = s
  return s
end

-- Vurgu cizgisini etkin sekmeye tasir (gecis animasyonlu; ilk kez ya da animasyonsuz aninda)
function Window:MoveTabMark(x, w, animate)
  local s = self.guideTabs
  local function put(px, pw)
    s.markX, s.markW = px, pw
    s.mark:ClearAllPoints(); s.mark:SetPoint("TOPLEFT", s, "TOPLEFT", px + GTAB_R, 0)
    s.mark:SetWidth(math.max(4, pw - 2 * GTAB_R))
    s.glow:ClearAllPoints(); s.glow:SetPoint("TOPLEFT", s, "TOPLEFT", px, 6); s.glow:SetWidth(pw)
  end
  if not animate or not s.markX then Skin:CancelTween(s); put(x, w) return end
  local x0, w0 = s.markX, s.markW
  if x0 == x and w0 == w then return end
  Skin:Tween(s, 0.22, function(p) put(x0 + (x - x0) * p, w0 + (w - w0) * p) end)
end

-- Sayfa icerigi rehber degisince yumusakca belirir
function Window:FadeContent()
  local parts = { self.nav, self.card, self.advice, self.brain, self.shortcut, self.hintText }
  for _, a in ipairs(self.accs or {}) do parts[#parts + 1] = a end
  local key = self.fadeKey or {}
  self.fadeKey = key
  Skin:Tween(key, 0.25, function(p) for _, x in ipairs(parts) do if x.SetAlpha then x:SetAlpha(0.15 + 0.85 * p) end end end)
end

-- Sekmenin sag tik menusu
function Window:GuideTabActions(anchor, id)
  local E = ns.Engine
  local items = {}
  if not (E.guide and E.guide.id == id) then
    items[#items + 1] = { text = L["Open"], onClick = function() E:OpenGuide(id) end }
  end
  items[#items + 1] = { text = L["Close tab"], onClick = function() E:CloseTab(id) end }
  if #E:OpenTabs() > 1 then
    items[#items + 1] = { text = L["Close other tabs"], onClick = function()
      for _, g in ipairs(E:OpenTabs()) do if g.id ~= id then E:RemoveTab(g.id) end end
      if not (E.guide and E.guide.id == id) then E:OpenGuide(id) end
      ns:Send("ARCANIS_TABS_CHANGED")
    end }
  end
  Skin:ShowMenu(anchor, items, 170)
end

-- Tasma menusu: acik rehberlerin hepsi (etkin isaretli)
function Window:GuideTabMenu(anchor)
  local E = ns.Engine
  local items = {}
  for _, g in ipairs(E:OpenTabs()) do
    local id = g.id
    items[#items + 1] = { text = ns.Guides:ShortTitle(g), checked = E.guide and E.guide.id == id or false,
      onClick = function() E:OpenGuide(id) end }
  end
  Skin:ShowMenu(anchor, items, 200)
end

-- Duz sekme: etkin sekme gezinme seridiyle ayni tonda (birlesik), digerleri zeminsiz; kapat etkinde hep,
-- digerlerinde fare ustundeyken
local function paintTab(b)
  local on, hover = b.active, b.hover
  if on then b.bg:Paint(GLASS) elseif hover then b.bg:Paint(HOVER) else b.bg:Paint(HOVER, 0) end
  b.text:SetTextColor(unpack((on or hover) and C.text or C.textDim))
  b.icon:SetVertexColor(unpack(on and C.accent or (hover and C.text or C.textDim)))
  b.close:SetShown(on or hover)
  b.drop:Hide()
end

local function guideTabButton(strip, i)
  local b = strip.buttons[i]
  if b then return b end
  b = CreateFrame("Button", nil, strip)
  b:SetHeight(GTAB_H)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
  b.bg = topRound(b)
  b.icon = tex(b, "compass", 12, C.textDim)
  b.icon:SetPoint("LEFT", b, "LEFT", 8, 0)
  b.text = fstr(b, 11, C.textDim)
  b.text:SetWordWrap(false)
  b.text:SetPoint("LEFT", b.icon, "RIGHT", 4, 0)
  b.close = Skin:CreateIconButton(b, "close", 10, 16, 16)
  b.close:SetPoint("RIGHT", b, "RIGHT", -4, 0)
  b.close:SetScript("OnClick", function() if b.id then ns.Engine:CloseTab(b.id) end end)
  b.close:SetTooltip(L["Close tab"])
  b.drop = tex(b, "chevdown", 10, C.textDim)
  b.drop:SetPoint("RIGHT", b, "RIGHT", -8, 0)
  b:SetScript("OnClick", function(_, button)
    local E = ns.Engine
    if not b.id then return end
    if button == "MiddleButton" then E:CloseTab(b.id)
    elseif button == "RightButton" then Window:GuideTabActions(b, b.id)
    elseif E.guide and E.guide.id == b.id then
      if ns.PathWindow and ns.PathWindow.ShowGuideMenu then ns.PathWindow:ShowGuideMenu(b) end
    else E:OpenGuide(b.id) end
  end)
  b:SetScript("OnEnter", function(x)
    x.hover = true; paintTab(x)
    local g = x.id and ns.Guides:Get(x.id)
    if not (GameTooltip and g) then return end
    GameTooltip:SetOwner(x, "ANCHOR_BOTTOM")
    GameTooltip:SetText(ns.Guides:TitleOf(g), 1, 0.82, 0.2)
    local E = ns.Engine
    local at = (E.guide and E.guide.id == g.id) and E.index or (E.char and E.char.progress and E.char.progress[g.id]) or 1
    local total = E:StepTotal(g)
    GameTooltip:AddLine(L["Step %d/%d"]:format(math.min(at, total), total), 1, 1, 1)
    GameTooltip:AddLine(x.active and L["Click: pick a guide. Right-click: tab menu."]
      or L["Click: switch guide. Right-click: tab menu. Middle-click: close."], 0.5, 0.8, 1, true)
    GameTooltip:Show()
  end)
  -- kapat dugmesine gecince sekme "ustunde" sayilir (dugme kaybolmasin)
  b:SetScript("OnLeave", function(x)
    if x.close.IsMouseOver and x.close:IsMouseOver() then return end
    x.hover = false; paintTab(x)
    if GameTooltip then GameTooltip:Hide() end
  end)
  if b.close.HookScript then
    b.close:HookScript("OnLeave", function()
      if b.IsMouseOver and b:IsMouseOver() then return end
      b.hover = false; paintTab(b)
    end)
  end
  strip.buttons[i] = b
  return b
end

-- Secici, gezinme seridi ve kart: off kadar asagi (sekmeler secicinin yerinde durur: 0)
function Window:PlaceTop(off)
  if self.topOffset == off then return end
  self.topOffset = off
  local f = self.frame
  self.selector:ClearAllPoints()
  self.selector:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, SELECT_Y - off)
  self.nav:ClearAllPoints()
  self.nav:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, NAV_Y - off)
  self.nav:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, NAV_Y - off)
  self.card:ClearAllPoints()
  self.card:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, LIST_Y - off)
  self.card:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, LIST_Y - off)
end

function Window:UpdateGuideTabs()
  if not self.frame then return end
  local E = ns.Engine
  local open = (self.db.guideTabs ~= false and E and E.OpenTabs) and E:OpenTabs() or {}
  local active = E and E.guide and E.guide.id
  local strip = self.guideTabs
  self:PlaceTop(0)
  if #open == 0 then
    if strip then strip:Hide(); strip.sheet:Hide(); strip.activeId = nil end
    self.selector:Show(); self.addButton:Show()
    self.tabsShown = 0
    return
  end
  strip = self:GuideTabBar()
  self.selector:Hide(); self.addButton:Hide()
  self:PlaceTop(-4)   -- gezinme seridi etkin sekmenin hemen altinda, ayni tonda
  -- genislikler: ikon + metin + (ok / kapat) ; MIN..MAX
  local widths, total = {}, 0
  for i, g in ipairs(open) do
    local b = guideTabButton(strip, i)
    b.text:SetText(ns.Guides:ShortTitle(g))
    local tw = b.text:GetStringWidth()
    tw = (type(tw) == "number" and tw > 0) and tw or #ns.Guides:ShortTitle(g) * 6
    local w = 8 + 12 + 4 + tw + 22
    widths[i] = math.floor(math.max(GTAB_MIN, math.min(GTAB_MAX, w)) + 0.5)
    total = total + widths[i] + (i > 1 and 2 or 0)
  end
  local avail = WIDTH - 2 * PAD - 22 - 4          -- sondaki "+"
  local vis = {}
  for i = 1, #open do vis[i] = true end
  local over = total > avail
  if over then
    avail = avail - 20 - 2
    local used = total
    -- sigana kadar etkin olmayan sekmeler gizlenir (sondan)
    while used > avail do
      local drop
      for i = #open, 1, -1 do if vis[i] and open[i].id ~= active then drop = i break end end
      if not drop then break end
      vis[drop] = false
      used = used - widths[drop] - 2
    end
  end
  local x, shown, ax, aw = 0, 0, nil, nil
  for i, g in ipairs(open) do
    local b = strip.buttons[i]
    b.id = g.id
    if vis[i] then
      local on = g.id == active
      b.active = on
      local w = math.max(GTAB_MIN, math.min(widths[i], avail - x))
      b:ClearAllPoints()
      b:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", x, 0)
      b:SetWidth(w)
      b.text:SetWidth(math.max(8, w - 8 - 12 - 4 - 22))
      b.icon:SetTexture(Skin.Icons[guideIcon(g)])
      paintTab(b)
      b:Show()
      if on then ax, aw = x, w end
      x = x + w + 2
      shown = shown + 1
    else
      b:Hide()
    end
  end
  for i = #open + 1, #strip.buttons do strip.buttons[i].id = nil; strip.buttons[i]:Hide() end
  strip.add:ClearAllPoints()
  strip.add:SetPoint("LEFT", strip, "LEFT", x + 2, 0)
  strip.more:SetShown(over)
  -- sade gorunum: ayri sayfa zemini, cizgi ve parlama yok (sekme gezinme seridiyle birlesir)
  local sheet = strip.sheet
  sheet.fill:SetVertexColor(GLASS[1], GLASS[2], GLASS[3], GLASS[4])
  for _, l in ipairs({ strip.lineL, strip.lineR }) do l:SetVertexColor(GLASS_EDGE[1], GLASS_EDGE[2], GLASS_EDGE[3], GLASS_EDGE[4]) end
  strip.lineL:ClearAllPoints(); strip.lineR:ClearAllPoints()
  strip.lineL:SetPoint("TOPLEFT", sheet, "TOPLEFT", 0, 0)
  strip.lineR:SetPoint("TOPRIGHT", sheet, "TOPRIGHT", 0, 0)
  if ax then
    strip.lineL:SetWidth(math.max(0.01, ax)); strip.lineL:SetShown(ax > 0)
    strip.lineR:SetPoint("TOPLEFT", sheet, "TOPLEFT", ax + aw, 0); strip.lineR:Show()
    strip.mark:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    strip.glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.35)
    strip.mark:Hide(); strip.glow:Hide(); strip.lineL:Hide(); strip.lineR:Hide()
    local animate = strip.activeId ~= nil and strip.activeId ~= active
    self:MoveTabMark(ax, aw, false)
    if animate then self:FadeContent() end
  else
    strip.lineL:SetPoint("TOPRIGHT", sheet, "TOPRIGHT", 0, 0); strip.lineL:Show()
    strip.lineR:Hide()
    strip.mark:Hide(); strip.glow:Hide()
  end
  strip.activeId = active
  strip:Show(); sheet:Hide()
  self.tabsShown = shown
end

function Window:ApplyPosition()
  local f = self.frame
  local D = ns.Island and ns.Island.Dock
  if not (D and D:Anchor(f)) then   -- rehber adadayken acik pencere adanin altinda (UI/IslandGuide.lua)
    f:ClearAllPoints()
    f:SetPoint(self.db.point, UIParent, self.db.relPoint, self.db.x, self.db.y)
  end
  f:SetScale(self.db.scale)
  if ns.Skin.Resnap then ns.Skin:Resnap() end   -- ince cizgiler yeni olcekte tam piksel
  self:ApplyAlpha()
  if ns.QuestItem and ns.QuestItem.Place then ns.QuestItem:Place() end
end

-- Baslik dugmeleri: yukari ok rehberi adaya tasir (adadaysa pencereyi katlar), igne adadan ayirir.
function Window:UpdateDockButtons(docked)
  local b = self.dockButton
  if not b then return end
  b:SetShown(ns.Island ~= nil and ns.Island:IsEnabled())
  if b.icon.SetRotation then b.icon:SetRotation(docked and 0 or math.pi) end   -- chevdown: 0 asagi, pi yukari
  if docked then
    b:SetTooltip(L["Detach from the hub"], L["The window goes back to its own place and the arrow comes back on screen."])
  else
    b:SetTooltip(L["Move to the Dynamic Hub"],
      L["The guide moves into the bar at the top of the screen. Click the bar for the full view."])
  end
end

-- Arka plan saydamligi: pencere, secici, serit (satirlar Update'te boyanir). Yazilar opak kalir.
function Window:ApplyAlpha()
  if not self.frame then return end
  -- hub'in icindeyken zemin ve kenar saydam: adanin zemini gorunur, tek yuzey (UI/IslandGuide.lua Seat)
  local D = ns.Island and ns.Island.Dock
  if D and D.seated then
    if self.chrome then self.chrome:SetColors({ 0, 0, 0, 0 }, { 0, 0, 0, 0 }) end
  elseif self.chrome then self.chrome:SetColors(fade(PANEL), FRAME) end
  Skin:ApplyBackdrop(self.selector, fade(ROW_BG), C.border)
  self:StyleNav()
end

-- Gezinme seridi: hub kartlari gibi cam (beyazin cok soluk tonu, ince acik kenar)
function Window:StyleNav()
  Skin:ApplyBackdrop(self.nav, { 1, 1, 1, 0.07 }, { 1, 1, 1, 0 })
end

-- Aktif adimin konumunu dunya haritasinda acar.
function Window:ShowOnMap()
  local step = ns.Engine:GetStep()
  local map = step and ns.Zones:Location(step)
  if not map then ns:Print(L["No map data for this step."]) return end
  -- oyunun harita isareti konmaz: ok onu izler (Nav:OnUserWaypoint) ve rehberin hedefini ezerdi; adimi Pins gosterir
  if OpenWorldMap then pcall(OpenWorldMap, map)
  elseif WorldMapFrame and WorldMapFrame.SetMapID then
    pcall(function() if ShowUIPanel then ShowUIPanel(WorldMapFrame) end; WorldMapFrame:SetMapID(map) end)
  end
end

-- Icerik
local function stepLine(step)
  local text = ns.Engine:Describe(step)
  if step.optional then text = text .. " " .. L["(optional)"] end
  return text
end

-- done: adim kesin bitti (geri gezinirken) -> yesil kenar ve yazi, tik ikonu, "Completed" etiketi.
function Window:PaintRow(row, step, index, current, done)
  row.stepIndex = index
  row.current = current
  row.done = done and true or false
  row.danger = not row.done and isDanger(step)
  local tcol = Skin.TypeColors[step.type] or C.accent
  row.icon:SetTexture(Skin.Icons[row.done and "check" or (TYPE_ICON[step.type] or "current")])
  row.title:SetText(stepLine(step))

  local sub
  local have, need, objText
  if current then have, need, objText = progressOf(step) end
  if current then
    local tip = step.tip and ns:LocalizedText(step.tip)
    if not tip and step.quest and ns.Tips then tip = ns.Tips:Get(step.quest) end
    sub = objText or tip
  end
  if not sub then
    local parts = {}
    if step.npc and not tostring(row.title:GetText() or ""):find(step.npc, 1, true) then parts[#parts + 1] = step.npc end
    local zone = zoneName(step)
    if zone then
      if step.x then parts[#parts + 1] = ("%s (%d, %d)"):format(zone, math.floor(step.x * 100 + 0.5), math.floor(step.y * 100 + 0.5))
      else parts[#parts + 1] = zone end
    end
    sub = table.concat(parts, "  -  ")
  end
  -- zindan gorev rehberi: zincirdeki gorev hangi zindan gorevini aciyor (Guide/DungeonGuides.lua)
  if step.unlocks and ns.DungeonGuides then
    local u = L["Unlocks: %s"]:format(ns.DungeonGuides.QuestName(step.unlocks))
    sub = (sub and sub ~= "" and (sub .. "  -  ") or "") .. u
  end
  -- quest ipucu (bina icinde, ust kat, magara...): yalniz su anki adimda
  local hint = current and ns.Hints and ns.Hints:For(step)
  if hint then sub = (sub and sub ~= "" and (sub .. "  -  ") or "") .. hint end
  -- teslim adiminda gorevin XP'si (Leveling: "Show quest XP")
  local Lv = ns.Leveling
  local xp = step.type == "turnin" and not row.done and Lv and Lv:IsEnabled() and Lv.db.questXP and Lv:QuestXP(step.quest)
  if xp then sub = (sub and sub ~= "" and (sub .. "  -  ") or "") .. L["+%s XP"]:format(Lv.FormatXP(xp)) end
  -- gecilen ama yapilmamis adim (bekliyor, artik alinamaz, bu karaktere degil): "Completed" yazmaz, nedeni alt satirda
  local st, why, ref = ns.Engine:StepStatus(step)
  row.skipped = row.done and (st == "wait" or st == "gone" or st == "na") or false
  local reason = row.skipped and st ~= "na" and ns.Engine:WaitText(why, ref)
  if reason then sub = (sub and sub ~= "" and (sub .. "  -  ") or "") .. reason end
  -- besleyici adim (Engine/Route.lua): hangi rehberden geldigi
  local from = step.feeder and ns.Guides:Get(step.feeder)
  if from then sub = (sub and sub ~= "" and (sub .. "  -  ") or "") .. L["From the guide %s"]:format(ns.Guides:TitleOf(from)) end
  row.sub:SetText(sub or "")

  if row.skipped then
    row.count:SetText(st ~= "wait" and L["Skipped"] or (why == "refused" or why == "gate") and L["Not offered"] or L["Waiting"])
  elseif row.done then
    row.count:SetText(L["Completed"])
  elseif have and need then
    row.count:SetText(("(%d/%d)"):format(have, need))
  elseif step.count and (step.type == "kill" or step.type == "collect") then
    row.count:SetText(("(0/%d)"):format(step.count))
  else
    row.count:SetText("")
  end
  local kind = not row.done and rightIcon(step)
  if kind then row.kind:SetTexture(Skin.Icons[kind]); row.kind:Show() else row.kind:Hide() end
  -- sayac yoksa ikon saga yaslanir
  row.kind:ClearAllPoints()
  row.kind:SetPoint("RIGHT", row, "RIGHT", (row.count:GetText() or "") ~= "" and -44 or -10, 0)

  if row.skipped then
    paintCard(row, fade(ROW_BG), C.border, nil)
    row.icon:SetVertexColor(unpack(C.textDim)); row.title:SetTextColor(unpack(C.textDim))
    row.count:SetTextColor(unpack(C.textDim))
  elseif row.done then
    local ok = Skin.StatusColors.ready
    paintCard(row, fade(ROW_BG), ok, ok)
    row.icon:SetVertexColor(unpack(ok)); row.title:SetTextColor(unpack(ok))
    row.count:SetTextColor(unpack(ok))
  elseif row.danger then
    paintCard(row, fade(DANGER_BG), DANGER, DANGER)
    row.icon:SetVertexColor(unpack(DANGER)); row.title:SetTextColor(unpack(DANGER))
    row.kind:SetVertexColor(unpack(DANGER)); row.count:SetTextColor(1, 0.75, 0.72, 1)
  elseif current then
    paintCard(row, fade(ROW_ACTIVE), BLUE, tcol)
    row.icon:SetVertexColor(1, 1, 1, 1); row.title:SetTextColor(unpack(C.text))
    row.kind:SetVertexColor(unpack(C.text)); row.count:SetTextColor(unpack(C.text))
  else
    paintCard(row, fade(ROW_BG), C.border, nil)
    row.icon:SetVertexColor(tcol[1], tcol[2], tcol[3], 0.85); row.title:SetTextColor(unpack(C.text))
    row.kind:SetVertexColor(unpack(C.textDim)); row.count:SetTextColor(unpack(C.textDim))
  end
  row.sub:SetTextColor(unpack(C.textDim))
  row:Show()
end

-- Uzak hedef: aktif adimin konumu cok uzaktaysa ucus noktasi / tas hatirlatir.
local FAR_YARDS = 1500
local FOCUS_NEAR = 60       -- yd: aktif adimin gorevi yoksa bu kadar yakindaki onerilen gorev "simdi" olur
local SHORTCUT_NEAR = 600   -- yd: kestirme ipucu (olum kestirmesi) bundan yakin hedefte gosterilmez
function Window:TravelHint(step)
  if not (step and step.type ~= "fly" and step.type ~= "hearth") then return nil end
  local map, x, y = ns.Zones:Location(step)
  if not map then return nil end
  local dist = P.DistanceTo(map, x, y)
  if dist and dist >= FAR_YARDS then
    return L["Far away (%s). Consider a flight path or your hearthstone."]:format(ns.NavMath.FormatDistance(dist))
  end
  return nil
end

local function setFill(self, fraction)
  fraction = math.max(0, math.min(1, fraction))
  local width = (WIDTH - 2 * PAD - 2) * fraction
  self.barFill:SetWidth(math.max(1, width))
  if self.barText then
    self.barText:SetText(ns.Engine.guide and L["Guide progress  %d%%"]:format(math.floor(fraction * 100 + 0.5)) or "")
  end
end
Window.BAR_W = WIDTH - 2 * PAD - 2

-- XP/saat ozeti (Leveling modulu); veri yoksa bos.
function Window:UpdateXP()
  if not self.xpText then return end
  local line = ns.Leveling and ns.Leveling.db.show and not self.actionMode and ns.Leveling:Line() or nil
  self.xpText:SetText(line or "")
end

-- Eylem modu: satirlar yerine mesaj + tek dugme.
function Window:ShowAction(message, text, fn)
  self.action = fn
  self.actionMode = true
  for _, acc in ipairs(self.accs) do acc.active = false; acc.questId = nil; acc:Hide() end
  if self.zoneAcc then self.zoneAcc.active = false; self.zoneAcc:Hide() end
  if self.trainAcc then self.trainAcc.active = false; self.trainAcc:Hide() end
  if self.campAcc then self.campAcc.active = false; self.campAcc:Hide() end
  if self.classAcc then self.classAcc.active = false; self.classAcc:Hide() end
  self.showCard = true
  local row = self.card
  row.stepIndex, row.current, row.danger, row.done = nil, false, false, false
  Skin:ApplyBackdrop(row, fade(ROW_BG), C.border)
  row.icon:SetTexture(Skin.Icons.compass); row.icon:SetVertexColor(unpack(C.accent))
  row.title:SetText(message); row.title:SetTextColor(unpack(C.text))
  row.sub:SetText(""); row.count:SetText(""); row.kind:Hide()
  row:Show()
  self.actionButton:SetText(text)
  self.actionButton:ClearAllPoints()
  self.actionButton:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -8)
  self.actionButton:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, -8)
  self.actionButton:Show()
  self.prevButton:Hide()
  self.nextButton:Hide()
  self.currentButton:Hide()
  self.jumpButton:Hide()
  self.skipButton:Hide()
  self.flagButton:Hide()
  self:UpdateXP()
end

function Window:ShowNavigation()
  self.action = nil
  self.actionMode = false
  self.actionButton:Hide()
  self.prevButton:Show()
  self.nextButton:Show()
  self.currentButton:Show()
  self.jumpButton:Show()
  self.skipButton:Show()
  self.flagButton:Show()
  self:UpdateXP()
end

-- Gorev akordeonu (ortak Skin bileseni): baslik = gorev adi + sayac, govde = ne yapilacak.
function Window:GetAcc(i)
  local acc = self.accs[i]
  if acc then return acc end
  acc = Skin:CreateAccordion(self.frame, WIDTH - 2 * PAD, 26, "row")
  acc.onAnimate = function() Window:Layout() end
  acc.onToggle = function(x) if x.questId then Window.open[x.questId] = x.expanded end end
  -- hedef satiri (tiklanir): ne yapilacak + nerede
  acc.go = CreateFrame("Button", nil, acc.body)
  acc.go:SetHeight(16)
  acc.go:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 8, -4)
  acc.go:SetPoint("TOPRIGHT", acc.body, "TOPRIGHT", -6, -4)
  -- hedef isareti: vurgu renkli yuvarlatilmis kare icinde ok
  acc.go.box = acc.go:CreateTexture(nil, "ARTWORK")
  acc.go.box:SetSize(6, 6)
  acc.go.box:SetPoint("LEFT", 4, 0)
  acc.go.box:SetTexture(Skin.Icons.roundrect)
  acc.go.box:SetVertexColor(unpack(BLUE))
  acc.go.text = fstr(acc.go, 11, C.text)
  acc.go.text:SetPoint("LEFT", acc.go.box, "RIGHT", 7, 0)
  acc.go.text:SetPoint("RIGHT", -2, 0)
  acc.go.text:SetWordWrap(false)
  acc.go.hl = acc.go:CreateTexture(nil, "BACKGROUND")
  acc.go.hl:SetAllPoints()
  acc.go.hl:SetColorTexture(1, 1, 1, 0.06)
  acc.go.hl:Hide()
  acc.go:SetScript("OnEnter", function(g) g.hl:Show() end)
  acc.go:SetScript("OnLeave", function(g) g.hl:Hide() end)
  acc.go:SetScript("OnClick", function()
    local E = ns.Engine
    local p = acc.plan
    if p and p.index and E.guide then E:SetGuide(E.guide.id, p.index)
    elseif p and p.target and ns.Nav then   -- rehber disi (sinif) quest: ok hedefe
      ns.Nav:SetTarget(p.target.map, p.target.x, p.target.y, p.target.label, "manual")
    end
  end)
  acc.text = fstr(acc.body, 11, C.text)
  -- konum satiri (hedefin altinda, kendi satirinda): pin + bolge (x, y)
  acc.loc = CreateFrame("Frame", nil, acc.body)
  acc.loc:SetHeight(14)
  acc.loc:SetPoint("TOPLEFT", acc.go, "BOTTOMLEFT", 2, 0)
  acc.loc:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
  acc.loc.icon = acc.loc:CreateTexture(nil, "ARTWORK")
  acc.loc.icon:SetSize(10, 10)
  acc.loc.icon:SetPoint("LEFT", 0, 0)
  acc.loc.icon:SetTexture(Skin.Icons.pin)
  acc.loc.icon:SetVertexColor(unpack(C.textDim))
  acc.loc.text = fstr(acc.loc, 10, C.textDim)
  acc.loc.text:SetPoint("LEFT", acc.loc.icon, "RIGHT", 5, 0)
  acc.loc.text:SetPoint("RIGHT", 0, 0)
  acc.loc.text:SetWordWrap(false)
  acc.text:SetPoint("TOPLEFT", acc.loc, "BOTTOMLEFT", 2, -3)
  acc.text:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
  acc.text:SetJustifyV("TOP")
  acc.text:SetWordWrap(true)
  -- hedef satirlarindan sonraki metin (teslim, not, ipucu, sinif bilgisi)
  acc.text2 = fstr(acc.body, 11, C.text)
  acc.text2:SetJustifyV("TOP")
  acc.text2:SetWordWrap(true)
  acc.go:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 0, -2)
  -- bant satiri: baslik adimin kendisi; govdede yalniz konum + hedefler, agac cizgisinin sagina girintili
  acc.go:Hide()
  -- sag tik: ok bu ise (eski hedef satirinin isi); sol tik acar/kapatir
  local toggle = acc.header:GetScript("OnClick")
  acc.header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  acc.header:SetScript("OnClick", function(h, button)
    if button == "RightButton" then
      local go = acc.go:GetScript("OnClick")
      if go then go(acc.go) end
    elseif toggle then toggle(h, button) end
  end)
  acc.loc:ClearAllPoints()
  acc.loc:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 22, -4)
  acc.loc:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
  self.accs[i] = acc
  return acc
end

local function hex(c)
  return ("|cff%02x%02x%02x"):format(math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- Hedef satiri simgesi: bitmis -> yesil onay; degilse oyunun hedef turune gore (yaratik, esya, nesne, olay, itibar)
local OBJ_ICON = { monster = "sword", item = "bag", object = "box", event = "flag", reputation = "star", player = "sword" }
local function objIcon(o)
  local name = o.finished and "check" or OBJ_ICON[o.type]
    or ((o.text or ""):find("slain", 1, true) and "sword") or "disc"
  local c = o.finished and GREEN or C.accent
  return ("|T%s:12:12:0:0:64:64:0:64:0:64:%d:%d:%d|t "):format(Skin.Icons[name],
    math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end
Window.ObjIcon = objIcon

-- Bitmemis hedefin rengi ilerlemeye gore: kirmizi (pending) -> turuncu (current) -> yesil (ready);
-- bitmeye az kalan hedef goze carpsin (sahibin istegi, 8 Kasim 2026)
local function progressColor(o, cur, target)
  local S = Skin.StatusColors
  local have, need = cur, target
  if not have then have, need = tonumber(o.numFulfilled) or 0, tonumber(o.numRequired) or 0 end
  local f = (need and need > 0) and math.max(0, math.min(1, have / need)) or 0
  local a, b = S.pending, S.current
  if f >= 0.5 then a, b, f = S.current, S.ready, f - 0.5 end
  f = f * 2
  return { a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f }
end
Window.ProgressColor = progressColor
-- odak noktasi (renk temadan, cizim aninda)
local function focusDot()
  return ("|T%s:8:8:0:0:64:64:0:64:0:64:%d:%d:%d|t "):format(Skin.Icons.disc,
    math.floor(GREEN[1] * 255 + 0.5), math.floor(GREEN[2] * 255 + 0.5), math.floor(GREEN[3] * 255 + 0.5))
end

-- Aktif gorev acik, digerleri kapali. Aktif adim gunlukteki bir goreve ait degilse (kabul, git, ucus...)
-- ustte adim karti gosterilir. Gorevler arasi gecis oklarla (adim adim) yapilir.
local MAX_QUESTS = 6
local OBJ_BAR_W = 64   -- hedef satirinin sagindaki ilerleme cubugu

-- Hedef satiri (gorev bandinin govdesinde): metin (alan/ipucu altinda) + sayacli hedefte ince ilerleme cubugu
function Window:ObjRow(acc, i)
  acc.objRows = acc.objRows or {}
  local r = acc.objRows[i]
  if r then return r end
  r = CreateFrame("Frame", nil, acc.body)
  r.text = fstr(r, 11, C.text)
  r.text:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
  r.text:SetJustifyV("TOP")
  r.text:SetWordWrap(true)
  r.bar = CreateFrame("Frame", nil, r)
  r.bar:SetSize(OBJ_BAR_W, 6)
  r.bar:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -4)
  r.bar.bg = r.bar:CreateTexture(nil, "BACKGROUND")
  r.bar.bg:SetAllPoints(); r.bar.bg:SetColorTexture(1, 1, 1, 0.12)
  r.bar.fill = r.bar:CreateTexture(nil, "ARTWORK")
  r.bar.fill:SetTexture("Interface\\Buttons\\WHITE8x8"); r.bar.fill._skinFixed = true
  r.bar.fill:SetPoint("TOPLEFT", 1, -1); r.bar.fill:SetPoint("BOTTOMLEFT", 1, 1)
  r.bar.fill:SetWidth(1)
  acc.objRows[i] = r
  return r
end

-- Esya satiri: ikon + "Use item: [ad]" + sagda tus kutusu (QuestItem dugmesinin tusu)
function Window:ItemRow(acc)
  local r = acc.itemRow
  if r then return r end
  r = CreateFrame("Frame", nil, acc.body)
  r:SetHeight(18)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.keyBg = CreateFrame("Frame", nil, r, "BackdropTemplate")
  r.keyBg:SetSize(22, 16); r.keyBg:SetPoint("RIGHT", r, "RIGHT", 0, 0)
  Skin:ApplyBackdrop(r.keyBg, { 1, 1, 1, 0.08 }, { 1, 1, 1, 0.35 })
  r.key = fstr(r.keyBg, 10, C.text, "CENTER", "")
  r.key:SetPoint("CENTER", r.keyBg, "CENTER", 0, 0)
  r.text = fstr(r, 11, C.text)
  r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.text:SetPoint("RIGHT", r.keyBg, "LEFT", -8, 0)
  r.text:SetWordWrap(false)
  acc.itemRow = r
  return r
end

-- Odaktaki gorevin kullanilacak esyasi (QuestItem panelindeki ilk dugme): { name, icon, key } ya da nil
function Window:FocusItem()
  local QI = ns.QuestItem
  local id = QI and QI:IsEnabled() and QI.db.enabled and QI.itemId
  if not id then return nil end
  local key = QI.db.key or (P.BindingKey and P.BindingKey("CLICK ArcanisPathQuestItem:LeftButton"))
  return { name = (P.ItemName and P.ItemName(id)) or ("#" .. id), icon = (P.ItemIcon and P.ItemIcon(id)) or "Interface\\Icons\\INV_Misc_QuestionMark",
    key = key and tostring(key):gsub("SHIFT%-", "S-"):gsub("CTRL%-", "C-"):gsub("ALT%-", "A-") or nil }
end

local function yards(d)
  if not d then return nil end
  return ns.NavMath and ns.NavMath.FormatDistance and ns.NavMath.FormatDistance(d) or ("%d yd"):format(math.floor(d + 0.5))
end

-- Coklu gorev planlayici: gunlukteki tum rehber gorevleri (en fazla 6) acik akordeonlar halinde, yakindan
-- uzaga siralanir. En yakin gorev "onerilen"dir (mavi); ustteki satir sirayi ozetler. Basliga tiklamak
-- akordeonu acar/kapatir; govdedeki hedef satirina tiklamak rehberi o goreve goturur (ok oraya doner).
-- Beceri hedefi ("Raise your fishing skill to 20"): bilinen meslegin seviyesi ve hedef ya da nil.
-- Meslek adlari P.Professions'ta Ingilizce (First Aid, Fishing...); hedef metni kucuk harfle karsilastirilir.
local function skillProgress(text)
  local name, target
  if type(text) == "string" then name, target = text:match("^Raise your (.-) skill to (%d+)") end
  if not name then return nil end
  for prof, rank in pairs(P.Professions and P.Professions() or {}) do
    if prof:lower() == name:lower() then return tonumber(rank) or 0, tonumber(target) end
  end
  return 0, tonumber(target)   -- meslek henuz yok: 0/20
end
Window.SkillProgress = skillProgress

function Window:UpdateQuests(step)
  local E = ns.Engine
  local inLog = step.quest and P.IsQuestInLog(step.quest)
  local plan = E:QuestPlan(MAX_QUESTS)
  self.plan = plan
  -- onerilen: rotadaki en yakin gorev (rehber disi / erken alinmis gorev hic onerilmez)
  local rec, onRoute = nil, 0
  for _, p in ipairs(plan) do
    if not p.off then onRoute = onRoute + 1; rec = rec or p end
  end
  self.recommended = rec
  -- odak ("Simdi"): gidilen gorev listenin basinda ve acik. Aktif adimin gorevi; yoksa cok yakindaki onerilen gorev.
  local focus
  for _, p in ipairs(plan) do if not p.off and step.quest and p.quest.id == step.quest then focus = p end end
  if not focus and rec and rec.distance and rec.distance <= FOCUS_NEAR then focus = rec end
  self.focus = focus

  -- aktif adim gunlukteki bir goreve ait degilse (kabul, git, ucus...) ustte adim karti. Geri gezinirken
  -- kesin bitmis adim her zaman kartta "Completed" olarak gosterilir.
  local offCount = 0
  for _, p in ipairs(plan) do if p.off then offCount = offCount + 1 end end
  self.offCount = offCount
  local other = self:Tab() == "other"
  local done = E:IsStepDone(step)
  local showCard = (done or not inLog) and not other
  if showCard then self:PaintRow(self.card, step, E.index, true, done) else self.card:Hide() end
  self.showCard = showCard

  -- oneri satiri (tek satir, sigar): "En yakin: A - 45 yd"
  if onRoute >= 2 and not other then
    local d = yards(rec.distance)
    -- hedefi biten quest "bitti" degil, teslim edilecek: oneri bunu acikca soyler
    local fmt = rec.quest.complete and L["Nearest: turn in %s"] or L["Nearest: %s"]
    self.advice:SetText(fmt:format(rec.quest.name .. (d and ("  -  " .. d) or "")))
    self.showAdvice = true
  else
    self.advice:SetText("")
    self.showAdvice = false
  end
  -- elle geri bakis (Prev / satira tiklama): rehber oyuncuyu buradan kendiliginden almaz; bunu acikca soyle
  -- (gizli durum oyuncuya "rehber kendi kafasina gore gidiyor" gibi gorunuyordu)
  -- bitmis adima bakis (viewDone) ve ileri bakis (browsing) da: soylenmeyince oyuncu "takildim" saniyordu
  local looking = (E.manual and E.manual == E.index) or (E.viewDone and E.viewDone == E.index) or E.browsing
  local cur = looking and E:CurrentIndex()
  if cur and cur ~= E.index and not other then
    self.advice:SetText(hex(Skin.StatusColors.current) .. L["Viewing step %d. Right-click an arrow to go back to step %d."]:format(E.index, cur) .. "|r")
    self.showAdvice = true
  end
  self:UpdateBrain()
  self:UpdateTrain()
  self:UpdateCamp()
  self:UpdateClassQuests()
  self:UpdateSit()
  if other then self.showBrain = false end

  local S = Skin.StatusColors
  -- Gorev Beyni'nin "yolda yap / simdi teslim et" dedigi quest'ler listede yesil ve etiketli: ince satir gozden kacar
  local onWay = {}
  for _, s in ipairs(self.brainList or {}) do
    if s.quest and (s.kind == "objective" or s.kind == "turnin") then onWay[s.quest] = true end
  end
  -- bitmemis hedefin canavar/obje alanlari: "Alanlar: 120 yd KD x14 · 240 yd G x6" (en iyi uc alan)
  local function areaLine(qid, k, o)
    local r = ns.Areas and ns.Areas:Ranked(qid, k, o.text)
    if not (r and r[1]) then return nil end
    local parts = {}
    for n = 1, math.min(3, #r) do
      local a = r[n]
      parts[#parts + 1] = (yards(a.yards) or "?") .. (a.dir and (" " .. a.dir) or "") .. " x" .. a.n
    end
    return hex(C.textDim) .. "   " .. L["Areas: %s"]:format(table.concat(parts, "  ·  ")) .. "|r"
  end
  -- kestirme: listedeki ilk quest'in kestirme ipucu ayri satirda (kutusu kapali olsa da). Hedefe zaten
  -- yakinsan (SHORTCUT_NEAR) gosterilmez: oraya vardiysan "olmek daha hizli" artik bir sey kazandirmaz.
  self.shortcutValue = nil
  for _, p in ipairs(plan) do
    local sc = ns.Tips and ns.Tips:Shortcut(p.quest.id)
    if sc and not p.off and not (p.distance and p.distance < SHORTCUT_NEAR) then self.shortcutValue = sc break end
  end
  if other then self.shortcutValue = nil end
  -- teslime hazir quest'ler listenin altinda ve kapali gelir (yapilacak is ustte kalsin); tiklayan yine acar
  -- sira: rotadaki yapilacaklar, rotadaki teslime hazirlar, en altta rehber disi / erken alinmis gorevler
  -- odaktan sonra yakindaki (FOCUS_NEAR) rotadaki gorevler, yakindan uzaga (teslime hazir olsa da): oradayken hepsi
  local shown, near = { focus }, {}
  if other then
    -- "Other quests" sekmesi: yalniz rehber disi / erken alinmis gorevler, yakindan uzaga
    shown = {}
    for _, p in ipairs(plan) do if p.off then shown[#shown + 1] = p end end
    table.sort(shown, function(a, b) return (a.distance or 1e9) < (b.distance or 1e9) end)
  else
  for _, p in ipairs(plan) do
    if p ~= focus and not p.off and p.distance and p.distance <= FOCUS_NEAR then near[#near + 1] = p; near[p] = true end
  end
  table.sort(near, function(a, b) return a.distance < b.distance end)
  for _, p in ipairs(near) do shown[#shown + 1] = p end
  for _, p in ipairs(plan) do if p ~= focus and not near[p] and not p.off and not p.quest.complete then shown[#shown + 1] = p end end
  for _, p in ipairs(plan) do if p ~= focus and not near[p] and not p.off and p.quest.complete then shown[#shown + 1] = p end end
  end
  -- kendiliginden yalniz siradaki is acik: odak, yoksa rotadaki ilk gorev. self.open yalniz oyuncunun tiklamasi;
  -- odak yeni bir goreve gecince o gorevdeki eski secim silinir (kutusu yine acilir).
  local lead = focus
  if not lead then for _, p in ipairs(shown) do if not p.off then lead = p break end end end
  if lead and self.leadId ~= lead.quest.id then self.leadId = lead.quest.id; self.open[lead.quest.id] = nil end
  local inPlan = {}
  for i, p in ipairs(shown) do
    local q = p.quest
    inPlan[q.id] = true
    local acc = self:GetAcc(i)
    local isRec = (p == rec)
    local isCurrent = step.quest == q.id
    local wayTag = onWay[q.id] and not isCurrent
    acc.plan = p
    -- odaktaki gorev ("simdi"): metin etiketi yerine adin onunde kucuk yesil nokta (sahibin karari)
    -- bant satiri: baslik yapilacak is ("Accept 'X'", "Kill ..."), solda tur ikonu, odakta tur renginde bant
    local kind = (p.step and p.step.type) or (q.complete and "turnin") or "complete"
    local tcol = Skin.TypeColors[kind] or C.accent
    local isFocus = p == focus and not p.off
    acc.a:SetText(p.step and ns.Engine:Describe(p.step) or (q.complete and L["Turn in: %s"]:format(q.name)) or q.name)
    acc.a:SetTextColor(unpack(p.off and C.textDim or ((isFocus or wayTag) and C.text or C.textDim)))
    acc:SetIcon(TYPE_ICON[kind] or "current", p.off and C.textDim or tcol)
    acc:SetTick(isFocus and tcol or nil)
    -- govde uc parca: ust metin (durum, oyunun hedef ozeti), hedef satirlari (her biri ilerleme cubuklu, altinda
    -- alan/ipucu), alt metin (teslim, not, ipucu, sinif). bodyText: hepsi birlikte (ipucu ve testler icin).
    local have, need, pre, objs, post = 0, 0, {}, {}, {}
    -- oyunun kendi hedef metni (bitmemis quest'te): ne yapilacagini ve kime donulecegini soyler
    local summary = not q.complete and P.QuestObjectiveText and P.QuestObjectiveText(q.id)
    if summary then pre[#pre + 1] = hex(C.textDim) .. summary .. "|r" end
    -- magara: ok girise ve icerideki yol noktalarina gider (rotadaki yol), pencere bunu acikca soyler
    if p.step and p.step.cave and not q.complete then
      pre[#pre + 1] = hex(Skin.StatusColors.current) .. L["In a cave: the arrow leads you to the entrance and inside."] .. "|r"
    end
    for k, o in ipairs(q.objectives) do
      local text = o.text
      -- "Raise your fishing skill to 20": oyun sayac vermiyor; beceri seviyesi eklenir (5/20) ve basliga yansir
      local cur, target = skillProgress(text)
      local oh, on = 0, 0
      if cur and not o.finished then
        oh, on = math.min(cur, target), target
        text = text .. (" (%d/%d)"):format(cur, target)
      else
        oh, on = tonumber(o.numFulfilled) or (o.finished and 1 or 0), tonumber(o.numRequired) or 1
      end
      have, need = have + oh, need + on
      if not text or text == "" then text = ("%d/%d"):format(o.numFulfilled or 0, o.numRequired or 0) end
      local e = { text = objIcon(o) .. hex(o.finished and S.done or progressColor(o, cur, target)) .. text .. "|r",
        have = oh, need = on, done = o.finished, extra = {} }
      local area = not o.finished and areaLine(q.id, k, o)
      if area then e.extra[#e.extra + 1] = area end
      local hint = not o.finished and ns.Hints and ns.Hints:Text(q.id, "o", k)
      if hint then e.extra[#e.extra + 1] = hex(Skin.StatusColors.current) .. "   " .. hint .. "|r" end
      objs[#objs + 1] = e
    end
    if q.complete and q.npc then
      post[#post + 1] = hex(S.ready) .. L["Turn in: %s"]:format(q.npc) .. "|r"
      local th = ns.Hints and ns.Hints:Text(q.id, "t")
      if th then post[#post + 1] = hex(Skin.StatusColors.current) .. "   " .. th .. "|r" end
    end
    -- zindan gorev rehberi: gorevin aciklamasi ve actigi zindan gorevi
    local gs = p.step or (isCurrent and step) or nil
    if gs and gs.info then post[#post + 1] = hex(C.text) .. ns:LocalizedText(gs.info) .. "|r" end
    if gs and gs.unlocks and ns.DungeonGuides then
      post[#post + 1] = hex(C.accent) .. L["Unlocks: %s"]:format(ns.DungeonGuides.QuestName(gs.unlocks)) .. "|r"
    end
    -- ipucu: hedef adimin kendi notu, yoksa gorev ipucu (Data/QuestTips + kullanicinin /wf tip notlari)
    local tip = (p.step and p.step.tip and ns:LocalizedText(p.step.tip)) or (isCurrent and step.tip and ns:LocalizedText(step.tip))
      or (ns.Tips and ns.Tips:Get(q.id))
    -- kestirme ipucu ("olmek daha hizli") hedefe yakinken anlamsiz: kutuda da gosterilmez
    if tip and p.distance and p.distance < SHORTCUT_NEAR and ns.Tips and tip == ns.Tips:Shortcut(q.id) then tip = nil end
    if tip then post[#post + 1] = hex(C.textDim) .. L["Tip: %s"]:format(tip) .. "|r" end
    -- sinif quest'i: Class Codex'teki not ve odul (Data/ClassGuide)
    if q.class and q.notNeeded then
      post[#post + 1] = hex(S.pending) .. ns.Engine:NotNeededText(q.class, q.notNeeded) .. "|r"
    end
    if q.class then
      local CG = ns.ClassGuide
      if q.class.note then post[#post + 1] = hex(C.textDim) .. L["Tip: %s"]:format(CG:Text(q.class.note)) .. "|r" end
      if q.class.reward then post[#post + 1] = hex(S.ready) .. L["Reward: %s"]:format(CG:Text(q.class.reward)) .. "|r" end
    end
    -- durum satiri (govdenin ilk satiri): etiket, yolda, sayac. Mesafe bandin saginda yazar.
    local d = yards(p.distance)
    local count = q.complete and L["Ready to turn in"] or (need > 0 and ("%d/%d"):format(have, need) or "")
    local status = {}
    if p.off then
      status[#status + 1] = hex(Skin.StatusColors.current) .. (q.notNeeded and L["Not needed"] or (q.class and L["Class quest"])
        or (q.extra and L["Not in guide"]) or L["Early"]) .. "|r"
    end
    if wayTag then status[#status + 1] = hex(GREEN) .. L["On the way"] .. "|r" end
    if count ~= "" then status[#status + 1] = hex(C.text) .. count .. "|r" end
    if #status > 0 then table.insert(pre, 1, table.concat(status, hex(C.textDim) .. "  ·  |r")) end
    acc.text:SetText(table.concat(pre, "\n"))
    acc.b:SetText(d or "")
    acc.b:SetTextColor(unpack(isFocus and C.text or C.textDim))
    if p.step then
      local where = zoneName(p.step)
      local loc = where and (p.step.x and ("%s (%d, %d)"):format(where, math.floor(p.step.x * 100 + 0.5), math.floor(p.step.y * 100 + 0.5)) or where)
      if p.step.npc and not ns.Engine:Describe(p.step):find(p.step.npc, 1, true) then loc = (loc and (p.step.npc .. "  -  " .. loc)) or p.step.npc end
      local from = p.step.feeder and ns.Guides:Get(p.step.feeder)   -- besleyici adim: hangi rehberden geldigi
      if from then loc = (loc and (loc .. "  -  ") or "") .. L["From the guide %s"]:format(ns.Guides:TitleOf(from)) end
      acc.go.text:SetText(ns.Engine:Describe(p.step))
      acc.loc.text:SetText(loc or "")
      acc.hasLoc = loc ~= nil
      -- konum rengi mesafeye gore: yakin yesil, orta beyaz, uzak / bilinmiyor gri
      local dist = p.distance
      local col = (dist and dist <= 60) and GREEN or ((dist and dist <= 250) and C.text or C.textDim)
      acc.loc.icon:SetVertexColor(unpack(col))
      acc.loc.text:SetTextColor(unpack(col))
      if loc then acc.loc:Show() else acc.loc:Hide() end
      local on = (isRec or isCurrent)
      acc.go.box:SetVertexColor(unpack(on and BLUE or C.textDim))
    elseif p.target then
      -- rehber disi quest: hedefin alani ya da teslim isareti (sag tik -> ok)
      local t = p.target
      local where = zoneName({ map = t.map })
      local loc = where and ("%s (%d, %d)"):format(where, math.floor(t.x * 100 + 0.5), math.floor(t.y * 100 + 0.5))
      acc.go.text:SetText(t.label or q.name)
      acc.loc.text:SetText(loc or "")
      acc.hasLoc = loc ~= nil
      acc.loc.icon:SetVertexColor(unpack(C.textDim))
      acc.loc.text:SetTextColor(unpack(C.textDim))
      if loc then acc.loc:Show() else acc.loc:Hide() end
      acc.go.box:SetVertexColor(unpack(C.textDim))
    else
      acc.loc:Hide()
      acc.hasLoc = false
    end
    -- metin gorunen son satirin altinda: gizli konum satiri ustte bos yer birakmasin
    acc.text:ClearAllPoints()
    if acc.hasLoc then acc.text:SetPoint("TOPLEFT", acc.loc, "BOTTOMLEFT", 0, -3)
    else acc.text:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 22, -5) end
    acc.text:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
    local function height(fs, n)
      if n == 0 then return 0 end
      local h = fs:GetStringHeight()
      return (type(h) == "number" and h > 0) and h or 13 * n
    end
    local y = (acc.hasLoc and 21 or 5) + height(acc.text, #pre) + (#pre > 0 and 3 or 0)
    -- hedef satirlari: agac cizgisinin sagina, sayacli olanlarda sagda ilerleme cubugu
    local all = {}
    for _, l in ipairs(pre) do all[#all + 1] = l end
    for i, e in ipairs(objs) do
      local r = self:ObjRow(acc, i)
      local lines = { e.text }
      for _, x in ipairs(e.extra) do lines[#lines + 1] = x end
      r.text:SetText(table.concat(lines, "\n"))
      for _, l in ipairs(lines) do all[#all + 1] = l end
      local bar = e.need > 1 and not e.done
      r.bar:SetShown(bar)
      if bar then
        local f = math.max(0, math.min(1, e.have / e.need))
        r.bar.fill:SetWidth(math.max(1, (OBJ_BAR_W - 2) * f))
        local c = progressColor({ numFulfilled = e.have, numRequired = e.need })
        r.bar.fill:SetVertexColor(c[1], c[2], c[3], 0.9)
      end
      r.text:SetPoint("RIGHT", r, "RIGHT", bar and -(OBJ_BAR_W + 8) or 0, 0)
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 22, -y)
      r:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
      local h = math.max(14, height(r.text, #lines))
      r:SetHeight(h)
      r:Show()
      y = y + h + 3
    end
    for i = #objs + 1, #(acc.objRows or {}) do acc.objRows[i]:Hide() end
    -- odaktaki gorevin esyasi: "Use item: [ad]" + tus (guvenli dugme QuestItem panelinde; burada bilgi)
    local item = isFocus and self:FocusItem()
    local ir = self:ItemRow(acc)
    if item then
      ir.icon:SetTexture(item.icon)
      ir.text:SetText(L["Use item: %s"]:format("[" .. item.name .. "]"))
      ir.key:SetText(item.key or "")
      ir.keyBg:SetShown(item.key ~= nil)
      ir:ClearAllPoints()
      ir:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 22, -y)
      ir:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
      ir:Show()
      all[#all + 1] = L["Use item: %s"]:format(item.name)
      y = y + 18 + 3
    else
      ir:Hide()
    end
    acc.text2:SetText(table.concat(post, "\n"))
    acc.text2:ClearAllPoints()
    acc.text2:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 22, -y)
    acc.text2:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
    y = y + height(acc.text2, #post)
    for _, l in ipairs(post) do all[#all + 1] = l end
    acc.bodyText = table.concat(all, "\n")
    acc:SetBodyHeight(y + 7)
    acc.active = true
    acc:Show()
    local want = self.open[q.id]
    if want == nil then want = (p == lead) end
    if acc.questId ~= q.id then
      acc.questId = q.id
      acc:SetExpanded(want, true)
    elseif acc.expanded ~= want then
      acc:SetExpanded(want)
    end
  end
  for i = #shown + 1, #self.accs do
    local acc = self.accs[i]
    acc.active = false; acc.questId = nil; acc.plan = nil; acc:Hide()
  end
  for qid in pairs(self.open) do if not inPlan[qid] then self.open[qid] = nil end end
  self:UpdateZone()
end

-- Onerilen (en yakin) goreve git.
function Window:GoRecommended()
  local E = ns.Engine
  local rec = self.recommended
  -- oyuncunun secimi: katı sırada da adim bitene kadar orada kalinir (Engine.chosen)
  if rec and rec.index and E.guide then E.chosen = rec.index; E:SetGuide(E.guide.id, rec.index) return true end
  local q = E:ActiveQuest()
  if q then return E:JumpToQuest(q.id) ~= nil end
  return false
end

-- Istege bagli bolge bilgisi (ayarlar > Interface): bolgedeki otlar / madenler (toplama becerine gore) ve zindanlar.
local ZONE_SHOW = 30
function Window:UpdateZone()
  local acc = self.zoneAcc
  local zone = P.ZoneText()
  local lines = self.db.zoneInfo and zone and ns.ZoneInfo and ns.ZoneInfo:Lines(zone) or nil
  -- girişte ve yeni bölgede ZONE_SHOW sn görünür, sonra gizlenir; oyuncu açtıysa kapatana kadar kalır
  local t = P.Now()
  if zone and zone ~= self.zoneShownFor then
    self.zoneShownFor, self.zoneUntil = zone, t + ZONE_SHOW
    P.After(ZONE_SHOW + 0.5, function() ns.SafeCall(Window.Update, Window) end)
  end
  if not lines or #lines < 2 or (t > (self.zoneUntil or 0) and not (acc and acc.expanded)) then
    if acc then acc.active = false; acc:Hide() end
    return
  end
  if not acc then
    acc = Skin:CreateAccordion(self.frame, WIDTH - 2 * PAD, 24, accStyle())
    acc.onAnimate = function() Window:Layout() end
    acc.onToggle = function(x) Window.db.zoneOpen = x.expanded end
    acc.text = fstr(acc.body, 10, C.textDim)
    acc.text:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 12, -5)
    acc.text:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
    acc.text:SetJustifyV("TOP")
    acc.text:SetWordWrap(true)
    Skin:SetFont(acc.a, 11, "")
    acc:SetTick(C.textDim)
    self.zoneAcc = acc
    acc:SetExpanded(self.db.zoneOpen, true)
  end
  acc.a:SetText(lines[1])
  acc.b:SetText("")
  local body = {}
  for i = 2, #lines do body[#body + 1] = lines[i] end
  acc.text:SetText(table.concat(body, "\n"))
  local th = acc.text:GetStringHeight()
  if type(th) ~= "number" or th <= 0 then th = 12 * #body end
  acc:SetBodyHeight(th + 10)
  acc.active = true
  acc:Show()
end

-- Ogrenilecek spell varken quest'lerin altinda (bolge bilgisinin ustunde) yanip sonen bolum: "New spells to train (2)  Frang". Her oturumda ve her yeni
-- seviyede birkac saniye yanip soner, trainer ziyaret edilene kadar kalir; acilinca ok trainer'a doner.
local FLASH_TIME = 6
function Window:UpdateTrain()
  local M = ns.Mentor
  local t = M and M.IsEnabled and M:IsEnabled() and M.TrainingInfo and M:TrainingInfo()
  local acc = self.trainAcc
  if not t then
    if acc then acc.active = false; acc:Hide() end
    return
  end
  if not acc then
    acc = Skin:CreateAccordion(self.frame, WIDTH - 2 * PAD, 24, accStyle())
    acc.onAnimate = function() Window:Layout() end
    acc.onToggle = function(x) if x.expanded and ns.Mentor then ns.Mentor:PointTrainer(x.trainer) end end
    acc.text = fstr(acc.body, 10, C.text)
    acc.text:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 12, -5)
    acc.text:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
    acc.text:SetJustifyV("TOP")
    acc.text:SetWordWrap(true)
    Skin:SetFont(acc.a, 11, "")
    acc:SetExpanded(false, true)
    self.trainAcc = acc
  end
  acc.trainer = t.trainer
  acc.a:SetText(t.count and L["New spells to train (%d)"]:format(t.count) or L["New spells to train"])
  acc.b:SetText(t.trainer and t.trainer.npc or "")
  local body = { t.spells or L["Visit your class trainer at level %d."]:format(t.level) }
  if t.trainer then body[#body + 1] = hex(C.textDim) .. L["Trainer: %s, %s"]:format(t.trainer.npc, t.trainer.mapHint or t.trainer.zone) .. "|r" end
  acc.text:SetText(table.concat(body, "\n"))
  local th = acc.text:GetStringHeight()
  if type(th) ~= "number" or th <= 0 then th = 12 * #body end
  acc:SetBodyHeight(th + 10)
  acc.active = true
  acc:Show()
  -- yanip sonme: oturumda ilk kez ve her yeni seviyede
  if self.trainFlashed ~= t.level then
    self.trainFlashed = t.level
    local untilT = (GetTime and GetTime() or 0) + FLASH_TIME
    acc:SetScript("OnUpdate", function(x)
      local now = GetTime and GetTime() or untilT
      local on = now < untilT and math.floor(now * 2) % 2 == 0
      x.a:SetTextColor(unpack(on and C.accent or C.text))
      x:SetTick(on and C.accent or Skin.StatusColors.current)
      if now >= untilT then x:SetScript("OnUpdate", nil) end
    end)
  end
  acc:SetTick(Skin.StatusColors.current)
end


-- Meslek kamp quest'i hatirlatmasi: en altta kapali bolum; acilinca ok quest'i veren NPC'ye doner. Zorlamaz.
function Window:UpdateCamp()
  local list = ns.Engine:CampReminders()
  local acc = self.campAcc
  local r = list[1]
  if not r then
    if acc then acc.active = false; acc:Hide() end
    return
  end
  if not acc then
    acc = Skin:CreateAccordion(self.frame, WIDTH - 2 * PAD, 24, accStyle())
    acc.onAnimate = function() Window:Layout() end
    acc.onToggle = function(x)
      local s = x.campStep
      if x.expanded and s and ns.Nav then
        local map, px, py = ns.Zones:Location(s)
        if map then ns.Nav:SetTarget(map, px, py, ns.Engine:Describe(s), "manual") end
      end
    end
    acc.text = fstr(acc.body, 10, C.text)
    acc.text:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 12, -5)
    acc.text:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
    acc.text:SetJustifyV("TOP")
    acc.text:SetWordWrap(true)
    Skin:SetFont(acc.a, 11, "")
    acc:SetExpanded(false, true)
    self.campAcc = acc
  end
  acc.campStep = r.step
  acc.a:SetText(#list > 1 and L["Camping quests for your professions (%d)"]:format(#list) or L["Camping quest for %s"]:format(r.prof))
  acc.b:SetText(r.step.npc or "")
  local body = {}
  for _, e in ipairs(list) do body[#body + 1] = "- " .. P.QuestName(e.step.quest, e.step.name) end
  body[#body + 1] = hex(C.textDim) .. L["Optional: take it from %s when you pass by."]:format(r.step.npc or "?") .. "|r"
  acc.text:SetText(table.concat(body, "\n"))
  local th = acc.text:GetStringHeight()
  if type(th) ~= "number" or th <= 0 then th = 12 * #body end
  acc:SetBodyHeight(th + 10)
  acc.active = true
  acc:Show()
  acc:SetTick(Skin.StatusColors.current)
end

-- Yan isler basligi: ince satir (ok + "Side tasks (N)"); tiklayinca alttaki hatirlatmalar birlikte acilip kapanir
-- Alt sekmeler: "Guide" (rotadaki gorevler + adim) ve "Other quests" (rehber disi / erken alinmis gorevler; secili
-- rehberin ekranina karismasin). Rehber disi gorev yoksa cubuk gorunmez.
local TAB_H = 24
function Window:Tabs()
  local tb = self.tabBar
  if tb then return tb end
  -- Segmentli sekme (iki esit bolme): yuvarlak koseli zemin, secili bolme vurgu tonunda dolu, simge + yazi + sayi rozeti
  tb = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
  tb:SetHeight(TAB_H)
  Skin:ApplyRound(tb, { 0.04, 0.05, 0.07, 0.9 }, C.border)
  tb.tabs, tb.items = {}, { { id = "guide", icon = "guides" }, { id = "other", icon = "exclaim" } }
  local function paint(seg)
    local on, hover = seg.selected, seg.hover
    if on then
      Skin:ApplyRound(seg, C.accentSoft, C.accent)
      seg.text:SetTextColor(unpack(C.accentHover))
      seg.icon:SetVertexColor(unpack(C.accent))
    else
      Skin:ApplyRound(seg, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
      seg.text:SetTextColor(unpack(hover and C.text or C.textDim))
      seg.icon:SetVertexColor(unpack(hover and C.text or C.textDim))
    end
  end
  for i, it in ipairs(tb.items) do
    local seg = CreateFrame("Button", nil, tb, "BackdropTemplate")
    seg:SetHeight(TAB_H - 4)
    seg.icon = tex(seg, it.icon, 12, C.textDim)
    seg.text = fstr(seg, 11, C.textDim)
    seg.text:SetWordWrap(false)
    seg.text:SetPoint("CENTER", seg, "CENTER", 8, 0)
    seg.icon:SetPoint("RIGHT", seg.text, "LEFT", -4, 0)
    seg:SetScript("OnEnter", function(x) x.hover = true; paint(x) end)
    seg:SetScript("OnLeave", function(x) x.hover = false; paint(x) end)
    seg:SetScript("OnClick", function() tb:Select(it.id) end)
    seg.paint = paint
    tb.tabs[it.id] = seg
    paint(seg)
  end
  -- bolmeler cubugun genisligini esit paylasir (2 px ic bosluk)
  local function layout()
    local w = tb:GetWidth()
    if type(w) ~= "number" or w < 40 then w = 220 end
    local half = (w - 4) / 2
    tb.tabs.guide:ClearAllPoints()
    tb.tabs.guide:SetPoint("LEFT", tb, "LEFT", 2, 0)
    tb.tabs.guide:SetWidth(half)
    tb.tabs.other:ClearAllPoints()
    tb.tabs.other:SetPoint("RIGHT", tb, "RIGHT", -2, 0)
    tb.tabs.other:SetWidth(half)
  end
  tb:SetScript("OnSizeChanged", layout)
  function tb:Select(id, silent)
    self.selected = id
    for tid, seg in pairs(self.tabs) do seg.selected = tid == id; seg.paint(seg) end
    if not silent then
      Window.db.tab = id
      Window:Update()
    end
  end
  function tb:SetTexts(fn)
    for _, it in ipairs(self.items) do self.tabs[it.id].text:SetText(fn(it.id)) end
    layout()
  end
  layout()
  tb:Hide()
  self.tabBar = tb
  return tb
end

-- Bilgi cubuklari (rehber ilerleme cubugunun ustunde, ayni bicimde; her biri ayri acilip kapanir):
--   XP (Window.db.xpBar): dolan kisim seviyedeki XP, acik kisim dinlenmis XP; solda "XP %37", sagda XP/saat.
--   Altin (Window.db.goldBar): binek hedefine (Mentor.db.mountGoal) dogru biriken para; solda para / hedef, sagda
--   altin/saat. Hedef yoksa (hepsi asildi) cubuk dolu, yalniz para.
local SPARK_N, STATS_H = 20, BAR_H
local XP_COL, RESTED_COL, GOLD_COL = { 0.58, 0.42, 0.92 }, { 0.35, 0.55, 0.95 }, { 0.95, 0.75, 0.25 }
local function infoBar(parent, color)
  local s = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  s:SetHeight(STATS_H)
  Skin:ApplyBackdrop(s, { 0.10, 0.12, 0.16, 1 }, FRAME)
  s.rested = s:CreateTexture(nil, "BORDER")
  s.rested:SetColorTexture(RESTED_COL[1], RESTED_COL[2], RESTED_COL[3], 0.30)
  s.rested:SetPoint("TOPLEFT", 1, -1); s.rested:SetPoint("BOTTOMLEFT", 1, 1); s.rested:SetWidth(1)
  s.rested:Hide()
  -- teslime hazir gorevlerin XP'si: dolgunun devami, dolgudan acik ton (yalniz XP cubugunda kullanilir)
  s.quest = s:CreateTexture(nil, "BORDER", nil, 1)
  s.quest:SetColorTexture(color[1], color[2], color[3], 0.30)
  s.quest:SetPoint("TOPLEFT", 1, -1); s.quest:SetPoint("BOTTOMLEFT", 1, 1); s.quest:SetWidth(1)
  s.quest:Hide()
  s.fill = s:CreateTexture(nil, "ARTWORK")
  s.fill:SetColorTexture(color[1], color[2], color[3], 0.60)
  s.fill:SetPoint("TOPLEFT", 1, -1); s.fill:SetPoint("BOTTOMLEFT", 1, 1); s.fill:SetWidth(1)
  s.left = fstr(s, 10, C.text, "LEFT", "OUTLINE")
  s.left:SetPoint("LEFT", s, "LEFT", 6, 0)
  s.right = fstr(s, 10, C.text, "RIGHT", "OUTLINE")
  s.right:SetPoint("RIGHT", s, "RIGHT", -6, 0)
  s:Hide()
  return s
end

function Window:StatsStrip()
  if not self.xpBar then
    self.xpBar = infoBar(self.frame, XP_COL)
    self.goldBar = infoBar(self.frame, GOLD_COL)
    self.statsStrip = self.xpBar   -- eski ad
  end
  return self.xpBar, self.goldBar
end

-- Bir sonraki binek hedefi: { level, amount } ya da nil (parasi her hedefi gecmis)
function Window:GoldGoal(money)
  local goals = ns.Mentor and ns.Mentor.db and ns.Mentor.db.mountGoal or {}
  local best
  for lv, amount in pairs(goals) do
    if amount > (money or 0) and (not best or lv < best.level) then best = { level = lv, amount = amount } end
  end
  return best
end

-- Son 30 dakikanin XP'si dilimlere bolunmus (eski -> yeni); veri yoksa bos tablo
function Window:XPBuckets()
  local Lv = ns.Leveling
  local out = {}
  for i = 1, SPARK_N do out[i] = 0 end
  if not (Lv and Lv.samples) then return out end
  local now, span = P.Now(), 1800 / SPARK_N
  for _, x in ipairs(Lv.samples) do
    local k = SPARK_N - math.floor((now - x.t) / span)
    if k >= 1 and k <= SPARK_N then out[k] = out[k] + (x.gained or 0) end
  end
  return out
end

function Window:UpdateStats()
  local xb, gb = self:StatsStrip()
  local inner = WIDTH - 2 * PAD - 2
  -- XP
  local xp, mx = P.XP()
  local f = (mx and mx > 0) and math.max(0, math.min(1, xp / mx)) or 0
  xb.fill:SetWidth(math.max(1, inner * f))
  local rest = P.RestXP and P.RestXP() or 0
  local rf = (mx and mx > 0) and math.max(0, math.min(1, (xp + rest) / mx)) or 0
  xb.rested:SetWidth(math.max(1, inner * rf))
  xb.rested:SetShown(rest > 0)
  local Lv = ns.Leveling
  local ready = Lv and Lv.ReadyQuestXP and Lv:ReadyQuestXP() or 0
  local qf = (mx and mx > 0) and math.max(0, math.min(1, (xp + ready) / mx)) or 0
  xb.quest:SetWidth(math.max(1, inner * qf))
  xb.quest:SetShown(ready > 0)
  local left = (mx and mx > 0) and L["XP %d%%"]:format(math.floor(f * 100)) or ""
  if ready > 0 then left = left .. "  " .. L["+%s from quests"]:format(Lv.FormatXP(ready)) end
  xb.left:SetText(left)
  if not xb.tipHooked and xb.EnableMouse then   -- fare ustundeyken hazir gorevlerin listesi
    xb.tipHooked = true
    xb:EnableMouse(true)
    xb:SetScript("OnEnter", function(bar)
      if not (GameTooltip and ns.Leveling) then return end
      GameTooltip:SetOwner(bar, "ANCHOR_TOP")
      if ns.Leveling:ReadyTooltip(GameTooltip) then GameTooltip:Show() else GameTooltip:Hide() end
    end)
    xb:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  end
  local rate = Lv and Lv:IsEnabled() and Lv:Rate()
  xb.right:SetText(rate and L["%s xp/h"]:format(Lv.FormatXP(rate)) or "")
  -- altin
  local F = ns.Suite and ns.Suite.FormatMoney or function(c) return tostring(c) end
  local money = P.Money()
  local goal = self:GoldGoal(money)
  if goal then
    gb.fill:SetWidth(math.max(1, inner * math.max(0, math.min(1, money / goal.amount))))
    gb.left:SetText(L["%s of %s (riding at %d)"]:format(F(money), F(goal.amount), goal.level))
  else
    gb.fill:SetWidth(inner)
    gb.left:SetText(F(money))
  end
  local G = ns.Gold
  local sum = G and G:IsEnabled() and G.Summary and G:Summary()
  local gr = sum and sum.rate
  gb.right:SetText((gr and gr > 0) and L["%s per hour"]:format(F(math.floor(gr))) or "")
end

-- Rehber disi gorevler satiri: tiklayinca "Guide" ile "Other quests" gorunumu arasinda gecer (Window.db.tab)
function Window:OtherRow()
  local r = self.otherRow
  if r then return r end
  r = CreateFrame("Button", nil, self.frame)
  r:SetHeight(18)
  r.hl = r:CreateTexture(nil, "BACKGROUND")
  r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 1, 1, 0.05); r.hl:Hide()
  r.text = fstr(r, 11, C.textDim)
  r.chev = tex(r, "chevdown", 10, C.textDim)
  r:SetScript("OnEnter", function(x) x.hl:Show(); x.text:SetTextColor(unpack(C.text)) end)
  r:SetScript("OnLeave", function(x) x.hl:Hide(); x.text:SetTextColor(unpack(C.textDim)) end)
  r:SetScript("OnClick", function()
    Window.db.tab = Window:Tab() == "other" and "guide" or "other"
    Window.open = Window.open or {}
    Window:Update()
  end)
  r:Hide()
  self.otherRow = r
  return r
end

function Window:Tab()
  return (self.offCount or 0) > 0 and self.db.tab == "other" and "other" or "guide"
end

function Window:SideHead()
  local h = self.sideHead
  if h then return h end
  h = CreateFrame("Button", nil, self.frame)
  h:SetHeight(18)
  h.chev = h:CreateTexture(nil, "ARTWORK")
  h.chev:SetSize(10, 10)
  h.chev:SetPoint("LEFT", 2, 0)
  h.chev:SetTexture(Skin.Icons.chevdown)
  h.chev:SetVertexColor(unpack(C.textDim))
  h.text = fstr(h, 10, C.textDim)
  h.text:SetPoint("LEFT", h.chev, "RIGHT", 4, 0)
  h.line = h:CreateTexture(nil, "BORDER")
  Skin:Fill(h.line, C.border)
  ns.Skin:Hairline(h.line, "h")
  h.line:SetPoint("LEFT", h.text, "RIGHT", 8, 0)
  h.line:SetPoint("RIGHT", h, "RIGHT", 0, 0)
  h:SetScript("OnClick", function()
    Window.db.sideCollapsed = not Window.db.sideCollapsed
    Window:Layout()
  end)
  h:Hide()
  self.sideHead = h
  return h
end

-- Sinif quest hatirlatmasi: alinabilir sinif quest'i en altta kapali bolumde; acilinca ok quest'i veren NPC'ye.
function Window:UpdateClassQuests()
  local list = ns.Engine:ClassQuestReminders()
  local acc = self.classAcc
  local e = list[1]
  if not e then
    if acc then acc.active = false; acc:Hide() end
    return
  end
  if not acc then
    acc = Skin:CreateAccordion(self.frame, WIDTH - 2 * PAD, 24, accStyle())
    acc.onAnimate = function() Window:Layout() end
    acc.onToggle = function(x)
      local q = x.classQuest
      if x.expanded and q and q.x and ns.Nav and ns.Zones then
        local map = ns.Zones:Resolve(q.zone)
        if map then ns.Nav:SetTarget(map, q.x / 100, q.y / 100, q.giver or q.name, "manual") end
      end
    end
    acc.text = fstr(acc.body, 10, C.text)
    acc.text:SetPoint("TOPLEFT", acc.body, "TOPLEFT", 12, -5)
    acc.text:SetPoint("RIGHT", acc.body, "RIGHT", -10, 0)
    acc.text:SetJustifyV("TOP")
    acc.text:SetWordWrap(true)
    Skin:SetFont(acc.a, 11, "")
    acc:SetExpanded(false, true)
    self.classAcc = acc
  end
  acc.classQuest = e
  acc.a:SetText(L["Class quest: %s"]:format(e.name))
  acc.b:SetText(L["Level %d"]:format(e.level or 1))
  local CG = ns.ClassGuide
  local body = { ("%s  -  %s (%.1f, %.1f)"):format(e.giver or "?", e.zone or "?", e.x or 0, e.y or 0) }
  if e.reward then body[#body + 1] = hex(Skin.StatusColors.ready) .. L["Reward: %s"]:format(CG:Text(e.reward)) .. "|r" end
  if e.note then body[#body + 1] = hex(C.textDim) .. CG:Text(e.note) .. "|r" end
  if #list > 1 then body[#body + 1] = hex(C.textDim) .. L["%d more in Class Codex > Quests."]:format(#list - 1) .. "|r" end
  body[#body + 1] = hex(C.textDim) .. L["Open this to point the arrow at the quest giver."] .. "|r"
  acc.text:SetText(table.concat(body, "\n"))
  local th = acc.text:GetStringHeight()
  if type(th) ~= "number" or th <= 0 then th = 12 * #body end
  acc:SetBodyHeight(th + 10)
  acc.active = true
  acc:Show()
  acc:SetTick(Skin.StatusColors.current)
end

-- Kamp atesi: oturma dugmesi. Forever'da kamp atesinin yaninda buff gelir; buff'in islemesi icin oturmak gerekir.
-- Kamp yalniz buff'tan anlasilir (dinlenme + "han degil" tahmini hanlarda yanlis tutuyordu, 8 Kasim 2026).
-- Bilinen kamp buff'lari ID ile; bilinmeyenler icin adinda kamp atesi geceni. Yenisi /wf camp ciktisindan eklenir.
-- "Welcoming Campfire": atesin basinda 1 dk oturunca kamp faydalari gelir; buff'in kalan suresi o geri sayim
-- (oyuncu bulgusu, 8 Kasim 2026). Ikon geri sayimi gosterir, sayim bitince (faydalar alindi) kamptan cikana kadar gizlenir.
local CAMP_AURAS = { 1328375 }   -- Violet Flames: kamp atesinin yaninda (oyuncu bulgusu, 7 Kasim 2026)
local CAMP_NAMES = { "campfire", "camp fire" }

-- Kamp buff'i: { id, name, exp, dur } ya da nil. Adla bulunan once (suresi, yani geri sayimi onda).
local function campBuff()
  for _, b in ipairs(P.PlayerBuffs and P.PlayerBuffs() or {}) do
    local n = type(b.name) == "string" and b.name:lower()
    if n then
      for _, k in ipairs(CAMP_NAMES) do
        if n:find(k, 1, true) then return b end
      end
    end
  end
  for _, id in ipairs(CAMP_AURAS) do
    if P.HasPlayerAura(id) then return { id = id } end
  end
  return nil
end

-- Kamp buff'ini okur ve bitis saatini saklar (campExp): dugmenin geri sayimi her karede buff taramasin.
function Window:AtCamp()
  if P.InCombat() then return false end
  local b = campBuff()
  self.campExp = b and type(b.exp) == "number" and b.exp > 0 and type(b.dur) == "number" and b.dur > 0 and b.exp or nil
  return b ~= nil
end

-- Kamp faydalarina kalan sure (sn) ya da nil (sureli kamp buff'i yok)
function Window:CampTimer()
  local b = campBuff()
  if b and type(b.exp) == "number" and b.exp > 0 and type(b.dur) == "number" and b.dur > 0 then
    return math.max(0, b.exp - P.Now())
  end
  return nil
end

-- Teshis: kamp tespitinin neden tuttugunu/tutmadigini ve uzerindeki buff'lari yazar (/wf camp)
ns:RegisterCommand("camp", function()
  local E = ns.Engine
  local b = campBuff()
  print(("Arcanis camp: setting=%s done=%s combat=%s camp buff=%s timer=%s -> icon=%s"):format(tostring(E and E.db and E.db.campSit),
    tostring(Window.campDone), tostring(P.InCombat()), tostring(b and (b.id or b.name)), tostring(Window:CampTimer()), tostring(Window.sitShown)))
  for _, x in ipairs(P.PlayerBuffs and P.PlayerBuffs() or {}) do
    print(("  buff %s  %s"):format(tostring(x.id), tostring(x.name)))
  end
end, "Why the campfire sit button shows or not")

local function timerText(rem)
  rem = math.ceil(rem)
  if rem >= 60 then return ("%d:%02d"):format(math.floor(rem / 60), rem % 60) end
  return tostring(rem)
end

-- Kose ikonu: gorev esyasi paneli gibi pencerenin sag kenarinda kare dugme (esya paneli varsa onun altinda)
local SIT_SIZE, SIT_PAD, SIT_GRIP = 28, 4, 8   -- QuestItem paneliyle ayni olculer
function Window:UpdateSit()
  local E = ns.Engine
  local atCamp = self:AtCamp()
  if not atCamp then self.campDone = nil end   -- kamptan cikinca bir sonraki kampta yeniden gorunur
  local on = E and E.db and E.db.campSit and atCamp and not self.campDone
  self.sitShown = on and true or false
  if not self.sitButton then
    if not on then return end
    -- gorev esyasi paneliyle ayni cerceve: arka planli panel, ustte tutma payi, icinde kare dugme
    local p = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    Skin:ApplyBackdrop(p, Skin.Colors.bg, Skin.Colors.border)
    p:SetSize(SIT_SIZE + 2 * SIT_PAD, SIT_GRIP + SIT_SIZE + SIT_PAD)
    self.sitPanel = p
    local b = CreateFrame("Button", nil, p, "BackdropTemplate")
    b:SetSize(SIT_SIZE, SIT_SIZE)
    b:SetPoint("TOPLEFT", p, "TOPLEFT", SIT_PAD, -SIT_GRIP)
    Skin:ApplyBackdrop(b, Skin.Colors.button, Skin.Colors.border)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 1, -1); b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon:SetTexture("Interface\\Icons\\Spell_Fire_Fire")
    -- geri sayim: ikonun ortasinda
    b.timer = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Skin:SetFont(b.timer, 13, "OUTLINE")
    b.timer:SetPoint("CENTER", 0, 0)
    b.timer:SetTextColor(1, 1, 1)
    b:SetScript("OnClick", function() P.Sit() end)
    b:SetScript("OnEnter", function(x)
      if not GameTooltip then return end
      GameTooltip:SetOwner(x, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["Sit by the campfire"])
      GameTooltip:AddLine(L["Camp buffs work only while you sit, lie or sleep by the fire."], 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnUpdate", function(x, dt)
      -- geri sayim her karede; sayim bittiyse kamp faydalari alindi: ikon gizlenir
      -- bitis saati AtCamp'ta saklanir (UNIT_AURA + asagidaki 2 sn'lik bakis); burada yalniz saat cikarilir
      local exp = Window.campExp
      local rem = exp and math.max(0, exp - P.Now())
      if rem then
        if rem <= 0.3 then Window.campDone = true; x.timer:SetText(""); Window:UpdateSit(); return end
        x.timer:SetText(timerText(rem))
      else
        x.timer:SetText("")
      end
      -- 2 sn'de bir yeniden bak: UNIT_AURA kacarsa kamptan uzaklasinca ikon takili kalmasin
      x.acc = (x.acc or 0) + (dt or 0)
      if x.acc < 2 then return end
      x.acc = 0
      if not Window:AtCamp() then Window.lastCamp = false; Window:UpdateSit() end
    end)
    self.sitButton = b
  end
  local p = self.sitPanel
  p:ClearAllPoints()
  local QI = ns.QuestItem
  local qp = QI and QI.panel
  if qp and qp.IsShown and qp:IsShown() and QI.db and QI.db.docked ~= false then
    p:SetPoint("TOPLEFT", qp, "BOTTOMLEFT", 0, -4)
  else
    p:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, 0)
  end
  if self.sitShown then p:Show() else p:Hide() end
end

-- Gorev Beyni onerisi satiri: "> Teslim et: X - 12 yd  +1"
function Window:UpdateBrain()
  local list = (ns.Brain and ns.Brain.Get and ns.Brain:Get()) or {}
  self.brainList = list
  local first = list[1]
  -- Beyin rotaya sapma ekladiyse (rotayi duzenle modu) once onu ve nedenini goster: guven icin acik olsun
  local E = ns.Engine
  self.brainDetour = E and E.detourReason and E.pulledTo == E.index and E.detourReason or nil
  if self.brainDetour then
    self.brain.text:SetText(hex(C.accent) .. ">|r " .. hex(C.text) .. L["Detour: %s"]:format(self.brainDetour) .. "|r")
    self.showBrain = true
    return
  end
  -- Planlayici: belirgin sure kazandiran aday "Next" olarak one cikar (rehber sirasi degismez)
  local pick = ns.Planner and ns.Planner.Next and ns.Planner:Next() or nil
  self.plannerPick = pick
  if pick then
    local d = pick.item.yards and yards(pick.item.yards)
    self.brain.text:SetText(hex(C.accent) .. "»|r " .. hex(C.text) .. L["Next: %s"]:format(ns.Brain:Label(pick.item)) .. "|r"
      .. (d and ("  -  " .. d) or "") .. hex(C.textDim) .. "  (" .. L["saves %s"]:format(pick.time) .. ")|r")
    self.showBrain = true
    return
  end
  if first then
    local d = first.yards and yards(first.yards)
    local more = #list > 1 and ("  +" .. (#list - 1)) or ""
    -- isaret tema vurgu renginde (kullanici vurgu rengini degistirirse o da degisir), metin ikincil renkte
    -- rehber disi quest: isteğe bagli adim gibi kehribar "+" ile, gozden kacmasin
    local opt = first.kind == "giver"
    local mark, col = opt and "+" or ">", opt and Skin.StatusColors.current or C.text
    self.brain.text:SetText(hex(C.accent) .. mark .. "|r " .. hex(col) .. ns.Brain:Label(first) .. "|r"
      .. (d and ("  -  " .. d) or "") .. more)
    self.showBrain = true
  else
    self.brain.text:SetText("")
    self.showBrain = false
  end
end

-- Dikey yerlesim ve pencere yuksekligi (akordeon animasyonunda da cagrilir).
function Window:Layout()
  local f = self.frame
  if not f then return end
  local y = -LIST_Y + (self.topOffset or 0)   -- rehber sekmeleri gorunurken liste asagi kayar
  if self.actionMode or self.showCard then y = y + ROW_H + ROW_GAP end
  self.advice:ClearAllPoints()
  if self.showAdvice and not self.actionMode then
    self.advice:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -(y + 1))
    self.advice:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    self.advice:Show()
    y = y + 16
  else
    self.advice:Hide()
  end
  self.brain:ClearAllPoints()
  if self.showBrain and not self.actionMode then
    self.brain:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -(y + 1))
    self.brain:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    self.brain:Show()
    y = y + 16
  else
    self.brain:Hide()
  end
  self.shortcut:ClearAllPoints()
  if self.shortcutValue and not self.actionMode then
    self.shortcut:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -(y + 1))
    self.shortcut:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    self.shortcut:SetText(self.shortcutValue)
    self.shortcut:Show()
    local h = self.shortcut:GetStringHeight()
    y = y + ((type(h) == "number" and h > 0) and h or 12) + 4
  else
    self.shortcut:Hide()
  end
  local function place(acc)
    acc:ClearAllPoints()
    acc:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
    acc:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
    y = y + acc:GetCurrentHeight() + 6
  end
  for _, acc in ipairs(self.accs) do if acc.active then place(acc) end end
  -- yan isler (trainer, bolge, kamp, sinif gorevi): tek baslik altinda, birlikte acilip kapanir
  local side = {}
  local tabsOn = not self.actionMode and (self.offCount or 0) > 0
  if not self.actionMode and not (tabsOn and self:Tab() == "other") then
    for _, acc in ipairs({ self.trainAcc, self.zoneAcc, self.campAcc, self.classAcc }) do
      if acc and acc.active then side[#side + 1] = acc end
    end
  end
  local head = self:SideHead()
  self.sideCount = #side
  if #side > 0 then
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
    head:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
    local closed = self.db.sideCollapsed
    head.text:SetText(L["Side tasks (%d)"]:format(#side))
    head.chev:SetRotation(closed and math.pi / 2 or 0)
    head:Show()
    y = y + 18 + 4
    for _, acc in ipairs(side) do
      if closed then acc:Hide() else acc:Show(); place(acc) end
    end
  else
    head:Hide()
  end
  local listBottom = y - ROW_GAP
  local hintText = self.hintValue or ""
  self.hintText:SetText(hintText)
  self.hintText:ClearAllPoints()
  -- eylem modunda (bekleyenler listesi) ipucu dugmenin altina iner
  self.hintText:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(listBottom + 6 + (self.actionMode and 32 or 0)))
  local hintHeight = 0
  if hintText ~= "" then
    local h = self.hintText:GetStringHeight()
    hintHeight = ((type(h) == "number" and h) or 12) + 6
  end
  local actionHeight = self.actionMode and (24 + 8) or 0
  -- rehber disi gorevler: ilerleme cubugunun ustunde tek ince satir ("Other quests (6) >"); acikken "< Back to guide"
  -- istatistik seridi: ilerleme cubugunun hemen ustunde (rehber gorunumunde)
  local xb, gb = self:StatsStrip()
  local statsHeight = 0
  local showBars = not self.actionMode and ns.Engine.guide ~= nil
  local wantXP = showBars and self.db.xpBar ~= false
  local wantGold = showBars and self.db.goldBar ~= false
  if wantXP or wantGold then self:UpdateStats() end
  for _, pair in ipairs({ { xb, wantXP }, { gb, wantGold } }) do
    local bar, on = pair[1], pair[2]
    if on then
      bar:ClearAllPoints()
      bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD + BAR_H + 4 + statsHeight)
      bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD + BAR_H + 4 + statsHeight)
      bar:Show()
      statsHeight = statsHeight + STATS_H + 4
    else
      bar:Hide()
    end
  end
  local tb = self:OtherRow()
  if self.tabBar then self.tabBar:Hide() end
  local tabHeight = 0
  if tabsOn then
    tb:ClearAllPoints()
    tb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD + BAR_H + 4 + statsHeight)
    tb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD + BAR_H + 4 + statsHeight)
    local other = self:Tab() == "other"
    tb.text:SetText(other and L["Back to the guide"] or L["Other quests (%d)"]:format(self.offCount))
    tb.chev:SetRotation(other and -math.pi / 2 or math.pi / 2)
    tb.chev:ClearAllPoints()
    if other then tb.chev:SetPoint("LEFT", tb, "LEFT", 4, 0); tb.text:SetPoint("LEFT", tb.chev, "RIGHT", 4, 0)
    else tb.text:SetPoint("LEFT", tb, "LEFT", 8, 0); tb.chev:SetPoint("LEFT", tb.text, "RIGHT", 4, 0) end
    tb:Show()
    tabHeight = 18 + 4
  else
    tb:Hide()
  end
  f:SetHeight(listBottom + hintHeight + actionHeight + tabHeight + statsHeight + 8 + BAR_H + PAD)
  if ns.QuestItem and ns.QuestItem.Place then ns.QuestItem:Place() end
end

local WAIT_LINES = 6   -- "bekleyenler" listesinde en cok bu kadar neden satiri
local update
function Window:Update()
  local E = ns.Engine
  if E and E.Batch then return E:Batch(update, self) end   -- gunluk bir yenilemede bir kez sorulur
  return update(self)
end

function update(self)
  local f = self.frame
  if not f then return end
  if not self:IsEnabled() then f:Hide() return end
  -- rehber adadaysa pencere gizli (ucus animasyonu surerken degil)
  local docked = ns.GuideDocked and ns.GuideDocked()
  local D = ns.Island and ns.Island.Dock
  local open = docked and D and D:Expanded()
  if (self.db.hidden and not open) or (docked and not open and not self.flying) then
    f:Hide()
    -- rehber adadayken gorev esyasi paneli kalir (kucuk halde savasta esya kullanmanin tek yolu)
    if not docked and ns.QuestItem and ns.QuestItem.HidePanel then ns.QuestItem:HidePanel() end
    return
  end
  self:UpdateDockButtons(docked)
  if not f:IsShown() then
    f:Show()
    if ns.QuestItem and ns.QuestItem.Update then ns.SafeCall(ns.QuestItem.Update, ns.QuestItem) end
  end
  self:UpdateGuideTabs()
  self:UpdateNavToggles()

  local E = ns.Engine
  local guide = E.guide
  local hintText = ""
  self.offCount = 0

  if not guide then
    self.title:SetText("Arcanis Path")
    self.progress:SetText("")
    setFill(self, 0)
    local info = P.PlayerInfo()
    local _, fallback = ns.Guides:Suggest(info)
    if fallback == "open" and not ns.Guides:HasRaceStart(info) and (info.level or 1) < 10 and ns.Recorder then
      -- irkin baslangic rehberi yok (or. Skyborne): kayit oner
      local rec = ns.Recorder:IsRecording()
      self:ShowAction(L["No starting guide for your race yet."],
        rec and L["Recording..."] or L["Record my route"], function()
          if not ns.Recorder:IsRecording() then ns.Recorder:Start() end
          Window:Update()
        end)
      self.card.sub:SetText(L["Play normally; quests become a guide (/wf rec)."])
    else
      self:ShowAction(L["No active guide."], L["Suggest guide"], function()
        local suggested = ns.Guides:Suggest(P.PlayerInfo())
        if suggested then
          E:SetGuide(suggested.id)
        else
          ns:Print(L["No suitable guide for this character."])
        end
      end)
    end
  else
    local index, total = E:GetProgress()
    self.title:SetText(ns.Guides:TitleOf(guide))
    self.progress:SetText(("%d/%d"):format(index, total))
    local step = E:GetStep()
    if not step then
      setFill(self, 1)
      self.progress:SetText(("%d/%d"):format(total, total))
      -- bekleyen quest varken rehber "bitti" demez: kac quest bekliyor ve kok neden basina bir satir
      local message, earlier = L["Guide finished."], nil
      if E:IsBlocked() then
        local waits, waitSteps = E:Waiting()
        local n, lines, DG = 0, {}, ns.DungeonGuides
        for i, w in ipairs(waits) do
          n = n + #w.quests
          local text = E:WaitText(w.reason, w.ref) or ""
          if w.reason ~= "pre" then
            local q = w.root or w.quests[1]
            text = ((DG and DG.QuestName and DG.QuestName(q)) or P.QuestName(q)) .. ": " .. text
          end
          if #w.quests > 1 then text = text .. (" (%d)"):format(#w.quests) end
          if i <= WAIT_LINES then lines[#lines + 1] = text end
        end
        if #waits > WAIT_LINES then lines[#lines + 1] = L["...and %d more quests"]:format(#waits - WAIT_LINES) end
        message = L["%d quests are waiting"]:format(n)
        hintText = table.concat(lines, "\n")
        setFill(self, (total - waitSteps) / total)
        self.progress:SetText(("%d/%d"):format(total - waitSteps, total))
        earlier = E:EarlierGuide()
      end
      local nextGuide = ns.Guides:GetNext(guide, P.PlayerInfo())
      if earlier then
        -- zincirler onceki rehberde: onu acmak beklemeyi cozer
        self:ShowAction(message, L["Open: %s"]:format(ns.Guides:TitleOf(earlier)), function() E:OpenGuide(earlier.id) end)
      elseif nextGuide then
        self:ShowAction(message, L["Next: %s"]:format(ns.Guides:TitleOf(nextGuide)), function() E:SetGuide(nextGuide.id) end)
      else
        local suggested = ns.Guides:Suggest(P.PlayerInfo(), guide.id)
        if suggested then
          self:ShowAction(message, L["Next: %s"]:format(ns.Guides:TitleOf(suggested)), function() E:SetGuide(suggested.id) end)
        else
          self:ShowAction(message, L["Open guide list"], function()
            if ns.PathWindow then ns.PathWindow:OpenGuideList("leveling") end
          end)
          self.card.sub:SetText(L["No further guide for your level. Pick one from the list."])
        end
      end
    else
      setFill(self, (index - 1) / total)
      self:ShowNavigation()
      self:UpdateQuests(step)
      hintText = self:TravelHint(step) or ""
      local active = E:ActiveQuest()
      local rec = self.recommended
      self.currentButton:SetEnabled(rec ~= nil or active ~= nil)
      self.currentButton:SetActive(rec ~= nil and rec.index == E.index)
      self.flagButton:SetEnabled(ns.Zones:Location(step) ~= nil)
      self.flagButton:SetActive(ns.Zones:Location(step) ~= nil)
      if E:CanPrev() then self.prevButton:Enable() else self.prevButton:Disable() end
      if E:CanNext() then self.nextButton:Enable() else self.nextButton:Disable() end
      self.jumpButton:SetEnabled(E:CurrentIndex() ~= E.index)
      local q = step.quest
      local skipped = q and E:QuestSkipped(q) or false
      self.skipButton:SetEnabled(q ~= nil)
      self.skipButton:SetActive(skipped)
      local qn = q and (P.QuestName(q, step.name) or step.name or ("#" .. q))
      self.skipButton:SetTooltip(q and (skipped and L["Restore quest: %s"] or L["Skip this quest: %s"]):format(qn)
        or L["Skip this quest: %s"]:format("-"))
    end
  end

  self.hintValue = hintText
  self:Layout()
end

-- Yasam dongusu
function Window:Refresh()
  self:Update()
end

-- Gorev olaylari arka arkaya gelir; guncellemeyi tek karede topla.
function Window:OnQuestEvent()
  if self.pending then return end
  self.pending = true
  local function run() Window.pending = false; Window:Update() end
  if C_Timer and C_Timer.After then C_Timer.After(0.2, run) else run() end
end

function Window:OnInitialize()
  if self.db.stats == false then self.db.xpBar, self.db.goldBar, self.db.stats = false, false, nil end   -- eski tek serit ayari
  self:BuildFrame()
  self:ApplyPosition()
end

function Window:OnEnable()
  ns:Listen("ARCANIS_LOCALE_CHANGED", self, "Refresh")
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, "Refresh")
  ns:Listen("ARCANIS_TABS_CHANGED", self, "Refresh")
  ns:Listen("ARCANIS_STEP_CHANGED", self, "Refresh")
  ns:Listen("ARCANIS_GUIDE_FINISHED", self, "Refresh")
  ns:Listen("ARCANIS_GUIDE_BLOCKED", self, "Refresh")
  ns:Listen("ARCANIS_SKIN_CHANGED", self, function(w) w:ApplyAlpha(); w:Refresh() end)
  -- SKILL_LINES_CHANGED: beceri hedefli quest'lerde (Camping 101) sayac beceri artinca yenilenir
  for _, ev in ipairs({ "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "QUEST_ACCEPTED", "QUEST_REMOVED", "SKILL_LINES_CHANGED" }) do
    ns:On(ev, self, "OnQuestEvent")
  end
  -- kamp oturma dugmesi: dinlenme/savas degisince; yurumeye baslayinca yeniden gosterilebilir
  local function sit(w) if w.frame then w:UpdateSit(); w:Layout() end end
  for _, ev in ipairs({ "PLAYER_UPDATE_RESTING", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
    ns:On(ev, self, sit)
  end
  -- kamp buff'i gelince/gidince (yalniz durum degisirse yeniden dizilir)
  ns:On("UNIT_AURA", self, function(w, _, unit)
    if (unit ~= nil and unit ~= "player") or not w.frame then return end
    local on = w:AtCamp()
    if on ~= w.lastCamp then w.lastCamp = on; sit(w) end
  end, "player")
  self:Update()
end

function Window:OnDisable()
  self.frame:Hide()
end

-- Komutlar
ns:RegisterCommand("window", function(args)
  local cmd, value = (args or ""):lower():match("^(%S*)%s*(.-)$")
  local db = Window.db
  if cmd == "show" then
    db.hidden = false
  elseif cmd == "hide" then
    db.hidden = true
  elseif cmd == "toggle" or cmd == "" then
    db.hidden = not db.hidden
  elseif cmd == "dock" or cmd == "undock" then
    local D = ns.Island and ns.Island.Dock
    if D then if cmd == "dock" then D:DockWindow() else D:Undock() end end
    return
  elseif cmd == "lock" then
    db.locked = true
  elseif cmd == "unlock" then
    db.locked = false
  elseif cmd == "reset" then
    local d = Window.defaults
    db.point, db.relPoint, db.x, db.y, db.scale = d.point, d.relPoint, d.x, d.y, d.scale
    db.hidden = false
    Window:ApplyPosition()
  elseif cmd == "scale" and tonumber(value) and tonumber(value) >= 0.5 and tonumber(value) <= 3 then
    db.scale = tonumber(value)
    Window:ApplyPosition()
  else
    ns:Print(L["Usage: /wf window show | hide | toggle | dock | undock | lock | unlock | reset | scale <0.5-3>"])
    return
  end
  Window:Update()
end, "[show|hide|toggle|dock|undock|lock|unlock|reset|scale <n>] step window")

ns:RegisterCommand("nearest", function() Window:GoRecommended() end, "go to the nearest quest")
