-- Arcanis: kucuk kolayliklar (modul "QoL"). Her biri ayri anahtar, hepsi varsayilan kapali:
--   hideErrors  : tekrarlayan kirmizi hata yazilarini gizler (bekleme suresi, enerji, hedef yok...); digerleri kalir
--   camera      : kamera en uzak mesafesi (CVar cameraDistanceMaxZoomFactor)
--   autoLoot    : otomatik ganimet (CVar autoLootDefault); fastLoot: ganimet penceresi acilir acilmaz hepsi alinir
--   bagSlots    : sirt cantasi dugmesinde bos yuva sayisi (CVar displayFreeBagSlots; yoksa kendi yazimiz)
--   compareShift: esya karsilastirma yalniz Shift ile (CVar alwaysCompareItems = 0)
-- CVar degistiren anahtar acilinca oyuncunun onceki degeri db.saved'e yazilir, kapaninca (ya da modul kapaninca)
-- o deger geri konur. Gorev ganimeti parlamasi alinmadi: tek bir CVar degil, etkilesim (soft target) ayarlarini
-- degistirmeyi gerektiriyor.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local QoL = ns:NewModule("QoL", {
  defaults = { hideErrors = false, camera = false, autoLoot = false, fastLoot = false, bagSlots = false,
    compareShift = false, saved = {} },
})
ns.QoL = QoL

-- anahtar -> { CVar, istenen deger, yedek deger... } (ilk kabul edilen yazilir)
QoL.CVARS = {
  camera = { "cameraDistanceMaxZoomFactor", "4", "2.6" },
  autoLoot = { "autoLootDefault", "1" },
  compareShift = { "alwaysCompareItems", "0" },
  bagSlots = { "displayFreeBagSlots", "1" },
}

-- Anahtarin CVar'ini uygular (on) ya da oyuncunun eski degerine dondurur. Dondurur: CVar bu istemcide var mi.
function QoL:ApplyCVar(key, on)
  local def = self.CVARS[key]
  if not def then return false end
  local name, saved = def[1], self.db.saved
  if on then
    local cur = P.GetCVar(name)
    if cur == nil then return false end
    if saved[name] == nil then saved[name] = cur end   -- ilk acilista: oyuncunun degeri (yeniden uygulamada ezilmez)
    for i = 2, #def do if P.SetCVar(name, def[i]) then return true end end
    return true
  end
  if saved[name] ~= nil then
    P.SetCVar(name, saved[name])
    saved[name] = nil
  end
  return true
end

-- Gizlenen hata yazilari: oyunun global metin adlari (oyunun dilinde karsilastirilir)
QoL.SPAM = {
  "ERR_ABILITY_COOLDOWN", "ERR_SPELL_COOLDOWN", "ERR_ITEM_COOLDOWN", "ERR_OUT_OF_ENERGY", "ERR_OUT_OF_RAGE",
  "ERR_OUT_OF_MANA", "ERR_OUT_OF_FOCUS", "ERR_NO_ATTACK_TARGET", "ERR_GENERIC_NO_TARGET", "ERR_INVALID_ATTACK_TARGET",
  "SPELL_FAILED_NO_COMBO_POINTS", "SPELL_FAILED_SPELL_IN_PROGRESS", "SPELL_FAILED_TARGETS_DEAD", "SPELL_FAILED_NOT_READY",
  "SPELL_FAILED_BAD_TARGETS", "OUT_OF_ENERGY", "OUT_OF_RAGE", "OUT_OF_MANA",
}
function QoL:IsSpam(msg)
  if type(msg) ~= "string" then return false end
  if not self.spam then
    self.spam = {}
    for _, name in ipairs(self.SPAM) do
      local t = P.GlobalText(name)
      if t then self.spam[t] = true end
    end
  end
  return self.spam[msg] == true
end

function QoL:ApplyErrors(on)
  if on then P.FilterUIErrors(function(msg) return QoL:IsSpam(msg) end)
  elseif self.errorsOn then P.FilterUIErrors(nil) end
  self.errorsOn = on or nil
end

-- Sirt cantasi bos yuva yazisi (istemcide CVar yoksa)
function QoL:UpdateBagText()
  local t = self.bagText
  if not t then return end
  t:SetText(tostring(P.FreeBagSlots()))
end

function QoL:ApplyBagSlots(on)
  if P.GetCVar(self.CVARS.bagSlots[1]) ~= nil then return self:ApplyCVar("bagSlots", on) end   -- istemcinin kendi gostergesi
  local btn = P.BackpackButton()
  if on and btn and not self.bagText and btn.CreateFontString then
    self.bagText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.bagText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
  end
  if self.bagText then
    self.bagText:SetShown(on and true or false)
    if on then self:UpdateBagText() end
  end
end

-- Bir anahtari uygular (ayar degisince ve modul acilip kapaninca)
function QoL:Apply(key)
  local on = self:IsEnabled() and self.db[key] and true or false
  if key == "hideErrors" then return self:ApplyErrors(on) end
  if key == "bagSlots" then return self:ApplyBagSlots(on) end
  if self.CVARS[key] then return self:ApplyCVar(key, on) end
end

QoL.KEYS = { "hideErrors", "camera", "autoLoot", "bagSlots", "compareShift" }
function QoL:ApplyAll() for _, k in ipairs(self.KEYS) do self:Apply(k) end end

function QoL:Set(key, v)
  self.db[key] = v and true or false
  self:Apply(key)
end

function QoL:OnLoot()
  if self.db.fastLoot and P.AutoLootActive() then P.LootAll() end
end

function QoL:OnEnable()
  self:ApplyAll()
  ns:On("LOOT_READY", self, "OnLoot")
  ns:On("BAG_UPDATE_DELAYED", self, "UpdateBagText")
end

function QoL:OnDisable() self:ApplyAll() end

-- Modul kapali yuklendiyse (ornegin QoL'u kapatan profil yuklendi, ardindan /reload) OnDisable hic calismaz:
-- degistirdigimiz CVar'larin oyuncu degerleri burada geri yazilir.
function QoL:RestoreIfOff()
  if self:IsEnabled() then return end
  for key in pairs(self.CVARS) do self:ApplyCVar(key, false) end
end

function QoL:OnInitialize()
  if self.db.disabled then self:RestoreIfOff() end   -- burada henuz hicbir modul acik degil: kayda bakilir
  -- karakterin varsayilan profili ARCANIS_INITIALIZED'da (modullerden sonra) yazilir ve QoL'u kapatabilir
  ns:Listen("ARCANIS_READY", self, function() QoL:RestoreIfOff() end)
end
