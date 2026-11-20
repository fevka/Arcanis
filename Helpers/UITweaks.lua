-- Arcanis: oyun arayuzu kolayliklari (modul "UITweaks"). Her biri ayri anahtar, hepsi varsayilan kapali:
--   moveFrames   : Blizzard pencereleri (karakter, buyu kitabi, gorev gunlugu, satici...) surukleyerek tasinir,
--                  Ctrl + tekerlek boyutu; yerler db.frames[ad] = { nokta, ust nokta, x, y, scale = }. Korumali
--                  cerceve (IsProtected) hic tutulmaz; savasta tasima yok. Cantalar yok: oyun her acilista dizer.
--   tooltipMouse : ipucu varsayilan yerine imlecin yaninda (GameTooltip_SetDefaultAnchor kancasi)
--   tooltipCombat: savasta ipucu gizli (Shift basiliyken gorunur)
--   chatCopy     : her sohbet penceresinde kopyala dugmesi -> son satirlar Skin:ShowTextBox'ta
--   chatUrls     : sohbetteki web adresleri tiklanir -> Skin:ShowCopyBox (baglanti turu addon:arcanisurl:)
--   chatFade     : sohbet pencereleri chatFadeSecs sn yeni mesaj yoksa (fare ustte / yazarken degil) solar
-- Kancalar bir kez kurulur ve her seferinde anahtara bakar (kapatinca etkisi biter; tasinan pencere /reload'da
-- oyunun yerine doner). Messenger'in fisilti adasina dokunulmaz: fisiltilar sohbette nasil gorunuyorsa oyle kalir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local UT = ns:NewModule("UITweaks", {
  defaults = { moveFrames = false, frames = {}, tooltipMouse = false, tooltipCombat = false,
    chatCopy = false, chatUrls = false, chatFade = false, chatFadeSecs = 30 },
})
ns.UITweaks = UT

function UT:On(key) return self:IsEnabled() and self.db[key] and true or false end

-- ===== Pencereleri tasima =====
UT.FRAMES = { "CharacterFrame", "SpellBookFrame", "QuestLogFrame", "FriendsFrame", "MerchantFrame", "GossipFrame",
  "QuestFrame", "TaxiFrame", "MailFrame", "TradeFrame", "BankFrame", "DressUpFrame", "LootFrame", "PetStableFrame",
  "ClassTrainerFrame", "PlayerTalentFrame", "TalentFrame", "TradeSkillFrame", "CraftFrame", "MacroFrame",
  "InspectFrame", "AuctionFrame", "KeyBindingFrame" }
UT.hooked = {}

function UT:Restore(name, f)
  local pos = self.db.frames[name]
  if not (pos and self:On("moveFrames")) or P.InLockdown() then return end
  f:ClearAllPoints()
  f:SetPoint(pos[1] or "CENTER", UIParent, pos[2] or "CENTER", pos[3] or 0, pos[4] or 0)
  if pos.scale then f:SetScale(pos.scale) end
end

function UT:SavePos(name, f)
  local p, _, rp, x, y = f:GetPoint(1)
  if not p then return end
  local old = self.db.frames[name]
  self.db.frames[name] = { p, rp, math.floor((x or 0) + 0.5), math.floor((y or 0) + 0.5), scale = old and old.scale }
  if f.SetUserPlaced then f:SetUserPlaced(false) end   -- oyunun kendi yerlesim onbellegine yazilmasin
end

-- Ctrl + tekerlek: 0.6 - 1.5 arasi
function UT.NextScale(cur, delta)
  local s = math.floor(((cur or 1) + (delta > 0 and 0.05 or -0.05)) * 100 + 0.5) / 100
  return math.max(0.6, math.min(1.5, s))
end

function UT:HookFrame(name)
  if self.hooked[name] then return true end
  local f = _G[name]
  if type(f) ~= "table" or not (f.HookScript and f.SetMovable and f.RegisterForDrag) then return false end
  if f.IsProtected and f:IsProtected() then return false end   -- savasta kilitli: hic dokunulmaz
  self.hooked[name] = f
  f:SetMovable(true)
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  f:RegisterForDrag("LeftButton")
  f:HookScript("OnDragStart", function(fr)
    if UT:On("moveFrames") and not P.InLockdown() then fr:StartMoving(); fr.arcMoving = true end
  end)
  f:HookScript("OnDragStop", function(fr)
    if not fr.arcMoving then return end
    fr.arcMoving = nil
    fr:StopMovingOrSizing()
    UT:SavePos(name, fr)
  end)
  f:HookScript("OnShow", function(fr) UT:Restore(name, fr) end)
  f:HookScript("OnMouseWheel", function(fr, delta)
    if not (UT:On("moveFrames") and P.CtrlDown()) or P.InLockdown() then return end
    local pos = UT.db.frames[name]
    if not pos then UT:SavePos(name, fr); pos = UT.db.frames[name] end
    if not pos then return end
    pos.scale = UT.NextScale(pos.scale, delta)
    fr:SetScale(pos.scale)
  end)
  self:WheelFrame(f)
  return true
