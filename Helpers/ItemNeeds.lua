-- Arcanis: esya zekasi (modul "ItemNeeds"). Veri: Data/Brain/QuestItems.lua (ns.BrainData).
--   * Esya ipucunda: "Gorev icin sakla: <gorev> (seviye N)" / "Gorev baslatir: <gorev>". Bitmis gorevler, oyuncunun
--     fraksiyonuna ya da sinifina kapali gorevler gosterilmez.
--   * Satici yardimcisi (Vendor) hala bir goreve yarayan esyayi otomatik satmaz (ItemNeeds:Keep).
-- Irk kontrolu bilerek fraksiyon duzeyinde: Cataclysm maskelerinde Skyborne biti yok; tam irk karsilastirmasi Skyborne
-- oyuncunun gorevlerini yanlislikla eler. Fazladan "sakla" demek zararsiz, yanlislikla sattirmak zararli.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local IN = ns:NewModule("ItemNeeds", { defaults = { tooltip = true, protect = true, upgradeTip = true,
  bagArrow = true, rollMarks = true, questUps = true, setBonus = true, rewards = {} } })
ns.ItemNeeds = IN

local MAX_LINES = 3

-- Lua 5.1'de 2^32 ustu maskeler icin bit.band kullanilamaz: aritmetikle bit testi.
local function hasBit(mask, value)
  return math.floor(mask / value) % 2 == 1
end

local FACTION_BITS = {
  Alliance = { 1, 4, 8, 64, 1024, 2097152, 2 ^ 32 },
  Horde = { 2, 16, 32, 128, 256, 512, 2 ^ 33 },
}
local CLASS_BIT = {
  WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, DEATHKNIGHT = 32, SHAMAN = 64,
  MAGE = 128, WARLOCK = 256, MONK = 512, DRUID = 1024,
}

local function data() return ns.BrainData or {} end

-- Gorev bu oyuncu icin gecerli mi (fraksiyon + sinif)? Bilinmeyen durumda acik kabul edilir.
function IN:QuestFits(q, player)
  local races, classes = q[4] or 0, q[5] or 0
  if races > 0 and player.faction and FACTION_BITS[player.faction] then
    local any = false
    for _, b in ipairs(FACTION_BITS[player.faction]) do
      if hasBit(races, b) then any = true break end
    end
    if not any then return false end
  end
  local cb = player.class and CLASS_BIT[player.class]
  if classes > 0 and cb and not hasBit(classes, cb) then return false end
  return true
end

-- Gorevin oyuncuya gore durumu: "log" (gunlukte), "later" (henuz alinmadi) ya da nil (bitmis / uygun degil).
function IN:QuestState(qid, player)
  local q = data().quests and data().quests[qid]
  if not q then return nil end
  if P.IsQuestFlaggedCompleted(qid) then return nil end
  if P.IsQuestInLog(qid) then return "log", q end
  if not self:QuestFits(q, player) then return nil end
  -- gri (cok dusuk) gorev icin esya saklatma: rehberin "skip gray" farkiyla ayni (varsayilan 8)
  local E = ns.Engine
  local diff = E and E.db and E.db.skipDiff or 8
  if player.level and q[2] and player.level - q[2] >= diff then return nil end
  return "later", q
end

