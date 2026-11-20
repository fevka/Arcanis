local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Ekran kodu Display.lua'da; burada komutlar ve /rof debug.

---------------------------------------------------------------------------
-- Komutlar
---------------------------------------------------------------------------
local function OnOff(v) return v and "|cff00ff00acik|r" or "|cffff4040kapali|r" end

local function Debug()
    ns.Print("Interface: " .. tostring(select(4, GetBuildInfo())))
    ns.Print(L("issecretvalue var mi: ") .. OnOff(issecretvalue ~= nil))
    ns.Print(L("C_AssistedCombat var mi: ") .. OnOff(ns.BlizzardAvailable()) .. L("  (mod: ") .. ns.db.mode .. ")")
    local ok, r = pcall(UnitPower, "player", Enum.PowerType.Rage)
    ns.Print(L("Rage gizli mi: ") .. tostring(ok and ns.issecret(r)) .. L("  (savasta tekrar dene)"))
    ns.Print(L("Aktif durus ID: ") .. tostring(ns.ActiveForm()))
    ns.Print((L("Talent: %d dugum okundu (C_Traits: %s) | puanlar %d/%d/%d | bos %d"))
        :format(ns.TalentCount(), OnOff(C_Traits ~= nil and C_Traits.GetConfigInfo ~= nil),
                ns.TalentPoints(1), ns.TalentPoints(2), ns.TalentPoints(3), ns.TalentUnspent()))
    local kind, interruptible, elapsed = ns.TargetCast()
    ns.Print((L("Hedef cast: %s | kesilebilir: %s | %.1f sn"))
        :format(tostring(kind), tostring(interruptible), elapsed))
    ns.Highlight_Scan()
    local c = ns.Highlight_Counts()
    ns.Print((L("Bar butonlari: Blizzard %d, ElvUI %d, Bartender4 %d"))
        :format(c.Blizzard, c.ElvUI, c.Bartender4))

    local n = 0
    for key, s in pairs(ns.spells) do
        n = n + 1
        ns.Print((L("  %s -> %s (id %d)")):format(key, s.name, s.id))
    end
    ns.Print(L("Bilinen buyu sayisi: ") .. n)
    local plates = GetCVar and GetCVar("nameplateShowEnemies")
    if plates == "0" then
        ns.Print(L("|cffff4040Dusman nameplate'leri kapali: AoE icin V tusuyla ac.|r"))
    end
    local cls = ns.classes[ns.playerClass]
    if cls then
        if cls.Debug then cls.Debug() end
        for key, def in pairs(cls.spells) do
            if not ns.spells[key] then
                ns.Print((L("  |cff888888bulunamadi: %s (%s)|r")):format(key, def.name))
            end
        end
    end
end

SLASH_ROTATIONFORGE1 = "/rotationforge"
SLASH_ROTATIONFORGE2 = "/rof"   -- /rf ResourceForge'da
SlashCmdList.ROTATIONFORGE = function(msg)
    local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    local db = ns.db

    if cmd == "lock" then
        db.locked = true; ns.UI_Apply(); ns.Print(L("Kilitlendi."))
    elseif cmd == "unlock" then
        db.locked = false; ns.UI_Apply(); ns.Print(L("Kilit acildi, ikonu surukleyebilirsin."))
    elseif cmd == "scale" then
        local s = tonumber(arg)
        if s and s >= 0.5 and s <= 3 then db.scale = s; ns.UI_Apply(); ns.Print(L("Boyut: ") .. s)
        else ns.Print(L("Kullanim: /rof scale 0.5-3")) end
    elseif cmd == "glow" then
        db.glow = not db.glow; ns.Print(L("Bar vurgusu: ") .. OnOff(db.glow))
    elseif cmd == "combat" then
        local order = { target = "combat", combat = "always", always = "target" }
        db.showWhen = order[db.showWhen or "target"] or "target"
        local names = { target = "Saldirilabilir hedef varken", combat = "Yalniz savasta", always = "Her zaman" }
        ns.Print(L("Ne zaman gorunsun: ") .. L(names[db.showWhen]))
        if ns.UI_Apply then ns.UI_Apply() end
    elseif cmd == "cds" then
        db.cds = not db.cds; ns.Print(L("Death Wish / Recklessness onerisi: ") .. OnOff(db.cds))
    elseif cmd == "hs" and ns.playerClass == "WARRIOR" then   -- Heroic Strike sadece Warrior'da
        local n = tonumber(arg)
        if arg == "auto" then n = 0 end
        if n and n >= 0 and n <= 100 then
            ns.cdb.hsRage = n
            ns.Options_Refresh()
            ns.Print(L("Heroic Strike rage esigi: ") .. (n == 0 and L("otomatik (spec'e gore)") or n))
        else
            local cur = ns.cdb.hsRage or 0
            ns.Print(L("Kullanim: /rof hs <15-100> | auto  (su an: ") .. (cur > 0 and cur or L("otomatik (spec'e gore)")) .. ")")
        end
    elseif cmd == "" or cmd == "config" or cmd == "ayar" then
        ns.Options_Open()
    elseif cmd == "mode" then
        if arg == "auto" or arg == "blizzard" or arg == "custom" then
            db.mode = arg; ns.Print(L("Mod: ") .. arg)
        else
            ns.Print(L("Kullanim: /rof mode custom | auto | blizzard  (su an: ") .. db.mode .. ")")
        end
    elseif cmd == "debug" then
        Debug()
    elseif cmd == "track" then
        -- Orijinal metin (buyuk/kucuk harf korunur)
        local rest = (msg or ""):match("^%S+%s+(.+)$")
        if rest and rest:lower() == "list" then ns.TrackPrint() else ns.TrackAdd(rest) end
    elseif cmd == "untrack" then
        ns.TrackRemove((msg or ""):match("^%S+%s+(.+)$"))
    elseif cmd == "reset" then
        ns.UI_ResetPositions()
    elseif cmd == "talent" then
        ns.TalentGuide_Print()
    elseif cmd == "import" then
        -- Orijinal metin (kucuk harfe cevrilmemis)
        ns.BuildImport((msg or ""):match("^%S+%s+(.+)$"))
    elseif cmd == "build" or cmd == "builds" then
        local sub, n = arg:match("^(%S*)%s*(.-)$")
        if sub == "delete" then ns.BuildDelete(n) else ns.BuildList() end
    else
        ns.Print(L("/rof (ayarlar) | unlock / lock | reset (konumlar) | minimap | track <yetenek> | track list | untrack <yetenek> | talent | import <kod> | builds | lock | unlock | scale <n> | glow | combat | cds | hs <n|auto> | mode <custom|auto|blizzard> | debug"))
    end
    if ns.Options_Refresh then ns.Options_Refresh() end
end
