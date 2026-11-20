local _, A = ...
local ns = A.RF
if not ns then return end

-- Blizzard aksiyon barlari: buton on eki -> tus atama on eki
local BARS = {
    { "ActionButton",              "ACTIONBUTTON" },
    { "MultiBarBottomLeftButton",  "MULTIACTIONBAR1BUTTON" },
    { "MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON" },
    { "MultiBarRightButton",       "MULTIACTIONBAR3BUTTON" },
    { "MultiBarLeftButton",        "MULTIACTIONBAR4BUTTON" },
    { "MultiBar5Button",           "MULTIACTIONBAR5BUTTON" },
    { "MultiBar6Button",           "MULTIACTIONBAR6BUTTON" },
    { "MultiBar7Button",           "MULTIACTIONBAR7BUTTON" },
}

local buttons = {}
local seen    = {}   -- btn -> true (ayni butonu iki kez eklememek icin)
local counts  = { Blizzard = 0, ElvUI = 0, Bartender4 = 0 }

-- Kendi parlama cercevemiz (secure butona dokunmadan ustune biner).
-- Savas disinda olusturulur.
local function MakeGlow(btn)
    local g = CreateFrame("Frame", nil, btn)
    g:SetAllPoints(btn)
    g:SetFrameLevel(btn:GetFrameLevel() + 5)

    local t = g:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    t:SetBlendMode("ADD")
    t:SetVertexColor(1, 0.85, 0.1)
    t:SetPoint("CENTER")
    g.tex = t

    local ag = g:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.35)
    a:SetDuration(0.45)
    g.anim = ag

    g:SetScript("OnShow", function(self)
        local w = btn:GetWidth() or 40
        self.tex:SetSize(w * 1.9, w * 1.9)
    end)
    g:Hide()
    return g
end

