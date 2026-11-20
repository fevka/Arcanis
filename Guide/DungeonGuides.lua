-- Arcanis: zindan gorev rehberleri. Zindan gunlugundeki (Data/Dungeons/<id>.lua) gorevler ve onlari acan onkosul
-- zinciri (Data/Brain QuestGraph + QuestFixes) oyuncunun tarafi / irki / sinifina gore sirali adimlara cevrilir ve
-- "dungeon-<zindan>-<taraf>" ozel rehberi olarak kaydedilir (special = true, dungeon = zindan id).
-- Adim konumlari once seviye rehberlerindeki ayni gorevin adimlarindan, yoksa gorev vereni verisinden (givers),
-- yoksa gunluk satirindaki NPC / bolge / koordinattan alinir. Metin yazilmaz: Engine:Describe uretir.
--
-- Sira: zindan ziyaretleri (run) boyunca: once o ziyarete kadar bitmesi gereken onkosul gorevleri dalga dalga
-- (kabul, hedef, teslim), sonra zindan gorevlerinin kabulleri, giris, hedefler, zindanda dusen esyayla baslayan
-- gorevler, teslimler. Baska bir zindan gorevine bagli gorev sonraki ziyarete kalir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local DG = {}
ns.DungeonGuides = DG

DG.MAX_DEPTH = 40   -- onkosul zinciri derinligi (dongu / bozuk veri korumasi)

-- QuestGraph irk maskesi bitleri (Brain ile ayni)
local RACE_BIT = { Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16, Tauren = 32, Gnome = 64, Troll = 128,
  Goblin = 256, BloodElf = 512, Draenei = 1024, Worgen = 2097152 }
local function hasBit(mask, value) return math.floor(mask / value) % 2 == 1 end

function DG.Id(dungeonId, faction)
  return ("dungeon-%s-%s"):format(dungeonId, tostring(faction or "any"):lower())
end

local function data() return ns.BrainData or {} end
local function record(q) return (data().givers or {})[q] or (data().quests or {})[q] end

-- Gorev oyuncuya uygun mu (irk / taraf / sinif maskesi). Kaydi olmayan gorev uygun sayilir.
function DG.Fits(q, player)
  local r = record(q)
  if not r then return true end
  local races = r[4] or 0
  local rb = player.race and RACE_BIT[player.race]
  if races > 0 and rb and not hasBit(races, rb) then return false end
  local IN = ns.ItemNeeds
  if IN and IN.QuestFits and not IN:QuestFits(r, player) then return false end
  return true
end

local function stepFits(s, player)
  if s.races and not (player.race and s.races[player.race:lower()]) then return false end
  if s.classes and not (player.class and s.classes[player.class:upper()]) then return false end
  return true
end

-- Rehber adimindan (Normalize edilmis: 0-1) yeni adim tanimi (0-100). Yalniz yapisal alanlar kopyalanir.
local COPY = { "quest", "name", "npc", "objective", "zone", "map", "radius", "tip", "cave", "npcId", "count", "item" }
local function copyStep(s, kind)
  local o = { type = kind or s.type }
  for _, k in ipairs(COPY) do o[k] = s[k] end
  if s.x and s.y and (s.map or s.zone) then o.x, o.y = s.x * 100, s.y * 100 else o.map, o.zone = nil, nil end
  if s.path and o.x then
    o.path = {}
    for i, p in ipairs(s.path) do o.path[i] = { p[1] * 100, p[2] * 100 } end
  end
  return o
end

