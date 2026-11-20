-- Arcanis: sehir ici yurume yolu (Data/CityNav.lua). Ok bir sehir haritasinda hedefe giderken duvar ve evlerin
-- icinden degil, sokaklardan gecen bir yol cizer: kaba izgarada (3 yd) A*, sonra gorus hattiyla kisaltilir
-- (koseler kalir, duz giden ara noktalar atlanir). Yol, okun mevcut yol noktasi duzenine (target.path, harita
-- 0-1) verilir; Nav.PathStart / PathPassed onu izler. Stormwind City (1453), Ironforge (1455), Undercity (1458),
-- Orgrimmar (1454), Thunder Bluff (1456), Darnassus (1457).
local _, ns = ...

local P = ns.Provider
local CN = {}
ns.CityRoute = CN

CN.MIN_YARDS = 30      -- hedef bundan yakinsa yol gerekmez (dogrudan)
CN.SMOOTH_LOOK = 40    -- Smooth: bir noktadan en cok bu kadar ileriye gorus hatti aranir
CN.FAIL_WAIT = 20      -- sn: yol bulunamayan hedef bu sure yeniden aranmaz...
CN.FAIL_MOVE = 10      -- ...oyuncu bu kadar hucre (3 yd) yer degistirmedikce
CN.SNAP = 6            -- yurunebilir hucre aranirken en cok bu kadar kaba hucre uzaga bakilir
CN.MAX_NODES = 60000   -- A* bu kadar dugumden sonra vazgecer (yol yok sayilir)

local grids = {}

