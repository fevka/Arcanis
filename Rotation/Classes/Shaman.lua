local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local SH = {}
ns.classes.SHAMAN = SH
SH.enemyProbe = "Stormstrike"   -- Enhancement: yakin dovus menzili; bilinmiyorsa ~10 yd (Elemental / leveling)
SH.nearProbe  = "EarthShock"    -- savasta ~10 yd yerine Earth Shock menzili (20 yd; CheckInteractDistance savasta kisitli)

-- WoW Forever Shaman. Forever notlari (beta verisi):
--   * Bloodlust / Heroism, Earth Shield, Shamanistic Rage, Lava Lash yok; Fire Nova artik buyu (12),
--     Searing / Magma totemin etrafinda patlar. Totem 1 sn GCD, buff totemleri 5 dk.
--   * Shock'lar 6 sn cooldown paylasir (Earth / Flame / Frost). Flame Shock 12 sn (Call of Flame +3 sn / rank).
--   * Lava Burst (Elemental talent, 10 sn): Flame Shock hedefteyken +%20. Elemental Mastery 3 dk.
--   * Stormstrike 16 puanlik Enhancement talenti (8 sn): debuff'i sonraki LB / CL / Earth Shock'i guclendirir.
--     Maelstrom Weapon 5 yigin = anlik, bedava Lightning Bolt. Rage of the Farseer: +%30 hiz 25 sn.
--   * Water Shield Restoration talenti (Lightning Shield ile ayni anda olmaz). Riptide / Nature's Swiftness
--     / Mana Tide Resto talentleri.
-- Restoration: baska birimlerin cani savasta gizli. Grupta can esigine bagli iyilestirme ONERILMEZ;
-- Resto solo hasar rotasyonu + kendi canina iyilestirme + bakim (kalkan, totem) yapar.
-- Totemler hedefte / savasta kendi atislarimizdan takip edilir (duration + group = ayni elementten
-- yeni totem eskisinin kaydini siler); totem oldurulurse oyun bilgisi yok, kayit sure bitince duser.
SH.spells = {
    -- Hasar / shock
    LightningBolt  = { id = 403,     name = "Lightning Bolt" },
    ChainLightning = { id = 421,     name = "Chain Lightning" },
    LavaBurst      = { id = 408490,  name = "Lava Burst" },
    EarthShock     = { id = 8042,    name = "Earth Shock" },
    FlameShock     = { id = 8050,    name = "Flame Shock", duration = 12 },
    FrostShock     = { id = 8056,    name = "Frost Shock", duration = 8 },
    FireNova       = { id = 408341,  name = "Fire Nova" },
    Stormstrike    = { id = 17364,   name = "Stormstrike" },
    Purge          = { id = 370,     name = "Purge" },

    -- Kalkanlar (biri digerini kaldirir)
    LightningShield = { id = 324,    name = "Lightning Shield", duration = 600, unit = "player", group = "shield" },
    WaterShield     = { id = 408510, name = "Water Shield",     duration = 600, unit = "player", group = "shield" },

    -- Silah imbue'lari (60 dk; savas disinda GetWeaponEnchantInfo ile kontrol)
    RockbiterWeapon   = { id = 8017, name = "Rockbiter Weapon" },
    FlametongueWeapon = { id = 8024, name = "Flametongue Weapon" },
    WindfuryWeapon    = { id = 8232, name = "Windfury Weapon" },

    -- Totemler (group: bir elementte tek totem; noAura: aura degil, sadece kendi kaydimizla takip)
    SearingTotem = { id = 3599, name = "Searing Totem", duration = 55, unit = "player", group = "fire", noAura = true,
                     durationByRank = { [3599] = 30, [6363] = 35, [6364] = 40, [6365] = 45, [10437] = 50, [10438] = 55 } },
    MagmaTotem   = { id = 8190, name = "Magma Totem", duration = 20, unit = "player", group = "fire", noAura = true },
    StrengthOfEarthTotem = { id = 8075, name = "Strength of Earth Totem", duration = 300, unit = "player", group = "earth", noAura = true },
    StoneskinTotem       = { id = 8071, name = "Stoneskin Totem", duration = 300, unit = "player", group = "earth", noAura = true },
    StoneclawTotem       = { id = 5730, name = "Stoneclaw Totem", duration = 15, unit = "player", group = "earth", noAura = true },
    EarthbindTotem       = { id = 2484, name = "Earthbind Totem", duration = 45, unit = "player", group = "earth", noAura = true },
    GraceOfAirTotem      = { id = 8835, name = "Grace of Air Totem", duration = 300, unit = "player", group = "air", noAura = true },
    WindfuryTotem        = { id = 8512, name = "Windfury Totem", duration = 300, unit = "player", group = "air", noAura = true },
    GroundingTotem       = { id = 8177, name = "Grounding Totem", duration = 45, unit = "player", group = "air", noAura = true },
    ManaSpringTotem      = { id = 5675, name = "Mana Spring Totem", duration = 300, unit = "player", group = "water", noAura = true },
    HealingStreamTotem   = { id = 5394, name = "Healing Stream Totem", duration = 300, unit = "player", group = "water", noAura = true },

    -- Iyilestirme (kendine)
    HealingWave       = { id = 331,   name = "Healing Wave" },
    LesserHealingWave = { id = 8004,  name = "Lesser Healing Wave" },
    NaturesSwiftness  = { id = 16188, name = "Nature's Swiftness" },

    -- Cooldown'lar (Bloodlust / Heroism Forever'da yok; varsa kullanilir)
    ElementalMastery = { id = 16166,  name = "Elemental Mastery" },
    RageOfTheFarseer = { id = 425336, name = "Rage of the Farseer" },
    Bloodlust        = { id = 2825,   name = "Bloodlust" },
    Heroism          = { id = 32182,  name = "Heroism" },
}
SH.interrupts = { "EarthShock" }

