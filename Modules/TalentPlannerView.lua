-- Arcanis: yetenek planlayicisinin gorunumu (Class Codex > Talents > "Planner"). Mantik Helpers/TalentPlanner.lua.
-- Ustte plan secici ve dugmeler, altinda uc bolumun izgarasi (sol tik puan ekler, sag tik son puani kaldirir),
-- en altta leveling build'imizle fark.
local _, ns = ...

local TP = ns.TalentPlanner
local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack
local U = Win.UI
local fstr, panel, safe = U.fstr, U.panel, U.safe

local CELL, STEP = 32, 40   -- yetenek kutusu ve izgara adimi (8 bosluk)

local WHY = {
  points = function() return L["All 51 points are spent."] end,
  max = function() return L["This talent is at its highest rank."] end,
  row = function() return L["Spend more points in this tree first (5 per row)."] end,
  parent = function() return L["The talent it depends on needs all its ranks first."] end,
  choice = function() return L["Only one talent of this choice can be taken."] end,
}

function TP.BuildView(parent)
  local v = CreateFrame("Frame", nil, parent)
  v.plan = 1

  -- ust satir: plan secici + dugmeler
  v.pick = Skin:CreateDropdown(v, 180, {}, 1, safe(function(i) v.plan = i; v.refresh() end))
  v.pick:SetPoint("TOPLEFT", 0, 0)
  local function button(text, w, fn)
    local b = Skin:CreateButton(v, text, w, 24)
    b:SetScript("OnClick", safe(fn))
    return b
  end
  local function current() return TP:Presets()[v.plan] end
  local function say(text, bad) v.status:SetText(text or ""); v.status:SetTextColor(unpack(bad and C.bad or C.textDim)) end
  v.new = button(L["New"], 76, function()
    v.plan = TP:NewPreset()
    say("")
    v.refresh()
  end)
  v.new:SetPoint("LEFT", v.pick, "RIGHT", 8, 0)
  v.rename = button(L["Rename"], 76, function()
    local p = current()
    if p then Skin:ShowTextBox(L["Plan name"], p.name, nil, function(t)
      t = t:gsub("^%s+", ""):gsub("%s+$", "")
      if t ~= "" then p.name = t:sub(1, 40) end
      v.refresh()
    end) end
  end)
  v.rename:SetPoint("LEFT", v.new, "RIGHT", 8, 0)
  v.export = button(L["Export"], 76, function()
    local p = current()
    if p then Skin:ShowCopyBox(L["Talent plan"], TP.Export(p.order, P.PlayerClassToken()), L["Copy it with Ctrl+C and send it."]) end
  end)
  v.export:SetPoint("LEFT", v.rename, "RIGHT", 8, 0)
  v.import = button(L["Import"], 76, function()
    Skin:ShowTextBox(L["Import a talent plan"], "", L["Paste an Arcanis plan, a talent calculator link or a loadout code."], function(text)
      local grid = TP:LiveGrid()
      if not grid then return say(L["Talents are not read yet. Open your talent window once."], true) end
      local order, _, err = TP.Import(grid, text, P.PlayerClassToken())
      if not order then return say(err, true) end
      v.plan = TP:NewPreset(nil, order)
      say(L["Plan imported."])
      v.refresh()
    end)
  end)
  v.import:SetPoint("LEFT", v.export, "RIGHT", 8, 0)
  v.reset = button(L["Reset"], 76, function()
    local p = current()
    if p then p.order = {}; TP:Changed(); v.refresh() end
  end)
  v.reset:SetPoint("LEFT", v.import, "RIGHT", 8, 0)
  v.delete = button(L["Delete"], 76, function()
    TP:DeletePreset(v.plan)
    v.plan = math.max(1, v.plan - 1)
    v.refresh()
  end)
  v.delete:SetPoint("LEFT", v.reset, "RIGHT", 8, 0)

  -- ikinci satir: siradaki talent icin kullan + puanlar + durum
  v.use = Skin:CreateCheckbox(v, L["Use for the next talent marker"], false, safe(function(on)
    TP:SetActive(on and v.plan or nil)
    v.refresh()
  end))
  v.use:SetPoint("TOPLEFT", v.pick, "BOTTOMLEFT", 0, -12)
  v.points = fstr(v, 12, C.text)
  v.points:SetPoint("LEFT", v.use, "RIGHT", 12, 0)
  v.status = fstr(v, 11, C.textDim)
  v.status:SetPoint("TOPLEFT", v.use, "BOTTOMLEFT", 0, -8)
  v.status:SetPoint("RIGHT", v, "RIGHT", -8, 0)

  v.area = Skin:CreateScrollArea(v, 600, 300)
  v.area:SetPoint("TOPLEFT", v.status, "BOTTOMLEFT", 0, -8)
  v.area:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", 0, 0)
  v.trees, v.cells = {}, {}
  for s = 1, 3 do
    local t = panel(v.area.content)
    t.title = fstr(t, 12, C.accentHover)
    t.title:SetPoint("TOPLEFT", 12, -10)
    v.trees[s] = t
  end
  v.compare = fstr(v.area.content, 11, C.textDim)
  v.compare:SetWordWrap(true)

  local function cell(i)
    local b = v.cells[i]
    if b then return b end
    b = CreateFrame("Button", nil, v.area.content, "BackdropTemplate")
    b:SetSize(CELL, CELL)
    Skin:ApplyBackdrop(b, C.bg, C.border)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 1, -1); b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.rank = fstr(b, 10, C.text, "RIGHT", "OUTLINE")
    b.rank:SetPoint("BOTTOMRIGHT", 2, -2)
    if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    b:SetScript("OnClick", safe(function(self, mouse)
      local p, grid = current(), v.grid
      if not (p and grid) then return end
      local ok, why
      if mouse == "RightButton" then ok, why = TP.Remove(grid, p, self.c.key)
      else ok, why = TP.Add(grid, p, self.c.key) end
      if ok then say(""); TP:Changed()
      elseif why and WHY[why] then say(WHY[why](), true)
      elseif why == "none" then say("")
      else say(L["Removing this point would break a later one."], true) end
      v.refresh()
    end))
    b:SetScript("OnEnter", function(self)
      if not GameTooltip then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if self.c.spellID and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.c.spellID)
      else GameTooltip:SetText(self.c.name) end
      GameTooltip:AddLine(L["Left click: add a point. Right click: remove one."], 0.7, 0.7, 0.7, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    v.cells[i] = b
    return b
  end

  function v.refresh()
    local list = TP:Presets()
    if #list == 0 then TP:NewPreset() end
    v.plan = math.max(1, math.min(v.plan, #list))
    local items = {}
    for i, p in ipairs(list) do items[i] = { value = i, text = p.name } end
    v.pick.value = v.plan
    v.pick:SetItems(items)
    local p = list[v.plan]
    v.use:SetChecked(TP.char.active == v.plan, true)
    v.grid = TP:LiveGrid()
    local grid = v.grid
    for _, b in ipairs(v.cells) do b:Hide() end
    if not grid then
      for _, t in ipairs(v.trees) do t:Hide() end
      v.points:SetText("")
      v.compare:SetText(L["Talents are not read yet. Open your talent window once."])
      v.compare:SetPoint("TOPLEFT", 8, -8)
      v.area:SetContentHeight(60)
      return
    end
    local ranks, spent = TP.Ranks(p.order), TP.Spent(grid, p.order)
    v.points:SetText(L["Points: %d / %d (%d / %d / %d), level %d"]:format(#p.order, TP.MAX_POINTS, spent[1], spent[2], spent[3],
      #p.order > 0 and #p.order + 9 or 10))
    -- bolum genisligi en genis bolumun sutunu kadar
    local cols, rows = 1, 1
    for _, c in ipairs(grid.cells) do cols = math.max(cols, c.col); rows = math.max(rows, c.row) end
    local tw = 24 + (cols - 1) * STEP + CELL
    local th = 36 + (rows - 1) * STEP + CELL + 12
    local RF = ns.RF
    for s, t in ipairs(v.trees) do
      t:ClearAllPoints()
      t:SetPoint("TOPLEFT", v.area.content, "TOPLEFT", (s - 1) * (tw + 8), 0)
      t:SetSize(tw, th)
      t.title:SetText(L["Tree %d: %d points"]:format(s, spent[s] or 0))
      t:Show()
    end
    local total = #p.order
    for i, c in ipairs(grid.cells) do
      local b = cell(i)
      b.c = c
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", v.trees[c.section], "TOPLEFT", 12 + (c.col - 1) * STEP, -36 - (c.row - 1) * STEP)
      local tex = c.spellID and P.SpellIcon(c.spellID) or P.SpellIcon(c.name)
      b.icon:SetTexture(tex or Skin.Icons.star)
      local have = ranks[c.key] or 0
      b.rank:SetText(("%d/%d"):format(have, c.max))
      -- verilebilir mi (yalniz renk): bir puan daha eklenince sira gecerli kaliyor mu
      p.order[total + 1] = c.key
      local open = TP.Validate(grid, p.order)
      p.order[total + 1] = nil
      b.icon:SetDesaturated(have == 0 and not open)
      b:SetAlpha((have > 0 or open) and 1 or 0.45)
      b:SetBackdropBorderColor(unpack(have >= c.max and C.accent or (have > 0 and C.accentHover or C.border)))
      b.rank:SetTextColor(unpack(have > 0 and C.text or C.textDim))
      b:Show()
    end
    -- leveling build'imizle fark
    local B = ns.Build
    local build = B and B:Available() and B:ListFor("Leveling")[1]
    local lines = {}
    if build then
      local diff = TP.Compare(grid, p.order, build)
      lines[1] = #diff == 0 and L["Same as the leveling build %s."]:format(build.shortname or "?")
        or L["Compared with the leveling build %s (plan / build):"]:format(build.shortname or "?")
      for _, d in ipairs(diff) do
        lines[#lines + 1] = ("%s  %d / %d"):format(RF and RF.TalentDisplayName and RF.TalentDisplayName(d.name) or d.name, d.plan, d.build)
      end
    end
    v.compare:ClearAllPoints()
    v.compare:SetPoint("TOPLEFT", v.trees[1], "BOTTOMLEFT", 0, -12)
    v.compare:SetWidth(3 * tw + 16)
    v.compare:SetText(table.concat(lines, "\n"))
    v.area:SetContentHeight(th + 24 + 14 * #lines)
  end
  return v
end
