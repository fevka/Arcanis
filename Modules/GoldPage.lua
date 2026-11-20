-- Arcanis Path sayfasi: Gold. Bes sekme:
--   Overview      bugun / 7 gun / oturum, altin/saat, kaynak dagilimi, son 14 gunun net grafigi
--   Characters    tum karakterlerin altini, son 7 gunluk net, hesap toplami
--   Farming       seviyene ve mesleklerine gore kasma yerleri, canli fiyatla tahmini altin/saat
--   Auction       cantadakiler: AH'de mi saticida mi satilmali, flip firsatlari (tarama varsa)
--   Professions   mesleklerin, bilinen tariflerin uretim kari ve en karli toplama isleri
-- Veri: Helpers/Gold.lua (kalici defter), Data/Farms.lua, fiyatlar tarama ya da paketteki liste.
local _, ns = ...

local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack
local U = Win.UI
local fstr, panel, safe = U.fstr, U.panel, U.safe
local ROW_H = 38

local GREEN, RED = { 0.40, 0.86, 0.47, 1 }, { 0.93, 0.40, 0.33, 1 }
local SOURCE_NAMES = {
  loot = function() return L["Loot"] end, quest = function() return L["Quests"] end,
  vendor = function() return L["Vendor"] end, ah = function() return L["Auction House"] end,
  mail = function() return L["Mail"] end, trainer = function() return L["Training"] end,
  repair = function() return L["Repairs"] end, taxi = function() return L["Flights"] end,
  other = function() return L["Other"] end,
}
local TABS = {
  { id = "overview", text = "Overview" }, { id = "chars", text = "Characters" }, { id = "farm", text = "Farming" },
  { id = "ah", text = "Auction" }, { id = "prof", text = "Professions" },
}
local TAB_KEYS = {
  overview = function() return L["Overview"] end, chars = function() return L["Characters"] end,
  farm = function() return L["Farming"] end, ah = function() return L["Auction"] end,
  prof = function() return L["Professions"] end,
}

local PROF_NAMES = {
  Mining = function() return L["Mining"] end, Herbalism = function() return L["Herbalism"] end,
  Skinning = function() return L["Skinning"] end, Tailoring = function() return L["Tailoring"] end,
  Leatherworking = function() return L["Leatherworking"] end, Blacksmithing = function() return L["Blacksmithing"] end,
  Alchemy = function() return L["Alchemy"] end, Engineering = function() return L["Engineering"] end,
  Enchanting = function() return L["Enchanting"] end, Jewelcrafting = function() return L["Jewelcrafting"] end,
  Inscription = function() return L["Inscription"] end, Cooking = function() return L["Cooking"] end,
  ["First Aid"] = function() return L["First Aid"] end, Fishing = function() return L["Fishing"] end,
}
local function profName(n) local f = PROF_NAMES[n]; return f and f() or n end

local function money(c) return ns.Suite.FormatMoney(c or 0) end
local function signed(c)
  c = c or 0
  return (c >= 0 and "|cff66dd77+" or "|cffee6655-") .. money(math.abs(c)) .. "|r"
end

local function statCard(parent)
  local c = panel(parent)
  c:SetHeight(64)
  c.title = fstr(c, 11, C.textDim)
  c.title:SetPoint("TOPLEFT", 12, -10)
  c.value = fstr(c, 17, C.text, "LEFT", "OUTLINE")
  c.value:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -6)
  c.sub = fstr(c, 10, C.textDim, "RIGHT")
  c.sub:SetPoint("TOPRIGHT", c, "TOPRIGHT", -12, -10)
  return c
end

