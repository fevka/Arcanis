-- Arcanis: rehber semasi (dogrulama + normallestirme). WoW API'sine bagimli degil.
--
--   local errors, warnings = ns.GuideSchema.Validate(def)
--   local guide            = ns.GuideSchema.Normalize(def)   -- yalnizca gecerli rehberde
--
-- Koordinatlar rehber dosyasinda 0-100 (yuzde) yazilir; Normalize bunlari 0-1'e cevirir.
-- Not: "goto" Lua 5.2+ icin ayrilmis kelimedir; adim turu daima ["goto"] seklinde indekslenir.
local _, ns = ...

local Schema = {}
ns.GuideSchema = Schema

local floor = math.floor

local function isInt(v) return type(v) == "number" and v == floor(v) end

local KIND = {
  string  = function(v) return type(v) == "string" and v ~= "" end,
  text    = function(v)
    if type(v) == "string" then return v ~= "" end
    if type(v) ~= "table" or next(v) == nil then return false end
    for code, s in pairs(v) do
      if type(code) ~= "string" or type(s) ~= "string" or s == "" then return false end
    end
    return true
  end,
  boolean = function(v) return type(v) == "boolean" end,
  id      = function(v) return isInt(v) and v > 0 end,
  count   = function(v) return isInt(v) and v > 0 end,
  radius  = function(v) return type(v) == "number" and v > 0 end,
  coord   = function(v) return type(v) == "number" and v >= 0 and v <= 100 end,
  path    = function(v)
    if type(v) ~= "table" or #v == 0 then return false end
    for _, p in ipairs(v) do
      if type(p) ~= "table" or type(p[1]) ~= "number" or type(p[2]) ~= "number"
         or p[1] < 0 or p[1] > 100 or p[2] < 0 or p[2] > 100 then return false end
    end
    return true
  end,
  level   = function(v) return isInt(v) and v >= 1 and v <= 80 end,
  idlist  = function(v)
    if type(v) ~= "table" or #v == 0 then return false end
    for _, x in ipairs(v) do if not (isInt(x) and x > 0) then return false end end
    return true
  end,
  stringlist = function(v)
    if type(v) ~= "table" or #v == 0 then return false end
    for _, item in ipairs(v) do
      if type(item) ~= "string" or item == "" then return false end
    end
    return true
  end,
}

local KIND_HINT = {
  string  = "non-empty string",
  text    = "non-empty string, or a table of strings keyed by locale code (e.g. { enUS = \"...\", trTR = \"...\" })",
  boolean = "true/false",
  id      = "positive integer",
  count   = "positive integer",
  radius  = "positive number",
  coord   = "number between 0 and 100",
  path    = "non-empty list of { x, y } points (0-100)",
  level   = "integer between 1 and 80",
  idlist  = "non-empty list of quest ids",
  stringlist = "non-empty list of strings",
}

-- classes/races: adim yalnizca bu siniflara/irklara gosterilir (sinif kodu / Ingilizce irk kodu).
local COMMON_FIELDS = {
  type = "string", text = "text", tip = "text", optional = "boolean",
  cave = "boolean",   -- adim bir magaranin icinde/girisinde (rotadan yapisal isaret; pencere kendi notunu yazar)
  sticky = "boolean",  -- "yolda yap" hedefi: su anki adim olmaz, asil adimina kadar yan gorev olarak gosterilir
  verify = "boolean",  -- quest Forever verisinde yok: oyunda dogrulanmali (tools/convert_forever_route.py isaretler)
  classes = "stringlist", races = "stringlist",
  -- oyuncu bu seviyenin ustundeyse adim gosterilmez (rota kaynagi adimi orada gizler; quest gunlukteyse kalir)
  maxLevel = "level",
  -- yalniz zindana girene: quest zindanin icinde yapilir (Data/Dungeons kimligi; rota kaynaginda zindan secenegi)
  dungeonOnly = "string",
  -- rota kaynaginin adim kosullari (19 Kasim 2026): grup gorevi, en dusuk seviye ve gorev durumuna bagli gosterim
  groupOnly = "boolean",   -- grup icerigi: Guide behaviour > "Group quests" acik degilse gosterilmez
  minLevel = "level",      -- oyuncu bu seviyenin altindaysa gosterilmez
  ifDone = "idlist",       -- biri teslim edildiyse gosterilir
  ifNotDone = "idlist",    -- biri henuz teslim edilmediyse gosterilir
  ifLog = "idlist",        -- biri gunlukteyse gosterilir
  ifComplete = "idlist",   -- biri gunlukte ve bitmisse gosterilir
  unlocks = "id",     -- zindan gorev rehberi: bu adimin gorevi hangi zindan gorevini acar (Guide/DungeonGuides.lua)
  info = "text",      -- gorevin kisa aciklamasi (adim penceresinde gorev kutusunda)
}
local LOC_FIELDS = { map = "id", zone = "string", x = "coord", y = "coord", radius = "radius", path = "path" }

