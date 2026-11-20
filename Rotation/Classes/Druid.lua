local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local D = {}
ns.classes.DRUID = D
D.enemyProbe = "Claw"   -- yakin dovus menzili (ayrica ~10 yd icindekiler sayilir; Balance'ta ~10 yd)

-- WoW Forever Druid. Forever notlari (beta verisi):
--   * Powershift yok; Furor enerjiyi form disinda korur. Tiger's Fury ve King of the Jungle kaldirildi
--     (spell varsa kullanilir, yoksa atlanir). Faerie Fire formda ucretsiz, 6 sn cooldown.
--   * Feral yeni yetenekleri: Shifting Power (Cat: mana -> 40 enerji), Primal Bite (Bear, Mangle yerine),
--     Berserk (31), Feral Charge. Lacerate 42'de temel. Barkskin 44'te bedava, formda kullanilir.
--   * Balance: Eclipse (Wrath 2 yigin yukler, Starfire birini harcar, 15 sn), Insect Swarm, Moonkin Form (40).
--   * Cat Form 20, Bear Form 10; Omen of Clarity pasif.
-- Ilk talent puanindan once (1-9) ve Restoration icin Balance benzeri solo hasar rotasyonu kullanilir.
-- RESTORATION SINIRLAMASI: baska birimlerin cani savasta gizli. Grupta can esigine bagli iyilestirme
-- onerilmez; sadece buff (Mark of the Wild, Thorns), kendi canin icin HoT / iyilestirme ve solo hasar.
D.spells = {
    -- Formlar (durus gibi; ns.ActiveForm ile ID ve adla karsilastirilir)
    BearForm     = { id = 5487,    name = "Bear Form",      stance = true },
    DireBearForm = { id = 9634,    name = "Dire Bear Form", stance = true },
    CatForm      = { id = 768,     name = "Cat Form",       stance = true },
    MoonkinForm  = { id = 24858,   name = "Moonkin Form",   stance = true },
    TravelForm   = { id = 783,     name = "Travel Form",    stance = true },

    -- Caster / Balance
    Wrath        = { id = 5176,    name = "Wrath" },
    Starfire     = { id = 2912,    name = "Starfire" },
    Moonfire     = { id = 8921,    name = "Moonfire", duration = 12, durationByRank = { [8921] = 9 } },
    InsectSwarm  = { id = 5570,    name = "Insect Swarm", duration = 12 },
    Hurricane    = { id = 16914,   name = "Hurricane" },
    FaerieFire   = { id = 770,     name = "Faerie Fire", duration = 40 },
    Innervate    = { id = 29166,   name = "Innervate" },
    NaturesSwiftness = { id = 17116, name = "Nature's Swiftness" },
    Barkskin     = { id = 22812,   name = "Barkskin" },

    -- Iyilestirme / buff (kendi canin ve buff bakimi)
    HealingTouch = { id = 5185,    name = "Healing Touch" },
    Regrowth     = { id = 8936,    name = "Regrowth", duration = 21, unit = "player" },
    Rejuvenation = { id = 774,     name = "Rejuvenation", duration = 12, unit = "player" },
    MarkOfTheWild = { id = 1126,   name = "Mark of the Wild", duration = 3600, unit = "player" },
    Thorns       = { id = 467,     name = "Thorns", duration = 600, unit = "player" },

    -- Cat
    Claw         = { id = 1082,    name = "Claw" },
    Shred        = { id = 5221,    name = "Shred" },
    Rake         = { id = 1822,    name = "Rake", duration = 9 },
    Rip          = { id = 1079,    name = "Rip", duration = 12 },
    FerociousBite = { id = 22568,  name = "Ferocious Bite" },
    Ravage       = { id = 6785,    name = "Ravage" },
    Pounce       = { id = 9005,    name = "Pounce" },
    Prowl        = { id = 5215,    name = "Prowl" },
    TigersFury   = { id = 5217,    name = "Tiger's Fury" },
    ShiftingPower = { id = 1322605, name = "Shifting Power" },   -- Forever
    FaerieFireFeral = { id = 16857, name = "Faerie Fire (Feral)", duration = 40 },

    -- Bear
    Maul         = { id = 6807,    name = "Maul" },
    Swipe        = { id = 779,     name = "Swipe" },
    DemoRoar     = { id = 99,      name = "Demoralizing Roar", duration = 30, area = true },
    Enrage       = { id = 5229,    name = "Enrage" },
    FrenziedRegen = { id = 22842,  name = "Frenzied Regeneration" },
    Lacerate     = { id = 414644,  name = "Lacerate", duration = 15, maxStacks = 5 },   -- Forever
    PrimalBite   = { id = 407995,  name = "Primal Bite" },                                -- Forever

    -- Ortak Feral (Bear + Cat)
    FeralCharge  = { id = 1238122, name = "Feral Charge" },   -- Forever
    Bash         = { id = 5211,    name = "Bash" },
    Berserk      = { id = 417141,  name = "Berserk" },        -- Forever
}
D.interrupts = { "FeralCharge", "Bash" }

D.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "form", default = true, label = "Form onerisi",
      tip = "Feral: Cat (ya da Bear), Balance: Moonkin Form. Feral savasta baska bir savas formundaysa form degistirmez." },
    { type = "cycle", key = "feralRole", values = { "cat", "bear" }, default = "cat", label = "Feral rolu",
      names = { cat = "Cat (hasar)", bear = "Bear (tank)" } },
    { type = "toggle", key = "buffs", default = true, label = "Mark of the Wild / Thorns hatirlatici",
      tip = "Sadece savas disinda ve form disindayken (buyu formu bozar)." },
    { type = "toggle", key = "charge", default = true, label = "Feral Charge ile yaklas" },
    { type = "toggle", key = "prowl", default = true, label = "Cat: savas disinda Prowl acilisi" },
    { type = "toggle", key = "shred", default = false, label = "Cat: Claw yerine Shred",
      tip = "Shred hedefin arkasini ister. Grupta tank varsa ac." },
    { type = "toggle", key = "rake", default = true, label = "Cat: Rake" },
    { type = "toggle", key = "rip", default = true, label = "Cat: Rip",
      tip = "Elit / grup / boss hedeflerde ve Ferocious Bite ogrenilmeden once." },
    { type = "toggle", key = "shifting", default = false, label = "Cat: Shifting Power (enerji bitince)",
      tip = "Enerji her vurus arasinda kisa sure yetmez; acik olursa cok sik onerilebilir." },
    { type = "toggle", key = "faerie", default = true, label = "Faerie Fire",
      tip = "Cat: elit / grup hedefler. Bear: her hedef. Caster: sadece grupta." },
    { type = "toggle", key = "dots", default = true, label = "Caster: Moonfire / Insect Swarm" },
    { type = "toggle", key = "innervate", default = true, label = "Mana bitince Innervate" },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Bear: Demoralizing Roar + Swipe. Caster: Hurricane (4+ dusman). Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },

    { type = "header", label = "Rage" },
    { type = "slider", key = "maulRage", default = 0, min = 0, max = 100, step = 5, zero = "Otomatik",
      label = "Maul rage esigi",
      tip = "Otomatik: Maul maliyeti + ana yetenegin (Lacerate / Swipe) maliyeti. Savasta rage gizli: ana yetenek hala karsilanabiliyorsa Maul onerilir." },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "barkskin",     default = 50, min = 0, max = 90, step = 5, zero = "Kapali", label = "Barkskin" },
    { type = "slider", key = "frenzied",     default = 40, min = 0, max = 90, step = 5, zero = "Kapali", label = "Frenzied Regeneration (Bear)" },
    { type = "slider", key = "healingTouch", default = 35, min = 0, max = 90, step = 5, zero = "Kapali", label = "Healing Touch (+ Nature's Swiftness)" },
    { type = "slider", key = "regrowth",     default = 55, min = 0, max = 90, step = 5, zero = "Kapali", label = "Regrowth (kendine)" },
    { type = "slider", key = "rejuv",        default = 65, min = 0, max = 100, step = 5, zero = "Kapali", label = "Rejuvenation (kendine)" },
    { type = "slider", key = "oocHeal",      default = 70, min = 0, max = 100, step = 5, zero = "Kapali",
      label = "Savas disi iyilesme (can %)", tip = "Form disindayken Rejuvenation / Regrowth ile toparlan." },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local DebuffDue = ns.DebuffDue
