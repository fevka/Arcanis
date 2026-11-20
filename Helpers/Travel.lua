-- Arcanis: yolculuk yardimcisi (modul "Travel"). Ucus ve hearthstone adimlarini otomatik ilerletir,
-- ucus haritasi acilinca hedefi hatirlatir. (Ucusu baslatmak korumali eylemdir; oyuncu kendisi secer.)
-- Gorev Beyni icin karakter basina ogrenir:
--   * ocak tasi konumu: ocak tasi bir hana baglaninca (HEARTHSTONE_BOUND) oyuncu hancinin yanindadir; ocak tasi
--     kullanilip varilinca da konum dogrulanir
--   * bilinen ucus noktalari: ucus haritasi acildiginda oyuncu ucus ustasinin yanindadir (ucus yolunu ogrendigi yer)
-- Konumlar dunya koordinatinda (kita, wx, wy) ve harita koordinatinda (ok icin) saklanir. Ek veri gerekmez.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Travel = ns:NewModule("Travel", {
  -- flightTimes: ucus haritasi ipucunda sure; autoTaxi: gorevi olmayan ucus ustasinda harita hemen acilir (Shift: acilmaz)
  defaults = { enabled = true, remind = true, learn = true, flights = {}, flightTimes = true, autoTaxi = true },
  charDefaults = { nodes = {} },
})
ns.Travel = Travel

local HEARTH_SPELLS = { [8690] = true, [556] = true }   -- Ocak tasi, Astral Recall
local HEARTHSTONE = 6948
local ARRIVE_WINDOW = 60   -- saniye: ocak tasindan sonra bu sure icinde ilk konum varis sayilir

local function stepOf(type_)
  local step = ns.Engine and ns.Engine:GetStep()
  if step and step.type == type_ then return step end
  return nil
end

local function now() return (GetTime and GetTime()) or os.time() end

-- Oyuncunun su anki konumu: { c, x, y, map, mx, my } ya da nil.
local function here()
  local c, wx, wy = P.PlayerWorldPos()
  if not c then return nil end
  local map, mx, my = P.PlayerMapPosition()
  return { c = c, x = wx, y = wy, map = map, mx = mx, my = my }
end

-- Ogrenme
function Travel:RememberHearth(reason)
  if not self.db.learn then return end
  local pos = here()
  if not pos then return end
  pos.name = P.BindLocation() or P.SubZoneText()
  pos.via = reason
  self.char.hearth = pos
end

local NODE_SAME = 80   -- yard: bu kadar yakin iki kayit ayni ucus noktasidir

-- Ucus noktasi ekle/guncelle: yakinda kayit varsa o guncellenir (oyuncunun durdugu yer ile ucus haritasindaki
-- nokta birkac yard farkli olur). Anahtar konum hucresi: ayni adli iki nokta birbirini ezmesin.
local function upsertNode(nodes, pos)
  for _, n in pairs(nodes) do
    if n.c == pos.c and math.abs(n.x - pos.x) < NODE_SAME and math.abs(n.y - pos.y) < NODE_SAME then
      for k, v in pairs(pos) do if v ~= nil and not (k == "name" and pos.weakName and n.name) then n[k] = v end end
      n.weakName = nil
      return n
    end
  end
  local key = ("%s:%d:%d"):format(tostring(pos.c), math.floor(pos.x / 100), math.floor(pos.y / 100))
  local base, n = key, 1
  while nodes[key] do n = n + 1; key = base .. "#" .. n end   -- ayni hucrede iki ayri nokta: ikisi de kalir
  nodes[key] = pos
  return pos
end

function Travel:RememberNode()
  if not self.db.learn then return end
  local pos = here()
  if not pos then return end
  pos.name = P.SubZoneText() or "?"
  pos.weakName = true   -- alt bolge adi; ucus haritasindaki gercek ad gelince o yazilir
  self.char.nodes = self.char.nodes or {}
  upsertNode(self.char.nodes, pos)
end

-- Ucus haritasindaki bilinen (gidilebilir) noktalarin hepsi ogrenilir; durulan nokta "current".
-- Donus: durulan noktanin adi (ucus suresi olcumu icin) ya da nil.
function Travel:LearnTaxiMap()
  if not self.db.learn then return nil end
  self.char.nodes = self.char.nodes or {}
  local current
  for _, n in ipairs(P.TaxiNodes()) do
    if n.state ~= "none" then
      upsertNode(self.char.nodes, { name = n.name, c = n.c, x = n.wx, y = n.wy, map = n.map, mx = n.x, my = n.y })
      if n.state == "current" then current = n.name end
    end
  end
  return current
