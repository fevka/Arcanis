-- Arcanis: meslek rehberleri. Data/ProfessionGuides.lua (yalniz yapi) oyuncunun tarafi ve irkina gore adim adim
-- rehbere cevrilir ve kaydedilir (special = true, profession = meslek). Adim metinlerini Engine:Describe yazar.
-- Trainer / vendor alternatifleri irka gore secilir (irkina uyan, yoksa kosulsuz, yoksa ilki: Skyborne).
local _, ns = ...

local PG = {}
ns.ProfGuides = PG

function PG.Id(faction, prof)
  return ("prof-%s-%s"):format(tostring(faction):lower(), (prof:lower():gsub("%s+", "-")))
end

local function has(list, v)
  for _, x in ipairs(list or {}) do if x == v then return true end end
  return false
end

local function pickAlt(alts, race)
  local free
  for _, a in ipairs(alts or {}) do
    if a.races then
      if has(a.races, race) then return a end
    elseif not free then free = a end
  end
  return free or (alts and alts[1])
end

-- ===== Toplama alani (Mining / Herbalism "gather" adimi) =====
-- Kaynak rehber her toplama adimina tek bolge ve tek nokta verir; oyuncunun seviyesine bakmaz (Mining 65-125
-- Wetlands'e, 20-30 bolgesine gonderiyordu). PG.GatherSpot: bolge oyuncuya agirsa (en dusuk seviyesi oyuncu + 1'den
-- yuksek) ayni becerideki damarlarin / bitkilerin bulundugu, seviyeye uyan, karsi tarafin olmayan bir bolge secilir;
-- nokta o bolgedeki herhangi bir meslek rehberi toplama noktasi (yoksa bolgenin ortasi). Adim metni hangi
-- damarlarin / bitkilerin toplanacagini ve alanda dolasilacagini soyler.
local KIND = { Mining = "ore", Herbalism = "herbs" }
-- karsi tarafin baslangic / kasaba bolgeleri (muhafizlar): oraya gonderilmez
local HOSTILE = {
  Alliance = { ["Durotar"] = true, ["Mulgore"] = true, ["Tirisfal Glades"] = true, ["Silverpine Forest"] = true,
    ["The Barrens"] = true },
  Horde = { ["Elwynn Forest"] = true, ["Dun Morogh"] = true, ["Teldrassil"] = true, ["Darkshore"] = true,
    ["Loch Modan"] = true, ["Westfall"] = true, ["Redridge Mountains"] = true, ["Duskwood"] = true },
}
PG.LEVEL_SLACK = 1   -- bolgenin en dusuk seviyesi oyuncunun seviyesini en cok bu kadar gecebilir

