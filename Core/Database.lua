-- Arcanis: kayitli veri.
--   ns.db   -> ArcanisCoreDB         (hesap geneli)
--   ns.char -> ArcanisCoreCharDB     (karakter bazli)
-- Moduller kendi alanlarini ns.db.modules[isim] altinda tutar (bkz. Modules.lua).
local _, ns = ...

local DB_VERSION = 1

local DEFAULTS = {
  dbVersion = DB_VERSION,
  modules = {},
  zoneMaps = {},   -- oyuncunun /wf zonemap ile atadigi bolge -> uiMapID
  tips = {},       -- oyuncunun /wf tip ile yazdigi gorev ipuclari: [questId] = metin
}

local CHAR_DEFAULTS = {
  modules = {},
}

-- Veritabani surumu degisirse gocler burada, sirayla uygulanir.
local MIGRATIONS = {
  -- [2] = function(db) ... end,
}

local function migrate(db)
  local from = db.dbVersion or 1
  for v = from + 1, DB_VERSION do
    local step = MIGRATIONS[v]
    if step then step(db) end
  end
  db.dbVersion = DB_VERSION
end

-- Eski kayit adlari (addon "Wayfarer" iken): ilk acilista yeni ada tasinir, eskisi bosaltilir (nil kaydedilir).
-- TOC'te yalniz bu tasima icin listelenir; herkes tasindiktan sonra TOC'ten ve buradan silinebilir.
local function adopt(newName, oldName)
  if _G[newName] == nil and type(_G[oldName]) == "table" then _G[newName] = _G[oldName] end
  _G[oldName] = nil
end

function ns:InitDatabase()
  adopt("ArcanisCoreDB", "ArcanisWayfarerDB")
  adopt("ArcanisCoreCharDB", "ArcanisWayfarerCharDB")
  ArcanisCoreDB = ArcanisCoreDB or {}
  ArcanisCoreCharDB = ArcanisCoreCharDB or {}

  migrate(ArcanisCoreDB)
  ns.FillDefaults(ArcanisCoreDB, DEFAULTS)
  ns.FillDefaults(ArcanisCoreCharDB, CHAR_DEFAULTS)

  self.db = ArcanisCoreDB
  self.char = ArcanisCoreCharDB
end

-- Tum ayarlari siler ve varsayilanlara doner (arayuz yeniden yuklenmeli).
function ns:ResetDatabase()
  wipe(ArcanisCoreDB)
  wipe(ArcanisCoreCharDB)
  self:InitDatabase()
end
