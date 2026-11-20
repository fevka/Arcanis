-- Arcanis: ilk acilis kurulumu (sahibin istegi, 13 Kasim 2026). Yeni kurulumda (ns.db.onboarded == nil) bir kez
-- acilir: oyuncu ne istedigini isaretler (bolumler), isaretlenmeyen bolumlerin modulleri kapali baslar. Rehber
-- cekirdegi (adim penceresi, ok, harita pinleri, rehber listesi) hep acik. Sonra Ayarlar > General "Run the setup
-- again" ya da /wf setup ile yeniden acilir. Savasta acilmaz (savas bitince acilir).
local _, ns = ...

local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack

local Setup = {}
ns.Setup = Setup

-- Hep acik: rehberin calismasi icin gereken cekirdek
Setup.CORE = { "Window", "Nav", "Pins", "GuideBrowser", "Engine", "QuestItem", "ItemNeeds", "Travel", "Transport", "Leveling" }

-- Secilebilen bolumler: { id, baslik(), aciklama(), moduller, varsayilan } (metinler islevle: dil denetimi gorsun)
Setup.GROUPS = {
  { id = "auto", title = function() return L["Quest automation"] end, desc = function() return L["Accepts and turns in your guide's quests and suggests nearby quests to do together."] end,
    modules = { "QuestAuto", "Brain" }, on = true },
  { id = "maps", title = function() return L["Maps"] end, desc = function() return L["Dungeon entrances, trainers, flight masters, rares and your farm spots on the maps; unexplored areas revealed."] end,
    modules = { "MapMarkers", "MapReveal", "Rares" }, on = true },
  { id = "dungeons", title = function() return L["Dungeons"] end, desc = function() return L["Dungeon journal: loot, quests, entrances and a quest guide for every dungeon."] end,
    modules = { "Journal" }, on = true },
  { id = "profs", title = function() return L["Professions and farming"] end, desc = function() return L["Profession guides, skill-ups, the farm compass and gold per hour while gathering."] end,
    modules = { "ProfActivity", "Farm", "ZoneInfo", "Recipes" }, on = false },
  { id = "gold", title = function() return L["Gold and auction house"] end, desc = function() return L["Gold tracker, auction prices and scan, auction house panel, selling junk and repairs."] end,
    modules = { "Gold", "Prices", "AuctionPanel", "Vendor", "Bags" }, on = false },
  { id = "class", title = function() return L["Class help"] end, desc = function() return L["Class codex (stats, talents, trainers, class quests, macros), talent tips and key bindings."] end,
    modules = { "Codex", "Build", "Keys", "TalentPlanner" }, on = true },
  { id = "rotation", title = function() return L["Rotation helper"] end, desc = function() return L["Shows your next spell and lights it on the action bar."] end,
    modules = { "Rotation" }, on = false },
  { id = "hub", title = function() return L["Dynamic Hub and alerts"] end, desc = function() return L["The strip at the top of the screen with notices, cards, alerts and whispers as conversations."] end,
    modules = { "Island", "Alerts", "Messenger", "Discover" }, on = true },
  { id = "mentor", title = function() return L["Mentor"] end, desc = function() return L["Advice on what to do next: training, bags, gear, good items for your level."] end,
    modules = { "Mentor", "LibraryBooks" }, on = true },
}

-- Secime gore modulleri acar / kapatir: cekirdek ve secilen bolumler acik, secilmeyen bolumler kapali; hicbir
-- bolumde olmayan moduller (gelistirici araclari) dokunulmaz. picks = { [bolum id] = true/false }
function Setup:Apply(picks)
  local want = {}
  for _, g in ipairs(self.GROUPS) do
    for _, m in ipairs(g.modules) do want[m] = want[m] or (picks[g.id] and true or false) end
  end
  for _, m in ipairs(self.CORE) do want[m] = true end
  local S = ns.Settings
  if S then S.applyingPreset = true end   -- Discover: kurulumun kapattigi modul "oyuncu kapatti" sayilmaz
  for name, on in pairs(want) do
    local mod = ns:GetModule(name)
    if mod and mod:IsEnabled() ~= on then
      mod:SetEnabled(on)
      local f = S and S.Feature and S.Feature(name)
      if f and f.onSwitch then ns.SafeCall(f.onSwitch, on) end
    end
  end
  if S then S.applyingPreset = nil end
  ns.db.onboarded = true
  ns.db.setupPicks = picks
  ns:Send("ARCANIS_PRESET_APPLIED", "setup")
  if ns.PathWindow and ns.PathWindow.LayoutNav then ns.SafeCall(ns.PathWindow.LayoutNav, ns.PathWindow) end