local BuffUp = ns.BuffUp

local SPECS = { "BALANCE", "FERAL", "RESTO" }
local spec, eclipseTalent, impStarfire = "LEVELING", 0, 0
function D.OnRefresh()
    spec          = SPECS[ns.MainTalentTab()] or "LEVELING"
    eclipseTalent = ns.TalentRank("Eclipse")
    impStarfire   = ns.TalentRank("Improved Starfire")
end

---------------------------------------------------------------------------
-- Kendi atislarimizdan takip (savasta combo point ve aura verisi gizli)
---------------------------------------------------------------------------
local BUILDERS  = { Claw = true, Shred = true, Rake = true, Ravage = true, Pounce = true }
local FINISHERS = { Rip = true, FerociousBite = true }

-- Eclipse: Wrath 2 yigin yukler (en fazla 4, 15 sn), Starfire birini harcar
local eclipseN, eclipseAt = 0, 0

function D.OnCast(key)
    local now = GetTime()
    if BUILDERS[key] then
        ns.comboGuess = math.min((ns.comboGuess or 0) + 1, 5)
    elseif FINISHERS[key] then
        ns.comboGuess = 0
    elseif key == "Wrath" then
        local alive = now - eclipseAt < 15
        eclipseN, eclipseAt = math.min((alive and eclipseN or 0) + 2, 4), now
    elseif key == "Starfire" then
        if now - eclipseAt < 15 then eclipseN = math.max(eclipseN - 1, 0) end
    end
