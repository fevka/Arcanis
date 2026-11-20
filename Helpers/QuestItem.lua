-- Arcanis: gorev esyasi paneli (modul "QuestItem"). Aktif adimin / gunlukteki gorevlerin kullanilan esyalarini
-- bulur ve kucuk bir paneldeki guvenli (secure) dugmelere baglar (en cok MAX_ITEMS, ilki su anki quest'in).
-- Panel varsayilan olarak adim penceresinin sagina yapisir; ust seridinden surukleyip birakilabilir, pencerenin sag
-- kenarina yakin birakilirsa tekrar yapisir. Tus atamasi ilk dugmeye: Oyun ayarlari > Tus Atamalari > Arcanis Path
-- ya da /wf itemkey <TUS>. Savasta panel degistirilemez; degisiklik savas bitince uygulanir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local QI = ns:NewModule("QuestItem", { defaults = { enabled = true, key = nil, docked = true } })
ns.QuestItem = QI

BINDING_HEADER_ARCANISPATH = "Arcanis Path"
_G["BINDING_NAME_CLICK ArcanisPathQuestItem:LeftButton"] = "Use quest item"

local MAX_ITEMS, SIZE, GAP, PAD, GRIP = 6, 28, 4, 4, 8
QI.HEARTHSTONE = 6948
local BIG = 40   -- ocak tasi dugmesi digerlerinden buyuk
local DOCK_SNAP = 30   -- ekran pikseli: pencerenin sag kenarina bu kadar yakin birakilan panel yapisir

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function instant(id)
  local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not fn then return nil end
  local ok, _, _, _, _, icon, classId = pcall(fn, id)
  if ok then return icon, classId end
  return nil
end

local function itemSpell(id)
  local fn = (C_Item and C_Item.GetItemSpell) or GetItemSpell
  if not fn then return nil end
  local ok, spell = pcall(fn, id)
  return ok and spell or nil
end

-- Kullanilacak esyalar (en cok MAX_ITEMS, sirali). Yalniz GOREV GUNLUGUNDEKI bir quest'e bagli esya gosterilir
-- (sahibin bulgusu, 15 Kasim 2026: hicbir quest'e bagli olmayan "quest" sinifli esya paneldeydi):
-- 1) "use" adiminin esyasi (adimin quest'i gunlukte), 2) su anki quest'in ozel esyasi, 3) cantada su anki quest'in
-- esyasi (Quest Brain verisi: Foreman's Blackjack -> Lazy Peons; Classic quest'lerinde GetQuestLogSpecialItemInfo bos
-- doner), 4) gunlukteki diger quest'lerin ozel esyalari ve cantadaki esyalari.
local function specialItem(q)
  local idx = GetQuestLogSpecialItemInfo and q and P.QuestLogIndex(q)
  if not idx then return nil end
  local ok, link = pcall(GetQuestLogSpecialItemInfo, idx)
  return ok and link and tonumber(tostring(link):match("item:(%d+)")) or nil
end

