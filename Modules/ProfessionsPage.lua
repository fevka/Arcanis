-- Arcanis Path sayfasi: Meslekler (sahibin istegi, 13 Kasim 2026; eski sayfa yalniz bolgenin bitki/maden listesiydi).
-- Uc sekme:
--   Mesleklerim  : her meslek icin beceri / sinir, sonraki trainer esigi, meslek rehberini baslat; toplama
--                  mesleklerinde seviyene uyan bolge ve hangi damar / bitki (ok)
--   Tarifler     : ogrenilmemis tarifler, gereken beceri, egitmen / tarif esyasi ve kayitli satici (Helpers/Recipes.lua)
--   Farm pusulasi: suren toplama oturumu, bu haritadaki en yakin kayitli yer (ok), en verimli farm bolgeleri
--                  (Helpers/Farm.lua kayitlari), bulundugun bolgenin bitki / madenleri
--   Paylas       : farm kayitlarini disa aktar (metin), ice aktar, temizle
local _, ns = ...

local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack
local U = Win.UI
local fstr, safe = U.fstr, U.safe

local CARD_H, GAP = 58, 8
local GATHERING = { Mining = true, Herbalism = true, Skinning = true, Fishing = true }

local function profIcon(name)
  local MM = ns.MapMarkers
  local st = MM and MM.PROF_STYLE and MM.PROF_STYLE[name]
  return st and st[1] or Skin.Icons.hammer
end

-- Kaydirilabilir kart listesi: list:Reset(); list:Card(title, sub, icon, buttons); list:Done()
local function cardList(parent)
  local area = Skin:CreateScrollArea(parent, 560, 400)
  area:SetPoint("TOPLEFT", 0, 0)
  area:SetPoint("BOTTOMRIGHT", 0, 0)
  local list = { area = area, cards = {}, n = 0, y = 0 }
  function list:Reset()
    self.n, self.y = 0, 8
    for _, c in ipairs(self.cards) do c:Hide() end
  end
  -- buttons = { { text, fn }, ... } (sagdan sola)
  function list:Card(title, sub, iconPath, buttons, color)
    self.n = self.n + 1
    local c = self.cards[self.n]
    if not c then
      c = U.panel(area.content, C.card, C.border)
      c.icon = c:CreateTexture(nil, "ARTWORK")
      c.icon:SetSize(30, 30)
      c.icon:SetPoint("LEFT", 12, 0)
      c.title = fstr(c, 13, C.text)
      c.title:SetPoint("TOPLEFT", 52, -10)
      c.sub = fstr(c, 11, C.textDim)
      c.sub:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -4)
      c.sub:SetWordWrap(true)
      c.buttons = {}
      self.cards[self.n] = c
    end
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", area.content, "TOPLEFT", 8, -self.y)
    c:SetPoint("RIGHT", area.content, "RIGHT", -8, 0)
    c.titleText, c.subText = title or "", sub or ""   -- (testler ve erisilebilirlik)
    c.title:SetText(title or "")
    c.title:SetTextColor(unpack(color or C.text))
    c.sub:SetText(sub or "")
    if iconPath then c.icon:SetTexture(iconPath); c.icon:Show() else c.icon:Hide() end
    for _, b in ipairs(c.buttons) do b:Hide() end
    local right = -12
    for i, spec in ipairs(buttons or {}) do
      local b = c.buttons[i]
      if not b then b = Skin:CreateButton(c, "", 110, 22); c.buttons[i] = b end
      b:SetText(spec[1])
      b:SetScript("OnClick", safe(spec[2]))
      b:ClearAllPoints()
      b:SetPoint("RIGHT", c, "RIGHT", right, 0)
      b:Show()
      right = right - 118
    end
    c.sub:SetPoint("RIGHT", c, "RIGHT", right - 4, 0)
    local sh = c.sub.GetStringHeight and c.sub:GetStringHeight()
    local h = math.max(CARD_H, (type(sh) == "number" and sh or 14) + 40)
    c:SetHeight(h)
    c:Show()
    self.y = self.y + h + GAP
    return c
  end
  function list:Done() area:SetContentHeight(self.y + 8) end
  return list
end

local function arrowTo(zone, x, y, label)
  local map = zone and ns.Zones and ns.Zones:Resolve(zone)
  if map and ns.Nav then ns.Nav:SetTarget(map, x, y, label, "manual") end
end

