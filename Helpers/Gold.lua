-- Arcanis: altin takibi (modul "Gold"). Oturum boyunca kazanilan/harcanan altin, saatlik altin, toplanan
-- ganimetler ve degerleri, cantadaki esyalarin toplam degeri. Fiyat: tarama, yoksa paket fiyatlari, yoksa satici.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Gold = ns:NewModule("Gold", { defaults = { track = true, ledger = {}, keepDays = 120, vendor = {}, skillPlan = true,
  deValue = true } })
ns.Gold = Gold

local function money() return (GetMoney and GetMoney()) or 0 end

function Gold:Reset()
  self.start = P.Now()
  self.last = money()
  self.startMoney = self.last
  self.gained, self.spent = 0, 0
  self.loot, self.lootOrder = {}, {}
end

function Gold:OnMoney()
  local m = money()
  local d = m - (self.last or m)
  if d > 0 then self.gained = self.gained + d elseif d < 0 then self.spent = self.spent - d end
  self.last = m
  if d ~= 0 then self:Record(d) end
  self:Touch()
end

-- Defter (kalici): her karakter icin gun gun kaynaga gore gelir/gider.
--   Gold.db.ledger["Realm-Name"] = { class, faction, money, seen, days = { ["2026-10-16"] = { quest = {in,out}, ... } } }
-- Kaynak, para degistigi andaki "baglam"dan gelir: satici penceresi acik -> vendor, posta -> mail,
-- acik artirma -> ah, egitmen -> trainer, ucus haritasi -> taxi, gorev teslimi (3 sn) -> quest,
-- tamir (2 sn) -> repair; baglam yoksa kazanc ganimet (loot), harcama diger (other) sayilir.
Gold.SOURCES = { "loot", "quest", "vendor", "ah", "mail", "trainer", "repair", "taxi", "other" }

local function charKey()
  local name = UnitName and UnitName("player") or "?"
  local realm = GetRealmName and GetRealmName() or "?"
  return realm .. "-" .. name
end

local function dayKey(offset)
  local t = (time and time() or 0) - (offset or 0) * 86400
  return date and date("%Y-%m-%d", t) or "today"
end
Gold.DayKey = dayKey

function Gold:Char(key)
  key = key or charKey()
  local led = self.db.ledger
  local c = led[key]
  if not c then
    c = { days = {} }
    led[key] = c
  end
  return c
end

function Gold:SetContext(name, secs)
  local prev = self.ctx
  if prev and prev.untilT then prev = prev.prev end
  if prev and prev.name == name then prev = prev.prev end   -- ayni bagliamin acik kopyasi kalmasin
  self.ctx = { name = name, untilT = secs and (P.Now() + secs) or nil, prev = secs and prev or nil }
end

function Gold:ClearContext(name)
  local c = self.ctx
  if c and c.untilT and c.prev and (not name or c.prev.name == name) then c.prev = nil return end
  if c and (not name or c.name == name) then self.ctx = nil end
end

function Gold:Context()
  local c = self.ctx
  if not c then return nil end
  if c.untilT and P.Now() > c.untilT then self.ctx = c.prev return self:Context() end
  return c.name
end

function Gold:Record(delta, source)
  local src = source or self:Context() or (delta > 0 and "loot" or "other")
  local c = self:Char()
  local day = dayKey()
  local d = c.days[day]
  if not d then d = {}; c.days[day] = d end
  local e = d[src]
  if not e then e = { 0, 0 }; d[src] = e end
  if delta > 0 then e[1] = e[1] + delta else e[2] = e[2] - delta end
  c.money = money()
end

-- Toplamlar: son n gun (n=1 bugun) icin { [kaynak] = {in,out} }, gelir, gider. key nil ise tum karakterler.
function Gold:Totals(nDays, key)
  local by, income, expense = {}, 0, 0
  local chars = {}
  if key then chars[key] = self.db.ledger[key] else chars = self.db.ledger end
  for i = 0, (nDays or 1) - 1 do
    local day = dayKey(i)
    for _, c in pairs(chars) do
      local d = c and c.days and c.days[day]
      if d then
        for src, e in pairs(d) do
          local b = by[src] or { 0, 0 }
          b[1], b[2] = b[1] + e[1], b[2] + e[2]
          by[src] = b
          income, expense = income + e[1], expense + e[2]
        end
      end
    end
  end
  return by, income, expense