-- Esyanin hala ise yaradigi gorevler: { { id, name, level, state }, ... } (gunluktekiler once, sonra seviyeye gore)
-- ve baslattigi gorev (ya da nil).
function IN:For(itemId)
  local entry = itemId and data().items and data().items[itemId]
  if not entry then return {}, nil end
  local player = P.PlayerInfo() or {}
  local list = {}
  for _, qid in ipairs(entry.need or {}) do
    local state, q = self:QuestState(qid, player)
    if state then list[#list + 1] = { id = qid, name = q[1], level = q[2], state = state } end
  end
  table.sort(list, function(a, b)
    if a.state ~= b.state then return a.state == "log" end
    return (a.level or 0) < (b.level or 0)
  end)
  local starts
  if entry.starts then
    local state, q = self:QuestState(entry.starts, player)
    if state == "later" then starts = { id = entry.starts, name = q[1], level = q[2] } end
  end
  return list, starts
end

-- Satilmamali mi? (bir goreve hala gerekli ya da bir gorevi baslatiyor)
-- Modul kapali olsa da korur: "Quest item hints" ipuclarini kapatir, satis korumasini degil (yanlislikla satmak zararli).
function IN:Keep(itemId)
  if self.db and self.db.protect == false then return false end
  local list, starts = self:For(itemId)
  return #list > 0 or starts ~= nil
end

-- Ipucu
function IN:TooltipLines(tt, itemId)
  -- kanca kayitli kalir; ozellik Ayarlar'dan kapatilinca satir eklenmemeli
  if not (self:IsEnabled() and self.db.tooltip and tt and itemId) then return end
  if tt.__arcanisNeeds == itemId then return end
  local list, starts = self:For(itemId)
  if #list == 0 and not starts then return end
  tt.__arcanisNeeds = itemId
  local tag = "|cff07aacbArcanis|r "
  if starts then
    tt:AddLine(tag .. L["Starts a quest: %s (level %d)"]:format(starts.name, starts.level or 0), 1, 0.82, 0.2, true)
  end
  for i = 1, math.min(#list, MAX_LINES) do
    local e = list[i]
    local text = e.state == "log" and L["Quest item, keep: %s (in your log)"] or L["Keep for quest: %s (level %d)"]
    tt:AddLine(tag .. text:format(e.name, e.level or 0), 0.4, 0.85, 0.5, true)
  end
  if #list > MAX_LINES then
    tt:AddLine(tag .. L["...and %d more quests"]:format(#list - MAX_LINES), 0.6, 0.6, 0.6)
  end
  tt:Show()
end

-- Giyilebilir esyada "senin icin yukseltme" satiri: Gear:Compare (sinif x uzmanlik stat agirliklari) takili
-- esyayla karsilastirir. Giyemedigin esyada ve takili esyanin kendisinde satir yok.
function IN:UpgradeLine(tt)
  if not (self:IsEnabled() and self.db.upgradeTip and tt and tt.GetItem and ns.Gear) then return end
  local _, link = tt:GetItem()
  if type(link) ~= "string" or tt.__arcanisUp == link then return end
  local d = P.ItemDetailsFromLink and P.ItemDetailsFromLink(link)
  if not (d and type(d.equipLoc) == "string" and d.equipLoc ~= "") then return end
  local ok, delta, slot, eqLink, score = pcall(ns.Gear.Compare, ns.Gear, d)
  if not (ok and type(delta) == "number" and type(score) == "number") or eqLink == link then return end
  tt.__arcanisUp = link
  local base = score - delta
  local pct = base > 0.5 and math.floor(delta / base * 100 + 0.5) or nil
  local where = slot and ns.Gear:SlotName(slot) or "?"
  local tag = "|cff07aacbArcanis|r "
  if delta > 0.5 then
    tt:AddLine(tag .. (pct and L["Upgrade for you: +%d%% (%s)"]:format(pct, where) or L["Upgrade for you: empty slot (%s)"]:format(where)),
      0.3, 0.9, 0.3)
  elseif delta < -0.5 and pct then
    tt:AddLine(tag .. L["Worse than yours: %d%% (%s)"]:format(pct, where), 0.6, 0.6, 0.6)
  else
    return
  end
  tt:Show()
end

-- Set parcasinda "Set: N/M pieces worn" (Gear:SetCount, Data/ItemSets.lua).
function IN:SetLine(tt, itemId)
  local G = ns.Gear
  if not (self:IsEnabled() and tt and itemId and G and G:SetBonusOn()) or tt.__arcanisSet == itemId then return end
  local set = G:SetOf(itemId)
  if not set then return end
  tt.__arcanisSet = itemId
  local n, m = G:SetCount(set)
  tt:AddLine("|cff07aacbArcanis|r " .. L["Set: %d/%d pieces worn"]:format(n, m), 0.6, 0.8, 1)
  tt:Show()
end

function IN:HookTooltips()
  if self.hooked then return end
  self.hooked = true
  local function idFrom(link) return link and tonumber(tostring(link):match("item:(%d+)")) end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, d)
      if tt ~= GameTooltip and tt ~= _G.ItemRefTooltip then return end
      tt.__arcanisNeeds, tt.__arcanisUp, tt.__arcanisSet = nil, nil, nil
      local id = d and d.id
      if P.Clean then id = P.Clean(id) end   -- gizli (secret) degerse nil
      ns.SafeCall(IN.TooltipLines, IN, tt, id)
      ns.SafeCall(IN.UpgradeLine, IN, tt)
      ns.SafeCall(IN.SetLine, IN, tt, id)
    end)
  elseif GameTooltip and GameTooltip.HookScript then
    for _, tt in ipairs({ GameTooltip, _G.ItemRefTooltip }) do
      if tt then
        tt:HookScript("OnTooltipSetItem", function(t)
          local _, link = t:GetItem()
          ns.SafeCall(IN.TooltipLines, IN, t, idFrom(link))
          ns.SafeCall(IN.UpgradeLine, IN, t)
          ns.SafeCall(IN.SetLine, IN, t, idFrom(link))
        end)
        tt:HookScript("OnTooltipCleared", function(t) t.__arcanisNeeds, t.__arcanisUp, t.__arcanisSet = nil, nil, nil end)
      end
    end
  end
end

function IN:OnEnable()
  self:HookTooltips()
  -- gorev odulu kaydi (Helpers/QuestRewards.lua) ve yukseltme isaretleri (UI/GearMarks.lua)
  if self.OnQuestWindow then
    ns:On("QUEST_DETAIL", self, "OnQuestWindow")
    ns:On("QUEST_COMPLETE", self, "OnQuestWindow")
  end
  if ns.GearMarks then ns.GearMarks:Start(self) end
end

function IN:OnDisable()
  if ns.GearMarks then ns.GearMarks:Clear() end
end

ns:RegisterCommand("itemneeds", function(args)
  local id = tonumber((args or ""):match("(%d+)")) or P.ItemIdFromLink(args or "")
  if not id then ns:Print(L["Usage: /wf itemneeds <item id or link>"]) return end
  local list, starts = IN:For(id)
  if #list == 0 and not starts then ns:Print(L["No open quest needs this item."]) return end
  if starts then ns:Print(L["Starts a quest: %s (level %d)"]:format(starts.name, starts.level or 0)) end
  for _, e in ipairs(list) do ns:Print(L["Keep for quest: %s (level %d)"]:format(e.name, e.level or 0)) end
end, "[item] which quests still need this item")
