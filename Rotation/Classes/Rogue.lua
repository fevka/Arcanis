local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local R = {}
ns.classes.ROGUE = R
R.enemyProbe = "SinisterStrike"   -- dusman sayimi yakin dovus menzilinde

-- WoW Forever Rogue. Forever notlari (beta verisi):
--   * Combo point ve energy savasta gizli olabilir: combo point ns.ComboEstimate() ile okunur,
--     OnCast kendi atislarimizdan ns.comboGuess'i gunceller (builder +, bitirici sifirlar).
--     Iskalanan / savusturulan vuruslar tahmini sisirebilir; gercek deger okunabilirse o kullanilir.
--   * Energy esigi yok: "yeter mi" ns.Usable ile. Savasta aura gizli: Slice and Dice, Venom ve
--     Rupture sureleri bitiriciye harcanan combo point'ten hesaplanip kendi kaydimizda tutulur.
--   * Slice and Dice 6 sn + 3 sn / CP (Improved Slice and Dice her rank +%15).
--     Rupture 6 sn + 2 sn / CP, Venom (Assassination 31) 6 sn + 3 sn / CP, +%30 zehir hasari.
--   * Mutilate (Assassination 21, iki hancer) 2 CP verir; Hemorrhage artik hasar almasini
--     arttirmaz, Rupture'i %15 guclendirir. Ghostly Strike Subtlety'de builder.
--   * Arkadan vurmak bilinemez: Backstab sadece ayardan ya da zindan / raid'de onerilir.
R.spells = {
    -- Builder'lar
    SinisterStrike = { id = 1752,    name = "Sinister Strike" },
    Backstab       = { id = 53,      name = "Backstab" },
    Mutilate       = { id = 1310707, name = "Mutilate" },
    Hemorrhage     = { id = 16511,   name = "Hemorrhage", duration = 15 },
    GhostlyStrike  = { id = 14278,   name = "Ghostly Strike" },
    Riposte        = { id = 14251,   name = "Riposte" },

    -- Gizlilik acilislari
    Stealth        = { id = 1784,    name = "Stealth" },
    Ambush         = { id = 8676,    name = "Ambush" },
    Garrote        = { id = 703,     name = "Garrote", duration = 18 },
    CheapShot      = { id = 1833,    name = "Cheap Shot" },
    Premeditation  = { id = 14183,   name = "Premeditation" },

    -- Bitiriciler (combo point harcar; sureleri OnCast'te kaydedilir)
    Eviscerate     = { id = 2098,    name = "Eviscerate" },
    SliceAndDice   = { id = 5171,    name = "Slice and Dice" },
    Rupture        = { id = 1943,    name = "Rupture" },
    KidneyShot     = { id = 408,     name = "Kidney Shot" },
    ExposeArmor    = { id = 8647,    name = "Expose Armor", duration = 30 },
    Venom          = { id = 1310703, name = "Venom" },

    -- Cooldown / savunma / yardimci
    ColdBlood      = { id = 14177,   name = "Cold Blood" },
    BladeFlurry    = { id = 13877,   name = "Blade Flurry" },
    AdrenalineRush = { id = 13750,   name = "Adrenaline Rush" },
    Preparation    = { id = 14185,   name = "Preparation" },
    Evasion        = { id = 5277,    name = "Evasion" },
    Vanish         = { id = 1856,    name = "Vanish" },
    Sprint         = { id = 2983,    name = "Sprint" },
    Kick           = { id = 1766,    name = "Kick" },
    Poisons        = { id = 2842,    name = "Poisons" },   -- zehir hatirlaticisi icin capa
}
R.interrupts = { "Kick" }

R.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "snd", default = true, label = "Slice and Dice bakimi",
      tip = "Slice and Dice bitmeden yenilenir (Combat 4, digerleri 2 combo point ile)." },
    { type = "toggle", key = "sndTrash", default = false, label = "Normal mob'larda Slice and Dice",
      tip = "Leveling / Combat tek basina normal mob'larda atlar: mob Slice and Dice'in karsiligini vermeden olur." },
    { type = "toggle", key = "rupture", default = true, label = "Rupture",
      tip = "Elit, grup ve oyuncu hedeflerde 5 combo point ile. Mechanical / Elemental kanamaz." },
    { type = "toggle", key = "exposeArmor", default = true, label = "Expose Armor (zindan elitleri)",
      tip = "Raid'de kapali: orada Sunder Armor var. Savasta tek bir savasci Sunder yapiyorsa kapat." },
    { type = "toggle", key = "backstab", default = false, label = "Backstab (arkadayim)",
      tip = "Arkada oldugun bilinemez. Kapaliyken Backstab sadece zindan / raid'de (tank var) onerilir. Hancer gerekir." },
    { type = "toggle", key = "cheapShot", default = true, label = "Cheap Shot acilisi",
      tip = "Elit ve oyuncu hedeflerde (Subtlety Initiative ile normal mob'larda da)." },
    { type = "toggle", key = "stealth", default = true, label = "Savas disinda Stealth hatirlatici" },
    { type = "toggle", key = "poison", default = true, label = "Zehir hatirlatici",
      tip = "Sadece savas disinda: silahta zehir yoksa kucuk ikonda Poisons." },
    { type = "slider", key = "finisherCP", default = 0, min = 0, max = 5, step = 1, zero = "Otomatik",
      label = "Eviscerate combo point esigi",
      tip = "Otomatik: 5 (normal mob'larda 4, 20 alti 3: hedef cani savasta gizli, mob erken bitsin)." },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Blade Flurry ve (3+ dusmanda) Adrenaline Rush. Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 2, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "evasion", default = 50, min = 0, max = 90, step = 5, zero = "Kapali", label = "Evasion" },
    { type = "slider", key = "vanish",  default = 20, min = 0, max = 90, step = 5, zero = "Kapali", label = "Vanish" },
    { type = "slider", key = "sprint",  default = 0,  min = 0, max = 90, step = 5, zero = "Kapali", label = "Sprint (kac)" },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local DebuffDue = ns.DebuffDue
