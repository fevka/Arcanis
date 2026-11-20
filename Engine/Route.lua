-- Arcanis: rota (ns.Route). Bir sekmenin oynadigi adim listesi = rehberin adimlari + besleyici adimlar.
--
-- Besleyici plan: oyuncu onceki rehberi atladiysa bu rehberin bazi quest'leri "onkosul eksik" diye bekler. Eksik
-- zincirin kabul / hedef / teslim adimlari onceki rehberden kopyalanir (`feeder = "<kaynak rehber>"`) ve ona bagli
-- ilk adimin onune girer. Yolculuk adimlari kopyalanmaz (ok ve bolge yolu dogrudan gider).
--
--   Route:Missing(E)            -> eklenebilecek quest'ler (kok once), { unlock = acilan quest sayisi, guide = kaynak }
--   Route:Usable(base, player, q, level) -> zincir quest'i bu rehbere eklenebilir mi (quest durumundan bagimsiz)
--   Route:Make(base, feed)      -> rota: { id, steps, next, ... , base = kayitli rehber, src = { adim no -> asil adim } }
--                                  (feed bossa kayitli rehberin kendisi; kayitli rehber hic degistirilmez)
--   Route.Remap(old, new, i)    -> eski rotadaki adim numarasinin yeni rotadaki karsiligi
--   Route:Earlier(E)            -> bekleyen zincirlerin alindigi onceki rehber, quest sayisi
--
-- Rota yalniz (rehber, char.feed[rehber] listesi, irk / sinif) ile belirlenir; quest durumuna bakmaz. Bu yuzden
-- /reload ayni rotayi kurar ve kayitli adim numaralari (progress, frontier) gecerli kalir. Liste yalniz buyur;
-- buyudugu an (Engine:SetGuide) kayitli numaralar Remap ile tasinir.
local _, ns = ...

local P = ns.Provider
local Guides = ns.Guides
local QS = ns.QuestState

local Route = {}
ns.Route = Route

-- yd: zincirin adimi rehberin gectigi bolgelerin disindaysa rehberin bir adimina en cok bu kadar uzak olabilir.
-- 0 = yalniz ayni bolge (oyunda denendikten sonra genisletilecek).
Route.FEED_REACH = 0
local MAX_PRED = 8   -- `next` ile geriye en cok bu kadar rehber once aranir
local DEPTH = 8
local QUEST_STEP = { accept = true, complete = true, turnin = true, kill = true, collect = true, use = true }

local function graph() return ns.BrainData and ns.BrainData.graph or {} end

-- Irk / sinif suzgeci (seviyeye bagli gorunurluk yok: rota seviye atlayinca degismemeli)
local function fits(s, player)
  if s.classes and not (player.class and s.classes[player.class:upper()]) then return false end
  if s.races and not (player.race and s.races[player.race:lower()]) then return false end
  return true
end

