-- Arcanis: ust ada (modul "Island"). Ekranin ust kenarina yapisik cikinti:
--   kapali (line): oyuncunun sectigi bilgiler yan yana (sinirsiz, db.strip sirasiyla);
--   olay (event): jole gibi esneyerek buyur, bildirimi gosterir, sonra kuculur;
--   hub: tiklayinca serit baslik olarak kalir, altina kartlar acilir (UI/IslandHub.lua, db.hub sirasiyla).
-- Acikken ns.Toast bildirimleri buraya gelir (Toast:Show yonlendirir). Sag tik: Ayarlar > Dynamic Hub.
--   ns.Island:Push(baslik [, govde [, tur]])   tur: "info" | "warn"
local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local P = ns.Provider
local L = ns.L

local Island = ns:NewModule("Island", { defaults = {
  strip = { "zone", "step", "level", "gold" },
  hub = { "xp", "levelup", "zone", "stats", "gold", "system" },
  bg = { 0, 0, 0 }, alpha = 0.92, width = 480,
  toasts = true, zone = true, card = true, hold = 4, jelly = 60,
  sep = "dot", sepText = "", fontSize = 11, textColor = "theme", accentFirst = true,
  visible = "all",   -- kapaliyken gorunen oge sayisi ("all" ya da sayi; 0 = yalniz gozler)
  xpColor = "purple", cardAlpha = 6, hubFont = 11, brows = true,
  hubCols = 2,   -- hub'da yan yana kucuk kutucuk sayisi (2-4)
  -- gozler: bebek acik/kapali, renkler (EYE_COLORS / PUPIL_COLORS kimligi), boyutlar %, kas egimi (derece; + ic uclar asagi)
  pupils = true, eyeColor = "white", pupilColor = "black", browColor = "white",
  pupilSize = 100, eyeHeight = 100, browAngle = 0,
  cardColor = "white", cardBorder = 8, cardTitle = "theme", cardValue = "theme",
  groupNames = {},   -- hub grup basliklarinin oyuncu adlari (bos: varsayilan ad)
  itemStyle = {},    -- serit ogesi basina { color = TEXT_COLORS kimligi, size = yazi boyu, outline = true }; yoksa genel ayar
  live = true, liveFlight = true, liveHearth = true, liveQuest = true,   -- canli etkinlikler (Island.LIVE)
  peek = true,       -- fare seritte durunca altinda o anki rehber adimi
  hideCombat = false, hideCinematic = true,
  gaugeStyle = "ring", -- hub gosterge kartlari: "ring" (halka) | "bar" (cam cubuk)
  eyeStyle = "glow",   -- "glow" (parlayan oval, uyuklar) | "classic" (bebekli, kasli)
  hubPages = true, hubShortcuts = true,   -- hub: tek sayfa + oklar; alt kisayol satiri
  cardStyle = "flat",  -- "flat" | "gradient" (kart altinda kendi renginde gecis)
  castBar = true, liveLure = true, liveBoat = true,
  badgeMail = true, badgeWhisper = true,   -- seridin sag ucunda okunmamis posta / yeni fisilti ikonu
  dungeonMine = false,   -- hub zindan gorunumu: "Only loot for me" (UI/IslandDungeon.lua)
} })
ns.Island = Island

local SMALL_H, MIN_W, MAX_W = 28, 160, 720
Island.SMALL_H = SMALL_H
local WIDE_W, WIDE_H = 380, 60
local RADIUS = 13
local CAST_EXTRA, CAST_BAR_Y = 6, 8   -- cast barinda govde biraz uzar; cizgi yazinin altinda, alt kenardan ayrik
local PAD, GAP = 16, 12
local WARN = Skin.Colors.bad
local AUTO_CLOSE = 25   -- sn: fare hub'dan ayrildiktan sonra kapanir
local EYES_W = 76       -- yalniz gozler gorunurken serit genisligi
local REVEAL_LEAVE = 0.4   -- sn: fare ayrildiktan sonra gizli ogeler kapanir
local PEEK_DELAY, PEEK_H = 0.35, 18   -- fare bu kadar durunca serit asagi uzar, altinda rehber adimi
local PILL_GAP = 6         -- canli etkinlik adasi ile serit arasi
local HEARTH, HEARTH_SOON = 6948, 300   -- ocak tasi: son 5 dk geri sayilir

local function num(v) return type(v) == "number" and v or 0 end

-- Geri sayim metni: 1:05 ya da 1:02:05
local function clock(s)
  s = math.max(0, math.floor(s + 0.5))
  local h, m = math.floor(s / 3600), math.floor(s % 3600 / 60)
  if h > 0 then return ("%d:%02d:%02d"):format(h, m, s % 60) end
  return ("%d:%02d"):format(m, s % 60)
end
Island.Clock = clock
Island.HEARTH = HEARTH

-- Canli etkinlikler: seridin yaninda kucuk ayri adalarda geri sayim. get: etiket, deger
-- ya da nil. Siradaki ilk iki etkin olan gosterilir (ilki sagda, ikincisi solda). key: acip kapatan db alani.
Island.LIVE = {
  { id = "flight", key = "liveFlight", get = function()
    local T = ns.Travel
    local f = T and T.flight
    if not (f and f.t and P.OnTaxi()) then return nil end
    local spent = P.Now() - f.t
    local known = (T.db.flights and T.db.flights[f.from .. ">" .. f.to])
      or T:DataFlight(T:NodeNamed(f.from), T:NodeNamed(f.to))
    local to = tostring(f.to):match("^([^,]+)") or tostring(f.to)
    -- bilinen yol: kalan sure; ilk ucus: havada gecen sure (+)
    return to, known and clock(known - spent) or "+" .. clock(spent)
  end },
  { id = "hearth", key = "liveHearth", get = function()
    if (P.ItemCount(HEARTH) or 0) < 1 then return nil end
    local cd = P.ItemCooldown(HEARTH)
    if cd and cd > 2 and cd <= HEARTH_SOON then return L["Hearthstone"], clock(cd) end
  end },
  { id = "boat", key = "liveBoat", get = function()
    return ns.Transport and ns.Transport:LiveText()
  end },
  { id = "lure", key = "liveLure", get = function()
    local Pa = ns.ProfActivity
    local t = Pa and Pa:IsEnabled() and Pa:Lure()
    if t then return L["Lure"], clock(t) end
  end },
  { id = "quest", key = "liveQuest", get = function()
    local t = P.QuestTimers()[1]
    if t then return t.quest and P.QuestName(t.quest, L["Timed quest"]) or L["Timed quest"], clock(t.left) end
  end },
}


