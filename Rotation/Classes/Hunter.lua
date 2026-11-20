local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

local H = {}
ns.classes.HUNTER = H
-- Dusman sayimi Multi-Shot menzilinde: Hunter uzaktan vurur, yakin dovus menzili
-- (Raptor Strike) ile sayilirsa Multi-Shot / Volley neredeyse hic onerilmezdi.
H.enemyProbe = "MultiShot"

-- WoW Forever Hunter. Forever notlari (beta verisi):
--   * Kaynak hala mana (Focus yok), cephane kullaniliyor, 8 yd olu bolge var.
--   * Aimed Shot 20'de temel; Multi-Shot ile 6 sn cooldown paylasir (Multi-Shot artik anlik).
--   * Arcane Shot (6 sn) cooldown'unu Summon Hawk ile paylasir (BM talenti, en fazla 2 sahin, 18 sn).
--   * Survival yakin dovus spec'i: Strider Kick, Lacerate (30), Mongoose Bite.
H.spells = {
    -- Atislar
    AutoShot       = { id = 75,      name = "Auto Shot" },
    ArcaneShot     = { id = 3044,    name = "Arcane Shot" },
    AimedShot      = { id = 19434,   name = "Aimed Shot" },
    MultiShot      = { id = 2643,    name = "Multi-Shot" },
    SerpentSting   = { id = 1978,    name = "Serpent Sting", duration = 15 },
    HuntersMark    = { id = 1130,    name = "Hunter's Mark", duration = 120 },
    ConcussiveShot = { id = 5116,    name = "Concussive Shot", duration = 4 },
    SniperShot     = { id = 1310687, name = "Sniper Shot" },
    Volley         = { id = 1510,    name = "Volley" },

    -- Yakin dovus
    RaptorStrike   = { id = 2973,    name = "Raptor Strike" },
    MongooseBite   = { id = 1495,    name = "Mongoose Bite" },
    WingClip       = { id = 2974,    name = "Wing Clip", duration = 10 },
    Lacerate       = { id = 24118,   name = "Lacerate", duration = 21 },
    StriderKick    = { id = 1317257, name = "Strider Kick" },
    Counterattack  = { id = 19306,   name = "Counterattack" },
    ExplosiveTrap  = { id = 13813,   name = "Explosive Trap" },

    -- Pet
    CallPet        = { id = 883,     name = "Call Pet" },
    RevivePet      = { id = 982,     name = "Revive Pet" },
    MendPet        = { id = 136,     name = "Mend Pet" },
    Intimidation   = { id = 19577,   name = "Intimidation" },
    BestialWrath   = { id = 19574,   name = "Bestial Wrath" },
    SummonHawk     = { id = 1293241, name = "Summon Hawk" },

    -- Aspect'ler (biri digerini kaldirir) ve auralar
    AspectHawk     = { id = 13165,   name = "Aspect of the Hawk",    duration = 3600, unit = "player", group = "aspect" },
    AspectMonkey   = { id = 13163,   name = "Aspect of the Monkey",  duration = 3600, unit = "player", group = "aspect" },
    AspectBeast    = { id = 13161,   name = "Aspect of the Beast",   duration = 3600, unit = "player", group = "aspect" },
    AspectCheetah  = { id = 5118,    name = "Aspect of the Cheetah", duration = 3600, unit = "player", group = "aspect" },
    AspectPack     = { id = 13159,   name = "Aspect of the Pack",    duration = 3600, unit = "player", group = "aspect" },
    TrueshotAura   = { id = 19506,   name = "Trueshot Aura" },

    -- Savunma / cooldown
    RapidFire      = { id = 3045,    name = "Rapid Fire" },
    FeignDeath     = { id = 5384,    name = "Feign Death" },
    Deterrence     = { id = 19263,   name = "Deterrence" },
}