function QI:FindAll()
  local out, seen = {}, {}
  local function add(id)
    if id and not seen[id] and #out < MAX_ITEMS then seen[id] = true; out[#out + 1] = id end
  end
  local E = ns.Engine
  local step = E and E:GetStep()
  -- ocak tasi zamani: buyuk dugme, tikla = kullan. Rehberin "Hearth to X" adiminda en ustte (tus da onu kullanir);
  -- yalniz okun plani ocak tasiysa gorev esyalarindan sonra (gorev esyasi tusu ocak tasina kaymasin)
  local hearth = (P.ItemCount(QI.HEARTHSTONE) or 0) > 0
  if hearth and step and step.type == "hearth" then add(QI.HEARTHSTONE) end
  if step and step.item and step.type == "use" and step.quest and P.IsQuestInLog(step.quest)
    and P.ItemCount(step.item) > 0 then add(step.item) end
  local active = not (step and step.quest) and E and E:ActiveQuest()
  local q = step and step.quest or (active and active.id)
  if q and not P.IsQuestInLog(q) then q = nil end
  add(specialItem(q))
  local items = ns.BrainData and ns.BrainData.items
  local forLog = {}
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local it = P.ContainerItem(bag, slot)
      if it and it.id and itemSpell(it.id) then
        local need = items and items[it.id] and items[it.id].need
        local mine, logged = false, false
        for _, nq in ipairs(need or {}) do
          if q and nq == q then mine = true elseif P.IsQuestInLog(nq) then logged = true end
        end
        if mine then add(it.id) elseif logged then forLog[#forLog + 1] = it.id end
      end
    end
  end
  for _, e in ipairs(P.QuestLogList()) do
    if e.id ~= q then add(specialItem(e.id)) end
  end
  for _, id in ipairs(forLog) do add(id) end
  if hearth and ns.Nav and ns.Nav.hearthDue then add(QI.HEARTHSTONE) end
  return out
end

local function newButton(parent, i)
  local b = CreateFrame("Button", i == 1 and "ArcanisPathQuestItem" or ("ArcanisPathQuestItem" .. i), parent,
    "SecureActionButtonTemplate,BackdropTemplate")
  b:SetSize(SIZE, SIZE)
  ns.Skin:ApplyBackdrop(b, ns.Skin.Colors.button, ns.Skin.Colors.border)
  -- tus atamasi bas-birak ikisinde de tetiklemesin: istemci ayarina gore tek kenar
  local down = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
  b:RegisterForClicks(down and "AnyDown" or "AnyUp")
  b:SetAttribute("type", "item")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 1, -1); b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  b.count:SetPoint("BOTTOMRIGHT", -1, 1)
  b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
  if b.cd then b.cd:SetAllPoints(b.icon) end
  b:SetScript("OnEnter", function(x)
    if GameTooltip and x.itemId then
      GameTooltip:SetOwner(x, "ANCHOR_RIGHT")
      pcall(GameTooltip.SetItemByID, GameTooltip, x.itemId)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, -(GRIP + (i - 1) * (SIZE + GAP)))
  b:Hide()
  return b
end

-- Panel UIParent'e baglidir (guvenli dugmeler adim penceresinin cocugu olsaydi pencere savasta gosterilip
-- gizlenemezdi); konumu savas disinda pencereye gore hesaplanir.
function QI:Build()
  if self.panel then return self.panel end
  local p = CreateFrame("Frame", "ArcanisQuestItems", UIParent, "BackdropTemplate")
  ns.Skin:RegisterRoot(p)
  ns.Skin:ApplyBackdrop(p, ns.Skin.Colors.bg, ns.Skin.Colors.border)
  p:SetFrameStrata("MEDIUM")
  p:SetSize(SIZE + 2 * PAD, GRIP + SIZE + PAD)
  if p.SetClampedToScreen then p:SetClampedToScreen(true) end
  p:SetMovable(true)
  p:EnableMouse(true)
  p:RegisterForDrag("LeftButton")
  p:SetScript("OnDragStart", function(f) if not inCombat() then f:StartMoving() end end)
  p:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); QI:OnDropped() end)
  p:Hide()
  self.panel = p
  self.buttons = {}
  for i = 1, MAX_ITEMS do self.buttons[i] = newButton(p, i) end
  self.button = self.buttons[1]
  self:ApplyKey()
  return p
end

-- Surukleme bitti: pencerenin sag kenarina yakin ve dikeyde ortusuyorsa yapisir, yoksa serbest konum saklanir.
function QI:OnDropped()
  local p, W = self.panel, ns.Window
  local f = W and W.frame
  local docked = false
  if f and f.GetRight and p.GetLeft then
    local pl, ps = p:GetLeft(), p:GetEffectiveScale()
    local wr, ws = f:GetRight(), f:GetEffectiveScale()
    local pt, wt, wb = p:GetTop(), f:GetTop(), f:GetBottom()
    if pl and wr and pt and wt and wb then
      docked = math.abs(pl * ps - wr * ws) <= DOCK_SNAP and pt * ps <= wt * ws + DOCK_SNAP and pt * ps >= wb * ws
    end
  end
  self.db.docked = docked
  if not docked then
    local point, _, relPoint, x, y = p:GetPoint()
    self.db.point, self.db.relPoint, self.db.x, self.db.y = point, relPoint, x, y
  end
  self:Place()
