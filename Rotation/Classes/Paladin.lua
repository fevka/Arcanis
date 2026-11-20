local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local P = {}
ns.classes.PALADIN = P
P.enemyProbe = "HolyStrike"   -- dusman sayimi yakin dovus menzilinde (Judgement 10 yd, melee degil)
P.nearProbe  = "Judgement"    -- savasta ~10 yd olcumu: Judgement menzili zaten 10 yd

-- WoW Forever Paladin. Forever notlari (beta verisi):
--   * Judgement muhuru TUKETMEZ: 10 sn cooldown, GCD disi. Muhur 30 sn surer, bitince / degistirince yenile.
--   * Muhurler birbirini kaldirir. Seal of Fury (10) tank muhru: Judgement'i 4 sn taunt eder, tank disi kullanma.
--   * Holy Strike 6'da temel (GCD'li). Consecration ve Blessing of Kings 20'de ogretmenden, Hammer of Wrath 44.
--   * Divine Shield / Divine Protection / Blessing of Protection / Templar's Bulwark Forbearance paylasir (60 sn).
--   * Kaynak sadece mana (Holy Power yok). Savasta mana ve aura gizli.
-- SINIRLAMA (Holy): savasta baska birimlerin cani gizli. Grupta can esigine bagli iyilestirme ONERILMEZ;
--   Holy icin sadece bakim (muhur / aura / blessing), solo hasar rotasyonu ve kendi canina iyilestirme var.
-- Spell ID'leri: rank 1; Forever'a ozel olanlar (Seal of Fury, Holy Shock, Light's Vigil, Templar's Bulwark,
-- Swift Judgement) beta verisinden.
P.spells = {
    -- Muhurlar (biri digerini kaldirir) ve Judgement
    SealRighteousness = { id = 20154,   name = "Seal of Righteousness", duration = 30, unit = "player", group = "seal" },
    SealCommand       = { id = 20375,   name = "Seal of Command",       duration = 30, unit = "player", group = "seal" },
    SealFury          = { id = 1311649, name = "Seal of Fury",          duration = 30, unit = "player", group = "seal" },
    SealCrusader      = { id = 21082,   name = "Seal of the Crusader",  duration = 30, unit = "player", group = "seal" },
    SealLight         = { id = 20165,   name = "Seal of Light",         duration = 30, unit = "player", group = "seal" },
    SealWisdom        = { id = 20166,   name = "Seal of Wisdom",        duration = 30, unit = "player", group = "seal" },
    SealJustice       = { id = 20164,   name = "Seal of Justice",       duration = 30, unit = "player", group = "seal" },
    Judgement         = { id = 20271,   name = "Judgement" },
    SwiftJudgement    = { id = 1310994, name = "Swift Judgement" },

    -- Ana ikon (GCD'li)
    HolyStrike    = { id = 679,     name = "Holy Strike" },
    Consecration  = { id = 26573,   name = "Consecration" },
    Exorcism      = { id = 879,     name = "Exorcism" },
    HammerOfWrath = { id = 24275,   name = "Hammer of Wrath" },
    HolyWrath     = { id = 2812,    name = "Holy Wrath" },
    HolyShield    = { id = 20925,   name = "Holy Shield", duration = 10, unit = "player" },
    HolyShock     = { id = 1311606, name = "Holy Shock" },
    LightsVigil   = { id = 1310911, name = "Light's Vigil" },

    -- Iyilesme
    HolyLight     = { id = 635,     name = "Holy Light" },
    FlashOfLight  = { id = 19750,   name = "Flash of Light" },

    -- Kucuk ikon (savunma / cooldown)
    HammerOfJustice      = { id = 853,     name = "Hammer of Justice" },
    DivineShield         = { id = 642,     name = "Divine Shield" },
    DivineProtection     = { id = 498,     name = "Divine Protection" },
    LayOnHands           = { id = 633,     name = "Lay on Hands" },
    BlessingOfProtection = { id = 1022,    name = "Blessing of Protection" },
    TemplarsBulwark      = { id = 1311015, name = "Templar's Bulwark" },
    DivineFavor          = { id = 20216,   name = "Divine Favor" },

    -- Auralar (biri digerini kaldirir)
    DevotionAura       = { id = 465,   name = "Devotion Aura",       duration = 3600, unit = "player", group = "aura" },
    RetributionAura    = { id = 7294,  name = "Retribution Aura",    duration = 3600, unit = "player", group = "aura" },
    ConcentrationAura  = { id = 19746, name = "Concentration Aura",  duration = 3600, unit = "player", group = "aura" },
    -- yalniz "bir aura acik mi" icin: oyuncunun sectigi direnc / Sanctity aurasi hatirlatici tarafindan ezilmesin
    ShadowResAura      = { id = 19876, name = "Shadow Resistance Aura", duration = 3600, unit = "player", group = "aura" },
    FrostResAura       = { id = 19888, name = "Frost Resistance Aura",  duration = 3600, unit = "player", group = "aura" },
    FireResAura        = { id = 19891, name = "Fire Resistance Aura",   duration = 3600, unit = "player", group = "aura" },
    SanctityAura       = { id = 20218, name = "Sanctity Aura",          duration = 3600, unit = "player", group = "aura" },

    -- Blessing'ler (kendine, 1 saat) ve Righteous Fury
    BlessingOfMight   = { id = 19740, name = "Blessing of Might",   duration = 3600, unit = "player", group = "blessing" },
    BlessingOfWisdom  = { id = 19742, name = "Blessing of Wisdom",  duration = 3600, unit = "player", group = "blessing" },
    BlessingOfKings   = { id = 20217, name = "Blessing of Kings",   duration = 3600, unit = "player", group = "blessing" },
    GreaterMight      = { id = 25782, name = "Greater Blessing of Might",  duration = 3600, unit = "player", group = "blessing" },
    GreaterWisdom     = { id = 25894, name = "Greater Blessing of Wisdom", duration = 3600, unit = "player", group = "blessing" },
    GreaterKings      = { id = 25898, name = "Greater Blessing of Kings",  duration = 3600, unit = "player", group = "blessing" },
    RighteousFury     = { id = 25780, name = "Righteous Fury", duration = 1800, unit = "player" },
}
-- Forever'da Paladin'in gercek interrupt'i yok; Hammer of Justice stun (Extra() icinde, boss disi).

local SEALS = { "SealRighteousness", "SealCommand", "SealFury", "SealCrusader", "SealLight", "SealWisdom", "SealJustice" }
local AURAS = { "DevotionAura", "RetributionAura", "ConcentrationAura", "ShadowResAura", "FrostResAura", "FireResAura",
    "SanctityAura" }
local FORBEAR = { "DivineShield", "DivineProtection", "TemplarsBulwark", "BlessingOfProtection" }

P.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "buffs", default = true, label = "Aura / Blessing / Righteous Fury hatirlatici",
      tip = "Savas disinda eksik aura, blessing ve (Prot) Righteous Fury'yi onerir." },
    { type = "cycle", key = "seal", default = "auto", label = "Muhur (Ret / leveling)",
      values = { "auto", "command", "righteousness", "crusader" },
      names = { auto = "Otomatik (yavas silahta Command)", command = "Seal of Command",
                righteousness = "Seal of Righteousness", crusader = "Seal of the Crusader" },
      tip = "Prot her zaman Seal of Fury (yoksa Righteousness); Holy grup / zindanda Wisdom veya Light." },
    { type = "cycle", key = "blessing", default = "auto", label = "Blessing (kendine)",
      values = { "auto", "might", "wisdom", "kings" },
      names = { auto = "Otomatik (Holy Wisdom, Prot Kings, digerleri Might)", might = "Blessing of Might",
                wisdom = "Blessing of Wisdom", kings = "Blessing of Kings" } },
    { type = "cycle", key = "aura", default = "auto", label = "Aura",
      values = { "auto", "devotion", "retribution", "concentration" },
      names = { auto = "Otomatik (hic aura yoksa)", devotion = "Devotion Aura",
                retribution = "Retribution Aura", concentration = "Concentration Aura" } },
    { type = "toggle", key = "crusader", default = true, label = "Judgement of the Crusader acilisi",
      tip = "Ret / leveling: elit, boss ve grupta Crusader muhru + Judgement, sonra normal muhur. Oyuncuda yapilmaz." },
    { type = "toggle", key = "protJudge", default = true, label = "Prot: Judgement (Fury taunt)",
      tip = "Seal of Fury Judgement'i 4 sn taunt eder. Raid'de kapali sayilir (ana tank'tan boss'u cekmesin)." },
    { type = "toggle", key = "holyShield", default = true, label = "Prot: Holy Shield surekli",
      tip = "Kapali: sadece elit / boss ya da can %50 altinda." },
    { type = "toggle", key = "holyDamage", default = false, label = "Holy: zindanda da hasar",
      tip = "Grup iyilestiricisi iken sadece bakim onerilir; acarsan hasar rotasyonu da gelir." },
    { type = "toggle", key = "hojCast", default = true, label = "Cast eden hedefe Hammer of Justice",
      tip = "Paladin'in interrupt'i yok; stun cast'i durdurur. Boss'larda onerilmez." },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },

    { type = "header", label = "Mana" },
    { type = "toggle", key = "consecration", default = true, label = "Consecration",
      tip = "Yakin dovuste, elit / grup / 2+ dusmanda." },
    { type = "slider", key = "consMana", default = 60, min = 0, max = 90, step = 5, zero = "Her zaman",
      label = "Consecration icin mana %",
      tip = "Savas disinda gercek mana. Savasta mana gizli: Holy Light / Holy Shield'in manasi kaliyorsa." },
    { type = "slider", key = "healOoc", default = 60, min = 0, max = 100, step = 5, zero = "Kapali",
      label = "Savas disi kendini iyilestir (can %)" },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "divineShield",     default = 20, min = 0, max = 90, step = 5, zero = "Kapali", label = "Divine Shield" },
    { type = "slider", key = "layOnHands",       default = 15, min = 0, max = 90, step = 5, zero = "Kapali", label = "Lay on Hands" },
    { type = "slider", key = "divineProtection", default = 30, min = 0, max = 90, step = 5, zero = "Kapali", label = "Divine Protection" },
    { type = "slider", key = "bop",              default = 25, min = 0, max = 90, step = 5, zero = "Kapali", label = "Blessing of Protection (oyuncuya karsi)" },
    { type = "slider", key = "templar",          default = 40, min = 0, max = 90, step = 5, zero = "Kapali", label = "Templar's Bulwark (Prot)" },
    { type = "slider", key = "hojSolo",          default = 40, min = 0, max = 90, step = 5, zero = "Kapali", label = "Hammer of Justice (yalniz)" },
    { type = "slider", key = "healLow",          default = 35, min = 0, max = 90, step = 5, zero = "Kapali", label = "Holy Light kendine (yalniz)" },
    { type = "slider", key = "healMid",          default = 50, min = 0, max = 90, step = 5, zero = "Kapali", label = "Flash of Light kendine (yalniz)" },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try