-- Seritte gosterilebilecek bilgiler: { id, ad (L anahtari), deger fonksiyonu (nil/"" ise oge gizlenir) }
Island.ELEMENTS = {
  { id = "zone", name = "Zone", get = function() return P.ZoneText() end },
  { id = "subzone", name = "Subzone", get = function() return P.SubZoneText and P.SubZoneText() end },
  { id = "step", name = "Guide step", get = function()
    local E = ns.Engine
    if E and E.guide and E.index then return ("%d/%d"):format(E.index, #E.guide.steps) end
  end },
  { id = "nextzone", name = "Next step zone", get = function()
    local step = ns.Engine and ns.Engine:GetStep()
    return step and step.zone
  end },
  { id = "level", name = "Level and XP", get = function()
    local xp, max, level = P.XP()
    return ("%d (%d%%)"):format(level, math.floor(xp / math.max(1, max) * 100))
  end },
  { id = "rested", name = "Rested XP", get = function()
    local r = P.RestXP()
    if r > 0 then return "|cff4d9be6" .. r .. "|r" end
  end },
  { id = "xph", name = "XP per hour", get = function() return ns.Leveling and ns.Leveling:Line() end },
  { id = "xpleft", name = "XP to level", get = function()
    local xp, max = P.XP()
    return ns.Leveling and ns.Leveling.FormatXP(math.max(0, max - xp)) or tostring(max - xp)
  end },
  { id = "ttl", name = "Time to level", get = function()
    local s = ns.Leveling and ns.Leveling:TimeToLevel()
    return s and ns.Leveling.FormatTime(s)
  end },
  { id = "session", name = "Session time", get = function()
    local Lv = ns.Leveling
    return Lv and Lv.started and Lv.FormatTime(P.Now() - Lv.started)
  end },
  { id = "gold", name = "Gold", get = function() return P.MoneyText(P.Money()) end },
  { id = "goldh", name = "Gold per hour", get = function()
    local s = ns.Gold and ns.Gold.Summary and ns.Gold:Summary()
    if s and s.rate then return P.MoneyText(math.max(0, s.rate)) .. "/h" end
  end },
  { id = "mail", name = "Mail", get = function() return P.HasNewMail() and L["New mail"] or nil end },
  { id = "gathering", name = "Gathering", get = function()
    local Pa = ns.ProfActivity
    local s = Pa and Pa.session
    if not s then return nil end
    local r = Pa:SessionRate()
    return r and P.MoneyText(math.max(0, r)) .. "/h" or tostring(s.nodes + s.catches)
  end },
  { id = "bags", name = "Free bag slots", get = function()
    return P.FreeBagSlots()
  end },
  { id = "durability", name = "Durability", get = function()
    local r = P.LowestDurability()
    if r then return math.floor(r * 100 + 0.5) .. "%" end
  end },
  { id = "fps", name = "FPS", get = function()
    local s = P.SystemStats()
    if s.fps then return ("%d fps"):format(s.fps) end
  end },
  { id = "ping", name = "Latency", get = function()
    local s = P.SystemStats()
    if s.world then return ("%d ms"):format(math.max(s.home or 0, s.world)) end
  end },
  { id = "memory", name = "Memory", get = function()
    local s = P.SystemStats()
    if s.luaKB then return ("%.1f MB"):format(s.luaKB / 1024) end
  end },
  { id = "clock", name = "Clock", get = function() return date and date("%H:%M") end },
  { id = "coords", name = "Coordinates", get = function()
    local _, x, y = P.PlayerMapPosition()
    if x then return ("%.1f, %.1f"):format(x * 100, y * 100) end
  end },
}
-- Karakter statlari: sinifa gore ana stat, kritik/isabet (buyucu, avci) ve guc. Hub'daki stat karti da bunu kullanir.
-- Doner: { main = {ad, deger}, stamina = ..., armor, crit, hit, power } (sira STAT_ORDER)
local STAT_ORDER = { "main", "stamina", "armor", "crit", "hit", "power" }
function Island:StatValues()
  if self.statCache then return self.statCache end   -- LayoutRow suresince bir kez okunur (her stat ogesi iki kez sorar)
  local s = P.PlayerStatBlock()
  local class = P.PlayerClassToken and P.PlayerClassToken() or ""
  local caster = ({ MAGE = 1, PRIEST = 1, WARLOCK = 1, DRUID = 1, SHAMAN = 1 })[class]
  local primary = ({ WARRIOR = "str", PALADIN = "str", ROGUE = "agi", HUNTER = "agi" })[class] or "int"
  local names = { str = L["Strength"], agi = L["Agility"], int = L["Intellect"] }
  local function num(v)
    if not v then return "-" end
    v = math.floor(v + 0.5)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(v) or tostring(v)
  end
  local function pct(v) return v and ("%.1f%%"):format(v) or "-" end
  local power = class == "HUNTER" and s.rap or s.ap
  local v = {
    main = { names[primary], num(s[primary]) },
    stamina = { L["Stamina"], num(s.sta) },
    armor = { L["Armor"], num(s.armor) },
    crit = { L["Crit"], pct(caster and s.spellCrit or (class == "HUNTER" and s.rangedCrit) or s.crit) },
    hit = { L["Hit"], pct(caster and s.spellHit or s.hit) },
    power = caster and { L["Spell damage"], num(s.spellDamage) } or { L["Attack power"], num(power) },
  }
  if self.statPass then self.statCache = v end
  return v
end
Island.STAT_ORDER = STAT_ORDER
-- her stat ayri bir oge de olur (barda "Kritik 5.0%", hub'da kendi kutucugu); tag: barda degerin onundeki ad
for _, st in ipairs({
  { key = "main", name = "Main stat" }, { key = "stamina", name = "Stamina" }, { key = "armor", name = "Armor" },
  { key = "crit", name = "Crit" }, { key = "hit", name = "Hit" }, { key = "power", name = "Power" },
}) do
  local k = st.key
  Island.ELEMENTS[#Island.ELEMENTS + 1] = {
    id = "stat_" .. k, name = st.name,
    get = function() return Island:StatValues()[k][2] end,
    tag = function() return Island:StatValues()[k][1] end,
  }
end

local BY_ID = {}
for _, e in ipairs(Island.ELEMENTS) do BY_ID[e.id] = e end
Island.BY_ID = BY_ID

-- Ogeler arasi ayrac (db.sep); "custom": db.sepText
Island.SEPARATORS = {
  { id = "dot", text = "·" }, { id = "bullet", text = "•" }, { id = "bar", text = "|" },
  { id = "slash", text = "/" }, { id = "dash", text = "-" }, { id = "none", text = "" }, { id = "custom" },
}
function Island:SepText()
  if self.db.sep == "custom" then return self.db.sepText or "" end
  for _, s in ipairs(self.SEPARATORS) do if s.id == self.db.sep then return s.text end end
  return "·"
end

-- Hub grup basliklari: listeye konan baslik altindaki ogeler bir grup gibi durur
-- Hub bolum basliklari (en fazla dort); adini oyuncu yazar, bossa "Section N".
Island.GROUPS = {
  { id = "group1", name = "Section" }, { id = "group2", name = "Section" },
  { id = "group3", name = "Section" }, { id = "group4", name = "Section" },
}
function Island:GroupName(i)
  local custom = self.db.groupNames[i]
  if custom and custom ~= "" then return custom end
  return L[self.GROUPS[i].name] .. " " .. i
end
-- Ayarlardaki ekleme dugmelerinin kategorileri; burada olmayan yeni bilgi "Other" altinda cikar.
Island.CATEGORIES = {
  { name = "World", ids = { "zone", "subzone", "coords", "step", "nextzone" } },
  { name = "Character", ids = { "level", "rested", "xph", "xpleft", "ttl", "session" } },
  { name = "Economy", ids = { "gold", "goldh", "gathering", "bags", "durability", "mail" } },
  { name = "System", ids = { "fps", "ping", "memory", "clock" } },
  { name = "Stats", ids = { "stat_main", "stat_stamina", "stat_armor", "stat_crit", "stat_hit", "stat_power" } },
}

-- Serit yazi rengi (db.textColor)
Island.TEXT_COLORS = {
  { id = "theme" }, { id = "white", c = { 1, 1, 1 } }, { id = "gold", c = { 1, 0.82, 0 } },
  { id = "grey", c = { 0.72, 0.72, 0.72 } }, { id = "blue", c = { 0.55, 0.78, 1 } }, { id = "green", c = { 0.55, 0.9, 0.55 } },
}
-- Renk ayarlari ya hazir bir kimlik (eski kayitlar, varsayilanlar) ya da renk seciciden {r,g,b} tutar.
-- id: {r,g,b}, TEXT_COLORS kimligi; "theme" ya da bilinmeyen -> fallback
function Island:ColorOf(id, fallback)
  if type(id) == "table" then return { id[1], id[2], id[3], 1 } end
  for _, t in ipairs(self.TEXT_COLORS) do if t.id == id and t.c then return { t.c[1], t.c[2], t.c[3], 1 } end end
  return fallback
end
function Island:TextColor() return self:ColorOf(self.db.textColor, Skin.Colors.text) end

-- Hub kart zemini renkleri (db.cardColor); saydamlik db.cardAlpha, kenar db.cardBorder (%)
Island.CARD_COLORS = {
  { id = "white", c = { 1, 1, 1 } }, { id = "black", c = { 0, 0, 0 } }, { id = "gold", c = { 1, 0.82, 0 } },
  { id = "blue", c = { 0.30, 0.50, 1 } }, { id = "purple", c = { 0.60, 0.30, 0.90 } },
  { id = "green", c = { 0.30, 0.80, 0.40 } }, { id = "red", c = { 0.90, 0.30, 0.30 } },
}
-- Goz ve kas renkleri (db.eyeColor, db.browColor) ile goz bebegi renkleri (db.pupilColor)
Island.EYE_COLORS = {
  { id = "white", c = { 1, 1, 1 } }, { id = "cream", c = { 1, 0.94, 0.80 } }, { id = "gold", c = { 1, 0.82, 0 } },
  { id = "blue", c = { 0.55, 0.78, 1 } }, { id = "green", c = { 0.55, 0.9, 0.55 } }, { id = "pink", c = { 1, 0.62, 0.78 } },
}
Island.PUPIL_COLORS = {
  { id = "black", c = { 0.08, 0.08, 0.12 } }, { id = "brown", c = { 0.36, 0.20, 0.08 } }, { id = "blue", c = { 0.12, 0.30, 0.75 } },
  { id = "green", c = { 0.10, 0.50, 0.20 } }, { id = "red", c = { 0.75, 0.10, 0.10 } }, { id = "purple", c = { 0.45, 0.15, 0.70 } },
}
function Island:PickColor(list, id)
  if type(id) == "table" then return id end
  for _, t in ipairs(list) do if t.id == id then return t.c end end
  return list[1].c
end

function Island:CardColor() return self:PickColor(self.CARD_COLORS, self.db.cardColor) end

-- Listeler (ayar sayfasi bunlari kullanir): "strip" (serit ogeleri) ve "hub" (hub kartlari), sirali kimlikler.
-- Bir kimlik listede bir kez durur.
function Island:Insert(list, id, pos)
  local t = self.db[list]
  for i = #t, 1, -1 do
    if t[i] == id then table.remove(t, i); if pos and i < pos then pos = pos - 1 end end
  end
  pos = math.max(1, math.min(pos or #t + 1, #t + 1))
  table.insert(t, pos, id)
  self:Changed()
end

function Island:Move(list, from, to)
  local t = self.db[list]
  local id = table.remove(t, from)
  if not id then return end
  table.insert(t, math.max(1, math.min(to, #t + 1)), id)
  self:Changed()
end

function Island:Remove(list, i)
  table.remove(self.db[list], i)
  self:Changed()
end

function Island:Has(list, id)
  for _, v in ipairs(self.db[list]) do if v == id then return true end end
  return false
end

-- bare: hub kutucugu kendi basligini yazdigi icin degerin onundeki ad (tag) eklenmez
function Island:ItemText(id, bare)
  local e = BY_ID[id]
  if not e then return "" end
  local ok, v = pcall(e.get)
  if not (ok and v) then return "" end
  if e.tag and not bare then
    local ok2, t = pcall(e.tag)
    if ok2 and t then return t .. " " .. tostring(v) end
  end
  return tostring(v)
end

-- Ayar degisti: gorunumu yeniden kur. rebuild: hub kartlari bastan kurulur (yazi boyutu degisti).
-- Kartlar silinemeyen cercevelerdir: kaydirici surukleme boyunca her adimda degil, durunca bir kez kurulur.
local REBUILD_WAIT = 0.4
function Island:Changed(rebuild, now)
  if not self.frame then return end
  if rebuild and not now then
    self.rebuildSeq = (self.rebuildSeq or 0) + 1
    local seq = self.rebuildSeq
    if P.After and P.After(REBUILD_WAIT, function() if Island.rebuildSeq == seq then Island:Changed(true, true) end end) then
      rebuild = false
    end
  end
  self:ApplyColors()
  if self.Hub then
    if rebuild then self.Hub:Reset() end
    for _, c in pairs(self.Hub.cards) do self.Hub:StyleCard(c) end
  end
  if self.mode == "hub" and self.Hub and not self.chatOpen and not self.dungeonOpen then self.Hub:Rebuild(); self:Animate(self:HubWidth(), self:HubHeight()) end
  if not self.db.peek then self:Peek(false) end
  self:Refresh(true)
  self:UpdateShown()
end

-- Cerceve: ust kenara yapisik, alt koseleri yuvarlak govde (renk ve saydamlik ayarlanir)
-- Alt koseleri yuvarlak govde dokulari (serit ve canli etkinlik adalari); f.pieces'e yazar.
local function shell(f)
  local function piece(path)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(path or "Interface\\Buttons\\WHITE8x8")
    t._skinFixed = true
    return t
  end
  local top, bottom = piece(), piece()
  top:SetPoint("TOPLEFT"); top:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, RADIUS)
  bottom:SetPoint("BOTTOMLEFT", RADIUS, 0); bottom:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -RADIUS, RADIUS)
  local bl, br = piece(Skin.Icons.corner), piece(Skin.Icons.corner)
  bl:SetSize(RADIUS, RADIUS); bl:SetPoint("BOTTOMLEFT"); bl:SetTexCoord(0, 1, 1, 0)
  br:SetSize(RADIUS, RADIUS); br:SetPoint("BOTTOMRIGHT"); br:SetTexCoord(1, 0, 1, 0)
  f.pieces = { top, bottom, bl, br }
end

function Island:Build()
  if self.frame then return end
  local f = CreateFrame("Button", "ArcanisIsland", UIParent)
  Skin:RegisterRoot(f)
  f:SetSize(MIN_W, SMALL_H)
  f:SetPoint("TOP", UIParent, "TOP", 0, 0)
  f:SetFrameStrata("HIGH")
  f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  shell(f)

  -- baslik satiri: serit ogeleri bu cercevede (hub acikken de ustte kalir)
  f.row = CreateFrame("Frame", nil, f)
  f.row:SetPoint("TOPLEFT"); f.row:SetPoint("TOPRIGHT")
  f.row:SetHeight(SMALL_H)
  f.items, f.dots = {}, {}

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f.title, 13, "")
  f.title:SetPoint("TOPLEFT", PAD, -10); f.title:SetPoint("TOPRIGHT", -PAD, -10)
  f.title:SetJustifyH("CENTER")
  f.title:SetWordWrap(false)
  f.body = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f.body, 11, "")
  f.body:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4); f.body:SetPoint("RIGHT", -PAD, 0)
  f.body:SetJustifyH("CENTER"); f.body:SetJustifyV("TOP")
  f.body:SetTextColor(unpack(Skin.Colors.textDim))
  -- sayacli bildirimin cubugu (beceri serisi): govdenin altinda ince iz + dolan cizgi
  local cb = CreateFrame("Frame", nil, f)
  cb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", RADIUS + 10, 8); cb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RADIUS - 10, 8)
  cb:SetHeight(4)
  cb.track = cb:CreateTexture(nil, "ARTWORK")
  cb.track:SetTexture("Interface\\Buttons\\WHITE8x8"); cb.track._skinFixed = true
  cb.track:SetVertexColor(1, 1, 1, 0.12); cb.track:SetAllPoints()
  cb.fill = cb:CreateTexture(nil, "OVERLAY")
  cb.fill:SetTexture("Interface\\Buttons\\WHITE8x8"); cb.fill._skinFixed = true
  cb.fill:SetVertexColor(0.40, 0.95, 0.55, 0.9)
  cb.fill:SetPoint("TOPLEFT"); cb.fill:SetPoint("BOTTOMLEFT"); cb.fill:SetWidth(1)
  cb:Hide()
  f.countBar = cb
  -- hub acikken bildirim: baslik satirinda gecici yazi
  f.notice = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f.notice, 11, "")
  f.notice:SetPoint("TOP", 0, -8)
  f.notice:Hide()
  -- fare seritte durunca: serit asagi uzar, altinda o anki rehber adimi (Peek)
  f.peek = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f.peek, 10, "")
  f.peek:SetPoint("TOPLEFT", PAD, -(SMALL_H - 4)); f.peek:SetPoint("TOPRIGHT", -PAD, -(SMALL_H - 4))
  f.peek:SetJustifyH("CENTER"); f.peek:SetWordWrap(false)
  f.peek:SetTextColor(unpack(Skin.Colors.textDim))
  f.peek:Hide()
  -- meslek cast'i: ad, kalan sure; yazinin altinda, kenardan ayrik dolan ince cizgi (OnProfCast)
  local c = CreateFrame("Frame", nil, f)
  c:SetPoint("TOPLEFT"); c:SetPoint("TOPRIGHT"); c:SetHeight(SMALL_H)
  c.label = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(c.label, 11, ""); c.label:SetPoint("LEFT", 14, 1); c.label:SetWordWrap(false)
  c.time = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(c.time, 11, "OUTLINE"); c.time:SetPoint("RIGHT", -14, 1); c.time:SetJustifyH("RIGHT")
  c.time:SetWidth(40)   -- sabit genislik: geri sayim degistikce ortadaki ad kaymasin
  c.label:SetPoint("RIGHT", c.time, "LEFT", -8, 0)
  c.track = c:CreateTexture(nil, "ARTWORK")
  c.track:SetTexture("Interface\\Buttons\\WHITE8x8"); c.track._skinFixed = true
  c.track:SetVertexColor(1, 1, 1, 0.12); c.track:SetHeight(3)
  c.track:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", RADIUS + 4, CAST_BAR_Y); c.track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RADIUS - 4, CAST_BAR_Y)
  c.bar = c:CreateTexture(nil, "OVERLAY")
  c.bar:SetTexture("Interface\\Buttons\\WHITE8x8"); c.bar._skinFixed = true
  c.bar:SetHeight(3); c.bar:SetPoint("BOTTOMLEFT", c.track, "BOTTOMLEFT")
  c:Hide()
  f.cast = c

  f:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
      if ns.Settings and not P.InCombat() then ns.Settings:Open("island") end
    elseif (Island.mode == "event" or Island.mode == "hub") and Island.current and Island.current.action then
      -- eylem yapildi (esya giyildi, sayfa acildi): bildirim kapanir; fare ustunde kalsa da beklemez
      if not P.InCombat() then
        local cur = Island.current
        ns.SafeCall(cur.action)
        if Island.current == cur then Island:Dismiss() end
      end
    elseif Island.mode ~= "hub" and ns.Messenger and ns.Messenger:IsEnabled() and ns.Messenger:UnreadTotal() > 0 then
      Island:OpenChat()   -- okunmamis fisilti varken ada sohbeti acar
    else
      Island:ToggleHub()
    end
  end)
  f:SetScript("OnEnter", function()
    Island.hover = true; Island.away = 0; Island.leaveAge = nil; Island.peekAge = 0
    Island:Wake(); Island:Reveal(true)
  end)
  f:SetScript("OnLeave", function() Island.hover = false; Island.leaveAge = 0 end)
  f:SetScript("OnUpdate", function(_, dt) Island:Update(dt) end)
  self.frame = f
  self.w, self.h, self.vw, self.vh = MIN_W, SMALL_H, 0, 0
  self.fadeAge, self.away = 1, 0
  self:BuildEyes()
  self:ApplyColors()
  self:ShowLine()
