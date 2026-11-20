-- Arcanis: zindanda gorev paylasimi (modul "QuestShare"). Partideyken bir zindanin icinde ya da girisinin yakininda,
-- gunlugundeki o zindanin gorevlerinden (zindan gunlugu verisi, Journal:Quests) grup uyelerinde olmayanlari adada
-- listeler; tiklayinca oyunun kendi paylasimiyla (Share Quest) hepsini paylasir. Uyelerin gorev durumu yalniz oyunun
-- verdigi kadar bilinir (C_QuestLog.IsUnitOnQuest); bilinmiyorsa paylasilabilir gorevlerin hepsi onerilir.
-- Komut: /wf share
local _, ns = ...

local P = ns.Provider
local L = ns.L

local QS = ns:NewModule("QuestShare", { defaults = { notify = true } })
ns.QuestShare = QS

local NEAR = 400   -- yard: zindan girisine bu kadar yakinsa "zindanin yaninda"

-- Paylasilacak gorevler (saf islev). quests: { {id, name}, ... }; inLog(q), pushable(q) -> bool;
-- members: { {unit, name}, ... }; onQuest(unit, q) -> true / false / nil (bilinmez).
-- Dondurur: { { id, name, lacking = { ad, ... }, unknown = bool }, ... } — gunlukte olan, paylasilabilir ve en az bir
-- uyede olmayan (ya da durumu bilinmeyen) gorevler.
function QS.Candidates(quests, inLog, pushable, members, onQuest)
  local out = {}
  if #members == 0 then return out end
  for _, q in ipairs(quests) do
    if inLog(q.id) and pushable(q.id) then
      local lacking, unknown = {}, false
      for _, m in ipairs(members) do
        local on = onQuest(m.unit, q.id)
        if on == nil then unknown = true elseif not on then lacking[#lacking + 1] = m.name end
      end
      if #lacking > 0 or unknown then out[#out + 1] = { id = q.id, name = q.name, lacking = lacking, unknown = unknown } end
    end
  end
  return out
end

local function plain(s) return (s or ""):lower():gsub("^the ", ""):gsub("[^%w]", "") end

-- Oyuncunun icinde ya da yaninda oldugu zindan (Data/Dungeons) ya da nil
function QS:Dungeon()
  local J = ns.Journal
  if not J then return nil end
  local player = P.PlayerInfo()
  local inside = P.InstanceInfo()
  for _, d in ipairs(J:List(player)) do
    if inside then
      if plain(d.name) == plain(inside) then return d end
    else
      for _, e in ipairs(J:Entrances(d)) do
        local yards = J:Distance(e)
        if yards and yards <= NEAR then return d end
      end
    end
  end
  return nil
end

function QS:List()
  local d = self:Dungeon()
  if not d then return {}, nil end
  local members = P.PartyMembers()
  if #members == 0 then return {}, d end
  local quests = ns.Journal:Quests(d, P.PlayerInfo())
  return QS.Candidates(quests, P.IsQuestInLog, P.QuestPushable, members, P.UnitOnQuest), d
end

-- Hepsini sirayla paylas (oyun ayni anda tek paylasim isler: araya kisa bekleme)
function QS:ShareAll(list)
  list = list or self:List()
  if #list == 0 then ns:Print(L["No dungeon quests to share here."]) return 0 end
  for i, q in ipairs(list) do
    local function go() P.ShareQuest(q.id) end
    if i == 1 or not P.After((i - 1) * 1.5, go) then go() end
  end
  ns:Print(L["Sharing %d dungeon quests with your group."]:format(#list))
  return #list
end

-- Adada bir kez bildir (ayni zindan + ayni liste tekrar bildirilmez)
function QS:Check()
  self.queued = false
  if not self.db.notify or P.InCombat() then return end
  local list, d = self:List()
  if #list == 0 then return end
  local ids = {}
  for _, q in ipairs(list) do ids[#ids + 1] = q.id .. ":" .. table.concat(q.lacking, ",") end
  local sig = d.id .. "|" .. table.concat(ids, ";")
  if sig == self.lastSig then return end
  self.lastSig = sig
  local names = {}
  for _, q in ipairs(list) do names[#names + 1] = q.name or ("#" .. q.id) end
  ns.Toast:Show(L["Share %d dungeon quests?"]:format(#list), "info",
    L["Your group may lack: %s. Click to share."]:format(table.concat(names, ", ")),
    function() QS:ShareAll(list) end, { cat = "dungeon", key = "questshare" })
end

function QS:Queue()
  if self.queued then return end
  self.queued = true
  if not P.After(2, function() ns.SafeCall(QS.Check, QS) end) then self:Check() end
end

function QS:OnEnable()
  local q = function(o) o:Queue() end
  for _, ev in ipairs({ "GROUP_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "QUEST_ACCEPTED",
      "UNIT_QUEST_LOG_CHANGED" }) do
    ns:On(ev, self, q)
  end
end

ns:RegisterCommand("share", function() QS:ShareAll() end, "share your dungeon quests with the party")
