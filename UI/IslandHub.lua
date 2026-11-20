-- Arcanis: ust ada hub'i (ns.Island.Hub). Adaya tiklayinca serit baslik olarak kalir, altina kartlar acilir.
-- db.hub sirali listesi uc tur kimlik alir: buyuk kartlar (Island.CARDS), seritteki her bilgi kucuk kutucuk olarak
-- (Island.ELEMENTS, ucu bir satirda) ve grup basliklari (Island.GROUPS). Izgara: ayni boydaki ardisik ogeler bir satirda
-- (full 1, half 2, third 3); satir dolmazsa ogeler genisler. Kartlar sirayla belirir.
-- Sistem grafikleri yalniz hub acikken ornek toplar (kapaninca sifirlanir); eklenti bellegi 5 sn'de bir okunur.
local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local P = ns.Provider
local L = ns.L
local Island = ns.Island
local WHITE = "Interface\\Buttons\\WHITE8x8"

local Hub = { cards = {} }
Island.Hub = Hub

local HEADER = 28
local FOOTER = 28   -- alt satir: kisayollar (solda) ve sayfa gecisi (ortada: < . . . >)
local PAD, GAP, INNER = 12, 8, 10
local STAGGER, APPEAR = 0.035, 0.14
local PER_ROW = { full = 1, half = 2, third = 3 }
local GREEN, AMBER, RED = Skin.Colors.good, Skin.Colors.caution, Skin.Colors.bad
Island.XP_COLORS = {
  { id = "purple", c = { 0.58, 0.0, 0.55 } }, { id = "blue", c = { 0.15, 0.45, 0.95 } },
  { id = "green", c = { 0.25, 0.70, 0.30 } }, { id = "gold", c = { 0.90, 0.65, 0.10 } },
  { id = "red", c = { 0.80, 0.20, 0.20 } }, { id = "accent" },
}

local function num(n) return BreakUpLargeNumbers and BreakUpLargeNumbers(math.floor(n + 0.5)) or tostring(math.floor(n + 0.5)) end
local function fmtTime(s) return ns.Leveling and ns.Leveling.FormatTime(s) or (math.floor(s / 60) .. " min") end
local function xpColor()
  if type(Island.db.xpColor) == "table" then return Island.db.xpColor end
  for _, x in ipairs(Island.XP_COLORS) do if x.id == Island.db.xpColor and x.c then return x.c end end
  if Island.db.xpColor == "accent" then return Skin.Colors.accent end
  return Island.XP_COLORS[1].c
end

-- Yazi: boyut hub yazi boyutu ayarina gore kayar (varsayilan 11).
local function text(parent, size, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(fs, size + (Island.db.hubFont or 11) - 11, "")
  fs:SetTextColor(unpack(color or Skin.Colors.text))
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(false)
  return fs
end
local function lineH() return 14 + (Island.db.hubFont or 11) - 11 end
-- kart basligi ve deger yazisi renkleri ayardan (db.cardTitle / db.cardValue; "theme" = varsayilan)
local function titleColor()
  return Island:ColorOf(Island.db.cardTitle, { 0.65, 0.65, 0.65, 1 })
end
local function valueColor() return Island:ColorOf(Island.db.cardValue, Skin.Colors.text) end
Hub.TitleColor, Hub.XPColor = titleColor, xpColor   -- ayarlardaki renk dugmeleri su anki rengi gosterir
local function fill(parent, layer, color, a)
  local t = parent:CreateTexture(nil, layer)
  t:SetTexture(WHITE)
  t:SetVertexColor(color[1], color[2], color[3], a or 1)
  t._skinFixed = true
  return t
end

-- Cam hap cubuk: pill.tga uc parcaya bolunur, istege bagli pillgloss biner. :SetColor(c, a), :SetFill(px).
local function soft(t)
  if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false); t:SetTexelSnappingBias(0) end
  t._skinFixed = true
  return t
end

local function slices(p, layer, tex, h)
  local r = h / 2
  local l = soft(p:CreateTexture(nil, layer)); l:SetTexture(tex); l:SetTexCoord(0, 0.5, 0, 1)
  l:SetSize(r, h); l:SetPoint("LEFT")
  local rr = soft(p:CreateTexture(nil, layer)); rr:SetTexture(tex); rr:SetTexCoord(0.5, 1, 0, 1)
  rr:SetSize(r, h); rr:SetPoint("RIGHT")
  local m = soft(p:CreateTexture(nil, layer)); m:SetTexture(tex); m:SetTexCoord(0.49, 0.51, 0, 1)
  m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", rr, "BOTTOMLEFT")
  return { l, m, rr }
end

local function pill(parent, level, h, gloss)
  local p = CreateFrame("Frame", nil, parent)
  p:SetFrameLevel((parent:GetFrameLevel() or 0) + level)
  p:SetHeight(h); p:SetPoint("TOPLEFT"); p:SetPoint("BOTTOMLEFT")
  p.parts = slices(p, "ARTWORK", Skin.Icons.pill, h)
  if gloss then
    for _, t in ipairs(slices(p, "OVERLAY", Skin.Icons.pillgloss, h)) do t:SetVertexColor(1, 1, 1, 0.55) end
  end
  function p:SetColor(c, a)
    for _, t in ipairs(self.parts) do t:SetVertexColor(c[1], c[2], c[3], a or 1) end
  end
  function p:SetFill(px) self:SetWidth(math.max(h, px)) end
  return p
end
Hub.Pill = pill

-- Halka gosterge: soluk tam halka uzerinde iki kirpilmis yarida dondurulen yarim halka (saat yonunde, tepeden).
-- :Set(p 0-1, renk, ortadaki yazi)
local RING = 46
local function ring(parent, size)
  local g = CreateFrame("Frame", nil, parent)
  g:SetSize(size, size)
  g.track = soft(g:CreateTexture(nil, "ARTWORK")); g.track:SetTexture(Skin.Icons.gauge); g.track:SetAllPoints()
  g.track:SetVertexColor(1, 1, 1, 0.09)
  g.halves = {}
  for k, side in ipairs({ "RIGHT", "LEFT" }) do
    local clip = CreateFrame("Frame", nil, g)
    clip:SetClipsChildren(true)
    clip:SetPoint("TOP"); clip:SetPoint("BOTTOM"); clip:SetWidth(size / 2)
    if side == "RIGHT" then clip:SetPoint("LEFT", g, "CENTER") else clip:SetPoint("RIGHT", g, "CENTER") end
    local t = soft(clip:CreateTexture(nil, "OVERLAY")); t:SetTexture(Skin.Icons.gaugehalf)
    t:SetSize(size, size); t:SetPoint("CENTER", g, "CENTER")
    g.halves[k] = t
  end
  g.value = text(g, 12, valueColor()); g.value:SetPoint("CENTER", 0, 0); g.value:SetJustifyH("CENTER")
  function g:Set(p, c, label)
    p = math.max(0, math.min(1, p or 0))
    -- sag yari 0-%50'yi, sol yari (ayni doku +180) %50-100'u acar; acisi kalan kismi kirpilan yariya iter
    local r, l = self.halves[1], self.halves[2]
    if r.SetRotation then
      r:SetRotation(math.rad(180 - 360 * math.min(p, 0.5)))
      l:SetRotation(math.rad(540 - 360 * math.max(p, 0.5)))
    end
    r:SetShown(p > 0); l:SetShown(p > 0.5)
    for _, t in ipairs(self.halves) do t:SetVertexColor(c[1], c[2], c[3], 1) end
    self.value:SetText(label or "")
    local fit = table.concat({ label or "", tostring(Island.db.hubFont), tostring(Skin.Constants.FONT), tostring(Skin.fontScale) }, "|")
    if self.fit == fit then return end
    self.fit = fit
    -- yazi halkanin icine sigana kadar kuculur ("Ready", "Bereit" ...)
    local fs, inner = 12, size - 16
    repeat
      Skin:SetFont(self.value, fs + (Island.db.hubFont or 11) - 11, "")
      fs = fs - 1
    until fs < 7 or (tonumber(self.value:GetStringWidth()) or 0) <= inner
  end
  return g
