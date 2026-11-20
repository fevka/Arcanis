-- Arcanis: hunter icin "bu hayvan petinden yuksek rutbe ogretiyor" uyarisi (Mentor'un parcasi, ayar Mentor.db.petTeach).
-- Hedef / fare / isim levhasindaki hayvan Data/HunterPets.lua'da `teaches` tasiyorsa ve cagrilmis petin o
-- yetenegi daha dusuk rutbede biliyorsa (ya da hic bilmiyor ama ailesi ogrenebiliyorsa) bir kez haber verilir.
-- Pet cagrili degilse karsilastirma yapilmaz (rutbeleri okunamaz).
local _, ns = ...

local P = ns.Provider
local L = ns.L
local Mentor = ns.Mentor

local byId   -- NPC kimligi -> HunterPetData satiri
local function teacher(id)
  if not byId then
    byId = {}
    for _, p in ipairs(ns.HunterPetData or {}) do if p.teaches then byId[p.id] = p end end
  end
  return byId[id]
end

local function familyLearns(family, ability)
  local f = family and ns.HunterPetFamilies and ns.HunterPetFamilies[family]
  for _, a in ipairs(f and f.learns or {}) do if a == ability then return true end end
  return false
end

-- Bu hayvan petine ne ogretir: { { ability, rank, petRank } } (bos = yeni bir sey yok). known: petin rutbeleri,
-- family: petin ailesi (yalniz petin hic bilmedigi yetenek icin bakilir).
function Mentor:PetTeaches(npcId, known, family)
  local p = teacher(npcId)
  local out = {}
  if not p then return out, nil end
  for _, t in ipairs(p.teaches) do
    local ability, rank = t[1], t[2]
    local have = known[ability]
    if (have and have < rank) or (not have and familyLearns(family, ability)) then
      out[#out + 1] = { ability = ability, rank = rank, petRank = have or 0 }
    end
  end
  return out, p
end

-- Birime bak (hedef, fare, levha). Hayvan basina oturumda bir kez. Dondurur: bildirildiyse true.
function Mentor:CheckPetTeacher(unit)
  if not (self.db.petTeach and self.db.popups) or (P.PlayerInfo() or {}).class ~= "HUNTER" then return false end
  local id = P.UnitNpcId(unit)
  if not id or not teacher(id) then return false end
  self.teachAlerted = self.teachAlerted or {}
  if self.teachAlerted[id] or not P.PetName() then return false end
  local list, p = self:PetTeaches(id, P.PetSpellRanks(), P.PetFamily())
  if #list == 0 then return false end
  self.teachAlerted[id] = true
  local parts = {}
  for _, t in ipairs(list) do
    parts[#parts + 1] = t.petRank > 0 and L["%s %d (your pet: %d)"]:format(t.ability, t.rank, t.petRank)
      or L["%s %d (your pet: none)"]:format(t.ability, t.rank)
  end
  local text = L["%s teaches %s"]:format(p.name, table.concat(parts, ", "))
  if ns.Toast then ns.Toast:Show(L["Mentor: %s"]:format(text), "info", nil, nil, { cat = "mentor" }) end
  ns:Print("|cffdb9e33" .. L["Mentor"] .. ":|r " .. text .. " - " .. L["Tame it and fight until you learn the rank, then teach it to your pet with Beast Training."])
  return true
end

local function check(unit)
  if Mentor:IsEnabled() and unit then Mentor:CheckPetTeacher(unit) end
end
ns:On("PLAYER_TARGET_CHANGED", "PetTeach", function() check("target") end)
ns:On("UPDATE_MOUSEOVER_UNIT", "PetTeach", function() check("mouseover") end)
ns:On("NAME_PLATE_UNIT_ADDED", "PetTeach", function(_, _, unit) check(unit) end)
