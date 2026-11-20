local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Talent rehberi: secili build'in sira listesine gore bir sonraki talent'i
-- gosterir. Puan harcamaz; sadece sohbet mesaji, talent butonu parlamasi ve
-- talent ekraninda (Blizzard_PlayerSpells) "SIRADAKI" parlamasi.
--
-- Build verisi: ns.BuildsForClass() (BuildImport.lua) -> { { key, name, spec, steps }, ... }
-- steps = { { "Talent", hedefRank }, ... }; spec: talent bolumu (1..3), otomatik secimde kullanilir.

ns.builds = ns.builds or {}

---------------------------------------------------------------------------
-- Build secimi ve sira
---------------------------------------------------------------------------
-- Secili build: ayardaki key, "auto" ise en cok puanli bolumun build'i
-- Sinifin olagan leveling agaci (Classic sekme sirasi): puan harcanmamisken build secimi icin.
local LEVELING_TAB = { WARRIOR = 1, PALADIN = 3, HUNTER = 1, ROGUE = 2, PRIEST = 3, SHAMAN = 2, MAGE = 3, WARLOCK = 1,
    DRUID = 2 }

function ns.ActiveBuild()
    -- yetenek planlayicisinda "siradaki talent icin kullan" secili plan her seyin onune gecer
    local plan = A.TalentPlanner and A.TalentPlanner:ActiveBuild()
    if plan then return plan end
    local list = ns.BuildsForClass()
    if #list == 0 then return nil end
    local want = ns.cdb and ns.cdb.build or "auto"
    if want ~= "auto" then
        for _, b in ipairs(list) do
            if b.key == want then return b end
        end
    end
    -- Liste sirasi: gomulu, guncelleyici (BuildsAuto), iceri aktarilan. Tersten bak:
    -- iceri aktarilan ve guncel cekilen build, gomulu (eskiyebilen) build'in onune gecer.
    -- hic puan yokken (agac 0) sinifin olagan leveling agaci: ilk gomulu build (Holy, Arcane...) secilip sonra
    -- baska build'e atlanmasin; sonraki puanlarda da ayni tersten tercih ayni build'i bulur
    local tab = ns.MainTalentTab()
    if not tab or tab == 0 then tab = LEVELING_TAB[ns.playerClass] end
    for i = #list, 1, -1 do
        if list[i].spec == tab then return list[i] end
    end
    return list[1]
end

