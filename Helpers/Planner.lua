-- Arcanis Planlayici (modul "Planner", yalniz oneri): Gorev Beyni'nin adaylarini sureyle tartar ve tek bir
-- "sirada bu var" karari verir. Rehber onceliklidir: bir aday ancak belirgin sure kazandiriyorsa one gecer.
-- Rehber sirasi ve ok degismez; karar adim penceresinde gorunur, tiklaninca ok o adaya doner.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Planner = ns:NewModule("Planner", { defaults = { enabled = true, share = 0.15, minSave = 20 } })
ns.Planner = Planner

local RUN = 7            -- yd/s; Travel yoksa
local LOOKAHEAD = 40     -- rehberde ileriye bakilan adim sayisi
local SAME_QUEST_MAX = 400   -- yd: ayni quest'in baska hedefi bu kadar yakinsa aday
local SAME_QUEST_GAIN = 0.7  -- ...ve su anki hedeften en az %30 yakinsa
local KEEP = 1.25        -- secili oneri, yenisi bu kat daha iyi degilse degismez
local REFRESH = 1.5      -- saniye
local ACTION = { turnin = 8, accept = 8, talk = 8, objective = 60, complete = 60, kill = 60, collect = 60, use = 30 }
local QUEST_KIND = { turnin = true, accept = true, objective = true }
local OBJECTIVE = { complete = true, kill = true, collect = true, use = true }
local REACH = 1000       -- yd: bundan uzak hazir teslim aday olmaz (sure hesabi zaten eler; tarama sinirli kalsin)
local BEHIND_LATER = 1500   -- yd: geride kalmis teslimi rehber bir daha gostermez; yapilmazsa kayip

local function now() return (GetTime and GetTime()) or os.time() end

local function dist(a, b)
  if not (a and b) or a[1] ~= b[1] then return nil end
  return P.WorldDistance(a[1], a[2], a[3], b[1], b[2], b[3])
end

function Planner:Speed()
  return (ns.Travel and ns.Travel.Speed and ns.Travel:Speed()) or RUN
end

