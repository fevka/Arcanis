-- Arcanis: gorunum katmani (ns.Skin).
-- Duz koyu zemin, vurgu rengi, 1px kenar.
-- Bilesenler: Button, Checkbox, Switch, Slider, Dropdown, EditBox, ScrollArea,
-- AccordionRow (acilir baslik), Banner (resimli baslik).
local _, ns = ...

local unpack = unpack or table.unpack

local Skin = {}
ns.Skin = Skin

Skin.Colors = {
  bg          = { 0.05, 0.05, 0.05, 0.95 },
  titleBg     = { 0.10, 0.10, 0.10, 1 },
  card        = { 0.07, 0.07, 0.07, 0.95 },
  border      = { 0.20, 0.20, 0.20, 1 },
  accent      = { 0.86, 0.62, 0.20, 1 },
  accentHover = { 0.96, 0.75, 0.34, 1 },
  button      = { 0.15, 0.15, 0.15, 0.90 },
  buttonHover = { 0.25, 0.25, 0.25, 0.90 },
  buttonOff   = { 0.11, 0.11, 0.11, 0.80 },   -- titleBg'den ayri: canli tema boyamasi esit renkleri ayirt edemez
  text        = { 0.90, 0.90, 0.90, 1 },
  textDim     = { 0.60, 0.60, 0.60, 1 },
  textOff     = { 0.40, 0.40, 0.40, 1 },
  barTrack    = { 0.12, 0.09, 0.08, 0.88 },
  ready       = { 0.00, 1.00, 0.50, 1 },
  borderLit   = { 0.32, 0.32, 0.32, 1 },
  accentSoft  = { 0.20, 0.15, 0.07, 0.95 },
}

-- Ek anlamsal renkler (kompakt rota paneli ve ana pencere)
local extra = {
  panel       = { 0.045, 0.055, 0.075, 0.96 },
  row         = { 0.075, 0.085, 0.11, 0.95 },
  rowActive   = { 0.07, 0.11, 0.17, 0.97 },
  highlight   = { 0.42, 0.72, 1.00, 1 },
  progress    = { 0.25, 0.85, 0.30, 1 },
  frameBorder = { 0.22, 0.26, 0.34, 1 },
  -- durum renkleri (iyi / dikkat / kotu / bilgi) ve ada kimlik renkleri (rozet, cast bari)
  good        = { 0.40, 0.85, 0.40, 1 },
  caution     = { 1.00, 0.72, 0.20, 1 },
  bad         = { 0.95, 0.35, 0.35, 1 },
  info        = { 0.45, 0.65, 1.00, 1 },
  mail        = { 1.00, 0.80, 0.35, 1 },
  whisper     = { 0.95, 0.55, 1.00, 1 },
  gather      = { 1.00, 0.66, 0.24, 1 },   -- caution'dan ayri: canli tema boyamasi esit renkleri karistirir
  fish        = { 0.35, 0.65, 1.00, 1 },
}
for k, v in pairs(extra) do Skin.Colors[k] = v end

-- Temalar: renk tablolari YERINDE degistirilir (dosyalarin tuttugu referanslar da guncellenir).
-- Pencereler acilista kuruldugu icin tema degisikligi /reload ile tam uygulanir.
local DEFAULTS = {}
for k, v in pairs(Skin.Colors) do DEFAULTS[k] = { v[1], v[2], v[3], v[4] } end

Skin.Themes = {
  { id = "arcanis", name = "Arcanis", colors = {} },
  { id = "astral", name = "Astral", colors = {
    bg = { 0.04, 0.06, 0.09, 0.96 }, titleBg = { 0.06, 0.09, 0.13, 1 }, card = { 0.06, 0.08, 0.12, 0.96 },
    border = { 0.16, 0.24, 0.32, 1 }, borderLit = { 0.26, 0.40, 0.52, 1 },
    accent = { 0.30, 0.80, 0.95, 1 }, accentHover = { 0.55, 0.90, 1.00, 1 }, accentSoft = { 0.06, 0.16, 0.22, 0.96 },
    button = { 0.08, 0.12, 0.17, 0.92 }, buttonHover = { 0.12, 0.19, 0.26, 0.92 },
    panel = { 0.035, 0.055, 0.08, 0.95 }, row = { 0.06, 0.09, 0.14, 0.95 }, rowActive = { 0.06, 0.15, 0.21, 0.97 },
    highlight = { 0.40, 0.90, 1.00, 1 }, progress = { 0.30, 0.80, 0.94, 1 }, frameBorder = { 0.18, 0.32, 0.42, 1 },
  } },
  -- Blood Orange (sahibin istegi, 13 Kasim 2026; yesil "Verdant"in yerine): 60 / 30 / 10 kurali.
  -- Ana ton Alpine Frost (buz beyazi: yazi ve acik yuzeyler), ikinci Slate Blue (arduvaz mavisi: zemin, kart,
  -- kenar), vurgu Blood Orange #FF4F1F (255, 79, 31) yalniz vurgu, secili ve ilerleme.
  { id = "bloodorange", name = "Blood Orange", colors = {
    bg = { 0.07, 0.085, 0.11, 0.96 }, titleBg = { 0.10, 0.12, 0.155, 1 }, card = { 0.09, 0.105, 0.135, 0.96 },
    border = { 0.22, 0.26, 0.32, 1 }, borderLit = { 0.36, 0.41, 0.49, 1 },
    accent = { 1.00, 0.31, 0.12, 1 }, accentHover = { 1.00, 0.46, 0.28, 1 }, accentSoft = { 0.24, 0.10, 0.07, 0.96 },
    button = { 0.13, 0.155, 0.195, 0.92 }, buttonHover = { 0.19, 0.22, 0.275, 0.92 }, buttonOff = { 0.105, 0.12, 0.15, 0.80 },
    text = { 0.89, 0.92, 0.94, 1 }, textDim = { 0.60, 0.65, 0.72, 1 }, textOff = { 0.40, 0.44, 0.50, 1 },
    panel = { 0.06, 0.075, 0.10, 0.95 }, row = { 0.11, 0.13, 0.165, 0.95 }, rowActive = { 0.20, 0.11, 0.09, 0.97 },
    highlight = { 0.80, 0.87, 0.92, 1 }, progress = { 1.00, 0.40, 0.18, 1 }, frameBorder = { 0.28, 0.33, 0.41, 1 },
  } },
  { id = "minimal", name = "Minimal", colors = {
    bg = { 0.03, 0.03, 0.03, 0.88 }, titleBg = { 0.06, 0.06, 0.06, 0.9 }, card = { 0.05, 0.05, 0.05, 0.85 },
    border = { 0.14, 0.14, 0.14, 1 }, borderLit = { 0.30, 0.30, 0.30, 1 },
    accent = { 0.92, 0.92, 0.92, 1 }, accentHover = { 1, 1, 1, 1 }, accentSoft = { 0.12, 0.12, 0.12, 0.9 },
    button = { 0.08, 0.08, 0.08, 0.85 }, buttonHover = { 0.16, 0.16, 0.16, 0.9 },
    panel = { 0.02, 0.02, 0.02, 0.80 }, row = { 0.04, 0.04, 0.04, 0.80 }, rowActive = { 0.10, 0.10, 0.10, 0.9 },
    highlight = { 0.98, 0.98, 0.98, 1 }, progress = { 0.85, 0.85, 0.85, 1 }, frameBorder = { 0.18, 0.18, 0.18, 1 },
  } },
}

-- Oyunun ipucu kenari: yuvarlak koseli kenar dokusu (ApplyRound)
local WOW = { edge = "Interface\\Tooltips\\UI-Tooltip-Border" }


local function set(t, v) t[1], t[2], t[3], t[4] = v[1], v[2], v[3], v[4] or 1 end

function Skin:GetTheme(id)
  for _, t in ipairs(self.Themes) do if t.id == id then return t end end
  return self.Themes[1]
end

-- id: tema; accent: {r,g,b} ya da nil (temanin vurgusu).
function Skin:ApplyTheme(id, accent)
  local theme = self:GetTheme(id)
  local before = self:SnapshotPalette()
  for k, v in pairs(DEFAULTS) do if self.Colors[k] then set(self.Colors[k], v) end end
  for k, v in pairs(theme.colors) do if self.Colors[k] then set(self.Colors[k], v) end end
  if type(accent) == "table" and accent[1] then
    local r, g, b = accent[1], accent[2], accent[3]
    set(self.Colors.accent, { r, g, b, 1 })
    set(self.Colors.accentHover, { math.min(1, r + 0.12), math.min(1, g + 0.12), math.min(1, b + 0.12), 1 })
    set(self.Colors.accentSoft, { r * 0.22, g * 0.22, b * 0.22, 0.96 })
  end
  self.theme = theme.id
  self:Repaint(before)
end

