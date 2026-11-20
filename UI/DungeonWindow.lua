-- Arcanis: zindan gunlugu (modul "DungeonWindow"). Gunluk ana pencerenin "dungeon" sayfasidir
-- (icerik UI/Settings.lua Settings.BuildDungeons); burasi yalniz eski acma/kapama API'sini ana pencereye yonlendirir.
-- Acma: adim penceresindeki ust menu, /wf dungeon, ayarlar > Helpers.
local _, ns = ...

local Win = ns:NewModule("DungeonWindow", {})
ns.DungeonWindow = Win

local function onPage()
  local PW = ns.PathWindow
  return PW:IsOpen() and PW.db.page == "dungeon"
end

function Win:Open() ns.PathWindow:Open("dungeon") end

function Win:Close() if onPage() then ns.PathWindow:Close() end end

function Win:Toggle() if onPage() then ns.PathWindow:Close() else ns.PathWindow:Open("dungeon") end end

function Win:IsOpen() return onPage() end
