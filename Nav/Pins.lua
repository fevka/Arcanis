-- Arcanis: harita isaretcileri (modul "Pins").
--
-- Aktif hedefi (Nav hedefi) minimap'te ve dunya haritasinda isaretler; oyuncudan hedefe giden
-- noktali bir iz cizer. Adimda `path` (yol noktalari) varsa iz bu noktalardan gecer, yoksa duz cizgidir.
-- Iz yol bulma yapmaz: zor ulasilan yerlerde rehber `path` ve `tip` alanlariyla yol tarif eder.
local _, ns = ...

local P = ns.Provider
local L = ns.L
local M = ns.NavMath
local C = ns.Skin.Colors

local Pins = ns:NewModule("Pins", {
  defaults = {
    minimap = true, worldmap = true, trail = true,
    trailColor = nil,       -- nil: tema vurgu rengi
    dotSize = 5,            -- nokta boyutu (piksel)
    spacing = 12,           -- noktalar arasi (piksel)
    fade = true,            -- iz hedefe dogru belirginlesir
  },
})
ns.Pins = Pins

local WHITE = "Interface\\Buttons\\WHITE8X8"
local MINI_UPDATE = 0.1      -- s
local WORLD_UPDATE = 0.25    -- s
local MAX_DOTS = 40
local DISC = "Interface\\AddOns\\Arcanis\\Media\\UI\\disc.tga"

local function trailColor()
  local c = Pins.db and Pins.db.trailColor
  if c then return c[1], c[2], c[3] end
  return C.accent[1], C.accent[2], C.accent[3]
end

-- Katman: bir cerceve uzerinde tek isaretci + nokta havuzu
local Layer = {}
Layer.__index = Layer

local function newLayer(parent, point, dotSize, pinSize)
  local l = setmetatable({ parent = parent, point = point, dots = {}, used = 0, dotSize = dotSize }, Layer)
  l.pinShadow = parent:CreateTexture(nil, "OVERLAY")
  l.pinShadow:SetTexture(WHITE)
  l.pinShadow:SetVertexColor(0, 0, 0, 0.85)
  l.pinShadow:SetSize(pinSize + 4, pinSize + 4)
  l.pinShadow:SetRotation(math.pi / 4)
  l.pin = parent:CreateTexture(nil, "OVERLAY")
  l.pin:SetTexture(WHITE)
  l.pin:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
  l.pin:SetSize(pinSize, pinSize)
  l.pin:SetRotation(math.pi / 4)
  l:HideAll()
  return l
end

function Layer:HideAll()
  self.pin:Hide()
  self.pinShadow:Hide()
  for i = 1, #self.dots do self.dots[i]:Hide(); if self.dots[i].shadow then self.dots[i].shadow:Hide() end end
  self.used = 0
end

function Layer:SetPin(x, y, alpha)
  for _, t in ipairs({ self.pinShadow, self.pin }) do
    t:ClearAllPoints()
    t:SetPoint("CENTER", self.parent, self.point, x, y)
    t:SetAlpha(alpha or 1)
    t:Show()
  end
end

function Layer:SetDotSize(size)
  self.dotSize = size
end

-- Yuvarlak nokta + koyu kenar (her zeminde okunur). t: 0 (oyuncu) .. 1 (hedef); fade acikken
-- iz hedefe dogru belirginlesir ve hafifce buyur ("karinca yolu").
function Layer:AddDot(x, y, t)
  local i = self.used + 1
  local d = self.dots[i]
  if not d then
    d = self.parent:CreateTexture(nil, "ARTWORK", nil, 2)
    d:SetTexture(DISC)
    d.shadow = self.parent:CreateTexture(nil, "ARTWORK", nil, 1)
    d.shadow:SetTexture(DISC)
    d.shadow:SetVertexColor(0, 0, 0, 0.75)
    self.dots[i] = d
  end
  local fade = Pins.db.fade ~= false
  t = t or 1
  local size = self.dotSize * (fade and (0.75 + 0.35 * t) or 1)
  local r, g, b = trailColor()
  d:SetVertexColor(r, g, b, fade and (0.45 + 0.55 * t) or 0.95)
  d:SetSize(size, size)
  d:ClearAllPoints()
  d:SetPoint("CENTER", self.parent, self.point, x, y)
  d:Show()
  d.shadow:SetSize(size + 2, size + 2)
  d.shadow:SetAlpha(fade and (0.4 + 0.4 * t) or 0.75)
  d.shadow:ClearAllPoints()
  d.shadow:SetPoint("CENTER", d, "CENTER", 0, 0)
  d.shadow:Show()
  self.used = i
