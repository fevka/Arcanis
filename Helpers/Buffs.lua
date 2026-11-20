-- Arcanis: buff hatirlatici (modul "Buffs"). Oyuncunun kendi buff listesi (sinifa gore varsayilanlar + /wf buffs add):
-- savas disinda eksik (ya da bitmek uzere) olan ilk buff ekranda ikonla gosterilir, ikona tiklamak onu atar
-- (guvenli dugme; ozellikleri yalniz savas disinda degisir). Binekte, aracta, ucusta, olu iken ve istege bagli
-- dinlenme alaninda (han, baskentler) sessiz.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Buffs = ns:NewModule("Buffs", {
  defaults = { quietResting = true, point = "CENTER", relPoint = "CENTER", x = 0, y = 160 },
  charDefaults = { off = {}, custom = {} },
})
ns.Buffs = Buffs

-- Sinif varsayilanlari: her satir bir grup buyu ID'si (rutbe 1); gruptan biri ustundeyse tamam, eksikse ilk bilinen
-- atilir (ad ile: en yuksek rutbe). Bekleme suresi kisa / savas buff'lari (Battle Shout) ve zehirler yok.
Buffs.CLASS = {
  MAGE = { { 1459 }, { 7302, 168, 6117 } },                          -- Arcane Intellect; Ice / Frost / Mage Armor
  PRIEST = { { 1243 }, { 588 } },                                    -- Power Word: Fortitude; Inner Fire
  DRUID = { { 1126 }, { 467 } },                                     -- Mark of the Wild; Thorns
  WARLOCK = { { 706, 687 } },                                        -- Demon Armor / Demon Skin
  PALADIN = { { 19740, 19742 }, { 465, 7294, 19746, 19876, 19888, 19891 } },   -- Blessing; aura
  HUNTER = { { 13165, 13163, 5118, 13159 } },                        -- Aspect of the Hawk / Monkey (Cheetah, Pack sayilir)
  SHAMAN = { { 324 } },                                              -- Lightning Shield
}

local SOON = 30   -- sn: bundan az kalan uzun buff (5 dk+) eksik sayilir

-- Ilk eksik buff (saf islev). list: { {id, ...}, ... }; known(id) -> bool; name(id) -> ad; auras: { {id, name, exp, dur} };
-- now: saniye. Dondurur: { group, cast = atilacak ID } ya da nil.
function Buffs.Missing(list, known, name, auras, now)
  local have = {}
  for _, a in ipairs(auras or {}) do
    local left = (a.exp and a.exp > 0 and a.dur and a.dur >= 300) and (a.exp - now) or nil
    if not (left and left < SOON) then
      if a.id then have[a.id] = true end
      if a.name then have[a.name] = true end
    end
  end
  for _, group in ipairs(list) do
    local cast, on
    for _, id in ipairs(group) do
      if have[id] or (name(id) and have[name(id)]) then on = true break end
      if not cast and known(id) then cast = id end
    end
    if cast and not on then return { group = group, cast = cast } end
  end
  return nil
end

