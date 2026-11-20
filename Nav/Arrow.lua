-- Arcanis: yon oku (modul "Nav").
--
-- Hedef: aktif adimin konumu (ARCANIS_STEP_CHANGED) ya da elle konulan nokta (/wf way).
--   ns.Nav:SetTarget(map, x, y, label, source, radius)   x,y 0-1
--   ns.Nav:ClearTarget()   ns.Nav:Update()
local _, ns = ...

local P = ns.Provider
local L = ns.L
local M = ns.NavMath

local function Skin_SetFont(fs, size)
  if ns.Skin and ns.Skin.SetFont then ns.Skin:SetFont(fs, size, "OUTLINE") end
end

local Nav = ns:NewModule("Nav", {
  defaults = {
    locked = false, hidden = false, scale = 1, point = "CENTER", relPoint = "CENTER", x = 0, y = -180,
    style = "3D",                            -- Media/Arrow<style>.tga
    size = 64,                               -- ok boyutu (piksel)
    color = { 0.86, 0.62, 0.20 },            -- ok rengi (TGA beyaz tabanli; renk burada verilir)
    alpha = 1,
    arriveColor = true,                      -- varinca yesile don
    showDistance = true, showLabel = true,
    textSize = 14,
    distColor = { 1, 0.82, 0 },              -- mesafe yazisi
    labelColor = { 1, 1, 1 },                -- adim yazisi
  },
})
ns.Nav = Nav

local MEDIA = "Interface\\AddOns\\Arcanis\\Media\\Arrow"   -- + stil + ".tga"; yukari bakan ok
local ARRIVE = { 0.2, 1, 0.2 }
Nav.styles = { "3D", "Chevron", "Dart", "Needle" }

function Nav:StylePath(style)
  return MEDIA .. (style or self.db.style or "3D") .. ".tga"
end

-- 3D ok: tools/make_arrow3d.py ile 64 yone onceden cizilmis 8x8 sayfa (kare i = i*360/64 derece, saat yonunun
-- tersi); aci kareyi secer, doku dondurulmez. Diger stiller tek resim, SetRotation ile doner.
local SHEET_COLS, SHEET_FRAMES = 8, 64
function Nav.SetHeading(tex, style, angle)
  if style == "3D" then
    local i = math.floor((angle or 0) / (2 * math.pi) * SHEET_FRAMES + 0.5) % SHEET_FRAMES
    local c, r = i % SHEET_COLS, math.floor(i / SHEET_COLS)
    tex:SetRotation(0)
    tex:SetTexCoord(c / SHEET_COLS, (c + 1) / SHEET_COLS, r / SHEET_COLS, (r + 1) / SHEET_COLS)
  else
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetRotation(angle or 0)
  end
end
local UPDATE = 0.05        -- ok donusu (s)
local TEXT_UPDATE = 0.25   -- mesafe metni (s)
local DEFAULT_RADIUS = 10  -- yard
local PATH_REACH = 12      -- yard: yol noktasina bu kadar yaklasinca siradakine gecilir
local HINT_NEAR = 80       -- yard: hedefe bu kadar yaklasinca ipucu (ust kat, magara...) etiketin altinda gorunur
local HINT_COLOR = "|cffffd24a"
local ENTRANCE_COLOR = "|cff7fd4ff"   -- giris satiri: ipucundan ayri renk (once girise git)

-- Adimin yer ipucu: rehber notu (tip) ya da gorev ipucu kategorisi (Hints). Yoksa nil.
function Nav.StepHint(step)
  if not step then return nil end
  local tip = step.tip and ns:LocalizedText(step.tip)
  if tip and tip ~= "" then return tip end
  return ns.Hints and ns.Hints.For and ns.Hints:For(step) or nil
end

Nav.target = nil
Nav.acc = 0
Nav.textAcc = 0

function Nav:GetTarget()
  return self.target
end

-- Magara / maden / mezar / bina girisi (Data/Entrances.lua): hedef icerideyse yol once giristen gecer.
-- Adim magara isaretliyse (step.cave) ya da ipucu "icerde" diyorsa (bina, kat, magara, maden, mezar) daha genis aranir.
local INSIDE_HINT = { building = true, upstairs = true, downstairs = true, cave = true, mine = true, crypt = true, tent = true }
local function insideHint(step)
  local h = step.quest and ns.BrainData and ns.BrainData.hints and ns.BrainData.hints[step.quest]
  if not h then return false end
  local codes = (step.type == "accept" and h.a) or (step.type == "turnin" and h.t) or (h.o and h.o[step.objective or 1])
  for _, c in ipairs(type(codes) == "table" and codes or {}) do if INSIDE_HINT[c] then return true end end
  return false
end