local function BuffLeft(key)
    return ns.AuraRemaining("player", key, "HELPFUL")
end

local BuffUp = ns.BuffUp

local function AnyUp(list)
    for _, k in ipairs(list) do
        if BuffUp(k) then return true end
    end
    return false
end

local SPECS = { "HOLY", "PROT", "RET" }
local spec = "LEVELING"
function P.OnRefresh()
    spec = SPECS[ns.MainTalentTab()] or "LEVELING"
end

---------------------------------------------------------------------------
-- Kendi atislarimizdan takip (savasta aura verisi gizli)
---------------------------------------------------------------------------
local isSeal = {}
for _, k in ipairs(SEALS) do isSeal[k] = true end

-- Son atilan muhur; Crusader muhruyle atilan Judgement hedefte Judgement of the Crusader birakir
local lastSeal, jotcAt = nil, 0

function P.OnCast(key)
    if isSeal[key] then lastSeal = key end
    if key == "Judgement" and lastSeal == "SealCrusader" then jotcAt = GetTime() end
end

local targetEv = CreateFrame("Frame")
pcall(targetEv.RegisterEvent, targetEv, "PLAYER_TARGET_CHANGED")
targetEv:SetScript("OnEvent", function() jotcAt = 0 end)

-- Forbearance (60 sn): debuff okunamazsa kendi atislarimiz
local function Forbearance()
    for _, k in ipairs(FORBEAR) do
        if ns.Recent(k, 60) then return true end
    end
    return false
