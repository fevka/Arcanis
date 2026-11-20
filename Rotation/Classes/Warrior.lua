local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local W = {}
ns.classes.WARRIOR = W
W.enemyProbe = "HeroicStrike"   -- dusman sayimi yakin dovus menzilinde

-- WoW Forever Warrior. id: rank 1 ID (Core ID'den yerel adi, oradan en yuksek
-- rank'i bulur; bu yuzden her dilde calisir). name sadece yedek ve debug icin.
-- duration: atinca takip edilen aura suresi (savasta aura verisi gizli).
-- Forever'a ozel ID'ler (Victory Rush, Spearing Strike, Tactical Mastery) beta verisinden.
W.spells = {
    -- Duruslar
    BattleStance    = { id = 2457,    name = "Battle Stance", stance = true },
    DefensiveStance = { id = 71,      name = "Defensive Stance", stance = true },
    BerserkerStance = { id = 2458,    name = "Berserker Stance", stance = true },
    TacticalMastery = { id = 1310185, name = "Tactical Mastery" },  -- 14'te pasif, durus degisince 10 rage kalir

    -- Ana ikon (GCD'li)
    Charge            = { id = 100,     name = "Charge" },
    BattleShout       = { id = 6673,    name = "Battle Shout", duration = 180, unit = "player" },
    VictoryRush       = { id = 402927,  name = "Victory Rush" },
    Execute           = { id = 5308,    name = "Execute" },
    Overpower         = { id = 7384,    name = "Overpower" },
    Revenge           = { id = 6572,    name = "Revenge" },
    Rend              = { id = 772,     name = "Rend", duration = 21,
                          durationByRank = { [772] = 9, [6546] = 12, [6547] = 15, [6548] = 18,
                                             [11572] = 21, [11573] = 21, [11574] = 21 } },
    MortalStrike      = { id = 12294,   name = "Mortal Strike" },
    SpearingStrike    = { id = 1310222, name = "Spearing Strike" },
    Slam              = { id = 1464,    name = "Slam" },
    Bloodthirst       = { id = 23881,   name = "Bloodthirst" },
    Whirlwind         = { id = 1680,    name = "Whirlwind" },
    SweepingStrikes   = { id = 12292,   name = "Sweeping Strikes" },
    ShieldSlam        = { id = 23922,   name = "Shield Slam" },
    ThunderClap       = { id = 6343,    name = "Thunder Clap", duration = 30, area = true,
                          durationByRank = { [6343] = 10, [8198] = 14, [8204] = 18, [8205] = 22,
                                             [11580] = 26, [11581] = 30 } },
    SunderArmor       = { id = 7386,    name = "Sunder Armor", duration = 30, maxStacks = 5 },
    DemoShout         = { id = 1160,    name = "Demoralizing Shout", duration = 45, area = true },
    IntimidatingShout = { id = 5246,    name = "Intimidating Shout" },

    -- Kucuk ikon (GCD disi / cooldown / savunma)
    HeroicStrike   = { id = 78,      name = "Heroic Strike" },
    Cleave         = { id = 845,     name = "Cleave" },
    ShieldBlock    = { id = 2565,    name = "Shield Block" },
    Bloodrage      = { id = 2687,    name = "Bloodrage" },
    BerserkerRage  = { id = 18499,   name = "Berserker Rage" },
    DeathWish      = { id = 12328,   name = "Death Wish" },
    Recklessness   = { id = 1719,    name = "Recklessness" },
    LastStand      = { id = 12975,   name = "Last Stand" },
    ShieldWall     = { id = 871,     name = "Shield Wall" },
    Retaliation    = { id = 20230,   name = "Retaliation" },

    -- Interrupt (Pummel: Berserker Stance, Shield Bash: kalkan + Battle / Defensive)
    Pummel         = { id = 6552,    name = "Pummel" },
    ShieldBash     = { id = 72,      name = "Shield Bash" },
}
W.interrupts = { "Pummel", "ShieldBash" }

-- Heroic Strike / Cleave otomatik esigi = bosaltma yeteneginin maliyeti + spec'in
-- ana yeteneklerine ayrilan rage. Maliyetler oyundan okunur (talent indirimleri
-- dahil); okunamazsa buradaki temel degerler kullanilir.
W.reserve = {
    LEVELING = { "Rend", "Overpower" },
    ARMS     = { "MortalStrike", "Overpower" },
    FURY     = { "Bloodthirst", "Whirlwind" },
    PROT     = { "ShieldSlam", "Revenge" },
}
W.mainStrike = { ARMS = "MortalStrike", FURY = "Bloodthirst", PROT = "ShieldSlam" }
local BASE_COST = {
    HeroicStrike = 15, Cleave = 20, MortalStrike = 30, Bloodthirst = 30, ShieldSlam = 20,
    Whirlwind = 25, Overpower = 5, Revenge = 5, Rend = 10,
}

-- Ayarlar paneli bu listeden kurulur; degerler ns.cdb[key] icinde saklanir.
W.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "stance", default = true, label = "Durus onerisi",
      tip = "Arms Battle, Fury Berserker, Prot Defensive Stance. Savasta sadece Tactical Mastery varsa." },
    { type = "toggle", key = "charge", default = true, label = "Savas disinda Charge" },
    { type = "toggle", key = "shout",  default = true, label = "Battle Shout hatirlatici" },
    { type = "toggle", key = "rend",   default = true, label = "Rend",
      tip = "Mechanical / Elemental hedeflerde ve Execute fazinda zaten onerilmez." },
    { type = "slider", key = "sunderStacks", default = 5, min = 1, max = 5, step = 1,
      label = "Sunder Armor yigini (Prot, elit / grup)", tip = "Normal mob'larda tek basina 2 yigin." },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 2, min = 2, max = 6, step = 1,
      label = "AoE icin dusman sayisi" },

    { type = "header", label = "Rage" },
    { type = "slider", key = "hsRage", default = 0, min = 0, max = 100, step = 5, zero = "Otomatik",
      label = "Heroic Strike / Cleave rage esigi",
      tip = "Otomatik: Heroic Strike / Cleave maliyeti + ana yeteneklerin maliyeti (Arms: Mortal Strike + Overpower, Fury: Bloodthirst + Whirlwind, Prot: Shield Slam + Revenge). Maliyetler oyundan okunur, talent indirimleri dahil. /rof debug hesaplanan degeri gosterir." },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "lastStand",   default = 30, min = 0, max = 90, step = 5, zero = "Kapali", label = "Last Stand" },
    { type = "slider", key = "shieldWall",  default = 25, min = 0, max = 90, step = 5, zero = "Kapali", label = "Shield Wall" },
    { type = "slider", key = "retaliation", default = 60, min = 0, max = 90, step = 5, zero = "Kapali", label = "Retaliation (3+ dusman)" },
    { type = "slider", key = "intimShout",  default = 35, min = 0, max = 90, step = 5, zero = "Kapali", label = "Intimidating Shout (3+ dusman, yalniz)" },
    { type = "slider", key = "victoryRush", default = 90, min = 0, max = 100, step = 5, zero = "Kapali",
      label = "Victory Rush'i en one al", tip = "Canin bunun altindayken Victory Rush her seyden once gelir." },
}