SH.options = {
    { type = "header", label = "Rotasyon" },
    { type = "cycle", key = "shield", default = "auto", label = "Kalkan",
      values = { "auto", "lightning", "water", "none" },
      names = { auto = "Otomatik", lightning = "Lightning Shield", water = "Water Shield", none = "Kapali" },
      tip = "Otomatik: Resto'da Water Shield (varsa), digerlerinde Lightning Shield." },
    { type = "cycle", key = "imbue", default = "auto", label = "Silah imbue hatirlaticisi (savas disi)",
      values = { "auto", "rockbiter", "flametongue", "windfury", "none" },
      names = { auto = "Otomatik", rockbiter = "Rockbiter", flametongue = "Flametongue", windfury = "Windfury", none = "Kapali" },
      tip = "Otomatik: Enhancement Windfury (yoksa Rockbiter), digerleri Flametongue (yoksa Rockbiter)." },
    { type = "toggle", key = "flameNormal", default = true, label = "Normal mob'lara da Flame Shock",
      tip = "Kapaliyken sadece elit / boss / oyuncu / grup hedeflerde." },
    { type = "slider", key = "shockMana", default = 30, min = 0, max = 90, step = 5, zero = "Her zaman",
      label = "Dolgu shock icin mana %",
      tip = "Savas disinda gercek mana. Savasta mana gizli: Earth Shock'in manasi kaliyorsa." },

    { type = "header", label = "Totemler" },
    { type = "toggle", key = "totems", default = true, label = "Hasar totemi (Searing / Magma)",
      tip = "Savasta hedef varken Searing Totem; AoE'de Magma Totem. Kapaliyken hic totem onerilmez." },
    { type = "toggle", key = "buffTotems", default = true, label = "Grupta buff totemleri",
      tip = "Enhancement: Strength of Earth + Windfury / Grace of Air; Elemental / Resto: Mana Spring. Sadece grupta." },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "selfHeal",   default = 35, min = 0, max = 90, step = 5, zero = "Kapali", label = "Kendine Healing Wave (savasta)" },
    { type = "slider", key = "natSwift",   default = 25, min = 0, max = 90, step = 5, zero = "Kapali", label = "Nature's Swiftness + anlik heal" },
    { type = "slider", key = "healOoc",    default = 60, min = 0, max = 100, step = 5, zero = "Kapali", label = "Savas disi can tamamlama" },
    { type = "slider", key = "stoneclaw",  default = 40, min = 0, max = 90, step = 5, zero = "Kapali", label = "Stoneclaw Totem (yalniz, mob ustundeyken)" },
    { type = "slider", key = "earthbind",  default = 0,  min = 0, max = 90, step = 5, zero = "Kapali", label = "Earthbind Totem (yalniz, mob ustundeyken)" },
    { type = "toggle", key = "grounding",  default = false, label = "Grounding Totem (hedef buyu atarken)",
      tip = "Earth Shock cooldown'dayken hedef cast ediyorsa." },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local BuffUp = ns.BuffUp

