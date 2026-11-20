local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local W = {}
ns.classes.WARLOCK = W
W.enemyProbe = nil   -- dusman sayimi ~10 yd (buyucu: Hellfire / Howl of Terror menzili)
W.nearProbe  = "DrainLife"   -- savasta ~10 yd yerine Drain Life menzili (20 yd, seviye 14; oncesinde CheckInteractDistance)

-- WoW Forever Warlock. Forever notlari (beta verisi):
--   * Curse of Agony / Curse of Doom artik "Bane": hedefte ayni anda bir Bane + bir Curse (bizden).
--     Bane of Havoc (Destruction) da Bane yuvasini kullanir. Curse of Shadow yok, Curse of the
--     Elements tum buyu okullarini kapsar.
--   * Seed of Corruption, Fel Armor, Felguard, Dark Pact yok. Life Tap Spirit ile olceklenir.
--   * Kaynak mana ve savasta gizli: "mana yetmiyor" icin ns.NoPower("ShadowBolt"). Kendi can %
--     tahmindir (ns.HealthPercent). Hedefin cani savasta gizli olabilir: Drain Soul sadece okunabilirse.
--   * Felhunter'in Spell Lock'u PET eylemi: oyuncu buyu kitabinda yok, bu yuzden interrupts listesi
--     YOK (kesme onerilemez). Healthstone (esya) bu surumde onerilmiyor.
--   * Soul Shard cantadaki esya (6265): sayim ns.Call ile; okunamazsa "bilinmiyor" sayilir.
W.spells = {
    -- Hasar
    ShadowBolt   = { id = 686,     name = "Shadow Bolt" },
    Immolate     = { id = 348,     name = "Immolate", duration = 15 },
    Corruption   = { id = 172,     name = "Corruption", duration = 18, durationByRank = { [172] = 12, [6222] = 15 } },
    SearingPain  = { id = 5676,    name = "Searing Pain", aura = "Demonic Brand", duration = 6 },
    SoulFire     = { id = 6353,    name = "Soul Fire" },
    Shoot        = { id = 5019,    name = "Shoot" },   -- asa (wand)

    -- Bane (hedefte bir tane; birbirini kaldirir)
    BaneOfAgony  = { id = 980,     name = "Bane of Agony", duration = 24, group = "bane" },
    BaneOfDoom   = { id = 603,     name = "Bane of Doom",  duration = 60, group = "bane" },
    BaneOfHavoc  = { id = 1225228, name = "Bane of Havoc", duration = 300, group = "bane" },

    -- Curse (hedefte bir tane; birbirini kaldirir)
    CurseOfTheElements  = { id = 440892, name = "Curse of the Elements",  duration = 300, group = "curse" },
    CurseOfWeakness     = { id = 702,    name = "Curse of Weakness",      duration = 120, group = "curse" },
    CurseOfRecklessness = { id = 704,    name = "Curse of Recklessness",  duration = 120, group = "curse" },
    CurseOfTongues      = { id = 1714,   name = "Curse of Tongues",       duration = 30,  group = "curse" },
    CurseOfExhaustion   = { id = 18223,  name = "Curse of Exhaustion",    duration = 12,  group = "curse" },
    AmplifyCurse        = { id = 18288,  name = "Amplify Curse" },

    -- Kanal / kaynak
    DrainSoul    = { id = 1120,    name = "Drain Soul" },
    DrainLife    = { id = 689,     name = "Drain Life" },
    LifeTap      = { id = 1454,    name = "Life Tap" },
    HealthFunnel = { id = 755,     name = "Health Funnel" },

    -- Talent buyuleri
    SiphonLife   = { id = 18265,   name = "Siphon Life", duration = 30 },
    Shadowburn   = { id = 17877,   name = "Shadowburn" },
    Conflagrate  = { id = 17962,   name = "Conflagrate" },
    Incinerate   = { id = 412758,  name = "Incinerate" },
    DemonicSacrifice = { id = 18788, name = "Demonic Sacrifice" },
    FelDomination    = { id = 18708, name = "Fel Domination", duration = 15, unit = "player" },
    SoulLink     = { id = 19028,   name = "Soul Link", duration = 3600, unit = "player" },

    -- Savunma / kontrol
    DeathCoil    = { id = 6789,    name = "Death Coil" },
    HowlOfTerror = { id = 5484,    name = "Howl of Terror" },

    -- AoE
    RainOfFire   = { id = 5740,    name = "Rain of Fire" },
    Hellfire     = { id = 1949,    name = "Hellfire" },
    Inferno      = { id = 1122,    name = "Inferno" },

    -- Zirh (biri digerini kaldirir)
    DemonSkin    = { id = 687,     name = "Demon Skin",  duration = 1800, unit = "player", group = "armor" },
    DemonArmor   = { id = 706,     name = "Demon Armor", duration = 1800, unit = "player", group = "armor" },

    -- Iblisler
    SummonImp        = { id = 688, name = "Summon Imp" },
    SummonVoidwalker = { id = 697, name = "Summon Voidwalker" },
    SummonSuccubus   = { id = 712, name = "Summon Succubus" },
    SummonIncubus    = { id = 713, name = "Summon Incubus" },
    SummonFelhunter  = { id = 691, name = "Summon Felhunter" },
}

