-- Arcanis: rehber kayit defteri.
--
--   ns.Guides:Register{ id=..., title=..., minLevel=1, maxLevel=10, steps={ ... } }
--   ns.Guides:Get(id)  ns.Guides:List()  ns.Guides:Find(player)  ns.Guides:Suggest(player)
--
-- Gecersiz rehberler kaydedilmez; nedenleri ns.Guides.rejected altinda tutulur ve
-- /wf guides errors ile gorulur. Uyarilar (ornegin bilinmeyen alan) rehberi engellemez.
local _, ns = ...

local Schema = ns.GuideSchema
local L = ns.L

local Guides = {
  byId = {},
  order = {},
  rejected = {},   -- id -> { hata, ... }
  warnings = {},   -- id -> { uyari, ... }
}
ns.Guides = Guides

local anonymous = 0

function Guides:Register(def)
  local errors, warnings = Schema.Validate(def)
  local id = type(def) == "table" and type(def.id) == "string" and def.id or nil

  if id and self.byId[id] then
    errors[#errors + 1] = "'" .. id .. "' id is already registered"
  end

  if #errors > 0 then
    if not id then
      anonymous = anonymous + 1
      id = "(adsiz #" .. anonymous .. ")"
    end
    self.rejected[id] = errors
    ns:Debug("guide rejected: " .. id .. " (" .. #errors .. " errors)")
    return false, errors
  end

  local guide = Schema.Normalize(def)
  self.byId[id] = guide
  self.order[#self.order + 1] = id
  self.rejected[id] = nil
  self.warnings[id] = (#warnings > 0) and warnings or nil
  ns:Send("ARCANIS_GUIDE_REGISTERED", id)
  return true, warnings
end

-- Rehberin etkin dildeki basligi (title string ya da dil tablosu olabilir).
function Guides:TitleOf(guide)
  return ns:LocalizedText(guide.title) or guide.id
end

-- Seviye araligi ayrica yazilan listeler icin: adin sonundaki "14-16" atilir ("Darkshore 14-16" -> "Darkshore").
function Guides:ShortTitle(guide)
  local t = self:TitleOf(guide)
  local short = t:gsub("%s+%d+%s*%-%s*%d+%s*$", "")
  return short ~= "" and short or t
end

function Guides:Get(id)
  return self.byId[id]
end

local function byLevelThenId(a, b)
  if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
  if a.maxLevel ~= b.maxLevel then return a.maxLevel < b.maxLevel end
  return a.id < b.id
end

-- Seviye rehberleri (minLevel, maxLevel, id sirasinda). filter(guide) verilirse suzer.
-- Ozel gorev serileri (special) oneri, bolge ve zincir aramasina girmez; withSpecial onlari da katar.
function Guides:List(filter, withSpecial)
  local list = {}
  for _, id in ipairs(self.order) do
    local guide = self.byId[id]
    if (withSpecial or not guide.special) and (not filter or filter(guide)) then list[#list + 1] = guide end
  end
  table.sort(list, byLevelThenId)
  return list
end

function Guides:GetPlayerInfo() return ns.Provider.PlayerInfo() end   -- tum WoW API cagrilari Provider'dan

-- Irk/sinif/taraf uygun mu? (seviye kontrol edilmez)
function Guides:IsEligible(guide, player)
  if guide.faction and guide.faction ~= player.faction then return false end
  if guide.races and not (player.race and guide.races[player.race:lower()]) then return false end
  if guide.classes and not (player.class and guide.classes[player.class:upper()]) then return false end
  return true
end

-- Oyuncunun seviyesini kapsayan ve ona uygun rehberler.
function Guides:Find(player)
  player = player or self:GetPlayerInfo()
  return self:List(function(guide)
    return player.level >= guide.minLevel
      and player.level <= guide.maxLevel
      and self:IsEligible(guide, player)
  end)
end

-- kac irka acik (kisitsiz = cok): irka ozel rehber genel rehberden once gelir (Dwarf 13: Loch Modan, Westfall degil)
-- (rehberin son seviyesinde ozellik sayilmaz: sinirda sonraki araliga gecilir)
local function breadth(guide, level)
  if not guide.races or level >= guide.maxLevel then return 99 end
  local n = 0
  for _ in pairs(guide.races) do n = n + 1 end
  return n
end

local function better(guide, best, level)
  if best and breadth(guide, level) ~= breadth(best, level) then return breadth(guide, level) < breadth(best, level) end
  return not best
    or guide.minLevel > best.minLevel
    or (guide.minLevel == best.minLevel and guide.maxLevel < best.maxLevel)
    or (guide.minLevel == best.minLevel and guide.maxLevel == best.maxLevel and guide.id < best.id)
end

-- Rehberin konumlu adimlarinin bolgelere gore payi: { [bolge] = 0..1 } (rehber basina bir kez hesaplanir).
function Guides:ZoneShare(guide)
  if guide._zoneShare then return guide._zoneShare end
  local count, total = {}, 0
  for _, s in ipairs(guide.steps) do
    if s.zone then count[s.zone] = (count[s.zone] or 0) + 1; total = total + 1 end
  end
  local share = {}
  for z, n in pairs(count) do share[z] = n / math.max(1, total) end
  guide._zoneShare = share
  return share
end

Guides.ZONE_MIN_SHARE = 0.25   -- rehber bir bolgede bu paydan az adim geciriyorsa o bolgenin rehberi sayilmaz
-- baskentler ugrak yeridir (teslim, egitmen): girince bolge rehberi onerilmez
Guides.CITIES = { ["Stormwind City"] = true, ["Ironforge"] = true, ["Darnassus"] = true,
  ["Orgrimmar"] = true, ["Thunder Bluff"] = true, ["Undercity"] = true }

-- Bu bolgede seviyeye uygun rehber: rehberin alt sinirindan en cok bir seviye asagi da olur; en cok bu bolgede
-- gecen secilir (esitlikte Suggest siralamasi). Donus: rehber ve bolgedeki payi, ya da nil.
function Guides:ForZone(zone, player)
  if not zone or zone == "" or self.CITIES[zone] then return nil end
  player = player or self:GetPlayerInfo()
  local best, bestShare
  for _, guide in ipairs(self:List()) do
    if player.level >= guide.minLevel - 1 and player.level <= guide.maxLevel and self:IsEligible(guide, player) then
      local share = self:ZoneShare(guide)[zone] or 0
      if share >= self.ZONE_MIN_SHARE and (not best or share > bestShare
        or (share == bestShare and better(guide, best, player.level))) then
        best, bestShare = guide, share
      end
    end
  end
  return best, bestShare
end

-- Oneri: oyuncunun seviyesini kapsayanlar arasinda once irka en ozel olan, sonra en son girilen aralik
-- (en yuksek minLevel); esitlikte daha dar olan (kucuk maxLevel), sonra id.
-- Irkina ozel baslangic rehberi olmayan oyuncu (ornegin Skyborne) bos kalmaz: irk kisitsiz ilk
-- uygun rehber onerilir ve 'fallback' isaretiyle dondurulur (arayuz kayit onerisini gosterir).
-- Oyuncunun rehber zinciri: irkinin baslangic rehberinden (yoksa en dusuk seviyeli uygun rehberden) `next` boyunca;
-- uygun olmayan (sinif/irk kolu) rehberden zincir devam eder ama listeye girmez.
function Guides:Chain(player)
  player = player or self:GetPlayerInfo()
  local start
  for _, guide in ipairs(self:List()) do
    if guide.races and self:IsEligible(guide, player) and (not start or guide.minLevel < start.minLevel) then start = guide end
  end
  if not start then
    for _, guide in ipairs(self:List()) do
      if self:IsEligible(guide, player) and (not start or guide.minLevel < start.minLevel) then start = guide end
    end
  end
  local out, seen, g = {}, {}, start
  while g and not seen[g.id] do
    seen[g.id] = true
    if self:IsEligible(g, player) then out[#out + 1] = g end
    g = self:GetNext(g, player)
  end
  return out
end

Guides.CHAIN_BEHIND = 0   -- seviye: zincirdeki rehber oyuncunun bu kadar altinda bitiyorsa hala onerilir
-- Zincirdeki ilk bitmemis ve seviyeye uyan rehber. Seviyeye gore "en yuksek minLevel" secimi zincirin bir halkasini
-- atlatiyordu: 16. seviye Human Darkshore 12-16 yerine 16-19'a giriyor, 16-19'un zincirleri 12-16'da kaliyordu.
local function finished(g)
  local E = ns.Engine
  local c = E and E.char or {}
  if c.done and c.done[g.id] then return true end   -- guncelleme adim ekleyip cikarsa da bitmis kalir
  local progress = c.progress or {}
  return (progress[g.id] or 0) > (E and E.StepTotal and E:StepTotal(g) or #g.steps)
end

-- Kanit: bitmemis rehberin quest'lerinden kaci gunlukte ya da bitmis (oyuncu o rehberin icinde demektir).
function Guides:Evidence(guide)
  local P = ns.Provider
  if not (P and P.IsQuestInLog and P.IsQuestFlaggedCompleted) or finished(guide) then return 0 end
  local n, seen = 0, {}
  for _, s in ipairs(guide.steps) do
    local q = s.quest
    if q and not seen[q] then
      seen[q] = true
      if P.IsQuestInLog(q) or P.IsQuestFlaggedCompleted(q) then n = n + 1 end
    end
  end
  return n
end

function Guides:ChainPick(player, excludeId)
  player = player or self:GetPlayerInfo()
  for _, g in ipairs(self:Chain(player)) do
    if g.id ~= excludeId and not finished(g) and player.level >= g.minLevel - 1
      and player.level <= g.maxLevel + self.CHAIN_BEHIND then
      return g
    end
  end
end

function Guides:Suggest(player, excludeId)
  player = player or self:GetPlayerInfo()
  -- aktif rehberin zincirdeki devami seviyeyi kapsiyorsa once o (ayni kita, dogal akis)
  local cur = ns.Engine and ns.Engine.guide
  if cur and cur.id ~= excludeId then
    local n = self:GetNext(cur, player)
    if n and n.id ~= excludeId and self:IsEligible(n, player) and player.level >= n.minLevel - 1 and player.level <= n.maxLevel then
      return n
    end
  end
  local chained = self:ChainPick(player, excludeId)
  if chained then return chained end
  -- zincir bir sey vermedi (zincir disi seviye, zincir bitti): seviyeyi kapsayanlardan quest'leri en cok gunlukte /
  -- bitmis olan, esitlikte eski siralama. Zincir secimine karismaz (ChainPick once doner).
  local best, bestEv
  for _, guide in ipairs(self:Find(player)) do
    if guide.id ~= excludeId then
      local ev = self:Evidence(guide)
      if not best or ev > bestEv or (ev == bestEv and better(guide, best, player.level)) then best, bestEv = guide, ev end
    end
  end
  if best then return best end
  -- irk kodu beklenenden farkliysa (istemci farkli bir kod dondururse): oyuncunun bulundugu bolgede
  -- baslayan irk rehberini oner.
  local zone = ns.Provider and ns.Provider.ZoneText and ns.Provider.ZoneText()
  local map = ns.Provider and ns.Provider.PlayerMapPosition and ns.Provider.PlayerMapPosition()
  if zone or map then
    for _, guide in ipairs(self:List()) do
      local first = guide.races and guide.steps[1]
      if first and player.level <= guide.maxLevel and (not guide.faction or guide.faction == player.faction)
        and ((map and first.map == map) or (zone and first.zone == zone)) then
        return guide, "zone"
      end
    end
  end
  local open = { faction = player.faction, class = player.class, level = player.level }
  local soonest
  for _, guide in ipairs(self:List()) do
    if not guide.races and self:IsEligible(guide, open) and player.level <= guide.maxLevel then
      if player.level >= guide.minLevel then
        if better(guide, best, player.level) then best = guide end
      elseif not soonest or guide.minLevel < soonest.minLevel then
        soonest = guide
      end
    end
  end
  local pick = best or soonest
  return pick, pick ~= nil and "open" or nil
end

-- Irkin kendi baslangic rehberi var mi? Diger irklar icin baslangic rehberi hic yoksa (or. test,
-- ozel paket) soru anlamsizdir ve true doner. Yoksa Kaydedici onerilir.
function Guides:HasRaceStart(player)
  player = player or self:GetPlayerInfo()
  local any = false
  for _, guide in ipairs(self:List()) do
    if guide.races then
      any = true
      if self:IsEligible(guide, player) then return true end
    end
  end
  return not any
end

-- Sonraki rehber: tanimli 'next' yoksa ayni tarafin, bu rehberin bitis seviyesine en yakin
-- baslayan (irk kisitsiz) rehberi; esitlikte id sirasi. Oyuncu bilgisi verilirse uygunluk aranir.
-- `nextBy`: oyuncunun sinifina / irkina uyan ilk satir `next`in onune gecer (oyuncu verilmezse yalniz `next`).
function Guides:GetNext(guide, player)
  if guide.special then return guide.next and self.byId[guide.next] or nil end   -- ozel seri seviye zincirine baglanmaz
  for _, b in ipairs(player and guide.nextBy or {}) do
    if (not b.classes or (player.class and b.classes[player.class:upper()]))
      and (not b.races or (player.race and b.races[player.race:lower()])) then
      return self.byId[b.id]
    end
  end
  if guide.next then return self.byId[guide.next] end
  local chained = ns.GuideChain and ns.GuideChain[guide.id]
  if chained and self.byId[chained] then return self.byId[chained] end
  local best, bestGap
  for _, g in ipairs(self:List()) do
    if g ~= guide and not g.races and g.minLevel > guide.minLevel and g.maxLevel > guide.maxLevel
      and g.minLevel >= guide.maxLevel - 3
      and (not guide.faction or not g.faction or g.faction == guide.faction)
      and (not player or self:IsEligible(g, player)) then
      local gap = math.abs(g.minLevel - guide.maxLevel)
      if not bestGap or gap < bestGap then best, bestGap = g, gap end
    end
  end
  return best
end

-- 'next' baglantilarini denetler: bulunamayan hedefler ve donguler.
function Guides:CheckLinks()
  local problems = {}
  for _, id in ipairs(self.order) do
    local guide = self.byId[id]
    local chained = ns.GuideChain and ns.GuideChain[id]
    if chained and not self.byId[chained] then
      problems[#problems + 1] = id .. ": chain target not found ('" .. chained .. "')"
    end
    if guide.next and not self.byId[guide.next] then
      problems[#problems + 1] = id .. ": 'next' target not found ('" .. guide.next .. "')"
    end
    for _, b in ipairs(guide.nextBy or {}) do
      if not self.byId[b.id] then problems[#problems + 1] = id .. ": 'nextBy' target not found ('" .. b.id .. "')" end
    end
  end
  for _, id in ipairs(self.order) do
    local seen, cursor = {}, self.byId[id]
    while cursor and cursor.next do
      if seen[cursor.id] then
        problems[#problems + 1] = id .. ": loop in 'next' chain"
        break
      end
      seen[cursor.id] = true
      cursor = self.byId[cursor.next]
    end
  end
  return problems
end

local function printList(title, map, limit)
  local ids = {}
  for id in pairs(map) do ids[#ids + 1] = id end
  table.sort(ids)
  if #ids == 0 then return end
  ns:Print(title)
  local shown = 0
  for _, id in ipairs(ids) do
    for _, msg in ipairs(map[id]) do
      shown = shown + 1
      if shown > limit then
        print(L["  ... (more not shown)"])
        return
      end
      print("  |cffffff00" .. id .. "|r: " .. msg)
    end
  end
end

ns:RegisterCommand("guides", function(args)
  args = (args or ""):lower()
  if args == "errors" then
    printList(L["Rejected guides:"], Guides.rejected, 20)
    printList(L["Warnings:"], Guides.warnings, 20)
    return
  elseif args == "check" then
    local problems = Guides:CheckLinks()
    if #problems == 0 then ns:Print(L["guide links are clean"]) end
    for _, p in ipairs(problems) do print("  " .. p) end
    return
  end

  local list = Guides:List()
  ns:Print(L["%d guides registered"]:format(#list))
  for _, g in ipairs(list) do
    print(("  %d-%d  %s  |cff888888(%s%s)|r"):format(
      g.minLevel, g.maxLevel, Guides:TitleOf(g), g.id, g.faction and (", " .. g.faction) or ""))
  end
  local rejected = 0
  for _ in pairs(Guides.rejected) do rejected = rejected + 1 end
  if rejected > 0 then ns:Print(L["%d guides rejected: /wf guides errors"]:format(rejected)) end
end, "[errors|check] list registered guides")
