-- Arcanis: Rehber Tarayicisi (modul "GuideBrowser", ana pencerede "Guides" sayfasi).
-- Sekmeler: Suggested (oneri, bolge, siradaki rehber), Leveling (seviye araliklarina gore gruplar), Class (sinif
-- gorev zincirleri ve durumlari), Professions (meslek basina beceri, trainer esigi, kasma onerisi), Recent, Favorites.
-- Solda arama + gruplu liste (Class Codex ile ayni satir/akordeon), sagda ayrinti paneli ve ana eylem.
local _, ns = ...

local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local U = Win.UI
local fstr, panel, safe = U.fstr, U.panel, U.safe
local GREEN = U.colors.objective
local unpack = unpack or table.unpack

local DETAIL_W = 280
local RECENT_MAX = 10

local GB = ns:NewModule("GuideBrowser", { defaults = { favorites = {} }, charDefaults = { recent = {} } })
ns.GuideBrowser = GB

function GB:Touch(id)
  local r = self.char and self.char.recent
  if not (r and id) then return end
  for i = #r, 1, -1 do if r[i] == id then table.remove(r, i) end end
  table.insert(r, 1, id)
  while #r > RECENT_MAX do table.remove(r) end
end

function GB:OnEnable()
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, function(o, _, id) o:Touch(id) end)
end

-- Rehberin oyuncuya gore durumu ve ilerleme orani: "current" | "done" | "low" (seviye yetmiyor) | "over" | "ok"
function GB:Status(g, player)
  local E = ns.Engine
  local n = g.steps and E:StepTotal(g) or 0
  local cur = E.guide and E.guide.id == g.id
  local at = cur and E.index or (E.char and E.char.progress and E.char.progress[g.id])
  local pct = (at and n > 0) and math.max(0, math.min(1, (at - 1) / n)) or 0
  if cur then return "current", pct end
  if at and at > n then return "done", 1 end
  if player.level < g.minLevel - 1 then return "low", pct end
  if player.level > g.maxLevel + 2 then return "over", pct end
  return "ok", pct
end

-- Sinif gorev zincirinin durumu: "done" | "active" | "notneeded" | "low" | "ok"
function GB:ClassStatus(e, player)
  local CG, E = ns.ClassGuide, ns.Engine
  local ids = CG:ChainIds(e)
  local done = #ids > 0
  for _, id in ipairs(ids) do
    if E:InLog(id) then return "active" end
    if not P.IsQuestFlaggedCompleted(id) then done = false end
  end
  if done then return "done" end
  if E.ClassQuestNotNeeded and E:ClassQuestNotNeeded(e.id) then return "notneeded" end
  if (e.level or 1) > (player.level or 1) then return "low" end
  return "ok"
end

local STATUS = {
  current = function() return L["Current"], GREEN end,
  done = function() return L["Done"], C.textDim end,
  low = function(g) return L["Level %d"]:format(g.minLevel or g.level or 1), C.textOff end,
  over = function() return L["Outleveled"], C.textDim end,
  ok = function() return "", C.accent end,
  active = function() return L["In progress"], GREEN end,
  notneeded = function() return L["Not needed"], C.textOff end,
}

local function guideRow(page, g, player, suggested)
  local GBm = GB
  local st, pct = GBm:Status(g, player)
  local text, tick = STATUS[st](g)
  if st == "ok" and suggested then text = L["Suggested"] end
  if st == "ok" and pct > 0 then text = ("%d%%"):format(math.floor(pct * 100)) end
  local dim = (st == "low" or st == "over" or st == "done")
  return {
    a = ns.Guides:ShortTitle(g), b = ("%d-%d"):format(g.minLevel, g.maxLevel) .. (GBm.db.favorites[g.id] and ("  " .. L["Favorite"]) or ""),
    right = text, tick = (page.sel and page.sel.guide == g) and C.accent or tick, aColor = dim and C.textDim or C.text,
    onClick = function() page.sel = { guide = g }; page.refresh() end,
  }
end

local function eligible(player)
  return ns.Guides:List(function(g) return ns.Guides:IsEligible(g, player) end)
end

-- Sekme icerikleri: list:Group(...) cagrilari
local VIEWS = {}

