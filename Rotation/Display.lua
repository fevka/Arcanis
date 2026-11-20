local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Ekran gruplari:
--   main  : ana ikon + sira ikonlari (sira yonu: db.queueDir)
--   extra : kucuk ikon (GCD disi / savunma / interrupt)
--   aoe   : ayri AoE ikonu
--   cd    : buyuk cooldown cubugu (CooldownBar.lua; yon / ortalama / satira sarma)
--
-- db.layoutMode:
--   together : hepsi ana gruba bagli, birlikte tasinir (db.iconLayout yatay / dikey)
--   free     : her grup kendi tutamacindan ayri suruklenir ve yeri kaydedilir. Hic
--              suruklenmemis grup ana gruba gore varsayilan yerinde durur.
-- Kilit acikken her grubun ustunde bir tutamac (etiketli serit) gorunur.

local f
local MAX_QUEUE = 3
local QUESTION_MARK = 134400
local groups = {}   -- ad -> cerceve

local BORDER = {
    normal    = { 0, 0, 0, 0.9 },
    interrupt = { 1, 0.1, 0.1, 1 },
    aoe       = { 0.6, 0.25, 0.9, 1 },
}

local function MakeIcon(parent, font)
    local i = CreateFrame("Frame", nil, parent)
    i.bg = i:CreateTexture(nil, "BACKGROUND")
    i.bg:SetPoint("TOPLEFT", -2, 2)
    i.bg:SetPoint("BOTTOMRIGHT", 2, -2)
    i.icon = i:CreateTexture(nil, "ARTWORK")
    i.icon:SetAllPoints()
    i.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    i.key = i:CreateFontString(nil, "OVERLAY", font)
    i.key:SetPoint("TOPRIGHT", -2, -2)
    i.label = i:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    i.label:SetPoint("BOTTOM", 0, 2)
    i:Hide()
    return i
end

local function Border(i, kind)
    i.bg:SetColorTexture(unpack(BORDER[kind] or BORDER.normal))
end

---------------------------------------------------------------------------
-- Gruplar: cerceve + tutamac + kayitli konum
---------------------------------------------------------------------------
local function Free() return ns.db.layoutMode == "free" end

-- Kaydedilen konum: grubun `point` kosesinin UIParent sol-altina gore yeri, UIParent
-- biriminde (cercevenin olcegiyle carpilmis). Boylece olcek degisince grup kaymaz.
local POINT_POS = {
    TOPLEFT     = function(g) return g:GetLeft(), g:GetTop() end,
    TOPRIGHT    = function(g) return g:GetRight(), g:GetTop() end,
    TOP         = function(g) return (g:GetLeft() + g:GetRight()) / 2, g:GetTop() end,
    BOTTOMLEFT  = function(g) return g:GetLeft(), g:GetBottom() end,
}

-- Kilit acik mi: ayar ya da ayar onizlemesi (Arcanis ayarlarinda Rotation helper acikken)
function ns.Unlocked() return (ns.db and not ns.db.locked) or ns.preview == true end

