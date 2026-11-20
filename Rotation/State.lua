local _, A = ...
local ns = A.RF
if not ns then return end

local issecret = ns.issecret

---------------------------------------------------------------------------
-- Yaratik tipi. UnitCreatureType istemcinin dilinde doner; tip ID'lerinden
-- (C_CreatureInfo) yerel ad -> Ingilizce tablosu kurulur. Savasta NPC tipi
-- gizli olabilir, bu yuzden hedefte okunan tip hedef degisene kadar saklanir.
---------------------------------------------------------------------------
local CREATURE_EN = { "Beast", "Dragonkin", "Demon", "Elemental", "Giant",
                      "Undead", "Humanoid", "Critter", "Mechanical" }
local toEnglish
local targetType

local function English(t)
    if not toEnglish then
        local get = C_CreatureInfo and C_CreatureInfo.GetCreatureTypeInfo
        local map, n = {}, 0
        for id, en in ipairs(CREATURE_EN) do
            local info = ns.Call(get, id)
            local name = info and info.name
            if name and not issecret(name) then map[name] = en; n = n + 1 end
        end
        -- API yoksa bos tablo: Ingilizce istemci varsayilir (her cagrida tekrar denenmez)
        toEnglish = map
    end
    return toEnglish[t] or t
end

-- Ingilizce tip adi ("Undead", "Elemental"...) veya nil. Hedef basina bir kez okunur
-- (hedef degisince sifirlanir); okunamadiysa sonraki cagrilarda tekrar denenir.
function ns.CreatureType()
    if targetType then return targetType end
    local t = ns.Call(UnitCreatureType, "target")
    if t then targetType = English(t) end
    return targetType
end

---------------------------------------------------------------------------
-- Oyuncu ve pet cani. Savasta UnitHealth gizli, ama UnitHealthMax ve
-- UNIT_COMBAT hasar/iyilesme miktarlari duz gelir: son duz okumadan
-- baslayip her vurus ve iyilesme uygulanir.
---------------------------------------------------------------------------
local hp = {}   -- unit -> tahmini mevcut can

local function ReadPlain(unit)
    local cur = ns.Call(UnitHealth, unit)
    if cur then hp[unit] = cur end
    return cur
end

-- 0-100, bilinmiyorsa nil. unit: "player" (varsayilan) veya "pet"
function ns.HealthPercent(unit)
    unit = unit or "player"
    local max = ns.Call(UnitHealthMax, unit)
    if not max or max <= 0 then return nil end
    local cur = ReadPlain(unit) or hp[unit]
    return cur and math.min(cur / max * 100, 100) or nil
end

-- Pet: "alive" / "dead" / "none". Olen pet bir sure kaybolur; olum hatirlanir.
local petDied = false
function ns.PetState()
    if ns.Call(UnitExists, "pet") then
        if ns.Call(UnitIsDead, "pet") then petDied = true; return "dead" end
        petDied = false
        return "alive"
    end
    return petDied and "dead" or "none"
end

---------------------------------------------------------------------------
-- Yakindaki dusman sayisi: savastaki dusman nameplate'leri, sinif modulunun
-- enemyProbe yeteneginin menzilinde ya da ~10 yd icinde olanlar. Nameplate'ler
-- kapaliysa (V tusu) 0.
---------------------------------------------------------------------------
-- Once issecret, sonra nil testi (gizli degerde == nil hata verebilir)
local function PlateUnit(plate)
    local u = plate.namePlateUnitToken
    if issecret(u) then return nil end
    if type(u) == "nil" then
        local uf = plate.UnitFrame
        u = type(uf) == "table" and uf.unit or nil
        if issecret(u) then return nil end
    end
    return type(u) == "string" and u or nil
end

-- ~10 yd icinde mi (true/false/nil)? CheckInteractDistance retail'de savasta dusmana
-- kisitli: savasta sinifin kisa menzilli hedefli yetenegi (X.nearProbe) yerine gecer.
-- Savasta yoklama buyusu ~20 yd; bu "ustumde" demek degil (Frost Nova / Arcane Explosion iskalar). Bu yuzden savasta
-- yalniz son MELEE_RECENT sn'de fiziksel vurus yediysek true; yoklama menzil disi derse false; gerisi nil (bilinmez).
local MELEE_RECENT = 3
ns.meleeHitAt = 0
function ns.Near(unit)
    if InCombatLockdown() then
        local cls = ns.classes[ns.playerClass]
        local p = cls and cls.nearProbe and ns.spells[cls.nearProbe]
        if p then
            local r = ns.Call(C_Spell.IsSpellInRange, p.id, unit)
            if r == false then return false end
            if r == true and GetTime() - (ns.meleeHitAt or 0) <= MELEE_RECENT then return true end
            return nil
        end
    end
    return ns.Call(CheckInteractDistance, unit, 3)
end

-- Sadece menzilde oldugu KESIN olanlar sayilir: uzaklik okunamazsa sayilmaz
-- (yoksa ekrandaki her nameplate "yakin" sayilip sahte AoE onerilirdi).
local function CountEnemies()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return nil end
    local plates = ns.Call(C_NamePlate.GetNamePlates)
    if type(plates) ~= "table" then return nil end

    local cls = ns.classes[ns.playerClass]
    local probe = cls and cls.enemyProbe and ns.spells[cls.enemyProbe]
    local count = 0
    for _, plate in ipairs(plates) do
        local unit = PlateUnit(plate)
        if unit and ns.Call(UnitCanAttack, "player", unit)
           and not ns.Call(UnitIsDead, unit)
           and ns.Call(UnitAffectingCombat, unit) ~= false then
            -- Yetenek menzilinde ya da ~10 yd icinde (Multi-Shot'un en az menzili var:
            -- ustundeki mob onun icin "menzil disi" doner ama yine de savastasin)
            local near = probe and ns.Call(C_Spell.IsSpellInRange, probe.id, unit)
            if near ~= true then near = ns.Near(unit) end
            if near == true then count = count + 1 end
        end
    end
    return count
