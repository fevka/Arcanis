-- Arcanis: zindan onerisi penceresi (ns.DungeonPrompt). Seviye bir zindana uyunca sorar:
-- rehberi baslat / gunlugu ac / simdi degil. Savasta gosterilmez (Journal bekletir).
local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L

local Prompt = { timeout = 45 }
ns.DungeonPrompt = Prompt

local WIDTH, ART_H = 380, 64

function Prompt:Build()
  if self.frame then return end
  local f = CreateFrame("Frame", "ArcanisDungeonPrompt", UIParent, "BackdropTemplate")
  ns.Skin:RegisterRoot(f)
  f:SetSize(WIDTH, ART_H + 92)
  f:SetPoint("TOP", UIParent, "TOP", 0, -190)
  f:SetFrameStrata("DIALOG")
  Skin:ApplyBackdrop(f, C.bg, C.accent)

  f.banner = Skin:CreateBanner(f, WIDTH - 2, ART_H)
  f.banner:SetPoint("TOPLEFT", 1, -1)

  f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f.text, 11, "")
  f.text:SetPoint("TOPLEFT", f.banner, "BOTTOMLEFT", 10, -8)
  f.text:SetWidth(WIDTH - 22)
  f.text:SetJustifyH("LEFT")
  f.text:SetTextColor(unpack(C.text))

  f.start = Skin:CreateButton(f, "", 150, 24, true)
  f.start:SetPoint("BOTTOMLEFT", 10, 10)
  f.open = Skin:CreateButton(f, "", 110, 24)
  f.open:SetPoint("LEFT", f.start, "RIGHT", 6, 0)
  f.later = Skin:CreateButton(f, "", 90, 24)
  f.later:SetPoint("BOTTOMRIGHT", -10, 10)

  f.start:SetScript("OnClick", function()
    local d = Prompt.dungeon
    Prompt:Hide()
    if d then ns.Journal:StartGuide(d) end
  end)
  f.open:SetScript("OnClick", function()
    local d = Prompt.dungeon
    Prompt:Hide()
    if d and ns.DungeonWindow then
      ns.Journal.focus = d.id
      ns.DungeonWindow:Open()
    end
  end)
  f.later:SetScript("OnClick", function() Prompt:Hide() end)
  f:SetScript("OnUpdate", function(_, elapsed)
    Prompt.age = (Prompt.age or 0) + elapsed
    if Prompt.age >= Prompt.timeout then Prompt:Hide() end
  end)
  f:Hide()
  self.frame = f
end

function Prompt:Show(d)
  self:Build()
  local f = self.frame
  self.dungeon, self.age = d, 0
  local dir = "Interface\\AddOns\\Arcanis\\Media\\Dungeons\\"
  f.banner:SetArt(dir .. (d.art or d.id) .. ".png", dir .. "tracked.png")
  f.banner.title:SetText(d.name)
  f.banner.sub:SetText(("%s  |  %d-%d"):format(d.zone, d.minLevel, d.maxLevel))
  f.text:SetText(L["You are level %d - %s is a good fit. Start the dungeon guide?"]:format(ns.Provider.PlayerLevel(), d.name))
  f.start:SetText(L["Start guide"])
  f.open:SetText(L["Open journal"])
  f.later:SetText(L["Not now"])
  f:Show()
end

function Prompt:Hide()
  if self.frame then self.frame:Hide() end
  self.dungeon = nil
end