W.options = {
    { type = "header", label = "Rotasyon" },
    { type = "cycle", key = "curse", default = "auto", label = "Curse",
      values = { "auto", "elements", "weakness", "recklessness", "tongues", "exhaustion", "none" },
      names = { auto = "Otomatik", elements = "Curse of the Elements", weakness = "Curse of Weakness",
                recklessness = "Curse of Recklessness", tongues = "Curse of Tongues",
                exhaustion = "Curse of Exhaustion", none = "Hicbiri" },
      tip = "Hedefte tek Curse. Otomatik: Elements (yoksa Weakness); oyuncuda Exhaustion / Tongues." },
    { type = "toggle", key = "curseNormal", default = false, label = "Normal mob'a da Curse",
      tip = "Kapaliyken Curse sadece elit, boss, oyuncu ve grup hedeflerinde." },
    { type = "cycle", key = "bane", default = "agony", label = "Bane", values = { "agony", "none" },
      names = { agony = "Bane of Agony", none = "Hicbiri" } },
    { type = "toggle", key = "doom", default = true, label = "Boss'ta Bane of Doom",
      tip = "Sadece boss hedefte ve Improved Bane of Agony yokken." },
    { type = "toggle", key = "destroDots", default = false, label = "Destruction: Corruption / Agony",
      tip = "Kapaliyken Destruction nuke'lari oncelikli; boss'ta yine uygulanir." },
    { type = "cycle", key = "destroFiller", default = "auto", label = "Destruction dolgu",
      values = { "auto", "shadowbolt", "incinerate" },
      names = { auto = "Otomatik (talente gore)", shadowbolt = "Shadow Bolt", incinerate = "Incinerate" },
      tip = "Otomatik: Incinerate + Shadow and Flame 5/5 varsa Incinerate, yoksa Shadow Bolt." },
    { type = "toggle", key = "drainSoul", default = true, label = "Drain Soul (shard)",
      tip = "Hedef cani okunabiliyorsa ve %25 altindaysa." },
    { type = "slider", key = "shardMax", default = 5, min = 1, max = 20, step = 1, label = "Drain Soul icin shard ust siniri" },
    { type = "toggle", key = "shadowburn", default = true, label = "Shadowburn (bekleme suresinde)",
      tip = "Hedef %20 altinda (okunabilirse) ya da Shadow and Flame 5/5. En az 3 shard kalir." },
    { type = "toggle", key = "wand", default = true, label = "Mana bitince asa (Shoot)",
      tip = "Life Tap kullanilamiyorsa (can dusuk / kapali)." },

    { type = "header", label = "Iblis (pet)" },
    { type = "toggle", key = "pet", default = true, label = "Iblis hatirlatici" },
    { type = "cycle", key = "demon", default = "auto", label = "Tercih edilen iblis",
      values = { "auto", "imp", "voidwalker", "succubus", "incubus", "felhunter" },
      names = { auto = "Otomatik", imp = "Imp", voidwalker = "Voidwalker", succubus = "Succubus",
                incubus = "Incubus", felhunter = "Felhunter" },
      tip = "Bilinmeyen iblis atlanir. Otomatik: tek basina Voidwalker, grupta / Demonology'de Imp / Succubus." },
    { type = "toggle", key = "petInCombat", default = false, label = "Savasta da iblis cagir",
      tip = "Fel Domination aktifken her zaman onerilir." },
    { type = "toggle", key = "sacrifice", default = false, label = "Demonic Sacrifice oner",
      tip = "Talent varsa ve iblis (Imp) disaridayken. Feda sonrasi hatirlatici susar." },
    { type = "toggle", key = "armor", default = true, label = "Demon Armor / Skin hatirlatici" },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },
    { type = "slider", key = "hellfire", default = 0, min = 0, max = 100, step = 5, zero = "Kapali",
      label = "Hellfire icin en az can %", tip = "Hellfire kendine hasar verir; 4+ dusman ve can bunun ustundeyken." },

    { type = "header", label = "Mana" },
    { type = "toggle", key = "lifeTap", default = true, label = "Life Tap" },
    { type = "slider", key = "lifeTapMana", default = 15, min = 5, max = 60, step = 5, label = "Life Tap icin mana %",
      tip = "Savas disinda gercek mana. Savasta mana gizli: Shadow Bolt'a yetmediginde." },
    { type = "slider", key = "lifeTapHP", default = 50, min = 20, max = 90, step = 5, label = "Life Tap icin en az can %" },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "deathCoil",  default = 35, min = 0, max = 90, step = 5, zero = "Kapali", label = "Death Coil" },
    { type = "slider", key = "howl",       default = 45, min = 0, max = 90, step = 5, zero = "Kapali", label = "Howl of Terror (solo, 3+ dusman)" },
    { type = "slider", key = "drainLife",  default = 40, min = 0, max = 90, step = 5, zero = "Kapali", label = "Drain Life" },
    { type = "slider", key = "healthFunnel", default = 30, min = 0, max = 90, step = 5, zero = "Kapali",
      label = "Health Funnel (iblis cani)", tip = "Kendi canin %55 ustundeyken." },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local DebuffDue = ns.DebuffDue