local SPECS = { "ELE", "ENH", "RESTO" }
local spec, callOfFlame = "LEVELING", 0
function SH.OnRefresh()
    spec = SPECS[ns.MainTalentTab()] or "LEVELING"
    callOfFlame = ns.TalentRank("Call of Flame")
end

---------------------------------------------------------------------------
-- Kendi atislarimizdan takip (savasta aura verisi gizli)
---------------------------------------------------------------------------
-- Flame Shock: Call of Flame sureyi uzatir (spells tanimi temel 12 sn), kendi tahminimiz
local flameAt = 0
-- Stormstrike debuff'i: sonraki LB / CL / Earth Shock harcar (12 sn)
local ssAt, ssSpent = 0, true
-- Nature's Swiftness: sonraki Nature buyusu anlik (30 sn)
local nsAt = 0
local SPEND = { EarthShock = true, LightningBolt = true, ChainLightning = true }
local NATURE = { HealingWave = true, LesserHealingWave = true, LightningBolt = true, ChainLightning = true }

-- Totem yeri: atildigi an oyuncunun dunya konumu (element basina). Totem menzili kisa; oyuncu
-- TOTEM_RANGE'den uzaklasinca totem "yok" sayilir (yeni mob'a yeni totem). Olunce hepsi gider (false).
local TOTEM_RANGE = 20
local totemPos = {}
local function PlayerPos()
    local ok, y, x = pcall(UnitPosition, "player")
    if not ok or ns.issecret(y) or ns.issecret(x) or type(y) ~= "number" or type(x) ~= "number" then return nil end
    return x, y
end

-- Lightning Shield 3 orb: atistan beri yenen fiziksel vuruslar (aura savasta okunamiyorsa kayit yerine)
local lsHits = 0
-- Imbue'larimizin silah buyusu kimlikleri (kendi atisimizdan ogrenilir; bileme tasi imbue sayilmaz)
local IMBUES = { RockbiterWeapon = true, FlametongueWeapon = true, WindfuryWeapon = true }
local function MainHandEnchant()
    local ok, has, _, _, id = pcall(GetWeaponEnchantInfo)
    if not ok or ns.issecret(has) or ns.issecret(id) then return nil end
    return has and true or false, id
end

function SH.OnCast(key)
    local now = GetTime()
    if key == "LightningShield" then lsHits = 0 end
    if IMBUES[key] and ns.cdb and C_Timer then
        C_Timer.After(0.5, function()
            local has, id = MainHandEnchant()
            if has and type(id) == "number" then
                ns.cdb.imbueIds = ns.cdb.imbueIds or {}
                ns.cdb.imbueIds[id] = true
            end
        end)
    end
    local def = SH.spells[key]
    if def and def.group and def.noAura then
        local x, y = PlayerPos()
        totemPos[def.group] = x and { x, y } or true
    end
    if key == "FlameShock" then flameAt = now end
    if key == "Stormstrike" then ssAt, ssSpent = now, false
    elseif SPEND[key] then ssSpent = true end
    if key == "NaturesSwiftness" then nsAt = now
    elseif NATURE[key] then nsAt = 0 end
end

local targetEv = CreateFrame("Frame")
pcall(targetEv.RegisterEvent, targetEv, "PLAYER_TARGET_CHANGED")
pcall(targetEv.RegisterEvent, targetEv, "PLAYER_DEAD")
pcall(targetEv.RegisterUnitEvent, targetEv, "UNIT_COMBAT", "player")
targetEv:SetScript("OnEvent", function(_, event, _, action, _, amount, school)
    if event == "UNIT_COMBAT" then
        if not (ns.issecret(action) or ns.issecret(school) or ns.issecret(amount))
            and action == "WOUND" and school == 1 and type(amount) == "number" and amount > 0 then
            lsHits = lsHits + 1
        end
        return
    end
    if event == "PLAYER_DEAD" then
        for _, g in ipairs({ "fire", "earth", "air", "water" }) do totemPos[g] = false end
        return
    end
    flameAt, ssAt, ssSpent = 0, 0, true
end)

local function StormstrikeUp() return not ssSpent and GetTime() - ssAt < 12 end
local function NSActive() return nsAt > 0 and GetTime() - nsAt < 30 end

