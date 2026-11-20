-- Arcanis: otomatik gorev (modul "QuestAuto"): gorevi al, tamamla, odulu ver.
--   mode "off"   : hicbir sey yapmaz (varsayilan)
--   mode "guide" : yalniz aktif rehberin yakin adimlarindaki gorevler
--   mode "all"   : her gorev
-- Shift basili tutulursa duraklar. Birden fazla odul seciliyorsa, rewardBest acik degilse oyuncuya birakilir.
-- Odul onerisi (ns.Gear: sinif + uzmanlik + seviye, silah DPS'i dahil) otomasyon kapali olsa da odul penceresinde
-- isaretlenir ve sohbete tek satir yazilir. Yukseltme yoksa en yuksek satici (ya da muzayede) degeri onerilir.
-- Gossip secimi icin C_GossipInfo gerekir (Retail ve Classic'in yeni surumlerinde var).
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Q = ns:NewModule("QuestAuto", { defaults = { mode = "off", rewardBest = true, rewardMode = "upgrade", markRewards = true } })
ns.QuestAuto = Q

local AHEAD = 8          -- rehberde bu kadar adim ileri bakilir
local MIN_UPGRADE = 0.5  -- bundan kucuk puan farki yukseltme sayilmaz
local RETRY_DELAY = 0.5  -- esya bilgisi onbellekte degilse bir kez sonra tekrar bakilir

-- Ad karsilastirmasi noktalama ve bosluktan bagimsiz: rehber verisi "Oh Brother. . .", oyun "Oh Brother..." yazar
-- (selamlama penceresinde quest kimligi gelmezse yalniz ad var; sahibin bulgusu, 15 Kasim 2026)
local function lower(s)
  if type(s) ~= "string" then return nil end
  local n = s:lower():gsub("[%p%s]", "")
  return n ~= "" and n or nil
end
Q.NormName = lower

-- Gorev, aktif rehberin [index-1, index+AHEAD] araligindaki accept/turnin/complete adimlarindan biri mi?
function Q:InGuide(questId, title)
  local E = ns.Engine
  if not (E and E.guide and E.index) then return false end
  local steps = E.guide.steps
  local name = lower(title)
  -- gorunur adimlar sayilir (sinifa ozel gizli bloklar ileriyi kapatmasin)
  local player = ns.Provider.PlayerInfo()
  local seen, i = 0, math.max(1, E.index - 1)
  while i <= #steps and seen <= AHEAD + 1 do
    local s = steps[i]
    if not s.sticky and E:IsVisible(s, player) then
      seen = seen + 1
      if s.type == "accept" or s.type == "turnin" or s.type == "complete" then
        if questId and s.quest == questId then return true end
        if name and lower(s.name) == name then return true end
      end
    end
    i = i + 1
  end
  return false
end

-- Gunlukteki (zaten alinmis) bir gorev rehberin HERHANGI bir yerinde geciyor mu? Teslim/ilerleme icin pencere
-- yetmez: oyuncu iki gorevi birlikte bitirip yakin olani once teslim edince digeri pencerenin gerisinde kalir.
function Q:InGuideLog(questId, title)
  local E = ns.Engine
  if not (E and E.guide) then return false end
  local name = lower(title)
  for _, s in ipairs(E.guide.steps) do
    if s.quest and (s.type == "turnin" or s.type == "complete" or s.type == "accept") then
      local match = (questId and s.quest == questId) or (name and lower(s.name) == name)
      if match and P.IsQuestInLog(s.quest) then return true end
    end
  end
  return false
end

-- turnin: teslim/ilerleme yolu (gorev zaten gunlukte). Yalniz bu yolda rehberin tamami aranir; kabulde
-- pencere kurali gecerli (ayni basliktaki baska bir gorev yanlislikla alinmasin).
function Q:Allowed(questId, title, turnin)
  local mode = self.db.mode
  if mode == "all" then return true end
  if mode == "guide" then return self:InGuide(questId, title) or (turnin == true and self:InGuideLog(questId, title)) end
  return false
end

function Q:Paused()
  return self.db.mode == "off" or P.IsShiftDown()
end

-- Etkin olay islemcileri ----------------------------------------------------
function Q:OnDetail()
  -- gereksiz sinif zinciri (ogrettikleri biliniyor ya da baska irklar icin): uyar, kendiliginden alma
  local E = ns.Engine
  local other, why
  if E and E.ClassQuestNotNeeded then other, why = E:ClassQuestNotNeeded(P.QuestID()) end
  if other then
    local msg = E:NotNeededText(other, why)
    if ns.Island and ns.Island.Push then ns.Island:Push(L["Not needed"], msg, "warn", nil, { cat = "quest" }) else ns:Print(msg) end
    return
  end
  self:MarkOffer()
  if self:Paused() then return end
  local title = GetTitleText and GetTitleText() or nil
  if self:Allowed(P.QuestID(), title) and AcceptQuest then AcceptQuest() end
end

function Q:OnProgress()
  if self:Paused() then return end
  local title = GetTitleText and GetTitleText() or nil
  if self:Allowed(P.QuestID(), title, true) and IsQuestCompletable and IsQuestCompletable() and CompleteQuest then
    CompleteQuest()
  end
end

-- Odul onerisi
-- Dondurur: secim sirasi, bilgi { reason = "upgrade"|"vendor"|"auction", link, delta, spec, missing }
-- Hicbir odulun baglantisi okunamiyorsa nil (karar verilemez, oyuncuya birakilir).
function Q:Recommend(choices)
  choices = choices or P.QuestChoiceCount()
  if not choices or choices < 1 then return nil end
  local Gear = ns.Gear
  local token, level = P.PlayerClassToken(), P.PlayerLevel()
  local specId = Gear and Gear.GetSpec and Gear:GetSpec(token) or nil
  local mode = self.db.rewardMode
  local known, missing = 0, 0
  local bestVendor, bestPrice, vendorLink = nil, -1, nil
  local bestUp, bestDelta, upLink = nil, MIN_UPGRADE, nil
  local bag = false   -- odullerden biri canta: canta kaliciliktir, otomatik secilmez (oyuncu karar verir)
  for i = 1, choices do
    local link = P.QuestChoiceLink(i)
    -- okunamayan odul (link ya da satis fiyati henuz gelmedi) "eksik" sayilir: o odul en iyisi olabilir,
    -- otomatik secim yapilmaz (HandleComplete bir kez daha dener, sonra yalniz isaretler)
    if not link then missing = missing + 1 end
    if link then
      known = known + 1
      local raw = P.ItemSellPrice(link)
      if raw == nil and mode ~= "upgrade" then missing = missing + 1 end
      local price = raw or 0
      if mode == "auction" and ns.Suite then
        price = ns.Suite:Price(P.ItemIdFromLink(link)) or price
      end
      if price > bestPrice then bestVendor, bestPrice, vendorLink = i, price, link end
      if mode == "upgrade" and Gear then
        local item = P.ItemDetailsFromLink(link)
        if not item then
          missing = missing + 1
        else
          if item.equipLoc == "INVTYPE_BAG" then bag = true end
          local ok, delta, _, eqLink, score = pcall(Gear.Compare, Gear, item, token, specId, level)
          -- bos yuva: "bos yuvaya +5" esigiyle statsiz esya (takı, yuzuk) gercek yukseltmeyi gecmesin; puanla siralanir
          if ok and eqLink == nil then
            if type(score) == "number" and score > 0 then delta = score else delta = nil end
          end
          if ok and type(delta) == "number" and delta > bestDelta then bestUp, bestDelta, upLink = i, delta, link end
        end
      end
    end
  end
  if known == 0 then return nil end
  if bestUp then
    return bestUp, { reason = "upgrade", link = upLink, delta = bestDelta, spec = specId, missing = missing, bag = bag }
  end
  return bestVendor or 1, { reason = mode == "auction" and "auction" or "vendor", link = vendorLink, missing = missing, bag = bag }
end

-- Odul dugmesinde gorunur isaret (korumasiz doku; Blizzard cercevesi yoksa yalniz sohbet satiri).
local marks = {}
local arrows = {}   -- yukseltme odulunde ek yesil ok (UI/GearMarks.lua ile ayni)

function Q:ClearMarks()
  for _, m in pairs(marks) do pcall(m.Hide, m) end
  for _, a in pairs(arrows) do pcall(a.Hide, a) end
end

local function accentColor()
  local C = ns.Skin and ns.Skin.Colors
  local a = C and C.accent
  if type(a) == "table" then return a[1] or 1, a[2] or 0.8, a[3] or 0.2 end
  return 1, 0.82, 0
end

local function markButton(btn, upgrade)
  if type(btn) ~= "table" or not btn.CreateTexture then return end
  local m = marks[btn]
  if not m then
    m = btn:CreateTexture(nil, "OVERLAY")
    if not m then return end
    local icon = btn.Icon
    if not icon and btn.GetName then
      local name = btn:GetName()
      icon = name and _G[name .. "IconTexture"]
    end
    m:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    m:SetBlendMode("ADD")
    m:SetSize(70, 70)
    m:SetPoint("CENTER", icon or btn, "CENTER", 0, 0)
    marks[btn] = m
  end
  local r, g, b = accentColor()
  m:SetVertexColor(r, g, b, 1)
  m:Show()
  if upgrade and ns.GearMarks then
    local a = ns.GearMarks.UpArrow(btn, 16)
    arrows[btn] = a
    a:Show()
  end
end

function Q:ReasonText(info)
  if info.reason == "upgrade" then
    local Gear = ns.Gear
    local spec = Gear and Gear.SpecName and Gear:SpecName(P.PlayerClassToken(), info.spec)
    if not spec and Gear and Gear.ClassName then spec = Gear:ClassName(P.PlayerClassToken() or "") end
    return L["upgrade for %s, +%d"]:format(spec or "?", math.floor((info.delta or 0) + 0.5))
  elseif info.reason == "auction" then
    return L["Highest auction value"]
  end
  return L["Highest vendor price"]
end

-- Onerilen odulu isaretle ve (bu pencerede bir kez) sohbete yaz.
function Q:ShowRecommendation(index, info)
  self:ClearMarks()
  if self.db.markRewards ~= false then
    ns.SafeCall(function() markButton(P.QuestRewardButton(index), info.reason == "upgrade") end)
  end
  local quest = P.QuestID() or (GetTitleText and GetTitleText()) or true
  if self.announced == quest then return end
  self.announced = quest
  local name = info.link
  if not name and GetQuestItemInfo then name = GetQuestItemInfo("choice", index) end
  ns:Print(L["Recommended reward: %s (%s)"]:format(tostring(name or ("#" .. index)), self:ReasonText(info)))
end

-- Gorev alinirken de (QUEST_DETAIL) onerilen odul isaretlenir; dugmeler pencere cizilince hazir olur.
-- Sohbete yazilmaz (teslimde yazilir).
function Q:MarkOffer()
  if self.db.markRewards == false then return end
  self.gen = (self.gen or 0) + 1
  local gen = self.gen
  local function mark()
    if gen ~= self.gen or P.QuestChoiceCount() < 2 then return end
    local pick, info = self:Recommend()
    self:ClearMarks()
    if pick then markButton(P.QuestRewardButton(pick), info.reason == "upgrade") end
  end
  if not P.After(0.1, function() ns.SafeCall(mark) end) then ns.SafeCall(mark) end
end

-- Odul penceresi: oneriyi goster; otomasyon izin veriyorsa odulu al.
function Q:OnComplete()
  self.gen = (self.gen or 0) + 1
  self:HandleComplete(self.gen, false)
end

function Q:HandleComplete(gen, retried)
  if gen ~= self.gen then return end   -- pencere kapandi ya da yeni gorev
  local choices = P.QuestChoiceCount()
  local pick, info
  local unsure = false
  if choices > 1 then
    pick, info = self:Recommend(choices)
    -- esya bilgisi henuz gelmediyse (hic link yok ya da bazi oduller okunamadi) bir kez daha dene
    if (pick == nil or info.missing > 0) and not retried then
      local this = self
      if P.After(RETRY_DELAY, function() this:HandleComplete(gen, true) end) then return end
    end
    if pick then self:ShowRecommendation(pick, info) end
    -- hala okunamayan odul varsa (bir yukseltme olabilir) oneri yalniz isaretlenir, otomatik secilmez
    unsure = pick == nil or info.missing > 0 or info.bag == true
  end
  if self:Paused() then return end
  local title = GetTitleText and GetTitleText() or nil
  if not self:Allowed(P.QuestID(), title, true) or not GetQuestReward then return end
  if choices <= 1 then
    GetQuestReward(choices == 1 and 1 or 0)
    return
  end
  if self.db.rewardBest and pick and not unsure then GetQuestReward(pick) end
end

function Q:OnFinished()
  self.gen = (self.gen or 0) + 1
  self.announced = nil
  self:ClearMarks()
end

-- Ayni gossip quest'i kisa surede yeniden secilmez: oyuncu geri cikinca (ya da quest alinamayinca) pencere
-- yeniden acildiginda dongu olmasin.
local RESELECT = 3

function Q:Select(kind, questId)
  local now = P.Now()
  local last = self.lastPick
  if last and last.id == questId and now - last.t < RESELECT then return false end
  self.lastPick = { id = questId, t = now }
  P.SelectGossipQuest(kind, questId)
  return true
end

-- Gossip: once tamamlanabilir gorevi ver, yoksa yeni gorevi al. Her olayda en fazla bir secim.
function Q:OnGossip()
  if self:Paused() then return end
  local avail, active = P.GossipQuests()
  if not avail then return end
  local all = self.db.mode == "all"
  for _, quest in ipairs(active) do
    -- "all": tekrarlanan teslim (malzeme bagisi) sorulmadan verilmez
    if quest.isComplete and not (all and quest.repeatable) and self:Allowed(quest.questID, quest.title, true) then
      if self:Select("active", quest.questID) then return end
    end
  end
  for _, quest in ipairs(avail) do
    -- "all" modunda gri (artik XP vermeyen) quest alinmaz; rehber modunda rehber karar verir
    local grey = (quest.isTrivial or quest.repeatable) and all
    if not grey and self:Allowed(quest.questID, quest.title) then
      if self:Select("available", quest.questID) then return end
    end
  end
end

-- Cok gorevli NPC (QUEST_GREETING): ad ile eslesir. Tamamlanmis olanlari rehber modunda verir.
function Q:OnGreeting()
  if self:Paused() then return end
  local nActive = GetNumActiveQuests and GetNumActiveQuests() or 0
  local all = self.db.mode == "all"
  if self.db.mode == "guide" or all then
    for i = 1, nActive do
      local title, isComplete
      if GetActiveTitle then title, isComplete = GetActiveTitle(i) end   -- "a and f()" yalniz ilk degeri dondurur
      -- bitmemis gorevi secmek ilerleme ekraninda takilir; "all": tekrarlanan teslim (malzeme bagisi) sorulmadan
      -- verilmez (OnGossip ile ayni kural)
      if isComplete and not (all and P.GreetingActiveRepeatable(i)) and self:Allowed(P.GreetingQuestId("active", i), title, true)
        and SelectActiveQuest then SelectActiveQuest(i) return end
    end
  end
  local nAvail = GetNumAvailableQuests and GetNumAvailableQuests() or 0
  for i = 1, nAvail do
    local title = GetAvailableTitle and GetAvailableTitle(i)
    if not (all and P.GreetingAvailableGrey(i)) and self:Allowed(P.GreetingQuestId("available", i), title)
      and SelectAvailableQuest then
      SelectAvailableQuest(i) return
    end
  end
end

function Q:OnEnable()
  ns:On("QUEST_DETAIL", self, "OnDetail")
  ns:On("QUEST_PROGRESS", self, "OnProgress")
  ns:On("QUEST_COMPLETE", self, "OnComplete")
  ns:On("QUEST_FINISHED", self, "OnFinished")
  ns:On("GOSSIP_SHOW", self, "OnGossip")
  ns:On("QUEST_GREETING", self, "OnGreeting")
end