-- Hedef (harita 0-1) bir girisin icindeyse: yol { giris, iceri yol noktalari } (0-1) ve giris kaydi; yoksa nil.
function Nav.Entrance(step, map, x, y)
  local list = ns.Entrances
  if not (list and step and map and x and y) or step.path then return nil end
  local tc, tx, ty = P.WorldPos(map, x, y)
  if not tc then return nil end
  local flagged = step.cave or insideHint(step)
  local best, bestD
  for _, e in ipairs(list) do
    if ns.Zones:Resolve(e.zone) == map then
      -- bina kapisi dar alan; magara genis (icerideki is noktalari seyrek)
      local lim = e.kind == "building" and (flagged and 25 or 10) or (flagged and 150 or 50)
      local function check(p)
        local c, wx, wy = P.WorldPos(map, p[1] / 100, p[2] / 100)
        local d = c and P.WorldDistance(tc, tx, ty, c, wx, wy)
        if d and d <= lim and (not bestD or d < bestD) then best, bestD = e, d end
      end
      for _, p in ipairs(e.inside or {}) do check(p) end
      for _, p in ipairs(e.path or {}) do check(p) end
    end
  end
  if not best then return nil end
  -- hedef girisin kendisindeyse (disaridan ulasilir) yol gerekmez
  local ec, ex, ey = P.WorldPos(map, best.x / 100, best.y / 100)
  local de = ec and P.WorldDistance(tc, tx, ty, ec, ex, ey)
  if de and de <= (best.r or 15) then return nil end
  local path = { { best.x / 100, best.y / 100 } }
  for _, p in ipairs(best.path or {}) do path[#path + 1] = { p[1] / 100, p[2] / 100 } end
  return path, best
end

-- Yolun nereden baslanacagi: yalniz hedefe oyuncudan YAKIN (yol ustundeki) noktalar sayilir, aralarindan oyuncuya en
-- yakini. Rehberin yol noktalari rotanin kendi gelis yonunu varsayar; oyuncu baska yerden geliyorsa (Planner sapmasi,
-- liste secimi) geri gonderilmez, hic uygun nokta yoksa dogrudan hedefe (#path + 1). Giris yolu: disaridaysan giris.
function Nav.PathStart(t)
  local path = t.path
  if not (path and #path > 0) then return 1 end
  -- sehir yolu oyuncunun bulundugu yerden baslar: ilk kose (kopru, kapi) yandan / geriden gitse de atlanmaz
  if t.city or t.zone then return 1 end   -- bolge yolu da: gecitler sirayla
  local dT = P.VectorTo(t.map, t.x, t.y)
  if t.entrance and not P.IsIndoors() then
    -- bina: oyuncu hedefe kapidan daha yakinsa (zaten iceride / kapinin otesinde) kapiya geri gonderilmez
    if t.entrance.kind == "building" and dT then
      local door = P.PointDistance(t.map, path[1][1], path[1][2], t.map, t.x, t.y)
      if door and dT < door then return #path + 1 end
    end
    return 1
  end
  local tc, tx, ty = P.WorldPos(t.map, t.x, t.y)
  if not (dT and tc) then return 1 end
  local best, bd
  for i, pt in ipairs(path) do
    local d = P.VectorTo(t.map, pt[1], pt[2])
    local c, wx, wy = P.WorldPos(t.map, pt[1], pt[2])
    local toT = c and P.WorldDistance(c, wx, wy, tc, tx, ty)
    if d and toT and toT < dT and d < dT and (not bd or d < bd) then best, bd = i, d end
  end
  return best or (#path + 1)
end

-- Yol noktasi i geride mi: yanina gelindi ya da oyuncu siradaki noktaya (son noktada hedefe) bu noktanin
-- kendisinden yakin (kose kesildi, nokta kacirildi -> ok geri donmez). Giris yolunda disaridayken yalniz yanina gelmek
-- sayilir: magaranin ustunden gecerken giris atlanmasin.
function Nav.PathPassed(t, i)
  local path = t.path
  local pt = path[i]
  local d = P.VectorTo(t.map, pt[1], pt[2])
  if d and d <= PATH_REACH then return true end
  if not d or (t.entrance and not P.IsIndoors()) then return false end
  -- sehir yolunda kose yalniz yakina (12 yd) gelince kesilebilir: duvarin / kanalin obur yanindan gecilmesin
  if t.city and d > 12 then return false end
  local nx, ny = t.x, t.y
  if path[i + 1] then nx, ny = path[i + 1][1], path[i + 1][2] end
  local dn = P.VectorTo(t.map, nx, ny)
  local c1, x1, y1 = P.WorldPos(t.map, pt[1], pt[2])
  local c2, x2, y2 = P.WorldPos(t.map, nx, ny)
  local seg = c1 and c2 and P.WorldDistance(c1, x1, y1, c2, x2, y2)
  return dn ~= nil and seg ~= nil and dn < seg
end

local function kindName(k)
  if k == "mine" then return L["Mine"] elseif k == "crypt" then return L["Crypt"] elseif k == "building" then return L["Building"] end
  return L["Cave"]
end

local CITY_MOVE = 8      -- yard: takilma (CITY_STALL) sayilmasi icin en az bu kadar yurunmus olmali
local CITY_OFF = 15      -- yard: siradaki yol parcasindan bu kadar uzaklasan oyuncu icin yol yeniden hesaplanir
local CITY_STALL = 10    -- sn: siradaki noktaya bu kadar sure ilerleme yoksa yol yeniden hesaplanir

-- Oyuncunun sehir yolundaki siradaki parcaya (onceki nokta ya da yolun basi -> siradaki nokta ya da hedef) uzakligi (yd).
function Nav.OffCityPath(t, c, wx, wy)
  local path, i = t.path, t.pathAt or 1
  if not (path and #path > 0) then return nil end
  local function w(pt)
    local pc, x, y = P.WorldPos(t.map, pt[1], pt[2])
    if pc == c then return x, y end
  end
  local ax, ay
  if i > 1 and path[i - 1] then ax, ay = w(path[i - 1]) elseif t.cityFrom then ax, ay = t.cityFrom[1], t.cityFrom[2] end
  local bx, by
  if path[i] then bx, by = w(path[i]) else bx, by = w({ t.x, t.y }) end
  if not (ax and bx) then return nil end
  local dx, dy = bx - ax, by - ay
  local len2 = dx * dx + dy * dy
  local u = len2 > 0 and math.max(0, math.min(1, ((wx - ax) * dx + (wy - ay) * dy) / len2)) or 0
  local px, py = ax + u * dx - wx, ay + u * dy - wy
  return math.sqrt(px * px + py * py)
end
local SAME_TARGET = 15   -- yard: bu kadar kayan hedef "ayni" sayilir (yol ilerlemesi korunur, ok zipllamaz)

local function samePath(a, b)
  if not (a and b) then return a == b end
  if #a ~= #b then return false end
  for i = 1, #a do if a[i][1] ~= b[i][1] or a[i][2] ~= b[i][2] then return false end end
  return true
end

-- Hedef ayni yer mi (kaynak ayni, yol ayni, en cok SAME_TARGET yard kaymis)
function Nav.SameTarget(t, map, x, y, source, path)
  local tp   -- sehir yolu hesaplanmis hedefte verilen yol (basePath, cogu zaman nil) karsilastirilir
  if t and (t.city or t.zone) then tp = t.basePath elseif t then tp = t.path end
  if not (t and t.source == (source or "guide") and samePath(tp, path)) then return false end
  if t.map == map and t.x == x and t.y == y then return true end
  local d = P.PointDistance(t.map, t.x, t.y, map, x, y)
  return d ~= nil and d <= SAME_TARGET
end

function Nav:SetTarget(map, x, y, label, source, radius, path, hint, entrance)
  local old = self.target
  local same = old and Nav.SameTarget(old, map, x, y, source, path)
  local keepAt = same and old.pathAt or nil
  -- sehir icinde (Data/CityNav.lua) yol yoksa sokaklardan gecen yol hesaplanir; ayni hedefte eski sehir yolu kalir
  -- (oyuncu ilerledikce yeniden hesaplanip ok ziplamasin). basePath: verilen yol (SameTarget karsilastirmasi icin).
  local base, city = path, nil
  if not path and not entrance and ns.CityRoute then
    if same and old.city then path, city = old.path, true
    else
      local ok, r = pcall(ns.CityRoute.Route, ns.CityRoute, map, x, y)
      if ok and r then path, city, keepAt = r, true, nil end
    end
  end
  -- hedef baska bolgede: bolge gecitlerinden gecen yol (Nav/ZoneRoute.lua)
  local zone, zoneFrom
  if not path and not entrance and ns.ZoneRoute then
    zoneFrom = P.PlayerMapPosition()
    if same and old.zone and old.zoneFrom == zoneFrom then path, zone = old.path, true
    else
      local ok, r = pcall(ns.ZoneRoute.Route, ns.ZoneRoute, map, x, y)
      if ok and r then path, zone, keepAt = r, true, nil end
    end
  end
  self.target = { map = map, x = x, y = y, label = label, source = source or "guide", radius = radius, path = path, hint = hint,
    entrance = entrance, pathAt = keepAt, basePath = base, city = city, zone = zone, zoneFrom = zone and zoneFrom or nil }
  self:Update(true)
  ns:Send("ARCANIS_TARGET_CHANGED", self.target)
end

function Nav:ClearTarget()
  -- ok oyunun isaretini izliyordu (sag tik, Stop): haritadaki isaret de kalkar, iki yol ayri kalmasin
  if self.target and self.target.source == "waypoint" then P.ClearUserWaypoint() end
  self.target = nil
  self:Update(true)
  ns:Send("ARCANIS_TARGET_CHANGED", nil)
end

-- Elle konulan hedefi birakir, ok rehberin adimina doner (varinca, haritadaki isarete sag tik). Rehber hedefi kalir.
function Nav:DropTarget()
  local t = self.target
  if not (t and t.source ~= "guide") then return false end
  self.reachedFor = nil
  self:ClearTarget()
  if self.RefreshGuideTarget then ns.SafeCall(self.RefreshGuideTarget, self) end
  return true
end

-- Arayuz
function Nav:BuildFrame()
  if self.frame then return end
  local f = CreateFrame("Frame", "ArcanisArrow", UIParent)
  f:SetSize(160, 100)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")

  self.tex = f:CreateTexture(nil, "ARTWORK")
  self.tex:SetSize(56, 56)
  self.tex:SetPoint("TOP", f, "TOP", 0, 0)
  self.tex:SetTexture(self:StylePath())

  self.distText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.distText:SetPoint("TOP", self.tex, "BOTTOM", 0, -2)

  self.labelText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.labelText:SetPoint("TOP", self.distText, "BOTTOM", 0, -2)
  self.labelText:SetWidth(156)

  f:SetScript("OnDragStart", function(frame)
    if not Nav.db.locked then frame:StartMoving() end
  end)
  f:SetScript("OnDragStop", function(frame)
    frame:StopMovingOrSizing()
    local point, _, relPoint, x, y = frame:GetPoint()
    if point then
      Nav.db.point, Nav.db.relPoint, Nav.db.x, Nav.db.y = point, relPoint, x, y
    end
  end)

  self.frame = f
  self:ApplyStyle()
end

-- Stil, boyut, renk, saydamlik, metin ayarlarini uygular.
function Nav:ApplyStyle()
  local f, db = self.frame, self.db
  if not f then return end
  local size = math.max(24, math.min(160, db.size or 64))
  local width = math.max(160, size + 40)
  f:SetSize(width, size + 46)
  self.tex:SetSize(size, size)
  self.tex:SetTexture(self:StylePath(db.style))
  self.tex:SetAlpha(db.alpha or 1)
  self.labelText:SetWidth(width - 4)
  local fontSize = db.textSize or 14
  Skin_SetFont(self.distText, fontSize)
  Skin_SetFont(self.labelText, math.max(9, fontSize - 3))
  local dc, lc = db.distColor or { 1, 0.82, 0 }, db.labelColor or { 1, 1, 1 }
  self.distText:SetTextColor(dc[1], dc[2], dc[3], 1)
  self.labelText:SetTextColor(lc[1], lc[2], lc[3], 1)
  if db.showDistance then self.distText:Show() else self.distText:Hide() end
  if db.showLabel then self.labelText:Show() else self.labelText:Hide() end
  self.arrived = nil
  self:Update(true)
end

function Nav:ApplyPosition()
  local f = self.frame
  f:ClearAllPoints()
  f:SetPoint(self.db.point, UIParent, self.db.relPoint, self.db.x, self.db.y)
  f:SetScale(self.db.scale)
  if ns.Skin.Resnap then ns.Skin:Resnap() end   -- ince cizgiler yeni olcekte tam piksel
end

-- Hedefe gore oku dondurur, mesafe metnini gunceller. force: metni de hemen yenile.
function Nav:Update(force)
  local f = self.frame
  if not f then return end
  if not self:IsEnabled() then f:Hide() return end
  local t = self.target
  -- rehber adadaysa (UI/IslandGuide.lua) ok ekranda gorunmez ama hesaplanir: ada ayni yonu ve mesafeyi cizer
  local docked = ns.GuideDocked and ns.GuideDocked() or false
  if not t or (self.db.hidden and not docked) then
    f:Hide()
    self.heading = nil
    return
  end
  f:Show()
  if self.docked ~= docked then
    self.docked = docked
    f:SetAlpha(docked and 0 or 1)
    if f.EnableMouse then f:EnableMouse(not docked) end
  end
  local dist, east, south = P.VectorTo(t.map, t.x, t.y)
  -- hedefe yakinken yer ipucu etiketin altinda ("Upstairs in the building"): yaklasinca nereye bakacagini soyler
  local label = t.label or ""
  if t.hint and dist and dist <= HINT_NEAR then label = label .. "\n" .. HINT_COLOR .. t.hint .. "|r" end
  if force or self.shownLabel ~= label then
    self.labelText:SetText(label)
    self.shownLabel = label
  end

  -- yol noktalari (magara girisi gibi): ok siradaki noktaya doner, yakina gelince bir sonrakine gecer;
  -- mesafe yazisi hedefe olan uzakliktir
  -- bolge yolu: oyuncu baska bolgeye gecince (2 sn'de bir bakilir) kalan gecitlerden yeniden; hedefin bolgesine
  -- girince yol biter (sehir yolu ya da dogrudan)
  if t.zone and ns.ZoneRoute then
    local now = P.Now()
    if not t.zoneAt or now - t.zoneAt >= 2 then
      t.zoneAt = now
      local pm = P.PlayerMapPosition()
      if pm and pm ~= t.zoneFrom then
        local ok, r = pcall(ns.ZoneRoute.Route, ns.ZoneRoute, t.map, t.x, t.y)
        t.zoneFrom, t.pathAt = pm, nil
        if ok and r then t.path = r else t.path, t.zone = nil, nil end
      end
    end
  end
  -- hedef konulurken sehirde degildin (ya da yol bulunamadi): sehre girince 2 sn'de bir sokak yolu yeniden denenir
  if not t.path and not t.entrance and ns.CityRoute and dist and dist >= ns.CityRoute.MIN_YARDS then
    local now = P.Now()
    if not t.cityTried or now - t.cityTried >= 2 then
      t.cityTried = now
      local ok, r = pcall(ns.CityRoute.Route, ns.CityRoute, t.map, t.x, t.y)
      if ok and r then t.path, t.city, t.pathAt = r, true, nil end
    end
  end
  -- sehir yolu yalniz oyuncu yoldan saptiginda yeniden hesaplanir (A* bir karede onlarca ms surebilir): siradaki yol
  -- parcasina CITY_OFF yd'den uzak ya da CITY_STALL sn ilerleme yok (en cok 2 sn'de bir); yol uzerinde yuruyen oyuncu
  -- icin hic hesaplanmaz, PathPassed noktalari tuketir. Hedefe yaklasinca (yol yok) ok dogrudan gider.
  if t.city and dist then
    local now = P.Now()
    local c, wx, wy = P.PlayerWorldPos()
    if c and not t.cityFrom then
      t.cityFrom, t.cityAt, t.cityProg = { wx, wy }, now, now   -- yol az once (SetTarget) bu yerden hesaplandi
    elseif c and now - (t.cityAt or 0) >= 2 then
      if t.pathAt ~= t.cityLastAt then t.cityLastAt, t.cityProg = t.pathAt, now end
      local off = Nav.OffCityPath(t, c, wx, wy)
      local stalled = now - (t.cityProg or now) >= CITY_STALL
        and math.sqrt((wx - t.cityFrom[1]) ^ 2 + (wy - t.cityFrom[2]) ^ 2) >= CITY_MOVE
      if (off and off > CITY_OFF) or stalled then
        t.cityFrom, t.cityAt, t.cityProg = { wx, wy }, now, now
        local ok, r = pcall(ns.CityRoute.Route, ns.CityRoute, t.map, t.x, t.y)
        if ok then t.path, t.pathAt = r, nil end
      end
    end
  end
  local path = t.path
  if dist and path and #path > 0 then
    if not t.pathAt then t.pathAt = Nav.PathStart(t) end
    while t.pathAt <= #path and Nav.PathPassed(t, t.pathAt) do t.pathAt = t.pathAt + 1 end
    local pt = path[t.pathAt]
    if pt then
      local _, e2, s2 = P.VectorTo(t.map, pt[1], pt[2])
      if e2 then east, south = e2, s2 end
    end
    -- girise gidiliyor: etiketin altinda "Entrance: Fargodeep Mine" (oyuncu nereye girecegini bilsin)
    if t.entrance then
      local e = t.entrance
      local line = t.pathAt == 1 and (ENTRANCE_COLOR .. L["Entrance: %s"]:format(e.sub or kindName(e.kind)) .. "|r") or nil
      local full = line and ((t.label or "") .. "\n" .. line) or nil
      if full and self.shownLabel ~= full then self.labelText:SetText(full); self.shownLabel = full
      elseif not full and self.shownLabel ~= label then self.labelText:SetText(label); self.shownLabel = label end
    end
  end
  if not dist then
    -- konum yok (Deeprun Tram, zindan) ya da baska kita: yon bilinmez, eski yonu gosteren ok yaniltir -> ok gizli
    self.tex:SetAlpha(0)
    local c1, c2 = P.PlayerWorldPos(), P.WorldPos(t.map, t.x, t.y)
    self.noPosText = c1 and c2 and c1 ~= c2 and L["Other continent"] or L["No position here"]
    self.distText:SetText(self.noPosText)
    self.distLabel = nil   -- eski "123 yd" yazisi Tick'te geri gelmesin
    self.heading = nil
    return
  end
  self.tex:SetAlpha(self.db.alpha or 1)
  local facing = P.Facing()
  self.heading = M.Relative(M.Bearing(east, south), facing)
  Nav.SetHeading(self.tex, self.db.style, self.heading)
  local base = self.db.color or ARRIVE
  self.reached = dist <= (t.radius or DEFAULT_RADIUS)
  self.tint = (self.reached and self.db.arriveColor) and ARRIVE or base
  self.tex:SetVertexColor(self.tint[1], self.tint[2], self.tint[3])
  self.distLabel = M.FormatDistance(dist)
  if force then self.distText:SetText(self.distLabel) end
end

function Nav:Tick(elapsed)
  self.acc = self.acc + elapsed
  self.textAcc = self.textAcc + elapsed
  if self.acc < UPDATE then return end
  self.acc = 0
  local refreshText = self.textAcc >= TEXT_UPDATE
  if refreshText then self.textAcc = 0 end
  self:Update(false)
  if refreshText and self.distLabel then self.distText:SetText(self.distLabel) end
  -- elle konulan hedef (harita isareti, Shift + tik, oyunun isareti) varinca 2 sn sonra kalkar; rehber ve ceset kendi isini bilir
  local t = self.target
  if self.reached and t and t.source ~= "guide" and t.source ~= "corpse" then
    self.reachedFor = (self.reachedFor or 0) + UPDATE
    if self.reachedFor >= 2 then self:DropTarget() end
  else
    self.reachedFor = nil
  end
  -- ucus plani konuma bagli (ucus ustasina vardin, ucuyorsun, indin): rehber hedefi seyrek yeniden degerlendirilir
  self.planAcc = (self.planAcc or 0) + UPDATE
  if self.planAcc >= 2 then
    self.planAcc = 0
    if self.target and self.target.source == "guide" then ns.SafeCall(self.RefreshGuideTarget, self) end
  end
end

-- Uzak adim: bilinen ucus noktalariyla gitmek belirgin hizliysa (Travel:Plan, en az 1 dk ve yurumenin %75'i)
-- ok once kalkis ucus ustasina. Ucarken ve inince plan yurume der: ok adima doner. Rehberin kendi ucus /
-- ocak adiminda karismaz.
-- Adim baska kitadaysa (gemiyle varilan yerdeki "Fly to ..." adimi da) rehberin kendi ucus adimi da planlanir:
-- gemideyken { kind = "ride" }, yoksa en hizli gecis (iskele / iskeleye ucus, ocak tasi, teleport).
-- Kita degisince (Tick'te RefreshGuideTarget) plan yeni kitadan kurulur: siradaki ayak.
local CROSS_KINDS = { boat = true, hearth = true, hearth_fly = true, teleport = true }
-- Plan secimi titremesin: onceki secim hala listedeyse, yenisi onu kalan surenin %10'u (en az 30 sn) gecmedikce
-- degismez (iki ucus ustasi ya da ucmak / yurumek arasinda her 2 sn'de bir gidip gelmesin). Hedef degisince sifirlanir.
local STEADY_MIN, STEADY_SHARE = 30, 0.10
local function planKey(o)
  local function n(p) return p and (p.name or (p.x and ("%.0f,%.0f"):format(p.x, p.y))) or "" end
  return table.concat({ o.kind or "", n(o.from), n(o.to), n(o.dock), n(o.place), tostring(o.dest or "") }, "|")
end
function Nav.Steady(opts, c, wx, wy)
  local best = opts and opts[1]
  local goal = ("%s:%.0f:%.0f"):format(tostring(c), wx or 0, wy or 0)
  local prev = Nav.lastPlan
  if best and prev and prev.goal == goal then
    for _, o in ipairs(opts) do
      if planKey(o) == prev.key then
        if o ~= best and best.time > o.time - math.max(STEADY_MIN, STEADY_SHARE * o.time) then best = o end
        break
      end
    end
  end
  Nav.lastPlan = best and { goal = goal, key = planKey(best) } or nil
  return best
end

function Nav.FlyFirst(step, map, x, y)
  local c, wx, wy = P.WorldPos(map, x, y)
  if not c then return nil end
  local here = P.PlayerWorldPos()
  local cross = here ~= nil and here ~= c
  if P.OnTaxi() then
    -- ucarken: iskeleye ucus planinin ikinci asamasi (gemi) kaybolmasin; ayni hedefin planiysa "taxi" doner
    local last = Nav.lastPlan
    if cross and last and last.c == c and last.wx == wx and last.wy == wy and last.plan.kind == "boat" and last.plan.dock then
      local p = last.plan
      return { kind = "taxi", to = p.to, dock = p.dock, ship = p.ship, dest = p.dest }
    end
    return nil
  end
  if step.type == "hearth" or (step.type == "fly" and not cross) then return nil end
  if cross then
    local TP = ns.Transport
    local ride = TP and TP.RidingTo and TP:IsEnabled() and TP:RidingTo(c)
    if ride then return { kind = "ride", ship = ride.kind, dest = ride.dest } end
  end
  local T = ns.Travel
  if not (T and T.Plan and T.IsEnabled and T:IsEnabled()) then return nil end
  local best = Nav.Steady(T:Plan(c, wx, wy), c, wx, wy)
  if best then Nav.lastPlan = { plan = best, c = c, wx = wx, wy = wy } end
  if best and best.kind == "fly" and best.from and best.from.map and best.from.mx then return best end
  -- ocak tasi / teleport ayni kitada da: en hizlisiysa ok onu soyler (eskiden yalniz baska kitada; ayni kitada plan
  -- bos donuyor, ok "yuru" diyordu, pencere ise ocak tasini oneriyordu; 17 Kasim 2026)
  if best and CROSS_KINDS[best.kind] and (cross or best.kind ~= "boat") then return best end
  if best and best.kind == "boat" then return best end   -- baska kita: once iskeleye (ya da iskeleye ucus)
  return nil
end

-- Yolculuk onerisinin satir basi ikonu: hepsi ayni rozet stilinde kendi ikonlarimiz (tools/make_travel_icons.py,
-- Media/UI/travel_<tur>.tga). Gemide ship = "zeppelin" ise zeplin ikonu.
local TRAVEL_ICON = { hearth = "hearth", hearth_fly = "hearth", teleport = "teleport", fly = "fly", boat = "boat",
  ride = "boat", zeppelin = "zeppelin" }
function Nav.TravelIcon(kind, ship)
  local name = TRAVEL_ICON[kind]
  if not name then return "" end
  if name == "boat" and ship == "zeppelin" then name = "zeppelin" end
  return ("|TInterface\\AddOns\\Arcanis\\Media\\UI\\travel_%s.tga:20:20:0:0|t "):format(name)
end

-- Adim bir zindanin icinde (bolgesi haritaya cozulmuyor: Forever'da zindan ic haritasi yok) ve oyuncu disarida:
-- ok zindanin girisine, yaklasma yoluyla gider (Journal:PointTo gibi). Iceride konum yok, nil.
function Nav.DungeonDoor(step, label, hint)
  local J = ns.Journal
  if not (J and step and step.zone) or P.InstanceInfo() then return nil end
  local d = J:Find(step.zone)
  local e = d and J:Entrances(d)[1]
  if not e then return nil end
  local path
  if e.path and #e.path > 0 then
    path = {}
    for i, p in ipairs(e.path) do path[i] = { p[1] / 100, p[2] / 100 } end
  end
  -- yaklasma yolu varsa giris bilgisi: ok etiketin altina "Entrance: <zindan>" yazar; yolsuz giriste bolge / sehir
  -- yolu devreye girebilsin diye verilmez
  return e.map, e.x / 100, e.y / 100, label, hint, 25, path, path and { sub = d.name, kind = "cave" } or nil
end

-- Rehber adiminin ok hedefi: (map, x, y, etiket, ipucu, yaricap, yol, giris) ya da nil
local guideTargetRaw
-- Ocak tasi zamani mi (QuestItem paneli ocak tasini buyuk dugme olarak gosterir): degisince panel yenilenir.
local function guideTarget(step)
  Nav.hearthNow = false
  local r = { guideTargetRaw(step) }
  local due = Nav.hearthNow
  if due ~= Nav.hearthDue then
    Nav.hearthDue = due
    local QI = ns.QuestItem
    if QI and QI.Update and QI:IsEnabled() then ns.SafeCall(QI.Update, QI) end
  end
  return unpack(r, 1, 8)
end

guideTargetRaw = function(step)
  -- elle bakilan, gecilmis adim (bitti ya da "Not offered"): ok oraya gondermez
  if ns.Engine.manual and ns.Engine:IsStepDone(step) then return nil end
  local map, x, y = ns.Zones:Location(step)
  local label, hint = ns.Engine:Describe(step), Nav.StepHint(step)
  -- rehberin kendi ucus adimi da plandaki "Fly to X" gibi kus ikonuyla (17 Kasim 2026: ikon yalniz planda vardi)
  if step.type == "fly" then label = Nav.TravelIcon("fly") .. label end
  -- konumsuz yolculuk adimi (ocak tasi): ok kaybolmasin; ocak tasinin bagli oldugu yeri (yoksa adimin goturdugu
  -- isin yerini) gosterir, etiket ne yapilacagini soyler (17 Kasim 2026: "Hearth to Darkshire"da ok yok oluyordu)
  if not map and step.type == "hearth" then
    local T, h = ns.Travel, nil
    if T and T.Hearth then h = T:Hearth() end
    local hm, hx, hy
    if h and h.c then hm, hx, hy = P.ContinentMapPos(h.c, h.x, h.y) end
    if not hm then
      local nxt = ns.Engine.LeadsTo and ns.Engine:LeadsTo(step)
      if nxt then hm, hx, hy = ns.Zones:Location(nxt) end
    end
    if hm then
      local wait = T and T.HearthWait and T:HearthWait()
      local text = Nav.TravelIcon("hearth") .. label
      if wait and wait > 0 and T.ReadyIn then text = text .. " - " .. T.ReadyIn(wait) end
      Nav.flyTo, Nav.hearthNow = nil, true
      return hm, hx, hy, text, hint, 40, nil, nil
    end
  end
  if not map then return Nav.DungeonDoor(step, label, hint) end
  local fly = Nav.FlyFirst(step, map, x, y)
  -- yolculuk satirlari kisa: yer adinin bolge eki dusulur ("Booty Bay, Stranglethorn" -> "Booty Bay"); dar etikette
  -- satir kirilip kalabaliklasmasin
  local function short(n) return n and n:match("^([^,]+)") or n or "?" end
  local function shipText(f)
    return Nav.TravelIcon("boat", f.ship) .. (f.ship == "zeppelin" and L["Zeppelin to %s"] or L["Boat to %s"]):format(short(f.dest))
  end
  -- baska kitaya gecis: ok gizli kalir (yon yok), etiket ne yapilacagini soyler; ikinci satir adimin kendisi
  if fly and fly.kind == "ride" then
    Nav.flyTo = nil
    local text = Nav.TravelIcon("ride", fly.ship) .. (fly.ship == "zeppelin" and L["On the zeppelin to %s"] or L["On the boat to %s"]):format(fly.dest or "?")
    return map, x, y, text .. "\n" .. label, nil, step.radius, nil, nil
  end
  -- iskeleye ucuyor: kalan asama (gemi) etikette; ok iskeleyi hedefler (ucarken ok gizli, harita izi iskeleye)
  if fly and fly.kind == "taxi" then
    local d = fly.dock
    local dm, dx, dy = P.ContinentMapPos(d.c, d.x, d.y)
    local text = "1. " .. Nav.TravelIcon("fly") .. L["Flying to %s"]:format(short(fly.to and fly.to.name)) .. "\n2. " .. shipText(fly)
    if dm then return dm, dx, dy, text, label, 30, nil, nil end
    return map, x, y, text .. "\n" .. label, nil, step.radius, nil, nil
  end
  -- ocak tasi (sonra ucus olsa da su an yapilacak ocak tasi) ya da teleport
  if fly and (fly.kind == "hearth" or fly.kind == "hearth_fly" or fly.kind == "teleport") then
    Nav.flyTo = nil
    Nav.hearthNow = fly.kind ~= "teleport"
    local text = Nav.TravelIcon(fly.kind) .. (fly.kind == "teleport" and L["Cast %s"]:format(fly.place.name or "?")
      or L["Hearthstone to %s"]:format(fly.place.name or "?"))
    if fly.wait and fly.wait > 0 and ns.Travel.ReadyIn then text = text .. " - " .. ns.Travel.ReadyIn(fly.wait) end
    return map, x, y, text .. "\n" .. label, nil, step.radius, nil, nil
  end
  if fly and fly.kind == "boat" and not (fly.from and fly.from.map and fly.from.mx) then
    Nav.flyTo = nil
    local d = fly.dock
    local dm, dx, dy = P.ContinentMapPos(d.c, d.x, d.y)
    if not dm then return map, x, y, label, hint, step.radius, step.path, nil end
    return dm, dx, dy, shipText(fly), label, 30, nil, nil   -- ok iskeleyi gosterir: iskele adi yazilmaz
  end
  Nav.flyTo = fly and fly.to and fly.to.name or nil   -- ucus haritasi acilinca bu nokta parlar (Travel)
  if fly then
    local n = fly.from
    local flyText = Nav.TravelIcon("fly") .. L["Fly to %s"]:format(short(fly.to.name))
    -- iskeleye ucus: asama asama, satir basina bir is ("1. Fly to Booty Bay" / "2. Boat to Ratchet")
    local text = fly.kind == "boat" and ("1. " .. flyText .. "\n2. " .. shipText(fly)) or flyText
    return n.map, n.mx, n.my, text, label, nil, nil, nil
  end
  local path, ent = step.path, nil
  if not path then path, ent = Nav.Entrance(step, map, x, y) end
  return map, x, y, label, hint, step.radius, path, ent
end

-- Hedef kaynaklari
function Nav:OnStepChanged(_, _, _, step)
  local src = self.target and self.target.source
  if src == "manual" or src == "waypoint" then return end   -- elle konan nokta / oyunun isareti oncelikli
  if ns.Engine and ns.Engine.IsPaused and ns.Engine:IsPaused() then self:ClearTarget() return end   -- rehber duraklatildi
  local map, x, y, label, hint, radius, path, ent
  if step then map, x, y, label, hint, radius, path, ent = guideTarget(step) end
  if map then
    self:SetTarget(map, x, y, label, "guide", radius, path, hint, ent)
  else
    self:ClearTarget()
  end
end

-- Adim ayni kalsa da hedefin yeri / yazisi degisebilir (bir hedef bitti -> "1/6" -> "2/6", oyunun isareti,
-- ogrenilen NPC yeri, ucus plani): rehber hedefi yeniden hesaplanir; degismediyse dokunulmaz.
function Nav:RefreshGuideTarget()
  local t = self.target
  if t and t.source ~= "guide" then return end
  if ns.Engine and ns.Engine.IsPaused and ns.Engine:IsPaused() then return end
  local step = ns.Engine and ns.Engine:GetStep()
  if not step then return end
  local map, x, y, label, hint, radius, path, ent = guideTarget(step)
  if not map then return end
  if t and t.label == label and t.hint == hint and Nav.SameTarget(t, map, x, y, "guide", path) then return end
  self:SetTarget(map, x, y, label, "guide", radius, path, hint, ent)
end

function Nav:OnGuideFinished()
  if self.target and self.target.source == "guide" then self:ClearTarget() end
end

function Nav:OnInitialize()
  self:BuildFrame()
  self:ApplyPosition()
  self.frame:Hide()
  if self.db.disabled then self:FollowSteps() end
end

-- Ok kapaliyken de hedef adimla yurur: "Map pins" ayri modul ve hedefini buradan alir (yoksa ok kapandigi andaki
-- adimda donup kaliyordu, ok girista kapaliysa hic rehber hedefi yoktu). Module:Disable dinleyicileri OnDisable'dan
-- once siler; OnEnable ayni sahiple yeniden kaydeder.
function Nav:FollowSteps()
  ns:Listen("ARCANIS_STEP_CHANGED", self, "OnStepChanged")
  ns:Listen("ARCANIS_GUIDE_FINISHED", self, "OnGuideFinished")
  ns:Listen("ARCANIS_GUIDE_BLOCKED", self, "OnGuideFinished")
  -- adim icinde siradaki hedefin yeri de (OnEnable ayni sahiple ayni isleyiciyi yeniden kurar)
  ns:On("QUEST_LOG_UPDATE", self, function()
    if Nav.qlPending then return end
    Nav.qlPending = true
    local function run() Nav.qlPending = nil; ns.SafeCall(Nav.RefreshGuideTarget, Nav) end
    if not (P.After and P.After(0.2, run)) then run() end
  end)
  local step = ns.Engine and ns.Engine:GetStep()
  if step then ns.SafeCall(self.OnStepChanged, self, nil, nil, nil, step) end
end

-- Oyunun harita isareti (Ctrl + tik, sohbetteki harita linki) okla esitlenir: konunca ok oraya doner ("waypoint",
-- elle konan nokta gibi rehberden once gelir), haritada kaldirilinca ok da birakir ve rehbere doner.
function Nav:OnUserWaypoint()
  local map, x, y = P.UserWaypoint()
  local t = self.target
  if map then
    if not (t and t.source == "waypoint" and Nav.SameTarget(t, map, x, y, "waypoint", nil)) then
      self:SetTarget(map, x, y, L["Waypoint"], "waypoint")
    end
  elseif t and t.source == "waypoint" then
    self.target = nil   -- isaret zaten yok; ClearTarget onu bir daha silmesin
    self:ClearTarget()
    self:RefreshGuideTarget()
  end
end

function Nav:OnEnable()
  ns:On("USER_WAYPOINT_UPDATED", self, function() ns.SafeCall(Nav.OnUserWaypoint, Nav) end)
  self.frame:SetScript("OnUpdate", function(_, elapsed) Nav:Tick(elapsed) end)
  -- adim / rehber sonu / gunluk dinleyicileri; Engine biz acilmadan adimi duyurmus olabilir: mevcut adim alinir
  self:FollowSteps()
end

function Nav:OnDisable()
  self.frame:SetScript("OnUpdate", nil)
  self.frame:Hide()
  self:FollowSteps()
end

-- Komutlar
ns:RegisterCommand("way", function(args)
  args = args or ""
  if args:lower() == "clear" then
    Nav.target = nil
    Nav:OnStepChanged(nil, nil, nil, ns.Engine and ns.Engine:GetStep())   -- ok rehber adimina doner (konumsuzsa temizlenir)
    ns:Print(L["Waypoint cleared."])
    return
  end
  local map, x, y, label = args:match("^(%d+)%s+([%d%.]+)%s+([%d%.]+)%s*(.*)$")
  map, x, y = tonumber(map), tonumber(x), tonumber(y)
  if not (map and x and y) or x > 100 or y > 100 then
    ns:Print(L["Usage: /wf way <mapID> <x> <y> [label]   (x,y 0-100)   |   /wf way clear"])
    return
  end
  Nav:SetTarget(map, x / 100, y / 100, label ~= "" and label or L["Waypoint"], "manual")
  ns:Print(L["Waypoint: map %d, %.1f %.1f"]:format(map, x, y))
end, "<map> <x> <y> [label] set a manual waypoint; 'clear' removes it")

ns:RegisterCommand("why", function()
  local t = Nav.target
  if not t then
    ns:Print("No arrow target. Current step has no resolvable location (see /wf zonemap).")
  end
  for _, line in ipairs(P.Diagnose(t and t.map, t and t.x, t and t.y)) do print("  " .. line) end
end, "explain why the arrow has no distance")

ns:RegisterCommand("arrow", function(args)
  local cmd, value = (args or ""):lower():match("^(%S*)%s*(.-)$")
  if cmd == "lock" then
    Nav.db.locked = true
  elseif cmd == "unlock" then
    Nav.db.locked = false
  elseif cmd == "show" then
    Nav.db.hidden = false
  elseif cmd == "hide" then
    Nav.db.hidden = true
  elseif cmd == "reset" then
    local d = Nav.defaults
    Nav.db.point, Nav.db.relPoint, Nav.db.x, Nav.db.y, Nav.db.scale = d.point, d.relPoint, d.x, d.y, d.scale
    Nav:ApplyPosition()
  elseif cmd == "scale" and tonumber(value) and tonumber(value) >= 0.5 and tonumber(value) <= 3 then
    Nav.db.scale = tonumber(value)
    Nav:ApplyPosition()
  else
    ns:Print(L["Usage: /wf arrow lock | unlock | show | hide | reset | scale <0.5-3>"])
    return
  end
  Nav:Update(true)
end, "lock|unlock|show|hide|reset|scale <n> arrow settings")

ns:RegisterCommand("here", function()
  local map, x, y = P.PlayerMapPosition()
  if not map then
    ns:Print(L["Position unavailable (indoors or no map data)."])
    return
  end
  ns:Print(L["Map %d, x %.1f, y %.1f"]:format(map, x * 100, y * 100))
  print(("  /wf way %d %.1f %.1f"):format(map, x * 100, y * 100))
end, "show your map ID and coordinates")
