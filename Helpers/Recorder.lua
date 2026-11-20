-- Arcanis: rota kaydedici (modul "Recorder").
-- Oyuncu normal oynarken gorev alma / hedef tamamlama / teslim, ucus, ocak taşı ve seviye adimlarini
-- NPC adi ve harita konumuyla kaydeder. Kayit:
--   * hemen bir rehber olarak kaydolur ("Kayitli: ..."), ayni irkla acilan ikinci karakter onu izleyebilir;
--   * /wf rec export ile Guides:Register{} Lua metni olarak kopyalanabilir (gelistiriciye gonderilir,
--     tools/merge_recording.py ile Guides/ altina eklenir).
-- Ayrica gezilen bolgelerin ad -> uiMapID eslemesini ogrenir (ns.db.zoneMaps; Zephras Isle gibi ozel bolgeler).
--
--   /wf rec start [ad]   kaydi baslat      /wf rec stop     durdur ve rehbere cevir
--   /wf rec note <metin> not adimi ekle    /wf rec export   son kaydi disa aktar
--   /wf rec list         kayitlar          /wf rec delete <n>
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Rec = ns:NewModule("Recorder", { defaults = { sessions = {}, active = nil } })
ns.Recorder = Rec

local HEARTH_SPELLS = { [8690] = true, [556] = true }   -- Ocak tasi, Astral Recall

local function now() return (time and time()) or 0 end

local function round2(v) return math.floor(v * 10000 + 0.5) / 100 end   -- 0-1 -> 0-100, 2 hane

-- Oyuncu konumu: map, zoneName, x, y (0-100). Alinamazsa yalnizca bolge adi.
local function here()
  local map, x, y = P.PlayerMapPosition()
  local zone
  if map and C_Map and C_Map.GetMapInfo then
    local ok, info = pcall(C_Map.GetMapInfo, map)
    zone = ok and info and info.name or nil
  end
  zone = zone or P.ZoneText()
  if map and x then return map, zone, round2(x), round2(y) end
  return nil, zone
end

local function questTitle(id)
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then
    local ok, t = pcall(C_QuestLog.GetTitleForQuestID, id)
    if ok and t and t ~= "" then return t end
  end
  return nil
end

local function questComplete(id)
  if C_QuestLog and C_QuestLog.IsComplete then
    local ok, v = pcall(C_QuestLog.IsComplete, id)
    return ok and v or false
  end
  return false
end

-- Acik kayit karakter basina (char.active): baska karakterle girince eski kayit uzamasin.
function Rec:Current()
  -- eski surumun hesap geneli acik kaydi kimseye devredilmez (iki karakterin adimlari karismis olabilir); kayit listede kalir
  self.db.active = nil
  local key = self.char.active
  return key and self.db.sessions[key] or nil
end

function Rec:IsRecording() return self:Current() ~= nil end