local function O(key) return ns.cdb[key] end

local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local DebuffDue = ns.DebuffDue

local improvedSlam, goreDrinker = 0, false
function W.OnRefresh()
    improvedSlam = ns.TalentRank("Improved Slam")
    goreDrinker = ns.TalentRank("Gore Drinker") > 0
end

---------------------------------------------------------------------------
-- Durum (her guncellemede bir kez okunur)
---------------------------------------------------------------------------
local ctx = {}

local function Spec()
    if Has("ShieldSlam")  then return "PROT" end
    if Has("Bloodthirst") then return "FURY" end
    return "ARMS"   -- leveling dahil
end

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.spec     = Spec()
    ctx.form     = ns.ActiveForm()   -- guncelleme basina bir kez
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    ctx.melee    = ns.InRange("HeroicStrike") == true
    ctx.health   = ns.HealthPercent()                 -- nil: bilinmiyor
    local n = ns.EnemiesNearby() or 0
    if ctx.melee and n < 1 then n = 1 end
    ctx.enemies  = n
    -- aoeForce = "single": ana ikon tek hedef kalsin (AoE ayri ikonda ya da kapali)
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and n >= O("aoeAt")
    -- Cleave (kucuk ikon) AoE gosterim modundan bagimsiz: dusman sayisina bakar
    ctx.many     = O("aoe") and n >= O("aoeAt")
    ctx.leveling = not (Has("MortalStrike") or Has("Bloodthirst") or Has("ShieldSlam"))
end

-- p: ayardaki esik (0 = kapali)
local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

local CreatureIs = ns.CreatureIs

