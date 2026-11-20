-- Arcanis: uyarilar (modul "Alerts"): cantalar dolu, dayaniklilik, bolge, seviye.
-- Bildirimler ns.Toast ile gosterilir. Her uyari yalniz esigi gecince bir kez verilir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Alerts = ns:NewModule("Alerts", {
  defaults = {
    bags = true, bagFree = 4,
    durability = true, durPct = 25,
    zone = true, levelUp = true,
    lowHealth = true, healthPct = 30, danger = true,
    mail = true, zoneGuide = true, upgrades = true,
    -- karsi taraftan oyuncu: hub'da sinif, seviye ve tehlike rengi; tehlike basina istege bagli ses
    enemy = true, enemyRepeat = 3,   -- ayni oyuncu en erken kac dakikada bir yeniden bildirilir
    enemySoundLow = "none", enemySoundEven = "none", enemySoundHigh = "none",
  },
})
ns.Alerts = Alerts

local FAR = 800   -- yard: sonraki adim bundan uzaksa bolge degisiminde hatirlat

-- opts: { prio, cat } (bildirim duzeyi ve turu, UI/Toast.lua)
function Alerts:Notify(text, kind, opts)
  if ns.Toast then ns.Toast:Show(text, kind, nil, nil, opts) end
end

function Alerts:CheckBags()
  if not self.db.bags then return end
  local free = P.FreeBagSlots()
  if free <= self.db.bagFree then
    if not self.bagWarned then
      self.bagWarned = true
      self:Notify(L["Bags almost full (%d free)"]:format(free), "warn", { cat = "warn" })
    end
  elseif free > self.db.bagFree + 1 then
    self.bagWarned = false
  end
end

-- Yeni gelen yukseltme: cantaya giren esya takiliyi geciyorsa adada bildirir, tiklayinca giyilir.
-- Ilk taramada cantada olanlar "gorulmus" sayilir: yalniz sonradan gelen (loot, odul, alim) haber verilir.
function Alerts:CheckUpgrades()
  if not (self.db.upgrades and ns.Gear) then return end
  -- butun yukseltmeler "gorulmus" isaretlenir (yalniz ilk 5 degil): biri giyilince siradaki eski esya yeni sanilmasin
  local ok, list = pcall(ns.Gear.Upgrades, ns.Gear, 200)
  if not ok then return end
  local first = self.upSeen == nil
  if first then
    -- ilk taramada cantadaki her esya gorulmus sayilir (esya bilgisi henuz gelmemis olsa da)
    self.upSeen = {}
    for bag = 0, P.LastBag() do
      for slot = 1, P.ContainerSlots(bag) do
        local it = P.ContainerItem(bag, slot)
        if it and it.link then self.upSeen[it.link] = true end
      end
    end
  end
  local shown = 0
  for _, u in ipairs(list) do
    if u.link and not self.upSeen[u.link] then
      self.upSeen[u.link] = true
      shown = shown + 1
      if not first and shown <= 3 then
        local link, slot = u.link, u.slot
        self.upOpen = self.upOpen or {}
        self.upOpen[link] = slot
        ns.Toast:Show(L["Upgrade: %s"]:format(link), "info", L["%s, +%.1f score. Click to equip."]:format(u.slotName or "?", u.delta),
          function()
            if not P.EquipItem(link, slot) then ns:Print(L["Cannot equip in combat."]) return end
            ns.Toast:Dismiss("upgrade:" .. link)   -- giyildi: oneri kapanir
          end, { cat = "upgrade", key = "upgrade:" .. link, hold = 10 })
      end
    end
  end
end

function Alerts:CheckDurability()
  if not self.db.durability then return end
  local ratio = P.LowestDurability()
  if not ratio then return end
  local pct = ratio * 100
  if pct <= self.db.durPct then
    if not self.durWarned then
      self.durWarned = true
      self:Notify(L["Durability low (%d%%)"]:format(math.floor(pct + 0.5)), "warn", { cat = "warn" })
    end
  elseif pct > self.db.durPct + 10 then
    self.durWarned = false
  end
end