-- Canli tema: ApplyTheme renk tablolarini yerinde gunceller; zaten cizilmis dokular, yazilar ve
-- arka planlar ise kayitli kok pencerelerde gezilerek eski tema rengi -> yeni tema rengi eslenir.
-- Saydamlik (alfa) korunur. Skin:Fill ile boyanan dokular dogrudan tablodan yeniden boyanir.
Skin.roots = {}
function Skin:RegisterRoot(frame)
  if not frame then return frame end
  for _, f in ipairs(self.roots) do if f == frame then return frame end end
  self.roots[#self.roots + 1] = frame
  return frame
end

function Skin:Fill(tex, color, alpha)
  tex:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
  tex._skinFill, tex._skinFillA = color, alpha
end

function Skin:SnapshotPalette()
  local snap = {}
  for k, c in pairs(self.Colors) do snap[k] = { c[1], c[2], c[3], c[4] } end
  return snap
end

local function close(a, b) return math.abs(a - b) < 0.004 end

function Skin:Repaint(before)
  if not before then return end
  local map, keys = {}, {}
  for k in pairs(before) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local o, n = before[k], self.Colors[k]
    if n and not (close(o[1], n[1]) and close(o[2], n[2]) and close(o[3], n[3])) then
      map[#map + 1] = { o, n, k }
    end
  end
  -- belirsiz eslemeleri at: eski deger degismeyen bir anahtarla ya da farkli yeni degerli baska bir
  -- anahtarla ayniysa hangi rengin kastedildigi bilinemez, dokunulmaz.
  local function eq(a, b) return close(a[1], b[1]) and close(a[2], b[2]) and close(a[3], b[3]) end
  local clean = {}
  for _, m in ipairs(map) do
    local ok = true
    for _, k in ipairs(keys) do
      if k ~= m[3] and eq(before[k], m[1]) then
        local n = self.Colors[k]
        if not n or not eq(n, m[2]) then ok = false break end
      end
    end
    if ok then clean[#clean + 1] = m end
  end
  map = clean
  if #map > 0 and #self.roots > 0 then
    local function find(r, g, b)
      if not r then return nil end
      for _, m in ipairs(map) do
        local o = m[1]
        if close(r, o[1]) and close(g, o[2]) and close(b, o[3]) then return m[2] end
      end
    end
    local seen = {}
    local function paintRegion(rg)
      if rg._skinFixed then return end
      if rg._skinFill then
        self:Fill(rg, rg._skinFill, rg._skinFillA)
        return
      end
      local kind = rg.GetObjectType and rg:GetObjectType()
      if kind == "FontString" then
        if rg.GetTextColor then
          local r, g, b, a = rg:GetTextColor()
          local n = find(r, g, b)
          if n then rg:SetTextColor(n[1], n[2], n[3], a or 1) end
        end
      elseif rg.GetVertexColor then
        local r, g, b, a = rg:GetVertexColor()
        local n = find(r, g, b)
        if n then rg:SetVertexColor(n[1], n[2], n[3], a or 1) end
      end
    end
    local function walk(f)
      if not f or seen[f] or f._skinFixed then return end
      seen[f] = true
      if f.GetBackdropColor and (not f.GetBackdrop or f:GetBackdrop()) then
        local r, g, b, a = f:GetBackdropColor()
        local n = find(r, g, b)
        if n then f:SetBackdropColor(n[1], n[2], n[3], a or 1) end
        if f.GetBackdropBorderColor then
          r, g, b, a = f:GetBackdropBorderColor()
          n = find(r, g, b)
          if n then f:SetBackdropBorderColor(n[1], n[2], n[3], a or 1) end
        end
      end
      if f.GetRegions then
        for _, rg in ipairs({ f:GetRegions() }) do pcall(paintRegion, rg) end
      end
      local ch = f.chrome
      if ch and ch.SetColors and ch.body.GetVertexColor then
        local r, g, b, a = ch.body:GetVertexColor()
        local br, bg, bb, ba = ch.bTop:GetVertexColor()
        if r and br then ch:SetColors({ r, g, b, a }, { br, bg, bb, ba }) end
      end
      if f.GetChildren then
        for _, c in ipairs({ f:GetChildren() }) do walk(c) end
      end
    end
    for _, root in ipairs(self.roots) do pcall(walk, root) end
  end
  if ns.Send then ns:Send("ARCANIS_SKIN_CHANGED", "theme") end
end

Skin.Constants = {
  FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
  FONT_SIZE = 12,
  FONT_SIZE_SMALL = 10,
  EDGE = 1,
}

local WHITE = "Interface\\Buttons\\WHITE8x8"

-- Yazi tipi ve boyut carpani kullanici ayarindan gelir. Skin:SetFont ile kurulan her yazi kaydedilir,
-- boylece Skin:ApplyFont tipi ve boyutu /reload olmadan hemen tum pencerelere uygular.
local FONT_DIR = "Interface\\AddOns\\Arcanis\\Media\\Fonts\\"
Skin.Fonts = {
  { id = "default", name = "Friz Quadrata", path = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" },
  { id = "righteous", name = "Righteous", path = FONT_DIR .. "Righteous.ttf" },   -- varsayilan (Skin.DEFAULT_FONT)
  { id = "arial", name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
  { id = "skurri", name = "Skurri", path = "Fonts\\skurri.ttf" },
  { id = "morpheus", name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
}
Skin.DEFAULT_FONT = "righteous"   -- secilmemisse ya da kaldirilmis bir font secilmisse bu kullanilir
Skin.fontScale = 1
local fontRegistry = setmetatable({}, { __mode = "k" })

-- Paylasilan medya kutuphanesi yukluyse onun yazi tiplerini de listeye ekler (en fazla 12).
function Skin:CollectFonts()
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if not LSM or self.lsmCollected then return self.Fonts end
  self.lsmCollected = true
  local known, added = {}, 0
  for _, f in ipairs(self.Fonts) do known[f.name:lower()] = true; known[f.path:lower()] = true end
  for _, name in ipairs(LSM:List("font") or {}) do
    local path = LSM:Fetch("font", name, true)
    if path and not known[name:lower()] and not known[path:lower()] and added < 12 then
      self.Fonts[#self.Fonts + 1] = { id = "lsm:" .. name, name = name, path = path }
      known[path:lower()] = true
      added = added + 1
    end
  end
  return self.Fonts
end

function Skin:ApplyFont(id, scale)
  if type(id) == "string" and id:sub(1, 4) == "lsm:" then self:CollectFonts() end
  local font, fallback = nil, self.Fonts[1]
  for _, f in ipairs(self.Fonts) do
    if f.id == id then font = f end
    if f.id == self.DEFAULT_FONT then fallback = f end
  end
  font = font or fallback
  self.Constants.FONT = font.path
  self.fontState = nil
  if font ~= self.Fonts[1] then self:ProbeFont(font.path, 1) end
  self.font = font.id
  self.fontScale = math.max(0.7, math.min(1.5, tonumber(scale) or 1))
  -- kayitli tum yazilari yeniden bicimle
  -- yazi dosyasi ilk kez yuklenirken WoW mevcut metni bos cizebilir: metin yeniden yazilir ve
  -- kisa bir gecikmeyle bir kez daha tazelenir.
  self:Refont()
  if C_Timer and C_Timer.After then C_Timer.After(0.1, function() Skin:Refont() end) end
  if ns.Send then ns:Send("ARCANIS_SKIN_CHANGED", "font") end
end

-- Yazi tipi dosyasi oyunda yuklendi mi. Ilk basvuruda dosya henuz hazir olmayabilir: birkac kez yeniden
-- denenir, basarida tum yazilar yeniden bicimlenir. Yalniz son deneme de basarisizsa uyarilir; secilen yazi
-- tipi birakilmaz (yuklenemeyen yazi sablonun yazisiyla gorunur kalir, sonra duzelir).
local PROBE_DELAYS = { 0.5, 2, 5 }
function Skin:ProbeFont(path, try)
  if not (UIParent and UIParent.CreateFontString) then return end
  self.probe = self.probe or UIParent:CreateFontString(nil, "OVERLAY")
  local ok = self.probe:SetFont(path, 12, "")
  local got = self.probe:GetFont()
  local file = path:lower():match("([^\\/]+)$") or path:lower()
  local loaded = ok ~= false and type(got) == "string" and got:lower():find(file, 1, true) ~= nil
  self.fontState = { path = path, ok = ok, got = got, loaded = loaded, try = try }
  if loaded then
    if try > 1 then self:Refont() end
    return
  end
  if path ~= self.Constants.FONT then return end
  local delay = PROBE_DELAYS[try]
  if delay and C_Timer and C_Timer.After then
    C_Timer.After(delay, function() if Skin.Constants.FONT == path then Skin:ProbeFont(path, try + 1) end end)
  elseif ns.Print and ns.L then
    ns:Print(ns.L["This font could not be loaded. Restart the game fully (not /reload) after installing new font files."])
  end
end

-- Kayitli tum yazilari su anki tip ve boyutla yeniden bicimler.
function Skin:Refont()
  for fs, spec in pairs(fontRegistry) do
    pcall(function()
      self:SetFont(fs, spec[1], spec[2])
      local t = fs.GetText and fs:GetText()
      if t and t ~= "" then fs:SetText(""); fs:SetText(t) end
    end)
  end
end

function Skin:SetFont(fontString, size, flags)
  size = size or self.Constants.FONT_SIZE
  local px = math.floor(size * (self.fontScale or 1) + 0.5)
  fontString:SetFont(self.Constants.FONT, px, flags or "")
  -- hic yazi tipi yoksa metin gorunmez: oyunun yazisi
  if fontString.GetFont and not fontString:GetFont() then
    fontString:SetFont(self.Fonts[1].path, px, flags or "")
  end
  local spec = fontRegistry[fontString]
  if spec then spec[1], spec[2] = size, flags else fontRegistry[fontString] = { size, flags } end
end

-- Piksel hizalama (sahibin bulgusu, 13 Kasim 2026: dusuk cozunurlukte kenarlar bozuk). 1 arayuz birimi dusuk
-- cozunurlukte 1 ekran pikselinden kucuk (ornek 1600x900, UI olcegi 0.71: 0.83 piksel); boyle ince cizgiler
-- piksel izgarasina yuvarlanirken bazi kenarlarda 0, bazilarinda 2 piksel olur. Px: n birimi bolgenin olcegine
-- gore tam ekran pikseline (en az 1) yuvarlar. Hairline / ApplyBackdrop kayitlidir; olcek degisince Resnap.
local function physH()
  if GetPhysicalScreenSize then
    local _, h = GetPhysicalScreenSize()
    if type(h) == "number" and h > 0 then return h end
  end
end
local function effScale(region)
  local r = region
  if r and not r.GetEffectiveScale and r.GetParent then r = r:GetParent() end
  local s = r and r.GetEffectiveScale and r:GetEffectiveScale()
  return (type(s) == "number" and s > 0) and s or 1
end
-- Bolgenin biriminde bir ekran pikseli basina dusen piksel sayisi (bilinmiyorsa 1).
function Skin:PixelsPerUnit(region)
  local h = physH()
  if not h then return 1 end
  return h / 768 * effScale(region)
end
function Skin:Px(region, n)
  n = n or 1
  local k = self:PixelsPerUnit(region)
  return math.max(1, math.floor(n * k + 0.5)) / k
end

local hairlines = setmetatable({}, { __mode = "k" })
local backdrops = setmetatable({}, { __mode = "k" })
-- Ince cizgi dokusu: axis "h" (yatay, yukseklik) ya da "w" (dikey, genislik); n piksel.
function Skin:Hairline(tex, axis, n)
  hairlines[tex] = { axis, n or 1 }
  local v = self:Px(tex, n or 1)
  if axis == "w" then tex:SetWidth(v) else tex:SetHeight(v) end
  return tex
end

local function setPixelBackdrop(frame, edge)
  frame:SetBackdrop({
    bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = edge,
    insets = { left = edge, right = edge, top = edge, bottom = edge },
  })
end

-- Olcek degisince (UI olcegi, cozunurluk, pencere olcegi) kayitli cizgi ve kenarlari yeniden hizalar.
function Skin:Resnap()
  for tex, spec in pairs(hairlines) do pcall(self.Hairline, self, tex, spec[1], spec[2]) end
  for frame in pairs(backdrops) do
    pcall(function()
      local bd = frame.GetBackdrop and frame:GetBackdrop()
      if not (bd and bd.edgeFile == WHITE) then return end
      local edge = self:Px(frame, self.Constants.EDGE)
      if bd.edgeSize == edge then return end
      local r, g, b, a = frame:GetBackdropColor()
      local br, bg, bb, ba = frame:GetBackdropBorderColor()
      setPixelBackdrop(frame, edge)
      if r then frame:SetBackdropColor(r, g, b, a) end
      if br then frame:SetBackdropBorderColor(br, bg, bb, ba) end
    end)
  end
end
do
  local ok, ev = pcall(CreateFrame, "Frame")
  if ok and ev and ev.RegisterEvent then
    for _, e in ipairs({ "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "PLAYER_ENTERING_WORLD" }) do pcall(ev.RegisterEvent, ev, e) end
    ev:SetScript("OnEvent", function() Skin:Resnap() end)
  end
end

function Skin:ApplyBackdrop(frame, bgColor, borderColor)
  if not frame.SetBackdrop and BackdropTemplateMixin and Mixin then
    Mixin(frame, BackdropTemplateMixin)
  end
  setPixelBackdrop(frame, self:Px(frame, self.Constants.EDGE))
  backdrops[frame] = true
  local bg = bgColor or self.Colors.bg
  local border = borderColor or self.Colors.border
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

-- Yuvarlak koseli dolgu (sohbet balonu, gun etiketi): oyunun yuvarlak ipucu kenari dolguyla ayni renkte.
Skin.ROUND_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
function Skin:ApplyBubble(frame, color, edge)
  if not frame.SetBackdrop and BackdropTemplateMixin and Mixin then Mixin(frame, BackdropTemplateMixin) end
  edge = edge or 12
  local inset = math.floor(edge / 4)
  frame:SetBackdrop({ bgFile = WHITE, edgeFile = self.ROUND_EDGE, tile = false, edgeSize = edge,
    insets = { left = inset, right = inset, top = inset, bottom = inset } })
  local c = color or self.Colors.card
  frame:SetBackdropColor(c[1], c[2], c[3], c[4] or 1)
  frame:SetBackdropBorderColor(c[1], c[2], c[3], c[4] or 1)
end

-- Duz yuvarlak dolgu (sohbet balonu): tek renk + dolu kose dokusu; kenar golgesi yok (ipucu kenar dokusu acik
-- renkte koyu bir halka birakiyordu). Tekrar cagrilirsa yalniz renk degisir.
function Skin:ApplyRounded(f, color, radius)
  radius = radius or 8
  if f.SetBackdrop and f.GetBackdrop and f:GetBackdrop() then pcall(f.SetBackdrop, f, nil) end
  local r = f.round
  if not r or r.radius ~= radius then
    if not r then
      r = {}
      local function tx(path)
        local t = f:CreateTexture(nil, "BACKGROUND", nil, -8)
        t:SetTexture(path or WHITE)
        t._skinFixed = true
        return t
      end
      r.mid, r.top, r.bottom = tx(), tx(), tx()
      r.tl, r.tr, r.bl, r.br = tx(self.Icons.corner), tx(self.Icons.corner), tx(self.Icons.corner), tx(self.Icons.corner)
      r.tr:SetTexCoord(1, 0, 0, 1); r.bl:SetTexCoord(0, 1, 1, 0); r.br:SetTexCoord(1, 0, 1, 0)
      f.round = r
    end
    r.radius = radius
    for _, t in ipairs({ r.mid, r.top, r.bottom, r.tl, r.tr, r.bl, r.br }) do t:ClearAllPoints() end
    r.mid:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -radius); r.mid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, radius)
    r.top:SetPoint("TOPLEFT", f, "TOPLEFT", radius, 0); r.top:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -radius, -radius)
    r.bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", radius, 0); r.bottom:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -radius, radius)
    for _, t in ipairs({ r.tl, r.tr, r.bl, r.br }) do t:SetSize(radius, radius) end
    r.tl:SetPoint("TOPLEFT"); r.tr:SetPoint("TOPRIGHT"); r.bl:SetPoint("BOTTOMLEFT"); r.br:SetPoint("BOTTOMRIGHT")
  end
  local c = color or self.Colors.card
  for _, t in ipairs({ r.mid, r.top, r.bottom, r.tl, r.tr, r.bl, r.br }) do t:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
end

-- Yuvarlak avatar: renkli daire + adin bas harfi. av:Set(ad, renk)
-- Oyunun sinif ikonlari (karakter yaratma dokusu); bilinmeyen sinifta nil.
Skin.CLASS_TEX = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local CLASS_COORDS = {
  WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 }, ROGUE = { 0.5, 0.75, 0, 0.25 }, DRUID = { 0.75, 1, 0, 0.25 },
  HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.5, 0.25, 0.5 }, PRIEST = { 0.5, 0.75, 0.25, 0.5 }, WARLOCK = { 0.75, 1, 0.25, 0.5 },
  PALADIN = { 0, 0.25, 0.5, 0.75 },
}
function Skin:ClassCoords(token)
  if type(token) ~= "string" then return nil end
  return (CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]) or CLASS_COORDS[token]
end

-- Yuvarlak avatar: sinif biliniyorsa oyunun sinif ikonu, yoksa renkli daire + bas harf.
-- Set(name, color, class, tag): tag, ad gizli bir Battle.net kodu (|K..|k) oldugunda harf icin kullanilir.
function Skin:CreateAvatar(parent, size)
  local av = CreateFrame("Frame", nil, parent)
  av:SetSize(size, size)
  av.disc = av:CreateTexture(nil, "ARTWORK")
  av.disc:SetAllPoints()
  av.disc:SetTexture(self.Icons.disc)
  av.disc._skinFixed = true
  av.icon = av:CreateTexture(nil, "OVERLAY")
  av.icon:SetPoint("CENTER")
  av.icon:SetSize(size - 2, size - 2)
  av.icon._skinFixed = true
  av.icon:Hide()
  av.letter = av:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(av.letter, math.max(9, math.floor(size * 0.5)), "")
  av.letter:SetPoint("CENTER", 0, 0)
  av.letter:SetTextColor(1, 1, 1, 1)
  function av:Set(name, color, class, tag)
    local c = color or Skin.Colors.accent
    self.disc:SetVertexColor(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1)
    local tc = Skin:ClassCoords(class)
    if tc then
      self.icon:SetTexture(Skin.CLASS_TEX)
      self.icon:SetTexCoord(tc[1] + 0.01, tc[2] - 0.01, tc[3] + 0.01, tc[4] - 0.01)
      self.icon:Show(); self.letter:Hide()
      return
    end
    self.icon:Hide(); self.letter:Show()
    local src = type(name) == "string" and not name:find("|K", 1, true) and name or tag
    local first = type(src) == "string" and src:match("^[%z\1-\127\194-\244][\128-\191]*") or "?"
    self.letter:SetText(first:upper())
  end
  return av
end

-- Renkli resim dugmesi (emoji): doku boyanmaz; ustune gelince hafif yuvarlak zemin ve buyume.
function Skin:CreateImageButton(parent, texture, size)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  b.hl = b:CreateTexture(nil, "BACKGROUND")
  b.hl:SetAllPoints()
  b.hl:SetTexture(self.Icons.disc)
  b.hl:SetVertexColor(1, 1, 1, 0.10)
  b.hl._skinFixed = true
  b.hl:Hide()
  b.img = b:CreateTexture(nil, "OVERLAY")
  b.img:SetPoint("CENTER")
  b.img:SetSize(size - 6, size - 6)
  b.img:SetTexture(texture)
  b.img._skinFixed = true
  b:SetScript("OnEnter", function(x)
    x.hl:Show(); x.img:SetSize(size - 3, size - 3)
    if x.tip and GameTooltip then GameTooltip:SetOwner(x, "ANCHOR_TOP"); GameTooltip:SetText(x.tip); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave", function(x)
    x.hl:Hide(); x.img:SetSize(size - 6, size - 6)
    if GameTooltip then GameTooltip:Hide() end
  end)
  function b:SetTooltip(t) self.tip = t end
  return b
end

-- Yuvarlak dolu ikon dugmesi (sohbette gonder): vurgu renginde daire + beyaz ikon; ustune gelince acilir.
-- shape = "square": daire yerine koseleri yumusak kare (ApplyRounded), ornek sohbetin gonder dugmesi.
function Skin:CreateRoundIconButton(parent, iconName, size, shape)
  local C = self.Colors
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  if shape ~= "square" then
    b.disc = b:CreateTexture(nil, "ARTWORK")
    b.disc:SetAllPoints()
    b.disc:SetTexture(self.Icons.disc)
  end
  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetSize(math.floor(size * 0.55), math.floor(size * 0.55))
  b.icon:SetPoint("CENTER")
  b.icon:SetTexture(self.Icons[iconName] or iconName)
  b.icon:SetVertexColor(1, 1, 1, 1)
  b.icon._skinFixed = true
  local function paint(over)
    local c = over and C.accentHover or C.accent
    if b.disc then b.disc:SetVertexColor(c[1], c[2], c[3], 1) else Skin:ApplyRounded(b, c, math.floor(size * 0.25)) end
  end
  paint(false)
  b:SetScript("OnEnter", function(x)
    paint(true)
    if x.tip and GameTooltip then GameTooltip:SetOwner(x, "ANCHOR_TOP"); GameTooltip:SetText(x.tip); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave", function() paint(false); if GameTooltip then GameTooltip:Hide() end end)
  function b:SetTooltip(t) self.tip = t end
  return b
end

-- Duz dugme. SetText/SetEnabled'i sarar; devre disiyken soluk gorunur.
function Skin:CreateButton(parent, text, width, height, primary)
  local C = self.Colors
  local baseBg = primary and C.accentSoft or C.button
  local baseBorder = primary and C.accent or C.border
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(width or 120, height or 24)
  self:ApplyBackdrop(btn, baseBg, baseBorder)

  btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  btn.text:SetPoint("CENTER")
  btn.text:SetText(text or "")
  self:SetFont(btn.text, self.Constants.FONT_SIZE, "OUTLINE")
  btn.text:SetTextColor(unpack(primary and C.accentHover or C.text))
  btn.enabled = true

  function btn:SetText(value) self.text:SetText(value) end
  function btn:GetText() return self.text:GetText() end
  function btn:SetEnabled(value)
    self.enabled = value and true or false
    if self.enabled then
      self:SetBackdropColor(unpack(baseBg))
      self:SetBackdropBorderColor(unpack(baseBorder))
      self.text:SetTextColor(unpack(primary and C.accentHover or C.text))
    else
      self:SetBackdropColor(unpack(C.buttonOff))
      self:SetBackdropBorderColor(unpack(C.border))
      self.text:SetTextColor(unpack(C.textOff))
    end
  end
  function btn:Enable() self:SetEnabled(true) end
  function btn:Disable() self:SetEnabled(false) end
  function btn:IsEnabled() return self.enabled end

  btn:SetScript("OnEnter", function(self)
    if not self.enabled then return end
    self:SetBackdropColor(unpack(C.buttonHover))
    self:SetBackdropBorderColor(unpack(C.accent))
  end)
  btn:SetScript("OnLeave", function(self)
    if not self.enabled then return end
    self:SetBackdropColor(unpack(baseBg))
    self:SetBackdropBorderColor(unpack(baseBorder))
  end)
  btn:SetScript("OnMouseDown", function(self)
    if self.enabled then self.text:SetPoint("CENTER", 1, -1) end
  end)
  btn:SetScript("OnMouseUp", function(self) self.text:SetPoint("CENTER", 0, 0) end)
  return btn
end

-- Onay kutusu (tek standart): 18x18 kare; metin bossa cerceve kutu boyunda, varsa 8 px sagina yazilir.
-- API: cb:SetChecked(v [, silent]), cb:SetText(s), cb:SetTooltip(fn -> metin), cb.callback(v), cb.checked.
-- size: kutu kenari (varsayilan 18; dar satirlarda daha kucuk)
function Skin:CreateCheckbox(parent, text, checked, callback, size)
  local C = self.Colors
  local BOX = size or 18
  local cb = CreateFrame("Frame", nil, parent)
  cb.box = CreateFrame("Button", nil, cb, "BackdropTemplate")
  cb.box:SetSize(BOX, BOX)
  cb.box:SetPoint("LEFT", 0, 0)
  cb.check = cb.box:CreateTexture(nil, "OVERLAY")
  self:ApplyBackdrop(cb.box, C.button, C.border)
  cb.check:SetTexture(WHITE)
  cb.check:SetPoint("CENTER")
  cb.check:SetSize(math.floor(BOX * 0.55 + 0.5), math.floor(BOX * 0.55 + 0.5))
  cb.check:SetVertexColor(unpack(C.accent))

  cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cb.label:SetPoint("LEFT", cb.box, "RIGHT", 8, 0)
  self:SetFont(cb.label, 11, "OUTLINE")
  cb.label:SetTextColor(unpack(C.text))

  local function paint(hover)
    local border = hover and C.borderLit or (cb.checked and C.accent or C.border)
    cb.box:SetBackdropBorderColor(unpack(border))
  end
  function cb:SetText(value)
    value = value or ""
    self.label:SetText(value)
    if value == "" then self:SetSize(BOX, BOX) else self:SetSize(200, 20) end
  end
  cb.callback = callback
  function cb:SetChecked(value, silent)
    self.checked = value and true or false
    if self.checked then self.check:Show() else self.check:Hide() end
    paint(false)
    if self.callback and not silent then self.callback(self.checked) end
  end
  function cb:SetTooltip(fn) self.tooltip = fn end
  cb.box:SetScript("OnClick", function() cb:SetChecked(not cb.checked) end)
  cb.box:SetScript("OnEnter", function(b)
    paint(true)
    local tip = cb.tooltip and cb.tooltip()
    if tip and GameTooltip then GameTooltip:SetOwner(b, "ANCHOR_LEFT"); GameTooltip:SetText(tip); GameTooltip:Show() end
  end)
  cb.box:SetScript("OnLeave", function() paint(false); if GameTooltip then GameTooltip:Hide() end end)
  cb:SetText(text)
  cb:SetChecked(checked, true)
  return cb
end

-- Ayarlar paneli bilesenleri

-- Anahtar (ac/kapa): sw:SetChecked(v [, silent]), sw.checked; degisince callback(v).
-- Yuvarlak koseli kutu (anahtar rayi, ayar karti): oyunun ipucu kenari ince boyutta, kenar rengi ayri.
function Skin:ApplyRound(frame, bgColor, borderColor, edge)
  if not frame.SetBackdrop and BackdropTemplateMixin and Mixin then Mixin(frame, BackdropTemplateMixin) end
  edge = edge or 4
  local inset = edge >= 10 and 3 or 1
  frame:SetBackdrop({ bgFile = WHITE, edgeFile = WOW.edge, tile = false, edgeSize = edge,
    insets = { left = inset, right = inset, top = inset, bottom = inset } })
  local bg, border = bgColor or self.Colors.bg, borderColor or self.Colors.border
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

-- Anahtar: yuvarlak ray (46x20), kayan dugme; acikken ray vurgu tonunda. Uzerine gelince kenar parlar;
-- sw:SetEnabled(false) soluk ve tiklanmaz. Sessiz SetChecked (kurulum, yenileme) dugmeyi kaydirmadan koyar.
local SW_W, SW_H, SW_KNOB = 46, 20, 18
function Skin:CreateSwitch(parent, text, checked, callback)
  local C = self.Colors
  local sw = CreateFrame("Frame", nil, parent)
  sw:SetSize(260, 22)

  sw.track = CreateFrame("Button", nil, sw, "BackdropTemplate")
  sw.track:SetSize(SW_W, SW_H)
  sw.track:SetPoint("LEFT", 0, 0)
  self:ApplyRound(sw.track, C.button, C.border)

  sw.thumb = CreateFrame("Frame", nil, sw.track, "BackdropTemplate")
  sw.thumb:SetSize(SW_KNOB, SW_H - 4)
  self:ApplyRound(sw.thumb, C.accent, C.accentSoft)

  sw.label = sw:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sw.label:SetPoint("LEFT", sw.track, "RIGHT", 8, 0)
  sw.label:SetText(text or "")
  self:SetFont(sw.label, 11)
  sw.label:SetTextColor(unpack(C.text))

  local function knob(x) sw.thumb:ClearAllPoints(); sw.thumb:SetPoint("LEFT", sw.track, "LEFT", x, 0) end
  local OFF_X, ON_X = 2, SW_W - SW_KNOB - 2
  sw.callback = callback
  local function mix(a, b, t)
    return a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t, (a[4] or 1) + ((b[4] or 1) - (a[4] or 1)) * t
  end
  -- t: 0 kapali, 1 acik; dugme konumu ve renkler birlikte gecer
  local function paint(t)
    sw.pos = t
    sw.knobX = OFF_X + (ON_X - OFF_X) * t
    knob(sw.knobX)
    sw.thumb:SetBackdropColor(mix(C.textOff, C.accent, t))
    sw.thumb:SetBackdropBorderColor(mix(C.buttonOff, C.accentSoft, t))
    sw.track:SetBackdropColor(mix(C.button, C.accentSoft, t))
    if sw.hover then sw.track:SetBackdropBorderColor(unpack(C.borderLit))
    else sw.track:SetBackdropBorderColor(mix(C.border, C.accent, t)) end
  end
  function sw:SetChecked(value, silent)
    local was = self.checked
    self.checked = value and true or false
    local to = self.checked and 1 or 0
    if was == self.checked and Skin:IsTweening(self) then
      -- ayni degerle sessiz yenileme (ayar sayfasi tazelemesi) suren kaymayi kesmesin
    elseif silent or was == nil or was == self.checked then
      Skin:CancelTween(self)
      paint(to)
    else
      local from = self.pos or (1 - to)
      -- ease-in-out: ResourceForge'daki gibi gorunur kayma (yalniz ease-out ilk karede bitmis gibi duruyordu)
      Skin:Tween(self, 0.22, function(p)
        local q = 1 - (1 - p) ^ (1 / 3)              -- Tick'in ease-out'unu dogrusala cevir
        q = q < 0.5 and 4 * q * q * q or 1 - (-2 * q + 2) ^ 3 / 2
        paint(from + (to - from) * q)
      end)
    end
    if self.callback and not silent then self.callback(self.checked) end
  end
  function sw:SetEnabled(on)
    self.disabled = not on
    self.track:EnableMouse(on and true or false)
    self:SetAlpha(on and 1 or 0.45)
  end
  sw.track:SetScript("OnEnter", function() sw.hover = true; sw.track:SetBackdropBorderColor(unpack(C.borderLit)) end)
  sw.track:SetScript("OnLeave", function()
    sw.hover = nil
    sw.track:SetBackdropBorderColor(unpack(sw.checked and C.accent or C.border))
  end)
  function sw:SetText(value) self.label:SetText(value) end
  -- Saga dayali kullanim: cerceve ray boyutunda (46x22), etiket rayin SOLUNDA 8 px, saga yasli.
  function sw:SetLabelLeft()
    self:SetSize(SW_W, 22)
    self.track:ClearAllPoints()
    self.track:SetPoint("RIGHT", 0, 0)
    self.label:ClearAllPoints()
    self.label:SetPoint("RIGHT", self.track, "LEFT", -8, 0)
    self.label:SetJustifyH("RIGHT")
  end
  sw.track:SetScript("OnClick", function() sw:SetChecked(not sw.checked) end)
  sw:SetChecked(checked, true)
  return sw
end

-- Kaydirici: s:Set(v [, silent]), s.value; kullanici degistirince callback(v).
function Skin:CreateSlider(parent, min, max, step, value, callback, width, fmt)
  local C = self.Colors
  local s = CreateFrame("Frame", nil, parent)
  s:SetSize(width or 220, 22)
  s.min, s.max, s.step, s.callback = min or 0, max or 1, step or 0.1, callback
  s.fmt = fmt or "%.1f"

  s.bar = CreateFrame("Slider", nil, s)
  s.bar:SetOrientation("HORIZONTAL")
  s.bar:SetPoint("LEFT", 0, 0)
  s.bar:SetPoint("RIGHT", s, "RIGHT", -50, 0)
  s.bar:SetHeight(14)
  s.bar:SetMinMaxValues(s.min, s.max)
  s.bar:SetValueStep(s.step)
  if s.bar.SetObeyStepOnDrag then s.bar:SetObeyStepOnDrag(true) end

  s.rail = s.bar:CreateTexture(nil, "BACKGROUND")
  s.rail:SetTexture(WHITE)
  s.rail:SetVertexColor(unpack(C.barTrack))
  s.rail:SetPoint("LEFT", 0, 0)
  s.rail:SetPoint("RIGHT", 0, 0)
  s.rail:SetHeight(4)

  s.thumb = s.bar:CreateTexture(nil, "OVERLAY")
  s.thumb:SetTexture(WHITE)
  s.thumb:SetVertexColor(unpack(C.accent))
  s.thumb:SetSize(8, 14)
  -- secili kisim: raydan dugmeye kadar vurgu renginde ince serit (degerin nerede oldugu bir bakista)
  s.fill = s.bar:CreateTexture(nil, "ARTWORK")
  Skin:Fill(s.fill, C.accent, 0.8)
  s.fill:SetHeight(2)
  s.fill:SetPoint("LEFT", s.rail, "LEFT", 0, 0)
  s.fill:SetPoint("RIGHT", s.thumb, "CENTER", 0, 0)
  s.bar:SetThumbTexture(s.thumb)

  s.text = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  -- deger sagdaki kontrollerle ayni kenara dayanir (anahtarlar gibi)
  s.text:SetPoint("LEFT", s.bar, "RIGHT", 8, 0)
  s.text:SetPoint("RIGHT", s, "RIGHT", 0, 0)
  s.text:SetJustifyH("RIGHT")
  self:SetFont(s.text, 11, "OUTLINE")
  s.text:SetTextColor(unpack(C.text))

  function s:Set(v, silent)
    v = math.max(self.min, math.min(self.max, v or self.min))
    self.value = v
    self.silent = silent
    self.bar:SetValue(v)
    self.silent = nil
    self.text:SetText(self.fmt:format(v))
  end
  s.bar:SetScript("OnValueChanged", function(_, v)
    if s.silent then return end
    v = math.floor(v / s.step + 0.5) * s.step
    s.value = v
    s.text:SetText(s.fmt:format(v))
    if s.callback then s.callback(v) end
  end)
  s:Set(value or s.min, true)
  return s
end

-- Acilir liste: items = { { value = ..., text = ... }, ... }.
-- dd:SetItems(items), dd:SetValue(v [, silent]), dd.value; secilince callback(value).
-- Secim alani (TEK STANDART): koyu satir zemini, istege bagli sol ikon, metin, sagda asagi ok.
-- Uzerine gelince kehribar kenar. Tum acilir listeler, rehber secicileri bunu kullanir.
--   local fld = Skin:CreateField(parent, genislik, yukseklik, ikonAdi)
--   fld.text, fld.icon, fld.chev, fld:SetIcon(ad), fld:SetLabel(metin)
function Skin:CreateField(parent, width, height, iconName)
  local C = self.Colors
  local fld = CreateFrame("Button", nil, parent, "BackdropTemplate")
  fld:SetSize(width or 180, height or 24)
  self:ApplyBackdrop(fld, C.card, C.border)
  local h = height or 24
  if iconName then
    fld.icon = fld:CreateTexture(nil, "OVERLAY")
    fld.icon:SetSize(math.min(18, h - 8), math.min(18, h - 8))
    fld.icon:SetPoint("LEFT", 8, 0)
    fld.icon:SetTexture(self.Icons[iconName] or iconName)
    fld.icon:SetVertexColor(unpack(C.accent))
  end
  fld.text = fld:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if fld.icon then fld.text:SetPoint("LEFT", fld.icon, "RIGHT", 7, 0) else fld.text:SetPoint("LEFT", 9, 0) end
  fld.text:SetPoint("RIGHT", -24, 0)
  fld.text:SetJustifyH("LEFT")
  fld.text:SetWordWrap(false)
  self:SetFont(fld.text, h >= 30 and 13 or 11, "")
  fld.text:SetTextColor(unpack(C.text))
  fld.chev = fld:CreateTexture(nil, "OVERLAY")
  fld.chev:SetSize(11, 11)
  fld.chev:SetPoint("RIGHT", -8, 0)
  fld.chev:SetTexture(self.Icons.chevdown)
  fld.chev:SetVertexColor(unpack(C.textDim))
  function fld:SetIcon(name) if self.icon then self.icon:SetTexture(Skin.Icons[name] or name) end end
  function fld:SetLabel(t) self.text:SetText(t or "") end
  fld:SetScript("OnEnter", function(x) x:SetBackdropBorderColor(unpack(C.accent)); x.chev:SetVertexColor(unpack(C.accent)) end)
  fld:SetScript("OnLeave", function(x) x:SetBackdropBorderColor(unpack(C.border)); x.chev:SetVertexColor(unpack(C.textDim)) end)
  return fld
end

-- Acilir liste: Field + ortak acilir menu (Skin:ShowMenu). dd:SetValue(v [, sessiz]), dd:SetItems(list), dd.value.
function Skin:CreateDropdown(parent, width, items, selected, callback)
  local dd = self:CreateField(parent, width or 180, 24)
  dd.items, dd.callback = items or {}, callback

  function dd:Close() Skin:HideMenu() end

  function dd:SetValue(value, silent)
    self.value = value
    local label = ""
    for _, item in ipairs(self.items) do
      if item.value == value then label = item.text end
    end
    self.text:SetText(label)
    if self.callback and not silent then self.callback(value) end
  end

  function dd:SetItems(list)
    self.items = list or {}
    self:SetValue(self.value, true)
  end

  dd:SetScript("OnClick", function(b)
    local menu = {}
    for _, item in ipairs(b.items) do
      local v = item.value
      menu[#menu + 1] = { text = item.text, checked = v == b.value, onClick = function() b:SetValue(v) end }
    end
    Skin:ShowMenu(b, menu, b:GetWidth() or width or 180)
  end)
  dd:SetValue(selected, true)
  return dd
end

-- Metin kutusu: eb:GetText(); metin degisince callback(text, kullaniciGirdisiMi).
function Skin:CreateEditBox(parent, width, height, callback)
  local C = self.Colors
  local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
  box:SetSize(width or 180, height or 24)
  box:SetAutoFocus(false)
  box:SetTextInsets(8, 8, 0, 0)
  self:SetFont(box, 11, "")
  box:SetTextColor(unpack(C.text))
  self:ApplyBackdrop(box, C.bg, C.border)
  box:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)
  box:SetScript("OnEditFocusGained", function(b) b:SetBackdropBorderColor(unpack(C.accent)) end)
  box:SetScript("OnEditFocusLost", function(b) b:SetBackdropBorderColor(unpack(C.border)) end)
  if callback then box:SetScript("OnTextChanged", function(b, user) callback(b:GetText(), user) end) end
  return box
end

-- Animasyon: tek bir surucu cerceve; Skin:Tween(anahtar, sure, fn(p), bitti) p: 0..1 (yavaslayarak biter).
-- Ayni anahtarla yeni tween eskisinin yerini alir. Testlerde Skin:Tick(dt) elle cagrilir.
local tweens, tweenDriver = {}, nil

function Skin:Tween(key, duration, fn, done)
  tweens[key] = { t = 0, d = math.max(0.01, duration), fn = fn, done = done }
  if not tweenDriver then tweenDriver = CreateFrame("Frame") end
  tweenDriver:SetScript("OnUpdate", function(_, dt) Skin:Tick(dt) end)
end

function Skin:CancelTween(key) tweens[key] = nil end
function Skin:IsTweening(key) return tweens[key] ~= nil end

function Skin:Tick(dt)
  local keys = {}
  for key in pairs(tweens) do keys[#keys + 1] = key end    -- tween eklenirken dolasim bozulmasin
  for _, key in ipairs(keys) do
    local tw = tweens[key]
    if tw then
      tw.t = tw.t + dt
      local p = math.min(1, tw.t / tw.d)
      tw.fn(1 - (1 - p) ^ 3)
      if p >= 1 and tweens[key] == tw then
        tweens[key] = nil
        if tw.done then tw.done() end
      end
    end
  end
  if next(tweens) == nil and tweenDriver then tweenDriver:SetScript("OnUpdate", nil) end
end

local TRACK_W = 8
local WHEEL_STEP = 48

-- Kaydirmali alan: area.content, area:SetContentHeight(h), area:ScrollToTop(), area:ScrollTo(y [, anlik]).
-- Fare tekerlegi yumusak kayar; sag kenardaki tutamac surukle-birak ile oynar, boslugu tiklayinca sayfa atlar.
function Skin:CreateScrollArea(parent, width, height)
  local C = self.Colors
  local area = CreateFrame("ScrollFrame", nil, parent)
  area:SetSize(width, height)
  area.content = CreateFrame("Frame", nil, area)
  area.content:SetSize(width - TRACK_W - 4, 10)
  area:SetScrollChild(area.content)
  area:EnableMouseWheel(true)
  area.scrollPos = 0

  area.trackFrame = CreateFrame("Frame", nil, area, "BackdropTemplate")
  area.trackFrame:SetWidth(TRACK_W)
  area.trackFrame:SetPoint("TOPRIGHT", 0, 0)
  area.trackFrame:SetPoint("BOTTOMRIGHT", 0, 0)
  area.trackFrame:EnableMouse(true)
  self:ApplyBackdrop(area.trackFrame, C.barTrack, C.border)
  area.track = area.trackFrame

  area.thumbFrame = CreateFrame("Frame", nil, area.trackFrame, "BackdropTemplate")
  area.thumbFrame:SetWidth(TRACK_W - 2)
  area.thumbFrame:EnableMouse(true)
  self:ApplyBackdrop(area.thumbFrame, C.accent, C.accentHover)
  area.thumbFrame:SetAlpha(0.75)
  area.thumb = area.thumbFrame

  local function range(a)
    return math.max(0, (a.content:GetHeight() or 0) - (a:GetHeight() or height))
  end
  local function trackTravel(a)
    return math.max(1, (a:GetHeight() or height) - (a.thumbHeight or 16) - 2)
  end

  function area:Sync()
    local viewH = self:GetHeight() or height
    local contentH = self.content:GetHeight() or 10
    local r = math.max(0, contentH - viewH)
    local pos = math.max(0, math.min(self.scrollPos or 0, r))
    self.scrollPos = pos
    self:SetVerticalScroll(pos)
    if r <= 0 then
      self.trackFrame:Hide()
      return
    end
    self.trackFrame:Show()
    local thumbH = self.fixedThumb or math.max(20, viewH * viewH / contentH)
    self.thumbHeight = thumbH
    self.thumbFrame:SetHeight(thumbH)
    self.thumbFrame:ClearAllPoints()
    self.thumbFrame:SetPoint("TOP", self.trackFrame, "TOP", 0, -(1 + (viewH - thumbH - 2) * pos / r))
  end

  -- anlik: dogrudan git; degilse yumusakca kay.
  function area:ScrollTo(y, instant)
    local target = math.max(0, math.min(range(self), y or 0))
    if instant then
      Skin:CancelTween(self)
      self.scrollPos = target
      self:Sync()
      return
    end
    local from = self.scrollPos or 0
    Skin:Tween(self, 0.16, function(p)
      self.scrollPos = from + (target - from) * p
      self:Sync()
    end)
    self.scrollTarget = target
  end

  function area:SetContentHeight(h)
    self.content:SetHeight(math.max(h, 10))
    self:Sync()
  end
  function area:ScrollToTop()
    self:ScrollTo(0, true)
  end

  area:SetScript("OnSizeChanged", function(a, w)
    if w and w > TRACK_W + 8 then a.content:SetWidth(w - TRACK_W - 4) end
    a:Sync()
  end)

  area:SetScript("OnMouseWheel", function(a, delta)
    local base = Skin:IsTweening(a) and (a.scrollTarget or a.scrollPos) or (a.scrollPos or 0)
    a:ScrollTo(base - delta * WHEEL_STEP)
  end)

  -- tutamac surukleme
  local thumb = area.thumbFrame
  thumb:SetScript("OnEnter", function(t) t:SetAlpha(1) end)
  thumb:SetScript("OnLeave", function(t) if not t.dragging then t:SetAlpha(0.75) end end)
  thumb:SetScript("OnMouseDown", function(t)
    if not GetCursorPosition then return end
    t.dragging = true
    t.startY = select(2, GetCursorPosition()) / (UIParent:GetEffectiveScale() or 1)
    t.startScroll = area.scrollPos or 0
    Skin:CancelTween(area)
    t:SetAlpha(1)
  end)
  thumb:SetScript("OnMouseUp", function(t) t.dragging = false; t:SetAlpha(0.75) end)
  thumb:SetScript("OnUpdate", function(t)
    if not t.dragging then return end
    local y = select(2, GetCursorPosition()) / (UIParent:GetEffectiveScale() or 1)
    local r = range(area)
    area:ScrollTo(t.startScroll + (t.startY - y) / trackTravel(area) * r, true)
  end)
  -- bosluga tiklayinca bir sayfa atla
  area.trackFrame:SetScript("OnMouseDown", function(_, button)
    if not GetCursorPosition then return end
    local _, cy = GetCursorPosition()
    cy = cy / (UIParent:GetEffectiveScale() or 1)
    local top = area:GetTop()
    if not top then return end
    local clickedPos = (top - cy) / math.max(1, (area:GetHeight() or height))
    local thumbPos = (area.scrollPos or 0) / math.max(1, range(area) + (area:GetHeight() or height))
    area:ScrollTo((area.scrollPos or 0) + ((clickedPos > thumbPos) and 1 or -1) * (area:GetHeight() or height) * 0.9)
  end)
  return area
end

-- Akordeon:
--   acc = Skin:CreateAccordion(parent, genislik [, baslikYuksekligi])
--   acc.header (Button), acc.a (baslik), acc.b (sag metin), acc.body (icerik cercevesi),
--   acc:SetTick(renk), acc:SetBodyHeight(h), acc:SetExpanded(v [, anlik]), acc:GetCurrentHeight(),
--   acc.onToggle(acc) tiklayinca, acc.onAnimate(acc) her animasyon karesinde.
-- Simge: Media/UI/plus.tga / minus.tga (beyaz; renklenir). Icerik cerceveye kirpilir.
local ICON_PLUS = "Interface\\AddOns\\Arcanis\\Media\\UI\\plus.tga"
local ICON_MINUS = "Interface\\AddOns\\Arcanis\\Media\\UI\\minus.tga"
Skin.Icons = {}
for _, name in ipairs({ "plus", "minus", "close", "next", "prev", "current", "gear", "box", "check", "star", "resize", "dungeon", "guides", "menu", "compass", "shield", "hammer", "exclaim", "question", "sword", "arrow", "wing", "bubble", "house", "repeat", "chevdown", "disc", "ring", "logo", "pin", "flag", "skull", "larrow", "rarrow", "map", "power", "roundrect", "corner", "cornerring", "vgrad", "roundring", "bag", "web", "glow", "pill", "pillgloss", "gauge", "gaugehalf", "mail", "grid", "skip" }) do
  Skin.Icons[name] = "Interface\\AddOns\\Arcanis\\Media\\UI\\" .. name .. ".tga"
end

-- Minimap kenarindaki yuvarlak dugme (Arcanis dugmesi, cekmece): yumusak golge, panel diski, ince halka,
-- ortada simge. Halka vurgu renginde (soluk); fare ustundeyken tam parlak + parlama, basinca simge 1 px iner.
-- tint: "accent" = simge tema vurgu renginde; nil = resmin kendi renkleri (logo).
-- Dugmenin OnEnter / OnLeave'i kurulduktan SONRA cagrilir (SetScript kancalari siler).
function Skin:MinimapDisc(b, size, icon, iconSize, tint)
  b:SetSize(size, size)
  local function tex(layer, sub, path, s)
    local t = b:CreateTexture(nil, layer, nil, sub)
    t:SetTexture(path)
    t:SetSize(s, s)
    t:SetPoint("CENTER")
    return t
  end
  b.shadow = tex("BACKGROUND", -2, self.Icons.glow, size + 10)
  b.shadow:SetVertexColor(0, 0, 0, 0.55)
  b.hover = tex("BACKGROUND", -1, self.Icons.glow, size + 12)
  b.hover:SetBlendMode("ADD")
  b.hover:Hide()
  b.bg = tex("BACKGROUND", 0, self.Icons.disc, size)
  b.ring = tex("BORDER", 0, self.Icons.ring, size)
  b.icon = tex("ARTWORK", 0, icon, iconSize)
  function b:PaintDisc(over)
    local c = Skin.Colors
    self.bg:SetVertexColor(c.panel[1], c.panel[2], c.panel[3], 0.95)
    -- halka hep vurgu renginde (dugme bizim oldugu belli olsun), fare ustundeyken tam parlak
    local r = c.accent
    self.ring:SetVertexColor(r[1], r[2], r[3], over and 1 or 0.7)
    self.hover:SetVertexColor(c.accent[1], c.accent[2], c.accent[3], 0.45)
    self.hover:SetShown(over and true or false)
    if tint == "accent" then self.icon:SetVertexColor(c.accent[1], c.accent[2], c.accent[3], 1) end
  end
  b:PaintDisc(false)
  -- fare ustundeyken disariya dogru yavasca acilip sonen ince halka (dalga); ayri cerceve: dugmenin kendi
  -- OnUpdate'i suruklemede kullaniliyor
  b.wave = tex("BACKGROUND", -1, self.Icons.ring, size)
  b.wave:SetBlendMode("ADD")
  b.wave:Hide()
  local waver = CreateFrame("Frame", nil, b)
  waver:Hide()
  local WAVE_T, WAVE_GROW, WAVE_A = 1.6, 16, 0.35
  waver:SetScript("OnUpdate", function(w, dt)
    w.t = ((w.t or 0) + dt) % WAVE_T
    local p = w.t / WAVE_T
    local c = Skin.Colors.accent
    b.wave:SetSize(size + WAVE_GROW * p, size + WAVE_GROW * p)
    b.wave:SetVertexColor(c[1], c[2], c[3], WAVE_A * (1 - p) * (1 - p))
  end)
  b:HookScript("OnEnter", function(s) s:PaintDisc(true); waver.t = 0; s.wave:Show(); waver:Show() end)
  b:HookScript("OnLeave", function(s) s:PaintDisc(false); waver:Hide(); s.wave:Hide() end)
  b:HookScript("OnMouseDown", function(s) s.icon:SetPoint("CENTER", 1, -1) end)
  b:HookScript("OnMouseUp", function(s) s.icon:SetPoint("CENTER", 0, 0) end)
  return b
end

local BODY_GAP = 2

-- style: nil (kart) | "minimal" (zeminsiz baslik, renkli serit yok, ustte ince ayrac cizgisi: f.sep)
function Skin:CreateAccordion(parent, width, headerH, style)
  local C = self.Colors
  headerH = headerH or 30
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(width, headerH)
  f:SetClipsChildren(true)
  f.headerH, f.bodyHeight, f.expanded, f.h = headerH, 0, false, headerH

  local header = CreateFrame("Button", nil, f, "BackdropTemplate")
  header:SetPoint("TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", 0, 0)
  header:SetHeight(headerH)
  self:ApplyBackdrop(header, C.titleBg, C.border)
  f.header = header

  f.tick = header:CreateTexture(nil, "ARTWORK")
  f.tick:SetSize(3, headerH - 2)
  f.tick:SetPoint("LEFT", 1, 0)
  Skin:Fill(f.tick, C.accent)

  -- +/- isareti kenarli kare kutunun icinde
  f.box = CreateFrame("Frame", nil, header, "BackdropTemplate")
  f.box:SetSize(20, 20)
  f.box:SetPoint("RIGHT", -8, 0)
  self:ApplyBackdrop(f.box, C.bg, C.textDim)
  f.icon = f.box:CreateTexture(nil, "OVERLAY")
  f.icon:SetSize(12, 12)
  f.icon:SetPoint("CENTER")
  f.icon:SetTexture(ICON_PLUS)
  f.icon:SetVertexColor(unpack(C.textDim))
  -- +/- isareti iki piksel cizgi (resim olceklenince dusuk cozunurlukte bulaniyordu); "glass" oku resim kalir
  f.icon:SetAlpha(0)
  f.cross = {}
  for i, axis in ipairs({ "h", "w" }) do
    local t = f.box:CreateTexture(nil, "OVERLAY")
    t:SetTexture(WHITE); t._skinFixed = true
    t:SetVertexColor(unpack(C.textDim))
    if axis == "h" then t:SetPoint("LEFT", f.box, "LEFT", 5, 0); t:SetPoint("RIGHT", f.box, "RIGHT", -5, 0)
    else t:SetPoint("TOP", f.box, "TOP", 0, -5); t:SetPoint("BOTTOM", f.box, "BOTTOM", 0, 5) end
    Skin:Hairline(t, axis == "h" and "h" or "w", 2)
    f.cross[i] = t
  end
  local function setMark(c)
    f.icon:SetVertexColor(unpack(c))
    for _, t in ipairs(f.cross) do t:SetVertexColor(c[1], c[2], c[3], 1) end
  end

  f.a = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(f.a, self.Constants.FONT_SIZE, "OUTLINE")
  f.a:SetPoint("LEFT", 14, 0)
  f.a:SetJustifyH("LEFT")
  f.a:SetTextColor(unpack(C.text))
  f.b = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(f.b, self.Constants.FONT_SIZE_SMALL, "")
  f.b:SetPoint("RIGHT", f.box, "LEFT", -10, 0)
  f.b:SetTextColor(unpack(C.textDim))
  f.a:SetPoint("RIGHT", f.b, "LEFT", -8, 0)

  f.body = CreateFrame("Frame", nil, f)
  f.body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -BODY_GAP)
  f.body:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -BODY_GAP)
  f.body:SetHeight(1)
  f.body:Hide()

  f.minimal = style == "minimal" or style == "soft"
  f.soft = style == "soft"
  if f.minimal then
    f.tick:Hide()
    f.sep = f:CreateTexture(nil, "ARTWORK")
    Skin:Fill(f.sep, C.border, 0.9)
    Skin:Hairline(f.sep, "h")
    f.sep:SetPoint("TOPLEFT", 0, 0); f.sep:SetPoint("TOPRIGHT", 0, 0)
    f.a:SetPoint("LEFT", 4, 0)
    self:SetFont(f.a, self.Constants.FONT_SIZE, "")
    f.box:SetBackdrop(nil)
    f.box:SetSize(16, 16)
    f.icon:SetSize(11, 11)
    f.cross[1]:SetPoint("LEFT", f.box, "LEFT", 3, 0); f.cross[1]:SetPoint("RIGHT", f.box, "RIGHT", -3, 0)
    f.cross[2]:SetPoint("TOP", f.box, "TOP", 0, -3); f.cross[2]:SetPoint("BOTTOM", f.box, "BOTTOM", 0, 3)
  end
  -- "soft": her bolum ayri bir kart gibi; baslik govdeden bir ton acik, ince kenar, goz yormayan
  if f.soft then
    f.sep:Hide()
    f.bodyBg = f:CreateTexture(nil, "BACKGROUND")
    f.bodyBg:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    f.bodyBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.bodyBg:SetColorTexture(1, 1, 1, 0.025)
    f.edge = {}
    for _, side in ipairs({ "LEFT", "RIGHT", "BOTTOM" }) do
      local t = f:CreateTexture(nil, "BORDER")
      Skin:Fill(t, C.border, 0.8)
      if side == "BOTTOM" then
        Skin:Hairline(t, "h"); t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0); t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
      else
        Skin:Hairline(t, "w"); t:SetPoint("TOP" .. side, header, "BOTTOM" .. side, 0, 0); t:SetPoint("BOTTOM" .. side, f, "BOTTOM" .. side, 0, 0)
      end
      f.edge[#f.edge + 1] = t
    end
    f.a:SetPoint("LEFT", 9, 0)
  end
  -- "glass": hub karti gibi tek parca yuvarlak cam kart (baslik + govde); kenar cizgisi yok, solda ince vurgu
  -- cubugu (SetTick), +/- yerine donen ok; fare ustunde kart yumusakca aydinlanir.
  -- "row": adim bandi (rehber penceresi). Basligin tamami yuvarlak koseli renkli bant (SetTick(renk); renksiz satir
  -- seffaf, fare ustunde hafif aydinlanir), solda tur ikonu (SetIcon), sagda f.b (mesafe); +/- kutusu yok.
  -- Govdede soldan inen ince agac cizgisi; hedef satirlari onun sagina girintili yazilir.
  f.row = style == "row"
  if f.row then
    header:SetBackdrop(nil)
    f.box:Hide()
    f.tick:Hide()
    f.lead = header:CreateTexture(nil, "OVERLAY")
    f.lead:SetSize(14, 14)
    f.lead:SetPoint("LEFT", header, "LEFT", 8, 0)
    f.lead:SetTexture(self.Icons.current)
    self:SetFont(f.a, 12, "")
    f.a:SetPoint("LEFT", 28, 0)
    f.b:ClearAllPoints()
    f.b:SetPoint("RIGHT", header, "RIGHT", -8, 0)
    f.b:SetJustifyH("RIGHT")
    f.a:SetPoint("RIGHT", f.b, "LEFT", -8, 0)
    f.vline = f.body:CreateTexture(nil, "ARTWORK")
    f.vline:SetTexture(WHITE); f.vline._skinFixed = true
    Skin:Hairline(f.vline, "w")
    f.vline:SetPoint("TOPLEFT", f.body, "TOPLEFT", 14, 0)
    f.vline:SetPoint("BOTTOMLEFT", f.body, "BOTTOMLEFT", 14, 6)
    f.vline:SetVertexColor(1, 1, 1, 0.18)
    self:ApplyRounded(header, { 1, 1, 1, 0 }, 5)
    function f:SetIcon(name, color)
      self.lead:SetTexture(Skin.Icons[name] or name)
      local c = color or C.textDim
      self.lead:SetVertexColor(c[1], c[2], c[3], 1)
    end
  end
  f.glass = style == "glass"
  if f.glass then
    header:SetBackdrop(nil)
    f.box:SetBackdrop(nil)
    f.box:SetSize(16, 16)
    f.icon:SetTexture(self.Icons.chevdown)
    f.icon:SetAlpha(1)
    for _, t in ipairs(f.cross) do t:Hide() end
    f.icon:SetSize(10, 10)
    f.icon:SetRotation(math.pi / 2)
    f.tick:ClearAllPoints()
    f.tick:SetSize(3, math.max(6, headerH - 12))
    f.tick:SetPoint("LEFT", header, "LEFT", 5, 0)
    f.tick:Hide()   -- yalniz SetTick ile (odaktaki is, yan isler)
    self:SetFont(f.a, self.Constants.FONT_SIZE, "")
    f.a:SetPoint("LEFT", 14, 0)
    f.cardA = 0.045
    self:ApplyRounded(f, { 1, 1, 1, f.cardA }, 6)
    f.fadeKey, f.turnKey = {}, {}
  end
  local function paint(hover)
    if f.row then
      local c = f.band
      if c then
        Skin:ApplyRounded(header, { c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, hover and 0.95 or 0.85 }, 5)
      else
        Skin:ApplyRounded(header, { 1, 1, 1, hover and 0.06 or 0 }, 5)
      end
      return
    end
    if f.glass then
      local to = hover and 0.085 or (f.expanded and 0.06 or 0.045)
      local from = f.cardA or to
      f.icon:SetVertexColor(unpack((hover or f.expanded) and C.text or C.textDim))
      if from == to then return end
      Skin:Tween(f.fadeKey, 0.15, function(p)
        f.cardA = from + (to - from) * p
        Skin:ApplyRounded(f, { 1, 1, 1, f.cardA }, 6)
      end)
      return
    end
    if f.soft then
      header:SetBackdropColor(1, 1, 1, hover and 0.09 or 0.06)
      header:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.8)
      setMark(hover and C.text or C.textDim)
      return
    end
    if f.minimal then
      header:SetBackdropColor(1, 1, 1, hover and 0.04 or 0)
      header:SetBackdropBorderColor(0, 0, 0, 0)
      setMark(hover and C.text or C.textDim)
      return
    end
    -- baslik acikken de koyu kalir; yalnizca kutu ve isaret vurgu rengine doner
    header:SetBackdropColor(unpack(hover and C.buttonHover or C.titleBg))
    header:SetBackdropBorderColor(unpack(hover and C.borderLit or C.border))
    local mark = (f.expanded or hover) and C.accentHover or C.textDim
    f.box:SetBackdropBorderColor(unpack(mark))
    setMark(mark)
  end

  function f:SetTick(color)
    if self.row then self.band = color; paint(false) return end
    if self.glass then
      if color then Skin:Fill(self.tick, color); self.tick:Show() else self.tick:Hide() end
      return
    end
    if not self.minimal then Skin:Fill(self.tick, color) end
  end
  function f:GetCurrentHeight() return self.h end
  local function target() return f.headerH + (f.expanded and (f.bodyHeight + BODY_GAP) or 0) end
  local function setH(h)
    f.h = h
    f:SetHeight(h)
    if f.onAnimate then f.onAnimate(f) end
  end

  function f:SetBodyHeight(h)
    self.bodyHeight = math.max(0, h)
    self.body:SetHeight(math.max(1, self.bodyHeight))
    if not Skin:IsTweening(self) then setH(target()) end
  end

  function f:SetExpanded(value, instant)
    self.expanded = value and true or false
    if self.glass then
      local r0, r1 = self.turn or math.pi / 2, self.expanded and 0 or math.pi / 2
      self.turn = r1
      if instant or r0 == r1 then
        Skin:CancelTween(self.turnKey); self.icon:SetRotation(r1)
      else
        Skin:Tween(self.turnKey, 0.2, function(p) self.icon:SetRotation(r0 + (r1 - r0) * p) end)
      end
    else
      self.icon:SetTexture(self.expanded and ICON_MINUS or ICON_PLUS)
      self.cross[2]:SetShown(not self.expanded)
    end
    paint(false)
    if self.expanded then self.body:Show() end
    local to, from = target(), self.h
    if instant or from == to then
      Skin:CancelTween(self)
      setH(to)
      if not self.expanded then self.body:Hide() end
      return
    end
    Skin:Tween(self, 0.2, function(p) setH(from + (to - from) * p) end, function()
      setH(target())
      if not f.expanded then f.body:Hide() end
    end)
  end

  header:SetScript("OnEnter", function() paint(true) end)
  header:SetScript("OnLeave", function() paint(false) end)
  header:SetScript("OnClick", function()
    f:SetExpanded(not f.expanded)
    if f.onToggle then f.onToggle(f) end
  end)
  paint(false)
  return f
end

-- Resimli baslik: banner:SetArt(yol), banner.title, banner.sub. Resim 4:1 (1024x256 PNG) beklenir; yatayda doldurur.
function Skin:CreateBanner(parent, width, height)
  local C = self.Colors
  local b = CreateFrame("Frame", nil, parent)
  b:SetSize(width, height)
  b.art = b:CreateTexture(nil, "BACKGROUND")
  b.art:SetAllPoints()
  -- 4:1 resmi alanin oranina gore ORTADAN kirp, asla esnetme: alan resimden genisse ustten/alttan,
  -- darsa soldan/sagdan esit pay atilir.
  local ART_RATIO = 4
  local function crop(w, h)
    w, h = w or width, h or height
    local ratio = w / h
    if ratio >= ART_RATIO then
      local keep = ART_RATIO / ratio               -- yuksekligin kullanilan payi
      b.art:SetTexCoord(0, 1, 0.5 - keep / 2, 0.5 + keep / 2)
    else
      local keep = ratio / ART_RATIO               -- genisligin kullanilan payi
      b.art:SetTexCoord(0.5 - keep / 2, 0.5 + keep / 2, 0, 1)
    end
  end
  crop(width, height)
  b:SetScript("OnSizeChanged", function(_, w, h)
    if type(w) == "number" and type(h) == "number" and w > 0 and h > 0 then crop(w, h) end
  end)
  -- Alt karartma: keskin bant yok; vgrad (ustte opak -> altta seffaf) ters cevrilir, boylece alt kenarda koyu,
  -- yukari dogru yumusakca acilir. Dokuyla yapilir (SetGradient API surume gore degisir).
  b.shade = b:CreateTexture(nil, "ARTWORK")
  b.shade:SetTexture(self.Icons.vgrad)
  b.shade:SetTexCoord(0, 1, 1, 0)
  b.shade:SetVertexColor(0, 0, 0, 0.92)
  b.shade:SetPoint("BOTTOMLEFT")
  b.shade:SetPoint("BOTTOMRIGHT")
  b.shade:SetHeight(height * 0.85)
  b.line = b:CreateTexture(nil, "OVERLAY")
  Skin:Fill(b.line, C.border)
  Skin:Hairline(b.line, "h")
  b.line:SetPoint("BOTTOMLEFT")
  b.line:SetPoint("BOTTOMRIGHT")
  b.title = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(b.title, 16, "OUTLINE")
  b.title:SetPoint("BOTTOMLEFT", 12, 24)
  b.title:SetTextColor(unpack(C.text))
  b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(b.sub, self.Constants.FONT_SIZE_SMALL, "OUTLINE")
  b.sub:SetPoint("BOTTOMLEFT", 12, 8)
  b.sub:SetTextColor(unpack(C.textDim))
  -- fallback: dosya yoksa (SetTexture false doner; ornek: resmi henuz cizilmemis yeni zindan) kullanilacak resim
  function b:SetArt(path, fallback)
    if path then
      if self.art:SetTexture(path) == false and fallback then self.art:SetTexture(fallback) end
      self.art:Show()
    else self.art:Hide() end
  end
  -- Yazilar ustte, baslik boyunda (ad 20, aciklama 12; zemin bandi yok, OUTLINE okunurlugu saglar).
  -- Alt kisim (karartmanin koyu bolgesi) sayfanin kontrollerine kalir.
  function b:SetTextAtTop()
    Skin:SetFont(self.title, 20, "OUTLINE")
    Skin:SetFont(self.sub, 12, "OUTLINE")
    self.title:ClearAllPoints()
    self.title:SetPoint("TOPLEFT", 12, -10)
    self.title:SetPoint("RIGHT", self, "RIGHT", -12, 0)
    self.title:SetJustifyH("LEFT")
    self.title:SetWordWrap(false)
    self.sub:ClearAllPoints()
    self.sub:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -4)
    self.sub:SetPoint("RIGHT", self, "RIGHT", -12, 0)
    self.sub:SetJustifyH("LEFT")
    self.sub:SetWordWrap(false)
  end
  return b
end



-- Adim tipine gore vurgu renkleri (adim penceresi, rehber listesi ve ayarlar ortak kullanir).
Skin.TypeColors = {
  accept = { 0.86, 0.62, 0.20, 1 }, turnin = { 0.30, 0.85, 0.50, 1 }, complete = { 0.35, 0.65, 0.95, 1 },
  kill = { 0.90, 0.32, 0.32, 1 }, collect = { 0.72, 0.52, 0.92, 1 }, use = { 0.72, 0.52, 0.92, 1 },
  talk = { 0.30, 0.78, 0.78, 1 }, fly = { 0.45, 0.80, 0.95, 1 }, hearth = { 0.45, 0.80, 0.95, 1 },
  ["goto"] = { 0.55, 0.55, 0.55, 1 }, level = { 0.85, 0.85, 0.40, 1 }, note = { 0.40, 0.40, 0.40, 1 },
}
-- Gorev durumu renkleri: bitmemis = kirmizi, bitmis = gri, aktif gorev = kehribar, teslime hazir = yesil.
Skin.StatusColors = {
  pending = { 0.95, 0.42, 0.36, 1 }, done = { 0.50, 0.50, 0.50, 1 },
  current = { 0.96, 0.75, 0.34, 1 }, ready = { 0.40, 0.85, 0.50, 1 },
}

-- Ikon dugmesi (TGA, beyaz ikon renklenir): btn:SetIcon(ad), btn:SetEnabled(v), btn:SetActive(v) (kehribar).
-- Uzerine gelince aydinlanir, bastikca 1px kayar, devre disiyken solar.
function Skin:CreateIconButton(parent, iconName, size, width, height)
  -- Duz ikon dugmesi (TEK STANDART): zemin/kenar yok, yalnizca ikon. Uzerine gelince hafif yuvarlak
  -- zemin + vurgu rengi ikon; aktifken ikon vurgu renginde; devre disiyken soluk.
  local C = self.Colors
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(width or size or 24, height or size or 24)
  btn.enabled, btn.active = true, false
  btn.hl = btn:CreateTexture(nil, "BACKGROUND")
  btn.hl:SetAllPoints()
  btn.hl:SetTexture(self.Icons.roundrect)
  btn.hl:SetVertexColor(1, 1, 1, 0.08)
  btn.hl:Hide()
  btn.icon = btn:CreateTexture(nil, "OVERLAY")
  local iconSize = math.max(10, (size or 24) - 8)
  btn.icon:SetSize(iconSize, iconSize)
  btn.icon:SetPoint("CENTER")
  local function paint(hover)
    if not btn.enabled then
      btn.hl:Hide()
      btn.icon:SetVertexColor(unpack(C.textOff))
    elseif hover then
      btn.hl:Show()
      btn.icon:SetVertexColor(unpack(C.accentHover))
    elseif btn.active then
      btn.hl:Hide()
      btn.icon:SetVertexColor(unpack(C.accent))
    else
      btn.hl:Hide()
      btn.icon:SetVertexColor(unpack(C.text))
    end
  end
  -- Durum yalniz gercekten degisince yeniden boyanir; boyarken fare hala ustteyse uzerine gelme
  -- gorunumu korunur (sik Update/Refresh cagrilari hover'i silip titretmesin).
  local function over() return (btn.IsMouseOver and btn:IsMouseOver()) and true or false end
  function btn:SetIcon(name) self.icon:SetTexture(Skin.Icons[name] or name) end
  -- Yerlesik Button:SetEnabled saklanir ve cagrilir: yoksa "pasif" gorunen dugme tiklaninca yine OnClick calisir.
  local nativeSetEnabled = btn.SetEnabled
  function btn:SetEnabled(v)
    v = v and true or false
    if v == self.enabled then return end
    self.enabled = v
    if nativeSetEnabled then pcall(nativeSetEnabled, self, v) end
    paint(over())
  end
  function btn:Enable() self:SetEnabled(true) end
  function btn:Disable() self:SetEnabled(false) end
  function btn:IsEnabled() return self.enabled end
  function btn:SetActive(v)
    v = v and true or false
    if v == self.active then return end
    self.active = v; paint(over())
  end
  -- Ipucu: ilk satir baslik, digerleri aciklama. OnEnter'i ezmeden (hover boyamasi korunur) gosterilir.
  function btn:SetTooltip(title, ...) self.tipLines = title and { title, ... } or nil end
  btn:SetScript("OnEnter", function()
    if btn.enabled then paint(true) end
    local lines = btn.tipLines
    if lines and GameTooltip then
      GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
      GameTooltip:SetText(lines[1])
      for i = 2, #lines do GameTooltip:AddLine(lines[i], 1, 1, 1, true) end
      GameTooltip:Show()
    end
  end)
  btn:SetScript("OnLeave", function()
    paint(false)
    if btn.tipLines and GameTooltip then GameTooltip:Hide() end
  end)
  btn:SetScript("OnMouseDown", function() if btn.enabled then btn.icon:SetPoint("CENTER", 1, -1) end end)
  btn:SetScript("OnMouseUp", function() btn.icon:SetPoint("CENTER", 0, 0) end)
  btn:SetIcon(iconName)
  paint(false)
  return btn
end


-- Renk secici (tek ornek): Skin:OpenColorPicker(renk, degisti(c)); degisti her oynatmada {r,g,b} ile cagrilir,
-- Cancel ilk rengi geri yollar.
function Skin.RGBToHSV(r, g, b)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local d = max - min
  local h, s = 0, max > 0 and d / max or 0
  if d > 0 then
    if r == max then h = (g - b) / d elseif g == max then h = 2 + (b - r) / d else h = 4 + (r - g) / d end
    h = (h / 6) % 1
  end
  return h, s, max
end

function Skin.HSVToRGB(h, s, v)
  if s <= 0 then return v, v, v end
  local i = math.floor(h * 6) % 6
  local f = h * 6 - math.floor(h * 6)
  local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
  if i == 0 then return v, t, p elseif i == 1 then return q, v, p elseif i == 2 then return p, v, t
  elseif i == 3 then return p, q, v elseif i == 4 then return t, p, v end
  return v, p, q
end

local function gradient(t, dir, a, b)
  if t.SetGradient and CreateColor then
    t:SetColorTexture(1, 1, 1, 1)
    t:SetGradient(dir, CreateColor(a[1], a[2], a[3], a[4]), CreateColor(b[1], b[2], b[3], b[4]))
  end
end

function Skin:ColorPickerFrame()
  if self.colorPicker then return self.colorPicker end
  local C = self.Colors
  local SV, BAR, GAP = 140, 20, 10
  local f = CreateFrame("Frame", "ArcanisColorPicker", UIParent, "BackdropTemplate")
  f:SetSize(330, 250); f:SetPoint("CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG"); f:EnableMouse(true); f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
  self:ApplyBackdrop(f, C.bg, C.accent)
  self:RegisterRoot(f)
  f:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisColorPicker") end   -- Esc kapatir (Cancel gibi)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(f.title, 12, "OUTLINE")
  f.title:SetPoint("TOPLEFT", 12, -10)
  f.title:SetTextColor(unpack(C.accentHover))
  f.title:SetText(ns.L["Pick a colour"])

  -- doygunluk (yatay) x parlaklik (dikey) karesi: ton zemini + beyazdan saydama + siyahtan saydama
  local sv = CreateFrame("Button", nil, f)
  sv:SetSize(SV, SV); sv:SetPoint("TOPLEFT", 12, -34)
  sv.hue = sv:CreateTexture(nil, "BACKGROUND", nil, 1); sv.hue:SetAllPoints()
  sv.white = sv:CreateTexture(nil, "BACKGROUND", nil, 2); sv.white:SetAllPoints()
  gradient(sv.white, "HORIZONTAL", { 1, 1, 1, 1 }, { 1, 1, 1, 0 })
  sv.black = sv:CreateTexture(nil, "BACKGROUND", nil, 3); sv.black:SetAllPoints()
  gradient(sv.black, "VERTICAL", { 0, 0, 0, 1 }, { 0, 0, 0, 0 })
  sv.thumb = CreateFrame("Frame", nil, sv, "BackdropTemplate")
  sv.thumb:SetSize(8, 8)
  self:ApplyBackdrop(sv.thumb, { 1, 1, 1, 1 }, { 0, 0, 0, 1 })

  -- ton cubugu: alttan uste kirmizi > sari > yesil > camgobegi > mavi > mor > kirmizi
  local hue = CreateFrame("Button", nil, f)
  hue:SetSize(BAR, SV); hue:SetPoint("TOPLEFT", sv, "TOPRIGHT", GAP, 0)
  local stops = { { 1, 0, 0 }, { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 0, 0, 1 }, { 1, 0, 1 }, { 1, 0, 0 } }
  for k = 1, 6 do
    local t = hue:CreateTexture(nil, "ARTWORK")
    t:SetSize(BAR, SV / 6)
    t:SetPoint("BOTTOMLEFT", hue, "BOTTOMLEFT", 0, (k - 1) * SV / 6)
    local a, b = stops[k], stops[k + 1]
    gradient(t, "VERTICAL", { a[1], a[2], a[3], 1 }, { b[1], b[2], b[3], 1 })
  end
  hue.thumb = hue:CreateTexture(nil, "OVERLAY")
  hue.thumb:SetSize(BAR + 4, 4); hue.thumb:SetColorTexture(1, 1, 1, 1)

  -- onizleme: ustte yeni, altta eski renk
  local px = 12 + SV + GAP + BAR + 16
  f.new = f:CreateTexture(nil, "ARTWORK"); f.new:SetPoint("TOPLEFT", px, -34); f.new:SetSize(330 - px - 12, 64)
  f.old = f:CreateTexture(nil, "ARTWORK"); f.old:SetPoint("TOPLEFT", f.new, "BOTTOMLEFT", 0, -6); f.old:SetSize(330 - px - 12, 64)

  -- R G B ve hex: Enter ile uygulanir
  local function input(text, x, w, max)
    local l = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self:SetFont(l, 10, ""); l:SetTextColor(unpack(C.textDim)); l:SetText(text)
    l:SetPoint("TOPLEFT", sv, "BOTTOMLEFT", x, -14)
    local eb = self:CreateEditBox(f, w, 20)
    eb:SetPoint("LEFT", l, "RIGHT", 4, 0)
    eb:SetMaxLetters(max)
    eb:SetTextInsets(4, 4, 0, 0)
    return eb
  end
  f.r, f.g, f.b = input("R", 0, 34, 3), input("G", 50, 34, 3), input("B", 100, 34, 3)
  f.hex = input("#", 150, 70, 7)

  f.h, f.s, f.v = 0, 0, 1
  local busy = false
  local function paint(fields, send)
    if busy then return end
    busy = true
    local r, g, b = Skin.HSVToRGB(f.h, f.s, f.v)
    f.new:SetColorTexture(r, g, b, 1)
    sv.hue:SetColorTexture(Skin.HSVToRGB(f.h, 1, 1))
    sv.thumb:ClearAllPoints(); sv.thumb:SetPoint("CENTER", sv, "BOTTOMLEFT", f.s * SV, f.v * SV)
    hue.thumb:ClearAllPoints(); hue.thumb:SetPoint("CENTER", hue, "BOTTOMLEFT", BAR / 2, f.h * SV)
    if fields then
      f.r:SetText(math.floor(r * 255 + 0.5)); f.g:SetText(math.floor(g * 255 + 0.5)); f.b:SetText(math.floor(b * 255 + 0.5))
      f.hex:SetText(("%02X%02X%02X"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)))
    end
    if send and f.changed then f.changed({ r, g, b }) end
    busy = false
  end
  function f:SetColor(c, send)
    self.h, self.s, self.v = Skin.RGBToHSV(c[1], c[2], c[3])
    paint(true, send ~= false)
  end
  function f:GetColor() return { Skin.HSVToRGB(self.h, self.s, self.v) } end

  -- surukleme: fare basiliyken her karede imlece gore
  local function cursor(frame)
    local mx, my = GetCursorPosition()
    local s = frame:GetEffectiveScale() or 1
    return (mx / s) - (frame:GetLeft() or 0), (my / s) - (frame:GetBottom() or 0)
  end
  local function clamp(x) return math.max(0, math.min(1, x)) end
  for _, area in ipairs({ sv, hue }) do
    area:SetScript("OnMouseDown", function() area.down = true end)
    area:SetScript("OnMouseUp", function() area.down = false end)
    area:SetScript("OnUpdate", function()
      if not area.down or not GetCursorPosition then return end
      local x, y = cursor(area)
      if area == sv then f.s, f.v = clamp(x / SV), clamp(y / SV) else f.h = clamp(y / SV) % 1 end
      paint(true, true)
    end)
  end
  local function fromFields()
    local function n(eb) return math.max(0, math.min(255, tonumber(eb:GetText()) or 0)) / 255 end
    f:SetColor({ n(f.r), n(f.g), n(f.b) })
    for _, eb in ipairs({ f.r, f.g, f.b }) do eb:ClearFocus() end
  end
  for _, eb in ipairs({ f.r, f.g, f.b }) do eb:SetScript("OnEnterPressed", fromFields) end
  f.hex:SetScript("OnEnterPressed", function(eb)
    local t = (eb:GetText() or ""):gsub("#", "")
    local r, g, b = tonumber(t:sub(1, 2), 16), tonumber(t:sub(3, 4), 16), tonumber(t:sub(5, 6), 16)
    if #t == 6 and r and g and b then f:SetColor({ r / 255, g / 255, b / 255 }) end
    eb:ClearFocus()
  end)

  f.ok = self:CreateButton(f, ns.L["OK"], 80, 22, true)
  f.ok:SetPoint("BOTTOMRIGHT", -12, 12)
  f.ok:SetScript("OnClick", function() f.cancelled = false; f:Hide() end)
  f.cancel = self:CreateButton(f, ns.L["Cancel"], 80, 22)
  f.cancel:SetPoint("RIGHT", f.ok, "LEFT", -8, 0)
  f.cancel:SetScript("OnClick", function()
    if f.changed and f.start then f.changed(f.start) end
    f.cancelled = false; f:Hide()
  end)
  -- Cancel, Esc ya da baska renk acilmasi: OK'e basilmadiysa ilk renk geri yollanir
  f:SetScript("OnHide", function()
    if f.cancelled and f.changed and f.start then f.changed(f.start) end
    f.changed = nil
  end)
  self.colorPicker = f
  return f
end

function Skin:OpenColorPicker(color, changed)
  local f = self:ColorPickerFrame()
  if f:IsShown() then f:Hide() end
  local c = { color[1], color[2], color[3] }
  f.start, f.cancelled = c, true
  f.old:SetColorTexture(c[1], c[2], c[3], 1)
  f:SetColor(c, false)
  f.changed = changed
  f:Show()
  return f
end

-- Renk dugmesi: rengi gosteren kutu; tiklayinca secici acilir. get() -> {r,g,b}, set(c) her degisimde.
function Skin:CreateColorButton(parent, get, set, width, height)
  local C = self.Colors
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(width or 20, height or 20)   -- kare
  self:ApplyBackdrop(btn, C.bg, C.border)
  btn.swatch = btn:CreateTexture(nil, "ARTWORK")
  btn.swatch:SetPoint("TOPLEFT", 2, -2); btn.swatch:SetPoint("BOTTOMRIGHT", -2, 2)
  function btn:Refresh()
    local c = get()
    self.swatch:SetColorTexture(c[1], c[2], c[3], 1)
  end
  btn:SetScript("OnClick", function()
    Skin:OpenColorPicker(get(), function(c) set(c); btn:Refresh() end)
  end)
  btn:SetScript("OnEnter", function(b) b:SetBackdropBorderColor(unpack(C.accentHover)) end)
  btn:SetScript("OnLeave", function(b) b:SetBackdropBorderColor(unpack(C.border)) end)
  btn:SetScript("OnShow", function(b) b:Refresh() end)
  btn:Refresh()
  return btn
end

-- Acilir menu (tek ornek): Skin:ShowMenu(anchor, items [, genislik])
-- items = { { text = "...", onClick = fn, checked = bool|nil, enabled = bool|nil }, ... }
-- Disariya tiklayinca ya da secim yapilinca kapanir.
function Skin:HideMenu()
  local m = self.menu
  if m then m.frame:Hide(); m.catcher:Hide() end
end

function Skin:ShowMenu(anchor, items, width)
  local C = self.Colors
  local m = self.menu
  if not m then
    m = { rows = {} }
    m.catcher = CreateFrame("Button", nil, UIParent)
    m.catcher:SetAllPoints(UIParent)
    m.catcher:SetFrameStrata("FULLSCREEN")
    m.catcher:SetScript("OnClick", function() Skin:HideMenu() end)
    m.frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    m.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    self:ApplyBackdrop(m.frame, C.bg, C.accent)
    self:RegisterRoot(m.frame)
    self.menu = m
  end
  local rowH = 24
  width = width or 190
  for i, item in ipairs(items) do
    local row = m.rows[i]
    if not row then
      row = CreateFrame("Button", nil, m.frame)
      row:SetHeight(rowH)
      row.bg = row:CreateTexture(nil, "BACKGROUND")
      row.bg:SetAllPoints()
      Skin:Fill(row.bg, C.buttonHover)
      row.bg:Hide()
      row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      row.label:SetPoint("LEFT", 12, 0)
      row.label:SetPoint("RIGHT", -24, 0)
      row.label:SetJustifyH("LEFT")
      row.label:SetWordWrap(false)
      Skin:SetFont(row.label, 11, "")
      row.tick = row:CreateTexture(nil, "OVERLAY")
      row.tick:SetSize(14, 14)
      row.tick:SetPoint("RIGHT", -8, 0)
      row.tick:SetTexture(Skin.Icons.check)
      row.tick:SetVertexColor(unpack(C.accent))
      row:SetScript("OnEnter", function(r) r.bg:Show() end)
      row:SetScript("OnLeave", function(r) r.bg:Hide() end)
      row:SetScript("OnClick", function(r)
        Skin:HideMenu()
        if r.onClick then ns.SafeCall(r.onClick) end
      end)
      m.rows[i] = row
    end
    row.onClick = item.onClick
    row.label:SetText(item.text or "")
    row.label:SetTextColor(unpack(item.enabled == false and C.textOff or C.text))
    if item.checked then row.tick:Show() else row.tick:Hide() end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", m.frame, "TOPLEFT", 1, -1 - (i - 1) * rowH)
    row:SetPoint("TOPRIGHT", m.frame, "TOPRIGHT", -1, -1 - (i - 1) * rowH)
    row:Show()
  end
  for i = #items + 1, #m.rows do m.rows[i]:Hide() end
  -- menu, bagli oldugu pencerenin olcegini alir (olcekli pencerede genislik/konum kaymasin)
  local ae = anchor.GetEffectiveScale and anchor:GetEffectiveScale()
  local ue = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
  if type(ae) == "number" and type(ue) == "number" and ue > 0 and m.frame.SetScale then m.frame:SetScale(ae / ue) end
  local h = #items * rowH + 2
  m.frame:SetSize(width, h)
  m.frame:ClearAllPoints()
  -- asagida yer yoksa (pencere ekranin altinda) menu yukari acilir; her durumda ekrandan tasmaz
  -- (menu baglantinin olceginde: ikisi de ayni birimde karsilastirilir)
  local bottom = anchor.GetBottom and anchor:GetBottom()
  if type(bottom) == "number" and bottom < h + 4 then
    m.frame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
  else
    m.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  end
  if m.frame.SetClampedToScreen then m.frame:SetClampedToScreen(true) end
  m.catcher:Show()
  m.frame:Show()
end


-- Pencere kabugu (TEK STANDART): yalnizca ust koseleri hafif yuvarlak, ust bant koyudan govdeye
-- yumusak gecis, 1px kenar. Backdrop yerine dokularla cizilir.
--   local chrome = Skin:ApplyWindowChrome(frame, ustBantYuksekligi)
--   chrome:SetColors(govde, kenar)   -- saydamlik govde rengindeki alfadan gelir
function Skin:ApplyWindowChrome(f, headerH, radius)
  radius = radius or 7
  if f.SetBackdrop then pcall(f.SetBackdrop, f, nil) end
  local ch = f.chrome
  if not ch then
    ch = {}
    f.chrome = ch
    local function tx(layer, sub, path)
      local t = f:CreateTexture(nil, layer, nil, sub)
      t:SetTexture(path or WHITE)
      return t
    end
    local frac = radius / headerH
    ch.body = tx("BACKGROUND", -8)
    ch.body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -radius)
    ch.body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    ch.top = tx("BACKGROUND", -8)
    ch.top:SetPoint("TOPLEFT", f, "TOPLEFT", radius, 0)
    ch.top:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -radius, -radius)
    ch.cl = tx("BACKGROUND", -8, self.Icons.corner)
    ch.cl:SetSize(radius, radius)
    ch.cl:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    ch.cr = tx("BACKGROUND", -8, self.Icons.corner)
    ch.cr:SetSize(radius, radius)
    ch.cr:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    ch.cr:SetTexCoord(1, 0, 0, 1)
    -- ust bant: koyu -> govde (dikey gecis dokusu, iki parca: koseler arasi ve alt kisim)
    ch.gradTop = tx("BACKGROUND", -6, self.Icons.vgrad)
    ch.gradTop:SetPoint("TOPLEFT", f, "TOPLEFT", radius, 0)
    ch.gradTop:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -radius, -radius)
    ch.gradTop:SetTexCoord(0, 1, 0, frac)
    ch.grad = tx("BACKGROUND", -6, self.Icons.vgrad)
    ch.grad:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -radius)
    ch.grad:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -headerH)
    ch.grad:SetTexCoord(0, 1, frac, 1)
    -- kenar
    ch.bTop = tx("BORDER", 0); Skin:Hairline(ch.bTop, "h")
    ch.bTop:SetPoint("TOPLEFT", f, "TOPLEFT", radius, 0); ch.bTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -radius, 0)
    ch.bLeft = tx("BORDER", 0); Skin:Hairline(ch.bLeft, "w")
    ch.bLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -radius); ch.bLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    ch.bRight = tx("BORDER", 0); Skin:Hairline(ch.bRight, "w")
    ch.bRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -radius); ch.bRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    ch.bBottom = tx("BORDER", 0); Skin:Hairline(ch.bBottom, "h")
    ch.bBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0); ch.bBottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    ch.rl = tx("BORDER", 0, self.Icons.cornerring); ch.rl:SetSize(radius, radius); ch.rl:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    ch.rr = tx("BORDER", 0, self.Icons.cornerring); ch.rr:SetSize(radius, radius); ch.rr:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    ch.rr:SetTexCoord(1, 0, 0, 1)
    ch.sep = tx("BORDER", 0); Skin:Hairline(ch.sep, "h")
    ch.sep:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -headerH); ch.sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -headerH)

    -- pencere kendi basligini cizer (eski tema baslik plakasi kaldirildi); doner: plaka gosterildi mi
    function ch:SetTitle() return false end

    function ch:SetColors(body, border)
      local r, g, b, a = body[1], body[2], body[3], body[4] or 1
      for _, t in ipairs({ self.body, self.top }) do t:SetVertexColor(r, g, b, a) end
      -- koseler ust bandin en koyu tonunu alir
      local k = 0.45
      for _, t in ipairs({ self.cl, self.cr }) do t:SetVertexColor(r * k, g * k, b * k, a) end
      for _, t in ipairs({ self.gradTop, self.grad }) do t:SetVertexColor(0, 0, 0, 0.55 * a) end
      local br, bg, bb, ba = border[1], border[2], border[3], border[4] or 1
      for _, t in ipairs({ self.bTop, self.bLeft, self.bRight, self.bBottom, self.rl, self.rr }) do t:SetVertexColor(br, bg, bb, ba) end
      self.sep:SetVertexColor(br, bg, bb, 0.35 * ba)
    end
  end
  ch:SetColors(self.Colors.panel, self.Colors.frameBorder)
  return ch
