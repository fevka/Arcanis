-- Arcanis: rehber adada / gorev modu (sahibin istegi, 13 Kasim 2026). Adim penceresinin basligindaki yukari ok
-- pencereyi adaya "yerlestirir" (Window.db.docked): pencere kuculup ustteki adaya ucar, ekrandaki ok gizlenir.
--   Kucuk hal (serit): ikinci, yuksek satirda zeminsiz buyuk donen duz ok, adim + alt satirda hedef, sagda sabit
--   genislikte mesafe ve adim numarasi (sayilar degisince satir kaymaz). Ada savasta da gorunur. Adanin altinda acik
--   pencere suruklenince rehber adadan ayrilir (Dock:TearOff).
--   Buyuk hal (sahibin karari: ayri pencere asagi inmesin, hub'in kendisi pencere olsun): adaya tikla -> ada jole
--   yayiyla buyuyerek gercek adim penceresine donusur (Island.guideOpen; pencere adanin icine oturur, kendi zemini
--   saydam, ada buyudukce belirir; sekmeler, gorev secimi, yan isler, esyalar penceredeki gibi). Adaya / seride
--   yeniden tikla ya da penceredeki yukari ok -> ada seride kuculur. Igne ya da surukleme rehberi adadan ayirir.
-- Ilk deneme (ada icinde ayri rehber sayfasi) sahibin karariyla kaldirildi: hub'da kalabalikti, kullanilmiyordu.
local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local P = ns.Provider
local L = ns.L
local Island = ns.Island

local Dock = { flyKey = {} }
Island.Dock = Dock

local STRIP_H = 34          -- seritte rehber satiri (kucuk hal)
local STRIP_TEXT_MAX = 360
local ARROW_SLOT = 30       -- ok yuvasi (px)
local DIST_W = 72           -- mesafe / adim sutunu sabit genislik ("1234 yd", "Paused")
local SIDE = 16             -- Island.lua seridin yan boslugu
local ARROW_DT, TEXT_DT = 0.05, 0.25
local FLY = 0.38            -- pencere <-> ada ucusu (sn)
local DROP_GAP = 6          -- acik pencere ile adanin alt kenari arasi
Dock.STRIP_H = STRIP_H

-- Rehber adada mi: pencere ve ada modulleri acik ve oyuncu yerlestirdi.
function ns.GuideDocked()
  local W = ns.Window
  return (W and W.db and W.db.docked and W:IsEnabled() and Island:IsEnabled()) and true or false
end
function Dock:Active() return ns.GuideDocked() end
-- Buyuk hal: hub adim penceresine donusmus (Island.guideOpen; yalniz oturumluk, giriste kucuk hal).
function Dock:Expanded() return self:Active() and Island.guideOpen or false end

local function num(v) return type(v) == "number" and v or 0 end
local function text(parent, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(fs, size, "")
  fs:SetTextColor(unpack(color or Skin.Colors.text))
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(false)
  return fs
end
local function width(fs) return num(fs:GetStringWidth()) end

-- Metinler
function Dock:CurrentStep()
  local E = ns.Engine
  return E and E.guide and E:GetStep() or nil
end
function Dock:StepText()
  local E = ns.Engine
  if not (E and E.guide) then return L["No active guide."] end
  local step = E:GetStep()
  if not step and E:IsBlocked() then
    local n = 0
    for _, w in ipairs((E:Waiting())) do n = n + #w.quests end
    return L["%d quests are waiting"]:format(n)
  end
  if not step then return L["Guide finished."] end
  local ok, t = pcall(E.Describe, E, step)
  return ok and t or ""
end
-- Adimin gorevinin ilk bitmemis hedefi; yoksa adimin bolgesi.
function Dock:SubText()
  local step = self:CurrentStep()
  if not step then return "" end
  if step.quest and P.QuestLogIndex and P.QuestLogIndex(step.quest) then
    for _, o in ipairs(P.GetObjectives(step.quest) or {}) do
      if not o.finished and type(o.text) == "string" and o.text ~= "" then return o.text end
    end
  end
  return step.zone or ""
end
function Dock:ProgressText()
  local E = ns.Engine
  if not (E and E.guide) then return "" end
  local index, total = E:GetProgress()
  return ("%d/%d"):format(math.min(index, total), total)
end
-- Mesafe: okun hesapladigi (Nav:Update) ya da konum yoksa nedeni; duraklatildiysa "Paused".
function Dock:DistText()
  local E, N = ns.Engine, ns.Nav
  if E and E.IsPaused and E:IsPaused() then return L["Paused"] end
  if not (N and N.target) then return "" end
  if N.heading then return N.distLabel or "" end
  return N.noPosText or ""
end

-- Oku cevirir: Nav'in son yonu ve rengi; yon yoksa soluk. Seritte kendi duz okumuz (Media/UI/hubarrow.tga,
-- tools/make_hub_arrow.py): siyah zeminde 3D ok sayfasindan net; okun stil ayarindan bagimsiz.
local HUB_ARROW = "Interface\\AddOns\\Arcanis\\Media\\UI\\hubarrow.tga"
function Dock:Heading(tex)
  local N = ns.Nav
  if not (N and N.db and tex) then return end
  if not tex.hubArrow then tex:SetTexture(HUB_ARROW); tex.hubArrow = true end
  if N.target and N.heading then
    tex:SetRotation(N.heading)
    local c = N.tint or { 1, 1, 1 }
    tex:SetVertexColor(c[1], c[2], c[3], 1)
    tex:SetAlpha(1)
  else
    tex:SetAlpha(0.2)
  end
end

-- ===== Kucuk hal: seritteki rehber satiri =====
function Dock:BuildStrip()
  local f = Island.frame
  if self.strip or not f then return end
  local C = Skin.Colors
  local s = CreateFrame("Frame", nil, f)
  s:SetHeight(STRIP_H)
  s:SetPoint("TOP", f.row, "BOTTOM", 0, 2)
  -- sabit yerlesim: solda ok yuvasi (zeminsiz), sagda sabit genislikte mesafe sutunu; degisen sayilar satiri oynatmaz
  s.slot = CreateFrame("Frame", nil, s)
  s.slot:SetSize(ARROW_SLOT, STRIP_H); s.slot:SetPoint("LEFT", s, "LEFT", 0, 0)
  s.arrow = s.slot:CreateTexture(nil, "OVERLAY")
  s.arrow:SetSize(28, 28); s.arrow._skinFixed = true
  s.arrow:SetPoint("CENTER", s.slot, "CENTER", 0, 0)
  s.text = text(s, 13, C.text)
  s.text:SetPoint("BOTTOMLEFT", s.slot, "RIGHT", 8, 0)
  s.sub = text(s, 10, C.textDim)
  s.sub:SetPoint("TOPLEFT", s.slot, "RIGHT", 8, -2)
  s.dist = text(s, 14, C.accentHover, "RIGHT")
  s.dist:SetPoint("BOTTOMRIGHT", s, "RIGHT", 0, 0)
  s.dist:SetWidth(DIST_W)
  s.prog = text(s, 10, C.textDim, "RIGHT")
  s.prog:SetPoint("TOPRIGHT", s, "RIGHT", 0, -2)
  s.prog:SetWidth(DIST_W)
  s.w = 0
  s:Hide()
  self.strip = s
end

-- Metinleri yazar, satirin genisligini olcer; degistiyse ada yeni boya esner.
function Dock:UpdateStrip(force)
  local s = self.strip
  if not s then return end
  local t, sub, d, pg = self:StepText(), self:SubText(), self:DistText(), self:ProgressText()
  local key = t .. "\1" .. sub .. "\1" .. d .. "\1" .. pg
  if not force and key == s.key then return end
  s.key = key
  s.text:SetWidth(0); s.sub:SetWidth(0)
  s.text:SetText(t); s.sub:SetText(sub)
  -- metin genisligi 24 px adimlarla: hedef sayaci (3/6 -> 4/6) satiri oynatmaz
  local tw = math.min(STRIP_TEXT_MAX, math.ceil(math.max(width(s.text), width(s.sub)) / 24) * 24)
  s.text:SetWidth(tw); s.sub:SetWidth(tw)
  s.dist:SetText(d); s.prog:SetText(pg)
  local w = ARROW_SLOT + 8 + tw + 16 + DIST_W
  s:SetWidth(math.max(1, w))
  if math.abs(w - (s.w or 0)) > 4 then
    s.w = w
    if Island.mode == "line" then Island:Refresh(true) end
  end
end

-- Seridin rehber satiri icin istedigi genislik (Island:LineSize).
function Dock:StripWidth()
  if not self.strip then self:BuildStrip(); self:UpdateStrip(true) end
  return (self.strip and self.strip.w or 0) + 2 * SIDE
end

function Dock:Refresh()
  if self.strip then self:UpdateStrip(true) end
end

-- Island:Update her karede cagirir.
function Dock:Tick(dt)
  local active = self:Active()
  local line = active and Island.mode == "line"
  if not line then
    if self.strip then self.strip:Hide() end
    return
  end
  if not self.strip then self:BuildStrip(); self:UpdateStrip(true) end
  local s = self.strip
  s:Show()
  s:SetAlpha(Island.frame.row.GetAlpha and Island.frame.row:GetAlpha() or 1)
  self.acc = (self.acc or 0) + dt
  self.textAcc = (self.textAcc or 0) + dt
  if self.acc >= ARROW_DT then self.acc = 0; self:Heading(s.arrow) end
  if self.textAcc >= TEXT_DT then self.textAcc = 0; self:UpdateStrip() end
end

-- ===== Buyuk hal: hub adim penceresine donusur =====
-- Pencere adanin cocugu olur, seridin altina oturur, kendi zemini ve kenari saydamlasir (adanin zemini gorunur:
-- tek yuzey). Ada pencerenin boyuna buyur (Island:HubWidth/HubHeight -> GuideSize); pencere ada buyudukce belirir.
-- Window:ApplyPosition sorar: icerideyse yeri seridin alti (kayitli konum degismez).
function Dock:Anchor(f)
  local I = Island.frame
  if not (self:Expanded() and I) then return false end
  f:ClearAllPoints()
  f:SetPoint("TOP", I, "TOP", 0, -(Island.SMALL_H or 28))
  return true
end

-- Adanin istedigi boy: pencerenin olceklenmis boyu (+ alt bosluk).
function Dock:GuideSize()
  local f = ns.Window and ns.Window.frame
  if not f then return 380, 200 end
  local s = num(f:GetScale()); if s <= 0 then s = 1 end
  return math.max(1, num(f:GetWidth()) * s), math.max(1, num(f:GetHeight()) * s + DROP_GAP)
end

-- Pencereyi adanin icine al / geri ver.
function Dock:Seat()
  local W = ns.Window
  local f, I = W and W.frame, Island.frame
  if not (f and I) then return end
  f:SetParent(I)
  f:SetFrameStrata(I:GetFrameStrata() or "HIGH")
  f:SetFrameLevel(num(I:GetFrameLevel()) + 20)
  f:SetAlpha(0)
  self.seated = true
  W:ApplyPosition()
  W:Update()
end

function Dock:Unseat()
  local W = ns.Window
  local f = W and W.frame
  self.seated = nil
  if not f then return end
  f:SetParent(UIParent)
  f:SetFrameStrata("MEDIUM")
  f:SetAlpha(1)
  W:ApplyPosition()
  W:Update()
end

-- Hub acikken her kare: pencerenin boyu degistiyse ada uyar; pencere ada buyudukce belirir.
function Dock:Follow()
  local f = ns.Window and ns.Window.frame
  if not (f and self.seated) then return end
  local w, h = self:GuideSize()
  local th = (Island.SMALL_H or 28) + h
  if math.abs(w - num(Island.tw)) > 1 or math.abs(th - num(Island.th)) > 1 then Island:Animate(w, th) end
  local grown = (num(Island.h) - (Island.SMALL_H or 28)) / math.max(1, h)
  local a = math.max(0, math.min(1, grown))
  f:SetAlpha(a * a)
end

-- Ucus: pencere bulundugu yerden (ApplyPosition: kendi yeri ya da adanin alti) ekranin ust ortasina kuculerek ve
-- solarak gider (toHub), ya da tersi. Bitince pencere yerine, olcegine ve saydamligina doner.
function Dock:Fly(toHub, done)
  local W = ns.Window
  local f = W and W.frame
  local function finish()
    if W then W.flying = nil end
    if done then done() end
  end
  if not (f and f.GetCenter and UIParent and UIParent.GetWidth) then return finish() end
  W:ApplyPosition()
  local s = f:GetScale() or 1
  local cx, cy = f:GetCenter()
  local fe = f.GetEffectiveScale and f:GetEffectiveScale() or s
  local ue = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  if not (cx and cy and fe and ue and ue > 0) then return finish() end
  local r = fe / ue                       -- pencere birimi -> UIParent birimi
  local hx, hy = cx * r, cy * r
  local tx, ty = UIParent:GetWidth() / 2, UIParent:GetHeight() - 14
  W.flying = true
  f:Show()
  local function apply(e)                 -- e: 0 = pencerenin yeri, 1 = ada (Tween zaten yumusatir)
    local k = 1 - 0.85 * e
    f:SetScale(s * k)
    f:SetAlpha(1 - 0.9 * e)
    local x, y = hx + (tx - hx) * e, hy + (ty - hy) * e
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / (r * k), y / (r * k))
  end
  apply(toHub and 0 or 1)
  Skin:Tween(self.flyKey, FLY, function(p) apply(toHub and p or 1 - p) end, function()
    W:ApplyPosition()
    if W.ApplyAlpha then W:ApplyAlpha() else f:SetAlpha(1) end
    finish()
  end)