-- ===== Mesleklerim =====
local function renderMine(list)
  list:Reset()
  local info = P.PlayerInfo() or {}
  local level = P.PlayerLevel()
  local ranks = P.ProfessionRanks() or {}
  if #ranks == 0 then
    list:Card(L["No professions learned yet."], L["Profession trainers are marked on your maps (Maps > Profession trainers)."], Skin.Icons.hammer)
  end
  local PG, PA, E = ns.ProfGuides, ns.ProfActivity, ns.Engine
  for _, p in ipairs(ranks) do
    local lines = {}
    local hint = PA and PA.TierHint and PA.TierHint(p.rank, p.max)
    if hint then lines[#lines + 1] = hint end
    local spot = GATHERING[p.name] and PG and PG.BestGatherZone and PG.BestGatherZone(p.name, level, p.rank, info.faction)
    if spot then
      lines[#lines + 1] = L["Best for you now: %s in %s"]:format(table.concat(spot.nodes, ", "), spot.zone)
    end
    local buttons = {}
    local guide = PG and PG.For and PG.For(p.name)
    if guide and E then
      buttons[#buttons + 1] = { L["Start the guide"], function() E:OpenGuide(guide.id); Win:ShowPage("level") end }
    end
    if spot then
      buttons[#buttons + 1] = { L["Arrow"], function() arrowTo(spot.zone, spot.x, spot.y, p.name .. ": " .. spot.zone) end }
    end
    list:Card(("%s  %d / %d"):format(L[p.name], p.rank, p.max), table.concat(lines, "\n"), profIcon(p.name), buttons)
  end
  list:Done()
end

-- ===== Tarifler (Helpers/Recipes.lua) =====
local RECIPE_CAP = 120   -- kart sayisi siniri ("All" uzun mesleklerde yuzlerce satir)

local function recipeCard(list, prof, e)
  local R = ns.Recipes
  local lines = { e.req and L["Learnable at skill %d. Yellow at %d, grey at %d."]:format(e.req, e.yellow, e.grey)
    or L["Yellow at %d, grey at %d."]:format(e.yellow, e.grey) }
  local buttons
  if e.auto then
    lines[#lines + 1] = L["Comes with the next profession rank."]
  elseif e.item then
    lines[#lines + 1] = L["Recipe item: %s"]:format(P.ItemName(e.item) or ("#" .. e.item))
    for i = 1, math.min(2, #e.vendors) do
      local v = e.vendors[i]
      lines[#lines + 1] = L["Sold by %s in %s"]:format(v.npc, v.zone or "?")
    end
    if e.vendors[1] then
      buttons = { { L["Arrow"], function() R:PointTo(e.vendors[1], e.vendors[1].npc .. ": " .. e.name) end } }
    else
      lines[#lines + 1] = L["Seller not recorded yet: vendors that sell it are saved when you visit them."]
    end
  else
    lines[#lines + 1] = L["Taught by a profession trainer."]
  end
  local icon = (e.product and P.ItemIcon(e.product)) or P.SpellIcon(e.spell) or profIcon(prof)
  list:Card(e.name, table.concat(lines, "\n"), icon, buttons)
end

local function renderRecipes(list, page)
  list:Reset()
  local R = ns.Recipes
  if not (R and R:IsEnabled()) then
    list:Card(L["Recipe browser is off"], L["Turn on the Recipe browser module in Settings > Modules."], Skin.Icons.hammer)
    list:Done()
    return
  end
  local shown, hidden = 0, 0
  for _, p in ipairs(P.ProfessionRanks() or {}) do
    local rows = (ns.RecipeList or {})[p.name] and R:Unlearned(p.name, p.rank, page.recipeAll) or nil
    if rows then
      list:Card(("%s  %d / %d"):format(L[p.name], p.rank, p.max),
        page.recipeAll and L["%d recipes you have not learned."]:format(#rows)
          or L["%d recipes you have not learned, up to %d skill points above yours."]:format(#rows, R.NEAR),
        profIcon(p.name), { { page.recipeAll and L["Near my skill"] or L["Show all"], function()
          page.recipeAll = not page.recipeAll
          page.refresh()
        end } }, C.accentHover)
      for _, e in ipairs(rows) do
        if shown < RECIPE_CAP then recipeCard(list, p.name, e); shown = shown + 1 else hidden = hidden + 1 end
      end
    end
  end
  if shown == 0 and hidden == 0 then
    list:Card(L["No recipes to show."], L["Learn a crafting profession, or open your profession window once."], Skin.Icons.hammer)
  end
  if hidden > 0 then list:Card(L["%d more not shown."]:format(hidden), nil, Skin.Icons.hammer) end
  list:Done()
end

-- ===== Farm pusulasi =====
local function money(v) return P.MoneyText and P.MoneyText(math.floor(v or 0)) or tostring(math.floor(v or 0)) end

local function renderFarm(list)
  list:Reset()
  local F = ns.Farm
  if not (F and F:IsEnabled()) then
    list:Card(L["Farm compass is off"], L["Turn on the Farm compass module in Settings > Modules."], Skin.Icons.hammer)
    list:Done()
    return
  end
  -- suren oturum
  local s = F:Current()
  if s then
    local secs = math.max(1, P.Now() - s.start)
    list:Card(L["Farming now: %s in %s"]:format(L[s.k], s.zone),
      L["%d gathered in %d min, %s (%s per hour)"]:format(s.nodes, math.floor(secs / 60), money(s.value), money(s.value / secs * 3600)),
      profIcon(s.k), nil, C.accentHover)
  else
    list:Card(L["No farming session"], L["Gather, skin or fish: every spot is remembered and each session is measured."], Skin.Icons.hammer)
  end
  -- bu haritadaki en yakin kayitli yer
  local near, d = F:Nearest()
  if near then
    list:Card(L["Nearest recorded spot: %s"]:format(L[near.k]), L["%d yd away, gathered there %d times."]:format(math.floor(d), near.n),
      profIcon(near.k), { { L["Arrow"], function()
        if ns.Nav then ns.Nav:SetTarget(near.map, near.x, near.y, L[near.k], "manual") end
      end } })
  end
  -- en verimli farm bolgeleri
  local stats = F:Stats()
  for i = 1, math.min(8, #stats) do
    local t = stats[i]
    list:Card(("%s  ·  %s"):format(t.zone, L[t.k]),
      L["%d per hour, %s per hour (%d sessions)"]:format(math.floor(t.perHour + 0.5), money(t.goldHour), t.runs), profIcon(t.k))
  end
  -- bulundugun bolgenin bitki / madenleri
  local zone = P.ZoneText and P.ZoneText()
  local lines = zone and ns.ZoneInfo and ns.ZoneInfo.Lines and ns.ZoneInfo:Lines(zone)
  if lines and #lines > 0 then
    list:Card(L["In %s"]:format(zone), table.concat(lines, "\n"), Skin.Icons.map)
  end
  list:Done()
end

-- ===== Paylas =====
local function buildShare(pane)
  local F = ns.Farm
  local t = fstr(pane, 12, C.text)
  t:SetPoint("TOPLEFT", 16, -14)
  t:SetPoint("RIGHT", pane, "RIGHT", -16, 0)
  t:SetWordWrap(true)
  t:SetText(L["Share your farm spots and sessions with friends: export copies a text, import adds theirs to yours."])
  local exp = Skin:CreateButton(pane, L["Export"], 130, 24, true)
  exp:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -12)
  exp:SetScript("OnClick", safe(function()
    if F then Skin:ShowCopyBox(L["Farm data"], F:Export(), L["Copy it with Ctrl+C and send it."]) end
  end))
  local box = Skin:CreateEditBox(pane, 360, 24)
  box:SetPoint("TOPLEFT", exp, "BOTTOMLEFT", 0, -16)
  local imp = Skin:CreateButton(pane, L["Import"], 130, 24)
  imp:SetPoint("LEFT", box, "RIGHT", 8, 0)
  local status = fstr(pane, 11, C.textDim)
  status:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
  imp:SetScript("OnClick", safe(function()
    if not F then return end
    local a, b = F:Import(box:GetText())
    if a then
      status:SetText(L["Imported: %d spots, %d sessions."]:format(a, b))
      box:SetText("")
    else
      status:SetText(L["This is not Arcanis farm data."])
    end
  end))
  local armed
  local clear = Skin:CreateButton(pane, L["Clear my farm data"], 160, 24)
  clear:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -20)
  clear:SetScript("OnClick", safe(function()
    if not F then return end
    if not armed or P.Now() - armed > 4 then
      armed = P.Now()
      clear:SetText(L["Click again to clear"])
      return
    end
    armed = nil
    F:Clear()
    clear:SetText(L["Clear my farm data"])
    status:SetText(L["Farm data cleared."])
  end))
  pane.export, pane.box, pane.import, pane.status, pane.clear = exp, box, imp, status, clear
  -- ArcanisVault (ayri addon) yukluyse eski sayfadaki dugme burada
  if _G.VaultPanel then
    local v = Skin:CreateButton(pane, L["Open ArcanisVault"], 180, 24)
    v:SetPoint("TOPLEFT", clear, "BOTTOMLEFT", 0, -20)
    v:SetScript("OnClick", safe(function() _G.VaultPanel:Show() end))
  end
end

local function build(page)
  local panes = {}
  local bar = Skin:CreateTabBar(page, {
    { id = "mine", text = L["My professions"] }, { id = "recipes", text = L["Recipes"] }, { id = "farm", text = L["Farm compass"] },
    { id = "share", text = L["Share"] },
  }, function(id)
    for k, p in pairs(panes) do if k == id then p:Show() else p:Hide() end end
    page.tab = id
    if page.refresh then page.refresh() end
  end)
  bar:SetPoint("TOPLEFT", 12, -6); bar:SetPoint("TOPRIGHT", -12, -6)
  for _, k in ipairs({ "mine", "recipes", "farm", "share" }) do
    local p = CreateFrame("Frame", nil, page)
    p:SetPoint("TOPLEFT", 0, -42); p:SetPoint("BOTTOMRIGHT", 0, 0)
    panes[k] = p
  end
  page.mine = cardList(panes.mine)
  page.recipes = cardList(panes.recipes)
  page.farm = cardList(panes.farm)
  buildShare(panes.share)
  page.panes, page.tabs, page.tab = panes, bar, "mine"
  function page.refresh()
    if page.tab == "mine" then renderMine(page.mine)
    elseif page.tab == "recipes" then renderRecipes(page.recipes, page)
    elseif page.tab == "farm" then renderFarm(page.farm) end
  end
  bar:Select("mine")
end

Win:RegisterPage({
  id = "professions", order = 30, icon = "hammer",
  title = function() return L["Professions"] end,
  build = build,
})
