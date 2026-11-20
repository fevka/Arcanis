local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local P = ns.Provider
local L = ns.L
local Island = ns.Island

-- Hub'da mesajlasma: solda kisiler (avatar, ad, son mesaj, saat, okunmamis), sagda secili sohbet (yuvarlak
-- balonlar, balon icinde saat, gun ayiricilari). Boyut, yazi, balon stili ve sinirlar Messenger ayarlarindan.
local Chat = { rows = {}, bubbles = {}, days = {} }
Island.Chat = Chat

local HEADER, PAD, GAP = 28, 12, 8
local LIST_W, ROW_H, HEAD_H, INPUT_H = 196, 44, 48, 48
local GROUP_GAP = 120   -- sn: ayni taraftan bu kadar icinde gelen mesajlar birbirine yakin dizilir
Chat.SIZES = { compact = { 560, 300 }, normal = { 640, 360 }, large = { 720, 440 } }

local function db() return ns.Messenger and ns.Messenger.db or {} end
local function size() return Chat.SIZES[db().chatSize or "normal"] or Chat.SIZES.normal end
function Chat:Width() return size()[1] end
function Chat:Height() return size()[2] end

local function text(parent, sz, color, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f, sz, "")
  f:SetTextColor(unpack(color or Skin.Colors.text))
  f:SetJustifyH(justify or "LEFT")
  return f
end

local BNET_BLUE = { 0.0, 0.7, 1.0, 1 }
-- Duz yazi: oyunun yazi sablonundaki siyah golge acik balonda kabartma (3D) gibi duruyordu; balon yazilarinda yok.
local function flat(fs)
  if fs.SetShadowOffset then fs:SetShadowOffset(0, 0) end
  if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0) end
  return fs
end

local function nameColor(c)
  local r, g, b = P.ClassRGB(c.class)
  if r then return { r, g, b, 1 } end
  if c.bn then return BNET_BLUE end
  return Skin.Colors.text
end

-- Balon renkleri: "clear" (acik balon, koyu yazi: en okunakli), "accent" (giden vurgu tonu), "whisper" (oyunun
-- fisilti tonu), "minimal" (yalniz ince zemin). Donus: gelen, giden, gelen yazi, giden yazi, saat (gelen, giden).
local LIGHT_TEXT, DARK_TEXT = nil, { 0.07, 0.08, 0.10, 1 }
local function bubbleColors()
  local C, style = Skin.Colors, db().bubbleStyle or "clear"
  local lt, dim = C.text, C.textDim
  if style == "clear" then
    local dt, dtime = DARK_TEXT, { 0.28, 0.30, 0.34, 1 }
    return { 0.89, 0.90, 0.92, 1 }, { 0.52, 0.76, 0.99, 1 }, dt, dt, dtime, dtime
  elseif style == "whisper" then
    local w = C.whisper or C.accent
    return { w[1] * 0.22, w[2] * 0.22, w[3] * 0.22, 0.95 }, { w[1] * 0.42, w[2] * 0.42, w[3] * 0.42, 0.95 }, lt, lt, dim, dim
  elseif style == "minimal" then
    return { 1, 1, 1, 0.05 }, { 1, 1, 1, 0.10 }, lt, lt, dim, dim
  end
  local a = C.accent
  return { C.row[1], C.row[2], C.row[3], 0.95 }, { a[1] * 0.42, a[2] * 0.42, a[3] * 0.42, 0.95 }, lt, lt, dim, dim
end

-- Acik balonda oyunun beyaz / sari / acik renk kodlari (esya, quest baglantisi) okunmaz: koyu karsiliklarina cevrilir.
local DARKEN = { ffffff = "202225", ffff00 = "7a6200", ffd200 = "7a6200", ["1eff00"] = "1a7a12", ["9d9d9d"] = "55585e",
  ["0070dd"] = "0b4f9e", a335ee = "6a1fb0", ff8000 = "a04f00", ["00ccff"] = "006f8c", ["40c040"] = "1a7a12" }
local function darkenCodes(s)
  return (s:gsub("|c(%x%x)(%x%x%x%x%x%x)", function(a, rgb) return "|c" .. a .. (DARKEN[rgb:lower()] or rgb) end))
