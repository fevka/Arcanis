local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Buyuk cooldown'lar: sinifin cooldown'lari (cls.cooldowns), racial'lar, "Use:" etkili
-- trinket'ler ve kullanicinin eklediklerini (/rof track). Hepsi istege bagli (db.cds);
-- her biri icin ayardan kullanim modu secilir.
--   * Racial'lar: asagidaki listeden oyuncunun bildikleri (IsPlayerSpell / buyu kitabi)
--   * Trinket'ler: takili eşya (slot 13/14) + C_Item.GetItemSpell ile "Use:" buyusu
-- Cooldown zamanlari savasta gizli olabilir: karsilastirilmadan dogrudan Cooldown
-- widget'ina verilir (CooldownBar.lua); "hazir mi" bilgisi gizli olmayan alanlardan gelir.

local issecret = ns.issecret
local issecrettable = issecrettable or function() return false end

-- Giris listesi onbellegi (her turda yeniden kurulmasin): Refresh / trinket taramasi /
-- takip degisince sifirlanir. Asagidaki fonksiyonlar kullandigi icin en ustte.
local entriesCache, entriesFor

-- Forever'daki racial ID'leri dogrulanmadi: ID'den ad, yoksa Ingilizce ad ile bulunur.
ns.RACIALS = {
    BloodFury  = { id = 20572, name = "Blood Fury" },    -- Orc: saldiri gucu
    Berserking = { id = 20554, name = "Berserking" },    -- Troll: saldiri / buyu hizi
    Stoneform  = { id = 20594, name = "Stoneform" },     -- Dwarf: savunma
    WarStomp   = { id = 20549, name = "War Stomp" },     -- Tauren: alan sersemletme
    WillOfTheForsaken = { id = 7744, name = "Will of the Forsaken" },  -- Undead: korku / uyku kirar
    EscapeArtist = { id = 20589, name = "Escape Artist" },  -- Gnome: kok / yavaslatma kirar
    Shadowmeld = { id = 20580, name = "Shadowmeld" },    -- Night Elf: gizlenme
    Perception = { id = 20600, name = "Perception" },    -- Human: gizlileri gorme
}
ns.RACIAL_ORDER = { "BloodFury", "Berserking", "Stoneform", "WarStomp", "WillOfTheForsaken",
                    "EscapeArtist", "Shadowmeld", "Perception" }
-- Saldiri racial'lari buyuk hedefte; savunma / kontrol olanlar varsayilan kapali (istersen ac)
ns.RACIAL_DEFAULT = { BloodFury = "big", Berserking = "big", Stoneform = "off", WarStomp = "off",
                      WillOfTheForsaken = "off", EscapeArtist = "off", Shadowmeld = "off", Perception = "off" }
local RACIAL_ORDER, RACIAL_DEFAULT = ns.RACIAL_ORDER, ns.RACIAL_DEFAULT

ns.CD_MODES = { "always", "big", "elite", "boss", "track", "off" }
ns.CD_MODE_NAMES = {
    track  = "Sadece takip (onerme)",
    always = "Her zaman (savasta)",
    big    = "Buyuk hedef (elit, boss, oyuncu, grup)",
    elite  = "Elit / boss / oyuncu",
    boss   = "Sadece boss",
    off    = "Kapali",
}

---------------------------------------------------------------------------
-- Kullanicinin takip ettigi yetenekler: cdb.tracked = { { id, name }, ... }
-- Anahtar "Track<id>"; ns.spells'e cozulur (oyuncu biliyorsa).
---------------------------------------------------------------------------
local function TrackedList()
    return ns.cdb and ns.cdb.tracked or {}
end

local function TrackKey(id) return "Track" .. id end

-- Sinif buyuleri + racial'lar + takip edilenler (Core Refresh bununla cozer)
function ns.SpellsWithRacials(cls)
    entriesCache = nil   -- Refresh: buyuler yeniden cozulecek
    local out = {}
    for k, v in pairs(cls.spells) do out[k] = v end
    for k, v in pairs(ns.RACIALS) do
        if not out[k] then out[k] = v end
    end
    for _, t in ipairs(TrackedList()) do
        out[TrackKey(t.id)] = { id = t.id, name = t.name }
    end
    return out
end