function Alerts:OnZone()
  local zone = P.ZoneText()
  -- ada aciksa bolge girisini kendisi (seviye araligiyla) gosterir
  if self.db.zone and zone and zone ~= "" and not (ns.Island and ns.Island:IsEnabled() and ns.Island.db.zone) then
    self:Notify(L["Entering %s"]:format(zone), "info", { prio = "low", cat = "zone" })
  end
  -- bu bolgeye uygun rehber onerildiyse "sonraki adim baska yerde" gereksiz
  if self:SuggestHere() or not self.db.zone then return end
  local E = ns.Engine
  local step = E and E:GetStep()
  if not step then return end
  local map, x, y = ns.Zones:Location(step)
  if not map then return end
  local dist = P.DistanceTo(map, x, y)
  if not dist or dist > FAR then
    self:Notify(L["Your next step is in %s"]:format(step.zone or "?"), "info", { cat = "zone" })
  end
end

-- Bolgeye girince / oyuna girince: bu bolgede seviyeye uygun bir rehber varsa onerilir. Oyuncu zaten bu bolgeyi
-- kapsayan uygun bir rehberdeyse sessiz; ayni rehber oturum basina bir kez. Hub'da bildirime tiklamak baslatir.
function Alerts:SuggestHere()
  if not self.db.zoneGuide or P.InCombat() then return nil end
  local G, E = ns.Guides, ns.Engine
  local zone = P.ZoneText()
  local player = G:GetPlayerInfo()
  local guide = G:ForZone(zone, player)
  if not guide then return nil end
  local cur = E and E.guide
  if cur and (cur.id == guide.id or ((G:ZoneShare(cur)[zone] or 0) >= G.ZONE_MIN_SHARE
    and player.level >= cur.minLevel - 1 and player.level <= cur.maxLevel)) then
    return nil
  end
  self.zoneSuggested = self.zoneSuggested or {}
  if self.zoneSuggested[guide.id] then return nil end
  self.zoneSuggested[guide.id] = true
  local start = function() if E and not P.InCombat() then E:SetGuide(guide.id) end end
  ns.Toast:Show(L["Guide for %s"]:format(zone), "info",
    L["%s (level %d-%d) - click to start"]:format(G:TitleOf(guide), guide.minLevel, guide.maxLevel), start, { cat = "zone" })
  return guide
end

function Alerts:OnLevelUp(_, level)
  if not self.db.levelUp then return end
  level = tonumber(level) or P.PlayerLevel()
  self:Notify(L["Level %d reached!"]:format(level), "info", { prio = "low", cat = "level" })
  local player = ns.Guides:GetPlayerInfo()
  player.level = level
  local suggested = ns.Guides:Suggest(player)
  local E = ns.Engine
  if suggested and not (E and E.guide and E.guide.id == suggested.id) then
    self:Notify(L["Suggested guide: %s"]:format(ns.Guides:TitleOf(suggested)), "info", { cat = "level" })
  end
end

-- Dusuk can: savasta esigin altina inince bir kez uyarir; can toparlaninca sifirlanir.
function Alerts:CheckHealth()
  if not self.db.lowHealth then return end
  local frac = P.HealthFraction()
  if not frac then return end
  local pct = frac * 100
  if pct <= self.db.healthPct and frac > 0 then
    if not self.hpWarned then
      self.hpWarned = true
      self:Notify(L["Low health (%d%%)!"]:format(math.floor(pct + 0.5)), "warn", { cat = "warn" })
    end
  elseif pct > self.db.healthPct + 20 then
    self.hpWarned = false
  end
end

-- Tehlikeli hedef: elit, boss ya da cok yuksek seviyeli (kafatasi) hedef secilince uyarir (ayni hedef bir kez).
local DANGER_TEXT = {
  elite = function() return L["Elite target - consider a group."] end,
  boss = function() return L["World boss - avoid alone."] end,
  skull = function() return L["Much higher level target - dangerous!"] end,
}
-- ===== Karsi taraftan oyuncu =====
-- Tehlike seviyenin farkina gore: "low" yesil (3+ alt), "even" sari (-2..+2), "high" kirmizi (3+ ust ya da "??").
Alerts.ENEMY_COLORS = { low = { 0.35, 0.85, 0.45 }, even = { 1.00, 0.82, 0.25 }, high = { 1.00, 0.30, 0.25 } }
-- Ses secenekleri: oyunun ses kiti adi ve yedek numara
Alerts.ENEMY_SOUNDS = {
  { value = "none" },
  { value = "ping", kit = "TELL_MESSAGE", id = 3081 },
  { value = "bell", kit = "READY_CHECK", id = 8960 },
  { value = "warning", kit = "RAID_WARNING", id = 8959 },
  { value = "alarm", kit = "ALARM_CLOCK_WARNING_3", id = 12889 },
}