local function prereqs(g)
  return g and ((g.any and #g.any > 0 and g.any) or g.all) or {}
end

-- Kaynak rehberler, oncelik sirasiyla: bu rehbere `next` ile gelenler (en yakin once), sonra ayni tarafin bu
-- rehberin araliginda ya da altinda biten diger rehberleri.
local function sources(base, player)
  local rev = {}
  for _, id in ipairs(Guides.order) do
    local o = Guides.byId[id]
    local n = o and not o.special and (o.next or (ns.GuideChain and ns.GuideChain[id]))
    if n then rev[n] = rev[n] or {}; rev[n][#rev[n] + 1] = o end
    for _, b in ipairs(o and not o.special and o.nextBy or {}) do   -- sinifa / irka bagli devam da bir baglantidir
      rev[b.id] = rev[b.id] or {}; rev[b.id][#rev[b.id] + 1] = o
    end
  end
  local function ok(o) return not o.special and o.faction == base.faction and Guides:IsEligible(o, player) end
  local out, seen, queue, head = {}, { [base.id] = true }, { base }, 1
  while queue[head] and #out < MAX_PRED do
    for _, o in ipairs(rev[queue[head].id] or {}) do
      if not seen[o.id] then
        seen[o.id] = true
        queue[#queue + 1] = o
        if ok(o) and #out < MAX_PRED then out[#out + 1] = o end
      end
    end
    head = head + 1
  end
  for _, id in ipairs(Guides.order) do
    local o = Guides.byId[id]
    if o and not seen[id] and ok(o) and (o.maxLevel or 0) <= (base.maxLevel or 0) then out[#out + 1] = o end
  end
  return out
end

-- Kaynak dizini: quest -> { guide, steps = { kaynak adimlari }, pos = { kaynaktaki siralari }, turnin }.
-- Quest'in kaynagi, kabulu oyuncuya gorunen ilk rehber. Rehber basina bir kez (irk / sinif oturumda degismez).
function Route:Index(base, player)
  local c = self.cache
  if c and c.base == base and c.n == #Guides.order then return c.by end
  local by = {}
  for _, src in ipairs(sources(base, player)) do
    local mine = {}
    for i, s in ipairs(src.steps) do
      local q = s.quest
      if q and QUEST_STEP[s.type] and not s.sticky and not by[q] and fits(s, player) then
        local e = mine[q] or { guide = src, steps = {}, pos = {} }
        mine[q] = e
        e.steps[#e.steps + 1], e.pos[#e.pos + 1] = s, i
        if s.type == "accept" then e.accept = true elseif s.type == "turnin" then e.turnin = true end
      end
    end
    for q, e in pairs(mine) do if e.accept then by[q] = e end end
  end
  self.cache = { base = base, n = #Guides.order, by = by }
  return by
end

-- quest -> ona (ya da onkosul zincirinde ona) bagli ilk rehber adiminin numarasi
local function positions(base, player)
  local pos, walked = {}, {}
  local function up(q, i, depth)
    if not pos[q] then pos[q] = i end
    if depth <= 0 then return end
    for _, p in ipairs(prereqs(graph()[q])) do
      if not pos[p] then up(p, i, depth - 1) end
    end
  end
  for i, s in ipairs(base.steps) do
    if s.quest and not walked[s.quest] and fits(s, player) then
      walked[s.quest] = true
      up(s.quest, i, DEPTH)
    end
  end
  return pos
end

function Route:Make(base, feed, player)
  if base.special or not feed or #feed == 0 then return base end
  player = player or P.PlayerInfo()
  local by, pos = self:Index(base, player), positions(base, player)
  -- ayni yere giren ve ayni rehberden gelen quest'ler tek blok: adimlar kaynak rehberin sirasinda
  local groups, at, any, turnin = {}, {}, false, {}
  for _, s in ipairs(base.steps) do
    if s.type == "turnin" and s.quest and fits(s, player) then turnin[s.quest] = true end
  end
  for _, q in ipairs(feed) do
    local e, p = by[q], pos[q]
    if e and p then
      local key = p .. ":" .. e.guide.id
      local g = groups[key]
      if not g then
        g = { guide = e.guide, items = {} }
        groups[key], any = g, true
        at[p] = at[p] or {}
        at[p][#at[p] + 1] = g
      end
      for k, s in ipairs(e.steps) do
        -- rehber quest'i kendisi teslim ettiriyorsa kaynagin teslimi alinmaz (teslimin yeri rehberin bildigi yer)
        if not (s.type == "turnin" and turnin[q]) then g.items[#g.items + 1] = { s, e.pos[k] } end
      end
    end
  end
  if not any then return base end
  local route = {}
  -- "_" ile baslayan alanlar onbellek (imza, bolge payi): rota kendi degerini hesaplar
  for k, v in pairs(base) do if type(k) ~= "string" or k:sub(1, 1) ~= "_" then route[k] = v end end
  route.questList, route.base, route.fed, route.steps, route.src = nil, base, #feed, {}, {}
  local steps, src = route.steps, route.src
  for i, s in ipairs(base.steps) do
    for _, g in ipairs(at[i] or {}) do
      table.sort(g.items, function(a, b) return a[2] < b[2] end)
      for _, it in ipairs(g.items) do
        local copy = {}
        for k, v in pairs(it[1]) do if type(k) ~= "string" or k:sub(1, 1) ~= "_" then copy[k] = v end end
        copy.feeder = g.guide.id
        steps[#steps + 1], src[#src + 1] = copy, it[1]
      end
    end
    steps[#steps + 1], src[#src + 1] = s, s
  end
  return route
end

function Route.Remap(old, new, i)
  if type(i) ~= "number" or old == new then return i end
  local was = old.src and old.src[i] or old.steps[i]
  if not was then return #new.steps + 1 end   -- rehberin sonu
  for j, s in ipairs(new.steps) do
    if (new.src and new.src[j] or s) == was then return j end
  end
  return i
end

-- q'nun eksik onkosul zinciri `out`a (kok once). Bir halkanin kaynagi yoksa nil.
-- "any" listesinde: biri tamam / gunlukte / rotada ise zincir gerekmez; degilse kaynagi olan ilk alternatif.
local function collect(E, q, by)
  local walk = QS.Walker(function(d)
    local g = graph()[d]
    local function need(p) return not (QS:PreDone(p) or E:InLog(p) or E:Brings(p, d)) end
    local list = {}
    if g and g.any and #g.any > 0 then
      for _, p in ipairs(g.any) do
        if not need(p) then return "all", list end
        if not list[1] and by[p] then list[1] = p end
      end
      return "any", list
    end
    for _, p in ipairs(prereqs(g)) do
      if need(p) then
        if not by[p] then return nil end
        list[#list + 1] = p
      end
    end
    return "all", list
  end, DEPTH - 1)
  if not walk.visit(q) then return nil end
  local out = walk.order
  out[#out] = nil   -- sonuncu q'nun kendisi
  return out
end

-- Adimin ham haritasi ve noktasi (Zones:Location oyun durumuna bakar; burada yalniz rehber verisi)
local function spot(s)
  local m = s.x and (s.map or (s.zone and ns.Zones:Resolve(s.zone)))
  if m then return m, s.x, s.y end
end

local function reachable(base, zones, e)
  for _, s in ipairs(e.steps) do
    local z = s.zone or s.map
    if z and not zones[z] then
      local m, x, y = spot(s)
      local near = false
      if m and Route.FEED_REACH > 0 then
        for _, o in ipairs(base.steps) do
          local m2, x2, y2 = spot(o)
          local d = m2 and P.PointDistance(m, x, y, m2, x2, y2)
          if d and d <= Route.FEED_REACH then near = true break end
        end
      end
      if not near then return false end
    end
  end
  return true
end

-- Zincir quest'i p bu rehbere eklenebilir mi (quest durumundan bagimsiz kisim; sureklilik denetimi de bunu sorar):
-- kaynagi var, teslimi var (kaynakta ya da rehberin kendisinde), seviyesi yetiyor, adimlari rehberin bolgelerinde.
function Route:Usable(base, player, p, level)
  local by, c = self:Index(base, player), self.cache
  if not c.zones then
    c.zones, c.turnin = {}, {}
    for _, s in ipairs(base.steps) do
      if s.zone or s.map then c.zones[s.zone or s.map] = true end
      if s.type == "turnin" and s.quest and fits(s, player) then c.turnin[s.quest] = true end
    end
  end
  local e, g = by[p], graph()[p]
  return e ~= nil and (e.turnin or c.turnin[p] or false) and not (g and g.lv and g.lv > level)
    and reachable(base, c.zones, e)
end

function Route:Missing(E)
  local out, info = {}, { unlock = 0 }
  local base = E.guide and (E.guide.base or E.guide)
  if not base or base.special or not E.db or E.db.feed == false then return out, info end
  local player = P.PlayerInfo()
  local level = player.level or P.PlayerLevel() or 1
  -- bekleyen quest -> koku
  local waits, order = {}, {}
  for _, s in ipairs(E.guide.steps) do
    local d = s.quest
    if d and not s.sticky and not waits[d] then
      local st, why, ref = E:StepStatus(s, player)
      if st == "wait" and why == "pre" then waits[d] = ref or true; order[#order + 1] = d end
    end
  end
  if #order == 0 then return out, info end
  local by, has = self:Index(base, player), {}
  for _, q in ipairs(E:FeedList(base.id)) do has[q] = true end
  local tally = {}
  for _, d in ipairs(order) do
    local chain = collect(E, d, by)
    local ok = chain ~= nil and #chain > 0
    for _, p in ipairs(chain or {}) do
      local st, why = QS:Status(p)
      -- kullanilabilir ve ulasilabilir (Usable), hala alinabilir
      if not self:Usable(base, player, p, level) or st == "never" or (st == "wait" and why ~= "pre") then
        ok = false
        break
      end
    end
    if ok then
      for _, p in ipairs(chain) do
        if not has[p] then
          has[p] = true
          out[#out + 1] = p
          local src = by[p].guide
          tally[src] = (tally[src] or 0) + 1
          if not info.guide or tally[src] > tally[info.guide] then info.guide = src end
        end
      end
    end
  end
  -- acilan quest: koku eklenenlerin icinde olan bekleyen
  local added = {}
  for _, p in ipairs(out) do added[p] = true end
  for _, d in ipairs(order) do
    if added[waits[d]] then info.unlock = info.unlock + 1 end
  end
  return out, info
end

function Route:Earlier(E)
  local base = E.guide and (E.guide.base or E.guide)
  if not base or base.special then return nil end
  local by, tally, best = self:Index(base, P.PlayerInfo()), {}, nil
  for _, w in ipairs((E:Waiting())) do
    local e = w.reason == "pre" and by[w.ref]
    if e then
      tally[e.guide] = (tally[e.guide] or 0) + #w.quests
      if not best or tally[e.guide] > tally[best] then best = e.guide end
    end
  end
  return best, best and tally[best]
end