end

function Layer:Finish()
  for i = self.used + 1, #self.dots do self.dots[i]:Hide(); self.dots[i].shadow:Hide() end
  local r, g, b = trailColor()
  self.pin:SetVertexColor(r, g, b, 1)
end

-- Iz noktalari

-- Hedefe giden yol noktalarindan oyuncuya en yakin olandan itibaren olanlari dondurur
-- (gecilmis noktalar atlanir). vecs: { {east, south, dist}, ... } sirali.
local function remainingPath(vecs)
  if #vecs == 0 then return vecs end
  local best, bestDist = 1, vecs[1][3]
  for i = 2, #vecs do
    if vecs[i][3] < bestDist then best, bestDist = i, vecs[i][3] end
  end
  local out = {}
  for i = best, #vecs do out[#out + 1] = vecs[i] end
  return out
end
Pins._remainingPath = remainingPath

-- Minimap
function Pins:UpdateMinimap(t)
  if not self:EnsureMiniLayer() then return end
  local layer = self.mini
  if not (self.db.minimap and t and t.map) then layer:HideAll() return end
  local radiusYards, rotate = P.MinimapInfo()
  if not radiusYards then layer:HideAll() return end
  local dist, east, south = P.VectorTo(t.map, t.x, t.y)
  if not dist then layer:HideAll() return end

  local radiusPx = ((Minimap and Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2
  local facing = P.Facing()
  layer.used = 0

  local pts = { { 0, 0 } }
  if self.db.trail and t.path then
    -- ok yolun nereden basladigini biliyorsa (Nav.PathStart) ayni nokta; oyuncu konumu bir kez okunur
    local vecs = P.VectorsTo(t.map, t.path, t.pathAt or 1)
    for _, v in ipairs(t.pathAt and vecs or remainingPath(vecs)) do pts[#pts + 1] = { v[1], v[2] } end
  end
  pts[#pts + 1] = { east, south }

  local px, py, inside = M.MinimapOffset(east, south, facing, rotate, radiusYards, radiusPx)
  if inside then
    layer:SetPin(px, py, 1)
  else
    local len = math.sqrt(px * px + py * py)
    local k = (radiusPx - 4) / len
    layer:SetPin(px * k, py * k, 0.75)
  end

  if self.db.trail then
    local yardsPerPx = radiusYards / radiusPx
    layer:SetDotSize(self.db.dotSize or 5)
    local samples = M.Resample(pts, (self.db.spacing or 12) * yardsPerPx, MAX_DOTS)
    for i, pt in ipairs(samples) do
      local x, y, ok = M.MinimapOffset(pt[1], pt[2], facing, rotate, radiusYards, radiusPx)
      if ok and ((x - px) ^ 2 + (y - py) ^ 2) > 7 * 7 then layer:AddDot(x, y, i / #samples) end
    end
  end
  layer:Finish()
end

-- Dunya haritasi
function Pins:EnsureWorldLayer()
  if self.world then return true end
  local frame = WorldMapFrame
  if not (frame and frame.GetCanvas) then return false end
  local canvas = frame:GetCanvas()
  if not canvas then return false end
  local holder = CreateFrame("Frame", "ArcanisWorldMapPins", canvas)
  holder:SetAllPoints(canvas)
  if holder.SetFrameLevel and canvas.GetFrameLevel then holder:SetFrameLevel((canvas:GetFrameLevel() or 1) + 30) end
  self.worldHolder = holder
  self.world = newLayer(holder, "TOPLEFT", 4, 10)
  -- isaretin ustunde tiklanabilir alan: sag tik elle konulan hedefi kaldirir (yoksa tik haritayi ust haritaya cikarir)
  local hit = CreateFrame("Button", nil, holder)
  hit:SetSize(18, 18)
  hit:RegisterForClicks("RightButtonUp")
  hit:SetScript("OnClick", function() if ns.Nav and ns.Nav.DropTarget then ns.Nav:DropTarget() end end)
  hit:SetScript("OnEnter", function(b)
    GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Right-click: remove this marker"], 1, 1, 1)
    GameTooltip:Show()
  end)
  hit:SetScript("OnLeave", function() GameTooltip:Hide() end)
  hit:Hide()
  self.worldHit = hit
  return true
end

-- Haritanin kendi katmanlari (kesfedilmis bolge dokulari, pin'ler) tuvalde yuksek frame level'larda; onlarin
-- altinda kalan nokta ve iz gorunmez. Saniyede bir en yuksek cocugun ustune cikilir (pin'ler sonradan eklenir).
function Pins:RaiseWorldLayer(canvas)
  local now = P.Now()
  if self.raisedAt and now - self.raisedAt < 1 then return end
  self.raisedAt = now
  local holder = self.worldHolder
  if not (holder and canvas and canvas.GetChildren and holder.SetFrameLevel) then return end
  -- harita isaretlerimiz (MapMarkers) ok isaretinin ve izin USTUNDE kalir: oyuncu tikladigi ikonu gormeli
  local markers = _G.ArcanisMapMarkers
  local top = 0
  for _, child in ipairs({ canvas:GetChildren() }) do
    if child ~= holder and child ~= markers and child.GetFrameLevel then top = math.max(top, child:GetFrameLevel() or 0) end
  end
  if top >= (holder:GetFrameLevel() or 0) then holder:SetFrameLevel(math.min(top + 10, 8990)) end
  local mine = holder:GetFrameLevel() or 0
  if markers and markers.GetFrameLevel and markers.SetFrameLevel and (markers:GetFrameLevel() or 0) <= mine then
    markers:SetFrameLevel(mine + 5)
  end
end

function Pins:UpdateWorldMap(t)
  if not self:EnsureWorldLayer() then return end
  local layer = self.world
  self.worldHit:Hide()
  local frame = WorldMapFrame
  if not (self.db.worldmap and t and t.map and frame.IsShown and frame:IsShown()) then layer:HideAll() return end

  local display = frame.GetMapID and frame:GetMapID()
  local canvas = frame:GetCanvas()
  self:RaiseWorldLayer(canvas)
  local w, h = canvas:GetWidth(), canvas:GetHeight()
  if not (display and w and h and w > 0 and h > 0) then layer:HideAll() return end

  -- hedef acik haritanin disinda olabilir (baska bolgedeki zindan): iz yine cizilir, haritanin icinde kalan kismi
  -- gorunur; isaretci yalniz hedef haritadaysa
  local tx, ty = P.MapPosOn(t.map, t.x, t.y, display)
  if not (tx and ty) then layer:HideAll() return end
  local inside = tx >= 0 and tx <= 1 and ty >= 0 and ty <= 1
  local function onMap(x, y) return x >= 0 and x <= w and y >= 0 and y <= h end

  -- Kanvas olcegi: nokta boyutlari ekranda sabit kalsin.
  local scale = 1
  if canvas.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
    local c, u = canvas:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if c and u and c > 0 then scale = c / u end
  end
  layer:SetDotSize((self.db.dotSize or 5) / scale)
  layer.used = 0
  -- ok bir harita isaretimizden kurulduysa o isaret parlar (MapMarkers); ustune ikinci isaretci cizilmez
  local MMk = ns.MapMarkers
  local marked = MMk and MMk.IsEnabled and MMk:IsEnabled() and MMk.ActiveTarget and MMk:ActiveTarget()
  if inside and not marked then layer:SetPin(tx * w, -ty * h, 1) else layer.pin:Hide(); layer.pinShadow:Hide() end
  if inside and not marked and t.source ~= "guide" then
    local hit = self.worldHit
    hit:SetSize(18 / scale, 18 / scale)
    hit:ClearAllPoints()
    hit:SetPoint("CENTER", self.worldHolder, "TOPLEFT", tx * w, -ty * h)
    hit:Show()
  end

  if self.db.trail then
    local pts = {}
    local ux, uy = P.PlayerPosOn(display)
    if ux then
      pts[#pts + 1] = { ux * w, uy * h }
      if t.path then
        -- yol noktalari: oyuncuya en yakin olandan itibaren
        local cand = {}
        for i = t.pathAt or 1, #t.path do
          local pt = t.path[i]
          local x, y = P.MapPosOn(t.map, pt[1], pt[2], display)
          if x then cand[#cand + 1] = { x * w, y * h, math.sqrt((x * w - pts[1][1]) ^ 2 + (y * h - pts[1][2]) ^ 2) } end
        end
        for _, v in ipairs(t.pathAt and cand or remainingPath(cand)) do pts[#pts + 1] = { v[1], v[2] } end
      end
      pts[#pts + 1] = { tx * w, ty * h }
      -- hedef haritanin disindaysa iz uzar: gorunen kisim seyrek kalmasin diye ust sinir yuksek
      local samples = M.Resample(pts, ((self.db.spacing or 12) + 4) / scale, inside and MAX_DOTS * 2 or MAX_DOTS * 8)
      for i, pt in ipairs(samples) do
        if onMap(pt[1], pt[2]) and ((pt[1] - tx * w) ^ 2 + (pt[2] - ty * h) ^ 2) > (8 / scale) ^ 2 then
          layer:AddDot(pt[1], -pt[2], i / #samples)
        end
      end
    end
  end
  layer:Finish()
end

-- Guncelleme dongusu
function Pins:Refresh()
  local t = ns.Nav and ns.Nav:GetTarget()
  self:UpdateMinimap(t)
  self:UpdateWorldMap(t)
end

function Pins:OnTargetChanged()
  self:Refresh()
end

function Pins:EnsureMiniLayer()
  if self.mini then return true end
  if not Minimap then return false end
  local holder = CreateFrame("Frame", "ArcanisMinimapPins", Minimap)
  holder:SetAllPoints(Minimap)
  if holder.SetFrameLevel and Minimap.GetFrameLevel then holder:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5) end
  self.miniHolder = holder
  self.mini = newLayer(holder, "CENTER", 3, 8)
  return true
end

function Pins:OnInitialize()
  self.driver = CreateFrame("Frame")
  self.miniAcc, self.worldAcc = 0, 0
end

function Pins:OnEnable()
  ns:Listen("ARCANIS_TARGET_CHANGED", self, "OnTargetChanged")
  self.driver:SetScript("OnUpdate", function(_, elapsed)
    Pins.miniAcc = Pins.miniAcc + elapsed
    Pins.worldAcc = Pins.worldAcc + elapsed
    local t = ns.Nav and ns.Nav:GetTarget()
    if not t then return end
    if Pins.miniAcc >= MINI_UPDATE then
      Pins.miniAcc = 0
      Pins:UpdateMinimap(t)
    end
    if Pins.worldAcc >= WORLD_UPDATE then
      Pins.worldAcc = 0
      Pins:UpdateWorldMap(t)
    end
  end)
  self:Refresh()
end

function Pins:OnDisable()
  self.driver:SetScript("OnUpdate", nil)
  if self.mini then self.mini:HideAll() end
  if self.world then self.world:HideAll() end
end

-- Komut
local FLAGS = { minimap = true, worldmap = true, trail = true }

ns:RegisterCommand("pins", function(args)
  local what, state = (args or ""):lower():match("^(%S*)%s*(%S*)$")
  if FLAGS[what] then
    if state == "on" then Pins.db[what] = true
    elseif state == "off" then Pins.db[what] = false
    else Pins.db[what] = not Pins.db[what] end
    Pins:Refresh()
  end
  local function word(v) return v and L["on"] or L["off"] end
  ns:Print(L["Pins - minimap: %s, world map: %s, trail: %s"]:format(
    word(Pins.db.minimap), word(Pins.db.worldmap), word(Pins.db.trail)))
end, "[minimap|worldmap|trail] [on|off] map pins and trail")
