-- Arcanis Path sayfasi: Class Codex (sinif rehberi). Sekmeler:
--   Character : uzmanlik (yetenekten ya da elle), zirh plani, stat onceligi (ns.Gear agirliklari), cantadaki yukseltmeler
--   Talents   : build'ler (Data/Codex) - yetenek sirasi + aciklamalar
--   Trainers  : sinif / portal / diger egitmenler, silah becerileri ve ogretildigi yer, yetenek kilometre taslari
--   Quests    : sinif gorevleri (fraksiyon + irk), web linki, ipuclari
--   Pets      : yalniz avci - pet egitmenleri, evcillestirilecek hayvanlar (seviyeye gore), pet aileleri
--   Macros    : sinif makrolari (Data/Macros.lua), tikla -> karakter makrosu olarak kurulur
-- Konumlu satira tiklamak oku oraya cevirir (ns.Nav). Veri: Data/ClassGuide (ns.ClassGuide), Helpers/Gear (ns.Gear).
local _, ns = ...

local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local P = ns.Provider
local unpack = unpack or table.unpack
local U = Win.UI
local fstr, panel, badge, setClassIcon, safe = U.fstr, U.panel, U.badge, U.setClassIcon, U.safe
local OBJECTIVE = U.colors.objective

local ROW_H, ROW_GAP, ACC_H = 36, 2, 32
local GREEN = OBJECTIVE
local BLUE = { 0.35, 0.65, 0.95, 1 }
local RED = { 0.95, 0.42, 0.36, 1 }

