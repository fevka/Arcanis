-- Arcanis: meslek etkinligi (modul "ProfActivity"). Toplama (Mining, Herb Gathering, Skinning), Fishing ve
-- uretim cast'lerini izler; Dynamic Hub cast barini (Island:OnProfCast) besler. Ayrica:
--   * beceri artisi bildirimi ve trainer esikleri (Journeyman 75, Expert 150, Artisan 225)
--   * toplama oturumu: damar/bitki, balik, esyalar, Auction House degeri ve saatlik altin
--   * cantalar doluyken toplama uyarisi, lure bitiyor uyarisi, meslek bekleme suresi bitti bildirimi
-- Yalniz bilgi verir; hicbir korumali eylem yapmaz.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Prof = ns:NewModule("ProfActivity", {
  defaults = { enabled = true, skillUps = true, bagWarn = true, lureWarn = true, cooldowns = true, trackWarn = true },
})
ns.ProfActivity = Prof

-- Toplama buyuleri (tum rutbeler) ve Ingilizce ad yedegi
local GATHER = {
  [2575] = "Mining", [2576] = "Mining", [3564] = "Mining", [10248] = "Mining",
  [2366] = "Herb Gathering", [2368] = "Herb Gathering", [3570] = "Herb Gathering", [11993] = "Herb Gathering",
  [8613] = "Skinning", [8617] = "Skinning", [8618] = "Skinning", [10768] = "Skinning",
}
local FISHING = { [7620] = true, [7731] = true, [7732] = true, [18248] = true }
local GATHER_NAMES = { ["Mining"] = true, ["Herb Gathering"] = true, ["Skinning"] = true }
-- Uzun meslek bekleme sureleri: Mooncloth, transmute'lar
local COOLDOWNS = { 18560, 17187, 11479, 11480, 17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566 }
local SALT_SHAKER = 15846
-- Beceri tavani -> bir sonraki rutbe (Classic)
local NEXT_TIER = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }
local LOOT_WINDOW = 4       -- sn: toplama basarisindan sonra acilan loot toplamadan sayilir
local BAG_WARN_GAP = 60     -- sn: cantalar dolu uyarisi en fazla bu aralikla
local LURE_WARN = 60        -- sn: lure bu kadar kala uyarir
local FISH_RECENT = 600     -- sn: son balik avindan bu kadar sonrasina kadar lure gosterilir
local TRACK_EVERY = 15      -- sn: iz (Find Minerals / Find Herbs) denetimi araligi
local TRACK_RECENT = 300    -- sn: son toplamadan bu kadar sonrasina kadar oturum suruyor sayilir
local TRACK_GAP = 600       -- sn: ayni meslek icin hatirlatma araligi
local GATHER_PROF = { ["Mining"] = "Mining", ["Herb Gathering"] = "Herbalism" }

local function now() return P.Now() end

-- Cast turu: "gather" | "fish" | "craft" | nil
function Prof.Kind(c)
  if not c then return nil end
  if FISHING[c.spellId] or c.name == "Fishing" then return "fish" end
  if GATHER[c.spellId] or GATHER_NAMES[c.name] then return "gather" end
  if c.tradeskill then return "craft" end
  return nil
end

-- Su anki meslek cast'i: { kind, name, icon, start, finish, done, total } ya da nil
function Prof:Current() return self.cast end

-- Cast olaylari
function Prof:OnCastStart(_, unit)
  if unit ~= "player" then return end
  local c = P.PlayerCast()
  local kind = Prof.Kind(c)
  if not kind then return end
  c.kind = kind
  if kind == "craft" and self.queue then c.done, c.total = self.queue.done, self.queue.total end
  if kind == "fish" then self.fishedAt = now() end
  self.cast = c
  if ns.Island and ns.Island:IsEnabled() then ns.Island:OnProfCast(c) end
end

