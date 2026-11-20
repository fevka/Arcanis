local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Buyuk cooldown cubugu (db.cdDisplay = "bar"): takip edilen her cooldown bir ikon.
--   * cooldown'da: donen dilim + sure yazisi, ikon soluk
--   * hazir: normal renk
--   * onerilen (kosullar tutuyor): altin, nabiz gibi atan kenarlik
-- Esnek yapi: db.cdDir yonunde buyur (sag / sol / asagi / yukari / ortali), db.cdPerRow
-- ikonda bir satira (ya da sutuna) sarar; ikon sayisi degisince cubuk kendini yeniden dizer.
-- Kilit acikken ikonlar suruklenerek siralanir (db cdOrder).
-- Savasta cooldown zamanlari gizli olabilir; CooldownFrameTemplate gizli degerleri kabul
-- eder, bu yuzden zamanlar karsilastirilmadan pcall ile dogrudan widget'a verilir.

local bar
local icons = {}
local shownCount, laidOut = 0, -1
local dragFrom
local QUESTION_MARK = 134400

-- Yone gore cubugun sabit kosesi: cubuk bu koseden disari buyur
local DIR_POINT = { right = "TOPLEFT", left = "TOPRIGHT", down = "TOPLEFT", up = "BOTTOMLEFT", center = "TOP" }

local function DropOn(target)
    if dragFrom and target and target.entryKey and target.entryKey ~= dragFrom then
        ns.CooldownMove(dragFrom, target.entryKey)
    end
    dragFrom = nil
end

local function MakeIcon()
    local i = CreateFrame("Frame", nil, bar)
    i.bg = i:CreateTexture(nil, "BACKGROUND")
    i.bg:SetPoint("TOPLEFT", -2, 2)
    i.bg:SetPoint("BOTTOMRIGHT", 2, -2)
    i.bg:SetColorTexture(0, 0, 0, 0.9)

    i.icon = i:CreateTexture(nil, "ARTWORK")
    i.icon:SetAllPoints()
    i.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    i.cd = CreateFrame("Cooldown", nil, i, "CooldownFrameTemplate")
    i.cd:SetAllPoints(i.icon)
    if i.cd.SetDrawEdge then i.cd:SetDrawEdge(false) end
    if i.cd.SetDrawBling then i.cd:SetDrawBling(false) end
    if i.cd.SetHideCountdownNumbers then i.cd:SetHideCountdownNumbers(false) end
    i.cd:EnableMouse(false)

    -- Onerilen cooldown: altin kenarlik, nabiz animasyonu
    i.glow = i:CreateTexture(nil, "OVERLAY")
    i.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    i.glow:SetBlendMode("ADD")
    i.glow:SetVertexColor(1, 0.75, 0.1)
    i.glow:SetPoint("CENTER")
    local ag = i:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetTarget(i.glow)
    a:SetFromAlpha(1); a:SetToAlpha(0.25); a:SetDuration(0.5)
    i.pulse = ag
    i.glow:Hide()

    i.key = i:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    i.key:SetPoint("TOPRIGHT", -1, -1)

    -- Kilit acikken surukle-birak ile siralama
    i:RegisterForDrag("LeftButton")
    i:SetScript("OnDragStart", function(self)
        dragFrom = self.entryKey
        self:SetAlpha(0.4)
    end)
    i:SetScript("OnDragStop", function(self)
        self:SetAlpha(1)
        local target
        for n = 1, shownCount do
            local o = icons[n]
            if o ~= self and o:IsShown() and o:IsMouseOver() then target = o; break end
        end
        DropOn(target)
    end)
    i:Hide()
    return i
end

local function Icon(n)
    icons[n] = icons[n] or MakeIcon()
    return icons[n]
end

function ns.CDBar_Init()
    bar = ns.MakeGroup("cd", L("Cooldown cubugu (ikonlari surukleyerek sirala)"))
end