local function cleanText(text)
  local out = {}
  for raw in tostring(text or ""):gmatch("[^\r\n]+") do
    local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      line = line:gsub("^%*%s*", "- ")
      out[#out + 1] = line
    end
  end
  return table.concat(out, "\n")
end

local function T(t) return ns.ClassGuide and ns.ClassGuide:Text(t) or (type(t) == "string" and t or "") end
local function coords(x, y) return (x and y) and ("(%.1f, %.1f)"):format(x, y) or nil end
local function join(list, sep)
  local out = {}
  for _, v in ipairs(list or {}) do out[#out + 1] = tostring(v) end
  return table.concat(out, sep or ", ")
end
local function money(copper)
  if not copper then return nil end
  if ns.Suite and ns.Suite.FormatMoney then return ns.Suite.FormatMoney(copper) end
  return ("%dg %ds"):format(math.floor(copper / 10000), math.floor(copper / 100) % 100)
end
local function playerInfo()
  local info = P.PlayerInfo() or {}
  info.level = info.level or P.PlayerLevel() or 1
  return info
end

-- Konumlu bir satiri oka hedef yap. Bolge adi haritaya cozulemezse sessizce gecilir.
local function waypoint(zone, x, y, label)
  if not (ns.Nav and ns.Zones and zone and x and y) then return false end
  local map = ns.Zones:Resolve(zone)
  if not map then
    ns:Print(L["No map for %s yet. Use /wf zonemap to link it."]:format(zone))
    return false
  end
  ns.Nav:SetTarget(map, x / 100, y / 100, label or zone, "codex")
  ns:Print(L["Arrow set: %s"]:format(label or zone))
  return true
end

local function hideTooltip() if GameTooltip then GameTooltip:Hide() end end

-- Ortak satir ve akordeon listesi (DESIGN.md: satir 36, sol serit, ikon 14 / metin 12 px iceride, sag yuva -8)
local function makeRow(parent)
  local r = CreateFrame("Button", nil, parent)
  r:SetHeight(ROW_H)
  r.bg = r:CreateTexture(nil, "BACKGROUND")
  r.bg:SetAllPoints()
  Skin:Fill(r.bg, C.row)
  r.tick = r:CreateTexture(nil, "BORDER")
  r.tick:SetWidth(3)
  r.tick:SetPoint("TOPLEFT"); r.tick:SetPoint("BOTTOMLEFT")
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(24, 24)
  r.icon:SetPoint("LEFT", 12, 0)
  r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  r.icon:Hide()
  r.a = fstr(r, 12, C.text)
  r.a:SetWordWrap(false)
  r.b = fstr(r, 10, C.textDim)
  r.b:SetWordWrap(false)
  r.right = fstr(r, 11, C.textDim, "RIGHT")
  r.right:SetPoint("RIGHT", r, "RIGHT", -12, 0)
  r.web = Skin:CreateIconButton(r, "web", 24)
  r.web:SetPoint("RIGHT", r, "RIGHT", -8, 0)
  r.web:Hide()
  r.web:HookScript("OnEnter", function(b)
    if GameTooltip then GameTooltip:SetOwner(b, "ANCHOR_LEFT"); GameTooltip:SetText(L["Copy Wowhead link"]); GameTooltip:Show() end
  end)
  r.web:HookScript("OnLeave", hideTooltip)
  r.web:SetScript("OnClick", safe(function(b)
    local row = b:GetParent()
    if row.url then Skin:ShowCopyBox(row.urlTitle or "", row.url) end
  end))
  r:SetScript("OnEnter", function(row)
    row.bg:SetVertexColor(unpack(C.rowActive))
    if row.tip and GameTooltip then
      GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
      ns.SafeCall(row.tip, GameTooltip, row)
      GameTooltip:Show()
    end
  end)
  r:SetScript("OnLeave", function(row) row.bg:SetVertexColor(unpack(row.hl and C.rowActive or C.row)); hideTooltip() end)
  r:SetScript("OnClick", safe(function(row) if row.onClick then row.onClick(row) end end))
  function r:Fill(e)
    -- e = { a, b, right, tick, aColor, icon, url, urlTitle, tip, onClick, button, onButton, onIcon, iconTip }
    local hasIcon = e.icon ~= nil
    if hasIcon then self.icon:SetTexture(e.icon); self.icon:Show() else self.icon:Hide() end
    -- tiklanabilir ikon (ornek: makro ikonu secimi)
    if e.onIcon and not self.iconBtn then
      self.iconBtn = CreateFrame("Button", nil, self)
      self.iconBtn:SetAllPoints(self.icon)
      self.iconBtn:SetScript("OnClick", safe(function(b) local row = b:GetParent(); if row.onIcon then row.onIcon(row) end end))
      self.iconBtn:SetScript("OnEnter", function(b)
        local row = b:GetParent()
        if row.iconTip and GameTooltip then GameTooltip:SetOwner(b, "ANCHOR_LEFT"); GameTooltip:SetText(row.iconTip); GameTooltip:Show() end
      end)
      self.iconBtn:SetScript("OnLeave", hideTooltip)
    end
    self.onIcon, self.iconTip = e.onIcon, e.iconTip
    if self.iconBtn then if e.onIcon and hasIcon then self.iconBtn:Show() else self.iconBtn:Hide() end end
    -- satir dugmesi sag kenarda (DESIGN: sag kontrol -8); ornek: makro Install / Uninstall
    if e.button and not self.button then
      self.button = Skin:CreateButton(self, "", 96, 24)
      self.button:SetPoint("RIGHT", self, "RIGHT", -8, 0)
      self.button:SetScript("OnClick", safe(function(b) local row = b:GetParent(); if row.onButton then row.onButton(row) end end))
    end
    self.onButton = e.onButton
    if self.button then
      if e.button then
        self.button:SetText(e.button)
        self.button:Show()
      else
        self.button:Hide()
      end
    end
    -- onay kutusu sag kenarda (ornek: zindan esyasini takip et); e.check = true/false, e.onCheck(row, on)
    local hasCheck = e.check ~= nil
    if hasCheck and not self.check then
      self.check = Skin:CreateCheckbox(self, "", false, function(on) if self.onCheck then self.onCheck(self, on) end end)
      self.check:SetPoint("RIGHT", self, "RIGHT", -8, 0)
    end
    self.onCheck = e.onCheck
    if self.check then
      if hasCheck then self.check:SetChecked(e.check, true); self.check:Show() else self.check:Hide() end
    end
    local slot = (e.button and 104 or 0) + (hasCheck and 26 or 0)
    self.right:ClearAllPoints()
    self.right:SetPoint("RIGHT", self, "RIGHT", -12 - slot, 0)
    local left = hasIcon and 44 or 12
    local rightInset = e.url and 40 or ((e.right and e.right ~= "" and 92 or 12) + slot)
    self.a:ClearAllPoints()
    self.a:SetPoint("TOPLEFT", left, (e.b and e.b ~= "") and -5 or -11)
    self.a:SetPoint("RIGHT", self, "RIGHT", -rightInset, 0)
    self.b:ClearAllPoints()
    self.b:SetPoint("TOPLEFT", left, -20)
    self.b:SetPoint("RIGHT", self, "RIGHT", -rightInset, 0)
    self.a:SetText(e.a or "")
    -- e.hl: vurgulu satir (ornek: bulundugun sehirdeki egitmen) acik zemin ve vurgu renginde ad
    self.hl = e.hl
    self.a:SetTextColor(unpack(e.aColor or (e.hl and C.accent) or C.text))
    self.b:SetText(e.b or "")
    self.right:SetText(e.url and "" or (e.right or ""))
    Skin:Fill(self.tick, e.tick or C.border)
    self.url, self.urlTitle = e.url, e.urlTitle
    if e.url then self.web:Show() else self.web:Hide() end
    self.tip, self.onClick = e.tip, e.onClick
    self.bg:SetVertexColor(unpack(e.hl and C.rowActive or C.row))
  end
  return r
end

-- Kaydirilabilir alanda akordeon gruplari: list:Begin() ; list:Group(key, title, right, tick, entries | text) ; list:End()
local function newAccList(view, defaultOpen)
  local list = { accs = {}, used = 0, open = {} }
  list.scroll = Skin:CreateScrollArea(view, 600, 400)
  list.scroll:SetPoint("TOPLEFT", 0, 0)
  list.scroll:SetPoint("BOTTOMRIGHT", 0, 0)
  local function layout()
    local y = 0
    for i = 1, list.used do
      local acc = list.accs[i]
      acc:ClearAllPoints()
      acc:SetPoint("TOPLEFT", list.scroll.content, "TOPLEFT", 0, -y)
      acc:SetPoint("TOPRIGHT", list.scroll.content, "TOPRIGHT", -2, -y)
      y = y + acc:GetCurrentHeight() + 8
    end
    list.scroll:SetContentHeight(y)
  end
  list.layout = layout
  local function acc(i)
    local a = list.accs[i]
    if a then return a end
    a = Skin:CreateAccordion(list.scroll.content, 600, ACC_H)
    -- hemen listeye sabitlenir: metin yuksekligi gercek genislikte olculsun (layout() yalniz End()'de calisir)
    a:SetPoint("TOPLEFT", list.scroll.content, "TOPLEFT", 0, 0)
    a:SetPoint("TOPRIGHT", list.scroll.content, "TOPRIGHT", -2, 0)
    a.onAnimate = layout
    a.onToggle = function(x) if x.key then list.open[x.key] = x.expanded end; layout() end
    a.rows = {}
    a.text = fstr(a.body, 11, C.text)
    a.text:SetPoint("TOPLEFT", a.body, "TOPLEFT", 14, -8)
    a.text:SetPoint("RIGHT", a.body, "RIGHT", -14, 0)
    a.text:SetJustifyV("TOP")
    a.text:SetWordWrap(true)
    list.accs[i] = a
    return a
  end
  function list:Begin() self.used = 0 end
  -- startClosed: grup ilk gorulusunde kapali (oyuncu acarsa acik kalir)
  function list:Group(key, title, right, tick, entries, startClosed)
    self.used = self.used + 1
    local a = acc(self.used)
    a:Show()
    a:SetTick(tick or C.accent)
    a.a:SetText(title or "")
    a.b:SetText(right or "")
    local h = 0
    if type(entries) == "string" then
      for _, r in ipairs(a.rows) do r:Hide() end
      a.text:SetText(entries); a.text:Show()
      local th = a.text:GetStringHeight()
      if type(th) ~= "number" or th <= 0 then
        local lines = 1
        for _ in entries:gmatch("\n") do lines = lines + 1 end
        th = lines * 14
      end
      h = th + 18
    else
      a.text:SetText(""); a.text:Hide()
      for i, e in ipairs(entries or {}) do
        local r = a.rows[i] or makeRow(a.body)
        a.rows[i] = r
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", a.body, "TOPLEFT", 0, -h)
        r:SetPoint("TOPRIGHT", a.body, "TOPRIGHT", 0, -h)
        r:Fill(e)
        r:Show()
        h = h + ROW_H + ROW_GAP
      end
      for i = #(entries or {}) + 1, #a.rows do a.rows[i]:Hide() end
    end
    a:SetBodyHeight(h)
    if a.key ~= key then
      a.key = key
      if self.open[key] == nil then self.open[key] = (not startClosed) and defaultOpen ~= false end
      a:SetExpanded(self.open[key], true)
    end
  end
  function list:End()
    for i = self.used + 1, #self.accs do self.accs[i]:Hide(); self.accs[i].key = nil end
    layout()
  end
  return list
end

-- ortak: Rehber Tarayicisi (Modules/GuideBrowser.lua) ayni satir ve akordeon listesini kullanir
U.makeRow, U.newAccList = makeRow, newAccList

-- Character: uzmanlik, zirh plani, stat onceligi, yukseltmeler
local STAT_OF = { sp = "spellDamage", heal = "healing", spellcrit = "spellCrit", spellhit = "spellHit", mp5 = "manaRegen" }
local PERCENT = { crit = true, hit = true, spellcrit = true, spellhit = true }
local WEAPON = { mh = true, oh = true, th = true, ranged = true, wand = true }

local function buildCharacter(page, view)
  local G = ns.Gear
  view.head = panel(view)
  view.head:SetPoint("TOPLEFT", 0, 0)
  view.head:SetPoint("TOPRIGHT", 0, 0)
  view.head:SetHeight(58)
  view.classIcon = view.head:CreateTexture(nil, "ARTWORK")
  view.classIcon:SetSize(36, 36)
  view.classIcon:SetPoint("LEFT", 12, 0)
  view.name = fstr(view.head, 14, C.text, "LEFT", "OUTLINE")
  view.name:SetPoint("TOPLEFT", view.classIcon, "TOPRIGHT", 12, -1)
  view.name:SetPoint("RIGHT", view.head, "RIGHT", -212, 0)
  view.name:SetWordWrap(false)
  view.sub = fstr(view.head, 11, C.textDim)
  view.sub:SetPoint("TOPLEFT", view.name, "BOTTOMLEFT", 0, -5)
  view.sub:SetPoint("RIGHT", view.head, "RIGHT", -212, 0)
  view.sub:SetWordWrap(false)
  view.spec = Skin:CreateDropdown(view.head, 188, {}, "auto", safe(function(v)
    if G and G.SetSpecOverride then G:SetSpecOverride(v ~= "auto" and v or nil) end
    page.refresh()
  end))
  view.spec:SetPoint("RIGHT", view.head, "RIGHT", -12, 0)

  view.body = CreateFrame("Frame", nil, view)
  view.body:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
  view.body:SetPoint("BOTTOMRIGHT", 0, 0)
  view.list = newAccList(view.body)

  function view.refresh()
    local info = playerInfo()
    local token, level = info.class, info.level
    setClassIcon(view.classIcon, token)
    local className = (G and G.ClassName and G:ClassName(token)) or token or ""
    if not G then
      view.name:SetText(className)
      view.sub:SetText("")
      view.spec:Hide()
      view.list:Begin(); view.list:End()
      return
    end
    local specId, specName, source = G:GetSpec(token)
    view.name:SetText(specName and (className .. "  -  " .. specName) or className)
    local plan = G:ArmorPlan(token, level)
    local armor = plan and plan.currentLabel and L["Wears %s"]:format(plan.currentLabel) or ""
    if plan and plan.next then armor = armor .. "   |   " .. L["%s from level %d"]:format(plan.next.label or plan.next.type, plan.next.level) end
    view.sub:SetText(armor)
    local items = { { value = "auto", text = L["Spec: from talents"] } }
    for _, s in ipairs(G:Specs(token) or {}) do
      items[#items + 1] = { value = s.id, text = G:SpecName(token, s.id) or tostring(s.name) }
    end
    view.spec.items = items
    view.spec:SetValue(source == "override" and specId or "auto", true)
    view.spec:Show()

    local list = view.list
    list:Begin()

    -- yukseltmeler (cantada, takili olandan iyi)
    local ups = {}
    for _, u in ipairs(G:Upgrades(12) or {}) do
      ups[#ups + 1] = {
        a = u.link or ("#" .. tostring(u.itemId)), icon = u.itemId and P.ItemIcon(u.itemId) or nil,
        b = (u.slotName or "") .. (u.equippedLink and ("  |  " .. L["replaces %s"]:format(u.equippedLink)) or ("  |  " .. L["empty slot"])),
        right = ("+%d"):format(math.floor((u.delta or 0) + 0.5)), tick = GREEN,
        tip = function(tt) if u.link then tt:SetHyperlink(u.link) end end,
      }
    end
    if #ups == 0 then ups[1] = { a = L["No upgrades in your bags right now."], tick = C.border } end
    list:Group("upgrades", L["Upgrades in your bags"], #ups > 0 and ups[1].right and L["%d items"]:format(#ups) or "", GREEN, ups)

    -- zindan yukseltmeleri: seviyene yakin zindanlarin loot'undan her yuva icin en iyisi (Journal:GearUpgrades)
    local J = ns.Journal
    if J and J.GearUpgrades then
      local dun, counts, pending = J:GearUpgrades(level, info, token)
      local rows, top, topN = {}, nil, 0
      -- satira tik: zindan gunlugu o zindanda acilir (esyanin boss'u loot listesinde)
      local function openDungeon(d)
        if ns.DungeonWindow then J.focus = d.id; ns.DungeonWindow:Open() end
      end
      for _, u in ipairs(dun) do
        rows[#rows + 1] = {
          a = u.link or ("#" .. tostring(u.itemId)), icon = P.ItemIcon(u.itemId),
          b = (u.slotName or "") .. "  |  " .. u.dungeon.name .. "  -  " .. (u.boss or "?")
            .. (u.needLevel and ("  |  " .. L["Level %d"]:format(u.needLevel)) or ""),
          right = ("+%d"):format(math.floor(u.delta + 0.5)), tick = u.needLevel and C.textDim or BLUE,
          check = J:IsTracked(u.itemId),
          onCheck = function(_, on) J:Track(u.itemId, on) end,
          onClick = function() openDungeon(u.dungeon) end,
          tip = function(tt)
            if u.link then tt:SetHyperlink(u.link) end
            tt:AddLine(" ")
            tt:AddLine(L["Click: open %s in the Dungeon Guide"]:format(u.dungeon.name), unpack(C.textDim))
            tt:AddLine(L["Box: track this item"], unpack(C.textDim))
          end,
        }
      end
      for id, n in pairs(counts) do
        if n > topN or (n == topN and top and id < top.id) then top, topN = J:Get(id), n end
      end
      if top then
        table.insert(rows, 1, { a = L["Best dungeon: %s"]:format(top.name), b = L["%d upgrades for you"]:format(topN), tick = GREEN,
          onClick = function() openDungeon(top) end })
      end
      if #rows == 0 then rows[1] = { a = pending and L["Loading item data..."] or L["No dungeon upgrades near your level."], tick = C.border } end
      list:Group("dungeonUps", L["Dungeon upgrades"], #dun > 0 and L["%d items"]:format(#dun) or "", BLUE, rows)

      -- gorev odulu yukseltmeleri (ItemNeeds:QuestUpgrades): gunlukteki, rehberde gelecek ve yakindaki gorevler
      local IN = ns.ItemNeeds
      if IN and IN.QuestUpgrades and IN:IsEnabled() and IN.db.questUps ~= false then
        local qups, qpending = IN:QuestUpgrades(level, info, token, 8)
        local qrows = {}
        local SRC = { log = L["in your log"], guide = L["in your guide"], next = L["next guide"], near = L["nearby"] }
        for _, u in ipairs(qups) do
          local canPoint = u.zone and u.x and ns.Mentor and ns.Zones and ns.Zones:Resolve(u.zone)
          qrows[#qrows + 1] = {
            a = u.link or ("#" .. tostring(u.itemId)), icon = P.ItemIcon(u.itemId),
            b = (u.slotName or "") .. "  |  " .. u.name .. "  (" .. (SRC[u.source] or "") .. ")"
              .. (u.needLevel and ("  |  " .. L["Level %d"]:format(u.needLevel)) or ""),
            right = ("+%d"):format(math.floor(u.delta + 0.5)), tick = u.needLevel and C.textDim or GREEN,
            onClick = canPoint and function() ns.Mentor:PointAt(u.zone, u.x, u.y, u.npc or u.name) end or nil,
            tip = function(tt)
              if u.link then tt:SetHyperlink(u.link) end
              tt:AddLine(" ")
              tt:AddLine(L["Reward of: %s"]:format(u.name), 1, 0.82, 0.2)
              if u.npc then tt:AddLine(L["Start: %s"]:format(u.npc .. (u.zone and (", " .. u.zone) or "")), unpack(C.textDim)) end
              if canPoint then tt:AddLine(L["Click: point the arrow to the quest giver"], unpack(C.textDim)) end
            end,
          }
        end
        if #qrows == 0 then
          qrows[1] = { a = qpending and L["Loading item data..."] or L["No known quest reward upgrades. Rewards are learned when you open a quest."], tick = C.border }
        end
        list:Group("questUps", L["Quest reward upgrades"], #qups > 0 and L["%d items"]:format(#qups) or "", GREEN, qrows)
        pending = pending or qpending
      end
      -- esya bilgisi sunucudan gelince bir kez daha ciz
      -- hic yuklenmeyen esya sonsuz yenileme yapmasin: en cok 5 deneme
      if pending and not view.reloadQueued and (view.reloads or 0) < 5 and C_Timer and C_Timer.After then
        view.reloadQueued, view.reloads = true, (view.reloads or 0) + 1
        C_Timer.After(1.5, function() view.reloadQueued = nil; if view:IsShown() then page.refresh() end end)
      end
    end

    -- buyu onerileri (Gear:EnchantOptions): takili yuva basina en iyi stat buyusu; malzeme fiyati varsa toplam
    local CX = ns.Codex
    if CX and CX.db and CX.db.enchants ~= false and G.EnchantOptions then
      local erows = {}
      for _, o in ipairs(G:EnchantOptions(token, specId, level)) do
        local parts = {}
        for k, v in pairs(o.stats) do
          parts[#parts + 1] = k == "wdmg" and L["+%s weapon damage"]:format(v) or ("+%s %s"):format(v, G:StatLabel(k))
        end
        table.sort(parts)
        local cost, priced = 0, true
        for _, m in ipairs(o.mats or {}) do
          local p = ns.Prices and ns.Prices:Get(m[1])
          if p then cost = cost + p * m[2] else priced = false end
        end
        erows[#erows + 1] = {
          a = o.name, icon = P.ItemIcon and o.link and P.ItemIcon(P.ItemIdFromLink(o.link)) or nil,
          b = o.slotName .. "  |  " .. table.concat(parts, ", ") .. "  |  " .. (o.known and L["you know it"] or L["ask an enchanter"]),
          right = ("+%d"):format(math.floor(o.gain + 0.5)), tick = o.known and GREEN or BLUE,
          tip = function(tt)
            tt:SetText(o.name, 1, 0.82, 0.2)
            if o.link then tt:AddLine(L["On: %s"]:format(o.link)) end
            tt:AddLine(L["Materials:"], unpack(C.textDim))
            for _, m in ipairs(o.mats or {}) do
              local d = P.ItemDetails(m[1])
              tt:AddLine(("%dx %s"):format(m[2], d and d.name or ("#" .. m[1])), 1, 1, 1)
            end
            if priced and cost > 0 and ns.Suite then tt:AddLine(L["Materials cost about %s"]:format(ns.Suite.FormatMoney(cost)), unpack(C.textDim)) end
          end,
        }
      end
      if #erows == 0 then erows[1] = { a = L["No better stat enchant for what you wear."], tick = C.border } end
      list:Group("enchants", L["Enchants"], #erows > 0 and erows[1].right and L["%d items"]:format(#erows) or "", BLUE, erows, true)
    end

    -- itibar odulleri (Helpers/RepRewards.lua): satici penceresinden kaydedilenler, taraf basina
    local RR = ns.RepRewards
    if RR and CX and CX.db and CX.db.repRecord ~= false then
      for _, f in ipairs(RR:List()) do
        local rrows = {}
        for _, it in ipairs(f.items) do
          local d = P.ItemDetails(it.id)
          local up = d and d.equipLoc and G:SourceUpgrade(d, token, specId, level, 0)
          rrows[#rrows + 1] = {
            a = d and d.link or ("#" .. it.id), icon = P.ItemIcon(it.id),
            b = (it.standing or "") .. "  |  " .. (it.vendor or "?") .. (it.zone and (", " .. it.zone) or ""),
            right = up and ("+%d"):format(math.floor(up + 0.5)) or "", tick = up and GREEN or C.border,
            tip = function(tt) if d and d.link then tt:SetHyperlink(d.link) end end,
          }
        end
        list:Group("rep:" .. f.faction, f.faction, L["%d items"]:format(#rrows), C.accent, rrows, true)
      end
    end

    -- stat onceligi: agirliklar birime gore (puan / %1 / silah DPS)
    local weights = G:Weights(token, specId, level) or {}
    local stats = G:PlayerStats() or {}
    local groups = { {}, {}, {} }
    for key, w in pairs(weights) do
      if type(w) == "number" and w >= 0.05 and key ~= "shield" then
        local g = WEAPON[key] and 3 or (PERCENT[key] and 2 or 1)
        groups[g][#groups[g] + 1] = { key = key, w = w }
      end
    end
    local rows = {}
    local units = { L["per point"], L["per 1%"], L["per weapon DPS"] }
    for g = 1, 3 do
      table.sort(groups[g], function(x, y) if x.w ~= y.w then return x.w > y.w end return x.key < y.key end)
      for _, e in ipairs(groups[g]) do
        local have = stats[STAT_OF[e.key] or e.key]
        local haveText = type(have) == "number" and (PERCENT[e.key] and ("%.1f%%"):format(have) or tostring(math.floor(have + 0.5))) or nil
        -- isabet siniri: "Sen: %5.2 (sinir %5)" / "(sinirda)"
        local note = G.capNotes and G.capNotes[e.key]
        if haveText and note then
          haveText = haveText .. "  " .. (note.capped and L["(capped)"] or L["(cap %d%%)"]:format(note.cap))
        end
        rows[#rows + 1] = {
          a = G:StatLabel(e.key) or e.key,
          b = haveText and L["You: %s"]:format(haveText) or nil,
          right = ("%.2f %s"):format(e.w, units[g]):gsub("%.?0+ ", " ", 1),
          tick = g == 3 and RED or (g == 2 and BLUE or C.accent),
        }
      end
    end
    -- kaynak: agirliklar her durumda statlarina gore (isabet siniri) duzeltilir
    local custom = G:CustomWeights(specId)
    table.insert(rows, 1, {
      a = custom and L["Weights: SimulationCraft"] or L["Weights: Arcanis, adjusted to your stats"],
      b = custom and L["Imported from SimC. Hit is still adjusted to your stats."] or L["Hit loses its value once you reach the cap."],
      tick = custom and GREEN or C.border,
    })
    list:Group("weights", L["Stat priority"], specName or "", C.accent, rows)

    -- disaridan agirlik: karakter profilini ver, bir stat simulatorunun agirliklarini al, ya da kendi
    -- agirliklarimiza don. Kullanmayan icin kapali grup.
    local ext = {
      { a = L["Export for SimulationCraft"], b = L["Your character as a SimC profile, to paste into SimulationCraft."],
        onClick = function()
          Skin:ShowTextBox(L["SimulationCraft profile"], G:CharacterProfile(), L["Press Ctrl+A, Ctrl+C and paste it into SimulationCraft. Turn on scale factors there."])
        end },
      { a = L["Import SimC weights"], b = L["Paste the Pawn string from SimulationCraft's scale factors."],
        onClick = function()
          Skin:ShowTextBox(L["Import SimC weights"], "", L["Paste the Pawn string, e.g. ( Pawn: v1: \"name\": Class=Warrior, Spec=Arms, Strength=2.1, ... )"], function(text)
            ns:Print(G:ImportMessage(G:ImportWeights(text)))
            page.refresh()
          end)
        end },
    }
    if custom then
      ext[#ext + 1] = { a = L["Use Arcanis weights"], b = L["Forgets the imported SimC weights for this spec."],
        onClick = function() G:ClearCustomWeights(specId); page.refresh() end }
    end
    list:Group("extWeights", L["SimulationCraft"], custom and L["in use"] or "", custom and GREEN or C.border, ext, true)

    -- zirh plani ve silah tercihi
    local guide = ns.ClassGuide and ns.ClassGuide:Get(token)
    if guide then
      local ar = {}
      for _, e in ipairs(ns.ClassGuide:Armor(token)) do
        local now = level >= (e.fromLevel or 1)
        ar[#ar + 1] = { a = e.type, b = e.note and T(e.note) or nil, right = L["Level %d"]:format(e.fromLevel or 1),
          tick = now and GREEN or C.border, aColor = now and C.text or C.textDim }
      end
      list:Group("armor", L["Armor"], plan and plan.currentLabel or "", BLUE, ar)
      if guide.role then list:Group("role", L["About your class"], "", C.accent, T(guide.role)) end
    end
    list:End()
  end
end

-- Talents: build (Data/Codex); kategori acilir listeden
local ORDER_H = 30
local CAT_ITEMS = function()
  local items = { { value = "Leveling", text = L["Leveling"] }, { value = "PVE", text = L["PvE"] }, { value = "PVP", text = L["PvP"] } }
  -- yetenek planlayicisi (Helpers/TalentPlanner.lua, Modules/TalentPlannerView.lua)
  if ns.TalentPlanner and ns.TalentPlanner:IsEnabled() then items[#items + 1] = { value = "Planner", text = L["Planner"] } end
  return items
end

local function buildTalents(page, view)
  view.cat = "Leveling"
  view.head = panel(view)
  view.head:SetPoint("TOPLEFT", 0, 0)
  view.head:SetPoint("TOPRIGHT", 0, 0)
  view.head:SetHeight(58)
  view.classIcon = view.head:CreateTexture(nil, "ARTWORK")
  view.classIcon:SetSize(36, 36)
  view.classIcon:SetPoint("LEFT", 12, 0)
  view.name = fstr(view.head, 14, C.text, "LEFT", "OUTLINE")
  view.name:SetPoint("TOPLEFT", view.classIcon, "TOPRIGHT", 12, -1)
  view.name:SetPoint("RIGHT", view.head, "RIGHT", -340, 0)
  view.name:SetWordWrap(false)
  view.split = fstr(view.head, 11, C.textDim)
  view.split:SetPoint("TOPLEFT", view.name, "BOTTOMLEFT", 0, -5)
  view.catDD = Skin:CreateDropdown(view.head, 140, CAT_ITEMS(), "Leveling", safe(function(v) view.cat = v; page.refresh() end))
  view.catDD:SetPoint("RIGHT", view.head, "RIGHT", -12, 0)
  view.oracle = Skin:CreateButton(view.head, L["Open ArcanisOracle"], 170, 24)
  view.oracle:SetPoint("RIGHT", view.catDD, "LEFT", -8, 0)
  view.oracle:SetScript("OnClick", safe(function()
    local o = _G.OracleAdvisorPanel
    if o and o.Show then o:Show() end
  end))

  view.orderBox = panel(view)
  view.orderBox:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
  view.orderBox:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
  view.orderBox:SetWidth(300)
  view.orderTitle = fstr(view.orderBox, 12, C.accentHover, "LEFT", "OUTLINE")
  view.orderTitle:SetPoint("TOPLEFT", 12, -10)
  view.orderScroll = Skin:CreateScrollArea(view.orderBox, 280, 300)
  view.orderScroll:SetPoint("TOPLEFT", view.orderBox, "TOPLEFT", 6, -32)
  view.orderScroll:SetPoint("BOTTOMRIGHT", view.orderBox, "BOTTOMRIGHT", -6, 6)
  view.orderRows = {}

  view.info = CreateFrame("Frame", nil, view)
  view.info:SetPoint("TOPLEFT", view.orderBox, "TOPRIGHT", 10, 0)
  view.info:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
  view.list = newAccList(view.info, false)   -- yalniz genel bakis ve rotasyon acik gelir
  view.list.open.ROT, view.list.open.DESC = true, true

  view.empty = fstr(view, 12, C.textDim, "CENTER")
  view.empty:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 20, -40)
  view.empty:SetPoint("RIGHT", view, "RIGHT", -20, 0)
  view.empty:SetWordWrap(true)

  local function orderRow(i)
    local r = view.orderRows[i]
    if r then return r end
    r = CreateFrame("Frame", nil, view.orderScroll.content)
    r:SetHeight(ORDER_H - 2)
    r:SetPoint("TOPLEFT", view.orderScroll.content, "TOPLEFT", 0, -(i - 1) * ORDER_H)
    r:SetPoint("TOPRIGHT", view.orderScroll.content, "TOPRIGHT", 0, -(i - 1) * ORDER_H)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetColorTexture(1, 1, 1, 0.03)
    r.badge = badge(r, 20)
    r.badge:SetPoint("LEFT", 4, 0)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20)
    r.icon:SetPoint("LEFT", r.badge, "RIGHT", 8, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.name = fstr(r, 12, C.text)
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.name:SetPoint("RIGHT", r, "RIGHT", -54, 0)
    r.name:SetWordWrap(false)
    r.rank = fstr(r, 11, C.textDim, "RIGHT")
    r.rank:SetPoint("RIGHT", r, "RIGHT", -8, 0)
    view.orderRows[i] = r
    return r
  end

  local SECTIONS = {
    { key = "DESC", title = function() return L["Overview"] end, color = C.accent },
    { key = "ROT", title = function() return L["Rotation and stats"] end, color = BLUE },
    { key = "PROS", title = function() return L["Strengths"] end, color = GREEN },
    { key = "CONS", title = function() return L["Weaknesses"] end, color = RED },
  }

  function view.refresh()
    view.orderTitle:SetText(L["Talent order"])
    view.oracle:SetText(L["Open ArcanisOracle"])
    if _G.OracleAdvisorPanel then view.oracle:Show() else view.oracle:Hide() end
    local TP = ns.TalentPlanner
    if view.cat == "Planner" and not (TP and TP:IsEnabled()) then view.cat = "Leveling" end
    view.catDD.items = CAT_ITEMS()
    view.catDD:SetValue(view.cat, true)
    if view.cat == "Planner" then
      if not view.planner then
        view.planner = TP.BuildView(view)
        view.planner:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
        view.planner:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
      end
      for _, f in ipairs({ view.orderBox, view.info, view.empty }) do f:Hide() end
      setClassIcon(view.classIcon, P.PlayerClassToken())
      view.name:SetText(L["Talent planner"])
      view.split:SetText(L["Plan your talents point by point."])
      view.planner:Show()
      view.planner.refresh()
      return
    end
    if view.planner then view.planner:Hide() end
    local B = ns.Build
    local list = (B and B:Available()) and B:ListFor(view.cat) or {}
    local build = list[1]
    local token = P.PlayerClassToken()
    setClassIcon(view.classIcon, token)
    local show = build ~= nil
    for _, f in ipairs({ view.orderBox, view.info }) do if show then f:Show() else f:Hide() end end
    if not show then
      view.name:SetText((ns.Gear and ns.Gear:ClassName(token)) or token or "")
      view.split:SetText("")
      view.empty:SetText(L["The codex has no build of this kind for your class yet."])
      view.empty:Show()
      return
    end
    view.empty:Hide()
    view.name:SetText(build.shortname or "?")
    view.split:SetText(L["Talent points: %s"]:format(("%d / %d / %d"):format(build.tree1 or 0, build.tree2 or 0, build.tree3 or 0)))

    local order = B:Order(build)
    for i = 1, math.max(#order, #view.orderRows) do
      local e, r = order[i], orderRow(i)
      if e then
        r:Show()
        local col = e.state == "done" and OBJECTIVE or (e.state == "next" and C.accent or C.textDim)
        r.badge:Set(tostring(i), col)
        local tex = e.icon or P.SpellIcon(e.name)
        r.name:ClearAllPoints()
        if tex then
          r.icon:SetTexture(tex); r.icon:Show()
          r.icon:SetDesaturated(e.state ~= "done" and e.state ~= "next" and e.state ~= "partial")
          r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
        else
          r.icon:Hide()
          r.name:SetPoint("LEFT", r.badge, "RIGHT", 10, 0)
        end
        r.name:SetPoint("RIGHT", r, "RIGHT", -54, 0)
        r.name:SetText(e.name)
        r.name:SetTextColor(unpack(e.state == "next" and C.accentHover or (e.state == "done" and C.textDim or C.text)))
        r.rank:SetText(e.max > 0 and ("%d/%d"):format(e.rank, e.max) or "")
        r.bg:SetColorTexture(1, 1, 1, e.state == "next" and 0.08 or 0.03)
      else
        r:Hide()
      end
    end
    view.orderScroll:SetContentHeight(#order * ORDER_H)

    view.list:Begin()
    for _, sec in ipairs(SECTIONS) do
      local text = build[sec.key] and cleanText(build[sec.key]) or ""
      if text ~= "" then view.list:Group(sec.key, sec.title(), "", sec.color, text) end
    end
    view.list:End()
  end
end

-- Trainers: egitmenler, silah becerileri, yetenek kilometre taslari
local function trainerRow(t, here)
  local where = join({ t.zone, t.mapHint }, " - ")
  local c = coords(t.x, t.y)
  return {
    a = t.npc .. (t.verify and "  *" or ""),
    b = where .. (c and ("  " .. c) or ""),
    tick = C.accent,
    hl = here ~= nil and t.zone == here,
    tip = function(tt)
      tt:SetText(t.npc, 1, 0.82, 0.2)
      tt:AddLine(where, 1, 1, 1, true)
      if t.note then tt:AddLine(T(t.note), 0.8, 0.8, 0.8, true) end
      if t.verify then tt:AddLine(L["Location not verified in WoW Forever yet."], 0.95, 0.6, 0.3, true) end
      if c then tt:AddLine(L["Click to point the arrow here."], 0.6, 0.6, 0.6) end
    end,
    onClick = c and function() waypoint(t.zone, t.x, t.y, t.npc) end or nil,
  }
end

local function buildTrainers(page, view)
  view.list = newAccList(view)
  function view.refresh()
    local CG = ns.ClassGuide
    local info = playerInfo()
    local list = view.list
    list:Begin()
    if not (CG and CG:Get(info.class)) then
      list:Group("none", L["Class guide"], "", C.border, L["No class guide data for your class yet."])
      list:End()
      return
    end
    local Tr = ns.Training
    -- siradaki egitmen seviyesi (egitmen penceresinden ya da istemci tablolarindan, Helpers/Training.lua)
    local nextLv, nextSpells
    if Tr then nextLv, nextSpells = Tr:NextLevel(info.class, info.level) end
    if nextLv then
      local rows = {}
      for _, s in ipairs(nextSpells) do
        local right = s.rank and L["Rank %d"]:format(s.rank) or ""
        if s.cost then right = right .. "  " .. money(s.cost) end
        rows[#rows + 1] = { a = s.name, right = right, tick = C.accent }
      end
      list:Group("nextspells", L["Next at level %d"]:format(nextLv), L["%d spells"]:format(#rows), C.accent, rows)
    end
    -- aksiyon cubugunda dusuk rutbe: tikla = bu rutbeyi tut / birak; son satir hepsini cevirir
    local low = Tr and Tr.db.lowRank and Tr:LowRanks(true) or {}
    if #low > 0 then
      local rows = {}
      for _, e in ipairs(low) do
        rows[#rows + 1] = {
          a = L["%s: rank %d on your bar, rank %d known"]:format(e.name, e.rank, e.bestRank),
          right = e.kept and L["kept"] or nil,
          tick = e.kept and C.border or C.accent, aColor = e.kept and C.textDim or C.text,
          tip = function(tt)
            tt:SetText(e.name, 1, 0.82, 0.2)
            tt:AddLine(e.kept and L["Click to update this spell again."] or L["Click to keep this rank on purpose (for example a cheap downrank)."], 0.8, 0.8, 0.8, true)
          end,
          onClick = function() Tr:SetKeep(e.id, not e.kept); view.refresh() end,
        }
      end
      rows[#rows + 1] = { a = L["Update all"], b = L["Out of combat only. Kept ranks stay."], tick = GREEN,
        onClick = function() Tr:UpdateRanks(); view.refresh() end }
      list:Group("lowrank", L["Low ranks on your bars"], L["%d spells"]:format(#low), C.accent, rows)
    end
    local here = ns.Provider.ZoneText()   -- bulundugun bolge / sehir: oradaki egitmenler vurgulu
    local byKind = { class = {}, portal = {}, other = {} }
    for _, t in ipairs(CG:Trainers(info.class, info.faction)) do
      local k = (t.kind == "portal" or t.kind == "other") and t.kind or (t.kind == "pet" and "pet" or "class")
      if k ~= "pet" then
        local keep = not t.races or (function() for _, r in ipairs(t.races) do if r == info.race then return true end end return false end)()
        if keep then byKind[k][#byKind[k] + 1] = trainerRow(t, here) end
      end
    end
    list:Group("trainers", L["Class trainers"], L["%d places"]:format(#byKind.class), C.accent, byKind.class)

    -- silah becerileri
    local weapons = {}
    for _, w in ipairs(CG:Weapons(info.class, info.faction)) do
      local known = w.startsKnownBy == "all"
      if type(w.startsKnownBy) == "table" then
        for _, r in ipairs(w.startsKnownBy) do if r == info.race then known = true end end
      end
      local at = w.learnAt and w.learnAt[1]
      local b
      if known then
        b = L["Known from the start"]
      elseif at then
        b = ("%s, %s%s"):format(at.npc, at.city, coords(at.x, at.y) and ("  " .. coords(at.x, at.y)) or "")
      else
        b = L["Learned from a weapon master"]
      end
      weapons[#weapons + 1] = {
        a = w.skill, b = b,
        right = (not known and at) and (money(at.cost) or "") .. ((at.minLevel and at.minLevel > 1) and ("  " .. L["Level %d"]:format(at.minLevel)) or "") or nil,
        tick = known and GREEN or BLUE,
        hl = not known and at ~= nil and here ~= nil and at.city == here,
        tip = function(tt)
          tt:SetText(w.skill, 1, 0.82, 0.2)
          if w.note then tt:AddLine(T(w.note), 1, 1, 1, true) end
          for _, m in ipairs(w.learnAt or {}) do
            tt:AddLine(("%s - %s %s"):format(m.npc, m.city, coords(m.x, m.y) or ""), 0.8, 0.8, 0.8, true)
          end
          if at and not known then tt:AddLine(L["Click to point the arrow here."], 0.6, 0.6, 0.6) end
        end,
        onClick = (at and not known) and function() waypoint(at.city, at.x, at.y, at.npc) end or nil,
      }
    end
    list:Group("weapons", L["Weapon skills"], L["%d skills"]:format(#weapons), BLUE, weapons)

    -- yetenek kilometre taslari: gecmis yesil, siradaki vurgu, sonrakiler soluk
    local miles, nextMarked = {}, false
    for _, m in ipairs(CG:Milestones(info.class)) do
      local past = (m.level or 1) <= info.level
      local isNext = not past and not nextMarked
      if isNext then nextMarked = true end
      miles[#miles + 1] = {
        a = L["Level %d"]:format(m.level or 1) .. "  " .. join(m.spells) .. (m.quest and ("  (" .. L["quest"] .. ")") or ""),
        b = m.note and T(m.note) or nil,
        tick = past and GREEN or (isNext and C.accent or C.border),
        aColor = past and C.textDim or (isNext and C.accentHover or C.text),
      }
    end
    list:Group("milestones", L["Ability milestones"], L["Level %d"]:format(info.level), C.accent, miles)
    if #byKind.portal > 0 then list:Group("portal", L["Portal trainers"], "", BLUE, byKind.portal) end
    if #byKind.other > 0 then list:Group("other", L["Other trainers"], "", C.border, byKind.other) end
    list:End()
  end
end

-- Spells: hangi seviyede hangi buyu/rutbe; sinif egitmeninin penceresinden okunur (Helpers/Training.lua).
-- Gecmis seviyeler yesil, siradaki ve simdiki acik.
local function buildSpells(page, view)
  view.list = newAccList(view, false)
  function view.refresh()
    local CG = ns.ClassGuide
    local info = playerInfo()
    local list = view.list
    list:Begin()
    if not (CG and CG.HasSpellData and CG:HasSpellData(info.class)) then
      list:Group("none", L["Spells"], "", C.border, L["Open your class trainer once: the spell list is read from the trainer window."])
      list:End()
      return
    end
    local byLevel, levels = {}, {}
    for _, s in ipairs(CG:Spells(info.class)) do
      local rows = byLevel[s.level]
      if not rows then rows = {}; byLevel[s.level] = rows; levels[#levels + 1] = s.level end
      local right = s.rank and L["Rank %d"]:format(s.rank) or nil
      if s.cost then right = (right and (right .. "  ") or "") .. money(s.cost) end
      rows[#rows + 1] = { a = s.name, right = right }
    end
    local nextLv
    for _, lv in ipairs(levels) do if lv > info.level then nextLv = lv break end end
    for _, lv in ipairs(levels) do
      local past, isNext = lv <= info.level, lv == nextLv
      local key = "lv" .. lv
      if list.open[key] == nil and (isNext or lv == info.level) then list.open[key] = true end
      local tick = past and GREEN or (isNext and C.accent or C.border)
      for _, r in ipairs(byLevel[lv]) do
        r.tick = r.tick or tick
        r.aColor = past and C.textDim or (isNext and C.accentHover or C.text)
      end
      list:Group(key, L["Level %d"]:format(lv) .. (isNext and ("  " .. L["(next)"]) or ""),
        L["%d spells"]:format(#byLevel[lv]), tick, byLevel[lv])
    end
    list:Group("source", L["Source"], "", C.border, ns.Training:Source(info.class) == "client"
      and L["From the game client's own tables. After your first class trainer visit the trainer's own list (with costs) replaces it."]
      or L["Read from your class trainer (%s). Visit a trainer again after a patch to refresh it."]:format(ns.Training:LastRead(info.class) or "?"))
    list:End()
  end
end

-- Quests: sinif gorevleri + ipuclari
local function buildQuests(page, view)
  view.list = newAccList(view)
  function view.refresh()
    local CG = ns.ClassGuide
    local info = playerInfo()
    local list = view.list
    list:Begin()
    if not (CG and CG:Get(info.class)) then
      list:Group("none", L["Class guide"], "", C.border, L["No class guide data for your class yet."])
      list:End()
      return
    end
    local rows, done = {}, 0
    for _, q in ipairs(CG:Quests(info.class, info.faction, nil, info.race)) do
      local finished = q.id and P.IsQuestFlaggedCompleted(q.id) or false
      if finished then done = done + 1 end
      local ready = not finished and (q.level or 1) <= info.level
      local c = coords(q.x, q.y)
      local giver = join({ q.giver, q.zone }, ", ")
      rows[#rows + 1] = {
        a = ("[%d] %s"):format(q.level or 1, q.name) .. (finished and ("  (" .. L["done"] .. ")") or "") .. (q.verify and "  *" or ""),
        b = giver .. (c and ("  " .. c) or ""),
        tick = finished and GREEN or (ready and C.accent or C.border),
        aColor = finished and GREEN or (ready and C.text or C.textDim),
        url = q.id and ns.Journal and ns.Journal:QuestURL(q.id) or nil, urlTitle = q.name,
        tip = function(tt)
          tt:SetText(q.name, 1, 0.82, 0.2)
          tt:AddLine(L["Level %d"]:format(q.level or 1), 1, 1, 1)
          if q.giver then tt:AddLine(L["Start: %s"]:format(giver), 0.8, 0.8, 0.8, true) end
          if q.turnIn then tt:AddLine(L["Turn in: %s"]:format(q.turnIn), 0.8, 0.8, 0.8, true) end
          if q.chain and #q.chain > 0 then tt:AddLine(L["Chain: %s"]:format(join(q.chain, " > ")), 0.8, 0.8, 0.8, true) end
          if q.note then tt:AddLine(T(q.note), 1, 1, 1, true) end
          if q.reward then tt:AddLine(L["Reward: %s"]:format(T(q.reward)), 0.4, 0.85, 0.5, true) end
          if q.verify then tt:AddLine(L["Location not verified in WoW Forever yet."], 0.95, 0.6, 0.3, true) end
          if c then tt:AddLine(L["Click to point the arrow here."], 0.6, 0.6, 0.6) end
        end,
        onClick = c and function() waypoint(q.zone, q.x, q.y, q.name) end or nil,
      }
    end
    if #rows == 0 then rows[1] = { a = L["No class quests for your faction."], tick = C.border } end
    list:Group("quests", L["Class quests"], L["%d / %d done"]:format(done, #rows), C.accent, rows)
    local tips = {}
    for _, t in ipairs(CG:Tips(info.class)) do tips[#tips + 1] = "- " .. T(t) end
    if #tips > 0 then list:Group("tips", L["Tips"], "", BLUE, table.concat(tips, "\n")) end
    list:End()
  end
end

-- Pets (avci): pet egitmenleri, evcillestirilecek hayvanlar, aileler
local function buildPets(page, view)
  view.list = newAccList(view)
  function view.refresh()
    local CG = ns.ClassGuide
    local info = playerInfo()
    local list = view.list
    list:Begin()
    if not CG then list:End() return end
    local beasts = {}
    for _, p in ipairs(CG:Pets(nil, info.faction)) do
      local now = (p.minLevel or 1) <= info.level and info.level <= (p.maxLevel or 60) + 5
      local later = (p.minLevel or 1) > info.level
      local c = coords(p.x, p.y)
      beasts[#beasts + 1] = {
        a = p.name .. "  (" .. p.family .. ")" .. (p.rare and ("  " .. L["rare"]) or "") .. (p.verify and "  *" or ""),
        b = join({ p.zone, c }, "  ") .. ((p.learn and #p.learn > 0) and ("  |  " .. L["Teaches: %s"]:format(join(p.learn))) or ""),
        right = ("%d-%d"):format(p.minLevel or 1, p.maxLevel or p.minLevel or 1),
        tick = now and C.accent or (later and C.border or GREEN),
        aColor = later and C.textDim or C.text,
        tip = function(tt)
          tt:SetText(p.name, 1, 0.82, 0.2)
          tt:AddLine(("%s  |  %s %d-%d"):format(p.family, L["Level"], p.minLevel or 1, p.maxLevel or 1), 1, 1, 1)
          if p.learn and #p.learn > 0 then tt:AddLine(L["Teaches: %s"]:format(join(p.learn)), 0.4, 0.85, 0.5, true) end
          if p.note then tt:AddLine(T(p.note), 0.8, 0.8, 0.8, true) end
          if p.verify then tt:AddLine(L["Location not verified in WoW Forever yet."], 0.95, 0.6, 0.3, true) end
          if c then tt:AddLine(L["Click to point the arrow here."], 0.6, 0.6, 0.6) end
        end,
        onClick = c and function() waypoint(p.zone, p.x, p.y, p.name) end or nil,
      }
    end
    list:Group("beasts", L["Beasts to tame"], L["Level %d"]:format(info.level), C.accent, beasts)
    local trainers = {}
    for _, t in ipairs(CG:Trainers(info.class, info.faction, "pet")) do trainers[#trainers + 1] = trainerRow(t) end
    if #trainers > 0 then list:Group("pettrainers", L["Pet trainers"], "", BLUE, trainers) end
    local fams = {}
    for _, f in ipairs(CG:PetFamilies()) do
      fams[#fams + 1] = {
        a = f.family .. (f.verify and "  *" or ""), b = L["Diet: %s"]:format(join(f.diet)), right = nil, tick = BLUE,
        tip = function(tt)
          tt:SetText(f.family, 1, 0.82, 0.2)
          if f.strengths then tt:AddLine(T(f.strengths), 1, 1, 1, true) end
          if f.abilities and #f.abilities > 0 then tt:AddLine(L["Abilities: %s"]:format(join(f.abilities)), 0.4, 0.85, 0.5, true) end
          tt:AddLine(L["Diet: %s"]:format(join(f.diet)), 0.8, 0.8, 0.8, true)
          if f.verify then tt:AddLine(L["Abilities not verified in WoW Forever yet."], 0.95, 0.6, 0.3, true) end
        end,
      }
    end
    if #fams > 0 then list:Group("families", L["Pet families"], L["%d families"]:format(#fams), BLUE, fams) end
    list:End()
  end
end

-- Macros: sinif makrolari (Data/Macros.lua, ns.Keys:ClassMacros); satirdaki Install / Uninstall dugmesi
local function iconPath(t)
  if type(t) == "string" and not t:find("\\", 1, true) then return "Interface\\Icons\\" .. t end
  return t
end

-- Makro editoru: secimlerden makro kurar (Keys.BuildMacro); canli onizleme ve karakter sayaci.
local ED_LABEL_W, ED_ROW = 108, 32
local function report(ok, why)
  if ok then return end
  local msg = (why == "combat" and L["Not possible in combat."]) or (why == "name" and L["Give the macro a name (up to 16 letters)."])
    or (why == "empty" and L["Pick a spell or an item first."]) or (why == "long" and L["The macro is longer than 255 characters."])
    or L["No free macro slots."]
  ns:Print(msg)
end

local function buildEditor(view)
  local K = ns.Keys
  local ed = panel(view)
  ed:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
  ed:SetPoint("BOTTOMRIGHT", 0, 0)
  ed:Hide()
  view.editor = ed
  local spec, y = {}, -12
  local labels = {}
  local function row(key)
    local lb = fstr(ed, 11, C.textDim)
    lb:SetPoint("TOPLEFT", 12, y - 6)
    labels[#labels + 1] = { fs = lb, text = key }
    local x, top = 12 + ED_LABEL_W, y
    y = y - ED_ROW
    return x, top
  end
  local function update()
    local body = K.BuildMacro(spec)
    ed.preview:SetText(body ~= "" and body or "-")
    local n = #body
    ed.count:SetText(("%d / %d"):format(n, K.MACRO_MAX))
    ed.count:SetTextColor(unpack(n > K.MACRO_MAX and RED or C.textDim))
    local icon = K:CustomMacro(spec).icons[1]
    ed.icon:SetTexture(iconPath(icon))
  end
  local function edit(width, field, x, top)
    local box = Skin:CreateEditBox(ed, width, 24, function(text, user) if user then spec[field] = text; update() end end)
    box:SetPoint("TOPLEFT", x, top)
    return box
  end
  local function drop(width, field, items, x, top)
    local dd = Skin:CreateDropdown(ed, width, items(), "", function(v) spec[field] = v; update() end)
    dd:SetPoint("TOPLEFT", x, top)
    dd.make = items
    return dd
  end

  local x, top = row(function() return L["Name"] end)
  ed.name = edit(160, "name", x, top)
  ed.name:SetMaxLetters(K.NAME_MAX)
  x, top = row(function() return L["Action"] end)
  ed.action = drop(130, "action", function() return { { value = "cast", text = L["Cast a spell"] }, { value = "use", text = L["Use an item"] } } end, x, top)
  ed.spell = edit(180, "spell", x + 138, top)
  ed.icon = ed:CreateTexture(nil, "ARTWORK")
  ed.icon:SetSize(24, 24)
  ed.icon:SetPoint("LEFT", ed.spell, "RIGHT", 8, 0)
  x, top = row(function() return L["Target"] end)
  ed.target = drop(200, "target", function() return {
    { value = "", text = L["Your target"] }, { value = "mouseover", text = L["Under the mouse, else your target"] },
    { value = "focus", text = L["Your focus, else your target"] }, { value = "player", text = L["Yourself"] },
    { value = "cursor", text = L["Where the cursor is"] } } end, x, top)
  x, top = row(function() return L["Only on"] end)
  ed.check = drop(200, "check", function() return {
    { value = "", text = L["Anyone"] }, { value = "harm", text = L["Enemies"] }, { value = "help", text = L["Friends"] } } end, x, top)
  x, top = row(function() return L["With a key held"] end)
  ed.mod = drop(100, "mod", function() return {
    { value = "", text = L["None"] }, { value = "shift", text = "Shift" }, { value = "ctrl", text = "Ctrl" }, { value = "alt", text = "Alt" } } end, x, top)
  ed.modSpell = edit(210, "modSpell", x + 108, top)
  ed.flags = {}
  local FLAGS = { { "tooltip", function() return L["Show the spell's tooltip"] end }, { "stopcasting", function() return L["Stop casting first"] end },
    { "startattack", function() return L["Start attacking"] end }, { "nodead", function() return L["Skip dead targets"] end } }
  for i, f in ipairs(FLAGS) do
    local cb = Skin:CreateCheckbox(ed, "", false, function(on) spec[f[1]] = on or nil; update() end)
    cb:SetPoint("TOPLEFT", 12 + ((i - 1) % 2) * 220, y - math.floor((i - 1) / 2) * 26)
    cb.textFn = f[2]
    ed.flags[f[1]] = cb
  end
  y = y - 2 * 26 - 8
  ed.box = panel(ed)
  ed.box:SetPoint("TOPLEFT", 12, y)
  ed.box:SetPoint("RIGHT", ed, "RIGHT", -12, 0)
  ed.box:SetHeight(84)
  ed.preview = fstr(ed.box, 11, BLUE)
  ed.preview:SetPoint("TOPLEFT", 8, -8)
  ed.preview:SetPoint("RIGHT", ed.box, "RIGHT", -8, 0)
  ed.preview:SetJustifyV("TOP")
  ed.preview:SetWordWrap(true)
  ed.count = fstr(ed, 10, C.textDim)
  ed.count:SetPoint("TOPRIGHT", ed.box, "BOTTOMRIGHT", 0, -4)

  ed.save = Skin:CreateButton(ed, "", 140, 24, true)
  ed.save:SetPoint("BOTTOMLEFT", 12, 12)
  ed.save:SetScript("OnClick", safe(function()
    local ok, why = K:SaveCustom(spec, ed.oldName)
    report(ok, why)
    if ok then ns:Print(L["%s added. Drag it to a bar from the macro window (/macro)."]:format(spec.name)); view.close() end
  end))
  ed.delete = Skin:CreateButton(ed, "", 100, 24)
  ed.delete:SetPoint("LEFT", ed.save, "RIGHT", 8, 0)
  ed.delete:SetScript("OnClick", safe(function()
    if ed.oldName then report(K:DeleteCustom(ed.oldName)) end
    view.close()
  end))
  ed.back = Skin:CreateButton(ed, "", 100, 24)
  ed.back:SetPoint("BOTTOMRIGHT", -12, 12)
  ed.back:SetScript("OnClick", safe(function() view.close() end))

  -- s: duzenlenecek kayit (yoksa yeni makro)
  function ed.open(s)
    spec = {}
    for k, v in pairs(s or { action = "cast", tooltip = true }) do spec[k] = v end
    ed.oldName = s and s.name or nil
    for _, l in ipairs(labels) do l.fs:SetText(l.text()) end
    for _, dd in ipairs({ ed.action, ed.target, ed.check, ed.mod }) do dd:SetItems(dd.make()) end
    ed.name:SetText(spec.name or ""); ed.spell:SetText(spec.spell or ""); ed.modSpell:SetText(spec.modSpell or "")
    ed.action:SetValue(spec.action or "cast", true); ed.target:SetValue(spec.target or "", true)
    ed.check:SetValue(spec.check or "", true); ed.mod:SetValue(spec.mod or "", true)
    for key, cb in pairs(ed.flags) do cb:SetText(cb.textFn()); cb:SetChecked(spec[key] and true or false, true) end
    ed.save:SetText(L["Save and install"]); ed.delete:SetText(L["Delete"]); ed.back:SetText(L["Back"])
    if ed.oldName then ed.delete:Show() else ed.delete:Hide() end
    update()
    ed:Show()
  end
  return ed
end

local function buildMacros(page, view)
  -- ust serit: aciklama (hicbir makro kendiliginden kurulmaz; her satirda Install / Uninstall) + yeni makro
  view.head = panel(view)
  view.head:SetPoint("TOPLEFT", 0, 0)
  view.head:SetPoint("TOPRIGHT", 0, 0)
  view.head:SetHeight(44)
  view.new = Skin:CreateButton(view.head, "", 120, 24, true)
  view.new:SetPoint("RIGHT", view.head, "RIGHT", -10, 0)
  view.new:SetScript("OnClick", safe(function() view.body:Hide(); view.editor.open(nil) end))
  view.hint = fstr(view.head, 11, C.textDim)
  view.hint:SetPoint("LEFT", view.head, "LEFT", 12, 0)
  view.hint:SetPoint("RIGHT", view.new, "LEFT", -12, 0)
  view.hint:SetWordWrap(false)
  view.body = CreateFrame("Frame", nil, view)
  view.body:SetPoint("TOPLEFT", view.head, "BOTTOMLEFT", 0, -10)
  view.body:SetPoint("BOTTOMRIGHT", 0, 0)
  view.list = newAccList(view.body)
  buildEditor(view)
  function view.close()
    view.editor:Hide()
    view.body:Show()
    view.refresh()
  end

  function view.refresh()
    local K, list = ns.Keys, view.list
    view.new:SetText(L["New macro"])
    if view.editor:IsShown() then return end
    local macros = K and K:ClassMacros(P.PlayerClassToken()) or {}
    view.macros = macros
    list:Begin()
    -- oyuncunun editorde kurdugu makrolar: tikla -> editor
    local mine = {}
    for _, s in ipairs(K and K.char and K.char.custom or {}) do
      local m = K:CustomMacro(s)
      local installed = K:MacroIndex(m) > 0
      mine[#mine + 1] = {
        a = m.name, b = (m.body:gsub("\n", "  ")), icon = iconPath(m.icons[1]),
        button = L["Edit"], onButton = function() view.body:Hide(); view.editor.open(s) end,
        onClick = function() view.body:Hide(); view.editor.open(s) end,
        tick = installed and GREEN or C.border,
        tip = function(tt) tt:SetText(m.name, 1, 0.82, 0.2); tt:AddLine(m.body, 0.55, 0.8, 1, true) end,
      }
    end
    if #mine > 0 then list:Group("mine", L["My macros"], tostring(#mine), GREEN, mine) end
    local rows, ready = {}, 0
    for _, m in ipairs(macros) do
      local installed = K:MacroIndex(m) > 0
      if m.known then ready = ready + 1 end
      local function report(ok, why)
        if not ok then ns:Print(why == "combat" and L["Not possible in combat."] or L["No free macro slots."]) end
      end
      rows[#rows + 1] = {
        a = m.name, b = m.desc,
        icon = iconPath(K:MacroIcon(m)),
        iconTip = L["Click to change the icon"],
        -- kurulu makroda yeni ikon hemen yazilir
        onIcon = function() K:CycleMacroIcon(m); if installed then report(K:InstallMacro(m)) end; view.refresh() end,
        right = not m.known and L["Not learned"] or nil,
        button = installed and L["Uninstall"] or (m.known and L["Install"] or nil),
        onButton = function()
          if installed then report(K:UninstallMacro(m))
          else
            local ok, why = K:InstallMacro(m)
            report(ok, why)
            if ok then ns:Print(L["%s added. Drag it to a bar from the macro window (/macro)."]:format(m.name)) end
          end
          view.refresh()
        end,
        tick = installed and GREEN or C.border,
        aColor = m.known and C.text or C.textDim,
        tip = function(tt)
          tt:SetText(m.name, 1, 0.82, 0.2)
          tt:AddLine(m.desc, 1, 1, 1, true)
          tt:AddLine(" ")
          tt:AddLine(m.body, 0.55, 0.8, 1, true)
          tt:AddLine(" ")
          if not m.known then
            tt:AddLine(L["Learn %s first."]:format(m.missing or ""), 0.95, 0.6, 0.3, true)
          else
            tt:AddLine(L["Click the icon to change it."], 0.6, 0.6, 0.6, true)
          end
        end,
      }
    end
    list:Group("macros", L["Class macros"], L["%d ready"]:format(ready), C.accent, rows)
    list:End()
    view.hint:SetText(L["Nothing is added on its own: press Install on the macros you want."])
  end
end

-- Rotasyon (RotationForge, Rotation/): durum, kisayollar ve talent rehberinin siradaki adimlari. Ayarlari kendi
-- penceresinde (/rof); Arcanis ayarlarina girmez.
local function buildRotation(page, view)
  view.list = newAccList(view)
  function view.refresh()
    local RF, list = ns.RF, view.list
    list:Begin()
    if not (RF and RF.db) or RF.stopped then
      list:Group("rof", L["Rotation helper"], "", C.border, (RF and RF.stopped)
        and L["The rotation helper is turned off in Settings > Modules."]
        or L["The rotation helper is not loaded."])
      list:End()
      return
    end
    local db = RF.db
    local cls = RF.classes and RF.classes[RF.playerClass or ""]
    local rows = {
      { a = L["Rotation settings"], b = L["Icons, cooldown bar, action bar glow, class options"], onClick = function() RF.Options_Open() end },
      { a = db.locked and L["Unlock the icons"] or L["Lock the icons"], b = L["Drag the icons to where you want them"],
        onClick = function() db.locked = not db.locked; if RF.UI_Apply then RF.UI_Apply() end; view.refresh() end },
      { a = L["Check spells"], b = L["Lists the spells it found and the ones it could not (chat)"], onClick = function() SlashCmdList.ROTATIONFORGE("debug") end },
    }
    list:Group("rof", L["Rotation helper"], cls and L["Ready"] or L["Not for this class yet"], C.accent, rows)
    -- talent rehberi: secili build ve siradaki bes puan
    local build = RF.ActiveBuild and RF.ActiveBuild()
    local steps = {}
    for i = 0, 4 do
      local name, rank, target = RF.NextTalent(build, i)
      if not name then break end
      steps[#steps + 1] = { a = ("%d. %s"):format(i + 1, RF.TalentDisplayName and RF.TalentDisplayName(name) or name), b = ("%d / %d"):format(rank, target) }
    end
    list:Group("rofTalents", build and build.name or L["Talent guide"],
      L["%d unspent"]:format(RF.TalentUnspent and RF.TalentUnspent() or 0), C.accent,
      #steps > 0 and steps or (build and L["The build is complete."] or L["No build for this class."]))
    list:End()
  end
end

-- Sayfa
local VIEWS = {
  { id = "character", text = function() return L["Character"] end, build = buildCharacter },
  { id = "talents", text = function() return L["Talents"] end, build = buildTalents },
  { id = "rotation", text = function() return L["Rotation"] end, build = buildRotation },
  { id = "trainers", text = function() return L["Trainers"] end, build = buildTrainers },
  { id = "spells", text = function() return L["Spells"] end, build = buildSpells },
  { id = "quests", text = function() return L["Quests"] end, build = buildQuests },
  { id = "pets", text = function() return L["Pets"] end, build = buildPets, hunter = true },
  { id = "macros", text = function() return L["Macros"] end, build = buildMacros },
}

local function buildCodex(page)
  local isHunter = P.PlayerClassToken() == "HUNTER"
  local tabs, defs = {}, {}
  for _, v in ipairs(VIEWS) do
    if not v.hunter or isHunter then tabs[#tabs + 1] = { id = v.id }; defs[v.id] = v end
  end
  page.views = {}
  page.view = "character"
  page.tabs = Skin:CreateTabBar(page, tabs, function(id) page.view = id; page.refresh() end)
  page.tabs:SetPoint("TOPLEFT", 0, 0)
  page.tabs:SetPoint("TOPRIGHT", 0, 0)
  page.tabs:Select("character", true)

  local function view(id)
    local v = page.views[id]
    if v then return v end
    v = CreateFrame("Frame", nil, page)
    v:SetPoint("TOPLEFT", page.tabs, "BOTTOMLEFT", 0, -10)
    v:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    defs[id].build(page, v)
    page.views[id] = v
    return v
  end

  function page.refresh()
    page.tabs:SetTexts(function(id) return defs[id] and defs[id].text() or id end)
    if not defs[page.view] then page.view = "character" end
    for id, v in pairs(page.views) do if id ~= page.view then v:Hide() end end
    local v = view(page.view)
    v:Show()
    if v.refresh then ns.SafeCall(v.refresh) end
  end
  -- pencere boyutu degisince metin bloklari yeni genislige gore yeniden olculur
  page:HookScript("OnSizeChanged", function()
    if page.IsVisible and page:IsVisible() then ns.SafeCall(page.refresh) end
  end)

  -- canta / ekipman / uzmanlik degisince Character gorunumu tazelenir (tek karede toplanir)
  local pending
  local function later()
    -- IsVisible: ana pencere kapaliyken sayfa "shown" kalir; kapaliyken ganimet toplarken canta taranmaz
    if pending or not (page.IsVisible and page:IsVisible()) or page.view ~= "character" then return end
    pending = true
    local function run() pending = false; ns.SafeCall(page.refresh) end
    if C_Timer and C_Timer.After then C_Timer.After(0.4, run) else run() end
  end
  ns:On("BAG_UPDATE_DELAYED", page, later)
  ns:On("PLAYER_EQUIPMENT_CHANGED", page, later)
  ns:Listen("ARCANIS_GEAR_SPEC_CHANGED", page, later)
  -- egitmen listesi okununca acik Spells sekmesi dolar
  ns:Listen("ARCANIS_TRAINING_CHANGED", page, function()
    if page.view == "spells" and page.IsVisible and page:IsVisible() then ns.SafeCall(page.refresh) end
  end)
end

Win:RegisterPage({
  id = "talents", order = 60, icon = "guides",
  title = function() return L["Class Codex"] end,
  -- Ayarlar'daki "Class codex" anahtari sayfayi gizler
  available = function() return not ns.Codex or ns.Codex:IsEnabled() or _G.ArcanisOracle ~= nil end,
  build = buildCodex,
})