-- form: durus cubugu butonlarinda form sirasi (1 = Battle Stance ...)
local function Add(btn, source, binding, form)
    if not btn or seen[btn] then return end
    seen[btn] = true
    counts[source] = counts[source] + 1
    buttons[#buttons + 1] = { btn = btn, glow = MakeGlow(btn), binding = binding, form = form }
end

-- Butonlar farkli zamanlarda olusur (ElvUI/Bartender kendi girislerinde),
-- bu yuzden birkac kez taranir. Yeni butonlar sadece savas disinda eklenir.
function ns.Highlight_Scan()
    if InCombatLockdown() then return end

    for _, bar in ipairs(BARS) do
        for i = 1, 12 do
            Add(_G[bar[1] .. i], "Blizzard", bar[2] .. i)
        end
    end

    -- ElvUI: ElvUI_Bar1Button1 ... ElvUI_Bar15Button12
    for b = 1, 15 do
        for i = 1, 12 do
            Add(_G[("ElvUI_Bar%dButton%d"):format(b, i)], "ElvUI")
        end
    end

    -- Bartender4: BT4Button1 ... BT4Button180
    for i = 1, 180 do
        Add(_G["BT4Button" .. i], "Bartender4")
    end

    -- Durus cubuklari (Battle / Defensive / Berserker Stance onerisi icin)
    for i = 1, 10 do
        Add(_G["StanceButton" .. i], "Blizzard", "SHAPESHIFTBUTTON" .. i, i)
        Add(_G["ElvUI_StanceBarButton" .. i], "ElvUI", "SHAPESHIFTBUTTON" .. i, i)
        Add(_G["BT4StanceButton" .. i], "Bartender4", "SHAPESHIFTBUTTON" .. i, i)
    end
end

function ns.Highlight_Init()
    ns.Highlight_Scan()
    C_Timer.After(2, ns.Highlight_Scan)
end

function ns.Highlight_Counts() return counts end

local function ActionSpellName(slot)
    if not slot or ns.issecret(slot) or not HasAction(slot) then return nil end
    local t, id = GetActionInfo(slot)
    if not t or ns.issecret(t) or ns.issecret(id) then return nil end
    if t == "spell" then
        return C_Spell.GetSpellName(id)
    elseif t == "macro" then
        local sid = GetMacroSpell(id)
        if sid and not ns.issecret(sid) then return C_Spell.GetSpellName(sid) end
    elseif t == "item" then
        -- Trinket / eşya: "Use:" buyusunun adi (Cooldowns.lua girisleriyle ayni ad)
        local getSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
        local ok, spellName = pcall(getSpell, id)
        if ok and type(spellName) == "string" then return spellName end
    end
end

-- Blizzard butonlari slotu btn.action'da tutar. ElvUI ve Bartender4
-- LibActionButton kullanir: tip _state_type, deger _state_action.
local function ButtonSpellName(b)
    local btn = b.btn
    if b.form then
        local ok, _, _, _, spellID = pcall(GetShapeshiftFormInfo, b.form)
        if ok and spellID and not ns.issecret(spellID) then return C_Spell.GetSpellName(spellID) end
        return nil
    end
    local stype = btn._state_type
    if ns.issecret(stype) then return nil end
    if stype ~= nil then
        local v = btn._state_action
        if stype == "action" then return ActionSpellName(v) end
        if stype == "spell" and v and not ns.issecret(v) then return C_Spell.GetSpellName(v) end
        return nil
    end
    return ActionSpellName(btn.action)
end

local function ShortKey(key)
    return (key:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A")
               :gsub("MOUSEWHEELUP", "MWU"):gsub("MOUSEWHEELDOWN", "MWD")
               :gsub("BUTTON", "M"):gsub("NUMPAD", "N"))
end

-- Tus atamasini sirayla dener: Blizzard adi, ElvUI/LAB keyBoundTarget,
-- Bartender4'un CLICK baglamalari.
local function ButtonKey(b)
    local btn = b.btn
    local name = btn:GetName()
    local candidates = {
        b.binding,
        btn.keyBoundTarget,
        btn.config and btn.config.keyBoundTarget,
        name and ("CLICK " .. name .. ":Keybind"),
        name and ("CLICK " .. name .. ":LeftButton"),
    }
    for i = 1, 5 do
        local c = candidates[i]
        if type(c) == "string" then
            local key = GetBindingKey(c)
            if key then return ShortKey(key) end
        end
    end
end

local COLORS = {
    main  = { 1, 0.85, 0.1 },   -- sari: ana oneri
    extra = { 0.3, 0.7, 1 },    -- mavi: kucuk ikon (GCD disi / cooldown)
    interrupt = { 1, 0.2, 0.2 }, -- kirmizi: interrupt
    aoe = { 0.75, 0.35, 1 },     -- mor: ayri AoE ikonu
    cd  = { 1, 0.55, 0 },        -- turuncu: onerilen buyuk cooldown
}

local function SetGlow(b, kind)
    if kind and ns.db.glow then
        if b.glowKind ~= kind then
            b.glow.tex:SetVertexColor(unpack(COLORS[kind]))
            b.glowKind = kind
        end
        b.glow:Show()
        if not b.glow.anim:IsPlaying() then b.glow.anim:Play() end
    elseif b.glow:IsShown() then
        b.glow.anim:Stop(); b.glow:Hide()
    end
end

-- Onerilen buyuleri iceren butonlari parlatir, her birinin ilk eslesen
-- butonunun tusunu dondurur.
---------------------------------------------------------------------------
-- Onbellek: butondaki buyu adi ve tus atamasi saniyede 10 kez okunmasin.
-- Bar / durus / sayfa degisince (olaylar) ve en gec 1 sn'de bir yenilenir;
-- bar addon'lari sayfa degistirirken her zaman olay gondermez.
---------------------------------------------------------------------------
local nameGen, keyGen, nameAt = 1, 1, 0

local function CachedName(b)
    if b.nameGen ~= nameGen then b.spellName, b.nameGen = ButtonSpellName(b), nameGen end
    return b.spellName
end

local function CachedKey(b)
    if b.keyGen ~= keyGen then b.keyText, b.keyGen = ButtonKey(b), keyGen end
    return b.keyText
end

-- view: { main, extra, aoe, queue }. Parlama: ana sari, kucuk mavi (interrupt kirmizi),
-- AoE mor. Sira ikonlari parlamaz, sadece tus atamalari bulunur.
-- Doner: { main = tus, extra = tus, aoe = tus, queue = { tus, ... } }
-- Tablolar her tick yeniden kullanilir (10 Hz'de cop uretmesin); donen binds sadece
-- ayni tick icinde okunur (Display / CooldownBar), saklanmaz.
local wanted, cdNames, queueNames = {}, {}, {}
local binds = { queue = {}, cd = {} }
function ns.Highlight_Set(view)
    local now = GetTime()
    -- Tus atamalari da: her baglama addon'u UPDATE_BINDINGS gondermez
    if now - nameAt >= 1 then nameGen, keyGen, nameAt = nameGen + 1, keyGen + 1, now end

    local main, extra, aoe = view.main, view.extra, view.aoe
    -- wanted: buyu adi -> parlama turu (sonra yazilan kazanir: ana > kucuk > AoE > cooldown)
    wipe(wanted); wipe(cdNames); wipe(queueNames); wipe(binds.queue); wipe(binds.cd)
    binds.main, binds.extra, binds.aoe = nil, nil, nil
    for _, st in ipairs(view.cds or {}) do
        cdNames[st.entry.name] = true
        if st.recommended then wanted[st.entry.name] = "cd" end
    end
    if aoe then wanted[aoe.name] = "aoe" end
    if extra then wanted[extra.name] = extra.interrupt and "interrupt" or "extra" end
    if main then wanted[main.name] = "main" end
    for i, q in ipairs(view.queue or {}) do queueNames[q.name] = queueNames[q.name] or i end

    local any = main or extra or aoe or next(queueNames) or next(cdNames)
    for _, b in ipairs(buttons) do
        local kind
        if any and b.btn:IsVisible() then
            local name = CachedName(b)
            if name then
                kind = wanted[name]
                if kind == "main" then binds.main = binds.main or CachedKey(b)
                elseif kind == "aoe" then binds.aoe = binds.aoe or CachedKey(b)
                elseif kind == "extra" or kind == "interrupt" then binds.extra = binds.extra or CachedKey(b) end
                if cdNames[name] and not binds.cd[name] then binds.cd[name] = CachedKey(b) end
                local qi = queueNames[name]
                if qi then
                    -- Ayni buyu sirada birden fazla kez olabilir
                    for i, q in ipairs(view.queue) do
                        if q.name == name then binds.queue[i] = binds.queue[i] or CachedKey(b) end
                    end
                end
            end
        end
        SetGlow(b, kind)
    end
    -- Ayni buyu hem ana hem AoE onerisiyse tus her iki ikonda da gorunsun
    if aoe and main and aoe.name == main.name then binds.aoe = binds.main end
    if aoe and extra and aoe.name == extra.name then binds.aoe = binds.extra end
    return binds
end

local cacheEv = CreateFrame("Frame")
for _, e in ipairs({ "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR",
                     "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "SPELLS_CHANGED",
                     "PLAYER_ENTERING_WORLD", "UPDATE_BINDINGS" }) do
    pcall(cacheEv.RegisterEvent, cacheEv, e)
end
cacheEv:SetScript("OnEvent", function(_, event)
    if event == "UPDATE_BINDINGS" then keyGen = keyGen + 1 else nameGen = nameGen + 1 end
end)

-- Bar addon'lari profil/sayfa degistirince veya savas bitince yeni butonlari yakala
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
    if ns.db and not ns.stopped then ns.Highlight_Scan() end   -- modul kapali: butonlara parlama cercevesi kurma
end)
