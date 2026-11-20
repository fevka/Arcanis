-- Arcanis: dunya haritasinda kesfedilmemis bolgeleri gosterir (modul "MapReveal").
--
-- Oyun yalniz kesfedilmis bolge dokularini verir; geri kalanlar Data/MapOverlays.lua'dan (istemcinin kendi
-- harita tablolari) kendi katmanimizda cizilir. Blizzard'in harita pin'lerine dokunulmaz. Istege bagli renk
-- tonu kesfedilmemis yerleri ayirir.
local _, ns = ...

local P = ns.Provider

local MapReveal = ns:NewModule("MapReveal", {
  defaults = {
    tint = true,                    -- kesfedilmemis bolgeler renk tonlu
    color = { 0.55, 0.65, 0.85 },   -- ton rengi
    alpha = 1,                      -- kesfedilmemis dokularin opakligi
  },
})
ns.MapReveal = MapReveal

local TILE = 256

-- Bir overlay'in 256 px karolari: { x, y, w, h, fileDataID, u, v } (u/v: dokunun kullanilan kismi).
function MapReveal.Tiles(o)
  local w, h, ox, oy = o[1], o[2], o[3], o[4]
  local cols, rows = math.ceil(w / TILE), math.ceil(h / TILE)
  local out = {}
  for r = 1, rows do
    local th = (r < rows) and TILE or ((h % TILE == 0) and TILE or h % TILE)
    local fh = TILE
    if r == rows and th < TILE then fh = 16; while fh < th do fh = fh * 2 end end
    for c = 1, cols do
      local tw = (c < cols) and TILE or ((w % TILE == 0) and TILE or w % TILE)
      local fw = TILE
      if c == cols and tw < TILE then fw = 16; while fw < tw do fw = fw * 2 end end
      local fdid = o[4 + (r - 1) * cols + c]
      if fdid then
        out[#out + 1] = { ox + TILE * (c - 1), oy + TILE * (r - 1), tw, th, fdid, tw / fw, th / fh }
      end
    end
  end
  return out
end

-- Haritanin kesfedilmemis overlay'leri.
function MapReveal.Unexplored(map)
  local list = ns.MapOverlays and ns.MapOverlays[map]
  if not list then return {} end
  local explored = P.ExploredOverlayKeys(map)
  local out = {}
  for _, o in ipairs(list) do
    if not (explored[o[5]] or explored[o[3] .. ":" .. o[4]]) then out[#out + 1] = o end
  end
  return out
end

function MapReveal:EnsureLayer()
  if self.holder then return true end
  local frame = WorldMapFrame
  if not (frame and frame.GetCanvas) then return false end
  local canvas = frame:GetCanvas()
  if not canvas then return false end
  local holder = CreateFrame("Frame", "ArcanisMapReveal", canvas)
  holder:SetAllPoints(canvas)
  if holder.SetFrameLevel and canvas.GetFrameLevel then holder:SetFrameLevel((canvas:GetFrameLevel() or 1) + 1) end
  self.holder, self.canvas, self.textures = holder, canvas, {}
  return true
end

-- Blizzard'in kesfedilmis doku katmaniyla ayni seviye: ustteki pin'ler (gorev, ucus noktasi) ortulmez.
function MapReveal:MatchExplorationLevel()
  local frame = WorldMapFrame
  if not (frame.EnumeratePinsByTemplate and self.holder.SetFrameLevel) then return end
  local ok, iter = pcall(frame.EnumeratePinsByTemplate, frame, "MapExplorationPinTemplate")
  if not (ok and iter) then return end
  for pin in iter do
    if pin.GetFrameLevel then self.holder:SetFrameLevel(math.max(1, pin:GetFrameLevel() or 1)) end
    return
  end
end

function MapReveal:HideAll()
  if not self.textures then return end
  for _, t in ipairs(self.textures) do t:Hide() end
end

function MapReveal:Refresh()
  if not self:EnsureLayer() then return end
  self:HideAll()
  local frame = WorldMapFrame
  if not (self.enabled and frame.IsShown and frame:IsShown()) then self.holder:Hide() return end
  local map = frame.GetMapID and frame:GetMapID()
  if not map then self.holder:Hide() return end
  self:MatchExplorationLevel()
  self.holder:Show()
  local db = self.db
  local r, g, b = 1, 1, 1
  if db.tint and db.color then r, g, b = db.color[1], db.color[2], db.color[3] end
  local n = 0
  for _, o in ipairs(MapReveal.Unexplored(map)) do
    for _, t in ipairs(MapReveal.Tiles(o)) do
      n = n + 1
      local tex = self.textures[n]
      if not tex then
        tex = self.holder:CreateTexture(nil, "ARTWORK")
        self.textures[n] = tex
      end
      tex:ClearAllPoints()
      tex:SetPoint("TOPLEFT", self.holder, "TOPLEFT", t[1], -t[2])
      tex:SetSize(t[3], t[4])
      tex:SetTexture(t[5], nil, nil, "TRILINEAR")
      tex:SetTexCoord(0, t[6], 0, t[7])
      tex:SetVertexColor(r, g, b, db.alpha or 1)
      tex:Show()
    end
  end
  self.shown = n
end

-- Harita acilinca ve harita degisince yeniden cizilir (yalniz sonradan cagrilan kancalar).
function MapReveal:Hook()
  if self.hooked or not WorldMapFrame then return end
  self.hooked = true
  if WorldMapFrame.HookScript then WorldMapFrame:HookScript("OnShow", function() MapReveal:Refresh() end) end
  if hooksecurefunc and WorldMapFrame.OnMapChanged then
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function() MapReveal:Refresh() end)
  end
end

function MapReveal:OnEnable()
  self:Hook()
  ns:On("MAP_EXPLORATION_UPDATED", self, function() MapReveal:Refresh() end)
  -- dunya haritasi sonradan yuklenen bir Blizzard eklentisi olabilir
  ns:On("ADDON_LOADED", self, function(_, _, name)
    if name == "Blizzard_WorldMap" then MapReveal:Hook(); MapReveal:Refresh() end
  end)
  self:Refresh()
end

function MapReveal:OnDisable()
  self:HideAll()
  if self.holder then self.holder:Hide() end
end
