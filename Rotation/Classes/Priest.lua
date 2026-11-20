local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local P = {}
ns.classes.PRIEST = P
P.enemyProbe = nil   -- dusman sayimi ~10 yd (Holy Nova / Psychic Scream menzili)
P.nearProbe  = "MindFlay"   -- savasta ~10 yd yerine Mind Flay menzili (20 yd; Shadow talenti, yoksa CheckInteractDistance)

-- WoW Forever Priest. Forever notlari (beta verisi):
--   * Divine Spirit 30'da, Devouring Plague ve Fear Ward 20'de temel. Devouring Plague cd 24 sn.
--   * Shadow Word: Death yeni temel yetenek (32): 18 sn cd, hedef olmezse %10 can geri tepmesi.
--   * Penance = Discipline talenti (12 sn cd, hasar / iyilestirme). Vampiric Embrace = Shadow talenti (30 sn cd).
--   * Shadowform = Shadow 31 puan; formdayken Holy buyuleri (iyilestirme) kilitli, PW:S / buff'lar acik.
--   * Irk buyuleri (10 / 20. seviye gorevi): Desperate Prayer (Dwarf), Starshards (Night Elf), Chastise (Dwarf),
--     Touch of Weakness (Undead), Hex of Weakness (Troll), Shadowguard (Troll), Elune's Grace (Night Elf).
--   * Asa (Shoot) hala dolgu; mana savasta gizli.
-- SINIRLAMA (Discipline / Holy): baska birimlerin cani savasta gizli. Grupta can esigine bagli
-- iyilestirme ONERILMEZ. Bu spec'ler solo hasar rotasyonu + kendine bakim (PW:S, Renew, Flash Heal)
-- + savas disi buff'lar (Fortitude, Inner Fire, Divine Spirit) onerir.
P.spells = {
    -- Hasar
    Smite           = { id = 585,     name = "Smite" },
    HolyFire        = { id = 14914,   name = "Holy Fire", duration = 10 },
    MindBlast       = { id = 8092,    name = "Mind Blast" },
    MindFlay        = { id = 15407,   name = "Mind Flay" },
    ShadowWordPain  = { id = 589,     name = "Shadow Word: Pain", duration = 18 },   -- OnRefresh: +3 sn / Improved SW:P
    DevouringPlague = { id = 2944,    name = "Devouring Plague", duration = 24 },
    ShadowWordDeath = { id = 1309595, name = "Shadow Word: Death" },
    VampiricEmbrace = { id = 15286,   name = "Vampiric Embrace", duration = 30 },
    Penance         = { id = 402174,  name = "Penance" },
    HolyNova        = { id = 15237,   name = "Holy Nova" },
    Shoot           = { id = 5019,    name = "Shoot" },   -- asa (wand)

    -- Irk hasar buyuleri
    Starshards      = { id = 10797,   name = "Starshards", duration = 6 },
    Chastise        = { id = 1277331, name = "Chastise" },
    HexOfWeakness   = { id = 9035,    name = "Hex of Weakness", duration = 120 },

    -- Kendine bakim / savunma
    PowerWordShield = { id = 17,      name = "Power Word: Shield", duration = 30, unit = "player" },
    Renew           = { id = 139,     name = "Renew", duration = 15, unit = "player" },
    FlashHeal       = { id = 2061,    name = "Flash Heal" },
    LesserHeal      = { id = 2050,    name = "Lesser Heal" },
    DesperatePrayer = { id = 13908,   name = "Desperate Prayer" },
    Fade            = { id = 586,     name = "Fade" },
    PsychicScream   = { id = 8122,    name = "Psychic Scream" },
    ElunesGrace     = { id = 2651,    name = "Elune's Grace", duration = 15, unit = "player" },

    -- Form / buff
    Shadowform      = { id = 15473,   name = "Shadowform", stance = true },
    PowerWordFortitude  = { id = 1243,  name = "Power Word: Fortitude",  duration = 3600, unit = "player" },
    PrayerOfFortitude   = { id = 21562, name = "Prayer of Fortitude",    duration = 3600, unit = "player" },
    InnerFire       = { id = 588,     name = "Inner Fire", duration = 600, unit = "player" },
    DivineSpirit    = { id = 14752,   name = "Divine Spirit",    duration = 3600, unit = "player" },
    PrayerOfSpirit  = { id = 27681,   name = "Prayer of Spirit", duration = 3600, unit = "player" },
    TouchOfWeakness = { id = 2652,    name = "Touch of Weakness", duration = 600, unit = "player" },
    Shadowguard     = { id = 18137,   name = "Shadowguard",       duration = 600, unit = "player" },

    -- Cooldown / kesme
    PowerInfusion   = { id = 10060,   name = "Power Infusion" },
    InnerFocus      = { id = 14751,   name = "Inner Focus" },
    Silence         = { id = 15487,   name = "Silence" },
}
P.interrupts = { "Silence" }