-- /rof track <ad | ID>: bilinen bir yetenegi takip listesine ekle
function ns.TrackAdd(text)
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        ns.Print(L("Kullanim: /rof track <yetenek adi veya ID>   (/rof track list, /rof untrack <ad>)"))
        return
    end
    local query = tonumber(text) or text
    local info = ns.Call(C_Spell.GetSpellInfo, query)
    if not info or not info.spellID then
        ns.Print(L("|cffff4040Bulunamadi:|r ") .. text .. L("  (ad, istemcinin dilinde ve bildigin bir yetenek olmali)"))
        return
    end
    if ns.Call(IsPlayerSpell, info.spellID) == false then
        ns.Print(L("|cffff4040Bu yetenegi bilmiyorsun:|r ") .. info.name)
        return
    end
    -- Sinif cooldown'u / racial ise zaten listede: modunu ayarlardan degistir
    local existing = ns.byName[info.name]
    if existing and not existing:find("^Track") then
        ns.Print(info.name .. L(" zaten listede; kullanim modunu /rof -> sinif -> Cooldown kullanimi'ndan degistir."))
        return
    end
    for _, t in ipairs(TrackedList()) do
        if t.id == info.spellID or t.name == info.name then ns.Print(L("Zaten takipte: ") .. info.name); return end
    end
    ns.cdb.tracked = ns.cdb.tracked or {}
    table.insert(ns.cdb.tracked, { id = info.spellID, name = info.name })
    ns.cdb.cdMode[TrackKey(info.spellID)] = "track"
    if ns.Refresh then ns.Refresh() end
    ns.Print((L("Takibe eklendi: |cff40ff40%s|r  (mod: %s). Cubukta hemen gorunur; mod secimi ayarlar panelinde /reload sonrasi."))
        :format(info.name, L(ns.CD_MODE_NAMES.track)))
end