-- Seviye rehberlerindeki gorev adimlari: idx[q] = { accept = adim, objectives = { adim, ... }, turnin = adim }.
-- Oyuncuya uygun rehberler ve adimlar; her gorevin ilk kabul / teslimi, hedef adimlari ilk gectigi rehberden.
local OBJ = { complete = true, kill = true, collect = true, use = true }
function DG:Index(player)
  local key = table.concat({ tostring(player.faction), tostring(player.race), tostring(player.class), #ns.Guides.order }, "|")
  if self.index and self.indexKey == key then return self.index end
  local idx = {}
  local list = ns.Guides:List(function(g) return ns.Guides:IsEligible(g, player) end)
  for _, g in ipairs(list) do
    for _, s in ipairs(g.steps) do
      local q = s.quest
      if q and not s.sticky and stepFits(s, player) then
        local e = idx[q]
        if not e then e = { objectives = {} }; idx[q] = e end
        if s.type == "accept" and not e.accept then e.accept = s
        elseif s.type == "turnin" and not e.turnin then e.turnin = s
        elseif OBJ[s.type] and (e.objFrom == nil or e.objFrom == g.id) then
          e.objFrom = g.id
          e.objectives[#e.objectives + 1] = s
        end
      end
    end
  end
  self.index, self.indexKey = idx, key
  return idx
end

-- Gunluk satirindaki veren / teslim metni: "NPC, Yer, Bolge (x, y)" -> npc, bolge, x, y (yalniz yapi).
-- Esyayla baslayan ("Starts from ...") metinde NPC yok.
function DG.ParseNpc(text)
  if type(text) ~= "string" or text == "" or text:match("^%s*Starts from") then return nil end
  local npc = text:match("^%s*([^,(]-)%s*[,(]") or text:match("^%s*(.-)%s*$")
  local zone, x, y = text:match(",%s*([^,]-)%s*%(%s*([%d.]+)%s*,%s*([%d.]+)%s*%)%s*$")
  x, y = tonumber(x), tonumber(y)
  if not (zone and x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100) then zone, x, y = nil, nil, nil end
  return (npc ~= "" and npc or nil), zone, x, y
end

-- Esyayla baslayan gorevler (QuestItems "starts") ters indeksi
local starters
local function startsFromItem(q, jq)
  if not starters then
    starters = {}
    for item, v in pairs(data().items or {}) do if v.starts then starters[v.starts] = item end end
  end
  if starters[q] then return true end
  return jq ~= nil and type(jq.giver) == "string" and jq.giver:match("^%s*Starts from") ~= nil
end

-- Onbellekleri sil (veri degisti: test, yeniden yukleme)
function DG:Reset() self.index, self.indexKey, starters = nil, nil, nil end

-- Onkosul adaylari: "any" listesinden oyuncuya uyanlar (seviye rehberlerinde kabulu olan once) -> "any", liste;
-- "any" yoksa "all" listesinin uyanlari -> "all", liste. Uymayan "all" ogesi taraf/sinif varyantidir, atlanir.
local function prereqs(q, player, idx)
  local g = (data().graph or {})[q]
  if not g then return "all", {} end
  if g.any and #g.any > 0 then
    local first, rest = {}, {}
    for _, p in ipairs(g.any) do
      if DG.Fits(p, player) then
        if idx[p] and idx[p].accept then first[#first + 1] = p else rest[#rest + 1] = p end
      end
    end
    for _, p in ipairs(rest) do first[#first + 1] = p end
    return "any", first
  end
  local out = {}
  for _, p in ipairs(g.all or {}) do if DG.Fits(p, player) then out[#out + 1] = p end end
  return "all", out
end

local function questLevel(q, jq)
  local g = (data().graph or {})[q]
  local r = record(q)
  local lv = (g and g.lv) or (r and r[3]) or (jq and jq.req)
  return type(lv) == "number" and lv >= 1 and lv <= 80 and math.floor(lv) or nil
end

local function questName(q, jq)
  local r = record(q)
  return (jq and jq.name) or (r and r[1]) or nil
end

-- Kabul adimi: rehber adimi > givers > gunluk metni > yalniz gorev
local function acceptStep(q, jq, idx)
  local e = idx[q]
  if e and e.accept then return copyStep(e.accept, "accept") end
  local st = { type = "accept", quest = q, name = questName(q, jq) }
  local r = (data().givers or {})[q]
  if r and r[6] and r[7] and r[8] and r[9] then
    st.npc, st.zone, st.x, st.y = r[6], r[7], r[8] * 100, r[9] * 100
  elseif jq then
    local npc, zone, x, y = DG.ParseNpc(jq.giver)
    st.npc, st.zone, st.x, st.y = npc, zone, x, y
  end
  return st
end

local function turninStep(q, jq, idx)
  local e = idx[q]
  if e and e.turnin then return copyStep(e.turnin, "turnin") end
  local st = { type = "turnin", quest = q, name = questName(q, jq) }
  if jq then
    local npc, zone, x, y = DG.ParseNpc(jq.turnin)
    st.npc, st.zone, st.x, st.y = npc, zone, x, y
  elseif ns.Brain and ns.Brain.TurnInGuess then
    local t = ns.Brain:TurnInGuess(q)
    if t then st.npc, st.zone, st.x, st.y = t.npc, t.zone, t.x * 100, t.y * 100 end
  end
  return st
end

local function objectiveSteps(q, jq, idx)
  local e = idx[q]
  local out = {}
  for _, s in ipairs(e and e.objectives or {}) do
    local o = copyStep(s)
    out[#out + 1] = o
  end
  if #out == 0 then out[1] = { type = "complete", quest = q, name = questName(q, jq) } end
  return out
end

local function byZoneLevel(info)
  return function(a, b)
    local za, zb = info[a].zone or "", info[b].zone or ""
    if za ~= zb then return za < zb end
    local la, lb = info[a].lv or 0, info[b].lv or 0
    if la ~= lb then return la < lb end
    return a < b
  end
end

-- Zindanin oyuncuya gore gorev plani: { targets = { q, ... }, quests = { [q] = bilgi }, runs = n } ya da nil.
function DG:Plan(d, player)
  local J = ns.Journal
  local idx = self:Index(player)
  local T, order, jqs = {}, {}, {}
  for _, jq in ipairs(J and J:Quests(d, player) or {}) do
    if jq.id and not T[jq.id] and DG.Fits(jq.id, player) then
      T[jq.id] = true; jqs[jq.id] = jq; order[#order + 1] = jq.id
    end
  end
  if #order == 0 then return nil end

  -- kapanis: her gorevin secilen onkosullari. Oyuncuya uyan onkosulu olmayan ("any" bos) gorev alinamaz:
  -- kendisi ve ona bagli zindan gorevi rehbere girmez.
  -- (yuruyus ortak: QuestState.Walker; burada adaylar oyuncuya uyan onkosullar)
  local walk = ns.QuestState.Walker(function(q) return prereqs(q, player, idx) end, DG.MAX_DEPTH)
  local deps, seen = walk.deps, walk.seen
  local targets = {}
  for _, q in ipairs(order) do
    if walk.visit(q) then targets[#targets + 1] = q else T[q] = nil end
  end
  if #targets == 0 then return nil end
  order = targets

  -- run(q): kabul edilebilmesi icin onceden bitmesi gereken zindan ziyareti sayisi
  local runOf = {}
  local function run(q)
    if runOf[q] then return runOf[q] end
    local r = 0
    for _, p in ipairs(deps[q]) do r = math.max(r, run(p) + (T[p] and 1 or 0)) end
    runOf[q] = r
    return r
  end
  -- wave(q): ayni ziyaret icindeki onkosul dalgasi (yalniz zindan disi gorevler)
  local waveOf = {}
  local function wave(q)
    if waveOf[q] then return waveOf[q] end
    local w = 0
    for _, p in ipairs(deps[q]) do
      if not T[p] and run(p) == run(q) then w = math.max(w, wave(p) + 1) end
    end
    waveOf[q] = w
    return w
  end

  local info, maxRun = {}, 0
  for q in pairs(seen) do
    local jq = jqs[q]
    local acc = acceptStep(q, jq, idx)
    info[q] = { q = q, jq = jq, target = T[q] or false, run = run(q), wave = (not T[q]) and wave(q) or 0,
      lv = questLevel(q, jq), zone = acc.zone, accept = acc, item = startsFromItem(q, jq) }
    if info[q].run > maxRun then maxRun = info[q].run end
  end
  -- unlocks: bu gorev hangi zindan gorevinin zincirinde (ilk hedef; kendisi hedefse ona bagli sonraki hedef)
  for _, t in ipairs(order) do
    local stack, mark = { t }, { [t] = true }
    while #stack > 0 do
      local q = table.remove(stack)
      for _, p in ipairs(deps[q] or {}) do
        if not mark[p] then
          mark[p] = true
          if info[p] and not info[p].unlocks then info[p].unlocks = t end
          stack[#stack + 1] = p
        end
      end
    end
  end
  return { targets = order, quests = info, runs = maxRun + 1, idx = idx, deps = deps }
end

-- Zindan gorevinin on gorevleri, yapilis sirasiyla (en eskisi once): gunlukte gorevin altinda listelenir.
-- { { q, name, lv, npc, zone, x, y, item, dungeon (baska bir zindan gorevi), done, taken }, ... }
function DG:Prereqs(d, target, player, plan)
  plan = plan or self:Plan(d, player or P.PlayerInfo())
  local out = {}
  if not (plan and plan.deps) then return out end
  local mark = { [target] = true }
  local function visit(q)
    for _, p in ipairs(plan.deps[q] or {}) do
      if not mark[p] then
        mark[p] = true
        visit(p)   -- once onun on gorevleri
        local v = plan.quests[p] or {}
        local a = v.accept or {}
        out[#out + 1] = { q = p, name = DG.QuestName(p), lv = v.lv, npc = a.npc, zone = a.zone, x = a.x, y = a.y,
          item = v.item, dungeon = v.target or false,
          done = P.IsQuestFlaggedCompleted(p) and true or false, taken = P.IsQuestInLog(p) and true or false }
      end
    end
  end
  visit(target)
  return out
end

-- Adimin "unlocks" gorevinin adi (oyunun adi, yoksa veri)
function DG.QuestName(q)
  local fallback = questName(q)
  if not fallback and ns.Journal then
    for _, d in ipairs(ns.DungeonData or {}) do
      for _, jq in ipairs(ns.Journal:Extra(d).quests or {}) do if jq.id == q then fallback = jq.name break end end
      if fallback then break end
    end
  end
  return P.QuestName(q, fallback or ("#" .. q))
end

-- Rehber adimlari (sema bicimi, koordinat 0-100). Gorev yoksa nil.
function DG:Steps(d, player)
  local plan = self:Plan(d, player)
  if not plan then return nil end
  local info, idx = plan.quests, plan.idx
  local steps, lastLevel = {}, 1
  -- her gorev adimi: hangi zindan gorevini actigi (unlocks) ve gunlukteki gorev notu (info)
  local function add(st)
    if not st then return end
    local v = st.quest and info[st.quest]
    if v and st.type ~= "level" and st.type ~= "goto" then
      st.unlocks = v.unlocks
      local note = v.jq and v.jq.note   -- metin ya da { enUS, trTR } tablosu
      if (type(note) == "string" and note ~= "") or type(note) == "table" then st.info = note end
    end
    steps[#steps + 1] = st
  end
  local function levelGate(list)
    local top = 0
    for _, q in ipairs(list) do if (info[q].lv or 0) > top then top = info[q].lv end end
    if top > lastLevel then add({ type = "level", level = top }); lastLevel = top end
  end
  local function sorted(filter)
    local list = {}
    for q, v in pairs(info) do if filter(v) then list[#list + 1] = q end end
    table.sort(list, byZoneLevel(info))
    return list
  end

  for r = 0, plan.runs - 1 do
    -- onkosul gorevleri, dalga dalga
    local maxWave = -1
    for _, v in pairs(info) do if not v.target and v.run == r and v.wave > maxWave then maxWave = v.wave end end
    for w = 0, maxWave do
      local list = sorted(function(v) return not v.target and v.run == r and v.wave == w end)
      local normal = {}
      for _, q in ipairs(list) do if not info[q].item then normal[#normal + 1] = q end end
      levelGate(normal)
      for _, q in ipairs(list) do add(info[q].accept) end
      for _, q in ipairs(list) do for _, o in ipairs(objectiveSteps(q, info[q].jq, idx)) do add(o) end end
      for _, q in ipairs(list) do add(turninStep(q, info[q].jq, idx)) end
    end
    -- zindan gorevleri
    local list = sorted(function(v) return v.target and v.run == r end)
    if #list > 0 then
      local outside, inside = {}, {}
      for _, q in ipairs(list) do
        if info[q].item then inside[#inside + 1] = q else outside[#outside + 1] = q end
      end
      levelGate(outside)
      for _, q in ipairs(outside) do add(info[q].accept) end
      local e = d.entrance
      if e and e.x and e.y and (e.map or e.zone) then
        local path
        if e.path and #e.path > 0 then
          path = {}
          for i, p in ipairs(e.path) do path[i] = { p[1], p[2] } end
        end
        add({ type = "goto", map = e.map, zone = e.zone, x = e.x, y = e.y, radius = 40, path = path })
      end
      for _, q in ipairs(outside) do for _, o in ipairs(objectiveSteps(q, info[q].jq, idx)) do add(o) end end
      for _, q in ipairs(inside) do add(info[q].accept) end
      for _, q in ipairs(inside) do for _, o in ipairs(objectiveSteps(q, info[q].jq, idx)) do add(o) end end
      for _, q in ipairs(list) do add(turninStep(q, info[q].jq, idx)) end
    end
  end
  return steps, plan
end

-- Ozet: { quests, questsDone, chain, chainDone, level, runs, before } ya da nil (karaktere uygun gorev yok).
-- quests: zindan gorevleri; chain: onlari acmak icin once yapilacak gorevler; level: en dusuk zindan gorevi seviyesi.
function DG:Summary(d, player)
  local plan = self:Plan(d, player or P.PlayerInfo())
  if not plan then return nil end
  local s = { quests = 0, questsDone = 0, chain = 0, chainDone = 0, runs = plan.runs, before = {} }
  for q, v in pairs(plan.quests) do
    local done = P.IsQuestFlaggedCompleted(q) and 1 or 0
    -- before[zindan gorevi] = { n, done }: zincirinde ondan once yapilacak gorevler
    if v.unlocks then
      local b = s.before[v.unlocks] or { n = 0, done = 0 }
      s.before[v.unlocks] = b
      b.n, b.done = b.n + 1, b.done + done
    end
    if v.target then
      s.quests, s.questsDone = s.quests + 1, s.questsDone + done
      if v.lv and (not s.level or v.lv < s.level) then s.level = v.lv end
    else
      s.chain, s.chainDone = s.chain + 1, s.chainDone + done
    end
  end
  return s
end

-- Ozetin tek satiri (gunluk ve sohbet)
function DG:SummaryText(s)
  if not s then return nil end
  local text = L["%d dungeon quests (%d done)"]:format(s.quests, s.questsDone)
  if s.chain > 0 then text = text .. "  ·  " .. L["%d quests to unlock them first (%d done)"]:format(s.chain, s.chainDone) end
  if s.level then text = text .. "  ·  " .. L["from level %d"]:format(s.level) end
  if s.runs > 1 then text = text .. "  ·  " .. L["%d dungeon runs"]:format(s.runs) end
  return text
end

-- Rehberi (yeniden) kaydeder; id ya da nil (gorev yok / sema hatasi).
function DG:Register(d, player)
  player = player or P.PlayerInfo()
  if player.faction ~= "Alliance" and player.faction ~= "Horde" then return nil end
  local steps = self:Steps(d, player)
  if not steps or #steps == 0 then return nil end
  local id = DG.Id(d.id, player.faction)
  local G = ns.Guides
  if G.byId[id] then
    G.byId[id] = nil
    for i = #G.order, 1, -1 do if G.order[i] == id then table.remove(G.order, i) end end
  end
  local ok, errs = G:Register({
    id = id, title = L["%s quests"]:format(d.name), faction = player.faction, special = true, dungeon = d.id,
    minLevel = d.minLevel, maxLevel = math.max(d.minLevel, d.maxLevel), steps = steps,
  })
  if not ok then ns:Debug("dungeon guide rejected: " .. table.concat(errs or {}, "; ")) return nil end
  return id
end

-- Kayitli zindan rehberlerini geri yukle (/reload): calisan rehber ve acik sekmelerdeki zindan rehberleri yeniden
-- uretilir (sekme kayitli rehber gelene kadar gizli kalir).
local done
local function restore()
  if done then return end
  local info = P.PlayerInfo()
  if info.faction ~= "Alliance" and info.faction ~= "Horde" then return end
  done = true
  local E = ns.Engine
  if not (E and E.char) then return end
  local ids, seen = {}, {}
  for _, id in ipairs(E.TabList and E:TabList() or {}) do ids[#ids + 1] = id end
  ids[#ids + 1] = E.char.guide   -- calisan rehber en son: geri donus hedefi (next) sekmelerden bulunur
  for _, id in ipairs(ids) do
    local dId = type(id) == "string" and not seen[id] and id:match("^dungeon%-(.+)%-%a+$")
    seen[id or ""] = true
    local d = dId and ns.Journal and ns.Journal:Get(dId)
    if d and not ns.Guides:Get(id) then
      if ns.Journal.BuildGuide then ns.Journal:BuildGuide(d, info) else DG:Register(d, info) end
    end
  end
end
ns:On("PLAYER_LOGIN", "DungeonGuides", restore)
ns:On("NEUTRAL_FACTION_SELECT_RESULT", "DungeonGuides", restore)
