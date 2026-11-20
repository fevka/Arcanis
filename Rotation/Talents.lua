local _, A = ...
local ns = A.RF
if not ns then return end

-- Talent okuma. Forever, retail'in trait sistemini (C_Traits) kullanir; Classic'in
-- GetTalentInfo / GetNumTalentTabs fonksiyonlari yoktur. Forever'da tek bir trait
-- agaci vardir, dugumleri soldan saga uc bolume ayrilir (Classic'teki uc talent
-- agaci: Arms/Fury/Prot, BM/MM/SV, Arcane/Fire/Frost). Bolumler dugumlerin x
-- konumundaki en genis iki bosluktan bulunur.
--
-- Talent'lar istemcinin dilindeki adla eslesir (build verisi Ingilizce adlar kullanir).
-- C_Traits yoksa (eski istemci) Classic API'sine dusulur.

local issecret = ns.issecret

local byName   = {}   -- kucuk harf ad -> { name, rank, max, nodeID, entryID, section }
local nodes    = {}   -- tum kayitlar
local spent    = { 0, 0, 0 }
local treeIDs  = {}
local configID
local SaveLayout   -- asagida tanimli (TalentsRebuild cagirir)

local function Num(t, k)
    if type(t) ~= "table" then return nil end
    local v = t[k]
    if issecret(v) or type(v) ~= "number" then return nil end
    return v
end

function ns.TalentConfigID()
    local id = C_ClassTalents and ns.Call(C_ClassTalents.GetActiveConfigID)
    if not id and C_SpecializationInfo and C_SpecializationInfo.GetCombatConfigIDForSpecGroup then
        local group = ns.Call(C_SpecializationInfo.GetActiveSpecGroup) or 1
        id = ns.Call(C_SpecializationInfo.GetCombatConfigIDForSpecGroup, group)
    end
    return id
end

local function EntryName(cfg, entryID)
    local entry = ns.Call(C_Traits.GetEntryInfo, cfg, entryID)
    local defID = Num(entry, "definitionID")
    local def = defID and ns.Call(C_Traits.GetDefinitionInfo, defID)
    if not def then return nil end
    local name = def.overrideName
    if issecret(name) or name == "" then name = nil end
    local spellID = Num(def, "spellID") or Num(def, "overriddenSpellID")
    if not name and spellID then name = ns.Call(C_Spell.GetSpellName, spellID) end
    return name, spellID
end

-- Dugum rank'i. live: talent ekraninda onaylanmamis secimler dahil.
local function NodeRank(node, live)
    if live then
        return Num(node, "currentRank") or Num(node, "ranksPurchased") or Num(node, "activeRank") or 0
    end
    return Num(node, "activeRank") or Num(node, "currentRank") or Num(node, "ranksPurchased") or 0
end