end
Hub.Ring = ring

-- Gosterge karti: db.gaugeStyle "ring" (solda halka, ortasinda deger) ya da "bar" (baslik, cam cubuk, satirlar).
local function ringStyle() return Island.db.gaugeStyle == "ring" end
local function gaugeHeight(lines)
  if ringStyle() then return 2 * INNER + math.max(RING, 16 + lines * lineH()) end
  return 2 * INNER + 16 + 8 + lines * lineH()
end

local function gaugeBuild(c, lines)
  c.head = text(c, 10, titleColor())
  c.headR = text(c, 11, valueColor()); c.headR:SetJustifyH("RIGHT")
  c.lines = {}
  for i = 1, lines do c.lines[i] = text(c, 11, i == 1 and valueColor() or Skin.Colors.textDim) end
  c.ring = ring(c, RING)
  c.bar = CreateFrame("Frame", nil, c); c.bar:SetHeight(6)
  c.track = pill(c.bar, 0, 6); c.track:SetPoint("TOPRIGHT"); c.track:SetColor({ 1, 1, 1 }, 0.08)
  c.fillP = pill(c.bar, 1, 6, true)
end

-- head: baslik; p 0-1; col: renk; label: halkanin ortasi / cubuk stilinde basligin sagi; lines: metinler
local function gaugeSet(c, head, p, col, label, lines)
  local isRing = ringStyle()
  c.ring:SetShown(isRing); c.bar:SetShown(not isRing); c.headR:SetShown(not isRing)
  c.head:ClearAllPoints(); c.headR:ClearAllPoints()
  local x = isRing and INNER + RING + 12 or INNER
  c.head:SetPoint("TOPLEFT", x, -INNER - (isRing and 2 or 0)); c.head:SetPoint("RIGHT", -INNER - (isRing and 0 or 50), 0)
  c.head:SetText(head:upper())
  local top
  if isRing then
    c.ring:ClearAllPoints(); c.ring:SetPoint("TOPLEFT", INNER, -INNER)
    c.ring:Set(p, col, label)
    top = -INNER - 18
  else
    c.headR:SetPoint("TOPRIGHT", -INNER, -INNER + 1); c.headR:SetText(label or "")
    c.headR:SetTextColor(col[1], col[2], col[3], 1)
    c.bar:ClearAllPoints(); c.bar:SetPoint("TOPLEFT", INNER, -INNER - 16); c.bar:SetPoint("TOPRIGHT", -INNER, -INNER - 16)
    c.fillP:SetFill(((c.w or 200) - 2 * INNER) * math.max(0, math.min(1, p)))
    c.fillP:SetColor(col, 1); c.fillP:SetShown(p > 0)
    top = -INNER - 16 - 10
  end
  for i, fs in ipairs(c.lines) do
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", x, top - (i - 1) * lineH()); fs:SetPoint("RIGHT", -INNER, 0)
    fs:SetText(lines[i] or "")
  end
end

-- Esik rengi: oran yuksekse yesil (higher = true) ya da tersi.
local function ratioColor(r) return r >= 0.5 and GREEN or (r >= 0.2 and AMBER or RED) end

-- Sinif reagent'lari ve kaynaklari: { id = esya, item = yedek ad (oyun adi gelmezse) } ya da kind = "ammo" | "pet" | "poisons"
local POISONS = { 6947, 6949, 6950, 8926, 8927, 8928, 2892, 2893, 8984, 8985, 20844, 3775, 3776, 5237, 6951, 9186, 10918, 10920, 10921, 10922 }
Hub.CLASS_ITEMS = {
  HUNTER = { { kind = "ammo" }, { kind = "pet" } },
  WARLOCK = { { id = 6265, item = "Soul Shard" } },
  ROGUE = { { kind = "poisons" }, { id = 5140, item = "Flash Powder" } },
  MAGE = { { id = 17031, item = "Rune of Teleportation" }, { id = 17032, item = "Rune of Portals" }, { id = 17020, item = "Arcane Powder" } },
  PRIEST = { { id = 17028, item = "Holy Candle" }, { id = 17029, item = "Sacred Candle" } },
  SHAMAN = { { id = 17030, item = "Ankh" } },
  PALADIN = { { id = 21177, item = "Symbol of Kings" }, { id = 17033, item = "Symbol of Divinity" } },
  DRUID = { { id = 17021, item = "Wild Berries" }, { id = 17034, item = "Maple Seed" } },
}
local function happyText(h) return h == 1 and L["Unhappy"] or (h == 2 and L["Content"] or L["Happy"]) end