end

-- Paneli yerlestirir (yalniz savas disinda): yapisiksa adim penceresinin sag ust kosesine, degilse saklanan yere.
function QI:Place()
  local p, W = self.panel, ns.Window
  if not p or inCombat() then return end
  -- rehber adadayken: hub'in saginda yan ada gibi (adanin govdesi, ust kenara yapisik). Panel guvenli dugmeler
  -- tasidigi icin adaya baglanmaz (savasta ada buyuyunce tasinamaz): ekran konumu savas disinda hesaplanir.
  local I = ns.Island
  if ns.GuideDocked and ns.GuideDocked() and I and I.frame and I.frame:IsShown() then
    local anchor = I.frame
    local pill = I.pills and I.pills[1]
    if pill and pill:IsShown() then anchor = pill end
    local ie = I.frame.GetEffectiveScale and I.frame:GetEffectiveScale()
    local ues = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
    if ie and ues and ues > 0 then p:SetScale(ie / ues) end
    local right, top = anchor:GetRight(), anchor:GetTop()
    if type(right) ~= "number" or type(top) ~= "number" then return end
    if not p.hub then
      p.hub = true
      for _, t in ipairs(I:AddShell(p)) do t:Show() end
      ns.Skin:ApplyBackdrop(p, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
      p:SetFrameStrata("HIGH")
    end
    p:ClearAllPoints()
    p:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right + (I.PILL_GAP or 6), top)
    return
  end
  if p.hub then   -- adadan cikti: kendi gorunusu
    p.hub = nil
    for _, t in ipairs(p.pieces or {}) do t:Hide() end
    ns.Skin:ApplyBackdrop(p, ns.Skin.Colors.bg, ns.Skin.Colors.border)
    p:SetFrameStrata("MEDIUM")
  end
  local f = W and W.frame
  local es = f and f.GetEffectiveScale and f:GetEffectiveScale()
  local ues = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
  if es and ues and ues > 0 then p:SetScale(es / ues) end   -- pencereyle ayni boyut
  if self.db.docked ~= false then
    local right, top = f and f.GetRight and f:GetRight(), f and f.GetTop and f:GetTop()
    if type(right) ~= "number" or type(top) ~= "number" then return end
    p:ClearAllPoints()
    p:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right + 4, top)
  elseif self.db.point then
    p:ClearAllPoints()
    p:SetPoint(self.db.point, UIParent, self.db.relPoint or self.db.point, self.db.x or 0, self.db.y or 0)
  end
end