local BuffUp = ns.BuffUp

local Recent = ns.Recent

local SPECS = { "AFF", "DEMO", "DESTRO" }
local spec = "LEVELING"
local impAgony, brand, soulLink, sacTalent, snf, incin = 0, 0, 0, 0, 0, 0
function W.OnRefresh()
    spec      = SPECS[ns.MainTalentTab()] or "LEVELING"
    impAgony  = ns.TalentRank("Improved Bane of Agony")
    brand     = ns.TalentRank("Demonic Brand")
    soulLink  = ns.TalentRank("Soul Link")
    sacTalent = ns.TalentRank("Demonic Sacrifice")
    snf       = ns.TalentRank("Shadow and Flame")
    incin     = ns.TalentRank("Incinerate")
end

---------------------------------------------------------------------------
-- Kendi atislarimizdan takip: Demonic Sacrifice sonrasi iblis yok (hatirlatma susar)
---------------------------------------------------------------------------
local sacrificed = false
local SUMMONS = { SummonImp = true, SummonVoidwalker = true, SummonSuccubus = true,
                  SummonIncubus = true, SummonFelhunter = true }

local conflagAt = 0   -- Conflagrate Immolate'i tuketir: kayit hala "var" dese de yok say

function W.OnCast(key)
    if key == "DemonicSacrifice" then sacrificed = true
    elseif SUMMONS[key] then sacrificed = false
    elseif key == "Conflagrate" then conflagAt = GetTime() end
end

---------------------------------------------------------------------------
-- Durum
---------------------------------------------------------------------------
local ctx = {}

local SHARD = 6265
local function ShardCount()
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    return ns.Call(fn, SHARD)
end

-- Hedef can % (sadece duz okunabiliyorsa, yoksa nil; bayat tahmin kullanilmaz)
local function TargetHP()
    local cur, max = ns.Call(UnitHealth, "target"), ns.Call(UnitHealthMax, "target")
    if cur and max and max > 0 then return cur / max * 100 end