-- Form ID'si buyu kitabindaki ID'den farkli olabilir (rank / takma ID): adla da karsilastir
local function InStance(key)
    local s, cur = S(key), ctx.form
    if not s or not cur then return false end
    return cur == s.id or ns.Call(C_Spell.GetSpellName, cur) == s.name
end

-- Hedef cani savasta gizli. Execute'un kullanilabilir olmasi "%20 alti" demek;
-- olmek uzere olan hedefe ve kanamayan yaratiklara Rend atma.
local function RendRule()
    if not O("rend") then return nil end
    if ns.Usable("Execute", false) or CreatureIs("Mechanical", "Elemental") then return nil end
    if DebuffDue("Rend", 2) then return Try("Rend", true) end
end

local function Cost(key)
    if not Has(key) then return 0 end
    return ns.SpellCost(key, Enum.PowerType.Rage) or BASE_COST[key] or 0
end

local function ReserveKeys()
    return W.reserve[ctx.leveling and "LEVELING" or ctx.spec]
end

-- Otomatik esik: bosaltma maliyeti + ayrilan rage (bilinen yetenekler)
local function AutoThreshold(dump)
    local sum = Cost(dump)
    for _, k in ipairs(ReserveKeys()) do sum = sum + Cost(k) end
    return sum
end

function W.HSThreshold(dump)
    local custom = O("hsRage")
    if custom > 0 then return custom end
    return AutoThreshold(dump or "HeroicStrike")
end

-- Rage yeterince fazla mi? Savas disinda gercek rage esikle karsilastirilir.
-- Savasta rage gizli: ayrilan yeteneklerin en pahalisi hala karsilanabiliyor
-- (IsSpellUsable gizli degil) VE ana vurus cooldown'da ise bosalt; ana vurus
-- hazirsa rage ona kalsin (zaten ana ikonda o oneriliyor).
local function SpareRage(threshold)
    local rage = ns.Rage()
    if rage then return rage >= threshold end
    -- ana ikon rage'li bir yetenek gosteriyor: rage ona kalsin (gizliyken ikisine yetip yetmedigi bilinmez)
    if ctx.mainRage then return false end

    local guard, guardCost
    for _, k in ipairs(ReserveKeys()) do
        local c = Cost(k)
        if Has(k) and (not guardCost or c > guardCost) then guard, guardCost = k, c end
    end
    if guard and not ns.Usable(guard, false) then return false end

    local main = not ctx.leveling and W.mainStrike[ctx.spec]
    if main and Has(main) and ns.Ready(main) then return false end
    return guard ~= nil or ns.Usable("HeroicStrike", false)
end

---------------------------------------------------------------------------
-- Durus
---------------------------------------------------------------------------
local function WantedStance()
    if ctx.spec == "PROT" then return "DefensiveStance" end
    -- Fury savas disinda Charge icin Battle'da, savasta Whirlwind (36) varsa Berserker'de
    if ctx.spec == "FURY" and ctx.inCombat and Has("Whirlwind") then return "BerserkerStance" end
    return "BattleStance"
end

-- Savasta Tactical Mastery yoksa durus degistirmek tum rage'i yakar
local function CanSwap()
    return not ctx.inCombat or Has("TacticalMastery")
end

local function StanceRule()
    if not O("stance") then return nil end
    local want = WantedStance()
    if not Has(want) or ctx.form == nil or InStance(want) then return nil end
    if CanSwap() then return Try(want, true) end
end

-- Whirlwind Berserker Stance ister: cooldown'u hazir ve rage yetiyorsa gec
local function WhirlwindDance()
    if not O("stance") or ctx.form == nil or not Has("Whirlwind") or InStance("BerserkerStance") or not CanSwap() then return nil end
    if ns.Ready("Whirlwind") and SpareRage(30) then return Try("BerserkerStance", true) end
end

-- Demoralizing Shout her mob / pakete erken (aldigin fiziksel hasari keser).
-- Ikisi de etrafina vurur: yakin dovus menzilinde.
-- Tek normal mobda ofke Rend / Mortal Strike'a gider: yalniz guclu mob ya da paket.
local function DemoRule()
    if not (ctx.big or (ctx.enemies or 0) >= 2) then return nil end
    if ctx.melee and DebuffDue("DemoShout", 3) then return Try("DemoShout", true) end
end

-- Thunder Clap debuff'ini tut; Prot grupta tehdit icin cooldown'da
local function ThunderRule(always)
    if ctx.melee and (always or DebuffDue("ThunderClap")) then return Try("ThunderClap", true) end
end