end

local function EclipseUp()
    return eclipseTalent > 0 and eclipseN > 0 and GetTime() - eclipseAt < 15
end

---------------------------------------------------------------------------
-- Durum (her guncellemede bir kez okunur)
---------------------------------------------------------------------------
local ctx = {}

-- Form ID'si buyu kitabindaki ID'den farkli olabilir: adla da karsilastir
local function InForm(key)
    local s, cur = S(key), ctx.form
    if not s or not cur then return false end
    return cur == s.id or ns.Call(C_Spell.GetSpellName, cur) == s.name
end

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.form     = ns.ActiveForm()   -- guncelleme basina bir kez
    ctx.cat      = InForm("CatForm")
    ctx.bear     = InForm("BearForm") or InForm("DireBearForm")
    ctx.moonkin  = InForm("MoonkinForm")
    ctx.travel   = InForm("TravelForm")
    ctx.caster   = not (ctx.cat or ctx.bear or ctx.moonkin or ctx.travel)   -- hic form yok
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    ctx.health   = ns.HealthPercent()                 -- nil: bilinmiyor
    ctx.moving   = (ns.Call(GetUnitSpeed, "player") or 0) > 0
    ctx.hasTarget = UnitExists("target") and true or false

    local probe = (ctx.cat and "Claw") or (ctx.bear and "Maul") or nil
    ctx.melee    = probe ~= nil and ns.InRange(probe) == true
    ctx.far      = probe ~= nil and ns.InRange(probe) == false
    ctx.cp       = ctx.cat and ns.ComboEstimate() or 0

    local n = ns.EnemiesNearby() or 0
    if ctx.melee and n < 1 then n = 1 end
    ctx.enemies  = n
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and n >= O("aoeAt")

    -- Mana: savas disinda gercek, savasta "dolgu buyusune yetiyor mu"
    local mana   = ns.ManaPercent()
    ctx.oom      = (mana and mana < 5) or ns.NoPower("Wrath") or ns.NoPower("Moonfire")
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

-- Savasta mana gizli: Starfire'in manasi kaliyorsa
local function SpareMana(pct)
    local m = ns.ManaPercent()
    if m then return m >= pct end
    return not ns.NoPower("Starfire")
end

---------------------------------------------------------------------------
-- Form ve hatirlaticilar
---------------------------------------------------------------------------
local function BearKey()
    return Has("DireBearForm") and "DireBearForm" or "BearForm"
end

