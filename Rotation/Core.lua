local ADDON, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L   -- Locale.lua Core'dan once yuklenir

ns.classes  = {}   -- sinif modulleri: ns.classes.WARRIOR vb.
ns.spells   = {}   -- key -> { key, name, id, icon } (sadece bilinen buyuler)
ns.byName   = {}   -- buyu adi -> key
ns.lastCast = {}   -- buyu adi -> GetTime() (cooldown gizliyse yedek takip)
ns.lastFail = {}   -- buyu adi -> son basarisiz atis (UNIT_SPELLCAST_FAILED)

local defaults = {
    language   = "auto",   -- arayuz dili (Locale.lua): auto = oyunun dili
    mode       = "custom", -- custom: kendi listemiz | auto: once Blizzard asistani | blizzard
    glow       = true,
    cds        = true,     -- buyuk cooldown onerileri (Cooldowns.lua) acik mi
    cdDisplay  = "bar",    -- bar: ayri cooldown cubugu | extra: kucuk ikonda
    cdSize     = 32,
    cdMax      = 8,        -- cubukta en fazla kac ikon
    cdOnlyReady = false,   -- cubukta sadece hazir olanlar
    cdGlow     = true,     -- onerilen cooldown parlasin
    showExtra  = true,     -- kucuk ikon (GCD disi / cooldown / savunma)
    -- Ikonlar (Display.lua)
    mainSize   = 52,
    queueCount = 2,        -- ana ikondan sonra kac tahmin (0-3)
    queueSize  = 34,
    queueAlpha = 0.85,
    extraSize  = 30,
    aoeSize    = 40,
    iconSpacing = 6,
    iconLayout = "horizontal",   -- horizontal | vertical (birlikte modunda gruplarin dizilisi)
    layoutMode = "free",         -- free: her grup ayri suruklenir | together: hepsi birlikte
    queueDir   = "right",        -- sira ikonlarinin yonu: right | left | down | up
    cdDir      = "right",        -- cooldown cubugunun buyume yonu: right | left | down | up | center
    cdPerRow   = 0,              -- bu kadar ikonda alt satira / sutuna sar (0 = tek satir)
    groupPos   = {},             -- grup adi -> { kose, x, y } (Display.lua)
    aoeDisplay = "separate",     -- separate: ayri AoE ikonu | auto: ana ikon AoE'ye gecer | off
    aoeAlways  = false,          -- ayri AoE ikonu savasta hep gorunsun (dusman sayimindan bagimsiz)
    interrupt  = true,     -- hedef cast ederken kucuk ikonda interrupt oner
    interruptDelay = 0,    -- cast basladiktan kac sn sonra (insan tepkisi / sahte cast)
    talentGuide = true,    -- bos talent puani varken siradaki talent'i goster
    talentChat  = true,    -- sohbete yaz
    talentGlow  = true,    -- talent butonu / talent ekraninda parlama
    class      = {},       -- sinif ayarlari: class[WARRIOR][key] (varsayilanlar cls.options'ta)
    locked     = true,         -- kilitli: ikonlar yalniz showWhen kosulunda (kilit acikken yer tutucularla hep)
    showWhen   = "target",     -- target: saldirilabilir hedef varken | combat: yalniz savasta | always: hep (son oneri kalir)
    scale      = 1,
    point      = { "CENTER", "UIParent", "CENTER", 0, -180 },
}
ns.defaults = defaults   -- Options.lua "Varsayilana don" ayni listeyi kullanir

-- Forever (Midnight motoru) savasta pek cok degeri "gizli" dondurur: rage,
-- hedef cani, aura verisi, NPC GUID'i, cooldown zamanlari. Gizli bir degeri
-- karsilastirmak, hatta if icinde test etmek bile hata verebilir. Bu yuzden
-- her okuma once issecret'ten gecer.
local issecret      = issecretvalue or function() return false end
local issecrettable = issecrettable or function() return false end
ns.issecret = issecret

function ns.Print(msg)
    print("|cffffd200Arcanis Rotation:|r " .. tostring(msg))
end

-- nil veya gizli degeri yedek degerle degistir
function ns.Safe(v, fallback)
    if issecret(v) or v == nil then return fallback end
    return v
end

-- pcall ile cagir, ilk donus degeri duz ise ver, degilse nil
function ns.Call(fn, ...)
    if not fn then return nil end
    local ok, r = pcall(fn, ...)
    if not ok or issecret(r) then return nil end
    return r
end

---------------------------------------------------------------------------
-- Buyu cozumleme: rank 1 ID'den adi bul, ad uzerinden oyuncunun bildigi
-- (en yuksek) rank'i al. ID'si bilinmeyen buyuler icin Ingilizce ad yedek.
-- list: key -> { id = <rank 1 ID veya nil>, name = "English Name", ... }
---------------------------------------------------------------------------
function ns.ResolveSpells(list)
    wipe(ns.spells)
    wipe(ns.byName)
    for key, def in pairs(list) do
        local name = def.id and ns.Call(C_Spell.GetSpellName, def.id) or def.name
        local info = name and ns.Call(C_Spell.GetSpellInfo, name)
        if info and info.spellID and ns.Call(IsPlayerSpell, info.spellID) ~= false then
            -- aura: debuff'in adi buyununkinden farkliysa (Scorch -> Fire Vulnerability)
            -- noAura: aura birakmayan, sadece kendi kaydimizla takip edilen (totemler)
            ns.spells[key] = { key = key, name = name, id = info.spellID, icon = info.iconID, aura = def.aura,
                               noAura = def.noAura }
            -- Takip anahtari, ayni adli sinif / racial buyusunun yerini almasin
            if not (key:find("^Track") and ns.byName[name]) then ns.byName[name] = key end
        end
    end
end

function ns.Has(key) return ns.spells[key] ~= nil end

-- Kullanilabilir mi? (kaynak, durus, reaktif kosullar). Gizliyse unknownAs doner.
function ns.Usable(key, unknownAs)
    local s = ns.spells[key]
    if not s then return false end
    local ok, usable = pcall(C_Spell.IsSpellUsable, s.id)
    if not ok or issecret(usable) or usable == nil then return unknownAs end
    return usable and true or false
end

-- Cooldown hazir mi? isActive / isOnGCD savasta da duz gelir,
-- startTime / duration gizli olabilir.
local function CooldownFields(cd) return cd.isOnGCD, cd.startTime, cd.duration, cd.isActive end

function ns.Ready(key)
    local s = ns.spells[key]
    if not s then return false end
    -- Tahmin modu (Predict.lua): "basilmis" sayilan cooldown'lu yetenek hazir degil
    if ns.sim and ns.sim.used[key] then return false end
    -- su an dokulen cooldown'lu buyu (Mind Blast, Pyroblast): bekleme dokum bitince baslar, o ana dek GCD gorunur
    if ns.castingName and ns.castingName == s.name and (ns.Call(GetSpellBaseCooldown, s.id) or 0) > 0 then
        return false
    end

    -- Tablo gizli alan tasisa bile isOnGCD / isActive duz gelir: alanlar tek tek
    -- kontrol edilir, okuma pcall icinde (gizli tablo indekslenemiyorsa yedege duser)
    local cd = ns.Call(C_Spell.GetSpellCooldown, s.id)
    local ok, onGCD, start, dur, active = false
    if type(cd) == "table" then ok, onGCD, start, dur, active = pcall(CooldownFields, cd) end
    if ok then
        if not issecret(onGCD) and onGCD == true then return true end
        if not issecret(start) and not issecret(dur) and start and dur then
            if start == 0 or dur <= 1.5 then return true end
            return (start + dur - GetTime()) <= 0.25
        end
        if not issecret(active) and active ~= nil then return not active end
    end

    -- Yedek: kendi kayitlarimiz + temel cooldown
    local last = ns.lastCast[s.name]
    if not last then return true end
    local baseMS = ns.Call(GetSpellBaseCooldown, s.id) or 0
    return (GetTime() - last) >= (baseMS / 1000 - 0.25)
end

-- Savasta gizli: nil doner
function ns.Rage()
    return ns.Call(UnitPower, "player", Enum.PowerType.Rage)
end

-- Savasta gizli olabilir: nil doner
function ns.Energy()
    return ns.Call(UnitPower, "player", Enum.PowerType.Energy)
end

-- Combo point (Rogue, Druid Cat). Savasta gizliyse nil; sinif modulu kendi atislarindan
-- tahmin eder (ns.ComboEstimate).
function ns.ComboPoints()
    local v = ns.Call(UnitPower, "player", Enum.PowerType.ComboPoints)
    if v == nil and GetComboPoints then v = ns.Call(GetComboPoints, "player", "target") end
    return v
end

-- Combo point tahmini: gercek deger okunabiliyorsa o, yoksa sinifin kendi sayaci
-- (builder +1, finisher 0; hedef degisince sifir). Sinif modulu ns.ComboEstimate'i doldurur.
ns.comboGuess = 0
function ns.ComboEstimate()
    local v = ns.ComboPoints()
    if v ~= nil then ns.comboGuess = v; return v end
    return ns.comboGuess
end

-- Her guncellemede bir kez okunur (Tick sifirlar); siniflar ve aura takibi cok kez sorar
local combatMemo
function ns.ClearCombatMemo() combatMemo = nil end   -- testler: savas durumu ayni tick icinde degisti

function ns.InCombat()
    if combatMemo == nil then
        combatMemo = ns.Call(UnitAffectingCombat, "player") and true or false
    end
    return combatMemo
end

-- Hedef menzilde mi: true / false / nil(bilinmiyor)
function ns.InRange(key)
    local s = ns.spells[key]
    if not s then return nil end
    return ns.Call(C_Spell.IsSpellInRange, s.id, "target")
end

-- "Bir sonraki vurusta" yetenekler (Heroic Strike) siradayken kullanilabilir
-- gorunmeye devam eder; tekrar onermemek icin.
function ns.Queued(key)
    local s = ns.spells[key]
    return s ~= nil and ns.Call(C_Spell.IsCurrentSpell, s.id) == true
end

-- Aktif durus/form buyusunun ID'si (yoksa veya okunamazsa nil)
function ns.ActiveForm()
    if ns.sim and ns.sim.form then return ns.sim.form end
    local n = ns.Call(GetNumShapeshiftForms) or 0
    for i = 1, n do
        local ok, _, active, _, spellID = pcall(GetShapeshiftFormInfo, i)
        if ok and not issecret(active) and active and not issecret(spellID) then
            return spellID
        end
    end
end

-- Gercek maliyet (talent indirimleri dahil, orn. Improved Heroic Strike, Focused Rage).
-- Okunabildiginde saklanir; savasta gizli gelirse son bilinen deger, hic yoksa nil.
local costCache = {}
local function FindCost(costs, powerType)
    for _, c in ipairs(costs) do
        local t, amount = c.type, c.cost
        if not issecret(t) and not issecret(amount) and t == powerType and type(amount) == "number" then
            return amount
        end
    end
end

function ns.SpellCost(key, powerType)
    local s = ns.spells[key]
    if not s or not (C_Spell and C_Spell.GetSpellPowerCost) then return costCache[key] end
    local ok, costs = pcall(C_Spell.GetSpellPowerCost, s.id)
    if ok and type(costs) == "table" then
        -- alanlar tek tek kontrol edilir; gizli tablo indekslenemiyorsa pcall yakalar
        local ok2, amount = pcall(FindCost, costs, powerType)
        if ok2 and amount then costCache[key] = amount end
    end
    return costCache[key]
end

-- Son `sec` saniye icinde atildi mi? (kendi kayitlarimiz)
function ns.Recent(key, sec)
    local s = ns.spells[key]
    local t = s and ns.lastCast[s.name]
    return t ~= nil and (GetTime() - t) < sec
end

-- Sinif modullerinin ortak oncelik yardimcilari (Classes/*.lua: local Try = ns.Try ...)
function ns.Try(key, unknownAs)
    if ns.Usable(key, unknownAs) and ns.Ready(key) then return ns.spells[key] end
end

-- Bizim debuff hedefte yok mu / bitmesine `early` sn'den az mi kaldi?
function ns.DebuffDue(key, early)
    return ns.AuraRemaining("target", key, "HARMFUL|PLAYER") <= (early or 0)
end

function ns.BuffUp(key)
    return ns.AuraRemaining("player", key, "HELPFUL") > 0
end

-- Hedefin yaratik tipi verilenlerden biri mi? (Ingilizce: "Undead", "Demon"...)
function ns.CreatureIs(...)
    local t = ns.CreatureType()
    if not t then return false end
    for i = 1, select("#", ...) do
        if t == select(i, ...) then return true end
    end
    return false
end

-- Savasta gizli: nil doner (0-100)
function ns.ManaPercent()
    local cur = ns.Call(UnitPower, "player", Enum.PowerType.Mana)
    local max = ns.Call(UnitPowerMax, "player", Enum.PowerType.Mana)
    if not cur or not max or max <= 0 then return nil end
    return cur / max * 100
end

-- Yetenek icin kaynak yetmiyor mu? (IsSpellUsable'in ikinci donusu; gizli degil)
function ns.NoPower(key)
    local s = ns.spells[key]
    if not s then return false end
    local ok, _, noMana = pcall(C_Spell.IsSpellUsable, s.id)
    if not ok or issecret(noMana) then return false end
    return noMana and true or false
end

-- Blizzard'in proc parlamasi yetenegin ustunde mi? (Missile Barrage, Heating Up, Fingers of Frost)
function ns.Proc(key)
    local s = ns.spells[key]
    if not s then return false end
    if ns.sim and ns.sim.used[key] then return false end   -- tahminde proc harcandi
    local fn = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed or IsSpellOverlayed
    return ns.Call(fn, s.id) == true
end

-- Otomatik tekrar (Auto Shot, Shoot) acik mi?
function ns.AutoRepeat(key)
    local s = ns.spells[key]
    if not s then return false end
    if C_Spell.IsAutoRepeatSpell then return ns.Call(C_Spell.IsAutoRepeatSpell, s.id) == true end
    -- API yoksa bilinemez: "calisiyor" say (Auto Shot surekli onerilmesin)
    if not IsAutoRepeatSpell then return true end
    return ns.Call(IsAutoRepeatSpell, s.name) and true or false
end

-- "boss" / "player" / "elite" / "normal"
function ns.TargetKind()
    local c = ns.Call(UnitClassification, "target")
    if c == "worldboss" or ns.Call(UnitLevel, "target") == -1 then return "boss" end
    if ns.Call(UnitIsPlayer, "target") then return "player" end
    if c == "elite" or c == "rareelite" then return "elite" end
    return "normal"
end

-- 5 kisilik zindan / raid icinde mi?
function ns.InstanceType()
    local _, t = IsInInstance()
    return t
end


---------------------------------------------------------------------------
-- Aura takibi. Savas disinda aura verisi okunur ve bitis zamani saklanir.
-- Savasta veri gizli oldugunda saklanan bitis zamani veya kendi atislarimiz
-- (spell tanimindaki duration) kullanilir. Hedef degisince hedef kayitlari silinir.
---------------------------------------------------------------------------
local expiry = { player = {}, target = {} }   -- unit -> buyu adi -> bitis zamani
-- alan debuff'lari (Demoralizing Shout / Roar, Thunder Clap): etraftaki her moba gider, hedef degisince silinmez;
-- savas bitince temizlenir
local areaExp = {}
-- hedef degisince eski hedefin kayitlari: GUID -> { buyu adi -> bitis }; savas bitince silinir
local byGuid, targetGuid = {}, nil
local function SafeGuid()
    local ok, g = pcall(UnitGUID, "target")
    if ok and g and not issecret(g) then return g end
end
local stacks = {}                             -- buyu adi -> hedefteki yigin (bizim atislar)

-- Ayni aura bir tick icinde bir kez sorgulanir (Tick basinda silinir).
-- Deger: aura tablosu, false = yok, UNREADABLE = okunamadi / gizli.
local auraMemo, UNREADABLE = {}, {}
local function QueryAura(unit, name, filter)
    local k = unit .. "|" .. name .. "|" .. (filter or "")
    local a = auraMemo[k]
    if a == nil then
        local ok, r = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter)
        if not ok or issecret(r) or issecrettable(r) then a = UNREADABLE else a = r or false end
        auraMemo[k] = a
    end
    return a
end

-- apiSeen[unit][buyu adi]: aura API'si savasta bu birimde BU auramizi okuyabildi (istemci gizlemiyor). Birim
-- basina tek bayrak yetmiyordu: istemci savasta bazi auralari verip bazilarini "yok" gosteriyor (sahibin bulgusu,
-- 15 Kasim 2026: acik Aspect of the Hawk ve hedefteki Serpent Sting surekli yeniden onerildi).
local apiSeen, AURA_GRACE = { player = {}, target = {} }, 1.5
local AURA_UNKNOWN_LEFT = 3600   -- sn: aura gorunuyor ama bitis zamani gizli (hicbir yenileme esigine girmesin)
ns.auraApiSeen = apiSeen

-- Savasta bu auranin "yok" cevabina guvenilir mi?
function ns.AuraTrusted(unit, key)
  local s = ns.spells[key]
  return s and apiSeen[unit] and apiSeen[unit][s.name] or false
end

-- Kalan sure (sn). Yoksa veya hic bilgi yoksa 0.
function ns.AuraRemaining(unit, key, filter)
    local s = ns.spells[key]
    if not s or not expiry[unit] then return 0 end
    if ns.sim then
        if ns.sim.auras[key] then return 999 end      -- tahminde atildi
        if ns.sim.auraOff[key] then return 0 end      -- ayni gruptan baskasi atildi
    end
    -- su an dokulen kendi buyumuz (Immolate, Holy Fire...): dokum bitene kadar "atildi" sayilir, ikon tekrar onu demez
    if ns.castingName and ns.castingName == s.name then return 999 end
    local now = GetTime()

    if not s.noAura and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local aura = QueryAura(unit, s.aura or s.name, filter)
        if aura ~= UNREADABLE then
            if aura == false then
                -- Savasta API gizli aurayi "yok" gibi gosterebilir: kendi kaydimiz hala gecerliyse ona guven.
                -- Ama API bu oturumda savasta bu birimdeki kendi auramizi bir kez okuyabildiyse "yok" gercektir:
                -- atistan AURA_GRACE sn sonra hala yoksa iskaladi / dustu (Serpent Sting 15 sn yenilenmiyordu).
                local exp = expiry[unit][s.name]
                local cast = ns.lastCast and ns.lastCast[s.name] or 0
                if exp and exp > now and ns.InCombat()
                    and not (apiSeen[unit][s.name] and now - cast > AURA_GRACE) then
                    return exp - now
                end
                expiry[unit][s.name] = nil
                return 0
            end
            if ns.InCombat() then apiSeen[unit][s.name] = true end   -- savasta okunabildi: "yok" cevabi da gercek
            local exp = aura.expirationTime
            if not issecret(exp) and exp then
                if exp == 0 then exp = now + 3600 end   -- suresiz
                expiry[unit][s.name] = exp
                return exp - now
            end
            -- aura var ama suresi gizli: "yok" sayilmaz (sahibin bulgusu, 16 Kasim 2026: ustunde Battle Shout varken
            -- ve hedefte Demoralizing Shout varken surekli yeniden oneriliyordu). Kendi kaydimiz gecerliyse o, yoksa
            -- bilinmeyen kalan sure: yenileme onerilmez, aura dusunce "yok" gelir.
            local rec = expiry[unit][s.name]
            if rec and rec > now then return rec - now end
            return AURA_UNKNOWN_LEFT
        end
    end

    local exp = expiry[unit][s.name]
    return exp and math.max(exp - now, 0) or 0
end

-- Hedefteki yigin sayisi (sadece bizim atislar; sure dolunca 0)
function ns.Stacks(key)
    local s = ns.spells[key]
    local add = ns.sim and ns.sim.stackAdd[key] or 0
    if not s then return add end
    -- Tahminde aura "var" sayilir; gercek yigin icin gercek bitis zamanina bak
    local up
    if ns.sim then up = (expiry.target[s.name] or 0) > GetTime()
    else up = ns.AuraRemaining("target", key, "HARMFUL|PLAYER") > 0 end
    if not up then return add end
    return (stacks[s.name] or 0) + add
end

local function OnOwnCast(spellID, name)
    local cls = ns.classes[ns.playerClass]
    local key = ns.byName[name]
    local def = cls and key and cls.spells[key]
    if not def or not def.duration then return end

    local unit = def.unit or "target"
    local dur = def.durationByRank and def.durationByRank[spellID] or def.duration
    -- Ayni gruptan biri digerini kaldirir (Hunter aspect'leri, Mage zirhlari)
    if def.group then
        for k, d in pairs(cls.spells) do
            local s = ns.spells[k]
            if d.group == def.group and s then expiry[unit][s.name] = nil end
        end
    end
    if unit == "target" and def.maxStacks then
        local alive = (expiry.target[name] or 0) > GetTime()
        stacks[name] = math.min((alive and stacks[name] or 0) + 1, def.maxStacks)
    end
    expiry[unit][name] = GetTime() + dur
    if def.area and unit == "target" then areaExp[name] = expiry[unit][name] end
end

---------------------------------------------------------------------------
-- Oneri: ana ikon (GCD'li rotasyon) + kucuk ikon (GCD disi / cooldown)
---------------------------------------------------------------------------
function ns.BlizzardAvailable()
    return C_AssistedCombat and C_AssistedCombat.GetNextCastSpell ~= nil
end

-- Blizzard asistani (mod auto / blizzard). Kendi listemiz kullanilacaksa nil.
local function BlizzardRec()
    local mode = ns.db.mode
    if mode == "custom" or not ns.BlizzardAvailable() then return nil end
    local id = ns.Call(C_AssistedCombat.GetNextCastSpell)
    if id and id ~= 0 then
        local info = C_Spell.GetSpellInfo(id)
        if info then return { name = info.name, id = id, icon = info.iconID } end
    end
    -- "blizzard": asistan onermiyorsa hicbir sey gosterme (false); "auto": kendi listemize dus (nil)
    if mode == "blizzard" then return false end
    return nil
end

-- Ekranda gosterilecek her sey: main, extra, aoe, queue = { ... }
-- AoE gosterimi (db.aoeDisplay):
--   auto     : yeterli dusman varsa ana ikon AoE onceligine gecer (tek ikon)
--   separate : ana ikon hep tek hedef, AoE onerisi ayri ikonda
--   off      : AoE hic onerilmez
local queueAt, queueFor, queueCache = 0, nil, {}

function ns.GetRecommendation()
    local view = { queue = {} }
    local blizz = BlizzardRec()
    if blizz ~= nil then
        view.main = blizz or nil
        return view
    end
    local cls = ns.classes[ns.playerClass]
    if not cls then return view end

    local display = ns.db.aoeDisplay
    ns.aoeForce = (display ~= "auto") and "single" or nil
    local main, extra = cls.Next()
    view.main = main
    -- Interrupt, kucuk ikondaki her seyin onune gecer
    view.extra = ns.InterruptRec(cls) or extra

    -- Buyuk cooldown'lar: sinifin bu turki durumuyla, sira tahmininden ONCE
    -- (tahmin, sinifin ctx'ini degistirir)
    local cds, cdRec = ns.CooldownStates(cls)
    view.cds = cds
    if cdRec and ns.db.cdDisplay == "extra" and not (view.extra and view.extra.interrupt)
       and (not view.extra or (cls.lowExtras and cls.lowExtras[view.extra.key])) then
        view.extra = cdRec
    end

    if display == "separate" and cls.NextAoE then view.aoe = cls.NextAoE() end

    -- Sira tahmini: pahali (Next birkac kez), 0.25 sn'de bir ya da ana oneri degisince
    local n = ns.db.queueCount or 0
    if n > 0 and main and ns.PredictQueue then
        local now = GetTime()
        if queueFor ~= main.key or now - queueAt >= 0.25 then
            queueCache, queueFor, queueAt = ns.PredictQueue(cls, main, n), main.key, now
        end
        view.queue = queueCache
    end
    ns.aoeForce = nil
    return view
end

-- Hedef kesilebilir bir buyu cast ediyorsa sinifin ilk hazir interrupt'i.
-- Kalkan durumu bilinmiyorsa (gizli) kesilebilir sayilir.
function ns.InterruptRec(cls)
    if not ns.db.interrupt or not cls.interrupts then return nil end
    local kind, interruptible, elapsed = ns.TargetCast()
    if not kind or interruptible == false or elapsed < ns.db.interruptDelay then return nil end
    for _, key in ipairs(cls.interrupts) do
        local s = ns.spells[key]
        if s and ns.Usable(key, true) and ns.Ready(key) and ns.InRange(key) ~= false then
            return { key = s.key, name = s.name, id = s.id, icon = s.icon, interrupt = true }
        end
    end
end

local function HostileTarget()
    if not UnitExists("target") then return false end
    if not ns.Safe(UnitCanAttack("player", "target"), true) then return false end
    if ns.Safe(UnitIsDead("target"), false) then return false end
    return true
end

-- Doner: oneri hesaplansin mi, ikonlar (son oneriyle) acik kalsin mi
local function ShouldShow()
    if ns.Unlocked() then return true end
    local mode = ns.db.showWhen or "target"
    if mode == "combat" and not ns.InCombat() then return false end
    if HostileTarget() then return true end
    return false, mode == "always"
end
ns.ShouldShow = ShouldShow

-- Savas disinda kendi buff'larimizin kaydini tazele: savasta aura gizli, /reload ya da
-- giristen once acilan uzun buff (aspect, zirh) kayit olmadan "yok" sayilirdi.
local buffScanAt = 0
local function ScanPlayerBuffs()
    local cls = ns.classes[ns.playerClass]
    if not cls or GetTime() < buffScanAt or ns.InCombat() then return end
    buffScanAt = GetTime() + 1
    for key, def in pairs(cls.spells) do
        if def.unit == "player" and def.duration and ns.spells[key] then
            ns.AuraRemaining("player", key, "HELPFUL")
        end
    end
end

local lastView
ns.ResetView = function() lastView = nil end   -- modul kapaninca: acilinca eski oneri geri gelmesin
local function TickInner()
    ScanPlayerBuffs()
    local show, keep = ShouldShow()
    local view
    if show then
        view = ns.GetRecommendation()
        lastView = view
    elseif keep and lastView then
        view = lastView   -- "her zaman": hedef yokken son oneri ekranda kalir
    else
        view = { queue = {} }
    end
    -- Kucuk ikon kapaliyken bile interrupt gosterilir
    if view.extra and not ns.db.showExtra and not view.extra.interrupt then view.extra = nil end
    view.binds = ns.Highlight_Set(view)
    ns.UI_Set(view)
end

-- Bir hata saniyede 10 kez tekrarlanmasin: ilk hatayi bir kez yaz, 5 sn bekle, tekrar dene
local pausedUntil, lastError = 0, nil
function ns.Tick()
    if GetTime() < pausedUntil then return end
    combatMemo = nil
    wipe(auraMemo)
    ns.aoeForce = nil   -- onceki turda hata olduysa takili kalmasin
    local ok, err = pcall(TickInner)
    if not ok then
        ns.aoeForce, ns.sim = nil, nil
        pausedUntil = GetTime() + 5
        if err ~= lastError then
            lastError = err
            ns.Print(L("|cffff4040Hata (5 sn sonra tekrar denenecek):|r ") .. tostring(err))
        end
    end
end

---------------------------------------------------------------------------
-- Olaylar
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
-- Istemcide olmayan bir olay RegisterEvent'te hata verir ve dosyanin geri kalani
-- calismaz: hepsi pcall ile (CHARACTER_POINTS_CHANGED Classic'e ait, Forever'da olmayabilir).
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "SPELLS_CHANGED",
                     "CHARACTER_POINTS_CHANGED", "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
pcall(ev.RegisterUnitEvent, ev, "UNIT_SPELLCAST_SUCCEEDED", "player")
for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
                     "UNIT_SPELLCAST_INTERRUPTED" }) do
    pcall(ev.RegisterUnitEvent, ev, e, "player")
end

local function Refresh()
    local cls = ns.classes[ns.playerClass]
    if not cls then return end
    ns.ResolveSpells(ns.SpellsWithRacials(cls))
    wipe(costCache)   -- rank / talent degisti: maliyetler yeniden okunur
    if ns.TalentsRebuild then ns.TalentsRebuild() end
    if cls.OnRefresh then cls.OnRefresh() end
end
ns.Refresh = Refresh   -- takip listesi degisince (Cooldowns.lua)

ev:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON then return end
        ArcanisRotationDB = ArcanisRotationDB or {}
        for k, v in pairs(defaults) do
            if ArcanisRotationDB[k] == nil then ArcanisRotationDB[k] = v end
        end
        ns.db = ArcanisRotationDB
        -- goc (1): eski varsayilan kilit acikti (ikonlar hedefsiz de soru isaretiyle gorunurdu); onlyCombat -> showWhen
        if (ns.db.visV or 0) < 1 then
            ns.db.visV = 1
            ns.db.locked = true
            if ns.db.onlyCombat then ns.db.showWhen = "combat" end
            ns.db.onlyCombat = nil
        end
        ns.SetLanguage(ns.db.language)

    elseif event == "PLAYER_LOGIN" then
        ns.playerClass = select(2, UnitClass("player"))
        local cls = ns.classes[ns.playerClass]
        if not cls then
            ns.Print(L("Bu sinif henuz desteklenmiyor: ") .. tostring(ns.playerClass))
        end
        -- Sinif ayarlari: eksik anahtarlara varsayilan
        ns.db.class[ns.playerClass] = ns.db.class[ns.playerClass] or {}
        ns.cdb = ns.db.class[ns.playerClass]
        for _, o in ipairs(cls and cls.options or {}) do
            if o.key and ns.cdb[o.key] == nil then ns.cdb[o.key] = o.default end
        end
        if ns.cdb.build == nil then ns.cdb.build = "auto" end
        ns.cdb.cdMode = ns.cdb.cdMode or {}   -- buyuk cooldown kullanim modlari (key -> mod)
        Refresh()
        ns.Highlight_Init()
        ns.UI_Init()
        ns.Options_Init()

    elseif event == "SPELLS_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
        -- modul kapali: buyuler yeniden cozulmez; talent agaci (Build okur) Talents.lua olaylariyla guncel kalir
        if ns.playerClass and not ns.stopped then Refresh() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        wipe(areaExp)   -- savas bitti: alan debuff'lari artik bir sonraki pakete ait degil
        wipe(byGuid)

    elseif event == "UNIT_SPELLCAST_START" then
        local _, _, spellID = ...
        ns.castingName = (spellID and not issecret(spellID)) and C_Spell.GetSpellName(spellID) or nil
        wipe(auraMemo)

    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        ns.castingName = nil
        wipe(auraMemo)
        if event == "UNIT_SPELLCAST_FAILED" then
            local _, _, spellID = ...
            local name = spellID and not issecret(spellID) and C_Spell.GetSpellName(spellID)
            if name then ns.lastFail[name] = GetTime() end
        end

    elseif event == "PLAYER_TARGET_CHANGED" then
        -- coklu hedef: eski hedefin kayitlari GUID'iyle saklanir, ona donunce geri gelir (savasta aura okunamazsa
        -- DoT'lu moba donunce yeniden oneriyordu)
        local t = GetTime()
        if targetGuid then
            local keep = {}
            for name, e in pairs(expiry.target) do if e > t then keep[name] = e end end
            byGuid[targetGuid] = keep
        end
        wipe(expiry.target)
        targetGuid = SafeGuid()
        for name, e in pairs(targetGuid and byGuid[targetGuid] or {}) do
            if e > t then expiry.target[name] = e end
        end
        for name, e in pairs(areaExp) do
            if e > t then expiry.target[name] = e else areaExp[name] = nil end
        end
        wipe(stacks)
        wipe(auraMemo)
        ns.comboGuess = 0   -- combo point'ler hedefe bagli

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and not ns.stopped then
        local _, _, spellID = ...
        if spellID and not issecret(spellID) then
            wipe(auraMemo)   -- yeni atis: onceki tick'in "aura yok" sonucu artik eski
            local name = C_Spell.GetSpellName(spellID)
            if name then
                ns.lastCast[name] = GetTime()
                OnOwnCast(spellID, name)
                local cls = ns.classes[ns.playerClass]
                if cls and cls.OnCast then cls.OnCast(ns.byName[name], spellID) end
            end
        end
    end
end)

-- 10 Hz guncelleme
local acc = 0
local driver = CreateFrame("Frame")
ns.driver = driver   -- modul kapaliyken gizlenir (OnUpdate hic calismaz), acilinca gosterilir (Init.lua)
driver:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.1 or not ns.db then return end
    acc = 0
    ns.Tick()
end)
