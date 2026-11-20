-- Arcanis: ozellik onerileri (modul "Discover"). Kapali bir modulun ise yarayacagi an gelince (ucuncu savas,
-- ilk muzayede, ucuncu fisilti...) Dynamic Hub'da kisa bir bildirim: tiklayinca modul acilir ve ayarlari gosterilir.
-- Israrci olmaz: savasta / instance'ta yok, iki oneri arasi en az 20 dk, oturumda en cok 2, her oneri en cok 2 kez
-- (ikincisinde de tiklanmazsa bir daha gelmez), "simdi degil" (tiklanmayan) 7 gun sonra yeniden. Oyuncunun kendi
-- kapattigi modul hic onerilmez. Ilk acilista (yeni kurulum) hazir kurulum secimi onerilir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local D = ns:NewModule("Discover", { defaults = { never = {} }, charDefaults = { seen = {}, count = {} } })
ns.Discover = D

local GAP = 20 * 60          -- sn: iki oneri arasi
local PER_SESSION = 2
local MAX_SHOWS = 2
local REARM = 7 * 24 * 3600  -- sn (sunucu saati): gosterilmis ama tiklanmamis oneri tekrar

local function count(key) return D.char.count[key] or 0 end

-- Kurallar: module (kapali olmali), minLevel, when(ctx). Metinler L[...] ile (locale_check gorur).
D.RULES = {
  { id = "rotation", module = "Rotation", minLevel = 10,
    when = function(c)
      local RF = ns.RF
      return c.combats >= 3 and RF and RF.classes and RF.classes[P.PlayerClassToken() or ""] ~= nil
    end,
    text = function() return L["Rotation helper"], L["Shows your next spell and lights it on your action bar. Click to turn it on."] end },
  { id = "auction", module = "AuctionPanel", when = function(c) return c.auction end,
    text = function() return L["Auction House panel"], L["Scan prices and post your items at your own price. Click to turn it on."] end },
  { id = "prices", module = "Prices", when = function(c) return c.auction end,
    text = function() return L["Auction prices"], L["Auction prices in item tooltips and on the Gold page. Click to turn it on."] end },
  { id = "vendor", module = "Vendor", when = function() return count("merchant") >= 3 end,
    text = function() return L["Vendor helper"], L["Sells grey items and repairs your gear at merchants. Click to turn it on."] end },
  { id = "messages", module = "Messenger", when = function(c) return c.whispers >= 3 end,
    text = function() return L["Messages"], L["Read and answer whispers as conversations on the Dynamic Hub. Click to turn it on."] end },
  { id = "profs", module = "ProfActivity", when = function() return #(P.ProfessionRanks() or {}) > 0 end,
    text = function() return L["Profession activity"], L["Skill-ups, a cast bar while gathering and gold per hour. Click to turn it on."] end },
  { id = "journal", module = "Journal", minLevel = 15, when = function() return count("dungeon") >= 1 end,
    text = function() return L["Dungeon journal"], L["Loot, quests and the right level for every dungeon. Click to turn it on."] end },
  { id = "questauto", module = "QuestAuto", when = function() return count("accepted") >= 10 end,
    text = function() return L["Quest automation"], L["Accepts and turns in your guide's quests for you. Click to turn it on."] end },
}

D.session = { combats = 0, whispers = 0, shown = 0 }

local function now() return P.ServerNow() or 0 end

-- Bu kural simdi gosterilebilir mi
function D:Eligible(rule)
  local mod = ns:GetModule(rule.module)
  if not mod or mod:IsEnabled() or self.db.never[rule.id] then return false end
  if rule.minLevel and P.PlayerLevel() < rule.minLevel then return false end
  local seen = self.char.seen[rule.id]
  if seen and (seen.n >= MAX_SHOWS or now() - (seen.t or 0) < REARM) then return false end
  local ok, yes = pcall(rule.when, self.session)
  return ok and yes and true or false
end

-- Simdi bir oneri yapilabilir mi (savas, instance, siklik)
function D:Quiet()
  local I = ns.Island
  if not (I and I.IsEnabled and I:IsEnabled()) then return false end
  if P.InCombat() or P.InstanceInfo() then return false end
  if self.session.shown >= PER_SESSION then return false end
  if self.lastShown and P.Now() - self.lastShown < GAP then return false end
  return true
end

