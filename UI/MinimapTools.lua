-- Arcanis: minimap araclari (modul "MinimapTools"). Iki anahtar, ikisi de varsayilan kapali:
--   collect: eklentilerin minimap dugmeleri (Arcanis'in kendi dugmesi de) tek "cekmece" dugmesinin arkasinda
--            toplanir; tikla -> dugmeler minimapin yaninda izgara. Blizzard'in dugmeleri (takip, saat, posta,
--            sira...) ve korumali cerceveler alinmaz. Dugme Button ve adinda "minimap" ya da "LibDBIcon" gecen.
--   square : kare minimap (maske dokusu + ince kenar); GetMinimapShape() baska eklentilere "SQUARE" der.
-- Kapatmak /reload ister (dugmeler ve yuvarlak maske oyunun kendi yerine o zaman doner): istemcinin asil maske
-- dokusu okunamiyor, eklenti dugmelerinin eski yerleri de eklentinin kendi kodunda.
local _, ns = ...

local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider

local MT = ns:NewModule("MinimapTools", {
  defaults = { collect = false, square = false, angle = 160 },
})
ns.MinimapTools = MT

function MT:On(key) return self:IsEnabled() and self.db[key] and true or false end

-- Blizzard'in minimap dugmeleri: hic toplanmaz
MT.SKIP = { QueueStatusMinimapButton = true, ExpansionLandingPageMinimapButton = true, GarrisonLandingPageMinimapButton = true,
  ArcanisMinimapDrawer = true, GameTimeFrame = true, TimeManagerClockButton = true, MiniMapTracking = true,
  MiniMapTrackingButton = true, MiniMapMailFrame = true, MiniMapBattlefieldFrame = true, MiniMapLFGFrame = true,
  MiniMapWorldMapButton = true, AddonCompartmentFrame = true }

function MT.IsAddonButton(name, objType)
  if type(name) ~= "string" or name == "" or MT.SKIP[name] or objType ~= "Button" then return false end
  local low = name:lower()
  if low:find("^minimap") then return false end   -- MinimapZoomIn, MiniMapTracking...: oyunun kendi dugmeleri
  return low:find("minimap", 1, true) ~= nil or low:find("libdbicon", 1, true) ~= nil
end

