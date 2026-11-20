local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Build kaynaklari ve oyun ici import.
--   ns.builds[CLASS]      : addon ile gelen, sirali leveling build'leri (Builds.lua)
--   ns.autoBuilds[CLASS]  : bilgisayardaki guncelleyici scriptin yazdigi (BuildsAuto.lua)
--   db.customBuilds[CLASS]: oyunda /rof import ile eklenenler
-- Bir build ya sirali `steps` ({ "Ad", hedefRank }) ya da sirasiz `ranks` ({ Ad = rank })
-- tasir; `ranks` gelen build'ler burada siraya cevrilir.
--
-- /rof import <kod>   desteklenen kodlar:
--   * Talent hesaplayici linki / kodu: "talent-calc/warrior/0503-3505-05" (her talent icin bir
--     rakam, bolumler "-" ile; talent sirasi oyundaki agacin satir/sutun sirasi)
--   * Blizzard loadout kodu (talent ekranindaki "Disa aktar")
--   * Duz metin: "Improved Rend:3, Deep Wounds:3, ..." (verilis sirasiyla)
--   * current: su anki talent'larini build olarak kaydet

ns.autoBuilds = ns.autoBuilds or {}

---------------------------------------------------------------------------
-- Sirasiz rank listesinden sira: once en cok puanli bolum, her bolumde
-- yukaridan asagi satir satir (agacin 5 puanda bir kademe kurali boylece korunur).
---------------------------------------------------------------------------
function ns.RanksToSteps(ranks)
    local layout = ns.TalentLayout()
    local perSection = {}
    for i, list in ipairs(layout) do
        local sum = 0
        for _, rec in ipairs(list) do sum = sum + (ranks[rec.name] or 0) end
        perSection[i] = { index = i, points = sum }
    end
    table.sort(perSection, function(a, b) return a.points > b.points end)

    local steps, used = {}, {}
    for _, sec in ipairs(perSection) do
        for _, rec in ipairs(layout[sec.index]) do
            local r = ranks[rec.name]
            if r and r > 0 and not used[rec.name] then
                used[rec.name] = true
                steps[#steps + 1] = { rec.name, math.min(r, rec.max) }
            end
        end
    end
    -- Agacta bulunamayanlar en sona (ad farkli olabilir; rehber uyarir)
    for name, r in pairs(ranks) do
        if not used[name] and r > 0 then steps[#steps + 1] = { name, r } end
    end
    return steps, perSection[1] and perSection[1].points > 0 and perSection[1].index or 0
end

-- Build'i rehberin kullanacagi hale getir (ranks -> steps)
local function Normalize(b)
    if b.steps or not b.ranks then return b end
    local steps, spec = ns.RanksToSteps(b.ranks)
    return { key = b.key, name = b.name, spec = b.spec or spec, steps = steps,
             source = b.source, updated = b.updated }
end

-- Rehberin ve ayar panelinin gordugu tum build'ler
function ns.BuildsForClass()
    local cls, out = ns.playerClass, {}
    for _, b in ipairs(ns.builds[cls] or {}) do out[#out + 1] = b end
    for _, b in ipairs(ns.autoBuilds[cls] or {}) do out[#out + 1] = Normalize(b) end
    local custom = ns.db and ns.db.customBuilds and ns.db.customBuilds[cls]
    for _, b in ipairs(custom or {}) do out[#out + 1] = Normalize(b) end
    return out
end

---------------------------------------------------------------------------
-- Kod cozuculer. Her biri ranks ({ Ad = rank }) ya da nil, hata mesaji doner.
---------------------------------------------------------------------------

-- Talent hesaplayici: "0503-3505-05" (link de olabilir)
local function DecodeCalc(text)
    local code = text:match("talent%-calc/[%a%-]+/([%d%-]+)") or text:match("^([%d%-]+)$")
    if not code then return nil end
    local layout = ns.TalentLayout()
    if #layout[1] == 0 then return nil, L("Talent agaci okunamadi (/rof debug).") end
    local ranks, sec = {}, 0
    for part in (code .. "-"):gmatch("([%d]*)%-") do
        sec = sec + 1
        local list = layout[sec]
        if not list then break end
        local i = 0
        for digit in part:gmatch("%d") do
            i = i + 1
            local rec = list[i]
            local r = tonumber(digit)
            -- Agacta olmayan konum ya da talent'in ust sinirini asan rakam = satir
            -- ayrimi kaymis: yanlis build kaydetmektense reddet
            if r > 0 and (not rec or r > rec.max) then
                return nil, L("Kod agacla uyusmuyor: ") .. (rec and rec.name or (sec .. "/" .. i))
            end
            if rec and r > 0 then ranks[rec.name] = r end
        end
    end
    return ranks
end

-- Blizzard loadout kodu (retail'deki ClassTalentImportExportMixin ile ayni format)
local function DecodeLoadout(text)
    if not (ExportUtil and ExportUtil.MakeImportDataStream and ClassTalentImportExportMixin) then return nil end
    if not text:match("^[%w%+/=]+$") or #text < 20 then return nil end
    local configID = ns.TalentConfigID()
    local cfg = configID and ns.Call(C_Traits.GetConfigInfo, configID)
    local treeID = cfg and cfg.treeIDs and cfg.treeIDs[1]
    if not treeID then return nil, L("Talent agaci okunamadi.") end

    local ok, content = pcall(function()
        local stream = ExportUtil.MakeImportDataStream(text)
        local m = CreateFromMixins(ClassTalentImportExportMixin)
        local valid = m:ReadLoadoutHeader(stream)
        if not valid then error("header") end
        return m:ReadLoadoutContent(stream, treeID)
    end)
    if not ok or type(content) ~= "table" then return nil, L("Loadout kodu cozulemedi.") end

    -- nodeID (+ secim) -> talent adi
    local byNode = {}
    for _, list in ipairs(ns.TalentLayout()) do
        for _, rec in ipairs(list) do
            byNode[rec.nodeID] = byNode[rec.nodeID] or {}
            byNode[rec.nodeID][rec.entryID or 0] = rec.name
        end
    end

    -- Kod, dugumleri GetTreeNodes sirasiyla tasir
    local nodeIDs = ns.Call(C_Traits.GetTreeNodes, treeID) or {}
    local ranks = {}
    for i, nodeID in ipairs(nodeIDs) do
        local c = content[i]
        local names = byNode[nodeID]
        if c and c.isNodeSelected and names then
            local node = ns.Call(C_Traits.GetNodeInfo, configID, nodeID)
            local entries = node and node.entryIDs or {}
            local entryID = c.isChoiceNode and entries[c.choiceNodeSelection] or entries[1]
            local name = names[entryID or 0] or select(2, next(names))
            local rank = c.isPartiallyRanked and c.partialRanksPurchased or (node and node.maxRanks) or 1
            if name then ranks[name] = rank end
        end
    end
    return ranks
end

-- Hesaplayici linki ya da loadout kodu -> ranks ({ Ad = rank }) ya da nil, hata (yetenek planlayicisi kullanir)
function ns.DecodeTalentCode(text)
    local ranks, err = DecodeCalc(text)
    if not ranks and not err then ranks, err = DecodeLoadout(text) end
    return ranks, err
end

-- Duz metin: "Ad:rank, Ad:rank" (sirali)
local function DecodeText(text)
    local steps = {}
    for name, r in text:gmatch("([^,;:]+):%s*(%d)") do
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        steps[#steps + 1] = { name, tonumber(r) }
    end
    return #steps > 0 and steps or nil
end

-- Su anki talent'lar
local function CurrentRanks()
    local ranks, any = {}, false
    for _, list in ipairs(ns.TalentLayout()) do
        for _, rec in ipairs(list) do
            if rec.rank > 0 then ranks[rec.name] = rec.rank; any = true end
        end
    end
    return any and ranks or nil
end

---------------------------------------------------------------------------
-- Kaydetme ve komutlar
---------------------------------------------------------------------------
local function Points(b)
    local n = 0
    for _, s in ipairs(b.steps or {}) do n = n + s[2] end
    for _, r in pairs(b.ranks or {}) do n = n + r end
    return n
end

local function Save(build)
    ns.db.customBuilds = ns.db.customBuilds or {}
    local list = ns.db.customBuilds[ns.playerClass] or {}
    ns.db.customBuilds[ns.playerClass] = list
    build.key = "custom" .. (#list + 1) .. "_" .. time()
    list[#list + 1] = build
    ns.cdb.build = build.key
    ns.Print((L("Build kaydedildi ve secildi: |cff40ff40%s|r (%d puan)")):format(build.name, Points(build)))
    if ns.Options_Refresh then ns.Options_Refresh() end
    if ns.TalentGuide_Update then ns.TalentGuide_Update() end
end

function ns.BuildImport(text)
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        ns.Print(L("Kullanim: /rof import <hesaplayici linki | loadout kodu | Ad:rank, ...> | current"))
        return
    end
    local n = #((ns.db.customBuilds or {})[ns.playerClass] or {}) + 1
    if text:lower() == "current" then
        local ranks = CurrentRanks()
        if not ranks then ns.Print(L("Henuz talent puanin yok.")); return end
        return Save({ name = "Benim build'im " .. n, ranks = ranks, source = "current" })
    end

    -- Link / kod oncelikli: bir URL "host:port" gibi ":rakam" icerebilir, metin sanilmasin
    local looksLikeCode = text:find("talent%-calc") or text:find("^https?://") or text:match("^[%w%+/=]+$")
    local steps = not looksLikeCode and DecodeText(text)
    if steps then return Save({ name = "Import " .. n, steps = steps, source = "text" }) end

    local ranks, err = DecodeCalc(text)
    if not ranks and not err then ranks, err = DecodeLoadout(text) end
    if not ranks then
        ns.Print(L("|cffff4040Import basarisiz:|r ") .. (err or L("Kod taninmadi.")))
        return
    end
    Save({ name = "Import " .. n, ranks = ranks, source = text:sub(1, 120) })
end

function ns.BuildList()
    local list = ns.BuildsForClass()
    if #list == 0 then ns.Print(L("Bu sinif icin build yok.")); return end
    local active = ns.ActiveBuild()
    for i, b in ipairs(list) do
        local isActive = active and b.key == active.key
        ns.Print((L("%s%d. %s (%d puan)%s")):format(isActive and "|cff40ff40>|r " or "  ", i, b.name,
            Points(b), b.updated and ("  guncelleme: " .. b.updated) or ""))
    end
    ns.Print(L("Silmek icin (sadece import ettiklerin): /rof build delete <no>"))
end

function ns.BuildDelete(index)
    local list = ns.BuildsForClass()
    local b = list[tonumber(index) or 0]
    local custom = ns.db.customBuilds and ns.db.customBuilds[ns.playerClass]
    for i, c in ipairs(custom or {}) do
        if b and c.key == b.key then
            table.remove(custom, i)
            if ns.cdb.build == b.key then ns.cdb.build = "auto" end
            ns.Print(L("Silindi: ") .. b.name)
            if ns.Options_Refresh then ns.Options_Refresh() end
            return
        end
    end
    ns.Print(L("Sadece /rof import ile eklenen build'ler silinebilir."))
end