end

-- Adaya tik (rehber adadayken): pencere adanin altina iner ya da geri katlanir.
function Dock:Toggle()
  if self:Expanded() then self:Collapse() else self:Expand() end
end

function Dock:Expand()
  local W = ns.Window
  if not (self:Active() and W and W.frame) or W.flying then return end
  Island:OpenGuide()
end

function Dock:Collapse()
  if not self:Expanded() then return end
  Island:CloseHub()
  Island:Bounce()
end

-- Pencereden adaya (baslik cubugundaki yukari ok; pencere aciksa katlar).
function Dock:DockWindow()
  local W = ns.Window
  if not (W and W.frame and Island:IsEnabled()) or W.flying then return end
  if self:Active() then return self:Collapse() end
  self:Fly(true, function()
    W.db.docked = true
    W:Update()
    if ns.Nav and ns.Nav.Update then ns.Nav:Update(true) end
    if self.strip then self:UpdateStrip(true) end
    Island:UpdateShown()
    Island:Wake()
    Island:Bounce()
    Island:Refresh(true)
  end)
end

-- Rehberi adadan ayir: pencere kendi yerine gider, ekrandaki ok geri gelir.
function Dock:Undock()
  local W = ns.Window
  if not W or W.flying then return end
  local wasOpen = self:Expanded()
  W.db.docked, W.db.hidden = false, false
  if Island.mode == "hub" then Island:CloseHub() end   -- icerdeki pencere geri verilir (Unseat)
  if self.strip then self.strip:Hide() end
  Island:UpdateShown()
  Island:Refresh(true)
  if ns.Nav and ns.Nav.Update then ns.Nav:Update(true) end
  W.flying = true
  W:Update()
  if wasOpen then W:ApplyPosition(); W.flying = nil; W:Update() else self:Fly(false) end
