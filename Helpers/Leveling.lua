-- Arcanis: seviye atlama istatistikleri (modul "Leveling"): saatlik XP, sonraki seviyeye kalan sure, seviye suresi.
-- Veriler oturum boyunca bellekte tutulur; son 30 dakikalik pencere kullanilir. Komut: /wf xp
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Lv = ns:NewModule("Leveling", { defaults = { show = true, questXP = true, readyXP = true }, charDefaults = { levelTimes = {} } })
ns.Leveling = Lv

local WINDOW = 1800   -- sn: hiz hesabi penceresi
local MIN_SPAN = 60   -- sn: bundan kisa surede hiz gostermeyiz

function Lv:Reset()
  local xp, mx, level = P.XP()
  self.samples = {}     -- { t, gained }
  self.lastXP, self.lastMax, self.level = xp, mx, level
  self.started = P.Now()
  self.levelStart = P.Now()
  -- seviye suresi oturumlar arasi birikir (char.lvLevel / char.lvSecs); bu seviyenin baslangici bilinmiyorsa
  -- (addon seviye ortasinda kuruldu) sure yazilmaz
  local c = self.char
  if c then
    if c.lvLevel == level then self.levelBase, self.levelPartial = c.lvSecs or 0, nil
    else self.levelBase, self.levelPartial = 0, true; c.lvLevel, c.lvSecs = level, 0 end
  end
end

-- Bu seviyede gecen oyun suresi (sn): onceki oturumlar + bu oturum.
function Lv:LevelSeconds()
  return (self.levelBase or 0) + (P.Now() - (self.levelStart or P.Now()))
end

function Lv:SaveLevelTime()
  if self.char and self.level then self.char.lvLevel, self.char.lvSecs = self.level, math.floor(self:LevelSeconds()) end
end