-- loc=true: adim konum alanlarini (map, x, y, radius) kabul eder.
-- required: zorunlu alanlar; anyOf: bunlardan en az biri zorunlu.
local STEP_SPECS = {
  ["goto"] = { loc = true, required = { "x", "y" }, anyOf = { "map", "zone" }, fields = { npc = "string" } },   -- npc: hedefteki vendor (ok "Talk to X" der)
  accept   = { loc = true, required = { "quest" }, fields = { quest = "id", name = "string", npc = "string" } },
  turnin   = { loc = true, required = { "quest" }, fields = { quest = "id", name = "string", npc = "string" } },
  complete = { loc = true, required = { "quest" }, fields = { quest = "id", name = "string", objective = "id" } },
  kill     = { loc = true, anyOf = { "npc", "npcId" },
               fields = { npc = "string", npcId = "id", count = "count", quest = "id", objective = "id" } },
  collect  = { loc = true, required = { "item" },
               fields = { item = "id", count = "count", quest = "id", objective = "id" } },
  talk     = { loc = true, required = { "npc" }, fields = { npc = "string", trainer = "boolean" } },   -- trainer: pencere acilinca biter
  use      = { loc = true, required = { "item" }, fields = { item = "id", quest = "id", objective = "id" } },
  fly      = { loc = true, required = { "to" }, fields = { to = "string", npc = "string" } },
  hearth   = { loc = false, required = { "to" }, fields = { to = "string" } },
  level    = { loc = false, required = { "level" }, fields = { level = "level" } },
  note     = { loc = false, required = { "text" }, fields = {} },
  -- meslek adimi (Guide/ProfGuides.lua): act = train (rutbe, max) | learn (tarif, spell) | craft / gather (beceri
  -- skill'e kadar) | buy / collect (esya, adet; skill'e gelince gereksiz). after: bu becerinin ustu tarifi bilir sayilir.
  prof     = { loc = true, required = { "act", "prof" },
               fields = { act = "string", prof = "string", skill = "count", max = "count", after = "count",
                          count = "count", name = "string", item = "id", spell = "id", npc = "string" } },
}
Schema.StepSpecs = STEP_SPECS