end

-- Tekerlek yalniz ozellik acikken alinir (kapaliyken pencere ustunde kamera yakinlastirmasi eskisi gibi)
-- Kapatinca pencerenin kendi eski durumu geri gelir (satici / buyu kitabi tekerlekle sayfa cevirir; false yazmak
-- bunu bozuyordu).
function UT:WheelFrame(f)
  if not f.EnableMouseWheel or P.InLockdown() then return end
  if f.__arcWheel == nil then f.__arcWheel = f.IsMouseWheelEnabled and f:IsMouseWheelEnabled() or false end
  f:EnableMouseWheel(self:On("moveFrames") or f.__arcWheel)
end

function UT:HookFrames()
  for _, name in ipairs(self.FRAMES) do self:HookFrame(name) end
  -- oyun panelleri acilinca kendi yerine dizer; kayitli yer sonra yeniden konur
  if not self.panelHook and hooksecurefunc and UpdateUIPanelPositions then
    self.panelHook = true
    hooksecurefunc("UpdateUIPanelPositions", function()
      if not UT:On("moveFrames") then return end
      for name, f in pairs(UT.hooked) do if f.IsShown and f:IsShown() then UT:Restore(name, f) end end
    end)
  end
end

function UT:ApplyMove()
  if self:On("moveFrames") then self:HookFrames() end
  for name, f in pairs(self.hooked) do
    self:WheelFrame(f)
    if f.IsShown and f:IsShown() then self:Restore(name, f) end
  end
end

function UT:ResetFrames()
  wipe(self.db.frames)
  if not P.InLockdown() then for _, f in pairs(self.hooked) do f:SetScale(1) end end
  ns:Print(L["Window positions reset. Type /reload to put every window back now."])
end

-- ===== Ipucu =====
function UT:HookTooltip()
  if self.tipHooked or not GameTooltip then return end
  self.tipHooked = true
  if hooksecurefunc and GameTooltip_SetDefaultAnchor then
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tt, parent)
      if UT:On("tooltipMouse") and tt and parent and tt.SetOwner then tt:SetOwner(parent, "ANCHOR_CURSOR") end
    end)
  end
  if GameTooltip.HookScript then
    GameTooltip:HookScript("OnShow", function(tt)
      if UT:On("tooltipCombat") and P.InCombat() and not P.ShiftDown() then tt:Hide() end
    end)
  end
end

-- ===== Sohbet =====
-- Renk, doku ve baglanti kodlari atilir; baglantinin gorunen metni kalir
function UT.PlainChat(text)
  if type(text) ~= "string" then return "" end
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", "")
  return text
end

function UT:CopyChat(frame)
  local lines = P.ChatLines(frame, 200)
  for i, l in ipairs(lines) do lines[i] = UT.PlainChat(l) end
  ns.Skin:ShowTextBox(L["Copy chat"], table.concat(lines, "\n"), L["Press Ctrl+C to copy."])
end

local URL_PATTERNS = { "https?://[%w%.%-_~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+", "www%.[%w%-]+%.[%w%.%-_~/%?#@!%$&'%*%+,;=%%]+" }
local LINK = "|cff4fb3ff|Haddon:arcanisurl:%s|h[%s]|h|r"