end

-- Bos kutuda soluk yer tutucu; odaklaninca ya da yazi varken gizlenir.
local function placeholder(box, sz)
  local hint = text(box, sz, Skin.Colors.textDim)
  hint:SetPoint("LEFT", 8, 0)
  local function update() if (box:GetText() or "") == "" and not (box.HasFocus and box:HasFocus()) then hint:Show() else hint:Hide() end end
  box:HookScript("OnTextChanged", update)
  box:HookScript("OnEditFocusGained", update)
  box:HookScript("OnEditFocusLost", update)
  box.hint, box.updateHint = hint, update
  return hint
end

-- Iç duzen sabit hedef boyuta gore kurulur (Hub acilirken buyurken anlik boyut kullanilmaz).
function Chat:Layout()
  local f = self.frame
  local W, H = self:Width(), self:Height() - HEADER
  local left = PAD + LIST_W + GAP + 1 + GAP
  f.list:SetHeight(H - (GAP + 24 + GAP) - PAD)
  f.msgs:SetSize(W - left - PAD, H - HEAD_H - INPUT_H - 4)
  f.msgs.content:SetWidth(W - left - PAD - 12)
  f.msgsBg:SetSize(W - left - PAD + 8, H - HEAD_H - INPUT_H + 4)
  self.msgW = W - left - PAD - 12
end