local function WantedForm()
    if spec == "FERAL" then
        -- Dire Bear Form ogrenilince Bear Form listeden dusebilir: ikisine de bak
        local bear = Has("BearForm") or Has("DireBearForm")
        if O("feralRole") == "bear" and bear then return BearKey() end
        if Has("CatForm") then return "CatForm" end
        if bear then return BearKey() end
    elseif spec == "BALANCE" and Has("MoonkinForm") then
        return "MoonkinForm"
    end
end

local function FormRule()
    if not O("form") then return nil end
    local want = WantedForm()
    if not want then return nil end
    local isBear = want == "BearForm" or want == "DireBearForm"
    if InForm(want) or (isBear and ctx.bear) then return nil end
    -- Seyahat formundayken savas disinda karisma
    if ctx.travel and not ctx.inCombat then return nil end
    -- Savasta baska bir savas formundaysan (Cat <-> Bear) enerji / rage yakma
    if ctx.inCombat and (ctx.cat or ctx.bear) then return nil end
    return Try(want, true)
end

-- Savas disinda, formdayken buyu atmak formu bozar: sadece form yokken
local function Buffs()
    if not O("buffs") or ctx.inCombat or not ctx.caster then return nil end
    -- baskasinin Gift of the Wild'i ustundeyse Mark of the Wild atilamaz (daha guclu buff): hatirlatma takilmasin
    local gift = ns.Call(C_UnitAuras.GetAuraDataBySpellName, "player",
        ns.Call(C_Spell.GetSpellName, 21849) or "Gift of the Wild", "HELPFUL")
    if not (type(gift) == "table") and ns.AuraRemaining("player", "MarkOfTheWild", "HELPFUL") < 60 then
        local r = Try("MarkOfTheWild", true)
        if r then return r end
    end
    if Has("Thorns") and ns.AuraRemaining("player", "Thorns", "HELPFUL") < 30 then
        return Try("Thorns", true)
    end
end

-- Savas disinda form yokken kendi canini topla
local function Recover()
    if ctx.inCombat or not ctx.caster then return nil end
    local p = O("oocHeal")
    if not HealthBelow(p) then return nil end
    if not BuffUp("Rejuvenation") then
        local r = Try("Rejuvenation", true)
        if r then return r end
    end
    if HealthBelow(p - 20) and not BuffUp("Regrowth") then
        return Try("Regrowth", true)
    end
end

-- Faerie Fire: formda "Faerie Fire (Feral)" varsa o, yoksa normal
local function Faerie(needBig)
    if not O("faerie") or not ctx.hasTarget then return nil end
    if needBig and not ctx.big then return nil end
    local key = "FaerieFire"
    if (ctx.cat or ctx.bear) and Has("FaerieFireFeral") then key = "FaerieFireFeral" end
    if DebuffDue(key, 3) then return Try(key, true) end
end

---------------------------------------------------------------------------
-- Cat (enerji + combo point)
---------------------------------------------------------------------------
local function Opener()
    if ctx.inCombat or not O("prowl") or not ctx.hasTarget then return nil end
    if not (Has("Pounce") or Has("Ravage") or Has("Shred")) then return nil end
    if not BuffUp("Prowl") then return Try("Prowl", true) end
    return Try("Pounce", true) or Try("Ravage", true) or Try("Shred", true)
end

local function CatFinisher()
    local cp = ctx.cp
    local full  = cp >= 5
    local early = cp >= 4 and not Has("FerociousBite")   -- Bite'tan once tek bitirici Rip
    if not (full or early) then return nil end
    -- kanama Mechanical / Elemental'e islemez (Warrior / Rogue ile ayni kural)
    local bleeds = not ns.CreatureIs("Mechanical", "Elemental")
    if O("rip") and bleeds and DebuffDue("Rip", 1) and (ctx.big or not Has("FerociousBite")) then
        local r = Try("Rip", true)
        if r then return r end
    end
    if full then return Try("FerociousBite", true) end
end

local function Builder()
    if O("shred") and Has("Shred") then
        local r = Try("Shred", true)
        if r then return r end
    end
    return Try("Claw", true)
end

