local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local M = {}
ns.classes.MAGE = M
M.enemyProbe = nil   -- dusman sayimi ~10 yd (Frost Nova / Arcane Explosion menzili)
M.nearProbe  = "FireBlast"   -- savasta ~10 yd yerine Fire Blast menzili (20 yd; CheckInteractDistance savasta kisitli)

-- WoW Forever Mage. Forever notlari (beta verisi):
--   * Arcane: Arcane Blast (yigin 4'e kadar, ilk yigindan 15 sn), Arcane Wrath (16. puan, 6 sn cd),
--     Missile Barrage proc'u (Arcane Missiles yarim sure, bedava).
--   * Fire: Heating Up (3 yigin = hizli Pyroblast), her Fire Blast yigin verir. Improved Scorch 3 ile
--     Scorch Fireball'dan iyi. Combustion 40'ta.
--   * Frost: Ice Lance donmus hedefe x3, Fingers of Frost proc'u. Winter's Chill sadece Cone of Cold'u guclendirir.
--   * Molten Armor ve Dragon's Breath yok. Savasta mana gizli.
M.spells = {
    -- Fire
    Fireball        = { id = 133,     name = "Fireball" },
    FireBlast       = { id = 2136,    name = "Fire Blast" },
    Scorch          = { id = 2948,    name = "Scorch", aura = "Fire Vulnerability", duration = 30, maxStacks = 5 },
    Pyroblast       = { id = 11366,   name = "Pyroblast" },
    Flamestrike     = { id = 2120,    name = "Flamestrike" },
    BlastWave       = { id = 11113,   name = "Blast Wave" },
    Combustion      = { id = 11129,   name = "Combustion" },

    -- Frost
    Frostbolt       = { id = 116,     name = "Frostbolt" },
    IceLance        = { id = 400640,  name = "Ice Lance", once = true },  -- donma / proc ilk Ice Lance ile biter
    FrostNova       = { id = 122,     name = "Frost Nova" },
    ConeOfCold      = { id = 120,     name = "Cone of Cold" },
    Blizzard        = { id = 10,      name = "Blizzard" },
    IceBlock        = { id = 11958,   name = "Ice Block" },
    ColdSnap        = { id = 12472,   name = "Cold Snap" },
    IceBarrier      = { id = 11426,   name = "Ice Barrier", duration = 60, unit = "player" },

    -- Arcane
    ArcaneMissiles  = { id = 5143,    name = "Arcane Missiles" },
    ArcaneBlast     = { id = 400574,  name = "Arcane Blast" },
    ArcaneWrath     = { id = 1326079, name = "Arcane Wrath" },
    ArcaneExplosion = { id = 1449,    name = "Arcane Explosion" },
    PresenceOfMind  = { id = 12043,   name = "Presence of Mind" },
    ArcanePower     = { id = 12042,   name = "Arcane Power" },
    Evocation       = { id = 12051,   name = "Evocation" },
    ManaShield      = { id = 1463,    name = "Mana Shield", duration = 60, unit = "player" },

    -- Buff / zirh (zirhlar birbirini kaldirir)
    ArcaneIntellect  = { id = 1459,   name = "Arcane Intellect",  duration = 3600, unit = "player" },
    ArcaneBrilliance = { id = 23028,  name = "Arcane Brilliance", duration = 3600, unit = "player" },
    FrostArmor       = { id = 168,    name = "Frost Armor", duration = 1800, unit = "player", group = "armor" },
    IceArmor         = { id = 7302,   name = "Ice Armor",   duration = 1800, unit = "player", group = "armor" },
    MageArmor        = { id = 6117,   name = "Mage Armor",  duration = 1800, unit = "player", group = "armor" },

    Shoot            = { id = 5019,   name = "Shoot" },   -- asa (wand)
    Counterspell     = { id = 2139,   name = "Counterspell" },
}
M.interrupts = { "Counterspell" }

M.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "buffs", default = true, label = "Arcane Intellect / zirh hatirlatici" },
    { type = "toggle", key = "scorch", default = true, label = "Scorch yigini (Fire, Improved Scorch 3)",
      tip = "Boss / elit hedefte Fire Vulnerability'yi 5 yiginda tutar." },
    { type = "slider", key = "abStacks", default = 2, min = 1, max = 4, step = 1,
      label = "Arcane Blast yigini (Arcane)", tip = "Arcane Wrath / Missiles oncesi kac Arcane Blast." },
    { type = "toggle", key = "wand", default = true, label = "Mana bitince asa (Shoot)" },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Ustune yigilmis dusmanlar (~10 yd). Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },

    { type = "header", label = "Mana" },
    { type = "toggle", key = "evocation", default = true, label = "Mana bitince Evocation" },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "iceBlock",   default = 20, min = 0, max = 90, step = 5, zero = "Kapali", label = "Ice Block" },
    { type = "slider", key = "iceBarrier", default = 70, min = 0, max = 100, step = 5, zero = "Kapali", label = "Ice Barrier" },
    { type = "slider", key = "manaShield", default = 50, min = 0, max = 90, step = 5, zero = "Kapali", label = "Mana Shield (mob ustundeyken)" },
    { type = "slider", key = "frostNova",  default = 90, min = 0, max = 100, step = 5, zero = "Kapali",
      label = "Frost Nova (mob ustundeyken)", tip = "Tek basina ve can bunun altindayken: kok sal, uzaklas." },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local BuffUp = ns.BuffUp

