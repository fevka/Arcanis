local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local P = ns.Provider
local L = ns.L
local Island = ns.Island

-- Hub'da zindan: zindanin icindeyken kisayol dugmesi kartlar yerine o zindanin boss'larini ve loot'unu gosterir
-- (sohbet gibi; Esc / baslik kapatir). Yalniz boss + loot; "Only loot for me" (Island.db.dungeonMine) sinifin
-- giyebildigi, asil zirh turundaki ve uzmanlik agirliklarina gore puani olan esyalari birakir. Yukseltme yesil ok.
local DV = { rows = {} }
Island.Dungeon = DV

local HEADER, PAD, W, H = 28, 12, 420, 380
local HEAD_H, BOSS_H, ROW_H = 34, 24, 22
local QUALITY = { [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd", [4] = "a335ee", [5] = "ff8000" }
local TRASH = "Trash Drops"

function DV:Width() return W end
function DV:Height() return H end

-- Instance adi -> Data/Dungeons.lua kaydi: once tam ad, sonra iki yonlu icerme (Journal:NoteEntrance gibi).
-- shortcut: ayni adli kanatlar (Scarlet Monastery, Dire Maul) ilk kanadi verir; iceride kapi konumu yok.
function DV.Lookup(name)
  if type(name) ~= "string" or name == "" then return nil end
  local low = name:lower()
  local list = ns.DungeonData or {}
  for _, d in ipairs(list) do if d.name:lower() == low then return d end end
  for _, d in ipairs(list) do
    local dn = d.name:lower()
    if dn:find(low, 1, true) or low:find(dn, 1, true) then return d end
  end
  -- basindaki "The" olmadan: oyun "Stormwind Stockade" der, verimiz "The Stockade" (18 Kasim 2026)
  local function bare(s) return (s:gsub("^the%s+", "")) end
  local lb = bare(low)
  for _, d in ipairs(list) do
    local dn = bare(d.name:lower())
    if dn:find(lb, 1, true) or lb:find(dn, 1, true) then return d end
  end
end

function DV.Current()
  return DV.Lookup((P.InstanceInfo()))
end

-- "Benim icin" esya: giyilebilir (sinif + silah becerisi), asil zirh turu, uzmanlik agirligiyla puani > 0.
-- Esyanin seviyesi oyuncudan yuksekse o seviyede bakilir (zindan loot'u birkac seviye sonra giyilir).
-- Bilgisi yuklenmemis esya listede kalir (Journal:Loot ile ayni kural).
function DV.ForMe(item, token, level)
  if not item then return true end
  local G = ns.Gear
  if not (G and G.SLOTS[item.equipLoc]) then return false end
  local at = math.max(level or 1, item.minLevel or 0)
  if not (G:CanEquip(item, token, at) and G:ProperArmor(item, token, at)) then return false end
  local score = G:Score(item, token, nil, at)
  return type(score) == "number" and score > 0
end

-- Boss gruplari, veri sirasiyla; "Trash Drops" en sonda. onlyMine: ForMe suzgeci. Doner: { { boss, items } }.
function DV.Groups(d, onlyMine, token, level)
  local J = ns.Journal
  local groups, trash = {}, nil
  for _, g in ipairs(J and d and J:Loot(d, token, false) or {}) do
    local items = {}
    for _, e in ipairs(g.items) do
      if not onlyMine or DV.ForMe(e.item, token, level) then items[#items + 1] = e end
    end
    if #items > 0 then
      local out = { boss = g.boss, items = items }
      if g.boss == TRASH then trash = out else groups[#groups + 1] = out end
    end
  end
  groups[#groups + 1] = trash
  return groups
end

local function text(parent, sz, color, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f, sz, "")
  f:SetTextColor(unpack(color or Skin.Colors.text))
  f:SetJustifyH(justify or "LEFT")
  f:SetWordWrap(false)
  return f
end

function DV:Build()
  if self.frame then return end
  local C = Skin.Colors
  local f = CreateFrame("Frame", "ArcanisIslandDungeon", Island.frame)
  f:SetPoint("TOPLEFT", Island.frame, "TOPLEFT", 0, -HEADER)
  f:SetPoint("BOTTOMRIGHT", Island.frame, "BOTTOMRIGHT", 0, 0)
  f:SetClipsChildren(true)
  f:EnableMouse(true)
  f:SetScript("OnHide", function() if not DV.hiding and Island.dungeonOpen then Island:CloseHub() end end)
  if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisIslandDungeon") end

  f.name = text(f, 14, C.text)
  f.name:SetPoint("TOPLEFT", PAD, -10)
  f.sub = text(f, 10, C.textDim)
  f.sub:SetPoint("LEFT", f.name, "RIGHT", 8, 0)
  f.mine = Skin:CreateCheckbox(f, L["Only loot for me"], Island.db.dungeonMine, function(v)
    Island.db.dungeonMine = v
    DV:Refresh()
  end)
  f.mine:SetWidth(18 + 8 + math.ceil(tonumber(f.mine.label:GetStringWidth()) or 100))
  f.mine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -9)
  f.name:SetPoint("RIGHT", f.mine, "LEFT", -12, 0)
  f.sep = f:CreateTexture(nil, "ARTWORK")
  Skin:Fill(f.sep, C.border, 0.6)
  Skin:Hairline(f.sep, "h")
  f.sep:SetPoint("TOPLEFT", PAD, -HEAD_H); f.sep:SetPoint("TOPRIGHT", -PAD, -HEAD_H)
  f.list = Skin:CreateScrollArea(f, W - 2 * PAD, H - HEADER - HEAD_H - 8 - PAD)
  f.list:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(HEAD_H + 8))
  f.empty = text(f, 12, C.textDim, "CENTER")
  f.empty:SetPoint("CENTER", f.list, "CENTER")

  -- esya bilgisi sonradan gelir: gorunurken bir kez toplu yenile
  ns:On("GET_ITEM_INFO_RECEIVED", self, function()
    if not (f:IsVisible() and DV.waiting) or DV.queued then return end
    DV.queued = true
    P.After(0.3, function() DV.queued = nil; if f:IsVisible() then ns.SafeCall(DV.Refresh, DV) end end)
  end)
  self.hiding = true
  f:Hide()
  self.hiding = nil
  self.frame = f
end

function DV:Row(i)
  local r = self.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, self.frame.list.content)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(16, 16)
  r.icon:SetPoint("LEFT", 0, 0)
  r.up = r:CreateTexture(nil, "OVERLAY")
  r.up:SetTexture(Skin.Icons.rarrow)
  r.up:SetSize(12, 12)
  r.up:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
  if r.up.SetRotation then r.up:SetRotation(math.pi / 2) end   -- GearMarks.UpArrow ile ayni: sag ok yukari doner
  r.up:SetVertexColor(0.3, 0.95, 0.35, 1)
  r.name = text(r, 11, Skin.Colors.text)
  r.slot = text(r, 10, Skin.Colors.textDim, "RIGHT")
  r.slot:SetPoint("RIGHT", r, "RIGHT", -4, 0)
  r:SetScript("OnEnter", function(x)
    if not (GameTooltip and x.itemId) then return end
    GameTooltip:SetOwner(x, "ANCHOR_RIGHT")
    pcall(GameTooltip.SetItemByID, GameTooltip, x.itemId)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  self.rows[i] = r
  return r
end

local function bossRow(r, name)
  r.itemId = nil
  r:SetHeight(BOSS_H)
  r.icon:Hide(); r.up:Hide(); r.slot:SetText("")
  r.name:ClearAllPoints()
  r.name:SetPoint("BOTTOMLEFT", 0, 4)
  r.name:SetPoint("RIGHT", r, "RIGHT", -4, 0)
  Skin:SetFont(r.name, 12, "")
  r.name:SetTextColor(unpack(Skin.Colors.accent))
  r.name:SetText(name == TRASH and L["Trash Drops"] or name)
end

local function itemRow(r, e, upgrade)
  local item = e.item
  r.itemId = e.id
  r:SetHeight(ROW_H)
  r.icon:SetTexture((item and item.icon) or P.ItemIcon(e.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
  r.icon:Show()
  r.up:SetShown(upgrade)
  r.name:ClearAllPoints()
  r.name:SetPoint("LEFT", upgrade and r.up or r.icon, "RIGHT", upgrade and 4 or 8, 0)
  r.name:SetPoint("RIGHT", r.slot, "LEFT", -8, 0)
  Skin:SetFont(r.name, 11, "")
  r.name:SetTextColor(unpack(Skin.Colors.text))
  local color = QUALITY[(item and item.quality) or e.q or 1] or "ffffff"
  r.name:SetText(("|cff%s%s|r"):format(color, (item and item.name) or e.n or ("#" .. e.id)))
  local slot = item and item.equipLoc and _G[item.equipLoc]
  r.slot:SetText(item and ((slot and slot ~= "" and slot ~= item.subType) and (slot .. ", " .. (item.subType or "")) or item.subType or "") or e.s or "")
end

function DV:Refresh()
  local f, d = self.frame, self.d
  if not (f and d) then return end
  local mine = Island.db.dungeonMine and true or false
  f.mine:SetChecked(mine, true)
  f.name:SetText(d.name)
  f.sub:SetText(d.minLevel and L["Level %d-%d"]:format(d.minLevel, d.maxLevel) or "")
  local token, level = P.PlayerClassToken(), P.PlayerLevel() or 1
  local groups = DV.Groups(d, mine, token, level)
  local content, GM = f.list.content, ns.GearMarks
  content:SetWidth(W - 2 * PAD - 12)
  local i, y = 0, 0
  self.waiting = false
  for gi, g in ipairs(groups) do
    i = i + 1
    local r = self:Row(i)
    if gi > 1 then y = y + 4 end
    bossRow(r, g.boss)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y); r:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    r:Show()
    y = y + BOSS_H
    for _, e in ipairs(g.items) do
      i = i + 1
      r = self:Row(i)
      if not e.item then self.waiting = true end
      itemRow(r, e, e.item and e.item.link and GM and GM:IsUpgrade(e.item.link) or false)
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y); r:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      r:Show()
      y = y + ROW_H
    end
  end
  for k = i + 1, #self.rows do self.rows[k]:Hide() end
  f.empty:SetText(#groups == 0 and (mine and L["Nothing here for your class."] or L["No loot recorded for this dungeon."]) or "")
  f.list:SetContentHeight(y + 4)
end

function DV:Open(d)
  self:Build()
  if d ~= self.d then self.d = d; self.frame.list:ScrollTo(0, true) end
  self.frame:Show()
  self:Refresh()
end

function DV:Hide()
  if not self.frame then return end
  self.hiding = true
  self.frame:Hide()
  self.hiding = nil
end