-- Flame Shock bitmesine `early` sn'den az mi kaldi? (aura okunamazsa kendi tahminimiz)
local function FlameDue(early)
    local rem = ns.AuraRemaining("target", "FlameShock", "HARMFUL|PLAYER")
    local est = flameAt > 0 and (flameAt + 12 + 3 * callOfFlame - GetTime()) or 0
    -- aura API savasta calisiyorsa (AuraRemaining ona guveniyor) tahmin gercek "yok"u ezmez: dirlenen /
    -- bagisik hedefte Flame Shock 12+ sn yenilenmiyordu
    if ns.AuraTrusted("target", "FlameShock") and GetTime() - flameAt > 1.5 then est = 0 end
    return math.max(rem, est) <= (early or 0)
end

local DebuffDue = ns.DebuffDue

---------------------------------------------------------------------------
-- Durum
---------------------------------------------------------------------------
local ctx = {}

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    -- Totem / saldiri onerileri icin saldirilabilir, canli hedef (dost ya da olu hedefte degil)
    ctx.target   = ns.Call(UnitCanAttack, "player", "target") == true and ns.Call(UnitIsDead, "target") ~= true
    ctx.near     = ns.Near("target") == true   -- ~10 yd (savasta nearProbe menzili)
    ctx.melee    = ns.InRange("Stormstrike") == true or (not Has("Stormstrike") and ctx.near)
    ctx.moving   = (ns.Call(GetUnitSpeed, "player") or 0) > 0
    ctx.health   = ns.HealthPercent()
    local n = ns.EnemiesNearby() or 0
    if ctx.near and n < 1 then n = 1 end
    ctx.enemies  = n
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and n >= O("aoeAt")
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

-- Savasta mana gizli: Earth Shock'in manasini yemeyen dolgu
local function SpareMana(pct)
    if pct <= 0 then return true end
    local m = ns.ManaPercent()
    if m then return m >= pct end
    return not ns.NoPower("EarthShock")
end

-- Flame Shock'a deger mi (elit / grup / oyuncu ya da ayar)
local function FlameWorth() return ctx.big or O("flameNormal") end

---------------------------------------------------------------------------
-- Hatirlaticilar: kalkan, silah imbue, savas disi iyilestirme
---------------------------------------------------------------------------
local function WantedShield()
    local o = O("shield")
    if o == "none" then return nil end
    if o == "water" and Has("WaterShield") then return "WaterShield" end
    if o == "lightning" then return Has("LightningShield") and "LightningShield" or nil end
    if spec == "RESTO" and Has("WaterShield") then return "WaterShield" end
    return Has("LightningShield") and "LightningShield" or (Has("WaterShield") and "WaterShield" or nil)
end

local function ShieldRule()
    local want = WantedShield()
    if not want then return nil end
    -- Savasta orblar bitince yenile; savas disinda bitmesine 1 dk kala
    if ns.AuraRemaining("player", want, "HELPFUL") <= (ctx.inCombat and 0 or 60) then
        return Try(want, true)
    end
    -- aura API savasta calismiyorsa kayit 10 dk "var" der: 3 vurusta orblar biter
    if want == "LightningShield" and ctx.inCombat and not ns.AuraTrusted("player", "LightningShield") and SH.ShieldSpent() then
        return Try(want, true)
    end
end

function SH.ShieldSpent() return lsHits >= 3 end

local function WantedImbue()
    local o = O("imbue")
    if o == "none" then return nil end
    local map = { rockbiter = "RockbiterWeapon", flametongue = "FlametongueWeapon", windfury = "WindfuryWeapon" }
    if map[o] and Has(map[o]) then return map[o] end
    if spec == "ENH" and Has("WindfuryWeapon") then return "WindfuryWeapon" end
    if spec ~= "ENH" and Has("FlametongueWeapon") then return "FlametongueWeapon" end
    return Has("RockbiterWeapon") and "RockbiterWeapon" or nil
end

-- Ana el buyulu degil ya da buyu bizim imbue'larimizdan biri degil (bileme tasi). Savasta okunamazsa (gizli)
-- oneri yok; okunabiliyorsa savasta biten imbue de yenilenir.
function SH.ImbueMissing()
    local has, id = MainHandEnchant()
    if has == nil then return false end
    if not has then return true end
    local known = ns.cdb and ns.cdb.imbueIds
    return known ~= nil and next(known) ~= nil and type(id) == "number" and not known[id]
end

