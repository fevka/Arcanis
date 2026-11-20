-- Arcanis: quest durumu (ns.QuestState). "Bu quest bu karakter icin ne durumda" sorusunun tek cevap yeri;
-- Engine (adim durumu), Brain (CanAccept), Route ve zindan rehberleri (zincir yuruyusu QS.Walker) buradan sorar.
--
--   QS:Status(q) -> durum, neden, ref, kok
--     "done"                                  teslim edildi (bayrak ya da bu oturumda)
--     "held",  "ready" | "progress"           gunlukte
--     "open"                                  alinabilir (kosullu quest de: karari NPC'nin penceresi verir)
--     "wait",  "level", seviye                gereken seviye gelmedi
--              "pre", kok quest               onkosul zinciri eksik ve rota onu getirmiyor
--              "item", esya                   baslatan esya cantada yok
--              "refused"                      NPC'nin tam listesinde yoktu (char.refused)
--              "gate"                         kosullu quest: NPC'nin yaninda duruldu, quest gelmedi (oturumluk)
--            zincirin koku bekliyorsa (esya, verilmiyor, seviye) quest kokun nedenini tasir; 4. deger kok quest
--     "never", "closed", kapatan quest        dislayan / zincirde sonraki bitti, seviye ust siniri
--              "skipped"                      oyuncu kabulu bilerek gecti (Engine:DroppedQuests)
--              "chain", kok quest             zincirin koku artik alinamaz ya da birakildi
--     "unknown"                               grafikte yok: "open" gibi davranilir
--   QS:Pre(q) -> "met" | "coming" | "missing", kok, kokun durumu, nedeni, ref'i
--     coming: eksik onkosul gunlukte ya da etkin rota onu bu quest'ten once aldiriyor (Engine:Brings)
--
-- NPC kaniti (karakter kaydi, Engine:NoteOffered yazar):
--   char.offered[q] = true             NPC quest'i listeledi ama veri onu kapali sayiyordu: veri engeli artik yok sayilir
--   char.refused[q] = { npc, level }   NPC'nin tam listesinde yoktu; seviye atlayinca, bir teslimde ya da sonraki bir
--                                      liste gosterince silinir (kosullu quest yalniz liste gosterince)
--   Engine.gated[q]                    kosullu quest'in NPC'si pencere acmadi (yaninda bekleme); oturumluk
-- Kural sirasi: done, held, skipped, closed, offered (open), refused, item, level, pre, gate, open.
local _, ns = ...

local P = ns.Provider

local QS = {}
ns.QuestState = QS

local DEPTH = 8        -- onkosul zinciri en cok bu kadar geriye izlenir

local function graph() return ns.BrainData and ns.BrainData.graph end

local function done(q)
  local E = ns.Engine
  return P.IsQuestFlaggedCompleted(q) or (E and E.turnedIn and E.turnedIn[q]) or false
end

local function held(q)
  local E = ns.Engine
  if E and E.InLog then return E:InLog(q) end
  return P.IsQuestInLog(q)
end

-- Onkosul bitti mi? Dislayan alternatiflerinden (sinif / irk varyanti) biri bittiyse de sayilir.
local function preDone(p)
  if done(p) then return true end
  local g = graph() and graph()[p]
  for _, x in ipairs((g and g.ex) or {}) do if done(x) then return true end end
  return false
end

function QS:PreDone(p) return preDone(p) end

-- NPC kaniti: char.offered / char.refused kaydi ya da nil
local function mark(name, q)
  local E = ns.Engine
  local t = E and E.char and E.char[name]
  return t and t[q]
end

function QS:Offered(q) return mark("offered", q) == true end

-- Quest'i baslatan esya (Data/Brain/QuestItems.lua `starts`) ya da nil. Dizin bir kez kurulur.
function QS:StartItem(q)
  if not self.startItem then
    self.startItem = {}
    for item, e in pairs(ns.BrainData and ns.BrainData.items or {}) do
      if e.starts then self.startItem[e.starts] = item end
    end
  end
  return self.startItem[q]
end

-- Esyayla baslayan quest'in esyasi cantada degil (quest alinmamis): esya kimligi, yoksa nil.
function QS:ItemWaiting(q)
  local item = self:StartItem(q)
  if not item or held(q) or done(q) then return nil end
  return (P.ItemCount(item) or 0) == 0 and item or nil
end

-- Geri donmeyen kapanis: kapatan quest (ya da seviye siniri icin true), yoksa nil. Kosullu quest sayilmaz.
local function closedBy(g)
  if g.gate then return nil end
  for _, x in ipairs(g.ex or {}) do if done(x) then return x end end
  -- yonlendirme (breadcrumb): hedef gorev alindiysa (gunlukte ya da bitti) NPC artik vermez
  if g.bc and (done(g.bc) or held(g.bc)) then return g.bc end
  if g.nx and done(g.nx) then return g.nx end
  if g.untilq and done(g.untilq) then return g.untilq end
  if g.maxlv and (P.PlayerLevel() or 1) > g.maxlv then return true end
  return nil
end

function QS:Closed(q)
  local g = graph() and graph()[q]
  if not g or done(q) or P.IsQuestInLog(q) then return false end
  return closedBy(g) ~= nil
end

-- Ortak zincir yuruyusu: bir quest'in onkosul kapanisi, derinlik once (besleyici plan Route:Missing ve zindan
-- rehberleri DG:Plan ayni yuruyusu kullanir; hangi onkosulun aday oldugunu cagiranin `pick`i soyler).
--   pick(q) -> "any", adaylar   cozulen ilk aday secilir; hicbiri cozulmezse q tikali
--              "all", adaylar   hepsi cozulmeli
--              nil              q tikali
--   w.visit(q) -> cozuldu mu;  w.deps[q] = secilen onkosullar, w.seen = cozulenler, w.order = cozulenler (kok once)
-- Dongu ve `max` derinlik asimi: o dal bagimliliksiz kabul edilir (kaydedilmez).
function QS.Walker(pick, max)
  local w = { deps = {}, seen = {}, order = {} }
  local visiting, blocked = {}, {}
  local function visit(q, depth)
    if w.seen[q] then return true end
    if blocked[q] then return false end
    if visiting[q] or depth > max then return true end
    visiting[q] = true
    local mode, cands = pick(q)
    local list, ok = {}, mode ~= nil
    if mode == "any" then
      local cyclic = false
      for _, p in ipairs(cands) do
        if visiting[p] then cyclic = true
        elseif visit(p, depth + 1) then list[1] = p break end
      end
      if #list == 0 and not cyclic then ok = false end
    elseif ok then
      for _, p in ipairs(cands) do
        if not visiting[p] then
          if visit(p, depth + 1) then list[#list + 1] = p else ok = false end
        end
      end
    end
    visiting[q] = nil
    if ok then
      w.deps[q], w.seen[q] = list, true
      w.order[#w.order + 1] = q
    else
      blocked[q] = true
    end
    return ok
  end
  w.visit = function(q) return visit(q, 0) end
  return w
end

-- Tek onkosul: "met" | "coming" | "missing", kok, kokun durumu, nedeni, ref'i
local function one(self, p, q, depth)
  if preDone(p) then return "met" end
  if held(p) then return "coming" end
  if depth <= 0 then return "missing", p, "open" end
  local st, why, ref, root = self:Status(p, depth - 1)
  if st == "never" then return "missing", why == "chain" and ref or p, "never" end
  if st == "wait" then
    if why == "pre" then return "missing", ref, "open" end   -- kok daha derinde
    return "missing", root or p, "wait", why, ref
  end
  local E = ns.Engine
  if E and E.Brings and E:Brings(p, q) then return "coming" end
  return "missing", p, "open"
end

function QS:Pre(q, depth)
  local g = graph() and graph()[q]
  if not g then return "met" end
  depth = depth or DEPTH
  if g.any and #g.any > 0 then   -- "any" varsa "all" dikkate alinmaz; biri yeter
    local coming, root, rst, rwhy, rref
    for _, p in ipairs(g.any) do
      local s, r, a, b, c = one(self, p, q, depth)
      if s == "met" then return "met" end
      if s == "coming" then
        coming = true
      elseif root == nil or (rst == "never" and a ~= "never") then   -- hala mumkun olan alternatif kok olur
        root, rst, rwhy, rref = r, a, b, c
      end
    end
    if coming then return "coming" end
    return "missing", root, rst, rwhy, rref
  end
  local out = "met"
  for _, p in ipairs(g.all or {}) do
    local s, r, a, b, c = one(self, p, q, depth)
    if s == "missing" then return "missing", r, a, b, c end
    if s == "coming" then out = "coming" end
  end
  return out
end

function QS:Status(q, depth)
  if not q then return "unknown" end
  if done(q) then return "done" end
  if held(q) then return "held", P.IsQuestComplete(q) and "ready" or "progress" end
  local E = ns.Engine
  if E and ((E.guide and E:DroppedQuests()[q]) or (E.QuestSkipped and E:QuestSkipped(q))) then return "never", "skipped" end
  local g = graph() and graph()[q]
  local by = g and closedBy(g)
  if by then return "never", "closed", by ~= true and by or nil end
  if mark("offered", q) then return "open" end   -- NPC verdi: verideki engel (seviye, onkosul, esya) yanlis
  if mark("refused", q) then return "wait", "refused" end
  local item = self:ItemWaiting(q)
  if item then return "wait", "item", item end
  if not g then return "unknown" end
  if g.lv and (P.PlayerLevel() or 1) < g.lv then return "wait", "level", g.lv end
  local pre, root, rst, rwhy, rref = self:Pre(q, depth)
  if pre == "missing" then
    if rst == "never" then return "never", "chain", root end
    if rst == "wait" then return "wait", rwhy, rref, root end
    return "wait", "pre", root
  end
  if E and E.gated and E.gated[q] then return "wait", "gate" end
  return "open"
end