function Prof:OnCastSucceeded(_, unit, _, spellId)
  if unit ~= "player" or not self.cast then return end
  local c = self.cast
  if spellId and not (issecretvalue and issecretvalue(spellId)) and c.spellId and spellId ~= c.spellId then return end
  if c.kind == "gather" then
    self:Session().nodes = self:Session().nodes + 1
    self.gatheredAt = now()
    self.lastGather = { prof = GATHER_PROF[GATHER[c.spellId] or c.name], at = now() }   -- iz hatirlatmasi
    self:CheckBags()
    ns:Send("ARCANIS_GATHERED", c.name)   -- farm pusulasi (Helpers/Farm.lua): yer ve oturum
  elseif c.kind == "craft" and self.queue then
    self.queue.done = self.queue.done + 1
    if self.queue.done >= self.queue.total then self.queue = nil end
  end
  c.ok = true
  -- uretim sirasi suruyorsa ada bir sonraki cast'te devam eder; kanal (Fishing) STOP'ta biter
  if not c.channel then self:EndCast(true) end
end

function Prof:OnCastFailed(_, unit)
  if unit ~= "player" or not self.cast then return end
  self.queue = nil
  self:EndCast(false)
end

function Prof:OnCastStop(_, unit)
  if unit ~= "player" or not self.cast then return end
  -- STOP: basarisiz cast'te INTERRUPTED ile birlikte gelir; basarili tek cast'te SUCCEEDED'dan sonra
  self:EndCast(self.cast.ok or (self.cast.channel and true) or false)
end

function Prof:EndCast(ok)
  local c = self.cast
  if not c then return end
  self.cast = nil
  if ns.Island and ns.Island:IsEnabled() then ns.Island:OnProfCastEnd(c, ok) end
end

-- "Create All": kac adet uretilecegi
function Prof:OnQueue(n)
  if n and n > 1 then self.queue = { total = n, done = 0 } else self.queue = nil end
end

-- Toplama oturumu
function Prof:Session()
  if not self.session then self.session = { nodes = 0, catches = 0, items = {}, value = 0, started = now() } end
  return self.session
end

function Prof:SessionRate()
  local s = self.session
  if not s then return nil end
  local secs = now() - s.started
  if secs < 60 then return nil end
  return s.value / secs * 3600
end

function Prof:ResetSession() self.session = nil end