end

-- Kapat dugmesi (TEK STANDART): normalde yalnizca kirmizi ikon; uzerine gelince yuvarlak kirmizi zemin,
-- beyaz ikon ve "Close" ipucu.
local CLOSE_RED = { 0.92, 0.27, 0.10, 1 }
function Skin:CreateCloseButton(parent, size)
  size = size or 14
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size + 14, size + 8)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:SetTexture(self.Icons.roundrect)
  b.bg:SetVertexColor(unpack(CLOSE_RED))
  b.bg:SetAlpha(0)
  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetSize(size, size)
  b.icon:SetPoint("CENTER")
  b.icon:SetTexture(self.Icons.power)
  b.icon:SetVertexColor(unpack(CLOSE_RED))
  b:SetScript("OnEnter", function(x)
    Skin:Tween(x, 0.12, function(p) x.bg:SetAlpha(p) end)
    x.icon:SetVertexColor(1, 1, 1, 1)
    if GameTooltip then
      GameTooltip:SetOwner(x, "ANCHOR_BOTTOMRIGHT")
      GameTooltip:SetText(ns.L["Close"])
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function(x)
    Skin:Tween(x, 0.12, function(p) x.bg:SetAlpha(1 - p) end)
    x.icon:SetVertexColor(unpack(CLOSE_RED))
    if GameTooltip then GameTooltip:Hide() end
  end)
  b:SetScript("OnMouseDown", function(x) x.icon:SetPoint("CENTER", 0, -1) end)
  b:SetScript("OnMouseUp", function(x) x.icon:SetPoint("CENTER", 0, 0) end)
  return b
