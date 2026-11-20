-- Arcanis: Mentor (modul "Mentor"). Diger modullerin bilgisinden "simdi ne yapmaliyim?" tavsiyeleri uretir.
-- Her tavsiye: { id, priority (kucuk = once), icon, title, detail, action = fn, actionText }.
-- Oyuncu bir tavsiyeyi gizleyebilir; gizleme seviye atlayana kadar surer (char.dismiss[id] = seviye).
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Mentor = ns:NewModule("Mentor", {
  defaults = { mountGoal = { [40] = 1000000, [60] = 9000000 }, popups = true, easyItems = true, petTeach = true },   -- binek hedefleri (bakir, yaklasik)
  charDefaults = { dismiss = {}, trainedAt = 0, read = {}, shown = {}, tamed = {}, petAlerted = {}, easyDone = {}, easyAlerted = {} },
})
ns.Mentor = Mentor

local GATHER = { Mining = true, Herbalism = true, Skinning = true }

-- Toplama aleti cantada yoksa meslek calismaz: bilinen aletler ve onlari satanlar (Forever yerleri; faction nil = herkes).
local TOOLS = {
  Skinning = { item = "Skinning Knife", ids = { 7005, 12709, 19901 }, vendors = {
    { npc = "Uualia Suncrest", zone = "Zephras Isle", x = 42.75, y = 24.49 },
    { npc = "Brother Danil", zone = "Elwynn Forest", x = 47.49, y = 41.57, faction = "Alliance" },
    { npc = "Adlin Pridedrift", zone = "Dun Morogh", x = 30.09, y = 71.58, faction = "Alliance" },
    { npc = "Lyrai", zone = "Teldrassil", x = 59.52, y = 40.91, faction = "Alliance" },
    { npc = "Bombus Finespindle", zone = "Ironforge", x = 39.61, y = 34.47, faction = "Alliance" },
    { npc = "Joshua Kien", zone = "Tirisfal Glades", x = 32.28, y = 65.44, faction = "Horde" },
    { npc = "Kawnie Softbreeze", zone = "Mulgore", x = 44.82, y = 77.04, faction = "Horde" },
    { npc = "Duokna", zone = "Durotar", x = 42.59, y = 67.34, faction = "Horde" },
    { npc = "Tamar", zone = "Orgrimmar", x = 63.04, y = 45.53, faction = "Horde" },
  } },
  Mining = { item = "Mining Pick", ids = { 2901, 756, 778, 1819, 1893, 1959, 9465, 20723 }, vendors = {
    { npc = "Uualia Suncrest", zone = "Zephras Isle", x = 42.75, y = 24.49 },
    { npc = "Brother Danil", zone = "Elwynn Forest", x = 47.49, y = 41.57, faction = "Alliance" },
    { npc = "Brooke Stonebraid", zone = "Stormwind City", x = 59.15, y = 37.48, faction = "Alliance" },
    { npc = "Adlin Pridedrift", zone = "Dun Morogh", x = 30.09, y = 71.58, faction = "Alliance" },
    { npc = "Thrawn Boltar", zone = "Dun Morogh", x = 45.30, y = 51.53, faction = "Alliance" },
    { npc = "Lyrai", zone = "Teldrassil", x = 59.52, y = 40.91, faction = "Alliance" },
    { npc = "Thelgrum Stonehammer", zone = "Darkshore", x = 38.22, y = 41.19, faction = "Alliance" },
    { npc = "Joshua Kien", zone = "Tirisfal Glades", x = 32.28, y = 65.44, faction = "Horde" },
    { npc = "Sarah Killian", zone = "Undercity", x = 56.72, y = 36.93, faction = "Horde" },
    { npc = "Kawnie Softbreeze", zone = "Mulgore", x = 44.82, y = 77.04, faction = "Horde" },
    { npc = "Kurm Stonehoof", zone = "Thunder Bluff", x = 34.35, y = 56.56, faction = "Horde" },
    { npc = "Duokna", zone = "Durotar", x = 42.59, y = 67.34, faction = "Horde" },
    { npc = "Flakk", zone = "Durotar", x = 52.98, y = 41.97, faction = "Horde" },
    { npc = "Gorina", zone = "Orgrimmar", x = 73.31, y = 26.60, faction = "Horde" },
  } },
}
Mentor.TOOLS = TOOLS