-- x konumlarindaki en genis iki bosluktan uc bolum
local function Sections(items)
    local xs = {}
    for _, it in ipairs(items) do xs[#xs + 1] = it.x end
    table.sort(xs)
    local gaps = {}
    for i = 2, #xs do gaps[#gaps + 1] = { d = xs[i] - xs[i - 1], x = xs[i] } end
    table.sort(gaps, function(a, b) return a.d > b.d end)
    local cuts = {}
    for i = 1, math.min(2, #gaps) do
        if gaps[i].d > 0 then cuts[#cuts + 1] = gaps[i].x end
    end
    table.sort(cuts)
    for _, it in ipairs(items) do
        local sec = 1
        for _, c in ipairs(cuts) do
            if it.x >= c then sec = sec + 1 end
        end
        it.section = sec
    end
end

local function Index(rec)
    local key = rec.name:lower()
    local prev = byName[key]
    if not prev or rec.rank > prev.rank then byName[key] = rec end
    nodes[#nodes + 1] = rec
end

local function RebuildTraits()
    configID = ns.TalentConfigID()
    if not configID then return false end
    local cfg = ns.Call(C_Traits.GetConfigInfo, configID)
    if not cfg or type(cfg.treeIDs) ~= "table" then return false end

    local items = {}
    for _, treeID in ipairs(cfg.treeIDs) do
        if not issecret(treeID) then
            treeIDs[#treeIDs + 1] = treeID
            for _, nodeID in ipairs(ns.Call(C_Traits.GetTreeNodes, treeID) or {}) do
                local node = not issecret(nodeID) and ns.Call(C_Traits.GetNodeInfo, configID, nodeID)
                local x, y = Num(node, "posX"), Num(node, "posY")
                -- Kullanilmayan dugumler agacin cok disina park edilir
                if node and Num(node, "ID") and node.isVisible ~= false and x and y
                   and x < 20000 and y < 10000 then
                    items[#items + 1] = { nodeID = nodeID, node = node, x = x, y = y }
                end
            end
        end
    end
    if #items == 0 then return false end
    Sections(items)

    for _, it in ipairs(items) do
        local node = it.node
        local rank, max = NodeRank(node), Num(node, "maxRanks") or 1
        local active = type(node.activeEntry) == "table" and Num(node.activeEntry, "entryID")
        local entries = type(node.entryIDs) == "table" and node.entryIDs or {}
        local choice = #entries > 1
        -- cikan kenarlar (hedef dugumler): yetenek planlayicisinin onkosulu (Helpers/TalentPlanner.lua)
        local edges = {}
        for _, e in ipairs(type(node.visibleEdges) == "table" and node.visibleEdges or {}) do
            local target = Num(e, "targetNode")
            if target then edges[#edges + 1] = target end
        end
        for _, entryID in ipairs(entries) do
            if not issecret(entryID) then
                local name, spellID = EntryName(configID, entryID)
                if name then
                    local chosen = not choice or active == entryID
                    Index({ name = name, spellID = spellID, rank = chosen and rank or 0, max = max,
                            nodeID = it.nodeID, entryID = entryID, section = it.section, x = it.x, y = it.y,
                            edges = edges })
                end
            end
        end
        spent[it.section] = (spent[it.section] or 0) + rank
    end
    return true
end

-- Eski istemciler (Classic API)
local function RebuildClassic()
    if not (GetNumTalentTabs and GetTalentInfo) then return end
    for tab = 1, ns.Call(GetNumTalentTabs) or 0 do
        for i = 1, ns.Call(GetNumTalents, tab) or 0 do
            local ok, name, _, tier, column, rank, max = pcall(GetTalentInfo, tab, i)
            if ok and type(name) == "string" and not issecret(rank) then
                Index({ name = name, rank = rank or 0, max = max or 1, section = tab, tab = tab, index = i, x = column, y = tier })
                spent[tab] = (spent[tab] or 0) + (rank or 0)
            end
        end
    end
end

-- Ingilizce adlar (build verisi) her istemci dilinde bulunsun: TalentIDs.lua'daki node ID
-- (yoksa spell ID) ile oyundaki kayda bagla. Node'un max rank'i tutmazsa (agac degismis,
-- yanlis eslesme) baglanmaz.
local function IndexEnglish()
    local map = ns.TALENT_IDS and ns.TALENT_IDS[ns.playerClass]
    if not map then return end
    local byNode, bySpell = {}, {}
    for _, rec in ipairs(nodes) do
        -- secim dugumunde secili giris (rank > 0) oncelikli
        if rec.nodeID and (not byNode[rec.nodeID] or rec.rank > byNode[rec.nodeID].rank) then
            byNode[rec.nodeID] = rec
        end
        if rec.spellID then bySpell[rec.spellID] = rec end
    end
    for english, v in pairs(map) do
        local key = english:lower()
        if not byName[key] then
            local rec = byNode[v.node] or bySpell[v.spell]
            if rec and (not v.max or rec.max == v.max) then byName[key] = rec end
        end
    end
end

function ns.TalentsRebuild()
    wipe(byName); wipe(nodes); wipe(treeIDs)
    spent[1], spent[2], spent[3] = 0, 0, 0
    if not (C_Traits and C_Traits.GetConfigInfo and RebuildTraits()) then
        RebuildClassic()
    end
    IndexEnglish()
    SaveLayout()
end

-- Istemcinin dilindeki ad (build'de Ingilizce yazili olsa bile)
function ns.TalentDisplayName(name)
    local rec = ns.Talent(name)
    return rec and rec.name or name
end

---------------------------------------------------------------------------
-- Okumalar
---------------------------------------------------------------------------
function ns.Talent(name)
    return name and byName[name:lower()]
end

-- Onaylanmis rank (bulunamazsa 0)
function ns.TalentRank(name)
    local rec = ns.Talent(name)
    return rec and rec.rank or 0
end

-- Canli rank: talent ekraninda tiklanip henuz onaylanmamis puanlar dahil
function ns.TalentLiveRank(name)
    local rec = ns.Talent(name)
    if not rec then return 0 end
    if rec.nodeID and configID and C_Traits then
        local node = ns.Call(C_Traits.GetNodeInfo, configID, rec.nodeID)
        if node then
            local active = type(node.activeEntry) == "table" and Num(node.activeEntry, "entryID")
            if type(node.entryIDs) == "table" and #node.entryIDs > 1 and active and active ~= rec.entryID then
                return 0
            end
            return NodeRank(node, true)
        end
    end
    return rec.rank
end

function ns.TalentPoints(section) return spent[section] or 0 end

-- En cok puanli bolum (puan yoksa 0)
function ns.MainTalentTab()
    local best, pts = 0, 0
    for i = 1, 3 do
        if (spent[i] or 0) > pts then best, pts = i, spent[i] end
    end
    return best
end

-- Harcanmamis puan (onaylanmamis secimler dusulmus)
function ns.TalentUnspent()
    if configID and C_Traits and C_Traits.GetTreeCurrencyInfo then
        local best
        for _, treeID in ipairs(treeIDs) do
            local cur = ns.Call(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
            local q = type(cur) == "table" and Num(cur[1], "quantity")
            if q then best = math.max(best or 0, q) end
        end
        if best then return best end
    end
    if UnitCharacterPoints then
        local n = ns.Call(UnitCharacterPoints, "player")
        if n then return n end
    end
    -- Classic kurali: 10'dan itibaren her level 1 puan
    local level = ns.Call(UnitLevel, "player") or 0
    return math.max(0, level - 9 - spent[1] - spent[2] - spent[3])
end

function ns.TalentNodeID(name)
    local rec = ns.Talent(name)
    return rec and rec.nodeID
end

function ns.TalentCount() return #nodes end

-- Satir numaralari. Ayni satirdaki dugumlerin y'si birkac birim farkli olabilir
-- (Survival'da 5730 / 5740), bu yuzden satir araligi y bosluklarinin medyanindan
-- bulunur ve medyanin %30'undan kucuk bosluklar ayni satir sayilir.
local function AssignRows(list)
    local ys = {}
    for _, rec in ipairs(list) do ys[#ys + 1] = rec.y or 0 end
    table.sort(ys)
    local gaps = {}
    for i = 2, #ys do
        if ys[i] > ys[i - 1] then gaps[#gaps + 1] = ys[i] - ys[i - 1] end
    end
    table.sort(gaps)
    local median = gaps[math.ceil(#gaps / 2)]
    local step
    for _, g in ipairs(gaps) do
        if g >= median * 0.3 then step = g; break end
    end
    for _, rec in ipairs(list) do
        rec.row = step and (1 + math.floor(((rec.y or 0) - (ys[1] or 0)) / step + 0.5)) or 1
    end
end

-- Bolum basina talent listesi, satir sonra sutun (x) sirasinda. Talent hesaplayici
-- kodlari (her talent icin bir karakter) bu siraya gore cozulur.
function ns.TalentLayout()
    local out = { {}, {}, {} }
    for _, rec in ipairs(nodes) do
        local list = out[rec.section]
        if list then list[#list + 1] = rec end
    end
    for _, list in ipairs(out) do
        AssignRows(list)
        table.sort(list, function(a, b)
            if a.row ~= b.row then return a.row < b.row end
            if (a.x or 0) ~= (b.x or 0) then return (a.x or 0) < (b.x or 0) end
            return a.name < b.name
        end)
    end
    return out
end

-- Disaridaki guncelleyici script icin agac duzeni SavedVariables'a duz metin olarak
-- yazilir: "Ad~maxRank~satir~nodeID~spellID", bolumler "|" ile ayrilir. Script bununla
-- hesaplayici kodlarini cozer ve kademe kuralini (her satir icin 5 puan) dogrular.
function SaveLayout()
    if ns.stopped or not (ArcanisRotationDB and ns.playerClass) or #nodes == 0 then return end
    local parts = {}
    for i, list in ipairs(ns.TalentLayout()) do
        local items = {}
        for _, rec in ipairs(list) do
            local name = rec.name:gsub("[~,|]", "")
            items[#items + 1] = table.concat({ name, rec.max, rec.row, rec.nodeID or 0, rec.spellID or 0 }, "~")
        end
        parts[i] = table.concat(items, ",")
    end
    ArcanisRotationDB.layout = ArcanisRotationDB.layout or {}
    ArcanisRotationDB.layout[ns.playerClass] = table.concat(parts, "|")
end

---------------------------------------------------------------------------
-- Olaylar: talent degisince yeniden oku, sinif modulune ve rehbere haber ver
---------------------------------------------------------------------------
local EVENTS = {
    "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED",
    "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",   -- SPELLS_CHANGED: Core Refresh zaten yeniden okur
}

local pending = false
local function Rebuild()
    pending = false
    ns.TalentsRebuild()   -- modul kapaliyken de: Build / Provider yetenekleri buradan okur
    if ns.stopped then return end
    local cls = ns.classes[ns.playerClass]
    if cls and cls.OnRefresh then cls.OnRefresh() end
    if ns.TalentGuide_Update then ns.TalentGuide_Update() end
end

local ev = CreateFrame("Frame")
for _, e in ipairs(EVENTS) do pcall(ev.RegisterEvent, ev, e) end
-- Olaylar art arda gelir: bir sonraki karede tek sefer oku
ev:SetScript("OnEvent", function()
    if pending or not ns.playerClass then return end
    pending = true
    C_Timer.After(0, Rebuild)
end)

-- Talent ekraninda tiklandikca (onaylanmamis secimler) rehber guncellensin
pcall(ev.RegisterEvent, ev, "TRAIT_NODE_CHANGED")
pcall(ev.RegisterEvent, ev, "TRAIT_TREE_CURRENCY_INFO_UPDATED")