---------------------------------------------------------------------------
-- AoE oncelikleri (2+ dusman). Zindanda da Demo Shout her paketin onunde.
---------------------------------------------------------------------------
local function ArmsAoE()
    return DemoRule()
        or Try("SweepingStrikes", true)
        -- 3+ dusmanda Thunder Clap Cleave'den iyi; grupta 2 dusmanda tanka birak
        or ((not ctx.group or ctx.enemies >= 3) and ThunderRule())
        or Try("Whirlwind", true)
        or WhirlwindDance()
end

local function FuryAoE()
    return DemoRule()
        or Try("Whirlwind", true)
        or (not ctx.group and InStance("BattleStance") and ThunderRule())
        or WhirlwindDance()
end

local function ProtAoE()
    return ThunderRule(ctx.group)
        or DemoRule()
        or Try("Revenge", false)
end

---------------------------------------------------------------------------
-- Tek hedef oncelikleri (ana ikon)
---------------------------------------------------------------------------
-- Execute (Forever): fazla rage'i cok verimsiz harcar ve rage'i sifirlar (sonraki mob'a
-- Demo Shout kalmaz); normal mob'da sadece bitirici, listenin sonunda.
-- Slam sadece Improved Slam ile (yoksa vurus zamanlayicisini bozar).
-- Leveling Fury (Bloodthirst oncesi) da bu listeyi kullanir (Spec() = ARMS).
-- Buyuk hedefte (elit / boss / grup) Execute fazi gercek: raid rehberleri gibi one al
local function BigExecute()
    return ctx.big and Try("Execute", false)
end

local function Arms()
    return Try("Overpower", false)            -- dodge / Bloodthrill penceresi kisa
        or BigExecute()
        or DemoRule()
        or RendRule()                          -- Bloodthrill: Rend, Overpower acar
        or (CreatureIs("Giant", "Dragonkin") and Try("SpearingStrike", true))
        or Try("MortalStrike", true)
        or (improvedSlam > 0 and Try("Slam", true))
        or Try("SpearingStrike", true)
        or ((ctx.big or ctx.enemies >= 2) and ThunderRule())   -- tek normal moba 20 rage'e deymez
        or Try("VictoryRush", false)
        or Try("Execute", false)
        -- 1-3. seviye: Heroic Strike tek saldiri; yalniz kucuk ikonda kalinca ana ikon bos kaliyordu
        or (ctx.leveling and not Has("Rend") and not ns.Queued("HeroicStrike") and Try("HeroicStrike", true))
end

local function Fury()
    -- Gore Drinker: buff'i Bloodthirst ile surekli tut, rage azsa Whirlwind'den once
    return BigExecute()
        or DemoRule()
        or (goreDrinker and Try("Bloodthirst", true))
        or Try("Whirlwind", true)
        or Try("Bloodthirst", true)
        -- Whirlwind (36) oncesi Fury Battle Stance'te Rend + Overpower ile savasir
        or (not Has("Whirlwind") and RendRule())
        or Try("Overpower", false)
        or (not Has("Whirlwind") and (ctx.big or ctx.enemies >= 2) and ThunderRule())
        or Try("VictoryRush", false)
        or Try("Execute", false)
end

local function SunderNeeded()
    local want = ctx.big and O("sunderStacks") or math.min(2, O("sunderStacks"))
    return ns.Stacks("SunderArmor") < want or DebuffDue("SunderArmor", 5)
end

local function Prot()
    return Try("Revenge", false)              -- block / parry / dodge sonrasi 5 sn
        or Try("ShieldSlam", true)
        or DemoRule()
        or RendRule()
        or ThunderRule(ctx.group)
        or (SunderNeeded() and Try("SunderArmor", true))
        or Try("VictoryRush", false)
        or Try("Execute", false)
        or Try("Overpower", false)
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma, GCD disi yetenekler ve buyuk cooldown'lar
---------------------------------------------------------------------------
local function Defensive()
    if not ctx.inCombat or not O("defensives") then return nil end
    return (HealthBelow(O("lastStand")) and Try("LastStand", true))
        or (HealthBelow(O("shieldWall")) and Try("ShieldWall", true))
        or (HealthBelow(O("retaliation")) and ctx.enemies >= 3 and Try("Retaliation", true))
        or (HealthBelow(O("intimShout")) and ctx.enemies >= 3 and not ctx.group and Try("IntimidatingShout", true))
end

