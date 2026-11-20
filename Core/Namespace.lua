-- Arcanis: ortak isim alani ve yardimcilar.
-- TOC'deki tum dosyalar ayni (ADDON, ns) cifti ile yuklenir.
local ADDON, ns = ...

_G.Arcanis = ns
ns.name = ADDON

local function metadata(field)
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    return C_AddOns.GetAddOnMetadata(ADDON, field)
  elseif GetAddOnMetadata then
    return GetAddOnMetadata(ADDON, field)
  end
end

ns.version = metadata("Version") or "dev"
ns.debug = false

local PREFIX = "|cff07aacbArcanis|r:"   -- addon listesindeki "Arcanis Core" rengiyle ayni

function ns:Print(...)
  print(PREFIX, ...)
end

function ns:Debug(...)
  if self.debug then
    print(PREFIX .. "|cff888888[debug]|r", ...)
  end
end

-- Hata bir dinleyiciyi dusurmesin: hatayi oyunun hata yoneticisine ilet.
function ns.SafeCall(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler(err) end
  end
  return ok
end

-- dest'te eksik olan anahtarlari src'den doldurur (var olani ezmez).
function ns.FillDefaults(dest, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dest[k]) ~= "table" then dest[k] = {}; ns.FillDefaults(dest[k], v)
      -- dizi (sirali liste) kullanicinindir: eleman eklenmez, yoksa silinen ogeler /reload'da geri gelir
      elseif v[1] == nil then ns.FillDefaults(dest[k], v) end
    elseif dest[k] == nil then
      dest[k] = v
    end
  end
  return dest
end