-- Rehber bu adaydan uzaklasacak mi? Uzaklastigi ilk adimin konumu; rehber adaya (index) ayni bolgede
-- kendisi varacaksa ya da bakilan pencerede bolgeden hic cikmiyorsa nil (ozel bir donus yolculugu gerekmez).
function Planner:AwayFrom(E, loc, index, player)
  local steps, idx = E.guide.steps, E.index
  -- "ayni yer" yaricapi (40 yd): rehber bunun disina gidip adaya geri gelecekse donus yolu kazanilir
  local hub = (ns.Brain.db and ns.Brain.db.hubYards) or 40
  -- su anki adim da sayilir: rehber once oraya (uzaga) gonderiyorsa aday icin geri donulecek
  for k = idx, math.min(#steps, idx + LOOKAHEAD) do
    if k == index then return nil end
    local s = steps[k]
    if E:IsVisible(s, player) then
      local w = ns.Brain:World(s)
      if w and (w[1] ~= loc[1] or (dist(w, loc) or 0) > hub) then return w end
    end
  end
  return nil
end

-- Bir adayi tartar: { item, saved (s), detour (yd), later (yd), why }. saved: simdi yapmanin kazandirdigi sure.
function Planner:Score(E, item, me, curLoc, player)
  local speed = self:Speed()
  if item.kind == "hearth" or item.kind == "fly" then
    -- yolculuk hesabi zaten kazanci verir; baska kitadaki adimda sure bilinmez, yine de belirgin kazanc sayilir
    return { item = item, saved = item.saves or 600, why = "travel" }
  end
  if not QUEST_KIND[item.kind] then return nil end   -- rehber disi (istege bagli) gorev "sirada" olmaz
  local loc = ns.Brain:World(item.step)
  local d1 = loc and dist(me, loc)
  if not d1 then return nil end
  local d2 = curLoc and dist(loc, curLoc)
  local d0 = curLoc and dist(me, curLoc)
  local detour = (d2 and d0) and math.max(0, d1 + d2 - d0) or 2 * d1
  local away = self:AwayFrom(E, loc, type(item.index) == "number" and item.index or nil, player)
  local later = away and 2 * (dist(loc, away) or 1500) or 0   -- baska kita: uzun bir donus
  if item.behind then later = math.max(later, BEHIND_LATER) end
  local saved = (later - detour) / speed
  return { item = item, saved = saved, detour = detour, later = later, yards = d1 }
end

-- Teslimi simdi yapmak ilerideki bir adimi bozar mi? q'nun "parent" oldugu ve rehberde kabulu olan, henuz
-- alinmamis alt quest: q gunlukten cikarsa o kabul yapilamaz.
local function neededLater(E, q)
  local kids = ns.Brain.ChildrenOf and ns.Brain:ChildrenOf(q)
  if not kids then return false end
  for _, c in ipairs(kids) do
    if not P.IsQuestInLog(c) and not P.IsQuestFlaggedCompleted(c) then
      for _, s in ipairs(E.guide.steps) do
        if s.type == "accept" and s.quest == c then return true end
      end
    end
  end
  return false
end

-- Rota isleri, oyuncunun BULUNDUGU yerden: hazir teslimler (rehberin herhangi bir yerinde, ileri adim once),
-- buradaki NPC'nin kabulleri, bu alandaki acik hedefler; ayrica Beyin'in yolculuk onerileri (ocak/ucus).
-- Ogeler Brain:Compute ile ayni bicimde: { kind, index, step, quest, yards, reason, behind }.
function Planner:Jobs(E, me, player)
  local B = ns.Brain
  local steps, idx = E.guide.steps, E.index
  local cur = steps[idx]
  local hub, area = B.db.hubYards or 40, B.db.areaYards or 150
  local skipped = (E.SkippedTurnins and E:SkippedTurnins()) or {}
  local refused = E.detourRefused or {}
  local out, seen = {}, {}
  local function yards(s) return dist(me, B:World(s)) end
  local function add(kind, i, s, y, reason, behind)
    out[#out + 1] = { kind = kind, index = i, step = s, quest = s.quest, yards = y, reason = reason, behind = behind }
  end
  -- 1) hazir teslimler: quest basina bir adim, once ileridekiler (rehberin kendi teslimi), sonra geride kalanlar
  local order = {}
  for i = idx + 1, #steps do order[#order + 1] = i end
  for i = idx - 1, 1, -1 do order[#order + 1] = i end
  for _, i in ipairs(order) do
    local s = steps[i]
    local q = s.quest
    -- istege bagli teslim de (rehberde kabulu olmayan, oneriyle alinmis quest sonradan biter)
    if s.type == "turnin" and q and not seen[q] and q ~= (cur and cur.quest) and not skipped[q]
      and B:Ready(q) and E:IsVisible(s, player) and not E:IsEarly(q) then
      seen[q] = true
      local y = not refused[i] and not neededLater(E, q) and yards(s)
      if y and y <= REACH then
        add("turnin", i, s, y, L["Ready to turn in, %d yd away: do it now."]:format(math.floor(y + 0.5)), i < idx)
      end
    end
  end
  -- 2) buradaki kabuller: rehberin ilerideki kabulu oyuncunun yanindaki NPC'de; hazir olmayan zorunlu teslim ya da
  -- seviye adimi sonrasini kapatir (grafik kesin "alinabilir" demedikce)
  local blocked = false
  for j = idx + 1, math.min(#steps, idx + LOOKAHEAD) do
    local s = steps[j]
    if E:IsVisible(s, player) then
      if s.type == "turnin" and s.quest and not s.optional and not P.IsQuestFlaggedCompleted(s.quest)
        and not B:Ready(s.quest) then blocked = true end
      if s.type == "level" then blocked = true end
      -- yalniz simdi yapilabilir kabul (StepStatus "todo"): bekleyen, NPC'nin vermedigi, birakilan quest aday olmaz
      if s.type == "accept" and s.quest and not refused[j] and not seen["a" .. s.quest]
        and E:StepStatus(s, player) == "todo" then
        local y = yards(s)
        local can = y and y <= hub and B:CanAccept(s.quest)
        if can == true or (y and y <= hub and can == nil and not blocked) then
          seen["a" .. s.quest] = true
          add("accept", j, s, y, L["Same place (%d yd): accept now and save a trip back."]:format(math.floor(y + 0.5)))
        end
      end
    end
  end
  -- 3) bu alandaki acik hedefler (gunlukteki, erken olmayan quest'ler; quest basina ilk adim). Su anki adimin
  -- quest'inin BASKA hedefi de aday: rehber hedefleri sirayla verir, oyuncu digerinin dibindeyken uzaga gonderilmesin
  -- (Darkshore 2098: Gelkak's Key parcalari); su anki hedeften SAME_QUEST_GAIN kat yakin ve SAME_QUEST_MAX yd icinde.
  local curY = cur and cur.quest and OBJECTIVE[cur.type] and yards(cur)
  for j = idx + 1, math.min(#steps, idx + LOOKAHEAD) do
    local s = steps[j]
    local q = s.quest
    local sameQ = q and cur and q == cur.quest
    local key = sameQ and ("o" .. q .. ":" .. tostring(s.objective)) or ("o" .. tostring(q))
    if OBJECTIVE[s.type] and q and not s.sticky and not seen[key] and not refused[j]
      and (not sameQ or (curY and s.objective ~= cur.objective))
      and P.IsQuestInLog(q) and E:IsStepComplete(s) ~= true and E:IsVisible(s, player) and not E:IsEarly(q) then
      seen[key] = true
      local y = yards(s)
      local ok = y and (sameQ and y <= SAME_QUEST_MAX and y < curY * SAME_QUEST_GAIN or not sameQ and y <= area)
      if ok then
        add("objective", j, s, y, L["Same area (%d yd): do it while you are here."]:format(math.floor(y + 0.5)))
      end
    end
  end
  -- 4) yolculuk (Beyin hesaplar: ogrenilmis ocak tasi / ucus). Rota karari (Route) bunlari kullanmaz (yolculuk adimi
  -- su anki adimdir): her 0,5 sn'lik degerlendirmede Brain'in tam hesabi yapilmaz.
  if not self.routing then
    for _, it in ipairs(B:Compute()) do
      if it.kind == "hearth" or it.kind == "fly" then out[#out + 1] = it end
    end
  end
  return out
end

-- Rehber adimina varis suresi (s): yurume + eylem. Konumsuz adimda yalniz eylem.
function Planner:GuideTime(cur, me, curLoc)
  local d0 = curLoc and dist(me, curLoc)
  return (d0 and d0 / self:Speed() or 0) + (ACTION[cur.type] or 10)
end

-- Saf hesap: adaylar (kazanca gore) ve esik. Donus: list, threshold, guideTime.
function Planner:Compute()
  local E, B = ns.Engine, ns.Brain
  if not (E and E.guide and E.index and B and B:IsEnabled()) then return {}, nil end
  local cur = E.guide.steps[E.index]
  local c, x, y = P.PlayerWorldPos()
  if not (cur and c) then return {}, nil end
  local me = { c, x, y }
  local curLoc = B:World(cur)
  local player = P.PlayerInfo()
  local out = {}
  for _, item in ipairs(self:Jobs(E, me, player)) do
    local s = self:Score(E, item, me, curLoc, player)
    if s then out[#out + 1] = s end
  end
  table.sort(out, function(a, b)
    if a.saved ~= b.saved then return a.saved > b.saved end
    return (a.yards or 0) < (b.yards or 0)
  end)
  local gt = self:GuideTime(cur, me, curLoc)
  local threshold = math.max(self.db.minSave or 20, (self.db.share or 0.15) * gt)
  return out, threshold, gt
end

local function key(s) return s.item.kind .. ":" .. tostring(s.item.index) end

-- Histerezisli karar: { item, saved, reason } ya da nil (rehber adimi en iyisi).
function Planner:Next()
  if not (self:IsEnabled() and self.db.enabled) then return nil end
  if P.InLockdown() then return self.pick end
  if P.IsDead() then self.pick = nil return nil end
  local E = ns.Engine
  local step = E and E.guide and (E.guide.id .. ":" .. tostring(E.index))
  if self.at and self.step == step and now() - self.at < REFRESH then return self.pick end
  local list, threshold = self:Compute()
  local best = list[1]
  if best and best.saved < threshold then best = nil end
  -- ayni adimda onceki secim hala gecerli ve yeterliyse kalir; yeni aday ancak belirgin daha iyiyse gecer
  if self.pick and self.step == step then
    for _, s in ipairs(list) do
      if key(s) == self.pick.key and s.saved >= threshold and (not best or best.saved < s.saved * KEEP) then
        best = s
        break
      end
    end
  end
  self.step, self.at = step, now()
  if not best then self.pick = nil return nil end
  local Lv = ns.Leveling
  local t = Lv and Lv.FormatTime and Lv.FormatTime(best.saved) or (math.floor(best.saved + 0.5) .. "s")
  self.pick = { key = key(best), item = best.item, saved = best.saved,
    reason = L["Saves about %s compared with going to the guide step first."]:format(t), time = t }
  return self.pick
end

local function savesText(saved)
  local Lv = ns.Leveling
  local t = Lv and Lv.FormatTime and Lv.FormatTime(saved) or (math.floor(saved + 0.5) .. "s")
  return L["Saves about %s compared with going to the guide step first."]:format(t)
end

-- Rota karari (motor sorar; sapma yokken): rehber adimi yerine yapilacak adim. Donus: adim, neden, puan ya da nil.
-- "Reorder the route" (Brain.db.mode "full"): her is; "Suggestions only": yalniz hazir teslimler (eski davranis).
-- Yalniz rehber adimi olan isler (yolculuk ve harita isaretleri oneride kalir); savasta ve oluyken yok.
local ROUTE_CACHE = 1.0   -- sn: ayni adimda ve ayni yerde rota karari en cok bu siklikta yeniden hesaplanir

function Planner:Route(E)
  local B = ns.Brain
  if not (self:IsEnabled() and B and B:IsEnabled()) or P.InCombat() then return nil end
  if P.IsDead() then return nil end
  local c0, x0, y0 = P.PlayerWorldPos()
  -- gunluk imzasi: rehber quest'lerinden gunlukte olan / teslime hazir olanlar (olay gelmeden degisse de yenilenir)
  local sig = {}
  for _, e in ipairs(E:GuideQuests()) do
    if E:InLog(e.id) then sig[#sig + 1] = e.id .. (P.IsQuestComplete(e.id) and "r" or "") end
  end
  local nref = 0
  for _ in pairs(E.detourRefused or {}) do nref = nref + 1 end
  sig = table.concat(sig, ",") .. "|" .. nref   -- reddedilen sapma da yeniden hesaplatir
  local rc = self.routeCache
  if rc and rc.index == E.index and rc.guide == E.guide and rc.sig == sig and now() - rc.at < ROUTE_CACHE
    and c0 == rc.c and math.abs((x0 or 0) - rc.x) < 5 and math.abs((y0 or 0) - rc.y) < 5 then
    return rc.t, rc.w, rc.s
  end
  local t, w, s = self:RouteNow(E, B)
  self.routeCache = { index = E.index, guide = E.guide, sig = sig, at = now(), c = c0, x = x0 or 0, y = y0 or 0,
    t = t, w = w, s = s }
  return t, w, s
end

function Planner:RouteNow(E, B)
  local full = B.db.mode == "full"
  self.routing = true
  local ok, list, threshold = pcall(self.Compute, self)
  self.routing = nil
  if not ok then error(list, 0) end
  if not threshold then return nil end
  -- aday su anki hedeften yakin olmali: oyuncu adimin yaninda calisirken baska ise atlatilmaz (sirasi fark etmez)
  local c, x, y = P.PlayerWorldPos()
  local dcur = c and dist({ c, x, y }, B:World(E.guide.steps[E.index]))
  for _, s in ipairs(list) do
    if s.saved < threshold then break end
    local it = s.item
    if type(it.index) == "number" and it.index ~= E.index and (full or it.kind == "turnin")
      and (not dcur or (s.yards or 0) < dcur) then
      return it.index, (it.reason or "") .. " " .. savesText(s.saved), s
    end
  end
  return nil
end

function Planner:MarkDirty() self.at, self.routeCache = nil, nil end

function Planner:OnEnable()
  ns:On("QUEST_LOG_UPDATE", self, "MarkDirty")
  ns:Listen("ARCANIS_STEP_CHANGED", self, "MarkDirty")
  ns:Listen("ARCANIS_GUIDE_CHANGED", self, function(p) p.pick, p.at = nil, nil end)
end

ns:RegisterCommand("plan", function()
  local list, threshold, gt = Planner:Compute()
  if not threshold then ns:Print(L["Planner: no guide step or position."]) return end
  ns:Print(L["Planner: guide step in about %d s, a detour needs to save %d s."]:format(math.floor(gt + 0.5), math.floor(threshold + 0.5)))
  if #list == 0 then ns:Print(L["Planner: nothing worth doing first."]) return end
  for i, s in ipairs(list) do
    ns:Print(("%d. %s  |  %+d s%s"):format(i, ns.Brain:Label(s.item), math.floor(s.saved + 0.5),
      s.saved >= threshold and "  <" or ""))
  end
end, "what the planner would do next and how much time each choice saves")