function Chat:Build()
  if self.frame then return end
  local C = Skin.Colors
  local f = CreateFrame("Frame", "ArcanisIslandChat", Island.frame)
  f:SetPoint("TOPLEFT", Island.frame, "TOPLEFT", 0, -HEADER)
  f:SetPoint("BOTTOMRIGHT", Island.frame, "BOTTOMRIGHT", 0, 0)
  f:SetClipsChildren(true)
  f:EnableMouse(true)
  f:SetScript("OnHide", function() if not Chat.hiding and Island.chatOpen then Island:CloseHub() end end)
  if UISpecialFrames then table.insert(UISpecialFrames, "ArcanisIslandChat") end

  -- sol: yeni fisilti kutusu + kisiler
  f.newBox = Skin:CreateEditBox(f, LIST_W, 24)
  f.newBox:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -GAP)
  placeholder(f.newBox, 11)
  f.newBox:SetScript("OnEnterPressed", function(b)
    local pick = Chat.suggest and Chat.suggest[Chat.pick or 0]
    if pick then Chat:PickContact(pick); return end
    local name = (b:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    Chat:PickContact(name ~= "" and { name = name } or nil)
  end)
  -- yazarken arkadas / Battle.net / lonca / son konusma onerileri (oklarla secilir, Enter ya da tikla)
  f.newBox:HookScript("OnTextChanged", function() Chat:UpdateSuggest() end)
  f.newBox:HookScript("OnEditFocusGained", function() Chat:UpdateSuggest() end)
  f.newBox:HookScript("OnEditFocusLost", function() P.After(0.15, function() Chat:HideSuggest() end) end)
  f.newBox:HookScript("OnEscapePressed", function() Chat:HideSuggest() end)
  f.newBox:SetScript("OnArrowPressed", function(_, key) Chat:MoveSuggest(key == "UP" and -1 or key == "DOWN" and 1 or 0) end)
  f.newBox:SetScript("OnTabPressed", function() Chat:MoveSuggest(1) end)
  f.list = Skin:CreateScrollArea(f, LIST_W, 200)
  f.list:SetPoint("TOPLEFT", f.newBox, "BOTTOMLEFT", 0, -GAP)
  f.split = f:CreateTexture(nil, "ARTWORK")
  Skin:Fill(f.split, C.border, 0.6)
  ns.Skin:Hairline(f.split, "w")
  f.split:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + LIST_W + GAP, -GAP)
  f.split:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + LIST_W + GAP, PAD)

  -- sag: baslik (avatar, ad, tur), sil
  local left = PAD + LIST_W + GAP + 1 + GAP
  f.avatar = Skin:CreateAvatar(f, 30)
  f.avatar:SetPoint("TOPLEFT", f, "TOPLEFT", left, -GAP)
  f.name = text(f, 14, C.text)
  f.name:SetPoint("TOPLEFT", f.avatar, "TOPRIGHT", GAP, -1)
  f.name:SetPoint("RIGHT", f, "RIGHT", -(10 + 18 + GAP), 0)
  f.name:SetWordWrap(false)
  f.sub = text(f, 10, C.textDim)
  f.sub:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -4)
  f.delete = Skin:CreateIconButton(f, "close", 18)
  f.delete:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -9)
  f.delete:SetTooltip(L["Delete conversation"])
  f.delete:SetScript("OnClick", function()
    if Chat.key and ns.Messenger then ns.Messenger:Remove(Chat.key); Chat.key = nil; Chat:Refresh() end
  end)

  -- mesaj alani: hafif koyu zemin
  f.msgsBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.msgsBg:SetPoint("TOPLEFT", f, "TOPLEFT", left - 4, -(HEAD_H - 4))
  Skin:ApplyBubble(f.msgsBg, { C.bg[1], C.bg[2], C.bg[3], 0.55 }, 12)
  f.msgs = Skin:CreateScrollArea(f, 400, 200)
  f.msgs:SetPoint("TOPLEFT", f, "TOPLEFT", left, -HEAD_H)

  -- yazma cubugu: kutu + yuvarlak gonder dugmesi
  f.send = Skin:CreateRoundIconButton(f, "rarrow", 28, "square")
  f.send:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD - 2)
  f.send:SetTooltip(L["Send"])
  -- emoji secici: yazma kutusunun solunda dugme, ustunde acilan izgara
  f.emojiBtn = Skin:CreateImageButton(f, ns.Messenger.EMOJI_PATH .. "smile", 26)
  f.emojiBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", left, PAD - 1)
  f.emojiBtn:SetTooltip(L["Emoji"])
  f.emojiBtn:SetScript("OnClick", function() Chat:ToggleEmoji() end)
  f.input = Skin:CreateEditBox(f, 300, 28)
  self:FlatInput(f)
  f.inputLeft = left
  self:BuildEmoji(f, left)
  if f.input.SetMaxBytes then f.input:SetMaxBytes(P.CHAT_MAX) end
  placeholder(f.input, 11)
  f.input:SetScript("OnEnterPressed", function() Chat:Send() end)
  f.input:HookScript("OnEscapePressed", function() f.emoji:Hide() end)
  f.send:SetScript("OnClick", function() Chat:Send() end)
  P.HookInsertLink(function(link)
    if f:IsVisible() and f.input:HasFocus() then f.input:Insert(link) end
  end)

  f.empty = text(f, 12, C.textDim, "CENTER")
  f.empty:SetPoint("CENTER", f.msgs, "CENTER")
  f.empty:SetWidth(300)
  f.empty:SetWordWrap(true)

  ns:Listen("ARCANIS_MESSAGES_CHANGED", self, function() if f:IsVisible() then ns.SafeCall(Chat.Refresh, Chat) end end)
  self:BuildSuggest(f)
  -- ilk kurulumda gizlemek OnHide'i tetikler; sohbet o an "acik" sayildigi icin hub kapanip ada kucuk kaliyordu
  self.hiding = true
  f:Hide()
  self.hiding = nil
  self.frame = f
  self:Layout()
end

local SUG_H, SUG_MAX = 26, 6