H.options = {
    { type = "header", label = "Rotasyon" },
    { type = "toggle", key = "mark",   default = true, label = "Hunter's Mark",
      tip = "Elit, grup ve oyuncu hedeflerde. Tek basina normal mob'larda onerilmez." },
    { type = "toggle", key = "aspect", default = true, label = "Aspect hatirlatici",
      tip = "Savasta Cheetah / Pack acik kalirsa da uyarir." },
    { type = "toggle", key = "pet",    default = true, label = "Pet hatirlatici (Call / Revive Pet)" },
    { type = "toggle", key = "melee",  default = true, label = "Olu bolgede yakin dovus",
      tip = "BM / MM: mob ustune gelince Raptor Strike / Mongoose Bite." },

    { type = "header", label = "AoE" },
    { type = "toggle", key = "aoe", default = true, label = "AoE oncelikleri",
      tip = "Dusman nameplate'leri acik olmali (V tusu)." },
    { type = "slider", key = "aoeAt", default = 3, min = 2, max = 6, step = 1, label = "AoE icin dusman sayisi" },
    { type = "toggle", key = "multiSingle", default = false, label = "Tek hedefte Multi-Shot (tek basina)",
      tip = "Kapali: grupta degilken Multi-Shot yalniz AoE'de onerilir (yandaki moblari cekebilir, mana yer)." },

    { type = "header", label = "Mana" },
    { type = "slider", key = "arcaneMana", default = 40, min = 0, max = 90, step = 5, zero = "Her zaman",
      label = "Arcane Shot icin mana %",
      tip = "Savas disinda gercek mana. Savasta mana gizli: Aimed / Multi-Shot'in manasi kaliyorsa." },

    { type = "header", label = "Savunma (kucuk ikon, can %)" },
    { type = "toggle", key = "defensives", default = true, label = "Savunma onerileri" },
    { type = "slider", key = "deterrence", default = 35, min = 0, max = 90, step = 5, zero = "Kapali", label = "Deterrence" },
    { type = "slider", key = "feignDeath", default = 30, min = 0, max = 90, step = 5, zero = "Kapali", label = "Feign Death (grupta)" },
    { type = "slider", key = "mendPet",    default = 40, min = 0, max = 90, step = 5, zero = "Kapali", label = "Mend Pet (pet cani)" },
}

local function O(key) return ns.cdb[key] end
local function S(key) return ns.spells[key] end
local function Has(key) return ns.spells[key] ~= nil end

local Try = ns.Try
local DebuffDue = ns.DebuffDue
local BuffUp = ns.BuffUp

local Recent = ns.Recent

local SPECS = { "BM", "MM", "SV" }
local spec, loneWolf = "LEVELING", false
function H.OnRefresh()
    spec = SPECS[ns.MainTalentTab()] or "LEVELING"
    loneWolf = ns.TalentRank("Lone Wolf") > 0
end

---------------------------------------------------------------------------
-- Sahinler (Summon Hawk): her biri 18 sn yasar, en fazla 2, hedefe bagli
---------------------------------------------------------------------------
local hawks = {}
local hawkGUID   -- sahinlerin saldirdigi hedef
local stingTries, stingGUID = {}, nil   -- Serpent Sting atislari (StingRefused)

