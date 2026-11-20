local _, A = ...
local ns = A.RF
if not ns then return end

-- Dil destegi. Eklentinin ana dili INGILIZCE: varsayilan "auto" oyunun diline (GetLocale)
-- uyar, cevirisi olmayan her dil ve her eksik metin Ingilizceye (enUS) duser.
-- Turkce yalnizca ayarlardan elle secilirse gelir (oyunun Turkce istemcisi yok,
-- GetLocale hicbir zaman trTR donmez).
-- Anahtarlar kaynak (Turkce) metinlerdir; bu yuzden her anahtarin enUS cevirisi olmali
-- (tools/i18n ile kontrol). Locales\xxXX.lua: ns.locales.xxXX = { ["kaynak"] = "ceviri" }.
-- Yerlesik WoW fontlari koKR / zhCN / zhTW / ruRU icin istemcinin kendi fontunu kullanir.

ns.locales = {}

ns.LANGUAGES = { "auto", "enUS", "deDE", "frFR", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "trTR" }
ns.LANGUAGE_NAMES = {
    auto = "Oyunun dili", enUS = "English", deDE = "Deutsch", frFR = "Francais", esES = "Espanol (EU)",
    esMX = "Espanol (AL)", itIT = "Italiano", ptBR = "Portugues (BR)", ruRU = "Russkiy",
    koKR = "Hangug-eo", zhCN = "Jianti Zhongwen", zhTW = "Fanti Zhongwen", trTR = "Turkce",
}

local current, english

-- db yuklenince (ADDON_LOADED) ve dil ayari degisince cagrilir
function ns.SetLanguage(choice)
    local loc = (choice and choice ~= "auto") and choice or GetLocale()
    if loc == "enGB" then loc = "enUS" end
    english = ns.locales.enUS
    if loc == "trTR" then
        current = nil                                    -- kaynak metinler Turkce
    else
        current = ns.locales[loc] or (loc == "esMX" and ns.locales.esES) or english
    end
    ns.language = loc
end

-- ns.L("metin") -> ceviri. Ek argumanlar varsa string.format uygular.
function ns.L(s, ...)
    local t = (current and current[s]) or (ns.language ~= "trTR" and english and english[s]) or s
    if select("#", ...) > 0 then return t:format(...) end
    return t
end

-- Dosyalar yuklenirken (db yokken) oyunun diliyle basla
ns.SetLanguage("auto")