function Chat:BuildSuggest(f)
  local p = CreateFrame("Frame", nil, f, "BackdropTemplate")
  p:SetWidth(LIST_W)
  p:SetPoint("TOPLEFT", f.newBox, "BOTTOMLEFT", 0, -4)
  p:SetFrameStrata("DIALOG")
  Skin:ApplyBubble(p, Skin.Colors.card, 10)
  p.rows = {}
  for i = 1, SUG_MAX do
    local r = CreateFrame("Button", nil, p, "BackdropTemplate")
    r:SetHeight(SUG_H)
    r:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -(4 + (i - 1) * SUG_H))
    r:SetPoint("RIGHT", p, "RIGHT", -4, 0)
    r.dot = r:CreateTexture(nil, "OVERLAY")
    r.dot:SetSize(6, 6)
    r.dot:SetPoint("LEFT", 8, 0)
    r.dot:SetTexture(Skin.Icons.disc)
    r.dot._skinFixed = true
    r.name = text(r, 11, Skin.Colors.text)
    r.name:SetPoint("LEFT", r.dot, "RIGHT", 8, 0)
    r.name:SetWordWrap(false)
    r.kind = text(r, 10, Skin.Colors.textDim, "RIGHT")
    r.kind:SetPoint("RIGHT", -8, 0)
    r.name:SetPoint("RIGHT", r.kind, "LEFT", -4, 0)
    r.index = i
    r:SetScript("OnEnter", function(x) Chat.pick = x.index; Chat:PaintSuggest() end)
    r:SetScript("OnClick", function(x) Chat:PickContact(Chat.suggest and Chat.suggest[x.index]) end)
    p.rows[i] = r
  end
  p:Hide()
  f.suggest = p
end

function Chat:UpdateSuggest()
  local f = self.frame
  if not (f and f.newBox.HasFocus and f.newBox:HasFocus()) then return end
  self.suggest = ns.Messenger:Suggest(f.newBox:GetText() or "", SUG_MAX)
  self.pick = (f.newBox:GetText() or "") ~= "" and #self.suggest > 0 and 1 or nil
  self:PaintSuggest()
end