-- Mesajdaki web adreslerini tiklanir baglantiya cevirir; var olan baglantilarin (|H...|h) icine girmez
function UT.LinkURLs(msg)
  if type(msg) ~= "string" or not (msg:find("://", 1, true) or msg:find("www.", 1, true)) then return msg end
  local out, pos = {}, 1
  while pos <= #msg do
    local s, e = msg:find("|H.-|h.-|h", pos)
    local plain = msg:sub(pos, (s or #msg + 1) - 1)
    for _, pat in ipairs(URL_PATTERNS) do
      plain = plain:gsub(pat, function(u)
        local trail = u:match("[%.,;:!%?%)]+$") or ""   -- cumle sonu noktalama adrese dahil degil
        u = u:sub(1, #u - #trail)
        return LINK:format(u, u) .. trail
      end)
      if plain:find("|Haddon:arcanisurl:", 1, true) then break end   -- "https://www..." iki kez sarilmasin
    end
    out[#out + 1] = plain
    if not s then break end
    out[#out + 1] = msg:sub(s, e)
    pos = e + 1
  end
  return table.concat(out)
end

UT.CHAT_EVENTS = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT",
  "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_CHANNEL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
  "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM", "CHAT_MSG_SYSTEM" }

local function urlFilter(_, _, msg, ...)
  if not UT:On("chatUrls") or type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return false end
  local new = UT.LinkURLs(msg)
  if new == msg then return false end
  return false, new, ...
end

function UT:HookChat()
  for _, f in ipairs(P.ChatFrames()) do
    if not f.arcHooked and f.HookScript then
      f.arcHooked = true
      f:HookScript("OnHyperlinkClick", function(_, link)
        local url = type(link) == "string" and link:match("^addon:arcanisurl:(.+)$")
        if url then ns.Skin:ShowCopyBox(L["Web link"], url) end
      end)
      if hooksecurefunc and f.AddMessage then
        hooksecurefunc(f, "AddMessage", function(fr) fr.arcLast = P.Now() end)
      end
    end
    if self:On("chatCopy") and not f.arcCopy then
      local b = ns.Skin:CreateIconButton(f, "bubble", 20)
      b:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
      b:SetFrameLevel((f.GetFrameLevel and f:GetFrameLevel() or 1) + 5)
      b:SetScript("OnClick", function() UT:CopyChat(f) end)
      b:SetScript("OnEnter", function(x)
        if not GameTooltip then return end
        GameTooltip:SetOwner(x, "ANCHOR_LEFT"); GameTooltip:SetText(L["Copy chat"]); GameTooltip:Show()
      end)
      b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
      f.arcCopy = b
    end
    if f.arcCopy then f.arcCopy:SetShown(self:On("chatCopy")) end
  end
  if not self.filtered then
    self.filtered = true
    for _, ev in ipairs(self.CHAT_EVENTS) do P.AddChatFilter(ev, urlFilter) end
  end
end

-- Solma: hedef saydamlik (0 = gizli). Fare ustte, yazma kutusu acik ya da yeni mesaj varken 1.
function UT.FadeTarget(now, last, secs, busy)
  if busy then return 1 end
  return (now - (last or now)) >= secs and 0 or 1
end

local function chatParts(f)
  local name = f.GetName and f:GetName()
  return f, name and _G[name .. "ButtonFrame"], name and _G[name .. "EditBox"]
end

function UT:FadeTick(dt)
  local now, secs = P.Now(), self.db.chatFadeSecs or 30
  for _, f in ipairs(P.ChatFrames()) do
    local _, buttons, edit = chatParts(f)
    f.arcLast = f.arcLast or now
    local busy = P.MouseOver(f) or (edit and edit.HasFocus and edit:HasFocus())
    if busy then f.arcLast = now end
    local want = self:On("chatFade") and UT.FadeTarget(now, f.arcLast, secs, busy) or 1
    local cur = f.GetAlpha and f:GetAlpha() or 1
    if cur ~= want then
      local a = want > cur and want or math.max(want, cur - dt * 2)   -- yavas solar, hemen geri gelir
      f:SetAlpha(a)
      if buttons and buttons.SetAlpha then buttons:SetAlpha(a) end
    end
  end
end

function UT:ApplyChat()
  if self:On("chatCopy") or self:On("chatUrls") or self:On("chatFade") then self:HookChat() end
  if self:On("chatFade") and not self.fader then
    self.fader = CreateFrame("Frame")
    local acc = 0
    self.fader:SetScript("OnUpdate", function(_, dt)
      acc = acc + dt
      if acc < 0.1 then return end
      ns.SafeCall(UT.FadeTick, UT, acc); acc = 0
    end)
  end
  if self.fader then
    if self:On("chatFade") then self.fader:Show() else self:FadeTick(10); self.fader:Hide() end
  end
  for _, f in ipairs(P.ChatFrames()) do if f.arcCopy then f.arcCopy:SetShown(self:On("chatCopy")) end end
end

function UT:ApplyAll()
  self:ApplyMove()
  if self:On("tooltipMouse") or self:On("tooltipCombat") then self:HookTooltip() end
  self:ApplyChat()
end

function UT:Set(key, v)
  self.db[key] = v and true or false
  self:ApplyAll()
end

function UT:OnEnable()
  self:ApplyAll()
  -- isteyince yuklenen Blizzard pencereleri (trainer, yetenek, meslek, makro...)
  ns:On("ADDON_LOADED", self, function() if UT:On("moveFrames") then UT:HookFrames() end end)
  ns:On("PLAYER_REGEN_ENABLED", self, function() UT:ApplyMove() end)
end

function UT:OnDisable() self:ApplyAll() end