-- Dugmeleri bulunan esyalara baglar (savasta ertelenir). Dondurur: ilk esya kimligi ya da nil.
function QI:Update()
  -- panel adim penceresine gore konumlanir; modul pencereden once acildiysa ilk guncellemede kurulur
  if not self.panel and not inCombat() and ns.Window and ns.Window.frame then self:Build() end
  local p = self.panel
  if not p then return nil end
  if inCombat() then self.pending = true return self.itemId end
  self.pending = false
  local W = ns.Window
  local shown = self:IsEnabled() and W and W:IsEnabled() and not (W.db and W.db.hidden)
  local list = (self.db.enabled and shown) and self:FindAll() or {}
  local y, width = GRIP, SIZE
  for i, b in ipairs(self.buttons) do
    local id = list[i]
    b.itemId = id
    if id then
      local s = id == QI.HEARTHSTONE and BIG or SIZE
      b:SetSize(s, s)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", p, "TOPLEFT", PAD, -y)
      y, width = y + s + GAP, math.max(width, s)
      b:SetAttribute("item", "item:" .. id)
      b.icon:SetTexture(instant(id) or P.ItemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark")
      local n = P.ItemCount(id)
      b.count:SetText(n > 1 and tostring(n) or "")
      b:Show()
    else
      b:SetAttribute("item", nil)
      b:Hide()
    end
  end
  self.itemId = list[1]
  if #list > 0 then
    p:SetSize(width + 2 * PAD, y - GAP + PAD)
    self:Place()
    p:Show()
  else
    p:Hide()
  end
  self:UpdateCooldown()
  -- kamp ikonu panelin altina dizilir: panel acilip kapaninca yerini yenile
  if W and W.sitButton then W:UpdateSit() end
  return list[1]
end

function QI:UpdateCooldown()
  local fn = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
  if not (fn and self.buttons) then return end
  for _, b in ipairs(self.buttons) do
    if b.itemId and b.cd and b.cd.SetCooldown then
      local ok, start, dur = pcall(fn, b.itemId)
      if ok and start and dur then b.cd:SetCooldown(start, dur) end
    end
  end
end

-- Kullanicinin sectigi tus: ilk dugmeye gecici (override) atama.
function QI:ApplyKey()
  local b = self.button
  if not b or inCombat() then return end
  if ClearOverrideBindings then ClearOverrideBindings(b) end
  if self.db.key and SetOverrideBindingClick then
    pcall(SetOverrideBindingClick, b, true, self.db.key, "ArcanisPathQuestItem", "LeftButton")
  end
end

-- Adim penceresi gizlenince / modul kapaninca panel de gizlenir (savasta ertelenir).
function QI:HidePanel()
  if not self.panel then return end
  if inCombat() then self.pending = true else self.panel:Hide() end
end

-- Modul kapaninca dugmeler bosaltilir ve tus atamasi kalkar (yoksa tus / makro son esyayi kullanmaya devam ederdi).
-- Savasta guvenli dugmelere dokunulamaz: savas bitince (modulun kendi olaylari kapali oldugu icin ayri cerceveyle).
function QI:Release()
  if self:IsEnabled() then return end
  ns.SafeCall(self.Update, self)
  if self.button and ClearOverrideBindings then ClearOverrideBindings(self.button) end
end

function QI:OnDisable()
  if not inCombat() then return self:Release() end
  local f = self.offFrame or CreateFrame("Frame")
  self.offFrame = f
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  f:SetScript("OnEvent", function(fr) fr:UnregisterAllEvents(); QI:Release() end)
end

function QI:OnEnable()
  _G["BINDING_NAME_CLICK ArcanisPathQuestItem:LeftButton"] = L["Use quest item"]
  -- olaylar sik gelir (QUEST_LOG_UPDATE, BAG_UPDATE_DELAYED): kisa gecikmeyle birlestir
  local function upd()
    if QI.queued then return end
    if C_Timer and C_Timer.After then
      QI.queued = true
      C_Timer.After(0.2, function() QI.queued = false; ns.SafeCall(QI.Update, QI) end)
    else
      ns.SafeCall(QI.Update, QI)
    end
  end
  ns:On("BAG_UPDATE_DELAYED", self, upd)
  ns:On("QUEST_LOG_UPDATE", self, upd)
  ns:On("PLAYER_REGEN_ENABLED", self, function()
    if QI.pending then upd() end
    QI:Place(); QI:ApplyKey()
  end)
  ns:On("BAG_UPDATE_COOLDOWN", self, function() QI:UpdateCooldown() end)
  ns:Listen("ARCANIS_STEP_CHANGED", self, upd)
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, upd)
  upd()
end

ns:RegisterCommand("itemkey", function(args)
  local key = (args or ""):match("^%s*(%S+)")
  if not key then
    ns:Print(L["Quest item key: %s"]:format(QI.db.key or L["none"]))
    return
  end
  if key:lower() == "clear" then QI.db.key = nil else QI.db.key = key:upper() end
  if inCombat() then ns:Print(L["Will apply after combat."]) end
  QI:ApplyKey()
  ns:Print(L["Quest item key: %s"]:format(QI.db.key or L["none"]))
end, "<KEY|clear> key for the quest item button")