end

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
    local it     = ns.InstanceType()
    ctx.dungeon  = it == "party" or it == "raid"
    -- Holy Strike (6) ogrenilmeden once yaklasik mesafe
    if Has("HolyStrike") then
        ctx.melee = ns.InRange("HolyStrike") == true
    else
        ctx.melee = ns.Near("target") == true
    end
    ctx.health   = ns.HealthPercent()                 -- nil: bilinmiyor
    local n = ns.EnemiesNearby() or 0
    if ctx.melee and n < 1 then n = 1 end
    ctx.enemies  = n
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and n >= O("aoeAt")
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

local CreatureIs = ns.CreatureIs

-- Savasta mana gizli: korunan buyu (guard) hala karsilaniyorsa "yeterli" say
local function SpareMana(pct, guard)
    if pct <= 0 then return true end
    local m = ns.ManaPercent()
    if m then return m >= pct end
    if guard and Has(guard) then return not ns.NoPower(guard) end
    return true
end

local function SlowWeapon()
    local speed = ns.Call(UnitAttackSpeed, "player")
    if type(speed) ~= "number" then return true end   -- bilinmiyorsa 2H say
    return speed >= 2.9
end

---------------------------------------------------------------------------
-- Muhur
---------------------------------------------------------------------------
local function WantedSeal()
    if spec == "PROT" then return Has("SealFury") and "SealFury" or "SealRighteousness" end
    if spec == "HOLY" and ctx.dungeon then   -- grup iyilestiricisi: Judgement of Wisdom / Light
        if Has("SealWisdom") then return "SealWisdom" end
        if Has("SealLight") then return "SealLight" end
        return "SealRighteousness"
    end
    local o = O("seal")
    if o == "crusader" and Has("SealCrusader") then return "SealCrusader" end
    if o == "righteousness" then return "SealRighteousness" end
    if Has("SealCommand") and (o == "command" or SlowWeapon()) then return "SealCommand" end
    return "SealRighteousness"