-- Buyuk cooldown'lar Cooldowns.lua'da (W.cooldowns); burada GCD disi / savunma / rage bosaltma.
local function Extra()
    local r = Defensive()
    if r then return r end
    if not ctx.inCombat or not ctx.melee then return nil end

    if ctx.spec == "PROT" then
        r = Try("ShieldBlock", true)
        if r then return r end
    end

    r = Try("Bloodrage", true) or (ctx.spec == "FURY" and Try("BerserkerRage", true))
    if r then return r end

    -- Rage bosaltma: birden fazla dusmanda Cleave, yoksa Heroic Strike.
    -- Siradayken tekrar onerme (oyun kullanilabilir gostermeye devam eder).
    if ns.Queued("HeroicStrike") or ns.Queued("Cleave") then return nil end
    if ctx.many and Has("Cleave") and SpareRage(W.HSThreshold("Cleave")) then
        r = Try("Cleave", true)
        if r then return r end
    end
    if SpareRage(W.HSThreshold("HeroicStrike")) then
        return Try("HeroicStrike", true)
    end
end

-- Buyuk cooldown'lar (Cooldowns.lua). default: kullanim modu (ayardan degisir),
-- cond: sinifa ozel ek kosul (bu turun ctx'i).
W.cooldowns = {
    -- Fury: "erken ve sik" (Gore Drinker'i da acar)
    { key = "DeathWish", default = "always", cond = function() return ctx.melee end },
    -- Boss'ta Execute fazina saklanir
    { key = "Recklessness", default = "elite",
      cond = function() return ctx.melee and (ctx.kind ~= "boss" or ns.Usable("Execute", false)) end },
}
-- Kucuk ikonda bunlar varken buyuk cooldown onerisi one gecer (kucuk ikon modunda)
W.lowExtras = { HeroicStrike = true, Cleave = true, Bloodrage = true, BerserkerRage = true }

---------------------------------------------------------------------------
-- Ana ikon
---------------------------------------------------------------------------
local SINGLE = { ARMS = Arms, FURY = Fury, PROT = Prot }
local AOE    = { ARMS = ArmsAoE, FURY = FuryAoE, PROT = ProtAoE }

local function Main()
    -- Canin azken Victory Rush her seyin onunde (bedava iyilesme)
    if HealthBelow(O("victoryRush")) then
        local r = Try("VictoryRush", false)
        if r then return r end
    end

    -- AoE durus dansi (Whirlwind icin Berserker) normal durus kuralindan once gelir
    if ctx.aoe and ctx.inCombat then
        local r = AOE[ctx.spec]()
        if r then return r end
    end

    -- AoE ayri ikondayken Whirlwind icin Berserker'e gecildiyse ana ikon hemen Battle'a geri cagirmaz
    local whirl = InStance("BerserkerStance") and Has("Whirlwind") and ns.Ready("Whirlwind") and (ctx.enemies or 0) >= 2
    local r = (not whirl) and StanceRule() or nil
    if r then return r end

    if O("shout") and ns.AuraRemaining("player", "BattleShout", "HELPFUL") <= (ctx.inCombat and 0 or 10) then
        r = Try("BattleShout", true)
        if r then return r end
    end

    if O("charge") and not ctx.inCombat and ns.InRange("Charge") == true then
        r = Try("Charge", true)
        if r then return r end
    end

    -- hedef menzil disinda (kacan mob, 30 yd uzak): yakin dovus listesi erisilemeyen yetenek gosterirdi
    if ns.InRange("HeroicStrike") == false then return nil end
    return SINGLE[ctx.spec]()
end

function W.Next()
    ReadContext()
    ctx.mainRage = nil
    local main = Main()
    ctx.mainRage = main and Cost(main.key) > 0 or nil
    return main or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function W.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AOE[ctx.spec]() or nil
end

-- /rof debug icin
function W.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | hedef: %s %s"))
        :format(ctx.spec, ctx.enemies, ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ctx.kind, tostring(ns.CreatureType())))
    local parts = {}
    for _, k in ipairs(ReserveKeys()) do
        if Has(k) then parts[#parts + 1] = ("%s %d"):format(S(k).name, Cost(k)) end
    end
    ns.Print((L("Heroic Strike esigi: %d %s | HS %d%s")):format(
        W.HSThreshold("HeroicStrike"), O("hsRage") > 0 and "(elle)" or "(otomatik)",
        Cost("HeroicStrike"), #parts > 0 and (" + " .. table.concat(parts, " + ")) or ""))
    if Has("Cleave") then ns.Print(L("Cleave esigi: ") .. W.HSThreshold("Cleave")) end
end