end

-- Gun gun net (en eskiden yeniye): { {day, net}, ... }
function Gold:Daily(nDays, key)
  local out = {}
  for i = (nDays or 14) - 1, 0, -1 do
    local day = dayKey(i)
    local net = 0
    for k, c in pairs(self.db.ledger) do
      if not key or k == key then
        local d = c.days and c.days[day]
        if d then for _, e in pairs(d) do net = net + e[1] - e[2] end end
      end
    end
    out[#out + 1] = { day = day, net = net }
  end
  return out
end

-- Karakterler: { {key, name, realm, class, money, seen, week}, ... } (altina gore)
function Gold:Characters()
  local list, total = {}, 0
  for key, c in pairs(self.db.ledger) do
    local _, wIn, wOut = self:Totals(7, key)
    local realm, name = key:match("^(.-)%-([^%-]+)$")
    list[#list + 1] = { key = key, name = name or key, realm = realm or "", class = c.class, money = c.money or 0,
      seen = c.seen, week = wIn - wOut }
    total = total + (c.money or 0)
  end
  table.sort(list, function(a, b) return a.money > b.money end)
  return list, total
end

function Gold:Prune()
  local keep = self.db.keepDays or 120
  local limit = dayKey(keep)
  for _, c in pairs(self.db.ledger) do
    for day in pairs(c.days or {}) do if day < limit then c.days[day] = nil end end
  end
end

function Gold:TouchChar()
  local c = self:Char()
  local class
  if UnitClass then class = select(2, UnitClass("player")) end   -- "a and f()" ikinci degeri dusurur
  c.class = class or c.class
  c.faction = UnitFactionGroup and UnitFactionGroup("player") or c.faction
  c.money = money()
  c.seen = time and time() or 0
  -- parcalama onerisi icin: bu karakter Enchanting biliyor mu (meslekler yuklenmeden bos tablo gelirse eskisi kalir)
  local profs = P.Professions()
  if next(profs) then c.ench = profs.Enchanting end
end

-- Parcalama (disenchant): beklenen malzemeler ve degeri, Data/Disenchant.lua tablosundan (oyun mekanigi).
-- item: ItemDetails (ilvl, quality, classId, equipLoc). Dondurur: { mats = { { id, count (ortalama), chance } },
-- value (bakir; fiyati bilinmeyen malzeme sayilmaz), priced (hepsinin fiyati var mi), skill } ya da nil.
local NO_DE = { INVTYPE_BODY = true, INVTYPE_TABARD = true, [""] = true }
local QUALITY = { [2] = "uncommon", [3] = "rare", [4] = "epic" }
function Gold:Disenchant(item)
  local D = ns.Disenchant
  local q = item and QUALITY[item.quality]
  if not (D and q and item.ilvl and (item.classId == 2 or item.classId == 4) and not NO_DE[item.equipLoc or ""]) then return nil end
  local il, mats = item.ilvl, nil
  for _, r in ipairs(D[q]) do
    if il >= r[1] and il <= r[2] then
      if q ~= "uncommon" then
        mats = {}
        for _, m in ipairs(r[3]) do mats[#mats + 1] = { id = m[1], count = (m[2] + m[3]) / 2, chance = m[4] } end
      else
        local weapon = item.classId == 2
        local main, side = r[5] and 0.75 or 0.8, 0.2
        mats = { { id = r[3][1], count = (r[3][2] + r[3][3]) / 2, chance = weapon and side or main },
                 { id = r[4][1], count = (r[4][2] + r[4][3]) / 2, chance = weapon and main or side } }
        if r[5] then mats[3] = { id = r[5][1], count = 1, chance = 0.05 } end
      end
      break
    end
  end
  if not mats then return nil end
  local value, priced = 0, true
  for _, m in ipairs(mats) do
    local p = (ns.Prices and ns.Prices:Get(m.id)) or (ns.Suite and ns.Suite:Price(m.id)) or nil
    if p then value = value + p * m.count * m.chance else priced = false end
  end
  local skill = 1
  for _, s in ipairs(D.skill) do if il <= s[1] then skill = s[2] break end end
  return { mats = mats, value = math.floor(value), priced = priced, skill = skill }
end

-- Parcalayabilecek karakter: "me" (bu karakter), bir alt'in adi ya da nil. Enchanting becerisi de doner.
function Gold:Enchanter()
  local mine = P.Professions().Enchanting
  if mine then return "me", mine end
  for key, c in pairs(self.db.ledger or {}) do
    if c.ench then return key:match("%-([^%-]+)$") or key, c.ench end
  end
  return nil
end

-- Oturum ozeti: kazanc, harcama, net, sure (sn), saatlik net (yeterli sure yoksa nil).
function Gold:Summary()
  local secs = P.Now() - (self.start or P.Now())
  local net = (self.gained or 0) - (self.spent or 0)
  local rate = secs >= 60 and (net / secs * 3600) or nil
  return { gained = self.gained or 0, spent = self.spent or 0, net = net, secs = secs, rate = rate }
end

-- Esya degeri: piyasa (Vault / varsayilan) ve satici.
function Gold:ItemValue(id, link)
  local vendor = P.ItemSellPrice(link or id) or 0
  local market = ns.Suite and ns.Suite:Price(id) or nil
  return market, vendor
end

-- Kendi ganimetin: "You receive loot: [Esya]x2." (oyunun kendi kalibindan cozulur, dile bagimsiz).
local function selfPrefix(fmt)
  return fmt and fmt:match("^(.-)%%s")
end
function Gold:OnLoot(_, msg)
  if type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end
  local p1, p2 = selfPrefix(LOOT_ITEM_SELF_MULTIPLE), selfPrefix(LOOT_ITEM_SELF)
  local mine = (p1 and p1 ~= "" and msg:find(p1, 1, true) == 1) or (p2 and p2 ~= "" and msg:find(p2, 1, true) == 1)
  if not mine then return end
  local link = msg:match("(|c%x+|Hitem:.-|h.-|h|r)")
  local id = link and tonumber(link:match("|Hitem:(%d+)"))
  if not id then return end
  local count = tonumber(msg:match("|h|r%s*x(%d+)")) or 1
  local e = self.loot[id]
  if not e then
    e = { id = id, link = link, count = 0 }
    self.loot[id] = e
    table.insert(self.lootOrder, 1, id)
  end
  e.count = e.count + count
  self:Touch()
end

-- Ganimet listesi (en yeni ustte): { {id, link, count, market, vendor}, ... }
function Gold:LootList()
  local out = {}
  for _, id in ipairs(self.lootOrder or {}) do
    local e = self.loot[id]
    local market, vendor = self:ItemValue(e.id, e.link)
    out[#out + 1] = { id = e.id, link = e.link, count = e.count, market = market, vendor = vendor }
  end
  return out
end

-- Canta degeri: toplam satici ve piyasa (piyasa yoksa satici sayilir).
function Gold:BagValue()
  local vendorSum, marketSum = 0, 0
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local it = P.ContainerItem(bag, slot)
      if it and it.id then
        local market, vendor = self:ItemValue(it.id, it.link)
        local n = it.count or 1
        vendorSum = vendorSum + (vendor or 0) * n
        marketSum = marketSum + (market or vendor or 0) * n
      end
    end
  end
  return vendorSum, marketSum
end

-- Kasma rehberi: Data/Farms.lua kayitlari, oyuncunun seviyesi/tarafi/meslegiyle uygunluk ve canli fiyatla
-- tahmini altin/saat. Donus: { {farm, gph, fit, missing}, ... } (uygun olanlar once, sonra altin/saat).
--   fit: "ok" uygun, "level" seviye disi, "prof" meslek eksik/dusuk
function Gold:FarmValue(farm)
  local total, parts = 0, {}
  for _, it in ipairs(farm.items) do
    local market, vendor = self:ItemValue(it[1])
    local each = market or vendor or 0
    total = total + each * it[2]
    parts[#parts + 1] = { id = it[1], perHour = it[2], each = each, priced = market ~= nil }
  end
  return total, parts
end

function Gold:Farms(player, profs)
  player = player or P.PlayerInfo()
  profs = profs or P.Professions()
  local out = {}
  for _, farm in ipairs(ns.FarmData or {}) do
    if not farm.faction or farm.faction == player.faction then
      local gph, parts = self:FarmValue(farm)
      local fit = "ok"
      if farm.prof then
        local have = profs[farm.prof[1]]
        if not have or have < farm.prof[2] then fit = "prof" end
      end
      local lv = player.level or 1
      if fit == "ok" and (lv < farm.min - 2) then fit = "level" end
      if fit == "ok" and lv > farm.max + 10 then fit = "over" end
      out[#out + 1] = { farm = farm, gph = gph, parts = parts, fit = fit, near = lv >= farm.min - 2 and lv <= farm.max + 5 }
    end
  end
  local rank = { ok = 0, prof = 1, over = 2, level = 3 }
  table.sort(out, function(a, b)
    if rank[a.fit] ~= rank[b.fit] then return rank[a.fit] < rank[b.fit] end
    if a.near ~= b.near then return a.near end
    return a.gph > b.gph
  end)
  return out
end

-- Acik artirma danismani: cantadaki satilabilir esyalar, AH ile satici karsilastirmasi ve oneri.
--   action: "ah" (AH'de sat, en az 1.5x ve 20s fark), "vendor" (saticiya), "keep" (fiyat yok/gorev esyasi)
function Gold:SellAdvice()
  local byId, list = {}, {}
  -- takiliyi gecen (baglanmamis) esyalar satilmaz, "sakla" denir
  local upgrade = {}
  if ns.Gear then
    local ok, ups = pcall(ns.Gear.Upgrades, ns.Gear, 200)
    if ok and type(ups) == "table" then
      for _, u in ipairs(ups) do if u.itemId then upgrade[u.itemId] = true end end
    end
  end
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local it = P.ContainerItem(bag, slot)
      if it and it.id and not it.noValue and not it.bound then
        local e = byId[it.id]
        if not e then
          local market, vendor = self:ItemValue(it.id, it.link)
          e = { id = it.id, link = it.link, count = 0, market = market, vendor = vendor or 0, icon = it.icon }
          byId[it.id] = e
          list[#list + 1] = e
        end
        e.count = e.count + (it.count or 1)
        -- en buyuk yigin: Auction House paneli ilani bu yerden koyar
        if (it.count or 1) > (e.stack or 0) then e.bag, e.slot, e.stack = bag, slot, it.count or 1 end
      end
    end
  end
  local ahTotal, vendorTotal = 0, 0
  for _, e in ipairs(list) do
    local m, v = e.market or 0, e.vendor or 0
    if (ns.ItemNeeds and ns.ItemNeeds:Keep(e.id)) or upgrade[e.id] then e.action = "keep"
    elseif m > 0 and m >= v * 1.5 and (m - v) >= 2000 then e.action = "ah"
    elseif v > 0 then e.action = "vendor"
    else e.action = "keep" end
    e.best = math.max(m, v) * e.count
    -- parcalama degeri (Gold:Disenchant); satilacak esyada, ayar aciksa
    if e.action ~= "keep" and self.db.deValue ~= false then
      e.de = self:Disenchant(P.ItemDetails(e.id))
    end
    if e.action == "ah" then ahTotal = ahTotal + m * e.count elseif e.action == "vendor" then vendorTotal = vendorTotal + v * e.count end
  end
  table.sort(list, function(a, b) return a.best > b.best end)
  return list, ahTotal, vendorTotal
end

-- Flip firsatlari: tarama varsa (min, medyan) karsilastirmasi. Yoksa bos.
function Gold:Flips()
  local v = _G.ArcanisVault
  local out = {}
  local scan = v and type(v.GetScanData) == "function" and select(2, pcall(v.GetScanData, v)) or nil
  if type(scan) ~= "table" then
    if ns.Prices and ns.Prices.db then
      local own = ns.Prices:Flips(25)
      return own, next(ns.Prices:Store().items) ~= nil
    end
    return out, false
  end
  for id, e in pairs(scan) do
    if type(e) == "table" and e.min and e.median and (e.count or 0) >= 3 and e.min < e.median * 0.6 then
      out[#out + 1] = { id = id, min = e.min, median = e.median, profit = e.median * 0.95 - e.min }
    end
  end
  table.sort(out, function(a, b) return a.profit > b.profit end)
  return out, true
end

-- Uretim (craft) kari: meslek penceresi acilinca tarifler karakter kaydina yazilir (filtreli pencere gizli
-- tarifleri silmesin diye birlestirilir); kar = urun fiyati x ortalama adet x %95 (AH payi) - malzeme maliyeti.
local AH_CUT = 0.95

function Gold:ScanRecipes()
  local prof, list, rank = P.TradeSkillRecipes()
  if not prof or #list == 0 then return end
  local c = self:Char()
  c.recipes = c.recipes or {}
  local t = c.recipes[prof] or {}
  c.recipes[prof] = t
  for _, r in ipairs(list) do t[r.id] = r end
  c.recipeRank = c.recipeRank or {}
  c.recipeRank[prof] = rank   -- renkler bu becerideydi; beceri artinca eskir
  self:Touch()
end

-- Meslek kasma onerisi: beceri puani veren tarifler, puan basina maliyete gore.
-- shortcut: renk basina sabit tahmini sans (turuncu kesin, sari/yesil yaklasik); oyunun gercek formulu degil.
local SKILL_ODDS = { optimal = 1, medium = 0.6, easy = 0.2 }
Gold.SKILL_ODDS = SKILL_ODDS

-- Toplama meslekleri: becerine gore puan veren dugum ve onu bulunduran bolgeler (Data/ZoneInfo.lua).
-- Renk: dugumun gereken becerisinden +25'e kadar turuncu, +50 sari, +100 yesil, sonra gri (puan yok).
local GATHER = { Herbalism = "herbs", Mining = "ore" }
local RARE = { Silver = true, Gold = true, Truesilver = true, ["Black Lotus"] = true }   -- hedef olarak onerilmez
local function gatherDiff(skill, need)
  local d = skill - need
  return (d < 25 and "optimal") or (d < 50 and "medium") or (d < 100 and "easy") or nil
end
-- Skinning: yaratigin seviyesi icin gereken beceri (10'a kadar 1, 20'ye kadar (sv-10)*10, sonra sv*5) ve tersi
local function skinNeed(lv) return lv <= 10 and 1 or lv <= 20 and (lv - 10) * 10 or lv * 5 end
local function skinLevel(skill)
  if skill >= 100 then return math.floor(skill / 5) end
  return math.max(10, math.floor(skill / 10) + 10)
end

-- Seviyesine en uygun bolgeler once (seviye araligindaysa, sonra araligin ortasina yakinlik), en cok n tane.
local function zonesFor(match, level, n)
  local out = {}
  for name, z in pairs(ns.ZoneInfoData or {}) do if match(z) then out[#out + 1] = { name = name, z = z } end end
  local function fit(e) return (level >= e.z.min - 2 and level <= e.z.max + 5) and 0 or 1 end
  table.sort(out, function(a, b)
    if fit(a) ~= fit(b) then return fit(a) < fit(b) end
    local da, db = math.abs((a.z.min + a.z.max) / 2 - level), math.abs((b.z.min + b.z.max) / 2 - level)
    if da ~= db then return da < db end
    return a.name < b.name
  end)
  local names = {}
  for i = 1, math.min(n or 3, #out) do names[i] = out[i].name end
  return names
end

-- Donus: { {prof, rank, rows = { {node, need, diff, zones} | {mobs = {lo, hi}, diff, zones} }, next = {node, need}}, ... }
function Gold:GatherAdvice(profs, level)
  profs = profs or P.Professions()
  level = level or P.PlayerLevel() or 1
  local skills = ns.GatherSkill or {}
  local out = {}
  for prof, kind in pairs(GATHER) do
    local skill = profs[prof]
    if skill then
      local rows, nextNode = {}, nil
      local nodes = {}
      for node, need in pairs(skills[kind] or {}) do if not RARE[node] then nodes[#nodes + 1] = { node, need } end end
      table.sort(nodes, function(a, b) return a[2] > b[2] or (a[2] == b[2] and a[1] < b[1]) end)
      for _, nd in ipairs(nodes) do
        local diff = nd[2] <= skill and gatherDiff(skill, nd[2])
        if diff and #rows < 2 then
          local node = nd[1]
          rows[#rows + 1] = { node = node, need = nd[2], diff = diff, zones = zonesFor(function(z)
            for _, x in ipairs(z[kind] or {}) do if x == node then return true end end
          end, level) }
        elseif nd[2] > skill then
          nextNode = { node = nd[1], need = nd[2] }
        end
      end
      out[#out + 1] = { prof = prof, rank = skill, rows = rows, next = nextNode }
    end
  end
  local skin = profs.Skinning
  if skin then
    local hi = skinLevel(skin)
    local lo = hi
    while lo > 1 and gatherDiff(skin, skinNeed(lo - 1)) do lo = lo - 1 end   -- puan veren en dusuk seviye
    local top = math.max(lo, hi - 3)   -- en iyi puan: turuncu/sari, en ust seviyeler
    out[#out + 1] = { prof = "Skinning", rank = skin, rows = {
      { mobs = { top, hi }, diff = gatherDiff(skin, skinNeed(top)) or "easy",
        zones = zonesFor(function(z) return z.min <= hi and z.max >= top end, level) },
    }, next = nil, low = lo }
  end
  table.sort(out, function(a, b) return a.prof < b.prof end)
  return out
end

-- Donus: { {prof, rank, stale, list ={ {id, name, diff, odds, cost, missing, can, perPoint}, ... }}, ... }
-- list: elindeki malzemeyle yapilabilenler once (sansi yuksek olan), sonra puan basina en ucuz; fiyatsizlar sonda.
-- stale: beceri tarifler okunduktan sonra artti (renkler eski; pencereyi yeniden ac).
function Gold:SkillUps(key, ranks)
  local c = self:Char(key)
  ranks = ranks or P.Professions()
  local price = function(id) return ns.Suite and ns.Suite:Price(id) or nil end
  local out = {}
  for prof, t in pairs(c.recipes or {}) do
    local list = {}
    for id, r in pairs(t) do
      local odds = SKILL_ODDS[r.diff]
      if odds then
        local cost, missing, can = 0, 0, nil
        for _, g in ipairs(r.reagents or {}) do
          local p = price(g.id)
          if p then cost = cost + p * g.count else missing = missing + 1 end
          local n = math.floor((P.ItemCount(g.id) or 0) / g.count)
          can = can and math.min(can, n) or n
        end
        list[#list + 1] = { id = id, name = r.name, diff = r.diff, odds = odds, cost = cost, missing = missing,
          can = can or 0, perPoint = missing == 0 and math.floor(cost / odds) or nil }
      end
    end
    table.sort(list, function(a, b)
      if (a.can > 0) ~= (b.can > 0) then return a.can > 0 end
      if a.can > 0 and a.odds ~= b.odds then return a.odds > b.odds end
      if (a.perPoint ~= nil) ~= (b.perPoint ~= nil) then return a.perPoint ~= nil end
      if a.perPoint and a.perPoint ~= b.perPoint then return a.perPoint < b.perPoint end
      if a.odds ~= b.odds then return a.odds > b.odds end
      return tostring(a.name) < tostring(b.name)
    end)
    local rank = c.recipeRank and c.recipeRank[prof]
    local now = ranks[prof]
    out[#out + 1] = { prof = prof, rank = rank, stale = (rank and now and now > rank) and true or false, list = list }
  end
  table.sort(out, function(a, b) return tostring(a.prof) < tostring(b.prof) end)
  return out
end

-- ===== Kasma plani: "becerini N'e cikar" =====
-- Bilinen tarifler (meslek penceresinden) + istemcinin renk esikleri (Data/RecipeSkill.lua: urun -> { sari, gri }).
-- Her beceri puaninda puan basina beklenen maliyeti en dusuk tarif secilir; cantadaki malzeme bedava sayilir (azalir).
-- Puan sansi (Classic formulu): turuncu 1, sonra (gri - beceri) / (gri - sari); gri 0. Beklenen uretim sayisina
-- PLAN_MARGIN kadar basarisizlik payi eklenir. Fiyat: saticida gorulen fiyat (db.vendor) ile muzayede fiyatinin ucuzu.
Gold.PLAN_MARGIN = 0.15

function Gold.SkillChance(yellow, grey, skill)
  if skill >= grey then return 0 end
  if skill < yellow then return 1 end
  return (grey - skill) / (grey - yellow)
end

-- Malzemenin tane fiyati ve kaynagi ("vendor" / "ah") ya da nil.
function Gold:BuyPrice(id)
  local v = self.db.vendor and self.db.vendor[id]
  local a = ns.Suite and ns.Suite:Price(id) or nil
  if v and (not a or v <= a) then return v, "vendor" end
  if a then return a, "ah" end
  return nil
end

-- Saticinin sinirsiz esyalarinin fiyatlari (MERCHANT_SHOW): kasma planinin "saticidan al" kaynagi.
function Gold:ScanMerchant()
  self.db.vendor = self.db.vendor or {}
  for _, it in ipairs(P.MerchantItems()) do self.db.vendor[it.id] = it.price end
end

-- Donus: nil (tarif yok) ya da { prof, from, to, steps = { {id, name, from, to, crafts} }, shopping = { {id, count,
-- price, source} }, cost, gap (plan bulunamayan puan sayisi) }. rank: simdiki beceri (yoksa oyundan).
function Gold:SkillUpPlan(prof, target, key, rank)
  local recipes = (self:Char(key).recipes or {})[prof]
  local thresholds = ns.RecipeSkill or {}
  rank = rank or P.Professions()[prof]
  if not (recipes and rank and target and target > rank) then return nil end
  local have = setmetatable({}, { __index = function(t, id) local n = P.ItemCount(id) or 0; rawset(t, id, n); return n end })
  local steps, gap = {}, 0
  for s = rank, target - 1 do
    local best
    for id, r in pairs(recipes) do
      local th = thresholds[id]
      local ch = th and Gold.SkillChance(th[1], th[2], s) or 0
      if ch > 0 then
        local cost, ok = 0, true
        for _, g in ipairs(r.reagents or {}) do
          local missing = math.max(0, g.count - have[g.id])
          if missing > 0 then
            local p = self:BuyPrice(g.id)
            if not p then ok = false break end
            cost = cost + missing * p
          end
        end
        local per = ok and cost / ch
        if per and (not best or per < best.per or (per == best.per and ch > best.ch)) then
          best = { id = id, r = r, ch = ch, per = per }
        end
      end
    end
    if best then
      local crafts = (1 / best.ch) * (1 + Gold.PLAN_MARGIN)
      for _, g in ipairs(best.r.reagents or {}) do have[g.id] = math.max(0, have[g.id] - g.count * crafts) end
      local last = steps[#steps]
      if last and last.id == best.id and last.to == s then
        last.to, last.crafts = s + 1, last.crafts + crafts
      else
        steps[#steps + 1] = { id = best.id, name = best.r.name, from = s, to = s + 1, crafts = crafts }
      end
    else
      gap = gap + 1
    end
  end
  -- yuvarla, sonra alisveris listesi: adimlarin malzemesi - cantadaki
  local need = {}
  for _, st in ipairs(steps) do
    st.crafts = math.ceil(st.crafts - 1e-9)
    for _, g in ipairs(recipes[st.id].reagents or {}) do need[g.id] = (need[g.id] or 0) + g.count * st.crafts end
  end
  local shopping, total = {}, 0
  for id, n in pairs(need) do
    local buy = n - (P.ItemCount(id) or 0)
    if buy > 0 then
      local p, src = self:BuyPrice(id)
      shopping[#shopping + 1] = { id = id, count = buy, price = p, source = src }
      total = total + (p or 0) * buy
    end
  end
  table.sort(shopping, function(a, b) return (a.price or 0) * a.count > (b.price or 0) * b.count end)
  return { prof = prof, from = rank, to = target, steps = steps, shopping = shopping, cost = total, gap = gap }
end

-- Donus: { {id, prof, name, diff, made, value, cost, profit, missing}, ... } karli ve fiyati tam olanlar once.
-- value: tek urunun fiyati (nil = bilinmiyor); missing: fiyati bilinmeyen malzeme sayisi (profit o zaman nil).
function Gold:CraftProfits(key)
  local out = {}
  local price = function(id) return ns.Suite and ns.Suite:Price(id) or nil end
  for prof, t in pairs(self:Char(key).recipes or {}) do
    for id, r in pairs(t) do
      local cost, missing = 0, 0
      for _, g in ipairs(r.reagents or {}) do
        local p = price(g.id)
        if p then cost = cost + p * g.count else missing = missing + 1 end
      end
      local value = price(id)
      local profit = (value and missing == 0) and math.floor(value * (r.made or 1) * AH_CUT - cost) or nil
      out[#out + 1] = { id = id, prof = prof, name = r.name, diff = r.diff, made = r.made or 1, value = value,
        cost = cost, profit = profit, missing = missing }
    end
  end
  table.sort(out, function(a, b)
    if (a.profit ~= nil) ~= (b.profit ~= nil) then return a.profit ~= nil end
    if a.profit and a.profit ~= b.profit then return a.profit > b.profit end
    return tostring(a.name) < tostring(b.name)
  end)
  return out
end

function Gold:Touch()
  local now = P.Now()
  if self.touchedAt and now - self.touchedAt < 1 then return end
  self.touchedAt = now
  local W = ns.PathWindow
  if W and W:IsOpen() and W.db.page == "gold" then ns.SafeCall(W.Refresh, W) end
end

local OPEN_CLOSE = {
  MERCHANT_SHOW = { "vendor" }, MERCHANT_CLOSED = { "vendor", true },
  MAIL_SHOW = { "mail" }, MAIL_CLOSED = { "mail", true },
  AUCTION_HOUSE_SHOW = { "ah" }, AUCTION_HOUSE_CLOSED = { "ah", true },
  TRAINER_SHOW = { "trainer" }, TRAINER_CLOSED = { "trainer", true },
  TAXIMAP_OPENED = { "taxi" }, TAXIMAP_CLOSED = { "taxi", 2 },
}

function Gold:OnEnable()
  self:Reset()
  self:TouchChar()
  self:Prune()
  ns:On("PLAYER_MONEY", self, "OnMoney")
  ns:On("CHAT_MSG_LOOT", self, "OnLoot")
  for ev, spec in pairs(OPEN_CLOSE) do
    ns:On(ev, self, function(o)
      if spec[2] == true then o:ClearContext(spec[1])
      elseif spec[2] then o:SetContext(spec[1], spec[2])   -- ucus ucreti kapanistan hemen sonra dusebilir
      else o:SetContext(spec[1]) end
    end)
  end
  ns:On("QUEST_COMPLETE", self, function(o) o:SetContext("quest") end)
  ns:On("QUEST_FINISHED", self, function(o) if o.ctx and o.ctx.name == "quest" then o:SetContext("quest", 3) end end)
  ns:On("QUEST_TURNED_IN", self, function(o) o:SetContext("quest", 3) end)
  ns:On("PLAYER_LOGOUT", self, "TouchChar")
  ns:On("TRADE_SKILL_SHOW", self, "ScanRecipes")
  ns:On("TRADE_SKILL_UPDATE", self, "ScanRecipes")        -- Classic adi
  ns:On("TRADE_SKILL_LIST_UPDATE", self, "ScanRecipes")   -- Forever (yeni istemci) adi
  -- MERCHANT_SHOW'un self sahipli dinleyicisi baglam icin (OPEN_CLOSE): fiyatlar ayri sahiple
  ns:On("MERCHANT_SHOW", "GoldVendorPrices", function() if Gold:IsEnabled() then Gold:ScanMerchant() end end)
  ns:Listen("ARCANIS_PRICES_CHANGED", self, function(o) o.touchedAt = nil; o:Touch() end)
  if hooksecurefunc and RepairAllItems and not self.repairHooked then
    self.repairHooked = true
    hooksecurefunc("RepairAllItems", function() Gold:SetContext("repair", 2) end)
  end
end

ns:RegisterCommand("gold", function(args)
  if (args or ""):lower():match("reset") then Gold:Reset() ns:Print(L["Gold session reset."]) return end
  local s = Gold:Summary()
  local F = ns.Suite.FormatMoney
  ns:Print(L["Session: +%s / -%s (net %s)"]:format(F(s.gained), F(s.spent), F(s.net)))
  if s.rate then ns:Print(L["%s per hour"]:format(F(s.rate))) end
end, "[reset] gold this session and gold per hour")