local BuffUp = ns.BuffUp

local SPECS = { "ASSASSINATION", "COMBAT", "SUBTLETY" }
local spec, impSnD = "LEVELING", 0
function R.OnRefresh()
    spec   = SPECS[ns.MainTalentTab()] or "LEVELING"
    impSnD = ns.TalentRank("Improved Slice and Dice")
end

---------------------------------------------------------------------------
-- Combo point sayaci ve bitirici sure kayitlari (aura savasta gizli)
---------------------------------------------------------------------------
-- Her builder'in verdigi combo point (hedefte bitenler dahil)
local GAIN = { SinisterStrike = 1, Backstab = 1, Hemorrhage = 1, GhostlyStrike = 1, Ambush = 1,
               Garrote = 1, CheapShot = 2, Mutilate = 2, Premeditation = 2 }
local FINISHERS = { Eviscerate = true, SliceAndDice = true, Rupture = true, KidneyShot = true,
                    ExposeArmor = true, Venom = true }

local sndEnd, venomEnd, ruptEnd = 0, 0, 0   -- bitis zamanlari (GetTime)
local ruptGUID                              -- Rupture atilan hedef

function R.OnCast(key)
    if FINISHERS[key] then
        local cp = math.max(ns.comboGuess or 0, 1)   -- harcanan combo point
        local now = GetTime()
        if key == "SliceAndDice" then sndEnd = now + (6 + 3 * cp) * (1 + 0.15 * impSnD) end
        if key == "Venom" then venomEnd = now + 6 + 3 * cp end
        if key == "Rupture" then ruptEnd, ruptGUID = now + 6 + 2 * cp, ns.Call(UnitGUID, "target") end
        ns.comboGuess = 0
    elseif GAIN[key] then
        ns.comboGuess = math.min((ns.comboGuess or 0) + GAIN[key], 5)
    end
