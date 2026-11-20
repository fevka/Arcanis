-- Arcanis: mesajlasma (modul "Messenger"). Gelen ve giden fisiltilar konusma konusma saklanir; ana pencerenin
-- "Messages" sayfasi (Modules/MessagesPage.lua) listeler, yanit yazdirir, mesaji kopyalatir.
--   Karakter fisiltilari karakter kaydinda (char.convos) tutulur (Ayarlar: "Keep message history" kapaliysa
--   yalniz bu oturum). Battle.net fisiltilarinin oyunun verdigi ad ve kimligi oturuma bagli: konusma tam
--   BattleTag'e gore (char.bnConvos) saklanir, girista arkadas listesinden bu oturumun kimligine baglanir.
--   Konusma basina en cok db.maxMsgs mesaj, en cok db.maxConvos konusma (en eskisi duser).
--   Metinler gizli degerse (issecretvalue) alinmaz (P.ChatLine).
local _, ns = ...

local P = ns.Provider

-- sohbet ayarlari (Ayarlar > Dynamic Hub > Chat): boyut, yazi, balon stili, avatar, saat, sinirlar
local M = ns:NewModule("Messenger", { defaults = {
  history = true, maxMsgs = 100, maxConvos = 40,
  chatSize = "normal", chatFont = 13, bubbleStyle = "clear", avatars = true, times = true, openOnWhisper = false,
  emoji = true, notify = true,
}, charDefaults = { convos = {}, bnConvos = {} } })
ns.Messenger = M

M.MAX_MSGS, M.MAX_CONVOS = 100, 40   -- varsayilan (ayar yoksa)
function M:Caps() return (self.db and self.db.maxMsgs) or M.MAX_MSGS, (self.db and self.db.maxConvos) or M.MAX_CONVOS end
M.live = {}   -- oturumluk konusmalar (Battle.net; gecmis kapaliyken hepsi)

function M.Key(name, bnID)
  if bnID then return "bn:" .. tostring(bnID) end
  return "c:" .. tostring(name)
end

function M:Get(key)
  return key and ((self.char and self.char.convos[key]) or self.live[key]) or nil
end

local function store(self, bnID)
  if bnID or not (self.db and self.db.history) or not self.char then return self.live end
  return self.char.convos
end

-- En eski konusmalar duser (son mesaj zamanina gore).
local function prune(tbl, max)
  local n, oldest, oldKey = 0, nil, nil
  for k, c in pairs(tbl) do
    n = n + 1
    if not oldest or (c.last or 0) < oldest then oldest, oldKey = c.last or 0, k end
  end
  if n > max and oldKey then tbl[oldKey] = nil; return prune(tbl, max) end
end

-- Battle.net konusmasi: BattleTag (harf avatari icin) ve oynadigi karakterin sinifi guncellenir.
function M:BNetInfo(c)
  local info = c and c.bn and P.BNetFriend and P.BNetFriend(c.bn)
  if not info then return c end
  c.tag = info.tag or c.tag
  c.full = info.full or c.full
  c.char = info.char
  if info.class then c.class = info.class end
  self:SaveBN(c)
  return c
end

