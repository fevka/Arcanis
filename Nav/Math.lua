-- Arcanis: yon hesabi (saf matematik, oyun API'sine bagimli degil).
-- Aci olcusu: radyan, kuzeyden saat yonunun tersine (0 = kuzey, pi/2 = bati), [0, 2pi).
local _, ns = ...

local M = {}
ns.NavMath = M

local TWO_PI = math.pi * 2
local atan2 = math.atan2 or math.atan   -- Lua 5.1: atan2; 5.3+: atan(y, x)

local function wrap(angle)
  angle = angle % TWO_PI
  if angle < 0 then angle = angle + TWO_PI end
  return angle
end

-- east/south: oyuncudan hedefe, dogu ve guney bilesenleri (yard).
function M.Bearing(east, south)
  return wrap(atan2(-east, -south))
end

-- Oyuncu facing yonune bakarken oka verilecek donus (saat yonunun tersine).
function M.Relative(bearing, facing)
  return wrap(bearing - (facing or 0))
end

function M.FormatDistance(yards)
  if yards >= 1000 then
    return ("%.1fk yd"):format(yards / 1000)
  end
  return ("%d yd"):format(math.floor(yards + 0.5))
end

-- Minimap: oyuncuya gore (east, south) yard farkini minimap merkezine gore piksele cevirir.
-- rotate: minimap oyuncunun baktigi yone gore donuyorsa true (facing gerekir).
-- Dondurur: x, y (yukari +), icerde mi (daire yaricapi icinde).
function M.MinimapOffset(east, south, facing, rotate, radiusYards, radiusPx)
  local x, y = east, -south
  if rotate and facing then
    local c, s = math.cos(facing), math.sin(facing)
    x, y = x * c + y * s, -x * s + y * c
  end
  local scale = radiusPx / radiusYards
  x, y = x * scale, y * scale
  return x, y, (x * x + y * y) <= radiusPx * radiusPx
end

-- Kirik cizgi (noktalar {x,y}) uzerinde her `spacing` birimde bir nokta uretir.
-- Ilk nokta baslangictan spacing uzakta olur; en fazla maxCount nokta.
function M.Resample(points, spacing, maxCount)
  local out = {}
  if spacing <= 0 then return out end
  local nextAt = spacing
  for i = 1, #points - 1 do
    local a, b = points[i], points[i + 1]
    local dx, dy = b[1] - a[1], b[2] - a[2]
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
      while nextAt <= len do
        local t = nextAt / len
        out[#out + 1] = { a[1] + dx * t, a[2] + dy * t }
        if maxCount and #out >= maxCount then return out end
        nextAt = nextAt + spacing
      end
      nextAt = nextAt - len
    end
  end
  return out
end