end

-- Rupture hedefe bagli: baska hedefe gecince kayit silinir (ayni mob yeniden secilince kalir; GUID okunamazsa silinir)
local targetEv = CreateFrame("Frame")
pcall(targetEv.RegisterEvent, targetEv, "PLAYER_TARGET_CHANGED")
targetEv:SetScript("OnEvent", function()
    local g = ns.Call(UnitGUID, "target")
    if not (g and g == ruptGUID) then ruptEnd = 0 end
end)

---------------------------------------------------------------------------
-- Durum (her guncellemede bir kez okunur)
---------------------------------------------------------------------------
local ctx = {}

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.spec     = spec
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    ctx.health   = ns.HealthPercent()                 -- nil: bilinmiyor
    ctx.inst     = ns.InstanceType()
    ctx.level    = ns.Call(UnitLevel, "player") or 60
    ctx.hasTarget = ns.Call(UnitCanAttack, "player", "target") == true
    ctx.melee    = ns.InRange("SinisterStrike") == true
    ctx.far      = ns.InRange("SinisterStrike") == false
    ctx.cp       = ns.ComboEstimate() or 0
    local n = ns.EnemiesNearby() or 0
    if ctx.melee and n < 1 then n = 1 end
    ctx.enemies  = n
    -- aoeForce = "single": ana ikon tek hedef kalsin (AoE ayri ikonda ya da kapali)
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and n >= O("aoeAt")
    -- Gizlilik: IsStealthed, Stealth durusu ya da Stealth / Vanish buff'i
    local form = ns.ActiveForm()
    ctx.stealth  = ns.Call(IsStealthed) == true or BuffUp("Stealth") or BuffUp("Vanish")
        or (form ~= nil and Has("Stealth") and form == S("Stealth").id)
end

-- p: ayardaki esik (0 = kapali)
local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

local CreatureIs = ns.CreatureIs

-- Kalan sure: savas disinda gercek aura, savasta gercek ya da kendi kaydimiz
local function Left(endTime, unit, key, filter)
    local real = ns.AuraRemaining(unit, key, filter)
    -- okunabiliyorsa gercek deger; aura API savasta bu birimde calistiysa "yok" da gercek (parry edilen Rupture)
    if not ctx.inCombat or real > 0 or ns.AuraTrusted(unit, key) then return real end
    -- Gizli: kendi kaydimiz (combo tahmini kacmis vuruslarla sismis olabilir; kisa tutulur)
    return math.max(endTime - GetTime(), 0)
end

local function SndLeft()   return Left(sndEnd, "player", "SliceAndDice", "HELPFUL") end
local function VenomLeft() return Left(venomEnd, "player", "Venom", "HELPFUL") end
local function RuptLeft()  return Left(ruptEnd, "target", "Rupture", "HARMFUL|PLAYER") end

-- Backstab: arkada olmak bilinemez; ayar ya da zindan / raid (tank tutuyor), oyuncuya degil
-- Ana elde hancer var mi? (Backstab, Ambush, Mutilate). Bilinmiyorsa oyunun "kullanilabilir"ine birakilir.
function R.DaggerInHand()
    local id = ns.Call(GetInventoryItemID, "player", 16)
    if not id then return true end
    local ok, _, _, _, _, _, classID, subID = pcall(C_Item.GetItemInfoInstant, id)
    if not ok or type(classID) ~= "number" or type(subID) ~= "number" then return true end
    return classID == 2 and subID == 15
end

local function BackstabOk()
    if not Has("Backstab") or not R.DaggerInHand() then return false end
    if O("backstab") then return true end
    return (ctx.inst == "party" or ctx.inst == "raid") and ctx.kind ~= "player"
end

-- Bu dovuste bitirici / uzun etkili buyu degmez mi (normal mob, tek basina)
local function Trash() return not ctx.big end