function Alerts.EnemyDanger(enemyLevel, myLevel)
  if not enemyLevel then return "high" end   -- seviyesi gorunmuyor ("??"): cok yuksek
  local d = enemyLevel - (myLevel or enemyLevel)
  if d >= 3 then return "high" elseif d <= -3 then return "low" end
  return "even"
end

function Alerts:PlayEnemySound(danger)
  local key = danger == "low" and "enemySoundLow" or danger == "even" and "enemySoundEven" or "enemySoundHigh"
  local want = self.db[key]
  for _, s in ipairs(Alerts.ENEMY_SOUNDS) do
    if s.value == want and s.kit then return P.PlaySoundKit(s.kit, s.id) end
  end
  return false
end

-- Tarafsiz muhafizli kasabalar: saldirmak mumkun ama muhafizlar saldirani oldurur; dusman uyarisi anlamsiz.
-- shortcut: Ingilizce alt bolge adlari (istemci dili baska ise eslesmez), gerekirse alan kimligine gecilir.
Alerts.SAFE_TOWNS = { ["Booty Bay"] = true, ["Ratchet"] = true, ["Gadgetzan"] = true, ["Everlook"] = true,
  ["Steamwheedle Port"] = true, ["Light's Hope Chapel"] = true, ["Cenarion Hold"] = true, ["Marshal's Refuge"] = true,
  ["Thorium Point"] = true, ["Mudsprocket"] = true }

-- Birim karsi taraftan oyuncuysa (isim levhasi, hedef, fare) hub'da bildirir. Ayni oyuncu enemyRepeat dakikada bir;
-- olu / hayalet oyuncu ve tarafsiz kasabadaki oyuncu bildirilmez.
function Alerts:CheckEnemy(unit)
  if not (self.db.enemy and unit) then return end
  if Alerts.SAFE_TOWNS[P.SubZoneText() or ""] then return end
  local e = P.EnemyPlayer(unit)
  if not e or e.dead then return end
  local now = P.Now()
  self.enemySeen = self.enemySeen or {}
  local last = self.enemySeen[e.guid]
  if last and now - last < (self.db.enemyRepeat or 3) * 60 then return end
  self.enemySeen[e.guid] = now
  -- tablo buyumesin: suresi gecenler atilir
  for g, t in pairs(self.enemySeen) do
    if now - t > (self.db.enemyRepeat or 3) * 60 then self.enemySeen[g] = nil end
  end
  local danger = Alerts.EnemyDanger(e.level, P.PlayerLevel())
  local hex = P.ClassColorHex(e.class)
  local name = hex and ("|c" .. hex .. e.name .. "|r") or e.name
  local lvl = e.level and tostring(e.level) or "??"
  local title = L["Enemy player: %s"]:format(name)
  local body = L["Level %s %s"]:format(lvl, e.className or "")
  if ns.Toast then
    ns.Toast:Show(title, "warn", body, nil,
      { cat = "enemy", key = "enemy:" .. e.guid, color = Alerts.ENEMY_COLORS[danger], hold = 6, flash = danger == "high" })
  end
  self:PlayEnemySound(danger)
  return danger
end

function Alerts:CheckTarget()
  self:CheckEnemy("target")
  if not self.db.danger then return end
  local kind = P.TargetDanger()
  local guid = P.TargetGUID() or kind
  if not kind then self.lastDanger = nil return end
  if self.lastDanger == guid then return end
  self.lastDanger = guid
  self:Notify(DANGER_TEXT[kind](), "warn", { cat = "warn" })
end

