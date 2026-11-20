-- Arcanis: oyun durumu saglayicisi. Oyun API'sine dokunan TEK katman burasidir;
-- motor yalnizca ns.Provider uzerinden okur (testlerde sahte saglayici konur).
-- Her cagri varlik kontrolu + yedek yol kullanir; hicbiri yoksa guvenli varsayilan doner.
-- /wf probe [gorevID] ile hangi API yolunun calistigi oyunda gorulebilir.
local _, ns = ...

local P = {}
ns.Provider = P

local function try(fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
  return nil
end

function P.PlayerLevel()
  return UnitLevel("player") or 1
end

function P.PlayerInfo()
  local _, race = UnitRace("player")
  local _, class = UnitClass("player")
  return { faction = UnitFactionGroup("player"), race = race, class = class, level = P.PlayerLevel() }
end

-- Gorev gunlugundeki sira (yoksa nil). Once C_QuestLog, yoksa gunlugu tarar.
function P.QuestLogIndex(questId)
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    local index = try(C_QuestLog.GetLogIndexForQuestID, questId)
    if index and index > 0 then return index end
    if index ~= nil then return nil end
  end
  -- Classic: kapali bolge basligi altindaki quest GetQuestLogTitle dongusunde gorunmez; bu API basligi dinlemez
  if GetQuestLogIndexByID then
    local index = try(GetQuestLogIndexByID, questId)
    if index and index > 0 then return index end
  end
  if GetNumQuestLogEntries and GetQuestLogTitle then
    local entries = GetNumQuestLogEntries()
    for i = 1, entries do
      local _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(i)
      if not isHeader and id == questId then return i end
    end
  end
  return nil
end

function P.IsQuestInLog(questId)
  return P.QuestLogIndex(questId) ~= nil
end

-- Teslim edilmis (bir daha alinamaz) mi?
function P.IsQuestFlaggedCompleted(questId)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return try(C_QuestLog.IsQuestFlaggedCompleted, questId) == true
  end
  if IsQuestFlaggedCompleted then
    return try(IsQuestFlaggedCompleted, questId) == true
  end
  if GetQuestsCompleted then
    local done = try(GetQuestsCompleted)
    return type(done) == "table" and done[questId] == true
  end
  return false
end

-- Tum hedefler tamam (teslim edilmeye hazir) mi?
function P.IsQuestComplete(questId)
  if C_QuestLog and C_QuestLog.IsComplete then
    local r = try(C_QuestLog.IsComplete, questId)
    if r ~= nil then return r == true end
  end
  if IsQuestComplete then
    return try(IsQuestComplete, questId) == true
  end
  local index = P.QuestLogIndex(questId)
  if index and GetQuestLogTitle then
    local _, _, _, _, _, isComplete = GetQuestLogTitle(index)
    return isComplete == 1 or isComplete == true
  end
  return false
end

-- { {finished=bool, numFulfilled=n, numRequired=n, text=...}, ... } ya da nil
function P.GetObjectives(questId)
  if C_QuestLog and C_QuestLog.GetQuestObjectives then
    local objectives = try(C_QuestLog.GetQuestObjectives, questId)
    if type(objectives) == "table" then return objectives end
  end
  local index = P.QuestLogIndex(questId)
  if index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local list = {}
    for i = 1, GetNumQuestLeaderBoards(index) or 0 do
      local text, _, finished = GetQuestLogLeaderBoard(i, index)
      list[i] = { text = text, finished = finished and true or false }
    end
    return list
  end
  return nil
end

-- fallback: oyun gorev adini bilmiyorsa (henuz alinmamis gorev) kullanilacak metin.
function P.QuestName(questId, fallback)
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then
    local title = try(C_QuestLog.GetTitleForQuestID, questId)
    if title and title ~= "" then return title end
  end
  local index = P.QuestLogIndex(questId)
  if index and GetQuestLogTitle then
    local title = GetQuestLogTitle(index)
    if title then return title end
  end
  return fallback or ("#" .. tostring(questId))
end

function P.ItemCount(itemId, includeBank)
  if C_Item and C_Item.GetItemCount then
    return try(C_Item.GetItemCount, itemId, includeBank and true or nil) or 0
  end
  if GetItemCount then return try(GetItemCount, itemId, includeBank and true or nil) or 0 end
  return 0
end

local function xy(vector)
  if not vector then return nil end
  if vector.GetXY then return vector:GetXY() end
  return vector.x, vector.y
end

local function world(map, x, y)
  local c, w = try(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x, y))
  if not c or not w then return nil end
  local wx, wy = xy(w)
  if not wx then return nil end
  return c, wx, wy
end

-- Dunya eksenlerinin yonunu varsaymamak icin: haritada dogu (+x) ve guney (+y) yonlerinin
-- dunya koordinatlarindaki birim vektorlerini olcer. Harita basina bir kez hesaplanir.
local basisCache = {}
local function basis(map)
  local b = basisCache[map]
  if b then return b end
  local c0, ax, ay = world(map, 0.5, 0.5)
  local c1, bx, by = world(map, 0.6, 0.5)
  local c2, cx, cy = world(map, 0.5, 0.6)
  if not (c0 and c1 and c2) or c0 ~= c1 or c0 ~= c2 then return nil end
  local ex, ey = bx - ax, by - ay
  local sx, sy = cx - ax, cy - ay
  local el = math.sqrt(ex * ex + ey * ey)
  local sl = math.sqrt(sx * sx + sy * sy)
  if el == 0 or sl == 0 then return nil end
  b = { ex = ex / el, ey = ey / el, sx = sx / sl, sy = sy / sl }
  basisCache[map] = b
  return b
end

-- Oyuncunun bulundugu harita ve konumu: mapID, x, y (0-1). Alinamazsa nil.
function P.PlayerMapPosition()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local map = try(C_Map.GetBestMapForUnit, "player")
  if not map then return nil end
  local x, y = xy(try(C_Map.GetPlayerMapPosition, map, "player"))
  if not x or (x == 0 and y == 0) then return nil end
  return map, x, y
end

-- Haritadaki quest isaretleri (oyuncunun bulundugu harita): { [questID] = { map, x, y } }, x,y 0-1.
-- Forever'da POI API'si yok ama dunya haritasi isaretleri C_QuestLog.GetQuestsOnMap ile okunuyor:
-- hedef alani ya da teslim NPC'si. Saniyede bir yenilenir (Brain her adim icin sorar).
local questMap, questMapAt
function P.QuestMapPos(questId)
  if not (C_QuestLog and C_QuestLog.GetQuestsOnMap and C_Map and C_Map.GetBestMapForUnit) then return nil end
  local now = P.Now()
  if not questMap or now - questMapAt > 1 then
    questMap, questMapAt = {}, now
    local map = try(C_Map.GetBestMapForUnit, "player")
    local list = map and try(C_QuestLog.GetQuestsOnMap, map)
    -- isaretin koordinati kendi haritasinin (q.mapID) cercevesindedir: alt harita (dukkan ici, alt bolge) isaretini
    -- oyuncunun haritasina gore okumak oku sehrin baska bir yerine gonderirdi (Philmor's Favor: Trade District yerine
    -- Dwarven District). Isaretin haritasi bilinmiyorsa oyuncunun haritasi.
    -- Ama Forever'da sehir haritasinda sorulan isaretin koordinati SORULAN haritanin cercevesinde, mapID ise ust
    -- harita (Ironforge 1455'te Tinkmaster Overspark: mapID Dun Morogh 1426, x/y Ironforge'unki; Dun Morogh'unku
    -- sanilinca ok 778 yd sehrin disina gidiyordu, 19 Kasim 2026). Belge cerceveyi soylemiyor: isaretin haritasi
    -- sorulan haritanin ustuyse sorulan harita esas, digeri yedek (alt); cagiran rehber noktasiyla secebilir.
    local parent = map and P.MapInfo(map)
    parent = parent and parent.parentMapID
    for _, q in ipairs(type(list) == "table" and list or {}) do
      local hidden = issecretvalue and (issecretvalue(q.x) or issecretvalue(q.y) or issecretvalue(q.mapID))
      if q.questID and q.x and q.y and not hidden then
        local qm = (type(q.mapID) == "number" and q.mapID > 0) and q.mapID or map
        if qm ~= map and qm == parent then
          questMap[q.questID] = { map, q.x, q.y, qm }
        else
          questMap[q.questID] = { qm, q.x, q.y, qm ~= map and map or nil }
        end
      end
    end
  end
  local p = questMap[questId]
  if p then return p[1], p[2], p[3], p[4] end
end

-- Sunucudan quest verisi iste: gizli tooltip'e "quest:ID" baglantisi; ad sonra P.QuestTipTitle(slot) ile okunur.
local scanTips = {}
function P.QuestTip(slot, questId)
  if not (CreateFrame and WorldFrame) then return false end
  local tip = scanTips[slot]
  if not tip then
    tip = CreateFrame("GameTooltip", "ArcanisScanTip" .. slot, nil, "GameTooltipTemplate")
    scanTips[slot] = tip
  end
  tip:SetOwner(WorldFrame, "ANCHOR_NONE")
  tip:ClearLines()
  return (pcall(tip.SetHyperlink, tip, "quest:" .. questId))
end