end

function Island:ApplyColors()
  local c, a = self.db.bg or { 0, 0, 0 }, self.db.alpha or 0.92
  for _, t in ipairs(self.frame.pieces) do t:SetVertexColor(c[1], c[2], c[3], a) end
  for _, p in ipairs(self.pills or {}) do
    for _, t in ipairs(p.pieces) do t:SetVertexColor(c[1], c[2], c[3], a) end
  end
  for _, p in ipairs(self.extraShells or {}) do
    for _, t in ipairs(p.pieces) do t:SetVertexColor(c[1], c[2], c[3], a) end
  end
  self:ApplyEyes()
end

-- Baska modulun cercevesine adanin govdesi (alt koseleri yuvarlak, adanin renginde): yan ada gibi gorunsun
-- (rehber adadayken gorev esyasi paneli, Helpers/QuestItem.lua). f.pieces doner; renk ApplyColors'ta.
function Island:AddShell(f)
  if f.pieces then return f.pieces end
  shell(f)
  self.extraShells = self.extraShells or {}
  table.insert(self.extraShells, f)
  if self.frame then self:ApplyColors() end
  return f.pieces
end
Island.PILL_GAP = PILL_GAP

-- Canli etkinlik adalari: seridin saginda (1) ve solunda (2), seritle ayni renkte kucuk govdeler.
function Island:Pill(i)
  self.pills = self.pills or {}
  local p = self.pills[i]
  if p then return p end
  local f = self.frame
  p = CreateFrame("Frame", nil, f)
  p:SetHeight(SMALL_H)
  shell(p)
  p.label = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(p.label, 11, "")
  p.label:SetPoint("LEFT", 12, 1); p.label:SetWordWrap(false)
  p.value = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(p.value, 11, "OUTLINE")
  p.value:SetPoint("LEFT", p.label, "RIGHT", 6, 0)
  if i == 1 then p:SetPoint("TOPLEFT", f, "TOPRIGHT", PILL_GAP, 0)
  else p:SetPoint("TOPRIGHT", f, "TOPLEFT", -PILL_GAP, 0) end
  p:Hide()
  self.pills[i] = p
  self:ApplyColors()
  return p
end