end

local function fstr(parent, size, color)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f, size, "")
  f:SetTextColor(unpack(color or C.text))
  f:SetJustifyH("LEFT")
  return f
end

local ROW_H = 46

function Setup:Build()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "ArcanisSetup", UIParent, "BackdropTemplate")
  f:SetSize(560, 120 + #self.GROUPS * ROW_H + 56)
  f:SetPoint("CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG")   -- ana pencere (DIALOG) tiklaninca one gelse de ustte kalsin
  f:SetToplevel(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  Skin:ApplyBackdrop(f, C.panel, C.border)
  if Skin.RegisterRoot then Skin:RegisterRoot(f) end
  f.title = fstr(f, 18, C.accentHover)
  f.title:SetPoint("TOPLEFT", 24, -20)
  f.title:SetText(L["Welcome to Arcanis"])
  f.desc = fstr(f, 12, C.textDim)
  f.desc:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -8)
  f.desc:SetPoint("RIGHT", f, "RIGHT", -24, 0)
  f.desc:SetWordWrap(true)
  f.desc:SetText(L["Tick what you want to use. The rest stays off and out of your way; you can turn anything on later in Settings > Modules. The quest guide, arrow and map pins are always on."])
  f.rows, f.picks = {}, {}
  local saved = ns.db.setupPicks
  for i, g in ipairs(self.GROUPS) do
    local on
    if saved and saved[g.id] ~= nil then on = saved[g.id] else on = g.on end
    f.picks[g.id] = on and true or false
    local r = CreateFrame("Frame", nil, f)
    r:SetPoint("TOPLEFT", 24, -96 - (i - 1) * ROW_H)
    r:SetPoint("RIGHT", f, "RIGHT", -24, 0)
    r:SetHeight(ROW_H - 4)
    r.check = Skin:CreateCheckbox(r, "", on, function(v) f.picks[g.id] = v and true or false end)
    r.check:SetPoint("TOPLEFT", 0, -4)
    r.title = fstr(r, 13, C.text)
    r.title:SetPoint("TOPLEFT", 28, -4)
    r.title:SetText(g.title())
    r.desc = fstr(r, 11, C.textDim)
    r.desc:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -3)
    r.desc:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.desc:SetWordWrap(true)
    r.desc:SetText(g.desc())
    f.rows[g.id] = r
  end
  local function close() f:Hide() end
  f.start = Skin:CreateButton(f, L["Start"], 130, 26, true)
  f.start:SetPoint("BOTTOMRIGHT", -24, 18)
  f.start:SetScript("OnClick", function() Setup:Apply(f.picks); close() end)
  f.all = Skin:CreateButton(f, L["Everything"], 130, 26)
  f.all:SetPoint("RIGHT", f.start, "LEFT", -8, 0)
  f.all:SetScript("OnClick", function()
    local all = {}
    for _, g in ipairs(Setup.GROUPS) do all[g.id] = true end
    Setup:Apply(all); close()
  end)
  f.skip = Skin:CreateButton(f, L["Later"], 110, 26)
  f.skip:SetPoint("BOTTOMLEFT", 24, 18)
  f.skip:SetScript("OnClick", function() ns.db.onboarded = true; close() end)
  f:Hide()
  self.frame = f
  return f
end

-- Doner: acildi mi (savasta bekler, savas bitince acilir)
function Setup:Open()
  if P.InCombat and P.InCombat() then
    self.pending = true
    if not self.waiter then
      self.waiter = CreateFrame("Frame")
      self.waiter:SetScript("OnEvent", function(w)
        w:UnregisterAllEvents()
        if Setup.pending then Setup.pending = nil; Setup:Open() end
      end)
    end
    self.waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
    return false
  end
  local f = self:Build()
  f.opened = true
  f:Show()
  f:Raise()
  return true
end

ns:RegisterCommand("setup", function() Setup:Open() end, "choose which parts of Arcanis to use")
