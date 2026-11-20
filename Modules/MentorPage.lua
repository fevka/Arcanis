-- Arcanis Path sayfasi: Mentor. Yeni oyuncu icin bilgi bankasi + "su an" tavsiyeleri.
--   Sekmeler: Now (durumuna gore: yetenek puani, egitmen, canta, tamir, yukseltme, binek parasi, meslek, zindan),
--   Items (kolay ama guclu esyalar, Data/EasyItems.lua: tikla -> ok kaynaga ya da ozel rehber; kutu = "aldim"),
--   Books (kutuphane kitaplari, Helpers/LibraryBooks.lua: durum, oyunda kaydedilen yer, ok),
--   All ve kategoriler (Basics, Leveling, Combat, Gear, Gold, Professions, Social, Class).
--   Bilgiler seviyene ve sinifina gore suzulur; okunanlar isaretlenir ve listenin sonuna iner.
local _, ns = ...

local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local U = Win.UI
local fstr, panel, icon, safe = U.fstr, U.panel, U.icon, U.safe
local GAP = 8

local TABS = {
  { id = "now" }, { id = "items" }, { id = "books" }, { id = "all" }, { id = "basics" }, { id = "leveling" }, { id = "combat" },
  { id = "gear" }, { id = "gold" }, { id = "professions" }, { id = "social" }, { id = "class" },
}
local TAB_TEXT = {
  now = function() return L["Now"] end, items = function() return L["Items"] end, all = function() return L["All"] end,
  books = function() return L["Books"] end,
  basics = function() return L["Basics"] end, leveling = function() return L["Leveling"] end,
  combat = function() return L["Combat"] end, gear = function() return L["Gear"] end,
  gold = function() return L["Gold"] end, professions = function() return L["Professions"] end,
  social = function() return L["Social"] end, class = function() return L["Class"] end,
}
local CAT_ICON = { basics = "compass", leveling = "star", combat = "sword", gear = "shield", gold = "bag",
  professions = "hammer", social = "bubble", class = "guides" }