end

-- Judgement of the Crusader acilisi: elit / boss / grupta, hedef basina bir kez (40 sn)
local function CrusaderOpener()
    if not O("crusader") or not Has("SealCrusader") or not Has("Judgement") then return false end
    if spec ~= "RET" and spec ~= "LEVELING" then return false end
    if ctx.kind == "player" or not ctx.big or WantedSeal() == "SealCrusader" then return false end
    -- Saldirilabilir, canli bir hedef sart (grupta hedefsiz / dost hedefte acilis yapilmaz)
    if ns.Call(UnitCanAttack, "player", "target") ~= true or ns.Call(UnitIsDead, "target") == true then return false end
    if ns.Recent("SealCrusader", 40) or GetTime() - jotcAt < 35 then return false end
    return ns.Ready("Judgement") and ns.InRange("Judgement") ~= false
end

-- Crusader muhru az once atildi, Judgement henuz atilmadi: muhuru degistirme
local function CrusaderPhase()
    return lastSeal == "SealCrusader" and ns.Recent("SealCrusader", 8) and BuffUp("SealCrusader")
        and GetTime() - jotcAt >= 35 and WantedSeal() ~= "SealCrusader"
end

local function SealRule()
    local want = WantedSeal()
    if not Has(want) or CrusaderPhase() then return nil end
    if CrusaderOpener() then return Try("SealCrusader", true) end
    if ctx.inCombat then
        -- oyuncunun elle actigi baska muhur (az manada Wisdom gibi) savasta ezilmez; Crusader acilistan kalabilir
        local other = false
        for _, k in ipairs(SEALS) do
            if k ~= want and k ~= "SealCrusader" and BuffUp(k) then other = true break end
        end
        if not other and BuffLeft(want) <= 2 then return Try(want, true) end
    elseif not AnyUp(SEALS) then
        return Try(want, true)
    end
end

-- Judgement: muhuru tuketmez, cooldown'da. Fury Judgement'i taunt eder.
local function JudgeAllowed()
    if not Has("Judgement") or not AnyUp(SEALS) or ns.InRange("Judgement") == false then return false end
    if not ctx.inCombat and not CrusaderPhase() then return false end
    if BuffUp("SealFury") then
        if spec ~= "PROT" or not O("protJudge") or ns.InstanceType() == "raid" then return false end
    end
    -- Righteousness rank 1'in Judgement etkisi yok (10'da gelir)
    if BuffUp("SealRighteousness") and (ns.Call(UnitLevel, "player") or 60) < 10 then return false end
    -- Holy grup iyilestiricisi: Judgement 40 sn surer, yaklasik 30 sn'de bir
    if spec == "HOLY" and ctx.dungeon and ns.Recent("Judgement", 30) then return false end
    return true