VIEWS.suggested = function(page, list, player)
  local G, E = ns.Guides, ns.Engine
  local rows, seen = {}, {}
  local function add(g, why)
    if g and not seen[g.id] then
      seen[g.id] = true
      local r = guideRow(page, g, player, true)
      r.b = r.b .. "  -  " .. why
      rows[#rows + 1] = r
    end
  end
  add(E.guide, L["Your guide"])
  add(E.guide and G:GetNext(E.guide, player), L["Next in the chain"])
  add(G:Suggest(player), L["For your level"])
  add(G:ForZone(P.ZoneText(), player), L["For this zone"])
  for _, g in ipairs(G:Find(player)) do if G:IsEligible(g, player) then add(g, L["For your level"]) end end
  list:Group("suggested", L["Suggested for you"], tostring(#rows), C.accent, rows)
end

VIEWS.leveling = function(page, list, player)
  local text = (page.search:GetText() or ""):lower()
  local bands, order = {}, {}
  for _, g in ipairs(eligible(player)) do
    if text == "" or ns.Guides:TitleOf(g):lower():find(text, 1, true) then
      local lo = math.floor(math.max(0, g.minLevel - 1) / 10) * 10
      if not bands[lo] then bands[lo] = {}; order[#order + 1] = lo end
      local b = bands[lo]
      b[#b + 1] = guideRow(page, g, player)
    end
  end
  table.sort(order)
  local mine = math.floor(math.max(0, (player.level or 1) - 1) / 10) * 10
  for _, lo in ipairs(order) do
    local key = "lv" .. lo
    if list.open[key] == nil then list.open[key] = (lo == mine) or text ~= "" end
    list:Group(key, L["Levels %d-%d"]:format(lo + 1, lo + 10), tostring(#bands[lo]), lo == mine and C.accent or C.border, bands[lo])
  end
  if #order == 0 then list:Group("none", L["No guide matches."], "", C.border, {}) end
end

VIEWS.class = function(page, list, player)
  local CG = ns.ClassGuide
  local rows, done = {}, {}
  for _, e in ipairs(CG and CG:Quests(player.class, player.faction, nil, player.race) or {}) do
    local st = GB:ClassStatus(e, player)
    local text, tick = STATUS[st](e)
    local r = {
      a = e.name, b = ("%d  -  %s"):format(e.level or 1, e.zone or "?"), right = text,
      tick = (page.sel and page.sel.class == e) and C.accent or tick,
      aColor = (st == "done" or st == "notneeded" or st == "low") and C.textDim or C.text,
      onClick = function() page.sel = { class = e }; page.refresh() end,
    }
    if st == "done" or st == "notneeded" then done[#done + 1] = r else rows[#rows + 1] = r end
  end
  list:Group("class", L["Class quests"], tostring(#rows), C.accent, rows)
  if #done > 0 then
    if list.open.classdone == nil then list.open.classdone = false end
    list:Group("classdone", L["Done or not needed"], tostring(#done), C.border, done)
  end
end

-- Ozel gorev serileri (rehber special = true): ayri odul zincirleri, seviye akisindan bagimsiz
VIEWS.special = function(page, list, player)
  local rows, done = {}, {}
  for _, g in ipairs(ns.Guides:List(function(g) return g.special and not g.profession and not g.dungeon and ns.Guides:IsEligible(g, player) end, true)) do
    local r = guideRow(page, g, player)
    if GB:Status(g, player) == "done" then done[#done + 1] = r else rows[#rows + 1] = r end
  end
  list:Group("special", L["Special quests"], tostring(#rows), C.accent, rows)
  if #done > 0 then list:Group("specialdone", L["Done"], tostring(#done), C.border, done) end
end

VIEWS.professions = function(page, list, player)
  local rows, known = {}, {}
  local function row(p, sub)
    return {
      a = p.name, b = sub,
      tick = (page.sel and page.sel.prof and page.sel.prof.name == p.name) and C.accent or C.border,
      onClick = function() page.sel = { prof = p }; page.refresh() end,
    }
  end
  for _, p in ipairs(P.ProfessionRanks() or {}) do
    known[p.name] = true
    rows[#rows + 1] = row(p, L["Skill %d / %d"]:format(p.rank or 0, p.max or 0))
  end
  -- acik ayrinti bos kalmasin: secim yoksa ilk meslek
  if not page.sel and rows[1] then page.sel = { prof = P.ProfessionRanks()[1] } end
  list:Group("profs", L["Your professions"], tostring(#rows), C.accent, rows)
  if #rows == 0 then list:Group("noprof", L["No professions learned yet."], "", C.border, {}) end
  -- ogrenilmemis meslekler: rehberi en bastan (trainer) baslatmak icin
  local other = {}
  local side = ns.ProfessionGuides and ns.ProfessionGuides[player.faction or ""] or {}
  local names = {}
  for name in pairs(side) do if not known[name] then names[#names + 1] = name end end
  table.sort(names)
  for _, name in ipairs(names) do other[#other + 1] = row({ name = name, rank = 0, max = 0 }, L["Not learned"]) end
  if #other > 0 then list:Group("otherprofs", L["Other professions"], tostring(#other), C.border, other) end
end

VIEWS.recent = function(page, list, player)
  local rows = {}
  for _, id in ipairs(GB.char.recent or {}) do
    local g = ns.Guides:Get(id)
    if g then rows[#rows + 1] = guideRow(page, g, player) end
  end
  list:Group("recent", L["Recently used"], tostring(#rows), C.accent, rows)
end

VIEWS.favorites = function(page, list, player)
  local rows = {}
  for _, g in ipairs(ns.Guides:List(function(g) return GB.db.favorites[g.id] end, true)) do rows[#rows + 1] = guideRow(page, g, player) end
  list:Group("fav", L["Favorites"], tostring(#rows), C.accent, rows)
  if #rows == 0 then list:Group("nofav", L["Mark guides as favorite in their details."], "", C.border, {}) end
end

local TABS = {
  { id = "suggested", text = function() return L["Suggested"] end },
  { id = "leveling", text = function() return L["Leveling"] end },
  { id = "class", text = function() return L["Class"] end },
  { id = "special", text = function() return L["Special"] end },
  { id = "professions", text = function() return L["Professions"] end },
  { id = "recent", text = function() return L["Recent"] end },
  { id = "favorites", text = function() return L["Favorites"] end },
}

-- Ayrinti paneli
local function detailGuide(d, g, player)
  local st, pct = GB:Status(g, player)
  d.title:SetText(ns.Guides:TitleOf(g))
  local lvl = L["Levels %d-%d"]:format(g.minLevel, g.maxLevel)
  local col = (st == "low") and C.textOff or ((st == "over") and C.textDim or C.text)
  d.sub:SetText(lvl); d.sub:SetTextColor(unpack(col))
  d.showBar(pct)
  local nxt = ns.Guides:GetNext(g, player)
  local lines = { L["%d steps"]:format(#(g.steps or {})) }
  if g.description then lines[#lines + 1] = ns:LocalizedText(g.description) end
  if nxt then lines[#lines + 1] = L["Next: %s"]:format(ns.Guides:TitleOf(nxt)) end
  if st == "low" then lines[#lines + 1] = L["You are below the level of this guide."] end
  d.body:SetText(table.concat(lines, "\n"))
  d.action:SetText(st == "current" and L["Open route"] or (pct > 0 and L["Continue"] or L["Start"]))
  d.action.run = function()
    if st ~= "current" then ns.Engine:SetGuide(g.id) end
    Win:Open("level")
  end
  d.action:Show()
  d.fav:SetChecked(GB.db.favorites[g.id] and true or false, true)
  d.fav.id = g.id
  d.fav:Show()
end

local function detailClass(d, e, player)
  local CG = ns.ClassGuide
  d.title:SetText(e.name)
  local text = STATUS[GB:ClassStatus(e, player)](e)
  d.sub:SetText(L["Level %d"]:format(e.level or 1) .. "  -  " .. (text ~= "" and text or L["Available"]))
  d.sub:SetTextColor(unpack(C.textDim))
  d.showBar(nil)
  local lines = { ("%s  -  %s (%.1f, %.1f)"):format(e.giver or "?", e.zone or "?", e.x or 0, e.y or 0) }
  if e.reward then lines[#lines + 1] = L["Reward: %s"]:format(CG:Text(e.reward)) end
  if e.note then lines[#lines + 1] = CG:Text(e.note) end
  local why = ns.Engine.ClassQuestNotNeeded and select(2, ns.Engine:ClassQuestNotNeeded(e.id))
  if why then lines[#lines + 1] = ns.Engine:NotNeededText(e, why) end
  d.body:SetText(table.concat(lines, "\n\n"))
  d.action:SetText(L["Show on the arrow"])
  d.action.run = function()
    local map = e.x and ns.Zones and ns.Zones:Resolve(e.zone)
    if map and ns.Nav then ns.Nav:SetTarget(map, e.x / 100, e.y / 100, e.giver or e.name, "manual") end
  end
  d.action:Show()
  d.fav:Hide()
end

local function detailProf(d, p, player)
  d.title:SetText(p.name)
  d.sub:SetText(L["Skill %d / %d"]:format(p.rank or 0, p.max or 0)); d.sub:SetTextColor(unpack(C.textDim))
  d.showBar((p.max or 0) > 0 and (p.rank or 0) / p.max or 0)
  local lines = {}
  local PA = ns.ProfActivity
  -- adim adim meslek rehberi (Guide/ProfGuides.lua): siradaki adimlar ve rehberi baslatan ana eylem
  local g = ns.ProfGuides and ns.ProfGuides.For(p.name)
  if g then
    local E, first = ns.Engine, nil
    local shown = {}
    for i, s in ipairs(g.steps) do
      if E:IsVisible(s, player) and E:StepDone(s) ~= true then
        first = first or i
        shown[#shown + 1] = ("%d. %s"):format(#shown + 1, E:Describe(s))
        if #shown >= 6 then break end
      end
    end
    lines[#lines + 1] = first and L["Next steps:"] or L["This profession guide is done."]
    for _, l in ipairs(shown) do lines[#lines + 1] = l end
    local current = E.guide and E.guide.id == g.id
    d.body:SetText(table.concat(lines, "\n"))
    d.action:SetText(current and L["Open route"] or L["Start the profession guide"])
    d.action.run = function()
      if not current then E:SetGuide(g.id, first) end
      Win:Open("level")
    end
    d.action:Show()
    d.fav:Hide()
    return
  end
  local hint = PA and PA.TierHint and PA.TierHint(p.rank or 0, p.max or 0)
  if hint then lines[#lines + 1] = hint end
  local plan = PA and PA.Plan and PA.Plan(p, player)
  for _, line in ipairs(PA and PA.PlanLines and PA.PlanLines(plan) or {}) do lines[#lines + 1] = line end
  -- tavana yaklasinca ana eylem: sonraki rutbenin en yakin trainer'i okta
  local t = plan and plan.trainer
  if t and t.map and (p.rank or 0) >= (p.max or 0) - 25 then
    d.body:SetText(table.concat(lines, "\n"))
    d.action:SetText(L["Show trainer on the arrow"])
    d.action.run = function() if ns.Nav then ns.Nav:SetTarget(t.map, t.x / 100, t.y / 100, t.npc, "manual") end end
    d.action:Show()
    d.fav:Hide()
    return
  end
  local G = ns.Gold
  for _, s in ipairs(G and G.SkillUps and G:SkillUps() or {}) do
    if s.prof == p.name and s.list[1] then
      lines[#lines + 1] = L["Cheapest skill-up: %s"]:format(s.list[1].name or ("#" .. s.list[1].id))
    end
  end
  for _, g in ipairs(G and G.GatherAdvice and G:GatherAdvice() or {}) do
    if g.prof == p.name and g.rows[1] then
      local r = g.rows[1]
      lines[#lines + 1] = (r.node and ("%s: %s"):format(r.node, table.concat(r.zones, ", "))
        or L["Beasts level %d-%d"]:format(r.mobs[1], r.mobs[2]) .. ": " .. table.concat(r.zones, ", "))
    end
  end
  if #lines == 0 then lines[1] = L["Open the profession window once so Arcanis can read its recipes."] end
  d.body:SetText(table.concat(lines, "\n"))   -- meslek satirlari cok: tek aralik
  d.action:SetText(L["Profession advice"])
  d.action.run = function() if ns.ShowGoldTab then ns.ShowGoldTab("prof") end end
  d.action:Show()
  d.fav:Hide()
end

local function build(page)
  page.tab = "suggested"
  local tabs = {}
  for _, t in ipairs(TABS) do tabs[#tabs + 1] = { id = t.id } end
  page.tabs = Skin:CreateTabBar(page, tabs, function(id) page.tab = id; page.sel = nil; page.refresh() end)
  page.tabs:SetPoint("TOPLEFT", 0, 0)
  page.tabs:SetPoint("TOPRIGHT", 0, 0)
  page.tabs:Select("suggested", true)

  page.search = Skin:CreateEditBox(page, 200, 24, function(_, user)
    if user then
      if page.tab ~= "leveling" and (page.search:GetText() or "") ~= "" then page.tab = "leveling"; page.tabs:Select("leveling", true) end
      page.refresh()
    end
  end)
  page.search:SetPoint("TOPLEFT", page.tabs, "BOTTOMLEFT", 0, -10)
  page.search:SetPoint("RIGHT", page, "RIGHT", -(DETAIL_W + 10), 0)
  page.searchHint = fstr(page.search, 10, C.textOff)
  page.searchHint:SetPoint("LEFT", 8, 0)

  page.body = CreateFrame("Frame", nil, page)
  page.body:SetPoint("TOPLEFT", page.search, "BOTTOMLEFT", 0, -8)
  page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -(DETAIL_W + 10), 0)
  page.list = U.newAccList(page.body)

  -- ayrinti paneli (sag sutun)
  local d = panel(page)
  d:SetPoint("TOPRIGHT", page.tabs, "BOTTOMRIGHT", 0, -10)
  d:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
  d:SetWidth(DETAIL_W)
  page.detail = d
  d.title = fstr(d, 14, C.text)
  d.title:SetPoint("TOPLEFT", 12, -12)
  d.title:SetPoint("RIGHT", d, "RIGHT", -12, 0)
  d.title:SetWordWrap(true)
  d.sub = fstr(d, 11, C.textDim)
  d.sub:SetPoint("TOPLEFT", d.title, "BOTTOMLEFT", 0, -4)
  d.sub:SetPoint("RIGHT", d, "RIGHT", -12, 0)
  d.track = CreateFrame("Frame", nil, d, "BackdropTemplate")
  Skin:ApplyBackdrop(d.track, C.barTrack, C.border)
  d.track:SetPoint("TOPLEFT", d.sub, "BOTTOMLEFT", 0, -10)
  d.track:SetPoint("RIGHT", d, "RIGHT", -12, 0)
  d.track:SetHeight(8)
  d.fill = d.track:CreateTexture(nil, "ARTWORK")
  Skin:Fill(d.fill, C.accent)
  d.fill:SetPoint("TOPLEFT", 1, -1)
  d.fill:SetPoint("BOTTOMLEFT", 1, 1)
  d.fill:SetWidth(1)
  function d.showBar(frac)
    if not frac then d.track:Hide() return end
    d.track:Show()
    local w = d.track:GetWidth()
    if type(w) ~= "number" or w <= 2 then w = DETAIL_W - 24 end
    d.fill:SetWidth(math.max(1, (w - 2) * math.min(1, frac)))
  end
  d.body = fstr(d, 11, C.text)
  d.body:SetPoint("TOPLEFT", d.track, "BOTTOMLEFT", 0, -12)
  d.body:SetPoint("RIGHT", d, "RIGHT", -12, 0)
  d.body:SetJustifyV("TOP")
  d.body:SetWordWrap(true)
  d.action = Skin:CreateButton(d, "", DETAIL_W - 24, 24, true)
  d.action:SetPoint("BOTTOMLEFT", 12, 12)
  d.action:SetScript("OnClick", safe(function(b) if b.run then b.run() end end))
  d.fav = Skin:CreateCheckbox(d, "", false, function(on)
    if d.fav.id then GB.db.favorites[d.fav.id] = on or nil; page.refresh() end
  end, 18)
  d.fav:SetPoint("BOTTOMLEFT", d.action, "TOPLEFT", 0, 8)
  d.empty = fstr(d, 11, C.textDim, "CENTER")
  d.empty:SetPoint("CENTER")

  function page.refresh()
    page.tabs:SetTexts(function(id) for _, t in ipairs(TABS) do if t.id == id then return t.text() end end return id end)
    page.searchHint:SetText((page.search:GetText() or "") == "" and L["Search guides..."] or "")
    d.fav:SetText(L["Favorite"])
    local player = P.PlayerInfo() or {}
    page.list:Begin()
    ns.SafeCall(VIEWS[page.tab] or VIEWS.suggested, page, page.list, player)
    page.list:End()
    local s = page.sel
    local show = s ~= nil
    for _, k in ipairs({ "title", "sub", "body", "action" }) do if show then d[k]:Show() else d[k]:Hide() end end
    d.empty:SetText(show and "" or L["Select a guide, class quest or profession to see its details."])
    if not show then d.track:Hide(); d.fav:Hide() return end
    if s.guide then detailGuide(d, s.guide, player)
    elseif s.class then detailClass(d, s.class, player)
    elseif s.prof then detailProf(d, s.prof, player) end
  end
  page:HookScript("OnSizeChanged", function()
    if page.IsVisible and page:IsVisible() then ns.SafeCall(page.refresh) end
  end)
  ns:Listen("ARCANIS_GUIDE_CHANGED", page, function()
    if page.IsVisible and page:IsVisible() then ns.SafeCall(page.refresh) end
  end)
end

-- Disaridan: belirli sekmeyle ac (adim penceresindeki secici, rehber bitince)
function GB:Open(tab)
  Win:Open("guides")
  local p = Win.pages and Win.pages.guides
  local page = p and (p.tabs and p or p.frame)
  if page and page.tabs and tab then page.tab = tab; page.tabs:Select(tab) end
end

Win:RegisterPage({
  id = "guides", order = 12, icon = "map",
  title = function() return L["Guide Browser"] end,
  available = function() return GB:IsEnabled() end,
  build = build,
})