end

-- Hub'daki pencere surukleniyor: rehber adadan ayrilir, pencere ekranda oldugu yerde kalir (ekran konumu
-- adadan cikinca yeni olcekle UIParent'a gore yazilir, ApplyPosition onu ziplatmaz), surukleme oradan surer.
function Dock:TearOff(f)
  local W = ns.Window
  if not (W and f and self:Expanded()) or W.flying then return false end
  local es = num(f:GetEffectiveScale()); if es <= 0 then es = 1 end
  local left, top = f:GetLeft(), f:GetTop()
  local sx, sy = left and left * es, top and top * es
  W.db.docked, W.db.hidden = false, false
  Island:CloseHub()   -- Unseat: pencere UIParent'a doner
  local es2 = num(f:GetEffectiveScale()); if es2 <= 0 then es2 = 1 end
  if sx and sy then
    W.db.point, W.db.relPoint, W.db.x, W.db.y = "TOPLEFT", "BOTTOMLEFT", sx / es2, sy / es2
  end
  if self.strip then self.strip:Hide() end
  Island:UpdateShown()
  Island:Refresh(true)
  W:ApplyPosition()
  f:SetAlpha(1)
  if ns.Nav and ns.Nav.Update then ns.Nav:Update(true) end
  W:Update()
  return true