P.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "buffs", default = true, label = "Buff hatirlaticilari",
      tip = "Power Word: Fortitude, Inner Fire, Divine Spirit, Shadowform (savas disi)." },
    { type = "toggle", key = "dots", default = true, label = "Shadow Word: Pain / Devouring Plague" },
    { type = "toggle", key = "embrace", default = true, label = "Vampiric Embrace",
      tip = "Grupta ve zor hedefte; tek basina sadece cani dusukken." },
    { type = "slider", key = "swdHp", default = 40, min = 10, max = 80, step = 5, zero = "Kapali",
      label = "Shadow Word: Death icin can %", tip = "Hedef olmezse %10 can kaybettirir: canin bunun ustundeyken onerilir." },
    { type = "toggle", key = "wand", default = true, label = "Mana bitince asa (Shoot)" },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Ustune yigilmis dusmanlar (~10 yd). Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "shield",   default = 70, min = 0, max = 100, step = 5, zero = "Kapali", label = "Power Word: Shield" },
    { type = "slider", key = "renew",    default = 60, min = 0, max = 100, step = 5, zero = "Kapali", label = "Renew (kendine)" },
    { type = "slider", key = "flash",    default = 35, min = 0, max = 90,  step = 5, zero = "Kapali", label = "Flash Heal (kendine)" },
    { type = "slider", key = "desperate", default = 30, min = 0, max = 90, step = 5, zero = "Kapali", label = "Desperate Prayer" },
    { type = "slider", key = "scream",   default = 40, min = 0, max = 90, step = 5, zero = "Kapali",
      label = "Psychic Scream (tek basina, 3+ dusman)" },
    { type = "toggle", key = "fade", default = true, label = "Fade (grupta, can dusukken)" },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local DebuffDue = ns.DebuffDue
local BuffUp = ns.BuffUp

local Recent = ns.Recent

local SPECS = { "DISC", "HOLY", "SHADOW" }
local spec, impPain = "LEVELING", 0
function P.OnRefresh()
    spec = SPECS[ns.MainTalentTab()] or "LEVELING"
    impPain = ns.TalentRank("Improved Shadow Word: Pain")
    -- Improved Shadow Word: Pain: +3 sn / puan (Core bu sureyi atistan takip eder)
    if P.spells.ShadowWordPain then P.spells.ShadowWordPain.duration = 18 + 3 * impPain end
end

---------------------------------------------------------------------------
-- Durum
---------------------------------------------------------------------------
local ctx = {}

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    ctx.health   = ns.HealthPercent()
    ctx.enemies  = ns.EnemiesNearby() or 0
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and ctx.enemies >= O("aoeAt")
    ctx.form     = ns.ActiveForm()   -- guncelleme basina bir kez
    -- Mana: savas disinda gercek, savasta "dolgu buyusune yetiyor mu"
    local mana   = ns.ManaPercent()
    ctx.oom      = (mana and mana < 5) or ns.NoPower("Smite") or ns.NoPower("MindBlast")
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

-- Form ID'si buyu kitabindaki ID'den farkli olabilir: adla da karsilastir
local function InShadowform()
    local s, cur = S("Shadowform"), ctx.form
    if not s or not cur then return false end
    return cur == s.id or ns.Call(C_Spell.GetSpellName, cur) == s.name
end

-- Shadowform'da Holy buyuleri (Flash Heal, Renew...) kilitli
local function CanHeal() return not InShadowform() end

-- Weakened Soul (15 sn) aura verisi gizli: kendi atisimiz + kalkan buff'i ile tahmin
local function ShieldFree()
    return not BuffUp("PowerWordShield") and not Recent("PowerWordShield", 15)
end