-- Yeni adim ekler; ard arda gelen ayni adimi (ayni tur + gorev) yinelemez.
function Rec:Add(step)
  local s = self:Current()
  if not s then return end
  local last = s.steps[#s.steps]
  if last and last.type == step.type and last.quest == step.quest and last.text == step.text and last.to == step.to
    and last.level == step.level then
    return
  end
  local map, zone, x, y = here()
  if step.loc ~= false and x then
    step.map, step.zone, step.x, step.y = map, zone, x, y
    if zone and map then s.maps[zone] = map end
  end
  step.loc = nil
  step.lv = P.PlayerLevel()
  s.steps[#s.steps + 1] = step
  s.maxLevel = math.max(s.maxLevel or 1, step.lv or 1)
  self.dirty = true
end

function Rec:Start(name)
  if self:IsRecording() then return self:Current() end
  local info = P.PlayerInfo()
  self.db.counter = (self.db.counter or 0) + 1
  local key = tostring(now()) .. "-" .. tostring(self.db.counter)
  local race = info.race or "Unknown"
  self.db.sessions[key] = {
    key = key,
    name = (name and name ~= "") and name or (race .. " " .. (info.level or 1) .. "+"),
    faction = info.faction, race = race, class = info.class,
    minLevel = info.level or 1, maxLevel = info.level or 1,
    started = now(), steps = {}, maps = {},
  }
  self.char.active = key
  self.known = {}
  self:SnapshotLog()
  ns:Print(L["Recording started. Play normally; type /wf rec stop when you are done."])
  ns:Send("ARCANIS_RECORDER_CHANGED")
  return self.db.sessions[key]
end

function Rec:Stop()
  local s = self:Current()
  if not s then return nil end
  self.char.active = nil
  s.stopped = now()
  -- ogrenilen bolge eslemelerini genel tabloya yaz
  ns.db.zoneMaps = ns.db.zoneMaps or {}
  for zone, map in pairs(s.maps or {}) do
    if ns.Zones:Resolve(zone) ~= map then ns.db.zoneMaps[zone] = map end
  end
  if self:RegisterSession(s) then
    ns:Print(L["Recording saved: %d steps. It is now listed as a guide."]:format(#s.steps))
  end
  ns:Send("ARCANIS_RECORDER_CHANGED")
  return s
end

-- Gorev gunlugundeki gorevlerin tamamlanma durumunu hatirlar (tamamlanma anini yakalamak icin).
function Rec:SnapshotLog()
  self.known = self.known or {}
  if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then return end
  local ok, n = pcall(C_QuestLog.GetNumQuestLogEntries)
  if not ok or not n then return end
  for i = 1, n do
    local ok2, info = pcall(C_QuestLog.GetInfo, i)
    if ok2 and info and info.questID and not info.isHeader then
      self.titles = self.titles or {}
      if info.title and info.title ~= "" then self.titles[info.questID] = info.title end
      local done = questComplete(info.questID)
      if self.known[info.questID] == false and done then
        self:Add({ type = "complete", quest = info.questID, name = (info.title ~= "" and info.title) or nil })
      end
      self.known[info.questID] = done
    end
  end
end

-- Kayit -> rehber tanimi (Guides:Register bicimi).
function Rec:ToGuide(s)
  local steps = {}
  for _, st in ipairs(s.steps) do
    local out = {}
    for k, v in pairs(st) do if k ~= "lv" then out[k] = v end end
    steps[#steps + 1] = out
  end
  local maxL = math.max(s.maxLevel or s.minLevel or 1, s.minLevel or 1)
  return {
    id = "rec-" .. s.key,
    title = s.name .. " (" .. L["recorded"] .. ")",
    faction = (s.faction == "Alliance" or s.faction == "Horde") and s.faction or nil,
    minLevel = s.minLevel or 1, maxLevel = maxL,
    races = s.race and s.race ~= "Unknown" and { s.race } or nil,
    steps = steps,
  }
end

function Rec:RegisterSession(s)
  if not s or #s.steps == 0 then return false end
  local def = self:ToGuide(s)
  if ns.Guides.byId[def.id] then return true end
  local ok, errs = ns.Guides:Register(def)
  if not ok and errs then ns:Print(L["Recording could not be turned into a guide: %s"]:format(tostring(errs[1]))) end
  return ok
end

-- Lua metni olarak disa aktarim.
local function lit(v)
  if type(v) == "string" then return ("%q"):format(v) end
  return tostring(v)
end
local ORDER = { "type", "quest", "name", "npc", "to", "text", "level", "map", "zone", "x", "y" }

function Rec:Export(s)
  s = s or self:Last()
  if not s then return nil end
  local g = self:ToGuide(s)
  local lines = {
    "-- Recorded with Arcanis Path /wf rec (" .. (s.race or "?") .. ", " .. (s.class or "?") .. ")",
    "local _, ns = ...", "", "ns.Guides:Register{",
    ("  id = %q, title = %q,%s"):format(g.id, s.name, g.faction and (" faction = %q,"):format(g.faction) or ""),
    ("  minLevel = %d, maxLevel = %d,"):format(g.minLevel, g.maxLevel),
  }
  if g.races then lines[#lines + 1] = ("  races = { %q },"):format(g.races[1]) end
  lines[#lines + 1] = "  steps = {"
  for _, st in ipairs(g.steps) do
    local parts = {}
    for _, k in ipairs(ORDER) do
      if st[k] ~= nil then parts[#parts + 1] = k .. " = " .. lit(st[k]) end
    end
    lines[#lines + 1] = "    { " .. table.concat(parts, ", ") .. " },"
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

function Rec:List()
  local list = {}
  for _, s in pairs(self.db.sessions) do list[#list + 1] = s end
  table.sort(list, function(a, b) return (a.started or 0) < (b.started or 0) end)
  return list
end

function Rec:Last()
  local list = self:List()
  return list[#list]
end

-- Olaylar
function Rec:OnNpc()
  local name = UnitName and UnitName("npc")
  if name then self.lastNpc, self.lastNpcAt = name, now() end
end

local function npcName(self)
  if self.lastNpc and now() - (self.lastNpcAt or 0) < 30 then return self.lastNpc end
  return nil
end

function Rec:OnAccepted(_, a, b)
  local id = tonumber(b) or tonumber(a)
  -- eski imza (logIndex, questID) ise ikinci arguman, yeni imza (questID) ise ilk arguman kimliktir.
  if not id then return end
  self:Add({ type = "accept", quest = id, name = questTitle(id), npc = npcName(self) })
  self.known = self.known or {}
  self.known[id] = questComplete(id)
end

function Rec:OnTurnedIn(_, id)
  id = tonumber(id)
  if not id then return end
  self:Add({ type = "turnin", quest = id, name = questTitle(id) or (self.titles and self.titles[id]), npc = npcName(self) })
  if self.known then self.known[id] = nil end
end

function Rec:OnLogUpdate()
  if not self:IsRecording() then return end
  self:SnapshotLog()
end

function Rec:OnSpell(_, unit, _, spellId)
  if unit ~= "player" or (issecretvalue and issecretvalue(spellId)) or not HEARTH_SPELLS[tonumber(spellId) or 0] then return end
  local to = GetBindLocation and GetBindLocation() or "Home"
  self:Add({ type = "hearth", to = to, loc = false })
end

function Rec:OnLevel(_, level)
  self:Add({ type = "level", level = tonumber(level) or P.PlayerLevel(), loc = false })
end

function Rec:OnZone()
  local s = self:Current()
  if not s then return end
  local map, zone = here()
  if map and zone then s.maps[zone] = map end
end

function Rec:OnEnable()
  -- kayitli oturumlari rehber olarak yukle
  for _, s in pairs(self.db.sessions) do ns.SafeCall(self.RegisterSession, self, s) end
  ns:On("QUEST_ACCEPTED", self, function(o, e, ...) if o:IsRecording() then o:OnAccepted(e, ...) end end)
  ns:On("QUEST_TURNED_IN", self, function(o, e, ...) if o:IsRecording() then o:OnTurnedIn(e, ...) end end)
  ns:On("QUEST_LOG_UPDATE", self, "OnLogUpdate")
  for _, ev in ipairs({ "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW", "QUEST_GREETING" }) do
    ns:On(ev, self, "OnNpc")
  end
  ns:On("UNIT_SPELLCAST_SUCCEEDED", self, function(o, e, ...) if o:IsRecording() then o:OnSpell(e, ...) end end, "player")
  ns:On("PLAYER_LEVEL_UP", self, function(o, e, ...) if o:IsRecording() then o:OnLevel(e, ...) end end)
  ns:On("ZONE_CHANGED_NEW_AREA", self, "OnZone")
  if hooksecurefunc and TakeTaxiNode and not self.taxiHooked then
    self.taxiHooked = true
    hooksecurefunc("TakeTaxiNode", function(i)
      if not Rec:IsRecording() then return end
      local to = TaxiNodeName and TaxiNodeName(i)
      if to then Rec:Add({ type = "fly", to = to, npc = npcName(Rec) }) end
    end)
  end
  if self:IsRecording() then self.known = {}; self:SnapshotLog() end
end

-- Disa aktarim penceresi (kopyalanabilir metin)
function Rec:ShowExport(text)
  local Skin = ns.Skin
  local f = self.exportFrame
  if not f then
    f = CreateFrame("Frame", "ArcanisPathRecorderExport", UIParent, "BackdropTemplate")
    f:SetSize(560, 400)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    Skin:ApplyWindowChrome(f, 32)
    Skin:RegisterRoot(f)
    local title = f:CreateFontString(nil, "OVERLAY")
    Skin:SetFont(title, 13, "")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetTextColor(unpack(Skin.Colors.accentHover))
    title:SetText(L["Recorded route"])
    local hint = f:CreateFontString(nil, "OVERLAY")
    Skin:SetFont(hint, 10, "")
    hint:SetPoint("BOTTOMLEFT", 14, 12)
    hint:SetTextColor(unpack(Skin.Colors.textDim))
    hint:SetText(L["Ctrl+A, Ctrl+C to copy. Send it to the Arcanis team to add it to the addon."])
    local close = Skin:CreateCloseButton(f, 14)
    close:SetPoint("TOPRIGHT", -10, -9)
    close:SetScript("OnClick", function() f:Hide() end)
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -42)
    scroll:SetPoint("BOTTOMRIGHT", -30, 34)
    local box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetWidth(500)
    box:SetFontObject(ChatFontNormal)
    box:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(box)
    f.box = box
    self.exportFrame = f
  end
  f.box:SetText(text or "")
  f.box:HighlightText()
  f.box:SetFocus()
  f:Show()
end

ns:RegisterCommand("rec", function(args)
  local cmd, rest = (args or ""):match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  if cmd == "start" then
    Rec:Start(rest)
  elseif cmd == "stop" then
    if not Rec:Stop() then ns:Print(L["Not recording."]) end
  elseif cmd == "note" and rest ~= "" then
    Rec:Add({ type = "note", text = rest, loc = false })
  elseif cmd == "export" then
    local text = Rec:Export()
    if not text then ns:Print(L["No recordings yet."]) return end
    Rec:ShowExport(text)
  elseif cmd == "list" then
    local list = Rec:List()
    if #list == 0 then ns:Print(L["No recordings yet."]) end
    for i, s in ipairs(list) do print(("  %d. %s - %d steps"):format(i, s.name, #s.steps)) end
  elseif cmd == "delete" then
    local s = Rec:List()[tonumber(rest) or 0]
    if not s then ns:Print(L["No recordings yet."]) return end
    if Rec.char.active == s.key then Rec.char.active = nil end
    if Rec.db.active == s.key then Rec.db.active = nil end
    Rec.db.sessions[s.key] = nil
    ns:Print(L["Recording deleted. Type /reload to remove it from the guide list."])
  else
    local s = Rec:Current()
    if s then
      ns:Print(L["Recording: %s (%d steps)."]:format(s.name, #s.steps))
    else
      ns:Print(L["Route recorder: /wf rec start | stop | note <text> | export | list | delete <n>"])
    end
  end
end, "Record a route while you play (Skyborne and missing zones)")