local function Cat()
    return Opener()
        or (O("charge") and ctx.far and Try("FeralCharge", true))
        or Faerie(true)
        or CatFinisher()
        or (O("rake") and ctx.cp < 5 and not ns.CreatureIs("Mechanical", "Elemental") and DebuffDue("Rake", 1.5) and Try("Rake", true))
        -- Enerji savasta gizli: Claw karsilanamiyorsa Shifting Power (mana -> 40 enerji)
        or (O("shifting") and ctx.inCombat and ns.NoPower("Claw") and Try("ShiftingPower", true))
        or Builder()
end

---------------------------------------------------------------------------
-- Bear (rage; Maul sonraki vurusta -> kucuk ikon)
---------------------------------------------------------------------------
local BASE_COST = { Maul = 15, Swipe = 20, Lacerate = 13, PrimalBite = 20 }

local function Cost(key)
    if not Has(key) then return 0 end
    return ns.SpellCost(key, Enum.PowerType.Rage) or BASE_COST[key] or 0
end

local function GuardKey()
    if Has("Lacerate") then return "Lacerate" end
    if Has("Swipe") then return "Swipe" end
end

-- Rage yeterince fazla mi? Savas disinda gercek rage; savasta ana yetenek hala
-- karsilanabiliyorsa ve Primal Bite hazir degilse bosalt.
local function SpareRage(threshold)
    local rage = ns.Rage()
    if rage then return rage >= threshold end
    if ctx.mainRage then return false end   -- ana ikondaki rage'li yetenek once
    local guard = GuardKey()
    if guard and not ns.Usable(guard, false) then return false end
    if Has("PrimalBite") and ns.Ready("PrimalBite") then return false end
    return guard ~= nil or ns.Usable("Maul", false)
end

local function MaulThreshold()
    local custom = O("maulRage")
    if custom > 0 then return custom end
    local guard = GuardKey()
    return Cost("Maul") + (guard and Cost(guard) or 0)
end

local function Bear()
    return (O("charge") and ctx.far and Try("FeralCharge", true))
        or Faerie(false)
        or (ctx.inCombat and ctx.melee and ctx.big and DebuffDue("DemoRoar", 3) and Try("DemoRoar", true))
        or Try("PrimalBite", true)
        or (DebuffDue("Lacerate", 3) and ctx.melee and Try("Lacerate", true))
        or (ns.Stacks("Lacerate") < 5 and ctx.melee and Try("Lacerate", true))
        or (not Has("Maul") and SpareRage(30) and Try("Swipe", true))
        or (ctx.melee and SpareRage(40) and Try("Swipe", true))
        -- 10-15: Swipe / Lacerate oncesi ana ikon bos kalmasin (Maul siradayken tekrar onerme)
        or (not Has("Swipe") and ctx.melee and not ns.Queued("Maul") and Try("Maul", true))
end

---------------------------------------------------------------------------
-- Caster / Moonkin (Balance, Restoration, leveling)
---------------------------------------------------------------------------
local function Caster()
    local dots = O("dots")
    local r = (not ctx.inCombat and ctx.hasTarget and Try("Wrath", true))   -- acilis: menzilden Wrath
        or (ctx.group and Faerie(true))
    if r then return r end
    return (dots and ctx.big and DebuffDue("InsectSwarm", 2) and Try("InsectSwarm", true))
        or (dots and DebuffDue("Moonfire", 2) and Try("Moonfire", true))
        -- hareket: anlik, ama hedefte zaten varsa her GCD yeniden atilmaz (mana)
        or (ctx.moving and ((DebuffDue("Moonfire", 2) and Try("Moonfire", true))
            or (DebuffDue("InsectSwarm", 2) and Try("InsectSwarm", true))))
        or (EclipseUp() and Try("Starfire", true))
        or (ns.Proc("Starfire") and Try("Starfire", true))                          -- Clearcasting
        or (impStarfire >= 3 and SpareMana(40) and Try("Starfire", true))
        or Try("Wrath", true)
        or Try("Starfire", true)
        or Try("Moonfire", true)
end

---------------------------------------------------------------------------
-- AoE
---------------------------------------------------------------------------
local function BearAoE()
    return (ctx.melee and DebuffDue("DemoRoar", 3) and Try("DemoRoar", true))
        or (ctx.melee and Try("Swipe", true))
end

