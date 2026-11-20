-- Arcanis: sunucuda hangi quest ID'leri var? (/wf qscan). Gelistirici araci: bulunan ID -> ad hesap kaydina
-- (ArcanisCoreDB.modules.QuestScan.found) yazilir; tools/qscan_compare.py Forever veritabaniyla karsilastirir.
-- SLOTS gizli tooltip birer ID sorar, WAIT sn sonra okunur; hiz ~8/sn, yalniz RANGES taranir.
-- Savasta yeni istek yok, /reload sonrasi kaldigi yerden devam eder.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local QS = ns:NewModule("QuestScan", { defaults = { found = {}, next = 1 } })
ns.QuestScan = QS

-- Tarama hizi; dogrulama (bilinen ama bulunamayan gorevler) yavas ve sabirli: ~4/sn, 3 sn bekleme, 3 deneme.
local SCAN = { slots = 8, wait = 1, tries = 2 }
local VERIFY = { slots = 4, wait = 3, tries = 3 }
local TICK = 0.1
local RANGES = { { 1, 10000 }, { 90000, 100000 } }
local LAST = RANGES[#RANGES][2]
local SWEEP_CHUNK = 2000   -- onbellek taramasinda kare basina okunan ID
QS.RANGES = RANGES

-- Taranacak toplam ID sayisi (ilerleme gostergesi).
local function total()
  local n = 0
  for _, r in ipairs(RANGES) do n = n + r[2] - r[1] + 1 end
  return n
end
QS.Total = total

-- id'ye kadar taranmis ID sayisi.
function QS:Done()
  local n, upto = 0, self.db.next - 1
  for _, r in ipairs(RANGES) do
    if upto >= r[1] then n = n + math.min(upto, r[2]) - r[1] + 1 end
  end
  return n
end

QS.running = false
QS.slots = {}   -- slot -> { id, at, tries }

function QS:Count()
  local n = 0
  for _ in pairs(self.db.found) do n = n + 1 end
  return n
end

local function inRanges(id)
  for _, r in ipairs(RANGES) do if id >= r[1] and id <= r[2] then return true end end
  return false
end

-- Arcanis'in bildigi (rehberler + onkosul grafigi) ama taramanin bulamadigi gorevler, sirali.
function QS:Unconfirmed()
  local seen, list = {}, {}
  local function add(q)
    if type(q) == "number" and not seen[q] and inRanges(q) and not self.db.found[q] then seen[q] = true; list[#list + 1] = q end
  end
  for q in pairs(ns.BrainData and ns.BrainData.graph or {}) do add(q) end
  for _, id in ipairs(ns.Guides and ns.Guides.order or {}) do
    for _, s in ipairs(ns.Guides.byId[id].steps) do add(s.quest) end
  end
  table.sort(list)
  return list
end

function QS:Params() return self.verifying and VERIFY or SCAN end

-- Bir sonraki taranmamis ID (bilinenler atlanir) ya da nil.
function QS:NextId()
  local db = self.db
  if self.verifying then
    while (db.vpos or 1) <= #(db.verify or {}) do
      local id = db.verify[db.vpos]
      db.vpos = db.vpos + 1
      if not db.found[id] then return id end
    end
    return nil
  end
  while db.next <= LAST do
    local id = db.next
    local inRange = false
    for _, r in ipairs(RANGES) do
      if id >= r[1] and id <= r[2] then inRange = true break end
      if id < r[1] then db.next = r[1]; break end   -- araliklar arasi atlanir
    end
    if inRange then
      db.next = id + 1
      if id % 5000 == 0 then ns:Print(L["Quest scan: %d / %d, found %d."]:format(self:Done(), total(), self:Count())) end
      if not db.found[id] then return id end
    end
  end
end

-- Onbellek taramasi: istemcinin onbelleginde adi olan tum ID'ler (sunucuya istek yok). Kare kare ilerler.
function QS:Sweep(from)
  from = from or 1
  local to = math.min(LAST, from + SWEEP_CHUNK - 1)
  for id = from, to do
    if not self.db.found[id] then
      local t = P.CachedQuestTitle(id)
      if t then self.db.found[id] = t end
    end
  end
  if to < LAST and P.After(0, function() QS:Sweep(to + 1) end) then return end
  self.running = false
  if self.onProgress then ns.SafeCall(self.onProgress) end
  if self.verifying then
    self.verifying = false
    local missing = self:Unconfirmed()
    self.db.missing = missing
    ns:Print(L["Quest verify finished: %d found, %d still missing. /reload saves them."]:format(self:Count(), #missing))
    return
  end
  ns:Print(L["Quest scan finished: %d quests found. /reload saves them."]:format(self:Count()))
end

-- Oyunun gorev yukleme cevabi: basarili cevap gorevin var oldugunu soyler (ikinci sinyal).
function QS:OnDataLoaded(_, id, success)
  -- yalniz tarama surerken: normal oyunda gelen her gorev verisi hesap kaydini buyutmesin
  if not self.running then return end
  if not (success and type(id) == "number") or self.db.found[id] then return end
  self.db.found[id] = P.CachedQuestTitle(id) or ("#" .. id)
  for slot, s in pairs(self.slots) do if s.id == id then self.slots[slot] = nil end end
end

local function ask(slot, id)
  P.RequestQuestData(id)
  return P.QuestTip(slot, id)
end

function QS:Step()
  if not self.running then return end
  local now, combat = P.Now(), P.InCombat()
  local prm = self:Params()
  local busy = false
  for slot = 1, prm.slots do
    local s = self.slots[slot]
    if s and now - s.at >= prm.wait then
      local title = P.QuestTipTitle(slot) or P.CachedQuestTitle(s.id)
      if title then
        self.db.found[s.id] = title
        s = nil
      elseif s.tries < prm.tries and not combat then
        s.tries, s.at = s.tries + 1, now
        ask(slot, s.id)
      else
        s = nil
      end
      self.slots[slot] = s
    end
    if not s and not combat then
      local id = self:NextId()
      if id and ask(slot, id) then s = { id = id, at = now, tries = 1 }; self.slots[slot] = s end
    end
    busy = busy or s ~= nil
  end
  if self.onProgress and now - (self.shownAt or 0) >= 0.5 then self.shownAt = now; ns.SafeCall(self.onProgress) end
  local exhausted = self.verifying and (self.db.vpos or 1) > #(self.db.verify or {}) or (not self.verifying and self.db.next > LAST)
  if not busy and exhausted then
    self:Sweep(1)
    return
  end
  if not P.After(TICK, function() QS:Step() end) then self.running = false end
end

function QS:Start()
  if self.running then ns:Print(L["Quest scan is already running."]) return end
  -- onceki yontemler (hizli tarama, tum araliklar) cogu quest'i kacirdi: yavas, aralikli taramayla bastan;
  -- bulunanlar korunur
  if self.db.method ~= "tooltip-slow" then self.db.next, self.db.method = 1, "tooltip-slow" end
  self.db.max = nil
  if self.db.next > LAST then self.db.next = 1 end
  self.verifying = false
  self.running = true
  ns:Print(L["Quest scan started: %d - %d (about %d quests per second)."]:format(self.db.next, LAST, SCAN.slots / SCAN.wait))
  self:Step()
end

-- Dogrulama: bilinen ama bulunamayan gorevler yavasca yeniden sorulur; sonunda hala yoklar db.missing'e yazilir.
function QS:Verify()
  if self.running then ns:Print(L["Quest scan is already running."]) return end
  -- yarim kalmis dogrulama (/reload, cikis) kaldigi yerden surer; bittiyse liste yeniden kurulur
  if not (self.db.verify and (self.db.vpos or 1) <= #self.db.verify) then
    self.db.verify, self.db.vpos = self:Unconfirmed(), 1
  end
  self.verifying = true
  self.running = true
  ns:Print(L["Quest verify started: %d known quests to check."]:format(#self.db.verify - (self.db.vpos or 1) + 1))
  self:Step()
end

function QS:VerifyLeft()
  if not self.verifying then return 0 end
  return math.max(0, #(self.db.verify or {}) - (self.db.vpos or 1) + 1)
end

function QS:OnEnable()
  ns:On("QUEST_DATA_LOAD_RESULT", self, "OnDataLoaded")
end

-- Modul kapaninca suren tarama durur (sunucuya soru sormaya devam etmesin).
function QS:OnDisable()
  if self.running then self:Stop() end
end

-- Durdurulunca yanit beklenen ID'ler geri alinir (devamda yeniden sorulur).
function QS:Stop()
  self.running = false
  if self.verifying then
    self.verifying = false
    self.slots = {}
    return
  end
  for _, s in pairs(self.slots) do
    if s.id < self.db.next then self.db.next = s.id end
  end
  self.slots = {}
end

-- Ana pencere sayfasi: ilerleme, Baslat/Duraklat, Sifirla, ust sinir. Sayfa modul yuklenince kaydolur
-- (Helpers, UI'den once yuklenir).
local function buildPage(page)
  local Skin, C = ns.Skin, ns.Skin.Colors
  local ob = ns.Settings.OptionList(page)
  local state, toggle
  ob:Header("Quest scan", "Asks the server which quest IDs exist (1-10000 and 90000-100000, about 8 per second, then reads the game's cache). Results are saved on /reload; tools/qscan_compare.py compares them with the Forever data.")
  ob:Custom("Progress", "IDs scanned / total, quests found.", 300, function(r)
    toggle = Skin:CreateButton(r, "", 110, 22, true)
    toggle:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    toggle:SetScript("OnClick", function()
      if QS.running then QS:Stop() else QS:Start() end
      page.refresh()
    end)
    state = ns.PathWindow.UI.fstr(r, 12, C.accentHover, "RIGHT", "OUTLINE")
    state:SetPoint("RIGHT", toggle, "LEFT", -12, 0)
    state:SetWidth(170)
  end)
  local verifyBtn = ob:Buttons("Verify known quests", "Asks again, slowly, for every quest Arcanis knows that the scan did not find (about 4 per second). Quests still missing afterwards are listed for the compare tool.", {
    { "Verify", function() if QS.running then QS:Stop() else QS:Verify() end; page.refresh() end },
  })[1]
  ob:Buttons("Reset", "Deletes the results and starts again from 1.", {
    { "Reset", function() QS:Stop(); QS.db.found, QS.db.next, QS.db.missing = {}, 1, nil; page.refresh() end },
  })
  ob:Finish(function()
    local done = QS.db.next > QS.RANGES[#QS.RANGES][2] and not QS.running
    if QS.verifying then
      state:SetText(L["checking %d, found %d"]:format(QS:VerifyLeft(), QS:Count()))
    else
      state:SetText(L["%d / %d, found %d"]:format(QS:Done(), QS.Total(), QS:Count()))
    end
    toggle:SetText((QS.running and not QS.verifying) and L["Pause"] or (done and L["Scan again"]) or (QS.db.next > 1 and L["Continue"]) or L["Start"])
    toggle:SetEnabled(not QS.verifying)
    verifyBtn:SetText(QS.verifying and L["Stop"] or L["Verify"])
    verifyBtn:SetEnabled(not QS.running or QS.verifying)
  end)
  QS.onProgress = function() if page:IsShown() then page.refresh() end end
end

function QS:OnInitialize()
  if ns.PathWindow and ns.PathWindow.RegisterPage then
    ns.PathWindow:RegisterPage({
      id = "qscan", order = 90, icon = "current",
      title = function() return L["Quest scan"] end,
      available = function() return QS:IsEnabled() end,
      build = buildPage,
    })
  end
end

ns:RegisterCommand("qscan", function(args)
  local cmd = (args or ""):match("^%s*(%S*)"):lower()
  if cmd == "stop" then
    QS:Stop()
    ns:Print(L["Quest scan stopped at %d."]:format(QS.db.next))
  elseif cmd == "clear" then
    QS:Stop()
    QS.db.found, QS.db.next = {}, 1
    ns:Print(L["Quest scan data cleared."])
  elseif cmd == "status" then
    ns:Print(L["Quest scan: %d / %d, found %d."]:format(QS:Done(), QS.Total(), QS:Count()))
  elseif cmd == "verify" then
    QS:Verify()
  else
    QS:Start()
  end
end, "scan which quest IDs exist on this server (start / stop / status / clear / verify)")
