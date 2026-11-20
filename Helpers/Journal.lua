-- Arcanis: zindan gunlugu (modul "Journal"). Veri: Data/Dungeons.lua + Data/Dungeons/<id>.lua.
-- Gorevler, boss loot'u, sinif uygunlugu (ns.Gear), takip listesi (esya hatirlaticilari), zindandan rehber
-- uretme ve seviye gelince oneri sorusu. Komut: /wf dungeon [ad]
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Journal = ns:NewModule("Journal", {
  defaults = { onlyMine = false, suggest = true, remind = true, autoReturn = true, bossTypes = true, bossInfo = {} },
  charDefaults = { wishlist = {}, notified = {}, asked = {} },
})
ns.Journal = Journal

function Journal:List(player)
  local out = {}
  for _, d in ipairs(ns.DungeonData or {}) do
    if not (player and d.faction and player.faction and d.faction ~= player.faction) then out[#out + 1] = d end
  end
  return out
end

function Journal:Get(id)
  for _, d in ipairs(ns.DungeonData or {}) do if d.id == id then return d end end
end

-- Gorevin web sayfasi; link veriye yazilmaz, kimlikten uretilir.
Journal.WOWHEAD = "https://www.wowhead.com/forever/"
function Journal:QuestURL(id)
  id = tonumber(id)
  return id and (self.WOWHEAD .. "quest=" .. id) or nil
end

function Journal:Find(query)
  query = (query or ""):lower():match("^%s*(.-)%s*$")
  if query == "" then return nil end
  for _, d in ipairs(ns.DungeonData or {}) do
    if d.id == query or d.name:lower():find(query, 1, true) then return d end
  end
end

-- Oyuncu seviyesine uyan zindanlar. Raid (d.raid) seviye onerisi degildir: soru, Mentor ve yukseltmelere girmez.
function Journal:ForLevel(level, player)
  local out = {}
  for _, d in ipairs(self:List(player)) do
    if not d.raid and level >= d.minLevel and level <= d.maxLevel then out[#out + 1] = d end
  end
  return out
end

-- Durum: "now" (seviyene uygun), "soon" (en fazla 3 seviye sonra), "over" (asildi), "later".
function Journal:Status(d, level)
  if level >= d.minLevel and level <= d.maxLevel then return "now" end
  if level < d.minLevel and d.minLevel - level <= 3 then return "soon" end
  if level > d.maxLevel then return "over" end
  return "later"
end

function Journal:Extra(d) return ns.DungeonExtras and ns.DungeonExtras[d.id] or {} end

-- Oyuncunun fraksiyonuna uygun gorevler (level'a gore sirali).
function Journal:Quests(d, player)
  local out = {}
  local DG = ns.DungeonGuides
  for _, q in ipairs(self:Extra(d).quests or {}) do
    -- taraf (verideki side) + irk / sinif maskesi (gorev grafigi; zindan rehberiyle ayni kontrol): alamayacagin
    -- gorev (paladin / warlock gorevi, baska irkin zinciri) listelenmez
    if not (q.side and player and player.faction and q.side ~= player.faction)
      and not (player and DG and DG.Fits and q.id and not DG.Fits(q.id, player)) then
      out[#out + 1] = q
    end
  end
  table.sort(out, function(a, b) return (a.level or 0) < (b.level or 0) end)
  return out
end

-- Veri dosyasindaki sinif kodlari ("34" = Gear.CLASSES sirasiyla Hunter, Rogue) -> sinif listesi.
function Journal:CodeClasses(codes)
  if type(codes) ~= "string" or codes == "" then return nil end
  local list = {}
  for ch in codes:gmatch("%d") do
    local token = ns.Gear.CLASSES[tonumber(ch)]
    if token then list[#list + 1] = { class = token } end
  end
  return list
end

-- Esya satirinin sinif listesi: esya bilgisi varsa Gear hesabi, yoksa veri dosyasindaki (c) kodlari.
function Journal:EntryClasses(entry, item)
  if item then return ns.Gear:ClassesFor(item, nil) end
  return self:CodeClasses(entry.c)
end

-- Loot satirlari: { boss, items = { { id, n, item, classes, mine } } }
-- onlyMine: yalniz oyuncunun sinifina uyanlar (esya bilgisi yuklenmediyse listede kalir).
function Journal:Loot(d, token, onlyMine)
  local out = {}
  for _, group in ipairs(self:Extra(d).loot or {}) do
    local items = {}
    for _, entry in ipairs(group.items) do
      local item = P.ItemDetails(entry.id)
      local classes = self:EntryClasses(entry, item)
      local mine = nil
      if classes and token then mine = ns.Gear:FitsPlayer(classes, token) end
      if not (onlyMine and classes and mine == false) then
        items[#items + 1] = { id = entry.id, n = entry.n, q = entry.q, s = entry.s, item = item, classes = classes, mine = mine, boss = group.boss }
      end
    end
    if #items > 0 then out[#out + 1] = { boss = group.boss, items = items } end
  end
  return out
end

-- Zindan yukseltmeleri (Gear Finder): seviyene yakin zindanlarin loot'u takili esyalarla Gear puaniyla
-- karsilastirilir; her yuva icin en iyisi. Seviye penceresi: zindan en cok 3 seviye sonra baslar, en cok 3 seviye
-- once biter; esya en cok 3 seviye sonra giyilebilir (o seviyede puanlanir). Dondurur:
--   { { slot, slotName, itemId, link, delta, needLevel?, dungeon, boss }, ... } (yuva sirasiyla),
--   { [dungeonId] = sayi }, pending (esya bilgisi henuz yuklenmedi: sonra yeniden sor)
Journal.UPGRADE_AHEAD = 3
function Journal:GearUpgrades(level, player, token)
  local G = ns.Gear
  local best, counts, pending = {}, {}, false
  if not (G and G.Compare) then return {}, counts, false end
  local ahead = self.UPGRADE_AHEAD
  local specId = G:GetSpec(token)
  for _, d in ipairs(self:List(player)) do
    if not d.raid and d.minLevel <= level + ahead and d.maxLevel >= level - ahead then
      for _, group in ipairs(self:Extra(d).loot or {}) do
        for _, e in ipairs(group.items) do
          local item = P.ItemDetails(e.id)
          if not item then
            pending = true
          else
            local delta, slot, at = G:SourceUpgrade(item, token, specId, level, ahead)
            local cur = delta and best[slot]
            if delta and (not cur or delta > cur.delta) then
              best[slot] = { slot = slot, slotName = G:SlotName(slot), itemId = e.id, link = item.link, delta = delta,
                needLevel = at > level and at or nil, dungeon = d, boss = group.boss }
            end
          end
        end
      end
    end
  end
  -- shortcut: iki yuvali esyalar (yuzuk, trinket, tek el) Compare'in sectigi zayif yuvaya yazilir; ikinci yuzuk onerisi
  -- kaybolabilir, gerekirse diger yuvayi da ayrica karsilastir.
  local out = {}
  for _, u in pairs(best) do
    out[#out + 1] = u
    counts[u.dungeon.id] = (counts[u.dungeon.id] or 0) + 1
  end
  table.sort(out, function(a, b) return a.slot < b.slot end)
  return out, counts, pending
end

-- Zindan anahtarlari (Data/DungeonKeys.lua) -------------------------------------------------------------
-- Oyuncunun zinciri: iki tarafa ortak (all) ya da kendi tarafininki.
function Journal:KeyChain(k, player)
  local c = k.chain or {}
  return c.all or (player and player.faction and c[player.faction]) or {}
end

-- Anahtar sende mi: "bag" (cantada, bankada ya da anahtarlikta), "done" (zincirin son gorevi bitti; esya baska
-- yerde olabilir) ya da nil.
function Journal:HasKey(k, player)
  if (P.ItemCount(k.item, true) or 0) > 0 or P.KeyringHas(k.item) then return "bag" end
  local chain = self:KeyChain(k, player)
  local last = chain[#chain]
  if last and P.IsQuestFlaggedCompleted(last) then return "done" end
  return nil
end

-- Anahtarin adimlari: once zincir gorevleri (on gorev satiri bicimi: ad, veren, bolge, x/y 0-100, bitti/gunlukte),
-- sonra gorev olmayan adimlar ({ text = metin, npc?, zone? }).
function Journal:KeySteps(k, player)
  local out, givers = {}, ns.BrainData and ns.BrainData.givers or {}
  for _, q in ipairs(self:KeyChain(k, player)) do
    local g, alt = givers[q], k.giver or {}
    out[#out + 1] = { q = q, name = P.QuestName(q, g and g[1] or ("#" .. q)), lv = g and g[3] or nil,
      npc = g and g[6] or alt.npc, zone = g and g[7] or alt.zone,
      x = g and g[8] and g[8] * 100 or alt.x, y = g and g[9] and g[9] * 100 or alt.y,
      done = P.IsQuestFlaggedCompleted(q) and true or false, taken = P.IsQuestInLog(q) and true or false }
  end
  for _, s in ipairs(k.steps or {}) do
    out[#out + 1] = { text = ns:LocalizedText(s.text), npc = s.npc, zone = s.zone, x = s.x, y = s.y }
  end
  return out
end

-- Bu zindana giren anahtarlar: { { key, name, have, steps }, ... }
function Journal:Keys(d, player)
  local out = {}
  for _, k in ipairs(ns.DungeonKeys or {}) do
    for _, id in ipairs(k.dungeons or {}) do
      if id == d.id then
        out[#out + 1] = { key = k, name = P.ItemName(k.item) or k.n or ("#" .. k.item), have = self:HasKey(k, player),
          steps = self:KeySteps(k, player) }
        break
      end
    end
  end
  return out
end

-- Zindan girisleri: ana giris once, sonra alt girisler (Maraudon'un mor kapisi gibi). Her biri
-- { name?, zone, map, x, y (0-100), path = { { x, y, kind }, ... } }; haritasi cozulemeyen giris atlanir.
local GAME_SAME = 30   -- yard: oyunun isareti bundan yakinsa bizim nokta (ve yaklasma yolu) kalir
-- Portal yer altinda / bina icinde mi: yaklasma yolunda yuzeyden ayrilan ilk nokta (bina kapisi, magara agzi,
-- inilen delik, asansor, su, zincir) "kapi"dir. Haritada isaret ve "nereden girilir" bu noktadir; portalin kendi
-- koordinati yuzeyde bos bir yer gosterir (Deadmines: Moonbrook'taki binadan madene inilir, portal cok batida).
local HIDDEN = { jump = true, cave = true, building = true, swim = true, elevator = true, chain = true, passage = true }
Journal.HIDDEN_KINDS = HIDDEN
function Journal.Door(e)
  for i, p in ipairs(e and e.path or {}) do
    if HIDDEN[p[3]] then return { x = p[1], y = p[2], kind = p[3], index = i } end
  end
  return nil
end

local WING_CLEAR = 60   -- yd: ayni adli kanatlardan en yakini digerinden bu kadar yakin degilse kanat belirsiz
local PATH_KEEP = 150   -- yd: oyunun / kaydin portali verimizden bu kadar yakinsa yaklasma yolu ve kapi korunur

function Journal:Entrances(d)
  local out = {}
  local function add(e, name)
    if not (e and e.x and e.y) then return end
    local map = e.map or (e.zone and ns.Zones and ns.Zones:Resolve(e.zone))
    if map then
      local entry = { name = name, zone = e.zone, map = map, x = e.x, y = e.y, path = e.path or {} }
      entry.door = Journal.Door(entry)
      out[#out + 1] = entry
    end
  end
  add(d.entrance)
  for _, a in ipairs(d.alt or {}) do add(a, a.name) end
  -- oyunun kendi giris isareti verimizden uzaksa o kullanilir (Forever bazi kapilari tasidi, ornek Stockade);
  -- yer cok degistiyse yaklasma yolu (ve kapi) eski yere gore cizildigi icin birakilir, az kaydiysa korunur
  local main = out[1]
  local seen = main and self.db.seenEntrance and self.db.seenEntrance[d.id]
  local g = main and (seen or self:GameEntrance(d, main))
  if g and g.off > GAME_SAME then
    main.x, main.y, main.game = g.x, g.y, true
    if g.off > PATH_KEEP then main.path, main.door = {}, nil end
  end
  return out
end

local GAME_NEAR = 300   -- yard: ad tutmazsa (oyun baska dilde) bu kadar yakindaki isaret ayni zindan sayilir
local gameCache = {}

local function plain(s) return (s or ""):lower():gsub("^the ", ""):gsub("[^%w]", "") end

-- Oyunun bu zindan icin giris isareti, girisimizin haritasinda: { x, y (0-100), off = bize uzaklik (yd) } ya da nil.
-- Once girisin bolge haritasi, sonra kita haritasi sorulur; eslesme adla, yoksa en yakin (GAME_NEAR icinde).
function Journal:GameEntrance(d, e)
  local now = P.Now()
  local hit = gameCache[d.id]
  if hit and (hit.ok or now - hit.at < 60) then return hit.ok end
  local c = P.WorldPos(e.map, e.x / 100, e.y / 100)
  local maps = { e.map, c and P.ContinentMap(c) }
  local best, bd
  for _, m in ipairs(maps) do
    for _, g in ipairs(P.DungeonEntrances(m)) do
      local x, y = P.MapPosOn(m, g.x, g.y, e.map)
      local dist = x and P.PointDistance(e.map, e.x / 100, e.y / 100, e.map, x, y)
      if dist then
        local named = plain(g.name) == plain(d.name)
        local score = named and -1 or dist
        if (named or dist <= GAME_NEAR) and (not bd or score < bd) then
          best, bd = { x = x * 100, y = y * 100, off = dist, name = g.name }, score
        end
      end
    end
    if best then break end
  end
  gameCache[d.id] = { ok = best, at = now }
  return best
end
Journal._gameCache = gameCache

-- Yol adimi turu -> yazi (kendi kisa ifadelerimiz).
function Journal:StepText(kind)
  local t = {
    path = L["Follow the path"], jump = L["Jump down here"], swim = L["Swim under the water"],
    elevator = L["Take the elevator down"], stairs = L["Take the stairs"], bridge = L["Cross the bridge"],
    cave = L["Enter the cave"], building = L["Enter the building"], ramp = L["Go up the ramp"],
    chain = L["Climb the chain"], balcony = L["Jump to the balcony"], passage = L["Take the passage down"],
  }
  return t[kind] or t.path
end

-- Giris icin oyuncuya gore durum: uzaklik (yard) ya da "baska kita" / bilinmez.
-- Dondurur: yards (sayi) | nil, otherContinent (bool)
function Journal:Distance(e)
  local yards = P.VectorTo(e.map, e.x / 100, e.y / 100)
  if yards then return yards, false end
  local c1 = P.PlayerWorldPos()
  local c2 = P.WorldPos(e.map, e.x / 100, e.y / 100)
  return nil, (c1 and c2 and c1 ~= c2) or false
end

-- Oku girise yonlendir: yaklasma yolu varsa ok disaridan yolu izler, etiketin altinda "Entrance: <zindan>".
function Journal:PointTo(d, e)
  e = e or self:Entrances(d)[1]
  if not (e and ns.Nav) then return false end
  local path
  if e.path and #e.path > 0 then
    path = {}
    for i, p in ipairs(e.path) do path[i] = { p[1] / 100, p[2] / 100 } end
  end
  local label = e.name and (d.name .. " - " .. e.name) or d.name
  ns.Nav:SetTarget(e.map, e.x / 100, e.y / 100, label, "journal", 25, path, nil,
    path and { sub = d.name, kind = "cave" } or nil)
  return true
end

-- Dunya haritasini girisin bolgesinde ac (savasta acilmaz: korumali panel).
function Journal:ShowOnMap(d, e)
  e = e or self:Entrances(d)[1]
  if not e or P.InLockdown() then return false end
  if OpenWorldMap then pcall(OpenWorldMap, e.map)
  elseif WorldMapFrame and WorldMapFrame.SetMapID then
    pcall(function() if ShowUIPanel then ShowUIPanel(WorldMapFrame) end; WorldMapFrame:SetMapID(e.map) end)
  end
  return true
end

-- Esyanin kaynagi: zindan ve boss (ilk eslesme).
function Journal:ItemSource(itemId)
  for _, d in ipairs(ns.DungeonData or {}) do
    for _, group in ipairs(self:Extra(d).loot or {}) do
      for _, e in ipairs(group.items) do
        if e.id == itemId then return d, group.boss, e end
      end
    end
  end
end

function Journal:Lines(d)
  local lines = {
    L["%s - level %d-%d"]:format(d.zone, d.minLevel, d.maxLevel),
    L["Bosses: %s"]:format(table.concat(d.bosses, ", ")),
  }
  local notes = d.notes and ns:LocalizedText(d.notes)
  if notes and notes ~= "" then lines[#lines + 1] = L["Tip: %s"]:format(notes) end
  local e = self:Entrances(d)[1]
  if e then lines[#lines + 1] = L["Entrance: %s (%.1f, %.1f)"]:format(e.zone or "?", e.x, e.y) end
  if e and e.door then
    lines[#lines + 1] = L["Way in: %s at %.1f, %.1f (the portal is underground or inside, follow the arrow from there)"]
      :format(self:StepText(e.door.kind), e.door.x, e.door.y)
  end
  local how = d.how and ns:LocalizedText(d.how)
  if how and how ~= "" then lines[#lines + 1] = L["Getting there: %s"]:format(how) end
  return lines
end

-- Takip listesi
function Journal:IsTracked(itemId) return self.char.wishlist[itemId] ~= nil end

function Journal:Track(itemId, on)
  if on == nil then on = not self:IsTracked(itemId) end
  if on then
    local d = self:ItemSource(itemId)
    self.char.wishlist[itemId] = d and d.id or true
    -- zaten giyilebilen esya icin "artik giyebilirsin" hatirlatmasi gelmesin
    local item = P.ItemDetails(itemId)
    if item and (item.minLevel or 0) <= P.PlayerLevel() then self.char.notified["w" .. itemId] = true end
  else
    self.char.wishlist[itemId] = nil
    self.char.notified["w" .. itemId] = nil
  end
  return on
end

-- Takip edilen esyalar: { { id, dungeon, boss, item, entry } } (zindan sirasina gore).
function Journal:Tracked()
  local out = {}
  for _, d in ipairs(ns.DungeonData or {}) do
    for _, group in ipairs(self:Extra(d).loot or {}) do
      for _, e in ipairs(group.items) do
        if self:IsTracked(e.id) then out[#out + 1] = { id = e.id, dungeon = d, boss = group.boss, entry = e, item = P.ItemDetails(e.id) } end
      end
    end
  end
  return out
end

function Journal:Notify(text, kind, prio)
  if ns.Toast then ns.Toast:Show(text, kind or "info", nil, nil, { prio = prio, cat = "dungeon" }) end
end

-- Seviye ya da esya bilgisi degisince: takip edilen esya giyilebilir oldu mu / zindan seviyene geldi mi.
function Journal:CheckReminders()
  if not self.db.remind then return end
  local level = P.PlayerLevel()
  local perDungeon = {}
  for _, t in ipairs(self:Tracked()) do
    perDungeon[t.dungeon.id] = (perDungeon[t.dungeon.id] or 0) + 1
    local key = "w" .. t.id
    if t.item and (t.item.minLevel or 0) <= level and not self.char.notified[key] then
      self.char.notified[key] = true
      self:Notify(L["You can use %s now (%s)."]:format(t.item.name, t.dungeon.name))
    end
  end
  for id, count in pairs(perDungeon) do
    local d = self:Get(id)
    local key = "d" .. id
    if d and self:Status(d, level) == "now" and not self.char.notified[key] then
      self.char.notified[key] = true
      self:Notify(L["%s fits your level - tracked items: %d."]:format(d.name, count), nil, "low")
    end
  end
end

-- Zindandan gorev rehberi (Guide/DungeonGuides.lua): zindanin gorevleri ve onlari acan zincir, oyuncuya gore sirali.
-- Rehber sekmesi olarak acilir (Engine:TabList); birakilan rehber kendi sekmesinde kalir. "Geri don" rehberi en son
-- kullanilan zindan disi sekmedir; zindan rehberinin "next"i odur: bitince adim penceresi ona donmeyi onerir,
-- autoReturn aciksa kendiliginden doner ve biten zindan sekmesi kapanir.
function Journal:HasGuide(d, player)
  local DG = ns.DungeonGuides
  return DG and DG:Plan(d, player or P.PlayerInfo()) ~= nil or false
end

function Journal:GuideId(d, player)
  player = player or P.PlayerInfo()
  return ns.DungeonGuides.Id(d.id, player.faction)
end

-- Su an bu zindanin rehberi mi calisiyor?
function Journal:GuideActive(d)
  local g = ns.Engine and ns.Engine.guide
  return g ~= nil and d ~= nil and g.id == self:GuideId(d)
end

local function notDungeon(g) return not g.dungeon end

-- Donulecek rehber: calisan zindan disi rehber, yoksa en son kullanilan zindan disi sekme
local function backGuide(except)
  local E = ns.Engine
  local cur = E.guide
  if cur and not cur.dungeon and cur.id ~= except then return cur end
  return E:RecentTab(except, notDungeon)
end

function Journal:BuildGuide(d, player)
  local id = ns.DungeonGuides:Register(d, player or P.PlayerInfo())
  local g = id and ns.Guides:Get(id)
  local back = backGuide(id)
  if g then g.next = back and back.id or nil end
  return id
end

function Journal:StartGuide(d)
  local E = ns.Engine
  local id = self:BuildGuide(d)
  if not id then ns:Print(L["No quests for your character in this dungeon."]) return false end
  E:OpenGuide(id)
  ns:Print(L["Started: %s"]:format(ns.Guides:TitleOf(ns.Guides:Get(id))))
  local DG = ns.DungeonGuides
  local summary = DG:SummaryText(DG:Summary(d))
  if summary then ns:Print(summary) end
  return true
end

-- Birakilan rehber: en son kullanilan zindan disi sekme (yoksa seviyeye uygun oneri)
function Journal:ReturnGuide()
  local cur = ns.Engine.guide
  return ns.Engine:RecentTab(cur and cur.id, notDungeon) or ns.Guides:Suggest(P.PlayerInfo())
end

-- Sekmesine gecer (biten zindan rehberinin sekmesi Engine:NoteTab'da kapanir)
function Journal:ReturnToGuide()
  local g = self:ReturnGuide()
  if not g then return false end
  ns.Engine:OpenGuide(g.id)
  ns:Print(L["Back to %s"]:format(ns.Guides:TitleOf(g)))
  return true
end

function Journal:OnGuideFinished(_, id)
  local g = id and ns.Guides:Get(id)
  if not (g and g.dungeon and self.db.autoReturn) then return end
  local function back()
    local cur = ns.Engine.guide
    if cur and cur.id == id then Journal:ReturnToGuide() end   -- bu arada baska sekmeye gecildiyse dokunma
  end
  if P.After(0, back) then return end
  back()
end

-- Seviye gelince sor
function Journal:CheckSuggest()
  if not self.db.suggest then return end
  if P.InCombat and P.InCombat() then self.suggestPending = true return end
  local player = P.PlayerInfo()
  local list = self:ForLevel(P.PlayerLevel(), player)
  local fresh = {}
  for _, d in ipairs(list) do if not self.char.asked[d.id] then fresh[#fresh + 1] = d end end
  if #fresh == 0 then return end
  table.sort(fresh, function(a, b) return a.minLevel > b.minLevel end)   -- seviyeye en yeni girilen
  for _, d in ipairs(fresh) do self.char.asked[d.id] = true end
  if ns.DungeonPrompt then ns.DungeonPrompt:Show(fresh[1]) end
end

function Journal:OnLevelUp()
  self:CheckSuggest()
  self:CheckReminders()
end

-- Giris kaydi: yukleme ekrani baslarken (portala girildi) oyuncunun disaridaki yeri saklanir; icerisi bir zindansa o
-- yer zindanin girisi olarak hesaba yazilir (db.seenEntrance). Oyunun giris isaretleri Forever'da bos, veri bazi
-- kapilarda yanlis; oyuncunun kendi girisi en dogru kaynak.
local SEEN_MAX = 1500   -- yard: verimizden bu kadar uzaktaki "giris" isinlanmadir (zindan bulucu, buyu), kaydedilmez
function Journal:OnLeavingWorld()
  if P.InstanceInfo() then self.leftAt = nil return end
  local map, x, y = P.PlayerMapPosition()
  self.leftAt = map and { map = map, x = x, y = y, at = P.Now() } or nil
end

function Journal:NoteEntrance()
  local from = self.leftAt
  self.leftAt = nil
  local name = P.InstanceInfo()
  if not (from and name) or P.Now() - from.at > 120 then return end
  -- ayni adi tasiyan kanatlar (Scarlet Monastery, Dire Maul, Stratholme): girilen yere en yakin verideki kapi;
  -- iki kanadin kapisi birbirine cok yakinsa hangisi oldugu bilinemez, kaydedilmez
  local lname = name:lower()
  local cands = {}
  for _, c in ipairs(ns.DungeonData or {}) do
    local ce = c.entrance
    local cm = ce and ce.zone and ns.Zones and ns.Zones:Resolve(ce.zone)
    if cm and (c.name:lower():find(lname, 1, true) or lname:find(c.name:lower(), 1, true)) then
      local cd = P.PointDistance(cm, ce.x / 100, ce.y / 100, from.map, from.x, from.y)
      if cd then cands[#cands + 1] = { d = c, dist = cd, map = cm } end
    end
  end
  table.sort(cands, function(a, b) return a.dist < b.dist end)
  local best = cands[1]
  if not best or (cands[2] and cands[2].dist - best.dist < WING_CLEAR) then return end
  local d, e, map, dist = best.d, best.d.entrance, best.map, best.dist
  if dist > SEEN_MAX then return end
  local x, y = P.MapPosOn(from.map, from.x, from.y, map)
  if not x then return end
  self.db.seenEntrance = self.db.seenEntrance or {}
  self.db.seenEntrance[d.id] = { x = x * 100, y = y * 100, off = dist }
  if dist > GAME_SAME then ns:Print(L["%s: entrance saved (%.1f, %.1f)"]:format(d.name, x * 100, y * 100)) end
  if ns.MapMarkers and ns.MapMarkers.Invalidate then   -- harita isareti hemen yeni yere
    ns.MapMarkers:Invalidate()
    if ns.MapMarkers.RefreshAll then ns.SafeCall(ns.MapMarkers.RefreshAll, ns.MapMarkers) end
  end
end

function Journal:OnEnteringWorld()
  self:NoteEntrance()
  local function run() Journal:CheckSuggest(); Journal:CheckReminders() end
  if C_Timer and C_Timer.After then C_Timer.After(6, run) else run() end
end

function Journal:OnRegen()
  if self.suggestPending then
    self.suggestPending = false
    self:CheckSuggest()
  end
end

function Journal:OnItemInfo(_, itemId, success)
  -- yalniz takip edilen esya; sunucunun tanimadigi esya (success = false) istek -> olay -> istek dongusu kurmasin
  if success == false or not self.char.wishlist[itemId] then return end
  if self.itemPending then return end
  self.itemPending = true
  local function run() Journal.itemPending = false; Journal:CheckReminders() end
  if C_Timer and C_Timer.After then C_Timer.After(1, run) else run() end
end

-- Boss yaratik turu, oyunda ogrenilir (ayar db.bossTypes): verimizdeki bir boss hedef alininca oyunun verdigi tur
-- ("Undead"...) ve sinif ("elite", "worldboss") hesap geneli db.bossInfo[boss adi]'na yazilir; gunlukte boss basliginda.
local bossNames
function Journal:BossName(name)
  if not bossNames then
    bossNames = {}
    for _, extra in pairs(ns.DungeonExtras or {}) do
      for _, g in ipairs(extra.loot or {}) do if type(g.boss) == "string" then bossNames[g.boss:lower()] = g.boss end end
    end
  end
  return type(name) == "string" and bossNames[name:lower()] or nil
end

function Journal:NoteTarget(unit)
  if self.db.bossTypes == false then return nil end
  local u = P.UnitCreatureInfo(unit or "target")
  local boss = u and u.type and self:BossName(u.name)
  if not boss then return nil end
  self.db.bossInfo = self.db.bossInfo or {}
  self.db.bossInfo[boss] = { type = u.type, class = u.class }
  return boss
end

function Journal:BossTitle(boss)
  local i = self.db.bossTypes ~= false and self.db.bossInfo and self.db.bossInfo[boss]
  return i and (boss .. "  -  " .. i.type) or boss
end

function Journal:OnEnable()
  ns:On("PLAYER_TARGET_CHANGED", self, function(j) j:NoteTarget("target") end)
  ns:On("PLAYER_LEVEL_UP", self, "OnLevelUp")
  ns:On("PLAYER_ENTERING_WORLD", self, "OnEnteringWorld")
  ns:On("PLAYER_LEAVING_WORLD", self, "OnLeavingWorld")
  ns:On("PLAYER_REGEN_ENABLED", self, "OnRegen")
  ns:On("GET_ITEM_INFO_RECEIVED", self, "OnItemInfo")
  ns:Listen("ARCANIS_GUIDE_FINISHED", self, "OnGuideFinished")
end

ns:RegisterCommand("dungeon", function(args)
  local player = P.PlayerInfo()
  local sub, rest = (args or ""):match("^(%S*)%s*(.-)$")
  if sub == "" or sub == "open" then
    local d = Journal:Find(rest)
    if ns.DungeonWindow then
      if d then ns.Journal.focus = d.id; ns.DungeonWindow:Open() else ns.DungeonWindow:Toggle() end
      return
    end
  end
  if sub == "list" then args = "" end
  if sub == "back" then
    if not Journal:ReturnToGuide() then ns:Print(L["Guide not found: %s"]:format("?")) end
    return
  end
  if sub == "way" then
    local d = Journal:Find(rest)
    if not (d and Journal:PointTo(d)) then ns:Print(L["Dungeon not found."]) end
    return
  end
  if sub == "check" then
    -- girislerimizi oyunun isaretleriyle karsilastir; sonuc hesap kaydinda (veri dosyasi sonra buna gore duzeltilir)
    local res, n, bad = {}, 0, 0
    for _, d in ipairs(ns.DungeonData or {}) do
      local e = d.entrance
      local map = e and e.zone and ns.Zones and ns.Zones:Resolve(e.zone)
      if map then
        gameCache[d.id] = nil
        local g = Journal:GameEntrance(d, { map = map, x = e.x, y = e.y })
        n = n + 1
        res[d.id] = { zone = e.zone, x = e.x, y = e.y, gx = g and g.x, gy = g and g.y, off = g and g.off, gname = g and g.name }
        if not g then
          ns:Print(L["%s: no game marker found"]:format(d.name))
        elseif g.off > GAME_SAME then
          bad = bad + 1
          ns:Print(L["%s: off by %d yd (ours %.1f, %.1f; game %.1f, %.1f)"]:format(d.name, g.off, e.x, e.y, g.x, g.y))
        end
      end
    end
    Journal.db.entranceCheck = res
    ns:Print(L["Entrances checked: %d, off: %d."]:format(n, bad))
    return
  end
  if sub == "start" then
    local d = Journal:Find(rest)
    if d then Journal:StartGuide(d) else ns:Print(L["Dungeon not found."]) end
    return
  end
  local d = Journal:Find(args)
  if d then
    ns:Print(d.name)
    for _, line in ipairs(Journal:Lines(d)) do ns:Print(line) end
    local quests = Journal:Quests(d, player)
    ns:Print(L["Quests: %d, loot sources: %d."]:format(#quests, #(Journal:Extra(d).loot or {})))
    return
  end
  local level = P.PlayerLevel()
  local names = {}
  for _, x in ipairs(Journal:List(player)) do
    local tag = Journal:Status(x, level) == "now" and "*" or ""
    names[#names + 1] = ("%s%s (%d-%d)"):format(tag, x.name, x.minLevel, x.maxLevel)
  end
  ns:Print(L["Dungeons: %s"]:format(table.concat(names, ", ")))
end, "[open [name] | list | <name> | start <name> | back] dungeon journal")