---------------------------------------------------------------------------
-- Gizlilik acilislari
---------------------------------------------------------------------------
local function CheapShotWanted()
    if not O("cheapShot") then return false end
    return ctx.kind == "player" or ctx.kind == "elite" or ctx.kind == "boss"
        or (spec == "SUBTLETY" and ns.TalentRank("Initiative") >= 3 and not Trash())
end

local function Opener()
    local r = (spec == "SUBTLETY" and ctx.cp < 3 and Try("Premeditation", true))
    if r then return r end
    return (ctx.kind == "player" and Try("CheapShot", true))
        or (R.DaggerInHand() and Try("Ambush", false))   -- hancer ve gizlilik gerekir
        or (CheapShotWanted() and Try("CheapShot", true))
        or (not CreatureIs("Mechanical", "Elemental") and DebuffDue("Garrote") and Try("Garrote", true))
end

-- Stealth ogrenilen acilisi varsa onerilir (14 Garrote, 18 Ambush, 26 Cheap Shot)
local function StealthRule()
    if not O("stealth") or ctx.inCombat or ctx.stealth or not ctx.hasTarget then return nil end
    if Has("Garrote") or Has("Ambush") or Has("CheapShot") then return Try("Stealth", true) end
end

---------------------------------------------------------------------------
-- Bitiriciler
---------------------------------------------------------------------------
-- Slice and Dice: Combat 4 CP, digerleri 2 CP; Subtlety 20'den sonra Rupture / Eviscerate'e harcar
local function SndRule()
    if not O("snd") or SndLeft() > 2 then return nil end
    if spec == "SUBTLETY" and ctx.level >= 20 then return nil end
    if (spec == "LEVELING" or spec == "COMBAT") and Trash() and not O("sndTrash") then return nil end
    if ctx.cp >= ((spec == "COMBAT") and 4 or 2) then return Try("SliceAndDice", true) end
end

local function VenomRule()
    if spec ~= "ASSASSINATION" or Trash() or VenomLeft() > 2 or ctx.cp < 4 then return nil end
    return Try("Venom", true)
end