local function add(list, e) list[#list + 1] = e end

-- Oku bir NPC'ye cevir: bolge adi -> harita (Zones), x/y 0-100.
local function pointAt(zone, x, y, label)
  if not (ns.Nav and ns.Zones and zone and x and y) then return end
  local map = ns.Zones:Resolve(zone)
  if map then ns.Nav:SetTarget(map, x / 100, y / 100, label or zone, "mentor") end
  return map and true or false
end
function Mentor:PointAt(zone, x, y, label) return pointAt(zone, x, y, label) end

local function raceOK(races, race)
  if not races then return true end
  for _, r in ipairs(races) do if r == race then return true end end
  return false
end

-- En yakin sinif egitmeni (irkina uygun): mesafesi olculebilenlerin en yakini. Olculemezse (zindan, harita
-- yuklenmemis) seviyeye uygun kademe: 1-5 baslangic koyu, 6-10 ilk kasaba, sonrasi baskent.
local function nearestTrainer(CG, info, level)
  local want = level <= 5 and 1 or (level <= 10 and 2 or 3)
  local best, bestD, byTier
  for _, t in ipairs(CG:Trainers(info.class, info.faction, "class")) do
    if t.x and raceOK(t.races, info.race) then
      local map = ns.Zones and ns.Zones:Resolve(t.zone)
      local d = map and P.DistanceTo(map, t.x / 100, t.y / 100)
      if d and (not bestD or d < bestD) then best, bestD = t, d end
      if not byTier and (t.tier or 3) == want then byTier = t end
    end
  end
  -- rehberin tek sinifa ait trainer adimlari da aday (Skyborne gibi sinif verisinde olmayan baslangic adalari)
  local E, class = ns.Engine, info.class and info.class:upper()
  for _, s in ipairs(E and E.guide and E.guide.steps or {}) do
    if s.trainer and s.npc and s.x and s.classes and class and s.classes[class] and next(s.classes, next(s.classes)) == nil then
      local map, x, y = ns.Zones:Location(s)
      local d = map and P.DistanceTo(map, x, y)
      if d and (not bestD or d < bestD) then
        best, bestD = { npc = s.npc, zone = s.zone, map = map, x = s.x * 100, y = s.y * 100 }, d
      end
    end
  end
  return best or byTier
end

-- "Frostbolt (Rank 2), Polymorph, ... +3 more"
local function spellText(spells, max)
  local out = {}
  for i, s in ipairs(spells) do
    if i > max then out[#out + 1] = L["+%d more"]:format(#spells - max) break end
    out[#out + 1] = s.rank and L["%s (Rank %d)"]:format(s.name, s.rank) or s.name
  end
  return table.concat(out, ", ")
end

-- Bulunulan sehirdeki silah ustalarinin sana ogretebilecegi beceriler: { { npc, at, skills, cost } }.
-- Beceri ancak "bilinmiyor" diye kesin okunursa sayilir; baslangicta bilinen bir beceri bile "bilinmiyor"
-- gorunuyorsa (buyu kimlikleri bu istemcide tutmuyor) hic oneri yapilmaz.
function Mentor:WeaponMastersHere(info, level, zone)
  local CG = ns.ClassGuide
  if not (CG and CG.Weapons and zone and P.KnowsWeaponSkill) then return {} end
  -- her sinif listedeki en az bir beceriyle baslar: hicbiri "biliniyor" okunmuyorsa okuma guvenilmez, oneri yok
  local weapons, missing, proven = CG:Weapons(info.class, info.faction), {}, false
  for _, w in ipairs(weapons) do
    local known = P.KnowsWeaponSkill(w.skill)
    if known == true then proven = true end
    if w.startsKnownBy == "all" and known == false then return {} end
    if known == false then missing[#missing + 1] = w end
  end
  if not proven then return {} end
  local byNpc, order = {}, {}
  for _, w in ipairs(missing) do
    for _, at in ipairs(w.learnAt or {}) do
      if at.city == zone and level >= (at.minLevel or 1) then
        local e = byNpc[at.npc]
        if not e then
          e = { npc = at.npc, at = at, skills = {}, cost = 0 }
          byNpc[at.npc] = e
          order[#order + 1] = e
        end
        e.skills[#e.skills + 1] = L[w.skill] or w.skill
        e.cost = e.cost + (at.cost or 0)
      end
    end
  end
  table.sort(order, function(a, b) return a.npc < b.npc end)
  return order
end

function Mentor:Dismiss(id)
  self.char.dismiss[id] = P.PlayerLevel()
end

function Mentor:IsDismissed(id)
  local lv = self.char.dismiss[id]
  return lv ~= nil and lv >= P.PlayerLevel()
end

-- Cantada giyilebilir yukseltme: { link, delta } en iyisi (yoksa nil).
-- Gear:Upgrades ile ayni sonuc (gomlek/tabard, bos yuvaya cop, takili kopyasi elenir).
function Mentor:BestBagUpgrade()
  local Gear = ns.Gear
  if not (Gear and Gear.Upgrades) then return nil end
  local ok, list = pcall(Gear.Upgrades, Gear, 1)
  local u = ok and list and list[1]
  return u and { link = u.link, delta = u.delta, bag = u.bag, slot = u.bagSlot } or nil
end

-- Trainer'a gitmek gerekiyor mu? due (true/false), trainer penceresinden okunmus liste varsa ogrenilecek spell'ler.
-- Liste yoksa: 1. seviye spell'leri karakterle gelir, Forever'da ilk yeniler 4. seviyede, sonra cift seviyelerde.
-- Rehberin trainer adimi da buna bakar (Engine): ogrenecek bir sey yoksa adim gecilir.
function Mentor:TrainingDue(level, class)
  local CG = ns.ClassGuide
  local trained = (self.char and self.char.trainedAt) or 0
  if CG and CG.HasSpellData and CG:HasSpellData(class) then
    -- 1. seviye buyuleri karakterle gelir: en erken 2. seviyeden sayilir
    local spells = CG:Spells(class, math.max(2, trained > 0 and trained + 1 or level - 1), level)
    return #spells > 0, spells
  end
  return level >= 4 and trained < level - level % 2, nil
end

-- Bilinen toplama meslegi icin cantada alet yoksa: { { prof, item, vendor = {npc, zone, x, y} | nil }, ... }.
-- Satici: ayni kitadaki en yakin (faction uygun); hic olculemezse ilk uygun.
function Mentor:ToolNeeds()
  local out, profs, faction = {}, P.Professions and P.Professions() or {}, P.PlayerInfo().faction
  for prof, tool in pairs(TOOLS) do
    if profs[prof] then
      local have = false
      for _, id in ipairs(tool.ids) do if (P.ItemCount(id) or 0) > 0 then have = true break end end
      if not have then
        local best, bestD, first
        for _, v in ipairs(tool.vendors) do
          if not v.faction or v.faction == faction then
            first = first or v
            local map = ns.Zones and ns.Zones:Resolve(v.zone)
            local d = map and P.DistanceTo(map, v.x / 100, v.y / 100)
            if d and (not bestD or d < bestD) then best, bestD = v, d end
          end
        end
        out[#out + 1] = { prof = prof, item = tool.item, vendor = best or first }
      end
    end
  end
  table.sort(out, function(a, b) return a.prof < b.prof end)
  return out
end

-- Alet eksikse oturumda meslek basina bir kez haber ver (Mentor bildirimleri aciksa).
function Mentor:ToolAlert()
  self.toolAlerted = self.toolAlerted or {}
  for _, n in ipairs(self:ToolNeeds()) do
    if not self.toolAlerted[n.prof] then
      self.toolAlerted[n.prof] = true
      if self.db.popups then
        local where = n.vendor and L["%s sells it (%s)."]:format(n.vendor.npc, n.vendor.zone) or ""
        if ns.Toast then ns.Toast:Show(L["Mentor: %s"]:format(L["Buy a %s"]:format(n.item)), "info", nil, nil, { prio = "low", cat = "mentor" }) end
        ns:Print("|cffdb9e33" .. L["Mentor"] .. ":|r " .. L["%s only works with a %s in your bags."]:format(L[n.prof] or n.prof, n.item) .. " " .. where)
      end
    end
  end
end

function Mentor:Advice()
  local list = {}
  local level = P.PlayerLevel()
  local E = ns.Engine
  local info = P.PlayerInfo()

  -- (rota/sonraki adim bilerek yok: onu adim penceresi zaten gosterir)

  -- 2) yetenek puani
  local points = P.UnspentTalents and P.UnspentTalents() or 0
  if points > 0 then
    local nextT = ns.Build and ns.Build.NextTalent and ns.Build:NextTalent()
    add(list, { id = "talent", priority = 12, icon = "star", title = L["You have %d unspent talent point(s)"]:format(points),
      detail = nextT and L["Recommended next: %s"]:format(nextT) or L["Open the Talents page for the build order."],
      actionText = L["Talents"], action = function() if ns.PathWindow then ns.PathWindow:Open("talents") end end })
  end

  -- 3) egitmen: son ziyaretten bu yana ogrenilecek buyuler (egitmen penceresinden okunmus liste, Helpers/Training.lua)
  -- ve en yakin sinif egitmeni. Ziyaret kaydi yoksa yalniz son iki seviye. Liste henuz yoksa genel hatirlatma.
  local CG = ns.ClassGuide
  local due, spells = self:TrainingDue(level, info.class)
  if spells then
    if due then
      local t = nearestTrainer(CG, info, level)
      local detail = L["%d to learn: %s"]:format(#spells, spellText(spells, 6))
      if t then detail = detail .. "\n" .. L["Trainer: %s, %s"]:format(t.npc, t.mapHint or t.zone) end
      local canPoint = t and ns.Zones and ns.Zones:Resolve(t.zone) ~= nil   -- haritasi yoksa ok dugmesi gosterilmez
      add(list, { id = "train", priority = 25, icon = "guides", title = L["New spells to train"], detail = detail,
        actionText = canPoint and L["Arrow"] or nil, action = canPoint and function() pointAt(t.zone, t.x, t.y, t.npc) end or nil })
    end
  elseif due then
    add(list, { id = "train", priority = 25, icon = "guides", title = L["New spells to train"],
      detail = L["Visit your class trainer at level %d."]:format(level) })
  end

  -- 3b) silah ustasi: bulundugun sehirde sinifinin kullanabildigi ama bilmedigin silah becerileri
  for _, e in ipairs(self:WeaponMastersHere(info, level, P.ZoneText())) do
    local at = e.at
    add(list, { id = "weapon-" .. e.npc, priority = 28, icon = "sword", title = L["Weapon master here: %s"]:format(e.npc),
      detail = L["Can teach you %s (%s in total)."]:format(table.concat(e.skills, ", "), ns.Suite.FormatMoney(e.cost))
        .. (at.mapHint and ("\n" .. at.mapHint) or ""),
      actionText = L["Arrow"], action = function() pointAt(at.city, at.x, at.y, e.npc) end })
  end

  -- 4) canta / tamir
  local free = P.FreeBagSlots and P.FreeBagSlots() or 99
  if free <= 3 then
    local r = ns.Bags and ns.Bags.Scan and ns.Bags:Scan()
    local junk = r and r.grey.value or 0
    add(list, { id = "bags", priority = 18, icon = "bag", title = L["Your bags are almost full (%d free)"]:format(free),
      detail = junk > 0 and L["Sell grey items at a vendor: %s"]:format(ns.Suite.FormatMoney(junk)) or L["Sell or bank what you do not need."],
      actionText = L["Auction"], action = function() if ns.ShowGoldTab then ns.ShowGoldTab("ah") end end })
  end
  local dura = P.LowestDurability and P.LowestDurability()
  if dura and dura < 0.3 then
    add(list, { id = "repair", priority = 14, icon = "hammer", title = L["Repair your gear"],
      detail = L["Lowest durability: %d%%. Broken gear gives no stats."]:format(math.floor(dura * 100)) })
  end

  -- 5) yukseltme
  local up = self:BestBagUpgrade()
  if up then
    add(list, { id = "gear", priority = 16, icon = "shield", title = L["Upgrade in your bags"],
      detail = L["%s is better than what you wear."]:format(up.link or "?") })
  end

  -- 6) altin: binek hedefi
  local goal = level >= 35 and level < 40 and 40 or (level >= 55 and level < 60 and 60) or nil
  if goal then
    local need = (self.db.mountGoal or {})[goal] or 0
    local have = P.Money()
    if need > 0 and have < need then
      add(list, { id = "mount" .. goal, priority = 30, icon = "wing", title = L["Save gold for riding at %d"]:format(goal),
        detail = L["You have %s of about %s. See Farming for the best gold for your level."]:format(ns.Suite.FormatMoney(have), ns.Suite.FormatMoney(need)),
        actionText = L["Farming"], action = function() if ns.ShowGoldTab then ns.ShowGoldTab("farm") end end })
    end
  end

  -- 7) meslek
  local profs = P.Professions and P.Professions() or {}
  local gathers, count = 0, 0
  for name in pairs(profs) do
    count = count + 1
    if GATHER[name] then gathers = gathers + 1 end
  end
  if level >= 5 and gathers == 0 and count < 2 then
    add(list, { id = "prof", priority = 40, icon = "hammer", title = L["Pick a gathering profession"],
      detail = L["Mining, Herbalism or Skinning pay for your training and mount while you level."] })
  end
  for _, n in ipairs(self:ToolNeeds()) do
    local v = n.vendor
    add(list, { id = "tool-" .. n.prof, priority = 15, icon = "hammer", title = L["Buy a %s"]:format(n.item),
      detail = L["%s only works with a %s in your bags."]:format(L[n.prof] or n.prof, n.item)
        .. (v and (" " .. L["%s sells it (%s)."]:format(v.npc, v.zone)) or ""),
      actionText = v and L["Arrow"] or nil, action = v and function() pointAt(v.zone, v.x, v.y, v.npc) end or nil })
  end
  for name, lv in pairs(profs) do
    if GATHER[name] and lv < math.min(300, level * 5 - 25) then
      -- seviyene uyan toplama bolgesi ve damar / bitki (Guide/ProfGuides.lua), ok oraya
      local PG = ns.ProfGuides
      local spot = PG and PG.BestGatherZone and PG.BestGatherZone(name, level, lv, info.faction)
      local detail = L["Skill %d. Gather on the way to keep up with the zones you quest in."]:format(lv)
      if spot then detail = detail .. "\n" .. L["Best for you now: %s in %s"]:format(table.concat(spot.nodes, ", "), spot.zone) end
      add(list, { id = "skill-" .. name, priority = 45, icon = "hammer", title = L["%s is behind your level"]:format(L[name] or name),
        detail = detail, actionText = spot and L["Arrow"] or nil,
        action = spot and function() pointAt(spot.zone, spot.x * 100, spot.y * 100, spot.zone) end or nil })
    end
  end

  -- 7b) evcilleştirmeye değer nadir pet (hunter, ClassGuide pets `recommend`)
  for _, pet in ipairs(self:PetAdvice(level, info)) do
    add(list, { id = "pet-" .. pet.name, priority = 20, icon = "star", title = L["Rare pet worth taming: %s"]:format(pet.name),
      detail = self:PetLine(pet),
      actionText = L["Arrow"], action = function() pointAt(pet.zone, pet.x, pet.y, pet.name) end })
  end

  -- 7c) kolay ama guclu esyalar (Data/EasyItems.lua, Helpers/EasyItems.lua): en cok 2
  if self.EasyItemAdvice then
    for _, e in ipairs(self:EasyItemAdvice(level, info)) do add(list, e) end
  end

  -- 8) zindan
  if ns.Journal and ns.Journal.ForLevel then
    local ok, ds = pcall(ns.Journal.ForLevel, ns.Journal, level, info)
    local d = ok and ds and ds[1]
    if d then
      add(list, { id = "dungeon-" .. tostring(d.id), priority = 50, icon = "skull", title = L["Dungeon for your level: %s"]:format(ns:LocalizedText(d.name) or d.id),
        detail = L["Good XP and gear. Open the Dungeons page for quests and loot."],
        actionText = L["Dungeons"], action = function() if ns.PathWindow then ns.PathWindow:Open("dungeon") end end })
    end
  end

  -- 8b) gorev odulu yukseltmesi (ItemNeeds:QuestUpgrades): en iyisi, tek satir
  local IN = ns.ItemNeeds
  if IN and IN.QuestUpgrades and IN:IsEnabled() and IN.db.questUps ~= false then
    local ok, ups = pcall(IN.QuestUpgrades, IN, level, info, info.class, 1)
    local u = ok and ups and ups[1]
    if u then
      local canPoint = u.zone and u.x and ns.Zones and ns.Zones:Resolve(u.zone) ~= nil
      add(list, { id = "questup-" .. u.quest, priority = 45, icon = "star",
        title = L["Quest reward upgrade: %s (+%d)"]:format(u.name, math.floor(u.delta + 0.5)),
        detail = (u.link or "") .. "  " .. (u.slotName or "") .. (u.npc and ("\n" .. L["Start: %s"]:format(u.npc .. (u.zone and (", " .. u.zone) or ""))) or ""),
        actionText = canPoint and L["Arrow"] or nil,
        action = canPoint and function() pointAt(u.zone, u.x, u.y, u.npc or u.name) end or nil })
    end
  end

  -- ===== Tek oneri akisi (sahibin istegi, 13 Kasim 2026): baska modullerin onerileri de burada =====
  -- 9) bu bolgede rehberde olmayan, alinabilir gorevler (Brain:GiversNear, rehber disi oneri kurallari)
  local B, zone = ns.Brain, P.ZoneText and P.ZoneText()
  if B and B.IsEnabled and B:IsEnabled() and B.GiversNear and E and E.guide and zone then
    local ok, givers = pcall(B.GiversNear, B, zone, E.guide, info)
    if ok and givers and #givers > 0 then
      local names, near, nd = {}, nil, nil
      for i, g in ipairs(givers) do
        if i <= 3 then names[#names + 1] = g.name end
        local map = ns.Zones and ns.Zones:Resolve(g.zone)
        local d = map and g.x and P.DistanceTo(map, g.x, g.y)
        if d and (not nd or d < nd) then near, nd = g, d end
      end
      add(list, { id = "extra-" .. zone, priority = 35, icon = "exclaim", title = L["Extra quests in %s: %d"]:format(zone, #givers),
        detail = table.concat(names, ", ") .. (#givers > 3 and ", ..." or ""),
        actionText = near and L["Arrow"] or nil,
        action = near and function() pointAt(near.zone, near.x * 100, near.y * 100, near.npc or near.name) end or nil })
    end
  end

  -- 10) en verimli farm bolgen (Helpers/Farm.lua kayitlari)
  local F = ns.Farm
  if F and F.IsEnabled and F:IsEnabled() and F.Stats then
    local best = F:Stats()[1]
    if best and best.goldHour > 0 then
      add(list, { id = "farm-best", priority = 52, icon = "bag", title = L["Your best farm: %s (%s)"]:format(best.zone, L[best.k] or best.k),
        detail = L["%d per hour, %s per hour (%d sessions)"]:format(math.floor(best.perHour + 0.5),
          ns.Suite.FormatMoney(math.floor(best.goldHour)), best.runs),
        actionText = L["Professions"], action = function() if ns.PathWindow then ns.PathWindow:Open("professions") end end })
    end
  end

  -- 11) okunmamis ipucu (bilgi bankasi): en uygun olani
  for _, t in ipairs(self:Tips()) do
    if not self.char.read[t.id] then
      local id = t.id
      add(list, { id = "tip-" .. id, priority = 55, icon = "bubble", title = L["Tip: %s"]:format(ns:LocalizedText(t.title) or "?"),
        detail = ns:LocalizedText(t.text) or "", actionText = L["Got it"], action = function() Mentor:MarkRead(id) end })
      break
    end
  end

  -- 12) acilabilecek ozellik (Discover kurallari; kapali ama isine yarayacak modul)
  local D = ns.Discover
  if D and D.IsEnabled and D:IsEnabled() and D.RULES and D.Eligible then
    for _, rule in ipairs(D.RULES) do
      local ok, yes = pcall(D.Eligible, D, rule)
      if ok and yes then
        local title, body = rule.text()
        add(list, { id = "discover-" .. rule.id, priority = 60, icon = "plus", title = L["Turn on: %s"]:format(title),
          detail = body, actionText = L["Turn on"], action = function() D:Accept(rule) end })
        break
      end
    end
  end

  local out = {}
  for _, e in ipairs(list) do if not self:IsDismissed(e.id) then out[#out + 1] = e end end
  table.sort(out, function(a, b) return a.priority < b.priority end)
  return out
end

-- Bilgi bankasi (Data/MentorTips.lua): seviyene ve sinifina uygun yeni oyuncu bilgileri.
Mentor.CATEGORIES = { "basics", "leveling", "combat", "gear", "gold", "professions", "social", "class" }

local function tipFits(t, level, class)
  if t.class and t.class ~= class then return false end
  return level >= (t.min or 1) - 2 and level <= (t.max or 60)
end

-- cat nil = hepsi. Okunmamislar once, sonra seviye sirasi.
function Mentor:Tips(cat, showAll)
  local level, class = P.PlayerLevel(), P.PlayerClassToken and P.PlayerClassToken()
  local out = {}
  for _, t in ipairs(ns.MentorTips or {}) do
    if (not cat or t.cat == cat) and (showAll or tipFits(t, level, class)) then out[#out + 1] = t end
  end
  local read = self.char.read
  table.sort(out, function(a, b)
    local ra, rb = read[a.id] and 1 or 0, read[b.id] and 1 or 0
    if ra ~= rb then return ra < rb end
    if (a.min or 1) ~= (b.min or 1) then return (a.min or 1) < (b.min or 1) end
    return a.id < b.id
  end)
  return out
end

function Mentor:UnreadCount()
  local n = 0
  for _, t in ipairs(self:Tips()) do if not self.char.read[t.id] then n = n + 1 end end
  return n
end

function Mentor:MarkRead(id, value)
  self.char.read[id] = value ~= false or nil
end

-- Olay tetikli bilgi: ilk kez oldugunda kisa bildirim + sohbet satiri (her bilgi karakter basina bir kez).
function Mentor:Trigger(name, value)
  local level, class = P.PlayerLevel(), P.PlayerClassToken and P.PlayerClassToken()
  for _, t in ipairs(ns.MentorTips or {}) do
    if t.trigger == name and not self.char.shown[t.id] and (not t.class or t.class == class)
      and (name ~= "level" or (value or level) == t.min) then
      -- bildirimler kapaliyken bilgi "gosterildi" sayilmaz: acilinca ilk firsatta gelir
      if self.db.popups then
        self.char.shown[t.id] = true
        local title, text = ns:LocalizedText(t.title), ns:LocalizedText(t.text)
        if ns.Toast then ns.Toast:Show(L["Mentor: %s"]:format(title), "info", nil, nil, { prio = "low", cat = "mentor" }) end
        ns:Print("|cffdb9e33" .. L["Mentor"] .. ":|r " .. (text or ""))
      end
      return t
    end
  end
end

-- Onerilen nadir petler (Data/ClassGuide/Hunter.lua `recommend = { from, to }`, `respawn` dakika): hunter,
-- seviye araliginda, taraf uygun, pet henuz evcillestirilmemis (cagrili pet o adda ise kayda gecer).
function Mentor:PetAdvice(level, info)
  info = info or P.PlayerInfo()
  level = level or P.PlayerLevel()
  if info.class ~= "HUNTER" or not (ns.ClassGuide and ns.ClassGuide.Pets) then return {} end
  local current = P.PetName and P.PetName()
  local out = {}
  for _, p in ipairs(ns.ClassGuide:Pets(nil, info.faction)) do
    local r = p.recommend
    if r and current == p.name then self.char.tamed[p.name] = true end
    if r and level >= (r.from or p.minLevel or 1) and level <= (r.to or 60) and not self.char.tamed[p.name] then
      out[#out + 1] = p
    end
  end
  return out
end

-- Tek satir: aile, seviye, yer, ogrettigi, yeniden dogma suresi, not
function Mentor:PetLine(p)
  local parts = { L["Level %d %s"]:format(p.minLevel or 1, L[p.family] or p.family or "?"),
    ("%s (%d, %d)"):format(p.zone or "?", p.x or 0, p.y or 0) }
  if p.learn and p.learn[1] then parts[#parts + 1] = L["Teaches: %s"]:format(table.concat(p.learn, ", ")) end
  local r = p.respawn
  if type(r) == "table" and r[1] then
    parts[#parts + 1] = L["Respawns every %d-%d hours (older measurements; not timed in Forever yet)."]:format(r[1], r[2] or r[1])
  end
  local text = table.concat(parts, "  -  ")
  local note = p.note and ns:LocalizedText(p.note)
  if note then text = text .. "\n" .. note end
  return text
end

-- Seviyesi gelince (ve bolgesine girince) kisa bildirim + sohbet satiri; pet basina karakterde bir kez
-- (bolge hatirlatmasi oturumda bir kez). zone: yalniz o bolgenin petleri. Doner: bildirilen sayi.
function Mentor:PetAlert(zone)
  if not self.db.popups then return 0 end
  self.zoneAlerted = self.zoneAlerted or {}
  local n = 0
  for _, p in ipairs(self:PetAdvice()) do
    local due
    if zone then due = p.zone == zone and not self.zoneAlerted[p.name]
    else due = not self.char.petAlerted[p.name] end
    if due then
      if zone then self.zoneAlerted[p.name] = true else self.char.petAlerted[p.name] = true end
      if ns.Toast then ns.Toast:Show(L["Mentor: %s"]:format(L["Rare pet worth taming: %s"]:format(p.name)), "info", nil, nil, { cat = "mentor" }) end
      ns:Print("|cffdb9e33" .. L["Mentor"] .. ":|r " .. L["Rare pet worth taming: %s"]:format(p.name) .. " - "
        .. (self:PetLine(p):gsub("\n", " ")))
      n = n + 1
    end
  end
  return n
end

-- Trainer bilgisi (step penceresi bolumu ve bildirim ayni kaynaktan): nil (ogrenecek yok) ya da
-- { spells = metin ya da nil, count, level, trainer = { npc, zone, x, y, mapHint } }.
function Mentor:TrainingInfo(level)
  local info = P.PlayerInfo()
  level = level or P.PlayerLevel()
  local due, spells = self:TrainingDue(level, info.class)
  if not due then return nil end
  return { spells = spells and spellText(spells, 6), count = spells and #spells, level = level,
    trainer = ns.ClassGuide and nearestTrainer(ns.ClassGuide, info, level) }
end

-- Trainer'a ok (step penceresi bolumu acilinca).
function Mentor:PointTrainer(t)
  if t and t.map and ns.Nav then ns.Nav:SetTarget(t.map, t.x / 100, t.y / 100, t.npc, "mentor")
  elseif t then pointAt(t.zone, t.x, t.y, t.npc) end
end

-- Seviye atlayinca ogrenilecek spell varsa kisa bildirim + sohbet satiri (Mentor sayfasi acik olmasa da gorulsun).
function Mentor:TrainAlert(level)
  if not self.db.popups or self.char.alertedAt == level then return false end   -- seviye basina bir kez
  local info = P.PlayerInfo()
  local due, spells = self:TrainingDue(level, info.class)
  if not due then return false end
  local detail = spells and L["%d to learn: %s"]:format(#spells, spellText(spells, 6))
    or L["Visit your class trainer at level %d."]:format(level)
  local t = ns.ClassGuide and nearestTrainer(ns.ClassGuide, info, level)
  if t then detail = detail .. "  " .. L["Trainer: %s, %s"]:format(t.npc, t.mapHint or t.zone) end
  if ns.Toast then ns.Toast:Show(L["Mentor: %s"]:format(L["New spells to train"]), "info", nil, nil, { cat = "mentor" }) end
  ns:Print("|cffdb9e33" .. L["Mentor"] .. ":|r " .. detail)
  self.char.alertedAt = level
  return true
end

local CAPITALS = { ["Stormwind City"] = true, ["Ironforge"] = true, ["Darnassus"] = true, ["Orgrimmar"] = true,
  ["Thunder Bluff"] = true, ["Undercity"] = true }

function Mentor:OnEnable()
  -- meslek egitmeni sinif egitmeni ziyareti sayilmaz (yoksa o seviyenin buyuleri hic soylenmez)
  -- yalniz sinif egitmeni ziyaret sayilir (meslek egitmeni, silah ustasi degil); liste gec dolabilir: UPDATE'te de
  local function visit(o)
    if ns.Training and ns.Training:IsClassTrainerOpen() then o.char.trainedAt = P.PlayerLevel() end
  end
  ns:On("TRAINER_SHOW", self, function(o) visit(o); o:Trigger("trainer") end)
  -- giriste de (seviye atlama /reload oncesi kacirildiysa): biraz sonra, seviye basina bir kez
  P.After(5, function() if Mentor:IsEnabled() then Mentor:TrainAlert(P.PlayerLevel()) end end)
  ns:On("TRAINER_UPDATE", self, visit)
  -- meslek ogrenince (ve giriste) alet kontrolu; ogrenme anindaki liste gec dolabilir
  -- geciktirilen islerde modul arada kapatildiysa calismaz
  ns:On("SKILL_LINES_CHANGED", self, function() P.After(1, function() if Mentor:IsEnabled() then Mentor:ToolAlert() end end) end)
  P.After(6, function() if Mentor:IsEnabled() then Mentor:ToolAlert() end end)
  P.After(8, function() if Mentor:IsEnabled() then Mentor:PetAlert() end end)
  ns:On("UNIT_PET", self, function(o, _, unit) if unit == "player" then o:PetAdvice() end end, "player")   -- evcillestirilince kayda gecer
  ns:On("TAXIMAP_OPENED", self, function(o) o:Trigger("flightmaster") end)
  ns:On("PLAYER_DEAD", self, function(o) o:Trigger("death") end)
  ns:On("PLAYER_UPDATE_RESTING", self, function(o) if IsResting and IsResting() then o:Trigger("inn") end end)
  ns:On("ZONE_CHANGED_NEW_AREA", self, function(o)
    local z = P.ZoneText()
    if z and CAPITALS[z] then o:Trigger("city") end
    if z then o:PetAlert(z) end
  end)
  ns:On("PLAYER_LEVEL_UP", self, function(o, _, lv)
    lv = tonumber(lv) or P.PlayerLevel()
    o:Trigger("level", lv)
    o:TrainAlert(lv)
    o:PetAlert()
    if o.EasyItemAlert then o:EasyItemAlert(lv) end
    if ns.Journal and ns.Journal.ForLevel then
      local ok, ds = pcall(ns.Journal.ForLevel, ns.Journal, lv, P.PlayerInfo())
      if ok and ds and #ds > 0 then o:Trigger("firstdungeonlevel") end
    end
  end)
  ns:On("BAG_UPDATE_DELAYED", self, function(o) if (P.FreeBagSlots and P.FreeBagSlots() or 99) <= 2 then o:Trigger("bagsfull") end end)
  ns:On("UPDATE_INVENTORY_DURABILITY", self, function(o)
    local d = P.LowestDurability and P.LowestDurability()
    if d and d < 0.3 then o:Trigger("lowdura") end
  end)
end

ns:RegisterCommand("mentor", function()
  local list = Mentor:Advice()
  if #list == 0 then ns:Print(L["Mentor: nothing urgent. Keep following your route."]) return end
  for i = 1, math.min(5, #list) do print(("  %d. %s - %s"):format(i, list[i].title, list[i].detail or "")) end
end, "What should I do next? Short advice list")