-- Istemci onbellegindeki quest adi (sunucuya istek yok; daha once sorulmus/gorulmus quest'ler). Yoksa nil.
-- Sunucudan gorev verisi iste; cevap QUEST_DATA_LOAD_RESULT(questID, success) olayiyla gelir. Gonderildiyse true.
function P.RequestQuestData(questId)
  if not (C_QuestLog and C_QuestLog.RequestLoadQuestByID) then return false end
  return (pcall(C_QuestLog.RequestLoadQuestByID, questId))
end

function P.CachedQuestTitle(questId)
  local t = C_QuestLog and C_QuestLog.GetTitleForQuestID and try(C_QuestLog.GetTitleForQuestID, questId)
  if issecretvalue and issecretvalue(t) then return nil end
  if type(t) == "string" and t ~= "" then return t end
end

function P.QuestTipTitle(slot)
  local line = _G["ArcanisScanTip" .. slot .. "TextLeft1"]
  local t = line and line.GetText and try(line.GetText, line)
  if issecretvalue and issecretvalue(t) then return nil end
  if type(t) == "string" and t ~= "" and t ~= RETRIEVING_DATA then return t end
end

-- Gunlukteki quest'in oyun tarafindan yazilan kisa hedef metni ("Kill 10 Mottled Boars then return to Gornek...").
-- Yeni API indeks alir; eski API secili girdiyi okur (secim geri alinir). Okunamazsa nil.
local questTextCache = {}
function P.QuestObjectiveText(questId)
  if questTextCache[questId] then return questTextCache[questId] end
  local idx = P.QuestLogIndex(questId)
  if not (idx and GetQuestLogQuestText) then return nil end
  local _, obj = try(GetQuestLogQuestText, idx)
  if (type(obj) ~= "string" or obj == "") and SelectQuestLogEntry and GetQuestLogSelection then
    local prev = try(GetQuestLogSelection)
    try(SelectQuestLogEntry, idx)
    _, obj = try(GetQuestLogQuestText)
    if prev then try(SelectQuestLogEntry, prev) end
  end
  if issecretvalue and issecretvalue(obj) then return nil end
  if type(obj) == "string" and obj ~= "" then
    questTextCache[questId] = obj
    return obj
  end
end

function P.ResetCache()
  for k in pairs(basisCache) do basisCache[k] = nil end
  questMap = nil
end

-- Oyuncudan (map, x, y) noktasina: uzaklik (yard), dogu bileseni, guney bileseni.
-- x,y 0-1 arasi. Hesaplanamazsa (farkli kita, ic mekan vb.) nil.
function P.VectorTo(map, x, y)
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition
          and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
    return nil
  end
  local playerMap = try(C_Map.GetBestMapForUnit, "player")
  if not playerMap then return nil end
  local pos = try(C_Map.GetPlayerMapPosition, playerMap, "player")
  local px, py = xy(pos)
  if not px or (px == 0 and py == 0) then return nil end
  local c1, ax, ay = world(playerMap, px, py)
  local c2, bx, by = world(map, x, y)
  if not (c1 and c2) or c1 ~= c2 then return nil end
  local b = basis(map)
  if not b then return nil end
  local dx, dy = bx - ax, by - ay
  return math.sqrt(dx * dx + dy * dy), dx * b.ex + dy * b.ey, dx * b.sx + dy * b.sy
end

-- VectorTo'nun yol icin toplu hali: oyuncu konumu bir kez okunur, noktalar P.WorldPos onbelleginden.
-- points[from..] -> { { dogu, guney, uzaklik }, ... } (hesaplanamayan nokta atlanir)
function P.VectorsTo(map, points, from)
  local out = {}
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return out end
  local playerMap = try(C_Map.GetBestMapForUnit, "player")
  local pos = playerMap and try(C_Map.GetPlayerMapPosition, playerMap, "player")
  local px, py = xy(pos)
  if not px or (px == 0 and py == 0) then return out end
  local c1, ax, ay = world(playerMap, px, py)
  local b = basis(map)
  if not (c1 and b) then return out end
  for i = from or 1, #points do
    local pt = points[i]
    local c2, bx, by = P.WorldPos(map, pt[1], pt[2])
    if c2 == c1 then
      local dx, dy = bx - ax, by - ay
      out[#out + 1] = { dx * b.ex + dy * b.ey, dx * b.sx + dy * b.sy, math.sqrt(dx * dx + dy * dy) }
    end
  end
  return out
end

-- Minimap: yaricap (yard) ve donuyor mu. Yoksa nil.
local MINI_OUT = { 466.6667, 400, 333.3333, 266.6667, 200, 133.3333 }   -- zoom 0..5, cap (yard)
local MINI_IN  = { 300, 240, 180, 120, 80, 50 }
function P.MinimapInfo()
  if not (Minimap and Minimap.GetZoom) then return nil end
  local zoom = try(Minimap.GetZoom, Minimap) or 0
  local indoors = IsIndoors and try(IsIndoors)
  local sizes = indoors and MINI_IN or MINI_OUT
  local diameter = sizes[zoom + 1] or sizes[1]
  local rotate = GetCVar and try(GetCVar, "rotateMinimap") == "1" or false
  return diameter / 2, rotate
end

-- (map, x, y) noktasinin `display` haritasindaki konumu (0-1); donusturulemezse nil.
function P.MapPosOn(map, x, y, display)
  if not (map and display) then return nil end
  if map == display then return x, y end
  if not (C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
  local c, wx, wy = world(map, x, y)
  if not c then return nil end
  local ok, _, pos = pcall(C_Map.GetMapPosFromWorldPos, c, CreateVector2D(wx, wy), display)
  if not ok then return nil end
  local px, py = xy(pos)
  return px, py
end

-- Haritanin dunya dikdortgeni (kita, sol ust ve sag alt kosenin dunya yardi): harita konumu dunya konumunun
-- dogrusal fonksiyonu; isaret katmani binlerce noktayi C_Map'e sormadan yerlestirir. Hesaplanamazsa nil.
local rectCache = {}
function P.MapWorldRect(map)
  if not map then return nil end
  local r = rectCache[map]
  if r then return r end
  local c0, wx0, wy0 = P.WorldPos(map, 0, 0)
  local c1, wx1, wy1 = P.WorldPos(map, 1, 1)
  if not (c0 and c1 and c0 == c1 and wx0 ~= wx1 and wy0 ~= wy1) then return nil end
  r = { c = c0, wx0 = wx0, wy0 = wy0, wx1 = wx1, wy1 = wy1 }
  rectCache[map] = r
  return r
end

-- Oyuncunun `display` haritasindaki konumu (0-1) ya da nil.
function P.PlayerPosOn(display)
  local map, x, y = P.PlayerMapPosition()
  if not map then return nil end
  return P.MapPosOn(map, x, y, display)
end

-- Instance icindeyse adi ve turu ("party", "raid"...); disarida nil.
function P.InstanceInfo()
  if not (IsInInstance and GetInstanceInfo) then return nil end
  local inside, kind = try(IsInInstance)
  if not inside then return nil end
  local name = try(GetInstanceInfo)
  return name, kind
end

-- Haritada kesfedilmis bolge dokulari: anahtar ilk dosya kimligi ve "x:y" ofseti -> true.
function P.ExploredOverlayKeys(map)
  local keys = {}
  if not (map and C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures) then return keys end
  local ok, list = pcall(C_MapExplorationInfo.GetExploredMapTextures, map)
  if not (ok and type(list) == "table") then return keys end
  for _, info in ipairs(list) do
    local ids = info.fileDataIDs
    if type(ids) == "table" and ids[1] then keys[ids[1]] = true end
    if info.offsetX and info.offsetY then keys[info.offsetX .. ":" .. info.offsetY] = true end
  end
  return keys
end


-- Yardimci modullerin kullandigi katman: cantalar, satici, onarim, gorev penceresi
-- (Retail ve Classic farklarini burada gizler.)
local function lastBag() return NUM_BAG_SLOTS or 4 end
P.LastBag = lastBag

function P.ContainerSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return try(C_Container.GetContainerNumSlots, bag) or 0 end
  if GetContainerNumSlots then return try(GetContainerNumSlots, bag) or 0 end
  return 0
end

-- { quality, noValue, count, link, id } ya da nil (bos).
function P.ContainerItem(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if not ok or type(info) ~= "table" then return nil end
    return { quality = info.quality, noValue = info.hasNoValue, count = info.stackCount or 1, link = info.hyperlink, id = info.itemID,
             bound = info.isBound, icon = info.iconFileID }
  end
  if GetContainerItemInfo then
    local ok, icon, count, _, quality, _, _, link, _, noValue, id = pcall(GetContainerItemInfo, bag, slot)
    if not ok or not icon then return nil end
    return { quality = quality, noValue = noValue, count = count or 1, link = link, id = id, icon = icon }
  end
  return nil
end

function P.ItemSellPrice(link)
  local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not fn or not link then return nil end
  local ok, _, _, _, _, _, _, _, _, _, _, price = pcall(fn, link)
  if ok then return price end
  return nil
end

-- Esyanin sinif numarasi (2 silah, 4 zirh ...) ya da nil.
function P.ItemClassId(link)
  if not link then return nil end
  local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not fn then return nil end
  local ok, _, _, _, _, _, classId = pcall(fn, link)
  if ok then return classId end
  return nil
end

-- Esya ayrintilari (kimlikten). Dondurur: { id, name, link, quality, equipLoc, classId, subClassId, minLevel, stats }
-- ya da nil. Esya onbellekte degilse nil doner ve yukleme istenir (GET_ITEM_INFO_RECEIVED gelir).
-- Esya ikonu (onbellekte olmasa da calisir).
function P.ItemIcon(itemId)
  if not itemId then return nil end
  if C_Item and C_Item.GetItemIconByID then
    local ok, ic = pcall(C_Item.GetItemIconByID, itemId)
    if ok and ic then return ic end
  end
  local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if instant then
    local ok, _, _, _, _, ic = pcall(instant, itemId)
    if ok and ic then return ic end
  end
  if GetItemIcon then
    local ok, ic = pcall(GetItemIcon, itemId)
    if ok and ic then return ic end
  end
  return nil
end

function P.ItemDetails(itemId)
  if not itemId then return nil end
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not getInfo then return nil end
  local ok, name, link, quality, ilvl, minLevel, _, subType, _, equipLoc = pcall(getInfo, itemId)
  if not ok or not name then
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, itemId) end
    return nil
  end
  local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  local classId, subClassId, icon
  if instant then
    local ok2, _, _, _, _, ic, c, sc = pcall(instant, itemId)
    if ok2 then classId, subClassId, icon = c, sc, ic end
  end
  if not icon and GetItemIcon then
    local ok4, ic = pcall(GetItemIcon, itemId)
    if ok4 then icon = ic end
  end
  local statsFn = (C_Item and C_Item.GetItemStats) or GetItemStats
  local stats
  if statsFn and link then
    local ok3, t = pcall(statsFn, link)
    if ok3 and type(t) == "table" then stats = t end
  end
  return { id = itemId, name = name, link = link, quality = quality, equipLoc = equipLoc, subType = subType,
           classId = classId, subClassId = subClassId, icon = icon, minLevel = minLevel or 0, stats = stats or {},
           ilvl = type(ilvl) == "number" and ilvl or nil }
end

-- Toplama becerileri: Herbalism (182) ve Mining (186) seviyeleri (yoksa nil).
function P.GatherSkill()
  if not (GetProfessions and GetProfessionInfo) then return nil end
  local ok, a, b, c, d, e = pcall(GetProfessions)
  if not ok then return nil end
  local out = { herbs = nil, ore = nil }
  for i = 1, 5 do
    local idx = select(i, a, b, c, d, e)
    if idx then
      local ok2, _, _, level, _, _, _, line = pcall(GetProfessionInfo, idx)
      if ok2 then
        if line == 182 then out.herbs = level elseif line == 186 then out.ore = level end
      end
    end
  end
  return out
end

-- Tum meslekler: { Mining = 125, Tailoring = 80, ... } (Ingilizce ad, beceri hattindan; yoksa bos tablo).
local SKILL_LINES = {
  [182] = "Herbalism", [186] = "Mining", [393] = "Skinning", [197] = "Tailoring", [165] = "Leatherworking",
  [164] = "Blacksmithing", [171] = "Alchemy", [202] = "Engineering", [333] = "Enchanting", [755] = "Jewelcrafting",
  [773] = "Inscription", [185] = "Cooking", [129] = "First Aid", [356] = "Fishing",
}
P.SKILL_LINES = SKILL_LINES
local SKILL_NAMES = {}
for _, n in pairs(SKILL_LINES) do SKILL_NAMES[n] = n end
function P.Professions()
  local out = {}
  if not (GetProfessions and GetProfessionInfo) then
    -- eski istemci: beceri satirlarindan (Ingilizce adlar)
    if GetNumSkillLines and GetSkillLineInfo then
      local ok, n = pcall(GetNumSkillLines)
      for i = 1, (ok and n or 0) do
        local ok2, name, header, _, rank = pcall(GetSkillLineInfo, i)
        if ok2 and name and not header and SKILL_NAMES[name] then out[name] = rank or 0 end
      end
    end
    return out
  end
  local ok, a, b, c, d, e = pcall(GetProfessions)
  if not ok then return out end
  for i = 1, 5 do
    local idx = select(i, a, b, c, d, e)
    if idx then
      local ok2, _, _, level, maxLevel, _, _, line = pcall(GetProfessionInfo, idx)
      if ok2 and SKILL_LINES[line] then out[SKILL_LINES[line]] = level or 0 end
    end
  end
  return out
end

-- Baglanti/ID'den esya kimligi.
function P.ItemIdFromLink(link)
  if type(link) == "number" then return link end
  return link and tonumber(tostring(link):match("item:(%d+)")) or nil
end

-- Oyuncunun can yuzdesi (0-1) ve hedef tehlikesi ("elite" | "boss" | "skull" | nil).
function P.HealthFraction()
  if not (UnitHealth and UnitHealthMax) then return nil end
  local hp, mx = try(UnitHealth, "player"), try(UnitHealthMax, "player")
  -- Yeni istemcide savasta can degerleri "gizli" (secret) olabilir: aritmetik hata verir, o zaman nil.
  if issecretvalue and (issecretvalue(hp) or issecretvalue(mx)) then return nil end
  local ok, f = pcall(function() if not hp or not mx or mx <= 0 then return nil end return hp / mx end)
  return ok and f or nil
end

local function targetDanger()
  if not (UnitExists and UnitExists("target")) or (UnitIsFriend and UnitIsFriend("player", "target")) then return nil end
  local class = UnitClassification and UnitClassification("target")
  local lvl = UnitLevel and UnitLevel("target")
  local me = UnitLevel("player") or 1
  if class == "worldboss" then return "boss" end
  if lvl == -1 or (lvl and lvl >= me + 5) then return "skull" end
  if class == "elite" or class == "rareelite" then return "elite" end
  return nil
end

function P.TargetDanger()
  local ok, v = pcall(targetDanger)
  return ok and v or nil
end

-- Hedefin GUID'i; savasta gizli (secret) olabilir, o zaman nil.
function P.TargetGUID()
  return UnitGUID and P.Clean(UnitGUID("target")) or nil
end

-- Deneyim: xp, azami xp, seviye.
function P.XP()
  return (UnitXP and UnitXP("player")) or 0, (UnitXPMax and UnitXPMax("player")) or 1, UnitLevel("player") or 1
end

-- Dinlenmis (rested) XP miktari; yoksa 0.
function P.RestXP()
  if not GetXPExhaustion then return 0 end
  local ok, v = pcall(GetXPExhaustion)
  return (ok and type(v) == "number" and not (issecretvalue and issecretvalue(v))) and v or 0
end

-- Azami oyuncu seviyesi (bu seviyede gorev XP vermez).
function P.MaxLevel()
  local v = GetMaxPlayerLevel and GetMaxPlayerLevel()
  return type(v) == "number" and v > 0 and v or 60
end

-- Gorev seviyesi (bilinmiyorsa nil). Oyun bu bilgiyi gunlukte olmayan gorev icin de verebilir.
function P.QuestLevel(questId)
  if not (C_QuestLog and C_QuestLog.GetQuestDifficultyLevel) then return nil end
  local lvl = try(C_QuestLog.GetQuestDifficultyLevel, questId)
  if type(lvl) == "number" and lvl > 0 then return lvl end
  return nil
end

function P.OnTaxi() return UnitOnTaxi and UnitOnTaxi("player") and true or false end

-- Oyuncunun yerdeki kosu hizi (yd/s; binekliyken binegin hizi) ya da nil.
function P.RunSpeed()
  if not GetUnitSpeed then return nil end
  local ok, _, run = pcall(GetUnitSpeed, "player")
  if not ok or type(run) ~= "number" or (issecretvalue and issecretvalue(run)) then return nil end
  return run
end

local function secret(...)
  if not issecretvalue then return false end
  for i = 1, select("#", ...) do if issecretvalue((select(i, ...))) then return true end end
  return false
end

-- Oyuncunun suren cast'i ya da kanali: { name, icon, start, finish (sn, GetTime olcegi), tradeskill, spellId, channel }
-- ya da nil (gizli deger dahil).
function P.PlayerCast()
  if UnitCastingInfo then
    local ok, name, _, icon, s, e, trade, _, _, id = pcall(UnitCastingInfo, "player")
    if ok and name and not secret(name, s, e, id) then
      return { name = name, icon = icon, start = (s or 0) / 1000, finish = (e or 0) / 1000, tradeskill = trade and true or false, spellId = id }
    end
  end
  if UnitChannelInfo then
    local ok, name, _, icon, s, e, trade, _, id = pcall(UnitChannelInfo, "player")
    if ok and name and not secret(name, s, e, id) then
      return { name = name, icon = icon, start = (s or 0) / 1000, finish = (e or 0) / 1000, tradeskill = trade and true or false, spellId = id, channel = true }
    end
  end
  return nil
end

-- Meslek becerileri: { {name = "Mining", rank, max}, ... } (Ingilizce ad; beceri satirlari ya da GetProfessionInfo)
function P.ProfessionRanks()
  local out = {}
  if GetProfessions and GetProfessionInfo then
    local ok, a, b, c, d, e = pcall(GetProfessions)
    for i = 1, 5 do
      local idx = ok and select(i, a, b, c, d, e)
      if idx then
        local ok2, _, _, level, maxLevel, _, _, line = pcall(GetProfessionInfo, idx)
        if ok2 and SKILL_LINES[line] then out[#out + 1] = { name = SKILL_LINES[line], rank = level or 0, max = maxLevel or 0 } end
      end
    end
  elseif GetNumSkillLines and GetSkillLineInfo then
    local ok, n = pcall(GetNumSkillLines)
    for i = 1, (ok and n or 0) do
      local ok2, name, header, _, rank, _, _, max = pcall(GetSkillLineInfo, i)
      if ok2 and name and not header and SKILL_NAMES[name] then out[#out + 1] = { name = name, rank = rank or 0, max = max or 0 } end
    end
  end
  return out
end

-- Acik loot penceresindeki esyalar: { {id, count, name}, ... } ve balik avi lootu mu.
function P.LootItems()
  local out = {}
  if not (GetNumLootItems and GetLootSlotInfo) then return out, false end
  local ok, n = pcall(GetNumLootItems)
  for i = 1, (ok and n or 0) do
    local ok2, _, name, count = pcall(GetLootSlotInfo, i)
    local link = GetLootSlotLink and try(GetLootSlotLink, i)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if ok2 and id and not secret(name, count) then out[#out + 1] = { id = id, count = count or 1, name = name } end
  end
  return out, IsFishingLoot and try(IsFishingLoot) and true or false
end

-- Ana eldeki gecici buyu (balik avi lure'u) icin kalan saniye ya da nil.
function P.LureTime()
  if GetWeaponEnchantInfo then
    local ok, has, ms = pcall(GetWeaponEnchantInfo)
    if ok and has and type(ms) == "number" and not secret(ms) then return ms / 1000 end
    return nil
  end
  if C_Item and C_Item.GetWeaponEnchantInfo and Enum and Enum.WeaponSlot then
    local list = try(C_Item.GetWeaponEnchantInfo, Enum.WeaponSlot.MainHand)
    local e = type(list) == "table" and list[1]
    if e and e.hasEnchant and type(e.timeLeft) == "number" and not secret(e.timeLeft) then return e.timeLeft / 1000 end
  end
  return nil
end

-- Bilinen buyu mu (meslek bekleme sureleri icin).
function P.KnowsSpell(id)
  if IsPlayerSpell then return try(IsPlayerSpell, id) and true or false end
  if C_SpellBook and C_SpellBook.IsSpellKnown and Enum and Enum.SpellBookSpellBank then
    return try(C_SpellBook.IsSpellKnown, id, Enum.SpellBookSpellBank.Player) and true or false
  end
  return false
end

-- Buyu bekleme suresi: kalan saniye (0 = hazir) ya da nil.
function P.SpellCooldown(id)
  local start, dur
  if C_Spell and C_Spell.GetSpellCooldown then
    local info = try(C_Spell.GetSpellCooldown, id)
    if type(info) == "table" then start, dur = info.startTime, info.duration end
  elseif GetSpellCooldown then
    start, dur = try(GetSpellCooldown, id)
  end
  if type(start) ~= "number" or type(dur) ~= "number" or secret(start, dur) then return nil end
  if start == 0 or dur == 0 then return 0 end
  return math.max(0, start + dur - ((GetTime and GetTime()) or 0))
end

function P.SpellName(id)
  if C_Spell and C_Spell.GetSpellName then
    local n = try(C_Spell.GetSpellName, id)
    if n then return n end
  end
  if GetSpellInfo then return (try(GetSpellInfo, id)) end
  return nil
end

-- "Create All" / "Create N": DoTradeSkill cagrisini dinler (fn(adet)).
function P.OnCraftQueue(fn)
  if hooksecurefunc and DoTradeSkill then
    hooksecurefunc("DoTradeSkill", function(_, n) fn(tonumber(n) or 1) end)
  end
end

-- Sureli gorevler: { {quest = id ya da nil, left = kalan saniye}, ... }
function P.QuestTimers()
  local out, list = {}, nil
  if C_QuestLog and C_QuestLog.GetQuestTimers then
    list = try(C_QuestLog.GetQuestTimers)
    for _, t in ipairs(type(list) == "table" and list or {}) do
      if type(t) == "table" and type(t.questTimer) == "number" and not (issecretvalue and issecretvalue(t.questTimer)) then
        out[#out + 1] = { quest = t.questID, left = t.questTimer }
      end
    end
  elseif GetQuestTimers then
    local ok, a, b, c = pcall(GetQuestTimers)
    for _, s in ipairs(ok and { a, b, c } or {}) do
      if type(s) == "number" then out[#out + 1] = { left = s } end
    end
  end
  return out
end

-- Yetenek listesi: { {name, rank, max}, ... } (sekme sirasiyla) ve harcanmamis puan.
function P.TalentList()
  if not (GetNumTalentTabs and GetNumTalents and GetTalentInfo) then return nil end
  local out = {}
  local tabs = try(GetNumTalentTabs) or 0
  for tab = 1, tabs do
    local n = try(GetNumTalents, tab) or 0
    for i = 1, n do
      local ok, name, icon, _, _, rank, max = pcall(GetTalentInfo, tab, i)
      if ok and name then out[#out + 1] = { name = name, icon = icon, rank = rank or 0, max = max or 1, tab = tab } end
    end
  end
  return out
end

-- Buyu ikonu (ada gore; bilinmiyorsa nil).
function P.SpellIcon(name)
  if not name then return nil end
  if C_Spell and C_Spell.GetSpellTexture then
    local ok, t = pcall(C_Spell.GetSpellTexture, name)
    if ok and t then return t end
  end
  if GetSpellTexture then
    local ok, t = pcall(GetSpellTexture, name)
    if ok and t then return t end
  end
  return nil
end

-- Forever'da Classic'in yetenek fonksiyonlari yok (C_Traits): RotationForge (ns.RF) agaci okuduysa ondan.
local function rfTalents()
  local RF = ns.RF
  if RF and RF.TalentCount and RF.TalentCount() > 0 then return RF end
  return nil
end

function P.UnspentTalents()
  local RF = rfTalents()
  if RF and RF.TalentUnspent then
    local ok, n = pcall(RF.TalentUnspent)
    if ok and type(n) == "number" then return n end
  end
  if GetUnspentTalentPoints then return try(GetUnspentTalentPoints) or 0 end
  return 0
end

function P.Now() return (GetTime and GetTime()) or 0 end

-- Karakter makrosunun sirasi (yoksa 0). GetMacroIndexByName hesap geneli makroyu da (ve ayni adda once onu) bulur;
-- kur / sil yalniz karakter makrosuna dokunsun diye karakter araligi (MAX_ACCOUNT_MACROS'tan sonrasi) taranir.
function P.CharacterMacroIndex(name)
  if type(name) ~= "string" or name == "" then return 0 end
  local base = type(MAX_ACCOUNT_MACROS) == "number" and MAX_ACCOUNT_MACROS or 120
  if GetNumMacros and GetMacroInfo then
    local ok, _, perChar = pcall(GetNumMacros)
    if ok and type(perChar) == "number" then
      for i = base + 1, base + perChar do
        local ok2, n = pcall(GetMacroInfo, i)
        if ok2 and n == name then return i end
      end
      return 0
    end
  end
  if not GetMacroIndexByName then return 0 end
  local ok, idx = pcall(GetMacroIndexByName, name)
  if not ok or type(idx) ~= "number" or idx <= 0 then return 0 end
  -- sayim API'si yoksa (eski istemci): hesap araligindaki sira karakter makrosu degildir
  if GetNumMacros and idx <= base then return 0 end
  return idx
end

-- Oyuncu olu ya da hayalet mi.
function P.IsDead()
  return UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") and true or false
end

-- Korumali islem kilidi (savas).
function P.InLockdown()
  return InCombatLockdown and InCombatLockdown() and true or false
end

function P.InCombat()
  return UnitAffectingCombat and UnitAffectingCombat("player") and true or false
end

-- Ic mekan (bina, magara): ok magara girisinden mi baslasin karari
function P.IsIndoors() return IsIndoors and try(IsIndoors) and true or false end

-- Dinlenme alani (han, sehir; Forever'da kamp atesi de kamp kurar ve dinlendirir)
function P.IsResting() return IsResting and try(IsResting) and true or false end

-- Oyuncuda bu buyu ID'li aura var mi
function P.HasPlayerAura(id)
  if not C_UnitAuras then return false end
  if C_UnitAuras.GetPlayerAuraBySpellID and try(C_UnitAuras.GetPlayerAuraBySpellID, id) ~= nil then return true end
  -- yedek: bazi aura'lar dogrudan sorguda donmuyor (Violet Flames, 7 Kasim 2026); buff'lari tek tek tara
  if not C_UnitAuras.GetAuraDataByIndex then return false end
  for i = 1, 80 do
    local a = try(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
    if not a then return false end
    local sid = a.spellId
    if not (issecretvalue and issecretvalue(sid)) and sid == id then return true end
  end
  return false
end

-- Oyuncunun buff'lari: { {id, name}, ... } (gizli degerler atlanir; teshis ve ada gore arama icin)
function P.PlayerBuffs()
  local out = {}
  if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return out end
  for i = 1, 80 do
    local a = try(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
    if not a then break end
    local sid, name, exp, dur = a.spellId, a.name, a.expirationTime, a.duration
    if issecretvalue and (issecretvalue(sid) or issecretvalue(name)) then sid, name = nil, nil end
    if issecretvalue and (issecretvalue(exp) or issecretvalue(dur)) then exp, dur = nil, nil end
    out[#out + 1] = { id = sid, name = name, exp = exp, dur = dur }
  end
  return out
end

-- Otur (/sit ile ayni emote; korumali degil)
function P.Sit() if DoEmote then try(DoEmote, "SIT") end end

-- Fareyle kamera cevriliyor mu (imlec gizli, konumu donmus kalir)
function P.MouseLooking()
  return IsMouselooking and IsMouselooking() and true or false
end

function P.PlayerClassToken()
  local _, token = UnitClass("player")
  return token
end

function P.UseContainerItem(bag, slot)
  local fn = (C_Container and C_Container.UseContainerItem) or UseContainerItem
  if fn then pcall(fn, bag, slot) end
end

function P.FreeBagSlots()
  local free = 0
  for bag = 0, lastBag() do
    local n
    if C_Container and C_Container.GetContainerNumFreeSlots then n = try(C_Container.GetContainerNumFreeSlots, bag)
    elseif GetContainerNumFreeSlots then n = try(GetContainerNumFreeSlots, bag) end
    free = free + (n or 0)
  end
  return free
end

-- En dusuk dayaniklilik orani (0-1) ya da nil.
function P.LowestDurability()
  if not GetInventoryItemDurability then return nil end
  local lowest
  for slot = 1, 18 do
    local ok, cur, max = pcall(GetInventoryItemDurability, slot)
    if ok and cur and max and max > 0 then
      local ratio = cur / max
      if not lowest or ratio < lowest then lowest = ratio end
    end
  end
  return lowest
end

function P.Money() return (GetMoney and try(GetMoney)) or 0 end

function P.MoneyText(copper)
  copper = math.floor(copper or 0)
  local g, s, c = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. "g" end
  if s > 0 or g > 0 then parts[#parts + 1] = s .. "s" end
  parts[#parts + 1] = c .. "c"
  return table.concat(parts, " ")
end

-- Onarim: cost, canRepair
function P.RepairCost()
  if not (CanMerchantRepair and try(CanMerchantRepair)) then return nil end
  local ok, cost, can = pcall(GetRepairAllCost)
  if ok then return cost, can end
  return nil
end

-- Silah becerisi biliniyor mu? Beceri bir "buyu" olarak ogrenilir (Classic kimlikleri). true/false; okunamazsa nil.
local WEAPON_SKILL_SPELL = {
  ["One-Handed Axes"] = 196, ["Two-Handed Axes"] = 197, ["One-Handed Maces"] = 198, ["Two-Handed Maces"] = 199,
  ["Polearms"] = 200, ["One-Handed Swords"] = 201, ["Two-Handed Swords"] = 202, ["Staves"] = 227, ["Bows"] = 264,
  ["Guns"] = 266, ["Daggers"] = 1180, ["Thrown"] = 2567, ["Wands"] = 5009, ["Crossbows"] = 5011, ["Fist Weapons"] = 15590,
}
-- Yalniz "evet" kesindir: buyu kimligi bu istemcide yoksa false doner, o yuzden beceri satirlarina da bakilir.
function P.KnowsWeaponSkill(skill)
  local id = WEAPON_SKILL_SPELL[skill]
  local fn = IsPlayerSpell or IsSpellKnown
  local answered = false
  if id and fn then
    local ok, known = pcall(fn, id)
    if ok and not (issecretvalue and issecretvalue(known)) and known ~= nil then
      if known == true then return true end
      answered = true
    end
  end
  if GetNumSkillLines and GetSkillLineInfo then   -- beceri satirlari (Ingilizce adlar)
    local ok, n = pcall(GetNumSkillLines)
    if ok and type(n) == "number" then
      for i = 1, n do
        local ok2, name, header = pcall(GetSkillLineInfo, i)
        if ok2 and not header and name == skill then return true end
      end
      answered = true
    end
  end
  if answered then return false end
  return nil
end

function P.IsWeaponSkillName(name) return WEAPON_SKILL_SPELL[name] ~= nil end

-- Acik egitmen penceresindeki tum hizmetler: { { name, rank, level, kind } } ya da nil (API yok).
-- Pencere filtreleri (ogrenilebilir / henuz degil / ogrenildi) gecici olarak "hepsi" yapilir ve geri alinir.
function P.TrainerServices()
  if not (GetNumTrainerServices and GetTrainerServiceInfo) then return nil end
  local saved = {}
  if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter then
    for _, f in ipairs({ "available", "unavailable", "used" }) do
      local v = try(GetTrainerServiceTypeFilter, f)
      saved[f] = (v == true or v == 1) and 1 or 0
      pcall(SetTrainerServiceTypeFilter, f, 1)
    end
  end
  local out = {}
  local ok, n = pcall(GetNumTrainerServices)
  for i = 1, (ok and type(n) == "number" and n or 0) do
    local ok2, name, sub, kind = pcall(GetTrainerServiceInfo, i)
    if ok2 and type(name) == "string" and not (issecretvalue and issecretvalue(name)) and kind ~= "header" then
      local lv = GetTrainerServiceLevelReq and try(GetTrainerServiceLevelReq, i)
      local rank = type(sub) == "string" and tonumber(sub:match("(%d+)")) or nil
      local cost = GetTrainerServiceCost and tonumber((try(GetTrainerServiceCost, i))) or nil
      out[#out + 1] = { name = name, rank = rank, level = tonumber(lv), kind = kind, cost = cost,
        sub = type(sub) == "string" and not secret(sub) and sub or nil }
    end
  end
  for f, v in pairs(saved) do pcall(SetTrainerServiceTypeFilter, f, v) end
  return out
end

-- Auction House ilani (UI/AuctionPanel.lua). Yalniz bir dugme tiklamasindan cagrilir (donanim olayi gerekir).
-- Modern istemci: C_AuctionHouse.PostItem / PostCommodity. Eski: satis yuvasi + PostAuction.
-- Sureler 1/2/3 (oyunun kendi kisa/orta/uzun sureleri; etiketler istemcinin metinlerinden).
function P.AHPostMode()
  if C_AuctionHouse and C_AuctionHouse.PostItem and ItemLocation and ItemLocation.CreateFromBagAndSlot then return "modern" end
  if PostAuction and ClickAuctionSellItemButton then return "classic" end
  return nil
end

function P.AHDurationLabels()
  local g = _G
  return { g.AUCTION_DURATION_ONE or "Short", g.AUCTION_DURATION_TWO or "Medium", g.AUCTION_DURATION_THREE or "Long" }
end

local function pickup(bag, slot)
  local fn = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
  if fn then pcall(fn, bag, slot) end
end

-- Ilan koy: quantity adet, birim fiyat unitPrice (bakir). itemId: yerde olmasi gereken esya (eski API'de satis
-- yuvasi bununla dogrulanir). Dondurur: true ya da false, neden. true = istek gonderildi (sunucu yine reddedebilir).
function P.AHPost(bag, slot, quantity, unitPrice, duration, itemId)
  if not (bag and slot and quantity and quantity > 0 and unitPrice and unitPrice > 0) then return false, "args" end
  local mode = P.AHPostMode()
  if mode == "modern" then
    local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    local okS, status = pcall(C_AuctionHouse.GetItemCommodityStatus, loc)
    local S = Enum and Enum.ItemCommodityStatus
    -- esya verisi yuklenmeden durum "bilinmiyor" (0): yanlis API'yle (adet x birim) ilan acilmasin
    if not okS or status == nil or status == ((S and S.Unknown) or 0) then return false, "item not loaded" end
    local commodity = status == ((S and S.Commodity) or 2)
    -- PostItem'in buyout'u tek esyanin fiyati (quantity ayri ilanlar). Sunucu onay isterse (needsConfirmation,
    -- fiyat piyasanin cok altinda: yanlis yazilmis fiyata tek koruma) kendiliginden onaylanmaz: false, "confirm",
    -- onay islevi doner; cagiran oyuncuya sorar (P.Confirm) ve evet derse islevi cagirir.
    local post = commodity and C_AuctionHouse.PostCommodity or C_AuctionHouse.PostItem
    local confirm = commodity and C_AuctionHouse.ConfirmPostCommodity or C_AuctionHouse.ConfirmPostItem
    local ok, res
    if commodity then
      ok, res = pcall(post, loc, duration, quantity, unitPrice)
    else
      ok, res = pcall(post, loc, duration, quantity, nil, unitPrice)
    end
    if not ok then return false, tostring(res) end
    if res == true then
      if not confirm then return false, "needs confirmation" end
      return false, "confirm", function()
        if commodity then return pcall(confirm, loc, duration, quantity, unitPrice) end
        return pcall(confirm, loc, duration, quantity, nil, unitPrice)
      end
    end
    return true
  elseif mode == "classic" then
    if ClearCursor then ClearCursor() end
    pickup(bag, slot)
    local okC = pcall(ClickAuctionSellItemButton)
    if ClearCursor then ClearCursor() end
    if not okC then return false, "slot" end
    -- satis yuvasinda gercekten bu esya ve yeterli adet var mi? (kilitli esya, bos imlec, baska esya)
    if GetAuctionSellItemInfo then
      local okI, _, _, count, _, _, _, _, _, _, sellId = pcall(GetAuctionSellItemInfo)
      if not okI or not count or count < quantity or (itemId and sellId and sellId ~= itemId) then return false, "slot" end
    end
    local stack = unitPrice * quantity   -- eski API: fiyatlar yigin basina
    local ok, err = pcall(PostAuction, stack, stack, duration, quantity, 1)
    return ok, not ok and tostring(err) or nil
  end
  return false, "api"
end

-- Esya ruhuna bagli mi? Yeni API isBound verir; eski API'de gizli ipucu satirlarina bakilir. Bilinmiyorsa nil.
local scanTip
function P.IsSoulbound(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if ok and type(info) == "table" and info.isBound ~= nil then return info.isBound == true end
  end
  if not (CreateFrame and ITEM_SOULBOUND) then return nil end
  scanTip = scanTip or CreateFrame("GameTooltip", "ArcanisScanTooltip", nil, "GameTooltipTemplate")
  if not scanTip then return nil end
  pcall(scanTip.SetOwner, scanTip, UIParent, "ANCHOR_NONE")
  pcall(scanTip.ClearLines, scanTip)
  if not pcall(scanTip.SetBagItem, scanTip, bag, slot) then return nil end
  local ok, n = pcall(scanTip.NumLines, scanTip)
  for i = 2, math.min(6, (ok and type(n) == "number") and n or 0) do
    local fs = _G["ArcanisScanTooltipTextLeft" .. i]
    local t = fs and fs:GetText()
    if t == ITEM_SOULBOUND or t == ITEM_BIND_QUEST then return true end
  end
  return false
end

-- Ilan ucreti (deposit, bakir) ya da nil (istemci ilan oncesi hesaplamiyorsa).
function P.AHDeposit(bag, slot, itemId, quantity, duration)
  if P.AHPostMode() ~= "modern" or not (bag and slot) then return nil end
  local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
  local okS, status = pcall(C_AuctionHouse.GetItemCommodityStatus, loc)
  local commodity = okS and status == ((Enum and Enum.ItemCommodityStatus and Enum.ItemCommodityStatus.Commodity) or 2)
  local ok, v
  if commodity and C_AuctionHouse.CalculateCommodityDeposit and itemId then
    ok, v = pcall(C_AuctionHouse.CalculateCommodityDeposit, itemId, duration, quantity)
  elseif not commodity and C_AuctionHouse.CalculateItemDeposit then
    ok, v = pcall(C_AuctionHouse.CalculateItemDeposit, loc, duration, quantity)
  end
  return ok and type(v) == "number" and v or nil
end

-- Acik egitmen meslek egitmeni mi? (sinif egitmeni ziyareti sayilmasin) Bilinmiyorsa false.
function P.IsTradeskillTrainer()
  return IsTradeskillTrainer ~= nil and try(IsTradeskillTrainer) == true
end

function P.CanGuildRepair() return CanGuildBankRepair ~= nil and try(CanGuildBankRepair) == true end

-- Harita bilgisi (C_Map.GetMapInfo: name, mapType, parentMapID) ya da nil.
function P.MapInfo(id)
  if not (id and C_Map and C_Map.GetMapInfo) then return nil end
  local info = try(C_Map.GetMapInfo, id)
  return type(info) == "table" and info or nil
end

-- "Bolge" haritasi turu (Enum.UIMapType.Zone; yoksa 3).
function P.ZoneMapType()
  return Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
end

-- Lonca bankasindan tamir icin cekilebilecek para (bakir; sinirsizsa math.huge) ya da nil (bilinmiyor).
function P.GuildRepairAllowance()
  if not GetGuildBankWithdrawMoney then return nil end
  local function plain(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return type(v) == "number" and v or nil
  end
  local n = plain(try(GetGuildBankWithdrawMoney))
  if not n then return nil end
  if n < 0 then n = math.huge end
  local bank = GetGuildBankMoney and plain(try(GetGuildBankMoney))
  if bank and bank < n then n = bank end
  return n
end

function P.RepairAll(useGuild)
  if useGuild and P.CanGuildRepair() then
    pcall(RepairAllItems, true)
    return true
  end
  pcall(RepairAllItems)
  return false
end

function P.ZoneText() return (GetZoneText and try(GetZoneText)) or nil end

function P.QuestID() return (GetQuestID and try(GetQuestID)) or nil end

function P.IsShiftDown() return (IsShiftKeyDown and try(IsShiftKeyDown)) or false end

-- Acik artirma arama kutusuna metni yazar ve aramayi baslatir (once Buy/Browse sekmesine gecer). Basarirsa true.
function P.AHSearch(text)
  if type(text) ~= "string" or text == "" then return false end
  local f = _G.AuctionHouseFrame
  local bar = f and f.SearchBar
  if bar and bar.SearchBox and f:IsShown() then
    if f.SetDisplayMode and AuctionHouseFrameDisplayMode and AuctionHouseFrameDisplayMode.Buy then
      pcall(f.SetDisplayMode, f, AuctionHouseFrameDisplayMode.Buy)
    end
    bar.SearchBox:SetText(text)
    if bar.StartSearch then pcall(bar.StartSearch, bar) end
    return true
  end
  local box = _G.BrowseName   -- eski artirma penceresi
  if box and _G.AuctionFrame and _G.AuctionFrame:IsShown() then
    box:SetText(text)
    if AuctionFrameBrowse_Search then pcall(AuctionFrameBrowse_Search) end
    return true
  end
  return false
end

-- Sohbet kutusu acik mi (Shift + tik baglantiyi oraya yazar; o zaman araya girilmez)
function P.ChatInputActive()
  local fn = ChatEdit_GetActiveWindow or (ChatFrameUtil and ChatFrameUtil.GetActiveWindow)
  return fn and try(fn) ~= nil or false
end

-- Battle.net arkadaslari (yalniz kimlik ve gorunen ad): { {bn, name}, ... }. Lonca/arkadas taramasi yok.
function P.BNetFriendList()
  local out = {}
  if not (BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo) then return out end
  for i = 1, tonumber(try(BNGetNumFriends)) or 0 do
    local a = try(C_BattleNet.GetFriendAccountInfo, i)
    local id = type(a) == "table" and P.NotSecret(a.bnetAccountID)
    local name = type(a) == "table" and P.NotSecret(a.accountName)
    if id and type(name) == "string" and name ~= "" then out[#out + 1] = { bn = id, name = name } end
  end
  return out
end

-- Konusulan NPC'nin adi (gossip / quest penceresi acikken) ya da nil.
function P.NpcName()
  local n = UnitName and try(UnitName, "npc")
  n = P.NotSecret(n)
  return type(n) == "string" and n ~= "" and n or nil
end

-- Quest selamlama penceresinde (QUEST_GREETING) verilen ve suren gorevlerin adlari: { [ad] = true }.
function P.GreetingTitles()
  local out = {}
  for i = 1, (GetNumAvailableQuests and try(GetNumAvailableQuests)) or 0 do
    local t = GetAvailableTitle and try(GetAvailableTitle, i)
    if type(t) == "string" then out[t] = true end
  end
  for i = 1, (GetNumActiveQuests and try(GetNumActiveQuests)) or 0 do
    local t = GetActiveTitle and try(GetActiveTitle, i)
    if type(t) == "string" then out[t] = true end
  end
  return out
end

function P.GossipQuests()
  if not (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then return nil end
  local avail = try(C_GossipInfo.GetAvailableQuests) or {}
  local active = (C_GossipInfo.GetActiveQuests and try(C_GossipInfo.GetActiveQuests)) or {}
  return avail, active
end

-- Selamlama penceresi (QUEST_GREETING) satiri tekrarlanan mi / gri mi. Bilinmiyorsa false.
function P.GreetingActiveRepeatable(i)
  local id = GetActiveQuestID and try(GetActiveQuestID, i)
  return id and C_QuestLog and C_QuestLog.IsRepeatableQuest and try(C_QuestLog.IsRepeatableQuest, id) and true or false
end

-- Selamlama penceresi satirinin quest kimligi (yoksa nil): etkin satir GetActiveQuestID, alinabilir satir
-- GetAvailableQuestInfo'nun 5. degeri (yeni istemciler). Ad eslesmesinden guvenilir.
function P.GreetingQuestId(kind, i)
  local id
  if kind == "active" then
    id = GetActiveQuestID and try(GetActiveQuestID, i)
  elseif GetAvailableQuestInfo then
    local ok, _, _, _, _, qid = pcall(GetAvailableQuestInfo, i)
    id = ok and qid or nil
  end
  return type(id) == "number" and id > 0 and id or nil
end

function P.GreetingAvailableGrey(i)
  if not GetAvailableQuestInfo then return false end
  local ok, isTrivial, _, isRepeatable = pcall(GetAvailableQuestInfo, i)
  return ok and (isTrivial or isRepeatable) and true or false
end

function P.SelectGossipQuest(kind, questId)
  local api = C_GossipInfo
  if not api then return end
  local fn = kind == "active" and api.SelectActiveQuest or api.SelectAvailableQuest
  if fn then pcall(fn, questId) end
end

-- Tani: ok neden hesaplanamiyor? Her asamayi ayri raporlar (satir listesi doner).
function P.Diagnose(map, x, y)
  local out = {}
  local function add(t) out[#out + 1] = t end
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
    add("C_Map API missing (GetBestMapForUnit / GetPlayerMapPosition / GetWorldPosFromMapPos)")
    return out
  end
  local playerMap = try(C_Map.GetBestMapForUnit, "player")
  local info = playerMap and try(C_Map.GetMapInfo, playerMap)
  add(("player map: %s (%s)"):format(tostring(playerMap), info and info.name or "?"))
  if not playerMap then return out end
  local px, py = xy(try(C_Map.GetPlayerMapPosition, playerMap, "player"))
  add(("player pos: %s, %s"):format(tostring(px), tostring(py)))
  local c1 = px and world(playerMap, px, py)
  add(("player world continent: %s"):format(tostring(c1)))
  if map then
    local tinfo = try(C_Map.GetMapInfo, map)
    add(("target map: %s (%s) at %s, %s"):format(tostring(map), tinfo and tinfo.name or "?", tostring(x), tostring(y)))
    local c2 = world(map, x, y)
    add(("target world continent: %s"):format(tostring(c2)))
    add(("basis: %s"):format(basis(map) and "ok" or "missing"))
  end
  return out
end

function P.DistanceTo(map, x, y)
  return (P.VectorTo(map, x, y))
end

-- Iki harita noktasi arasi yarda (ayni kitada degilse ya da hesaplanamazsa nil). x, y 0-1.
function P.PointDistance(m1, x1, y1, m2, x2, y2)
  local c1, ax, ay = P.WorldPos(m1, x1, y1)
  local c2, bx, by = P.WorldPos(m2, x2, y2)
  if not (c1 and c2) or c1 ~= c2 then return nil end
  return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
end

-- Harita noktasinin dunya konumu (kita, wx, wy; yarda). Rehber noktalari sabit oldugu icin onbellege alinir:
-- gorev olayi firtinalarinda C_Map tekrar tekrar cagrilmasin (Gorev Beyni). Hesaplanamazsa nil.
local worldCache, worldCacheSize = {}, 0
local resetBasis = P.ResetCache
function P.ResetCache()   -- harita onbellegiyle birlikte dunya konumu onbellegi de
  if resetBasis then resetBasis() end
  worldCache, worldCacheSize = {}, 0
end
function P.WorldPos(map, x, y)
  if not (map and x and y and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local key = map .. ":" .. x .. ":" .. y
  local hit = worldCache[key]
  if hit == nil then
    local c, wx, wy = world(map, x, y)
    hit = c and { c, wx, wy } or false
    worldCacheSize = worldCacheSize + 1
    if worldCacheSize > 5000 then worldCache, worldCacheSize = {}, 1 end
    worldCache[key] = hit
  end
  if not hit then return nil end
  return hit[1], hit[2], hit[3]
end

-- Oyuncunun dunya konumu (onbelleksiz). nil: ic mekan / harita yok.
function P.PlayerWorldPos()
  local map, x, y = P.PlayerMapPosition()
  if not (map and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local c, wx, wy = world(map, x, y)
  if not c then return nil end
  return c, wx, wy
end

-- Esya bekleme suresi: kalan saniye (0 = hazir) ya da nil (bilinmiyor). Ocak tasi icin (6948).
function P.ItemCooldown(itemId)
  local fn = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
  if not fn then return nil end
  local ok, start, duration = pcall(fn, itemId)
  if not ok or type(start) ~= "number" or type(duration) ~= "number" then return nil end
  if (issecretvalue and (issecretvalue(start) or issecretvalue(duration))) then return nil end
  if start == 0 or duration == 0 then return 0 end
  local now = GetTime and GetTime() or 0
  return math.max(0, start + duration - now)
end

-- Ocak tasinin bagli oldugu yerin adi (ornek "Razor Hill") ya da nil.
function P.BindLocation()
  if not GetBindLocation then return nil end
  local name = try(GetBindLocation)
  return type(name) == "string" and name ~= "" and name or nil
end

-- Gorev gunlugu (basliklar haric): { {id, title, complete}, ... }
function P.QuestLogList()
  local out = {}
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for i = 1, try(C_QuestLog.GetNumQuestLogEntries) or 0 do
      local info = try(C_QuestLog.GetInfo, i)
      if type(info) == "table" and not info.isHeader and not info.isHidden and info.questID then
        out[#out + 1] = { id = info.questID, title = info.title, complete = P.IsQuestComplete(info.questID) }
      end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for i = 1, try(GetNumQuestLogEntries) or 0 do
      local ok, title, _, _, isHeader, _, isComplete, _, id = pcall(GetQuestLogTitle, i)
      if ok and title and not isHeader then
        out[#out + 1] = { id = id, title = title, complete = isComplete == 1 or isComplete == true }
      end
    end
  end
  return out
end

-- Izlenen faction: { name, standing (1-8), min, max, value } ya da nil.
function P.WatchedFaction()
  if C_Reputation and C_Reputation.GetWatchedFactionData then
    local d = try(C_Reputation.GetWatchedFactionData)
    if type(d) ~= "table" or not d.name or secret(d.currentStanding) then return nil end
    return { name = d.name, standing = d.reaction, min = d.currentReactionThreshold or 0,
             max = d.nextReactionThreshold or 0, value = d.currentStanding or 0 }
  end
  if not GetWatchedFactionInfo then return nil end
  local ok, name, standing, min, max, value = pcall(GetWatchedFactionInfo)
  if not ok or not name or secret(value) then return nil end
  return { name = name, standing = standing, min = min or 0, max = max or 0, value = value or 0 }
end

function P.StandingLabel(standing) return _G["FACTION_STANDING_LABEL" .. tostring(standing)] end

-- Ammo yuvasindaki (0) mermi/ok sayisi ya da nil (Classic; avci).
function P.AmmoCount()
  if not GetInventoryItemCount then return nil end
  local ok, n = pcall(GetInventoryItemCount, "player", 0)
  return ok and type(n) == "number" and not secret(n) and n or nil
end

-- Bir komuta bagli ilk tus (yoksa nil): GetBindingKey("CLICK ArcanisPathQuestItem:LeftButton")
function P.BindingKey(command)
  if not GetBindingKey then return nil end
  local ok, k = pcall(GetBindingKey, command)
  return ok and type(k) == "string" and k ~= "" and k or nil
end

-- Cagrilmis evcil hayvanin adi (yoksa nil). Evcil yeniden adlandirilmadiysa yaratigin adidir.
function P.PetName()
  if not (UnitExists and UnitName and UnitExists("pet")) then return nil end
  local ok, n = pcall(UnitName, "pet")
  if not ok or secret(n) or type(n) ~= "string" then return nil end
  return n
end

-- Avci peti mutlulugu: 1 unhappy, 2 content, 3 happy; pet yoksa nil.
function P.PetHappiness()
  if not (GetPetHappiness and UnitExists and UnitExists("pet")) then return nil end
  local ok, h = pcall(GetPetHappiness)
  return ok and h or nil
end

function P.BagSlotsTotal()
  local total = 0
  for bag = 0, lastBag() do total = total + (P.ContainerSlots(bag) or 0) end
  return total
end

-- Sunucu saati "13:05" ve yerel saat ya da nil.
function P.ServerTime()
  if not GetGameTime then return nil end
  local ok, h, m = pcall(GetGameTime)
  return ok and h and ("%02d:%02d"):format(h, m) or nil
end
function P.LocalTime() return date and date("%H:%M") or nil end

function P.HasNewMail() return HasNewMail and try(HasNewMail) and true or false end

-- Okunmamis postanin son (en fazla 3) gondereni.
function P.MailSenders()
  if not GetLatestThreeSenders then return {} end
  local ok, a, b, c = pcall(GetLatestThreeSenders)
  local out = {}
  for _, s in ipairs(ok and { a, b, c } or {}) do
    if type(s) == "string" and not secret(s) then out[#out + 1] = s end
  end
  return out
end

-- Fisilti metni ve gonderenin kisa adi; gizli degerse (savas kilidi) nil.
function P.ChatLine(text, sender)
  if type(text) ~= "string" or type(sender) ~= "string" or secret(text, sender) then return nil end
  local name = Ambiguate and try(Ambiguate, sender, "none") or sender
  return text, name
end

-- Mesajlasma (Messenger). Duvar saati: kayitlar oturumlar arasi karsilastirilir (GetTime degil).
function P.Clock() return (time and time()) or 0 end
function P.ClockText(t) return date and t and date("%H:%M", t) or "" end
-- Gun anahtari ("2026-11-05") ve kisa tarih ("05.11.2026"); sohbetteki gun ayiricilari icin.
function P.DayKey(t) return date and t and date("%Y-%m-%d", t) or "" end
function P.DateText(t) return date and t and date("%d.%m.%Y", t) or "" end

-- Olay argumani gizli degerse nil, degilse kendisi.
function P.NotSecret(v) if v == nil or secret(v) then return nil end return v end

-- Fisiltinin sinifi (GUID'den; bilinmiyorsa nil). Gizli degerde nil.
function P.ClassOfGUID(guid)
  if type(guid) ~= "string" or guid == "" or secret(guid) or not GetPlayerInfoByGUID then return nil end
  local _, class = try(GetPlayerInfoByGUID, guid)
  return type(class) == "string" and class or nil
end

-- Sinif rengi (r, g, b) ya da nil.
function P.ClassRGB(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then return c.r, c.g, c.b end
  return nil
end

-- Oyuncunun karakter adi (gizli ya da yoksa "").
function P.PlayerName()
  local n = UnitName and try(UnitName, "player")
  return type(n) == "string" and not secret(n) and n or ""
end

-- Yerel sinif adindan dosya adi (Mage -> MAGE); bilinmiyorsa nil.
local function classToken(localized)
  if type(localized) ~= "string" or secret(localized) then return nil end
  for _, map in ipairs({ LOCALIZED_CLASS_NAMES_MALE or {}, LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
    for token, n in pairs(map) do if n == localized then return token end end
  end
  return nil
end

-- Fisilti kutusu icin kisiler: oyun arkadaslari, Battle.net arkadaslari, lonca uyeleri.
-- { name, label, sub, match, class, online, kind = "friend"|"bn"|"guild", bn }
function P.WhisperContacts()
  local out = {}
  local function str(v) v = P.NotSecret(v); return type(v) == "string" and v ~= "" and v or nil end
  if C_FriendList and C_FriendList.GetNumFriends then
    for i = 1, tonumber(try(C_FriendList.GetNumFriends)) or 0 do
      local info = try(C_FriendList.GetFriendInfoByIndex, i)
      local name = type(info) == "table" and str(info.name)
      if name then
        out[#out + 1] = { name = name, label = name, match = name, kind = "friend",
          online = info.connected == true, class = classToken(info.className) }
      end
    end
  end
  if BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
    for i = 1, tonumber(try(BNGetNumFriends)) or 0 do
      local a = try(C_BattleNet.GetFriendAccountInfo, i)
      local id = type(a) == "table" and P.NotSecret(a.bnetAccountID)
      if id then
        local g = type(a.gameAccountInfo) == "table" and a.gameAccountInfo or {}
        local tag = str(a.battleTag)
        tag = tag and tag:match("^[^#]+") or nil
        local char = str(g.characterName)
        local label = str(a.accountName) or tag
        if label then
          out[#out + 1] = { name = label, label = label, sub = char, match = (tag or "") .. " " .. (char or ""),
            kind = "bn", bn = id, online = g.isOnline == true, class = str(g.classFilename) }
        end
      end
    end
  end
  if IsInGuild and GetNumGuildMembers and GetGuildRosterInfo and try(IsInGuild) then
    for i = 1, tonumber(try(GetNumGuildMembers)) or 0 do
      local ok, name, _, _, _, _, _, _, _, online, _, class = pcall(GetGuildRosterInfo, i)
      name = ok and str(name)
      if name then
        out[#out + 1] = { name = name, label = (name:gsub("%-.*$", "")), match = name, kind = "guild",
          online = P.NotSecret(online) and true or false, class = str(class) }
      end
    end
  end
  return out
end

-- Battle.net arkadasinin gorunur bilgisi: { tag = BattleTag adi (#'siz), char = oyundaki karakter, class }; yoksa nil.
function P.BNetFriend(id)
  if not (id and C_BattleNet and C_BattleNet.GetAccountInfoByID) then return nil end
  local a = try(C_BattleNet.GetAccountInfoByID, id)
  if type(a) ~= "table" then return nil end
  local function str(v) v = P.NotSecret(v); return type(v) == "string" and v ~= "" and v or nil end
  local g = type(a.gameAccountInfo) == "table" and a.gameAccountInfo or {}
  local tag = str(a.battleTag)
  -- full: tam BattleTag (oturumdan bagimsiz kimlik; Battle.net konusmasini kaydetmek icin)
  return { tag = tag and tag:match("^[^#]+") or nil, full = tag, char = str(g.characterName), class = str(g.classFilename) }
end

-- Fisilti gonder: karakter adina ya da Battle.net hesap kimligine (bnID). Basarida true.
-- Sohbet gonderme korumali degil; savasta da calisir. Bos / gizli metin gonderilmez.
P.CHAT_MAX = 255
function P.SendWhisper(target, text, bnID)
  if type(text) ~= "string" or text == "" or secret(text) then return false end
  if bnID then
    if not BNSendWhisper then return false end
    return (pcall(BNSendWhisper, bnID, text))
  end
  if type(target) ~= "string" or target == "" then return false end
  if C_ChatInfo and C_ChatInfo.SendChatMessage then
    return (pcall(C_ChatInfo.SendChatMessage, text, "WHISPER", nil, target))
  end
  if SendChatMessage then return (pcall(SendChatMessage, text, "WHISPER", nil, target)) end
  return false
end

-- Shift + esya/buyu tiklamasinin linki (oyunun sohbet kutusuna eklenirken) fn(link) ile de bildirilir.
function P.HookInsertLink(fn)
  if hooksecurefunc and ChatEdit_InsertLink and type(fn) == "function" then
    pcall(hooksecurefunc, "ChatEdit_InsertLink", function(link) if type(link) == "string" then pcall(fn, link) end end)
  end
end

function P.IsGhost() return UnitIsGhost and UnitIsGhost("player") and true or false end

local CONTINENT_MAP = { [0] = 1415, [1] = 1414 }   -- Forever kita haritalari

-- Oyunun zindan giris isaretleri (dunya haritasindaki kapi ikonlari): { { name, id (journalInstanceID), x, y 0-1 } }
-- ya da {} (API yok, bos, gizli deger).
function P.DungeonEntrances(map)
  local out = {}
  local fn = map and C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap
  local list = fn and try(fn, map)
  if type(list) ~= "table" then return out end
  for _, e in ipairs(list) do
    local x, y = xy(e.position)
    if x and not secret(x, y) and type(e.name) == "string" and not secret(e.name) then
      out[#out + 1] = { name = e.name, id = e.journalInstanceID, x = x, y = y }
    end
  end
  return out
end

function P.ContinentMap(c) return CONTINENT_MAP[c] end

-- Oyunun kendi harita isareti (Ctrl + tik / harita linki): map, x, y (0-1) ya da nil.
function P.UserWaypoint()
  if not (C_Map and C_Map.HasUserWaypoint and C_Map.GetUserWaypoint) or not try(C_Map.HasUserWaypoint) then return nil end
  local p = try(C_Map.GetUserWaypoint)
  local x, y = xy(p and p.position)
  if not (p and p.uiMapID and x) or secret(x, y) then return nil end
  return p.uiMapID, x, y
end

function P.ClearUserWaypoint()
  if C_Map and C_Map.ClearUserWaypoint then try(C_Map.ClearUserWaypoint) end
end

-- Ceset konumu (map, x, y 0-1) ya da nil (olunce bir an sonra gelir). Once kita haritasinda: hayalet baska
-- bolgedeki mezarliktan cikinca bolge haritasindaki konum 0-1 disina tasar ve dunya konumuna cevrilemez (ok "No
-- position here" der); kita haritasi bilinmiyorsa (adalar) oyuncunun haritasi.
function P.CorpsePosition()
  local map = P.PlayerMapPosition()
  if not (map and C_DeathInfo and C_DeathInfo.GetCorpseMapPosition) then return nil end
  local c = P.PlayerWorldPos()
  for _, m in ipairs({ c and CONTINENT_MAP[c] or map, map }) do
    local pos = try(C_DeathInfo.GetCorpseMapPosition, m)
    local x, y = xy(pos)   -- "pos and xy(pos)" yalniz x'i dondururdu: y hep nil kalirdi
    if x and not secret(x, y) and x > 0 and x < 1 and y > 0 and y < 1 then return m, x, y end
  end
  return nil
end

-- Dunya noktasinin (kita, yard) bolge adi: kita haritasinda o noktadaki bolge.
function P.ZoneAtWorld(c, wx, wy)
  local cm = CONTINENT_MAP[c]
  if not (cm and C_Map and C_Map.GetMapPosFromWorldPos and C_Map.GetMapInfoAtPosition and CreateVector2D) then return nil end
  local ok, _, pos = pcall(C_Map.GetMapPosFromWorldPos, c, CreateVector2D(wx, wy), cm)
  local x, y = xy(ok and pos or nil)
  if not x then return nil end
  local info = try(C_Map.GetMapInfoAtPosition, cm, x, y)
  return type(info) == "table" and info.mapID ~= cm and info.name or nil
end

-- Dunya noktasinin kita haritasindaki yeri (harita, x, y; 0-1) ya da nil: ok hedefi icin (iskele).
function P.ContinentMapPos(c, wx, wy)
  local cm = CONTINENT_MAP[c]
  if not (cm and C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
  local ok, _, pos = pcall(C_Map.GetMapPosFromWorldPos, c, CreateVector2D(wx, wy), cm)
  local x, y = xy(ok and pos or nil)
  if not x or secret(x, y) then return nil end
  return cm, x, y
end

-- Sunucu saati (sn); gemi/zeplin donemleri buna baglanir.
function P.ServerNow() return GetServerTime and try(GetServerTime) or nil end

function P.ItemName(itemId)
  local d = P.ItemDetails(itemId)
  return d and d.name or nil
end

-- Acik ucus haritasindaki noktalar: { {name, state = "current"|"reachable"|"none", c, wx, wy, map, x, y}, ... }
-- ya da {} (map/x/y: kita haritasinda, ok hedefi icin).
-- Yalniz TAXIMAP_OPENED sirasinda dolu. Konum ucus haritasinin (kita) koordinatindan dunya konumuna cevrilir.
function P.TaxiNodes()
  local out = {}
  local mapId = GetTaxiMapID and try(GetTaxiMapID)
  local function add(name, state, x, y)
    local c, wx, wy
    if mapId and x and y and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then c, wx, wy = world(mapId, x, y) end
    if type(name) == "string" and c then
      out[#out + 1] = { name = name, state = state, c = c, wx = wx, wy = wy, map = mapId, x = x, y = y }
    end
  end
  if C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and mapId then
    local STATES = { [0] = "current", [1] = "reachable" }   -- Enum.FlightPathState
    for _, n in ipairs(try(C_TaxiMap.GetAllTaxiNodes, mapId) or {}) do
      local x, y = xy(n.position)
      add(n.name, STATES[n.state] or "none", x, y)
    end
    if #out > 0 then return out end
  end
  if NumTaxiNodes and TaxiNodeName and TaxiNodePosition then
    for i = 1, (try(NumTaxiNodes) or 0) do
      local t = TaxiNodeGetType and try(TaxiNodeGetType, i)
      local x, y = try(TaxiNodePosition, i)
      add(try(TaxiNodeName, i), (t == "CURRENT" and "current") or (t == "REACHABLE" and "reachable") or "none", x, y)
    end
  end
  return out
end

-- Acik ucus haritasinda adi verilen noktanin cercevesi (eski TaxiFrame dugmesi ya da FlightMapFrame pini) ya da nil.
-- Ad tam ya da virgulden onceki kismi eslesir ("Sentinel Hill" = "Sentinel Hill, Westfall").
local function sameNode(a, b)
  if type(a) ~= "string" or type(b) ~= "string" then return false end
  a, b = a:lower(), b:lower()
  return a == b or a:match("^([^,]+)") == b:match("^([^,]+)")
end
-- Acik ucus haritasinin nokta cerceveleri: { { frame, name }, ... } (FlightMapFrame pinleri ya da eski TaxiButton'lar).
function P.TaxiNodeFrames()
  local out = {}
  local fm = _G.FlightMapFrame
  if fm and fm.IsShown and fm:IsShown() and fm.EnumerateAllPins then
    local ok, iter = pcall(fm.EnumerateAllPins, fm)
    if ok and iter then
      for pin in iter do
        local d = pin.taxiNodeData
        if d and type(d.name) == "string" then out[#out + 1] = { frame = pin, name = d.name } end
      end
    end
  end
  if #out == 0 and NumTaxiNodes and TaxiNodeName then
    for i = 1, (try(NumTaxiNodes) or 0) do
      local b = _G["TaxiButton" .. i]
      local name = b and b.IsShown and b:IsShown() and try(TaxiNodeName, b.GetID and b:GetID() or i)
      if type(name) == "string" then out[#out + 1] = { frame = b, name = name } end
    end
  end
  return out
end

-- Ad once nokta adiyla, yoksa bolge adiyla (virgulden sonrasi) eslesir: rehber "Redridge" der, nokta
-- "Lakeshire, Redridge" (sahibin bulgusu, 15 Kasim 2026: hedef parlamiyordu). Bolgede tek nokta varsa o.
local function zoneOf(a) return type(a) == "string" and a:lower():match(",%s*(.-)%s*$") or nil end
function P.TaxiNodeFrame(name)
  if not name then return nil end
  local nodes = P.TaxiNodeFrames()
  for _, n in ipairs(nodes) do
    if sameNode(n.name, name) then return n.frame end
  end
  local want, hit = name:lower(), nil
  for _, n in ipairs(nodes) do
    if zoneOf(n.name) == want then
      if hit then return nil end   -- bolgede birden cok nokta: belirsiz, parlatilmaz
      hit = n.frame
    end
  end
  return hit
end

-- Konusulan NPC'nin ucus secenegi (gossip, taksi ikonu) kimligi ya da nil; secince ucus haritasi acilir.
local TAXI_ICON = 132057   -- Interface/GossipFrame/TaxiGossipIcon
function P.GossipTaxiOption()
  if not (C_GossipInfo and C_GossipInfo.GetOptions) then return nil end
  for _, o in ipairs(try(C_GossipInfo.GetOptions) or {}) do
    if type(o) == "table" and o.gossipOptionID and (o.icon == TAXI_ICON or o.overrideIconID == TAXI_ICON) then
      return o.gossipOptionID
    end
  end
  return nil
end

function P.SelectGossipOption(id)
  if id and C_GossipInfo and C_GossipInfo.SelectOption then pcall(C_GossipInfo.SelectOption, id) end
end

-- Acik meslek penceresinin tarifleri: meslek adi ve { {id, name, diff, made, reagents = {{id, count}}}, ... }.
-- Yalniz esya ureten tarifler (Enchanting'in Craft penceresi esya vermez). Esya bilgisi onbellekte degilse o tarif
-- atlanir; pencere guncellendikce (TRADE_SKILL_UPDATE) yeniden okunur. Pencere kapaliysa nil, {}.
function P.TradeSkillRecipes()
  local out = {}
  local line, rank
  if GetTradeSkillLine then line, rank = try(GetTradeSkillLine) end
  if type(line) ~= "string" or line == "" or line == "UNKNOWN" or not GetNumTradeSkills then return nil, out end
  for i = 1, (try(GetNumTradeSkills) or 0) do
    local name, kind = try(GetTradeSkillInfo, i)
    local id = name and kind ~= "header" and GetTradeSkillItemLink and P.ItemIdFromLink(try(GetTradeSkillItemLink, i))
    if id then
      local lo, hi = 1, 1
      if GetTradeSkillNumMade then lo, hi = try(GetTradeSkillNumMade, i) end
      lo = tonumber(lo) or 1
      local r = { id = id, name = name, diff = kind, made = (lo + (tonumber(hi) or lo)) / 2, reagents = {} }
      for k = 1, (GetTradeSkillNumReagents and try(GetTradeSkillNumReagents, i) or 0) do
        local _, _, count = try(GetTradeSkillReagentInfo, i, k)
        local rid = GetTradeSkillReagentItemLink and P.ItemIdFromLink(try(GetTradeSkillReagentItemLink, i, k))
        if not (rid and tonumber(count)) then r = nil break end
        r.reagents[#r.reagents + 1] = { id = rid, count = tonumber(count) }
      end
      if r then out[#out + 1] = r end
    end
  end
  return line, out, tonumber(rank)
end

-- Ucus secilince fn(hedefAdi) cagrilir (korumasiz kanca; ucusu baslatmaz). Bir kez kurulur.
local taxiHooks
function P.OnTakeTaxi(fn)
  if not taxiHooks then
    taxiHooks = {}
    if hooksecurefunc and TakeTaxiNode then
      hooksecurefunc("TakeTaxiNode", function(i)
        local to = TaxiNodeName and try(TaxiNodeName, i)
        for _, f in ipairs(taxiHooks) do pcall(f, to) end
      end)
    end
  end
  taxiHooks[#taxiHooks + 1] = fn
end

-- Oyuncunun bulundugu alt bolge adi (ucus noktasi adi icin yedek).
function P.SubZoneText()
  local fn = GetSubZoneText or GetMinimapZoneText
  local name = fn and try(fn)
  if type(name) ~= "string" or name == "" then name = GetZoneText and try(GetZoneText) end
  return type(name) == "string" and name ~= "" and name or nil
end

-- Iki dunya noktasi arasi yarda; farkli kita ya da eksik konumda nil.
function P.WorldDistance(c1, x1, y1, c2, x2, y2)
  if not (c1 and c2 and x1 and x2) or c1 ~= c2 then return nil end
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

-- Oyuncunun baktigi yon: radyan, kuzeyden saat yonunun tersine (0 = kuzey). Yoksa nil.
function P.Facing()
  if GetPlayerFacing then return try(GetPlayerFacing) end
  return nil
end


-- Ekipman puanlama (Helpers/Gear.lua) ve odul secimi (Helpers/QuestAuto.lua) icin eklenen sarmalayicilar.
-- Hepsi varlik kontrolu + pcall kullanir; gizli (secret) degerler nil olarak doner.
local function clean(v)
  if v == nil then return nil end
  if issecretvalue then
    local ok, secret = pcall(issecretvalue, v)
    if not ok or secret then return nil end
  end
  return v
end
P.Clean = clean

-- Ipucunun gosterdigi birim bir NPC ise adi (oyuncu, gizli deger ya da birimsiz ipucu: nil).
function P.TooltipNpcName(tt)
  local ok, name = pcall(function()
    if not (tt and tt.GetUnit) then return nil end
    local n, unit = tt:GetUnit()
    n, unit = clean(n), clean(unit)
    if not unit or (UnitIsPlayer and clean(UnitIsPlayer(unit))) then return nil end
    return type(n) == "string" and n ~= "" and n or nil
  end)
  return ok and name or nil
end

-- Birim rare mi: { id (NPC), name, level, elite } ya da nil (rare degil, oyuncu, gizli deger).
function P.UnitRare(unit)
  local ok, r = pcall(function()
    if not (UnitExists and UnitExists(unit)) then return nil end
    if UnitIsPlayer and clean(UnitIsPlayer(unit)) then return nil end
    local class = clean(UnitClassification and UnitClassification(unit))
    if class ~= "rare" and class ~= "rareelite" then return nil end
    local guid = clean(UnitGUID and UnitGUID(unit))
    local id = type(guid) == "string" and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)")) or nil
    if not id then return nil end
    local name = clean(UnitName and UnitName(unit))
    local level = clean(UnitLevel and UnitLevel(unit))
    return { id = id, name = type(name) == "string" and name or nil,
      level = type(level) == "number" and level > 0 and level or nil, elite = class == "rareelite" }
  end)
  return ok and r or nil
end

-- Birim karsi taraftan bir oyuncu mu: { guid, name, class (token), className (oyunun dilinde), level (nil = "??"),
-- dead } ya da nil (oyuncu degil, ayni taraf, dost, gizli deger).
function P.EnemyPlayer(unit)
  local ok, r = pcall(function()
    if not (UnitExists and UnitExists(unit)) then return nil end
    if not (UnitIsPlayer and clean(UnitIsPlayer(unit))) then return nil end
    local mine = clean(UnitFactionGroup and UnitFactionGroup("player"))
    local theirs = clean(UnitFactionGroup and UnitFactionGroup(unit))
    if not (mine and theirs) or mine == theirs or theirs == "Neutral" then return nil end
    -- bana saldiramayan (goblin kasabasi / sanctuary, PvP bayragi kapali) dusman tehdit degil: uyari bosuna gelmesin
    if UnitCanAttack and clean(UnitCanAttack(unit, "player")) == false then return nil end
    local guid = clean(UnitGUID and UnitGUID(unit))
    if type(guid) ~= "string" then return nil end
    local className, class = UnitClass(unit)
    className, class = clean(className), clean(class)
    local level = clean(UnitLevel and UnitLevel(unit))
    local name = clean(UnitName and UnitName(unit))
    local dead = clean(UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))
    return { guid = guid, name = type(name) == "string" and name or "?", class = class, className = className,
      level = (type(level) == "number" and level > 0) and level or nil, dead = dead and true or false }
  end)
  return ok and r or nil
end

-- Sinif rengi "ffrrggbb" (bilinmiyorsa nil).
function P.ClassColorHex(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if not c then return nil end
  if c.colorStr then return c.colorStr end
  return ("ff%02x%02x%02x"):format(math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
end

-- Oyunun ses kitinden ses calar (ad SOUNDKIT'te yoksa sayi). Doner: calindi mi.
function P.PlaySoundKit(name, fallback)
  if not PlaySound then return false end
  local id = (SOUNDKIT and name and SOUNDKIT[name]) or fallback
  if not id then return false end
  return (pcall(PlaySound, id, "Master"))
end

local function num(v)
  v = clean(v)
  return type(v) == "number" and v or nil
end

-- Yetenek agaclari: { { name, points }, ... } (sekme sirasiyla) ya da nil.
-- Puanlar GetTalentInfo rutbelerinin toplamidir (GetTalentTabInfo donus sirasi istemciye gore degisir).
function P.TalentTabs()
  local RF = rfTalents()
  if RF and RF.TalentPoints and not GetNumTalentTabs then
    -- Forever: tek trait agaci, RotationForge uc bolume ayirir (adlar yok)
    return { { points = RF.TalentPoints(1) }, { points = RF.TalentPoints(2) }, { points = RF.TalentPoints(3) } }
  end
  if not GetNumTalentTabs then return nil end
  local tabs = num(try(GetNumTalentTabs)) or 0
  if tabs <= 0 then return nil end
  local out = {}
  for tab = 1, tabs do out[tab] = { points = 0 } end
  if GetTalentTabInfo then
    for tab = 1, tabs do
      local r = { pcall(GetTalentTabInfo, tab) }
      if r[1] then
        -- ad: ilk metin donusu (Classic: name, ...; yeni istemci: id, name, ...)
        for i = 2, #r do
          local v = clean(r[i])
          if type(v) == "string" and v ~= "" then out[tab].name = v break end
        end
      end
    end
  end
  local list = P.TalentList and P.TalentList()
  if type(list) == "table" then
    for _, t in ipairs(list) do
      local e = t.tab and out[t.tab]
      local rank = num(t.rank)
      if e and rank then e.points = e.points + rank end
    end
  end
  return out
end

-- Retail tarzi istemcide secili uzmanligin kimligi (SpecID) ya da nil.
function P.ActiveSpecID()
  if not (GetSpecialization and GetSpecializationInfo) then return nil end
  local index = num(try(GetSpecialization))
  if not index or index <= 0 then return nil end
  return num(try(GetSpecializationInfo, index))
end

-- Cift silah: oyunun bilgisi; API yoksa nil (Gear sinif/seviyeye gore tahmin eder).
function P.CanDualWield()
  if not CanDualWield then return nil end
  local v = clean(try(CanDualWield))
  if v == nil then return nil end
  return v and true or false
end

-- Baglantidan esya ayrintilari: rastgele ek ("of the Bear") statlari dahil. ItemDetails tablosu ya da nil.
function P.ItemDetailsFromLink(link)
  local id = P.ItemIdFromLink(link)
  if not id then return nil end
  local d = P.ItemDetails(id)
  if not d then return nil end
  if type(link) == "string" and link:find("|H", 1, true) then
    local statsFn = (C_Item and C_Item.GetItemStats) or GetItemStats
    if statsFn then
      local ok, t = pcall(statsFn, link)
      if ok and type(t) == "table" and next(t) then d.stats = t end
    end
    d.link = link
  end
  return d
end

-- Takili esya (baglantidan, rastgele ekler dahil) -> ayrinti tablosu, baglanti.
function P.EquippedItemFull(slotId)
  if not (GetInventoryItemLink and slotId) then return nil end
  local ok, link = pcall(GetInventoryItemLink, "player", slotId)
  link = ok and clean(link) or nil
  if not link then return nil end
  return P.ItemDetailsFromLink(link), link
end

-- Takili esyanin kimligi (ucuz: statlar okunmaz; set parcasi saymak icin) ya da nil.
function P.EquippedItemId(slotId)
  if not (GetInventoryItemID and slotId) then return nil end
  local id = clean(try(GetInventoryItemID, "player", slotId))
  return type(id) == "number" and id or nil
end

-- Takili esyanin buyu (enchant) kimligi, baglantidan (0 = yok) ya da nil (yuva bos).
function P.EquippedEnchant(slotId)
  if not (GetInventoryItemLink and slotId) then return nil end
  local link = clean(try(GetInventoryItemLink, "player", slotId))
  if type(link) ~= "string" then return nil end
  return tonumber(link:match("item:%d+:(%d*)")) or 0
end

-- Birimin yaratik turu (oyunun dilinde: "Undead"...) ve sinifi ("elite", "worldboss"...); oyuncu ya da gizli deger: nil.
function P.UnitCreatureInfo(unit)
  if not (UnitExists and UnitExists(unit)) or (UnitIsPlayer and clean(try(UnitIsPlayer, unit))) then return nil end
  local name = clean(UnitName and try(UnitName, unit))
  if type(name) ~= "string" then return nil end
  local kind = clean(UnitCreatureType and try(UnitCreatureType, unit))
  local class = clean(UnitClassification and try(UnitClassification, unit))
  return { name = name, type = type(kind) == "string" and kind or nil, class = type(class) == "string" and class or nil }
end

-- Acik saticinin itibar isteyen esyalari, oyunun ipucundan ("Requires <taraf> - <seviye>", ITEM_REQ_REPUTATION
-- kalibi, her dilde): { { id, faction, standing, price } }; pencere kapali ya da API yoksa bos.
function P.MerchantRepItems()
  local out = {}
  if not (GetMerchantNumItems and GetMerchantItemLink and C_TooltipInfo and C_TooltipInfo.GetMerchantItem) then return out end
  local tmpl = type(ITEM_REQ_REPUTATION) == "string" and ITEM_REQ_REPUTATION or "Requires %s - %s"
  local pat = "^" .. tmpl:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0"):gsub("%%s", "(.-)") .. "$"
  for i = 1, (tonumber((try(GetMerchantNumItems))) or 0) do
    local id = P.ItemIdFromLink(clean(try(GetMerchantItemLink, i)))
    local data = id and try(C_TooltipInfo.GetMerchantItem, i)
    for _, line in ipairs(type(data) == "table" and type(data.lines) == "table" and data.lines or {}) do
      local text = clean(line.leftText)
      local fac, standing
      if type(text) == "string" then fac, standing = text:match(pat) end
      if fac and fac ~= "" then
        local info = C_MerchantFrame and C_MerchantFrame.GetItemInfo and try(C_MerchantFrame.GetItemInfo, i)
        local price = type(info) == "table" and clean(info.price) or nil
        out[#out + 1] = { id = id, faction = fac, standing = standing, price = type(price) == "number" and price or nil }
        break
      end
    end
  end
  return out
end

-- Esyayi giydirir (yalniz tiklamadan, savas disinda). Baglanma onayi gerekiyorsa oyun kendi penceresini acar.
function P.EquipItem(link, slotId)
  if P.InCombat() then return false end
  local fn = (C_Item and C_Item.EquipItemByName) or EquipItemByName
  return fn ~= nil and pcall(fn, link, slotId) or false
end

-- Esya ipucundan statlar: GetItemStats'in vermedigi "Equip:" satirlari, silah DPS'i, zirh. Yalniz C_TooltipInfo varsa.
-- Dondurur: { crit, hit, spellcrit, spellhit, sp, heal, mp5, ap, rap, defense, dps, armor } (bulunanlar) ya da nil.
-- "Equip:" desenleri Ingilizce istemci metnine gore; DPS ve zirh oyunun kendi sablonundan (her dilde) okunur.
local tipCache, tipCacheSize, TIP_CACHE_MAX = {}, 0, 500
local function templatePattern(tmpl)
  if type(tmpl) ~= "string" then return nil end
  local p = tmpl:gsub("[%%%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
  p = p:gsub("%%%%s", "([%%d%%.,]+)"):gsub("%%%%d", "(%%d+)")
  return p
end
local EQUIP_PATTERNS = {
  { "critical strike with spells by (%d+)%%", "spellcrit" },
  { "chance to hit with spells by (%d+)%%", "spellhit" },
  { "critical strike by (%d+)%%", "crit" },
  { "chance to hit by (%d+)%%", "hit" },
  { "damage and healing done by magical spells and effects by up to (%d+)", "sp", "heal" },
  { "healing done by spells and effects by up to (%d+)", "heal" },
  { "damage done by %a+ spells and effects by up to (%d+)", "sp" },
  { "(%d+) mana per 5 sec", "mp5" },
  { "^%+?(%d+) ranged attack power", "rap" },
  { "^%+?(%d+) attack power", "ap" },
  { "defense %+(%d+)", "defense" },
}
function P.ItemExtraStats(link)
  if type(link) ~= "string" then return nil end
  if tipCache[link] ~= nil then return tipCache[link] or nil end
  if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
  local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
  if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
  local out, found = {}, false
  local dpsPat = templatePattern(DPS_TEMPLATE) or "%(([%d%.,]+) damage per second%)"
  local armorPat = templatePattern(ARMOR_TEMPLATE) or "^([%d,]+) Armor"
  for _, line in ipairs(data.lines) do
    local text = type(line) == "table" and clean(line.leftText) or nil
    if type(text) == "string" then
      local lower = text:lower()
      local dps = text:match(dpsPat)
      if dps then out.dps = tonumber((dps:gsub(",", "."))); found = true end
      local armor = not out.armor and text:match(armorPat)
      if armor then out.armor = tonumber((armor:gsub("[,%.]", ""))); found = true end
      for _, p in ipairs(EQUIP_PATTERNS) do
        local v = tonumber(lower:match(p[1]))
        if v then
          out[p[2]] = (out[p[2]] or 0) + v
          if p[3] then out[p[3]] = (out[p[3]] or 0) + v end
          found = true
          break
        end
      end
    end
  end
  -- rastgele ekli ("of the Bear") baglantilar oturum boyunca birikir: sinira gelince bastan baslat
  tipCacheSize = tipCacheSize + 1
  if tipCacheSize > TIP_CACHE_MAX then tipCache, tipCacheSize = {}, 1 end
  tipCache[link] = found and out or false
  return found and out or nil
end

-- Esya alt sinif adi (oyunun dilinde), ornek (4, 3) -> "Mail". Yoksa nil.
function P.ItemSubClassName(classId, subClassId)
  local fn = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo
  if not (fn and classId and subClassId) then return nil end
  local ok, name = pcall(fn, classId, subClassId)
  name = ok and clean(name) or nil
  return type(name) == "string" and name or nil
end

-- Sistem: kare hizi, gecikme (ev / dunya, ms), tum eklentilerin Lua bellegi (KB; ucuz, collectgarbage).
function P.SystemStats()
  local fps = GetFramerate and num(try(GetFramerate)) or nil
  local home, world
  if GetNetStats then
    local ok, _, _, h, w = pcall(GetNetStats)
    if ok then home, world = num(h), num(w) end
  end
  return { fps = fps, home = home, world = world, luaKB = collectgarbage and collectgarbage("count") or nil }
end

-- Bu eklentinin bellegi (KB). UpdateAddOnMemoryUsage pahalidir: yalniz hub acikken, seyrek cagrilir.
function P.AddonMemoryKB(name)
  -- Forever belgelerinde C_AddOns surumu yok; eski global adlar (yoksa nil)
  if not (UpdateAddOnMemoryUsage and GetAddOnMemoryUsage) then return nil end
  pcall(UpdateAddOnMemoryUsage)
  return num(try(GetAddOnMemoryUsage, name))
end


-- Karakter statlari (karakter penceresindeki degerler). Okunamayan ya da gizli deger nil kalir.
function P.PlayerStatBlock()
  local s = {}
  if UnitStat then
    local keys = { "str", "agi", "sta", "int", "spi" }
    for i = 1, 5 do
      local ok, _, effective = pcall(UnitStat, "player", i)
      if ok then s[keys[i]] = num(effective) end
    end
  end
  local function power(fn)
    if not fn then return nil end
    local ok, base, pos, neg = pcall(fn, "player")
    if not ok then return nil end
    base, pos, neg = num(base), num(pos) or 0, num(neg) or 0
    if not base then return nil end
    return base + pos + neg
  end
  s.ap = power(UnitAttackPower)
  s.rap = power(UnitRangedAttackPower)
  if GetCritChance then s.crit = num(try(GetCritChance)) end
  if GetRangedCritChance then s.rangedCrit = num(try(GetRangedCritChance)) end
  local function bestSchool(fn)
    local best
    for school = 2, 7 do
      local v = num(try(fn, school))
      if v and (not best or v > best) then best = v end
    end
    return best
  end
  if GetSpellCritChance then s.spellCrit = bestSchool(GetSpellCritChance) end
  if GetSpellBonusDamage then s.spellDamage = bestSchool(GetSpellBonusDamage) end
  if GetSpellBonusHealing then s.healing = num(try(GetSpellBonusHealing)) end
  if GetHitModifier then s.hit = num(try(GetHitModifier)) end
  if GetSpellHitModifier then s.spellHit = num(try(GetSpellHitModifier)) end
  if UnitArmor then
    local ok, _, effective = pcall(UnitArmor, "player")
    if ok then s.armor = num(effective) end
  end
  if GetManaRegen then
    local ok, base, casting = pcall(GetManaRegen)
    if ok then
      base, casting = num(base), num(casting)
      if base then s.manaRegen = base * 5 end           -- 5 saniyede, buyu yapmazken
      if casting then s.manaRegenCasting = casting * 5 end
    end
  end
  if UnitHealthMax then s.health = num(try(UnitHealthMax, "player")) end
  if UnitPowerMax then s.mana = num(try(UnitPowerMax, "player", 0)) end
  return s
end

-- Gorev odul penceresi: secilebilir odul sayisi, odul baglantisi, odul dugmesi (cerceve; yoksa nil).
function P.QuestChoiceCount()
  if not GetNumQuestChoices then return 0 end
  return num(try(GetNumQuestChoices)) or 0
end

function P.QuestChoiceLink(index)
  if not GetQuestItemLink then return nil end
  return clean(try(GetQuestItemLink, "choice", index))
end

-- Gorev penceresindeki sabit (secimsiz) oduller
function P.QuestRewardCount()
  if not GetNumQuestRewards then return 0 end
  return num(try(GetNumQuestRewards)) or 0
end

function P.QuestRewardLink(index)
  if not GetQuestItemLink then return nil end
  return clean(try(GetQuestItemLink, "reward", index))
end

-- Grup loot zarindaki esyanin baglantisi
function P.LootRollLink(rollId)
  if not (GetLootRollItemLink and rollId) then return nil end
  return clean(try(GetLootRollItemLink, rollId))
end

-- Anahtarlik (eski istemcide canta -2): esya orada mi? Sayaca (ItemCount) girmeyebilir.
function P.KeyringHas(itemId)
  local bag = KEYRING_CONTAINER
  if not (bag and itemId) then return false end
  for slot = 1, P.ContainerSlots(bag) do
    local it = P.ContainerItem(bag, slot)
    if it and it.id == itemId then return true end
  end
  return false
end

-- ===== Sinif egitimi, pet, toplama izi, satici (Helpers/Training.lua, Helpers/PetTeach.lua, ProfActivity, Gold) =====

-- Aksiyon yuvasindaki buyu kimligi (yuva bos / makro / esya: nil).
function P.ActionSpell(slot)
  if not GetActionInfo then return nil end
  local ok, kind, id = pcall(GetActionInfo, slot)
  if not ok or kind ~= "spell" or type(id) ~= "number" or secret(id) then return nil end
  return id
end

-- Buyuyu aksiyon yuvasina koy (eski rutbenin yerine). Savasta yapilmaz: false. Yuvadaki eski buyu imlece gelir, silinir.
function P.PlaceSpell(slot, id)
  if P.InLockdown() or not PlaceAction then return false end
  local pick = (C_Spell and C_Spell.PickupSpell) or PickupSpell
  if not pick then return false end
  if ClearCursor then ClearCursor() end
  local ok = pcall(pick, id) and pcall(PlaceAction, slot)
  if ClearCursor then ClearCursor() end
  return ok and true or false
end

-- Cagrilmis petin yetenek rutbeleri: { [ad] = en yuksek rutbe } (pet yok / API yok: bos tablo).
function P.PetSpellRanks()
  local out = {}
  if not (C_SpellBook and C_SpellBook.HasPetSpells and C_SpellBook.GetSpellBookItemName and Enum and Enum.SpellBookSpellBank) then
    return out
  end
  local n = tonumber((try(C_SpellBook.HasPetSpells))) or 0
  for i = 1, n do
    local ok, name, sub = pcall(C_SpellBook.GetSpellBookItemName, i, Enum.SpellBookSpellBank.Pet)
    if ok and type(name) == "string" and not secret(name, sub) then
      local rank = type(sub) == "string" and tonumber(sub:match("(%d+)")) or 1
      if rank > (out[name] or 0) then out[name] = rank end
    end
  end
  return out
end

-- Cagrilmis petin ailesi (Ingilizce istemcide "Wolf"...) ya da nil.
function P.PetFamily()
  if not (UnitCreatureFamily and UnitExists and UnitExists("pet")) then return nil end
  local ok, name = pcall(UnitCreatureFamily, "pet")
  return ok and type(name) == "string" and not secret(name) and name or nil
end

-- Birimin NPC kimligi (GUID'den) ya da nil (oyuncu, gizli deger).
function P.UnitNpcId(unit)
  if not (UnitExists and UnitExists(unit) and UnitGUID) then return nil end
  local ok, guid = pcall(UnitGUID, unit)
  if not ok or type(guid) ~= "string" or secret(guid) then return nil end
  return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
end

-- Minimap izi (Find Herbs / Find Minerals) acik mi: true / false; API yoksa ya da iz listede yoksa nil.
function P.TrackingActive(spellId)
  if not (C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then return nil end
  local n = tonumber((try(C_Minimap.GetNumTrackingTypes))) or 0
  for i = 1, n do
    local info = try(C_Minimap.GetTrackingInfo, i)
    if type(info) == "table" and info.spellID == spellId then return info.active == true end
  end
  return nil
end

-- Acik saticinin sinirsiz satilan esyalari: { { id, price (tane basina bakir) } }; pencere kapaliysa bos.
function P.MerchantItems()
  local out = {}
  if not (GetMerchantNumItems and GetMerchantItemLink and C_MerchantFrame and C_MerchantFrame.GetItemInfo) then return out end
  for i = 1, (tonumber((try(GetMerchantNumItems))) or 0) do
    local info = try(C_MerchantFrame.GetItemInfo, i)
    local id = P.ItemIdFromLink(try(GetMerchantItemLink, i))
    if id and type(info) == "table" and info.numAvailable == -1 and not info.hasExtendedCost
      and type(info.price) == "number" and info.price > 0 and not secret(info.price) then
      out[#out + 1] = { id = id, price = info.price / math.max(1, tonumber(info.stackCount) or 1) }
    end
  end
  return out
end

-- Acik saticinin butun esya kimlikleri (sinirli stok ve ozel bedelliler dahil); pencere kapaliysa bos.
function P.MerchantItemIds()
  local out = {}
  if not (GetMerchantNumItems and GetMerchantItemLink) then return out end
  for i = 1, (tonumber((try(GetMerchantNumItems))) or 0) do
    local id = P.ItemIdFromLink(try(GetMerchantItemLink, i))
    if id then out[#out + 1] = id end
  end
  return out
end

-- Cantadaki esyanin baslattigi gorev kimligi ya da nil.
function P.ContainerQuestId(bag, slot)
  if not (C_Container and C_Container.GetContainerItemQuestInfo) then return nil end
  local info = try(C_Container.GetContainerItemQuestInfo, bag, slot)
  local q = type(info) == "table" and info.questID
  return type(q) == "number" and not secret(q) and q or nil
end

function P.QuestRewardButton(index)
  if QuestInfo_GetRewardButton then
    local frame = (QuestInfoFrame and QuestInfoFrame.rewardsFrame) or QuestInfoRewardsFrame
    if frame then
      local btn = try(QuestInfo_GetRewardButton, frame, index)
      if btn then return btn end
    end
  end
  return _G["QuestInfoRewardsFrameQuestInfoItem" .. index] or _G["QuestRewardItem" .. index]
end

-- Gecikmeli cagri; C_Timer yoksa cagrilmaz ve false doner.
function P.After(seconds, fn)
  if C_Timer and C_Timer.After then
    return (pcall(C_Timer.After, seconds, fn))
  end
  return false
end

-- ===== Kucuk kolayliklar: CVar, ganimet, hata yazilari, canta dolu, buff, gorev paylasimi, isim levhalari =====

-- Istemci ayari (CVar); yoksa nil (bu istemcide o ayar yok).
function P.GetCVar(name)
  local fn = (C_CVar and C_CVar.GetCVar) or GetCVar
  if not fn then return nil end
  local v = try(fn, name)
  return type(v) == "string" and v or nil
end

-- Istemci ayarini yazar; basarili mi (bazi degerler bu istemcide reddedilir, ornek kamera 4).
function P.SetCVar(name, value)
  local fn = (C_CVar and C_CVar.SetCVar) or SetCVar
  if not fn then return false end
  local ok, r = pcall(fn, name, value)
  local now = P.GetCVar(name)
  return ok and r ~= false and (now == tostring(value) or (tonumber(now) ~= nil and tonumber(now) == tonumber(value)))
end

-- Otomatik ganimet bu acilista gecerli mi (ayar, degistirici tusla tersine doner)
function P.AutoLootActive()
  local on = P.GetCVar("autoLootDefault") == "1"
  if IsModifiedClick and try(IsModifiedClick, "AUTOLOOTTOGGLE") then on = not on end
  return on
end

-- Acik ganimet penceresindeki her seyi al (LootSlot korumali degil); sondan basa, kayan sira sorun olmasin.
function P.LootAll()
  if not (GetNumLootItems and LootSlot) then return 0 end
  local n = try(GetNumLootItems) or 0
  for i = n, 1, -1 do try(LootSlot, i) end
  return n
end

-- Kirmizi hata yazilari suzgeci: drop(msg) true donen mesaj gosterilmez; drop nil verilirse oyunun haline donulur.
-- Oyunun cercevesi olayi birakir, kendi cercevemiz alir ve kalanlari ona iletir (ses ve renk oyunun kodundan).
local errFrame
function P.FilterUIErrors(drop)
  local ui = UIErrorsFrame
  if not (ui and ui.UnregisterEvent and CreateFrame) then return false end
  if not drop then
    if errFrame then errFrame:UnregisterAllEvents() end
    pcall(ui.RegisterEvent, ui, "UI_ERROR_MESSAGE")
    return true
  end
  errFrame = errFrame or CreateFrame("Frame")
  errFrame:SetScript("OnEvent", function(_, event, kind, msg, ...)
    if secret(msg) or not drop(msg) then
      local fn = ui.GetScript and ui:GetScript("OnEvent")
      if fn then pcall(fn, ui, event, kind, msg, ...) end
    end
  end)
  pcall(ui.UnregisterEvent, ui, "UI_ERROR_MESSAGE")
  errFrame:RegisterEvent("UI_ERROR_MESSAGE")
  return true
end

-- Oyunun global metni (ERR_INV_FULL gibi); yoksa nil.
function P.GlobalText(name)
  local v = _G[name]
  return type(v) == "string" and v or nil
end

-- Sirt cantasi dugmesi (bos yuva sayisi yazisi icin) ya da nil.
function P.BackpackButton() return _G.MainMenuBarBackpackButton end

-- Canta yuvasindaki esyayi yok et. Yalniz yuvada hala ayni baglanti varsa ve imlec bossa; imlecteki esya
-- beklenen degilse birakilir, hicbir sey silinmez. Cagiran oyuncunun onayini almis olmali.
function P.DestroyBagItem(bag, slot, link)
  local cur = P.ContainerItem(bag, slot)
  if not (cur and link and cur.link == link) then return false end
  if not (GetCursorInfo and DeleteCursorItem) then return false end
  if try(GetCursorInfo) then return false end   -- imlecte baska bir sey var
  local pick = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
  if not pick or not pcall(pick, bag, slot) then return false end
  local kind, id = try(GetCursorInfo)
  if kind ~= "item" or (cur.id and id ~= cur.id) then
    if ClearCursor then ClearCursor() end
    return false
  end
  return (pcall(DeleteCursorItem))
end

-- Evet/Hayir sorusu (oyunun onay penceresi); evet'e basilinca onAccept. Pencere yoksa false (hicbir sey yapilmaz).
function P.Confirm(text, onAccept, yes)
  if not (StaticPopupDialogs and StaticPopup_Show) then return false end
  StaticPopupDialogs.ARCANIS_CONFIRM = StaticPopupDialogs.ARCANIS_CONFIRM or {
    text = "%s", timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnAccept = function(_, data) if type(data) == "function" then data() end end,
  }
  local d = StaticPopupDialogs.ARCANIS_CONFIRM
  d.button1, d.button2 = yes or _G.ACCEPT or "OK", _G.CANCEL or "Cancel"
  return try(StaticPopup_Show, "ARCANIS_CONFIRM", text, nil, onAccept) ~= nil
end

function P.IsMounted() return IsMounted and try(IsMounted) and true or false end
function P.InVehicle() return UnitInVehicle and try(UnitInVehicle, "player") and true or false end

-- Gruptaki diger oyuncular (parti): { { unit, name }, ... }; baskin (raid) grupta bos.
function P.PartyMembers()
  local out = {}
  if not (UnitExists and UnitName) or (IsInRaid and try(IsInRaid)) then return out end
  for i = 1, 4 do
    local unit = "party" .. i
    if try(UnitExists, unit) then
      local n = clean(try(UnitName, unit))
      out[#out + 1] = { unit = unit, name = type(n) == "string" and n or unit }
    end
  end
  return out
end

-- Birim bu gorevde mi: true / false; API yoksa ya da cevap gizliyse nil (bilinmez).
function P.UnitOnQuest(unit, questId)
  local fn = (C_QuestLog and C_QuestLog.IsUnitOnQuest) or IsUnitOnQuest
  if not fn then return nil end
  local ok, r = pcall(fn, unit, questId)
  if not ok or r == nil or secret(r) then return nil end
  return r == true or r == 1
end

-- Gorev gruba paylasilabilir mi (API yoksa paylasmayi deneriz)
function P.QuestPushable(questId)
  if C_QuestLog and C_QuestLog.IsPushableQuest then
    local r = try(C_QuestLog.IsPushableQuest, questId)
    if r ~= nil and not secret(r) then return r == true end
  end
  return true
end

-- Gorevi gruba paylas (oyunun "Share" dugmesi); gunlukte yoksa false.
function P.ShareQuest(questId)
  local idx = P.QuestLogIndex(questId)
  if not (idx and QuestLogPushQuest) then return false end
  if C_QuestLog and C_QuestLog.SetSelectedQuest then try(C_QuestLog.SetSelectedQuest, questId)
  elseif SelectQuestLogEntry then try(SelectQuestLogEntry, idx) end
  return (pcall(QuestLogPushQuest, idx))
end

-- Isim levhasi cercevesi (yasakli / yoksa nil)
function P.NamePlateFor(unit)
  if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
  return try(C_NamePlate.GetNamePlateForUnit, unit, false)
end

-- Birim ipucunun satirlari (oyunun kendi verisi): { { type, text, done }, ... } ya da nil. Gizli metin atlanir.
-- Tur: "title" (gorev adi), "player" (grup uyesinin adi), "objective" (hedef), digerleri nil.
local LINE_KIND
function P.UnitTooltipLines(unit)
  if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return nil end
  local data = try(C_TooltipInfo.GetUnit, unit)
  if type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
  if not LINE_KIND then
    local E = Enum and Enum.TooltipDataLineType or {}
    LINE_KIND = { [E.QuestObjective or 8] = "objective", [E.QuestTitle or 17] = "title", [E.QuestPlayer or 18] = "player" }
  end
  local out = {}
  for _, l in ipairs(data.lines) do
    local text = l.leftText
    if not secret(text, l.type) then
      out[#out + 1] = { type = LINE_KIND[l.type], text = type(text) == "string" and text or "", done = l.completed == true }
    end
  end
  return out
end

-- Birimin GUID'i ya da adi (onbellek anahtari); ikisi de gizliyse nil.
function P.UnitKey(unit)
  local g = clean(UnitGUID and try(UnitGUID, unit))
  if type(g) == "string" then return g end
  local n = clean(UnitName and try(UnitName, unit))
  return type(n) == "string" and n or nil
end

-- ===== Arayuz kolayliklari: profiller, sohbet, davet/duello suzgeci =====

function P.ReloadUI()
  if C_UI and C_UI.Reload then return (pcall(C_UI.Reload)) end
  if ReloadUI then return (pcall(ReloadUI)) end
  return false
end

function P.ShiftDown() return IsShiftKeyDown and try(IsShiftKeyDown) and true or false end
function P.CtrlDown() return IsControlKeyDown and try(IsControlKeyDown) and true or false end

-- Oyuncu arkadas, Battle.net arkadasi ya da lonca uyesi mi (gizli deger / API yok: false = yabanci)
function P.KnownPlayer(name, guid)
  name, guid = clean(name), clean(guid)
  local function yes(fn, ...) local r = fn and clean(try(fn, ...)); return r and r ~= 0 end
  if type(guid) == "string" and guid ~= "" then
    if C_FriendList and yes(C_FriendList.IsFriend, guid) then return true end
    if C_BattleNet and yes(C_BattleNet.GetGameAccountInfoByGUID, guid) then return true end
  end
  if type(name) == "string" and name ~= "" and C_GuildInfo and yes(C_GuildInfo.MemberExistsByName, name) then return true end
  return false
end

-- Grup davetini / duelloyu reddeder ve oyunun sorusunu kapatir
function P.DeclineInvite()
  local ok = DeclineGroup and pcall(DeclineGroup)
  if StaticPopup_Hide then pcall(StaticPopup_Hide, "PARTY_INVITE") end
  return ok and true or false
end
function P.DeclineDuel()
  local ok = CancelDuel and pcall(CancelDuel)
  if StaticPopup_Hide then pcall(StaticPopup_Hide, "DUEL_REQUESTED") end
  return ok and true or false
end

-- Sohbet olay suzgeci (ChatFrame_AddMessageEventFilter): fn(self, event, msg, ...) -> engelle?, yeni msg, ...
function P.AddChatFilter(event, fn)
  if not ChatFrame_AddMessageEventFilter then return false end
  return (pcall(ChatFrame_AddMessageEventFilter, event, fn))
end

-- Oyunun sohbet cerceveleri (ChatFrame1..N)
function P.ChatFrames()
  local out = {}
  for i = 1, tonumber(NUM_CHAT_WINDOWS) or 10 do
    local f = _G["ChatFrame" .. i]
    if f then out[#out + 1] = f end
  end
  return out
end

-- Sohbet cercevesinin son satirlari (eskiden yeniye, en cok max); gizli satir atlanir
function P.ChatLines(frame, max)
  local out = {}
  if not (frame and frame.GetNumMessages and frame.GetMessageInfo) then return out end
  local n = tonumber(try(frame.GetNumMessages, frame)) or 0
  for i = math.max(1, n - (max or 200) + 1), n do
    local text = clean(try(frame.GetMessageInfo, frame, i))
    if type(text) == "string" then out[#out + 1] = text end
  end
  return out
end

function P.MouseOver(frame) return frame and MouseIsOver and try(MouseIsOver, frame) and true or false end