local function CasterAoE()
    if not (ctx.enemies >= 4 or (ctx.group and ctx.enemies >= 3)) then return nil end
    return (not ctx.moving and Try("Hurricane", true))
        or (O("dots") and DebuffDue("Moonfire", 2) and Try("Moonfire", true))
end

local function AoE()
    if ctx.bear then return BearAoE() end
    if ctx.cat then return nil end
    return CasterAoE()
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma, rage bosaltma, ekstra
---------------------------------------------------------------------------
-- Form disinda kendi canin: Nature's Swiftness + Healing Touch, Regrowth, Rejuvenation
local function SelfHeal()
    if not (ctx.caster or ctx.moonkin) then return nil end
    if HealthBelow(O("healingTouch")) then
        local r = not ns.Recent("NaturesSwiftness", 15) and Try("NaturesSwiftness", true)
        if r then return r end
        r = Try("HealingTouch", true)
        if r then return r end
    end
    if HealthBelow(O("regrowth")) and not BuffUp("Regrowth") then
        local r = Try("Regrowth", true)
        if r then return r end
    end
    if HealthBelow(O("rejuv")) and not BuffUp("Rejuvenation") then
        return Try("Rejuvenation", true)
    end
end

local function Defensive()
    if not ctx.inCombat or not O("defensives") then return nil end
    return (HealthBelow(O("barkskin")) and Try("Barkskin", true))
        or (ctx.bear and HealthBelow(O("frenzied")) and Try("FrenziedRegen", true))
        or SelfHeal()
end

local function Extra()
    local r = Defensive()
    if r then return r end
    if not ctx.inCombat or not ctx.bear then return nil end

    -- Rage dusukse Enrage (savasta rage gizli: Maul karsilanamiyorsa)
    local rage = ns.Rage()
    if (rage and rage < 10) or (not rage and ns.NoPower("Maul")) then
        r = Try("Enrage", true)
        if r then return r end
    end

    -- Maul sonraki vurusta: siradayken tekrar onerme
    if ctx.melee and not ns.Queued("Maul") and SpareRage(MaulThreshold()) then
        return Try("Maul", true)
    end
end

-- Buyuk cooldown'lar (Cooldowns.lua): default kullanim modu, cond sinifa ozel kosul
D.cooldowns = {
    { key = "Innervate", default = "always",
      cond = function() return O("innervate") and ctx.oom and not (ctx.cat or ctx.bear) end },
    { key = "Berserk", default = "elite",
      cond = function() return (ctx.cat or ctx.bear) and ctx.melee end },
    { key = "TigersFury", default = "big",
      cond = function() return ctx.cat and ctx.melee end },
}
D.lowExtras = { Maul = true, Enrage = true }

---------------------------------------------------------------------------
-- Ana ikon
---------------------------------------------------------------------------
local function Main()
    local r = Buffs() or Recover()
    if r then return r end

    r = FormRule()
    if r then return r end

    if ctx.aoe and ctx.inCombat then
        r = AoE()
        if r then return r end
    end

    if ctx.travel and not ctx.inCombat then return nil end
    if ctx.cat then return Cat() end
    if ctx.bear then return Bear() end
    return Caster()
end

function D.Next()
    ReadContext()
    ctx.mainRage = nil
    local main = Main()
    ctx.mainRage = ctx.bear and main and Cost(main.key) > 0 or nil
    return main or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function D.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AoE() or nil
end

-- /rof debug icin
function D.Debug()
    ReadContext()
    local form = (ctx.cat and "Cat") or (ctx.bear and "Bear") or (ctx.moonkin and "Moonkin")
        or (ctx.travel and "Travel") or "Caster"
    ns.Print((L("Spec: %s | form: %s | dusman: %d | can: %s | hedef: %s"))
        :format(spec, form, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?", ctx.kind))
    ns.Print((L("combo: %d | enerji: %s | rage: %s | mana: %s | Eclipse: %d"))
        :format(ctx.cp, tostring(ns.Energy() or "gizli"), tostring(ns.Rage() or "gizli"),
                ns.ManaPercent() and ("%%%d"):format(math.floor(ns.ManaPercent())) or "gizli",
                EclipseUp() and eclipseN or 0))
    if ctx.bear then ns.Print(L("Maul esigi: ") .. MaulThreshold()) end
end