local function ImbueRule()
    local want = WantedImbue()
    if want and SH.ImbueMissing() then return Try(want, true) end
end

local function Reminders()
    local r = ShieldRule() or ImbueRule()
    if r then return r end
    if not ctx.inCombat and HealthBelow(O("healOoc")) then
        return Try("LesserHealingWave", true) or Try("HealingWave", true)
    end
end

---------------------------------------------------------------------------
-- Totemler (kendi atislarimizdan takip, savasta ve hedef varken)
---------------------------------------------------------------------------
-- Kayit suruyor, olmedik ve totemin yanindayiz (konum bilinmiyorsa kayda guvenilir)
function SH.TotemHere(key)
    if not BuffUp(key) then return false end
    local p = totemPos[SH.spells[key].group]
    if p == false then return false end
    if type(p) ~= "table" then return true end
    local x, y = PlayerPos()
    return not x or (x - p[1]) ^ 2 + (y - p[2]) ^ 2 <= TOTEM_RANGE ^ 2
end

local function TotemUp(...)
    for i = 1, select("#", ...) do
        if SH.TotemHere((select(i, ...))) then return true end
    end
    return false
end

local function FireTotemUp() return TotemUp("SearingTotem", "MagmaTotem") end

local function DamageTotem()
    if not O("totems") or not ctx.inCombat or not ctx.target then return nil end
    -- Totem menzili kisa: kosan / uzaktaki mob'a birakma
    if ctx.group and not ctx.near and not ctx.melee then return nil end
    if not FireTotemUp() then return Try("SearingTotem", true) end
end

-- Grupta buff totemleri: Enhancement Strength of Earth + Windfury / Grace of Air, digerleri Mana Spring
local function BuffTotems()
    if not O("buffTotems") or not ctx.group or not ctx.inCombat or not ctx.target then return nil end
    if spec == "ENH" then
        if not TotemUp("StrengthOfEarthTotem", "StoneclawTotem", "EarthbindTotem") then
            local r = Try("StrengthOfEarthTotem", true)
            if r then return r end
        end
        if not TotemUp("WindfuryTotem", "GraceOfAirTotem", "GroundingTotem") then
            return Try("WindfuryTotem", true) or Try("GraceOfAirTotem", true)
        end
    elseif not TotemUp("ManaSpringTotem", "HealingStreamTotem") then
        return Try("ManaSpringTotem", true) or Try("HealingStreamTotem", true)
    end
end

---------------------------------------------------------------------------
-- AoE (2+ dusman)
---------------------------------------------------------------------------
local function AoE()
    return (ctx.near and ctx.enemies >= 3 and O("totems") and not TotemUp("MagmaTotem") and Try("MagmaTotem", true))
        or (ctx.near and FireTotemUp() and Try("FireNova", true))
        or (spec == "ENH" and ns.Proc("LightningBolt") and Try("LightningBolt", true))   -- Maelstrom Weapon
        or Try("ChainLightning", true)
end

---------------------------------------------------------------------------
-- Tek hedef oncelikleri (ana ikon)
---------------------------------------------------------------------------
-- Elemental / leveling / Resto solo: Flame Shock, Lava Burst, shock, Lightning Bolt
local function Caster()
    -- shock'lar 20 yd: uzaktan acilista Lightning Bolt'a dusulur
    return (FlameWorth() and FlameDue(2) and ns.InRange("FlameShock") ~= false and Try("FlameShock", true))
        or (not FlameDue(0) and Try("LavaBurst", true))          -- Flame Shock +%20
        or (ctx.kind == "player" and DebuffDue("FrostShock") and Try("FrostShock", true))
        -- Hareket halinde ya da Lava Burst yokken anlik shock
        -- Flame Shock bilinmiyor / istenmiyorsa (1-9. level, normal mob) Earth Shock'u engellemesin
        or ((ctx.moving or not Has("LavaBurst")) and SpareMana(O("shockMana"))
            and (not Has("FlameShock") or not FlameWorth() or not FlameDue(4.5)) and ns.InRange("EarthShock") ~= false
            and Try("EarthShock", true))
        or (ctx.moving and Try("FrostShock", true))
        or (not ctx.moving and Try("LightningBolt", true))   -- yururken dokulemez
end

local function Elemental()
    return Caster()
end