-- Etkin canli etkinlikler: { {etiket, deger}, ... } (en fazla iki; hub acikken yok)
function Island:LiveActivities()
  local out = {}
  if not self.db.live or self.mode == "hub" then return out end
  for _, a in ipairs(self.LIVE) do
    if self.db[a.key] ~= false then
      local ok, label, value = pcall(a.get)
      if ok and label then out[#out + 1] = { label = label, value = value or "" } end
      if #out == 2 then break end
    end
  end
  return out
end

function Island:LayoutLive()
  if not self.frame then return end
  local acts = self:LiveActivities()
  for i = 1, 2 do
    local a = acts[i]
    if a then
      local p = self:Pill(i)
      p.label:SetText(a.label); p.value:SetText(a.value)
      p.label:SetTextColor(unpack(Skin.Colors.accentHover))
      p.value:SetTextColor(unpack(self:TextColor()))
      p:SetWidth(24 + num(p.label:GetStringWidth()) + 6 + num(p.value:GetStringWidth()))
      if not p.on then p.on, p.fade = true, 0; p:SetAlpha(0) end   -- belirerek gelir
      p:Show()
    elseif self.pills and self.pills[i] then
      self.pills[i].on = nil; self.pills[i]:Hide()
    end
  end
  self.liveCount = #acts
  self:WatchHearth()
end

-- Ocak tasi beklemesi bitince bir kez haber verir (yalniz bekledigini gordugu ocak tasi icin).
function Island:WatchHearth()
  if not (self.db.live and self.db.liveHearth ~= false) or (P.ItemCount(HEARTH) or 0) < 1 then
    self.hearthWait = nil
    return
  end
  local cd = P.ItemCooldown(HEARTH)
  if not cd then return end
  if cd > 2 then self.hearthWait = true
  elseif self.hearthWait then
    self.hearthWait = nil
    self:Push(L["Hearthstone ready"], nil, "info")
  end
end

-- Gorunurluk: ara sahne / film boyunca ve (istenirse) savasta gizlenir. Canli adalar seridin cocugudur, onunla gizlenir.
function Island:UpdateShown()
  if not self.frame then return end
  self.frame:SetShown(not self:Hidden())
end

-- Gizli mi: ara sahnede (istenirse) ve savasta (istenirse). Rehber adadaysa savasta gizlenmez (yol gosteriyor).
function Island:Hidden()
  local docked = ns.GuideDocked and ns.GuideDocked()
  return (self.cinematic and self.db.hideCinematic) or (self.fighting and self.db.hideCombat and not docked) or false
end

function Island:OnCinematic(on) self.cinematic = on; self:UpdateShown() end
function Island:OnFight(on)
  self.fighting = on
  self:UpdateShown()
  if not on then self:Next() end
end

-- Goz ayarlari (renk, bebek boyutu); kirpma ve egim StepEyes'ta her karede uygulanir.
function Island:ApplyEyes()
  local e = self.frame and self.frame.eyeFrame
  if not e then return end
  local ec = self:PickColor(self.EYE_COLORS, self.db.eyeColor)
  local pc = self:PickColor(self.PUPIL_COLORS, self.db.pupilColor)
  local bc = self:PickColor(self.EYE_COLORS, self.db.browColor)
  for _, eye in ipairs(e.eyes) do
    eye.eye:SetVertexColor(ec[1], ec[2], ec[3], 1)
    eye.pupil:SetVertexColor(pc[1], pc[2], pc[3], 1)
    eye.brow:SetVertexColor(bc[1], bc[2], bc[3], 0.9)
  end
  self:StyleEyes()
end

-- Jole animasyonu: genislik ve yukseklik ayri yaylarla hedefe gider. Yukseklik yayi daha yumusak (geride kalir),
-- genislik hizla acilirken govde bir an basilir (hacim korunuyormus gibi), sonra sallanarak oturur.
-- jelly 0 = sallanmadan oturur, 100 = cok sallanir.
local STIFF = 190
local SUB = 1 / 120

function Island:SpringParams()
  local jelly = math.max(0, math.min(100, self.db.jelly or 60)) / 100
  local zeta = 1 - 0.78 * jelly            -- sonum orani: 1 (sallanmaz) .. 0.22 (jole)
  return STIFF, 2 * zeta * math.sqrt(STIFF), STIFF * 0.62, 2 * zeta * math.sqrt(STIFF * 0.62)
end

-- Kuculurken govde hedefin altina inmez (yazilar zeminsiz kalmasin); sallanmayi yazilar yapar (Bounce).
function Island:Animate(w, h)
  self.shrinkW, self.shrinkH = w < (self.w or w), h < (self.h or h)
  if self.shrinkH then self:Bounce() end
  self.tw, self.th = w, h
  self.fadeAge = 0
end

-- Serit yazilari yukari sicrayip yerine oturur (jole miktariyla).
function Island:Bounce()
  self.ry, self.rvy = 0, 70 + 50 * (self.db.jelly or 60) / 100
end

function Island:StepBounce(dt)
  if not self.ry then return end
  local k = 320
  local c = 2 * (1 - 0.7 * (self.db.jelly or 60) / 100) * math.sqrt(k)
  local left = math.min(dt, 0.1)
  while left > 0 do
    local s = math.min(SUB, left)
    self.rvy = self.rvy + (-k * self.ry - c * self.rvy) * s
    self.ry = self.ry + self.rvy * s
    left = left - s
  end
  if math.abs(self.ry) < 0.2 and math.abs(self.rvy) < 2 then self.ry, self.rvy = nil, nil end
  local row = self.frame.row
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", 0, self.ry or 0); row:SetPoint("TOPRIGHT", 0, self.ry or 0)
end

-- Sekme orani: jelly 0 -> sekmez, 100 -> hizinin %65'iyle geri seker.
function Island:Rebound() return 0.65 * math.max(0, math.min(100, self.db.jelly or 60)) / 100 end

function Island:StepSpring(dt)
  if not self.tw then return false end
  local kw, cw, kh, ch = self:SpringParams()
  local left = math.min(dt, 0.1)
  while left > 0 do
    local s = math.min(SUB, left)
    self.vw = self.vw + (kw * (self.tw - self.w) - cw * self.vw) * s
    self.vh = self.vh + (kh * (self.th - self.h) - ch * self.vh) * s
    self.w = self.w + self.vw * s
    self.h = self.h + self.vh * s
    -- kuculurken hedefe degince geri seker (hedefin altina inmez, jole gibi oturur)
    if self.shrinkW and self.w < self.tw then self.w, self.vw = self.tw, -self.vw * self:Rebound() end
    if self.shrinkH and self.h < self.th then self.h, self.vh = self.th, -self.vh * self:Rebound() end
    left = left - s
  end
  local settled = math.abs(self.tw - self.w) < 0.3 and math.abs(self.vw) < 2
    and math.abs(self.th - self.h) < 0.3 and math.abs(self.vh) < 2
  if settled then
    self.w, self.h, self.vw, self.vh = self.tw, self.th, 0, 0
    self.tw, self.th = nil, nil
  end
  -- hizla genislerken basilir; kuculurken basilma yok (hedefin altina inmesin)
  local squash = self.shrinkH and 0 or math.max(0, math.min(6, self.vw * 0.012))
  self.frame:SetSize(math.max(RADIUS * 2, self.w), math.max(RADIUS + 4, self.h - squash))
  return true
end

function Island:Update(dt)
  -- animasyon adimi en fazla 1/30 sn: takilan bir kare (ilk acilista kart kurulumu) animasyonu atlatmasin
  local adt = math.min(dt, 1 / 30)
  self:StepSpring(adt)
  self:StepBounce(adt)
  self:StepEyes(adt)
  self:StepBadges(adt)
  if self.Dock then self.Dock:Tick(dt) end
  if self.leaveAge then
    self.leaveAge = self.leaveAge + dt
    if self.leaveAge >= REVEAL_LEAVE then self.leaveAge = nil; self:Peek(false); self:Reveal(false) end
  end
  if self.hover and self.peekAge and self.mode == "line" then
    self.peekAge = self.peekAge + dt
    if self.peekAge >= PEEK_DELAY then self.peekAge = nil; self:Peek(true) end
  end
  local f = self.frame
  if self.fadeAge < 1 then
    self.fadeAge = math.min(1, self.fadeAge + adt / 0.22)
    -- serit yazilari govdeden genisse (hub acilirken tum ogeler) govde yetisene kadar gorunmez
    if self.tw and (self.mode == "line" or self.mode == "hub") and self.w < (self.rowW or 0) - 1 then self.fadeAge = 0 end
    local a = self.fadeAge
    f.row:SetAlpha(a); f.title:SetAlpha(a); f.body:SetAlpha(a); f.peek:SetAlpha(a)
  end
  for _, p in ipairs(self.pills or {}) do
    if p.fade and p.fade < 1 then p.fade = math.min(1, p.fade + adt / 0.3); p:SetAlpha(p.fade) end
  end
  if self.mode == "cast" then self:StepCast(dt) end
  if self.mode == "hub" then
    if self.Hub and not self.chatOpen and not self.guideOpen and not self.dungeonOpen then self.Hub:Update(dt) end
    if self.guideOpen and self.Dock then self.Dock:Follow() end
    -- sohbet, zindan ve rehber kendiliginden kapanmaz (Esc / baslik); hub fare ayrilinca kapanir
    if self.chatOpen or self.guideOpen or self.dungeonOpen or self:MouseOnHub() or self:SettingsOpen() then self.away = 0
    else
      self.away = (self.away or 0) + dt
      if self.away >= AUTO_CLOSE then self:CloseHub() end
    end
  end
  self:Tick(dt)
  -- rehber adadayken gorev esyasi paneli adanin yaninda: ada esneyince savas disinda pesinden gider
  self.itemAcc = (self.itemAcc or 0) + dt
  if self.itemAcc >= 0.1 then
    self.itemAcc = 0
    local QI = ns.QuestItem
    local docked = ns.GuideDocked and ns.GuideDocked()
    -- gizli panel gosterilirken zaten yerlesir (QI:Update); gizliyken ya da modul kapaliyken bos is yapilmaz
    if QI and QI.panel and QI.panel:IsShown() and QI:IsEnabled() and (docked or QI.panel.hub) and not P.InCombat() then
      QI:Place()
    end
  end
end

-- Serit satiri: ogeler yan yana, araya soluk nokta; satir ortalanir.
local function rowItem(f, i)
  local fs = f.items[i]
  if not fs then
    fs = f.row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Skin:SetFont(fs, 11, "")
    fs:SetWordWrap(false)
    f.items[i] = fs
    local dot = f.row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Skin:SetFont(dot, 11, "")
    dot:SetText("·")
    dot:SetTextColor(1, 1, 1, 0.3)
    f.dots[i] = dot
  end
  return fs, f.dots[i]
end

-- Kapaliyken gosterilecek oge sayisi: db.visible "all" ya da sayi (0 = yalniz gozler). Fare seritteyken
-- (revealed) ve hub acikken hepsi gosterilir.
function Island:VisibleLimit()
  local v = self.db.visible
  if v == "all" or self.revealed or self.mode == "hub" then return math.huge end
  return tonumber(v) or math.huge
end

-- Ogeleri yazar ve satirin dogal genisligini dondurur. Hic oge gorunmuyorsa gozler acilir.
function Island:LayoutRow()
  local f = self.frame
  local shown, widths, total = {}, {}, 0
  local C = Skin.Colors
  local size, sep, color = self.db.fontSize or 11, self:SepText(), self:TextColor()
  local limit = self:VisibleLimit()
  self.hiddenCount = 0
  self.statPass, self.statCache = true, nil
  -- rozetler (posta, fisilti) sag uca yerlesir; icerik onlara yer acmak icin sola kayar
  local reserve = self:LayoutBadges()
  local gap = sep == "" and GAP * 0.75 or GAP   -- ayrac yoksa ogeler biraz yaklasir
  -- hub acikken baslik hub genisligine sigar; sigmayan ogeler gizli sayilir
  local cap = self.mode == "hub" and self:HubWidth() or MAX_W
  for _, id in ipairs(self.db.strip) do
    local text = self:ItemText(id)
    if text ~= "" and #shown >= limit then
      self.hiddenCount = self.hiddenCount + 1
    elseif text ~= "" then
      local fs, dot = rowItem(f, #shown + 1)
      local st = self.db.itemStyle[id] or {}
      local isize, flags = st.size or size, st.outline and "OUTLINE" or ""
      if fs.size ~= isize or fs.flags ~= flags then Skin:SetFont(fs, isize, flags); fs.size, fs.flags = isize, flags end
      if dot.size ~= size then Skin:SetFont(dot, size, ""); dot.size = size end
      dot:SetText(sep)
      fs:SetText(text)
      local own = st.color and self:ColorOf(st.color, nil)
      fs:SetTextColor(unpack(own or ((#shown == 0 and self.db.accentFirst) and C.accentHover or color)))
      local sw = fs:GetStringWidth()
      sw = type(sw) == "number" and sw or 0
      if #shown > 0 and 2 * PAD + total + sw + #shown * gap * 2 + reserve > cap then
        fs:Hide(); dot:Hide()
        self.hiddenCount = self.hiddenCount + 1
      else
        shown[#shown + 1], widths[#shown + 1] = fs, sw
        total = total + sw
      end
    end
  end
  self.statPass, self.statCache = nil, nil
  for i = #shown + 1, #f.items do f.items[i]:Hide(); f.dots[i]:Hide() end
  local w = 2 * PAD + total + math.max(0, #shown - 1) * gap * 2 + reserve
  local x = -(total + math.max(0, #shown - 1) * gap * 2) / 2 - reserve / 2
  for i, fs in ipairs(shown) do
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", f.row, "CENTER", x, 1)
    fs:Show()
    x = x + widths[i]
    local dot = f.dots[i]
    if i < #shown then
      dot:ClearAllPoints()
      dot:SetPoint("CENTER", f.row, "CENTER", x + gap, 1)
      dot:Show()
      x = x + gap * 2
    else
      dot:Hide()
    end
  end
  self.shownCount = #shown
  self:ShowEyes(#shown == 0)
  if #shown == 0 then w = EYES_W + reserve end
  local e = f.eyeFrame
  if e then e:ClearAllPoints(); e:SetPoint("CENTER", f.row, "CENTER", -reserve / 2, 0) end
  self.rowW = math.max(#shown == 0 and EYES_W or MIN_W, math.min(MAX_W, w))
  return self.rowW
end

-- Rozetler: okunmamis posta ve yeni fisilti seridin sag ucunda kucuk ikon. Gelince buyuyerek belirir
-- (pop), parlar ve gozler bir an ona bakar. Fisilti rozeti hub acilinca ya da WHISPER_KEEP sn sonra kalkar.
local BADGE, BADGE_STEP, WHISPER_KEEP, POP = 14, 20, 300, 0.45
Island.BADGES = {
  { id = "mail", key = "badgeMail", icon = "mail", color = Skin.Colors.mail,
    active = function() return P.HasNewMail() end },
  { id = "whisper", key = "badgeWhisper", icon = "bubble", color = Skin.Colors.whisper,
    active = function() return Island.whisperAt and P.Now() - Island.whisperAt < WHISPER_KEEP end },
}

function Island:ActiveBadges()
  local out = {}
  for _, b in ipairs(Island.BADGES) do
    if self.db[b.key] ~= false then
      local ok, on = pcall(b.active)
      if ok and on then out[#out + 1] = b end
    end
  end
  return out
end

-- Rozetleri yerlestirir; satirda ayrilan genisligi dondurur.
function Island:LayoutBadges()
  local f = self.frame
  f.badges = f.badges or {}
  local list = self:ActiveBadges()
  local on = {}
  for k, b in ipairs(list) do
    local t = f.badges[b.id]
    if not t then
      t = CreateFrame("Frame", nil, f.row)
      t:SetSize(BADGE, BADGE)
      t.glow = t:CreateTexture(nil, "BACKGROUND"); t.glow:SetTexture(Skin.Icons.glow); t.glow:SetPoint("CENTER")
      t.glow:SetSize(BADGE * 2.4, BADGE * 2.4); t.glow._skinFixed = true
      t.icon = t:CreateTexture(nil, "OVERLAY"); t.icon:SetTexture(Skin.Icons[b.icon]); t.icon:SetAllPoints(); t.icon._skinFixed = true
      f.badges[b.id] = t
    end
    t.icon:SetVertexColor(b.color[1], b.color[2], b.color[3], 1)
    t.glow:SetVertexColor(b.color[1], b.color[2], b.color[3], 0.35)
    t:ClearAllPoints()
    t:SetPoint("CENTER", f.row, "RIGHT", -PAD + 4 - BADGE / 2 - (k - 1) * BADGE_STEP, 1)
    if not t.on then t.pop = 0; self.glance = 1.4; self:Wake() end   -- yeni geldi: buyuyerek belirir, gozler bakar
    t.on = true
    t:Show()
    on[b.id] = true
  end
  for id, t in pairs(f.badges) do if not on[id] then t.on = nil; t:Hide() end end
  return #list > 0 and (#list * BADGE_STEP + 2) or 0
end

-- Pop: 0 -> 1.3 -> 1 olcek (asiri yumusak geri donus), parilti once parlak sonra soluk nabiz.
function Island:StepBadges(dt)
  local f = self.frame
  for _, t in pairs(f.badges or {}) do
    if t.on then
      local s, ga
      if t.pop then
        t.pop = t.pop + dt
        local p = math.min(1, t.pop / POP)
        s = p < 0.6 and (p / 0.6) * 1.3 or 1.3 - 0.3 * ((p - 0.6) / 0.4)
        ga = 0.8 * (1 - p) + 0.3
        if p >= 1 then t.pop = nil end
      else
        t.clock = (t.clock or 0) + dt
        s, ga = 1, 0.22 + 0.12 * math.sin(t.clock * 2.4)
      end
      t:SetSize(BADGE * math.max(0.05, s), BADGE * math.max(0.05, s))
      t.glow:SetAlpha(ga)
    end
  end
  if self.glance then self.glance = self.glance - dt; if self.glance <= 0 then self.glance = nil end end
end

-- Fare seride gelince gizli ogeler yana acilir; ayrildiktan 0.4 sn sonra kapanir.
function Island:Reveal(on)
  on = on and true or false
  if self.mode ~= "line" or (self.revealed or false) == on then return end
  self.revealed = on
  self.leaveAge = nil
  -- gizli oge yoksa genislik degismez: animasyon (yazilarin yeniden belirmesi) baslatilmaz, yoksa hover'da yanip soner
  local w, h = self:LineSize(self:LayoutRow())
  if math.abs(w - (self.tw or self.w or 0)) > 0.5 then self:Animate(w, h) end
end

-- Kapali seridin boyutu: satir genisligi; adim onizlemesi aciksa en az onun genisligi ve bir satir daha uzun.
-- Rehber adadaysa (UI/IslandGuide.lua) altta hep rehber satiri: ok + adim + mesafe.
function Island:LineSize(w)
  local h = SMALL_H
  if self.Dock and self.Dock:Active() then
    w, h = math.max(w, self.Dock:StripWidth()), h + self.Dock.STRIP_H
  end
  if not self.peeking then return w, h end
  return math.max(w, self.peekW or 0), h + PEEK_H
end

-- Meslek cast bari (ProfActivity cagirir): serit genisler, ikon + ad + kalan sure, alt kenarda ilerleme.
-- Bitince kisa sure sonuc (+2 Copper Ore / Interrupted) gorunur, sonra serit geri gelir. Bildirimler bekler.
local CAST_W = 260
local CAST_COLORS = { gather = Skin.Colors.gather, fish = Skin.Colors.fish }
local GREEN, RED = Skin.Colors.good, Skin.Colors.bad

function Island:OnProfCast(c)
  if not (self.frame and self.db.castBar) or self.mode == "hub" then return end
  if self.current then   -- gosterilen bildirim cast bitince tekrar gelir
    self.queue = self.queue or {}
    table.insert(self.queue, 1, self.current)
    self.current = nil
  end
  local f = self.frame
  self.mode, self.castInfo, self.castEnd, self.peeking = "cast", c, nil, false
  f.row:Hide(); f.peek:Hide(); f.title:Hide(); f.body:Hide()
  if f.countBar then f.countBar:Hide() end
  local cf = f.cast
  local label = c.name
  if c.total then label = ("%s  %d/%d"):format(c.name, (c.done or 0) + 1, c.total) end
  cf.label:SetText(label); cf.label:SetTextColor(unpack(self:TextColor()))
  local col = CAST_COLORS[c.kind] or Skin.Colors.accentHover
  cf.bar:SetVertexColor(col[1], col[2], col[3], 1)
  cf:Show()
  self:Wake()
  self:Animate(math.max(CAST_W, self.rowW or 0), SMALL_H + CAST_EXTRA)
  self:StepCast(0)
end

function Island:OnProfCastEnd(c, ok)
  if self.mode ~= "cast" or self.castInfo ~= c then return end
  local cf = self.frame.cast
  local col = ok and GREEN or RED
  cf.bar:SetVertexColor(col[1], col[2], col[3], 1)
  cf.bar:SetWidth(math.max(1, num(cf.track:GetWidth())))
  cf.time:SetText("")
  if not ok then cf.label:SetText(L["Interrupted"]); cf.label:SetTextColor(unpack(RED)) end
  -- uretim sirasi suruyorsa bir sonraki cast hemen gelir; toplamada loot yazisi icin biraz bekler
  self.castEnd = (c.kind == "craft" and ok) and 0.7 or (ok and 1.2 or 0.9)
end

-- Toplama / balik loot'u: sonuc satirinda gorunur.
function Island:OnProfLoot(text)
  if self.mode ~= "cast" or not self.castEnd then return end
  local cf = self.frame.cast
  cf.label:SetText(text); cf.label:SetTextColor(unpack(GREEN))
  self.castEnd = math.max(self.castEnd, 1.6)
end

function Island:StepCast(dt)
  local cf = self.frame.cast
  if self.castEnd then
    self.castEnd = self.castEnd - dt
    if self.castEnd <= 0 then
      self.castEnd, self.castInfo = nil, nil
      cf:Hide()
      self:ShowLine()
      self:Next()
    end
    return
  end
  local c = self.castInfo
  if not c then return end
  local t, span = P.Now(), math.max(0.1, c.finish - c.start)
  local p = math.max(0, math.min(1, (t - c.start) / span))
  if c.channel then p = 1 - p end   -- kanal (Fishing): cizgi azalir
  local tw = num(cf.track:GetWidth())
  if tw <= 0 then tw = (self.w or CAST_W) - 2 * RADIUS end
  cf.bar:SetWidth(math.max(1, tw * p))
  local left = math.max(0, c.finish - t)
  cf.time:SetText(left < 10 and ("%.1f"):format(left) or clock(left))
end

-- O anki rehber adimi (onizleme metni) ya da nil.
function Island:PeekText()
  local E = ns.Engine
  local step = E and E.GetStep and E:GetStep()
  if not step then return nil end
  local ok, text = pcall(E.Describe, E, step)
  return ok and text or nil
end

-- Fare seritte durunca serit asagi uzar, altinda o anki adim gorunur; fare ayrilinca geri kuculur.
function Island:Peek(on)
  -- rehber adadayken adim zaten seritte yazili: onizleme yok
  on = on and self.db.peek and self.mode == "line" and not (self.Dock and self.Dock:Active()) and true or false
  if (self.peeking or false) == on then return end
  local f = self.frame
  local text = on and self:PeekText()
  if on and not text then return end
  self.peeking = on
  if on then
    f.peek:SetText(text); f.peek:Show()
    self.peekW = math.min(MAX_W, num(f.peek:GetStringWidth()) + 2 * PAD)
  else
    f.peek:Hide()
  end
  self:Animate(self:LineSize(self:LayoutRow()))
end

-- Gozler: serit bos gorunurken iki oval goz imleci izler, ara ara kirpar ve kisilir.
local EYE_TEX = "Interface\\AddOns\\Arcanis\\Media\\UI\\eye"
local EYE_TC = { 0.32, 0.66, 0.17, 0.81 }
local EYE_W, EYE_H, EYE_GAP = 9, 10.4, 9
local PUPIL = 4.5   -- goz bebegi: imlece gozden biraz daha fazla kayar, goz kapaninca kaybolur
local GAZE_X, GAZE_Y = 4, 1.5
local BROW_W, BROW_Y = 9, 9
local SQUINT = { 0.15, 0.5, 1.0, 1.45 }   -- hazirlik / kisilma / bekleme / donus bitisleri (sn)
-- "glow" stili: parlayan dik oval goz; uzun sessizlikte uyuklar, fare gelince uyanir.
local GLOW_W, GLOW_H, GLOW_GAP = 7.5, 11, 13
local GLOW = { { pad = 6, c = { 0.47, 0.75, 1 }, a = 0.6 }, { pad = 16, c = { 0.31, 0.55, 1 }, a = 0.28 } }
local DOZE_AFTER = 45   -- sn: bu kadar sessizlikte uyuklar

-- Kisilma egrisi: 0 acik .. 1 tam kisik (hazirlikta once azicik acilir).
function Island.SquintAmount(t)
  local a, b, c, d = SQUINT[1], SQUINT[2], SQUINT[3], SQUINT[4]
  if t < a then return -0.12 * math.sin(t / a * math.pi) end
  if t < b then local u = (t - a) / (b - a); return 1 - (1 - u) ^ 3 end
  if t < c then return 1 end
  if t < d then local u = (t - c) / (d - c); return 1 - u * u * (3 - 2 * u) end
  return 0
end

function Island:BuildEyes()
  local f = self.frame
  local e = CreateFrame("Frame", nil, f.row)
  e:SetSize(2 * EYE_W + EYE_GAP + 8, EYE_H + 10)
  e:SetPoint("CENTER", f.row, "CENTER", 0, 0)
  e.eyes = {}
  for i = 1, 2 do
    local side = i == 1 and -1 or 1
    local eye = e:CreateTexture(nil, "ARTWORK")
    eye:SetTexture(EYE_TEX)
    eye:SetTexCoord(unpack(EYE_TC))
    eye:SetVertexColor(1, 1, 1, 1)
    eye:SetSize(EYE_W, EYE_H)
    eye._skinFixed = true
    local pupil = e:CreateTexture(nil, "ARTWORK", nil, 2)
    pupil:SetTexture(Skin.Icons.disc)
    pupil:SetVertexColor(0.08, 0.08, 0.12, 1)
    pupil:SetSize(PUPIL, PUPIL)
    pupil._skinFixed = true
    local brow = e:CreateTexture(nil, "ARTWORK")
    brow:SetTexture("Interface\\Buttons\\WHITE8x8")
    brow:SetVertexColor(1, 1, 1, 0.9)
    brow:SetSize(BROW_W, 1.5)
    brow._skinFixed = true
    local glows = {}
    for k = 1, #GLOW do
      local g = e:CreateTexture(nil, "BACKGROUND", nil, -k)
      g:SetTexture(Skin.Icons.glow)
      g._skinFixed = true
      glows[k] = g
    end
    e.eyes[i] = { eye = eye, pupil = pupil, brow = brow, glows = glows, x = side * (EYE_W + EYE_GAP) / 2, side = side }
  end
  e.gx, e.gy, e.open, e.clock = 0, 0, 1, 0
  e.nextBlink = math.random(4, 7)
  e.nextSquint = math.random(9, 15)
  e:Hide()
  f.eyeFrame = e
end

function Island:GlowEyes() return self.db.eyeStyle ~= "classic" end

-- Goz stili: glow duz oval (disk dokusu) ve parilti katmanlari; classic el cizimi goz dokusu.
function Island:StyleEyes()
  local e = self.frame and self.frame.eyeFrame
  if not e then return end
  local glow = self:GlowEyes()
  local w, gap = glow and GLOW_W or EYE_W, glow and GLOW_GAP or EYE_GAP
  for _, eye in ipairs(e.eyes) do
    eye.eye:SetTexture(glow and Skin.Icons.disc or EYE_TEX)
    if glow then eye.eye:SetTexCoord(0, 1, 0, 1) else eye.eye:SetTexCoord(unpack(EYE_TC)) end
    eye.eye:SetWidth(w)
    eye.x = eye.side * (w + gap) / 2
    for k, g in ipairs(eye.glows) do
      local s = GLOW[k]
      g:SetVertexColor(s.c[1], s.c[2], s.c[3], s.a)
      g:SetShown(glow)
    end
  end
end

-- Uyku: son hareketten (fare, bildirim) beri gecen sure DOZE_AFTER'i asinca. Fare gelince uyanir ve sicrar.
function Island:Wake()
  local e = self.frame and self.frame.eyeFrame
  if e and e.doze and e.doze > 0.3 and self.eyesShown then
    self:Bounce()                       -- merhaba: serit (gozler) yukari sicrar
    e.blink, e.double = 0, true         -- ve iki kez kirpar
  end
  self.quiet = 0
  if e then e.doze = 0 end
end

function Island:ShowEyes(on)
  local e = self.frame.eyeFrame
  if e then e:SetShown(on) end
  self.eyesShown = on
end

function Island:StepEyes(dt)
  local e = self.frame.eyeFrame
  if not (e and self.eyesShown) then return end
  e.clock = e.clock + dt
  -- bakis: imlecin yonu, uzaklikla artan erim (1 - e^(-d/160))
  local tx, ty = 0, 0
  if GetCursorPosition then
    local mx, my = GetCursorPosition()
    local cx, cy = e:GetCenter()
    local scale = e:GetEffectiveScale()
    if type(mx) == "number" and type(cx) == "number" and type(scale) == "number" and scale > 0 then
      local dx, dy = mx / scale - cx, my / scale - cy
      local d = math.sqrt(dx * dx + dy * dy)
      if d > 0.5 then
        local reach = 1 - math.exp(-d / 160)
        tx, ty = dx / d * reach * GAZE_X, dy / d * reach * GAZE_Y * 1.15
      end
    end
  end
  if self.glance then tx, ty = GAZE_X, 0 end   -- yeni rozet: gozler saga, ikona bakar
  local blend = 1 - math.exp(-dt * 12)
  e.gx, e.gy = e.gx + (tx - e.gx) * blend, e.gy + (ty - e.gy) * blend
  -- uyuklama: sessizlik uzayinca gozler yavasca kapanir (0 uyanik .. 1 uyuyor)
  self.quiet = (self.quiet or 0) + dt
  local sleepy = self.hover and 0 or (self.quiet >= DOZE_AFTER and 1 or 0)
  e.doze = (e.doze or 0) + (sleepy - (e.doze or 0)) * (1 - math.exp(-dt * (sleepy > 0 and 0.6 or 6)))
  local dozing = e.doze > 0.2
  if dozing then e.blink, e.squint = nil, nil; e.nextBlink, e.nextSquint = e.clock + 2, e.clock + 4 end
  -- fare ustundeyken azicik irilesir
  local want = self.hover and 1.12 or 1
  e.open = e.open + (want - e.open) * (1 - math.exp(-dt * 8))
  -- kirpma
  if e.blink then
    e.blink = e.blink + dt
    if e.blink >= (e.double and 0.48 or 0.20) then e.blink = nil; e.nextBlink = e.clock + math.random(4, 7) end
  elseif e.clock >= e.nextBlink and not e.squint then
    e.blink, e.double = 0, math.random(1, 4) == 1
  end
  local lid = 1
  if e.blink then
    local phase = e.blink
    if phase > 0.28 then phase = phase - 0.28 end
    if phase <= 0.2 then lid = math.max(0.04, math.abs(phase - 0.10) / 0.10) end
  end
  -- sinsi kisilma
  if e.squint then
    e.squint = e.squint + dt
    if e.squint >= SQUINT[4] then e.squint = nil; e.nextSquint = e.clock + math.random(9, 15) end
  elseif e.clock >= e.nextSquint and not e.blink then
    e.squint = 0
  end
  local s = e.squint and Island.SquintAmount(e.squint) or 0
  local tall = (self.db.eyeHeight or 100) / 100
  local glow = self:GlowEyes()
  -- uyurken goz neredeyse kapali bir cizgi; yavasca nefes alir gibi biraz acilip kapanir
  local sleep = 1 - e.doze * (0.86 - 0.06 * math.sin(e.clock * 1.6))
  local h = math.max(1, (glow and GLOW_H or EYE_H) * tall * e.open * lid * (1 - 0.55 * s) * sleep)
  local brows = self.db.brows ~= false and not glow
  local pw = math.min(EYE_W - 1, PUPIL * (self.db.pupilSize or 100) / 100)
  local gw = glow and GLOW_W or EYE_W
  local tilt = math.rad(self.db.browAngle or 0)
  for _, eye in ipairs(e.eyes) do
    eye.eye:SetHeight(h)
    eye.eye:ClearAllPoints()
    eye.eye:SetPoint("CENTER", e, "CENTER", eye.x + e.gx, e.gy)
    -- goz bebegi gozle birlikte kapanir (kirpma, kisilma) ve gozun icinde kalir
    for k, g in ipairs(eye.glows) do
      if glow then
        local pad = GLOW[k].pad
        g:SetSize(gw + 2 * pad, h + 2 * pad)
        g:ClearAllPoints()
        g:SetPoint("CENTER", e, "CENTER", eye.x + e.gx, e.gy)
      end
    end
    local ph = math.min(pw, h - 1)
    local showPupil = self.db.pupils ~= false and ph >= 1 and not glow
    eye.pupil:SetShown(showPupil)
    if showPupil then
      eye.pupil:SetSize(pw, ph)
      eye.pupil:ClearAllPoints()
      eye.pupil:SetPoint("CENTER", e, "CENTER", eye.x + e.gx * 1.5, e.gy + math.max(-1, math.min(1, e.gy)) * (h - ph) / 2)
    end
    eye.brow:SetShown(brows)
    if brows then
      eye.brow:ClearAllPoints()
      eye.brow:SetPoint("CENTER", e, "CENTER", eye.x + e.gx * 0.6, BROW_Y * tall + e.gy * 0.5 - 3 * s - (1 - lid))
      eye.brow:SetRotation(eye.side * (tilt + 0.35 * math.max(0, s)))   -- ic uclar asagi (egim + kisilma)
    end
  end
  self.eyeH, self.squintNow = h, s
end

function Island:ShowLine()
  local f = self.frame
  if not f then return end
  self.mode = "line"
  self.revealed = self.hover and true or false
  self.peeking = false
  f.title:Hide(); f.body:Hide(); f.notice:Hide(); f.peek:Hide(); f.cast:Hide()
  if f.countBar then f.countBar:Hide() end
  f.row:Show()
  if self.Hub then self.Hub:Hide() end
  if self.Chat then self.Chat:Hide() end
  if self.Dungeon then self.Dungeon:Hide() end
  self.chatOpen, self.dungeonOpen = nil, nil
  if self.guideOpen and self.Dock then self.guideOpen = nil; self.Dock:Unseat() end
  self:Animate(self:LineSize(self:LayoutRow()))
  self:LayoutLive()
end

-- Seridi yeniler; genislik belirgin degistiyse esneyerek uyar. Canli etkinlikler de her yenilemede guncellenir.
function Island:Refresh(force)
  local f = self.frame
  if not f then return end
  if self.mode == "line" then
    local w, h = self:LineSize(self:LayoutRow())
    if force or math.abs(w - (self.tw or self.w)) > 6 then self.tw, self.th = w, h end
  elseif self.mode == "hub" then
    self:LayoutRow()
  end
  self:LayoutLive()
end

function Island:ShowItem(item, w, h)
  local f = self.frame
  self.peeking = false
  f.row:Hide(); f.peek:Hide(); f.cast:Hide()
  f.title:SetText(item.title); f.title:Show()
  f.body:SetText(item.body or ""); f.body:Show()
  f.title:SetTextColor(unpack(item.color or (item.kind == "warn" and WARN) or Skin.Colors.accentHover))
  local cb = f.countBar
  if item.count and cb then
    -- sayac: baslik eski degerden baslar, cubuk eski orandan; Tick yeniye dogru sayar (CountStep)
    item.count.shown, item.count.popped, item.count.settled = nil, nil, nil
    f.title:SetText(item.count.fmt:format(item.count.from))
    Skin:SetFont(f.title, 16, "OUTLINE")
    cb:Show()
    self:CountStep(0)
    h = h + 10
  else
    Skin:SetFont(f.title, 13, "")
    if cb then cb:Hide() end
  end
  self:Animate(w, h)
end

-- Sayacli bildirim (beceri serisi): COUNT_TIME sn'de yavaslayarak sayar, cubuk dolar; bitince baslik kisa parlar.
local COUNT_TIME, COUNT_DELAY = 1.4, 0.35
local function easeOut(p) return 1 - (1 - p) ^ 3 end
function Island:CountStep(age)
  local f, item = self.frame, self.current
  local c = item and item.count
  if not (f and c and f.countBar) then return end
  local p = math.max(0, math.min(1, (age - COUNT_DELAY) / COUNT_TIME))
  local v = c.from + (c.to - c.from) * easeOut(p)
  local shown = math.floor(v + 1e-6)
  if shown ~= c.shown then
    c.shown = shown
    f.title:SetText(c.fmt:format(shown))
  end
  local cb = f.countBar
  local w = cb.track:GetWidth() or 0
  local frac = (c.max and c.max > 0) and math.min(1, v / c.max) or p
  if w > 0 then cb.fill:SetWidth(math.max(1, w * frac)) end
  if p >= 1 and not c.popped then
    c.popped = true
    f.title:SetTextColor(0.40, 0.95, 0.55)   -- son deger: yesil parlama
  elseif c.popped and not c.settled and age > COUNT_DELAY + COUNT_TIME + 0.6 then
    c.settled = true
    f.title:SetTextColor(unpack(item.color or Skin.Colors.accentHover))
  end
end

-- action: istege bagli; bildirim gorunurken adaya sol tik onu calistirir (fisilti -> Messages sayfasi).
-- opts (istege bagli): flash = baslik yanip soner, hold = ekranda kalma suresi (sn), color = baslik rengi,
-- key = ayni anahtarli bildirim gosteriliyor ya da sirada bekliyorsa yenisi onun yerine gecer (ust uste beceri artisi).
function Island:Push(title, body, kind, action, opts)
  if ns.NoticeAllowed and not ns.NoticeAllowed(kind, action, opts) then return end   -- bildirim duzeyi (UI/Toast.lua)
  self.queue = self.queue or {}
  opts = opts or {}
  local item = { title = title, body = body, kind = kind or "info", action = action,
    flash = opts.flash, hold = opts.hold, color = opts.color, key = opts.key, count = opts.count }
  local cur = self.current
  if item.key and cur and cur.key == item.key then
    self.current, self.age = item, 0
    local f = self.frame
    if self.mode == "hub" then f.notice:SetText(title)
    else f.title:SetText(title); f.body:SetText(body or "") end
    return
  end
  for i, it in ipairs(self.queue) do
    if item.key and it.key == item.key then self.queue[i] = item; return end
  end
  if #self.queue >= 6 then table.remove(self.queue, 1) end
  self.queue[#self.queue + 1] = item
  self:Wake()
  self:Next()
end

-- Bildirimi hemen kapat: key verilirse yalniz o anahtarli (gosterilen ya da sirada bekleyen), yoksa gosterilen.
function Island:Dismiss(key)
  for i = #(self.queue or {}), 1, -1 do
    if key and self.queue[i].key == key then table.remove(self.queue, i) end
  end
  local cur = self.current
  if not cur or (key and cur.key ~= key) then return end
  local f = self.frame
  if cur.flash and f then f.notice:SetAlpha(1); f.title:SetAlpha(1) end
  self.current = nil
  if f then
    if self.mode == "hub" then f.notice:Hide(); f.row:Show() else self:ShowLine() end
  end
  self:Next()
end

-- Siradaki olay. Savasta yalniz uyarilar (dusuk can...) gosterilir; bilgi olaylari savas bitince gelir.
-- Hub acikken bildirim baslik satirinda gecici yazi olarak gosterilir (hub kuculmez).
function Island:Next()
  if not self.frame or self.current or self.mode == "cast" then return end
  local queue, pick = self.queue or {}, nil
  for i, it in ipairs(queue) do
    if it.kind == "warn" or not P.InCombat() then pick = i break end
  end
  local item = pick and table.remove(queue, pick)
  if not item then return end
  self.current, self.age = item, 0
  local f = self.frame
  -- yanip sonen bildirim yarida kesildiyse (hub / sohbet acildi, kapandi) soluk kalmasin
  f.notice:SetAlpha(1); f.title:SetAlpha(1)
  if self.mode == "hub" then
    f.row:Hide()
    f.notice:SetText(item.title)
    f.notice:SetTextColor(unpack(item.color or (item.kind == "warn" and WARN) or Skin.Colors.accentHover))
    f.notice:Show()
    return
  end
  self.mode = "event"
  local lines = item.body and item.body ~= "" and select(2, item.body:gsub("\n", "")) + 1 or 0
  self:ShowItem(item, WIDE_W, lines > 0 and WIDE_H + (lines - 1) * 14 or 38)
end

function Island:Tick(dt)
  if not self.current or (self.hover and self.mode ~= "hub") then return end
  self.age = self.age + dt
  local f = self.frame
  -- yanip sonen bildirim (ornek: kacirilan quest): baslik nabiz gibi soluklasip parlar
  if self.current.flash then
    local a = 0.35 + 0.65 * math.abs(math.cos(self.age * math.pi / 0.6))
    if self.mode == "hub" then f.notice:SetAlpha(a) else f.title:SetAlpha(a) end
  end
  if self.current.count and self.mode == "event" then self:CountStep(self.age) end
  if self.age >= (self.current.hold or self.db.hold or 4) then
    if self.current.flash then f.notice:SetAlpha(1); f.title:SetAlpha(1) end
    self.current = nil
    if self.mode == "hub" then
      self.frame.notice:Hide(); self.frame.row:Show()
    else
      self:ShowLine()
    end
    self:Next()
  end
end

-- Hub
function Island:HubWidth()
  if self.chatOpen and self.Chat then return self.Chat:Width() end
  if self.dungeonOpen and self.Dungeon then return self.Dungeon:Width() end
  if self.guideOpen and self.Dock then return self.Dock:GuideSize() end
  return math.max(380, math.min(560, self.db.width or 480))
end
function Island:HubHeight()
  if self.chatOpen and self.Chat then return SMALL_H + self.Chat:Height() end
  if self.dungeonOpen and self.Dungeon then return SMALL_H + self.Dungeon:Height() end
  if self.guideOpen and self.Dock then return SMALL_H + select(2, self.Dock:GuideSize()) end
  return SMALL_H + (self.Hub and self.Hub:ContentHeight(self:HubWidth()) or 0)
end

-- Sohbet: hub yerine adanin altinda fisilti konusmalari (UI/IslandChat.lua). key yoksa son konusma.
function Island:OpenChat(key)
  if not (self.Chat and self.frame and ns.Messenger and ns.Messenger:IsEnabled()) or P.InCombat() then return false end
  if self.Hub then self.Hub:Hide() end   -- kartlar her durumda kapanir (iki gorunum ust uste binmesin)
  if self.Dungeon then self.Dungeon:Hide() end
  self.dungeonOpen = nil
  self.current = nil
  self.whisperAt = nil
  self.chatOpen = true
  self.mode = "hub"
  self.away = 0
  self.peeking = false
  self.castInfo, self.castEnd = nil, nil
  local f = self.frame
  f.title:Hide(); f.body:Hide(); f.notice:Hide(); f.peek:Hide(); f.cast:Hide()
  if f.countBar then f.countBar:Hide() end
  f.row:Show()
  self:LayoutRow()
  self:LayoutLive()
  self.Chat:Open(key)
  self:Animate(self:HubWidth(), self:HubHeight())
  return true
end

-- Zindan: hub yerine bulunulan zindanin boss'lari ve loot'u (UI/IslandDungeon.lua). Zindanda degilse false.
function Island:OpenDungeon(d)
  d = d or (self.Dungeon and self.Dungeon.Current())
  if not (d and self.Dungeon and self.frame) or P.InCombat() then return false end
  if self.Hub then self.Hub:Hide() end
  if self.Chat then self.Chat:Hide() end
  if self.guideOpen and self.Dock then self.guideOpen = nil; self.Dock:Unseat() end
  self.chatOpen, self.dungeonOpen = nil, true
  self.current, self.whisperAt = nil, nil
  self.mode = "hub"
  self.away = 0
  self.peeking = false
  self.castInfo, self.castEnd = nil, nil
  local f = self.frame
  f.title:Hide(); f.body:Hide(); f.notice:Hide(); f.peek:Hide(); f.cast:Hide()
  if f.countBar then f.countBar:Hide() end
  f.row:Show()
  self:LayoutRow()
  self:LayoutLive()
  self.Dungeon:Open(d)
  self:Animate(self:HubWidth(), self:HubHeight())
  return true
end

-- Rehber: hub adim penceresine donusur (UI/IslandGuide.lua; pencere adanin icine oturur, ada onun boyuna buyur).
function Island:OpenGuide()
  if not (self.frame and self.Dock and self.Dock:Active()) then return false end
  if self.Hub then self.Hub:Hide() end
  if self.Chat then self.Chat:Hide() end
  if self.Dungeon then self.Dungeon:Hide() end
  self.chatOpen, self.dungeonOpen, self.guideOpen = nil, nil, true
  self.current, self.whisperAt = nil, nil
  self.mode = "hub"
  self.away = 0
  self.peeking = false
  self.castInfo, self.castEnd = nil, nil
  local f = self.frame
  f.title:Hide(); f.body:Hide(); f.notice:Hide(); f.peek:Hide(); f.cast:Hide()
  if f.countBar then f.countBar:Hide() end
  f.row:Show()
  self:LayoutRow()
  self:LayoutLive()
  self.Dock:Seat()
  self:Animate(self:HubWidth(), self:HubHeight())
  return true
end

function Island:OpenHub()
  if not (self.db.card and self.Hub) or P.InCombat() then return false end
  if self.Chat then self.Chat:Hide() end   -- sohbet acik kaldiysa kapanir (iki gorunum ust uste binmesin)
  if self.Dungeon then self.Dungeon:Hide() end
  if self.guideOpen and self.Dock then self.guideOpen = nil; self.Dock:Unseat() end
  self.chatOpen, self.dungeonOpen = nil, nil
  self.current = nil
  self.whisperAt = nil   -- hub'a bakildi: fisilti rozeti kalkar
  self.mode = "hub"
  self.away = 0
  self.peeking = false
  self.castInfo, self.castEnd = nil, nil
  local f = self.frame
  f.title:Hide(); f.body:Hide(); f.notice:Hide(); f.peek:Hide(); f.cast:Hide()
  if f.countBar then f.countBar:Hide() end
  f.row:Show()
  self:LayoutRow()
  self:LayoutLive()
  self.Hub:Open(self:HubWidth())
  self:Animate(self:HubWidth(), self:HubHeight())
  return true
end

function Island:CloseHub()
  if self.mode ~= "hub" then return end
  self.current = nil
  self:ShowLine()
  self:Next()
end

-- Imlec seritte ya da hub'da mi. Kamera cevrilirken imlec donmus kalir; o sirada disarida sayilir.
function Island:MouseOnHub()
  if P.MouseLooking() then return false end
  return self.hover or (self.Hub and self.Hub.frame and self.Hub.frame:IsMouseOver())
    or (self.Chat and self.Chat.frame and self.Chat.frame:IsMouseOver())
    or (self.Dungeon and self.Dungeon.frame and self.Dungeon.frame:IsMouseOver()) or false
end

-- Ayarlar acikken hub acik kalir: yapilan degisiklik canli gorunsun.
function Island:SettingsOpen()
  return ns.Settings and ns.Settings.IsOpen and ns.Settings:IsOpen() or false
end

-- Hub disinda herhangi bir yere tiklaninca (dunya dahil) hub kapanir; ayarlar acikken kapanmaz.
function Island:OnMouseDown()
  if self.mode == "hub" and not self.chatOpen and not self.dungeonOpen and not self.guideOpen and not self:MouseOnHub() and not self:SettingsOpen() then self:CloseHub() end
end

function Island:ToggleHub()
  if self.Dock and self.Dock:Active() and (self.mode ~= "hub" or self.guideOpen) then return self.Dock:Toggle() end
  if self.mode == "hub" then self:CloseHub() else self:OpenHub() end
end

-- Ornek olay (ayar sayfasindaki onizleme dugmesi)
function Island:Preview()
  self:Push(L["Entering %s"]:format(P.ZoneText() or "Elwynn Forest"), L["%s - level %d-%d"]:format("Elwynn Forest", 1, 10))
end

function Island:OnZone()
  self:Refresh()
  if not self.db.zone then return end
  local zone = P.ZoneText()
  if not zone or zone == "" then return end
  -- "a and f()" f'nin yalniz ilk degerini verir: ad ikinci deger oldugu icin cagri ayri yapilir
  local d, name
  if ns.ZoneInfo then d, name = ns.ZoneInfo:Get(zone) end
  local body = d and d.min and d.max and L["%s - level %d-%d"]:format(name or zone, d.min, d.max) or nil
  self:Push(L["Entering %s"]:format(zone), body, "info")
end

-- Toast bildirimleri buraya gelsin mi (Toast:Show ve Alerts sorar)
function Island:TakesNotices()
  if not (self:IsEnabled() and self.db.toasts) then return false end
  -- savasta / ara sahnede gizliyken bildirim adaya gitmez (gorunmez, sure islemez): ayri kutu gosterir
  if self:Hidden() then return false end
  return true
end

-- Eski uc yuvali ayar (slots) sirali seride tasinir.
function Island:OnInitialize()
  local old = self.db.slots
  if type(old) == "table" then
    local strip = {}
    for i = 1, 3 do if old[i] and old[i] ~= "empty" and BY_ID[old[i]] then strip[#strip + 1] = old[i] end end
    if #strip > 0 then self.db.strip = strip end
    self.db.slots = nil
  end
end

function Island:OnEnable()
  if self.Hub then self.Hub.startLevel = self.Hub.startLevel or P.PlayerLevel() end   -- oturumdaki seviye artisi
  self:Build()
  self.frame:Show()
  self:ShowLine()
  -- hub kartlari simdiden kurulur: ilk tiklamada kurulum takilmasi animasyonu bozmasin
  if self.Hub and self.db.card then self.Hub:Rebuild() end
  ns:On("ZONE_CHANGED_NEW_AREA", self, "OnZone")
  for _, ev in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_XP_UPDATE", "PLAYER_MONEY", "PLAYER_LEVEL_UP",
    "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "UPDATE_EXHAUSTION", "UPDATE_PENDING_MAIL" }) do
    ns:On(ev, self, "Refresh")
  end
  -- savas: InCombatLockdown PLAYER_REGEN_DISABLED aninda henuz true olmayabilir; bayrak olaydan tutulur
  ns:On("PLAYER_REGEN_DISABLED", self, function(t) t:OnFight(true) end)
  ns:On("PLAYER_REGEN_ENABLED", self, function(t) t:OnFight(false) end)
  ns:On("CINEMATIC_START", self, function(t) t:OnCinematic(true) end)
  ns:On("CINEMATIC_STOP", self, function(t) t:OnCinematic(false) end)
  ns:On("PLAY_MOVIE", self, function(t) t:OnCinematic(true) end)
  ns:On("STOP_MOVIE", self, function(t) t:OnCinematic(false) end)
  ns:On("GLOBAL_MOUSE_DOWN", self, "OnMouseDown")
  ns:On("LOOT_OPENED", self, function(t) if t.Hub then t.Hub:OnLoot() end end)   -- hub Loot log karti
  ns:On("QUEST_LOG_UPDATE", self, function(t) if t.Hub then t.Hub.questsDirty = true end end)   -- hub Quest log karti
  for _, ev in ipairs({ "CHAT_MSG_WHISPER", "CHAT_MSG_BN_WHISPER" }) do
    ns:On(ev, self, function(t) t.whisperAt = P.Now(); t:Refresh(true) end)   -- fisilti rozeti
  end
  ns:Listen("ARCANIS_STEP_CHANGED", self, "Refresh")
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, "Refresh")
  -- saat, koordinat, FPS gibi olaysiz bilgiler icin seyrek yenileme
  if C_Timer and C_Timer.NewTicker and not self.ticker then
    self.ticker = C_Timer.NewTicker(1, function() if Island:IsEnabled() then Island:Refresh() end end)
  end
end

function Island:OnDisable()
  -- hub'a oturan adim penceresi gizli adayla birlikte kaybolmasin
  if self.guideOpen and self.Dock then self.guideOpen = nil; self.Dock:Unseat() end
  if self.frame then self.frame:Hide() end
  if self.Hub then self.Hub:Hide() end
  self.queue, self.current = {}, nil
  self.mode = "line"
end