-- frames: { cerceve, ... } -> toplanacaklar (ada gore sirali, her biri bir kez)
function MT.Pick(frames)
  local out, seen = {}, {}
  for _, f in ipairs(frames) do
    local name = f.GetName and f:GetName()
    local kind = f.GetObjectType and f:GetObjectType()
    if not seen[f] and MT.IsAddonButton(name, kind) and not (f.IsProtected and f:IsProtected()) then
      seen[f] = true
      out[#out + 1] = f
    end
  end
  table.sort(out, function(a, b) return a:GetName() < b:GetName() end)
  return out
end

local function children(parent)
  local out = {}
  if parent and parent.GetChildren then for _, c in ipairs({ parent:GetChildren() }) do out[#out + 1] = c end end
  return out
end

local COLS, SIZE = 6, 34

local function inDrawer(f) return MT.panel and f:GetParent() == MT.panel and MT:On("collect") end

-- Cekmecedeki dugme hep tam gorunur. Fareyle belirenler (simge kutuphanesinin "mouseover" solmasi) cekmecede
-- solmaz; eklentisinin gizledigi dugme yer tutmaz (sahibin bulgusu, 15 Kasim 2026: bos koyu yuvalar).
function MT.Brighten(b)
  -- simge kutuphanesi fadeOut'u (animasyon) her fare giris/cikisinda cagirir: silinmez (nil hata verirdi),
  -- durdurulur ve "fareyle belir" bayragi kapatilir. Kutuphane ayarlari yenileyince bayragi geri yazar ve
  -- animasyon SetAlpha'dan gecmeden soldurur (sahibin bulgusu: arada, rastgele koyu dugmeler): Play kancasi durdurur.
  b.showOnMouseover = false
  local fade = b.fadeOut
  if fade and fade.Stop then
    fade:Stop()
    if not b.arcFadeHook and hooksecurefunc and fade.Play then
      b.arcFadeHook = true
      hooksecurefunc(fade, "Play", function(g) if inDrawer(b) then g:Stop(); b:SetAlpha(1) end end)
    end
  end
  -- baska bir eklenti (arayuz paketleri, minimap soldurucular) dugmeyi sonradan yeniden soldurabilir: cekmecedeyken
  -- her SetAlpha tam gorunurluge geri cekilir (sahibin bulgusu: dugmeler acilistan sonra da koyu kaliyordu)
  if not b.arcAlphaHook and hooksecurefunc then
    b.arcAlphaHook = true
    hooksecurefunc(b, "SetAlpha", function(f, a) if a and a < 1 and inDrawer(f) then f:SetAlpha(1) end end)
  end
  b:SetAlpha(1)
  if b.icon and b.icon.SetAlpha then b.icon:SetAlpha(1) end
  if b.icon and b.icon.SetDesaturated then b.icon:SetDesaturated(false) end
end

function MT:Scan()
  if P.InLockdown() then return end
  local list = children(Minimap)
  for _, c in ipairs(children(_G.MinimapBackdrop)) do list[#list + 1] = c end
  if self.panel then for _, c in ipairs(children(self.panel)) do list[#list + 1] = c end end
  self.buttons = MT.Pick(list)
  -- Arcanis dugmesi minimaptan alinip ekranda bir yere birakildiysa cekmeceye girmez
  local own, MB = nil, ns.MinimapButton
  if MB.db and MB.db.free then own = MB.button end
  for i = #self.buttons, 1, -1 do if self.buttons[i] == own then table.remove(self.buttons, i) end end
  local panel = self.panel
  local n = 0
  for _, b in ipairs(self.buttons) do
    if b:GetParent() ~= panel then
      b:SetParent(panel)
      if b.RegisterForDrag then b:RegisterForDrag() end   -- minimap kenarinda surukleme artik anlamsiz
    end
    MT.Brighten(b)
    -- dugmeler kendi katman / seviyelerini tasir (simge kutuphanesi MEDIUM + 8, kilitli): cekmece zemininin altinda
    -- kalip koyu gorunuyordu (/wf drawer: hepsi alpha 1). Kilitli olmayanlar panelin ustune alinir; kilitliler
    -- zaten panelin (seviye 2) ustunde.
    if b.SetFrameStrata then b:SetFrameStrata(panel:GetFrameStrata()) end
    if b.SetFrameLevel and (b:GetFrameLevel() or 0) <= (panel:GetFrameLevel() or 1) then
      b:SetFrameLevel((panel:GetFrameLevel() or 1) + 2)
    end
    b:ClearAllPoints()
    if b:IsShown() then
      n = n + 1
      b:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + ((n - 1) % COLS) * SIZE, -8 - math.floor((n - 1) / COLS) * SIZE)
    end
  end
  panel:SetSize(16 + math.max(1, math.min(n, COLS)) * SIZE, 16 + math.max(1, math.ceil(n / COLS)) * SIZE)
end


function MT:BuildDrawer()
  if self.drawer or not Minimap then return self.drawer end
  local b = CreateFrame("Button", "ArcanisMinimapDrawer", Minimap)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(9)
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnClick", function() MT:ToggleDrawer() end)
  b.arcLevel = 9
  b:SetClampedToScreen(true)
  b:SetScript("OnDragStart", function(btn) ns.MinimapButton.Drag(btn, MT.db) end)
  b:SetScript("OnDragStop", function(btn) btn:SetScript("OnUpdate", nil) end)
  b:SetScript("OnEnter", function(btn)
    if not GameTooltip then return end
    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
    GameTooltip:SetText(L["Addon buttons"])
    GameTooltip:AddLine(L["Click to show or hide them. Drag along the minimap edge, or pull it away to place it anywhere."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  -- Arcanis dugmesiyle ayni boy (30): 24 px'lik menu cizgileri cok kucuk ve silik duruyordu (sahibin bulgusu)
  Skin:MinimapDisc(b, 30, Skin.Icons.grid, 16, "accent")   -- dort karo: "eklenti dugmeleri" (tools/make_grid_icon.py)
  local panel = CreateFrame("Frame", "ArcanisMinimapDrawerPanel", UIParent, "BackdropTemplate")
  -- MEDIUM: eklentilerin kendi ipucu pencereleri (cogu HIGH / DIALOG) cekmecenin ustunde kalsin
  panel:SetFrameStrata("MEDIUM")
  -- dusuk seviye: simge kutuphanesi dugmeleri MEDIUM + 8'e KILITLER (SetFixedFrameLevel), seviyeleri
  -- degistirilemez; panel onlarin altinda kalmali yoksa zemin dugmelerin ustune cizilir (koyu dugmeler)
  panel:SetFrameLevel(2)
  panel:SetPoint("TOPRIGHT", b, "BOTTOMLEFT", 0, 0)
  panel:SetClampedToScreen(true)   -- cekmece dugmesi ekranin kenarina birakilabilir
  -- her acilista dugmeleri yeniden tam gorunur yap (asagida MT.Brighten)
  panel:SetScript("OnShow", function() for _, f in ipairs(MT.buttons or {}) do MT.Brighten(f) end end)
  Skin:ApplyBackdrop(panel, C.panel, C.border)
  panel:Hide()
  Skin:RegisterRoot(panel)
  self.drawer, self.panel = b, panel
  return b
end

-- Teshis: cekmecedeki dugmeler, gorunurluk ve saydamlik (koyu gorunen dugmenin adini bulmak icin)
ns:RegisterCommand("drawer", function()
  if not MT.buttons then ns:Print(L["The addon button drawer is empty."]) return end
  for _, b in ipairs(MT.buttons) do
    local icon = b.icon and b.icon.GetAlpha and b.icon:GetAlpha()
    ns:Print(("%s  shown=%s  alpha=%.2f  effective=%.2f%s  %s/%d (panel %s/%d)"):format(b:GetName() or "?",
      tostring(b:IsShown()), b:GetAlpha() or 0, b.GetEffectiveAlpha and b:GetEffectiveAlpha() or 0,
      icon and (" icon=%.2f"):format(icon) or "", b:GetFrameStrata() or "?", b:GetFrameLevel() or 0,
      MT.panel and MT.panel:GetFrameStrata() or "?", MT.panel and MT.panel:GetFrameLevel() or 0))
  end
end)   -- teshis komutu: yardim listesinde yok

function MT:ToggleDrawer()
  if not self.panel then return end
  if self.panel:IsShown() then self.panel:Hide(); return end
  self:Scan()   -- sonradan yuklenen eklentilerin dugmeleri de
  self.panel:Show()
end

function MT:ApplyCollect()
  if not self:On("collect") then
    if self.drawer then self.drawer:Hide(); self.panel:Hide() end
    return
  end
  if P.InLockdown() then return end   -- savas bitince (PLAYER_REGEN_ENABLED)
  local b = self:BuildDrawer()
  if not b then return end
  ns.MinimapButton.Place(b, self.db)
  b:Show()
  self:Scan()
end

-- ===== Kare minimap =====
local ROUND_PARTS = { "MinimapBorder", "MinimapCompassTexture" }

function MT:ApplySquare()
  if not (self:On("square") and Minimap and Minimap.SetMaskTexture) or self.squared then return end
  self.squared = true
  Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
  for _, n in ipairs(ROUND_PARTS) do local t = _G[n]; if t and t.Hide then t:Hide() end end
  local edge = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
  edge:SetPoint("TOPLEFT", -1, 1); edge:SetPoint("BOTTOMRIGHT", 1, -1)
  edge:EnableMouse(false)
  Skin:ApplyBackdrop(edge, { 0, 0, 0, 0 }, C.border)
  self.edge = edge
end

-- baska eklentiler (dugme kutuphaneleri) dugmeleri kenara gore dizer
if not _G.GetMinimapShape then
  function GetMinimapShape() return MT.squared and "SQUARE" or "ROUND" end
end

function MT:Set(key, v)
  local was = self.db[key]
  self.db[key] = v and true or false
  if was and not v then ns:Print(L["Type /reload to put the minimap back the way the game draws it."]) end
  self:ApplyAll()
end

function MT:ApplyAll()
  local wasSquare = self.squared
  self:ApplySquare()   -- once: dugmeler yeni kenar sekline gore dizilir
  self:ApplyCollect()
  if self.squared and not wasSquare and ns.MinimapButton.button then ns.MinimapButton:Apply() end
end

function MT:OnEnable()
  self:ApplyAll()
  P.After(5, function() if MT:On("collect") then ns.SafeCall(MT.ApplyCollect, MT) end end)   -- gec kurulan dugmeler
  ns:On("PLAYER_REGEN_ENABLED", self, function() MT:ApplyCollect() end)
end

function MT:OnDisable()
  self:ApplyCollect()
  if self.squared then ns:Print(L["Type /reload to put the minimap back the way the game draws it."]) end
end