local function Enhancement()
    return (ctx.melee and Try("Stormstrike", true))
        or (ns.Proc("LightningBolt") and Try("LightningBolt", true))   -- Maelstrom Weapon 5 yigin
        or (ctx.melee and FlameWorth() and FlameDue(0) and Try("FlameShock", true))
        -- Stormstrike debuff'ini harcamak ya da Stormstrike yokken shock
        or ((StormstrikeUp() or not Has("Stormstrike")) and SpareMana(O("shockMana")) and Try("EarthShock", true))
        or (ctx.melee and FireTotemUp() and Try("FireNova", true))
        -- Menzil disinda: yaklasirken Lightning Bolt
        or (not ctx.melee and not ctx.moving and Try("LightningBolt", true))
end

local function Resto()
    return Caster()
end

local SINGLE = { LEVELING = Caster, ELE = Elemental, ENH = Enhancement, RESTO = Resto }

local function Main()
    local r = Reminders()
    if r then return r end
    if ctx.aoe and ctx.inCombat then
        -- AoE'de once Magma Totem vb. (Searing once gelirse Magma onu silip bir GCD bosa gider)
        r = AoE() or DamageTotem()
        if r then return r end
    end
    -- AoE ayri ikondayken (aoeDisplay "separate") Magma isteniyorsa ana ikon Searing dikmez (Magma onu silerdi)
    -- AoE kapaliyken Magma onerilmez: Searing yine gelsin (yoksa hic ates totemi yoktu); esik AoE ayari
    local magmaWanted = ctx.near and O("aoe") and (ctx.enemies or 0) >= (O("aoeAt") or 3) and O("totems") and Has("MagmaTotem")
    r = (not magmaWanted and DamageTotem()) or BuffTotems()
    if r then return r end
    return SINGLE[spec]()
end

---------------------------------------------------------------------------
-- Kucuk ikon: savunma / kendine iyilestirme
---------------------------------------------------------------------------
-- Hedef buyu atiyorsa Grounding Totem (Earth Shock hazir degilse; hazirsa interrupt ikonu kullanir)
local function TargetCasting()
    local kind = ns.TargetCast()
    return kind ~= nil
end

local function Defensive()
    if not ctx.inCombat or not O("defensives") then return nil end
    -- Nature's Swiftness bekliyorsa anlik heal
    if NSActive() and HealthBelow(O("natSwift") + 15) then
        local r = Try("HealingWave", true)
        if r then return r end
    end
    return (HealthBelow(O("natSwift")) and not NSActive() and Try("NaturesSwiftness", true))
        or (not ctx.group and ctx.near and HealthBelow(O("stoneclaw")) and not TotemUp("StoneclawTotem") and Try("StoneclawTotem", true))
        or (not ctx.group and ctx.near and HealthBelow(O("earthbind")) and not TotemUp("EarthbindTotem") and Try("EarthbindTotem", true))
        or (O("grounding") and ctx.target and TargetCasting() and not ns.Ready("EarthShock")
            and not TotemUp("GroundingTotem") and Try("GroundingTotem", true))
        or (HealthBelow(O("selfHeal")) and (Try("LesserHealingWave", true) or Try("HealingWave", true)))
end

local function Extra()
    return Defensive()
    -- Buyuk cooldown'lar Cooldowns.lua'da (SH.cooldowns)
end

-- Buyuk cooldown'lar (Cooldowns.lua): default kullanim modu, cond sinifa ozel kosul
SH.cooldowns = {
    { key = "ElementalMastery", default = "big", cond = function() return ctx.inCombat and spec ~= "RESTO" end },
    { key = "RageOfTheFarseer", default = "big", cond = function() return ctx.inCombat and ctx.melee end },
    { key = "Bloodlust",        default = "elite" },
    { key = "Heroism",          default = "elite" },
    -- Resto / Elemental: dusuk canda anlik heal icin
    { key = "NaturesSwiftness", default = "always",
      cond = function() return ctx.inCombat and O("defensives") and HealthBelow(O("natSwift")) and not NSActive() end },
}
SH.lowExtras = {}

function SH.Next()
    ReadContext()
    return Main() or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function SH.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    return AoE() or nil
end

function SH.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | mana: %s | hedef: %s | Stormstrike: %s | Flame Shock: %s"))
        :format(spec, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ns.ManaPercent() and ("%%%d"):format(math.floor(ns.ManaPercent())) or "gizli",
                ctx.kind, tostring(StormstrikeUp()), tostring(not FlameDue(0))))
end
