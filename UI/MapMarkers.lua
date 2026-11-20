-- Arcanis: harita isaretleri (modul "MapMarkers"). Dunya haritasinda ve minimapte: zindan girisleri, sinifinin
-- trainer'lari, meslek trainer'lari, ucus noktalari, rare'ler, hunter icin ozel petler. Her kategori iki harita icin ayri acilip kapanir:
-- dunya haritasinin sag ustundeki Arcanis dugmesinden (kutucuklu panel) ya da Ayarlar > Route > Map markers.
-- Veri: Data/Dungeons.lua (Journal:Entrances), Data/ClassGuide (trainers), Data/Professions.lua (trainers),
-- Data/Transit.lua (ucus noktalari, dunya yardi). Blizzard pin'lerine dokunulmaz: tuvalde / minimapte kendi katmanimiz.
-- Gorevler: "!" su an alinabilir (veren tablosu + QuestState + Brain:CanAccept + Brain:GiverFits), "?" teslime hazir
-- (gunluk; konum rehber adimi > oyunun isareti > zincirdeki sonraki verenden tahmin). Rehberdeki gorev altin, digeri mavi.
-- Ulasim: iskeleler (Data/Transit.lua hatlari) ve ZR.LINKS (tram, portal). Bolge gecitleri (Data/ZoneGates.lua) tabela.
-- Bolge haritasinin ustunde seviye araligi (Data/ZoneInfo.lua). NPC ipucunda alinabilir / teslim edilecek gorevler.
local _, ns = ...

local P = ns.Provider
local L = ns.L
local M = ns.NavMath

local MM = ns:NewModule("MapMarkers", {
  defaults = {
    -- sahibin karari: yalniz zindan kapilari ve ucus noktalari acik gelir; hunter petleri yalniz hunter'da (nil = sinifa gore)
    world = { dungeons = true, classTrainers = false, profTrainers = false, flights = true, rares = false, farm = true, graveyards = true,
      quests = true, turnins = true, transport = true, gates = false },
    mini = { dungeons = true, classTrainers = false, profTrainers = false, flights = true, rares = false, farm = false, graveyards = false,
      quests = false, turnins = false, transport = false, gates = false },
    myProfs = false,   -- meslek trainer'lari: yalniz bildigin meslekler
    petDetails = true, -- hunter: pet isaretinin ipucunda ogrettigi yetenek, hiz, aile ozellikleri
    button = true,     -- dunya haritasinda Arcanis dugmesi
    zoneLevel = true,  -- bolge haritasinin ustunde seviye araligi
    npcTooltip = true, -- NPC ipucunda alinabilir / teslim edilecek gorevler
  },
})
ns.MapMarkers = MM

MM.CATEGORIES = { "dungeons", "quests", "turnins", "classTrainers", "profTrainers", "flights", "transport", "graveyards", "rares",
  "pets", "farm", "gates" }
local PIN, MINI_PIN = 20, 14
local MERGE = 0.006        -- dunya haritasinda ayni isarette birlesen noktalar (harita kesri)
local MINI_UPDATE = 0.5    -- minimap aday listesi (yakindakiler) bu siklikla; konumlar her karede
local MINI_MOVE = 0.03
MM.STATUS_COLORS = {
  now = { 0.30, 0.85, 0.50 }, soon = { 0.95, 0.75, 0.25 }, over = { 0.55, 0.55, 0.55 }, later = { 0.80, 0.80, 0.80 },
}
local CAT_COLOR = {
  classTrainers = { 0.96, 0.75, 0.34 }, profTrainers = { 0.45, 0.75, 0.95 }, flights = { 0.85, 0.85, 0.85 },
  rares = { 0.80, 0.55, 1.00 }, pets = { 0.55, 0.88, 0.40 }, farm = { 0.95, 0.80, 0.35 },
  graveyards = { 0.55, 0.85, 0.95 }, quests = { 1.00, 0.82, 0.10 }, turnins = { 1.00, 0.82, 0.10 },
  transport = { 0.60, 0.85, 1.00 }, gates = { 0.85, 0.78, 0.60 },
}
local CAT_ICON = { dungeons = "dungeon", classTrainers = "shield", profTrainers = "hammer", flights = "wing", rares = "star", pets = "pin", farm = "hammer",
  graveyards = "skull", quests = "exclaim", turnins = "question", transport = "flag", gates = "compass" }
-- gorev isareti rengi: rehberdeki gorev altin, rehber disi mavi
MM.QUEST_COLORS = { guide = { 1.00, 0.82, 0.10 }, other = { 0.45, 0.78, 1.00 } }
local TRAVEL_TEX = "Interface\\AddOns\\Arcanis\\Media\\UI\\travel_%s.tga"

function MM:CategoryName(cat)
  local t = {
    dungeons = L["Dungeons"], classTrainers = L["Class trainers"], profTrainers = L["Profession trainers"],
    flights = L["Flight masters"], rares = L["Rares"], pets = L["Hunter pets"], farm = L["Farm spots"],
    graveyards = L["Graveyards"], quests = L["Quest givers"], turnins = L["Quest turn-ins"], transport = L["Boats and portals"],
    gates = L["Zone borders"],
  }
  return t[cat] or cat
end

-- ===== Veri: kategori basina noktalar { map, x, y (0-1), cat, title, sub, d?, e? } =====
local function factionOK(f, mine) return not f or f == "Neutral" or not mine or f == mine end

local function raceOK(races, race)
  if not (races and race) then return true end
  for _, r in ipairs(races) do if r == race then return true end end
  return false
end

local SOURCES = {}

function SOURCES.dungeons(player)
  local J, out = ns.Journal, {}
  if not J then return out end
  for _, d in ipairs(J:List(player)) do
    for _, e in ipairs(J:Entrances(d)) do
      -- portal yer altinda / iceride: isaret yuzeydeki kapida (bina, magara agzi, asansor), ipucunda nasil girilir
      local at = e.door or e
      local how = d.how and ns:LocalizedText(d.how)
      out[#out + 1] = { map = e.map, x = at.x / 100, y = at.y / 100, cat = "dungeons",
        title = e.name and (d.name .. " - " .. e.name) or d.name, sub = L["Level %d-%d"]:format(d.minLevel, d.maxLevel),
        way = e.door and J:StepText(e.door.kind) or nil, how = how ~= "" and how or nil, d = d, e = e }
    end
  end
  return out
end

function SOURCES.classTrainers(player)
  local CG, out = ns.ClassGuide, {}
  if not (CG and player and player.class) then return out end
  local kinds = { class = L["Class trainer"], pet = L["Pet trainer"], portal = L["Portal trainer"], other = L["Class quest"] }
  for _, t in ipairs(CG:Trainers(player.class, player.faction)) do
    local map = t.map or (t.zone and ns.Zones:Resolve(t.zone))
    if map and t.x and t.y and raceOK(t.races, player.race) then
      out[#out + 1] = { map = map, x = t.x / 100, y = t.y / 100, cat = "classTrainers", title = t.npc,
        sub = (kinds[t.kind or "class"] or kinds.class) .. (t.mapHint and (" - " .. t.mapHint) or "") }
    end
  end
  return out
end

-- Meslek basina oyunun kendi ikonu ve ayirt edici renk (halka): ayni bolgedeki trainer'lar karismasin.
local PROF_STYLE = {
  Alchemy = { "Interface\\Icons\\Trade_Alchemy", { 0.45, 0.90, 0.40 } },
  Blacksmithing = { "Interface\\Icons\\Trade_BlackSmithing", { 0.70, 0.72, 0.78 } },
  Enchanting = { "Interface\\Icons\\Trade_Engraving", { 0.75, 0.50, 1.00 } },
  Engineering = { "Interface\\Icons\\Trade_Engineering", { 1.00, 0.62, 0.20 } },
  Herbalism = { "Interface\\Icons\\Trade_Herbalism", { 0.30, 0.80, 0.30 } },
  Leatherworking = { "Interface\\Icons\\INV_Misc_ArmorKit_17", { 0.72, 0.50, 0.30 } },
  Mining = { "Interface\\Icons\\Trade_Mining", { 0.85, 0.75, 0.45 } },
  Skinning = { "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", { 0.80, 0.60, 0.45 } },
  Tailoring = { "Interface\\Icons\\Trade_Tailoring", { 1.00, 0.55, 0.75 } },
  Cooking = { "Interface\\Icons\\INV_Misc_Food_15", { 1.00, 0.85, 0.30 } },
  ["First Aid"] = { "Interface\\Icons\\Spell_Holy_SealOfSacrifice", { 1.00, 0.35, 0.35 } },
  Fishing = { "Interface\\Icons\\Trade_Fishing", { 0.35, 0.75, 1.00 } },
}
MM.PROF_STYLE = PROF_STYLE
local RANK_OF = { [75] = "Apprentice", [150] = "Journeyman", [225] = "Expert", [300] = "Artisan" }