end

---------------------------------------------------------------------------
-- Hatirlaticilar (aura, blessing, Righteous Fury, savas disi iyilesme)
---------------------------------------------------------------------------
local function WantedAura()
    local o = O("aura")
    local want = ({ devotion = "DevotionAura", retribution = "RetributionAura",
                    concentration = "ConcentrationAura" })[o]
    if not want then
        if spec == "RET" then want = "RetributionAura"
        elseif spec == "HOLY" and ctx.dungeon then want = "ConcentrationAura"
        else want = "DevotionAura" end
    end
    return Has(want) and want or "DevotionAura"
end

local function AuraRule()
    local want = WantedAura()
    if O("aura") == "auto" then
        if not AnyUp(AURAS) then return Try(want, true) end
    elseif not BuffUp(want) then
        return Try(want, true)
    end
end

local function WantedBlessing()
    local want = ({ might = "BlessingOfMight", wisdom = "BlessingOfWisdom", kings = "BlessingOfKings" })[O("blessing")]
    if not want then
        want = (spec == "HOLY" and "BlessingOfWisdom") or (spec == "PROT" and "BlessingOfKings") or "BlessingOfMight"
    end
    return Has(want) and want or "BlessingOfMight"
end

local GREATER = { BlessingOfMight = "GreaterMight", BlessingOfWisdom = "GreaterWisdom", BlessingOfKings = "GreaterKings" }

local function BlessingRule()
    local want = WantedBlessing()
    if BuffLeft(want) >= 60 or BuffLeft(GREATER[want]) >= 60 then return nil end
    -- Dost bir hedefe atildiysa kendi ustumuzde gorunmez: hemen tekrar onerme
    if ns.Recent(want, 10) then return nil end
    return Try(want, true)
end

local function Reminders()
    if spec == "PROT" and O("buffs") and BuffLeft("RighteousFury") <= (ctx.inCombat and 0 or 60) then
        local r = Try("RighteousFury", true)
        if r then return r end
    end
    if ctx.inCombat then return nil end
    if O("buffs") then
        local r = AuraRule() or BlessingRule()
        if r then return r end
    end
    if HealthBelow(O("healOoc")) then
        return Try("FlashOfLight", true) or (not Has("FlashOfLight") and Try("HolyLight", true)) or nil
    end
end

---------------------------------------------------------------------------
-- Hasar yetenekleri
---------------------------------------------------------------------------
local function ConsecrationRule(pct)
    if not O("consecration") or not ctx.melee then return nil end
    local guard = spec == "PROT" and "HolyShield" or "HolyLight"
    if SpareMana(pct or O("consMana"), guard) then return Try("Consecration", true) end
end

-- Prot: Holy Shield (10 sn, cooldown 10 sn) surekli; kapaliysa sadece zor vuruslarda
local function HolyShieldRule()
    if not ctx.melee or BuffLeft("HolyShield") > 0.5 then return nil end
    if O("holyShield") or ctx.kind == "elite" or ctx.kind == "boss" or HealthBelow(50) then
        return Try("HolyShield", true)
    end
end

local function UndeadRule()
    return CreatureIs("Undead", "Demon") and Try("Exorcism", true)
end

local function AoE()
    if spec == "HOLY" and ctx.dungeon and not O("holyDamage") then return nil end
    return (spec == "PROT" and HolyShieldRule())
        or ConsecrationRule(spec == "PROT" and 20 or 25)
        or (CreatureIs("Undead", "Demon") and Try("HolyWrath", true))
end

---------------------------------------------------------------------------
-- Tek hedef oncelikleri (ana ikon). Judgement GCD disi: Extra()'da.
---------------------------------------------------------------------------
local function Damage()   -- Ret / leveling
    return Try("HammerOfWrath", false)             -- sadece %20 alti hedefte kullanilabilir
        or UndeadRule()
        or (ctx.melee and Try("HolyStrike", true))
        or (SpareMana(40, "HolyLight") and Try("HolyShock", true))
        or (ctx.big and ConsecrationRule())
        or (ctx.enemies >= 2 and ConsecrationRule())
end

local function Protection()
    return HolyShieldRule()
        or (ctx.melee and Try("HolyStrike", true))   -- tehdit
        or Try("HammerOfWrath", false)
        or UndeadRule()
        or ((ctx.big or ctx.enemies >= 2) and ConsecrationRule(50))
