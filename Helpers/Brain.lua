-- Arcanis Gorev Beyni (modul "Brain"): rehber adimlarina isaret eden oneriler (hazir teslim, ayni NPC, ayni alan).
-- Rehber sirasini degistirmez; oneri sirasi bir adim boyunca sabit kalir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

-- mode: "suggest" (yalniz oneri, varsayilan) | "full" (adim bitince rotaya sapma ekler)
local Brain = ns:NewModule("Brain", { defaults = { show = true, mode = "full", hubYards = 40, areaYards = 150, max = 3,
  missedAlert = true } })
ns.Brain = Brain

local OBJECTIVE = { complete = true, kill = true, collect = true, use = true }
local HUB = { accept = true, turnin = true, talk = true }
local ACCEPT_WINDOW, AREA_WINDOW = 30, 40
local REFRESH = 1.5     -- saniye; ayni adimda yeniden hesaplama siklik siniri (pencere 1.2 s'de bir sorar)
local DIRTY_MIN = 0.3   -- gorev olayi firtinasinda bundan sik hesaplanmaz
local MISSED_YARDS = 60   -- yd: gecilmis kabulun NPC'si bu kadar yakindaysa hatirlatilir
local TRAVEL_MIN = 1200   -- yard: bundan yakin adim icin yolculuk onerilmez (karar Travel:Plan'da, sureyle)

local function now() return (GetTime and GetTime()) or os.time() end

-- Adimin dunya konumu: kita, wx, wy (ya da nil). Rehber adimi degismez: sonuc adimin kendisinde saklanir.
local function locOf(step)
  if not (step and ns.Zones) then return nil end
  -- hedef/teslim konumu canli (alan secimi, harita isareti): onbelleklenmez
  local live = step.type == "complete" or step.type == "turnin"
  local w = not live and step._world or nil
  if w == nil then
    local map, x, y = ns.Zones:Location(step)
    local c, wx, wy
    if map then c, wx, wy = P.WorldPos(map, x, y) end
    w = c and { c, wx, wy } or false
    if not live then step._world = w end
  end
  if not w then return nil end
  return w[1], w[2], w[3]
end

local function dist(a, b)
  if not (a and b) then return nil end
  return P.WorldDistance(a[1], a[2], a[3], b[1], b[2], b[3])
end

local function pack(c, x, y) if c then return { c, x, y } end end

-- Adimin dunya konumu { kita, x, y } ya da nil (planlayici da kullanir).
function Brain:World(step) return pack(locOf(step)) end

-- Gunlukte, teslime hazir ve henuz teslim edilmemis mi?
local function ready(q)
  return q and P.IsQuestInLog(q) and P.IsQuestComplete(q) and not P.IsQuestFlaggedCompleted(q)
end

-- Onkosul grafigi (Data/Brain/QuestGraph.lua); grafikte olmayan gorevde nil doner.
local function graph() return ns.BrainData and ns.BrainData.graph end
local function doneQ(q) return P.IsQuestFlaggedCompleted(q) end

function Brain:Ready(q) return ready(q) and true or false end

-- q'yu "parent" sayan alt quest'ler (yalniz q gunlukteyken alinabilir). Ters indeks bir kez kurulur.
function Brain:ChildrenOf(q)
  if not self.childIndex then
    local idx = {}
    for c, g in pairs(graph() or {}) do
      if g.parent then idx[g.parent] = idx[g.parent] or {}; table.insert(idx[g.parent], c) end
    end
    self.childIndex = idx
  end
  return self.childIndex[q]
end

-- q'dan sonra gelen quest'ler: zincirde onu kapatan (`nx`) once, sonra onkosulu (any/all) q olanlar.
-- Ters indeks bir kez kurulur. Sira belirli (ID'ye gore).
function Brain:Followers(q)
  if not self.followIndex then
    local idx = {}
    for c, g in pairs(graph() or {}) do
      for _, list in ipairs({ g.any or {}, g.all or {} }) do
        for _, p in ipairs(list) do idx[p] = idx[p] or {}; table.insert(idx[p], c) end
      end
    end
    for _, l in pairs(idx) do table.sort(l) end
    self.followIndex = idx
  end
  local out, seen = {}, {}
  local nx = graph() and graph()[q] and graph()[q].nx
  if nx then out[1] = nx; seen[nx] = true end
  for _, c in ipairs(self.followIndex[q] or {}) do if not seen[c] then out[#out + 1] = c; seen[c] = true end end
  return out
end

-- Teslim yeri tahmini: zincirdeki sonraki quest'i veren NPC genellikle bu quest'in teslim NPC'sidir
-- (Data/Brain givers). Donus: { npc, zone, x, y } (x, y 0-1) ya da nil.
function Brain:TurnInGuess(q)
  local givers = ns.BrainData and ns.BrainData.givers or {}
  for _, f in ipairs(self:Followers(q)) do
    local g = givers[f]
    if g and g[6] and g[7] and g[8] then return { npc = g[6], zone = g[7], x = g[8], y = g[9] } end
  end
  return nil
end

-- Durum sorulari tek yerde: Engine/QuestState.lua (Status / Pre / Closed). CanAccept onun ustune "NPC su an verir
-- mi" kapilarini ekler (onkosul gunlukte ama teslim edilmemis, dislayan gunlukte, parent, kosullu quest bilinmez).
-- true: alinabilir; false: alinamaz; nil: grafik bu gorevi bilmiyor.
function Brain:CanAccept(q)
  local g = graph() and graph()[q]
  if not g then return nil end
  if doneQ(q) or P.IsQuestInLog(q) then return false end
  -- onkosul kosullu quest'te de bakilir (Darkshore 944 <- 948: 12-16'yi atlayan oyuncu Onu'ya bosuna gidiyordu)
  -- NPC quest'i listelediyse (char.offered) verideki onkosul ve seviye engeli yok sayilir
  local offered = ns.QuestState:Offered(q)
  local pre = offered and "met" or ns.QuestState:Pre(q)
  if pre == "missing" then return false end
  -- meslek/itibar/ek esya/buyu/tekrarlanabilir: oyunda dogrulanamaz, eski muhafazakar kapilar gecerli kalsin
  if g.gate then return nil end
  local lvl = P.PlayerLevel() or 1
  if not offered and g.lv and lvl < g.lv then return false end
  if g.maxlv and lvl > g.maxlv then return false end
  if pre ~= "met" then return false end   -- gunlukte / yolda: NPC henuz vermez
  -- dislayan: biri gunlukte ya da bitmisse alinamaz
  for _, x in ipairs(g.ex or {}) do if doneQ(x) or P.IsQuestInLog(x) then return false end end
  if g.bc and (doneQ(g.bc) or P.IsQuestInLog(g.bc)) then return false end        -- yonlendirme: hedef zaten alinmis
  if g.nx and (doneQ(g.nx) or P.IsQuestInLog(g.nx)) then return false end        -- zincirde kapatan gorev etkin
  -- Cataclysm fazlari
  if g.dis and P.IsQuestInLog(g.dis) then return false end                        -- su gorev gunlukteyken kapali
  if g.untilq and doneQ(g.untilq) then return false end                           -- su teslim edilince kaybolur
  if g.startq and not (doneQ(g.startq) or P.IsQuestInLog(g.startq)) then return false end   -- su alininca acilir
  if g.parent and not P.IsQuestInLog(g.parent) then return false end              -- su gorev etkinken acik
  return true
end

-- Zincir degeri: bu gorev bitince (dogrudan ya da 2 adim sonra) acilan gorev sayisi. Ters indeks bir kez kurulur.
function Brain:ChainValue(q)
  local G = graph()
  if not G then return 0 end
  if not self.children then
    local kids = {}
    for id, g in pairs(G) do
      for _, list in ipairs({ g.all or {}, g.any or {} }) do
        for _, p in ipairs(list) do
          kids[p] = kids[p] or {}
          kids[p][#kids[p] + 1] = id
        end
      end
    end
    self.children = kids
  end
  local seen, count = { [q] = true }, 0
  local frontier = { q }
  for _ = 1, 2 do
    local nextLevel = {}
    for _, p in ipairs(frontier) do
      for _, c in ipairs(self.children[p] or {}) do
        if not seen[c] then
          seen[c] = true
          if not doneQ(c) then count = count + 1 end   -- bitmis cocuk "acilacak" sayilmaz
          nextLevel[#nextLevel + 1] = c
        end
      end
    end
    frontier = nextLevel
  end
  return count
end

-- Rehber disi gorev verenler (Data/Brain/QuestGraph.lua "givers"): bolgedeki, bu oyuncuya uygun, gri olmayan ve
-- su anki rehberde gecmeyen gorevler; her biri sahte bir "accept" adimi (konum Zones:Location ile cozulur).
local RACE_BIT = { Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16, Tauren = 32, Gnome = 64, Troll = 128,
  Goblin = 256, BloodElf = 512, Draenei = 1024, Worgen = 2097152 }
local GREY = 5   -- gorev seviyesi oyuncunun bundan fazla altindaysa gri sayilir
-- Rehber disi gorev onerisi kurallari (sahibin istegi, 11 Kasim 2026):
--   gri: gorev seviyesi oyuncudan GREY'den fazla dusuk -> yok
--   kirmizi: gorev seviyesi oyuncu + RED ya da ustu, ya da alma seviyesi oyuncudan yuksek -> yok
--   etkinlik / tekrarli teslim: gorev seviyesi 60 ve alma seviyesi EVENT_REQ'ten dusuk (Classic verisinde
--     etkinlik gorevleri boyle tutulur: Love is in the Air "Dangerous Love" 8903 = 60/1, Darkmoon Faire, Winter Veil,
--     Lunar Festival, Children's Week, savas bagislari, PvP) -> hic onerilmez (veren cogu zaman orada degil)
--   onkosul eksik (Brain:CanAccept false) ya da verilmiyor (char.refused) -> yok
--   veren yerinde yok: noktasinda GIVER_DWELL sn durup goremeyince "verilmiyor" (Brain:GiverMissing)
local RED, EVENT_REQ = 5, 50
function Brain.IsEventQuest(r)
  return r ~= nil and r[2] == 60 and (r[3] or 0) < EVENT_REQ
end
local GIVER_NEAR, GIVER_DWELL = 15, 6   -- yd / sn: verenin yerinde bu kadar durup gorevi goremeyen "verilmiyor" der

local function hasBit(mask, value) return math.floor(mask / value) % 2 == 1 end

-- Veren satirinin (givers) bu oyuncuya sabit uygunlugu: seviye bandi (gri / kirmizi), etkinlik, irk ve sinif.
-- Durum (onkosul, verilmiyor) sorulmaz; harita isaretleri (UI/MapMarkers.lua) de ayni suzgeci kullanir.
-- Rehberlerin bu gorevi aldirdigi en dusuk seviye (rehberin minLevel'i; hicbir rehberde yoksa nil). Veri setindeki
-- alma seviyesi Forever'da bazen dusuk (sahibin bulgusu, 15 Kasim 2026: Alther's Mill 98386 veride 15, rehberde 24,
-- NPC 19'da vermiyor): rehber dışı oneri ve harita "!"i en az bu seviyeyi bekler.
function Brain:GuideLevel(q)
  if not self.guideLevels then
    local t = {}
    for _, g in ipairs(ns.Guides and ns.Guides:List() or {}) do
      for _, s in ipairs(g.steps or {}) do
        if s.type == "accept" and s.quest and (not t[s.quest] or g.minLevel < t[s.quest]) then t[s.quest] = g.minLevel end
      end
    end
    self.guideLevels = t
  end
  return self.guideLevels[q]
end

-- q verilirse rehberlerin aldirdigi seviye de beklenir (Brain:GuideLevel)
function Brain:GiverFits(r, player, q)
  local lvl = player.level or 1
  if (r[2] > 0 and r[2] < lvl - GREY) or r[2] >= lvl + RED or (r[3] or 0) > lvl or Brain.IsEventQuest(r) then
    return false
  end
  local gl = q and self:GuideLevel(q)
  if gl and lvl < gl then return false end
  local rb = RACE_BIT[player.race or ""]
  if rb and r[4] > 0 and not hasBit(r[4], rb) then return false end
  local IN = ns.ItemNeeds
  return not (IN and IN.QuestFits and not IN:QuestFits(r, player))
end

function Brain:GiversNear(zone, guide, player)
  local givers = ns.BrainData and ns.BrainData.givers
  if not (givers and zone and guide) then return {} end
  if not self.giverZones then
    local byZone = {}
    for q, r in pairs(givers) do
      local list = byZone[r[7]] or {}
      byZone[r[7]] = list
      list[#list + 1] = { type = "accept", quest = q, name = r[1], npc = r[6], zone = r[7], x = r[8], y = r[9], info = r }
    end
    self.giverZones = byZone
  end
  if not (self.guideQuests and self.guideQuests.guide == guide) then   -- rota buyuyunce (besleyici adim) yeniden
    local set = { guide = guide }
    for _, s in ipairs(guide.steps) do if s.quest then set[s.quest] = true end end
    self.guideQuests = set
  end
  local out = {}
  local E = ns.Engine
  local off = E and E.char and E.char.refused or {}
  for _, g in ipairs(self.giverZones[zone] or {}) do
    if not self.guideQuests[g.quest] and self:GiverFits(g.info, player, g.quest)
      and not off[g.quest] and self:CanAccept(g.quest) ~= false then
      if not self:GiverMissing(g) then out[#out + 1] = g end
    end
  end
  return out
end

-- Veren yerinde yok: oyuncu verenin noktasinda GIVER_DWELL sn durdu ve gorev gunlukte degil (verenin penceresi
-- acilmadi / NPC orada degil: etkinlik, faz). Kendi kaydina (`char.giverMissing`) yazilir: yalniz rehber disi oneriyi
-- susturur; rehberlerin "verilmiyor" kaydina (refused) dokunmaz (yaninda durmak baska bir rehberin adimini
-- gecirmesin). NPC'nin listesi sonra gorevi gosterirse Engine:NoteOffered siler. Doner: true (artik onerilmez).
function Brain:GiverMissing(g)
  local E = ns.Engine
  if not (E and E.char) or P.IsQuestInLog(g.quest) then return false end
  if E.char.giverMissing and E.char.giverMissing[g.quest] then return true end
  local map, x, y = ns.Zones and ns.Zones:Location(g)
  local d = map and P.DistanceTo(map, x, y)
  self.giverNear = self.giverNear or {}
  if not (d and d <= GIVER_NEAR) then self.giverNear[g.quest] = nil return false end
  local now = P.Now()
  self.giverNear[g.quest] = self.giverNear[g.quest] or now
  if now - self.giverNear[g.quest] < GIVER_DWELL then return false end
  E.char.giverMissing = E.char.giverMissing or {}
  E.char.giverMissing[g.quest] = true
  self.giverNear[g.quest] = nil
  return true
end

-- Olu/hayalet: ceset yolunda konum anlamsiz; ne oneri ne sapma.
local function dead() return P.IsDead() end

-- Saf hesap (onbelleksiz): oneri listesi { kind, index, step, quest, yards, reason }.
function Brain:Compute()
  local E = ns.Engine
  if not (E and E.guide and E.index) then return {} end
  local steps, idx = E.guide.steps, E.index
  local cur = steps[idx]
  if not cur then return {} end
  local player = P.PlayerInfo()
  local anchor = pack(locOf(cur))
  local me = pack(P.PlayerWorldPos())
  if not (anchor or me) then return {} end
  local hub, area = self.db.hubYards or 40, self.db.areaYards or 150
  local skipped = (E.SkippedTurnins and E:SkippedTurnins()) or {}
  local out, used = {}, {}

  local function add(kind, i, s, yards, reason)
    local key = kind .. ":" .. tostring(s.quest or i)
    if used[key] then return end
    used[key] = true
    out[#out + 1] = { kind = kind, index = i, step = s, quest = s.quest, yards = yards, reason = reason }
  end

  -- 1) hazir teslimler (rehberin herhangi bir yerinde), oyuncuya yakin (oyuncu konumu yoksa su anki adima).
  -- Geri gezinirken (cephenin gerisinde) yapilmaz: oyuncu eski bir adima bakiyordur, oradaki konum anlamsiz.
  local browsing = E.Frontier and E:Frontier() and idx < E:Frontier()
  for i, s in ipairs(steps) do
    if not browsing and i ~= idx and s.type == "turnin" and s.quest and not s.optional and not skipped[s.quest]
      and s.quest ~= cur.quest and ready(s.quest) and E:IsVisible(s, player) then
      local loc = pack(locOf(s))
      local d = me and dist(me, loc) or dist(anchor, loc)
      if d and d <= hub then
        add("turnin", i, s, d, L["Ready to turn in, %d yd away: do it now."]:format(math.floor(d + 0.5)))
      end
    end
  end

  -- 2) merkez: ayni NPC'de, rehberin seni uzaklastirip geri getirecegi kabuller
  if HUB[cur.type] and anchor then
    local away, blocked = false, false
    for j = idx + 1, math.min(#steps, idx + ACCEPT_WINDOW) do
      local s = steps[j]
      if E:IsVisible(s, player) then
        local loc = pack(locOf(s))
        local d = dist(anchor, loc)
        local here = d ~= nil and d <= hub
        -- hazir olmayan zorunlu teslim ya da seviye adimi sonrasini kapatir
        if s.type == "turnin" and s.quest and not s.optional and not P.IsQuestFlaggedCompleted(s.quest)
          and not ready(s.quest) then blocked = true end
        if s.type == "level" then blocked = true end
        if loc and not here then away = true end
        if here and away and s.type == "accept" and s.quest and not P.IsQuestInLog(s.quest)
          and not P.IsQuestFlaggedCompleted(s.quest) then
          local can = self:CanAccept(s.quest)
          if can == true or (can == nil and not blocked) then
            add("accept", j, s, d, L["Same place (%d yd): accept now and save a trip back."]:format(math.floor(d + 0.5)))
          end
        end
      end
    end
  end

  -- 2b) rehber disi: oyuncunun yakininda SIMDI alinabilir Forever gorevleri (grafik kesin "alinabilir" demeli)
  if me then
    for _, g in ipairs(self:GiversNear(P.ZoneText(), E.guide, player)) do
      local d = dist(me, pack(locOf(g)))
      local can = self:CanAccept(g.quest)
      -- grafikte satiri yok = onkosulu ve seviye kapisi yok (uretici bos satir yazmaz); gate'li gorev nil kalir
      if can == nil and not (graph() and graph()[g.quest]) then
        can = not doneQ(g.quest) and not P.IsQuestInLog(g.quest)
      end
      if d and d <= hub and can == true then
        add("giver", "g" .. g.quest, g, d, L["Not in the guide, %d yd away: %s gives it now."]:format(math.floor(d + 0.5), g.npc))
      end
    end
  end

  -- 2c) kacirilan kabul: rehberin gecilmis bir kabul adimi, quest gunlukte yok ve rehber ilerde ona ihtiyac duyuyor;
  -- NPC'nin yanindan geciliyorsa hatirlatilir (rota degismez; hedef/teslim adimina gelinince motor kabule ceker)
  if me and not browsing then
    for i = 1, math.min(idx - 1, #steps) do
      local s = steps[i]
      local g = s.type == "accept" and s.quest and graph() and graph()[s.quest]
      -- bekleyen (verilmeyen, esyasi dusmemis, zinciri eksik) ya da artik alinamayan quest "kacirildi" sayilmaz;
      -- oyuncunun bilerek gectigi (skipped) quest hatirlatilir
      local st, why
      if s.type == "accept" and s.quest and not s.optional and not (g and g.gate) then st, why = E:StepStatus(s, player) end
      if (st == "todo" or (st == "gone" and why == "skipped")) and self:CanAccept(s.quest) ~= false then
        local needed = false
        for j = idx, #steps do
          if steps[j].quest == s.quest and steps[j].type ~= "accept" then needed = true break end
        end
        local d = needed and dist(me, pack(locOf(s)))
        if d and d <= MISSED_YARDS then
          add("missed", i, s, d, L["You passed this accept, %d yd away: take it now."]:format(math.floor(d + 0.5)))
        end
      end
    end
  end

  -- 3) alan: su anki hedefle ayni alanda, gunlukteki baska gorevlerin bitmemis hedefleri
  if OBJECTIVE[cur.type] and anchor then
    for j = idx + 1, math.min(#steps, idx + AREA_WINDOW) do
      local s = steps[j]
      if OBJECTIVE[s.type] and s.quest and not s.sticky and s.quest ~= cur.quest and P.IsQuestInLog(s.quest)
        and E:IsStepComplete(s) ~= true and E:IsVisible(s, player) then
        local d = dist(anchor, pack(locOf(s)))
        if d and d <= area then
          add("objective", j, s, d, L["Same area (%d yd): do it while you are here."]:format(math.floor(d + 0.5)))
        end
      end
    end
  end

  -- 3a) sticky: rotanin "yolda yap" dedigi, asil adimina henuz gelinmemis bitmemis hedefler (uzakliktan bagimsiz)
  if E.Sticky then
    for _, e in ipairs(E:Sticky(player)) do
      local loc = pack(locOf(e.step))
      add("objective", e.index, e.step, (me and loc and dist(me, loc)) or 0, L["On the way: do it as you pass by."])
    end
  end

  -- 3b) canli hedef: gunlukteki bitmemis rehber quest'inin harita isareti (oyunun gosterdigi hedef alani)
  -- oyuncuya yakinsa "yolda yap"
  if me and P.QuestMapPos then
    for _, q in ipairs((E.GetTrackedQuests and select(1, E:GetTrackedQuests(25))) or {}) do
      if not q.complete and not q.early and q.id ~= cur.quest then
        local map, x, y = P.QuestMapPos(q.id)
        local d = map and dist(me, pack(P.WorldPos(map, x, y)))
        if d and d <= area then
          add("objective", "o" .. q.id, { type = "complete", quest = q.id, name = q.name }, d,
            L["Same area (%d yd): do it while you are here."]:format(math.floor(d + 0.5)))
        end
      end
    end
  end

  -- 4) Seyahat: siradaki adim cok uzaksa ogrenilmis ocak tasi / ucus noktasi (Travel modulu ogrenir).
  -- Rehber zaten ucus/ocak adimindaysa onerilmez.
  local T = ns.Travel
  local curLoc = pack(locOf(cur))
  -- baska kitadaki adim: mesafe hesaplanamaz ama tam ocak tasi durumudur -> "sonsuz uzak" sayilir
  local far = me and curLoc and (dist(me, curLoc) or math.huge)
  -- Sureye gore plan (Travel:Plan): ocak tasi ve ucus, yurumeden belirgin hizliysa; en hizli once.
  if T and T.Plan and far and far > TRAVEL_MIN and cur.type ~= "fly" and cur.type ~= "hearth" and not P.OnTaxi() then
    local function saved(o)
      return o.saves and L["saves about %d min"]:format(math.max(1, math.floor(o.saves / 60 + 0.5)))
        or L["the step is on another continent"]
    end
    local hearthDone, flyDone
    for _, o in ipairs((T:Plan(curLoc[1], curLoc[2], curLoc[3]))) do
      if (o.kind == "hearth" or o.kind == "hearth_fly" or o.kind == "teleport") and not hearthDone then
        hearthDone = true
        local h = o.place
        if (dist(me, { h.c, h.x, h.y }) or math.huge) > TRAVEL_MIN then
          local reason = o.kind == "teleport" and L["Cast %s: %s."]:format(h.name or "?", saved(o))
            or o.kind == "hearth" and L["Hearth to %s: %s."]:format(h.name or "?", saved(o))
            or L["Hearth to %s, then fly %s to %s: %s."]:format(h.name or "?", o.from.name or "?", o.to.name or "?", saved(o))
          if o.wait and o.wait > 0 then reason = reason .. " " .. ns.Travel.ReadyIn(o.wait) end   -- bekleme suresi plana dahil
          out[#out + 1] = { kind = "hearth", index = idx, step = cur, yards = dist(curLoc, { h.c, h.x, h.y }) or 0,
            place = h.name, reason = reason, teleport = o.kind == "teleport" or nil, spell = o.spell, saves = o.saves }
        end
      elseif o.kind == "fly" and not flyDone then
        flyDone = true
        out[#out + 1] = { kind = "fly", index = idx, step = cur, yards = dist(me, { o.from.c, o.from.x, o.from.y }) or 0,
          node = o.from, dest = o.to, saves = o.saves,
          reason = L["Fly from %s to %s: %s."]:format(o.from.name or "?", o.to.name or "?", saved(o)) }
      end
    end
  end

  local order = { turnin = 1, missed = 2, hearth = 3, fly = 4, objective = 5, accept = 6, giver = 7 }
  for _, s in ipairs(out) do
    s.value = ((s.kind == "accept" or s.kind == "giver" or s.kind == "missed") and s.quest) and self:ChainValue(s.quest) or 0
  end
  table.sort(out, function(a, b)
    if a.kind ~= b.kind then return order[a.kind] < order[b.kind] end
    if a.value ~= b.value then return a.value > b.value end      -- kabullerde onunu daha cok acan once
    return (a.yards or 0) < (b.yards or 0)
  end)
  return out
end

-- Histerezisli oneri listesi (adim penceresi her guncellemede cagirir).
function Brain:Get()
  if not (self:IsEnabled() and self.db.show) or dead() then return {} end
  local E = ns.Engine
  if not (E and E.guide) then return {} end
  local key = E.guide.id .. ":" .. tostring(E.index)
  local c = self.cache
  if c and c.key == key then
    local age = now() - c.at
    -- savasta plan hesaplanmaz (yalniz performans); olay firtinasinda en fazla 0.3 s'de bir
    if P.InLockdown() then return c.list end
    if age < DIRTY_MIN or (not self.dirty and age < REFRESH) then return c.list end
  end
  local fresh = self:Compute()
  local list = {}
  if c and c.key == key then
    -- ayni adim: eski sira korunur (hala gecerli olanlar), yeniler sona
    local freshBy = {}
    for _, f in ipairs(fresh) do freshBy[f.kind .. ":" .. f.index] = f end
    for _, o in ipairs(c.list) do
      local f = freshBy[o.kind .. ":" .. o.index]
      if f then list[#list + 1] = f; freshBy[o.kind .. ":" .. o.index] = nil end
    end
    for _, f in ipairs(fresh) do
      if freshBy[f.kind .. ":" .. f.index] then list[#list + 1] = f end
    end
  else
    list = fresh
  end
  self:AnnounceMissed(fresh)
  local max = self.db.max or 3
  for i = #list, max + 1, -1 do list[i] = nil end
  self.cache = { key = key, list = list, at = now() }
  self.dirty = false
  -- oku bir oneriye cevirdiysek ve o oneri bittiyse ok rehbere geri doner (bayat hedef kalmasin)
  if self.pointed and ns.Nav and ns.Nav.target and ns.Nav.target.source == "brain" then
    local still = false
    for _, s in ipairs(list) do if s.kind .. ":" .. s.index == self.pointed then still = true end end
    if not still then
      self.pointed = nil
      if ns.Nav.OnStepChanged then ns.SafeCall(ns.Nav.OnStepChanged, ns.Nav, nil, nil, nil, E:GetStep()) end
    end
  end
  return list
end

-- Kacirilan kabul ilk gorulunce (oturumda quest basina bir kez) ustteki adada yanip sonen bildirim; tiklayinca ok
-- NPC'ye doner. Ada kapaliysa normal bildirim (Toast).
function Brain:AnnounceMissed(list)
  if self.db.missedAlert == false or not ns.Toast then return end
  self.announced = self.announced or {}
  for _, s in ipairs(list) do
    local dropped = ns.Engine and ns.Engine.DroppedQuests and ns.Engine:DroppedQuests()[s.quest]
    if s.kind == "missed" and s.quest and not dropped and not self.announced[s.quest] then
      self.announced[s.quest] = true
      local name = (s.step and s.step.name) or P.QuestName(s.quest) or "?"
      ns.Toast:Show(L["Missed quest: %s"]:format(name), "info",
        L["%s gives it, %d yd away. Click to point the arrow."]:format(s.step.npc or "?", math.floor((s.yards or 0) + 0.5)),
        function() Brain:Point(s) end, { cat = "quest", flash = true, hold = 8, color = ns.Skin.StatusColors.current })
    end
  end
end

-- Oneri metni: "Teslim et: X", "Kabul et: X", "Hedef: X".
function Brain:Label(s)
  local name = (s.step and s.step.name) or (s.quest and P.QuestName(s.quest)) or "?"
  if s.kind == "turnin" then return L["Turn in: %s"]:format(name) end
  if s.kind == "accept" then return L["Accept: %s"]:format(name) end
  if s.kind == "giver" then return L["Optional quest: %s (%s)"]:format(name, s.step.npc or "?") end
  if s.kind == "missed" then return L["Missed: %s (%s)"]:format(name, s.step.npc or "?") end
  local ic = ns.Nav and ns.Nav.TravelIcon or function() return "" end   -- yolculuk onerisinde ikon
  if s.kind == "hearth" and s.teleport then return ic("teleport", s.spell) .. L["Cast %s"]:format(s.place or "?") end
  if s.kind == "hearth" then return ic("hearth") .. L["Use your hearthstone (%s)"]:format(s.place or "?") end
  if s.kind == "fly" then return ic("fly") .. L["Fly to %s"]:format((s.dest and s.dest.name) or "?") end
  return L["Objective: %s"]:format(name)
end

-- Oku oneriye cevir (rehber adimi degismez).
function Brain:Point(s)
  if not (s and s.step and ns.Nav and ns.Zones) then return false end
  if s.kind == "hearth" then return false end   -- ok yok: ocak tasi kullanilir
  if s.kind == "fly" then                         -- ok yakindaki ucus noktasina
    local n = s.node
    if not (n and n.map and n.mx) then return false end
    ns.Nav:SetTarget(n.map, n.mx, n.my, self:Label(s), "brain")
    self.pointed = s.kind .. ":" .. s.index
    return true
  end
  local map, x, y = ns.Zones:Location(s.step)
  if not map then return false end
  ns.Nav:SetTarget(map, x, y, self:Label(s), "brain", nil, nil, ns.Nav.StepHint and ns.Nav.StepHint(s.step))
  self.pointed = s.kind .. ":" .. s.index
  return true
end

function Brain:MarkDirty() self.dirty = true end

function Brain:OnEnable()
  -- 7 Kasim 2026: rota karari Planner'a gecti, "Reorder the route" varsayilan (kayitli eski varsayilan bir kez cevrilir)
  if not self.db.routeV2 then self.db.mode, self.db.routeV2 = "full", true end
  ns:On("QUEST_LOG_UPDATE", self, "MarkDirty")
  ns:On("UNIT_QUEST_LOG_CHANGED", self, "MarkDirty")
  ns:Listen("ARCANIS_STEP_CHANGED", self, "MarkDirty")
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, function(b) b.cache = nil; b.dirty = true end)
end

ns:RegisterCommand("brain", function()
  local list = Brain:Get()
  if #list == 0 then ns:Print(L["Brain: nothing to combine right now."]) return end
  for i, s in ipairs(list) do
    ns:Print(("%d. %s  |  %s"):format(i, Brain:Label(s), s.reason or ""))
  end
end, "quests the brain suggests doing together right now")