end

-- Ana menu ogesi (TEK STANDART): kart + solda koyu ikon kutusu + bolum adi. Secili: vurgu zemin,
-- vurgu kenar, solda vurgu cubugu, ikon kutusu ve ikon vurgu renginde.
--   local it = Skin:CreateMenuItem(parent, genislik, yukseklik, ikonAdi); it.label, it:SetSelected(v)
function Skin:CreateMenuItem(parent, width, height, iconName)
  local C = self.Colors
  height = height or 44
  local it = CreateFrame("Button", nil, parent, "BackdropTemplate")
  it:SetSize(width or 170, height)
  self:ApplyBackdrop(it, C.card, C.border)
  it.bar = it:CreateTexture(nil, "OVERLAY")
  Skin:Fill(it.bar, C.accent)
  it.bar:SetPoint("TOPLEFT", -1, 1); it.bar:SetPoint("BOTTOMLEFT", -1, -1)
  it.bar:SetWidth(3)
  it.bar:Hide()
  local box = height - 12
  it.box = CreateFrame("Frame", nil, it, "BackdropTemplate")
  it.box:SetSize(box, box)
  it.box:SetPoint("LEFT", 6, 0)
  self:ApplyBackdrop(it.box, { 0.02, 0.02, 0.02, 0.95 }, C.border)
  it.icon = it.box:CreateTexture(nil, "OVERLAY")
  it.icon:SetSize(box - 12, box - 12)
  it.icon:SetPoint("CENTER")
  it.icon:SetTexture(self.Icons[iconName] or iconName)
  it.icon:SetVertexColor(unpack(C.text))
  it.label = it:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self:SetFont(it.label, 12, "OUTLINE")
  it.label:SetPoint("LEFT", it.box, "RIGHT", 10, 0)
  it.label:SetPoint("RIGHT", it, "RIGHT", -8, 0)
  it.label:SetJustifyH("LEFT")
  it.label:SetWordWrap(false)
  it.label:SetTextColor(unpack(C.text))
  local function paint(hover)
    if it.selected then
      it:SetBackdropColor(unpack(C.accentSoft)); it:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.55)
      it.box:SetBackdropBorderColor(unpack(C.accent)); it.icon:SetVertexColor(unpack(C.accentHover)); it.bar:Show()
    else
      it:SetBackdropColor(unpack(C.card)); it:SetBackdropBorderColor(unpack(hover and C.borderLit or C.border))
      it.box:SetBackdropBorderColor(unpack(hover and C.borderLit or C.border))
      it.icon:SetVertexColor(unpack(hover and C.accentHover or C.text)); it.bar:Hide()
    end
  end
  function it:SetSelected(v) self.selected = v and true or false; paint(false) end
  it:SetScript("OnEnter", function() paint(true) end)
  it:SetScript("OnLeave", function() paint(false) end)
  paint(false)
  return it