-- Yeni posta: olay giriste ve bolge degisiminde tekrar gelir; yalniz gonderenler degisince bildirilir.
function Alerts:OnMail()
  if not self.db.mail then return end
  if not P.HasNewMail() then self.mailSeen = nil return end
  local senders = P.MailSenders()
  local key = table.concat(senders, ",")
  if key == self.mailSeen then return end
  self.mailSeen = key
  ns.Toast:Show(L["New mail"], "info", #senders > 0 and L["From %s"]:format(table.concat(senders, ", ")) or nil, nil, { cat = "mail" })
end

local WHISPER_MAX = 80   -- bayt: uzun fisilti kisaltilir (UTF-8 harfi ortadan bolunmez)

-- Fisilti bildirimi. Ayar Messenger'da (db.notify; Ayarlar > Messages > Whispers). Alerts kapaliyken Messenger
-- bu islevi kendi olayindan cagirir; ikisi de aciksa yalniz Alerts dinler (cift bildirim olmaz).
function Alerts:OnWhisper(event, text, sender, ...)
  local Ms = ns.Messenger
  if Ms and Ms.db and Ms.db.notify == false then return end
  local msg, name = P.ChatLine(text, sender)
  if not msg then return ns.Toast:Show(L["New whisper"], "info", nil, nil, { cat = "whisper" }) end
  if #msg > WHISPER_MAX then msg = msg:sub(1, WHISPER_MAX - 3):gsub("[\192-\255][\128-\191]*$", "") .. "..." end
  -- adada tiklaninca Messages sayfasi bu konusmayla acilir (Messenger aciksa)
  local bnID = event and event:find("BN_", 1, true) and P.NotSecret((select(11, ...))) or nil
  local open = Ms and Ms:IsEnabled() and function() Ms:Open(name, bnID) end or nil
  ns.Toast:Show(L["Whisper from %s"]:format(name), "info", msg, open, { cat = "whisper" })
end

function Alerts:OnEnable()
  ns:On("UPDATE_PENDING_MAIL", self, "OnMail")
  ns:On("CHAT_MSG_WHISPER", self, "OnWhisper")
  ns:On("CHAT_MSG_BN_WHISPER", self, "OnWhisper")
  ns:On("UNIT_HEALTH", self, function(_, _, unit) if unit == nil or unit == "player" then self:CheckHealth() end end, "player")
  ns:On("PLAYER_TARGET_CHANGED", self, "CheckTarget")
  ns:On("NAME_PLATE_UNIT_ADDED", self, function(o, _, unit) o:CheckEnemy(unit) end)
  ns:On("UPDATE_MOUSEOVER_UNIT", self, function(o) o:CheckEnemy("mouseover") end)
  ns:On("BAG_UPDATE_DELAYED", self, function(o)
    o:CheckBags()
    -- tarama tum cantayi puanlar: art arda gelen olaylar tek taramada birlesir
    if not o.upPending then
      o.upPending = true
      if not P.After(1, function() o.upPending = nil; ns.SafeCall(o.CheckUpgrades, o) end) then o.upPending = nil; o:CheckUpgrades() end
    end
  end)
  ns:On("UPDATE_INVENTORY_DURABILITY", self, "CheckDurability")
  -- oneri disinda (cantadan surukleyip) giyilen yukseltmenin bildirimi de kapanir
  ns:On("PLAYER_EQUIPMENT_CHANGED", self, function(o, _, slot)
    for link, s in pairs(o.upOpen or {}) do
      local _, now = P.EquippedItemFull(s)
      if now == link then o.upOpen[link] = nil; ns.Toast:Dismiss("upgrade:" .. link) end
    end
  end)
  ns:On("ZONE_CHANGED_NEW_AREA", self, "OnZone")
  ns:On("PLAYER_LEVEL_UP", self, "OnLevelUp")
  -- oyuna giris: dunya yuklenip bolge adi oturunca bir kez
  ns:On("PLAYER_ENTERING_WORLD", self, function(_, _, isLogin)
    if isLogin and not P.After(6, function() ns.SafeCall(Alerts.SuggestHere, Alerts) end) then self:SuggestHere() end
  end)
end

ns:RegisterCommand("alerts", function(args)
  local cmd = (args or ""):lower():match("^(%S*)")
  if cmd == "test" then
    Alerts:Notify(L["Entering %s"]:format("Durotar"), "info")
    Alerts:Notify(L["Bags almost full (%d free)"]:format(3), "warn")
    return
  end
  if cmd == "enemy" then   -- uc tehlike rengini ve seslerini dener
    for i, d in ipairs({ "low", "even", "high" }) do
      local lvl = d == "low" and L["Level %s %s"]:format("8", "Rogue") or d == "even" and L["Level %s %s"]:format("12", "Mage")
        or L["Level %s %s"]:format("??", "Warrior")
      ns.Toast:Show(L["Enemy player: %s"]:format("Test" .. i), "warn", lvl, nil,
        { key = "enemytest" .. i, color = Alerts.ENEMY_COLORS[d], hold = 4, flash = d == "high" })
    end
    Alerts:PlayEnemySound("high")
    return
  end
  local mod = ns:GetModule("Alerts")
  if cmd == "on" or cmd == "off" then mod:SetEnabled(cmd == "on") end
  ns:Print(L["Alerts: %s"]:format(mod:IsEnabled() and L["on"] or L["off"]))
end, "[on|off|test] alerts and notifications")