end

-- Holy: grup iyilestiricisi iken sadece bakim (baska birimlerin cani savasta gizli)
local function Holy()
    if ctx.dungeon and not O("holyDamage") then return nil end
    return Try("HammerOfWrath", false)
        or (SpareMana(40, "HolyLight") and Has("HolyShock") and ns.Ready("HolyShock") and Try("LightsVigil", true))
        or (SpareMana(40, "HolyLight") and Try("HolyShock", true))
        or UndeadRule()
        or (ctx.melee and Try("HolyStrike", true))
        or (not ctx.group and ConsecrationRule())
end

local SINGLE = { HOLY = Holy, PROT = Protection, RET = Damage, LEVELING = Damage }

local function Main()
    local r = Reminders()
    if r then return r end
    r = SealRule()
    if r then return r end
    if ctx.aoe and ctx.inCombat then
        r = AoE()
        if r then return r end
    end
    return SINGLE[spec]()
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma, Judgement, stun, buyuk cooldown'lar
---------------------------------------------------------------------------
local function SoloHeal()
    if ctx.group then return nil end
    return (HealthBelow(O("hojSolo")) and ctx.kind ~= "boss" and ns.InRange("HammerOfJustice") ~= false
            and Try("HammerOfJustice", true))
        or (HealthBelow(O("healLow")) and Try("HolyLight", true))
        or (HealthBelow(O("healMid")) and (Try("FlashOfLight", true)
            or (not Has("FlashOfLight") and Try("HolyLight", true))))
end

local function Defensive()
    if not ctx.inCombat or not O("defensives") then return nil end
    -- Grupta tank balonla mob'lari gruba birakir: Prot grupta Divine Shield / Protection onerilmez
    local noBubble = Forbearance() or (spec == "PROT" and ctx.group and ctx.kind ~= "player")
    return (not noBubble and HealthBelow(O("divineShield")) and Try("DivineShield", true))
        or (HealthBelow(O("layOnHands")) and not ns.Recent("DivineShield", 12) and Try("LayOnHands", true))
        or (not noBubble and HealthBelow(O("divineProtection")) and Try("DivineProtection", true))
        or (spec == "PROT" and not Forbearance() and HealthBelow(O("templar")) and Try("TemplarsBulwark", true))
        or (ctx.kind == "player" and not Has("DivineShield") and not Forbearance()
            and HealthBelow(O("bop")) and Try("BlessingOfProtection", true))
        or SoloHeal()
end

local function Extra()
    local r = Defensive()
    if r then return r end

    -- Hedef cast ediyor: Hammer of Justice stun'i (boss bagisik)
    if O("hojCast") and ctx.inCombat and ctx.kind ~= "boss" and ns.TargetCast() ~= nil
       and ns.InRange("HammerOfJustice") ~= false then
        r = Try("HammerOfJustice", true)
        if r then return r end
    end

    if JudgeAllowed() then
        r = Try("Judgement", true)
        if r then return r end
        -- Prot: Judgement cooldown'da ise Swift Judgement sifirlar (ekstra Judgement / taunt)
        if spec == "PROT" and ctx.inCombat and ctx.big then
            return Try("SwiftJudgement", true)
        end
    end

    -- Buyuk cooldown'lar Cooldowns.lua'da (P.cooldowns)
end

-- Buyuk cooldown'lar (Cooldowns.lua). Divine Favor sonraki iyilestirmeyi kritik yapar: Holy, canin dusukken.
P.cooldowns = {
    { key = "DivineFavor", default = "big", cond = function() return spec == "HOLY" and HealthBelow(60) end },
}
-- Judgement sik cikar; bu varken buyuk cooldown onerisi one gecer (kucuk ikon modunda)
P.lowExtras = { Judgement = true, SwiftJudgement = true }

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

-- /rof debug icin
function P.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | mana: %s | hedef: %s %s"))
        :format(spec, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ns.ManaPercent() and ("%%%d"):format(math.floor(ns.ManaPercent())) or "gizli",
                ctx.kind, tostring(ns.CreatureType())))
    ns.Print((L("Istenen muhur: %s | aura: %s | blessing: %s | Forbearance: %s | Crusader acilisi: %s"))
        :format(WantedSeal(), WantedAura(), WantedBlessing(), tostring(Forbearance()), tostring(CrusaderOpener())))
end
