-- Arcanis: isim levhasinda gorev isareti (modul "QuestPlates"). Gunlukteki bir gorevin hedefi olan yaratigin isim
-- levhasinin yaninda kucuk kilic ve ilerleme ("3/10"). Kaynak oyunun kendi birim ipucu verisi (C_TooltipInfo.GetUnit:
-- gorev hedefi satirlari); ek veri yok. Sonuc birim basina (GUID, yoksa ad) onbellekte, gorev gunlugu degisince silinir.
-- Dusen esya (loot) hedefleri ipucunda yoksa isaretlenmez: yaratik -> gorev esyasi eslemesi verimizde yok.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local QP = ns:NewModule("QuestPlates", { defaults = { progress = true } })
ns.QuestPlates = QP

-- Ipucu satirlarindan isaret (saf islev). lines: { {type, text, done}, ... } (P.UnitTooltipLines); grup uyesinin
-- adindan ("player") sonra gelen hedefler o uyenin, sayilmaz (yeni gorev basligi sifirlar); me: oyuncunun adi.
-- Dondurur: { text = "3/10" | "" } (bitmemis hedef var) ya da nil.
function QP.MarkFromLines(lines, me)
  if type(lines) ~= "table" then return nil end
  local mine = true
  for _, l in ipairs(lines) do
    if l.type == "title" then mine = true
    elseif l.type == "player" then mine = (me ~= nil and l.text == me)
    elseif l.type == "objective" and mine and not l.done then
      local have, need = (l.text or ""):match("(%d+)%s*/%s*(%d+)")
      have, need = tonumber(have), tonumber(need)
      if not (have and need and have >= need) then
        return { text = have and ("%d/%d"):format(have, need) or "" }
      end
    end
  end
  return nil
end

local cache = {}   -- birim anahtari -> isaret ya da false
QP.cache = cache
local shown = {}   -- gorunen levha birimleri

function QP:MarkFor(unit)
  local key = P.UnitKey(unit)
  if key and cache[key] ~= nil then return cache[key] or nil end
  local mark = QP.MarkFromLines(P.UnitTooltipLines(unit), P.PlayerName())
  if key then cache[key] = mark or false end
  return mark
end

local function badge(plate)
  local b = plate.arcanisQuest
  if b then return b end
  b = CreateFrame("Frame", nil, plate)
  b:SetSize(14, 14)
  b:SetPoint("LEFT", plate, "RIGHT", 2, 0)
  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetAllPoints()
  b.icon:SetTexture(ns.Skin.Icons.sword)
  b.icon:SetVertexColor(1, 0.82, 0.2)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.text:SetPoint("LEFT", b, "RIGHT", 2, 0)
  plate.arcanisQuest = b
  QP.badges[#QP.badges + 1] = b
  return b
end
QP.badges = {}

function QP:Paint(unit)
  local plate = P.NamePlateFor(unit)
  if not plate then return end
  local mark = self:IsEnabled() and self:MarkFor(unit) or nil
  if not mark then
    if plate.arcanisQuest then plate.arcanisQuest:Hide() end
    return
  end
  local b = badge(plate)
  b.text:SetText(self.db.progress and mark.text or "")
  b:Show()
end

function QP:Refresh()
  self.queued = false
  for k in pairs(cache) do cache[k] = nil end
  for unit in pairs(shown) do self:Paint(unit) end
end

function QP:Queue()
  if self.queued then return end
  self.queued = true
  if not P.After(0.3, function() ns.SafeCall(QP.Refresh, QP) end) then self:Refresh() end
end

function QP:OnEnable()
  ns:On("NAME_PLATE_UNIT_ADDED", self, function(o, _, unit) if unit then shown[unit] = true; o:Paint(unit) end end)
  ns:On("NAME_PLATE_UNIT_REMOVED", self, function(_, _, unit) if unit then shown[unit] = nil end end)
  ns:On("QUEST_LOG_UPDATE", self, "Queue")
  ns:On("UNIT_QUEST_LOG_CHANGED", self, "Queue", "player")
  self:Refresh()
end

-- kapaninca butun isaretler gizlenir (levhalar yeniden kullanilir; eski isaret baska yaratikta kalmasin)
function QP:OnDisable()
  for _, b in ipairs(self.badges) do b:Hide() end
  for k in pairs(cache) do cache[k] = nil end
end
