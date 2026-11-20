-- Arcanis: kutuphane kitaplari (modul "LibraryBooks"). Forever'in toplanan kitaplari: her kitap dunyada bir nesne;
-- alinca gorev baslatan esya verir, gorev kutuphane gorevlisine teslim edilir. Kitap listesi kendi gorev grafigimizden:
-- "Research Access" (LibraryBooks.HUB) gorevinin onkosullari (any) kitap gorevleridir; ad, seviye ve teslim NPC'si
-- BrainData.givers / quests, esya BrainData.items'tan (yalniz bir kismi biliniyor).
-- Kitaplarin dunyadaki yeri hicbir temiz kaynakta yok (istemcinin GameObjects tablosunda da yok): oyunda kaydedilir.
-- Kitap esyasi cantaya yeni girdiginde (esyanin baslattigi gorev kitap gorevi) ya da gorev esyasiz alininca oyuncunun
-- yeri hesap geneline yazilir (db.spots[gorev]); ogrenilen esya kimligi db.items'a. Mentor > Books gosterir, ok
-- kayitli yere ya da (kitap elindeyse) teslim NPC'sine gider.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local LB = ns:NewModule("LibraryBooks", { defaults = { spots = {}, items = {} } })
ns.LibraryBooks = LB

LB.HUB = 97286

local books
-- { { quest, name, level, item, npc, zone, x, y } } seviye sonra ad sirasinda
function LB:Books()
  if books then return books end
  books = {}
  local D = ns.BrainData or {}
  local hub = D.graph and D.graph[LB.HUB]
  local itemOf = {}
  for id, e in pairs(D.items or {}) do
    for _, q in ipairs(e.need or {}) do itemOf[q] = itemOf[q] or id end
    if e.starts then itemOf[e.starts] = id end
  end
  for _, q in ipairs(hub and hub.any or {}) do
    local g, qd = D.givers and D.givers[q], D.quests and D.quests[q]
    books[#books + 1] = { quest = q, name = (g and g[1]) or (qd and qd[1]) or ("#" .. q), level = (g and g[2]) or (qd and qd[2]) or 0,
      item = itemOf[q], npc = g and g[6], zone = g and g[7], x = g and g[8], y = g and g[9] }
  end
  table.sort(books, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.name < b.name end)
  return books
end
function LB.Reset() books = nil end

local function bookOf(q)
  for _, b in ipairs(LB:Books()) do if b.quest == q then return b end end
end
LB.BookOf = bookOf

function LB:ItemOf(b) return b.item or self.db.items[b.quest] end

-- "done" (teslim edildi) / "log" (gorev gunlukte) / "bag" (kitap cantada) / "missing"
function LB:State(b)
  if P.IsQuestFlaggedCompleted(b.quest) then return "done" end
  if P.QuestLogIndex(b.quest) then return "log" end
  local item = self:ItemOf(b)
  if item and (P.ItemCount(item) or 0) > 0 then return "bag" end
  return "missing"
end

function LB:Counts()
  local done = 0
  for _, b in ipairs(self:Books()) do if self:State(b) == "done" then done = done + 1 end end
  return done, #self:Books()
end

-- Oyuncunun yerini kitabin yeri olarak yaz (ilk kayit kalir). Doner: true = yeni kayit
function LB:Record(q)
  if self.db.spots[q] then return false end
  local map, x, y = P.PlayerMapPosition()
  if not map then return false end
  self.db.spots[q] = { map = map, x = x, y = y, zone = P.ZoneText() }
  return true
end

-- Cantadaki kitap esyalari: { [gorev] = esya }
local function bagBooks()
  local out = {}
  for bag = 0, P.LastBag() do
    for slot = 1, P.ContainerSlots(bag) do
      local q = P.ContainerQuestId(bag, slot)
      if q and bookOf(q) then
        local it = P.ContainerItem(bag, slot)
        out[q] = it and it.id or true
      end
    end
  end
  return out
end

-- Canta taramasi: yeni giren kitabin yeri kaydedilir. Ilk tarama (giris) yalniz durumu alir.
function LB:ScanBags()
  local now = bagBooks()
  for q, item in pairs(now) do
    if type(item) == "number" then self.db.items[q] = self.db.items[q] or item end
    if self.had and not self.had[q] then self:Record(q) end
    self.seen = self.seen or {}
    self.seen[q] = true
  end
  self.had = now
end

-- Gorev alindi: kitap cantada hic gorulmediyse (nesneden dogrudan alinan gorev) yer burasi
function LB:OnAccepted(q)
  if bookOf(q) and not (self.seen and self.seen[q]) then self:Record(q) end
end

-- Ok: kitap elinde ya da gorev gunlukteyse teslim NPC'sine, yoksa kayitli yerine. Doner: true = ok kuruldu
function LB:PointTo(b)
  if not ns.Nav then return false end
  local st = self:State(b)
  if (st == "bag" or st == "log") and b.zone and ns.Mentor then
    return ns.Mentor:PointAt(b.zone, b.x * 100, b.y * 100, b.npc) and true or false
  end
  local s = self.db.spots[b.quest]
  if s then ns.Nav:SetTarget(s.map, s.x, s.y, b.name, "manual") return true end
  return false
end

function LB:OnEnable()
  self.had, self.seen = nil, nil
  ns:On("BAG_UPDATE_DELAYED", self, function(o) ns.SafeCall(o.ScanBags, o) end)
  ns:On("PLAYER_ENTERING_WORLD", self, function(o) ns.SafeCall(o.ScanBags, o) end)
  ns:On("QUEST_ACCEPTED", self, function(o, _, a, b)
    -- Forever: (questId); eski istemci: (index, questId)
    local q = (type(b) == "number" and b) or (type(a) == "number" and a) or nil
    if q then ns.SafeCall(o.OnAccepted, o, q) end
  end)
end

ns:RegisterCommand("books", function()
  local done, total = LB:Counts()
  ns:Print(L["Library books turned in: %d of %d."]:format(done, total))
end, "library books turned in")
