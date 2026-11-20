-- Arcanis: adim motoru (modul "Engine").
--
-- Aktif rehber ve adimi tutar, oyun durumundan adimin bittigini algilar ve ilerler.
--   ns.Engine:SetGuide(id [, index])   ns.Engine:Next()   ns.Engine:Prev()
--   ns.Engine:GetStep()   ns.Engine:Evaluate()   ns.Engine:Describe(step)
--   ns.Engine:CurrentIndex()   ns.Engine:JumpToCurrent()   ns.Engine:IsStepDone(step)
--   ns.Engine:StepStatus(step) -> done / todo / manual / na / wait / gone, neden, ref
--   ns.Engine:Waiting()   ns.Engine:IsBlocked()
--
-- Mesajlar: ARCANIS_GUIDE_CHANGED(id), ARCANIS_STEP_CHANGED(id, index, step),
--           ARCANIS_GUIDE_FINISHED(id, nextGuide), ARCANIS_GUIDE_BLOCKED(id) (sona gelindi, bekleyen quest var)
local _, ns = ...

local P = ns.Provider
local Guides = ns.Guides
local L = ns.L

local Engine = ns:NewModule("Engine", { defaults = { skipGray = true, skipDiff = 8, pinOrder = false, strict = true, feed = true, campReminder = true, campSit = true, classQuests = true, dungeonSteps = false, groupSteps = false }, charDefaults = { index = 1, progress = {} } })
ns.Engine = Engine

Engine.guide = nil
Engine.index = 1
Engine.finished = false
Engine.dirty = false
Engine.acc = 0

local TICK = 0.5          -- saniye; olaylar ve konum kontrolu bu aralikla degerlendirilir
local DEFAULT_RADIUS = 20 -- yard; goto adimi icin varsayilan varis mesafesi

-- Konusma adiminin NPC'si (dunya konumu) bu noktaya yakin mi? (ocak tasi kaydi, bilinen ucus noktasi)
local NEAR = 150   -- yard; han / ucus ustasi ile kayitli nokta arasi
local function nearStep(s, c, wx, wy)
  local map, x, y = ns.Zones:Location(s)
  local sc, sx, sy
  if map then sc, sx, sy = P.WorldPos(map, x, y) end
  return sc ~= nil and sc == c and wx ~= nil and (sx - wx) ^ 2 + (sy - wy) ^ 2 <= NEAR * NEAR
end

-- "Set your hearthstone here": ocak tasi bu hana bagli (Travel kaydi) ya da bagli yer rehberin sonraki
-- hearth hedefi (addon kurulmadan once baglanmis olabilir).
local function homeSet(s)
  local T = ns.Travel
  local h = T and T.Hearth and T:Hearth()
  if h and h.c and nearStep(s, h.c, h.x, h.y) then return true end
  if s._bindTo == nil then
    local steps, seen = Engine.guide and Engine.guide.steps or {}, false
    for _, o in ipairs(steps) do
      if o == s then seen = true elseif seen and o.type == "hearth" then s._bindTo = o.to or false break end
    end
    if seen and s._bindTo == nil then s._bindTo = false end
  end
  local bind = P.BindLocation()
  return bind ~= nil and s._bindTo == bind
end

-- "Get the flight path": bu NPC'nin yanindaki ucus noktasi biliniyor (Travel ucus haritasindan ogrenir).
local function flightKnown(s)
  local T = ns.Travel
  for _, n in ipairs(T and T.KnownNodes and T:KnownNodes() or {}) do
    if n.c and nearStep(s, n.c, n.x, n.y) then return true end
  end
  return false
end

local function objectiveDone(step)
  local q = step.quest
  if P.IsQuestFlaggedCompleted(q) or P.IsQuestComplete(q) then return true end
  if not Engine:InLog(q) then return false end
  local objectives = P.GetObjectives(q)
  if not objectives or #objectives == 0 then return false end
  if step.objective then
    local o = objectives[step.objective]
    return o ~= nil and o.finished == true
  end
  for _, o in ipairs(objectives) do
    if not o.finished then return false end
  end
  return true
end

-- Hedefsiz yolculuk quest'i ("gemiyle Dalaran'a git, orada konus"): oyun kabul edilir edilmez "tamam" der, rehberin
-- hedef adimi (iskele) ise gidilecek yer ve gemi bekleme noktasidir. Adim oyuncu o kitadan ayrilinca biter
-- (iskeleye varmak yetmez: gemi gelene kadar "burada bekle" kalir; teslimin oku da iskeleyi gosterirdi).
-- Gemi yolculugu sayilmasi icin teslim adimi baska kitada olmali: ayni kitadaki "git, konus" quest'i (hedefsiz,
-- koordinatli hedef adimi) yolculuk degildir. Sonuc adimda saklanir (rehber verisi degismez).
local function crossesContinent(self, s)
  if s._cross == nil then
    local t
    for _, o in ipairs(self.guide and self.guide.steps or {}) do
      if o.type == "turnin" and o.quest == s.quest then t = o break end
    end
    -- rehberin kendi noktasi (Zones:Location yolculuk adimini sorar: dongu olurdu)
    local function cont(o)
      local m = o and o.x and (o.map or (o.zone and ns.Zones:Resolve(o.zone)))
      return m and P.WorldPos(m, o.x, o.y)
    end
    local c1, c2 = cont(s), cont(t)
    if c1 == nil or c2 == nil then return true end   -- olculemedi: eski davranis (yolculuk), kayit yok, sonra yeniden
    s._cross = c1 ~= c2
  end
  return s._cross
end

function Engine:TravelObjective(s)
  if s.type ~= "complete" or not s.quest or s.x == nil or not self:InLog(s.quest) then return false end
  local objs = P.GetObjectives(s.quest)
  return type(objs) == "table" and #objs == 0 and crossesContinent(self, s)
end

-- Quest'in henuz yapilmamis yolculuk adimi (numara) ya da nil: quest "tamam" gorunse de once gemiye binilir.
function Engine:PendingTravel(q)
  for i, s in ipairs(q and self.guide and self.guide.steps or {}) do
    if s.quest == q and not s.sticky and self:TravelObjective(s) and self:IsStepComplete(s) ~= true then return i end
  end
end

-- Quest'in durumu (alinabilir / bekliyor / hic alinamaz) tek yerden sorulur: Engine/QuestState.lua.
-- NPC'nin listesinde olmayan quest "verilmiyor" kaydedilir (Engine:NoteOffered, char.refused): kosullu quest (meslek,
-- itibar...: graph.gate) her pencerede, digerleri NPC'nin tam listesinde alinabilir oldugu halde yoksa. O quest'in
-- adimlari rotayi durdurmaz (Skyborne "Camping 101": yalniz meslegine uyan). Liste sonra quest'i gosterirse kayit silinir.
-- NPC'nin listeledigi ama verinin kapali saydigi quest char.offered'a yazilir: NPC'nin dedigi veriden once gelir.
local QS = ns.QuestState
local Route = ns.Route
local GATE_NEAR, GATE_DWELL = 15, 6   -- yard, sn: kosullu quest'in NPC'si yaninda bu kadar durulduysa ve quest yoksa verilmiyor
local GATE_GAP = 10   -- sn: adima bu kadar bakilmadiysa (sekme, duraklatma, sapma) NPC yanindaki bekleme bastan sayilir
local function clock() return (time and time()) or P.Now() end   -- eskort suresi
-- Esyayla baslayan quest (Data/Brain/QuestItems.lua `starts`): esya cantada degilse ve quest alinmamissa
-- kabul / hedef / teslim adimlari rotayi bekletmez (nadir dusen esya: Lakota'mani, Furlbrow's Deed).
-- Esya dusunce (BAG_UPDATE_DELAYED) kabul adimi yeniden gecerli olur; geride kaldiysa kacirilan kabul ceker.
Engine.ResetItemStarts = function() QS.startItem = nil end   -- veri degisince (test) indeks yeniden kurulur