local function buildMentor(page)
  page.tab = "now"
  page.tabs = Skin:CreateTabBar(page, TABS, function(id) page.tab = id; page.scroll:ScrollToTop(); page.refresh() end)
  page.tabs:SetPoint("TOPLEFT", 0, 0)
  page.tabs:SetPoint("TOPRIGHT", 0, 0)
  page.tabs:Select("now", true)
  page.sub = fstr(page, 10, C.textDim)
  page.sub:SetPoint("TOPLEFT", page.tabs, "BOTTOMLEFT", 2, -8)
  page.sub:SetPoint("RIGHT", page, "RIGHT", -170, 0)
  page.sub:SetWordWrap(false)
  -- Sag ust filtre: anahtar cercevesi gorunen rayla ayni boyutta (46x22) ve kart sag kenariyla ayni x'te (-2).
  page.allLevels = Skin:CreateSwitch(page, "", false, safe(function(v) page.showAll = v; page.refresh() end))
  page.allLevels:SetLabelLeft()
  page.allLevels:SetPoint("TOPRIGHT", page.tabs, "BOTTOMRIGHT", -2, -4)
  page.allText = fstr(page, 10, C.textDim, "RIGHT")
  page.allText:SetPoint("RIGHT", page.allLevels, "LEFT", -8, 0)
  page.scroll = Skin:CreateScrollArea(page, 600, 400)
  page.scroll:SetPoint("TOPLEFT", page.tabs, "BOTTOMLEFT", 0, -30)
  page.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
  page.empty = fstr(page, 12, C.textDim, "CENTER")
  page.empty:SetPoint("CENTER")
  page.cards = {}

  local function card(i)
    local c = page.cards[i]
    if c then return c end
    c = panel(page.scroll.content)
    c.icon = icon(c, "compass", 18, C.accent)
    c.icon:SetPoint("TOPLEFT", 14, -12)
    c.dot = icon(c, "disc", 7, C.accent)
    c.dot:SetPoint("TOPLEFT", 6, -6)
    c.dot._skinFixed = nil
    c.title = fstr(c, 13, C.text)
    c.title:SetPoint("TOPLEFT", c, "TOPLEFT", 44, -12)
    c.title:SetPoint("RIGHT", c, "RIGHT", -150, 0)
    c.title:SetWordWrap(false)
    c.text = fstr(c, 11, C.textDim)
    c.text:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -6)
    c.text:SetPoint("RIGHT", c, "RIGHT", -16, 0)
    c.text:SetWordWrap(true)
    c.text:SetJustifyV("TOP")
    c.close = Skin:CreateIconButton(c, "close", 18)
    c.close:SetPoint("TOPRIGHT", c, "TOPRIGHT", -10, -9)
    c.action = Skin:CreateButton(c, "", 110, 22, true)
    c.action:SetPoint("RIGHT", c.close, "LEFT", -8, 0)
    -- Okundu kutusu: kapat dugmesiyle ayni sag ust yuva (-10, -9); sekmeye gore yalniz biri gorunur.
    c.read = Skin:CreateCheckbox(c, "", false, nil)
    c.read:SetPoint("TOPRIGHT", c, "TOPRIGHT", -10, -9)
    page.cards[i] = c
    return c
  end

  local function layoutCard(c, y, minH)
    local w = page.scroll.content:GetWidth()
    if type(w) ~= "number" or w < 100 then w = 760 end
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", page.scroll.content, "TOPLEFT", 0, -y)
    c:SetPoint("TOPRIGHT", page.scroll.content, "TOPRIGHT", -2, -y)
    c.text:SetWidth(w - 62)
    local th = c.text:GetStringHeight()
    if type(th) ~= "number" or th <= 0 then th = 28 end
    local h = math.max(minH or 0, 12 + 16 + 6 + th + 12)
    c:SetHeight(h)
    return y + h + GAP
  end

  local function showAdvice()
    local list = ns.Mentor and ns.Mentor:Advice() or {}
    page.empty:SetText(#list == 0 and L["All good right now. Read the tips on the other tabs."] or "")
    local y = 0
    for i = 1, math.max(#list, #page.cards) do
      local e, c = list[i], card(i)
      if e then
        c:Show()
        c.icon:SetTexture(Skin.Icons[e.icon] or Skin.Icons.compass)
        c.dot:Hide()
        c.title:SetText(e.title or "")
        c.title:SetTextColor(unpack(C.text))   -- havuzdaki kart baska sekmeden soluk renk getirmesin
        c.text:SetText(e.detail or "")
        c.read:Hide()
        c.close:Show()
        c.close:SetScript("OnClick", safe(function() ns.Mentor:Dismiss(e.id); page.refresh() end))
        if e.action then
          c.action:SetText(e.actionText or L["Go"])
          c.action:SetScript("OnClick", safe(function() e.action(); page.refresh() end))
          c.action:Show()
        else
          c.action:Hide()
        end
        y = layoutCard(c, y, 58)
      else
        c:Hide()
      end
    end
    return y
  end

  local function showTips(cat)
    local M = ns.Mentor
    local list = M and M:Tips(cat ~= "all" and cat or nil, page.showAll) or {}
    page.empty:SetText(#list == 0 and L["No tips for your level in this category."] or "")
    local y = 0
    for i = 1, math.max(#list, #page.cards) do
      local t, c = list[i], card(i)
      if t then
        c:Show()
        local isRead = M.char.read[t.id]
        c.icon:SetTexture(Skin.Icons[CAT_ICON[t.cat] or "compass"] or Skin.Icons.compass)
        if isRead then c.dot:Hide() else c.dot:Show() end
        c.title:SetText(ns:LocalizedText(t.title) or t.id)
        c.title:SetTextColor(unpack(isRead and C.textDim or C.text))
        c.text:SetText(ns:LocalizedText(t.text) or "")
        -- yeri bilinen bilgi (t.go[taraf]): ok dugmesi
        local go = t.go and t.go[(ns.Provider.PlayerInfo() or {}).faction or ""]
        if go then
          c.action:SetText(L["Arrow"])
          c.action:SetScript("OnClick", safe(function() M:PointAt(go.zone, go.x, go.y, go.npc) end))
          c.action:Show()
        else
          c.action:Hide()
        end
        c.close:Hide()
        c.read:Show()
        c.read:SetChecked(isRead, true)
        c.read.callback = safe(function(v) M:MarkRead(t.id, v); page.refresh() end)
        c.read:SetTooltip(function() return c.read.checked and L["Mark as unread"] or L["Mark as read"] end)
        y = layoutCard(c, y)
      else
        c:Hide()
      end
    end
    return y
  end

  local ITEM_ICON = { bag = "bag", rest = "star", weapon = "sword", wand = "sword", armor = "shield" }

  -- Kolay esyalar: seviyene/sinifina uyanlar; "All levels" acikken araligi disindakiler ve bitenler de (soluk).
  local function showItems()
    local M = ns.Mentor
    local list = M and M.EasyItems and M:EasyItems(nil, nil, page.showAll) or {}
    page.empty:SetText(#list == 0 and L["No easy items left for your level. Turn on All levels to see the full list."] or "")
    local y = 0
    for i = 1, math.max(#list, #page.cards) do
      local e, c = list[i], card(i)
      if e then
        c:Show()
        local done = M:EasyItemDone(e)
        c.icon:SetTexture(Skin.Icons[ITEM_ICON[e.kind] or "bag"] or Skin.Icons.bag)
        c.dot:Hide()
        c.title:SetText(M:EasyItemTitle(e))
        c.title:SetTextColor(unpack(done and C.textDim or C.text))
        c.text:SetText(M:EasyItemLine(e))
        c.close:Hide()
        local act = M:EasyItemActionText(e)
        if act then
          c.action:SetText(act)
          c.action:SetScript("OnClick", safe(function() M:EasyItemGo(e) end))
          c.action:Show()
        else
          c.action:Hide()
        end
        c.read:Show()
        c.read:SetChecked(M.char.easyDone[e.id] and true or false, true)
        c.read.callback = safe(function(v) M:MarkEasyItem(e.id, v); page.refresh() end)
        c.read:SetTooltip(function() return c.read.checked and L["Suggest it again"] or L["I have it / skip it"] end)
        y = layoutCard(c, y, 58)
      else
        c:Hide()
      end
    end
    return y
  end

  -- Kutuphane kitaplari (Helpers/LibraryBooks.lua): durum, kayitli yer ya da teslim NPC'si, ok
  local BOOK_STATE = {
    done = function() return L["Turned in."] end, log = function() return L["Quest in your log: turn it in."] end,
    bag = function() return L["In your bags: read it to start the quest."] end, missing = function() return L["Not found yet."] end,
  }
  local function showBooks()
    local LB = ns.LibraryBooks
    if not (LB and LB:IsEnabled()) then
      page.empty:SetText(L["Turn on the Library books module in Settings > Modules."])
      for _, c in ipairs(page.cards) do c:Hide() end
      return 0
    end
    local list = LB:Books()
    page.empty:SetText(#list == 0 and L["No library books in the data."] or "")
    local y = 0
    for i = 1, math.max(#list, #page.cards) do
      local b, c = list[i], card(i)
      if b then
        c:Show()
        local st = LB:State(b)
        local spot = LB.db.spots[b.quest]
        c.icon:SetTexture(Skin.Icons.guides)
        c.dot:Hide()
        c.title:SetText(("%s  (%d)"):format(P.QuestName(b.quest, b.name), b.level))
        c.title:SetTextColor(unpack(st == "done" and C.textDim or C.text))
        local lines = { BOOK_STATE[st]() }
        if st ~= "done" then
          lines[#lines + 1] = spot and L["Found at %s (%.1f, %.1f)."]:format(spot.zone or "?", spot.x * 100, spot.y * 100)
            or L["Place not recorded yet: it is saved when you pick the book up."]
          if b.npc then lines[#lines + 1] = L["Turn in to %s, %s."]:format(b.npc, b.zone or "?") end
        end
        c.text:SetText(table.concat(lines, "\n"))
        c.close:Hide()
        c.read:Hide()
        local canGo = st ~= "done" and (spot or ((st == "bag" or st == "log") and b.zone))
        if canGo then
          c.action:SetText(L["Arrow"])
          c.action:SetScript("OnClick", safe(function() LB:PointTo(b) end))
          c.action:Show()
        else
          c.action:Hide()
        end
        y = layoutCard(c, y, 58)
      else
        c:Hide()
      end
    end
    return y
  end

  function page.refresh()
    page.tabs:SetTexts(function(id) return TAB_TEXT[id]() end)
    page.allText:SetText(L["All levels"])
    local M = ns.Mentor
    if page.tab == "now" then
      page.sub:SetText(L["What needs your attention right now."])
      page.allLevels:Hide(); page.allText:Hide()
      page.scroll:SetContentHeight(showAdvice())
    elseif page.tab == "items" then
      page.sub:SetText(L["Easy to get, strong for your level: bags, quest rewards and early weapons."])
      page.allLevels:Show(); page.allText:Show()
      page.scroll:SetContentHeight(showItems())
    elseif page.tab == "books" then
      local LB = ns.LibraryBooks
      local done, total = 0, 0
      if LB and LB:IsEnabled() then done, total = LB:Counts() end
      page.sub:SetText(L["Library books: %d of %d turned in."]:format(done, total))
      page.allLevels:Hide(); page.allText:Hide()
      page.scroll:SetContentHeight(showBooks())
    else
      local unread = M and M:UnreadCount() or 0
      page.sub:SetText(L["Tips for new players, picked for your level and class. Unread: %d"]:format(unread))
      page.allLevels:Show(); page.allText:Show()
      page.scroll:SetContentHeight(showTips(page.tab))
    end
  end
end

Win:RegisterPage({
  id = "mentor", order = 5, icon = "star",
  title = function() return L["Mentor"] end,
  available = function() return ns.Mentor and ns.Mentor:IsEnabled() end,
  build = buildMentor,
})