-- Bu becerideki puan veren dugumler (en zor once): { "Tin", "Copper" }. Turuncu/sari/yesil: beceri - gereken < 100.
function PG.GoodNodes(prof, skill)
  local kind = KIND[prof]
  local t = kind and ns.GatherSkill and ns.GatherSkill[kind]
  local out = {}
  for node, need in pairs(t or {}) do
    if need <= skill and skill - need < 100 and not node:find("Rich ") and node ~= "Black Lotus" then
      out[#out + 1] = { node, need }
    end
  end
  table.sort(out, function(a, b) return a[2] > b[2] end)
  local names = {}
  for i = 1, math.min(2, #out) do names[i] = out[i][1] end
  return names
end

local points   -- bolge -> { { x, y, faction, prof }, ... } (meslek rehberlerindeki toplama / malzeme noktalari)
local function gatherPoints()
  if points then return points end
  points = {}
  for faction, side in pairs(ns.ProfessionGuides or {}) do
    for prof, steps in pairs(side) do
      for _, s in ipairs(steps) do
        if (s.act == "gather" or s.act == "collect") and s.zone and s.x and s.y then
          points[s.zone] = points[s.zone] or {}
          table.insert(points[s.zone], { x = s.x, y = s.y, faction = faction, prof = prof })
        end
      end
    end
  end
  return points
end

local function zoneHas(zone, kind, nodes)
  local z = ns.ZoneInfoData and ns.ZoneInfoData[zone]
  for _, have in ipairs(z and z[kind] or {}) do
    for _, n in ipairs(nodes) do if have == n then return true end end
  end
  return false
end

-- Rehber adimi olmadan: bu meslek ve beceride seviyeye uyan en iyi toplama bolgesi (Meslekler sayfasi).
-- Doner: { zone, x, y (0-1), nodes } ya da nil (toplama meslegi degil / uygun bolge yok).
function PG.BestGatherZone(prof, level, skill, faction)
  local kind = KIND[prof or ""]
  if not kind then return nil end
  local nodes = PG.GoodNodes(prof, skill or 1)
  if #nodes == 0 then return nil end
  local best, bd
  for name, z in pairs(ns.ZoneInfoData or {}) do
    if z.min <= (level or 1) + PG.LEVEL_SLACK and not (HOSTILE[faction or ""] or {})[name] and zoneHas(name, kind, nodes) then
      local d = math.abs((z.min + z.max) / 2 - (level or 1)) + (zoneHas(name, kind, { nodes[1] }) and 0 or 100)
      if not bd or d < bd or (d == bd and name < best) then best, bd = name, d end
    end
  end
  if not best then return nil end
  local pick
  for _, pt in ipairs(gatherPoints()[best] or {}) do
    local score = (pt.faction == faction and 0 or 2) + (pt.prof == prof and 0 or 1)
    if not pick or score < pick.score then pick = { x = pt.x / 100, y = pt.y / 100, score = score } end
  end
  return { zone = best, x = pick and pick.x or 0.5, y = pick and pick.y or 0.5, nodes = nodes }
end

-- Doner: { zone, x, y (0-1), nodes, moved = eski bolge | nil } ya da nil (meslek toplama adimi degil).
function PG.GatherSpot(step, level, skill, faction)
  local kind = KIND[step.prof or ""]
  if not (kind and step.act == "gather" and step.zone) then return nil end
  local P = ns.Provider
  level = level or P.PlayerLevel()
  faction = faction or (P.PlayerInfo() or {}).faction
  if not skill then
    local p = ns.Engine and ns.Engine.ProfRank and ns.Engine:ProfRank(step.prof)
    skill = p and p.rank or 1
  end
  local nodes = PG.GoodNodes(step.prof, skill)
  local zi = ns.ZoneInfoData or {}
  local here = zi[step.zone]
  local fits = not here or here.min <= level + PG.LEVEL_SLACK
  if fits and (#nodes == 0 or not here or zoneHas(step.zone, kind, nodes)) then
    return { zone = step.zone, x = step.x, y = step.y, nodes = nodes }
  end
  -- seviyeye uyan, bu dugumleri tasiyan, karsi tarafin olmayan bolgeler: seviye ortasi oyuncuya en yakin
  -- en cok puan veren dugumu (nodes[1]) tasiyan bolge once
  local best, bd
  for name, z in pairs(zi) do
    if z.min <= level + PG.LEVEL_SLACK and not (HOSTILE[faction or ""] or {})[name] and zoneHas(name, kind, nodes) then
      local d = math.abs((z.min + z.max) / 2 - level) + (zoneHas(name, kind, { nodes[1] }) and 0 or 100)
      if not bd or d < bd or (d == bd and name < best) then best, bd = name, d end
    end
  end
  if not best then   -- uygun bolge yok: rehberin bolgesi kalir (metin uyarir)
    return { zone = step.zone, x = step.x, y = step.y, nodes = nodes, tooHigh = not fits }
  end
  local pick
  for _, pt in ipairs(gatherPoints()[best] or {}) do
    local score = (pt.faction == faction and 0 or 2) + (pt.prof == step.prof and 0 or 1)
    if not pick or score < pick.score then pick = { x = pt.x / 100, y = pt.y / 100, score = score } end
  end
  return { zone = best, x = pick and pick.x or 0.5, y = pick and pick.y or 0.5, nodes = nodes, moved = step.zone }
end

-- ===== Aletler ve rutbe ucreti (adim metni, Engine describeProf) =====
-- Rutbe ucreti: meslek egitmeninde okunur (Training:CaptureFees); bilinmiyorsa nil.
function PG.Fee(max)
  local rank = (max or 300) <= 75 and "Apprentice" or max <= 150 and "Journeyman" or max <= 225 and "Expert" or "Artisan"
  return ns.Training and ns.Training.ProfFee and ns.Training:ProfFee(rank) or nil
end

-- Meslegin bu becerideki aletleri: { { item, name, ids } }. Veri Data/ProfessionTools.lua (istemcinin SpellTotems'i),
-- toplama aletleri Mentor.TOOLS'tan (her kazma / bicak sayilir). Runed rod'lardan yalniz en ust uyan (eskisi kasmada
-- gerekmez).
function PG.Tools(prof, skill)
  local out, rod = {}, nil
  local gather = ns.Mentor and ns.Mentor.TOOLS and ns.Mentor.TOOLS[prof or ""]
  for _, t in ipairs(ns.ProfessionTools and ns.ProfessionTools[prof or ""] or {}) do
    if t.from <= (skill or 1) then
      local e = { item = t.item, name = t.name, ids = (gather and gather.item == t.name) and gather.ids or { t.item } }
      if t.name:find("^Runed ") then rod = e else out[#out + 1] = e end
    end
  end
  if rod then out[#out + 1] = rod end
  if gather and #out == 0 then out[1] = { item = gather.ids[1], name = gather.item, ids = gather.ids } end
  return out
end

-- Cantada olmayan aletlerin adlari (bos = hepsi var).
function PG.MissingTools(prof, skill)
  local out = {}
  for _, t in ipairs(PG.Tools(prof, skill)) do
    local have = false
    for _, id in ipairs(t.ids) do if (ns.Provider.ItemCount(id) or 0) > 0 then have = true break end end
    if not have then out[#out + 1] = t.name end
  end
  return out
end

-- Veri adimlari -> rehber adimlari (sema bicimi). Irka uymayan adim atlanir.
function PG.Steps(prof, data, race)
  local out = {}
  for _, s in ipairs(data or {}) do
    if not s.races or has(s.races, race) then
      local a = pickAlt(s.alts, race)
      local zone, x, y = s.zone, s.x, s.y
      if a and a.zone then zone, x, y = a.zone, a.x, a.y end
      local st
      if s.act == "level" then
        st = { type = "level", level = s.level }
      elseif s.act == "goto" then
        st = { type = "goto" }
      elseif s.act == "accept" or s.act == "turnin" then
        st = { type = s.act, quest = s.quest, name = s.name, npc = a and a.npc }
      else
        st = { type = "prof", act = s.act, prof = prof, skill = s.skill, max = s.max, after = s.after,
               count = s.count, name = s.name, item = s.item, spell = s.spell, npc = a and a.npc }
      end
      if zone and x and st.type ~= "level" then st.zone, st.x, st.y = zone, x, y end
      -- yer ipucu (kategori kodu -> yerellestirilmis kisa cumle): ok hedefe yaklasinca etiketin altinda
      if a and a.hint and ns.Hints and ns.Hints.Phrase then st.tip = ns.Hints.Phrase(a.hint) end
      -- toplama bir nokta degil alan: ok yaklasinca etiketin altinda dolasma ipucu
      if s.act == "gather" and not st.tip then
        local L = ns.L
        st.tip = prof == "Herbalism" and L["Gathering area: turn on Find Herbs and walk around; herbs show on the minimap."]
          or prof == "Mining" and L["Gathering area: turn on Find Minerals and walk around; veins show on the minimap."] or nil
      end
      if st.type ~= "goto" or st.zone then out[#out + 1] = st end
    end
  end
  return out
end

function PG.Register(faction, race)
  local side = ns.ProfessionGuides and ns.ProfessionGuides[faction]
  for prof, data in pairs(side or {}) do
    local steps = PG.Steps(prof, data, race)
    if #steps > 0 then
      ns.Guides:Register{
        id = PG.Id(faction, prof), title = prof .. " 1-300", faction = faction,
        special = true, profession = prof, minLevel = 1, maxLevel = 60, steps = steps,
      }
    end
  end
end

-- Oyuncunun meslek rehberi (kayitli degilse nil)
function PG.For(prof)
  local info = ns.Provider.PlayerInfo()
  return ns.Guides:Get(PG.Id(info.faction or "?", prof))
end

-- yuklenirken taraf bilinmiyorsa (yeni karakter / tarafsiz baslangic) girisle ya da taraf secilince tekrar denenir
local done
local function tryRegister()
  if done then return end
  local info = ns.Provider.PlayerInfo()
  if info.faction ~= "Alliance" and info.faction ~= "Horde" then return end
  done = true
  PG.Register(info.faction, info.race)
end
tryRegister()
ns:On("PLAYER_LOGIN", "ProfGuides", tryRegister)
ns:On("NEUTRAL_FACTION_SELECT_RESULT", "ProfGuides", tryRegister)