-- Etkin rota p'yi q'dan once aldiriyor mu (QuestState "coming"): p'nin oyuncuya gorunen kabul adimi var ve q'nun
-- kabulunden once (q'nun kabulu rotada yoksa herhangi bir yerde).
-- Rota dizini rehber + irk / sinif / seviye basina bir kez kurulur: accept[quest] = gorunen ilk kabul adimi,
-- at[adim] = sirasi.
local function route(self)
  local g = self.guide
  if not g then return nil end
  local player = P.PlayerInfo() or {}
  local who = tostring(player.race) .. "/" .. tostring(player.class) .. "/" .. tostring(player.level)
  local r = self.route
  if not r or r.guide ~= g or r.who ~= who or r.n ~= #g.steps then
    r = { guide = g, who = who, n = #g.steps, accept = {}, at = {} }
    for i, s in ipairs(g.steps) do
      r.at[s] = i
      if s.type == "accept" and s.quest and not r.accept[s.quest] and self:IsVisible(s, player) then r.accept[s.quest] = i end
    end
    self.route = r
  end
  return r
end

function Engine:Brings(p, q)
  local r = route(self)
  local a = r and r.accept[p]
  if not a then return false end
  -- gecilmis istege bagli kabul artik "gelecek" degildir (Tharil'zun <- Alther's Mill: kabul geride, alinmadi;
  -- 19 acik sanilip oyuncu Marris'e gonderiliyordu, 18 Kasim 2026)
  local s = self.guide.steps[a]
  if s and s.optional and a < (self.index or 1) then return false end
  local b = r.accept[q]
  return b == nil or a < b
end

-- Sahipsiz adim: quest gunlukte yok, bitmemis, esyayla baslamiyor ve rotada bu adima kadar oyuncuya gorunen kabul
-- adimi yok (rehber kabulu baska irk/sinifa veriyor: Darkshore 729 yalniz Night Elf / Skyborne hunter, teslimi butun
-- hunter'lara; ya da quest onceki rehberde aliniyor). Oyuncu oraya bosuna gonderilmez; quest alininca adim geri gelir.
local function orphan(self, s)
  if QS:StartItem(s.quest) then return false end
  local r = route(self)
  local at = r and r.at[s]
  if not at then return false end   -- etkin rehberin adimi degil: soylenemez
  local a = r.accept[s.quest]
  return not (a and a <= at)
end

-- Kosullu quest'in beceri hedefi ("Raise your First Aid skill to 20") bitmemisse o quest'in hedef/teslim adimlari
-- rotayi durdurmaz: beceri ayri bir istir, ilerleme quest listesinde gorunur; hedef bitince teslim "geride kalmis
-- teslim" kuraliyla (overdueTurnin) rotaya geri gelir. objective verilirse yalniz o hedefe bakilir.
local function skillGoalPending(q, objective)
  local g = q and ns.BrainData and ns.BrainData.graph and ns.BrainData.graph[q]
  if not (g and g.gate and Engine:InLog(q)) or P.IsQuestComplete(q) then return false end
  local objectives = P.GetObjectives(q) or {}
  for k, o in ipairs(objectives) do
    -- Ingilizce metin ya da (baska dilde) sayacsiz "log" turu hedef: beceri hedefinin oyunun verdigi tek isareti
    if (objective == nil or k == objective) and not o.finished and type(o.text) == "string"
      and (o.text:find("^Raise your .- skill to %d+") or (o.type == "log" and o.text:find("%d+"))) then
      return true
    end
  end
  return false
end
Engine.SkillGoalPending = function(_, q, objective) return skillGoalPending(q, objective) end

-- Rehber basina birakilan quest'ler (karakter kaydi): kacirilan kabule geri cekilen oyuncu kabulu yapmadan
-- Next ile ayrildiysa o quest'in sonraki hedef/teslim adimlari rotayi durdurmaz (QuestState: never / skipped).
function Engine:DroppedQuests()
  if not self.guide then return {} end
  if not self.char then self.droppedQuests = self.droppedQuests or {}; return self.droppedQuests end
  self.char.dropped = self.char.dropped or {}
  local id = self.guide.id
  self.char.dropped[id] = self.char.dropped[id] or {}
  return self.char.dropped[id]
end

-- Kosullu quest'i veremeyen NPC cogu zaman pencere bile acmaz: NPC'nin yanina gelindi ve GATE_DWELL sn sonra quest
-- hala yoksa verilmiyor sayilir (oturumluk isaret Engine.gated: sonraki hedef/teslim adimlari da bekler; NPC baska
-- yerde olabilir, kalici yazilmaz). Yazdiysa true.
local function gateDwell(s)
  local g = ns.BrainData and ns.BrainData.graph and ns.BrainData.graph[s.quest]
  if not (g and g.gate and Engine.char) then return false end
  local map, x, y = ns.Zones:Location(s)
  local d = map and P.DistanceTo(map, x, y)
  Engine.gateNear = Engine.gateNear or {}
  Engine.gateSeen = Engine.gateSeen or {}
  if not (d and d <= GATE_NEAR) then
    Engine.gateNear[s.quest], Engine.gateSeen[s.quest] = nil, nil
    return false
  end
  local now = P.Now()
  -- bekleme kesintisiz olmali: adima GATE_GAP sn bakilmadiysa sayac bastan baslar
  if Engine.gateSeen[s.quest] and now - Engine.gateSeen[s.quest] > GATE_GAP then Engine.gateNear[s.quest] = nil end
  Engine.gateSeen[s.quest] = now
  Engine.gateNear[s.quest] = Engine.gateNear[s.quest] or now
  if now - Engine.gateNear[s.quest] < GATE_DWELL then return false end   -- konusmaya firsat: hemen gecilmez
  Engine.gated = Engine.gated or {}
  Engine.gated[s.quest] = true
  return true
end

-- Yolculuk hedefine varildi mi: oyuncunun bolgesi ya da alt bolgesi hedef adini iceriyor (buyuk/kucuk harf duyarsiz;
-- "Lakeshire, Redridge" gibi nokta adinda virgulden onceki ve sonraki parcalar da denenir). Ucarken false.
function Engine.Arrived(to)
  if type(to) ~= "string" or to == "" or P.OnTaxi() then return false end
  local zone, sub = (P.ZoneText() or ""):lower(), (P.SubZoneText() or ""):lower()
  for part in to:lower():gmatch("[^,]+") do
    part = part:match("^%s*(.-)%s*$")
    if part ~= "" and (zone:find(part, 1, true) or sub:find(part, 1, true)) then return true end
  end
  return false
end

-- Adim algilayicilari yalniz "bu is yapildi mi" der: true = bitti, false = bitmedi, nil = elle ilerlenir.
-- Quest'in alinip alinamayacagi burada sorulmaz (status / QuestState).
local DETECTORS = {
  accept = function(s) return (Engine:InLog(s.quest) or P.IsQuestFlaggedCompleted(s.quest)) and true or false end,
  turnin = function(s) return P.IsQuestFlaggedCompleted(s.quest) and true or false end,
  complete = function(s)
    if Engine:TravelObjective(s) then
      -- olculemiyor: baska kitada (yola cikmis). Zindan ya da bilinmeyen adim haritasi bitirmez.
      local map, x, y = ns.Zones:Location(s)
      if not map or P.InstanceInfo() then return false end
      return not P.DistanceTo(map, x, y)
    end
    return objectiveDone(s)
  end,
  -- ucus / ocak tasi: varildi = bulundugun bolge ya da alt bolge hedefin adini tasiyor ("Redridge" -> Redridge
  -- Mountains, "Darkshire" alt bolgesi). Ucarken degil. Varilmadiysa elle (nil): sonraki is bitince de gecilir.
  -- 17 Kasim 2026: Redridge'e ucan oyuncuya ok Darkshire'daki kuscuyu gostermeye devam ediyordu.
  fly = function(s) return Engine.Arrived(s.to) or nil end,
  hearth = function(s) return Engine.Arrived(s.to) or nil end,
  kill = function(s) if s.quest then return objectiveDone(s) end return nil end,
  use = function(s) if s.quest then return objectiveDone(s) end return nil end,
  collect = function(s)
    if s.quest then return objectiveDone(s) end
    return P.ItemCount(s.item) >= (s.count or 1)
  end,
  ["goto"] = function(s)
    local map, x, y = ns.Zones:Location(s)
    if not map then return nil end   -- konum bilinmiyor (bolge eslemesi yok): elle ilerlenir
    local distance = P.DistanceTo(map, x, y)
    return distance ~= nil and distance <= (s.radius or DEFAULT_RADIUS)
  end,
  level = function(s) return P.PlayerLevel() >= s.level end,
  -- meslek adimi (Guide/ProfGuides.lua): beceri / tavan / esya / bilinen tarif
  prof = function(s)
    local p = Engine:ProfRank(s.prof)
    if s.act == "buy" or s.act == "collect" then
      if p and s.skill and p.rank >= s.skill then return true end
      return (P.ItemCount(s.item) or 0) >= (s.count or 1)
    end
    if not p then return false end
    if s.act == "train" then return p.max >= s.max end
    if s.act == "learn" then return (s.after and p.rank > s.after) or (s.spell and P.KnowsSpell(s.spell)) or false end
    return p.rank >= (s.skill or 0)
  end,
  -- trainer adimi: bu adimdayken trainer penceresi acildiysa biter; digerleri elle ilerlenir
  -- trainer adimi rotayi durdurmaz: ogrenilecek spell'leri step penceresinin "New spells to train" bolumu
  -- seviyeye gore surekli gosterir (Mentor:TrainingInfo); diger konusma adimlari elle ilerlenir
  -- ocak tasi / ucus noktasi adimi: yapildiysa biter, yoksa elle (nil) kalir
  talk = function(s)
    if s.trainer then return true end
    if s.text == "Set your hearthstone here" then return homeSet(s) or nil end
    if s.text == "Get the flight path" then return flightKnown(s) or nil end
    return nil
  end,
  -- talk, fly, hearth, note: elle ilerlenir (Next).
}

-- Adimin durumu (gorunurluk haric): durum, neden, ref, kok
--   "done"    is yapildi                       "todo"  simdi yapilabilir
--   "manual"  algilayicisi yok (Next ile)      "na"    bu karakter / bu an icin degil ("optional", "orphan", "skill")
--   "wait"    quest'i bekliyor (QuestState nedeni: level / pre / item / refused / gate)
--   "gone"    quest'i artik hic alinamaz ya da birakildi
-- done / na / wait / gone gecilir; yalniz "wait" rehberin sonunda "bekliyor" sayilir.
local QUEST_STEP = { accept = true, complete = true, turnin = true, kill = true, collect = true, use = true }

-- Rota kaynaginin gorev durumu kosullari (adim alanlari; her biri "listeden biri" demektir, kaynagin kendi kurali):
-- ifDone teslim edildi, ifNotDone henuz teslim edilmedi, ifLog gunlukte, ifComplete gunlukte ve bitti. Tutmazsa adim
-- "na" (gecilir); kosul sonradan tutarsa imlec geri doner (kati sira bastan arar). Gorev durumuna bagli oldugu icin
-- gorunurluge (onbellekli rota dizini) degil burada, canli bakilir.
local function anyOf(list, fn)
  for _, x in ipairs(list) do if fn(x) then return true end end
  return false
end
local function stepCondsMet(s)
  if s.ifDone and not anyOf(s.ifDone, function(x) return P.IsQuestFlaggedCompleted(x) end) then return false end
  if s.ifNotDone and not anyOf(s.ifNotDone, function(x) return not P.IsQuestFlaggedCompleted(x) end) then return false end
  if s.ifLog and not anyOf(s.ifLog, function(x) return Engine:InLog(x) end) then return false end
  if s.ifComplete and not anyOf(s.ifComplete, function(x) return Engine:InLog(x) and P.IsQuestComplete(x) end) then
    return false
  end
  return true
end
Engine.StepCondsMet = stepCondsMet

-- Gunlukte olup henuz teslim edilmemis onkosul (NPC bagli quest'i o teslim edilene kadar vermez) ya da nil.
-- Yalniz gunluktekiler: rotada sirasi gelecek onkosul (Brings) bekleme sayilmaz, katı sıra onu zaten once aldirir.
local function heldPre(q)
  local g = ns.BrainData and ns.BrainData.graph and ns.BrainData.graph[q]
  if not g then return nil end
  local any = g.any and #g.any > 0
  for _, p in ipairs(any and g.any or g.all or {}) do
    if P.IsQuestFlaggedCompleted(p) then
      if any then return nil end   -- "biri yeter" ve biri teslim edildi
    elseif Engine:InLog(p) then
      return p
    end
  end
  return nil
end

local function status(s)
  local detector = DETECTORS[s.type]
  local det
  if detector then det = detector(s) end
  local q = s.quest
  if not (q and QUEST_STEP[s.type]) then
    if det == nil then return "manual" end
    return det and "done" or "todo"
  end
  if det == true then return "done" end
  if Engine:QuestSkipped(q) and not P.IsQuestFlaggedCompleted(q) then return "gone", "skipped" end
  if not stepCondsMet(s) then return "na", "cond" end
  if s.type ~= "accept" then
    if skillGoalPending(q, s.type ~= "turnin" and s.objective or nil) then return "na", "skill" end
    if Engine:InLog(q) then return "todo" end
    if s.optional then return "na", "optional" end   -- rotada kabulu olmayan (ilan panosu, esya) quest: gunlukte yoksa gecilir
  end
  local st, why, ref, root = QS:Status(q)
  if st == "done" then return "done" end
  if st == "never" then return "gone", why, ref end
  if st == "wait" then
    if s.optional then return "na", "optional" end
    -- eksik onkosul gri (rehber onu gostermiyor, oyuncu yapmayacak): bekleyen degil, bu karaktere degil
    if why == "pre" and ref and Engine:QuestGray(ref) then return "na", "gray" end
    return "wait", why, ref, root
  end
  if s.type == "accept" then
    if gateDwell(s) then return "wait", "gate" end
    -- onkosulu henuz teslim edilmedi (gunlukte ya da rotada once geliyor): NPC simdi vermez, rehber gondermez;
    -- teslim edilince imlec geri doner (Reclaiming Goods 281 <- 279 gunlukteyken Karl Boran'a gonderiyordu)
    local held = not QS:Offered(q) and heldPre(q)
    if held then return "wait", "pre", held end
    return "todo"
  end
  if orphan(Engine, s) then return "na", "orphan" end
  return "todo"   -- alinabilir ama gunlukte degil: kacirilan kabul kurali ceker
end

-- Algilayici / veri hatasi motoru dusurmez: adim elle ilerlenir hale gelir.
local function stepStatus(step)
  local ok, st, why, ref, root = pcall(status, step)
  if not ok then
    ns:Debug("step status error (" .. tostring(step.type) .. "): " .. tostring(st))
    return "manual"
  end
  return st, why, ref, root
end

function Engine:StepStatus(step, player)
  if not step then return "na" end
  if not self:IsVisible(step, player) then return "na", "filter" end
  return stepStatus(step)
end

-- Rotayi tutmayan adim mi: true = gecilir (bitti, bu karaktere degil, bekliyor, hic alinamaz), false = yapilacak,
-- nil = elle ilerlenir. "Gercekten bitti" ayrimi icin StepStatus.
local PASSED = { done = true, na = true, wait = true, gone = true }
local function isComplete(step)
  local st = stepStatus(step)
  if PASSED[st] then return true end
  if st == "todo" then return false end
  return nil
end
Engine.IsStepComplete = function(_, step) return isComplete(step) end
-- Adim kesin olarak gecildi mi. Elle ilerlenen / bilinmeyen adimlar false.
function Engine:IsStepDone(step)
  return step ~= nil and isComplete(step) == true
end
-- Gorunurluk: adimdaki classes/races kumeleri oyuncuya uymuyorsa adim atlanir.
-- Cok dusuk seviyeli (gri) ve henuz alinmamis gorevlerin adimlari atlanir.
function Engine:IsGray(step, player)
  local ok, gray = pcall(self.CheckGray, self, step, player)
  return ok and gray or false
end

function Engine:CheckGray(step, player)
  if not step.quest or not QUEST_STEP[step.type] then return false end
  if step.feeder then return false end   -- besleyici adim: gri olmayan bir quest'in onkosulu
  return self:QuestGray(step.quest, player)
end

-- Rehberin gri sayip gostermedigi quest (alinmamis, bitmemis, seviyesi oyuncudan skipDiff kadar dusuk)
function Engine:QuestGray(q, player)
  if not (self.db and self.db.skipGray) or not q then return false end
  if self:InLog(q) or P.IsQuestFlaggedCompleted(q) then return false end
  -- oyun alinmamis quest'in seviyesini cogu zaman vermez (GetQuestDifficultyLevel 0): verimizdeki seviye.
  -- Yoksa gri kurali oyunda hic calismiyordu (Blackrock Menace 21, 29. seviyede gosterildi).
  local row = ns.BrainData and ns.BrainData.quests and ns.BrainData.quests[q]
  local level = P.QuestLevel(q) or (row and type(row[2]) == "number" and row[2] > 0 and row[2]) or nil
  if not level then return false end
  return ((player and player.level) or P.PlayerLevel()) - level >= (self.db.skipDiff or 8)
end

-- Adim bitti mi (algilayiciya gore; nil = elle ilerlenen). Guide Browser meslek rehberinin sirasini bulur.
function Engine:StepDone(step) return isComplete(step) end

function Engine:IsVisible(step, player)
  player = player or P.PlayerInfo()
  if self:IsGray(step, player) then return false end
  -- rota kaynaginin seviye siniri: ustundeki oyuncuya adim yok (Shadow Magic 115 kaynakta 27'ye kadar; 29'da
  -- Marris'e 10 kez gonderiyordu, 19 Kasim 2026). Quest gunlukteyse hedef / teslim adimlari kalir.
  if step.maxLevel and (player.level or P.PlayerLevel() or 1) > step.maxLevel
      and not (step.quest and step.type ~= "accept" and self:InLog(step.quest)) then return false end
  -- zindan icinde yapilan quest: oyuncu istemedikce rehber oraya gondermez (Tirisfal Rear Guard Patrol 99156 Ruins of
  -- Lordaeron'da; rota kaynagi zindan secilmedikce gostermez, 19 Kasim 2026). Gunlukteyse adimlari kalir.
  if step.dungeonOnly and not (self.db and self.db.dungeonSteps)
      and not (step.quest and step.type ~= "accept" and self:InLog(step.quest)) then return false end
  -- grup icerigi ve en dusuk seviye (rota kaynagi: .group, .xp <N): ayni kural, gunlukteki quest'in adimlari kalir
  local held = step.quest and step.type ~= "accept" and self:InLog(step.quest)
  if step.groupOnly and not (self.db and self.db.groupSteps) and not held then return false end
  if step.minLevel and (player.level or P.PlayerLevel() or 1) < step.minLevel and not held then return false end
  if step.classes and not (player.class and step.classes[player.class:upper()]) then return false end
  if step.races and not (player.race and step.races[player.race:lower()]) then return false end
  -- trainer adimi yalniz ogrenilecek spell varken (seviye yetmiyorsa oklarla gezinirken de cikmaz)
  local M = step.trainer and ns.Mentor
  if M and M.TrainingDue and not M:TrainingDue(player.level or P.PlayerLevel(), player.class) then return false end
  return true
end

function Engine:GetStep()
  if not self.guide then return nil end
  return self.guide.steps[self.index]
end

-- Rehberde gecen gorevler (rehber basina bir kez hesaplanir):
-- { { id, name, first = ilkAdim, turnin = teslimAdimi, npc = teslimNpc }, ... }
function Engine:GuideQuests()
  local guide = self.guide
  if not guide then return {} end
  if guide.questList then return guide.questList end
  local byId, list = {}, {}
  for i, step in ipairs(guide.steps) do
    local q = step.quest
    if q then
      local entry = byId[q]
      if not entry then
        entry = { id = q, name = step.name, first = i }
        byId[q] = entry
        list[#list + 1] = entry
      end
      if step.name and not entry.name then entry.name = step.name end
      if step.type == "turnin" then entry.turnin, entry.npc = i, step.npc end
      if step.type == "accept" and not entry.accept then entry.accept = i end
    end
  end
  guide.questList = list
  return list
end

-- Gunlukte mi? Batch suresince sonuc tutulur: adim penceresinin tek yenilemesi rehberin gorevlerini
-- birkac kez tarar (ActiveQuest, GetTrackedQuests, CurrentIndex); disarida onbellek yok, eski deger kalmaz.
function Engine:InLog(q)
  local c = self.logCache
  if not c then return P.IsQuestInLog(q) end
  local v = c[q]
  if v == nil then v = P.IsQuestInLog(q) and true or false; c[q] = v end
  return v
end

function Engine:Batch(fn, ...)
  if self.logCache then return fn(...) end   -- ic ice: distaki onbellek kullanilir
  self.logCache = {}
  local ok, err = pcall(fn, ...)
  self.logCache = nil
  if not ok then error(err, 0) end
end

-- Gorev gunlugunde olan ve bu rehberin parcasi olan gorevler: aktif adimin gorevi once, sonra
-- teslim sirasina gore. Dondurur: liste (en fazla limit), toplam sayi.
-- Rehber sormadan alinmis gorev: rehberdeki ilk kabul adimi henuz gelinmemis ilerde (cepheden sonra). Rotayi
-- etkilemez (Brain sapmalari, yakin teslim cekmesi); listede en altta ve isaretli. Rehber oraya varinca normaldir.
-- Bitmis (teslime hazir) quest erken sayilmaz: oyuncu isi yapmis, teslim rotaya girer (toplu teslim, sapma).
function Engine:IsEarly(q)
  if not (self.guide and q) then return false end
  if P.IsQuestComplete(q) then return false end
  if self.char and self.char.adopted and self.char.adopted[q] then return false end   -- rotada alindi (Engine:Adopt)
  local f = self:Reach()
  for _, entry in ipairs(self:GuideQuests()) do
    if entry.id == q then return entry.accept ~= nil and entry.accept > f end
  end
  return false
end

-- Rotada alinan quest'i benimse (QUEST_ACCEPTED): sapma surerken (Planner / kacirilan kabul) ya da rehberdeki kabul
-- adimi cepheden en cok ADOPT_AHEAD adim ilerideyse quest "erken" (Other quests, rotayi etkilemez) sayilmaz; hedefi
-- ve teslimi rotaya girer. Ornek (Fable incelemesi, 11 Kasim 2026): Philmor's Favor teslim sapmasinda ayni NPC'den
-- alinan Gatehouse Goods'un 12 yd'deki hedefi "erken" diye gizleniyor, rehber oyuncuyu sehrin obur ucuna yolluyordu.
Engine.ADOPT_AHEAD = 20
function Engine:Adopt(q)
  if not (self.guide and self.char and q) then return false end
  local entry
  for _, e in ipairs(self:GuideQuests()) do if e.id == q then entry = e break end end
  if not (entry and entry.accept) then return false end
  if not (self.pulledTo or entry.accept - self:Reach() <= self.ADOPT_AHEAD) then return false end
  self.char.adopted = self.char.adopted or {}
  self.char.adopted[q] = true
  return true
end

-- Gunlukte olan ama bu rehberde hic gecmeyen gorevler: { {id, name, objectives, complete, extra = true} }.
function Engine:ExtraQuests()
  local out = {}
  if not self.guide then return out end
  local mine = {}
  for _, entry in ipairs(self:GuideQuests()) do mine[entry.id] = true end
  local CG, class = ns.ClassGuide, P.PlayerClassToken()
  for _, q in ipairs(P.QuestLogList and P.QuestLogList() or {}) do
    if q.id and not mine[q.id] then
      local entry = CG and CG.QuestFor and CG:QuestFor(class, q.id) or nil
      out[#out + 1] = { id = q.id, name = P.QuestName(q.id, q.title), objectives = P.GetObjectives(q.id) or {},
        complete = q.complete and true or false, extra = true, order = math.huge, class = entry,
        -- zincir baska irklar icin (ornek: Skyborne bu dersleri kendi baslangicinda alir): bosuna yapilmasin
        notNeeded = entry and select(2, self:ClassQuestNotNeeded(q.id)) or nil }
    end
  end
  return out
end

-- Zincirin ogrettigi buyulerin hepsi zaten biliniyor mu (ClassGuide `teaches`)?
local function knowsAll(entry)
  if not (entry and entry.teaches and #entry.teaches > 0) then return false end
  for _, id in ipairs(entry.teaches) do if not P.KnowsSpell(id) then return false end end
  return true
end
Engine.KnowsClassReward = knowsAll

-- Bu sinif quest'i gereksiz mi? Donus: zincir girisi, neden ("known": ogrettikleri zaten biliniyor (ornek: Skyborne
-- bunlari kendi baslangicinda ogrenir) | "race": zincir baska irklar icin) ya da nil.
function Engine:ClassQuestNotNeeded(id)
  local CG = ns.ClassGuide
  if not (CG and CG.QuestFor and id) then return nil end
  local info = P.PlayerInfo() or {}
  local entry = CG:QuestFor(info.class, id)
  if not entry then return nil end
  if knowsAll(entry) then return entry, "known" end
  if entry.races and info.race and not CG.RaceMatches(entry.races, info.race) then return entry, "race" end
  return nil
end

-- Uyari metni (adim penceresi ve quest penceresi ayni cumleyi kullanir)
function Engine:NotNeededText(entry, why)
  if why == "known" then
    local names = {}
    for _, id in ipairs(entry.teaches) do names[#names + 1] = P.SpellName(id) or ("#" .. id) end
    return L["You already know what this chain teaches (%s), so you can skip it."]:format(table.concat(names, ", "))
  end
  return L["This chain is meant for %s. Your race learns the same at its own start, so you can abandon it."]:format(table.concat(entry.races or {}, ", "))
end

-- Rehber disi quest icin ok hedefi: teslime hazirsa oyunun teslim isareti; degilse ilk bitmemis hedefin en iyi
-- alani (Data/Brain/QuestAreas), yoksa oyunun quest isareti. Donus: { map, x, y, label } ya da nil.
function Engine:OffGuideTarget(q)
  if not q then return nil end
  if not q.complete then
    for k, o in ipairs(q.objectives or {}) do
      if not o.finished then
        local r = ns.Areas and ns.Areas:Ranked(q.id, k, o.text)
        local a = r and r[1]
        if a then return { map = a.map, x = a.x, y = a.y, label = o.text or q.name } end
        break
      end
    end
  end
  local map, x, y
  if P.QuestMapPos then map, x, y = P.QuestMapPos(q.id) end
  if map and x and y then return { map = map, x = x, y = y, label = q.complete and L["Turn in: %s"]:format(q.name) or q.name } end
  -- oyunun isareti yalniz bulunulan haritada: teslim baska bolgedeyse zincirin sonraki quest'ini veren NPC
  local guess = q.complete and ns.Brain and ns.Brain.TurnInGuess and ns.Brain:TurnInGuess(q.id)
  local gmap = guess and ns.Zones and ns.Zones:Resolve(guess.zone)
  if gmap then return { map = gmap, x = guess.x, y = guess.y, label = L["Turn in: %s"]:format(guess.npc) } end
  return nil
end

-- Alinabilir sinif quest'leri (seviye, fraksiyon, irk uygun; zincir ne gunlukte ne bitmis), dusuk seviye once.
function Engine:ClassQuestReminders()
  local out = {}
  local CG = ns.ClassGuide
  if not (CG and self.db and self.db.classQuests) then return out end
  local info = P.PlayerInfo() or {}
  for _, e in ipairs(CG:Quests(info.class, info.faction, info.level, info.race)) do
    local started = false
    for _, id in ipairs(CG:ChainIds(e)) do
      if self:InLog(id) or P.IsQuestFlaggedCompleted(id) then started = true break end
    end
    if not started and not knowsAll(e) and not QS:Closed(e.id) then out[#out + 1] = e end
  end
  return out
end

function Engine:GetTrackedQuests(limit)
  local out = {}
  if not self.guide then return out, 0 end
  local step = self:GetStep()
  local currentId = step and step.quest
  local f = self:Reach()
  for _, entry in ipairs(self:GuideQuests()) do
    if self:InLog(entry.id) then
      out[#out + 1] = {
        -- IsEarly ile ayni kural (benimsenen quest erken sayilmaz)
        early = entry.accept ~= nil and entry.id ~= currentId and self:IsEarly(entry.id) or nil,
        id = entry.id,
        name = P.QuestName(entry.id, entry.name),
        objectives = P.GetObjectives(entry.id) or {},
        complete = P.IsQuestComplete(entry.id) and true or false,
        npc = entry.npc,
        current = entry.id == currentId,
        order = entry.turnin or entry.first,
      }
    end
  end
  table.sort(out, function(a, b)
    if a.current ~= b.current then return a.current end
    return a.order < b.order
  end)
  local total = #out
  while #out > (limit or 4) do table.remove(out) end
  return out, total
end

-- Su an uzerinde calisilmasi gereken gorev: rehber sirasina gore gunlukte olan ilk tamamlanmamis gorev
-- (yoksa teslime hazir ilk gorev). Dondurur: { id, name, complete } ya da nil.
function Engine:ActiveQuest()
  local ready
  for _, entry in ipairs(self:GuideQuests()) do
    if self:InLog(entry.id) then
      if P.IsQuestComplete(entry.id) then
        ready = ready or { id = entry.id, name = P.QuestName(entry.id, entry.name), complete = true }
      else
        return { id = entry.id, name = P.QuestName(entry.id, entry.name), complete = false }
      end
    end
  end
  return ready
end

-- Gorevin su an gidilecek hedef adimi: bittiyse teslim adimi, bitmediyse konumu olan ilk hedef adimi
-- (complete/kill/collect/use/goto). Dondurur: adim, adimNo (yoksa nil).
local OBJECTIVE_STEP = { complete = true, kill = true, collect = true, use = true, ["goto"] = true }
function Engine:QuestTarget(questId)
  if not self.guide then return nil end
  local travel = self:PendingTravel(questId)
  if travel then return self.guide.steps[travel], travel end
  local complete = P.IsQuestComplete(questId)
  local fallback, fallbackIndex, anyStep, anyIndex, turnStep, turnIndex
  for i, step in ipairs(self.guide.steps) do
    if step.quest == questId and not step.sticky then
      if step.type == "turnin" and not turnStep then turnStep, turnIndex = step, i end
      if complete then
        if step.type == "turnin" then return step, i end
      elseif OBJECTIVE_STEP[step.type] then
        if not anyStep or (step.x and not anyStep.x) then anyStep, anyIndex = step, i end
        if self:IsStepComplete(step) ~= true then   -- bitmis hedefin adimi degil (eski hedefe yonlendirmesin)
          if step.x then return step, i end
          fallback, fallbackIndex = fallback or step, fallbackIndex or i
        end
      end
    end
  end
  if fallback then return fallback, fallbackIndex end
  if anyStep then return anyStep, anyIndex end   -- hepsi bitmis gorunuyor (teslim bilgisi gecikmeli): eski davranis
  -- rehberde hedef adimi olmayan quest ("Camping 101: Fishing": beceriyi 20'ye cikar, sonra NPC ile konus):
  -- quest kutusu teslim NPC'sini gosterir
  return turnStep, turnIndex
end

-- Gunlukteki rehber gorevleri, yakindan uzaga: { {quest, step, index, distance} }. Konumu bilinmeyenler sona.
-- Mesafeler 25 yard'lik dilimlere yuvarlanarak siralanir (yuruyuste liste titremesin).
function Engine:QuestPlan(limit)
  local plan = {}
  for _, q in ipairs((self:GetTrackedQuests(25))) do
    local step, index = self:QuestTarget(q.id)
    local dist
    if step then
      local map, x, y = ns.Zones:Location(step)
      if map then dist = P.DistanceTo(map, x, y) end
    end
    plan[#plan + 1] = { quest = q, step = step, index = index, distance = dist, order = q.order or 0, off = q.early }
  end
  -- rehber disi gorevler: adimi yok, rotayi etkilemez; listenin en altinda
  for _, q in ipairs(self:ExtraQuests()) do
    local t = self:OffGuideTarget(q)
    plan[#plan + 1] = { quest = q, order = math.huge, off = true, target = t,
      distance = t and P.DistanceTo(t.map, t.x, t.y) or nil }
  end
  table.sort(plan, function(a, b)
    if (a.off or false) ~= (b.off or false) then return not a.off end   -- rotadaki gorevler once
    local da = a.distance and math.floor(a.distance / 25) or math.huge
    local db = b.distance and math.floor(b.distance / 25) or math.huge
    if da ~= db then return da < db end
    return a.order < b.order
  end)
  -- aktif adimin gorevi kesilmesin: sinirin disinda kaldiysa son yere tasinir
  if limit and #plan > limit then
    for i = limit + 1, #plan do
      if plan[i].quest.current then
        local cur = table.remove(plan, i)
        table.insert(plan, limit, cur)
        break
      end
    end
  end
  while limit and #plan > limit do table.remove(plan) end
  return plan
end

-- Bir goreve ait adima git: teslime hazirsa teslim adimi, degilse ilk hedef adimi (kabul/teslim disindaki).
-- Dondurur: adim numarasi ya da nil.
function Engine:JumpToQuest(id)
  if not self.guide then return nil end
  local complete = P.IsQuestComplete(id)
  local pick, first
  for i, step in ipairs(self.guide.steps) do
    if step.quest == id and not step.sticky then   -- sticky kopya degil, asil adim
      first = first or i
      if complete then
        if step.type == "turnin" and not pick then pick = i end
      elseif step.type ~= "accept" and step.type ~= "turnin" and not pick then
        pick = i
      end
    end
  end
  pick = self:PendingTravel(id) or pick or first
  -- oyuncunun sectigi adim: Planner o adimdayken rotayi degistirmez (adim degisince normal karar)
  if pick then self.chosen = pick; self:SetGuide(self.guide.id, pick) end
  return pick
end

function Engine:CanNext()
  return self.guide ~= nil and self.index <= #self.guide.steps
end

function Engine:GetProgress()
  if not self.guide then return 0, 0 end
  return math.min(self.index, #self.guide.steps), #self.guide.steps
end

-- Durum degisimi
-- Sapma ileriye mi (Gorev Beyni)? Geri cekme (geride kalan teslim) degil.
function Engine:OnForwardDetour()
  return self.pulledTo ~= nil and self.pulledTo == self.index and self.resumeAt ~= nil and self.resumeAt < self.index
end

function Engine:Persist()
  if not self.char then return end
  self.char.guide = self.guide and self.guide.id or nil
  -- sapma ortasinda /reload: sapma isaretleri kalici degil; kalinan yer (resumeAt) kaydedilir. Ileri sapmada
  -- aradaki adimlar atlanmaz; geri cekmede oyuncu aradaki (hic almadigi) adimlara takilmaz, teslim sonra yine onerilir.
  -- ileri bakarken (Browse / Prev ile hala cephenin onunde) bakilan adim kaydedilmez: cephe kaydedilir (sekme / reload
  -- aradaki adimlari atlamasin)
  local keep = self.resumeAt or (self.browsing and self:Frontier()) or self.index
  self.char.index = keep
  -- rehber basina ilerleme: zindan rehberine gecip donunce kaldigin yerden devam
  if self.guide then
    self.char.progress = self.char.progress or {}
    self.char.progress[self.guide.id] = keep
    -- adim numarasi hangi rehber surumune ait (RestoreSaved: rehber degistiyse bastan yerles)
    self.guide._sig = self.guide._sig or Engine.GuideSig(self.guide)
    self.char.sig = self.char.sig or {}
    self.char.sig[self.guide.id] = self.guide._sig
  end
end

-- Rehber basina "cephe": otomatik ilerlemenin ya da ileri gitmenin ulastigi en yuksek adim. Geri gezinme
-- (Prev, eski adima tiklama) onu dusurmez; "su anki adima don" buradan devam eder. Eski kayitlarda cephe
-- yoksa rehberin kayitli ilerlemesi kullanilir.
function Engine:Frontier()
  if not self.guide then return nil end
  local id, last = self.guide.id, #self.guide.steps + 1
  local f = self.char and self.char.frontier and self.char.frontier[id]
  if type(f) ~= "number" then f = self.char and self.char.progress and self.char.progress[id] end
  if type(f) ~= "number" then f = self.index end
  return math.max(1, math.min(f, last))
end

-- Elle gelinen adim cephenin gerisinde ve zaten bitmisse "bakiliyor" diye isaretle (Evaluate onu birakir).
Engine.MANUAL_LEAVE = 150   -- yd: elle bakilan yolculuk adiminda bu kadar uzaklasinca bakis biter

function Engine:NoteLanding()
  local s = self.guide and self.guide.steps[self.index]
  local front = self:Frontier()
  local behind = s and front and self.index < front
  self.viewDone = (behind and isComplete(s) == true) and self.index or nil
  -- geride bitmemis bir adima bilerek gelindi (Prev, listeden secim): motor oyuncuyu oradan kendiliginden
  -- almaz (ara nokta atlama, yakindaki teslim cekmesi, sapma donusu yok); adim bitince oradan normal devam eder
  self.manual = (behind and isComplete(s) ~= true and not s.sticky and self:IsVisible(s)) and self.index or nil
  local c, x, y
  if self.manual then c, x, y = P.PlayerWorldPos() end
  self.manualFrom = c and { c, x, y } or nil
  self:NoteLook()
end

-- Bakis (bitmis adima donmek: viewDone; ileri bakmak: browsing) kendiliginden bitmiyordu ve pencere bunu soylemiyordu:
-- oyuncu bitmis bir adimda "takili" kaliyordu (Karl Boran, 19 Kasim 2026). Bakis, oyuncu is yapinca (gorev alma /
-- teslim) ya da baktigi yerden MANUAL_LEAVE yd uzaklasinca biter.
Engine.LOOK_HOLD = 20   -- sn: son ok tiklamasindan bu kadar sonra bakis biter (oyuncu bilmeden tiklayip "takiliyordu")
function Engine:NoteLook()
  self.lookEnd = nil
  self.lookAt = P.Now()
  if (self.viewDone and self.viewDone == self.index) or self.browsing then
    local c, x, y = P.PlayerWorldPos()
    self.lookFrom = c and { c, x, y } or nil
  else
    self.lookFrom = nil
  end
end

function Engine:LookOver()
  if self.lookEnd then return true end
  if self.lookAt and P.Now() - self.lookAt > self.LOOK_HOLD then return true end
  local f = self.lookFrom
  if not f then return false end
  local c, x, y = P.PlayerWorldPos()
  local d = c and P.WorldDistance(c, x, y, f[1], f[2], f[3])
  return d ~= nil and d > self.MANUAL_LEAVE
end

-- Rehberi bilerek bastan / bir adimdan yeniden baslatma (Ayarlar "su adimdan basla"): cephe o adima iner.
function Engine:ResetFrontier(guideId, index)
  if not (self.char and guideId) then return end
  self.char.frontier = self.char.frontier or {}
  self.char.frontier[guideId] = index or 1
end

-- Oyuncu rehberi bilerek bir adimdan baslatir (Ayarlar > rehber listesi "Start"): katı sırada oncesindeki bitmemis
-- adimlar bilerek gecilmis sayilir (imlec bastan aranirken onlara donmez).
function Engine:StartAt(id, index)
  index = index or 1
  self:ResetFrontier(id, index)
  if not self:SetGuide(id, index) then return false end
  if self:Strict() then
    local skip, player = self:SkipSteps(), P.PlayerInfo()
    for i = 1, math.min(index - 1, #self.guide.steps) do
      local s = self.guide.steps[i]
      if self:IsVisible(s, player) and isComplete(s) == false then skip[stepKey(s)] = true end
    end
    self.index, self.manual, self.viewDone = index, nil, nil
    self:Evaluate()
    self:Persist()
  end
  return true
end

function Engine:RaiseFrontier(index)
  if not (self.guide and self.char) then return end
  self.char.frontier = self.char.frontier or {}
  local id = self.guide.id
  local cur = self.char.frontier[id]
  if type(cur) ~= "number" then cur = self:Frontier() end
  index = math.min(index or self.index, #self.guide.steps + 1)
  self.char.frontier[id] = math.max(cur, index)
end

function Engine:AnnounceStep()
  local step = self:GetStep()
  if step then
    ns:Send("ARCANIS_STEP_CHANGED", self.guide.id, self.index, step)
  end
end

-- Bekleyen quest'ler, kok nedene gore: { { reason, ref, root, quests = { id, ... } }, ... }, bekleyen adim sayisi.
-- Sayilmaz: seviye bekleyenler (seviye gelince acilir) ve bu karaktere verilmeyen kosullu quest (meslek / itibar:
-- "Camping 101" yalniz meslegine uyan).
function Engine:Waiting(player)
  local out, by, seen, count = {}, {}, {}, 0
  if not self.guide then return out, 0 end
  player = player or P.PlayerInfo()
  local graph = ns.BrainData and ns.BrainData.graph or {}
  for _, s in ipairs(self.guide.steps) do
    local q = s.quest
    if q and not s.sticky and self:IsVisible(s, player) then
      local st, why, ref, root = stepStatus(s)
      local g = graph[root or q]
      if st == "wait" and why ~= "level" and not ((why == "refused" or why == "gate") and g and g.gate) then
        count = count + 1
        if not seen[q] then
          seen[q] = true
          local key = why .. ":" .. tostring(ref or root or q)
          local e = by[key]
          if not e then
            e = { reason = why, ref = ref, root = root, quests = {} }
            by[key] = e
            out[#out + 1] = e
          end
          e.quests[#e.quests + 1] = q
        end
      end
    end
  end
  return out, count
end

-- Bekleme / gecilme nedeninin cumlesi (adim satiri ve "bekleyenler" listesi ayni metni kullanir) ya da nil.
function Engine:WaitText(why, ref)
  local function name(q)
    local DG = ns.DungeonGuides
    return q and ((DG and DG.QuestName and DG.QuestName(q)) or P.QuestName(q)) or "?"
  end
  if why == "level" then return L["Requires level %d"]:format(ref or 0) end
  if why == "pre" or why == "chain" then return L["Requires %s first"]:format(name(ref)) end
  if why == "item" then return L["Starts from an item you do not have yet: %s"]:format(P.ItemName(ref) or ("#" .. tostring(ref))) end
  if why == "refused" then return L["The quest giver does not offer it"] end
  if why == "gate" then return L["Not offered here right now"] end
  if why == "skipped" then return L["You skipped this quest"] end
  if why == "closed" then return L["No longer available"] end
  return nil
end

-- "Bekliyor" isareti rehber basina (karakter kaydi): son bildirilen bekleyen quest sayisi.
local function blockedMarks(self)
  if not self.char then self.blockedMarks = self.blockedMarks or {}; return self.blockedMarks end
  self.char.blocked = self.char.blocked or {}
  return self.char.blocked
end

-- Rehberin sonuna gelindi ama bekleyen quest var: "bitti" denmez (ARCANIS_GUIDE_FINISHED gitmez).
function Engine:IsBlocked()
  return self.guide ~= nil and not self.finished and self.index > #self.guide.steps
    and blockedMarks(self)[self.guide.id] ~= nil
end

-- Rehberin sonu: bekleyen quest yoksa biter; varsa "bekliyor" (liste degistikce ARCANIS_GUIDE_BLOCKED).
local function finish(self)
  if self.finished then return end
  local id, marks = self.guide.id, blockedMarks(self)
  local n = 0
  for _, w in ipairs((self:Waiting())) do n = n + #w.quests end
  if n > 0 then
    if marks[id] ~= n then
      marks[id] = n
      ns:Send("ARCANIS_GUIDE_BLOCKED", id)
    end
    return
  end
  marks[id] = nil
  self.finished = true
  -- acik "bitti" isareti: kayitli adim sayisi bir guncellemeyle rehberin boyuyla tutmayabilir (Guides finished)
  if self.char and not self.guide.special then
    self.char.done = self.char.done or {}
    self.char.done[id] = true
  end
  ns:Send("ARCANIS_GUIDE_FINISHED", id, Guides:GetNext(self.guide, P.PlayerInfo()))
end

-- Bekleyerek sonuna gelinmis rehberde artik alinabilen ilk kabul adimi (onkosul baska yerde bitti, esya dustu).
local function reopened(self, player)
  for j, s in ipairs(self.guide.steps) do
    if s.type == "accept" and s.quest and not s.optional and not s.sticky and self:IsVisible(s, player)
      and stepStatus(s) == "todo" then return j end
  end
  return nil
end

-- Gorunmeyen adimlari gecerek idx'ten itibaren ilk gorunur adimi dondurur. Sticky ("yolda yap") adimlar hic
-- su anki adim olmaz: Engine:Sticky listesinde yan gorev olarak gosterilir.
local function seek(self, from, direction, player)
  local steps = self.guide.steps
  local i = from
  while i >= 1 and i <= #steps do
    if not steps[i].sticky and self:IsVisible(steps[i], player) then return i end
    i = i + direction
  end
  return nil
end

local STICKY_WINDOW = 40   -- asil adimi olmayan sticky hedef en cok bu kadar adim boyunca gosterilir

-- Sticky adimin "sahibi": ileride ayni quest (ve hedef) icin asil complete/turnin adimi. Oraya gelince sticky biter.
-- Onbellek adim listesi basina (adim numarasi tutar: besleyici adim eklenmis rota ile kayitli rehber ayni adimi paylasir).
local OWNERS = setmetatable({}, { __mode = "k" })
local function stickyOwner(steps, j)
  local own = OWNERS[steps]
  if not own then own = {}; OWNERS[steps] = own end
  local s = steps[j]
  if own[s] == nil then
    own[s] = false
    for k = j + 1, #steps do
      local o = steps[k]
      if not o.sticky and o.quest == s.quest
        and ((o.type == "complete" and (o.objective == nil or o.objective == s.objective)) or o.type == "turnin") then
        own[s] = k
        break
      end
    end
  end
  return own[s]
end

-- Su an gecerli "yolda yap" hedefleri: gecilmis, gorunur, quest'i gunlukte ve hedefi bitmemis sticky adimlar;
-- asil adimina henuz gelinmemis. Asil adimi yoksa (ya da oyuncuya gorunmuyorsa) en cok STICKY_WINDOW adim.
-- Donus: { {index, step}, ... }
function Engine:Sticky(player)
  local out = {}
  if not (self.guide and self.index) then return out end
  player = player or P.PlayerInfo()
  local steps = self.guide.steps
  local cur = math.min(self.index, #steps + 1)
  for j = 1, cur - 1 do
    local s = steps[j]
    if s.sticky and s.quest then
      local owner = stickyOwner(steps, j)
      if owner and not self:IsVisible(steps[owner], player) then owner = nil end
      if (owner and owner > cur) or (not owner and cur - j <= STICKY_WINDOW) then
        if self:InLog(s.quest) and isComplete(s) ~= true and self:IsVisible(s, player) then
          out[#out + 1] = { index = j, step = s }
        end
      end
    end
  end
  return out
end

function Engine:CanPrev()
  if not self.guide then return false end
  return seek(self, math.min(self.index, #self.guide.steps + 1) - 1, -1) ~= nil
end

-- from'dan itibaren bitmis ve gorunmeyen adimlari gecer; durulacak adimi dondurur (sonda #steps + 1).
-- Yolculuk adimi (goto, hearth, fly) yalniz sonraki is icin yol: ardindaki ilk yolculuk olmayan adim zaten
-- bittiyse oraya gitmek gereksiz (is baska yoldan yapildi; rota "Hearth to ..." gibi adimda takilmasin).
local TRAVEL = { ["goto"] = true, hearth = true, fly = true }
local passes
local function travelSpent(self, v, player)
  local steps, n = self.guide.steps, v
  repeat n = seek(self, n + 1, 1, player) until not n or not TRAVEL[steps[n].type]
  return n ~= nil and passes(self, steps[n])
end

-- Ara nokta: goto'dan sonraki isin yeri goto'ya bu kadar yakinsa goto gereksiz (ok dogrudan ise gider).
-- Magara ve yol (cave / path) adimlari korunur: oradaki ara nokta yolu gosterir.
local WAYPOINT_NEAR = 80
local function gotoRedundant(self, v, player)
  local steps, s = self.guide.steps, self.guide.steps[v]
  if s.type ~= "goto" or s.cave or s.path or s.npc then return false end
  local n = v
  repeat n = seek(self, n + 1, 1, player) until not n or not TRAVEL[steps[n].type]
  if not n then return false end
  local m1, x1, y1 = ns.Zones:Location(s)
  local m2, x2, y2 = ns.Zones:Location(steps[n])
  local d = m1 and m2 and P.PointDistance(m1, x1, y1, m2, x2, y2)
  return d ~= nil and d <= WAYPOINT_NEAR
end

-- Katı sıra (db.strict, varsayilan acik; sahibin karari, 15 Kasim 2026): imlec her degerlendirmede rehberin BASINDAN
-- aranan en kucuk numarali, su an yapilabilir, bitmemis adimdir (Engine:Lowest). Gecilen: API ile dogrulanan (done),
-- bu karaktere ait olmayan (na), artik alinamayan (gone), oyuncunun Shift + ileri ile bilerek gectigi adim
-- (char.skipSteps) ve su an yapilamayan (wait: seviye, onkosul, esya, NPC vermiyor; bitmis sayilmaz, yapilabilir
-- olunca imlec geri doner). Cephenin gerisindeki elle ilerlenen (talk, note) ve yolculuk adimlari gecilmis sayilir.
-- Rota sapmasi (Planner) adimi / oku kaydirmaz, yalniz "Next" onerir. Eskiden imlec yalniz bulundugu yerden ileri
-- bakiyordu: 71'deki bitmemis hedef (3/10) dururken 77'deki teslime gonderiyordu.
function Engine:Strict() return self.db ~= nil and self.db.strict ~= false end

-- Adimin kimligi (rota numarasi degisse de ayni): bilerek gecilen adimlarin kaydi icin
local function keyPart(v)
  if type(v) == "table" then v = v.enUS or v[1] end   -- cok dilli metin
  return tostring(v or "")
end
local function stepKey(s)
  return table.concat({ keyPart(s.type), keyPart(s.quest), keyPart(s.objective), keyPart(s.npc or s.text),
    keyPart(s.x), keyPart(s.y) }, "|")
end
function Engine:SkipSteps()
  if not (self.char and self.guide) then return {} end
  self.char.skipSteps = self.char.skipSteps or {}
  local id = self.guide.id
  self.char.skipSteps[id] = self.char.skipSteps[id] or {}
  return self.char.skipSteps[id]
end

-- settle'in "gecilir" karari
passes = function(self, s, v, front)
  local st = stepStatus(s)
  if PASSED[st] then return true end
  if not self:Strict() then return false end
  if self:SkipSteps()[stepKey(s)] then return true end
  -- cephenin gerisinde: elle ilerlenen ve yolculuk adimi gecilmistir (oyuncu oradan gecti)
  -- gorevsiz yardimci adim (esya topla / satin al) da: sonradan eklenen adim ilerdeki oyuncuyu geri cekmez
  return v ~= nil and front ~= nil and v < front and (st == "manual" or TRAVEL[s.type] == true or not s.quest)
end

-- Yolculuk hala gerekli mi: ucus / ocak tasi adiminin varis yeri, sirasi gelen ilk yapilacak isin bolgesi ve oyuncu
-- oraya varmadi. O zaman adim gecilmez: ne "sonraki is bitti" kurali ne cephe gerisi kurali. (19 Kasim 2026, sahibin
-- bulgusu: Ironforge -> Wetlands ucusundan sonraki istege bagli teslim gecildigi icin ucus atlaniyordu; ok Wetlands'teki
-- ocak tasi adimina Ironforge'dan yuruterek gonderiyordu.)
local TRAVEL_LOOK = 30
Engine.TRAVEL_FAR = 500   -- yd: sirasi gelen is bundan uzaksa ve varis yerine varilmadiysa yolculuk adimi gosterilir
local function travelNeeded(self, v, player, front)
  local steps, s = self.guide.steps, self.guide.steps[v]
  if not ((s.type == "fly" or s.type == "hearth") and type(s.to) == "string" and s.to ~= "") then return false end
  if Engine.Arrived(s.to) or self:SkipSteps()[stepKey(s)] then return false end
  local n, looked = v, 0
  repeat
    n = seek(self, n + 1, 1, player)
    looked = looked + 1
    -- arada baska bir ucus / ocak tasi varsa sirasi gelen ise o goturur: eski yolculuk geri cekmez
    if n and (steps[n].type == "fly" or steps[n].type == "hearth") then return false end
  until not n or looked > TRAVEL_LOOK or not (TRAVEL[steps[n].type] or passes(self, steps[n], n, front))
  local nxt = n and looked <= TRAVEL_LOOK and steps[n]
  if not nxt then return false end
  -- konum once (rehberlerin cogunda ucus kasabaya gider, is bolge adi tasir: "Crossroads" / "The Barrens"; ad eslemesi
  -- 347 riskli yolculugun yalniz 168'ini yakaliyordu): is uzaktaysa ya da baska kitadaysa yolculuk gerekli
  local m, x, y = ns.Zones:Location(nxt)
  if m then
    local d = P.DistanceTo(m, x, y)
    if d then return d > Engine.TRAVEL_FAR end
    local pc = P.PlayerWorldPos and P.PlayerWorldPos()
    local tc = P.WorldPos and P.WorldPos(m, x, y)
    if pc and tc and pc ~= tc then return true end
  end
  if type(nxt.zone) ~= "string" then return false end
  local zone = nxt.zone:lower()
  for part in s.to:gmatch("[^,]+") do
    local p = part:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if p ~= "" and (zone:find(p, 1, true) or p:find(zone, 1, true)) then return true end
  end
  return false
end
Engine.TravelNeeded = travelNeeded

local function settle(self, from, player)
  local i = from
  local front = self:Strict() and self:Frontier() or nil
  while true do
    local v = seek(self, i, 1, player)
    if not v then return #self.guide.steps + 1 end
    local s = self.guide.steps[v]
    if TRAVEL[s.type] and travelNeeded(self, v, player, front) and stepStatus(s) ~= "done" then return v end
    if passes(self, s, v, front) or (TRAVEL[s.type] and travelSpent(self, v, player)) or gotoRedundant(self, v, player) then
      i = v + 1
    else
      return v
    end
  end
end

-- Yolculuk adiminin goturdugu is (sonraki yolculuk olmayan gorunur adim) ya da nil. Adim basina bir kez bulunur.
function Engine:LeadsTo(step)
  -- yalniz etkin rehberde bulunan adim onbellege yazilir (baska rehberin adimina kalici "false" yazilmaz);
  -- gorunurluk (seviye, gri) degisince Evaluate onbellegi temizler (leadsGen)
  if step._leads ~= nil and step._leadsGen == self.leadsGen then return step._leads or nil end
  if not self.guide then return nil end
  local steps = self.guide.steps
  for i, s in ipairs(steps) do
    if s == step then
      local n = i
      repeat n = seek(self, n + 1, 1) until not n or not TRAVEL[steps[n].type]
      step._leads, step._leadsGen = n and steps[n] or false, self.leadsGen
      return step._leads or nil
    end
  end
  return nil
end

-- Geride kalmis teslim: "before"dan onceki, ayni bolgedeki, gunlukte TESLIME HAZIR bir gorevin teslim adimi.
-- Oyuncu en yakin goreve atlayip onu teslim edince digerinin teslimi arkada kalmasin (Orc 1-12: Galgar + Invaders).
-- Atlanmaz: istege bagli adimlar, oyuncunun Next ile bilerek gectigi teslimler, rehberde daha ileride ayrica
-- teslim adimi olan gorevler, baska bolgedeki eski gorevler (oyuncuyu haritanin obur ucuna cekmesin).
-- Oyuncunun Next ile bilerek gectigi teslimler, rehber basina kalici (karakter kaydi): /reload sonrasi da dayatilmaz.
function Engine:SkippedTurnins()
  if not self.guide then return {} end
  if not self.char then self.skippedTurnins = self.skippedTurnins or {}; return self.skippedTurnins end
  self.char.skipped = self.char.skipped or {}
  local id = self.guide.id
  self.char.skipped[id] = self.char.skipped[id] or {}
  return self.char.skipped[id]
end

-- Oyuncu adimin yaninda mi (Brain alan yaricapi, 150 yd)? true / false; konum bilinmiyorsa nil.
local function nearPlayer(s)
  local B = ns.Brain
  if not (B and B.IsEnabled and B:IsEnabled() and B.World) then return nil end
  local c, px, py = P.PlayerWorldPos()
  local w = c and B:World(s)
  if not w then return nil end
  local d = P.WorldDistance(c, px, py, w[1], w[2], w[3])
  return d ~= nil and d <= ((B.db and B.db.areaYards) or 150)
end

local function overdueTurnin(self, before, player)
  local steps = self.guide.steps
  local last = math.min(before, #steps + 1) - 1
  if last < 1 then return nil end
  local here = steps[math.min(before, #steps)]
  local zone = here and here.zone
  local skipped = self:SkippedTurnins()
  -- baska bolgeye gecen adimda da: oyuncu teslimin yanindaysa atlanmaz
  local near = function(s) return nearPlayer(s) == true end
  for i = 1, last do
    local s = steps[i]
    -- optional teslim de: rehberde kabulu olmayan quest (Brain onerisiyle alinan gibi) sonradan bitebilir
    if s.type == "turnin" and s.quest and not skipped[s.quest]
      and self:InLog(s.quest) and P.IsQuestComplete(s.quest) and not P.IsQuestFlaggedCompleted(s.quest)
      and self:IsVisible(s, player)
      and (zone == nil or s.zone == nil or s.zone == zone or near(s)) then   -- konum en son (pahali)
      local later = false
      for j = before, #steps do
        if steps[j].type == "turnin" and steps[j].quest == s.quest then later = true break end
      end
      if not later then return i end
    end
  end
  return nil
end

-- Cephenin gerisinde kalan, gorevi gunlukte duran ve yapilmamis adim (ayni bolgede; istege bagli/sticky haric).
local PENDING = { turnin = true, complete = true, kill = true, collect = true, use = true }
local function pendingBehind(self, before, player)
  local steps = self.guide.steps
  local here = steps[math.min(before, #steps)]
  local zone = here and here.zone
  for i = 1, math.min(before, #steps + 1) - 1 do
    local s = steps[i]
    if PENDING[s.type] and s.quest and not s.optional and not s.sticky
      and self:InLog(s.quest) and not P.IsQuestFlaggedCompleted(s.quest) and not skillGoalPending(s.quest)
      and (s.type == "turnin" or isComplete(s) == false) and self:IsVisible(s, player) then
      -- yalniz oyuncunun yanindaki is (150 yd); konum yoksa ayni bolge. Bolgenin obur ucuna geri gonderilmez.
      local n = nearPlayer(s)
      local here_ = n == true or (n == nil and (zone == nil or s.zone == nil or s.zone == zone))
      -- rehber ayni isi ileride ayrica yaptiriyorsa (teslim / ayni hedef) geri cekilmez
      local later = not here_
      for j = before, here_ and #steps or before - 1 do
        local o = steps[j]
        if o.quest == s.quest and not o.sticky and (o.type == "turnin"
          or (s.type ~= "turnin" and PENDING[o.type] and (o.objective == nil or o.objective == s.objective))) then
          later = true
          break
        end
      end
      if not later then return i end
    end
  end
  return nil
end

-- Kacirilan kabul: "at" adimi gunlukte olmayan bir quest'in hedefi / teslimi ve o quest'in kabul adimi geride
-- (gecilmis). Kabul adiminin numarasi ya da nil. Yalniz su an alinabilir quest (QuestState open / unknown): bekleyen,
-- birakilan, artik alinamayan ve istege bagli quest'ler sayilmaz.
local function missedAccept(self, at, player)
  local s = self.guide.steps[at]
  if not (s and PENDING[s.type] and s.quest and not s.optional and not s.sticky) then return nil end
  local q = s.quest
  local st = QS:Status(q)
  if st ~= "open" and st ~= "unknown" then return nil end
  if ns.Brain and ns.Brain.CanAccept and ns.Brain:CanAccept(q) == false then return nil end
  for j = at - 1, 1, -1 do
    local a = self.guide.steps[j]
    if a.type == "accept" and a.quest == q and self:IsVisible(a, player) then return j end
  end
  return nil
end
Engine.MissedAccept = function(self, at) return missedAccept(self, at or self.index, P.PlayerInfo()) end

-- Bitmis adimlari atlayarak ilerler. Elle ilerlenen adimda durur.
-- Duraklat (adim penceresinin Pause dugmesi, karakter kaydi): rehber kendiliginden ilerlemez, sapma / cekme
-- yapmaz, ok rehber hedefini birakir; oklarla elle gezinme surer. Devam edince yeniden degerlendirilir.
function Engine:IsPaused() return self.char ~= nil and self.char.paused == true end

function Engine:SetPaused(v)
  if not self.char then return end
  self.char.paused = v and true or nil
  if not v then self.dirty = true; self:Evaluate() end
  self:AnnounceStep()
end

function Engine:Evaluate()
  if not self.guide then return false end
  if self:IsPaused() then return false end
  local player = P.PlayerInfo()
  -- bakis bitti (oyuncu is yapti ya da uzaklasti): normal akisa donulur
  if ((self.viewDone and self.viewDone == self.index) or self.browsing) and self:LookOver() then
    self.viewDone, self.browsing, self.browseDone, self.lookFrom, self.lookEnd = nil, nil, nil, nil, nil
    if not self:Strict() then self.index = self:CurrentIndex() or self.index end
  end
  -- Geri gezinme: zaten bitmis bir adima bakiliyorsa (viewDone) yerinden oynatma; yalniz cephe ilerler.
  if self.viewDone and self.viewDone == self.index then
    self:RaiseFrontier(settle(self, self:Frontier(), player))
    return false
  end
  -- Ileri bakis (Browse): cephe gercek ilerlemeyle yukselir; ilerleme bakilan adima yetisince normal akisa donulur.
  if self.browsing then
    local cur = self.index <= self:Frontier() and self.index or settle(self, self:Strict() and 1 or self:Frontier(), player)
    if cur >= self.index then
      self.browsing, self.browseDone = nil, nil
    else
      self:RaiseFrontier(cur)
      local s = self.guide.steps[self.index]
      if not self.browseDone and s and isComplete(s) == true and not TRAVEL[s.type] then
        local nxt = settle(self, self.index, player)
        -- rehberin sonuna bakarak gelinmez: gercek adimlar geride kaldikca rehber "bitti" sayilmaz
        if nxt ~= self.index and nxt <= #self.guide.steps then
          self.index = nxt
          self.browseDone = isComplete(self.guide.steps[nxt]) == true
          self:AnnounceStep()
          return true
        end
      end
      return false
    end
  end
  -- elle bakistan uzaklasinca yapilan donus de "adim degisti" sayilmali (kayit + duyuru): baslangic burada alinir
  local startIndex = self.index
  -- Elle gelinen bitmemis adim: oyuncu orada kalir; adim bitince oradan normal akis surer
  if self.manual and self.manual == self.index then
    local s = self.guide.steps[self.index]
    -- yolculuk adimi (goto/hearth/fly) yaklasinca "biter": elle bakarken oyuncuyu oradan almaz, ileri / sag tik bekler.
    -- Ama oyuncu bakmaya basladigi yerden MANUAL_LEAVE yd uzaklastiysa bakis biter: oyuncu yola cikmistir, rehber
    -- su anki ise doner (eskiden yolculuk adiminda elle bakis hic bitmiyor, Planner da karar veremiyordu).
    local away = false
    if s and TRAVEL[s.type] and self.manualFrom then
      local c, x, y = P.PlayerWorldPos()
      local m = self.manualFrom
      local d = c and P.WorldDistance(c, x, y, m[1], m[2], m[3])
      away = d ~= nil and d > self.MANUAL_LEAVE
    end
    if away then
      self.manual, self.manualFrom = nil, nil
      local cur = self:CurrentIndex()
      if cur and cur ~= self.index then self.index = cur end
    elseif not (s and isComplete(s) == true) or TRAVEL[s.type] then
      self:RaiseFrontier(settle(self, self:Frontier(), player))
      return false
    end
  end
  self.manual = nil
  self.viewDone = nil
  -- Katı sıra: sapma / geri cekme yok; imlec = en kucuk yapilabilir bitmemis adim (oyuncunun listeden sectigi adim
  -- bitene kadar kalir)
  if self:Strict() then
    self.resumeAt, self.pulledTo, self.detourReason, self.missedQuest = nil, nil, nil, nil
    self.pullYards, self.pullFor, self.keepOrder = nil, nil, nil
    local steps = self.guide.steps
    local keep = self.chosen and self.chosen == self.index and steps[self.index]
      and not passes(self, steps[self.index], self.index, self:Frontier())
    if not keep then self.chosen = nil; self.index = settle(self, 1, player) end
    self:RaiseFrontier(self.index)
    local moved = self.index ~= startIndex
    if moved then self:Persist() end
    if self.index > #steps then
      if not self.finished then finish(self) end
    elseif moved then
      self:AnnounceStep()
    end
    return moved
  end
  -- Sapma adimindan (geri teslim ya da ileri oneri) ayrilinca kalinan yere (resumeAt) donulur.
  if self.resumeAt and self.pulledTo then
    local pulled = self.guide.steps[self.pulledTo]
    local pulledDone = pulled and isComplete(pulled) == true
    -- Planner sapmasi bayatlar: oyuncu secildigi andakinden bir alan (150 yd) daha uzaklastiysa birakilir
    local expired = false
    if self.pullYards and self.pullFor == self.pulledTo and not pulledDone and self.index == self.pulledTo
      and ns.Brain and ns.Brain.World then
      local c, x, y = P.PlayerWorldPos()
      local w = c and ns.Brain:World(pulled)
      local d = w and P.WorldDistance(c, x, y, w[1], w[2], w[3])
      expired = d ~= nil and d > self.pullYards + ((ns.Brain.db and ns.Brain.db.areaYards) or 150)
    end
    if self.index ~= self.pulledTo or pulledDone or expired then
      -- bitmeden birakilan ILERI sapma reddedilmis sayilir: bu oturumda ayni adima tekrar sapilmaz (dongu olmaz;
      -- ornek: NPC'nin vermedigi kabul, sunucunun almadigi teslim); bayatlayan sapma da (geri dahil)
      if not pulledDone and (self.resumeAt < self.pulledTo or expired) then
        self.detourRefused = self.detourRefused or {}
        self.detourRefused[self.pulledTo] = true
      end
      -- kacirilan kabule cekilmisken kabul yapilmadan ayrildi: quest birakildi, sonraki adimlari durdurmaz
      if self.missedQuest and not pulledDone then self:DroppedQuests()[self.missedQuest] = true end
      self.missedQuest = nil
      if self.resumeAt ~= self.index then self.index = self.resumeAt end
      self.resumeAt, self.pulledTo, self.detourReason = nil, nil, nil
      self.pullYards, self.pullFor, self.keepOrder = nil, nil, nil
    end
  end
  self.index = settle(self, self.index, player)
  -- ileri sapma surerken cephe sapma hedefine degil, kalinan yere (resumeAt) gore yukselir; yoksa "su anki adim"
  -- sapmanin kendisi olur ve sonra aradaki adimlar sessizce atlanir
  self:RaiseFrontier(self:OnForwardDetour() and self.resumeAt or self.index)
  -- Sapma yalniz adim bitip ilerleyince ya da geride hazir teslim varken dusunulur; pinOrder acikken hic yapilmaz.
  local pinned = self.db and self.db.pinOrder
  -- kacirilan kabul: quest'in hedef/teslim adimina gelindi ama quest gunlukte yok -> once kabule; alininca geri
  local missed = not pinned and not self.pulledTo and self.index <= #self.guide.steps and missedAccept(self, self.index, player)
  if missed then
    local a = self.guide.steps[missed]
    self.resumeAt, self.pulledTo, self.index = self.index, missed, missed
    self.pullYards, self.pullFor = nil, nil
    self.missedQuest = a.quest
    self.detourReason = L["You passed this quest's accept: take it from %s first."]:format(a.npc or "?")
    self:Persist()
    self:AnnounceStep()
    return true
  end
  -- Rota karari tek yerde: Planner isleri (hazir teslim ileri/geri, buradaki kabul, alandaki hedef) rehberi takip
  -- etmeye gore kazandirdigi sureyle tartar; belirgin kazanc varsa sapilir, is bitince kalinan yere donulur.
  local target, why, pick
  if self.chosen and self.chosen ~= self.index then self.chosen = nil end
  -- katı sırada sapma yok: yandaki isin ilerlemesi kaydedilir, pencerede "Next" onerisi kalir, adim ve ok kilitli
  if not pinned and not self:Strict() and not self.pulledTo and not self.chosen and self.index <= #self.guide.steps
    and ns.Planner and ns.Planner.Route then
    local ok, t, w, s = pcall(ns.Planner.Route, ns.Planner, self, player)
    if ok and t then target, why, pick = t, w, s end
    if not ok and ns.Debug then ns:Debug("Planner.Route: " .. tostring(t)) end
    -- konum yok (ic mekan, olcum yok): Planner tartamaz; eski kural yedek kalir (ayni bolgede geride kalan teslim)
    if not target and not P.PlayerWorldPos() then
      target = overdueTurnin(self, self.index, player)
    end
  end
  if target then
    if target < self.index then
      -- geri: cephe teslime iner (geri gezinme sayilmasin, Next normal calissin); Reach erken hesabini korur
      self.resumeAt = math.max(self.resumeAt or 0, self.index)
      self:ResetFrontier(self.guide.id, target)
    else
      self.resumeAt = self.index   -- ileri: cephe kalinan yerde; "su anki adim" sapmayi birakip rotaya doner
    end
    self.pulledTo, self.index, self.detourReason = target, target, why
    self.pullYards, self.pullFor = pick and pick.yards, target   -- uzaklasinca sapma biter (yalniz bu sapma)
    -- rota degisti: adada haber ver (ust uste sapmalarda tek bildirim guncellenir)
    local t = self.guide.steps[target]
    if ns.Toast then
      ns.Toast:Show(L["Detour: %s"]:format(P.QuestName(t.quest, t.name) or t.text or "?"), "info", why, nil, { cat = "quest", key = "detour" })
    end
  end
  local moved = self.index ~= startIndex
  if moved then self:Persist() end
  if self.index > #self.guide.steps then
    if not self.finished then
      -- beklerken sona gelinmisti ve bir kabul acildi: rehber oradan surer (cephe oraya iner; Next ile gecilirse
      -- quest birakilir ve yeniden sona gelinir)
      local back = not pinned and blockedMarks(self)[self.guide.id] and reopened(self, player)
      if back then
        self:ResetFrontier(self.guide.id, back)
        self.index = back
        self:Persist()
        self:AnnounceStep()
        return true
      end
      finish(self)
    end
  elseif moved then
    self:AnnounceStep()
  end
  return moved
end

-- Besleyici plan (Engine/Route.lua): rehber basina eklenen zincir quest'leri (karakter kaydi, yalniz buyur);
-- `steps` alani eklenen adim sayisi.
local NO_FEED = {}
function Engine:FeedList(id, create)
  local c = self.char or self
  if not create then return c.feed and c.feed[id] or NO_FEED end
  c.feed = c.feed or {}
  c.feed[id] = c.feed[id] or {}
  return c.feed[id]
end

-- Rehberin oynanan adim listesi (etkin degilse kayitli besleyici listesinden kurulur) ve adim sayisi:
-- kayitli adim numaralari (progress) bu listeye gore.
function Engine:RouteOf(id)
  if self.guide and self.guide.id == id then return self.guide end
  local base = Guides:Get(id)
  return base and Route:Make(base, self:FeedList(id))
end

function Engine:StepTotal(guide)
  local f = self.char and self.char.feed and self.char.feed[guide.id]
  return #guide.steps + (f and f.steps or 0)
end

-- Eksik zincirleri rotaya ekler (rehber acilirken, sekme degisirken, seviye atlayinca; savasta degil). Kayitli adim
-- numaralari yeni rotaya tasinir; eklenen blok geride kaldiysa cephe oraya iner (zincir, ona bagli adimlardan once).
-- index: SetGuide'in yerlesecegi adim (kayitli yer ya da cagiranin verdigi; o da tasinir ve blogun gerisine
-- dusmez: yoksa cephe blogu atlar, bagli kabuller NPC'nin vermedigi quest'e gonderir). Doner: yeni index.
local function feed(self, base, index)
  local add, info = Route:Missing(self)
  if #add == 0 then return index end
  local id, list, old = base.id, self:FeedList(base.id, true), self.guide
  for _, q in ipairs(add) do list[#list + 1] = q end
  local new = Route:Make(base, list, P.PlayerInfo())
  if new == old then return index end
  local was, first = {}, #new.steps + 1
  for i, s in ipairs(old.steps) do was[old.src and old.src[i] or s] = true end
  for j = 1, #new.steps do
    if not was[new.src[j]] then first = j break end
  end
  local function move(i) return type(i) == "number" and math.min(Route.Remap(old, new, i), first) or i end
  local c = self.char
  if c then
    if c.progress then c.progress[id] = move(c.progress[id]) end
    if c.frontier then c.frontier[id] = move(c.frontier[id]) end
  end
  index = move(index)
  -- reddedilen sapmalar adim numarasiyla tutulur: eklenen adimlarla birlikte kayar (reddedilen teslim tekrar
  -- onerilmesin, ilgisiz adim susmasin)
  if self.detourRefused then
    local moved = {}
    for i in pairs(self.detourRefused) do moved[Route.Remap(old, new, i)] = true end
    self.detourRefused = moved
  end
  list.steps = #new.steps - #base.steps
  self.guide = new
  if ns.Toast and info.guide then
    ns.Toast:Show(L["Added %d steps from %s"]:format(#new.steps - #old.steps, Guides:TitleOf(info.guide)), "info",
      L["They unlock %d quests here."]:format(info.unlock), nil, { cat = "quest", key = "feed" })
  end
  return index
end

-- Seviye atlandi (ya da rehber savasta acildi): eklenebilecek zincir varsa rota yeniden kurulur.
function Engine:Feed()
  self.feedDue = nil
  if not self.guide or #Route:Missing(self) == 0 then return false end
  self:Persist()
  return self:SetGuide(self.guide.id)
end

-- Kayitli yeri olmayan rehber kanita gore acilir: capa = quest'i gunlukte ya da bitmis son gorunur adim; capadan
-- onceki elle ilerlenen (talk, note) ve yolculuk adimlari gecilmis sayilir (oyuncu oradan gecmis ki o quest'e
-- varmis). Yapilacak quest adiminda yine durulur. Capa yoksa nil (adim 1).
local function place(self)
  local player, steps, anchor = P.PlayerInfo(), self.guide.steps, nil
  for i, s in ipairs(steps) do
    local q = s.quest
    if q and QUEST_STEP[s.type] and not s.sticky and (self:InLog(q) or P.IsQuestFlaggedCompleted(q))
      and self:IsVisible(s, player) then anchor = i end
  end
  if not anchor then return nil end
  local i = settle(self, 1, player)
  while i < anchor and (TRAVEL[steps[i].type] or isComplete(steps[i]) == nil) do i = settle(self, i + 1, player) end
  return i
end

-- Rehber secilince ileride gereken, satin alinan / getirilen esyalar (gorevsiz "collect" adimlari, ornek Bronze Tube):
-- cantada yoksa tek bildirim (oturumda rehber basina bir kez). Doner: metin listesi (test icin).
function Engine:PrepList(guide, from)
  local out, player = {}, P.PlayerInfo()
  for i = from or 1, #guide.steps do
    local s = guide.steps[i]
    if s.type == "collect" and not s.quest and s.item and s.text and self:IsVisible(s, player)
      and (P.ItemCount(s.item) or 0) < (s.count or 1) then
      out[#out + 1] = ns:LocalizedText(s.text)
    end
  end
  return out
end

function Engine:PrepNotice()
  local guide = self.guide
  if not guide then return end
  self.prepShown = self.prepShown or {}
  if self.prepShown[guide.id] then return end
  self.prepShown[guide.id] = true
  local list = self:PrepList(guide, self.index)
  if #list == 0 or not ns.Toast then return end
  ns.Toast:Show(L["This guide needs something later"], "info", table.concat(list, "\n"), nil,
    { cat = "quest", key = "prep", hold = 12, prio = "high" })
end

function Engine:SetGuide(id, index)
  local base = Guides:Get(id)
  if not base then return false, L["Guide not found: %s"]:format(tostring(id)) end
  self.resumeAt, self.pulledTo, self.detourReason = nil, nil, nil
  self.pullYards, self.pullFor, self.keepOrder, self.missedQuest = nil, nil, nil, nil   -- bilerek bir adima gidildi: eski "kalinan yer" gecersiz
  self.browsing, self.browseDone = nil, nil
  local prev = self.guide
  if not prev or prev.id ~= id then
    self.gateNear, self.gateSeen = nil, nil
    self.detourRefused, self.chosen, self.manual, self.viewDone = nil, nil, nil, nil   -- sapma ve secim rehbere ozel
  end
  self:NoteTab(id, prev, self.finished or (prev and self.index > #prev.steps))
  local list = self:FeedList(id)
  -- ayni rota yeniden kurulmaz (listeden adim secmek besleyici adimlarin kopyalarini degistirmesin)
  local same = prev and prev.id == id and (prev.base or prev) == base and (prev.fed or 0) == #list
  self.guide = same and prev or Route:Make(base, list, P.PlayerInfo())
  if not index and self.char then
    index = self:Reseat(id, self.guide) or (self.char.progress and self.char.progress[id])
  end
  if P.InCombat() then self.feedDue = true else index = feed(self, base, index) end
  local guide = self.guide
  if guide ~= prev then self.leadsGen = (self.leadsGen or 0) + 1 end   -- "Head to" onbellegi adim listesine bagli
  if not index then
    local ok, at = pcall(place, self)   -- oyun API'si hata verirse adim 1
    index = ok and at or nil
  end
  self.index = math.max(1, math.min(index or 1, #guide.steps + 1))
  -- sticky adim hic su anki adim olmaz (liste tiklamasi, "buradan basla", kayitli yer): sonraki asil adima
  if guide.steps[self.index] and guide.steps[self.index].sticky then
    local i = self.index
    while guide.steps[i] and guide.steps[i].sticky do i = i + 1 end
    self.index = i
  end
  -- yeniden baslatilan / gercek ise inen rehber artik bitmis degil (char.done yalniz sona gelince yazilir)
  if self.char and self.char.done and self.index <= #guide.steps then self.char.done[id] = nil end
  self.finished = false
  self.dirty = false
  self:NoteLanding()
  -- katı sıra: rehber acilinca / geri yuklenince (sekme, /reload) kayitli adim "bakilan" adim degildir. Cephenin
  -- gerisindeki bitmis adima inince bakis sayiliyordu ve imlec bitmis kabulde takili kaliyordu (Wolves at Our Heels,
  -- 16 Kasim 2026). Oyuncunun kendi secimi (Engine.chosen) korunur.
  if self:Strict() and not self.chosen then self.viewDone, self.manual = nil, nil end
  self:Persist()
  ns:Send("ARCANIS_GUIDE_CHANGED", id)
  if not prev or prev.id ~= id then self:PrepNotice() end
  if not self:Evaluate() then
    if self.index > #guide.steps then finish(self) else self:AnnounceStep() end
  end
  return true
end

-- Eskort / "bul ve geri getir" (Gyromast's Revenge, Therylune's Escape): oyuncu gorevin alan verisindeki NPC ile
-- konusunca (gossip / quest penceresi) ya da kabulu eskortu baslatan quest'i alinca eskort basladi sayilir; hedef
-- adimi o sure dogma yerini degil varis yerini gosterir (Zones:Location). Hedef bitince, quest gunlukten cikinca ya
-- da ESCORT_TTL sonra duser.
local ESCORT_TTL = 1200
function Engine:EscortActive(q)
  local e = self.escort and self.escort[q]
  if not e then return false end
  if not self:InLog(q) or P.IsQuestComplete(q) or clock() - e > ESCORT_TTL then self.escort[q] = nil; return false end
  return true
end

function Engine:StartEscort(q)
  if not (q and self:InLog(q)) or P.IsQuestComplete(q) then return false end
  self.escort = self.escort or {}
  self.escort[q] = clock()
  if ns.Nav and ns.Nav.RefreshGuideTarget then ns.Nav:RefreshGuideTarget() end
  return true
end

-- Konusulan NPC bir gunlukteki quest'in alan verisinde (hedef yaratigi) geciyorsa o quest'in eskortu basladi.
function Engine:NoteEscort(npc)
  local areas = npc and ns.BrainData and ns.BrainData.areas
  if not (areas and self.guide) then return end
  for _, s in ipairs(self.guide.steps) do
    local q = s.quest
    if s.type == "complete" and q and areas[q] and self:InLog(q) and not P.IsQuestComplete(q) then
      for _, o in ipairs(areas[q]) do
        if o[1] == npc then self:StartEscort(q) break end
      end
    end
  end
end

-- Kabulu eskortu baslatan quest (ipucu verisinde kabul asamasi "escort"): alininca eskort basladi.
function Engine:NoteEscortAccept(q)
  local h = q and ns.BrainData and ns.BrainData.hints and ns.BrainData.hints[q]
  for _, c in ipairs(h and h.a or {}) do
    if c == "escort" then return self:StartEscort(q) end
  end
  return false
end

-- Rotaya eklenemeyen bekleyen zincirlerin (baska bolge, ayar kapali) alindigi onceki rehber ve quest sayisi:
-- rehberin sonunda "bekliyor" dugmesi onu acar.
function Engine:EarlierGuide()
  return Route:Earlier(self)
end

-- Rehberi durdur (bos rehber): ilerleme rehber basina saklanir, tekrar secince kaldigi yerden; ok rehber
-- hedefini birakir, /reload'da rehber geri gelmez.
function Engine:StopGuide()
  if not self.guide then return false end
  self:Persist()
  local stopped = self.guide.id
  self.guide, self.index, self.finished = nil, 1, false
  self.resumeAt, self.pulledTo, self.detourReason, self.browsing, self.browseDone = nil, nil, nil, nil, nil
  self.manual, self.chosen, self.missedQuest = nil, nil, nil
  self.pullYards, self.pullFor, self.keepOrder = nil, nil, nil
  if self.char then
    self.char.guide, self.char.index = nil, nil
    if stopped then self:RemoveTab(stopped) end   -- durdurulan rehberin sekmesi kapanir (ilerleme saklanir)
  end
  ns:Send("ARCANIS_GUIDE_CHANGED", nil)
  ns:Send("ARCANIS_STEP_CHANGED", nil, nil, nil)
  return true
end

-- Rehber sekmeleri: ayni anda birden cok rehber acik durur (seviye + zindan / meslek rehberi). Karakter kaydi:
-- char.tabs acik rehberlerin sirasi, char.tabUse kullanim sirasi (en son kullanilan sonda). Her rehberin yeri
-- zaten rehber basina saklanir (progress, frontier, dropped, sig); sekmeye gecmek SetGuide(id) ile kaldigi
-- yerden devam eder. Yalniz etkin sekme oku, Brain/Planner'i ve gorev listesini surer (Engine.guide tektir).
Engine.MAX_TABS = 8

local function without(list, id)
  for i = #list, 1, -1 do if list[i] == id then table.remove(list, i) end end
end

local function indexOf(list, id)
  for i, v in ipairs(list) do if v == id then return i end end
end

-- Acik sekmeler (kimlik listesi, kayitli sira). Eski kayit: o anki rehber (+ zindan gunlugunun "geri don" rehberi).
function Engine:TabList()
  local c = self.char
  if not c then return {} end
  if type(c.tabs) ~= "table" then
    c.tabs, c.tabUse = {}, {}
    local J = ns.Journal and ns.Journal.char
    local back = J and J.returnTo
    if type(back) == "string" and back ~= c.guide then c.tabs[1], c.tabUse[1] = back, back end
    if J then J.returnTo = nil end
    if type(c.guide) == "string" then c.tabs[#c.tabs + 1] = c.guide; c.tabUse[#c.tabUse + 1] = c.guide end
  end
  c.tabUse = c.tabUse or {}
  return c.tabs
end

-- Gorunen sekmeler: kayitli rehberler (zindan rehberi girişte yeniden uretilir; o zamana kadar gizli kalir)
function Engine:OpenTabs()
  local out = {}
  for _, id in ipairs(self:TabList()) do
    local g = Guides:Get(id)
    if g then out[#out + 1] = g end
  end
  return out
end

function Engine:HasTab(id)
  return indexOf(self:TabList(), id) ~= nil
end

local function tabsOn()
  local W = ns.Window
  return not (W and W.db and W.db.guideTabs == false)
end

-- SetGuide cagirir: yeni rehber sekme olur (simdikinin sagina) ya da var olan sekme one gelir. Sekmeler kapaliysa
-- ya da biten rehberden geciliyorsa (zincirin sonraki rehberi, listeden baska rehber) eski sekmenin yerini alir.
function Engine:NoteTab(id, prev, prevFinished)
  if not self.char then return end
  local tabs, use = self:TabList(), self.char.tabUse
  -- biten rehberden ayrilinca sekmesi kapanir (zincirde sonraki rehber onun yerine gecer)
  if prev and prevFinished and prev.id ~= id and indexOf(tabs, id) and indexOf(tabs, prev.id) then
    without(tabs, prev.id); without(use, prev.id)
  end
  if not indexOf(tabs, id) then
    local at = prev and indexOf(tabs, prev.id)
    if at and prev.id ~= id and (prevFinished or not tabsOn()) then
      without(use, prev.id)
      tabs[at] = id
    elseif at then
      table.insert(tabs, at + 1, id)
    else
      tabs[#tabs + 1] = id
    end
    -- sinir: en uzun suredir kullanilmayan (etkin olmayan) sekme kapanir
    while #tabs > self.MAX_TABS do
      local drop
      for _, u in ipairs(use) do if u ~= id then drop = u break end end
      drop = drop or (tabs[1] ~= id and tabs[1]) or tabs[2]
      without(tabs, drop); without(use, drop)
    end
  end
  without(use, id)
  use[#use + 1] = id
end

-- Sekmeyi listeden cikarir (rehber degismez).
function Engine:RemoveTab(id)
  if not (self.char and id) then return end
  without(self:TabList(), id)
  without(self.char.tabUse or {}, id)
end

-- En son kullanilan diger sekme (filtre(rehber) istege bagli); yoksa nil.
function Engine:RecentTab(except, filter)
  self:TabList()
  local use = self.char and self.char.tabUse or {}
  for i = #use, 1, -1 do
    local g = use[i] ~= except and Guides:Get(use[i])
    if g and indexOf(self.char.tabs, g.id) and (not filter or filter(g)) then return g end
  end
end

-- Rehberi ac: sekmesi varsa ona gecer (kaldigi yerden), yoksa yeni sekme. SetGuide ile ayni sonuc.
function Engine:OpenGuide(id, index)
  if self.guide and self.guide.id == id and not index then return true end
  return self:SetGuide(id, index)
end

-- Sekmeyi kapat: etkin sekmeyse bir onceki (en son kullanilan) sekmeye donulur; baska sekme yoksa rehber durur.
-- Ilerleme rehber basina saklanir, ayni rehber sonra acilinca kaldigi yerden.
function Engine:CloseTab(id)
  if not (self.char and id) then return false end
  if not self.guide or self.guide.id ~= id then
    self:RemoveTab(id)
    ns:Send("ARCANIS_TABS_CHANGED")
    return true
  end
  local back = self:RecentTab(id)
  if back then
    self:Persist()
    self:RemoveTab(id)
    self:SetGuide(back.id)
  else
    self:StopGuide()
  end
  ns:Send("ARCANIS_TABS_CHANGED")
  return true
end

-- Kacirilan kabule cekilmisken ileri gitmek: quest birakilir, kalinan yere (resumeAt) donulur. Yapildiysa true.
local function leaveMissed(self)
  if not (self.missedQuest and self.pulledTo == self.index and self.resumeAt) then return false end
  self:DroppedQuests()[self.missedQuest] = true
  local back = self.resumeAt
  self.resumeAt, self.pulledTo, self.detourReason, self.missedQuest = nil, nil, nil, nil
  self.pullYards, self.pullFor, self.keepOrder = nil, nil, nil
  self.browsing, self.browseDone = nil, nil
  self.index = back
  self:NoteLanding()
  self:Persist()
  self:AnnounceStep()
  self:Evaluate()
  return true
end

-- Ileri gecerken (Next: Shift + tik ya da tus; duz tik yalniz ileri bakar) uzerinde durulan kabul alinmamissa bilerek gecilmis sayilir: quest birakilir (sonraki adimlari
-- rotayi durdurmaz, kacirilan kabul cekmesi yapilmaz), oyuncuya soylenir. Prev ile kabule donmek kaydi siler.
local function skipAccept(self)
  local s = self.guide.steps[self.index]
  if self.pulledTo == self.index then return end   -- sapmadan ayrilmak sapmayi reddetmektir, quest'i birakmak degil
  if not (s and s.type == "accept" and s.quest and not s.optional) or isComplete(s) ~= false then return end
  self:DroppedQuests()[s.quest] = true
  if ns.Toast then
    ns.Toast:Show(L["Skipped: %s"]:format(s.name or P.QuestName(s.quest) or "?"), "info",
      L["Its later steps will not stop the route. Go back with the left arrow to take it."], nil, { cat = "quest" })
  end
end

-- Elle bir sonraki gorunur adima gec (zorunlu/opsiyonel fark etmez).
function Engine:Next()
  if not self.guide or self.index > #self.guide.steps then return false end
  if leaveMissed(self) then return true end
  -- ileri bakarken atlamak aradaki gercek adimlari da gecmek olurdu: bakis surer (ilerdeki kabul birakilmaz)
  if self.browsing then return self:Browse() end
  skipAccept(self)
  -- elle gecilen bitmemis teslim kalici olarak "gecildi" kaydedilir (yalniz cephedeki adimda)
  local leaving = self.guide.steps[self.index]
  -- ileri sapmadan Next ile ayrilmak: sapma bu oturumda reddedilmis sayilir, cephe yukseltilmez
  local detour = self:OnForwardDetour()
  if detour then
    self.detourRefused = self.detourRefused or {}
    self.detourRefused[self.index] = true
  elseif leaving and leaving.type == "turnin" and leaving.quest and isComplete(leaving) ~= true
      and self.index >= (self:Frontier() or self.index) then
    self:SkippedTurnins()[leaving.quest] = true
  end
  -- katı sıra: bilerek gecilen bitmemis adim kaydedilir (imlec bastan aranirken ona geri donmez); Prev ile donunce silinir
  -- yolculuk adimi (ucus / ocak tasi) elle ilerlenir: Next "gitmeyecegim" demektir, yoksa travelNeeded geri cekerdi
  local wontTravel = leaving and TRAVEL[leaving.type] and isComplete(leaving) == nil
  if self:Strict() and leaving and (isComplete(leaving) == false or wontTravel) then
    self:SkipSteps()[stepKey(leaving)] = true
  end
  local target = seek(self, self.index + 1, 1)
  self.index = target or (#self.guide.steps + 1)
  if not detour then self:RaiseFrontier(self.index) end
  -- katı sırada Next bakis degil ilerlemedir: imlec Evaluate'te bastan bulunur (bitmis adima "bakiliyor" denmez)
  if self:Strict() then self.viewDone, self.manual, self.chosen = nil, nil, nil else self:NoteLanding() end
  self:Persist()
  -- son adimdaki sapmayi reddetmek rehberi bitirmez: Evaluate kalinan yere (resumeAt) dondurur
  if self.index > #self.guide.steps and not detour then
    finish(self)
  else
    self:AnnounceStep()
    self:Evaluate()
  end
  return true
end

-- Pencere okuyla ileri bakmak: ilerleme degismez, sag tik gercek adima doner. Elle adimda ya da sapmada Next olur.
function Engine:Browse()
  if not self.guide or self.index > #self.guide.steps then return false end
  if leaveMissed(self) then return true end
  local here = self.guide.steps[self.index]
  if self:OnForwardDetour() or (self.index == self:CurrentIndex() and isComplete(here) == nil) then
    self.browsing, self.browseDone = nil, nil   -- gercek adimdayiz (Next tekrar Browse'a donmesin)
    return self:Next()
  end
  local target = seek(self, self.index + 1, 1)
  if not target then return false end   -- bakarak rehber bitirilmez
  self.index = target
  self.finished = false
  self.browsing = target > self:Frontier() or nil
  self.browseDone = isComplete(self.guide.steps[target]) == true   -- bakmaya gelindiginde zaten bitmis
  self:NoteLanding()
  self:AnnounceStep()   -- kayit yok: /reload sonrasi kalinan (gercek) yerden devam edilir
  return true
end

function Engine:Prev()
  if not self.guide then return false end
  local target = seek(self, math.min(self.index, #self.guide.steps + 1) - 1, -1)
  if not target then return false end
  self.finished = false
  -- geri gitmek bir sapmayi (ileri oneri, geri teslim, kacirilan kabul) birakir; dongu olmasin diye isaretlenir
  if self:OnForwardDetour() then
    self.detourRefused = self.detourRefused or {}
    self.detourRefused[self.index] = true
  end
  self:KeepReach()
  self.resumeAt, self.pulledTo, self.detourReason, self.missedQuest = nil, nil, nil, nil
  self.pullYards, self.pullFor = nil, nil
  if target <= (self:Frontier() or target) then self.browsing, self.browseDone = nil, nil end
  local land = self.guide.steps[target]
  if land and land.type == "accept" and land.quest then self:DroppedQuests()[land.quest] = nil end
  if land then self:SkipSteps()[stepKey(land)] = nil end
  self.index = target
  self:NoteLanding()
  self:Persist()
  self:AnnounceStep()
  return true
end

-- Otomatik ilerlemenin su an uzerinde olacagi adim: cepheden itibaren bitmis adimlar gecilir.
function Engine:CurrentIndex()
  if not self.guide then return nil end
  local player = P.PlayerInfo()
  if self:Strict() then return settle(self, 1, player) end   -- katı sıra: en kucuk yapilabilir bitmemis adim
  local i = settle(self, self:Frontier(), player)
  if self.db and self.db.pinOrder then return i end   -- "Pin guide order": hicbir geri cekme yok
  return pendingBehind(self, i, player) or overdueTurnin(self, i, player) or i
end

-- Geri cekme (geride kalan teslim, kacirilan kabul) cepheyi teslime indirir; kalinan yer resumeAt'ta. Sapma
-- birakilirken (Prev, sag tik) cephe kalinan yere geri cikar: oyuncu teslimden sonra eski bir adima dusmez.
-- Sag tikin "gunlukte bekleyen is" donusu (keepOrder) bilerek cepheyi indirir: sonraki kabuller sirayla gelsin.
function Engine:KeepReach()
  if self.resumeAt and self.pulledTo and self.resumeAt > self.pulledTo and not self.keepOrder then
    self:RaiseFrontier(self.resumeAt)
  end
  -- Planner'in sectigi sapmayi (pullFor) oyuncu biraktiysa yon fark etmeden reddedilmis sayilir: sonraki
  -- degerlendirme ayni teslime geri cekmez (sag tik / Prev ile sekme olmaz)
  if self.pulledTo and self.pullFor == self.pulledTo then
    self.detourRefused = self.detourRefused or {}
    self.detourRefused[self.pulledTo] = true
  end
  self.keepOrder = nil
end

-- Erken (Early) karsilastirmasinin cephesi: geri cekilmisken kalinan yer (resumeAt) sayilir; yoksa geride bir
-- teslime donmek aradaki adimlarda alinan quest'leri "erken" yapar.
function Engine:Reach()
  return math.max(self:Frontier() or self.index or 1, self.resumeAt or 0)
end

-- Geri gezinmeden sonra su anki (aktif) adima don. Dondurur: adim numarasi ya da nil.
function Engine:JumpToCurrent()
  if not self.guide then return nil end
  -- ileri sapmayi birakmak reddetmektir: ayni adima bu oturumda tekrar cekilmez (Next ile ayni)
  if self:OnForwardDetour() then
    self.detourRefused = self.detourRefused or {}
    self.detourRefused[self.index] = true
  end
  self:KeepReach()
  self.browsing, self.browseDone, self.manual, self.missedQuest = nil, nil, nil, nil
  self.pullYards, self.pullFor = nil, nil
  local player = P.PlayerInfo()
  if self:Strict() then
    self.resumeAt, self.pulledTo, self.detourReason, self.keepOrder, self.viewDone, self.chosen = nil, nil, nil, nil, nil, nil
    local target = settle(self, 1, player)
    self:RaiseFrontier(target)
    if target == self.index then return target end
    self.index = target
    self:Persist()
    if target > #self.guide.steps then finish(self) else self.finished = false; self:AnnounceStep() end
    return target
  end
  local settled = settle(self, self:Frontier(), player)
  -- teslime gelindi ama quest'in gemi adimi yapilmadi (cephe onu gecmis): once iskeleye
  local cur = self.guide.steps[settled]
  local travel = cur and self:PendingTravel(cur.quest)
  if travel and travel < settled then
    self:ResetFrontier(self.guide.id, travel)
    settled = travel
  end
  -- gunlukte bekleyen geride kalmis is: oraya donulur ve cephe oraya iner (sonraki kabuller sirayla gelsin);
  -- oyuncu acikca "su anki adim" istedi: o gorevin "gecildi" kaydi da silinir
  local pinned = self.db and self.db.pinOrder   -- "Pin guide order": sag tik da geri cekmez
  local pending = not pinned and pendingBehind(self, settled, player)
  if pending then
    local q = self.guide.steps[pending].quest
    self:SkippedTurnins()[q] = nil
    -- is bitince kalinan yere donulur; resumeAt "erken" karsilastirmasini da korur (Engine:Reach)
    self.resumeAt, self.pulledTo, self.detourReason = settled, pending, nil
    self.keepOrder = true
    self:ResetFrontier(self.guide.id, pending)
    self.viewDone = nil
    if pending ~= self.index then
      self.index = pending
      self.finished = false
      self:Persist()
      self:AnnounceStep()
    end
    return pending
  end
  local back = not pinned and overdueTurnin(self, settled, player)
  local target = back or settled
  if back then
    -- geride kalan teslime donuluyor: teslimden sonra kalinan yere devam edilsin
    self.resumeAt, self.pulledTo, self.detourReason = settled, back, nil
    self:ResetFrontier(self.guide.id, back)
  else
    self.resumeAt, self.pulledTo, self.detourReason = nil, nil, nil
    self:RaiseFrontier(target)
  end
  self.viewDone = nil
  if target == self.index then return target end
  self.index = target
  self:Persist()
  if target > #self.guide.steps then
    finish(self)
  else
    self.finished = false
    self:AnnounceStep()
  end
  return target
end

-- Aciklama metni
local function withNpc(text, npc)
  if npc then return text .. " (" .. npc .. ")" end
  return text
end

-- Meslegin { rank, max }'i ya da nil (ogrenilmemis). Meslek etkinligi modulunun onbellegi varsa o.
function Engine:ProfRank(name)
  -- onbellek yalniz modul acikken guncel (SKILL_LINES_CHANGED'i o dinler)
  local PA = ns.ProfActivity
  local cached = PA and PA.IsEnabled and PA:IsEnabled() and PA.ranks
  if cached then return cached[name] end
  for _, p in ipairs(P.ProfessionRanks()) do if p.name == name then return p end end
  return nil
end

local function rankName(max)
  if max <= 75 then return L["Apprentice"] elseif max <= 150 then return L["Journeyman"]
  elseif max <= 225 then return L["Expert"] end
  return L["Artisan"]
end

local function describeProf(s)
  local a, n = s.act, s.name or (s.item and P.ItemName(s.item)) or "?"
  if a == "train" then
    return withNpc(L["Train %s %s"]:format(rankName(s.max or 300), s.prof), s.npc)
  elseif a == "learn" then
    return withNpc(L["Learn the recipe: %s"]:format(n), s.npc)
  elseif a == "craft" then
    -- kaynak bazi adimlarda ne yapilacagini adlandirmiyor: tarif listesindeki turuncu/sari tarif
    if not s.name then return L["Craft orange or yellow recipes until skill %d"]:format(s.skill or 0) end
    local base = s.count and L["Craft %d %s"]:format(s.count, n) or L["Craft %s"]:format(n)
    return base .. " - " .. L["until skill %d"]:format(s.skill or 0)
  elseif a == "gather" then
    -- toplama alani: hangi damar / bitki, hangi bolge (seviyene uyan; rehberinki agirsa baska bolge, PG.GatherSpot)
    local spot = ns.ProfGuides and ns.ProfGuides.GatherSpot and ns.ProfGuides.GatherSpot(s)
    if spot and #spot.nodes > 0 then
      local fmt = s.prof == "Herbalism" and L["Pick %s around %s until skill %d"] or L["Mine %s around %s until skill %d"]
      local text = fmt:format(table.concat(spot.nodes, ", "), spot.zone, s.skill or 0)
      if spot.moved then text = text .. " " .. L["(%s is too high for your level)"]:format(spot.moved)
      elseif spot.tooHigh then text = text .. " " .. L["(dangerous at your level)"] end
      return text
    end
    return L["Raise %s to %d in this area"]:format(s.prof, s.skill or 0)
  elseif a == "buy" then
    return withNpc(L["Buy %d %s"]:format(s.count or 1, n), s.npc)
  end
  return L["Get %d %s"]:format(s.count or 1, n)
end

-- Meslek adimi eki: egitmen ucreti (biliniyorsa) ve cantada olmayan alet (ProfGuides PG.Fee / PG.MissingTools).
local function profExtras(s, text)
  local PG = ns.ProfGuides
  if not (PG and PG.MissingTools) then return text end
  if s.act == "train" then
    local fee = PG.Fee(s.max)
    if fee and ns.Suite and ns.Suite.FormatMoney then text = text .. " - " .. L["costs %s"]:format(ns.Suite.FormatMoney(fee)) end
  end
  if s.act == "train" or s.act == "craft" or s.act == "gather" then
    local r = Engine.ProfRank and Engine:ProfRank(s.prof)
    local miss = PG.MissingTools(s.prof, math.max(1, (r and r.rank) or s.skill or 1))
    if #miss > 0 then text = text .. " " .. L["(needs a %s)"]:format(table.concat(miss, ", ")) end
  end
  return text
end

function Engine:Describe(step)
  local custom = ns:LocalizedText(step.text)
  if custom then return custom end
  local t = step.type
  if t == "prof" then return profExtras(step, describeProf(step)) end
  if t == "accept" then
    return withNpc(L["Accept quest: %s"]:format(P.QuestName(step.quest, step.name)), step.npc)
  elseif t == "turnin" then
    return withNpc(L["Turn in quest: %s"]:format(P.QuestName(step.quest, step.name)), step.npc)
  elseif t == "complete" then
    if self:TravelObjective(step) then
      local zone   -- teslimin bolgesi (Dalaran: Alterac Mountains)
      for _, s in ipairs(self.guide and self.guide.steps or {}) do
        if s.type == "turnin" and s.quest == step.quest and s.zone then zone = s.zone break end
      end
      zone = zone or P.QuestName(step.quest, step.name)
      return L["Wait here for the ride to %s"]:format(zone)
    end
    local base = L["Complete quest: %s"]:format(P.QuestName(step.quest, step.name))
    -- hangi hedef: adimin kendi hedefi, yoksa ilk bitmemis hedef ("Al'Aketh Stormcaller slain: 1/6")
    local objs = step.quest and P.GetObjectives and P.GetObjectives(step.quest)
    local o = objs and step.objective and objs[step.objective]
    if objs and not step.objective then
      for _, x in ipairs(objs) do if not x.finished then o = x break end end
    end
    local text = o and o.text
    if P.NotSecret then text = P.NotSecret(text) end
    if type(text) == "string" and text ~= "" then return base .. " - " .. text end
    return base
  elseif t == "kill" then
    local text = L["Kill %s"]:format(step.npc or ("#" .. tostring(step.npcId)))
    return step.count and (text .. " x" .. step.count) or text
  elseif t == "collect" then
    if step.text then return ns:LocalizedText(step.text) end   -- rehberin kendi cumlesi (Bronze Tube satin al)
    local text = L["Collect item #%d"]:format(step.item)
    return step.count and (text .. " x" .. step.count) or text
  elseif t == "use" then
    return L["Use item #%d"]:format(step.item)
  elseif t == "talk" then
    return L["Talk to %s"]:format(step.npc)
  elseif t == "fly" then
    return L["Fly to %s"]:format(step.to or "?")
  elseif t == "hearth" then
    return L["Hearth to %s"]:format(step.to or "?")
  elseif t == "level" then
    return L["Reach level %d"]:format(step.level)
  elseif t == "goto" then
    if step.npc then return L["Talk to %s"]:format(step.npc) end   -- vendor / esya alma: hedefte bir NPC var
    -- koordinat yerine nereye gidildigi: "Head to: Complete Among the Faithful"
    local nxt = self:LeadsTo(step)
    if nxt then return L["Head to: %s"]:format(self:Describe(nxt)) end
    return L["Go to %.1f, %.1f"]:format(step.x * 100, step.y * 100)
  end
  return step.type
end

-- Yasam dongusu
local EVENTS = {
  "QUEST_ACCEPTED", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "QUEST_REMOVED",
  "UNIT_QUEST_LOG_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED",
  "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
}

function Engine:MarkDirty()
  self.dirty = true
end

function Engine:Tick(elapsed)
  self.acc = self.acc + (elapsed or 0)
  if self.acc < TICK then return end
  self.acc = 0
  if self.feedDue and not P.InCombat() then self:Feed() end
  local step = self:GetStep()
  local graph = ns.BrainData and ns.BrainData.graph
  -- konuma bagli adimlar her tikta: goto ve kosullu (gate) kabul (NPC yaninda bekleme)
  local poll = step and (step.type == "goto" or self:TravelObjective(step)
    or (step.type == "accept" and step.quest and graph and graph[step.quest] and graph[step.quest].gate))
  -- oyuncu son degerlendirmeden bu yana MOVE_REDECIDE yd yuruduyse rota yeniden tartilir (Planner onbellekli):
  -- kabul / teslim adimindayken yanina gelinen is de rotaya girer, pencere satiri ile motor ayni kalir
  local c, x, y = P.PlayerWorldPos()
  local last = self.evalFrom
  if c and not (last and last[1] == c and P.WorldDistance(c, x, y, last[1], last[2], last[3]) < self.MOVE_REDECIDE) then
    poll = true
  end
  -- olay gelmeden degisen kosullar (quest kabulunden hemen sonra hedef verisi, teslimden sonra onkosul) icin
  -- oyuncu kipirdamasa da REDECIDE_SECS'te bir yeniden tartilir: pencerenin "Next" satiri (Planner:Next, ~1 sn)
  -- 6 yd'deki isi gosterirken ok uzak adimda kaliyordu (Gatehouse Goods, 15 Kasim 2026)
  local now = P.Now()
  if not poll and not P.InCombat() and now - (self.evalAt or 0) >= self.REDECIDE_SECS then poll = true end
  if self.dirty or poll then
    self.dirty = false
    if c then self.evalFrom = { c, x, y } end
    self.evalAt = now
    self:Evaluate()
  end
end
Engine.MOVE_REDECIDE = 25
Engine.REDECIDE_SECS = 3

-- Quest teslim edilmeden gunlukten cikti (abandon): rehber o quest'in alma adimina doner. Yeniden alininca
-- bitmis adimlar kendiliginden gecilir, quest'in hedef adimlarinda durulur. Teslimde QUEST_REMOVED da gelir:
-- QUEST_TURNED_IN ile ayirt edilir, kontrol bir an sonra yapilir (olaylarin sirasi garanti degil).
function Engine:OnQuestRemoved(q)
  -- gunlukten cikan quest (teslim ya da birakma) artik "benimsenmis" degil: tablo buyumez, sonraki rehberde erken
  -- alinirsa yine "Early" gorunur
  if q and self.char and self.char.adopted and not P.IsQuestInLog(q) then self.char.adopted[q] = nil end
  if not (self.guide and q) or (self.turnedIn and self.turnedIn[q]) then return false end
  if P.IsQuestFlaggedCompleted(q) or P.IsQuestInLog(q) then return false end
  -- yalniz rehber bu quest'e ileride hala ihtiyac duyuyorsa geri donulur
  local needed = false
  for j = self.index, #self.guide.steps do
    if self.guide.steps[j].quest == q then needed = true break end
  end
  if not needed then return false end
  -- aninda geri atlanmaz (cephe bozulur, aradaki quest'ler "erken" olurdu): quest'in sonraki adimina gelinince
  -- kacirilan kabul (missedAccept) kalinan yeri hatirlayarak kabule ceker; su anki adim oysa hemen.
  return self:Evaluate()
end

-- Forever verisiyle yeniden kurulan rehberlerin eski kimlikleri: kayitli rehber yeni rehbere tasinir. Adimlar
-- farkli oldugu icin bastan baslanir (bitmis adimlar kendiliginden gecilir).
Engine.RENAMED = { ["horde-1-12-orc"] = "horde-1-12-durotar", ["horde-1-12-troll"] = "horde-1-12-durotar" }

-- Kayitli rehbere kaldigi yerden devam et.
-- Rehberin icerik imzasi: adim sayisi + adim turleri ve quest'lerin ozeti. Rehber guncellenince (adimlar
-- kayinca) kayitli adim numarasi baska bir adimi gosterir; imza degistiyse bastan yerlesilir.
function Engine.GuideSig(guide)
  local h = 0
  for _, s in ipairs(guide.steps) do h = (h * 31 + (s.quest or 0) + #s.type) % 2147483647 end
  return #guide.steps .. ":" .. h
end

-- Kayitli adim numarasi baska bir rehber surumune mi ait (addon guncellendi, adimlar kaydi)? Oyleyse quest'i olan ilk
-- bitmemis adima yerlesir (goto/talk atlanir; uzaktaki bir goto'da takilmasin), cephe ve rehber ilerlemesi oraya
-- cekilir; doner: yeni adim ya da nil. Imzasiz eski kayit benimsenir. Etkin rehber kadar acik sekmeler icin de
-- (SetGuide kayitli ilerlemeyle girerken) calisir.
function Engine:Reseat(id, guide)
  if not (self.char and guide) then return nil end
  self.char.sig = self.char.sig or {}
  guide._sig = guide._sig or Engine.GuideSig(guide)
  local sig, at = guide._sig, nil
  if self.char.sig[id] ~= nil and self.char.sig[id] ~= sig then
    local player = P.PlayerInfo()
    at = #guide.steps + 1
    for j, s in ipairs(guide.steps) do
      if s.quest and not s.sticky and self:IsVisible(s, player) and isComplete(s) == false then at = j break end
    end
    self:ResetFrontier(id, at)
    if self.char.progress then self.char.progress[id] = nil end
  end
  self.char.sig[id] = sig
  return at
end

function Engine:RestoreSaved()
  local id = self.char.guide
  if id and not Guides:Get(id) and self.RENAMED[id] then
    id = self.RENAMED[id]
    self.char.guide, self.char.index = id, 1
    self:ResetFrontier(id, 1)
  elseif id and not Guides:Get(id) and not Guides.rejected[id] and id:match("^%a+%-%d+%-%d+%-") then
    -- (sema hatasiyla reddedilen guncel rehberin kaydi korunur; duzelince geri gelir)
    -- kaldirilan eski (Cataclysm) rehber: karaktere uygun Forever rehberine gecilir. Kayit/zindan rehberleri
    -- bu kaliba uymaz; onlar sonradan kaydolunca ARCANIS_GUIDE_REGISTERED ile gelir.
    local g = Guides:Suggest(P.PlayerInfo())
    id = g and g.id
    self.char.guide, self.char.index = id, 1
    if id then self:ResetFrontier(id, 1) end
  end
  local guide = id and Guides:Get(id)
  if guide then
    -- kayitli adim numarasi rotaya gore (besleyici adimlar dahil): imza da rota uzerinden karsilastirilir
    local at = self:Reseat(id, self:RouteOf(id))
    if at then self.char.index = at end
  end
  if guide then
    self:SetGuide(id, self.char.index)
    -- kayitli yer oyuncunun kaldigi yerdir, geri gezinme degil: bitmisse kendiliginden ilerlesin
    if self.viewDone or self.manual then self.viewDone, self.manual = nil, nil; self:Evaluate() end
  end
end

-- Eski kayit (char.notOffered: true = pencereden, sayi = NPC yaninda bekleme): pencere isaretleri char.refused'a
-- gecer, sureli isaretler duser. offerV < 2 kayitlarinda "true" NPC'nin yanindan gecmekle de yaziliyordu: alinmaz.
function Engine:MigrateMarks()
  local c = self.char
  if not c then return end
  if c.notOffered then
    c.refused = c.refused or {}
    if (c.offerV or 0) >= 2 then
      for q, v in pairs(c.notOffered) do
        if v == true then c.refused[q] = { level = P.PlayerLevel() } end
      end
    end
    c.notOffered = nil
  end
  c.offerV = nil
end

-- "Verilmiyor" isaretleri yeniden denenir (seviye atlandi, bir teslim yapildi: quest artik veriliyor olabilir).
-- Kosullu (gate) quest'in isareti kalir: meslek / itibar degismedi; onu yalniz NPC'nin listesi siler.
-- turned: teslim edilen quest (nil = seviye atlandi, hepsi silinir). Teslimde yalniz o teslimin acabilecegi
-- "verilmiyor" kayitlari silinir: teslim edilen quest verideki onkosul kapanisinda. Eskiden her teslim hepsini
-- siliyordu; "ayni NPC'ye teslim de siler" kurali da Marris'e Missing In Action teslim edilince Shadow Magic'e geri
-- attirdi, kaldirildi (18 Kasim 2026).
local function unlocks(graph, q, t, depth, seen)
  local g = graph[q]
  if not g or depth <= 0 or seen[q] then return false end
  seen[q] = true
  for _, list in ipairs({ g.any or {}, g.all or {} }) do
    for _, p in ipairs(list) do
      if p == t or unlocks(graph, p, t, depth - 1, seen) then return true end
    end
  end
  return false
end

function Engine:ClearRefused(turned)
  -- Brain'in "veren yok" kaydi da: posta kutusu / satici yanindaki verenin noktasinda 6 sn durmak gorevi kalici
  -- gizliyordu (denetim, 15 Kasim 2026); seviye ve teslimde yeniden denenir
  if self.char then self.char.giverMissing = nil end
  local r = self.char and self.char.refused
  if r then
    local graph = ns.BrainData and ns.BrainData.graph or {}
    for q, v in pairs(r) do
      -- seviye atlamak, quest'in seviyesinin 3+ ustundeyken verilmeyen quest'i acmaz (Marris 115'i 29'da vermedi)
      local lv = graph[q] and graph[q].lv
      local leveled = not turned and not (type(v) == "table" and v.level and lv and v.level >= lv + 3)
      if not (graph[q] and graph[q].gate) and (leveled or (turned and unlocks(graph, q, turned, 6, {}))) then
        r[q] = nil
      end
    end
  end
  self:MarkDirty()
end

-- Oyuncunun bilerek atladigi quest (butun rehberlerde): adimlari gecilir, ona bagli quest'ler de ("never" zinciri).
function Engine:QuestSkipped(q)
  local t = self.char and self.char.skipQuest
  return t and q and t[q] == true or false
end

function Engine:SkipQuest(q, on)
  if not (q and self.char) then return end
  self.char.skipQuest = self.char.skipQuest or {}
  self.char.skipQuest[q] = on and true or nil
  self:MarkDirty()
end

-- NPC'nin verdigi quest'ler (kimlik ya da ad kumesi): rotada bu NPC'den alinacak kosullu (gate) quest'lerden
-- listede olmayanlar "verilmiyor" (char.refused); sonradan listede gorulurse kayit silinir.
Engine.LIST_PICK = 30   -- sn: ayni NPC'nin listesinden bu kadar sonra acilan tek quest penceresi listeden secilmistir

function Engine:NoteOffered(npc, ids, titles, listed)
  if not (self.guide and self.char and type(npc) == "string") then return end
  local graph = ns.BrainData and ns.BrainData.graph or {}
  local c = self.char
  c.refused, c.offered = c.refused or {}, c.offered or {}
  -- NPC'nin gosterdigi quest'ler verilir: "verilmiyor" isaretleri kalkar (rehber disi veren onerileri dahil). Veri
  -- quest'i kapali sayiyorsa (seviye, onkosul, esya) NPC hakli: char.offered, veri duzeltme adayi olarak yazilir.
  for q in pairs(ids or {}) do
    c.refused[q] = nil
    if self.gated then self.gated[q] = nil end
    if c.giverMissing then c.giverMissing[q] = nil end
    if not c.offered[q] and not self:InLog(q) then
      local st, why, ref = QS:Status(q)
      if st == "wait" or (st == "never" and why == "chain") then
        c.offered[q] = true
        ns:Debug(("data-fix candidate: quest %d is offered by %s, the data says %s %s"):format(q, npc, tostring(why), tostring(ref or "")))
      end
    end
  end
  local B = ns.Brain
  for _, s in ipairs(self.guide.steps) do
    -- kosullu quest her pencerede; digerleri yalniz NPC'nin tam listesi gorunurken ve grafige gore alinabilirken
    -- (rota verisindeki bazi quest'ler Forever'da o NPC'de yok: ornek Westfall "Harvesting the Harvesters" 92911)
    -- kosulsuz quest yalniz kimlik listesiyle (gossip) yargilanir: selamlama penceresi yalniz baslik verir ve rehberdeki
    -- ad Forever'daki basliktan farkli olabilir (yanlis "verilmiyor" adimlari sessizce gecirirdi)
    -- (pahali CanAccept yalniz bu NPC'nin kabul adimlarinda)
    if s.type == "accept" and s.quest and s.npc == npc then
      local g = graph[s.quest]
      local free = g and not g.gate and listed and B and B.CanAccept and B:CanAccept(s.quest) == true
      local gameName = titles and P.QuestName and P.QuestName(s.quest)
      -- selamlama penceresi yalniz baslik verir: oyunun bu quest icin bildigi baslik varsa (istemci verisi) onunla
      -- yargilanir. Eskiden hic yargilanmiyordu: cok gorevli NPC'lerde (Marris) verilmeyen quest'e hep geri gonderiyordu.
      local named = gameName and not gameName:find("^#")
      local check = g and (g.gate or (free and (ids or named)))
      local offered = (ids and ids[s.quest]) or (titles and ((s.name and titles[s.name]) or (gameName and titles[gameName])))
      if check then
        local refused = not offered and not self:InLog(s.quest)
        c.refused[s.quest] = refused and { npc = npc, level = P.PlayerLevel() } or nil
        if refused then c.offered[s.quest] = nil end   -- son liste gecerli: eski "verdi" kaydi "verilmiyor"u ortmesin
      elseif free and offered then
        c.refused[s.quest] = nil   -- yalniz baslik: isaret konmaz, ama gorulen quest'in eski isareti kalkar
      end
    end
  end
  self:MarkDirty()
end

-- NPC'nin gercek yeri: quest / gossip penceresi acikken oyuncu NPC'nin yanindadir. Rehberdeki NPC'ler icin
-- konum hesap geneli saklanir (db.npcPos[ad] = { map, x, y }); Zones:Location rehber koordinati ve oyunun
-- isaretinden once bunu kullanir (referans rotalarin koordinati bazen onlarca yard sapiyor).
function Engine:LearnNpc()
  local name = P.NpcName()
  if not (name and self.guide and self.db) then return end
  if self.npcSetFor ~= self.guide then
    self.npcSet, self.npcSetFor = {}, self.guide
    for _, s in ipairs(self.guide.steps) do if s.npc then self.npcSet[s.npc] = true end end
  end
  if not self.npcSet[name] then return end
  local map, x, y = P.PlayerMapPosition()
  if not map then return end
  self.db.npcPos = self.db.npcPos or {}
  self.db.npcPos[name] = { map, math.floor(x * 10000 + 0.5) / 10000, math.floor(y * 10000 + 0.5) / 10000 }
end

function Engine:NpcSpot(name)
  local t = name and self.db and self.db.npcPos
  return t and t[name]
end

-- Meslek kamp quest'i hatirlatmasi (Skyborne "Camping 101: <meslek>"): bildigin meslegin kamp quest'i rehberde
-- varsa ve henuz alinmadiysa onerilir; rota zorlanmaz (adim penceresinin en altinda). { { prof, step }, ... }
function Engine:CampReminders()
  local out = {}
  if not (self.guide and self.db and self.db.campReminder) then return out end
  local profs = P.Professions and P.Professions() or {}
  if not next(profs) then return out end
  local player = P.PlayerInfo()
  local seen = {}
  for _, s in ipairs(self.guide.steps) do
    local prof = s.type == "accept" and s.quest and s.name and s.name:match("^Camping 101: (.+)$")
    if prof and profs[prof] and not seen[s.quest] and self:IsVisible(s, player)
        and not self:InLog(s.quest) and not P.IsQuestFlaggedCompleted(s.quest) then
      seen[s.quest] = true
      out[#out + 1] = { prof = prof, step = s }
    end
  end
  return out
end

function Engine:OnGossipQuests()
  local avail, active = P.GossipQuests()
  if not avail then return end
  local ids = {}
  for _, list in ipairs({ avail, active or {} }) do
    for _, q in ipairs(list) do if q.questID then ids[q.questID] = true end end
  end
  self:NoteOffered(P.NpcName(), ids, nil, true)
end

function Engine:OnEnable()
  for _, event in ipairs(EVENTS) do ns:On(event, self, "MarkDirty") end
  -- seviye / beceri degisince adim gorunurlugu (trainer, gri) degisir: "Head to" onbellegi yenilenir
  -- seviyesi gelen eksik zincir rotaya eklenir (savas bitince: Tick)
  ns:On("PLAYER_LEVEL_UP", self, function(o) o.leadsGen = (o.leadsGen or 0) + 1; o.feedDue = true; o:ClearRefused() end)
  ns:On("SKILL_LINES_CHANGED", self, function(o) o.leadsGen = (o.leadsGen or 0) + 1; o:MarkDirty() end)
  local offer = self.offerWatch or {}
  self.offerWatch = offer
  -- listeli pencere (gossip / selamlama) tum verilenleri gosterir; tek quest penceresi (QUEST_DETAIL) yalniz
  -- listesi olmayan NPC'de sayilir (listeden secilen tek quest digerlerini "verilmiyor" yapmasin)
  ns:On("GOSSIP_SHOW", offer, function()
    Engine.listedNpc, Engine.listedAt = P.NpcName(), P.Now()
    Engine:LearnNpc(); Engine:OnGossipQuests()
    Engine:NoteEscort(Engine.listedNpc)   -- eskort NPC'si ile konusuldu: ok varis yerine
  end)
  ns:On("QUEST_GREETING", offer, function()
    Engine.listedNpc, Engine.listedAt = P.NpcName(), P.Now()
    Engine:LearnNpc()
    Engine:NoteOffered(Engine.listedNpc, nil, P.GreetingTitles(), true)
  end)
  -- Listesiz acilan tek quest penceresi = NPC'nin su an verdigi tek quest: tam liste sayilir (18 Kasim 2026: Marris
  -- dogrudan Blackrock Blockade'i acti, rehber Shadow Magic'i istemeye devam ediyordu). Listeden secilen quest'in
  -- penceresi (ayni NPC'nin listesi az once gorundu) sayilmaz.
  ns:On("QUEST_DETAIL", offer, function()
    Engine:LearnNpc()
    local q, npc = P.QuestID(), P.NpcName()
    if not (q and npc) then return end
    local fromList = npc == Engine.listedNpc and P.Now() - (Engine.listedAt or 0) < Engine.LIST_PICK
    Engine:NoteOffered(npc, { [q] = true }, nil, not fromList)
  end)
  ns:On("QUEST_PROGRESS", offer, function() Engine:LearnNpc() end)
  ns:On("QUEST_COMPLETE", offer, function() Engine:LearnNpc() end)
  self.frame = self.frame or CreateFrame("Frame")
  self.frame:SetScript("OnUpdate", function(_, elapsed) Engine:Tick(elapsed) end)
  self:MigrateMarks()
  self:RestoreSaved()
  -- ayri sahip: ayni olaylarin MarkDirty kaydini ezmesin
  local watch = self.questWatch or {}
  self.questWatch = watch
  ns:On("QUEST_TURNED_IN", watch, function(_, _, q)
    if q then Engine.turnedIn = Engine.turnedIn or {}; Engine.turnedIn[q] = true end
    Engine:ClearRefused(q or 0)
    Engine.lookEnd = true   -- oyuncu is yapti: bitmis adima / ileri bakis biter
  end)
  ns:On("QUEST_ACCEPTED", watch, function(_, _, a, b)
    Engine.lookEnd = true
    -- Forever: (questId); eski istemci: (index, questId)
    local q = (type(b) == "number" and b) or (type(a) == "number" and a) or nil
    if q then
      Engine:Adopt(q)
      -- gunluk hemen guncellenmeyebilir: eskort kontrolu biraz sonra
      if not P.After(0.5, function() Engine:NoteEscortAccept(q) end) then Engine:NoteEscortAccept(q) end
    end
  end)
  ns:On("QUEST_REMOVED", watch, function(_, _, q)
    if q and not P.After(0.5, function() Engine:OnQuestRemoved(q) end) then Engine:OnQuestRemoved(q) end
  end)
  -- Sonradan kaydolan rehberler (kayit, zindan rehberi): kayitli rehber gelince geri yukle.
  ns:Listen("ARCANIS_GUIDE_REGISTERED", self, function(o, _, id)
    if not o.guide and o.char.guide and id == o.char.guide then
      o:SetGuide(id, o.char.index)
      if o.viewDone or o.manual then o.viewDone, o.manual = nil, nil; o:Evaluate() end   -- kayitli yer: bitmisse ilerlesin
    end
  end)
end

function Engine:OnDisable()
  if self.frame then self.frame:SetScript("OnUpdate", nil) end
end

-- Komutlar
local function showStep()
  local step = Engine:GetStep()
  if not Engine.guide then
    ns:Print(L["No active guide. Use /wf guides, /wf guide <id> or /wf suggest"])
  elseif not step and Engine:IsBlocked() then
    local n = 0
    for _, w in ipairs((Engine:Waiting())) do n = n + #w.quests end
    ns:Print(Guides:TitleOf(Engine.guide) .. ": " .. L["%d quests are waiting"]:format(n))
  elseif not step then
    ns:Print(L["%s: guide finished."]:format(Guides:TitleOf(Engine.guide)))
  else
    local i, n = Engine:GetProgress()
    ns:Print(("%s [%d/%d] %s"):format(Guides:TitleOf(Engine.guide), i, n, Engine:Describe(step)))
  end
end

ns:RegisterCommand("guide", function(args)
  if args == "" then showStep() return end
  local ok, err = Engine:SetGuide(args)
  if not ok then ns:Print(err) else showStep() end
end, "<id> start a guide")

ns:RegisterCommand("suggest", function()
  local guide = Guides:Suggest(P.PlayerInfo())
  if not guide then ns:Print(L["No suitable guide for this character."]) return end
  Engine:SetGuide(guide.id)
  showStep()
end, "start the suggested guide for this character")

ns:RegisterCommand("next", function() Engine:Next() showStep() end, "go to the next step")
ns:RegisterCommand("prev", function() Engine:Prev() showStep() end, "go back one step")
ns:RegisterCommand("step", showStep, "show the current step")

-- Teshis: bir quest'in (verilmezse su anki adimin quest'i) durumu ve nedeni; oyuncu "NPC'de yok" deyince sorulur
ns:RegisterCommand("quest", function(args)
  local step = Engine:GetStep()
  local skip, rest = (args or ""):match("^%s*(%a+)%s*(.-)%s*$")
  if skip ~= "skip" and skip ~= "unskip" then skip, rest = nil, args end
  local q = tonumber(rest) or (step and step.quest)
  if not q then ns:Print("No quest on this step. Use /wf quest <id>.") return end
  if skip then   -- /wf quest skip|unskip [id]: adim penceresi menusundeki "Skip this quest" ile ayni
    Engine:SkipQuest(q, skip == "skip")
    ns:Print(("%s %d %s"):format(skip, q, tostring(P.QuestName(q))))
    return
  end
  local st, why, ref, root = QS:Status(q)
  local g = ns.BrainData and ns.BrainData.graph and ns.BrainData.graph[q] or {}
  local function list(t) local o = {} for _, x in ipairs(t or {}) do o[#o + 1] = tostring(x) end return table.concat(o, ",") end
  local c = Engine.char or {}
  ns:Print(("Quest %d %s: done=%s inLog=%s status=%s %s %s %s"):format(q, tostring(P.QuestName(q)),
    tostring(P.IsQuestFlaggedCompleted(q)), tostring(Engine:InLog(q)), tostring(st), tostring(why or ""),
    tostring(ref or ""), tostring(root or "")))
  print(("  level %s  any {%s}  all {%s}  offered=%s refused=%s"):format(tostring(g.lv), list(g.any), list(g.all),
    tostring(c.offered and c.offered[q] or false), tostring(c.refused and c.refused[q] and true or false)))
  for _, p in ipairs(g.any or g.all or {}) do
    print(("  pre %d %s: done=%s inLog=%s status=%s"):format(p, tostring(P.QuestName(p)),
      tostring(P.IsQuestFlaggedCompleted(p)), tostring(Engine:InLog(p)), tostring((QS:Status(p)))))
  end
end, "[id] why a quest is (not) offered")
ns:RegisterCommand("stop", function() if Engine:StopGuide() then ns:Print(L["Guide stopped. Pick a guide to continue."]) end end,
  "stop the guide (progress is kept)")

ns:RegisterCommand("probe", function(args)
  local questId = tonumber(args)
  local function yn(v) return v and "|cff00ff00present|r" or "|cffff4040missing|r" end
  ns:Print("API paths:")
  print("  C_QuestLog.GetLogIndexForQuestID: " .. yn(C_QuestLog and C_QuestLog.GetLogIndexForQuestID))
  print("  C_QuestLog.IsQuestFlaggedCompleted: " .. yn(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted))
  print("  C_QuestLog.IsComplete: " .. yn(C_QuestLog and C_QuestLog.IsComplete))
  print("  C_QuestLog.GetQuestObjectives: " .. yn(C_QuestLog and C_QuestLog.GetQuestObjectives))
  print("  C_Map.GetWorldPosFromMapPos: " .. yn(C_Map and C_Map.GetWorldPosFromMapPos))
  print("  C_Map.GetPlayerMapPosition: " .. yn(C_Map and C_Map.GetPlayerMapPosition))
  print("  GetQuestLogTitle: " .. yn(GetQuestLogTitle))
  if questId then
    ns:Print("Quest " .. questId .. ":")
    print("  in log: " .. tostring(P.IsQuestInLog(questId)))
    print("  turned in: " .. tostring(P.IsQuestFlaggedCompleted(questId)))
    print("  objectives complete: " .. tostring(P.IsQuestComplete(questId)))
    local objectives = P.GetObjectives(questId)
    print("  objective count: " .. tostring(objectives and #objectives))
  end
  local step = Engine:GetStep()
  local map, x, y
  if step then map, x, y = ns.Zones:Location(step) end   -- "a and f()" yalniz ilk degeri birakir
  if map then
    print("  distance to active step (yd): " .. tostring(P.DistanceTo(map, x, y)))
  end
end, "[questID] test game API paths")