function Hub:ClassRows()
  local out = {}
  for _, e in ipairs(Hub.CLASS_ITEMS[P.PlayerClassToken() or ""] or {}) do
    if e.kind == "ammo" then
      local n = P.AmmoCount()
      if n then out[#out + 1] = { L["Ammo"], tostring(n), n < 200 and (n == 0 and RED or AMBER) or nil } end
    elseif e.kind == "pet" then
      local h = P.PetHappiness()
      if h then out[#out + 1] = { L["Pet"], happyText(h), h == 1 and RED or (h == 2 and AMBER or GREEN) } end
    elseif e.kind == "poisons" then
      local n = 0
      for _, id in ipairs(POISONS) do n = n + (P.ItemCount(id) or 0) end
      out[#out + 1] = { L["Poisons"], tostring(n), n == 0 and RED or nil }
    else
      local n = P.ItemCount(e.id) or 0
      out[#out + 1] = { P.ItemName(e.id) or e.item, tostring(n), n == 0 and RED or nil }
    end
  end
  return out
end

-- Son ganimetler (en yenisi ustte, en cok 5): LOOT_OPENED'da Island cagirir.
Hub.loot = {}
function Hub:OnLoot()
  for _, it in ipairs((P.LootItems())) do
    local price = ns.Prices and ns.Prices.Get and ns.Prices:Get(it.id)
    table.insert(self.loot, 1, { name = it.name or ("#" .. it.id), count = it.count, value = price and price * it.count })
    if #self.loot > 5 then table.remove(self.loot) end
  end
end
Hub.sessionStart = P.Now()

-- Hub her acildiginda siradaki Mentor bilgisi (okunmamislar once).
function Hub:Tip()
  local tips = ns.Mentor and ns.Mentor.char and ns.Mentor:Tips() or {}
  if #tips == 0 then return nil end
  return tips[((self.tipIndex or 1) - 1) % #tips + 1]
end

-- Mini grafik: n cubuk (aralarinda 1 px), yeni ornek sagdan girer.
local function sparkline(parent, n, w, h)
  local s = { bars = {}, values = {}, n = n, h = h }
  for i = 1, n do s.bars[i] = fill(parent, "ARTWORK", GREEN, 0.9) end
  -- genislik degisince (hub genisligi) cubuklar yeniden dizilir
  function s:SetWidth(width)
    local bw = math.max(1, math.floor(width / self.n) - 1)
    for i, b in ipairs(self.bars) do
      b:SetWidth(bw)
      b:ClearAllPoints()
      b:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", (i - 1) * (bw + 1), 0)
    end
  end
  s:SetWidth(w)
  function s:Add(v, color)
    self.values[#self.values + 1] = { v = v or 0, c = color }
    if #self.values > self.n then table.remove(self.values, 1) end
    local max = 1
    for _, x in ipairs(self.values) do if x.v > max then max = x.v end end
    for i, b in ipairs(self.bars) do
      local x = self.values[i - (self.n - #self.values)]
      if x then
        b:SetHeight(math.max(1, x.v / max * self.h))
        b:SetVertexColor(x.c[1], x.c[2], x.c[3], 0.9)
        b:Show()
      else
        b:Hide()
      end
    end
  end
  function s:Clear() self.values = {}; for _, b in ipairs(self.bars) do b:Hide() end end
  return s
end

local function threshold(v, good, ok, higherIsBetter)
  if higherIsBetter then return v >= good and GREEN or (v >= ok and AMBER or RED) end
  return v <= good and GREEN or (v <= ok and AMBER or RED)
end

-- Bolge kartinin satirlari (yukseklik bunlara gore).
local function zoneLines()
  local zone = P.ZoneText() or ""
  local d = ns.ZoneInfo and ns.ZoneInfo:Get(zone)
  local out = {}
  if d and (#d.herbs > 0 or #d.ore > 0) then
    local g = {}
    for _, n in ipairs(d.herbs) do g[#g + 1] = n end
    for _, n in ipairs(d.ore) do g[#g + 1] = n end
    out[#out + 1] = table.concat(g, ", ")
  end
  if d and #d.dungeons > 0 then
    local g = {}
    for _, e in ipairs(d.dungeons) do
      local dj = ns.Journal and ns.Journal:Get(e.id)
      g[#g + 1] = ("%s %d-%d"):format(dj and dj.name or e.id, e.min, e.max)
    end
    out[#out + 1] = table.concat(g, ", ")
  end
  local E = ns.Engine
  local step = E and E:GetStep()
  if step then
    local s = ("%d/%d"):format(E.index or 0, E.guide and #E.guide.steps or 0)
    if step.zone and step.zone ~= zone then s = s .. "  ·  " .. L["Your next step is in %s"]:format(step.zone) end
    out[#out + 1] = s
  end
  return zone, d, out
end

-- Buyuk kartlar: { id, name (L), size "full"|"half", height (sayi ya da fonksiyon), build(card), update(card) }
Island.CARDS = {
  { id = "xp", name = "XP bar", size = "full", height = function() return 36 + lineH() end,
    build = function(c)
      c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.bar = CreateFrame("Frame", nil, c)
      c.bar:SetHeight(12)
      c.bar:SetPoint("TOPLEFT", INNER, -26); c.bar:SetPoint("TOPRIGHT", -INNER, -26)
      -- cam hap: soluk iz, ustunde yari saydam rested, en ustte parlak dolgu
      c.track = pill(c.bar, 0, 12); c.track:SetPoint("TOPRIGHT"); c.track:SetColor({ 1, 1, 1 }, 0.09)
      c.rested = pill(c.bar, 1, 12); c.rested:SetColor({ 0.35, 0.6, 1 }, 0.3)
      c.quest = pill(c.bar, 2, 12)   -- teslime hazir gorevlerin XP'si: dolgunun acik tonlu devami
      c.fill = pill(c.bar, 3, 12, true)
      c.left = text(c, 11, Skin.Colors.textDim); c.left:SetPoint("TOPLEFT", c.bar, "BOTTOMLEFT", 0, -4)
      -- dinlenmis XP basligin sagi, XP/saat sayilarla ayni satirin sagi (alt alta tasmasin)
      c.right = text(c, 10, Skin.Colors.info); c.right:SetPoint("TOPRIGHT", -INNER, -INNER)
      c.right:SetJustifyH("RIGHT")
      c.rate = text(c, 11, valueColor()); c.rate:SetPoint("TOPRIGHT", c.bar, "BOTTOMRIGHT", 0, -4)
      c.rate:SetPoint("LEFT", c.left, "RIGHT", 8, 0)
      c.rate:SetJustifyH("RIGHT"); c.rate:SetWordWrap(false)
    end,
    update = function(c)
      local xp, max, level = P.XP()
      local pct = xp / math.max(1, max)
      local rested = P.RestXP()
      c.head:SetText(L["Level %d - %d%%"]:format(level, math.floor(pct * 100)):upper())
      local bw = c.bar:GetWidth()
      bw = (type(bw) == "number" and bw > 0) and bw or (c.w or 400) - 2 * INNER
      local col = xpColor()
      c.fill:SetColor(col, 1)
      c.fill:SetFill(bw * pct); c.fill:SetShown(xp > 0)
      c.rested:SetFill(bw * math.min(1, (xp + rested) / math.max(1, max)))
      c.rested:SetShown(rested > 0)
      local Lv = ns.Leveling
      local ready = Lv and Lv.ReadyQuestXP and Lv:ReadyQuestXP() or 0
      c.quest:SetColor(col, 0.35)
      c.quest:SetFill(bw * math.min(1, (xp + ready) / math.max(1, max)))
      c.quest:SetShown(ready > 0)
      local left = ("%s / %s"):format(num(xp), num(max))
      if ready > 0 then left = left .. "  " .. L["+%s from quests"]:format(num(ready)) end
      c.left:SetText(left)
      c.right:SetText(rested > 0 and L["Rested %s"]:format(num(rested)) or "")
      -- XP/saat: oturumun ilk dakikalarinda veri yok; tek tire yerine ne beklendigini soyler (soluk)
      local line = ns.Leveling and ns.Leveling:Line()
      c.rate:SetText(line or L["Not enough XP data yet. Kill or quest for a minute."])
      c.rate:SetTextColor(unpack(line and valueColor() or Skin.Colors.textDim))
      c.pulse = pct >= 0.95
    end },

  { id = "levelup", name = "Level-up tracker", size = "full", height = function() return 2 * INNER + 3 + 16 + lineH() end,
    build = function(c)
      c.value = text(c, 14, valueColor()); c.value:SetPoint("TOPLEFT", INNER, -INNER)
      c.sub = text(c, 11, Skin.Colors.textDim); c.sub:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -3)
    end,
    update = function(c)
      local Lv = ns.Leveling
      local onLevel = Lv and Lv.levelStart and (P.Now() - Lv.levelStart) or 0
      c.value:SetText(L["On this level %s"]:format(fmtTime(onLevel)))
      local session = P.PlayerLevel() - (Hub.startLevel or P.PlayerLevel())
      local parts = { L["This session: +%d levels"]:format(session) }
      local best
      for _, t in ipairs(Lv and Lv.char and Lv.char.levelTimes or {}) do
        if t.secs >= 30 and (not best or t.secs < best.secs) then best = t end
      end
      if best then parts[#parts + 1] = L["Fastest: %s (level %d)"]:format(fmtTime(best.secs), best.level - 1) end
      c.sub:SetText(table.concat(parts, "  ·  "))
    end },

  -- yukseklik satir sayisina gore: bos satir yer kaplamaz
  { id = "zone", name = "Zone info", size = "full",
    height = function()
      local _, _, out = zoneLines()
      return 2 * INNER + 16 + math.max(1, #out) * lineH()
    end,
    build = function(c)
      c.head = text(c, 13, valueColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.range = text(c, 11, Skin.Colors.text); c.range:SetPoint("TOPRIGHT", -INNER, -INNER - 1); c.range:SetJustifyH("RIGHT")
      c.lines = {}
      for i = 1, 3 do
        local fs = text(c, 11, Skin.Colors.textDim)
        fs:SetPoint("TOPLEFT", i == 1 and c.head or c.lines[i - 1], "BOTTOMLEFT", 0, i == 1 and -4 or -2)
        fs:SetPoint("RIGHT", c, "RIGHT", -INNER, 0)
        c.lines[i] = fs
      end
    end,
    update = function(c)
      local zone, d, out = zoneLines()
      c.head:SetText(zone)
      local lvl = P.PlayerLevel()
      if d then
        local col = lvl < d.min - 2 and RED or (lvl < d.min and AMBER or (lvl > d.max + 4 and { 0.6, 0.6, 0.6 } or GREEN))
        c.range:SetText(("%d-%d"):format(d.min, d.max)); c.range:SetTextColor(col[1], col[2], col[3], 1)
      else
        c.range:SetText("")
      end
      if #out == 0 then out[1] = L["No info for this zone."] end
      for i, fs in ipairs(c.lines) do fs:SetText(out[i] or "") end
    end },

  { id = "stats", name = "Character stats", size = "half", height = function() return 2 * INNER + 6 * (lineH() - 1) end,
    build = function(c)
      c.rows = {}
      for i = 1, 6 do
        local a = text(c, 11, Skin.Colors.textDim)
        a:SetPoint("TOPLEFT", INNER, -INNER - (i - 1) * (lineH() - 1))
        local b = text(c, 11, valueColor())
        b:SetPoint("TOPRIGHT", -INNER, -INNER - (i - 1) * (lineH() - 1)); b:SetJustifyH("RIGHT")
        c.rows[i] = { a, b }
      end
    end,
    update = function(c)
      local v = Island:StatValues()
      for i, r in ipairs(c.rows) do
        local row = v[Island.STAT_ORDER[i]]
        r[1]:SetText(row[1]); r[2]:SetText(row[2])
      end
    end },

  { id = "gold", name = "Gold", size = "half", height = function() return 2 * INNER + 14 + 22 + 2 * lineH() end,
    build = function(c)
      c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.value = text(c, 14, Skin.Colors.text); c.value:SetPoint("TOPLEFT", c.head, "BOTTOMLEFT", 0, -6)
      c.rate = text(c, 11, Skin.Colors.textDim); c.rate:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -6)
      c.total = text(c, 11, Skin.Colors.textDim); c.total:SetPoint("TOPLEFT", c.rate, "BOTTOMLEFT", 0, -3)
    end,
    update = function(c)
      c.head:SetText(L["Session"]:upper())
      local s = ns.Gold and ns.Gold.Summary and ns.Gold:Summary()
      local net = s and s.net or 0
      local col = net >= 0 and GREEN or RED
      c.value:SetText((net >= 0 and "+" or "-") .. P.MoneyText(math.abs(net)))
      c.value:SetTextColor(col[1], col[2], col[3], 1)
      c.rate:SetText(L["Gold/h %s"]:format(s and s.rate and P.MoneyText(math.max(0, s.rate)) or "-"))
      c.total:SetText(L["Total %s"]:format(P.MoneyText(P.Money())))
    end },

  { id = "system", name = "System", size = "full", height = 64,
    build = function(c)
      c.panels = {}
      for i, key in ipairs({ "FPS", "Latency", "Memory" }) do
        local p = CreateFrame("Frame", nil, c)
        p:SetSize(120, 44)
        p.label = text(p, 10, titleColor()); p.label:SetPoint("TOPLEFT")
        p.label:SetText(L[key]:upper())
        p.value = text(p, 11, valueColor()); p.value:SetPoint("TOPRIGHT"); p.value:SetJustifyH("RIGHT")
        local g = CreateFrame("Frame", nil, p)
        g:SetSize(120, 18); g:SetPoint("BOTTOMLEFT")
        p.graph = sparkline(g, 30, 120, 18)
        p.g = g
        c.panels[i] = p
      end
    end,
    -- uc panel kartin genisligini paylasir (dar hub'da ust uste binmesin)
    layout = function(c, w)
      local gap = 12
      local pw = math.floor((w - 2 * INNER - 2 * gap) / 3)
      for i, p in ipairs(c.panels) do
        p:SetWidth(pw); p.g:SetWidth(pw); p.graph:SetWidth(pw)
        p:ClearAllPoints(); p:SetPoint("TOPLEFT", INNER + (i - 1) * (pw + gap), -INNER)
      end
    end,
    update = function(c, sample)
      if not sample then return end
      local s = P.SystemStats()
      local fps, ping = s.fps or 0, math.max(s.home or 0, s.world or 0)
      local cf, cp = threshold(fps, 50, 25, true), threshold(ping, 80, 200, false)
      c.panels[1].value:SetText(("%d"):format(fps)); c.panels[1].graph:Add(fps, cf)
      c.panels[2].value:SetText(("%d ms"):format(ping)); c.panels[2].graph:Add(ping, cp)
      Hub.memAge = (Hub.memAge or 99) + 1
      if Hub.memAge >= 5 then
        Hub.memAge = 0
        local kb = P.AddonMemoryKB("Arcanis") or s.luaKB or 0
        c.panels[3].value:SetText(("%.1f MB"):format(kb / 1024)); c.panels[3].graph:Add(kb, { 0.6, 0.6, 0.6 })
      end
    end,
    clear = function(c) for _, p in ipairs(c.panels) do p.graph:Clear() end; Hub.memAge = nil end },

  -- meslekler: her biri bir satir (ad, beceri cubugu, deger, trainer ipucu); yukseklik meslek sayisina gore
  { id = "profs", name = "Professions", size = "full",
    height = function() return 2 * INNER + math.max(1, #P.ProfessionRanks()) * (lineH() + 10) end,
    build = function(c) c.rows = {} end,
    update = function(c)
      local list = P.ProfessionRanks()
      local w = (c.w or 400) - 2 * INNER
      for i = 1, math.max(#list, #c.rows) do
        local r, p = c.rows[i], list[i]
        if p and not r then
          r = {}
          r.name = text(c, 11, valueColor())
          r.value = text(c, 11, valueColor()); r.value:SetJustifyH("RIGHT")
          r.hint = text(c, 10, Skin.Colors.textDim); r.hint:SetJustifyH("RIGHT")
          r.bar = CreateFrame("Frame", nil, c); r.bar:SetHeight(6)
          r.bg = pill(r.bar, 0, 6); r.bg:SetPoint("TOPRIGHT"); r.bg:SetColor({ 1, 1, 1 }, 0.08)
          r.fill = pill(r.bar, 1, 6, true)
          c.rows[i] = r
        end
        if r then
          local shown = p ~= nil
          for _, k in ipairs({ "name", "value", "hint", "bar" }) do r[k]:SetShown(shown) end
          if p then
            local y = -INNER - (i - 1) * (lineH() + 10)
            r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", INNER, y)
            r.value:ClearAllPoints(); r.value:SetPoint("TOPRIGHT", -INNER, y)
            r.hint:ClearAllPoints(); r.hint:SetPoint("RIGHT", r.value, "LEFT", -10, 0)
            r.bar:ClearAllPoints(); r.bar:SetPoint("TOPLEFT", INNER, y - lineH() - 1); r.bar:SetWidth(w)
            r.name:SetText(L[p.name])
            r.value:SetText(("%d / %d"):format(p.rank, p.max))
            local hint = ns.ProfActivity and ns.ProfActivity.TierHint(p.rank, p.max)
            r.hint:SetText(hint or "")
            r.fill:SetFill(w * p.rank / math.max(1, p.max))
            r.fill:SetColor(p.rank >= p.max and GREEN or AMBER, 1)
          end
        end
      end
      if #list == 0 then
        c.empty = c.empty or text(c, 11, Skin.Colors.textDim)
        c.empty:SetPoint("TOPLEFT", INNER, -INNER); c.empty:SetText(L["No professions learned yet."]); c.empty:Show()
      elseif c.empty then c.empty:Hide() end
    end },

  -- toplama oturumu: damar/bitki ve balik sayisi, Auction House degeri, saatlik altin
  { id = "gathering", name = "Gathering", size = "half", height = function() return 2 * INNER + 14 + 22 + 2 * lineH() end,
    build = function(c)
      c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.value = text(c, 14, Skin.Colors.text); c.value:SetPoint("TOPLEFT", c.head, "BOTTOMLEFT", 0, -6)
      c.rate = text(c, 11, Skin.Colors.textDim); c.rate:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -6)
      c.count = text(c, 11, Skin.Colors.textDim); c.count:SetPoint("TOPLEFT", c.rate, "BOTTOMLEFT", 0, -3)
    end,
    update = function(c)
      c.head:SetText(L["Gathering"]:upper())
      local Pa = ns.ProfActivity
      local s = Pa and Pa.session
      if not s then
        c.value:SetText("-"); c.rate:SetText(L["Gather or fish to start a session."]); c.count:SetText("")
        return
      end
      c.value:SetText(P.MoneyText(s.value))
      local r = Pa:SessionRate()
      c.rate:SetText(L["Gold/h %s"]:format(r and P.MoneyText(math.max(0, r)) or "-"))
      c.count:SetText(L["Nodes %d, catches %d"]:format(s.nodes, s.catches))
    end },

  -- ----- gosterge kartlari (halka ya da cubuk: db.gaugeStyle) -----
  { id = "repair", name = "Bags & Repair", size = "half", height = function() return gaugeHeight(2) end,
    build = function(c) gaugeBuild(c, 2) end,
    update = function(c)
      local d = P.LowestDurability()
      local free, total = P.FreeBagSlots(), P.BagSlotsTotal()
      local cost = P.RepairCost()
      gaugeSet(c, L["Durability"], d or 1, ratioColor(d or 1), d and ("%d%%"):format(math.floor(d * 100 + 0.5)) or "-", {
        L["%d / %d bag slots free"]:format(free, total),
        cost and cost > 0 and L["Repair %s"]:format(P.MoneyText(cost)) or "" })
      c.lines[1]:SetTextColor(unpack(free <= 2 and RED or (free <= 6 and AMBER or valueColor())))
    end },

  { id = "quests", name = "Quest log", size = "full", height = function() return gaugeHeight(2) end,
    build = function(c) gaugeBuild(c, 2) end,
    update = function(c)
      -- gorev gunlugu yalniz QUEST_LOG_UPDATE'ten sonra yeniden okunur (her saniye butun hedefler okunmasin)
      local key = Island.db.gaugeStyle .. ":" .. tostring(c.w)   -- stil ya da genislik degisince yeniden cizilir
      if c.quests and not Hub.questsDirty and c.key == key then return end
      Hub.questsDirty, c.key = false, key
      local list = P.QuestLogList()
      c.quests = list
      local ready, best, bestR = 0, nil, -1
      for _, q in ipairs(list) do
        if q.complete then ready = ready + 1
        else
          -- en cok ilerlemis hedef: "Kobold Candles: 6/8"
          for _, o in ipairs(P.GetObjectives(q.id) or {}) do
            local need = tonumber(o.numRequired) or 0
            local r = need > 0 and (tonumber(o.numFulfilled) or 0) / need or 0
            if not o.finished and o.text and r > bestR then best, bestR = o.text, r end
          end
        end
      end
      local n = #list
      gaugeSet(c, L["Quest log"], n > 0 and ready / n or 0, GREEN, ("%d/%d"):format(ready, n), {
        n == 0 and L["No quests in your log."] or L["%d ready to turn in"]:format(ready), best or "" })
    end },

  { id = "guide", name = "Guide progress", size = "full", height = function() return gaugeHeight(2) end,
    build = function(c) gaugeBuild(c, 2) end,
    update = function(c)
      local E = ns.Engine
      local g, total = E and E.guide, E and E.guide and #E.guide.steps or 0
      local i = math.min(E and E.index or 0, total)
      local p = total > 0 and i / total or 0
      local step = E and E.GetStep and E:GetStep()
      local ok, next = false, nil
      if step then ok, next = pcall(E.Describe, E, step) end
      gaugeSet(c, g and ns.Guides:TitleOf(g) or L["Guide progress"], p, Skin.Colors.accentHover,
        ("%d%%"):format(math.floor(p * 100)), {
          g and L["Step %d / %d"]:format(i, total) or L["No guide loaded."], ok and next or "" })
    end },

  { id = "hearthcard", name = "Hearthstone", size = "half", height = function() return gaugeHeight(2) end,
    build = function(c) gaugeBuild(c, 2) end,
    update = function(c)
      local left = P.ItemCooldown(Island.HEARTH)
      local ready = left == 0
      local p = left and 1 - math.min(1, left / 3600) or 0   -- shortcut: 60 dk varsayilir (Classic); Forever farkliysa yuzde kayar
      gaugeSet(c, L["Hearthstone"], p, ready and GREEN or Skin.Colors.accentHover,
        ready and L["Ready"] or (left and Island.Clock(left) or "-"), {
          P.BindLocation() and L["Bound to %s"]:format(P.BindLocation()) or "", "" })
    end },

  { id = "rep", name = "Reputation", size = "half", height = function() return gaugeHeight(2) end,
    build = function(c) gaugeBuild(c, 2) end,
    update = function(c)
      local f = P.WatchedFaction()
      if not f then
        gaugeSet(c, L["Reputation"], 0, AMBER, "-", { L["Watch a faction in the Reputation pane."], "" })
        return
      end
      local span = math.max(1, f.max - f.min)
      local p = (f.value - f.min) / span
      local fc = FACTION_BAR_COLORS and FACTION_BAR_COLORS[f.standing]
      local col = fc and { fc.r, fc.g, fc.b } or Skin.Colors.accentHover
      gaugeSet(c, f.name, p, col, ("%d%%"):format(math.floor(p * 100)), {
        P.StandingLabel(f.standing) or "", ("%s / %s"):format(num(f.value - f.min), num(span)) })
    end },

  -- ----- bilgi kartlari -----
  { id = "classres", name = "Class resources", size = "half",
    height = function() return 2 * INNER + 14 + math.max(1, #Hub:ClassRows()) * lineH() end,
    build = function(c) c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER); c.rows = {} end,
    update = function(c)
      c.head:SetText(L["Class resources"]:upper())
      local rows = Hub:ClassRows()
      if #rows == 0 then rows = { { L["No reagents for your class."], "" } } end
      for i = 1, math.max(#rows, #c.rows) do
        local r, v = c.rows[i], rows[i]
        if v and not r then
          r = { text(c, 11, Skin.Colors.textDim), text(c, 11, valueColor()) }
          r[2]:SetJustifyH("RIGHT")
          c.rows[i] = r
        end
        if r then
          r[1]:SetShown(v ~= nil); r[2]:SetShown(v ~= nil)
          if v then
            local y = -INNER - 14 - (i - 1) * lineH()
            r[1]:ClearAllPoints(); r[1]:SetPoint("TOPLEFT", INNER, y)
            r[2]:ClearAllPoints(); r[2]:SetPoint("TOPRIGHT", -INNER, y)
            r[1]:SetText(v[1]); r[2]:SetText(v[2])
            r[2]:SetTextColor(unpack(v[3] or valueColor()))
          end
        end
      end
    end },

  { id = "loot", name = "Loot log", size = "full",
    height = function() return 2 * INNER + 14 + math.max(1, #Hub.loot) * lineH() end,
    build = function(c) c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER); c.rows = {} end,
    update = function(c)
      c.head:SetText(L["Loot log"]:upper())
      for i = 1, 5 do
        local it = Hub.loot[i]
        local r = c.rows[i]
        if not r then
          r = { text(c, 11, valueColor()), text(c, 11, Skin.Colors.textDim) }
          r[1]:SetPoint("TOPLEFT", INNER, -INNER - 14 - (i - 1) * lineH()); r[1]:SetPoint("RIGHT", -INNER - 90, 0)
          r[2]:SetPoint("TOPRIGHT", -INNER, -INNER - 14 - (i - 1) * lineH()); r[2]:SetJustifyH("RIGHT")
          c.rows[i] = r
        end
        if it then
          r[1]:SetText(it.count > 1 and ("%dx %s"):format(it.count, it.name) or it.name)
          r[2]:SetText(it.value and P.MoneyText(it.value) or "")
        else
          r[1]:SetText(i == 1 and L["Nothing looted yet."] or ""); r[2]:SetText("")
        end
      end
    end },

  { id = "clockcard", name = "Clock & session", size = "half", height = function() return 2 * INNER + 14 + 22 + 2 * lineH() end,
    build = function(c)
      c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.value = text(c, 18, valueColor()); c.value:SetPoint("TOPLEFT", c.head, "BOTTOMLEFT", 0, -4)
      c.sub = text(c, 11, Skin.Colors.textDim); c.sub:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -4)
      c.sub2 = text(c, 11, Skin.Colors.textDim); c.sub2:SetPoint("TOPLEFT", c.sub, "BOTTOMLEFT", 0, -2)
    end,
    update = function(c)
      local server = P.ServerTime()
      c.head:SetText(L["Clock & session"]:upper())
      c.value:SetText(P.LocalTime() or server or "-")
      c.sub:SetText(L["Server %s"]:format(server or "-") .. "  ·  " .. L["Session %s"]:format(fmtTime(P.Now() - Hub.sessionStart)))
      local Lv = ns.Leveling
      c.sub2:SetText(L["On this level %s"]:format(fmtTime(Lv and Lv.levelStart and (P.Now() - Lv.levelStart) or 0)))
    end },

  { id = "tip", name = "Mentor tip", size = "full", height = function() return 2 * INNER + 14 + 18 + 3 * lineH() end,
    build = function(c)
      c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.title = text(c, 12, valueColor()); c.title:SetPoint("TOPLEFT", c.head, "BOTTOMLEFT", 0, -4); c.title:SetPoint("RIGHT", -INNER, 0)
      c.body = text(c, 11, Skin.Colors.textDim); c.body:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -3)
      c.body:SetPoint("RIGHT", -INNER, 0); c.body:SetWordWrap(true); c.body:SetJustifyV("TOP"); c.body:SetHeight(3 * lineH())
    end,
    update = function(c)
      c.head:SetText(L["Mentor tip"]:upper())
      local t = Hub:Tip()
      c.title:SetText(t and ns:LocalizedText(t.title) or L["No tips for your level."])
      c.body:SetText(t and ns:LocalizedText(t.text) or "")
    end },

  { id = "talents", name = "Talent points", size = "half", height = function() return 2 * INNER + 14 + 22 + lineH() end,
    build = function(c)
      c.head = text(c, 10, titleColor()); c.head:SetPoint("TOPLEFT", INNER, -INNER)
      c.value = text(c, 18, valueColor()); c.value:SetPoint("TOPLEFT", c.head, "BOTTOMLEFT", 0, -4)
      c.sub = text(c, 11, Skin.Colors.textDim); c.sub:SetPoint("TOPLEFT", c.value, "BOTTOMLEFT", 0, -4)
    end,
    update = function(c)
      local n = P.UnspentTalents()
      c.head:SetText(L["Talent points"]:upper())
      c.value:SetText(tostring(n))
      c.value:SetTextColor(unpack(n > 0 and Skin.Colors.accentHover or valueColor()))
      c.sub:SetText(n > 0 and L["%d unspent"]:format(n) or L["All talent points spent."])
    end },
}

-- Sekme ikonu ve gradyan rengi (kart stili "gradient")
local LOOK = {
  xp = { "star", { 0.58, 0.2, 0.8 } }, levelup = { "repeat", { 0.25, 0.45, 0.95 } }, zone = { "map", { 0.25, 0.7, 0.35 } },
  stats = { "shield", { 0.45, 0.55, 0.75 } }, gold = { "bag", { 0.9, 0.65, 0.1 } }, system = { "power", { 0.2, 0.65, 0.7 } },
  profs = { "hammer", { 0.9, 0.5, 0.2 } }, gathering = { "pin", { 0.35, 0.75, 0.3 } },
  repair = { "shield", { 0.75, 0.45, 0.25 } }, quests = { "exclaim", { 0.95, 0.75, 0.2 } },
  guide = { "compass", { 0.3, 0.6, 0.95 } }, hearthcard = { "house", { 0.4, 0.55, 0.95 } }, rep = { "wing", { 0.3, 0.75, 0.55 } },
  classres = { "sword", { 0.7, 0.35, 0.8 } }, loot = { "box", { 0.85, 0.7, 0.3 } }, clockcard = { "repeat", { 0.45, 0.6, 0.8 } },
  tip = { "bubble", { 0.35, 0.7, 0.9 } }, talents = { "star", { 0.95, 0.6, 0.2 } },
}
for _, d in ipairs(Island.CARDS) do
  local look = LOOK[d.id]
  if look then d.icon, d.tint = look[1], look[2] end
end

-- Seritteki her bilgi hub'da kucuk kutucuk olabilir (ust: ad, alt: deger); grup basliklari tam satir.
local DEFS = {}
for _, d in ipairs(Island.CARDS) do DEFS[d.id] = d end
for _, e in ipairs(Island.ELEMENTS) do
  DEFS[e.id] = DEFS[e.id] or { id = e.id, name = e.name, size = "third", tile = true,
    height = function() return 2 * 7 + 12 + lineH() end,
    build = function(c)
      c.label = text(c, 9, titleColor()); c.label:SetPoint("TOPLEFT", 8, -7); c.label:SetPoint("RIGHT", -8, 0)
      c.label:SetText(L[e.name]:upper())
      c.value = text(c, 13, valueColor()); c.value:SetPoint("TOPLEFT", c.label, "BOTTOMLEFT", 0, -3); c.value:SetPoint("RIGHT", -8, 0)
    end,
    update = function(c)
      local v = Island:ItemText(e.id, true)
      c.value:SetText(v ~= "" and v or "-")
      -- ana stat gibi adi sinifa gore degisen ogeler basligi kendisi verir
      if e.tag then
        local ok, t = pcall(e.tag)
        if ok and t then c.label:SetText(t:upper()) end
      end
    end }
end
for i, g in ipairs(Island.GROUPS) do
  DEFS[g.id] = { id = g.id, name = g.name, size = "full", group = true, height = 16,
    build = function(c)
      c.label = text(c, 10, Skin.Colors.accentHover); c.label:SetPoint("BOTTOMLEFT", 2, 3)
      c.line = fill(c, "ARTWORK", Skin.Colors.accent, 0.35)
      ns.Skin:Hairline(c.line, "h"); c.line:SetPoint("BOTTOMLEFT", 0, 0); c.line:SetPoint("BOTTOMRIGHT", 0, 0)
    end,
    update = function(c) c.label:SetText(Island:GroupName(i):upper()) end }
  DEFS[g.id].icon, DEFS[g.id].groupIndex = "flag", i
end
Island.HUB_DEFS = DEFS

-- yukseklik saniyelik tick ve her Rebuild basinda bir kez hesaplanir (Pages, rowHeight, HubHeight tekrar sorar)
Hub.hcache = {}
local function heightOf(d)
  if type(d.height) ~= "function" then return d.height end
  local v = Hub.hcache[d]
  if v == nil then v = d.height(); Hub.hcache[d] = v end
  return v
end

-- Izgara
-- Satirlar: ayni boydaki ardisik ogeler bir satirda (full 1, half 2, third 3), bilinmeyen kimlikler atlanir.
-- Bir satira kac oge sigar: kucuk kutucuklar (third) ayardan (db.hubCols, 2-4), digerleri sabit.
function Hub.PerRow(size)
  if size == "third" then return math.max(2, math.min(4, Island.db.hubCols or 2)) end
  return PER_ROW[size]
end

-- Ogenin satirdan kapladigi pay: tam 1, yarim 1/2, kutucuk 1/hubCols.
function Hub.Fraction(size) return 1 / (Hub.PerRow(size) or 1) end

-- Satirlar genislige gore dolar: siradaki oge satira sigiyorsa (paylar toplami <= 1) yanina gelir, sigmiyorsa yeni
-- satir baslar. Boylece yarim kartin yanina kutucuklar konabilir. Her oge kendi payi kadar yer kaplar (esnemez).
function Hub.Pack(ids, sizeOf)
  local rows, cur = {}, nil
  for i, id in ipairs(ids) do
    local size = sizeOf(id)
    if size then
      local f = Hub.Fraction(size)
      if not cur or cur.used + f > 1.001 then
        cur = { used = 0 }
        rows[#rows + 1] = cur
      end
      cur[#cur + 1] = { index = i, id = id, at = cur.used, frac = f }
      cur.used = cur.used + f
    end
  end
  return rows
end

-- Sayfalar: db.hubPages aciksa her grup basligi yeni sayfa baslatir (baslik sayfanin ilk satiri kalir) ve
-- PAGE_MAX'tan uzun bolum satir sinirindan bolunur; kapaliysa tek sayfa. Donus: { {id, ...}, ... }
local PAGE_MAX = 190
local function sizeOf(id) return DEFS[id] and DEFS[id].size end

function Hub:Pages()
  local all = {}
  for _, id in ipairs(Island.db.hub) do if DEFS[id] then all[#all + 1] = id end end
  if Island.db.hubPages == false then return #all > 0 and { all } or {} end
  local pages, cur, h = {}, nil, 0
  for _, r in ipairs(Hub.Pack(all, sizeOf)) do
    local rh, group = 0, false
    for _, e in ipairs(r) do rh = math.max(rh, heightOf(DEFS[e.id])); group = group or DEFS[e.id].group end
    if not cur or (#cur > 0 and (group or h + rh > PAGE_MAX)) then cur, h = {}, 0; pages[#pages + 1] = cur end
    for _, e in ipairs(r) do cur[#cur + 1] = e.id end
    h = h + rh + GAP
  end
  return pages
end

-- Gorunen sayfanin ogeleri ve sayfa sayisi (sayfa numarasi sinirlar icinde tutulur).
function Hub:PageIds()
  local pages = self:Pages()
  self.page = math.max(1, math.min(#pages, self.page or 1))
  return pages[self.page] or {}, #pages
end

-- Kisayollar: alt satirin solu. run savas disinda calisir (pencereler korumali degil ama acilis savasi bolmesin).
Hub.SHORTCUTS = {
  { icon = "compass", tip = "Quest Tracker", run = function() ns.PathWindow:Open("level") end },
  -- zindanin icindeyse hub o zindanin boss + loot gorunumune doner; disarida zindan rehberi sayfasi
  { icon = "shield", tip = "Dungeon Guide", run = function() if not Island:OpenDungeon() then ns.PathWindow:Open("dungeon") end end },
  { icon = "bag", tip = "Gold", run = function() ns.PathWindow:Open("gold") end },
  { icon = "bubble", tip = "Messages", run = function() if ns.Messenger then ns.Messenger:Open() end end },
  { icon = "gear", tip = "Settings", run = function() ns.Settings:Open("island") end },
}

-- Alt satir gorunur mu: kisayollar acik ya da birden cok sayfa var.
function Hub:FooterShown()
  local _, n = self:PageIds()
  return Island.db.hubShortcuts ~= false or n > 1
end

-- Sayfa degistir (d = +1 / -1, basa/sona sarar); kartlar kayarak yeniden belirir, ada yeni boya esner.
function Hub:Turn(d)
  local _, n = self:PageIds()
  if n < 2 then return end
  self.page = (self.page - 1 + d) % n + 1
  self.slide = d > 0 and 14 or -14
  self:Rebuild()
  self.age = 0
  for _, c in ipairs(self.order) do c:SetAlpha(0) end
  if Island.mode == "hub" then Island:Animate(Island:HubWidth(), Island:HubHeight()) end
end

function Hub:Rows()
  local rows = Hub.Pack((self:PageIds()), function(id) return DEFS[id] and DEFS[id].size end)
  -- satir: tanimlar (r[k]) ve yerleri (r.slots[k]: at, frac)
  for _, r in ipairs(rows) do
    r.slots = {}
    for k, e in ipairs(r) do r.slots[k], r[k] = e, DEFS[e.id] end
  end
  return rows
end

local function rowHeight(r)
  local h = 0
  for _, d in ipairs(r) do h = math.max(h, heightOf(d)) end
  return h
end

function Hub:ContentHeight()
  self.hcache = {}   -- her olcum taze; ayni olcumdeki Pages + Rows yuksekligi bir kez sorar
  local rows = self:Rows()
  local foot = self:FooterShown() and FOOTER or 0
  if #rows == 0 then return foot end
  local h = PAD
  for _, r in ipairs(rows) do h = h + rowHeight(r) + GAP end
  return h - GAP + PAD + foot
end

-- Alt satir: kisayol dugmeleri, sayfa oklari ve noktalari.
function Hub:BuildFooter()
  local f = self.frame
  local ft = CreateFrame("Frame", nil, f)
  ft:SetHeight(FOOTER)
  ft:SetPoint("BOTTOMLEFT", PAD - 4, 2); ft:SetPoint("BOTTOMRIGHT", -PAD + 4, 2)
  ft.sep = fill(ft, "ARTWORK", { 1, 1, 1 }, 0.08)
  ns.Skin:Hairline(ft.sep, "h"); ft.sep:SetPoint("TOPLEFT", 4, 0); ft.sep:SetPoint("TOPRIGHT", -4, 0)
  local function tip(btn, key)
    btn:HookScript("OnEnter", function()
      if not GameTooltip then return end
      GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM"); GameTooltip:SetText(L[key]); GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  end
  ft.shortcuts = {}
  for i, s in ipairs(Hub.SHORTCUTS) do
    local b = Skin:CreateIconButton(ft, s.icon, 22)
    b:SetPoint("LEFT", (i - 1) * 24, -1)
    b:SetScript("OnClick", function()
      if P.InCombat() then return end
      Island:CloseHub()
      ns.SafeCall(s.run)
    end)
    tip(b, s.tip)
    ft.shortcuts[i] = b
  end
  ft.dots = {}
  f.footer = ft
  -- tekerlek: sayfa degistirir
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(_, delta) Hub:Turn(delta > 0 and -1 or 1) end)
end

-- Sayfanin ikonu ve adi (nokta ipucu): ilk ogesi grup basligiysa grubun, degilse ilk kartin.
function Hub:PageInfo(i)
  local ids = self:Pages()[i]
  local d = ids and DEFS[ids[1]]
  if not d then return "menu", "" end
  if d.group then return d.icon, Island:GroupName(d.groupIndex) end
  return d.icon or "menu", L[d.name]
end

function Hub:GoTo(i)
  local _, n = self:PageIds()
  if i == self.page or i < 1 or i > n then return end
  self:Turn(i - self.page)
end

-- Sayfa noktasi: tiklaninca o sayfaya gecer, ustune gelince sayfa adi (grup basligi ya da ilk kart).
-- Kucuk dokular piksel izgarasina oturtulunca kenarlari tirtikli gorunur; izgara kapatilip yumusak suzulur.
local function smooth(t)
  if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false); t:SetTexelSnappingBias(0) end
  t._skinFixed = true
end

local function newDot(ft, i)
  local d = CreateFrame("Button", nil, ft)
  d:SetSize(12, 16)
  d.halo = d:CreateTexture(nil, "ARTWORK")   -- aktif noktanin goz gibi parlamasi
  d.halo:SetTexture(Skin.Icons.glow); d.halo:SetSize(22, 22); d.halo:SetPoint("CENTER"); smooth(d.halo)
  d.disc = d:CreateTexture(nil, "OVERLAY")
  d.disc:SetTexture(Skin.Icons.disc); d.disc:SetPoint("CENTER"); smooth(d.disc)
  d:SetScript("OnClick", function() Hub:GoTo(i) end)
  d:SetScript("OnEnter", function()
    if not GameTooltip then return end
    local _, name = Hub:PageInfo(i)
    GameTooltip:SetOwner(d, "ANCHOR_BOTTOM"); GameTooltip:SetText(name); GameTooltip:Show()
  end)
  d:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  return d
end

function Hub:LayoutFooter()
  local ft = self.frame.footer
  local _, n = self:PageIds()
  ft:SetShown(self:FooterShown())
  local short = Island.db.hubShortcuts ~= false
  for _, b in ipairs(ft.shortcuts) do b:SetShown(short) end
  local paged = n > 1
  local STEP = 12
  for i = 1, math.max(n, #ft.dots) do
    local d = ft.dots[i]
    if i <= n and paged then
      if not d then d = newDot(ft, i); ft.dots[i] = d end
      d:ClearAllPoints()
      d:SetPoint("CENTER", ft, "CENTER", (i - (n + 1) / 2) * STEP, -1)
      local on = i == self.page
      local c = on and Skin.Colors.accentHover or { 1, 1, 1 }
      d.disc:SetSize(on and 8 or 5, on and 8 or 5)
      d.disc:SetVertexColor(c[1], c[2], c[3], on and 1 or 0.3)
      d.halo:SetVertexColor(c[1], c[2], c[3], 0.55); d.halo:SetShown(on)
      d:Show()
    elseif d then
      d:Hide()
    end
  end
end

function Hub:Build()
  if self.frame then return end
  local f = CreateFrame("Frame", "ArcanisIslandHub", Island.frame)
  f:SetPoint("TOPLEFT", Island.frame, "TOPLEFT", 0, -HEADER)
  f:SetPoint("BOTTOMRIGHT", Island.frame, "BOTTOMRIGHT", 0, 0)
  f:SetClipsChildren(true)
  f:EnableMouse(true)   -- kartlara tiklamak hub'i kapatmasin (kapatma: baslik satiri, Esc, 25 sn)
  f.sep = fill(f, "ARTWORK", { 1, 1, 1 }, 0.08)
  ns.Skin:Hairline(f.sep, "h"); f.sep:SetPoint("TOPLEFT", PAD, 0); f.sep:SetPoint("TOPRIGHT", -PAD, 0)
  -- Esc: oyun cerceveyi gizler; bunu hub kapanisi say
  f:SetScript("OnHide", function() if not Hub.hiding and Island.mode == "hub" then Island:CloseHub() end end)
  if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisIslandHub") end
  f:Hide()
  self.frame = f
  self:BuildFooter()
end

-- Kart zemini ve kenari ayardan: renk (db.cardColor), zemin saydamligi (db.cardAlpha %), kenar (db.cardBorder %).
-- WoW temasinda kenar oyunun altin tooltip kenaridir (ayni renkle tonlanir). Grup basliginda zemin yok.
function Hub:StyleCard(c)
  if c.def.group then return end
  local col = Island:CardColor()
  local a, b = (Island.db.cardAlpha or 6) / 100, (Island.db.cardBorder or 8) / 100
  -- gradyan: kartin alt yarisi kendi renginde koyulasir
  local tint = Island.db.cardStyle == "gradient" and c.def.tint
  if tint then
    if not c.grad then
      c.grad = c:CreateTexture(nil, "BACKGROUND", nil, 1)
      c.grad:SetTexture(Skin.Icons.vgrad); c.grad._skinFixed = true
      c.grad:SetTexCoord(0, 1, 1, 0)   -- doku ustte koyu; ters cevrilir: renk altta
      c.grad:SetPoint("TOPLEFT", 1, -1); c.grad:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    c.grad:SetVertexColor(tint[1], tint[2], tint[3], 0.45)
    c.grad:Show()
  elseif c.grad then
    c.grad:Hide()
  end
  Skin:ApplyBackdrop(c, { col[1], col[2], col[3], a }, { col[1], col[2], col[3], b })
end

local function cardFrame(d)
  local c = CreateFrame("Frame", nil, Hub.frame, "BackdropTemplate")
  c.def = d
  Hub:StyleCard(c)
  d.build(c)
  return c
end

-- Kartlari db.hub sirasiyla yerlestirir (kartlar bir kez kurulur, sonra yeniden kullanilir).
function Hub:Rebuild()
  self.hcache = {}   -- ayar ya da sayfa degisti: yukseklikler yeniden
  self:Build()
  local w = Island:HubWidth()
  for _, c in pairs(self.cards) do c:Hide() end
  self.order = {}
  local y = PAD
  local unit = w - 2 * PAD + GAP   -- pay 1 = tam satir (araliklar dahil)
  for _, r in ipairs(self:Rows()) do
    local rh = rowHeight(r)
    for k, d in ipairs(r) do
      local s = r.slots[k]
      local cw = math.floor(s.frac * unit - GAP)
      local c = self.cards[d.id] or cardFrame(d)
      self.cards[d.id] = c
      c.w, c.baseX, c.baseY = cw, PAD + math.floor(s.at * unit + 0.5), y
      c:SetSize(cw, rh)
      c:ClearAllPoints()
      c:SetPoint("TOPLEFT", self.frame, "TOPLEFT", c.baseX, -c.baseY)
      if d.layout then d.layout(c, cw) end
      c:Show()
      self.order[#self.order + 1] = c
    end
    y = y + rh + GAP
  end
  self:LayoutFooter()
  self:UpdateCards(true)
end

-- Gorunum ayari degisti (yazi boyutu, kart saydamligi): kartlar yeniden kurulur.
function Hub:Reset()
  for _, c in pairs(self.cards) do c:Hide() end
  self.cards, self.order = {}, {}
end

function Hub:UpdateCards(sample)
  for _, c in ipairs(self.order or {}) do
    local ok, err = pcall(c.def.update, c, sample)
    if not ok then ns:Debug("hub card " .. c.def.id .. ": " .. tostring(err)) end
  end
end

function Hub:Open()
  self.tipIndex = (self.tipIndex or 0) + 1   -- Mentor karti her acilista siradaki bilgi
  self:Build()
  self:Rebuild()
  self.frame:Show()
  self.age, self.tick, self.lastH, self.slide = 0, 0, nil, nil
  for _, c in ipairs(self.order) do c:SetAlpha(0) end
end

function Hub:Hide()
  if not self.frame then return end
  self.hiding = true
  self.frame:Hide()
  self.hiding = nil
  for _, c in pairs(self.cards) do if c.def.clear then c.def.clear(c) end end
end

-- Kartlar sirayla belirir (alfa 0->1, 6 px yukaridan); saniyede bir guncellenir; XP %95'te nabiz.
-- Bolge kartinin satir sayisi degisirse (yeni bolge) hub yeniden dizilir.
function Hub:Update(dt)
  if not (self.frame and self.frame:IsShown()) then return end
  self.age = (self.age or 0) + math.min(dt, 1 / 30)
  for i, c in ipairs(self.order or {}) do
    local p = math.max(0, math.min(1, (self.age - 0.06 - (i - 1) * STAGGER) / APPEAR))
    if p < 1 or c.appearing then
      c.appearing = p < 1
      p = 1 - (1 - p) ^ 3
      c:SetAlpha(p)
      c:ClearAllPoints()
      -- acilista 6 px yukaridan; sayfa degisince yandan (gecis yonunde) kayarak gelir
      c:SetPoint("TOPLEFT", self.frame, "TOPLEFT", c.baseX + (self.slide or 0) * (1 - p), -c.baseY + (self.slide and 0 or 6) * (1 - p))
    end
    if c.pulse then c.fill:SetAlpha(0.85 + 0.15 * math.sin(self.age * math.pi / 0.6)) end
  end
  self.tick = (self.tick or 0) + dt
  if self.tick >= 1 then
    self.tick = 0
    self.hcache = {}
    local h = self:ContentHeight()
    if h ~= self.lastH and self.lastH then self:Rebuild(); Island:Animate(Island:HubWidth(), Island:HubHeight())
    else self:UpdateCards(true) end
    self.lastH = h
  end
end