-- Sonraki adim: ad, verilecek rank, hedef rank, bulunamayan talent'lar
function ns.NextTalent(build, skip)
    build = build or ns.ActiveBuild()
    if not build then return nil end
    local missing = {}
    local seen = 0
    for _, step in ipairs(build.steps) do
        local name, target = step[1], step[2]
        if ns.TalentCount() > 0 and not ns.Talent(name) then
            missing[#missing + 1] = name
        else
            local live = ns.TalentLiveRank(name)
            if live < target then
                seen = seen + 1
                if seen > (skip or 0) then return name, live + 1, target, missing end
            end
        end
    end
    return nil, nil, nil, missing
end

---------------------------------------------------------------------------
-- Parlamalar
---------------------------------------------------------------------------
local glows = {}

local function Glow(key, parent, label)
    local g = glows[key]
    if not g then
        g = CreateFrame("Frame", nil, UIParent)
        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        t:SetBlendMode("ADD")
        t:SetVertexColor(0.2, 1, 0.2)
        t:SetPoint("CENTER")
        g.tex = t
        -- Genis butonlar (Apply) icin ince kenarlik: kare halka dokusu esnetilince
        -- butonun ortasinda dar bir kutu olarak kaliyordu
        local E = 3
        g.edges = {}
        for i, pts in ipairs({
            { "TOPLEFT", -E, E, "TOPRIGHT", E, E },
            { "BOTTOMLEFT", -E, -E, "BOTTOMRIGHT", E, -E },
            { "TOPLEFT", -E, E, "BOTTOMLEFT", -E, -E },
            { "TOPRIGHT", E, E, "BOTTOMRIGHT", E, -E },
        }) do
            local e = g:CreateTexture(nil, "OVERLAY")
            e:SetColorTexture(0.2, 1, 0.2, 0.9)
            e:SetPoint(pts[1], g, pts[1], pts[2], pts[3])
            e:SetPoint(pts[4], g, pts[4], pts[5], pts[6])
            if i <= 2 then e:SetHeight(E) else e:SetWidth(E) end
            g.edges[i] = e
        end
        g.text = g:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        g.text:SetPoint("BOTTOM", g, "TOP", 0, 2)
        local ag = g:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local a = ag:CreateAnimation("Alpha")
        a:SetFromAlpha(1); a:SetToAlpha(0.3); a:SetDuration(0.5)
        g.anim = ag
        glows[key] = g
    end
    g:SetParent(parent)
    g:ClearAllPoints()
    g:SetAllPoints(parent)
    g:SetFrameLevel(parent:GetFrameLevel() + 10)
    -- Kareye yakin dugum / mikro buton: halka dokusu; genis buton: kenarlik
    local w, h = parent:GetWidth() or 36, parent:GetHeight() or 36
    local wide = w > h * 1.5
    g.tex:SetShown(not wide)
    g.tex:SetSize(w * 1.9, w * 1.9)
    for _, e in ipairs(g.edges) do e:SetShown(wide) end
    g.text:SetText(label or "")
    g:Show()
    if not g.anim:IsPlaying() then g.anim:Play() end
end

local function Unglow(key)
    local g = glows[key]
    if g then g.anim:Stop(); g:Hide() end
end

local lastAnnounced

-- Modul kapatilinca (Init.lua stop): butun parlamalar (mikro buton, dugum, Apply) kalkar
function ns.TalentGuide_Clear()
    for key in pairs(glows) do Unglow(key) end
    lastAnnounced = nil
end

local MICRO = { "TalentMicroButton", "PlayerSpellsMicroButton" }

-- Talent sekmesi acik mi? PlayerSpellsFrame ayni pencerede buyu kitabini da gosterir;
-- ayrica diger spec grubu goruntuleniyorsa dugum parlamasi yanlis yere duser.
local function TalentsFrame()
    local f = PlayerSpellsFrame
    local tf = f and f:IsShown() and f.TalentsFrame
    if not (tf and tf:IsShown()) then return nil end
    if f.IsFrameTabActive and PlayerSpellsUtil and PlayerSpellsUtil.FrameTabs then
        local ok, active = pcall(f.IsFrameTabActive, f, PlayerSpellsUtil.FrameTabs.ClassTalents)
        if ok and active == false then return nil end
    end
    return tf
end

local function ViewingActiveSpec(tf)
    if not tf.IsActiveTabSelected then return true end
    local ok, active = pcall(tf.IsActiveTabSelected, tf)
    return not ok or active ~= false
end

local function NodeButton(tf, nodeID)
    if not (tf and nodeID and tf.GetTalentButtonByNodeID) then return nil end
    local ok, btn = pcall(tf.GetTalentButtonByNodeID, tf, nodeID)
    return ok and btn or nil
end

---------------------------------------------------------------------------
-- Guncelleme
---------------------------------------------------------------------------
function ns.TalentGuide_Update()
    local db = ns.db
    if not db or not ns.cdb then return end
    local name, rank, target = ns.NextTalent()
    local unspent = ns.TalentUnspent()
    local active = db.talentGuide and name and unspent > 0

    -- Sohbet: her yeni adimda bir kez
    if active and db.talentChat then
        local key = name .. rank
        if key ~= lastAnnounced then
            lastAnnounced = key
            ns.Print((L("Siradaki talent: |cff40ff40%s|r (%d/%d)  -  %d puan bos"))
                :format(ns.TalentDisplayName(name), rank, target, unspent))
        end
    elseif not active then
        lastAnnounced = nil
    end

    -- Parlamalar
    local tf = TalentsFrame()
    local glowOn = active and db.talentGlow
    for _, n in ipairs(MICRO) do
        local b = _G[n]
        if glowOn and b and b:IsShown() and not tf then Glow("micro" .. n, b) else Unglow("micro" .. n) end
    end
    local btn = glowOn and tf and ViewingActiveSpec(tf) and NodeButton(tf, ns.TalentNodeID(name))
    if btn then Glow("node", btn, "|cff40ff40" .. L("SIRADAKI") .. "|r") else Unglow("node") end
    local apply = tf and tf.ApplyButton
    local staged = C_Traits and C_Traits.ConfigHasStagedChanges
        and ns.Call(C_Traits.ConfigHasStagedChanges, ns.TalentConfigID())
    if db.talentGlow and apply and staged and apply:IsShown() then
        Glow("apply", apply, "|cff40ff40" .. L("Onayla") .. "|r")
    else
        Unglow("apply")
    end
end

-- /rof talent: sonraki 5 adim
function ns.TalentGuide_Print()
    local build = ns.ActiveBuild()
    if not build then ns.Print(L("Bu sinif icin build yok.")); return end
    ns.Print((L("Build: %s  |  bos puan: %d")):format(build.name, ns.TalentUnspent()))
    for i = 0, 4 do
        local name, rank, target = ns.NextTalent(build, i)
        if not name then
            if i == 0 then ns.Print(L("  Build tamamlandi.")) end
            break
        end
        ns.Print(("  %d. %s (%d/%d)"):format(i + 1, ns.TalentDisplayName(name), rank, target))
    end
    local _, _, _, missing = ns.NextTalent(build)
    if missing and #missing > 0 then
        ns.Print(L("|cffff8040Agacta bulunamayan talent'lar (ad farkli olabilir):|r ") .. table.concat(missing, ", "))
    end
end

---------------------------------------------------------------------------
-- Talent ekrani (Blizzard_PlayerSpells) acilinca/kapaninca
---------------------------------------------------------------------------
local hooked = false
local function Hook()
    if hooked or not PlayerSpellsFrame then return end
    hooked = true
    local function Later() C_Timer.After(0.1, ns.TalentGuide_Update) end
    PlayerSpellsFrame:HookScript("OnShow", Later)
    PlayerSpellsFrame:HookScript("OnHide", Later)
    local tf = PlayerSpellsFrame.TalentsFrame
    if tf and tf.HookScript then
        tf:HookScript("OnShow", Later)
        tf:HookScript("OnHide", Later)
    end
    -- Sekme degisimi, butonlarin yeniden cizilmesi, spec grubu degisimi
    if EventRegistry and EventRegistry.RegisterCallback then
        for _, name in ipairs({ "PlayerSpellsFrame.TalentTab.Show", "TalentFrameBase.ButtonsUpdated",
                                "TalentFrameBase.ConfigUpdated" }) do
            pcall(EventRegistry.RegisterCallback, EventRegistry, name, Later, ns)
        end
    end
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "ADDON_LOADED")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == "Blizzard_PlayerSpells" then Hook() end
    if event == "PLAYER_LOGIN" then
        Hook()
        C_Timer.After(3, ns.TalentGuide_Update)
    end
end)