-- Battle.net konusmasi tam BattleTag'e gore karakter kaydinda (char.bnConvos[tag]) saklanir: oyunun verdigi
-- ad (|K..|k) ve kimlik oturumluk oldugu icin kaydedilmez; girista arkadas listesinden yeniden baglanir.
-- Kayitli gecmis ile bu oturumun mesajlari ayni tabloyu paylasir.
function M:SaveBN(c)
  if not (c and c.bn and c.full and self.char and self.db and self.db.history) then return end
  self.char.bnConvos = self.char.bnConvos or {}
  local saved = self.char.bnConvos
  local s = saved[c.full]
  if not s then s = { msgs = c.msgs }; saved[c.full] = s end
  if s.msgs ~= c.msgs then
    for _, m in ipairs(c.msgs) do s.msgs[#s.msgs + 1] = m end
    c.msgs = s.msgs
    while #c.msgs > (self:Caps()) do table.remove(c.msgs, 1) end
  end
  s.last, s.unread, s.class, s.tag = c.last, c.unread, c.class, c.tag
  prune(saved, select(2, self:Caps()))
end

-- Kayitli Battle.net konusmalarini bu oturumun kimlikleriyle geri yukler. Arkadas listesi okunduysa true
-- (liste girista gec dolabilir: o zamana kadar her List'te yeniden denenir).
function M:RestoreBN()
  local saved = self.char and self.char.bnConvos
  if not (saved and next(saved)) then return true end
  local any = false
  for _, e in ipairs(P.BNetFriendList and P.BNetFriendList() or {}) do
    if e.bn then
      any = true
      local info = P.BNetFriend(e.bn)
      local s = info and info.full and saved[info.full]
      local key = M.Key(e.name, e.bn)
      if s and not self.live[key] then
        self.live[key] = { name = e.name, bn = e.bn, full = info.full, tag = info.tag, char = info.char,
          class = info.class or s.class, msgs = s.msgs, last = s.last, unread = s.unread or 0 }
      end
    end
  end
  return any
end

-- Bir mesaj ekler. out: giden (bizim yazdigimiz). session: kimligi gelmeyen Battle.net mesaji gibi, kaydedilmez.
-- Donus: konusma anahtari.
function M:Add(name, text, out, guid, bnID, session)
  if type(name) ~= "string" or name == "" or type(text) ~= "string" then return nil end
  local key = M.Key(name, bnID)
  local tbl = session and self.live or store(self, bnID)
  local c = tbl[key]
  if not c then
    c = { name = name, bn = bnID, msgs = {}, unread = 0 }
    tbl[key] = c
  end
  c.name = name
  c.class = c.class or P.ClassOfGUID(guid)
  if bnID then self:BNetInfo(c) end
  local now = P.Clock()
  c.msgs[#c.msgs + 1] = { t = now, out = out and true or nil, text = text }
  local maxMsgs, maxConvos = self:Caps()
  while #c.msgs > maxMsgs do table.remove(c.msgs, 1) end
  c.last = now
  if out then
    c.unread = 0   -- yanit verdik: okunmus sayilir
  elseif self.viewing ~= key then
    c.unread = (c.unread or 0) + 1
  end
  prune(tbl, maxConvos)
  if bnID then self:SaveBN(c) end
  ns:Send("ARCANIS_MESSAGES_CHANGED", key)
  return key
end

-- Bos bir konusma ac (sayfadaki "Whisper to..." kutusu). Donus: anahtar.
function M:Start(name, bnID, class)
  if type(name) ~= "string" then return nil end
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then return nil end
  local key = M.Key(name, bnID)
  local tbl = store(self, bnID)
  if not self:Get(key) then
    tbl[key] = self:BNetInfo({ name = name, bn = bnID, class = class, msgs = {}, unread = 0, last = P.Clock() })
    prune(tbl, select(2, self:Caps()))
    ns:Send("ARCANIS_MESSAGES_CHANGED", key)
  end
  return key
end

-- Konusmalar, en yenisi once: { { key, convo }, ... }
function M:List()
  if not self.bnRestored then self.bnRestored = self:RestoreBN() end
  local out = {}
  local function add(tbl) for k, c in pairs(tbl) do out[#out + 1] = { key = k, convo = c } end end
  if self.char then add(self.char.convos) end
  add(self.live)
  table.sort(out, function(a, b)
    if (a.convo.last or 0) ~= (b.convo.last or 0) then return (a.convo.last or 0) > (b.convo.last or 0) end
    return a.key < b.key
  end)
  return out
end

-- Fisilti kutusu onerileri: yazilan harflerle baslayan (sonra iceren) kisiler; son konusmalar, arkadaslar,
-- Battle.net, lonca. Bos metinde yalniz son konusmalar ve cevrimici olanlar. En cok limit kadar.
local KIND_ORDER = { recent = 1, friend = 2, bn = 3, guild = 4 }
function M:Suggest(text, limit)
  text = type(text) == "string" and text:gsub("^%s+", ""):gsub("%s+$", ""):lower() or ""
  limit = limit or 6
  local me = P.PlayerName():lower()
  local seen, out = {}, {}
  local function score(hay)
    if text == "" then return 2 end
    hay = hay:lower()
    if hay:sub(1, #text) == text or hay:find("[%s%-]" .. text:gsub("%p", "%%%0")) then return 1 end
    if hay:find(text, 1, true) then return 2 end
    return nil
  end
  local function add(e)
    local id = e.bn and ("bn:" .. tostring(e.bn)) or ("c:" .. e.name:lower())
    if seen[id] or e.name:lower() == me then return end
    if text == "" and e.kind ~= "recent" and not e.online then return end
    local sc = score(e.match or e.name)
    if not sc then return end
    seen[id] = true
    e.score = sc
    out[#out + 1] = e
  end
  for _, it in ipairs(self:List()) do
    local c = it.convo
    add({ name = c.name, label = c.name, match = c.name, kind = "recent", bn = c.bn, class = c.class, online = true, key = it.key })
  end
  for _, e in ipairs(P.WhisperContacts and P.WhisperContacts() or {}) do add(e) end
  table.sort(out, function(a, b)
    if a.score ~= b.score then return a.score < b.score end
    if a.online ~= b.online then return a.online end
    if KIND_ORDER[a.kind] ~= KIND_ORDER[b.kind] then return KIND_ORDER[a.kind] < KIND_ORDER[b.kind] end
    return a.label:lower() < b.label:lower()
  end)
  for i = #out, limit + 1, -1 do out[i] = nil end
  return out
end

function M:UnreadTotal()
  local n = 0
  for _, e in ipairs(self:List()) do n = n + (e.convo.unread or 0) end
  return n
end

function M:MarkRead(key)
  local c = self:Get(key)
  if c and (c.unread or 0) > 0 then c.unread = 0; self:SaveBN(c); ns:Send("ARCANIS_MESSAGES_CHANGED", key) end
end

function M:Remove(key)
  local c = self:Get(key)
  if self.char and c and c.full and self.char.bnConvos then self.char.bnConvos[c.full] = nil end
  if self.char then self.char.convos[key] = nil end
  self.live[key] = nil
  if self.viewing == key then self.viewing = nil end
  ns:Send("ARCANIS_MESSAGES_CHANGED", key)
end

function M:ClearAll()
  if self.char then self.char.convos, self.char.bnConvos = {}, {} end
  self.live = {}
  self.viewing = nil
  ns:Send("ARCANIS_MESSAGES_CHANGED")
end

-- Yanit gonder. Mesaj listeye oyunun "gonderildi" olayiyla (WHISPER_INFORM) eklenir; burada eklenmez.
function M:Reply(key, text)
  local c = self:Get(key)
  if not c or type(text) ~= "string" then return false end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then return false end
  if #text > P.CHAT_MAX then text = text:sub(1, P.CHAT_MAX):gsub("[\192-\255][\128-\191]*$", "") end
  return P.SendWhisper(c.name, text, c.bn)
end

-- Adadaki sohbeti bir konusmayla ac (fisilti bildirimi, hub kisayolu). name verilmezse son konusma.
function M:Open(name, bnID)
  local key = name and M.Key(name, bnID) or nil
  if ns.Island and ns.Island.OpenChat then return ns.Island:OpenChat(key) end
  return false
end

-- Olaylar: CHAT_MSG_WHISPER(_INFORM) ve CHAT_MSG_BN_WHISPER(_INFORM). Arguman 12 GUID, 13 Battle.net kimligi.
function M:OnChat(event, text, sender, ...)
  local out = event:find("INFORM", 1, true) ~= nil
  -- fisilti bildirimi: Alerts kapaliysa buradan (aciksa kendi olayiyla gosterir; gizli metinde yalniz baslik)
  local A = ns.Alerts
  if not out and A and A.OnWhisper and not A:IsEnabled() then A:OnWhisper(event, text, sender, ...) end
  local msg, name = P.ChatLine(text, sender)
  if not msg then return end
  local guid, bnID = select(10, ...), select(11, ...)
  local isBN = event:find("BN_", 1, true) ~= nil
  local bn = isBN and P.NotSecret(bnID) or nil
  -- Battle.net adi oturuma bagli bir kod (|K..|k): kimlik gelmese de hicbir zaman kaydedilmez
  local key = self:Add(name, msg, out, P.NotSecret(guid), bn, isBN)
  -- istege bagli: gelen fisiltide sohbet kendiliginden acilir (savasta ve sohbet zaten acikken degil)
  local I = ns.Island
  if not out and key and self.db.openOnWhisper and I and I.OpenChat and not I.chatOpen and not P.InCombat() then
    I:OpenChat(key)
  end
end

-- bir kez: fisilti bildirimi ayari eskiden Alerts'teydi (Alerts.db.whispers); kapatilmissa kapali kalir
function M:OnInitialize()
  if self.db.notifyVer then return end
  self.db.notifyVer = 1
  local a = ns.db and ns.db.modules and ns.db.modules.Alerts
  if type(a) == "table" and (a.whispers == false or a.disabled) then self.db.notify = false end
end

function M:OnEnable()
  -- bir kez: eski varsayilan (koyu "accent" balon, 12 yazi) okunakli acik balona ve 13 yaziya gecer
  if self.db and (self.db.lookVer or 0) < 2 then
    if self.db.bubbleStyle == "accent" then self.db.bubbleStyle = "clear" end
    if self.db.chatFont == 12 then self.db.chatFont = 13 end
    self.db.lookVer = 2
  end
  for _, ev in ipairs({ "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM" }) do
    ns:On(ev, self, "OnChat")
  end
end

-- Islevsel bicim (sayfa ve testler): {rt1} / {yildiz} gibi hedef isaretleri ikona doner.
local RAID = { star = 1, circle = 2, diamond = 3, triangle = 4, moon = 5, square = 6, cross = 7, x = 7, skull = 8 }
-- Emojiler (Media/Emoji, tools/make_emoji.py): metin kodu (tek basina kelime) ya da emoji karakteri -> doku.
-- Secici ilk kodu yazar; Arcanis kullanmayan oyuncu duz metni (":)") gorur.
M.EMOJI_PATH = "Interface\\AddOns\\Arcanis\\Media\\Emoji\\"
M.EMOJI = {
  { id = "smile", codes = { ":)", ":-)" }, chars = { "🙂", "😊", "☺" } },
  { id = "grin", codes = { ":D", ":-D" }, chars = { "😀", "😃", "😄", "😁" } },
  { id = "laugh", codes = { "xD", "XD" }, chars = { "😂", "🤣", "😆" } },
  { id = "wink", codes = { ";)", ";-)" }, chars = { "😉" } },
  { id = "tongue", codes = { ":P", ":p", ":-P" }, chars = { "😛", "😜", "😝" } },
  { id = "sad", codes = { ":(", ":-(" }, chars = { "🙁", "☹", "😞", "😔" } },
  { id = "cry", codes = { ":'(" }, chars = { "😢", "😭" } },
  { id = "surprised", codes = { ":O", ":o", ":-O" }, chars = { "😮", "😲", "😯" } },
  { id = "angry", codes = { ">:(" }, chars = { "😠", "😡" } },
  { id = "cool", codes = { "(cool)" }, chars = { "😎" } },
  { id = "think", codes = { "(hmm)" }, chars = { "🤔", "😕" } },
  { id = "heart", codes = { "<3" }, chars = { "❤", "💕", "💖", "😍", "🥰" } },
  { id = "thumbsup", codes = { "(y)" }, chars = { "👍" } },
  { id = "thumbsdown", codes = { "(n)" }, chars = { "👎" } },
  { id = "fire", codes = { "(fire)" }, chars = { "🔥" } },
  { id = "gold", codes = { "(gold)" }, chars = { "💰", "🪙" } },
  { id = "check", codes = { "(ok)" }, chars = { "✅", "✔" } },
  { id = "party", codes = { "(party)" }, chars = { "🎉", "🥳" } },
}
local EMOJI_CODE, EMOJI_CHAR = {}, {}
for _, e in ipairs(M.EMOJI) do
  for _, c in ipairs(e.codes) do EMOJI_CODE[c] = e.id end
  for _, c in ipairs(e.chars) do EMOJI_CHAR[#EMOJI_CHAR + 1] = { c, e.id } end
end
function M.EmojiIcon(id) return "|T" .. M.EMOJI_PATH .. id .. ":0|t" end

local function emojify(text)
  -- varyasyon secici, ten rengi ve birlestirici atilir; bilinen karakterler dokuya doner
  text = text:gsub("\239\184\143", ""):gsub("\240\159\143[\187-\191]", ""):gsub("\226\128\141", "")
  for _, p in ipairs(EMOJI_CHAR) do
    text = text:gsub(p[1], M.EmojiIcon(p[2]))
  end
  -- bilinmeyen emoji (U+1F000 ustu) kutu yerine notr yuz
  text = text:gsub("\240\159[\128-\191][\128-\191]", M.EmojiIcon("unknown"))
  -- metin kodlari yalniz tek basina kelimeyse (adreslerdeki ":/" gibi seyler bozulmaz)
  return (text:gsub("(%S+)", function(tok)
    local core, tail = tok:match("^(.-)([!%.,%?]*)$")
    local id = EMOJI_CODE[tok] or (core ~= "" and EMOJI_CODE[core])
    if id then return M.EmojiIcon(id) .. (EMOJI_CODE[tok] and "" or tail) end
  end))
end

function M.Display(text)
  if type(text) ~= "string" then return "" end
  text = text:gsub("{(%w+)}", function(w)
    local n = tonumber(w:match("^rt(%d)$") or "") or RAID[w:lower()]
    if n and n >= 1 and n <= 8 then return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. n .. ":0|t" end
  end)
  if M.db and M.db.emoji == false then return text end
  return emojify(text)
end

-- Kopyalanacak duz metin: renk kodlari ve link kabuklari atilir ("[Esya]" kalir).
function M.Plain(text)
  if type(text) ~= "string" then return "" end
  text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
  return text
end