-- `n` gorunur ikonu yone ve satir sayisina gore diz; cubugun boyutunu ayarla
local function Arrange(n)
    local db = ns.db
    local sp, size = db.iconSpacing, db.cdSize
    local step = size + sp
    local per = (db.cdPerRow > 0 and db.cdPerRow < n) and db.cdPerRow or math.max(n, 1)
    local lines = math.ceil(math.max(n, 1) / per)
    local dir = db.cdDir
    local horizontal = dir ~= "down" and dir ~= "up"
    local long, short = per * step - sp, lines * step - sp
    if horizontal then bar:SetSize(long, short) else bar:SetSize(short, long) end

    for k = 1, n do
        local i = icons[k]
        local idx = k - 1
        local line, pos = math.floor(idx / per), idx % per
        i:ClearAllPoints()
        if dir == "left" then
            i:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -pos * step, -line * step)
        elseif dir == "down" then
            i:SetPoint("TOPLEFT", bar, "TOPLEFT", line * step, -pos * step)
        elseif dir == "up" then
            i:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", line * step, pos * step)
        elseif dir == "center" then
            -- Her satiri ortala (son satir eksik olabilir)
            local inLine = math.min(per, n - line * per)
            local offset = (per - inLine) * step / 2
            i:SetPoint("TOPLEFT", bar, "TOPLEFT", offset + pos * step, -line * step)
        else
            i:SetPoint("TOPLEFT", bar, "TOPLEFT", pos * step, -line * step)
        end
    end
    laidOut = n
end

-- Display.lua cagirir: place(bar, kose) cubugu yerlestirir
function ns.CDBar_Layout(place)
    if not bar then return end
    local db = ns.db
    for n = 1, db.cdMax do
        local i = Icon(n)
        i:SetSize(db.cdSize, db.cdSize)
        i.glow:SetSize(db.cdSize * 1.9, db.cdSize * 1.9)
    end
    for n = db.cdMax + 1, #icons do icons[n]:Hide() end
    place(bar, DIR_POINT[db.cdDir] or "TOPLEFT")
    laidOut = -1   -- boyut / yon degisti: bir sonraki Set yeniden dizsin
    Arrange(math.max(math.min(shownCount, db.cdMax), 1))
end

local function SetGlow(i, on)
    if on then
        i.glow:Show()
        -- Cerceve gizlenip acilinca animasyon durur: oynamiyorsa yeniden baslat
        if not i.pulse:IsPlaying() then i.pulse:Play() end
    elseif i.glow:IsShown() then
        i.pulse:Stop(); i.glow:Hide()
    end
end

local function Paint(i, st, key, unlocked)
    local e = st.entry
    i.entryKey = e.key
    i:EnableMouse(unlocked)
    i.icon:SetTexture(e.icon or QUESTION_MARK)
    i.key:SetText(key or "")
    -- type() gizli degerde de guvenli; "if st.start" ise gizli degeri test eder (hata)
    if type(st.start) == "number" and type(st.dur) == "number" then
        pcall(i.cd.SetCooldown, i.cd, st.start, st.dur)
    else
        i.cd:Clear()
    end
    if st.ready == true then i.cd:Clear() end
    i.icon:SetDesaturated(st.ready == false)
    SetGlow(i, ns.db.cdGlow and st.recommended)
    i:Show()
end

-- Doner: gorunen ikon sayisi
function ns.CDBar_Set(view, unlocked)
    if not bar then return 0 end
    local db = ns.db
    local n = 0
    if db.cds and db.cdDisplay == "bar" then
        for _, st in ipairs(view.cds or {}) do
            if n >= db.cdMax then break end
            -- Kilit acikken hepsi (siralamak icin); kilitliyken ayara gore
            if unlocked or not db.cdOnlyReady or st.ready ~= false then
                n = n + 1
                Paint(Icon(n), st, view.binds and view.binds.cd and view.binds.cd[st.entry.name], unlocked)
            end
        end
        -- Kilit acikken hic giris yoksa yer tutucu: cubugun yeri ve boyutu gorunsun
        if unlocked and n == 0 then
            for k = 1, math.min(3, db.cdMax) do
                local i = Icon(k)
                i.entryKey = nil
                i:EnableMouse(false)
                i.icon:SetTexture(QUESTION_MARK); i.icon:SetDesaturated(false)
                i.cd:Clear(); i.key:SetText(""); SetGlow(i, false); i:Show()
            end
            n = math.min(3, db.cdMax)
        end
    end
    for k = n + 1, #icons do
        SetGlow(icons[k], false)
        icons[k]:Hide()
    end
    shownCount = n
    if n > 0 and n ~= laidOut then Arrange(n) end
    return n
end