end

-- Sekme cubugu (TEK STANDART): yazi sekmeleri, secili olanin altinda vurgu cizgisi.
--   local tb = Skin:CreateTabBar(parent, { {id=, text=}, ... }, onSelect); tb:Select(id [, sessiz]); tb:SetTexts(fn)
function Skin:CreateTabBar(parent, items, onSelect)
  local C = self.Colors
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetHeight(30)
  bar.line = bar:CreateTexture(nil, "ARTWORK")
  Skin:Fill(bar.line, C.border)
  Skin:Hairline(bar.line, "h")
  bar.line:SetPoint("BOTTOMLEFT"); bar.line:SetPoint("BOTTOMRIGHT")
  bar.tabs, bar.items = {}, items
  local function layout()
    local x = 0
    for _, it in ipairs(bar.items) do
      local tab = bar.tabs[it.id]
      local w = tab.text:GetStringWidth()
      tab:SetWidth(math.max(60, (type(w) == "number" and w or 50) + 24))
      tab:ClearAllPoints()
      tab:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 0)
      x = x + (tab:GetWidth() or 80) + 2
    end
  end
  for _, it in ipairs(items) do
    local tab = CreateFrame("Button", nil, bar)
    tab:SetHeight(30)
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self:SetFont(tab.text, 12, "OUTLINE")
    tab.text:SetPoint("CENTER", 0, 1)
    tab.text:SetText(it.text or it.id)
    tab.mark = tab:CreateTexture(nil, "OVERLAY")
    Skin:Fill(tab.mark, C.accent)
    tab.mark:SetHeight(2)
    tab.mark:SetPoint("BOTTOMLEFT"); tab.mark:SetPoint("BOTTOMRIGHT")
    tab.mark:Hide()
    tab:SetScript("OnEnter", function(t) if not t.selected then t.text:SetTextColor(unpack(C.text)) end end)
    tab:SetScript("OnLeave", function(t) if not t.selected then t.text:SetTextColor(unpack(C.textDim)) end end)
    tab:SetScript("OnClick", function() bar:Select(it.id) end)
    tab.text:SetTextColor(unpack(C.textDim))
    bar.tabs[it.id] = tab
  end
  function bar:Select(id, silent)
    self.selected = id
    for tid, tab in pairs(self.tabs) do
      tab.selected = tid == id
      if tab.selected then tab.mark:Show(); tab.text:SetTextColor(unpack(C.accentHover))
      else tab.mark:Hide(); tab.text:SetTextColor(unpack(C.textDim)) end
    end
    if onSelect and not silent then onSelect(id) end
  end
  function bar:SetTexts(fn)
    for _, it in ipairs(self.items) do self.tabs[it.id].text:SetText(fn(it.id)) end
    layout()
  end
  layout()
  return bar