-- Satiri coz: "." bos, hex maske, "z"+2 hane base36 = o kadar bos hucre. Doner: maske dizisi (0 = bos)
local function decodeRow(s)
  local out, k, n = {}, 1, #s
  while k <= n do
    local ch = s:sub(k, k)
    if ch == "z" then
      local cnt = tonumber(s:sub(k + 1, k + 2), 36) or 0
      for _ = 1, cnt do out[#out + 1] = 0 end
      k = k + 3
    elseif ch == "." then
      out[#out + 1] = 0
      k = k + 1
    else
      out[#out + 1] = tonumber(ch, 16) or 0
      k = k + 1
    end
  end
  return out
end

-- Izgara (ilk kullanimda cozulur): { rect, x0, y0, cell, rows = { [i] = { [j] = maske } }, h, w }
function CN:Grid(map)
  local g = grids[map]
  if g ~= nil then return g or nil end
  local d = ns.CityNav and ns.CityNav[map]
  if not d then grids[map] = false return nil end
  g = { rect = d.rect, x0 = d.x0, y0 = d.y0, cell = d.cell, rows = {}, w = 0 }
  for i, s in ipairs(d.rows) do
    local r = decodeRow(s)
    g.rows[i - 1] = r
    if #r > g.w then g.w = #r end
  end
  g.h = #d.rows
  grids[map] = g
  return g
end

local function mask(g, i, j)
  local r = g.rows[i]
  return r and r[j + 1] or 0
end

-- harita (0-1) <-> dunya (X kuzey, Y bati) <-> hucre
local function mapToWorld(g, mx, my)
  local minX, maxX, minY, maxY = g.rect[1], g.rect[2], g.rect[3], g.rect[4]
  return maxX - my * (maxX - minX), maxY - mx * (maxY - minY)
end
local function worldToMap(g, wx, wy)
  local minX, maxX, minY, maxY = g.rect[1], g.rect[2], g.rect[3], g.rect[4]
  return (maxY - wy) / (maxY - minY), (maxX - wx) / (maxX - minX)
end
local function cellOf(g, wx, wy)
  return math.floor((wx - g.x0) / g.cell), math.floor((wy - g.y0) / g.cell)
end
local function center(g, i, j)
  return g.x0 + (i + 0.5) * g.cell, g.y0 + (j + 0.5) * g.cell
end

-- En yakin yurunebilir hucre (halka halka, CN.SNAP'e kadar)
function CN.Snap(g, i, j)
  if mask(g, i, j) > 0 then return i, j end
  for r = 1, CN.SNAP do
    local best, bd
    for di = -r, r do
      for dj = -r, r do
        if (math.abs(di) == r or math.abs(dj) == r) and mask(g, i + di, j + dj) > 0 then
          local d = di * di + dj * dj
          if not bd or d < bd then best, bd = { i + di, j + dj }, d end
        end
      end
    end
    if best then return best[1], best[2] end
  end
  return nil
end

-- komsular: 4 yon maskeden; capraz yalniz iki yoldan da (once i sonra j, once j sonra i) gecilebiliyorsa
local DIRS = { { 1, 0, 1 }, { -1, 0, 2 }, { 0, 1, 4 }, { 0, -1, 8 } }
local function canStep(g, i, j, di, dj)
  if di ~= 0 and dj ~= 0 then
    return canStep(g, i, j, di, 0) and canStep(g, i + di, j, 0, dj) and canStep(g, i, j, 0, dj) and canStep(g, i, j + dj, di, 0)
  end
  local bit = (di == 1 and 1) or (di == -1 and 2) or (dj == 1 and 4) or 8
  return math.floor(mask(g, i, j) / bit) % 2 == 1
end
CN.CanStep = canStep

-- ikili yigin (A* acik listesi): paralel diziler (dugum, f), itiste tablo uretilmez
local function push(hn, hf, n, node, f)
  n = n + 1
  local k = n
  while k > 1 do
    local p = math.floor(k / 2)
    if hf[p] <= f then break end
    hn[k], hf[k] = hn[p], hf[p]
    k = p
  end
  hn[k], hf[k] = node, f
  return n
end
local function pop(hn, hf, n)
  local top, last, lf = hn[1], hn[n], hf[n]
  hn[n], hf[n] = nil, nil
  n = n - 1
  if n > 0 then
    local k = 1
    while true do
      local l = 2 * k
      if l > n then break end
      if l < n and hf[l + 1] < hf[l] then l = l + 1 end
      if hf[l] >= lf then break end
      hn[k], hf[k] = hn[l], hf[l]
      k = l
    end
    hn[k], hf[k] = last, lf
  end
  return top, n
end

-- A*: hucre (si, sj) -> (ti, tj). Doner: { {i, j}, ... } ya da nil
-- Hiz (oyunda kare suresi): kapali kume (yigindaki eski kopyalar atlanir), hafif agirlikli sezgi (H_WEIGHT; yol en
-- fazla ~%20 uzun olabilir, Smooth zaten duzeltir), yol sona eklenip ters cevrilir.
CN.H_WEIGHT = 1.2
function CN.AStar(g, si, sj, ti, tj)
  local W = g.w + 2
  local hn, hf, n = {}, {}, 0
  local gs, from, closed = {}, {}, {}
  local sk, tk = si * W + sj, ti * W + tj
  local HW = CN.H_WEIGHT
  gs[sk] = 0
  n = push(hn, hf, n, sk, 0)
  local count, SQ, sqrt, floor = 0, math.sqrt(2), math.sqrt, math.floor
  while n > 0 do
    local cur
    cur, n = pop(hn, hf, n)
    if cur == tk then
      local rev, k = {}, cur
      while k do
        rev[#rev + 1] = { floor(k / W), k % W }
        k = from[k]
      end
      local path = {}
      for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
      return path
    end
    if not closed[cur] then
      closed[cur] = true
      count = count + 1
      if count > CN.MAX_NODES then return nil end
      local ci, cj = floor(cur / W), cur % W
      local gc = gs[cur]
      for di = -1, 1 do
        for dj = -1, 1 do
          if (di ~= 0 or dj ~= 0) and canStep(g, ci, cj, di, dj) then
            local nk = (ci + di) * W + (cj + dj)
            if not closed[nk] then
              local ng = gc + ((di ~= 0 and dj ~= 0) and SQ or 1)
              if not gs[nk] or ng < gs[nk] then
                gs[nk], from[nk] = ng, cur
                local hi, hj = ti - ci - di, tj - cj - dj
                n = push(hn, hf, n, nk, ng + HW * sqrt(hi * hi + hj * hj))
              end
            end
          end
        end
      end
    end
  end
  return nil
end

-- (a) -> (b) duz cizgi izgarada yurunebilir mi (her adim gecis kurallarina uyar)
function CN.Clear(g, ai, aj, bi, bj)
  local di, dj = bi - ai, bj - aj
  local n = math.max(math.abs(di), math.abs(dj))
  if n == 0 then return true end
  local pi, pj = ai, aj
  for k = 1, n do
    local i = math.floor(ai + di * k / n + 0.5)
    local j = math.floor(aj + dj * k / n + 0.5)
    local si, sj = i - pi, j - pj
    if (si ~= 0 or sj ~= 0) and not canStep(g, pi, pj, si, sj) then return false end
    pi, pj = i, j
  end
  return true
end

-- gorus hattiyla kisalt: her noktadan gorulebilen en uzak noktaya atla
function CN.Smooth(g, path)
  if #path <= 2 then return path end
  local out, k = { path[1] }, 1
  while k < #path do
    local far = k + 1
    -- ileri bakis SMOOTH_LOOK noktayla sinirli (her noktadan yolun sonuna kadar cizgi yurutmek O(n^2) idi)
    for m = math.min(#path, k + CN.SMOOTH_LOOK), k + 2, -1 do
      if CN.Clear(g, path[k][1], path[k][2], path[m][1], path[m][2]) then far = m break end
    end
    out[#out + 1] = path[far]
    k = far
  end
  return out
end

-- Oyuncudan hedefe (harita map, x, y 0-1) sehir yolu: { {x, y}, ... } harita 0-1 (son nokta haric: hedefin
-- kendisi target.x/y'dedir) ya da nil (sehir verisi yok, oyuncu baska haritada, yakin, yol bulunamadi).
function CN:Route(map, tx, ty)
  local pm, px, py = P.PlayerMapPosition()
  if not (map and pm and px) then return nil end
  -- hedef baska haritanin koordinatiyla gelebilir (ucus noktalari kita haritasinda): oyuncunun sehir haritasina
  -- cevrilir, yol orada bulunur, noktalar hedefin haritasina geri cevrilir (ok yolu t.map ile okur)
  local back
  if pm ~= map then
    local cx, cy = P.MapPosOn(map, tx, ty, pm)
    if not (cx and cx >= 0 and cx <= 1 and cy >= 0 and cy <= 1) then return nil end
    back, tx, ty = map, cx, cy
  end
  local g = self:Grid(pm)
  if not g then return nil end
  local pwx, pwy = mapToWorld(g, px, py)
  local twx, twy = mapToWorld(g, tx, ty)
  local dx, dy = pwx - twx, pwy - twy
  if math.sqrt(dx * dx + dy * dy) < self.MIN_YARDS then return nil end
  local si, sj = CN.Snap(g, cellOf(g, pwx, pwy))
  local ti, tj = CN.Snap(g, cellOf(g, twx, twy))
  if not (si and ti) then return nil end
  -- yol bulunamayan hedef (baska bolumde: asansorle cikilan teras, ip kopru) her 2 sn'de butun izgarayi
  -- taramasin: ayni hedef, oyuncu FAIL_MOVE hucreden fazla yer degistirmedikce FAIL_WAIT sn yeniden denenmez
  local fkey = pm .. ":" .. ti .. ":" .. tj
  local f = self.failed and self.failed[fkey]
  local now = P.Now and P.Now() or 0
  if f and now - f.at < CN.FAIL_WAIT and math.abs(f.i - si) + math.abs(f.j - sj) <= CN.FAIL_MOVE then return nil end
  local raw = CN.AStar(g, si, sj, ti, tj)
  if not raw then
    self.failed = self.failed or {}
    self.failed[fkey] = { at = now, i = si, j = sj }
    return nil
  end
  if self.failed then self.failed[fkey] = nil end
  local smooth = CN.Smooth(g, raw)
  local out = {}
  for k = 2, #smooth - 1 do   -- ilk nokta oyuncunun hucresi, son nokta hedefin hucresi
    local wx, wy = center(g, smooth[k][1], smooth[k][2])
    local mx, my = worldToMap(g, wx, wy)
    if back then
      mx, my = P.MapPosOn(pm, mx, my, back)
      if not mx then return nil end
    end
    out[#out + 1] = { mx, my }
  end
  return #out > 0 and out or nil
end