end

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    ctx.health   = ns.HealthPercent()
    ctx.thp      = TargetHP()
    ctx.pet      = ns.PetState()
    ctx.petHP    = ctx.pet == "alive" and ns.HealthPercent("pet") or nil
    ctx.enemies  = ns.EnemiesNearby() or 0
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and ctx.enemies >= O("aoeAt")
    ctx.shards   = ShardCount()
    if ctx.pet == "alive" then sacrificed = false end
    -- Mana: savas disinda gercek, savasta "Shadow Bolt'a yetiyor mu"
    ctx.mana     = ns.ManaPercent()
    ctx.oom      = (ctx.mana ~= nil and ctx.mana < O("lifeTapMana")) or ns.NoPower("ShadowBolt")
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end
local function HealthAtLeast(p) return ctx.health ~= nil and ctx.health >= p end
local function TargetAbove(p) return ctx.thp == nil or ctx.thp > p end
local function ShardsAtLeast(n) return ctx.shards == nil or ctx.shards >= n end

---------------------------------------------------------------------------
-- Iblis ve zirh hatirlaticilari
---------------------------------------------------------------------------
local DEMON_KEY = { imp = "SummonImp", voidwalker = "SummonVoidwalker", succubus = "SummonSuccubus",
                    incubus = "SummonIncubus", felhunter = "SummonFelhunter" }