end


-- Kopyalama penceresi (tek ornek): Skin:ShowCopyBox(baslik, metin [, ipucu])
-- WoW tarayici acamaz; link secili bir kutuda gosterilir, oyuncu Ctrl+C ile kopyalar. Ctrl+C'den sonra
-- "Kopyalandi" yazar ve kendiliginden kapanir. Kutu salt okunur (yazilan geri alinir). Esc kapatir.
function Skin:ShowCopyBox(titleText, value, hintText)
  local C, L = self.Colors, ns.L
  local f = self.copyBox
  if not f then
    f = CreateFrame("Frame", "ArcanisCopyBox", UIParent, "BackdropTemplate")
    f:SetSize(440, 104)
    f:SetPoint("CENTER", 0, 140)
    -- ana pencere DIALOG katmaninda; kutu her zaman onun ustunde acilmali (ShowMenu/Toast ile ayni katman)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    self:ApplyWindowChrome(f, 32)
    self:RegisterRoot(f)
    f.title = f:CreateFontString(nil, "OVERLAY")
    self:SetFont(f.title, 13, "")
    f.title:SetPoint("TOPLEFT", 14, -10)
    f.title:SetPoint("RIGHT", f, "RIGHT", -44, 0)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.title:SetTextColor(unpack(C.accentHover))
    f.close = self:CreateCloseButton(f, 14)
    f.close:SetPoint("TOPRIGHT", -10, -9)
    f.close:SetScript("OnClick", function() f:Hide() end)
    f.box = self:CreateEditBox(f, 412, 24)
    f.box:SetPoint("TOPLEFT", 14, -40)
    f.box:SetPoint("RIGHT", f, "RIGHT", -14, 0)
    f.hint = f:CreateFontString(nil, "OVERLAY")
    self:SetFont(f.hint, 10, "")
    f.hint:SetPoint("BOTTOMLEFT", 14, 12)
    f.hint:SetPoint("RIGHT", f, "RIGHT", -14, 0)
    f.hint:SetJustifyH("LEFT")
    f.hint:SetTextColor(unpack(C.textDim))
    local function reselect(b) b:SetFocus(); b:HighlightText() end
    f.box:SetScript("OnEscapePressed", function() f:Hide() end)
    f.box:SetScript("OnEnterPressed", function() f:Hide() end)
    f.box:SetScript("OnTextChanged", function(b, user)
      if user and b:GetText() ~= f.value then b:SetText(f.value or ""); reselect(b) end
    end)
    f.box:SetScript("OnMouseUp", reselect)
    f.box:SetScript("OnKeyDown", function(_, key)
      if key == "C" and IsControlKeyDown and IsControlKeyDown() then
        f.hint:SetText(L["Copied"])
        f.hint:SetTextColor(unpack(C.accent))
        -- kopyalama tusun kendisiyle olur; pencere bir an sonra kapanir. Bu arada baska bir link acildiysa
        -- (gen degisti) yeni pencere kapatilmaz.
        local gen = f.gen
        if C_Timer and C_Timer.After then
          C_Timer.After(0.6, function() if f.gen == gen and f:IsShown() then f:Hide() end end)
        else
          f:Hide()
        end
      end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisCopyBox") end
    self.copyBox = f
  end
  f.gen = (f.gen or 0) + 1
  f.value = value or ""
  f.title:SetText(titleText or "")
  f.hint:SetText(hintText or L["Press Ctrl+C to copy, then paste it into your browser."])
  f.hint:SetTextColor(unpack(C.textDim))
  f.box:SetText(f.value)
  f:Show()
  f:Raise()
  f.box:SetFocus()
  f.box:HighlightText()
  return f
end

-- Cok satirli metin penceresi (tek ornek): Skin:ShowTextBox(baslik, metin, ipucu [, onAccept])
-- onAccept yoksa gosterir (secili, Ctrl+C ile kopyalanir); varsa yapistirilacak alan: "Use" dugmesi metni verir.
-- Esc kapatir. Kopyalama kutusuyla ayni kabuk ve katman.
function Skin:ShowTextBox(titleText, value, hintText, onAccept)
  local C, L = self.Colors, ns.L
  local f = self.textBox
  if not f then
    f = CreateFrame("Frame", "ArcanisTextBox", UIParent, "BackdropTemplate")
    f:SetSize(520, 300)
    f:SetPoint("CENTER", 0, 80)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    self:ApplyWindowChrome(f, 32)
    self:RegisterRoot(f)
    f.title = f:CreateFontString(nil, "OVERLAY")
    self:SetFont(f.title, 13, "")
    f.title:SetPoint("TOPLEFT", 14, -10)
    f.title:SetPoint("RIGHT", f, "RIGHT", -44, 0)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.title:SetTextColor(unpack(C.accentHover))
    f.close = self:CreateCloseButton(f, 14)
    f.close:SetPoint("TOPRIGHT", -10, -9)
    f.close:SetScript("OnClick", function() f:Hide() end)
    f.area = self:CreateScrollArea(f, 492, 196)
    f.area:SetPoint("TOPLEFT", 14, -40)
    f.area:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 56)
    f.box = CreateFrame("EditBox", nil, f.area.content)
    f.box:SetMultiLine(true)
    f.box:SetAutoFocus(false)
    f.box:SetPoint("TOPLEFT", 4, -4)
    f.box:SetPoint("RIGHT", f.area.content, "RIGHT", -4, 0)
    f.box:SetHeight(186)
    f.box:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    f.box:SetTextColor(unpack(C.text))
    f.box:SetScript("OnEscapePressed", function() f:Hide() end)
    f.box:SetScript("OnTextChanged", function(b)
      local h = b.GetHeight and b:GetHeight() or 186
      f.area:SetContentHeight(math.max(196, (type(h) == "number" and h or 186) + 8))
    end)
    f.hint = f:CreateFontString(nil, "OVERLAY")
    self:SetFont(f.hint, 10, "")
    f.hint:SetPoint("BOTTOMLEFT", 14, 18)
    f.hint:SetPoint("RIGHT", f, "RIGHT", -130, 0)
    f.hint:SetJustifyH("LEFT")
    f.hint:SetWordWrap(true)
    f.hint:SetTextColor(unpack(C.textDim))
    f.use = self:CreateButton(f, L["Use"], 100, 24, true)
    f.use:SetPoint("BOTTOMRIGHT", -14, 14)
    f.use:SetScript("OnClick", function()
      local fn = f.onAccept
      if fn then fn(f.box:GetText() or "") end
      f:Hide()
    end)
    if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisTextBox") end
    self.textBox = f
  end
  f.onAccept = onAccept
  f.title:SetText(titleText or "")
  f.hint:SetText(hintText or "")
  f.box:SetText(value or "")
  if onAccept then f.use:Show() else f.use:Hide() end
  f:Show()
  f:Raise()
  f.box:SetFocus()
  if not onAccept then f.box:HighlightText() end
  return f
end

-- /wf font: secili yazi tipinin oyunda gercekten yuklenip yuklenmedigi.
ns:RegisterCommand("font", function()
  local s = Skin.fontState
  ns:Print(("font=%s path=%s"):format(tostring(Skin.font), tostring(Skin.Constants.FONT)))
  if s then
    ns:Print(("probe try=%s SetFont=%s GetFont=%s loaded=%s"):format(tostring(s.try), tostring(s.ok), tostring(s.got), tostring(s.loaded)))
  else
    ns:Print("probe: none (game font)")
  end
end, "Show whether the selected font file loaded")