function ns.TrackRemove(text)
    text = (text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local list = TrackedList()
    for i, t in ipairs(list) do
        if t.name:lower() == text or tostring(t.id) == text then
            table.remove(list, i)
            ns.cdb.cdMode[TrackKey(t.id)] = nil
            if ns.Refresh then ns.Refresh() end
            ns.Print(L("Takipten cikarildi: ") .. t.name)
            return
        end
    end
    ns.Print(L("Takip listesinde yok: ") .. text)
end

function ns.TrackPrint()
    local list = TrackedList()
    if #list == 0 then ns.Print(L("Takip listesi bos. Eklemek icin: /rof track <yetenek>")); return end
    for i, t in ipairs(list) do
        ns.Print((L("  %d. %s (ID %d) - %s")):format(i, t.name, t.id,
            L(ns.CD_MODE_NAMES[ns.cdb.cdMode[TrackKey(t.id)] or "track"])))
    end
end

---------------------------------------------------------------------------
-- Trinket'ler
---------------------------------------------------------------------------
local SLOTS = { 13, 14 }
local SLOT_LABEL = { [13] = "Trinket 1 (ust)", [14] = "Trinket 2 (alt)" }
local trinkets = {}          -- slot -> giris
local itemDur = {}           -- spellID -> son okunan cooldown suresi (savasta gizliyse)

local function ScanTrinkets()
    entriesCache = nil
    wipe(trinkets)
    local getSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
    for _, slot in ipairs(SLOTS) do
        local itemID = ns.Call(GetInventoryItemID, "player", slot)
        if itemID and getSpell then
            local ok, spellName, spellID = pcall(getSpell, itemID)
            if ok and type(spellID) == "number" and not issecret(spellID) then
                trinkets[slot] = {
                    key = "Trinket" .. slot, label = SLOT_LABEL[slot], name = spellName, id = spellID,
                    itemID = itemID, slot = slot, isItem = true, default = "big",
                    icon = ns.Call(GetInventoryItemTexture, "player", slot),
                }
            end
        end
    end
end

function ns.TrinketSlots() return SLOTS, SLOT_LABEL end

---------------------------------------------------------------------------
-- Giris listesi (sinif -> racial -> trinket)
---------------------------------------------------------------------------
function ns.CooldownEntries(cls)
    if entriesCache and entriesFor == cls then return entriesCache end
    local out = {}
    for _, c in ipairs(cls and cls.cooldowns or {}) do
        local s = ns.spells[c.key]
        if s then
            out[#out + 1] = { key = c.key, name = s.name, label = s.name, id = s.id, icon = s.icon,
                              default = c.default or "big", cond = c.cond }
        end
    end
    for _, key in ipairs(RACIAL_ORDER) do
        local s = ns.spells[key]
        if s then
            out[#out + 1] = { key = key, name = s.name, label = s.name .. " " .. L("(racial)"), id = s.id,
                              icon = s.icon, default = RACIAL_DEFAULT[key] }
        end
    end
    for _, slot in ipairs(SLOTS) do
        if trinkets[slot] then out[#out + 1] = trinkets[slot] end
    end
    for _, t in ipairs(TrackedList()) do
        local key = TrackKey(t.id)
        local s = ns.spells[key]
        if s then
            out[#out + 1] = { key = key, name = s.name, label = s.name .. " " .. L("(takip)"), id = s.id,
                              icon = s.icon, default = "track", tracked = true }
        end
    end
    -- Kullanicinin sirasi (cooldown cubugunda surukle-birak): siradakiler once, digerleri
    -- kendi sirasinda sonra
    local order = ns.cdb and ns.cdb.cdOrder
    if order and #order > 0 then
        local rank = {}
        for i, key in ipairs(order) do rank[key] = i end
        for i, e in ipairs(out) do e.base = i end
        table.sort(out, function(a, b)
            local ra, rb = rank[a.key] or (1000 + a.base), rank[b.key] or (1000 + b.base)
            return ra < rb
        end)
    end
    entriesCache, entriesFor = out, cls
    return out
end

-- Surukle-birak: `fromKey` girisini `toKey`'in yerine tasi (digerleri kayar)
function ns.CooldownMove(fromKey, toKey)
    local cls = ns.classes[ns.playerClass]
    local keys = {}
    for _, e in ipairs(ns.CooldownEntries(cls)) do keys[#keys + 1] = e.key end
    local from, to
    for i, k in ipairs(keys) do
        if k == fromKey then from = i end
        if k == toKey then to = i end
    end
    if not from or not to then return end
    table.insert(keys, to, table.remove(keys, from))
    ns.cdb.cdOrder = keys
    entriesCache = nil
end

function ns.CooldownOrderReset()
    if ns.cdb then ns.cdb.cdOrder = nil end
    entriesCache = nil
end

function ns.TrackedEntries()
    local out = {}
    for _, t in ipairs(TrackedList()) do
        out[#out + 1] = { key = TrackKey(t.id), label = t.name .. " " .. L("(takip)"), default = "track" }
    end
    return out
end

-- Cooldown zamanlari (widget'a gidecek ham, belki gizli) ve hazir mi (true/false/nil)
function ns.CooldownTimes(e)
    local now = GetTime()
    if e.isItem then
        local ok, start, dur = pcall(GetInventoryItemCooldown, "player", e.slot)
        if not ok then return nil, nil, nil end
        if not issecret(start) and not issecret(dur) and start and dur then
            if dur > 1.5 then itemDur[e.id] = dur end
            return start, dur, start == 0 or dur <= 1.5 or (start + dur - now) <= 0.25
        end
        -- Gizli: son kullanim (UNIT_SPELLCAST_SUCCEEDED) + bilinen sure
        local last = ns.lastCast[e.name]
        local known = itemDur[e.id]
        if not last then return start, dur, nil end
        -- Suresi hic okunamadiysa (ilk kullanim savasta): cogu trinket 2 dk; o kadar bekle
        return start, dur, now - last >= (known or 120) - 0.25
    end
    local start, dur
    local cd = ns.Call(C_Spell.GetSpellCooldown, e.id)
    if cd and not issecrettable(cd) then start, dur = cd.startTime, cd.duration end
    return start, dur, ns.Ready(e.key)
end

local function ModeOK(mode, kind, group)
    if mode == "off" or mode == "track" then return false end
    if mode == "always" then return true end
    if mode == "boss" then return kind == "boss" end
    if mode == "elite" then return kind ~= "normal" end
    return kind ~= "normal" or group   -- big
end

function ns.CooldownMode(e)
    local modes = ns.cdb and ns.cdb.cdMode
    return modes and modes[e.key] or e.default
end

-- Her giris icin durum + ilk onerilen. Sinifin cond fonksiyonlari sinifin bu turki
-- durumunu (ReadContext) kullanir: Next'ten sonra, sira tahmininden once cagrilmali.
function ns.CooldownStates(cls)
    if not ns.db.cds then return {}, nil end
    -- Saldirilabilir bir hedef yokken (grupta, savasta) onerme
    local inCombat = ns.InCombat() and ns.Call(UnitCanAttack, "player", "target") == true
    local kind, group = ns.TargetKind(), IsInGroup() and true or false
    local states, first = {}, nil
    for _, e in ipairs(ns.CooldownEntries(cls)) do
        local mode = ns.CooldownMode(e)
        if mode ~= "off" then
            local start, dur, ready = ns.CooldownTimes(e)
            local usable
            if e.isItem then usable = ns.Call(C_Item and C_Item.IsUsableItem or IsUsableItem, e.itemID) ~= false
            else usable = ns.Usable(e.key, true) end
            local rec = inCombat and ready ~= false and usable and ModeOK(mode, kind, group)
                        and (not e.cond or e.cond()) and true or false
            local st = { entry = e, start = start, dur = dur, ready = ready, recommended = rec }
            states[#states + 1] = st
            if rec and not first then
                first = { key = e.key, name = e.name, id = e.id, icon = e.icon, cooldown = true, isItem = e.isItem }
            end
        end
    end
    return states, first
end

-- Eşya verisi girişte henuz onbellekte olmayabilir (GetItemSpell nil): veri gelince
-- (GET_ITEM_INFO_RECEIVED) ve birkac saniye sonra tekrar tara
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ns.ScanTrinkets = function() ScanTrinkets() end   -- modul yeniden acilinca (Init.lua)
ev:SetScript("OnEvent", function(_, event, itemID)
    if ns.stopped then return end   -- modul kapali: acilinca bir kez taranir
    -- GET_ITEM_INFO_RECEIVED her esya sorgusunda gelir: sadece takili trinket icin tara
    if event == "GET_ITEM_INFO_RECEIVED" then
        local mine = false
        for _, slot in ipairs(SLOTS) do
            if itemID ~= nil and not issecret(itemID) and itemID == ns.Call(GetInventoryItemID, "player", slot) then mine = true end
        end
        if not mine then return end
    end
    ScanTrinkets()
    if event == "PLAYER_ENTERING_WORLD" then C_Timer.After(3, ScanTrinkets) end
end)