function Chat:PaintSuggest()
  local p, list = self.frame.suggest, self.suggest or {}
  if #list == 0 then p:Hide(); return end
  local C = Skin.Colors
  for i, r in ipairs(p.rows) do
    local e = list[i]
    if e then
      r.name:SetText(e.sub and (e.label .. "  |cff8a8a8a" .. e.sub .. "|r") or e.label)
      r.name:SetTextColor(unpack(nameColor(e)))
      r.kind:SetText(e.kind == "recent" and L["Recent"] or e.kind == "bn" and L["Battle.net"] or e.kind == "guild" and L["Guild"] or L["Friend"])
      r.dot:SetVertexColor(unpack(e.online and { 0.35, 0.85, 0.45, 1 } or { 0.5, 0.5, 0.5, 0.6 }))
      Skin:ApplyBubble(r, i == self.pick and C.rowActive or { 0, 0, 0, 0 }, 8)
      r:Show()
    else
      r:Hide()
    end
  end
  p:SetHeight(#list * SUG_H + 8)
  p:Show()
end

function Chat:MoveSuggest(d)
  local n = self.suggest and #self.suggest or 0
  if n == 0 or d == 0 then return end
  self.pick = ((self.pick or (d > 0 and 0 or 1)) - 1 + d) % n + 1
  self:PaintSuggest()
end

function Chat:HideSuggest()
  self.suggest, self.pick = nil, nil
  if self.frame then self.frame.suggest:Hide() end
end

-- Oneri ya da elle yazilan ad: konusma acilir (varsa onceki), yazma kutusuna gecilir.
function Chat:PickContact(e)
  local f = self.frame
  f.newBox:SetText("")
  self:HideSuggest()
  f.newBox:ClearFocus()
  if not (e and ns.Messenger) then return end
  self.key = e.key or ns.Messenger:Start(e.name, e.bn, e.class)
  self:Refresh()
  f.input:SetFocus()
end

local EMOJI_COLS, EMOJI_CELL = 6, 28

function Chat:BuildEmoji(f, left)
  local list = ns.Messenger.EMOJI
  local rows = math.ceil(#list / EMOJI_COLS)
  local p = CreateFrame("Frame", nil, f, "BackdropTemplate")
  p:SetSize(EMOJI_COLS * EMOJI_CELL + 2 * GAP, rows * EMOJI_CELL + 2 * GAP)
  p:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", left, INPUT_H - 4)
  p:SetFrameStrata("DIALOG")
  Skin:ApplyBubble(p, Skin.Colors.card, 12)
  p.cells = {}
  for i, e in ipairs(list) do
    local b = Skin:CreateImageButton(p, ns.Messenger.EMOJI_PATH .. e.id, EMOJI_CELL)
    b:SetPoint("TOPLEFT", p, "TOPLEFT", GAP + ((i - 1) % EMOJI_COLS) * EMOJI_CELL, -(GAP + math.floor((i - 1) / EMOJI_COLS) * EMOJI_CELL))
    b:SetTooltip(e.codes[1])
    b.code = e.codes[1]
    b:SetScript("OnClick", function(x) Chat:PickEmoji(x.code) end)
    p.cells[i] = b
  end
  p:Hide()
  f.emoji = p
end

-- Emoji acikken kutu dugmenin sagindan, kapaliyken sol kenardan baslar.
-- Yazma kutusu: oyunun kutu kenari yerine duz, yumusak koseli zemin ve 1 px kenar (odakta vurgu rengi).
function Chat:FlatInput(f)
  local box, C = f.input, Skin.Colors
  if box.SetBackdrop then pcall(box.SetBackdrop, box, nil) end
  for _, t in ipairs(box.slices or {}) do t:Hide() end
  function box:SetBackdropColor() end
  function box:SetBackdropBorderColor() end
  local edge = CreateFrame("Frame", nil, f)
  edge:SetPoint("TOPLEFT", box, "TOPLEFT"); edge:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT")
  edge:SetFrameLevel(math.max(0, (box:GetFrameLevel() or 1) - 1))
  local fill = CreateFrame("Frame", nil, edge)
  fill:SetPoint("TOPLEFT", 1, -1); fill:SetPoint("BOTTOMRIGHT", -1, 1)
  f.inputEdge, f.inputFill = edge, fill
  local function paint(focus)
    Skin:ApplyRounded(edge, focus and C.accent or C.border, 7)
    Skin:ApplyRounded(fill, { C.bg[1], C.bg[2], C.bg[3], 1 }, 6)
  end
  paint(false)
  f.paintInput = paint
  box:SetTextColor(unpack(C.text))
  if box.SetShadowOffset then box:SetShadowOffset(0, 0) end
  box:HookScript("OnEditFocusGained", function() paint(true) end)
  box:HookScript("OnEditFocusLost", function() paint(false) end)
  -- zemin kutunun altinda ayri cerceve: kutu gizlenince / gorununce o da
  box:HookScript("OnShow", function() edge:Show() end)
  box:HookScript("OnHide", function() edge:Hide() end)
end

function Chat:PlaceInput(emoji)
  local f = self.frame
  f.emojiBtn:SetShown(emoji)
  if not emoji then f.emoji:Hide() end
  f.input:ClearAllPoints()
  f.input:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", f.inputLeft + (emoji and 26 + GAP or 0), PAD - 2)
  f.input:SetPoint("RIGHT", f.send, "LEFT", -GAP, 0)
end

function Chat:ToggleEmoji()
  local p = self.frame and self.frame.emoji
  if p then p:SetShown(not p:IsShown()) end
end

-- Secilen emojinin metin kodu kutuya eklenir (karsi taraf Arcanis kullanmiyorsa ":)" gorur).
function Chat:PickEmoji(code)
  local f = self.frame
  local cur = f.input:GetText() or ""
  local sep = (cur ~= "" and not cur:match("%s$")) and " " or ""
  if f.input.Insert then f.input:Insert(sep .. code .. " ") else f.input:SetText(cur .. sep .. code .. " ") end
  f.input:SetFocus()
  f.emoji:Hide()
end

function Chat:Send()
  local Ms, f = ns.Messenger, self.frame
  if not (Ms and self.key) then return end
  local msg = f.input:GetText() or ""
  if not msg:find("%S") then return end   -- bos kutuda Enter: hata yazma
  if Ms:Reply(self.key, msg) then
    -- kutu hemen bosalir (sunucu onayini beklemek hantal); onay (WHISPER_INFORM) 3 sn icinde gelmezse
    -- metin geri yazilir, mesaj kaybolmaz
    local pend = { key = self.key, n = #Ms:Get(self.key).msgs, text = msg }
    self.pending = pend
    f.input:SetText("")
    P.After(3, function()
      if self.pending ~= pend then return end
      self.pending = nil
      if f.input:GetText() == "" and self.key == pend.key then f.input:SetText(pend.text) end
    end)
  else
    ns:Print(L["Could not send the message."])
  end
end

function Chat:Row(i)
  local r = self.rows[i]
  if r then return r end
  local C = Skin.Colors
  r = CreateFrame("Button", nil, self.frame.list.content, "BackdropTemplate")
  r:SetHeight(ROW_H)
  r.avatar = Skin:CreateAvatar(r, 28)
  r.avatar:SetPoint("LEFT", 8, 0)
  r.name = text(r, 12, C.text)
  r.name:SetPoint("TOPLEFT", r.avatar, "TOPRIGHT", GAP, 0)
  r.name:SetPoint("RIGHT", r, "RIGHT", -44, 0)
  r.name:SetWordWrap(false)
  r.time = text(r, 10, C.textDim, "RIGHT")
  r.time:SetPoint("TOPRIGHT", -GAP, -GAP)
  r.preview = text(r, 10, C.textDim)
  r.preview:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4)
  r.preview:SetPoint("RIGHT", r, "RIGHT", -28, 0)
  r.preview:SetWordWrap(false)
  r.badge = ns.PathWindow.UI.badge(r, 16)
  r.badge:SetPoint("BOTTOMRIGHT", -GAP, 6)
  r:SetScript("OnClick", function(x) Chat.key = x.key; Chat:Refresh() end)
  self.rows[i] = r
  return r
end

function Chat:LayoutList(list)
  local C, content = Skin.Colors, self.frame.list.content
  content:SetWidth(LIST_W - 12)
  local showAv = db().avatars ~= false
  local y = 0
  for i = 1, math.max(#list, #self.rows) do
    local e, r = list[i], self:Row(i)
    if e then
      local c, sel = e.convo, e.key == self.key
      r.key = e.key
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
      r:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      local rc = sel and C.rowActive or { 0, 0, 0, 0 }
      local rk = table.concat(rc, ",")
      if r.colorKey ~= rk then Skin:ApplyBubble(r, rc, 10); r.colorKey = rk end   -- backdrop yalniz renk degisince
      r.avatar:SetShown(showAv)
      if c.bn then ns.Messenger:BNetInfo(c) end
      r.avatar:Set(c.name, nameColor(c), c.class, c.tag)
      r.name:ClearAllPoints()
      if showAv then r.name:SetPoint("TOPLEFT", r.avatar, "TOPRIGHT", GAP, 0) else r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 10, -GAP) end
      r.name:SetPoint("RIGHT", r, "RIGHT", -44, 0)
      r.name:SetText(c.name or "?")
      r.name:SetTextColor(unpack(nameColor(c)))
      local last = c.msgs[#c.msgs]
      r.preview:SetText(last and ((last.out and (L["You"] .. ": ") or "") .. ns.Messenger.Display(ns.Messenger.Plain(last.text))) or "")
      r.time:SetText(last and P.ClockText(last.t) or "")
      if (c.unread or 0) > 0 and not sel then r.badge:Set(tostring(c.unread)); r.badge:Show() else r.badge:Hide() end
      r:Show()
      y = y + ROW_H + 2
    else
      r:Hide()
    end
  end
  self.frame.list:SetContentHeight(y)
end

function Chat:Bubble(i)
  local b = self.bubbles[i]
  if b then return b end
  b = CreateFrame("Button", nil, self.frame.msgs.content, "BackdropTemplate")
  b.text = flat(text(b, 12, Skin.Colors.text))
  b.text:SetPoint("TOPLEFT", 10, -GAP)
  b.text:SetWordWrap(true)
  b.text:SetJustifyV("TOP")
  b.time = flat(text(b, 9, Skin.Colors.textDim, "RIGHT"))
  b.time:SetPoint("BOTTOMRIGHT", -10, 6)
  b:SetScript("OnClick", function(x)
    if x.msg then Skin:ShowCopyBox(L["Copy message"], ns.Messenger.Plain(x.msg.text), L["Press Ctrl+C to copy."]) end
  end)
  b:SetScript("OnEnter", function(x)
    if GameTooltip then GameTooltip:SetOwner(x, "ANCHOR_TOP"); GameTooltip:SetText(L["Click to copy"]); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  self.bubbles[i] = b
  return b
end

function Chat:Day(i)
  local d = self.days[i]
  if d then return d end
  d = CreateFrame("Frame", nil, self.frame.msgs.content, "BackdropTemplate")
  d:SetHeight(18)
  d.text = flat(text(d, 10, Skin.Colors.textDim, "CENTER"))
  d.text:SetPoint("CENTER", 0, 0)
  self.days[i] = d
  return d
end

local function dayLabel(t)
  local now = P.Clock()
  local key = P.DayKey(t)
  if key == P.DayKey(now) then return L["Today"] end
  if key == P.DayKey(now - 86400) then return L["Yesterday"] end
  return P.DateText(t)
end

function Chat:LayoutMessages(c)
  local C, area = Skin.Colors, self.frame.msgs
  local W = self.msgW or 400
  local maxText = math.floor(W * 0.72) - 20
  local fs = db().chatFont or 12
  local showTime = db().times ~= false
  local inColor, outColor, inText, outText, inTime, outTime = bubbleColors()
  local light = (db().bubbleStyle or "clear") == "clear"
  local y, prev, nDay = 6, nil, 0
  -- ayni konusmaya yalniz yeni mesaj eklendiyse (ayar ve ilk mesaj ayni) eskiler yeniden dizilmez:
  -- her gelen/giden mesajda 100 baloncugu bastan olcmek sohbeti hantallastiriyordu
  local fontKey = fs .. ":" .. tostring(Skin.Constants and Skin.Constants.FONT)   -- boyut ve yazi tipi
  local sig = table.concat({ W, fontKey, tostring(showTime), tostring(db().emoji), table.concat(inColor, ","), table.concat(outColor, ","),
    table.concat(inText, ",") }, "|")
  local lay, from = self.lay, 1
  if lay and lay.c == c and lay.sig == sig and lay.first == c.msgs[1] and #c.msgs >= lay.n then
    y, prev, nDay, from = lay.y, lay.prev, lay.nDay, lay.n + 1
  end
  for i = from, math.max(#c.msgs, #self.bubbles) do
    local m, b = c.msgs[i], self:Bubble(i)
    if m then
      local day = P.DayKey(m.t)
      if not prev or P.DayKey(prev.t) ~= day then
        nDay = nDay + 1
        local d = self:Day(nDay)
        d.text:SetText(dayLabel(m.t))
        d:SetWidth(math.ceil(tonumber(d.text:GetStringWidth()) or 60) + 20)
        Skin:ApplyRounded(d, { C.card[1], C.card[2], C.card[3], 0.9 }, 8)
        d:ClearAllPoints()
        d:SetPoint("TOP", area.content, "TOP", 0, -y)
        d:Show()
        y = y + 18 + GAP
      elseif prev then
        local close = (prev.out and true or false) == (m.out and true or false) and (m.t or 0) - (prev.t or 0) <= GROUP_GAP
        y = y + (close and 2 or 6)
      end
      prev = m
      if b.fs ~= fontKey then Skin:SetFont(b.text, fs, ""); flat(b.text); b.fs = fontKey end
      b.msg = m
      b.text:SetWidth(maxText)
      local shown = ns.Messenger.Display(m.text)
      b.text:SetText(light and darkenCodes(shown) or shown)
      b.text:SetTextColor(unpack(m.out and outText or inText))
      b.time:SetTextColor(unpack(m.out and outTime or inTime))
      local tw = math.min(maxText, math.ceil(tonumber(b.text:GetStringWidth()) or maxText))
      local th = math.ceil(tonumber(b.text:GetStringHeight()) or fs + 2)
      local timeW = 0
      if showTime then
        b.time:SetText(P.ClockText(m.t)); b.time:Show()
        timeW = math.ceil(tonumber(b.time:GetStringWidth()) or 28) + GAP
      else
        b.time:Hide()
      end
      local w, h
      if showTime and th <= fs + 4 and tw + timeW <= maxText then
        w, h = tw + timeW + 20, th + 16         -- tek satir: saat ayni satirin sonunda
      else
        w, h = math.max(tw, timeW) + 20, th + 16 + (showTime and 12 or 0)
      end
      b.text:SetWidth(tw + 1)
      b:SetSize(w, h)
      b:ClearAllPoints()
      if m.out then b:SetPoint("TOPRIGHT", area.content, "TOPRIGHT", -4, -y)
      else b:SetPoint("TOPLEFT", area.content, "TOPLEFT", 4, -y) end
      -- backdrop yalniz renk degisince kurulur (her yenilemede 100 baloncuk yeniden kurulmasin)
      local col = m.out and outColor or inColor
      local ck = table.concat(col, ",")
      if b.colorKey ~= ck then Skin:ApplyRounded(b, col, 8); b.colorKey = ck end
      b:Show()
      y = y + h
    else
      b.msg = nil
      b:Hide()
    end
  end
  for i = nDay + 1, #self.days do self.days[i]:Hide() end
  self.lay = { c = c, sig = sig, first = c.msgs[1], n = #c.msgs, y = y, prev = prev, nDay = nDay }
  area:SetContentHeight(y + GAP)
  area:ScrollTo(y + GAP, true)
end

function Chat:Refresh()
  local Ms, f = ns.Messenger, self.frame
  if not (Ms and f) then return end
  self:Layout()
  f.newBox.hint:SetText(L["Whisper to..."])
  f.input.hint:SetText(L["Write a message..."])
  f.newBox.updateHint(); f.input.updateHint()
  local list = Ms:List()
  if self.key and not Ms:Get(self.key) then self.key = nil end
  self.key = self.key or (list[1] and list[1].key)
  Ms.viewing = self.key
  if self.key then Ms:MarkRead(self.key) end
  self:LayoutList(list)
  local c = self.key and Ms:Get(self.key)
  local pend = self.pending
  if pend and c and pend.key == self.key and #c.msgs > pend.n and c.msgs[#c.msgs].out then
    self.pending = nil   -- onay geldi (kutu gonderirken bosaltildi)
  end
  if c then
    if c.bn then Ms:BNetInfo(c) end
    f.avatar:Show(); f.avatar:Set(c.name, nameColor(c), c.class, c.tag)
    f.name:SetText(c.name or "")
    f.name:SetTextColor(unpack(nameColor(c)))
    f.sub:SetText(c.bn and (c.char and (L["Battle.net"] .. " · " .. c.char) or L["Battle.net"]) or L["Whisper"])
    f.delete:Show(); f.input:Show(); f.send:Show()
    self:PlaceInput(db().emoji ~= false)
    f.empty:SetText(#c.msgs == 0 and L["No messages yet. Write the first one below."] or "")
    self:LayoutMessages(c)
  else
    f.avatar:Hide()
    f.name:SetText(L["Messages"])
    f.name:SetTextColor(unpack(Skin.Colors.text))
    f.sub:SetText("")
    f.delete:Hide(); f.input:Hide(); f.send:Hide(); f.emojiBtn:Hide(); f.emoji:Hide()
    f.empty:SetText(L["No messages yet. Whispers you send and receive appear here."])
    self:LayoutMessages({ msgs = {} })
  end
end

function Chat:Open(key)
  self:Build()
  if key then self.key = key end
  self.lay = nil   -- acilista tam dizilir ("Today" / "Yesterday" etiketleri tazelenir)
  self.frame:Show()
  self:Refresh()
end

function Chat:Hide()
  if not self.frame then return end
  self.hiding = true
  self.frame.emoji:Hide()
  self:HideSuggest()
  self.frame:Hide()
  self.hiding = nil
  if ns.Messenger then ns.Messenger.viewing = nil end
end

-- Ayar degisti (boyut, yazi, stil): aciksa yeniden dizilir, ada yeni boya esner.
function Chat:Apply()
  if not self.frame then return end
  if Island.chatOpen then
    self.lay = nil
    self:Refresh()
    Island:Animate(Island:HubWidth(), Island:HubHeight())
  end
end

function Chat:Typing()
  local f = self.frame
  return f and f:IsVisible() and ((f.input.HasFocus and f.input:HasFocus()) or (f.newBox.HasFocus and f.newBox:HasFocus())) or false
end