function H.OnCast(key)
    if key == "SerpentSting" then
        local g = ns.Call(UnitGUID, "target")
        if g ~= stingGUID then stingGUID, stingTries = g, {} end
        stingTries[#stingTries + 1] = GetTime()
        return
    end
    if key ~= "SummonHawk" then return end
    local g = ns.Call(UnitGUID, "target")
    if g ~= hawkGUID then wipe(hawks) end
    hawkGUID = g
    hawks[#hawks + 1] = GetTime()
    if #hawks > 2 then table.remove(hawks, 1) end
end

local hawkEv = CreateFrame("Frame")
pcall(hawkEv.RegisterEvent, hawkEv, "PLAYER_TARGET_CHANGED")
hawkEv:SetScript("OnEvent", function()
    local g = ns.Call(UnitGUID, "target")
    if not (g and g == hawkGUID) then wipe(hawks) end
end)

-- 2'den az sahin var ya da eskisinin `margin` (3) sn'den az kaldi
local function NeedHawk(margin)
    local now, alive, oldest = GetTime(), 0, nil
    for _, t in ipairs(hawks) do
        if now - t < 18 then
            alive = alive + 1
            oldest = oldest and math.min(oldest, t) or t
        end
    end
    return alive < 2 or (18 - (now - oldest)) < (margin or 3)
end
H.NeedHawk = NeedHawk

---------------------------------------------------------------------------
-- Durum
---------------------------------------------------------------------------
local ctx = {}

local function ReadContext()
    ctx.inCombat = ns.InCombat()
    ctx.kind     = ns.TargetKind()
    ctx.group    = IsInGroup() and true or false
    ctx.dungeon  = ns.InstanceType() == "party"
    ctx.big      = ctx.kind ~= "normal" or ctx.group
    -- Olu bolgede: Raptor menzili tek basina guvenilmez (uzakta true donebilir);
    -- Auto Shot menzildeyse (8 yd disi) yakin dovus olamaz.
    -- Hedef Auto Shot menzilinin de OTESINDEYKEN (acilis, 35 yd+) ikisi ayni sonucu verir: ayrica yakinlik gerekir.
    -- Savas disi ~10 yd olcumu (CheckInteractDistance) kesin; savasta (olcum kisitli) mob son birkac saniyede
    -- bize vurduysa ustumdedir (sahibin bulgusu, 15 Kasim 2026: uzaktaki hedefe acilis Raptor Strike oneriliyordu).
    -- Savasta yalniz yakin olcum "uzak" derse dislanir: pet tanklarken mob bize vurmaz, SV yine yakin dovusmeli
    -- (inceleme 15 Kasim 2026: "son 3 sn'de vurus yedi" sarti SV'yi uzak dala itiyordu).
    local near
    if ctx.inCombat then near = ns.Near("target") ~= false
    else near = ns.Near("target") == true end
    ctx.melee    = near and ns.InRange("RaptorStrike") == true and ns.InRange("AutoShot") ~= true
    ctx.health   = ns.HealthPercent()
    ctx.pet      = ns.PetState()
    ctx.petHP    = ctx.pet == "alive" and ns.HealthPercent("pet") or nil
    ctx.enemies  = ns.EnemiesNearby() or 0
    ctx.aoe      = ns.aoeForce ~= "single" and O("aoe") and ctx.enemies >= O("aoeAt")
end

local function HealthBelow(p) return p > 0 and ctx.health ~= nil and ctx.health < p end

-- Savasta mana gizli: Aimed / Multi-Shot'in manasini yemeyen dolgu
local function SpareMana(pct)
    if pct <= 0 then return true end
    local m = ns.ManaPercent()
    if m then return m >= pct end
    if Has("AimedShot") then return not ns.NoPower("AimedShot") end
    return true
end

---------------------------------------------------------------------------
-- Hatirlaticilar (pet, aspect, aura)
---------------------------------------------------------------------------
local COMBAT_ASPECTS = { "AspectHawk", "AspectBeast", "AspectMonkey" }

local function WantedAspect()
    if spec == "SV" and Has("AspectBeast") then return "AspectBeast" end
    if Has("AspectHawk") then return "AspectHawk" end
    return "AspectMonkey"
end

local function AspectRule()
    if not O("aspect") then return nil end
    local wanted = WantedAspect()
    for _, k in ipairs(COMBAT_ASPECTS) do
        if BuffUp(k) then
            -- savas disinda daha iyi aspect ogrenildiyse (Monkey -> Hawk) ona gec
            if k ~= wanted and not ctx.inCombat and Has(wanted) then return Try(wanted, true) end
            return nil
        end
    end
    -- Savas disinda Cheetah / Pack ile yolculuk ediyorsan karisma
    local travel = BuffUp("AspectCheetah") or BuffUp("AspectPack")
    if travel and not ctx.inCombat then return nil end
    return Try(wanted, true)
end

-- Savasta pet hatirlatmasi ana ikonu ele gecirmez (Revive Pet uzun dokum); Call Pet yeni denendiyse ve pet gelmediyse
-- (terk edilmis / ahirda) tekrar onerilmez
local function PetRule()
    if not O("pet") or loneWolf or ctx.inCombat then return nil end
    if ctx.pet == "dead" then return Try("RevivePet", true) end
    if ctx.pet ~= "none" then return nil end
    -- relog sonrasi olu pet "none" gorunur: Call Pet yeni basarisiz olduysa Revive Pet
    local s = ns.spells.CallPet
    if s and GetTime() - (ns.lastFail[s.name] or -99) < 30 then return Try("RevivePet", true) end
    if not Recent("CallPet", 10) then return Try("CallPet", true) end
end

local function Reminders()
    return PetRule()
        or AspectRule()
        or (not ctx.inCombat and Has("TrueshotAura") and not BuffUp("TrueshotAura") and Try("TrueshotAura", true))
        or (not ctx.inCombat and ctx.petHP and ctx.petHP < 60 and not Recent("MendPet", 15) and Try("MendPet", true))
end

local function MarkRule()
    if O("mark") and ctx.big and DebuffDue("HuntersMark") then return Try("HuntersMark", true) end
end

-- Ayni hedefe ust uste atilip tutmayan sting (bagisiklik, evade): hedef degisene kadar onerilmez; yoksa
-- bekleme suresi olmayan Serpent Sting ana ikonda sonsuza dek kalirdi.
local function StingRefused()
    local g = ns.Call(UnitGUID, "target")
    if g ~= stingGUID then stingGUID, stingTries = g, {} end
    local now, n = GetTime(), 0
    for _, t in ipairs(stingTries) do if now - t < 12 then n = n + 1 end end
    return n >= 2
end

local function SerpentRule()
    if DebuffDue("SerpentSting") and not StingRefused() then return Try("SerpentSting", true) end
end

---------------------------------------------------------------------------
-- Uzak mesafe oncelikleri (BM / MM / leveling)
---------------------------------------------------------------------------
-- Tek hedef listesinde Multi-Shot: grupta (ya da ayar acikken); tek basina yandaki moblari ceker
local function SingleMulti()
    return (ctx.group or O("multiSingle")) and Try("MultiShot", true)
end

local function RangedAoE()
    return Try("MultiShot", true)
        or (ctx.enemies >= 4 and Try("Volley", true))
end

local function Leveling()
    return MarkRule()
        or (SpareMana(O("arcaneMana")) and Try("ArcaneShot", true))
        or SerpentRule()
        -- Pet yokken (1-9) mob'u yavaslat
        or (ctx.pet ~= "alive" and ctx.inCombat and DebuffDue("ConcussiveShot") and not Recent("ConcussiveShot", 8)
            and Try("ConcussiveShot", true))
        or Try("AimedShot", true)
        or SingleMulti()
end

local function BeastMastery()
    return (ctx.dungeon and Try("AimedShot", true))   -- zindanda Multi-Shot CC kirabilir
        or MarkRule()
        or SerpentRule()
        or (NeedHawk() and Try("SummonHawk", true))
        or SingleMulti()
        -- Arcane Shot sahinle 6 sn cooldown paylasir: eski sahinin 9 sn'den fazlasi varsa arada atilir
        or ((not Has("SummonHawk") or not NeedHawk(9)) and SpareMana(O("arcaneMana")) and Try("ArcaneShot", true))
end

local function Marksmanship()
    return SerpentRule()
        or (ctx.group and not ns.NoPower("AimedShot") and Try("MultiShot", true))
        or MarkRule()
        or (ns.Proc("AimedShot") and Try("AimedShot", true))      -- Rapid Killing
        or Try("AimedShot", true)
        or (not ns.NoPower("AimedShot") and SingleMulti())
        or ((ctx.big or not ctx.inCombat) and Try("SniperShot", true))
        or (SpareMana(O("arcaneMana")) and Try("ArcaneShot", true))
end

-- Olu bolge: mob ustundeyken yakin dovus
local function DeadZone()
    if not O("melee") or not ctx.melee then return nil end
    return Try("MongooseBite", false)
        or (not ns.Queued("RaptorStrike") and Try("RaptorStrike", true))
end

---------------------------------------------------------------------------
-- Survival (yakin dovus spec'i)
---------------------------------------------------------------------------
local function Survival()
    if not ctx.melee then
        -- Yaklasirken uzaktan
        return MarkRule() or SerpentRule() or Try("ArcaneShot", true)
    end
    return MarkRule()
        or (ctx.aoe and Try("ExplosiveTrap", true))
        or Try("MongooseBite", false)
        or Try("Counterattack", false)
        or Try("StriderKick", true)
        or (DebuffDue("Lacerate", 3) and Try("Lacerate", true))
        or (not ns.Queued("RaptorStrike") and Try("RaptorStrike", true))
end

local RANGED = { LEVELING = Leveling, BM = BeastMastery, MM = Marksmanship }

local function Main()
    local r = Reminders()
    if r then return r end
    if spec == "SV" then return Survival() end
    -- mob ustundeyken uzak atislar atilamaz: yakin dovus onerisi (yoksa bos) doner, menzilli listeye dusulmez
    if O("melee") and ctx.melee then return DeadZone() end
    if ctx.aoe and ctx.inCombat then
        r = RangedAoE()
        if r then return r end
    end
    return RANGED[spec]()
end

---------------------------------------------------------------------------
-- Kucuk ikon: Auto Shot, savunma, cooldown'lar
---------------------------------------------------------------------------
local function Extra()
    if O("defensives") and ctx.inCombat then
        local r = (HealthBelow(O("deterrence")) and Try("Deterrence", true))
               or (ctx.group and HealthBelow(O("feignDeath")) and Try("FeignDeath", true))
               or (O("mendPet") > 0 and ctx.petHP and ctx.petHP < O("mendPet")
                   and not Recent("MendPet", 15) and Try("MendPet", true))   -- 15 sn kanal: yarida yeniden onerilmez
        if r then return r end
    end

    -- Auto Shot calismiyorsa (uzak mesafede)
    if spec ~= "SV" and not ctx.melee and Has("AutoShot") and not ns.AutoRepeat("AutoShot")
       and ns.InRange("AutoShot") == true then
        return S("AutoShot")
    end

    -- Buyuk cooldown'lar Cooldowns.lua'da (H.cooldowns)
end

-- Buyuk cooldown'lar (Cooldowns.lua): default kullanim modu, cond sinifa ozel kosul
H.cooldowns = {
    { key = "BestialWrath", default = "big",   cond = function() return ctx.pet == "alive" end },
    { key = "RapidFire",    default = "elite" },
    -- Boss'lar stun'a bagisik
    { key = "Intimidation", default = "big",   cond = function() return ctx.pet == "alive" and ctx.kind ~= "boss" end },
}
H.lowExtras = {}

-- Yakin dovus (olu bolge) karari: test ve teshis icin
function H.Melee()
    ReadContext()
    return ctx.melee
end

function H.Next()
    ReadContext()
    return Main() or nil, Extra() or nil
end

-- Ayri AoE ikonu (aoeDisplay = separate): sadece AoE onceligi; yeterli dusman yoksa
-- (ya da "her zaman goster" kapaliysa) nil.
function H.NextAoE()
    ReadContext()
    if not ctx.inCombat or not O("aoe") or not (ns.db.aoeAlways or ctx.enemies >= O("aoeAt")) then return nil end
    if spec == "SV" then return (ctx.melee and Try("ExplosiveTrap", true)) or nil end
    return RangedAoE() or nil
end

function H.Debug()
    ReadContext()
    ns.Print((L("Spec: %s | dusman: %d | can: %s | pet: %s %s | mana: %s"))
        :format(spec, ctx.enemies,
                ctx.health and ("%%%d"):format(math.floor(ctx.health)) or "?",
                ctx.pet, ctx.petHP and ("%%%d"):format(math.floor(ctx.petHP)) or "",
                ns.ManaPercent() and ("%%%d"):format(math.floor(ns.ManaPercent())) or "gizli"))
    ns.Print(("melee: %s | Raptor: %s | Auto Shot: %s | aspect: %s %.0f"):format(tostring(ctx.melee),
        tostring(ns.InRange("RaptorStrike")), tostring(ns.InRange("AutoShot")),
        WantedAspect(), ns.AuraRemaining("player", WantedAspect(), "HELPFUL")))
    ns.Print(("Serpent Sting: %.1f s left | aura API seen in combat: %s"):format(
        ns.AuraRemaining("target", "SerpentSting", "HARMFUL|PLAYER"), tostring(ns.AuraTrusted("target", "SerpentSting"))))
end