-- Genel satir listesi: her satir ikon + baslik + alt satir + sagda deger/alt deger (+ istege bagli cubuk).
local function makeList(host)
  local list = { rows = {} }
  list.scroll = Skin:CreateScrollArea(host, 600, 300)
  list.scroll:SetPoint("TOPLEFT", host, "TOPLEFT", 6, -6)
  list.scroll:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -6, 6)
  list.empty = fstr(host, 11, C.textDim, "CENTER")
  list.empty:SetPoint("CENTER")
  local function row(i)
    local r = list.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, list.scroll.content)
    r:SetHeight(ROW_H - 2)
    r:SetPoint("TOPLEFT", list.scroll.content, "TOPLEFT", 0, -(i - 1) * ROW_H)
    r:SetPoint("TOPRIGHT", list.scroll.content, "TOPRIGHT", 0, -(i - 1) * ROW_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetColorTexture(1, 1, 1, 0.03)
    r.bg._skinFixed = true
    r.bar = r:CreateTexture(nil, "BORDER")
    r.bar:SetPoint("BOTTOMLEFT", 0, 0)
    r.bar:SetHeight(2)
    r.bar._skinFixed = true
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(26, 26)
    r.icon:SetPoint("LEFT", 6, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.title = fstr(r, 12, C.text)
    r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 42, -5)
    r.title:SetPoint("RIGHT", r, "RIGHT", -200, 0)
    r.title:SetWordWrap(false)
    r.sub = fstr(r, 10, C.textDim)
    r.sub:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", 0, -3)
    r.sub:SetPoint("RIGHT", r, "RIGHT", -200, 0)
    r.sub:SetWordWrap(false)
    r.value = fstr(r, 12, C.text, "RIGHT")
    r.value:SetPoint("TOPRIGHT", r, "TOPRIGHT", -10, -5)
    r.value:SetWidth(190)
    r.value2 = fstr(r, 10, C.textDim, "RIGHT")
    r.value2:SetPoint("TOPRIGHT", r.value, "BOTTOMRIGHT", 0, -3)
    r.value2:SetWidth(190)
    r:SetScript("OnEnter", function(x)
      if not GameTooltip then return end
      if x.link then
        GameTooltip:SetOwner(x, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(x.link); GameTooltip:Show()
      elseif x.tip then
        GameTooltip:SetOwner(x, "ANCHOR_RIGHT"); GameTooltip:SetText(x.tipTitle or "", 1, 1, 1)
        GameTooltip:AddLine(x.tip, nil, nil, nil, true); GameTooltip:Show()
      end
    end)
    r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    list.rows[i] = r
    return r
  end
  -- items: { icon, title, sub, value, value2, link, tip, tipTitle, bar = {oran, renk} }
  function list:Set(items, emptyText)
    self.empty:SetText(#items == 0 and (emptyText or "") or "")
    for i = 1, math.max(#items, #self.rows) do
      local e, r = items[i], row(i)
      if e then
        r:Show()
        r.link, r.tip, r.tipTitle = e.link, e.tip, e.tipTitle
        if e.icon then r.icon:SetTexture(e.icon); r.icon:Show() else r.icon:Hide() end
        r.title:ClearAllPoints()
        r.title:SetPoint("TOPLEFT", r, "TOPLEFT", e.icon and 42 or 10, -5)
        r.title:SetPoint("RIGHT", r, "RIGHT", -200, 0)
        r.title:SetText(e.title or "")
        r.sub:SetText(e.sub or "")
        r.value:SetText(e.value or "")
        r.value2:SetText(e.value2 or "")
        if e.bar and e.bar[1] and e.bar[1] > 0 then
          local w = r:GetWidth()
          if type(w) ~= "number" or w < 50 then w = 600 end
          r.bar:SetWidth(math.max(2, w * math.min(1, e.bar[1])))
          local c = e.bar[2] or C.accent
          r.bar:SetColorTexture(c[1], c[2], c[3], 0.8)
          r.bar:Show()
        else
          r.bar:Hide()
        end
      else
        r:Hide()
      end
    end
    self.scroll:SetContentHeight(#items * ROW_H)
  end
  return list
end

local function itemIcon(id) return P.ItemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark" end
local function itemName(id)
  local d = P.ItemDetails and P.ItemDetails(id)
  return d and (d.link or d.name) or ("#" .. id), d and d.link
end

local function buildOverview(view)
  view.cards = { statCard(view), statCard(view), statCard(view), statCard(view) }
  view.chart = panel(view)
  view.chart:SetHeight(110)
  view.chartTitle = fstr(view.chart, 11, C.textDim)
  view.chartTitle:SetPoint("TOPLEFT", 12, -8)
  view.bars = {}
  for i = 1, 14 do
    local b = view.chart:CreateTexture(nil, "ARTWORK")
    b._skinFixed = true
    view.bars[i] = b
  end
  view.base = view.chart:CreateTexture(nil, "BORDER")
  Skin:Fill(view.base, C.border)
  ns.Skin:Hairline(view.base, "h")
  view.listBox = panel(view)
  view.list = makeList(view.listBox)

  function view.layout(w)
    local cw = math.floor((w - 30) / 4)
    for i, c in ipairs(view.cards) do
      c:ClearAllPoints()
      c:SetPoint("TOPLEFT", view, "TOPLEFT", (i - 1) * (cw + 10), 0)
      c:SetWidth(cw)
    end
    view.chart:ClearAllPoints()
    view.chart:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -74)
    view.chart:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, -74)
    view.listBox:ClearAllPoints()
    view.listBox:SetPoint("TOPLEFT", view.chart, "BOTTOMLEFT", 0, -10)
    view.listBox:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    view.chartW = w
  end

  function view.refresh()
    local G = ns.Gold
    local s = G:Summary()
    local _, tIn, tOut = G:Totals(1, nil)
    local by7, wIn, wOut = G:Totals(7, nil)
    local _, total = G:Characters()
    local a, b, c, d = unpack(view.cards)
    a.title:SetText(L["Today (all characters)"]); a.value:SetText(signed(tIn - tOut))
    a.sub:SetText(L["+%s / -%s"]:format(money(tIn), money(tOut)))
    b.title:SetText(L["Last 7 days"]); b.value:SetText(signed(wIn - wOut))
    b.sub:SetText(L["+%s / -%s"]:format(money(wIn), money(wOut)))
    c.title:SetText(L["Gold per hour"]); c.value:SetText(s.rate and money(math.max(0, s.rate)) or "-")
    c.sub:SetText(L["This session"] .. ": " .. signed(s.net))
    d.title:SetText(L["Account gold"]); d.value:SetText(money(total))
    local vendor, market = G:BagValue()
    d.sub:SetText(L["Bags: %s"]:format(money(market or vendor)))

    -- 14 gunluk grafik
    view.chartTitle:SetText(L["Net gold, last 14 days"])
    local days = G:Daily(14)
    local maxAbs = 1
    for _, e in ipairs(days) do maxAbs = math.max(maxAbs, math.abs(e.net)) end
    local w = (view.chartW or 840) - 24
    local bw = math.max(4, math.floor(w / 14) - 4)
    local mid, half = -66, 34
    view.base:ClearAllPoints()
    view.base:SetPoint("TOPLEFT", view.chart, "TOPLEFT", 12, mid)
    view.base:SetPoint("TOPRIGHT", view.chart, "TOPRIGHT", -12, mid)
    for i, e in ipairs(days) do
      local bar = view.bars[i]
      local h = math.max(1, math.floor(math.abs(e.net) / maxAbs * half))
      bar:ClearAllPoints()
      bar:SetSize(bw, h)
      local x = 12 + (i - 1) * (bw + 4)
      if e.net >= 0 then
        bar:SetPoint("BOTTOMLEFT", view.chart, "TOPLEFT", x, mid)
        bar:SetColorTexture(GREEN[1], GREEN[2], GREEN[3], e.net == 0 and 0.15 or 0.85)
      else
        bar:SetPoint("TOPLEFT", view.chart, "TOPLEFT", x, mid)
        bar:SetColorTexture(RED[1], RED[2], RED[3], 0.85)
      end
    end

    -- kaynaklar (7 gun)
    local items, peak = {}, 1
    for _, src in ipairs(G.SOURCES) do
      local e = by7[src]
      if e then peak = math.max(peak, e[1], e[2]) end
    end
    for _, src in ipairs(G.SOURCES) do
      local e = by7[src]
      if e and (e[1] > 0 or e[2] > 0) then
        local net = e[1] - e[2]
        items[#items + 1] = {
          title = SOURCE_NAMES[src](), sub = L["Last 7 days"],
          value = signed(net), value2 = L["+%s / -%s"]:format(money(e[1]), money(e[2])),
          bar = { math.max(e[1], e[2]) / peak, net >= 0 and GREEN or RED },
        }
      end
    end
    view.list:Set(items, L["No gold movements recorded yet. Play a bit and come back."])
  end
end

local function buildChars(view)
  view.box = panel(view)
  view.box:SetAllPoints()
  view.list = makeList(view.box)
  function view.refresh()
    local list, total = ns.Gold:Characters()
    local items = {}
    for _, ch in ipairs(list) do
      local col = ch.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[ch.class]
      local name = col and col.colorStr and ("|c" .. col.colorStr .. ch.name .. "|r") or ch.name
      local seen = ch.seen and date and date("%Y-%m-%d", ch.seen) or ""
      items[#items + 1] = {
        title = name, sub = ch.realm .. (seen ~= "" and ("  -  " .. L["last seen %s"]:format(seen)) or ""),
        value = money(ch.money), value2 = L["7 days: %s"]:format(signed(ch.week)),
        bar = { total > 0 and ch.money / total or 0, C.accent },
      }
    end
    view.list:Set(items, L["No characters yet."])
  end
end

local function buildFarm(view)
  view.box = panel(view)
  view.box:SetAllPoints()
  view.list = makeList(view.box)
  function view.refresh()
    local farms = ns.Gold:Farms()
    local items, top = {}, 1
    for _, f in ipairs(farms) do top = math.max(top, f.gph) end
    for _, f in ipairs(farms) do
      local farm = f.farm
      local tipLines = {}
      for _, p in ipairs(f.parts) do
        tipLines[#tipLines + 1] = ("%s  ~%d/h  x %s"):format(itemName(p.id), p.perHour, money(p.each))
      end
      local status
      if f.fit == "prof" then status = "|cffee6655" .. L["Needs %s %d"]:format(profName(farm.prof[1]), farm.prof[2]) .. "|r"
      elseif f.fit == "level" then status = "|cffaaaaaa" .. L["Level %d+"]:format(farm.min) .. "|r"
      elseif f.fit == "over" then status = "|cffaaaaaa" .. L["Outleveled"] .. "|r"
      else status = "|cff66dd77" .. L["Good for you"] .. "|r" end
      items[#items + 1] = {
        icon = itemIcon(farm.items[1][1]),
        title = ns:LocalizedText(farm.title),
        sub = ("%s  -  %d-%d  -  %s"):format(farm.zone, farm.min, farm.max, status),
        value = L["~%s / hour"]:format(money(f.gph)),
        value2 = L["estimate"],
        tipTitle = ns:LocalizedText(farm.title), tip = ns:LocalizedText(farm.tip) .. "\n\n" .. table.concat(tipLines, "\n"),
        bar = { f.gph / top, f.fit == "ok" and GREEN or C.textOff },
      }
    end
    view.list:Set(items, L["No farm data."])
  end
end

local function buildAH(view)
  view.head = panel(view)
  view.head:SetHeight(44)
  view.head:SetPoint("TOPLEFT"); view.head:SetPoint("TOPRIGHT")
  view.summary = fstr(view.head, 12, C.text)
  view.summary:SetPoint("LEFT", 12, 0)
  view.scan = Skin:CreateButton(view.head, "", 130, 24, true)
  view.scan:SetPoint("RIGHT", -10, 0)
  view.scan:SetScript("OnClick", safe(function() if ns.Prices then ns.Prices:StartScan() end end))
  -- fiyat kaynagi secimi (Ayarlar > Helpers ile ayni ayar)
  local PR0 = ns.Prices
  view.sourceDD = Skin:CreateDropdown(view.head, 170, PR0 and PR0:SourceItems() or {}, PR0 and PR0.db.source or "auto",
    safe(function(v) if ns.Prices then ns.Prices:SetSource(v) end end))
  view.sourceDD:SetPoint("RIGHT", view.scan, "LEFT", -10, 0)
  view.source = fstr(view.head, 10, C.textDim, "RIGHT")
  view.source:SetPoint("RIGHT", view.sourceDD, "LEFT", -10, 0)
  view.box = panel(view)
  view.box:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
  view.box:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
  view.list = makeList(view.box)
  function view.refresh()
    local G = ns.Gold
    local list, ahTotal, vendorTotal = G:SellAdvice()
    view.summary:SetText(L["Sell on AH: %s   Vendor: %s"]:format(money(ahTotal), money(vendorTotal)))
    local PR = ns.Prices
    local active = PR and PR:ActiveSource()
    view.source:SetText(L["Prices: %s - last scan %s"]:format(active and PR:SourceName(active) or L["none"], PR and PR:LastScanText() or "-"))
    view.scan:SetText(L["Arcanis scan"])
    view.scan:SetEnabled(PR and PR:AtAuctionHouse() and not PR.scanning)
    if PR then view.sourceDD:SetItems(PR:SourceItems()); view.sourceDD:SetValue(PR.db.source or "auto", true) end
    local items = {}
    local flips, hasScan = G:Flips()
    for i = 1, math.min(#flips, 10) do
      local fl = flips[i]
      local nm, link = itemName(fl.id)
      items[#items + 1] = { icon = itemIcon(fl.id), title = nm, link = link,
        sub = "|cff66ccff" .. L["Flip: buy under %s, market %s"]:format(money(fl.min), money(fl.median)) .. "|r",
        value = signed(fl.profit), value2 = L["per item"] }
    end
    -- parcalama (Gold:Disenchant): bir karakterin Enchanting'i varsa satirda malzeme ve deger, yoksa tek ipucu satiri
    local enchanter = G:Enchanter()
    local deCount = 0
    for _, e in ipairs(list) do
      if e.action ~= "keep" then
        local act = e.action == "ah" and ("|cff66dd77" .. L["Sell on AH"] .. "|r") or ("|cffaaaaaa" .. L["Vendor it"] .. "|r")
        if e.de then
          deCount = deCount + 1
          if enchanter then
            local names = {}
            for _, m in ipairs(e.de.mats) do
              local d = P.ItemDetails(m.id)
              names[#names + 1] = d and d.name or ("#" .. m.id)
            end
            local worth = e.de.value > 0 and L["Disenchant: about %s"]:format(money(e.de.value * e.count)) or L["Disenchant"]
            local color = e.de.value * e.count > e.best and "66ccff" or "aaaaaa"
            act = act .. ("  |  |cff%s%s|r"):format(color, worth .. " (" .. table.concat(names, ", ") .. ")")
          end
        end
        items[#items + 1] = { icon = itemIcon(e.id), title = (e.link or ("#" .. e.id)) .. (e.count > 1 and ("  x" .. e.count) or ""),
          link = e.link, sub = act,
          value = money(e.best), value2 = L["AH %s / vendor %s"]:format(money(e.market or 0), money(e.vendor or 0)) }
      end
    end
    if deCount > 0 and not enchanter then
      table.insert(items, 1, { title = L["%d items here could be disenchanted"]:format(deCount),
        sub = "|cffaaaaaa" .. L["None of your characters knows Enchanting. An enchanter can turn them into materials."] .. "|r" })
    end
    local empty = hasScan and L["Nothing to sell."] or L["Nothing to sell. Scan the auction house (Arcanis scan) to find flips."]
    view.list:Set(items, empty)
  end
end

local function buildProf(view)
  view.head = panel(view)
  view.head:SetHeight(44)
  view.head:SetPoint("TOPLEFT"); view.head:SetPoint("TOPRIGHT")
  view.skills = fstr(view.head, 12, C.text)
  view.skills:SetPoint("LEFT", 12, 0)
  view.skills:SetPoint("RIGHT", -12, 0)
  view.skills:SetWordWrap(false)
  view.box = panel(view)
  view.box:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
  view.box:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
  view.list = makeList(view.box)
  function view.refresh()
    local profs = P.Professions()
    local parts = {}
    for name, lv in pairs(profs) do parts[#parts + 1] = ("%s |cffffd100%d|r"):format(profName(name), lv) end
    table.sort(parts)
    view.skills:SetText(#parts > 0 and table.concat(parts, "   ")
      or L["No professions learned. Gathering professions are the easiest way to earn gold while leveling."])
    local items, top = {}, 1
    -- meslek kasma: her meslekte beceri puani veren en iyi 3 tarif (elde malzeme varsa once)
    local DIFF = { optimal = { "ff8040", L["sure skill point"] }, medium = { "ffff00", L["likely skill point"] },
      easy = { "40c040", L["small chance"] } }
    -- toplama meslekleri: hangi dugum, hangi bolgede
    for _, g in ipairs(ns.Gold:GatherAdvice(profs)) do
      local sub = g.next and L["Next: %s at %d"]:format(g.next.node, g.next.need) or L["Where your skill still rises."]
      items[#items + 1] = { title = L["Skill up: %s"]:format(profName(g.prof)) .. " |cffffd100" .. g.rank .. "|r", sub = sub }
      if #g.rows == 0 then
        items[#items + 1] = { title = L["Nothing gives skill points yet."], sub = "|cffaaaaaa" .. L["Learn the next rank from a trainer."] .. "|r" }
      end
      for _, r in ipairs(g.rows) do
        local d = DIFF[r.diff]
        local zones = #r.zones > 0 and table.concat(r.zones, ", ") or L["no zone data"]
        local title = r.mobs and L["Beasts level %d-%d"]:format(r.mobs[1], r.mobs[2]) or ("%s (%d)"):format(r.node, r.need)
        items[#items + 1] = { title = title, sub = ("|cff%s%s|r  -  %s"):format(d[1], d[2], zones) }
      end
    end
    for _, s in ipairs(ns.Gold:SkillUps(nil, profs)) do
      local head = s.stale and ("|cffffd100" .. L["Your skill went up: open the %s window again to refresh."]:format(profName(s.prof)) .. "|r")
        or (#s.list == 0 and ("|cffaaaaaa" .. L["No known recipe gives skill points. Learn new ones from a trainer."] .. "|r"))
        or L["Cheapest recipes that still give skill points."]
      items[#items + 1] = { title = L["Skill up: %s"]:format(profName(s.prof)) .. (s.rank and (" |cffffd100" .. s.rank .. "|r") or ""), sub = head }
      for i = 1, math.min(#s.list, 3) do
        local e = s.list[i]
        local nm, link = itemName(e.id)
        local d = DIFF[e.diff]
        local have = e.can > 0 and ("  -  |cff66dd77" .. L["can make %d now"]:format(e.can) .. "|r") or ""
        items[#items + 1] = { icon = itemIcon(e.id), title = nm, link = link,
          sub = ("|cff%s%s|r%s"):format(d[1], d[2], have),
          value = e.perPoint and money(e.perPoint) or "-",
          value2 = e.missing > 0 and L["%d reagent prices missing"]:format(e.missing) or L["per skill point"] }
      end
      -- kasma plani: bir sonraki rutbe sinirina kadar (Gold:SkillUpPlan), ayar Gold.db.skillPlan
      local rank = profs[s.prof]
      local cap = rank and (rank < 75 and 75 or rank < 150 and 150 or rank < 225 and 225 or 300)
      local plan = ns.Gold.db.skillPlan and cap and cap > rank and ns.Gold:SkillUpPlan(s.prof, cap, nil, rank)
      if plan and #plan.steps > 0 then
        local crafts = 0
        for _, st in ipairs(plan.steps) do crafts = crafts + st.crafts end
        items[#items + 1] = { title = L["Plan to skill %d"]:format(plan.to),
          sub = L["%d crafts, including a margin for failed skill-ups. Materials in your bags count as free."]:format(crafts)
            .. (plan.gap > 0 and ("  |cffaaaaaa" .. L["No known recipe for %d points."]:format(plan.gap) .. "|r") or ""),
          value = money(plan.cost), value2 = L["to buy"] }
        for i = 1, math.min(#plan.steps, 6) do
          local st = plan.steps[i]
          local nm, link = itemName(st.id)
          items[#items + 1] = { icon = itemIcon(st.id), title = L["Craft %d %s"]:format(st.crafts, nm), link = link,
            sub = L["skill %d to %d"]:format(st.from, st.to) }
        end
        for i = 1, math.min(#plan.shopping, 8) do
          local b = plan.shopping[i]
          local nm, link = itemName(b.id)
          items[#items + 1] = { icon = itemIcon(b.id), title = L["Buy %d %s"]:format(b.count, nm), link = link,
            sub = b.source == "vendor" and L["from a vendor"] or (b.source == "ah" and L["at the Auction House"] or L["no price known"]),
            value = b.price and money(b.price * b.count) or "-" }
        end
      end
    end
    -- uretim kari: bilinen tarifler (meslek penceresi bir kez acilinca okunur), karli olanlar ustte
    local crafts = ns.Gold:CraftProfits()
    local best = 1
    for _, c in ipairs(crafts) do if c.profit and c.profit > best then best = c.profit end end
    for i = 1, math.min(#crafts, 20) do
      local c = crafts[i]
      local nm, link = itemName(c.id)
      local made = c.made > 1 and ("  x%g"):format(c.made) or ""
      local detail = c.missing > 0 and ("|cffaaaaaa" .. L["%d reagent prices missing"]:format(c.missing) .. "|r")
        or (c.value and L["cost %s, sells %s"]:format(money(c.cost), money(c.value * c.made)))
        or ("|cffaaaaaa" .. L["no price for the product"] .. "|r")
      local skill = (c.diff == "optimal" or c.diff == "medium") and ("  -  |cffff9933" .. L["skill-up"] .. "|r") or ""
      items[#items + 1] = { icon = itemIcon(c.id), title = nm .. made, link = link,
        sub = ("%s  -  %s%s"):format(profName(c.prof), detail, skill),
        value = c.profit and signed(c.profit) or "-", value2 = L["per craft"],
        bar = { c.profit and c.profit > 0 and c.profit / best or 0, GREEN } }
    end
    if #crafts == 0 and next(profs) then
      items[#items + 1] = { title = L["Crafting profit"], sub = L["Open a profession window once so Arcanis can read its recipes."] }
    end
    -- meslege bagli kasma isleri (beceri yeterli olanlar ustte)
    local farms = ns.Gold:Farms(nil, profs)
    for _, f in ipairs(farms) do if f.farm.prof then top = math.max(top, f.gph) end end
    for _, f in ipairs(farms) do
      local farm = f.farm
      if farm.prof then
        local have = profs[farm.prof[1]]
        local need = ("%s %d"):format(profName(farm.prof[1]), farm.prof[2])
        local state = (have and have >= farm.prof[2]) and ("|cff66dd77" .. L["ready"] .. "|r")
          or (have and ("|cffffd100" .. L["skill %d / %d"]:format(have, farm.prof[2]) .. "|r"))
          or ("|cffaaaaaa" .. L["not learned"] .. "|r")
        items[#items + 1] = { icon = itemIcon(farm.items[1][1]), title = ns:LocalizedText(farm.title),
          sub = ("%s  -  %s  -  %s"):format(farm.zone, need, state),
          value = L["~%s / hour"]:format(money(f.gph)), value2 = L["estimate"],
          tipTitle = ns:LocalizedText(farm.title), tip = ns:LocalizedText(farm.tip),
          bar = { f.gph / top, (have and have >= farm.prof[2]) and GREEN or C.textOff } }
      end
    end
    view.list:Set(items, "")
  end
end

local BUILDERS = { overview = buildOverview, chars = buildChars, farm = buildFarm, ah = buildAH, prof = buildProf }

local function buildGold(page)
  page.tab = "overview"
  page.views = {}
  page.tabs = Skin:CreateTabBar(page, TABS, function(id) page.tab = id; page.refresh() end)
  page.tabs:SetPoint("TOPLEFT", 0, 0)
  page.tabs:SetPoint("TOPRIGHT", 0, 0)
  page.tabs:Select("overview", true)
  page.body = CreateFrame("Frame", nil, page)
  page.body:SetPoint("TOPLEFT", page.tabs, "BOTTOMLEFT", 0, -10)
  page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 34)

  page.reset = Skin:CreateButton(page, "", 150, 24)
  page.reset:SetPoint("BOTTOMLEFT", 0, 0)
  page.reset:SetScript("OnClick", safe(function() ns.Gold:Reset(); page.refresh() end))
  page.vault = Skin:CreateButton(page, "", 170, 24)
  page.vault:SetPoint("LEFT", page.reset, "RIGHT", 8, 0)
  page.vault:SetScript("OnClick", safe(function() local v = _G.VaultPanel; if v and v.Show then v:Show() end end))

  local function view(id)
    local v = page.views[id]
    if v then return v end
    v = CreateFrame("Frame", nil, page.body)
    v:SetAllPoints()
    BUILDERS[id](v)
    page.views[id] = v
    return v
  end
  local function width()
    local w = page.body:GetWidth()
    if type(w) ~= "number" or w < 200 then w = 840 end
    return w
  end
  page:SetScript("OnSizeChanged", function()
    local v = page.views[page.tab]
    if v and v.layout then v.layout(width()) end
  end)

  function page.refresh()
    if page.tabs.SetTexts then page.tabs:SetTexts(function(id) return TAB_KEYS[id]() end) end
    page.reset:SetText(L["Reset session"])
    page.vault:SetText(L["Open ArcanisVault"])
    if _G.VaultPanel then page.vault:Show() else page.vault:Hide() end
    for id, v in pairs(page.views) do if id ~= page.tab then v:Hide() end end
    local v = view(page.tab)
    v:Show()
    if v.layout then v.layout(width()) end
    v.refresh()
  end
end

-- Disaridan belirli sekmeyi acmak icin (Mentor): ns.ShowGoldTab("farm")
function ns.ShowGoldTab(id)
  Win:Open("gold")
  local p = Win.pages and Win.pages.gold
  local page = p and (p.tabs and p or p.frame)
  if page and page.tabs then page.tabs:Select(id) end
end

Win:RegisterPage({
  id = "gold", order = 70, icon = "bag",
  title = function() return L["Gold"] end,
  available = function() return ns.Gold and ns.Gold:IsEnabled() end,
  build = buildGold,
})
