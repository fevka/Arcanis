-- Arcanis: minimap dugmesi (modul "MinimapButton").
--   Sol tik        adim penceresini ac/kapat
--   Sag tik        ayarlar
--   Shift + sol    zindan rehberi
--   Ctrl + sol     altin sayfasi
--   Alt + sol      ana pencere (Mentor)
-- Dugme minimap kenarinda (kare ya da yuvarlak) surukleyerek tasinir; minimaptan uzaga cekilince ekranda
-- istenen yere birakilir (db.free). Ayarlar > Interface'ten gizlenebilir.
local _, ns = ...

local L = ns.L

local MB = ns:NewModule("MinimapButton", { defaults = { hide = false, angle = 215 } })
ns.MinimapButton = MB

-- Kenar konumu: aci -> minimap merkezine gore x, y. Kare (ya da yuvarlak olmayan) minimapte dugme dikdortgenin
-- kenarinda gezer, yuvarlakta elipste. hw, hh: yari genislik / yukseklik + pay.
function MB.EdgeOffset(angle, hw, hh, shape)
  local r = math.rad(angle or 215)
  local c, s = math.cos(r), math.sin(r)
  if shape == nil or shape == "ROUND" then return c * hw, s * hh end
  local t = math.min(math.abs(c) > 1e-6 and hw / math.abs(c) or math.huge,
    math.abs(s) > 1e-6 and hh / math.abs(s) or math.huge)
  return c * t, s * t
end

MB.PAD = 5        -- dugme merkezi minimap kenarinin bu kadar disinda
MB.DETACH = 24    -- imlec minimap dikdortgeninden bu kadar disari cikinca dugme serbest kalir

-- db: { angle, free = { x, y } | nil }. Kenardayken minimapin cocugu, serbestken UIParent'in.
function MB.Place(b, db)
  b:ClearAllPoints()
  if db.free then
    if b:GetParent() ~= UIParent then b:SetParent(UIParent) end
    b:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.free.x, db.free.y)
  else
    if b:GetParent() ~= Minimap then b:SetParent(Minimap) end
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local x, y = MB.EdgeOffset(db.angle, (Minimap:GetWidth() or 140) / 2 + MB.PAD,
      (Minimap:GetHeight() or 140) / 2 + MB.PAD, shape)
    b:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end
  -- SetParent seviyeyi ebeveynden yeniden hesaplar
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(b.arcLevel or 8)
end

-- Surukleme: imlec minimapin yakinindaysa kenara oturur (aci), uzaklasinca serbest yer (UIParent koordinati).
function MB.Drag(b, db)
  b:SetScript("OnUpdate", function(btn)
    local l, r, t, bot = Minimap:GetLeft(), Minimap:GetRight(), Minimap:GetTop(), Minimap:GetBottom()
    local cx, cy = GetCursorPosition()
    local ms, us = Minimap:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not (l and r and t and bot and cx and ms and us) then return end
    local px, py = cx / ms, cy / ms
    if math.max(l - px, px - r, bot - py, py - t) <= MB.DETACH then
      db.free = nil
      db.angle = math.deg(math.atan2(py - (bot + t) / 2, px - (l + r) / 2))
    else
      db.free = { x = cx / us, y = cy / us }
    end
    MB.Place(btn, db)
  end)
end

local function openPage(id)
  if ns.PathWindow then ns.PathWindow:Open(id) end
end

function MB:OnClick(button)
  if button == "RightButton" then
    openPage("settings")
  elseif IsShiftKeyDown and IsShiftKeyDown() then
    openPage("dungeon")
  elseif IsControlKeyDown and IsControlKeyDown() then
    openPage("gold")
  elseif IsAltKeyDown and IsAltKeyDown() then
    openPage("mentor")
  else
    local W = ns.Window
    if W and W.db then
      W.db.hidden = not W.db.hidden
      if W.Update then W:Update() end
    end
  end
end

function MB:Build()
  if self.button or not Minimap then return self.button end
  local b = CreateFrame("Button", "ArcanisCoreMinimapButton", Minimap)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")

  b:SetScript("OnClick", function(_, button) ns.SafeCall(MB.OnClick, MB, button) end)
  b:SetClampedToScreen(true)
  b:SetScript("OnDragStart", function(btn) MB.Drag(btn, MB.db) end)
  b:SetScript("OnDragStop", function(btn) btn:SetScript("OnUpdate", nil) end)
  b:SetScript("OnEnter", function(btn)
    if not GameTooltip then return end
    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
    GameTooltip:SetText("Arcanis Core", 1, 0.82, 0)
    GameTooltip:AddLine(L["Left click: step window"], 1, 1, 1)
    GameTooltip:AddLine(L["Right click: settings"], 1, 1, 1)
    GameTooltip:AddLine(L["Shift + click: dungeon guide"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Ctrl + click: gold"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Alt + click: mentor"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Drag along the minimap edge, or pull it away to place it anywhere."], 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  -- renkli logo; tema rengi uygulanmaz
  ns.Skin:MinimapDisc(b, 30, "Interface\\AddOns\\Arcanis\\Media\\UI\\AddonIcon", 20)
  self.button = b
  ns.Skin:RegisterRoot(b)
  return b
end

function MB:Apply()
  local b = self:Build()
  if not b then return end
  -- cekmecedeyse (Minimap tools) yeri orasi
  local MT = ns.MinimapTools
  if not (MT and MT.panel and b:GetParent() == MT.panel) then MB.Place(b, self.db) end
  if self.db.hide or not self:IsEnabled() then b:Hide() else b:Show() end
end

function MB:OnEnable() self:Apply() end
function MB:OnDisable() if self.button then self.button:Hide() end end

ns:RegisterCommand("minimap", function()
  MB.db.hide = not MB.db.hide
  MB:Apply()
end, "show or hide the minimap button")