-- XP degisti: kazanilan miktari hesapla (seviye atlandiysa onceki seviyenin kalanini ekle).
function Lv:OnXP()
  if not self.samples then self:Reset() return end
  local xp, mx, level = P.XP()
  local gained = xp - (self.lastXP or xp)
  -- seviye atlandi: OnLevelUp self.level'i once guncelleyebilir; azami XP degisimi kesin isarettir
  if level ~= self.level or mx ~= self.lastMax or gained < 0 then gained = math.max(0, (self.lastMax or mx) - (self.lastXP or 0)) + xp end
  self.lastXP, self.lastMax, self.level = xp, mx, level
  if gained > 0 then self.samples[#self.samples + 1] = { t = P.Now(), gained = gained } end
  self:Prune()
  self:Touch()
end

function Lv:Prune()
  local now = P.Now()
  while self.samples[1] and now - self.samples[1].t > WINDOW do table.remove(self.samples, 1) end
end

-- XP / saat (yetersiz veri varsa nil).
function Lv:Rate()
  if not self.samples or #self.samples == 0 then return nil end
  self:Prune()
  local sum = 0
  for _, s in ipairs(self.samples) do sum = sum + s.gained end
  local span = math.min(WINDOW, P.Now() - (self.started or P.Now()))
  if span < MIN_SPAN or sum <= 0 then return nil end
  return sum / span * 3600
end

-- Sonraki seviyeye kalan saniye (hiz yoksa nil).
function Lv:TimeToLevel()
  local rate = self:Rate()
  if not rate or rate <= 0 then return nil end
  local xp, mx = P.XP()
  return (mx - xp) / rate * 3600
end

function Lv.FormatXP(n)
  if n >= 1000 then return ("%.1fk"):format(n / 1000) end
  return tostring(math.floor(n + 0.5))
end

-- Oyuncu seviyesi gorevin 5 seviye ustunu gecince XP azalir (Classic kurali): 6 -> %80 ... 10+ -> %10.
local XP_FALLOFF = { [6] = 0.8, [7] = 0.6, [8] = 0.4, [9] = 0.2 }

-- Gorevin bu seviyedeki XP'si (Data/Brain/QuestXP.lua, Forever beta degeri); veri yoksa ya da azami seviyede nil.
function Lv:QuestXP(q, level)
  local row = q and ns.BrainData and ns.BrainData.xp and ns.BrainData.xp[q]
  if not row then return nil end
  level = level or P.PlayerLevel()
  if not level or level >= P.MaxLevel() then return nil end
  local xp, qlevel = row[1], P.QuestLevel(q) or (row[2] > 0 and row[2] or nil)
  local diff = qlevel and level - qlevel or 0
  if diff >= 10 then xp = xp * 0.1 elseif XP_FALLOFF[diff] then xp = xp * XP_FALLOFF[diff] end
  -- sunucu gibi kademeli yuvarlama: <=100 -> 5, <=500 -> 10, <=1000 -> 25, ustu -> 50
  local step = xp <= 100 and 5 or xp <= 500 and 10 or xp <= 1000 and 25 or 50
  return math.max(5, math.floor(xp / step + 0.5) * step)
end

-- Teslime hazir gorevlerin XP'si (gunlukte bitmis, bu seviyedeki deger): toplam, { {id, title, xp}, ... }.
-- Ayar kapali ya da modul kapaliyken 0.
function Lv:ReadyQuestXP(level)
  local total, list = 0, {}
  if not (self:IsEnabled() and self.db.readyXP) then return total, list end
  for _, q in ipairs(P.QuestLogList()) do
    local xp = q.complete and q.id and self:QuestXP(q.id, level)
    if xp then
      total = total + xp
      list[#list + 1] = { id = q.id, title = q.title, xp = xp }
    end
  end
  table.sort(list, function(a, b) return a.xp > b.xp end)
  return total, list
end

-- Ipucuna hazir gorev XP'si satirlari (fare cubugun ustundeyken)
function Lv:ReadyTooltip(tip)
  local total, list = self:ReadyQuestXP()
  if total <= 0 then return false end
  tip:AddLine(L["Quests ready to turn in: +%s XP"]:format(self.FormatXP(total)))
  for _, q in ipairs(list) do tip:AddDoubleLine(q.title or ("#" .. q.id), "+" .. self.FormatXP(q.xp), 1, 1, 1, 1, 1, 1) end
  return true
end

function Lv.FormatTime(sec)
  sec = math.floor(sec + 0.5)
  if sec >= 3600 then return ("%dh %02dm"):format(math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
  if sec >= 60 then return ("%d min"):format(math.floor(sec / 60 + 0.5)) end
  return ("%d s"):format(sec)
end

-- Tek satir ozet: "8.4k xp/h | 12 min" (veri yoksa nil).
function Lv:Line()
  local rate = self:Rate()
  if not rate then return nil end
  local text = L["%s xp/h"]:format(self.FormatXP(rate))
  local ttl = self:TimeToLevel()
  if ttl then text = text .. "  |  " .. self.FormatTime(ttl) end
  return text
end

function Lv:Touch()
  local W = ns.Window
  if W and W.UpdateXP then ns.SafeCall(W.UpdateXP, W) end
end

function Lv:OnLevelUp(_, level)
  level = tonumber(level) or P.PlayerLevel()
  local took = self:LevelSeconds()
  local partial = self.levelPartial
  self.levelStart, self.levelBase, self.levelPartial = P.Now(), 0, nil
  if self.char then self.char.lvLevel, self.char.lvSecs = level, 0 end
  -- XP alanlarina dokunulmaz: tasan XP'yi OnXP (eski seviyenin kalani + yeni xp) olay sirasindan bagimsiz sayar
  self.level = level
  if partial then self:Touch() return end   -- baslangici bilinmeyen seviye: sure yanlis olur, yazilmaz
  local times = self.char.levelTimes
  times[#times + 1] = { level = level, secs = math.floor(took) }
  while #times > 10 do table.remove(times, 1) end
  if took >= 30 and ns.Toast and self.db.show then
    ns.Toast:Show(L["Level %d took %s."]:format(level - 1, self.FormatTime(took)), "info", nil, nil, { prio = "low", cat = "level" })
  end
  self:Touch()
end

function Lv:OnEnable()
  self:Reset()
  ns:On("PLAYER_XP_UPDATE", self, "OnXP")
  ns:On("PLAYER_LEVEL_UP", self, "OnLevelUp")
  ns:On("PLAYER_LOGOUT", self, "SaveLevelTime")
end

ns:RegisterCommand("xp", function()
  local line = Lv:Line()
  if not line then ns:Print(L["Not enough XP data yet. Kill or quest for a minute."]) return end
  ns:Print(line)
  local xp, mx = P.XP()
  ns:Print(L["XP: %d / %d (%d%%)"]:format(xp, mx, math.floor(xp / math.max(1, mx) * 100)))
end, "XP per hour and time to next level")