function D:Accept(rule)
  self.db.never[rule.id] = true   -- kabul edildi: bir daha sorulmaz
  local mod = ns:GetModule(rule.module)
  if mod and not mod:IsEnabled() then
    mod:SetEnabled(true)
    local f = ns.Settings and ns.Settings.Feature and ns.Settings.Feature(rule.module)
    if f and f.onSwitch then ns.SafeCall(f.onSwitch, true) end
  end
  local S = ns.Settings
  if S and not S:OpenOptions(rule.module) then S:Open("modules") end
end

function D:Check()
  if not self:IsEnabled() or not self:Quiet() then return nil end
  for _, rule in ipairs(self.RULES) do
    if self:Eligible(rule) then
      local title, body = rule.text()
      local seen = self.char.seen[rule.id] or { n = 0 }
      seen.n, seen.t = seen.n + 1, now()
      self.char.seen[rule.id] = seen
      self.session.shown = self.session.shown + 1
      self.lastShown = P.Now()
      ns.Island:Push(title, body, "info", function() D:Accept(rule) end, { key = "discover", hold = 12, prio = "low", cat = "discover" })
      return rule.id
    end
  end
  return nil
end

-- Oyuncu bir modulu kendisi kapatirsa o modulun onerileri biter (hazir kurulum sayilmaz)
function D:OnModuleDisabled(name)
  if ns.Settings and ns.Settings.applyingPreset then return end
  -- yalniz kalici kapatma (SetEnabled(false) disabled yazar); ic Disable() sayilmaz
  local mod = ns:GetModule(name)
  if not (mod and mod.db and mod.db.disabled) then return end
  for _, rule in ipairs(self.RULES) do
    if rule.module == name then self.db.never[rule.id] = true end
  end
end

-- Ilk acilis: yeni kurulumda hazir kurulum secimi onerilir (Settings > Modules > Quick setup)
function D:Welcome()
  if ns.db.onboarded ~= nil then return end
  ns.db.onboarded = false   -- bir kez sorulur; kurulum secilince true
  -- ilk acilis kurulumu (UI/Setup.lua): pencere dogrudan acilir; savastaysa savas bitince
  if ns.Setup and ns.Setup.Open then ns.Setup:Open() return end
  local I = ns.Island
  local open = function() if ns.Settings then ns.Settings:Open("modules") end end
  if I and I.IsEnabled and I:IsEnabled() then
    I:Push(L["Welcome to Arcanis"], L["Pick a setup: Minimal, Leveling or Everything. Click to choose."], "info", open,
      { key = "discover", hold = 20 })
  else
    ns:Print(L["Welcome to Arcanis: pick a setup in /wf options."])
  end
end

-- Bu surumden once oyuncunun kapattigi moduller de "kendi kapatti" sayilir (bir kez)
function D:OnInitialize()
  if self.db.seeded then return end
  self.db.seeded = true
  -- kayitli tablodan okunur: toc'ta Discover'dan sonra gelen modullerin mod.db'si burada henuz yok
  local saved = ns.db and ns.db.modules or {}
  for _, rule in ipairs(self.RULES) do
    local m = saved[rule.module]
    if type(m) == "table" and m.disabled then self.db.never[rule.id] = true end
  end
end

function D:OnEnable()
  local function check() ns.SafeCall(D.Check, D) end
  ns:On("PLAYER_REGEN_ENABLED", self, function() D.session.combats = D.session.combats + 1; check() end)
  ns:On("AUCTION_HOUSE_SHOW", self, function() D.session.auction = true; check() end)
  ns:On("MERCHANT_SHOW", self, function() D.char.count.merchant = count("merchant") + 1; check() end)
  ns:On("CHAT_MSG_WHISPER", self, function() D.session.whispers = D.session.whispers + 1; check() end)
  ns:On("QUEST_ACCEPTED", self, function() D.char.count.accepted = count("accepted") + 1 end)
  ns:On("SKILL_LINES_CHANGED", self, check)
  ns:On("PLAYER_LEVEL_UP", self, check)
  -- instance'tan cikinca: ilk zindan gorulduyse zindan onerileri
  ns:On("PLAYER_ENTERING_WORLD", self, function()
    local _, kind = P.InstanceInfo()
    if kind == "party" or kind == "raid" then D.inDungeon = true
    elseif D.inDungeon then D.inDungeon = nil; D.char.count.dungeon = count("dungeon") + 1; check() end
  end)
  ns:Listen("ARCANIS_MODULE_DISABLED", self, function(_, _, name) D:OnModuleDisabled(name) end)
  if not (P.After and P.After(8, function() ns.SafeCall(D.Welcome, D) end)) then self:Welcome() end
end