---------------------------------------------------------------------------
-- Hatirlaticilar (savas disi)
---------------------------------------------------------------------------
local function Buffs()
    if not O("buffs") or ctx.inCombat then return nil end
    -- Form "yok" ile "okunamadi" ikisi de nil doner: savas disinda aura da okunur, ikisi de
    -- yok diyorsa oner (yoksa Shadowform'u acikken kapatan bir oneri olurdu)
    if spec == "SHADOW" and Has("Shadowform") and not InShadowform()
       and ns.AuraRemaining("player", "Shadowform", "HELPFUL") <= 0 then
        local r = Try("Shadowform", true)
        if r then return r end
    end
    if ns.AuraRemaining("player", "PowerWordFortitude", "HELPFUL") < 60
       and ns.AuraRemaining("player", "PrayerOfFortitude", "HELPFUL") < 60 then
        local r = (ctx.group and Try("PrayerOfFortitude", true)) or Try("PowerWordFortitude", true)
        if r then return r end
    end
    if ns.AuraRemaining("player", "InnerFire", "HELPFUL") < 30 then
        local r = Try("InnerFire", true)
        if r then return r end
    end
    if ns.AuraRemaining("player", "DivineSpirit", "HELPFUL") < 60
       and ns.AuraRemaining("player", "PrayerOfSpirit", "HELPFUL") < 60 then
        local r = (ctx.group and Try("PrayerOfSpirit", true)) or Try("DivineSpirit", true)
        if r then return r end
    end
    if ns.AuraRemaining("player", "TouchOfWeakness", "HELPFUL") < 30 then
        local r = Try("TouchOfWeakness", true)
        if r then return r end
    end
    if ns.AuraRemaining("player", "Shadowguard", "HELPFUL") < 30 then
        return Try("Shadowguard", true)
    end
end

---------------------------------------------------------------------------
-- AoE (dusmanlar ustune yigilmisken)
---------------------------------------------------------------------------
local function AoE()
    -- Holy Nova: Holy buyusu, Shadowform'da kilitli; grupta pack'i cekmemek icin sadece tek basina
    return (not ctx.group and CanHeal() and not ns.NoPower("HolyNova") and Try("HolyNova", true))
        or (O("dots") and DebuffDue("ShadowWordPain", 1.5) and Try("ShadowWordPain", true))
end

---------------------------------------------------------------------------
-- Ortak parcalar
---------------------------------------------------------------------------
local function Dots()
    if not O("dots") then return nil end
    return (DebuffDue("ShadowWordPain", 1.5) and Try("ShadowWordPain", true))
end

local function Racials()
    return Try("Starshards", true)
        or (ns.CreatureType() == "Humanoid" and Try("Chastise", true))
        or (ctx.big and DebuffDue("HexOfWeakness", 2) and Try("HexOfWeakness", true))
end

-- Shadow Word: Death: hedef hayattaysa geri tepme; yeterli can varsa
local function Death()
    if O("swdHp") <= 0 or ctx.health == nil or ctx.health < O("swdHp") then return nil end
    return Try("ShadowWordDeath", true)
end

---------------------------------------------------------------------------
-- Spec oncelikleri
---------------------------------------------------------------------------
-- 1-9 ve talentsiz: SW:P, Mind Blast, Smite
local function Leveling()
    return Dots()
        or Try("MindBlast", true)
        or (DebuffDue("HolyFire", 0) and Try("HolyFire", true))
        or Racials()
        or Try("Smite", true)
end

-- Disc / Holy: solo hasar + kendine bakim. Grupta can gizli: iyilestirme onerilmez.
local function Healer()
    return (DebuffDue("HolyFire", 0) and Try("HolyFire", true))
        or Try("MindBlast", true)
        or Dots()
        or (spec == "DISC" and Try("Penance", true))
        or Racials()
        or (not ctx.group and ctx.kind ~= "normal" and DebuffDue("DevouringPlague", 0) and Try("DevouringPlague", true))
        or Death()
        or Try("Smite", true)
end

local function Shadow()
    return (O("embrace") and (ctx.group or ctx.kind ~= "normal" or HealthBelow(60))
            and DebuffDue("VampiricEmbrace", 0) and Try("VampiricEmbrace", true))
        or Dots()
        or Try("MindBlast", true)
        or (O("dots") and (ctx.big or not Has("MindFlay")) and DebuffDue("DevouringPlague", 0)
            and Try("DevouringPlague", true))
        or Death()   -- 32'den itibaren temel buyu: Shadowform (40) beklenmez
        or Racials()
        or Try("MindFlay", true)
        or Try("Smite", true)
end

local SINGLE = { LEVELING = Leveling, DISC = Healer, HOLY = Healer, SHADOW = Shadow }

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
-- Kucuk ikon: savunma, kendine bakim, burst cooldown'lari
---------------------------------------------------------------------------
local function Defensive()
    if not O("defensives") or not ctx.inCombat then return nil end
    return (HealthBelow(O("desperate")) and Try("DesperatePrayer", true))
        or (HealthBelow(O("shield")) and ShieldFree() and Try("PowerWordShield", true))
        or (CanHeal() and HealthBelow(O("flash")) and (Try("FlashHeal", true) or Try("LesserHeal", true)))
        or (CanHeal() and HealthBelow(O("renew")) and not BuffUp("Renew") and Try("Renew", true))
        or (O("fade") and ctx.group and HealthBelow(80) and Try("Fade", true))
        or (not ctx.group and ctx.enemies >= 3 and HealthBelow(O("scream")) and Try("PsychicScream", true))
        or (HealthBelow(50) and not BuffUp("ElunesGrace") and Try("ElunesGrace", true))
end

local function Extra()
    local r = Defensive()
    if r then return r end
    if not ctx.inCombat then return nil end
    -- Buyuk cooldown'lar Cooldowns.lua'da (P.cooldowns)
end

-- Buyuk cooldown'lar (Cooldowns.lua): default kullanim modu
P.cooldowns = {
    { key = "PowerInfusion", default = "elite", cond = function() return ctx.inCombat end },
    { key = "InnerFocus",    default = "big",
      cond = function() return ctx.inCombat and spec == "SHADOW" and ns.Ready("MindBlast") end },
}
P.lowExtras = {}

function P.Next()
    ReadContext()
    return Main() or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function P.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AoE() or nil
end

function P.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | mana: %s | Shadowform: %s | kalkan serbest: %s"))
        :format(spec, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ns.ManaPercent() and ("%%%d"):format(math.floor(ns.ManaPercent())) or "gizli",
                tostring(InShadowform()), tostring(ShieldFree())))
end