-- Onizleme: ayarlar acikken ikonlar soru isaretli yer tutucularla Arcanis penceresinin USTUNDE gorunur (pencere
-- DIALOG katmaninda, ikonlar normalde MEDIUM'da kalip altinda kaybolur); her degisiklik aninda gorulur.
function ns.UI_SetPreview(on)
    on = on and true or false
    if ns.preview == on then return end
    ns.preview = on
    for _, g in pairs(groups or {}) do g:SetFrameStrata(on and "FULLSCREEN_DIALOG" or "MEDIUM") end
    if ns.UI_Apply then ns.UI_Apply() end
end

local function SavePosition(name, g, point)
    point = point or g.anchorPoint or "TOPLEFT"
    if not g:GetLeft() then return end
    local x, y = POINT_POS[point](g)
    local s = g:GetScale()
    ns.db.groupPos[name] = { point, x * s, y * s }
end

local function MakeGroup(name, label)
    local g = CreateFrame("Frame", "RotationForge_" .. name, UIParent)
    g:SetSize(1, 1)
    g:SetClampedToScreen(true)
    g:SetMovable(true)
    g.groupName = name

    -- Tutamac: kilit acikken gorunen, suruklenebilen etiketli serit
    local h = CreateFrame("Frame", nil, g)
    h:SetHeight(14)
    h:SetPoint("BOTTOMLEFT", g, "TOPLEFT", -2, 3)
    h:SetPoint("BOTTOMRIGHT", g, "TOPRIGHT", 2, 3)
    h.bg = h:CreateTexture(nil, "BACKGROUND")
    h.bg:SetAllPoints()
    h.bg:SetColorTexture(1, 0.82, 0, 0.35)
    h.text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h.text:SetPoint("LEFT", 3, 0)
    h.text:SetText(label)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:SetScript("OnDragStart", function()
        -- Birlikte modunda sadece ana grup tasinir (digerleri ona bagli)
        local target = (Free() or name == "main") and g or groups.main
        target:StartMoving()
        h.moving = target
    end)
    h:SetScript("OnDragStop", function()
        local target = h.moving or g
        target:StopMovingOrSizing()
        h.moving = nil
        SavePosition(target.groupName, target)
        ns.UI_Apply()
    end)
    h:Hide()
    g.handle = h
    groups[name] = g
    return g
end
ns.MakeGroup = MakeGroup

-- Grubu yerlestir: serbest modda kayitli yer varsa oraya, yoksa `relative`'e
-- (ana gruba gore varsayilan yer)
local function Place(name, g, point, relative)
    local pos = ns.db.groupPos[name]
    local saved = (Free() or name == "main") and pos
    -- Kayitli kose istenen koseden farkliysa (cubugun yonu degisti): cerceve hala
    -- yerindeyken (ClearAllPoints'ten ONCE) mevcut sinirlardan yeni koseye cevir
    if saved and pos[1] ~= point and g:GetLeft() then
        SavePosition(name, g, point)
        pos = ns.db.groupPos[name]
    end
    g:ClearAllPoints()
    g.anchorPoint = point
    if saved then
        local s = g:GetScale()
        g:SetPoint(pos[1], UIParent, "BOTTOMLEFT", pos[2] / s, pos[3] / s)
    elseif relative then
        relative(g)
    else
        g:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    end
end

---------------------------------------------------------------------------
-- Yerlesim
---------------------------------------------------------------------------
local QUEUE_ANCHOR = {
    right = { "LEFT", "RIGHT", 1, 0 },
    left  = { "RIGHT", "LEFT", -1, 0 },
    down  = { "TOP", "BOTTOM", 0, -1 },
    up    = { "BOTTOM", "TOP", 0, 1 },
}

local function Layout()
    local db = ns.db
    local sp = db.iconSpacing
    local vertical = db.iconLayout == "vertical"

    for _, g in pairs(groups) do g:SetScale(db.scale) end

    -- Ana grup
    f:SetSize(db.mainSize, db.mainSize)
    Place("main", f, "TOPLEFT", function(g)
        local pt = db.point   -- eski tek cerceve konumu (henuz kaydedilmediyse)
        g:SetPoint(pt[1], UIParent, pt[3], pt[4], pt[5])
    end)
    local qa = QUEUE_ANCHOR[db.queueDir] or QUEUE_ANCHOR.right
    local prev = f.main
    for n = 1, MAX_QUEUE do
        local q = f.queue[n]
        q:SetSize(db.queueSize, db.queueSize)
        q:SetAlpha(db.queueAlpha)
        q:ClearAllPoints()
        q:SetPoint(qa[1], prev, qa[2], qa[3] * sp, qa[4] * sp)
        prev = q
    end

    -- Kucuk ikon
    local gx = groups.extra
    gx:SetSize(db.extraSize, db.extraSize)
    Place("extra", gx, "TOPLEFT", function(g)
        if vertical then g:SetPoint("TOPLEFT", f, "TOPRIGHT", sp, 0)
        else g:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, sp + 16) end   -- tutamaca yer
    end)

    -- AoE ikonu
    local ga = groups.aoe
    ga:SetSize(db.aoeSize, db.aoeSize)
    Place("aoe", ga, "TOPLEFT", function(g)
        if vertical then g:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, sp + 16)
        else g:SetPoint("TOPRIGHT", f, "TOPLEFT", -sp, 0) end
    end)

    -- Cooldown cubugu (yon / ortalama CooldownBar.lua'da)
    if ns.CDBar_Layout then
        ns.CDBar_Layout(function(g, point)
            Place("cd", g, point, function(gg)
                if vertical then gg:SetPoint("TOPLEFT", gx, "TOPRIGHT", sp, 0)
                elseif point == "TOP" then gg:SetPoint("TOP", f, "BOTTOM", 0, -(sp + 18))
                elseif point == "TOPRIGHT" then gg:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -(sp + 18))
                elseif point == "BOTTOMLEFT" then gg:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, sp + db.extraSize + 34)
                else gg:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -(sp + 18)) end
            end)
        end)
    end
end

local function ApplyLock()
    local unlocked = ns.Unlocked()
    f:EnableMouse(false)
    for name, g in pairs(groups) do
        -- Birlikte modunda tek tutamac (ana grup); digerleri ana grupla gelir
        g.handle:SetShown(unlocked and (Free() or name == "main"))
    end
    groups.main.handle.text:SetText(Free() and L("Ana + sira (surukle)") or L("Hepsi (surukle)"))
end

-- Ayarlar paneli / komutlar degisiklikten sonra cagirir
function ns.UI_Apply()
    if not f then return end
    Layout()
    ApplyLock()
end

-- Tum konumlari varsayilana dondur
function ns.UI_ResetPositions()
    ns.db.groupPos = {}
    ns.db.point = { "CENTER", "UIParent", "CENTER", 0, -180 }
    if f then
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
        SavePosition("main", f, "TOPLEFT")
    end
    ns.UI_Apply()
    ns.Print(L("Ikon konumlari sifirlandi."))