function Prof:OnLoot()
  local items, fishing = P.LootItems()
  local fromGather = self.gatheredAt and now() - self.gatheredAt <= LOOT_WINDOW
  if not (fishing or fromGather) or #items == 0 then return end
  self.gatheredAt = nil
  local s = self:Session()
  if fishing then s.catches = s.catches + 1; self.fishedAt = now(); self:CheckBags() end
  local parts, gained = {}, 0
  for _, it in ipairs(items) do
    s.items[it.id] = (s.items[it.id] or 0) + it.count
    local price = ns.Prices and ns.Prices.Get and ns.Prices:Get(it.id)
    if price then s.value = s.value + price * it.count; gained = gained + price * it.count end
    parts[#parts + 1] = ("+%d %s"):format(it.count, it.name or ("#" .. it.id))
  end
  ns:Send("ARCANIS_GATHER_LOOT", fishing and true or false, gained, items)   -- farm pusulasi
  self.lastLoot = table.concat(parts, ", ")
  if ns.Island and ns.Island:IsEnabled() then ns.Island:OnProfLoot(self.lastLoot) end
end

function Prof:CheckBags()
  if not self.db.bagWarn or (P.FreeBagSlots() or 1) > 0 then return end
  if self.bagWarnAt and now() - self.bagWarnAt < BAG_WARN_GAP then return end
  self.bagWarnAt = now()
  ns.Toast:Show(L["Bags are full. New items will not fit."], "warn", nil, nil, { cat = "profession" })
end

-- Beceri artisi
-- Bildirim alt satiri: tavana yaklasinca bir sonraki rutbe (Classic esikleri: tavandan 25 asagi ogrenilebilir).
function Prof.TierHint(rank, max)
  local tier = NEXT_TIER[max]
  if not tier then return nil end
  tier = ({ Journeyman = L["Journeyman"], Expert = L["Expert"], Artisan = L["Artisan"] })[tier]
  if rank >= max then return L["Skill capped. Learn %s from a trainer."]:format(tier) end
  if rank >= max - 25 then return L["You can learn %s now."]:format(tier) end
  return L["%d to the cap"]:format(max - rank)
end

-- Meslek rotasi (Data/Professions.lua): bu beceride ne yapilir, sonraki rutbe, en yakin trainer, malzeme.
-- p = { name, rank, max } (P.ProfessionRanks), player = { faction, level }. Veri yoksa nil.
local RANK_ORDER = { Apprentice = 1, Journeyman = 2, Expert = 3, Artisan = 4 }

-- trainer bu rutbeyi ogretir mi: ust rutbe trainer'i alt rutbeleri de ogretir (Classic); "All Ranks" ve
-- "Journeyman+" hepsini
local function teaches(t, rank)
  local r = t.rank or ""
  local top = (r == "All Ranks" or r:sub(-1) == "+") and 4 or RANK_ORDER[r]
  return top ~= nil and top >= (RANK_ORDER[rank] or 9)
end

local function sideOk(f, faction)
  return not f or f == "Neutral" or f == "Both" or f == faction
end

function Prof.Plan(p, player)
  local d = ns.ProfessionData and ns.ProfessionData[p.name]
  if not d then return nil end
  local rank, out = p.rank or 0, {}
  for _, s in ipairs(d.steps or {}) do
    if rank >= s.from and rank < s.to then out.step = s break end
  end
  local cur
  for _, r in ipairs(d.ranks or {}) do
    if rank >= r.from and rank < r.to then cur = r end
    if r.from == p.max and p.max < (d.maxSkill or 300) then out.nextRank = r end
  end
  if out.nextRank then
    local r = out.nextRank
    out.canLearn = rank >= (r.skill or 0) and (player.level or 0) >= (r.level or 0)
    local best, bestD
    for _, t in ipairs(d.trainers or {}) do
      if teaches(t, r.name) and sideOk(t.faction, player.faction) then
        local dist = t.map and P.VectorTo(t.map, t.x / 100, t.y / 100)
        if not best or (dist and (not bestD or dist < bestD)) then best, bestD = t, dist end
      end
    end
    out.trainer = best
  end
  out.shopping = {}
  for _, s in ipairs(d.shopping or {}) do
    local a, b = (s.tier or ""):match("^(%d+)%-(%d+)$")
    if (a and rank >= tonumber(a) and rank < tonumber(b)) or (cur and s.tier == cur.name) then out.shopping[#out.shopping + 1] = s end
  end
  for _, r in ipairs(d.routes or {}) do
    if rank >= r.from and rank < r.to then
      local z = (player.faction == "Horde" and r.horde) or (player.faction == "Alliance" and r.alliance)
      if not z and sideOk(r.faction, player.faction) then z = r.zone end
      out.zone = z
      break
    end
  end
  for _, h in ipairs(d.herbs or {}) do
    if h.skill > rank then out.nextHerb = h break end
  end
  out.vendors = d.vendors
  -- yan bilgiler: alet, cubuk (Enchanting), meslek quest'leri, tarif acan zincir, balik/yem/olta, kamp, yardimci esyalar
  out.tool = d.tool
  for _, r in ipairs(d.rods or {}) do
    if r.skill <= rank then out.rod = r elseif not out.nextRod then out.nextRod = r end
  end
  out.quests = {}
  for _, q in ipairs(d.quests or {}) do
    if sideOk(q.faction, player.faction) and rank >= (q.skill or 0) - 25 then out.quests[#out.quests + 1] = q end
  end
  out.unlocks = {}
  for _, u in ipairs(d.unlocks or {}) do
    if sideOk(u.faction, player.faction) and rank >= 225 then out.unlocks[#out.unlocks + 1] = u end
  end
  for _, f in ipairs(d.fishByTier or {}) do
    if f.skill > rank then
      out.nextFish = { name = f.name, skill = f.skill, zone = player.faction == "Horde" and f.horde or f.alliance }
      break
    end
  end
  out.lures, out.poles, out.camp, out.gear, out.questFish = d.lures, d.poles, d.camp, d.gear, d.questFish
  out.boosts = {}
  for _, b in ipairs(d.boostItems or {}) do
    if sideOk(b.faction, player.faction) then out.boosts[#out.boosts + 1] = b end
  end
  out.speculative = d.speculativeAbove and rank >= d.speculativeAbove and d.speculativeAbove or nil
  return out
end

local function named(list, withBonus)
  local parts = {}
  for _, e in ipairs(list or {}) do
    parts[#parts + 1] = (withBonus and e.bonus and e.bonus > 0) and ("%s +%d"):format(e.name, e.bonus) or e.name
  end
  return table.concat(parts, ", ")
end

-- Rota bilgisini ayrinti satirlarina cevirir (Guide Browser > Professions).
function Prof.PlanLines(plan)
  local lines = {}
  if not plan then return lines end
  local s = plan.step
  if s then
    lines[#lines + 1] = (s.count and s.count > 0) and L["Make %d x %s (until %d)"]:format(s.count, s.name, s.to)
      or L["Make %s until %d"]:format(s.name, s.to)
  end
  if plan.zone then lines[#lines + 1] = L["Gather in: %s"]:format(plan.zone) end
  if plan.nextHerb then lines[#lines + 1] = L["Next herb: %s at %d"]:format(plan.nextHerb.name, plan.nextHerb.skill) end
  if #plan.shopping > 0 then
    local parts = {}
    for _, m in ipairs(plan.shopping) do parts[#parts + 1] = ("%d %s"):format(m.count or 1, m.name) end
    lines[#lines + 1] = L["Materials for this stage: %s"]:format(table.concat(parts, ", "))
  end
  local r = plan.nextRank
  if r then
    local t = plan.trainer
    lines[#lines + 1] = L["Next rank: %s (skill %d, level %d)"]:format(L[r.name], r.skill or 0, r.level or 0)
      .. (t and ("\n" .. L["Trainer: %s, %s"]:format(t.npc, t.zone or "?")) or "")
  end
  for _, v in ipairs(plan.vendors or {}) do
    lines[#lines + 1] = L["Recipe vendor: %s, %s"]:format(v.npc, v.zone or "?")
  end
  if plan.speculative then lines[#lines + 1] = L["The route above %d is not confirmed yet."]:format(plan.speculative) end
  if plan.tool then
    local ok, d = pcall(P.ItemDetails, plan.tool)
    lines[#lines + 1] = L["Keep in your bags: %s"]:format(ok and d and d.name or ("#" .. plan.tool))
  end
  if plan.rod then lines[#lines + 1] = L["Rod: %s"]:format(plan.rod.name) end
  if plan.nextRod then lines[#lines + 1] = L["Next rod: %s at %d"]:format(plan.nextRod.name, plan.nextRod.skill) end
  for _, q in ipairs(plan.quests or {}) do
    lines[#lines + 1] = L["Profession quest: %s"]:format(q.name) .. (q.npc and (" (" .. q.npc .. ")") or "")
  end
  if plan.quests and #plan.quests > 0 and plan.questFish then lines[#lines + 1] = L["Fish for it: %s"]:format(named(plan.questFish)) end
  for _, u in ipairs(plan.unlocks or {}) do
    lines[#lines + 1] = L["Recipe quest: %s from %s"]:format(u.recipe or "?", u.npc or "?")
  end
  if plan.nextFish then lines[#lines + 1] = L["Next fish: %s at %d (%s)"]:format(plan.nextFish.name, plan.nextFish.skill, plan.nextFish.zone or "?") end
  if plan.lures then lines[#lines + 1] = L["Lures: %s"]:format(named(plan.lures, true)) end
  if plan.poles then lines[#lines + 1] = L["Poles: %s"]:format(named(plan.poles, true)) end
  if plan.gear then lines[#lines + 1] = L["Helpful items: %s"]:format(named(plan.gear, true)) end
  for _, b in ipairs(plan.boosts or {}) do lines[#lines + 1] = L["Quest reward: %s (%s)"]:format(b.reward or "?", b.name) end
  if plan.camp then lines[#lines + 1] = L["Camp items: %s"]:format(named(plan.camp)) end
  return lines
end

function Prof:OnSkills()
  local now_ = {}
  for _, p in ipairs(P.ProfessionRanks()) do now_[p.name] = p end
  local old = self.ranks
  self.ranks = now_
  if not (old and self.db.skillUps) then return end
  -- artis aninda adada bildirilir (sahibin istegi: gec dusuyordu); seri icinde (STREAK_END sn) gelen sonraki artislar
  -- ayni bildirimi gunceller: sayac son gosterilen degerden yeniye sayar, "+N" serinin toplami
  self.streak = self.streak or {}
  local t = now()
  for name, p in pairs(now_) do
    local o = old[name]
    if o and p.rank > o.rank then
      local s = self.streak[name]
      if not (s and t - s.at <= Prof.STREAK_END) then s = { from = o.rank } end
      s.at, s.to, s.max = t, p.rank, p.max
      self.streak[name] = s
      self:ShowStreak(name)
    end
  end
end

Prof.STREAK_END = 20   -- sn: bu kadar yeni beceri artisi gelmezse seri biter (sonraki artis yeni bildirim)

-- "Mining 65 -> 66" sayarak (adada), altinda serinin toplami ve trainer ipucu.
function Prof:ShowStreak(name)
  local s = self.streak and self.streak[name]
  if not s then return end
  local title = L[name] .. "  %d"
  local hint = Prof.TierHint(s.to, s.max)
  local body = hint and ("+%d  ·  %s"):format(s.to - s.from, hint) or ("+%d"):format(s.to - s.from)
  local from = s.shown or s.from
  s.shown = s.to
  ns.Toast:Show(title:format(s.to), "info", body, nil,
    { cat = "profession", key = "skill:" .. name, hold = 6, count = { from = from, to = s.to, max = s.max, fmt = title } })
end
Prof.FinishStreak = Prof.ShowStreak   -- eski ad

-- Biten seriler atilir (bir sonraki artis yeni seri baslatir).
function Prof:CheckStreaks()
  local t = now()
  for name, s in pairs(self.streak or {}) do
    if t - s.at > Prof.STREAK_END then self.streak[name] = nil end
  end
end

-- Lure ve bekleme sureleri (saniyede bir)
-- Lure kalan suresi: yalniz yakinda balik avlandiysa (baska gecici silah buyusuyle karismasin)
function Prof:Lure()
  if not (self.fishedAt and now() - self.fishedAt <= FISH_RECENT) then return nil end
  return P.LureTime()
end

function Prof:Tick()
  self:CheckStreaks()
  local lure = self:Lure()
  if lure and self.db.lureWarn then
    if lure <= LURE_WARN and not self.lureWarned then
      self.lureWarned = true
      ns.Toast:Show(L["Your fishing lure is running out."], "info", nil, nil, { cat = "profession" })
    elseif lure > LURE_WARN then
      self.lureWarned = nil
    end
  end
  self.trackAge = (self.trackAge or 0) + 1
  if self.trackAge >= TRACK_EVERY then self.trackAge = 0; self:CheckTracking() end
  self.cdAge = (self.cdAge or 30) + 1
  if self.cdAge >= 30 then self.cdAge = 0; self:CheckCooldowns() end
end

-- Find Minerals / Find Herbs izi kapali mi: meslek rehberinin toplama adimi etkinken ya da son TRACK_RECENT sn'de
-- toplandiysa hatirlatir (meslek basina en sik TRACK_GAP sn'de bir). Klasik istemcide ayni anda tek iz acik olur.
local TRACK = { Mining = { spell = 2580, name = "Find Minerals" }, Herbalism = { spell = 2383, name = "Find Herbs" } }
Prof.TRACK = TRACK

-- Su an hangi toplama mesleginin izi gerekli: "Mining" / "Herbalism" ya da nil.
function Prof:TrackingNeed()
  local st = ns.Engine and ns.Engine.GetStep and ns.Engine:GetStep()
  if st and st.type == "prof" and st.act == "gather" and TRACK[st.prof or ""] then return st.prof end
  local g = self.lastGather
  if g and g.prof and TRACK[g.prof] and now() - g.at <= TRACK_RECENT then return g.prof end
  return nil
end

-- Dondurur: hatirlatildiysa meslek adi.
function Prof:CheckTracking()
  if not self.db.trackWarn then return nil end
  local need = self:TrackingNeed()
  local t = need and TRACK[need]
  if not (t and P.KnowsSpell(t.spell)) or P.TrackingActive(t.spell) ~= false then return nil end
  self.trackWarned = self.trackWarned or {}
  local last = self.trackWarned[need]
  if last and now() - last < TRACK_GAP then return nil end
  self.trackWarned[need] = now()
  local name = P.SpellName(t.spell) or t.name
  ns.Toast:Show(L["%s is off. Turn it on to see nodes on the minimap."]:format(name), "info", nil, nil, { cat = "profession" })
  return need
end

-- Bekleme suresi biten meslek buyusu (ya da Salt Shaker) bir kez bildirilir.
function Prof:CheckCooldowns()
  if not self.db.cooldowns then return end
  self.waiting = self.waiting or {}
  local function check(key, left, name)
    if not left then return end
    if left > 2 then self.waiting[key] = true
    elseif self.waiting[key] then
      self.waiting[key] = nil
      ns.Toast:Show(L["%s is ready."]:format(name or "?"), "info", nil, nil, { cat = "profession" })
    end
  end
  for _, id in ipairs(COOLDOWNS) do
    if P.KnowsSpell(id) then check(id, P.SpellCooldown(id), P.SpellName(id)) end
  end
  if (P.ItemCount(SALT_SHAKER) or 0) > 0 then check("salt", P.ItemCooldown(SALT_SHAKER), L["Salt Shaker"]) end
end

function Prof:OnEnable()
  ns:On("UNIT_SPELLCAST_START", self, "OnCastStart", "player")
  ns:On("UNIT_SPELLCAST_CHANNEL_START", self, "OnCastStart", "player")
  ns:On("UNIT_SPELLCAST_SUCCEEDED", self, "OnCastSucceeded", "player")
  ns:On("UNIT_SPELLCAST_INTERRUPTED", self, "OnCastFailed", "player")
  ns:On("UNIT_SPELLCAST_FAILED", self, "OnCastFailed", "player")
  ns:On("UNIT_SPELLCAST_STOP", self, "OnCastStop", "player")
  ns:On("UNIT_SPELLCAST_CHANNEL_STOP", self, "OnCastStop", "player")
  ns:On("LOOT_OPENED", self, "OnLoot")
  ns:On("SKILL_LINES_CHANGED", self, "OnSkills")
  self:OnSkills()   -- ilk okuma: bildirim yok, yalniz karsilastirma tabani
  if not self.queueHooked then
    self.queueHooked = true
    P.OnCraftQueue(function(n) Prof:OnQueue(n) end)
  end
  if C_Timer and C_Timer.NewTicker and not self.ticker then
    self.ticker = C_Timer.NewTicker(1, function() if Prof:IsEnabled() then Prof:Tick() end end)
  end
end

function Prof:OnDisable()
  if self.cast then self:EndCast(false) end
  self.queue = nil
end
