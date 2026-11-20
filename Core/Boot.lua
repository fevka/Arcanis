-- Arcanis: acilis sirasi.
--   ADDON_LOADED  -> veritabani + modullerin OnInitialize'i
--   PLAYER_LOGIN  -> modullerin OnEnable'i
local ADDON, ns = ...

ns:On("ADDON_LOADED", ns, function(_, _, loaded)
  if loaded ~= ADDON then return end
  ns:Off("ADDON_LOADED", ns)
  local fresh = ArcanisCoreDB == nil and ArcanisWayfarerDB == nil   -- yeni kurulum: ilk acilista kurulum onerilir
  ns:InitDatabase()
  if ns.db.onboarded == nil and not fresh then ns.db.onboarded = true end   -- eski kurulum: hicbir sey degismez
  if ns.db.theme == "wow" then ns.db.theme = nil end   -- WoW temasi kaldirildi (11 Kasim 2026): varsayilan tema
  if ns.db.theme == "verdant" then ns.db.theme = "bloodorange" end   -- yesil tema yerine Blood Orange (13 Kasim 2026)
  if ns.Skin and ns.Skin.ApplyTheme then ns.Skin:ApplyTheme(ns.db.theme, ns.db.accent) end
  if ns.Skin and ns.Skin.ApplyFont then ns.Skin:ApplyFont(ns.db.font, ns.db.fontScale) end
  if not (ns.db.locale and ns:SetLocale(ns.db.locale)) then ns:SetLocale("auto") end
  ns:InitializeModules()
  ns:Send("ARCANIS_INITIALIZED")
end)

ns:On("PLAYER_LOGIN", ns, function()
  ns:Off("PLAYER_LOGIN", ns)
  ns:EnableModules()
  ns:Send("ARCANIS_READY")
  ns:Debug("ready, version " .. ns.version)
end)