-- Oyuncunun listesi: sinif varsayilanlari (kapatilanlar haric) + kendi ekledikleri
function Buffs:List()
  local out = {}
  for _, g in ipairs(self.CLASS[P.PlayerClassToken() or ""] or {}) do
    if not self.char.off[g[1]] then out[#out + 1] = g end
  end
  for _, id in ipairs(self.char.custom) do
    if not self.char.off[id] then out[#out + 1] = { id } end
  end
  return out
end

function Buffs:Quiet()
  return P.InCombat() or P.IsDead() or P.OnTaxi() or P.IsMounted() or P.InVehicle()
    or (self.db.quietResting and P.IsResting())
end

function Buffs:Find()
  if self:Quiet() then return nil end
  return Buffs.Missing(self:List(), P.KnowsSpell, P.SpellName, P.PlayerBuffs(), P.Now())
end

local SIZE = 36
function Buffs:Button()
  if self.button then return self.button end
  local b = CreateFrame("Button", "ArcanisBuffButton", UIParent, "SecureActionButtonTemplate,BackdropTemplate")
  b:SetSize(SIZE, SIZE)
  ns.Skin:ApplyBackdrop(b, ns.Skin.Colors.button, ns.Skin.Colors.accent)
  -- tek kenar (QuestItem gibi): istemci ayari tusu basista istiyorsa basista
  b:RegisterForClicks(P.GetCVar("ActionButtonUseKeyDown") == "1" and "AnyDown" or "AnyUp")
  b:SetAttribute("type1", "spell")   -- yalniz sol tik: sag tusla surukleme buyuyu atmasin
  b:SetAttribute("unit", "player")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetPoint("TOPLEFT", 1, -1); b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b:SetMovable(true)
  b:RegisterForDrag("RightButton")   -- sol tik buyuyu atar; sag tusla surukle
  b:SetScript("OnDragStart", function(f) if not P.InLockdown() then f:StartMoving() end end)
  b:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    local point, _, relPoint, x, y = f:GetPoint()
    Buffs.db.point, Buffs.db.relPoint, Buffs.db.x, Buffs.db.y = point, relPoint, x, y
  end)
  b:SetScript("OnEnter", function(f)
    if not (GameTooltip and f.spellName) then return end
    GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Missing buff: %s"]:format(f.spellName))
    GameTooltip:AddLine(L["Click to cast it. Right-drag to move."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  b:SetPoint(self.db.point, UIParent, self.db.relPoint, self.db.x, self.db.y)
  b:Hide()
  self.button = b
  return b
end

-- Dugmeyi eksik buff'a bagla ya da gizle. Savasta guvenli dugmeye dokunulmaz (savas bitince tekrar).
function Buffs:Update()
  if P.InLockdown() then self.pending = true return end
  self.pending = false
  local miss = self:IsEnabled() and self:Find() or nil
  if not miss then
    if self.button then self.button:Hide(); self.button:SetAttribute("spell", nil) end
    return nil
  end
  local b = self:Button()
  local name = P.SpellName(miss.cast)
  b.spellName = name
  b:SetAttribute("spell", name)
  b.icon:SetTexture(P.SpellIcon(name) or "Interface\\Icons\\INV_Misc_QuestionMark")
  b:Show()
  return miss
end

function Buffs:Queue()
  if self.queued then return end
  self.queued = true
  if not P.After(0.3, function() Buffs.queued = false; ns.SafeCall(Buffs.Update, Buffs) end) then
    self.queued = false; self:Update()
  end
end

-- Uzun buff bitmek uzereyken de hatirlatsin: savas disinda 15 sn'de bir bakar
function Buffs:Tick()
  if not self:IsEnabled() then self.ticking = false return end
  self:Queue()
  if not P.After(15, function() ns.SafeCall(Buffs.Tick, Buffs) end) then self.ticking = false end
end

function Buffs:OnEnable()
  local q = function(o) o:Queue() end
  ns:On("UNIT_AURA", self, q, "player")
  -- savas basliyor: kilit henuz yokken dugme gizlenir (savasta tiklanip yanlislikla atilmasin)
  ns:On("PLAYER_REGEN_DISABLED", self, function(o)
    if o.button and not P.InLockdown() then o.button:Hide() end
  end)
  for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_UPDATE_RESTING",
      "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_UNGHOST",
      "PLAYER_ALIVE" }) do
    ns:On(ev, self, q)
  end
  if not self.ticking then self.ticking = true; self:Tick() end
  self:Queue()
end

-- Kapaninca dugme gizlenir (savasta: savas bitince, modulun olaylari kapali oldugu icin ayri cerceveyle)
function Buffs:OnDisable()
  if not self.button then return end
  if not P.InLockdown() then self.button:Hide() return end
  local f = self.offFrame or CreateFrame("Frame")
  self.offFrame = f
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  f:SetScript("OnEvent", function(fr) fr:UnregisterAllEvents(); if not Buffs:IsEnabled() then Buffs.button:Hide() end end)
end

-- /wf buffs [add|remove <buyu ID ya da baglanti>]: kendi listen
ns:RegisterCommand("buffs", function(args)
  args = args or ""
  local cmd = args:lower():match("^%s*(%a*)")
  local id = tonumber(args:match("spell:(%d+)") or args:match("(%d+)%s*$"))
  local c = Buffs.char
  if cmd == "add" and id then
    local known = false
    for _, x in ipairs(c.custom) do if x == id then known = true end end
    if not known then c.custom[#c.custom + 1] = id end
    c.off[id] = nil
    ns:Print(L["Buff reminder: %s added."]:format(P.SpellName(id) or ("#" .. id)))
  elseif cmd == "remove" and id then
    for i = #c.custom, 1, -1 do if c.custom[i] == id then table.remove(c.custom, i) end end
    ns:Print(L["Buff reminder: %s removed."]:format(P.SpellName(id) or ("#" .. id)))
  else
    for _, g in ipairs(Buffs:List()) do ns:Print("  " .. (P.SpellName(g[1]) or ("#" .. g[1]))) end
    ns:Print(L["Add your own with /wf buffs add <spell ID or shift-clicked spell>."])
  end
  Buffs:Queue()
end, "[add|remove <spell>] your buff reminder list")