end

-- Bilinen ocak tasi konumu (bagli yer degismediyse) ya da nil.
function Travel:Hearth()
  local h = self.char and self.char.hearth
  if not h then return nil end
  local bind = P.BindLocation()
  if bind and h.name and bind ~= h.name then return nil end   -- baska yere baglanmis: eski konum gecersiz
  return h
end

-- Ocak tasina kalan bekleme (sn; 0 hazir) ya da nil (tas yok / bilinmiyor). Bekleme plana sure olarak girer:
-- 3 dk sonra hazir olacak tas 15 dk'lik yurumeyi yine gecebilir.
-- "Ready in 2:30." (ocak tasi / teleport beklemesi)
function Travel.ReadyIn(sec)
  sec = math.max(0, math.floor(sec + 0.5))
  return L["Ready in %s."]:format(("%d:%02d"):format(math.floor(sec / 60), sec % 60))
end

function Travel:HearthWait()
  if (P.ItemCount(HEARTHSTONE) or 0) < 1 then return nil end
  local cd = P.ItemCooldown(HEARTHSTONE)
  if cd == nil then return nil end
  return cd <= 2 and 0 or cd   -- 1.5 s global bekleme "hazir degil" sayilmasin (oneri titremesin)
end

function Travel:KnownNodes()
  local out = {}
  for _, n in pairs((self.char and self.char.nodes) or {}) do out[#out + 1] = n end
  table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
  return out
end

-- Yolculuk planlayicisi: yurume, ucus, ocak tasi ve ocak tasi + ucus sureleri (saniye) karsilastirilir.
local RUN = 7              -- yd/s kosu
local MOUNT_LEVEL, MOUNT_MUL = 40, 1.6
-- shortcut: binek sahipligi bilinmiyor, 40+ seviye binekli sayilir; yanlis cikarsa GetUnitSpeed ornekleriyle olc
local FLY_SPEED = 30       -- yd/s, olculmemis ucusun tahmini (rota egriligi icin mesafe x1.25), bilinmeyen kitada
-- Olculmemis ucusun suresi: kita basina kus ucusu mesafeyle dogrusal model { sn/yd, sabit sn }. Katsayilar ornek ucus
-- surelerinden (Eastern Kingdoms 128, Kalimdor 158 rota) goreli hataya gore uyduruldu; sure tablosu tasinmaz.
-- Ortanca hata ~%13 / %10. Oyunda olculen sure her zaman once gelir.
local FLIGHT_MODEL = { [0] = { 0.0406, 15 }, [1] = { 0.0421, 10 } }
local TAXI_OVERHEAD = 20   -- s: ucus ustasiyla konusma, kalkis, inis
local HEARTH_TIME = 25     -- s: 10 s okuma + yukleme
local MIN_SAVE, MAX_RATIO = 60, 0.75   -- en az 1 dk ve yurumenin en cok %75'i: kucuk kazanc icin rota degismez

local function hypot(ax, ay, bx, by) local dx, dy = bx - ax, by - ay return math.sqrt(dx * dx + dy * dy) end

-- Alliance kasabasindaki iskeleler (Data/Transit.lua docks adlari)
local ALLIANCE_DOCKS = {
  ["Menethil Harbor"] = true, ["Theramore"] = true, ["Rut'theran Village"] = true, ["Auberdine"] = true,
  ["Stormwind"] = true, ["Southshore"] = true, ["Feathermoon"] = true,
}

-- Ogrenilmis ucus noktasinin Data/Transit.lua kimligi: ayni kitada 100 yard icindeki en yakin nokta.
local NODE_MATCH = 100
local tidCache = setmetatable({}, { __mode = "k" })   -- nokta tablosu -> kimlik (yoksa false); plan her cift icin sorar
local function dataNode(n)
  local T = ns.Transit
  if not (T and n and n.c and n.x) then return nil end
  local hit = tidCache[n]
  if hit and hit.x == n.x and hit.y == n.y then return hit.id or nil end
  local best, bd = nil, NODE_MATCH * NODE_MATCH
  for id, d in pairs(T.nodes) do
    if d[1] == n.c then
      local dx, dy = d[2] - n.x, d[3] - n.y
      if dx * dx + dy * dy < bd then best, bd = id, dx * dx + dy * dy end
    end
  end
  tidCache[n] = { id = best or false, x = n.x, y = n.y }   -- nokta guncellenirse (upsertNode) konum degisir, yeniden bulunur
  return best
end

-- Veri paketindeki yonlu ucus suresi (sn) ya da nil. Paket artik ucus suresi tasimaz (oyunda olculur);
-- tablo verilirse kullanilir.
function Travel:DataFlight(a, b)
  local t = ns.Transit and ns.Transit.flights
  if not t then return nil end
  local ia, ib = dataNode(a), dataNode(b)
  return ia and ib and t[ia .. ">" .. ib] or nil
end

function Travel:NodeNamed(name)
  for _, n in pairs((self.char and self.char.nodes) or {}) do if n.name == name then return n end end
end

-- Ucus agi (Data/TaxiPaths.lua: dogrudan yollarin gercek uzunlugu): a'dan b'ye oyuncunun bildigi noktalardan gecen
-- en kisa zincir (aktarmali ucus). Donus: toplam yard ya da nil (ag yok / noktalardan biri veride yok); false: agda
-- bilinen noktalardan yol yok (bu ucus yapilamaz).
function Travel:TaxiLength(a, b)
  local TP = ns.TaxiPaths
  local ia, ib = TP and dataNode(a), TP and dataNode(b)
  if not (ia and ib) then return nil end
  -- bilinen noktalar degismedikce her baslangicin en kisa yollari bir kez hesaplanir (plan 2 sn'de bir sorar)
  local known, n = {}, 0
  for _, k in pairs((self.char and self.char.nodes) or {}) do
    local id = dataNode(k)
    if id and not known[id] then known[id], n = true, n + 1 end
  end
  local cache = self.taxiCache
  if not (cache and cache.n == n and cache.tp == TP) then cache = { n = n, tp = TP, from = {} }; self.taxiCache = cache end
  local dist = cache.from[ia]
  if not dist then
    known[ia] = true
    dist = { [ia] = 0 }
    local done = {}
    while true do
      local u, du
      for id, d in pairs(dist) do if not done[id] and (not du or d < du) then u, du = id, d end end
      if not u then break end
      done[u] = true
      for id in pairs(known) do
        local len = not done[id] and TP.len[u .. ">" .. id]
        if len and (not dist[id] or du + len < dist[id]) then dist[id] = du + len end
      end
    end
    cache.from[ia] = dist
  end
  if dist[ib] then return dist[ib] end
  -- hedef bilinen noktalar arasinda degil: ona dogrudan yolu olan en iyi noktadan son ayak
  local best
  for id, d in pairs(dist) do
    local len = TP.len[id .. ">" .. ib]
    if len and (not best or d + len < best) then best = d + len end
  end
  return best or false
end

-- Sure: once kendi olcumun, sonra veri paketi, sonra ucus agindaki yol uzunlugu, yoksa mesafeden tahmin. Ikinci
-- donus: olculmus/bilinen mi. Ucus aginda bilinen noktalardan yol yoksa nil (bu cift uculamaz).
function Travel:FlightTime(a, b)
  local key = tostring(a.name) .. ">" .. tostring(b.name)
  local t = (self.db.flights and self.db.flights[key]) or self:DataFlight(a, b)
  if t then return t, true end
  local len = self:TaxiLength(a, b)
  if len == false then return nil, false end
  if len then return len / ns.TaxiPaths.speed + ns.TaxiPaths.base, false end
  local d = hypot(a.x, a.y, b.x, b.y)
  local m = a.c ~= nil and a.c == b.c and FLIGHT_MODEL[a.c]
  return m and (d * m[1] + m[2]) or (d * 1.25 / FLY_SPEED), false
end

-- Hedef dunya konumuna (c, x, y) en hizli yol. Donus: secenekler listesi (en hizlisi basta), her biri
-- { kind = "walk"|"fly"|"hearth"|"hearth_fly", time, from, to, saves } ve yurume suresi (baska kitada nil).
-- Yalniz yuruyusten belirgin hizli secenekler listelenir; yurume her zaman sonda (karsilastirma icin).
-- Tahmini yer hizi (yd/s): kosu, 40+ seviyede binekli.
-- Olcum: oyunun verdigi kosu hizi (binekliyken binegin); karakterin gorulen en yuksek yer hizi saklanir (yolculukta
-- bineceksin), ucusta / yuzerken / tuhaf degerde yazilmaz. Olcum yoksa: 40+ seviye binekli varsayilir.
local MAX_GROUND = 20
function Travel:Speed()
  local cur = not P.OnTaxi() and P.RunSpeed()
  if self.char and cur and cur > (self.char.speed or 0) and cur <= MAX_GROUND then self.char.speed = cur end
  local seen = self.char and self.char.speed
  if seen and seen > RUN then return seen end
  return RUN * (((P.PlayerLevel() or 1) >= MOUNT_LEVEL) and MOUNT_MUL or 1)
end

function Travel:Plan(c, x, y)
  local c1, x1, y1 = P.PlayerWorldPos()
  if not (c and c1) then return {}, nil end
  local speed = self:Speed()
  local function walk(ax, ay, bx, by) return hypot(ax, ay, bx, by) / speed end
  local byC = {}
  for _, n in ipairs(self:KnownNodes()) do
    if n.c then byC[n.c] = byC[n.c] or {}; table.insert(byC[n.c], n) end
  end
  -- (sx, sy) baslangicindan (tx, ty) noktasina ayni kitada ucarak: en iyi A -> B cifti
  local function bestFly(sc, sx, sy, tx, ty)
    local nodes = byC[sc] or {}
    if #nodes < 2 then return nil end
    local best, from, to
    for _, a in ipairs(nodes) do
      local toA = walk(sx, sy, a.x, a.y)
      if not best or toA < best then   -- A'ya yurumek zaten en iyiyi geciyorsa B'lere bakilmaz
        for _, b in ipairs(nodes) do
          if b ~= a then
            local ft = self:FlightTime(a, b)   -- nil: bilinen noktalardan bu ciftin arasinda ucus yolu yok
            local t = ft and (toA + TAXI_OVERHEAD + ft + walk(b.x, b.y, tx, ty))
            if t and (not best or t < best) then best, from, to = t, a, b end
          end
        end
      end
    end
    return best, from, to
  end
  local walkT = (c1 == c) and walk(x1, y1, x, y) or nil
  local opts = {}
  local t, a, b
  if c1 == c then t, a, b = bestFly(c1, x1, y1, x, y) end
  if t then opts[#opts + 1] = { kind = "fly", time = t, from = a, to = b } end
  local h = self:Hearth()
  local hw = h and h.c == c and self:HearthWait()
  if hw then
    opts[#opts + 1] = { kind = "hearth", time = hw + HEARTH_TIME + walk(h.x, h.y, x, y), place = h, wait = hw }
    t, a, b = bestFly(h.c, h.x, h.y, x, y)
    if t then opts[#opts + 1] = { kind = "hearth_fly", time = hw + HEARTH_TIME + t, place = h, from = a, to = b, wait = hw } end
  end
  -- baska kitadaki adim: bu kitadaki iskeleden hedef kitaya giden gemi / zeplin (zeplinler Horde'un).
  -- Sure: iskeleye (yuru ya da uc) + ortalama bekleme (yarim donem) + yolculuk + varistan hedefe (yuru ya da uc).
  local TR = ns.Transit
  if c1 ~= c and TR then
    local horde = (P.PlayerInfo() or {}).faction == "Horde"
    -- Horde, muhafizli Alliance iskelesine (Menethil, Theramore, Auberdine...) gonderilmez
    local function allianceStop(r)
      for _, s in ipairs(r.stops) do
        local d = TR.docks[s[1]]
        if d and ALLIANCE_DOCKS[d[4]] then return true end
      end
      return false
    end
    local TP = ns.Transport
    for id, r in pairs(TR.routes) do
      if (r.kind ~= "zeppelin" or horde) and not (horde and allianceStop(r)) then
        for _, s in ipairs(r.stops) do
          local d = TR.docks[s[1]]
          if d and d[1] == c1 then
            for _, e in ipairs(r.stops) do
              local f = TR.docks[e[1]]
              if f and f[1] == c then
                local toDock = walk(x1, y1, d[2], d[3])
                local ft, fa, fb = bestFly(c1, x1, y1, d[2], d[3])
                if ft and ft < toDock then toDock = ft else fa, fb = nil, nil end
                local fromDock = math.min(walk(f[2], f[3], x, y), bestFly(c, f[2], f[3], x, y) or math.huge)
                -- bekleme: hat olculduyse iskeleye varistan sonraki gercek kalkis, yoksa yarim donem
                local wait = TP and TP.DepartureWait and TP:DepartureWait(id, s, toDock)
                local known = wait ~= nil
                wait = wait or r.period / 2000
                local ride = ((e[2] - s[3]) % r.period) / 1000
                opts[#opts + 1] = { kind = "boat", ship = r.kind, time = toDock + wait + ride + fromDock, wait = wait,
                  waitKnown = known, dock = { name = d[4], c = d[1], x = d[2], y = d[3] }, dest = f[4], from = fa, to = fb }
              end
            end
          end
        end
      end
    end
  end
  -- sinif teleportu (Mage sehirleri, Teleport: Moonglade): bilinen buyu, reagent var; bekleme sure olarak eklenir
  for _, tp in ipairs(ns.Transit and ns.Transit.teleports or {}) do
    local spell, tc, tx, ty, reagent = tp[1], tp[2], tp[3], tp[4], tp[5]
    if tc == c and P.KnowsSpell(spell) and (reagent == 0 or (P.ItemCount(reagent) or 0) > 0) then
      local cd = P.SpellCooldown(spell) or 0
      cd = cd <= 2 and 0 or cd
      opts[#opts + 1] = { kind = "teleport", time = cd + HEARTH_TIME + walk(tx, ty, x, y), spell = spell, wait = cd,
        place = { name = P.SpellName(spell) or ("#" .. spell), c = tc, x = tx, y = ty } }
    end
  end
  local out = {}
  for _, o in ipairs(opts) do
    if not walkT or (walkT - o.time >= MIN_SAVE and o.time <= walkT * MAX_RATIO) then
      o.saves = walkT and (walkT - o.time)
      out[#out + 1] = o
    end
  end
  table.sort(out, function(p, q) return p.time < q.time end)
  if walkT then out[#out + 1] = { kind = "walk", time = walkT } end
  return out, walkT
end

-- Ucus suresi olcumu: secim (TakeTaxiNode) yalniz hazirlar; saat ucus gercekten baslayinca (kontrol kaybi +
-- UnitOnTaxi) baslar. Para yetmeyen / iptal edilen secim ya da sonraki bir korku-sersemletme olcum yazmaz.
-- Olcum hesap geneli kaydedilir (yol ayni).
function Travel:OnTakeTaxi(to)
  self.flight = (to and self.taxiFrom) and { from = self.taxiFrom, to = to } or nil
end

function Travel:StartFlightClock()
  local f = self.flight
  if not f or f.t then return end
  if P.OnTaxi() then f.t = now() else self.flight = nil end
end

function Travel:OnControlGained()
  local f = self.flight
  if not f or not f.t or P.OnTaxi() then return end
  self.flight = nil
  local secs = now() - f.t
  if secs < 10 or secs > 1800 then return end   -- iptal / yukleme / takilma
  self.db.flights = self.db.flights or {}
  self.db.flights[f.from .. ">" .. f.to] = math.floor(secs + 0.5)
end

-- Su anki rehber adimi icin ucus plani simdi yeniden hesaplanir (okun son etiketinden kalan Nav.flyTo eskiyebilir:
-- adim degistikten sonra hesaplanmamis olabilir). Ucus planin en iyisiyse varis noktasinin adi, yoksa nil.
function Travel:PlannedFlight()
  local E, Nav = ns.Engine, ns.Nav
  local step = E and E:GetStep()
  if not (step and Nav and Nav.FlyFirst and ns.Zones) then return nil end
  local map, x, y = ns.Zones:Location(step)
  if not map then return nil end
  local ok, fly = pcall(Nav.FlyFirst, step, map, x, y)
  if ok and fly and (fly.kind == "fly" or fly.kind == "boat") and fly.to then return fly.to.name end
  -- en hizlisi ocak tasi olsa da ucus ustasindaysan en iyi ucus parlar (oyuncu ucmayi secti)
  local c, wx, wy = P.WorldPos(map, x, y)
  if not c then return nil end
  for _, o in ipairs((self:Plan(c, wx, wy))) do
    if o.kind == "fly" and o.to then return o.to.name end
  end
  return nil
end

-- Olaylar
-- Ucus haritasi acildi: ucus noktasini ogren; aktif adim "fly" ise nereye gidilecegini hatirlat.
function Travel:OnTaxiOpened()
  self.taxiFrom = self:LearnTaxiMap()
  -- ucus haritasi API'si yoksa (ya da durulan nokta okunamadiysa) oyuncunun konumu ucus noktasi olarak kaydedilir
  if not self.taxiFrom then self:RememberNode() end
  local step = stepOf("fly")
  local dest = (step and step.to) or Travel:PlannedFlight()
  -- durdugun nokta hedef olamaz (eski plan "Stormwind'e uc" diyordu, oyuncu Stormwind'deydi; 17 Kasim 2026)
  if dest and self.taxiFrom then
    local a, b = dest:lower():match("^([^,]+)"), self.taxiFrom:lower():match("^([^,]+)")
    if a == b then dest = nil end
  end
  -- haritadaki noktalar pencere acildiktan hemen sonra cizilir: kisa gecikmeyle bulunur
  if dest and not (P.After and P.After(0.2, function() ns.SafeCall(Travel.HighlightTaxi, Travel, dest) end)) then
    self:HighlightTaxi(dest)
  end
  if not (P.After and P.After(0.2, function() ns.SafeCall(Travel.HookTaxiTooltips, Travel) end)) then self:HookTaxiTooltips() end
  if not self.db.remind then return end
  if dest then ns.Toast:Show(L["Choose the flight to %s."]:format(dest), "info", nil, nil, { prio = "low", cat = "travel" }) end
end

-- Ucus haritasinda gidilecek noktayi parlatir (yanip sonen hale); harita kapaninca gizlenir.
function Travel:HighlightTaxi(name)
  local node = P.TaxiNodeFrame(name)
  local g = self.taxiGlow
  if not node then if g then g:Hide() end return false end
  if not g then
    g = CreateFrame("Frame", nil, UIParent)
    g:SetSize(44, 44)
    g.tex = g:CreateTexture(nil, "OVERLAY")
    g.tex:SetAllPoints()
    g.tex:SetTexture(ns.Skin.Icons.glow)
    g.tex:SetBlendMode("ADD")
    -- noktanin ustunde kendi ucus rozetimiz (yolculuk onerileriyle ayni ikon): nereye ucacagin ilk bakista belli
    g.badge = g:CreateTexture(nil, "OVERLAY", nil, 2)
    g.badge:SetSize(24, 24)
    g.badge:SetPoint("BOTTOM", g, "TOP", 0, -10)
    g.badge:SetTexture("Interface\\AddOns\\Arcanis\\Media\\UI\\travel_fly.tga")
    g:SetScript("OnUpdate", function(f, elapsed)
      f.t = (f.t or 0) + elapsed
      if not (f.node and f.node:IsVisible()) then f:Hide() return end
      f.tex:SetAlpha(0.55 + 0.45 * math.sin(f.t * 5))
      f.badge:SetPoint("BOTTOM", f, "TOP", 0, -10 + 3 * math.sin(f.t * 3))   -- hafif yukari asagi
    end)
    self.taxiGlow = g
  end
  local c = ns.Skin.Colors.progress or { 0.4, 0.85, 0.5 }
  g.tex:SetVertexColor(c[1], c[2], c[3])
  g.node = node
  g:SetParent(node)
  g:SetFrameLevel((node:GetFrameLevel() or 1) + 5)
  g:ClearAllPoints()
  g:SetPoint("CENTER", node, "CENTER")
  g:Show()
  return true
end

-- Ucus haritasi ipucu satiri: durulan noktadan `name`e sure ("Flight time: 2:10", olculmemisse "~") ya da nil.
function Travel:TaxiTimeText(name)
  local from, to = self.taxiFrom and self:NodeNamed(self.taxiFrom), name and self:NodeNamed(name)
  if not (from and to) or from == to then return nil end
  local t, known = self:FlightTime(from, to)
  if not t then return nil end
  local clock = ns.Island and ns.Island.Clock and ns.Island.Clock(t) or tostring(math.floor(t + 0.5))
  return L["Flight time: %s"]:format((known and "" or "~") .. clock)
end

-- Haritadaki her nokta cercevesine bir kez OnEnter kancasi; cerceveler havuzdan yeniden kullanildigi icin ad her
-- acilista guncellenir. Blizzard ipucunu kurduktan sonra satir eklenir.
function Travel:HookTaxiTooltips()
  if not self.db.flightTimes then return end
  for _, n in ipairs(P.TaxiNodeFrames()) do
    local f = n.frame
    f.__arcanisTaxi = n.name
    if not f.__arcanisHooked and f.HookScript then
      f.__arcanisHooked = true
      f:HookScript("OnEnter", function(frame)
        if not (Travel.db.flightTimes and GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(frame)) then return end
        local text = Travel:TaxiTimeText(frame.__arcanisTaxi)
        if text then GameTooltip:AddLine(text, 0.40, 0.85, 1.00); GameTooltip:Show() end
      end)
    end
  end
end

-- Gorevi olmayan ucus ustasi: ucus haritasi hemen acilir (konusma penceresi atlanir). Shift basiliyken ya da NPC
-- gorev veriyor / teslim aliyorsa acilmaz.
function Travel:OnGossip()
  if not self.db.autoTaxi or P.IsShiftDown() then return end
  local avail, active = P.GossipQuests()
  if (avail and #avail > 0) or (active and #active > 0) then return end
  P.SelectGossipOption(P.GossipTaxiOption())
end

-- Ucus basladi: "fly" adimi tamam.
function Travel:OnControlLost()
  self:StartFlightClock()
  if P.OnTaxi() and stepOf("fly") then ns.Engine:Next() end
end

-- Hearthstone okuyuldu: "hearth" adimi tamam; varis konumu beklenir.
function Travel:OnCast(_, unit, _, spellId)
  if unit ~= "player" or (issecretvalue and issecretvalue(spellId)) or not HEARTH_SPELLS[spellId] then return end
  self.hearthCastAt = now()
  if stepOf("hearth") then ns.Engine:Next() end
  -- ayni bolge icinde isinlanirsa "yeni bolge" olayi gelmez: kisa bir sure sonra konum yine de alinir
  local this = self
  if P.After then
    P.After(2, function() this:OnArrive() end)
    P.After(8, function() this:OnArrive() end)   -- uzun yukleme ekrani
  end
end

-- Ocak tasindan sonra varildi: varis noktasi ocak tasi konumudur. Yukleme ekranindan once gelen olaylar eski
-- konumu verebilir; yalniz oyuncu GERCEKTEN bagli oldugu yerdeyse (alt bolge adi = bagli yer) kaydedilir,
-- yoksa pencere suresince beklenir.
function Travel:OnArrive()
  if not self.hearthCastAt then return end
  if now() - self.hearthCastAt > ARRIVE_WINDOW then self.hearthCastAt = nil return end
  local bind, sub = P.BindLocation(), P.SubZoneText()
  if bind and sub and bind == sub then
    self.hearthCastAt = nil
    self:RememberHearth("arrive")
  end
end

function Travel:OnEnable()
  ns:On("TAXIMAP_OPENED", self, "OnTaxiOpened")
  ns:On("GOSSIP_SHOW", self, "OnGossip")
  ns:On("PLAYER_CONTROL_LOST", self, "OnControlLost")
  ns:On("PLAYER_CONTROL_GAINED", self, "OnControlGained")
  if not self.taxiHooked then
    self.taxiHooked = true
    P.OnTakeTaxi(function(to) Travel:OnTakeTaxi(to) end)
  end
  ns:On("UNIT_SPELLCAST_SUCCEEDED", self, "OnCast", "player")
  ns:On("HEARTHSTONE_BOUND", self, function(t) t:RememberHearth("bound") end)
  ns:On("PLAYER_ENTERING_WORLD", self, "OnArrive")
  ns:On("ZONE_CHANGED_NEW_AREA", self, "OnArrive")
  ns:On("ZONE_CHANGED", self, "OnArrive")
  ns:On("ZONE_CHANGED_INDOORS", self, "OnArrive")   -- han ici alt bolge
end