local GUIDE_FIELDS = {
  id = "string", title = "text", description = "text", faction = "string",
  minLevel = "level", maxLevel = "level", next = "string",
  special = "boolean",   -- ozel gorev serisi: seviye onerisine ve zincire girmez (Guide Browser > Special)
  profession = "string", -- meslek rehberi (special ile birlikte; Guide Browser > Professions)
  dungeon = "string",    -- zindan gorev rehberi (special ile birlikte; Guide/DungeonGuides.lua, zindan gunlugunden)
  races = true, classes = true, steps = true,
  -- sinifa / irka bagli devam: { { classes = {...}, races = {...}, id = "rehber" }, ... }; oyuncuya uyan ilk satir,
  -- yoksa `next` (Guides:GetNext). Orc/Troll: Durotar -> Tirisfal (hunter ve shaman The Barrens'a).
  nextBy = true,
}

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

local function validateStep(step, label, errors, warnings)
  if type(step) ~= "table" then
    errors[#errors + 1] = label .. ": step must be a table"
    return
  end
  if type(step.type) ~= "string" then
    errors[#errors + 1] = label .. ": missing 'type'"
    return
  end
  local spec = STEP_SPECS[step.type]
  if not spec then
    errors[#errors + 1] = label .. ": unknown step type '" .. step.type .. "'"
    return
  end

  local allowed = {}
  for k, kind in pairs(COMMON_FIELDS) do allowed[k] = kind end
  for k, kind in pairs(spec.fields) do allowed[k] = kind end
  if spec.loc then
    for k, kind in pairs(LOC_FIELDS) do allowed[k] = kind end
  end

  for _, k in ipairs(sortedKeys(step)) do
    local kind = allowed[k]
    if not kind then
      warnings[#warnings + 1] = label .. ": unknown field '" .. tostring(k) .. "' (possible typo)"
    elseif not KIND[kind](step[k]) then
      errors[#errors + 1] = label .. ": '" .. tostring(k) .. "' is invalid (expected: " .. KIND_HINT[kind] .. ")"
    end
  end

  if spec.required then
    for _, k in ipairs(spec.required) do
      if step[k] == nil then
        errors[#errors + 1] = label .. ": missing '" .. k .. "'"
      end
    end
  end

  if spec.anyOf then
    local found = false
    for _, k in ipairs(spec.anyOf) do
      if step[k] ~= nil then found = true end
    end
    if not found then
      errors[#errors + 1] = label .. ": '" .. table.concat(spec.anyOf, "' or '") .. "' required"
    end
  end

  -- Konum verilecekse tam verilmeli (goto icin zaten zorunlu).
  if spec.loc then
    local present = 0
    if step.map ~= nil or step.zone ~= nil then present = present + 1 end
    if step.x ~= nil then present = present + 1 end
    if step.y ~= nil then present = present + 1 end
    if present > 0 and present < 3 then
      errors[#errors + 1] = label .. ": 'map' (or 'zone'), 'x' and 'y' must be given together"
    end
  end
end

local function validateStringList(list, name, errors)
  if list == nil then return end
  if type(list) ~= "table" or #list == 0 then
    errors[#errors + 1] = "'" .. name .. "' must be a non-empty list of strings"
    return
  end
  for i, v in ipairs(list) do
    if type(v) ~= "string" or v == "" then
      errors[#errors + 1] = "'" .. name .. "'[" .. i .. "] is invalid"
    end
  end
end

function Schema.Validate(def)
  local errors, warnings = {}, {}
  if type(def) ~= "table" then
    errors[1] = "guide must be a table"
    return errors, warnings
  end

  for _, k in ipairs(sortedKeys(def)) do
    local kind = GUIDE_FIELDS[k]
    if not kind then
      warnings[#warnings + 1] = "unknown guide field '" .. tostring(k) .. "'"
    elseif type(kind) == "string" and not KIND[kind](def[k]) then
      errors[#errors + 1] = "'" .. tostring(k) .. "' is invalid (expected: " .. KIND_HINT[kind] .. ")"
    end
  end

  for _, k in ipairs({ "id", "title", "minLevel", "maxLevel" }) do
    if def[k] == nil then errors[#errors + 1] = "missing '" .. k .. "'" end
  end

  if def.faction ~= nil and def.faction ~= "Alliance" and def.faction ~= "Horde" then
    errors[#errors + 1] = "'faction' must be 'Alliance' or 'Horde'"
  end

  if KIND.level(def.minLevel) and KIND.level(def.maxLevel) and def.minLevel > def.maxLevel then
    errors[#errors + 1] = "'minLevel' cannot exceed 'maxLevel'"
  end

  validateStringList(def.races, "races", errors)
  validateStringList(def.classes, "classes", errors)
  if def.nextBy ~= nil then
    if type(def.nextBy) ~= "table" or #def.nextBy == 0 then
      errors[#errors + 1] = "'nextBy' must be a non-empty list"
    else
      for i, b in ipairs(def.nextBy) do
        if type(b) ~= "table" or type(b.id) ~= "string" or b.id == "" or (b.classes == nil and b.races == nil) then
          errors[#errors + 1] = "'nextBy'[" .. i .. "] needs 'id' and 'classes' or 'races'"
        else
          validateStringList(b.classes, "nextBy[" .. i .. "].classes", errors)
          validateStringList(b.races, "nextBy[" .. i .. "].races", errors)
        end
      end
    end
  end

  local steps = def.steps
  if type(steps) ~= "table" or #steps == 0 then
    errors[#errors + 1] = "'steps' must be a non-empty list of steps"
    return errors, warnings
  end
  local count = 0
  for _ in pairs(steps) do count = count + 1 end
  if count ~= #steps then
    errors[#errors + 1] = "'steps' must be a gap-free array (1..n)"
    return errors, warnings
  end

  for i, step in ipairs(steps) do
    local kind = type(step) == "table" and step.type or "?"
    validateStep(step, "adim " .. i .. " (" .. tostring(kind) .. ")", errors, warnings)
  end

  return errors, warnings
end

local function toSet(list, transform)
  if not list then return nil end
  local set = {}
  for _, v in ipairs(list) do set[transform(v)] = true end
  return set
end

-- Gecerli bir rehberin kopyasini dondurur: koordinatlar 0-1, adimlar numaralanmis,
-- races/classes kume haline getirilmis. Giris tablosuna dokunulmaz.
function Schema.Normalize(def)
  local guide = {
    id = def.id,
    title = def.title,
    description = def.description,
    faction = def.faction,
    minLevel = def.minLevel,
    maxLevel = def.maxLevel,
    next = def.next,
    special = def.special,
    profession = def.profession,
    dungeon = def.dungeon,
    races = toSet(def.races, string.lower),
    classes = toSet(def.classes, string.upper),
    steps = {},
  }
  if def.nextBy then
    guide.nextBy = {}
    for i, b in ipairs(def.nextBy) do
      guide.nextBy[i] = { id = b.id, classes = toSet(b.classes, string.upper), races = toSet(b.races, string.lower) }
    end
  end
  for i, src in ipairs(def.steps) do
    local step = {}
    for k, v in pairs(src) do step[k] = v end
    if step.x ~= nil then
      step.x = step.x / 100
      step.y = step.y / 100
    end
    if step.path then
      local path = {}
      for j, pt in ipairs(step.path) do path[j] = { pt[1] / 100, pt[2] / 100 } end
      step.path = path
    end
    step.classes = toSet(src.classes, string.upper)
    step.races = toSet(src.races, string.lower)
    step.index = i
    step.guide = def.id
    guide.steps[i] = step
  end
  return guide
end