end

-- Surukle-birak: pencerenin ust kenari adaya degiyor ve yatayda adanin ustunde mi (ekran koordinati).
local DROP_REACH = 24   -- px: adanin alt kenarinin bu kadar altina birakmak da sayilir
function Dock:OverHub(f)
  local I = Island.frame
  if not (f and I and Island:IsEnabled() and I:IsShown()) then return false end
  local fe, ie = num(f:GetEffectiveScale()), num(I:GetEffectiveScale())
  if fe <= 0 then fe = 1 end
  if ie <= 0 then ie = 1 end
  local top, l, r = f:GetTop(), f:GetLeft(), f:GetRight()
  local ib, il, ir = I:GetBottom(), I:GetLeft(), I:GetRight()
  if not (top and l and r and ib and il and ir) then return false end
  return top * fe >= ib * ie - DROP_REACH and l * fe < ir * ie and r * fe > il * ie
end

-- Hub'a birakildi: rehber adaya girer ve hub pencereye donusur (kayitli konum degismez: asagi ok oraya goturur).
function Dock:DropIn()
  local W = ns.Window
  if not (W and W.frame and Island:IsEnabled()) then return false end
  W.db.docked, W.db.hidden = true, false
  if ns.Nav and ns.Nav.Update then ns.Nav:Update(true) end
  Island:UpdateShown()
  Island:Wake()
  Island:OpenGuide()
  if self.strip then self:UpdateStrip(true) end
  return true
end

ns:Listen("ARCANIS_STEP_CHANGED", Dock, function() if Dock:Active() then Dock:Refresh() end end)
ns:Listen("ARCANIS_GUIDE_CHANGED", Dock, function() if Dock:Active() then Dock:Refresh() end end)