-- Meslek trainer'lari: meslek verisi (Data/Professions.lua) + meslek rehberlerinin "train" adimlari (taraf, irk);
-- ayni meslekte ayni NPC bir kez. Cooking, First Aid, Mining, Engineering yalniz rehberlerde.
function SOURCES.profTrainers(player, db)
  local out, seen = {}, {}
  local known = db and db.myProfs and P.Professions() or nil
  local function add(prof, npc, map, x, y, rank)
    if not (map and x and y and npc) or seen[prof .. "|" .. npc] then return end
    seen[prof .. "|" .. npc] = true
    local st = PROF_STYLE[prof]
    out[#out + 1] = { map = map, x = x / 100, y = y / 100, cat = "profTrainers", title = npc,
      sub = L[prof] .. (rank and (" (" .. L[rank] .. ")") or ""), group = prof,
      icon = st and st[1], color = st and st[2] }
  end
  for prof, data in pairs(ns.ProfessionData or {}) do
    if not known or known[prof] then
      for _, t in ipairs(data.trainers or {}) do
        if factionOK(t.faction, player and player.faction) then
          add(prof, t.npc, t.map or (t.zone and ns.Zones:Resolve(t.zone)), t.x, t.y, t.rank)
        end
      end
    end
  end
  local side = player and player.faction and ns.ProfessionGuides and ns.ProfessionGuides[player.faction]
  for prof, steps in pairs(side or {}) do
    if not known or known[prof] then
      for _, st in ipairs(steps) do
        if st.act == "train" then
          for _, a in ipairs(st.alts or {}) do
            if raceOK(a.races, player.race) then
              add(prof, a.npc, a.zone and ns.Zones:Resolve(a.zone), a.x, a.y, RANK_OF[st.max])
            end
          end
        end
      end
    end
  end
  return out
end

-- Farm pusulasi (Helpers/Farm.lua): toplanan yerler; meslek ikonu ve rengi, ipucunda kac kez toplandigi
function SOURCES.farm()
  local out, F = {}, ns.Farm
  if not (F and F.IsEnabled and F:IsEnabled()) then return out end
  for _, s in ipairs(F:Spots()) do
    local st = PROF_STYLE[s.k == "Herbalism" and "Herbalism" or s.k]
    out[#out + 1] = { map = s.map, x = s.x, y = s.y, cat = "farm", title = L[s.k], group = "farm:" .. s.k,
      sub = L["Gathered here %d times"]:format(s.n), icon = st and st[1], color = st and st[2] }
  end
  return out
end