end

-- Modul kapatilinca (Init.lua stop): ikonlar, gruplar ve tutamaclar gizlenir; onizleme biter. UI_Set'ten farkli
-- olarak kilit acikken yer tutucu cizmez.
function ns.UI_Stop()
    ns.preview = false
    if f then
        f.main:Hide(); f.extra:Hide(); f.aoe:Hide()
        for n = 1, MAX_QUEUE do f.queue[n]:Hide() end
        if ns.CDBar_Set then ns.CDBar_Set({}, false) end
    end
    for _, g in pairs(groups) do
        g:SetFrameStrata("MEDIUM")
        g.handle:Hide()
        g:Hide()
    end
end

function ns.UI_Init()
    if ns.uiReady then ns.UI_Apply() return end
    ns.uiReady = true
    local db = ns.db
    db.groupPos = db.groupPos or {}

    f = MakeGroup("main", L("Ana + sira (surukle)"))
    -- Eski tek-cerceve konumunu (db.point) ilk aciliste ana grubun konumu yap. db.point
    -- eski cercevenin olcegiyle kaydedildi: once ayni olcek.
    f:SetScale(db.scale)
    if not db.groupPos.main then
        f:SetPoint(db.point[1], UIParent, db.point[3], db.point[4], db.point[5])
        f:SetSize(db.mainSize, db.mainSize)
        SavePosition("main", f, "TOPLEFT")
    end

    f.main = MakeIcon(f, "NumberFontNormal")
    f.main:SetAllPoints()
    f.queue = {}
    for n = 1, MAX_QUEUE do f.queue[n] = MakeIcon(f, "NumberFontNormalSmall") end

    local gx = MakeGroup("extra", L("Kucuk ikon"))
    f.extra = MakeIcon(gx, "NumberFontNormalSmall")
    f.extra:SetAllPoints()

    local ga = MakeGroup("aoe", "AoE")
    f.aoe = MakeIcon(ga, "NumberFontNormalSmall")
    f.aoe:SetAllPoints()

    ns.CDBar_Init()   -- buyuk cooldown cubugu kendi grubunu kurar (CooldownBar.lua)

    ns.UI_Apply()
    for _, g in pairs(groups) do g:Hide() end
end

---------------------------------------------------------------------------
-- Cizim
---------------------------------------------------------------------------
local function Paint(i, rec, bind, border, label)
    Border(i, rec.interrupt and "interrupt" or border)
    i.icon:SetTexture(rec.icon)
    i.key:SetText(bind or "")
    i.label:SetText(label or "")
    local inRange = ns.Call(C_Spell.IsSpellInRange, rec.id, "target")
    if inRange == false then i.icon:SetVertexColor(1, 0.3, 0.3)   -- menzil disi: kirmizi
    else i.icon:SetVertexColor(1, 1, 1) end
    i:Show()
end

-- Kilit aciksa yer tutucu (soru isareti) ile goster ki yerlesim ve boyut gorulsun
local function Placeholder(i, border, label)
    Border(i, border)
    i.icon:SetTexture(QUESTION_MARK)
    i.icon:SetVertexColor(1, 1, 1)
    i.key:SetText("")
    i.label:SetText(label or "")
    i:Show()
end

-- Doner: ikon gorunuyor mu
local function Set(i, rec, bind, border, label, unlocked, wanted)
    if rec then Paint(i, rec, bind, border, label); return true end
    if unlocked and wanted then Placeholder(i, border, label); return true end
    i:Hide()
    return false
end

function ns.UI_Set(view)
    if not f then return end
    local db = ns.db
    local unlocked = ns.Unlocked()
    local binds = view.binds or { queue = {} }

    local anyMain = Set(f.main, view.main, binds.main, "normal", nil, unlocked, true)
    for n = 1, MAX_QUEUE do
        local shown = Set(f.queue[n], n <= db.queueCount and view.queue[n] or nil, binds.queue[n],
                          "normal", nil, unlocked, n <= db.queueCount)
        anyMain = anyMain or shown
    end
    local anyExtra = Set(f.extra, view.extra, binds.extra, "normal", nil, unlocked, db.showExtra)
    local anyAoe = Set(f.aoe, view.aoe, binds.aoe, "aoe", "AoE", unlocked, db.aoeDisplay == "separate")
    local cdCount = ns.CDBar_Set(view, unlocked) or 0

    -- Birlikte modunda digerleri ana gruba bagli: herhangi biri gorunuyorsa ana grup da acik
    local together = not Free()
    local anything = anyMain or anyExtra or anyAoe or cdCount > 0
    f:SetShown(anyMain or (together and anything))
    groups.extra:SetShown(anyExtra)
    groups.aoe:SetShown(anyAoe)
    if groups.cd then groups.cd:SetShown(cdCount > 0) end
end