end

-- Saniyede 10 kez sorulur ama 0.5 sn'de bir sayilir
local enemyCache, enemyAt = nil, 0
function ns.EnemiesNearby()
    local now = GetTime()
    if now - enemyAt >= 0.5 then
        enemyCache, enemyAt = CountEnemies(), now
    end
    return enemyCache
end

---------------------------------------------------------------------------
-- Hedefin cast'i. Savasta baska birimlerin cast bilgisi gizli olabilir, ama
-- UNIT_SPELLCAST_* olaylari "target" icin yine de tetiklenir: olayin kendisi
-- duz sinyaldir. INTERRUPTIBLE / NOT_INTERRUPTIBLE kalkan durumunu soyler.
---------------------------------------------------------------------------
local cast = { kind = nil, interruptible = nil, since = 0 }

-- Cast/channel bilgisini API'den oku (okunabiliyorsa). notInterruptible duz
-- degilse nil: bilinmiyor.
local function PollCast()
    local kind, notInt
    local ok, name, _, _, _, _, _, _, ni = pcall(UnitCastingInfo, "target")
    -- type() gizli degerde de guvenli; ~= nil karsilastirmasi hata verebilir
    if ok and type(name) ~= "nil" then
        kind, notInt = "cast", ni
    else
        local ok2, cname, _, _, _, _, _, cni = pcall(UnitChannelInfo, "target")
        if ok2 and type(cname) ~= "nil" then kind, notInt = "channel", cni end
    end
    cast.kind = kind
    if kind and not issecret(notInt) and notInt ~= nil then
        cast.interruptible = not notInt
    else
        cast.interruptible = nil
    end
end

local function CastStart(kind)
    PollCast()
    cast.kind = cast.kind or kind
    cast.since = GetTime()
end

local function CastStop()
    cast.kind, cast.interruptible = nil, nil
end

local CAST_EVENTS = {
    UNIT_SPELLCAST_START             = function() CastStart("cast") end,
    UNIT_SPELLCAST_CHANNEL_START     = function() CastStart("channel") end,
    UNIT_SPELLCAST_DELAYED           = PollCast,
    UNIT_SPELLCAST_CHANNEL_UPDATE    = PollCast,
    UNIT_SPELLCAST_STOP              = CastStop,
    UNIT_SPELLCAST_FAILED            = CastStop,
    UNIT_SPELLCAST_INTERRUPTED       = CastStop,
    UNIT_SPELLCAST_CHANNEL_STOP      = CastStop,
    UNIT_SPELLCAST_INTERRUPTIBLE     = function() cast.interruptible = true end,
    UNIT_SPELLCAST_NOT_INTERRUPTIBLE = function() cast.interruptible = false end,
}

-- kind ("cast" / "channel" / nil), interruptible (true / false / nil = bilinmiyor), gecen sure
-- 15 sn'den uzun "cast": bitis olayi kacmis olmali, kirmizi oneri takili kalmasin
local CAST_TIMEOUT = 15
function ns.TargetCast()
    if cast.kind and GetTime() - cast.since > CAST_TIMEOUT then
        cast.kind, cast.interruptible = nil, nil
    end
    return cast.kind, cast.interruptible, cast.kind and (GetTime() - cast.since) or 0
end

local castEv = CreateFrame("Frame")
for event in pairs(CAST_EVENTS) do pcall(castEv.RegisterUnitEvent, castEv, event, "target") end
castEv:SetScript("OnEvent", function(_, event) CAST_EVENTS[event]() end)

---------------------------------------------------------------------------
-- Olaylar
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_TARGET_CHANGED")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
pcall(ev.RegisterEvent, ev, "PLAYER_DEAD")
pcall(ev.RegisterEvent, ev, "UNIT_PET")
pcall(ev.RegisterUnitEvent, ev, "UNIT_HEALTH", "player", "pet")
pcall(ev.RegisterUnitEvent, ev, "UNIT_COMBAT", "player", "pet")

ev:SetScript("OnEvent", function(_, event, unit, action, _, amount, school)
    if event == "PLAYER_TARGET_CHANGED" then
        targetType = nil
        ns.CreatureType()
        -- Yeni hedef zaten cast ediyor olabilir
        CastStop()
        PollCast()
        if cast.kind then cast.since = GetTime() end
    elseif event == "PLAYER_DEAD" then
        hp.player = nil
    elseif event == "UNIT_PET" then
        hp.pet = nil
        ReadPlain("pet")
    elseif event == "PLAYER_REGEN_DISABLED" then
        ReadPlain("player"); ReadPlain("pet")
    elseif event == "UNIT_HEALTH" then
        ReadPlain(unit)
    elseif event == "UNIT_COMBAT" then
        if issecret(unit) or issecret(amount) or issecret(action) then return end
        if type(amount) ~= "number" or amount <= 0 or not hp[unit] then return end
        local max = ns.Call(UnitHealthMax, unit)
        if not max then return end
        if action == "WOUND" then
            hp[unit] = math.max(1, hp[unit] - amount)
            -- dusman yakinda (ns.Near): yalniz fiziksel vurus (okul maskesi 1); 18 yd'den Firebolt / DoT tiki sayilmaz
            if unit == "player" and (school == nil or issecret(school) or school == 1) then ns.meleeHitAt = GetTime() end
        elseif action == "HEAL" then
            hp[unit] = math.min(max, hp[unit] + amount)
        end
    end
end)
