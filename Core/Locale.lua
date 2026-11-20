-- Arcanis: yerellestirme.
-- Kaynak dil Ingilizcedir: kodda L["English text"] yazilir; ceviri yoksa metin aynen doner.
-- Cevirilmis diller Locales/<kod>.lua icinde ns:RegisterLocale("trTR", { ["English text"] = "Ceviri" }) ile eklenir.
--   ns.L                       metin tablosu (eksik anahtar -> anahtarin kendisi)
--   ns:SetLocale(code|"auto")  dili degistirir; "auto" istemcinin dilini kullanir
--   ns:LocalizedText(value)    string ya da { enUS = "...", trTR = "..." } tablosundan gecerli dilin metnini secer
--   ns.localeCode              etkin dil kodu
local _, ns = ...

local locales = {}
ns.locales = locales

-- Istemci kodu -> kullanilan ceviri. enGB ve esMX ayri dosya gerektirmez.
local ALIASES = { enGB = "enUS", esMX = "esES" }

-- Dil secicide gosterilen yerel adlar. trTR istemci dili degildir (WoW Turkceyi
-- desteklemez): otomatik secilmez, yalniz /wf locale trTR ile elle secilir.
local NATIVE_NAMES = {
  enUS = "English", deDE = "Deutsch", esES = "Español", frFR = "Français", itIT = "Italiano",
  ptBR = "Português (Brasil)", ruRU = "Русский", koKR = "한국어", zhCN = "简体中文", zhTW = "繁體中文",
  trTR = "Türkçe",
}

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L
ns.localeCode = "enUS"

function ns:RegisterLocale(code, strings)
  locales[code] = strings
end

function ns:GetLocales()
  local list = { "enUS" }
  for code in pairs(locales) do
    if code ~= "enUS" then list[#list + 1] = code end
  end
  table.sort(list)
  return list
end

function ns:GetLocaleName(code)
  return NATIVE_NAMES[code] or code
end

-- "deDE (Deutsch), enUS (English), ..." biciminde liste metni.
function ns:DescribeLocales()
  local parts = {}
  for _, code in ipairs(self:GetLocales()) do
    parts[#parts + 1] = code .. " (" .. self:GetLocaleName(code) .. ")"
  end
  return table.concat(parts, ", ")
end

-- Kullanici girdisini (buyuk/kucuk harf farki, takma ad) desteklenen koda cevirir; yoksa nil.
function ns:ResolveLocale(input)
  if type(input) ~= "string" then return nil end
  local wanted = input:lower()
  for code, target in pairs(ALIASES) do
    if code:lower() == wanted then wanted = target:lower() break end
  end
  if wanted == "enus" then return "enUS" end
  for code in pairs(locales) do
    if code:lower() == wanted then return code end
  end
  return nil
end

local function clientLocale()
  return (GetLocale and GetLocale()) or "enUS"
end

-- Dil kodu gecerliyse uygular ve true doner; degilse false (mevcut dil korunur).
function ns:SetLocale(code)
  if code == nil or code == "auto" then
    code = self:ResolveLocale(clientLocale()) or "enUS"   -- istemci dili desteklenmiyorsa Ingilizce
  else
    code = self:ResolveLocale(code)
    if not code then return false end
  end
  for key in pairs(L) do L[key] = nil end
  if code ~= "enUS" then
    for key, value in pairs(locales[code]) do L[key] = value end
  end
  ns.localeCode = code
  ns:Send("ARCANIS_LOCALE_CHANGED", code)
  return true
end

-- value: string, ya da dil koduna gore metin tablosu. Sira: etkin dil, enUS, alfabetik ilk dil.
function ns:LocalizedText(value)
  if type(value) ~= "table" then return value end
  local text = value[ns.localeCode] or value.enUS
  if text then return text end
  local keys = {}
  for k in pairs(value) do keys[#keys + 1] = k end
  table.sort(keys)
  return keys[1] and value[keys[1]] or nil
end