-- Tercih sirasi: secili iblis once, sonra moda gore; Imp'in shard'i yok, son care
local function DemonOrder()
    local pick = DEMON_KEY[O("demon")]
    local list = {}
    if pick then list[1] = pick end
    if ctx.group or spec == "DEMO" then
        list[#list + 1] = "SummonSuccubus"; list[#list + 1] = "SummonImp"; list[#list + 1] = "SummonVoidwalker"
    else
        list[#list + 1] = "SummonVoidwalker"; list[#list + 1] = "SummonImp"
    end
    list[#list + 1] = "SummonImp"
    return list
end

local function SummonDemon()
    for _, k in ipairs(DemonOrder()) do
        -- Imp disindakiler shard ister (Fel Domination aktifken gerekmez)
        local free = k == "SummonImp" or BuffUp("FelDomination")
        if Has(k) and (free or ShardsAtLeast(1)) then
            local r = Try(k, true)
            if r then return r end
        end
    end
end

local function PetRule()
    if not O("pet") or sacrificed or ctx.pet == "alive" then return nil end
    if BuffUp("FelDomination") then return SummonDemon() end
    if ctx.inCombat then
        local r = Try("FelDomination", false)
        if r then return r end
        if not O("petInCombat") then return nil end
    end
    return SummonDemon()
end

local function ArmorRule()
    if not O("armor") or ctx.inCombat then return nil end
    if BuffUp("DemonArmor") or BuffUp("DemonSkin") then return nil end
    return Try("DemonArmor", true) or Try("DemonSkin", true)
end

local function SacrificeRule()
    if not O("sacrifice") or sacTalent == 0 or sacrificed or ctx.pet ~= "alive" then return nil end
    return Try("DemonicSacrifice", true)
end

local function Reminders()
    return PetRule()
        or SacrificeRule()
        or ArmorRule()
        or (not ctx.inCombat and soulLink > 0 and ctx.pet == "alive" and not BuffUp("SoulLink") and Try("SoulLink", true))
        -- Savas oncesi: iblisi doldur, mana tamamla
        or (not ctx.inCombat and ctx.petHP and ctx.petHP < 50 and HealthAtLeast(70)
            and not Recent("HealthFunnel", 10) and Try("HealthFunnel", true))
        or (not ctx.inCombat and O("lifeTap") and ctx.mana and ctx.mana < 60 and HealthAtLeast(75)
            and not Recent("LifeTap", 3) and Try("LifeTap", true))
end

---------------------------------------------------------------------------
-- Curse / Bane / DoT'lar
---------------------------------------------------------------------------
local CURSE_KEY = { elements = "CurseOfTheElements", weakness = "CurseOfWeakness",
                    recklessness = "CurseOfRecklessness", tongues = "CurseOfTongues",
                    exhaustion = "CurseOfExhaustion" }

local function WantedCurse()
    local mode = O("curse")
    if mode == "none" then return nil end
    if CURSE_KEY[mode] then return CURSE_KEY[mode] end
    if ctx.kind == "player" then return Has("CurseOfExhaustion") and "CurseOfExhaustion" or "CurseOfTongues" end
    return Has("CurseOfTheElements") and "CurseOfTheElements" or "CurseOfWeakness"
end

local function CurseRule()
    if not (ctx.big or O("curseNormal")) or not TargetAbove(25) then return nil end
    local key = WantedCurse()
    if key and DebuffDue(key, 2) then return Try(key, true) end
end

local function BaneUp(key) return not DebuffDue(key, 0) end

local function BaneRule()
    if O("bane") == "none" or not TargetAbove(30) then return nil end
    -- Boss'ta Doom tek buyuk vurus; Agony onu kaldirirdi, bu yuzden Doom varken Agony yok
    if O("doom") and ctx.kind == "boss" and impAgony == 0 and Has("BaneOfDoom") then
        if DebuffDue("BaneOfDoom", 1) and not BaneUp("BaneOfHavoc") then return Try("BaneOfDoom", true) end
        return nil
    end
    if BaneUp("BaneOfDoom") or BaneUp("BaneOfHavoc") then return nil end
    if DebuffDue("BaneOfAgony", 1) then return Try("BaneOfAgony", true) end
end

local function CorruptionRule()
    if TargetAbove(25) and DebuffDue("Corruption", 1.5) then return Try("Corruption", true) end
end

-- Immolate bitmek uzere mi, ya da son Immolate'ten sonra Conflagrate ile tuketildi mi?
local function ImmolateDue(early)
    local imm = S("Immolate")
    local last = imm and ns.lastCast[imm.name] or 0
    -- Conflagrate'ten sonra dokulmekte olan (ya da tahminde atilmis) Immolate yeniden onerilmez
    return DebuffDue("Immolate", early)
        or (conflagAt > last and not (imm and ns.castingName == imm.name) and not (ns.sim and ns.sim.auras.Immolate))
end

local function ImmolateRule(minHP)
    if TargetAbove(minHP) and ImmolateDue(2) then return Try("Immolate", true) end
end

local function SiphonRule()
    if Has("SiphonLife") and TargetAbove(30) and DebuffDue("SiphonLife", 2) then return Try("SiphonLife", true) end
end

---------------------------------------------------------------------------
-- Dolgu, drain, mana
---------------------------------------------------------------------------
-- Drain Soul: shard sayisi dusukse ve hedef cani okunabilir ve %25 altindaysa
local function DrainSoulRule()
    if not O("drainSoul") or ctx.thp == nil or ctx.thp >= 25 then return nil end
    if ctx.shards ~= nil and ctx.shards >= O("shardMax") then return nil end
    return Try("DrainSoul", true)
end

-- Mana yetmiyor, Life Tap'e can yeter
local function LifeTapRule()
    if not O("lifeTap") or not ctx.oom or not HealthAtLeast(O("lifeTapHP")) then return nil end
    return Try("LifeTap", true)
end

local function FireFiller()
    local mode = O("destroFiller")
    if mode == "incinerate" then return true end
    return mode == "auto" and incin > 0 and snf >= 5
end

local function Filler()
    return (ns.Proc("ShadowBolt") and Try("ShadowBolt", true))       -- Shadow Trance (Nightfall)
        or DrainSoulRule()
        or LifeTapRule()
        or (spec == "DESTRO" and FireFiller() and Try("Incinerate", true))
        or Try("ShadowBolt", true)
end

---------------------------------------------------------------------------
-- Spec oncelikleri
---------------------------------------------------------------------------
local function Leveling()
    return ImmolateRule(40)
        or CorruptionRule()
        or BaneRule()   -- Agony seviye atlarken normal mob'da da guclu (BaneRule %30 altinda atmaz)
        or Filler()
end

local function Affliction()
    return CurseRule()
        or BaneRule()
        or CorruptionRule()
        or SiphonRule()
        or ((ctx.big or not Has("SiphonLife")) and ImmolateRule(60))
        or Filler()
end

local function Demonology()
    return CurseRule()
        or BaneRule()
        or CorruptionRule()
        or ImmolateRule(50)
        -- Demonic Brand: Searing Pain iblisin vuruslarini guclendirir
        or (brand > 0 and ctx.pet == "alive" and DebuffDue("SearingPain", 1) and Try("SearingPain", true))
        or (ns.Proc("SoulFire") and Try("SoulFire", true))           -- Decimation
        or Filler()
end

local function Destruction()
    local dots = O("destroDots") or ctx.kind == "boss"
    return CurseRule()
        or (dots and BaneRule())
        -- Conflagrate Immolate'i tuketir; sonra Immolate yenilenir
        or (not ImmolateDue(0) and Try("Conflagrate", true))
        or ImmolateRule(20)
        or (dots and CorruptionRule())
        or (O("shadowburn") and (snf >= 5 or (ctx.thp ~= nil and ctx.thp < 20))
            and ShardsAtLeast(3) and Try("Shadowburn", true))
        or (ns.Proc("SoulFire") and Try("SoulFire", true))
        or Filler()
end

local SINGLE = { LEVELING = Leveling, AFF = Affliction, DEMO = Demonology, DESTRO = Destruction }

---------------------------------------------------------------------------
-- AoE
---------------------------------------------------------------------------
local function AoE()
    return (ctx.enemies >= 4 and O("hellfire") > 0 and HealthAtLeast(O("hellfire")) and Try("Hellfire", true))
        or (spec == "DESTRO" and ctx.big and not BaneUp("BaneOfHavoc") and not BaneUp("BaneOfDoom")
            and not BaneUp("BaneOfAgony") and Try("BaneOfHavoc", true))
        or Try("RainOfFire", true)
end

local function Main()
    local r = Reminders()
    if r then return r end
    if ctx.aoe and ctx.inCombat then
        r = CorruptionRule() or AoE()
        if r then return r end
    end
    r = SINGLE[spec]()
    if r then return r end
    -- Mana bitti ve Life Tap olmuyor: asa
    if O("wand") and ctx.oom and Has("Shoot") and not ns.AutoRepeat("Shoot") and ns.Usable("Shoot", true) then
        return S("Shoot")
    end
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma
---------------------------------------------------------------------------
local function Extra()
    if not O("defensives") or not ctx.inCombat then return nil end
    return (HealthBelow(O("deathCoil")) and Try("DeathCoil", true))
        -- Howl 10 yd: sayim 20 yd'lik olcuyle; moblar ustumdeyken (fiziksel vurus yedim) oner
        or (not ctx.group and ctx.enemies >= 3 and ns.Near("target") == true and HealthBelow(O("howl"))
            and Try("HowlOfTerror", true))
        or (HealthBelow(O("drainLife")) and Try("DrainLife", true))
        or (O("healthFunnel") > 0 and ctx.petHP and ctx.petHP < O("healthFunnel") and HealthAtLeast(55)
            and not Recent("HealthFunnel", 10) and Try("HealthFunnel", true))
end

-- Buyuk cooldown'lar (Cooldowns.lua): default kullanim modu, cond sinifa ozel kosul
W.cooldowns = {
    -- Bane of Agony yenilenecekken: sonraki Agony %50 guclu
    { key = "AmplifyCurse", default = "big", cond = function()
        return Has("BaneOfAgony") and O("bane") ~= "none" and DebuffDue("BaneOfAgony", 1) end },
    -- Buyuk cekim: Infernal (reagent gerekir; kullanilamiyorsa Usable false doner)
    { key = "Inferno", default = "elite", cond = function() return ctx.enemies >= 5 end },
}
W.lowExtras = { AmplifyCurse = true }

function W.Next()
    ReadContext()
    return Main() or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function W.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AoE() or nil
end

function W.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | mana: %s | pet: %s %s | shard: %s | feda: %s"))
        :format(spec, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ctx.mana and ("%%%d"):format(math.floor(ctx.mana)) or "gizli",
                ctx.pet, ctx.petHP and ("%%%d"):format(math.floor(ctx.petHP)) or "",
                ctx.shards and tostring(ctx.shards) or "?", tostring(sacrificed)))
end
