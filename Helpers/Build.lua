-- Arcanis: sinif build'leri (modul "Build"). Seviye atlayinca siradaki yetenegi onerir, /wf build build'i gosterir.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Build = ns:NewModule("Build", { defaults = { tips = true }, charDefaults = { pick = 1 } })
ns.Build = Build

local CATEGORY = "Leveling"

-- Sinif build listesi (yoksa bos liste). Kategoriler: "Leveling", "PVE", "PVP". Once Data/Codex.
function Build:ListFor(category)
  local C = ns.Codex
  if C and C:IsEnabled() then
    local list = C:Get(P.PlayerClassToken(), category)
    if #list > 0 then return list end
  end
  local oracle = _G.ArcanisOracle
  if not (oracle and oracle.GetBuilds) then return {} end
  local ok, list = pcall(oracle.GetBuilds, oracle, P.PlayerClassToken(), category)
  return (ok and type(list) == "table") and list or {}
end

function Build:List() return self:ListFor(CATEGORY) end

function Build:Available()
  for _, cat in ipairs({ "Leveling", "PVE", "PVP" }) do
    if #self:ListFor(cat) > 0 then return true end
  end
  return false
end

-- Build'in yetenekleri ve hedef rutbeleri: { {name, want} } ilk gorulme sirasiyla. PERPOINT build'de (Forever
-- leveling siralari) ad her puan icin tekrar eder, hedef = tekrar sayisi; eski build'lerde her ad bir kez, hedef tavan.
local function targets(build)
  local out, at = {}, {}
  for _, name in ipairs(build and build.TALENTS or {}) do
    local k = name:lower()
    if at[k] then out[at[k]].want = out[at[k]].want + 1
    else out[#out + 1] = { name = name, want = 1 }; at[k] = #out end
  end
  return out
end

-- Yetenek adi (kucuk harf) -> { name, icon, rank, max } ya da nil. Forever'da Classic'in GetTalentInfo'su yok:
-- yetenekler RotationForge'un C_Traits okumasindan (ns.RF; rank onaylanmamis puanlari da sayar). RF yoksa ya da
-- agac okunmadiysa eski Classic listesi. have verilirse (test) o liste.
local function talentLookup(have)
  local RF = ns.RF
  if not have and RF and RF.Talent and RF.TalentCount and RF.TalentCount() > 0 then
    return function(key)
      local r = RF.Talent(key)
      if not r then return nil end
      return { name = r.name, rank = RF.TalentLiveRank and RF.TalentLiveRank(key) or r.rank or 0, max = r.max or 1,
               icon = P.SpellIcon(r.name) }
    end
  end
  have = have or P.TalentList()
  if not have then return nil end
  local byName = {}
  for _, t in ipairs(have) do byName[t.name:lower()] = t end
  return function(key) return byName[key] end
end

-- Yetenek sirasinin durumu: { {name, icon, rank, max, state = "done"|"partial"|"next"|"todo"|"unknown"} }
function Build:Order(build)
  local look = talentLookup() or function() return nil end
  local byName = setmetatable({}, { __index = function(_, k) return look(k) end })
  local nxt = self:NextTalent(build)
  local out = {}
  for _, e0 in ipairs(targets(build)) do
    local t = byName[e0.name:lower()]
    local want = (build.PERPOINT and t) and math.min(e0.want, t.max) or (t and t.max) or 0
    local e = { name = e0.name, icon = t and t.icon, rank = t and t.rank or 0, max = build.PERPOINT and want or (t and t.max or 0) }
    if not t then e.state = "unknown"
    elseif t.rank >= want then e.state = "done"
    elseif e0.name == nxt then e.state = "next"
    elseif t.rank > 0 then e.state = "partial"
    else e.state = "todo" end
    out[#out + 1] = e
  end
  return out
end

function Build:Current()
  local list = self:List()
  if #list == 0 then return nil end
  local i = math.max(1, math.min(self.char.pick or 1, #list))
  return list[i], i, #list
end

-- Build sirasina gore ogrenilmemis ilk yetenek (isim eslesmesi). nil = oneri yok.
function Build:NextTalent(build, have)
  build = build or self:Current()
  if not (build and build.TALENTS) then return nil end
  local look = talentLookup(have)
  if not look then return nil end
  local count = {}
  for _, name in ipairs(build.TALENTS) do
    local t = look(name:lower())
    local k = name:lower()
    count[k] = (count[k] or 0) + 1
    -- puan puan sirada bu satir ad'in count'uncu puani: rutbe ona ulasmadiysa siradaki puan bu
    local want = build.PERPOINT and count[k] or (t and t.max)
    if t and t.rank < math.min(want, t.max) then return name end
  end
  return nil
end

function Build:OnLevelUp()
  if not self.db.tips or not ns.Toast or P.UnspentTalents() <= 0 then return end
  local RF = ns.RF
  -- rotasyon yardimcisinin talent rehberi aciksa siradaki talent'i o soyluyor (modul kapaliysa soylemez)
  if RF and not RF.stopped and RF.db and RF.db.talentGuide then return end
  local name = self:NextTalent()
  if name then ns.Toast:Show(L["Talent point: %s"]:format(name), "info", nil, nil, { prio = "low", cat = "level" }) end
end

-- Yetenek penceresindeki isaret ve siradaki talent satiri RotationForge'un talent rehberinden gelir (Rotation/).

function Build:OnEnable()
  ns:On("PLAYER_LEVEL_UP", self, function(owner) ns.SafeCall(owner.OnLevelUp, owner) end)
end

local function lines(text, max)
  local out = {}
  for raw in (text or ""):gmatch("[^\r\n]+") do
    local line = raw:gsub("^%s+", "")
    if line ~= "" then out[#out + 1] = line end
    if #out >= max then break end
  end
  return out
end

ns:RegisterCommand("build", function(args)
  local list = Build:List()
  if #list == 0 then ns:Print(L["No leveling build found (ArcanisOracle not loaded?)."]) return end
  local arg = (args or ""):lower():match("^%s*(%S*)")
  local n = tonumber(arg)
  if n and list[n] then Build.char.pick = n end
  local build, idx, total = Build:Current()
  ns:Print(("%s (%d/%d)"):format(build.shortname or "?", idx, total))
  local nextTalent = Build:NextTalent(build)
  if nextTalent then ns:Print(L["Talent point: %s"]:format(nextTalent)) end
  if arg == "rot" or arg == "" or n then
    for _, l in ipairs(lines(build.ROT, 8)) do ns:Print(l) end
  end
  if total > 1 then ns:Print(L["Use /wf build <number> to switch builds."]) end
end, "Leveling build and talent suggestion (ArcanisOracle)")

-- Tani: oyundaki yetenek adlari ile Codex sirasindaki adlari karsilastirir (eslesmeyenleri yazar).
ns:RegisterCommand("talents", function()
  local RF = ns.RF
  local n = (RF and RF.TalentCount and RF.TalentCount()) or 0
  if n == 0 then
    local have = P.TalentList()
    n = have and #have or 0
  end
  if n == 0 then ns:Print(L["The game did not return any talents."]) return end
  ns:Print(L["Talents in game: %d"]:format(n))
  local build = Build:Current()
  if not build then return end
  local missing = {}
  for _, e in ipairs(Build:Order(build)) do if e.state == "unknown" then missing[#missing + 1] = e.name end end
  ns:Print(L["Not found in game: %s"]:format(#missing > 0 and table.concat(missing, ", ") or "-"))
end, "compare the codex talent order with your talents")