function SOURCES.flights(player)
  local out, T = {}, ns.Transit
  if not (T and T.nodes) then return out end
  for _, n in pairs(T.nodes) do
    if factionOK(n[5], player and player.faction) then
      local map, x, y = P.ContinentMapPos(n[1], n[2], n[3])
      if map then out[#out + 1] = { map = map, x = x, y = y, cat = "flights", title = n[4], sub = L["Flight master"] } end
    end
  end
  return out
end
-- Dirilis noktalari (Data/Graveyards.lua, dunya yardi): oyuncunun tarafindakiler ve iki tarafin ortaklari.
-- Sunucu oldugun bolgeye bagli mezarliklardan cesede en yakinini secer; harita hepsini gosterir (taktik olum plani).
function SOURCES.graveyards(player)
  local out, mine = {}, player and player.faction
  local side = mine == "Alliance" and "A" or mine == "Horde" and "H" or nil
  for _, g in ipairs(ns.Graveyards or {}) do
    if not g[4] or not side or g[4] == side then
      out[#out + 1] = { c = g[1], wx = g[2], wy = g[3], cat = "graveyards", title = L["Graveyard"],
        sub = L["You resurrect here if you die nearby."] }
    end
  end
  return out
end

-- Rare'ler: bilinen dogma noktalari + oyunda gorulenler (Helpers/Rares.lua)
function SOURCES.rares()
  local out, R = {}, ns.RareSpawns
  if not (R and R.db) then return out end
  for _, r in ipairs(R:Points()) do
    local lv = r.lv and (r.lvMax and L["Level %d-%d"]:format(r.lv, r.lvMax) or L["Level %d"]:format(r.lv))
      or (r.skull and (L["Level %d"]:gsub("%%d", "??"))) or ""   -- skull: seviyesi "??" (Data/Rares.lua)
    local parts = { lv }
    if r.elite then parts[#parts + 1] = L["Rare elite"] end
    if r.tame then parts[#parts + 1] = L["Tameable"] end
    if r.seen then parts[#parts + 1] = L["Seen by you"] end
    local sub = table.concat(parts, "  ")
    out[#out + 1] = { map = r.map, x = r.x, y = r.y, c = r.c, wx = r.wx, wy = r.wy, cat = "rares", title = r.name or "?",
      sub = sub ~= "" and sub or nil }
  end
  return out
end
-- Hunter petleri: oyunun aile ikonu; rare olanlarin halkasi mavi (ayni yerde siradanla birlesmez).
local PET_ICON = {
  Cat = "Cat", Wolf = "Wolf", Spider = "Spider", Bear = "Bear", ["Carrion Bird"] = "Vulture", Hyena = "Hyena",
  Scorpid = "Scorpid", ["Wind Serpent"] = "WindSerpent", Turtle = "Turtle", Tallstrider = "TallStrider",
  Raptor = "Raptor", Crocolisk = "Crocolisk", ["Bird of Prey"] = "Owl", Gorilla = "Gorilla", Boar = "Boar",
  Bat = "Bat", Crab = "Crab",
}
MM.PET_ICON = PET_ICON
local PET_RARE_COLOR = { 0.35, 0.65, 1.00 }
MM.PET_PER_FAMILY = 5      -- bolge x aile basina en cok bu kadar isaret (harita noktaya bogulmasin)
local PET_GAP = 40         -- yd: secilen isaretler en az bu kadar ayri

-- Bir bolgedeki ayni ailenin noktalarindan en cok n tane: once her pet bir nokta (rare once, kendi
-- noktalarinin ortasina en yakini), kalan yer birbirinden en uzak noktalarla dolar.
function MM.SpreadPets(group, n)
  table.sort(group, function(a, b)
    if (a.rare and 1 or 0) ~= (b.rare and 1 or 0) then return a.rare ~= nil end
    return (a.lv or 0) < (b.lv or 0)
  end)
  local picked, pool = {}, {}
  for _, r in ipairs(group) do
    local cx, cy = 0, 0
    for _, p in ipairs(r.pts) do cx, cy = cx + p[1], cy + p[2] end
    cx, cy = cx / #r.pts, cy / #r.pts
    local best, bd
    for _, p in ipairs(r.pts) do
      local d = (p[1] - cx) ^ 2 + (p[2] - cy) ^ 2
      if not bd or d < bd then best, bd = p, d end
      pool[#pool + 1] = { r = r, p = p }
    end
    if #picked < n then picked[#picked + 1] = { r = r, p = best } end
  end
  while #picked < n do
    local best, bd
    for _, c in ipairs(pool) do
      local md
      for _, s in ipairs(picked) do
        local d = (c.p[1] - s.p[1]) ^ 2 + (c.p[2] - s.p[2]) ^ 2
        if not md or d < md then md = d end
      end
      if md and md >= PET_GAP * PET_GAP and (not bd or md > bd) then best, bd = c, md end
    end
    if not best then break end
    picked[#picked + 1] = best
  end
  return picked
end

-- Hunter icin ozel petler (Data/HunterPets.lua): yalniz hunter karakterlerde. Dunya yardi -> kita haritasi bir kez.
function SOURCES.pets(player)
  local out = {}
  if not (player and player.class == "HUNTER") then return out end
  local groups, order = {}, {}
  for _, r in ipairs(ns.HunterPetData or {}) do
    if r.pts and #r.pts > 0 then
      local key = (r.zone or "?") .. "|" .. (r.family or "?")
      if not groups[key] then groups[key] = {}; order[#order + 1] = key end
      table.insert(groups[key], r)
    end
  end
  for _, key in ipairs(order) do
    for _, s in ipairs(MM.SpreadPets(groups[key], MM.PET_PER_FAMILY)) do
      local r = s.r
      local parts = { r.family }
      if r.lv then parts[#parts + 1] = r.lvMax and L["Level %d-%d"]:format(r.lv, r.lvMax) or L["Level %d"]:format(r.lv) end
      if r.rare then parts[#parts + 1] = L["Rare"] end
      if r.fast then parts[#parts + 1] = L["Faster attack"] end
      if r.elite then parts[#parts + 1] = L["Elite"] end
      local icon = PET_ICON[r.family]
      out[#out + 1] = { c = r.c, wx = s.p[1], wy = s.p[2], cat = "pets", title = r.name, sub = table.concat(parts, "  "),
        pet = r, group = "pets:" .. (r.family or "?") .. (r.rare and ":rare" or ""),
        icon = "Interface\\Icons\\" .. (icon and ("Ability_Hunter_Pet_" .. icon) or "Ability_Hunter_BeastTaming"),
        color = r.rare and PET_RARE_COLOR or nil }
    end
  end
  return out
end

-- ===== Gorevler: "!" alinabilir, "?" teslime hazir =====
local function guideSet()
  local E, set = ns.Engine, {}
  for _, s in ipairs(E and E.guide and E.guide.steps or {}) do if s.quest then set[s.quest] = true end end
  return set
end

local function questSub(level, npc, guide)
  local parts = {}
  if level and level > 0 then parts[#parts + 1] = L["Level %d"]:format(level) end
  if npc then parts[#parts + 1] = npc end
  parts[#parts + 1] = guide and L["In your guide"] or L["Not in guide"]
  return table.concat(parts, "  ")
end

-- Bu karakterin SIMDI alabilecegi gorevler (Data/Brain givers): { { q, r, guide }, ... }, rehberdekiler once.
-- Ucuz suzgec (seviye bandi, irk / sinif, Brain:GiverFits) once: QuestState yalniz kalan birkac yuz goreve sorulur.
function MM:Available(player)
  local G, B, QS = ns.BrainData and ns.BrainData.givers, ns.Brain, ns.QuestState
  if not (G and B and QS and player) then return {} end
  local E = ns.Engine
  local missing = E and E.char and E.char.giverMissing or {}
  local inGuide, out = guideSet(), {}
  for q, r in pairs(G) do
    if not missing[q] and B:GiverFits(r, player, q) then
      local st = QS:Status(q)
      if (st == "open" or st == "unknown") and B:CanAccept(q) ~= false then
        out[#out + 1] = { q = q, r = r, guide = inGuide[q] or false }
      end
    end
  end
  table.sort(out, function(a, b) if a.guide ~= b.guide then return a.guide end return a.q < b.q end)
  return out
end

function SOURCES.quests(player)
  local out, QC = {}, MM.QUEST_COLORS
  for _, a in ipairs(MM:Available(player)) do
    local r = a.r
    local map = r[7] and ns.Zones:Resolve(r[7])
    if map and r[8] and r[9] then
      out[#out + 1] = { map = map, x = r[8], y = r[9], cat = "quests", title = r[1], npc = r[6], quest = a.q, level = r[2],
        sub = questSub(r[2], r[6], a.guide), color = a.guide and QC.guide or QC.other }
    end
  end
  return out
end

-- Teslime hazir gorevler (gunluk). Konum: etkin rehberin teslim adimi (Zones:Location: ogrenilen NPC yeri, oyunun
-- isareti) > oyunun isareti (yalniz oyuncunun haritasi) > zincirdeki sonraki gorevin vereni (Brain:TurnInGuess).
function SOURCES.turnins()
  local out, E, QC = {}, ns.Engine, MM.QUEST_COLORS
  local steps = {}
  for _, s in ipairs(E and E.guide and E.guide.steps or {}) do
    if s.type == "turnin" and s.quest and not steps[s.quest] then steps[s.quest] = s end
  end
  local G = ns.BrainData and ns.BrainData.givers or {}
  for _, e in ipairs(P.QuestLogList()) do
    if e.complete and e.id then
      local s = steps[e.id]
      local map, x, y, npc
      if s then map, x, y = ns.Zones:Location(s); npc = s.npc end
      if not map then map, x, y = P.QuestMapPos(e.id) end
      if not map and ns.Brain then
        local g = ns.Brain:TurnInGuess(e.id)
        if g then map, x, y, npc = ns.Zones:Resolve(g.zone), g.x, g.y, g.npc end
      end
      if map and x and y then
        local lv = P.QuestLevel(e.id) or (G[e.id] and G[e.id][2])
        out[#out + 1] = { map = map, x = x, y = y, cat = "turnins", title = e.title or P.QuestName(e.id, "?"), npc = npc,
          quest = e.id, level = lv, sub = questSub(lv, npc, s ~= nil), color = s and QC.guide or QC.other }
      end
    end
  end
  return out
end

-- ===== Ulasim: iskeleler (gemi / zeplin hatlari), tram ve portal =====
local function departure(p)
  local T = ns.Transport
  local n = p.dock and T and T.NextDeparture and T:NextDeparture(p.dock)
  if not n then return nil end
  local label = n.to == "?" and (n.kind == "zeppelin" and L["Next zeppelin"] or L["Next boat"])
    or (n.kind == "zeppelin" and L["Zeppelin to %s"] or L["Boat to %s"]):format(n.to)
  if n.boarding then return L["Boarding now: %s"]:format(label) end
  local clock = ns.Island and ns.Island.Clock and ns.Island.Clock(n.wait) or tostring(math.floor(n.wait))
  return L["Next departure: %s in %s"]:format(label, (n.stale and "~" or "") .. clock)
end
MM.Departure = departure

function SOURCES.transport(player)
  local out, T = {}, ns.Transit
  local horde = player and player.faction == "Horde"
  local lines = {}   -- iskele -> { kind, "Boat to X", ... }
  for _, r in pairs(T and T.routes or {}) do
    if r.kind ~= "zeppelin" or horde then   -- zeplin kuleleri Horde kasabalarinda (ZR:LinkNodes ile ayni kural)
      for k, s in ipairs(r.stops) do
        local l = lines[s[1]] or { kind = r.kind }
        lines[s[1]] = l
        for j, e in ipairs(r.stops) do
          local d = j ~= k and T.docks[e[1]]
          if d and d[4] ~= "?" then l[#l + 1] = (r.kind == "zeppelin" and L["Zeppelin to %s"] or L["Boat to %s"]):format(d[4]) end
        end
      end
    end
  end
  for id, l in pairs(lines) do
    local d = T.docks[id]
    if d and d[4] ~= "?" then
      table.sort(l)
      out[#out + 1] = { c = d[1], wx = d[2], wy = d[3], cat = "transport", title = d[4], dock = id, lines = l,
        icon = TRAVEL_TEX:format(l.kind), live = departure, group = "transport:" .. l.kind }
    end
  end
  -- tram ve Darnassus portali yalniz Alliance sehirlerinde
  for _, k in ipairs(not horde and ns.ZoneRoute and ns.ZoneRoute.LINKS or {}) do
    if k.kind then
      local title = k.kind == "tram" and L["Deeprun Tram"] or L["Portal"]
      for _, e in ipairs({ { k.a, k.nb }, { k.b, k.na } }) do
        out[#out + 1] = { c = k.c, wx = e[1][1], wy = e[1][2], cat = "transport", title = title, sub = L["To %s"]:format(e[2]),
          icon = k.kind == "portal" and TRAVEL_TEX:format("teleport") or nil, group = "transport:" .. k.kind }
      end
    end
  end
  return out
end

-- ===== Bolge seviyesi ve gecitler =====
local zoneNames   -- ui harita -> Ingilizce bolge adi (Data/ZoneInfo.lua anahtari)
function MM.ZoneLevel(ui)
  if not zoneNames then
    zoneNames = {}
    for name, id in pairs(ns.Zones and ns.Zones.defaults or {}) do
      if ns.ZoneInfoData and ns.ZoneInfoData[name] then zoneNames[id] = name end
    end
  end
  local d = ui and zoneNames[ui] and ns.ZoneInfoData[zoneNames[ui]]
  if d then return d.min, d.max end
end

local function zoneName(ui)
  local info = P.MapInfo(ui)
  return info and info.name or (zoneNames and zoneNames[ui]) or tostring(ui)
end

local LEVEL_HIGH = { 0.95, 0.35, 0.30 }
-- Seviye araligi rengi: ustundesin gri, icindesin yesil, 3 seviye altindasin sari, daha asagidaysan kirmizi.
function MM.LevelColor(min, max, level)
  local S = MM.STATUS_COLORS
  if level > max then return S.over elseif level >= min then return S.now elseif level >= min - 3 then return S.soon end
  return LEVEL_HIGH
end

local function levelText(ui)
  local min, max = MM.ZoneLevel(ui)
  return min and L["Level %d-%d"]:format(min, max) or nil
end

-- Gecit tabelasi: bakilan bolgeden digerine "To X" (bakilan harita gecidin iki bolgesinden biri degilse ikisi).
local function describeGate(p, view)
  local a, b = p.gate[1], p.gate[2]
  local other = (view == a and b) or (view == b and a) or nil
  if other then return L["To %s"]:format(zoneName(other)), levelText(other) end
  return p.title, nil
end
MM.DescribeGate = describeGate

function SOURCES.gates()
  local out = {}
  for c, list in pairs(ns.ZoneGates or {}) do
    for _, g in ipairs(list) do
      out[#out + 1] = { c = c, wx = g[3], wy = g[4], cat = "gates", gate = { g[1], g[2] }, describe = describeGate,
        title = zoneName(g[1]) .. " / " .. zoneName(g[2]), group = "gates:" .. g[1] .. ":" .. g[2] }
    end
  end
  return out
end
MM.SOURCES = SOURCES

-- Kategori acik mi: hunter petleri yalniz hunter'da (kayitli secim yoksa acik); digerleri ayardan.
function MM:Shown(which, cat, player)
  if cat == "pets" then
    player = player or P.PlayerInfo()
    if not (player and player.class == "HUNTER") then return false end
    return self.db[which].pets ~= false
  end
  return self.db[which][cat] and true or false
end

-- Noktanin dunya konumu (kita, yard): veride hazir (rare, pet) ya da harita noktasindan bir kez (onbellek).
local function worldOf(p)
  if p.c == nil and p.map then
    local c, wx, wy = P.WorldPos(p.map, p.x, p.y)
    if c then p.c, p.wx, p.wy = c, wx, wy end   -- istemci hazir degilse onbellege alinmaz, sonra yeniden denenir
  end
  return p.c, p.wx, p.wy
end
MM.WorldOf = worldOf

-- Haritadaki konumu (oka): harita noktasi yoksa dunya yardindan kita haritasina.
local function mapOf(p)
  if not p.map and p.c then p.map, p.x, p.y = P.ContinentMapPos(p.c, p.wx, p.wy) end
  return p.map, p.x, p.y
end
MM.MapOf = mapOf

-- Acik kategorilerin noktalari (which: "world" | "mini"). Kaynaklar degismedigi icin onbellek; seviye/meslek/
-- ayar degisince MM:Invalidate().
-- Bir kategorinin noktalari (onbellekli; gorevler QuestTick'te en cok QUEST_REFRESH sn'de bir yenilenir).
function MM:List(cat, player)
  self.cache = self.cache or {}
  local list = self.cache[cat]
  if not list then list = SOURCES[cat](player or P.PlayerInfo(), self.db); self.cache[cat] = list end
  return list
end

function MM:Points(which, player)
  player = player or P.PlayerInfo()
  local out = {}
  for _, cat in ipairs(self.CATEGORIES) do
    if self:Shown(which, cat, player) then
      for _, p in ipairs(self:List(cat, player)) do out[#out + 1] = p end
    end
  end
  return out
end

function MM:Invalidate() self.cache, self.miniBuckets, self.npcIndex = nil, nil, nil end

-- Gorev listeleri gunluk / rehber degisince eskir: olaylar yalniz isaretler, yenileme surucude seyreltilir
-- (QUEST_LOG_UPDATE savasta saniyede birkac kez gelir). Liste tembel: harita / ipucu istemedikce kurulmaz.
local QUEST_REFRESH = 2
function MM:QuestTick()
  local E = ns.Engine
  local guide = E and E.guide
  if guide ~= self.questGuide then self.questGuide, self.questDirty = guide, true end
  if not self.questDirty or P.Now() - (self.questAt or 0) < QUEST_REFRESH then return end
  self.questDirty, self.questAt = false, P.Now()
  if self.cache then self.cache.quests, self.cache.turnins = nil, nil end
  self.npcIndex = nil
  if self:Shown("mini", "quests") or self:Shown("mini", "turnins") then self.miniBuckets = nil end
  if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown()
    and (self:Shown("world", "quests") or self:Shown("world", "turnins")) then self:RefreshWorld() end
end

-- ===== NPC ipucu: fare altindaki NPC'nin alinabilir ve teslim edilecek gorevleri =====
local NPC_NEAR = 300   -- yd: ayni adli NPC'ler (muhafiz vb.) ayrissin; verenin noktasi oyuncuya bu kadar yakin olmali
function MM:NpcIndex(player)
  if self.npcIndex then return self.npcIndex end
  local idx = {}
  for _, cat in ipairs({ "turnins", "quests" }) do
    for _, p in ipairs(self:List(cat, player)) do
      if p.npc then idx[p.npc] = idx[p.npc] or {}; table.insert(idx[p.npc], p) end
    end
  end
  self.npcIndex = idx
  return idx
end

-- Ipucu satirlari { { metin, r, g, b }, ... }: once teslimler ("?"), sonra alinabilirler ("!"). c, x, y oyuncunun
-- dunya konumu (yoksa yalniz ad).
function MM:NpcLines(name, player, c, x, y)
  local out = {}
  for _, p in ipairs(name and self:NpcIndex(player)[name] or {}) do
    local pc, px, py = worldOf(p)
    if not (c and pc) or (pc == c and math.abs(px - x) <= NPC_NEAR and math.abs(py - y) <= NPC_NEAR) then
      local col = p.color or CAT_COLOR[p.cat]
      local lv = p.level and p.level > 0 and (" (" .. p.level .. ")") or ""
      out[#out + 1] = { (p.cat == "turnins" and "? " or "! ") .. p.title .. lv, col[1], col[2], col[3] }
    end
  end
  return out
end

function MM:HookTooltip()
  if self.tipHooked then return end
  self.tipHooked = true
  local function add(tt, fresh)
    if tt ~= GameTooltip or not (MM:IsEnabled() and MM.db.npcTooltip) then return end
    local name = P.TooltipNpcName(tt)
    if not name then return end
    local lines = MM:NpcLines(name, nil, P.PlayerWorldPos())
    for _, ln in ipairs(lines) do tt:AddLine(ln[1], ln[2], ln[3], ln[4]) end
    if #lines > 0 and not fresh then tt:Show() end
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt) ns.SafeCall(add, tt, true) end)
  elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tt) ns.SafeCall(add, tt) end)
  end
end

-- Minimap noktalari kitaya gore (onbellekli; acik kategoriler ya da veri degisince yeniden): RefreshMini 0,5 sn'de
-- bir yalniz oyuncunun kitasindakilere bakar, her seferinde binlerce noktalik yeni liste kurmaz.
function MM:MiniBuckets()
  local player = P.PlayerInfo()
  local sig = {}
  for _, cat in ipairs(self.CATEGORIES) do sig[#sig + 1] = self:Shown("mini", cat, player) and "1" or "0" end
  sig = table.concat(sig)
  if self.miniBuckets and self.miniSig == sig then return self.miniBuckets end
  local buckets = {}
  for _, p in ipairs(self:Points("mini", player)) do
    local c = worldOf(p)
    if c then
      buckets[c] = buckets[c] or {}
      buckets[c][#buckets[c] + 1] = p
    end
  end
  self.miniBuckets, self.miniSig = buckets, sig
  return buckets
end

-- Gosterilen haritadaki isaretler: ayni kategoride ust uste dusenler tek isarette.
-- { { x, y (0-1), cat, list = { nokta, ... } }, ... }
-- Hiz: haritanin dunya dikdortgeni (P.MapWorldRect, onbellekli) ile her nokta tek carpma; birlestirme izgarayla
-- (binlerce rare / pet noktasinda harita acilisi yavaslamasin). Dikdortgen yoksa nokta basina P.MapPosOn.
function MM:WorldPoints(display, player)
  local out = {}
  if not display then return out end
  local rect = P.MapWorldRect and P.MapWorldRect(display)
  local grid = {}
  for _, p in ipairs(self:Points("world", player)) do
    local x, y
    if rect then
      local c, wx, wy = worldOf(p)
      if c == rect.c then
        x = (wy - rect.wy0) / (rect.wy1 - rect.wy0)
        y = (wx - rect.wx0) / (rect.wx1 - rect.wx0)
      end
    elseif p.map then
      x, y = P.MapPosOn(p.map, p.x, p.y, display)
    end
    if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
      -- ayni kategoride MERGE icindeki isaret: kendi hucresi ve 8 komsusu aranir
      local gx, gy = math.floor(x / MERGE), math.floor(y / MERGE)
      local hit
      for dx = -1, 1 do
        for dy = -1, 1 do
          local cell = grid[(p.group or p.cat) .. ":" .. (gx + dx) .. ":" .. (gy + dy)]
          if cell then
            for _, o in ipairs(cell) do
              if math.abs(o.x - x) < MERGE and math.abs(o.y - y) < MERGE then hit = o break end
            end
          end
          if hit then break end
        end
        if hit then break end
      end
      if hit then hit.list[#hit.list + 1] = p
      else
        hit = { x = x, y = y, cat = p.cat, list = { p } }
        local key = (p.group or p.cat) .. ":" .. gx .. ":" .. gy
        grid[key] = grid[key] or {}
        table.insert(grid[key], hit)
        out[#out + 1] = hit
      end
    end
  end
  return out
end

-- Isaret rengi: zindanda seviyeye en uygun olanin durumu, digerlerinde kategori rengi.
local RANK = { now = 1, soon = 2, later = 3, over = 4 }
function MM.Color(pt, level)
  if pt.list[1] and pt.list[1].color then return pt.list[1].color end
  if pt.cat ~= "dungeons" then return CAT_COLOR[pt.cat] end
  local J, best = ns.Journal, nil
  for _, p in ipairs(pt.list) do
    local s = J:Status(p.d, level)
    if not best or RANK[s] < RANK[best] then best = s end
  end
  return MM.STATUS_COLORS[best or "later"]
end

-- ===== Isaret dugmesi (dunya haritasi ve minimap ortak) =====
-- Hunter pet ayrintisi (ayar petDetails, yalniz hunter): { { metin, r, g, b }, ... }
local function pct(v) return (v > 0 and "+" or "") .. v .. "%" end
function MM:PetLines(r, player)
  player = player or P.PlayerInfo()
  if not (r and self.db.petDetails and player and player.class == "HUNTER") then return {} end
  local out = {}
  local function add(text, c) out[#out + 1] = { text, (c or { 0.85, 0.85, 0.85 })[1], (c or { 0.85, 0.85, 0.85 })[2], (c or { 0.85, 0.85, 0.85 })[3] } end
  if r.teaches and #r.teaches > 0 then
    local t = {}
    for _, a in ipairs(r.teaches) do t[#t + 1] = a[1] .. " " .. L["Rank %d"]:format(a[2]) end
    add(L["Teaches: %s"]:format(table.concat(t, ", ")), { 0.40, 0.85, 1.00 })
  end
  add(L["Attack speed: %s"]:format(r.speed and ("%.1f"):format(r.speed) or "2.0"), r.speed and { 0.40, 0.90, 0.45 } or nil)
  local f = ns.HunterPetFamilies and ns.HunterPetFamilies[r.family]
  if f then
    local mods = {}
    if f.dmg ~= 0 then mods[#mods + 1] = L["Damage %s"]:format(pct(f.dmg)) end
    if f.armor ~= 0 then mods[#mods + 1] = L["Armor %s"]:format(pct(f.armor)) end
    if f.hp ~= 0 then mods[#mods + 1] = L["Health %s"]:format(pct(f.hp)) end
    if #mods > 0 then add(table.concat(mods, "  ")) end
    if f.special then add(L["Family ability: %s"]:format(f.special)) end
    if f.learns and #f.learns > 0 then add(L["Can learn: %s"]:format(table.concat(f.learns, ", "))) end
    if f.diet and #f.diet > 0 then
      local foods = {}
      local names = { meat = L["meat"], fish = L["fish"], cheese = L["cheese"], bread = L["bread"], fungus = L["fungus"],
        fruit = L["fruit"], ["raw fish"] = L["raw fish"] }
      for _, w in ipairs(f.diet) do foods[#foods + 1] = names[w] or w end
      add(L["Diet: %s"]:format(table.concat(foods, ", ")))
    end
  end
  return out
end

local function tooltip(pin)
  if not (GameTooltip and pin.pt) then return end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  local level, player = P.PlayerLevel(), P.PlayerInfo()
  -- bakilan harita (gecit tabelasi "To X" buna gore): dunya haritasi ya da minimapte oyuncunun haritasi
  local view = pin.mini and P.PlayerMapPosition() or (WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID())
  for i, p in ipairs(pin.pt.list) do
    local c = p.d and MM.STATUS_COLORS[ns.Journal:Status(p.d, level)] or p.color or CAT_COLOR[p.cat] or { 1, 1, 1 }
    local title, sub = p.title, p.sub
    if p.describe then title, sub = p.describe(p, view) end
    if i == 1 then GameTooltip:SetText(title, c[1], c[2], c[3]) else GameTooltip:AddLine(title, c[1], c[2], c[3]) end
    if sub then GameTooltip:AddLine(sub, 1, 1, 1) end
    for _, ln in ipairs(p.lines or {}) do GameTooltip:AddLine(ln, 1, 1, 1) end
    local live = p.live and p.live(p)
    if live then GameTooltip:AddLine(live, 0.40, 0.85, 1.00) end
    if p.way then GameTooltip:AddLine(L["Way in here: %s"]:format(p.way), 0.40, 0.85, 1.00) end
    if p.how and #pin.pt.list == 1 then GameTooltip:AddLine(p.how, 0.85, 0.85, 0.85, true) end
    if p.pet and i <= 3 then
      for _, ln in ipairs(MM:PetLines(p.pet, player)) do GameTooltip:AddLine(ln[1], ln[2], ln[3], ln[4], true) end
    end
  end
  if pin.pt.cat == "dungeons" then GameTooltip:AddLine(L["Click: open in the dungeon journal"], 0.6, 0.6, 0.6) end
  if pin.pt.cat == "gates" and not pin.mini then GameTooltip:AddLine(L["Click: open that zone's map"], 0.6, 0.6, 0.6) end
  GameTooltip:AddLine(L["Shift-click: point the arrow here"], 0.6, 0.6, 0.6)
  local t = ns.Nav and ns.Nav:GetTarget()
  if t and t.source ~= "guide" then GameTooltip:AddLine(L["Right-click: stop the arrow"], 0.6, 0.6, 0.6) end
  GameTooltip:Show()
end

-- Sag tik: haritadan / gunlukten kurulan oku birakir; rehber varsa ok rehberin adimina doner.
function MM:StopArrow()
  local Nav = ns.Nav
  return Nav and Nav.DropTarget and Nav:DropTarget() or false
end

-- Oku kuran isaret (tikla / Shift + tik): ok hala onun hedefindeyken isaret buyur ve parlar, ok isaretcisi gizlenir.
local function pinKey(p) return (p.cat or "") .. ":" .. tostring(p.title) end
function MM:ActiveTarget()
  local a, t = self.active, ns.Nav and ns.Nav:GetTarget()
  return a and t and a.t == t and a or nil
end

local function onClick(pin, button)
  if button == "RightButton" then MM:StopArrow() return end
  local p = pin.pt and pin.pt.list[1]
  if not p then return end
  local shift = IsShiftKeyDown and IsShiftKeyDown()
  local before = ns.Nav and ns.Nav:GetTarget()
  MM:Point(pin, p, shift)
  local t = ns.Nav and ns.Nav:GetTarget()
  if t and t ~= before then MM.active = { key = pinKey(p), t = t } end
  MM:RefreshWorld()
end

function MM:Point(pin, p, shift)
  if p.d and not shift then
    if ns.DungeonWindow then ns.Journal.focus = p.d.id; ns.DungeonWindow:Open() end
  elseif p.d then
    ns.Journal:PointTo(p.d, p.e)
  elseif p.gate and not shift and not pin.mini and WorldMapFrame and WorldMapFrame.SetMapID then
    local view = WorldMapFrame:GetMapID()
    WorldMapFrame:SetMapID(view == p.gate[1] and p.gate[2] or p.gate[1])
  elseif ns.Nav then
    local map, x, y = mapOf(p)
    if map then ns.Nav:SetTarget(map, x, y, p.title, "manual") end
  end
end

local function newPin(holder, size)
  local Skin = ns.Skin
  local pin = CreateFrame("Button", nil, holder)
  pin.mini = size == MINI_PIN
  pin.size = size
  pin:SetSize(size, size)
  pin.bg = pin:CreateTexture(nil, "BACKGROUND")
  pin.bg:SetAllPoints()
  pin.bg:SetTexture(Skin.Icons.disc)
  pin.bg:SetVertexColor(0.05, 0.05, 0.07, 0.85)
  pin.ring = pin:CreateTexture(nil, "BORDER")
  pin.ring:SetAllPoints()
  pin.ring:SetTexture(Skin.Icons.ring)
  pin.icon = pin:CreateTexture(nil, "ARTWORK")
  pin.icon:SetPoint("CENTER")
  pin.icon:SetSize(size - 8, size - 8)
  pin.count = pin:CreateFontString(nil, "OVERLAY")
  Skin:SetFont(pin.count, 9, "OUTLINE")
  pin.count:SetPoint("BOTTOMRIGHT", 3, -2)
  pin:SetScript("OnEnter", tooltip)
  pin:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  if pin.RegisterForClicks then pin:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
  pin:SetScript("OnClick", onClick)
  return pin
end

local function paintPin(pin, pt, level)
  pin.pt = pt
  local c = MM.Color(pt, level)
  local own = pt.list[1] and pt.list[1].icon
  pin.ring:SetVertexColor(c[1], c[2], c[3], 1)
  if own then
    -- meslek: oyunun renkli ikonu (kenarlari kirpilmis), halka meslek renginde
    pin.icon:SetTexture(own)
    if pin.icon.SetTexCoord then pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    pin.icon:SetVertexColor(1, 1, 1, 1)
  else
    pin.icon:SetTexture(ns.Skin.Icons[CAT_ICON[pt.cat]])
    if pin.icon.SetTexCoord then pin.icon:SetTexCoord(0, 1, 0, 1) end
    pin.icon:SetVertexColor(c[1], c[2], c[3], 1)
  end
  pin.count:SetText(#pt.list > 1 and tostring(#pt.list) or "")
  -- gidilen isaret: kendi renginde parlak hale, ikon tam renk, biraz buyuk
  local a = not pin.mini and MM:ActiveTarget()
  local on = a and pt.list[1] and a.key == pinKey(pt.list[1])
  if on and not pin.glow then
    pin.glow = pin:CreateTexture(nil, "BACKGROUND", nil, -1)
    pin.glow:SetPoint("CENTER")
    pin.glow:SetTexture(ns.Skin.Icons.disc)
    pin.glow:SetBlendMode("ADD")
  end
  if pin.glow then
    if on then
      -- hale yarim guc (sahibin istegi, 15 Kasim 2026: haritada beyaz leke gibi duruyordu)
      pin.glow:SetSize(pin.size * 1.2, pin.size * 1.2)   -- bir kez daha %30 kucuk (sahibin istegi)
      pin.glow:SetVertexColor(c[1], c[2], c[3], 0.38)
      pin.glow:Show()
    else
      pin.glow:Hide()
    end
  end
  pin.activeScale = on and 1.35 or 1
  pin.ring:SetVertexColor(on and 1 or c[1], on and 1 or c[2], on and 1 or c[3], 1)
end

-- ===== Dunya haritasi =====
function MM:EnsureWorld()
  if self.holder then return true end
  local frame = WorldMapFrame
  if not (frame and frame.GetCanvas) then return false end
  local canvas = frame:GetCanvas()
  if not canvas then return false end
  local holder = CreateFrame("Frame", "ArcanisMapMarkers", canvas)
  holder:SetAllPoints(canvas)
  if holder.SetFrameLevel and canvas.GetFrameLevel then holder:SetFrameLevel((canvas:GetFrameLevel() or 1) + 20) end
  self.holder, self.canvas, self.pins = holder, canvas, {}
  return true
end

-- Bolge haritasinda Blizzard'in ve bizim (Reveal map) doku katmanlari tuvalde yuksek seviyelerde; altinda kalan
-- isaret gorunmez ama fareyi alir. Her cizimde tuvalin en yuksek cocugunun ustune cikilir.
function MM:RaiseLayer()
  local holder, canvas = self.holder, self.canvas
  if not (holder.SetFrameLevel and canvas.GetChildren) then return end
  local top = 0
  for _, child in ipairs({ canvas:GetChildren() }) do
    if child ~= holder and child.GetFrameLevel then top = math.max(top, child:GetFrameLevel() or 0) end
  end
  if top >= (holder:GetFrameLevel() or 0) then holder:SetFrameLevel(math.min(top + 5, 9000)) end
end

function MM:HideWorld()
  for _, p in ipairs(self.pins or {}) do p:Hide() end
  if self.holder then self.holder:Hide() end
  if self.zoneLabel then self.zoneLabel:Hide() end
  self.shown = 0
end

-- Bolge haritasinin ust ortasinda seviye araligi (oyuncunun seviyesine gore renkli); bolge verisi yoksa gizli.
function MM:ZoneLabel(display)
  local frame = WorldMapFrame
  local parent = frame and (frame.ScrollContainer or frame)
  if not parent then return end
  local f = self.zoneLabel
  if not f then
    f = CreateFrame("Frame", nil, parent)
    f:SetSize(200, 20)
    f:SetPoint("TOP", parent, "TOP", 0, -12)
    if f.SetFrameLevel and parent.GetFrameLevel then f:SetFrameLevel((parent:GetFrameLevel() or 1) + 50) end
    f.text = f:CreateFontString(nil, "OVERLAY")
    ns.Skin:SetFont(f.text, 13, "OUTLINE")
    f.text:SetPoint("CENTER")
    self.zoneLabel = f
  end
  local min, max
  if self.db.zoneLevel then min, max = MM.ZoneLevel(display) end
  if not min then f:Hide() return end
  local c = MM.LevelColor(min, max, P.PlayerLevel())
  f.text:SetText(L["Level %d-%d"]:format(min, max))
  f.text:SetTextColor(c[1], c[2], c[3])
  f.levels = { min, max }
  f:Show()
end

function MM:RefreshWorld()
  if not self:EnsureWorld() then return end
  self:UpdateButton()
  local frame = WorldMapFrame
  if not (self:IsEnabled() and frame.IsShown and frame:IsShown()) then self:HideWorld() return end
  local display = frame.GetMapID and frame:GetMapID()
  local w, h = self.canvas:GetWidth(), self.canvas:GetHeight()
  if not (display and w and h and w > 0 and h > 0) then self:HideWorld() return end
  self.holder:Show()
  self:ZoneLabel(display)
  self:RaiseLayer()
  local level, n = P.PlayerLevel(), 0
  for _, pt in ipairs(self:WorldPoints(display)) do
    n = n + 1
    local pin = self.pins[n]
    if not pin then pin = newPin(self.holder, PIN); self.pins[n] = pin end
    paintPin(pin, pt, level)
    pin.px, pin.py = pt.x, pt.y
    if pin.SetFrameLevel and self.holder.GetFrameLevel then
      pin:SetFrameLevel((self.holder:GetFrameLevel() or 1) + (pin.activeScale ~= 1 and 3 or 1))
    end
    pin:Show()
  end
  for i = n + 1, #self.pins do self.pins[i]:Hide() end
  self.shown, self.shownMap = n, display
  self:PlaceWorld()
  if self.button and self.button.panel:IsShown() then self.button.panel:Sync() end
end

-- Isaretleri tuvale gore boyutlar ve konumlar (noktalar harita kesri: yakinlastirma listeyi degistirmez).
-- Yakinlastirma animasyonu her karede OnCanvasScaleChanged gonderir: o zaman yalniz bu calisir.
function MM:PlaceWorld()
  local w, h = self.canvas:GetWidth(), self.canvas:GetHeight()
  if not (w and h and w > 0 and h > 0) then return end
  -- tuval olcegi: isaret ekranda hep ayni boyda
  local scale = 1
  if self.canvas.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
    local c, u = self.canvas:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if c and u and c > 0 then scale = c / u end
  end
  for i = 1, self.shown or 0 do
    local pin = self.pins[i]
    local ps = (pin.activeScale or 1) / scale
    pin:SetScale(ps)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", self.holder, "TOPLEFT", pin.px * w / ps, -pin.py * h / ps)
  end
end

function MM:OnCanvasScale()
  local frame = WorldMapFrame
  local display = frame and frame.GetMapID and frame:GetMapID()
  if self.shownMap and display == self.shownMap and self.holder and self.holder:IsShown() then self:PlaceWorld()
  else self:RefreshWorld() end
end

-- ===== Minimap: yakindaki noktalar (minimap yaricapi icinde) =====
function MM:EnsureMini()
  if self.miniHolder then return true end
  if not Minimap then return false end
  local holder = CreateFrame("Frame", "ArcanisMinimapMarkers", Minimap)
  holder:SetAllPoints(Minimap)
  if holder.SetFrameLevel and Minimap.GetFrameLevel then holder:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 4) end
  self.miniHolder, self.miniPins = holder, {}
  return true
end

function MM:HideMini()
  for _, p in ipairs(self.miniPins or {}) do p:Hide() end
  self.miniShown = 0
end

-- Yakindaki adaylar (minimap yaricapinin 1,5 kati) MINI_UPDATE'te bir; ikonlar her karede oyuncunun anlik konumu ve
-- yonuyle yerlesir (minimap kayarken ikonlar onunla birlikte akar, sicramaz).
function MM:RefreshMini()
  if not self:EnsureMini() then return end
  if not self:IsEnabled() then self:HideMini() return end
  local radiusYards = P.MinimapInfo()
  local pc, px, py = P.PlayerWorldPos()
  if not (radiusYards and pc) then self:HideMini(); self.miniCand = nil return end
  local reach = radiusYards * 1.5
  local cand = {}
  for _, p in ipairs(self:MiniBuckets()[pc] or {}) do
    if math.abs(p.wx - px) <= reach and math.abs(p.wy - py) <= reach then cand[#cand + 1] = p end
  end
  self.miniCand = cand
  self:PlaceMini()
end

function MM:PlaceMini()
  local cand = self.miniCand
  if not (cand and self.miniHolder) then return end
  if #cand == 0 and (self.miniShown or 0) == 0 then return end   -- yakinda isaret yok: kare basina is yapma
  local radiusYards, rotate = P.MinimapInfo()
  local pc, px, py = P.PlayerWorldPos()
  if not (radiusYards and pc) then self:HideMini() return end
  local radiusPx = ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2
  local facing = P.Facing()
  local level, n = P.PlayerLevel(), 0
  for _, p in ipairs(cand) do
    -- dunya ekseni: x kuzey, y bati -> dogu = -(dy), guney = -(dx)
    local east, south = -(p.wy - py), -(p.wx - px)
    local x, y, inside = M.MinimapOffset(east, south, facing, rotate, radiusYards, radiusPx)
    if inside then
      n = n + 1
      local pin = self.miniPins[n]
      if not pin then pin = newPin(self.miniHolder, MINI_PIN); self.miniPins[n] = pin end
      if pin.pt == nil or pin.pt.list[1] ~= p then paintPin(pin, { cat = p.cat, list = { p } }, level) end
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", self.miniHolder, "CENTER", x, y)
      pin:Show()
    end
  end
  for i = n + 1, #self.miniPins do self.miniPins[i]:Hide() end
  self.miniShown = n
end

-- ===== Dunya haritasi dugmesi ve kutucuklu panel =====
local ROW, PANEL_W = 26, 250
function MM:BuildPanel(parent)
  local Skin, C = ns.Skin, ns.Skin.Colors
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetFrameStrata("DIALOG")
  Skin:ApplyBackdrop(f, C.bg, C.border)
  Skin:RegisterRoot(f)
  f:EnableMouse(true)
  local function text(size, color, justify)
    local fs = f:CreateFontString(nil, "OVERLAY")
    Skin:SetFont(fs, size, "")
    fs:SetTextColor(unpack(color))
    fs:SetJustifyH(justify or "LEFT")
    return fs
  end
  f.title = text(12, C.text)
  f.title:SetPoint("TOPLEFT", 12, -10)
  f.title:SetText(L["Map markers"])
  -- sutun basliklari: kutucuklarin ortasinda (sag kenar -12, kutular arasi 16)
  local colMini, colWorld = -12, -12 - 18 - 16
  f.hMini = text(9, C.textDim, "CENTER")
  f.hMini:SetPoint("TOP", f, "TOPRIGHT", colMini - 9, -30)
  f.hMini:SetText(L["Minimap"])
  f.hWorld = text(9, C.textDim, "CENTER")
  f.hWorld:SetPoint("TOP", f, "TOPRIGHT", colWorld - 9, -30)
  f.hWorld:SetText(L["Map"])
  f.rows = {}
  local y = -44
  local hunter = (P.PlayerInfo() or {}).class == "HUNTER"
  for _, cat in ipairs(self.CATEGORIES) do
   if cat ~= "pets" or hunter then   -- hunter petleri satiri yalniz hunter'da
    local row = { cat = cat }
    row.label = text(11, C.text)
    row.label:SetPoint("LEFT", f, "TOPLEFT", 12, y - ROW / 2)
    row.label:SetText(self:CategoryName(cat))
    row.world = Skin:CreateCheckbox(f, "", self:Shown("world", cat), function(v) MM:SetShown("world", cat, v) end)
    row.world:SetPoint("RIGHT", f, "TOPRIGHT", colWorld, y - ROW / 2)
    row.mini = Skin:CreateCheckbox(f, "", self:Shown("mini", cat), function(v) MM:SetShown("mini", cat, v) end)
    row.mini:SetPoint("RIGHT", f, "TOPRIGHT", colMini, y - ROW / 2)
    f.rows[#f.rows + 1] = row
    y = y - ROW
   end
  end
  y = y - 4
  f.myProfs = Skin:CreateCheckbox(f, L["Only my professions"], self.db.myProfs, function(v)
    MM.db.myProfs = v; MM:Invalidate(); MM:RefreshAll()
  end)
  f.myProfs:SetPoint("LEFT", f, "TOPLEFT", 12, y - ROW / 2)
  y = y - ROW
  f.zoneLevel = Skin:CreateCheckbox(f, L["Zone level range"], self.db.zoneLevel, function(v) MM.db.zoneLevel = v; MM:RefreshWorld() end)
  f.zoneLevel:SetPoint("LEFT", f, "TOPLEFT", 12, y - ROW / 2)
  y = y - ROW
  -- yalniz hunter: pet ipucunda ayrinti
  f.petDetails = Skin:CreateCheckbox(f, L["Pet details in the tooltip"], self.db.petDetails, function(v) MM.db.petDetails = v end)
  f.petDetails:SetPoint("LEFT", f, "TOPLEFT", 12, y - ROW / 2)
  local player = P.PlayerInfo()
  if player and player.class == "HUNTER" then y = y - ROW else f.petDetails:Hide() end
  y = y - 4
  -- gosterilen bolgenin rare'leri: kac tanesi goruldu; ustune gelince gorulmeyenlerin adlari
  f.rareLine = CreateFrame("Button", nil, f)
  f.rareLine:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
  f.rareLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, y)
  f.rareLine:SetHeight(18)
  f.rareLine.text = f.rareLine:CreateFontString(nil, "OVERLAY")
  Skin:SetFont(f.rareLine.text, 10, "")
  f.rareLine.text:SetTextColor(unpack(C.textDim))
  f.rareLine.text:SetAllPoints()
  f.rareLine.text:SetJustifyH("LEFT")
  f.rareLine:SetScript("OnEnter", function(b)
    if not (GameTooltip and b.unseen and #b.unseen > 0) then return end
    GameTooltip:SetOwner(b, "ANCHOR_LEFT")
    GameTooltip:SetText(L["Not seen yet"])
    for _, n in ipairs(b.unseen) do GameTooltip:AddLine(n, 1, 1, 1) end
    GameTooltip:Show()
  end)
  f.rareLine:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  y = y - 18 - 8
  f:SetSize(PANEL_W, -y)
  f:Hide()
  function f:Sync()
    for _, r in ipairs(self.rows) do
      r.world:SetChecked(MM:Shown("world", r.cat), true)
      r.mini:SetChecked(MM:Shown("mini", r.cat), true)
    end
    self.myProfs:SetChecked(MM.db.myProfs, true)
    self.zoneLevel:SetChecked(MM.db.zoneLevel, true)
    self.petDetails:SetChecked(MM.db.petDetails, true)
    local R = ns.RareSpawns
    local zone = R and WorldMapFrame and WorldMapFrame.GetMapID and R:ZoneName(WorldMapFrame:GetMapID())
    local seen, unseen = {}, {}
    if zone then seen, unseen = R:ZoneStatus(zone) end
    self.rareLine.unseen = unseen
    if #seen + #unseen > 0 then
      self.rareLine.text:SetText(L["Rares here: %d of %d seen"]:format(#seen, #seen + #unseen))
    else
      self.rareLine.text:SetText(L["No known rares on this map."])
    end
  end
  return f
end

function MM:EnsureButton()
  if self.button then return true end
  local frame = WorldMapFrame
  local parent = frame and (frame.ScrollContainer or frame)
  if not parent then return false end
  local Skin = ns.Skin
  local b = Skin:CreateIconButton(parent, "logo", 30)
  b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
  if b.SetFrameLevel and parent.GetFrameLevel then b:SetFrameLevel((parent:GetFrameLevel() or 1) + 50) end
  b.disc = b:CreateTexture(nil, "BACKGROUND", nil, -1)
  b.disc:SetAllPoints()
  b.disc:SetTexture(Skin.Icons.disc)
  b.disc:SetVertexColor(0.05, 0.05, 0.07, 0.85)
  b:HookScript("OnEnter", function(btn)
    if GameTooltip then GameTooltip:SetOwner(btn, "ANCHOR_LEFT"); GameTooltip:SetText(L["Map markers"]); GameTooltip:Show() end
  end)
  b:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  b.panel = self:BuildPanel(parent)
  b.panel:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, -4)
  b:SetScript("OnClick", function() MM:TogglePanel() end)
  self.button = b
  return true
end

function MM:TogglePanel(show)
  if not self:EnsureButton() then return end
  local p = self.button.panel
  if show == nil then show = not p:IsShown() end
  if show then p:Sync(); p:Show() else p:Hide() end
end

function MM:UpdateButton()
  if not self:EnsureButton() then return end
  local on = self:IsEnabled() and self.db.button
  if on then self.button:Show() else self.button:Hide(); self.button.panel:Hide() end
end

-- Ayar degisikligi (panel, Ayarlar, /wf markers)
function MM:SetShown(which, cat, value)
  self.db[which][cat] = value and true or false
  self:RefreshAll()
end

function MM:RefreshAll()
  self:RefreshWorld()
  self:RefreshMini()
  if self.button and self.button.panel:IsShown() then self.button.panel:Sync() end
end

-- ===== Yasam dongusu =====
function MM:Hook()
  if self.hooked or not WorldMapFrame then return end
  self.hooked = true
  if WorldMapFrame.HookScript then
    WorldMapFrame:HookScript("OnShow", function() MM:RefreshWorld() end)
    WorldMapFrame:HookScript("OnHide", function() if MM.button then MM.button.panel:Hide() end end)
  end
  if hooksecurefunc and WorldMapFrame.OnMapChanged then
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function() MM:RefreshWorld() end)
  end
  if hooksecurefunc and WorldMapFrame.OnCanvasScaleChanged then
    hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", function() MM:OnCanvasScale() end)
  end
end

-- Goc (1): eski varsayilanlar her seyi aciyordu; yeni varsayilan yalniz zindan + ucus (hunter petleri sinifa gore)
function MM:MigrateDefaults()
  if (self.db.defV or 0) >= 1 then return end
  self.db.defV = 1
  for _, which in ipairs({ "world", "mini" }) do
    local t = self.db[which]
    t.dungeons, t.flights = true, true
    t.classTrainers, t.profTrainers, t.rares, t.pets = false, false, false, nil
  end
end

function MM:OnInitialize()
  self:MigrateDefaults()
  self.driver = CreateFrame("Frame")
  self.acc = 0
end

function MM:OnEnable()
  self:Hook()
  ns:On("ADDON_LOADED", self, function(_, _, name)
    if name == "Blizzard_WorldMap" then MM:Hook(); MM:RefreshWorld() end
  end)
  ns:On("PLAYER_LEVEL_UP", self, function() MM:Invalidate(); MM:RefreshAll() end)
  ns:On("SKILL_LINES_CHANGED", self, function() if MM.db.myProfs then MM:Invalidate(); MM:RefreshAll() end end)
  for _, ev in ipairs({ "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED" }) do
    ns:On(ev, self, function() MM.questDirty = true end)
  end
  self:HookTooltip()
  -- ok baska yere donunce (sag tik, varis, rehber) parlayan isaret soner
  ns:Listen("ARCANIS_TARGET_CHANGED", self, function()
    if MM.active and not MM:ActiveTarget() then MM.active = nil; MM:RefreshWorld() end
  end)
  self.driver:SetScript("OnUpdate", function(_, elapsed)
    MM.acc = MM.acc + elapsed
    MM.moveAcc = (MM.moveAcc or 0) + elapsed
    if MM.acc >= MINI_UPDATE then MM.acc, MM.moveAcc = 0, 0; MM:QuestTick(); MM:RefreshMini()
    elseif MM.moveAcc >= MINI_MOVE then MM.moveAcc = 0; MM:PlaceMini() end
  end)
  self:Invalidate()
  self:RefreshAll()
end

function MM:OnDisable()
  self.driver:SetScript("OnUpdate", nil)
  self:HideWorld()
  self:HideMini()
  if self.button then self.button:Hide(); self.button.panel:Hide() end
end

-- /wf markers [world|mini] <kategori> [on|off]   (kategori yoksa paneli acar)
ns:RegisterCommand("markers", function(args)
  local a, b, c = (args or ""):lower():match("^(%S*)%s*(%S*)%s*(%S*)")
  local which = (a == "mini" or a == "minimap") and "mini" or (a == "world" or a == "map") and "world" or nil
  local catArg = which and b or a
  local state = which and c or b
  local cat
  for _, k in ipairs(MM.CATEGORIES) do if k:lower() == catArg then cat = k end end
  if not cat then
    for _, k in ipairs(MM.CATEGORIES) do
      ns:Print(("%s: %s %s, %s %s"):format(MM:CategoryName(k), L["Map"], MM:Shown("world", k) and "on" or "off",
        L["Minimap"], MM:Shown("mini", k) and "on" or "off"))
    end
    return
  end
  for _, w in ipairs(which and { which } or { "world", "mini" }) do
    local v = (state == "on") or (state ~= "off" and not MM:Shown(w, cat))
    MM:SetShown(w, cat, v)
  end
end)