local SPECS = { "ARCANE", "FIRE", "FROST" }
local spec, impScorch, wintersChill = "LEVELING", 0, 0
function M.OnRefresh()
    spec = SPECS[ns.MainTalentTab()] or "LEVELING"
    impScorch    = ns.TalentRank("Improved Scorch")
    wintersChill = ns.TalentRank("Winter's Chill")
end

---------------------------------------------------------------------------
-- Kendi atislarimizdan takip (savasta aura verisi gizli)
---------------------------------------------------------------------------
-- Presence of Mind: atildiktan sonra ilk cast sureli buyuye kadar acik
local CASTTIME = { Fireball = true, Frostbolt = true, Pyroblast = true, ArcaneBlast = true,
                   ArcaneWrath = true, Scorch = true, Flamestrike = true }
local pomAt = 0
-- Arcane Blast yigini: ilk yigindan 15 sn surer, sonrakiler sureyi yenilemez
local abFirst, abCount = 0, 0
-- Frost Nova hedefi dondurdu mu (hedef yakindayken atildiysa, ilk Ice Lance'e kadar)
local novaAt = 0

function M.OnCast(key)
    local now = GetTime()
    if key == "PresenceOfMind" then pomAt = now
    elseif CASTTIME[key] then pomAt = 0 end

    if key == "ArcaneBlast" then
        if now - abFirst > 15 then abFirst, abCount = now, 1
        else abCount = math.min(abCount + 1, 4) end
    elseif key == "FrostNova" then
        if ns.Near("target") == true then novaAt = now end   -- yalniz gercekten ustundeyken donmus say
    elseif key == "IceLance" then
        novaAt = 0
    end
end

local novaEv = CreateFrame("Frame")
pcall(novaEv.RegisterEvent, novaEv, "PLAYER_TARGET_CHANGED")
novaEv:SetScript("OnEvent", function() novaAt = 0 end)

local function PoMActive() return pomAt > 0 and GetTime() - pomAt < 30 end
local function ABStacks() return (GetTime() - abFirst < 15) and abCount or 0 end
local function Frozen() return GetTime() - novaAt < 8 end

---------------------------------------------------------------------------
-- Durum
---------------------------------------------------------------------------
local ctx = {}

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    ctx.near     = ns.Near("target") == true   -- ~10 yd: ustunde (savasta nearProbe menzili)
    ctx.health   = ns.HealthPercent()
    ctx.enemies  = ns.EnemiesNearby() or 0
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and ctx.enemies >= O("aoeAt")
    -- Mana: savas disinda gercek, savasta "dolgu buyusune yetiyor mu"
    local mana   = ns.ManaPercent()
    -- ikisi de pahaliysa: Frostbolt hala atilabiliyorken Evocation / asa onerilmesin
    ctx.oom      = (mana and mana < 5) or (ns.NoPower("Frostbolt") and ns.NoPower("Fireball"))
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

---------------------------------------------------------------------------
-- Hatirlaticilar
---------------------------------------------------------------------------
local function ArmorUp()
    return BuffUp("FrostArmor") or BuffUp("IceArmor") or BuffUp("MageArmor")
end

local function Buffs()
    if not O("buffs") or ctx.inCombat then return nil end
    if ns.AuraRemaining("player", "ArcaneIntellect", "HELPFUL") < 60
       and ns.AuraRemaining("player", "ArcaneBrilliance", "HELPFUL") < 60 then
        local r = (ctx.group and Try("ArcaneBrilliance", true)) or Try("ArcaneIntellect", true)
        if r then return r end
    end
    if not ArmorUp() then
        -- Uzun dovuslerde (grup / zindan) Mage Armor'in mana yenilemesi
        return (ctx.group and Try("MageArmor", true)) or Try("IceArmor", true) or Try("FrostArmor", true)
    end
    -- Frost: savas oncesi kalkan
    if spec == "FROST" and UnitExists("target") and not BuffUp("IceBarrier") then
        return Try("IceBarrier", true)
    end
end

---------------------------------------------------------------------------
-- AoE (dusmanlar ustune yigilmisken)
---------------------------------------------------------------------------
local function AoE()
    return (ctx.near and not ctx.group and Try("FrostNova", true))
        or (spec == "FIRE" and Try("BlastWave", true))
        or (ctx.near and Try("ArcaneExplosion", true))
        or (ctx.near and Try("ConeOfCold", true))
        or (ctx.enemies >= 4 and Try("Blizzard", true))
        or (not ns.Recent("Flamestrike", 8) and Try("Flamestrike", true))
end

---------------------------------------------------------------------------
-- Spec oncelikleri
---------------------------------------------------------------------------
local function Leveling()
    -- Fire Blast kisa menzilli: uzaktan acilista Fireball / Frostbolt'a dusulur
    return (ns.InRange("FireBlast") ~= false and Try("FireBlast", true))
        -- 8-9: Arcane Missiles dusuk rank Frostbolt'u gecer (savasta mana gizli: bilinmiyorsa izin ver)
        or ((ns.ManaPercent() or 100) >= 40 and Try("ArcaneMissiles", true))
        or Try("Frostbolt", true)
        or Try("Fireball", true)
end

local function Arcane()
    if PoMActive() then
        local r = Try("ArcaneWrath", true) or Try("Pyroblast", true) or Try("ArcaneBlast", true)
        if r then return r end
    end
    return (ns.Proc("ArcaneMissiles") and Try("ArcaneMissiles", true))   -- Missile Barrage
        or (ABStacks() < O("abStacks") and not ns.NoPower("ArcaneBlast") and Try("ArcaneBlast", true))
        or Try("ArcaneWrath", true)
        or (ABStacks() >= 1 and Try("ArcaneMissiles", true))
        or (ns.InRange("FireBlast") == true and Try("FireBlast", true))
        or Try("Frostbolt", true)
        or Try("Fireball", true)
        or Try("ArcaneMissiles", true)
end

-- Fire Vulnerability: 5 yigin, bitmesine 6 sn kala yenile
local function ScorchNeeded()
    if not O("scorch") or impScorch < 3 then return false end
    if not (ctx.kind == "boss" or ctx.kind == "elite") then return false end
    return ns.Stacks("Scorch") < 5
        or ns.AuraRemaining("target", "Scorch", "HARMFUL") <= 6
end

local function Fire()
    if PoMActive() then
        local r = Try("Pyroblast", true)
        if r then return r end
    end
    return (ns.Proc("Pyroblast") and Try("Pyroblast", true))   -- Heating Up x3
        or (not ctx.inCombat and Try("Pyroblast", true))        -- acilis
        or (ScorchNeeded() and Try("Scorch", true))
        or (ns.InRange("FireBlast") == true and Try("FireBlast", true))
        or (impScorch >= 3 and Try("Scorch", true))
        or Try("Fireball", true)
        or Try("Frostbolt", true)
end

local function Frost()
    if PoMActive() then
        local r = Try("Frostbolt", true)
        if r then return r end
    end
    return (ns.Proc("IceLance") and Try("IceLance", true))     -- Fingers of Frost
        or (Frozen() and Try("IceLance", true))
        or (wintersChill >= 3 and ctx.near and Try("ConeOfCold", true))
        -- anlik Fire Blast menzildeyse Frostbolt'tan once (Frostbolt hep atilabildigi icin sonda hic gelmiyordu)
        or (ns.InRange("FireBlast") == true and Try("FireBlast", true))
        or Try("Frostbolt", true)
end

local SINGLE = { LEVELING = Leveling, ARCANE = Arcane, FIRE = Fire, FROST = Frost }

local function Main()
    local r = Buffs()
    if r then return r end
    if ctx.aoe and ctx.inCombat then
        r = AoE()
        if r then return r end
    end
    r = SINGLE[spec]()
    if r then return r end
    -- Mana bitti: asa
    if O("wand") and ctx.oom and Has("Shoot") and ns.Usable("Shoot", true) and not ns.AutoRepeat("Shoot") then
        return S("Shoot")
    end
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma, mana, burst cooldown'lari
---------------------------------------------------------------------------
local function Defensive()
    if not O("defensives") or not ctx.inCombat then return nil end
    return (HealthBelow(O("iceBlock")) and Try("IceBlock", true))
        -- Cold Snap: Ice Block bilinip cooldown'daysa (ayar Kapali ise hic)
        or (O("iceBlock") > 0 and Has("IceBlock") and HealthBelow(O("iceBlock") + 5)
            and not ns.Ready("IceBlock") and Try("ColdSnap", true))
        or (HealthBelow(O("iceBarrier")) and not BuffUp("IceBarrier") and Try("IceBarrier", true))
        or (ctx.near and not ctx.group and HealthBelow(O("frostNova")) and Try("FrostNova", true))
        or (ctx.near and HealthBelow(O("manaShield")) and not BuffUp("IceBarrier")
            and not BuffUp("ManaShield") and Try("ManaShield", true))
end

local function Extra()
    local r = Defensive()
    if r then return r end
    if not ctx.inCombat then return nil end

    if O("evocation") and ctx.oom then
        r = Try("Evocation", true)
        if r then return r end
    end

    -- Buyuk cooldown'lar Cooldowns.lua'da (M.cooldowns)
end

-- Buyuk cooldown'lar (Cooldowns.lua): default kullanim modu
M.cooldowns = {
    { key = "ArcanePower",    default = "big" },
    { key = "Combustion",     default = "big" },
    { key = "PresenceOfMind", default = "big" },
}
M.lowExtras = {}

function M.Next()
    ReadContext()
    return Main() or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function M.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AoE() or nil
end

function M.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | mana: %s | AB yigini: %d | donmus: %s"))
        :format(spec, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ns.ManaPercent() and ("%%%d"):format(math.floor(ns.ManaPercent())) or "gizli",
                ABStacks(), tostring(Frozen())))
end