local function ExposeRule()
    if not O("exposeArmor") or ctx.cp < 5 or ctx.inst ~= "party" then return nil end
    if ctx.kind ~= "elite" and ctx.kind ~= "boss" then return nil end
    -- Slice and Dice tutuluyorsa once o (Subtlety 20'den sonra ve ayar kapaliyken tutulmaz)
    local sndKept = O("snd") and Has("SliceAndDice") and not (spec == "SUBTLETY" and (ns.Call(UnitLevel, "player") or 0) >= 20)
    if DebuffDue("ExposeArmor", 3) and (not sndKept or SndLeft() > 8) then return Try("ExposeArmor", true) end
end

local function RuptureRule()
    if spec == "COMBAT" or spec == "LEVELING" then return nil end   -- Combat Eviscerate'e harcar
    if not O("rupture") or ctx.cp < 5 or Trash() then return nil end
    if CreatureIs("Mechanical", "Elemental") or RuptLeft() > 1 then return nil end
    return Try("Rupture", true)
end

-- Eviscerate esigi: ayar, yoksa 5 (normal mob 4, 20 alti 3)
local function EviscerateAt()
    local custom = O("finisherCP")
    if custom > 0 then return custom end
    if Trash() then return ctx.level < 20 and 3 or 4 end
    return 5
end

local function Finisher()
    return SndRule()
        or VenomRule()
        or RuptureRule()
        or ExposeRule()
        -- PvP: Cheap Shot bitince Kidney Shot ile sersemlik zinciri
        or (ctx.kind == "player" and ctx.cp >= 4 and not ns.Recent("CheapShot", 3) and Try("KidneyShot", true))
        or (ctx.cp >= EviscerateAt() and Try("Eviscerate", true))
end

---------------------------------------------------------------------------
-- Builder'lar
---------------------------------------------------------------------------
local function Build()
    -- 4 CP'de Mutilate (+2) 5'i asar: tek puanlik builder ile tamamla
    if Has("Mutilate") and ctx.cp <= 3 and R.DaggerInHand() then
        local r = Try("Mutilate", true)
        if r then return r end
    end
    if spec == "SUBTLETY" and ctx.cp < 5 then
        local r = Try("GhostlyStrike", true)
        if r then return r end
        if ctx.big and DebuffDue("Hemorrhage", 3) then
            r = Try("Hemorrhage", true)
            if r then return r end
        end
    end
    return (BackstabOk() and Try("Backstab", true))
        or (spec == "SUBTLETY" and Try("Hemorrhage", true))
        or Try("SinisterStrike", true)
end

---------------------------------------------------------------------------
-- AoE: Blade Flurry (Combat) ve coklu cekimde Adrenaline Rush
---------------------------------------------------------------------------
local function AoE()
    if ctx.stealth then return nil end
    return Try("BladeFlurry", true)
        or (ctx.enemies >= 3 and Try("AdrenalineRush", true))
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma, zehir hatirlatici
---------------------------------------------------------------------------
local function Defensive()
    if not ctx.inCombat or not O("defensives") then return nil end
    return (HealthBelow(O("vanish")) and Try("Vanish", true))
        or (HealthBelow(O("evasion")) and Try("Evasion", true))
        or (HealthBelow(O("sprint")) and Try("Sprint", true))
end

-- Silah buyusu bilgisi savasta guvenilmez: sadece savas disinda
local function WeaponNeedsPoison()
    local ok, hasMain, _, _, _, hasOff = pcall(GetWeaponEnchantInfo)
    if not ok or ns.issecret(hasMain) or hasMain == nil then return false end
    if not hasMain then return true end
    return not ns.issecret(hasOff) and hasOff == false and ns.Call(OffhandHasWeapon) == true
end

local function Extra()
    local r = Defensive()
    if r then return r end
    if not ctx.inCombat and O("poison") and Has("Poisons") and WeaponNeedsPoison() then
        return S("Poisons")
    end
end

-- Buyuk cooldown'lar (Cooldowns.lua). cond: bu turun ctx'i
R.cooldowns = {
    { key = "ColdBlood",      default = "big",
      cond = function() return ctx.melee and ctx.cp >= 4 and not ctx.stealth end },
    { key = "BladeFlurry",    default = "elite", cond = function() return ctx.melee and not ctx.stealth end },
    { key = "AdrenalineRush", default = "big",   cond = function() return ctx.melee and not ctx.stealth end },
    -- Vanish / Premeditation'i sifirlar: Vanish beklerken
    { key = "Preparation",    default = "boss",
      cond = function() return Has("Vanish") and not ns.Ready("Vanish") end },
}
R.lowExtras = {}

---------------------------------------------------------------------------
-- Ana ikon
---------------------------------------------------------------------------
local function Main()
    local r = StealthRule()
    if r then return r end

    -- Gizliyken acilis (menzil disindayken de goster: yaklasirken)
    if ctx.stealth and ctx.hasTarget then
        r = Opener()
        if r then return r end
    end

    -- Slice and Dice menzil istemez
    r = SndRule() or VenomRule()
    if r then return r end

    if not ctx.hasTarget or ctx.far then return nil end

    if ctx.aoe and ctx.inCombat then
        r = AoE()
        if r then return r end
    end

    return Try("Riposte", false) or Finisher() or Build()
end

function R.Next()
    ReadContext()
    return Main() or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function R.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AoE() or nil
end

-- /rof debug icin
function R.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | hedef: %s %s"))
        :format(spec, ctx.enemies, ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ctx.kind, tostring(ns.CreatureType())))
    local energy = ns.Energy()
    ns.Print((L("Combo: %d | energy: %s | gizlilik: %s"))
        :format(ctx.cp, energy and tostring(math.floor(energy)) or "gizli", tostring(ctx.stealth)))
    ns.Print((L("Slice and Dice: %.1f sn | Rupture: %.1f sn | Venom: %.1f sn"))
        :format(SndLeft(), RuptLeft(), VenomLeft()))
end
