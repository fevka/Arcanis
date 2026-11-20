-- Arcanis: "What's new" penceresi. Addon surumu degisince (ns.version > ns.db.newsSeen) bir kez, giristen birkac
-- saniye sonra ve savas disinda kucuk bir pencere notlari (Data/WhatsNew.lua) gosterir. Yeni kurulumda gosterilmez
-- (ilk acilis kurulumu acilir); "dev" surumde hic. Kapatma: Esc / dugme. Ayarlar > General "Show what's new after
-- an update" (ns.db.newsOff). /wf news son surumlerin notlarini her zaman acar.
local _, ns = ...

local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack

local WN = {}
ns.WhatsNew = WN

-- "1.10.2" > "1.9" ; sayi olmayan surum (dev) karsilastirilamaz: nil
function WN.Compare(a, b)
  if type(a) ~= "string" or type(b) ~= "string" or not a:match("^%d") or not b:match("^%d") then return nil end
  local pa, pb = {}, {}
  for n in a:gmatch("%d+") do pa[#pa + 1] = tonumber(n) end
  for n in b:gmatch("%d+") do pb[#pb + 1] = tonumber(n) end
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i] or 0, pb[i] or 0
    if x ~= y then return x < y and -1 or 1 end
  end
  return 0
end

-- seen'den yeni, current'tan eski olmayan notlar (yeniden eskiye). seen nil: yalniz current'in notlari.
function WN.Pending(data, seen, current)
  local out = {}
  for _, e in ipairs(data or {}) do
    local upto = WN.Compare(e.version, current)
    local after = seen and WN.Compare(e.version, seen) or (WN.Compare(e.version, current) == 0 and 1 or -1)
    if upto and upto <= 0 and after and after > 0 then out[#out + 1] = e end
  end
  return out
end

-- Giriste: gosterilecek notlar ya da nil; gorulen surumu yazar
function WN:Check()
  local db, cur = ns.db, ns.version
  if not WN.Compare(cur, cur) then return nil end   -- dev
  if db.onboarded == nil then db.newsSeen = cur; return nil end   -- yeni kurulum
  if db.newsSeen and (WN.Compare(cur, db.newsSeen) or 1) <= 0 then return nil end
  local list = WN.Pending(ns.WhatsNewData, db.newsSeen, cur)
  db.newsSeen = cur
  if db.newsOff or #list == 0 then return nil end
  return list
end

local function fstr(parent, size, color)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f, size, "")
  f:SetTextColor(unpack(color or C.text))
  f:SetJustifyH("LEFT")
  f:SetWordWrap(true)
  return f
end

function WN:Build()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "ArcanisWhatsNew", UIParent, "BackdropTemplate")
  f:SetSize(460, 200)
  f:SetPoint("CENTER", 0, 80)
  f:SetFrameStrata("DIALOG")
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  Skin:ApplyBackdrop(f, C.panel, C.border)
  Skin:RegisterRoot(f)
  f.title = fstr(f, 16, C.accentHover)
  f.title:SetPoint("TOPLEFT", 16, -16)
  f.title:SetPoint("RIGHT", f, "RIGHT", -40, 0)
  f.close = Skin:CreateCloseButton(f, 14)
  f.close:SetPoint("TOPRIGHT", -10, -12)
  f.close:SetScript("OnClick", function() f:Hide() end)
  f.body = fstr(f, 12, C.text)
  f.body:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -12)
  f.body:SetPoint("RIGHT", f, "RIGHT", -16, 0)
  f.ok = Skin:CreateButton(f, L["Got it"], 110, 24, true)
  f.ok:SetPoint("BOTTOMRIGHT", -16, 16)
  f.ok:SetScript("OnClick", function() f:Hide() end)
  if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisWhatsNew") end
  f:Hide()
  self.frame = f
  return f
end

-- Metin: surum basligi + madde satirlari
function WN.Text(list)
  local lines = {}
  for _, e in ipairs(list) do
    if #list > 1 then lines[#lines + 1] = "|cffffd100" .. e.version .. "|r" end
    for _, n in ipairs(e.notes or {}) do lines[#lines + 1] = "- " .. (ns:LocalizedText(n) or "") end
    lines[#lines + 1] = ""
  end
  return table.concat(lines, "\n")
end

-- Savasta bekler (savas bitince acilir). Doner: acildi mi
function WN:Show(list)
  if not list or #list == 0 then return false end
  if P.InCombat() then
    self.pending = list
    ns:On("PLAYER_REGEN_ENABLED", self, function()
      ns:Off("PLAYER_REGEN_ENABLED", WN)
      local l = WN.pending
      WN.pending = nil
      WN:Show(l)
    end)
    return false
  end
  local f = self:Build()
  f.title:SetText(L["What's new in Arcanis %s"]:format(list[1].version))
  f.body:SetText(WN.Text(list))
  local h = f.body.GetStringHeight and f.body:GetStringHeight() or 0
  f:SetHeight(16 + 20 + 12 + (type(h) == "number" and h or 120) + 16 + 24 + 16)
  f:Show()
  if f.Raise then f:Raise() end
  return true
end

ns:Listen("ARCANIS_READY", WN, function()
  P.After(6, function() ns.SafeCall(function() WN:Show(WN:Check()) end) end)
end)

-- Ayarlar > General kartina tek anahtar (kurucu UI/Settings.lua buildAppearance)
function WN:BuildSettings(ob)
  ob:Switch("Show what's new after an update", "A small window with the changes, once after each new version (also /wf news).",
    function() return not ns.db.newsOff end, function(v) ns.db.newsOff = (not v) or nil end)
end

ns:RegisterCommand("news", function()
  local list = {}
  for _, e in ipairs(ns.WhatsNewData or {}) do
    if #list < 3 and (WN.Compare(e.version, ns.version) or 0) <= 0 then list[#list + 1] = e end
  end
  if not WN:Show(list) and #list == 0 then ns:Print(L["No release notes."]) end
end, "show what's new in Arcanis")
