-- Arcanis: rotasyon yardimcisi (eski adiyla RotationForge, artik Arcanis'in kendi parcasi). Kendi ns'i A.RF,
-- kayit ArcanisRotationDB, dil dosyalari Rotation/Locales (anahtarlar Turkce kaynak metin; Rotation/LocaleBridge.lua
-- "auto"yu Arcanis'in diline baglar). Ayarlari Settings > Modules > Rotation helper cekmecesinde (Rotation/Options.lua
-- Arcanis'in ayar kurucusuyla cizer). Komut: /wf rotation <...> (eski /rof da calisir).
local _, A = ...

A.RF = {}

-- Ayarlar > Modules anahtari (modul "Rotation"). Bu dosyalar yuklenirken kayit henuz yok, bu yuzden kapaliysa
-- ADDON_LOADED'da (yardimci PLAYER_LOGIN'de kurulmadan once) motoru, ekranini, bar parlamasini ve talent
-- rehberini bos islevlerle durdurur; /rof yalniz durumu soyler. Oyun icinde kapatinca ikonlar ve parlamalar hemen
-- kalkar; tamamen acmak / kapatmak /reload ister.
-- Varsayilan kapali (sahibin karari, 11 Kasim 2026): Ayarlar > Modules'tan acilir.
local Rot = A:NewModule("Rotation", { defaults = { disabled = true } })
local STOP = { "Tick", "UI_Init", "UI_Set", "UI_Apply", "UI_SetPreview", "Highlight_Init", "Highlight_Scan",
               "Highlight_Set", "Options_Init", "TalentGuide_Update", "CDBar_Init", "Print" }

local saved   -- durdurulan islevlerin asillari (acinca geri yuklenir)

local function stop(RF)
  if RF.stopped then return end
  RF.stopped = true
  saved = { slash = SlashCmdList.ROTATIONFORGE }
  for _, fn in ipairs(STOP) do saved[fn] = RF[fn] end
  -- ekrandakini temizle (kurulduysa): ikonlar, gruplar ve tutamaclar gizlenir (kilit acik olsa da yer tutucu
  -- kalmaz), bar parlamasi ve talent rehberinin parlamalari kalkar
  if RF.UI_Set then pcall(RF.UI_Set, { queue = {} }) end   -- bos oneri (cooldown cubugu sayaclari sifirlanir)
  if RF.UI_Stop then pcall(RF.UI_Stop) end
  if RF.Highlight_Set then pcall(RF.Highlight_Set, {}) end
  if RF.TalentGuide_Clear then pcall(RF.TalentGuide_Clear) end
  if RF.ResetView then pcall(RF.ResetView) end
  if RF.driver then RF.driver:Hide() end
  for _, fn in ipairs(STOP) do RF[fn] = function() end end
  SlashCmdList.ROTATIONFORGE = function()
    A:Print(A.L["The rotation helper is turned off in Settings > Modules."])
  end
end

function Rot:OnInitialize()
  if self.db.disabled and A.RF then stop(A.RF) end
end

function Rot:OnDisable()
  if A.RF then stop(A.RF) end
end

-- Yeniden acinca: asil islevler geri gelir; giris sirasinda kapaliydiysa ekran simdi kurulur (reload gerekmez).
function Rot:OnEnable()
  local RF = A.RF
  if not (RF and RF.stopped and saved) then return end
  for _, fn in ipairs(STOP) do if saved[fn] then RF[fn] = saved[fn] end end
  if saved.slash then SlashCmdList.ROTATIONFORGE = saved.slash end
  saved, RF.stopped = nil, false
  if RF.driver then RF.driver:Show() end
  if RF.playerClass and RF.db then
    if RF.ScanTrinkets then pcall(RF.ScanTrinkets) end
    if RF.Refresh then pcall(RF.Refresh) end
    if not RF.uiReady then
      pcall(RF.Highlight_Init)
      pcall(RF.UI_Init)
    end
    if RF.UI_Apply then pcall(RF.UI_Apply) end
    if RF.TalentGuide_Update then pcall(RF.TalentGuide_Update) end
  end
end

-- Arcanis'in dili degisince yardimci "auto"daysa ona gecer (acik cekmece yenilenir)
A:Listen("ARCANIS_LOCALE_CHANGED", "RotationBridge", function()
  local RF = A.RF
  if RF and RF.db and (RF.db.language or "auto") == "auto" then pcall(RF.SetLanguage, "auto") end
end)

A:RegisterCommand("rotation", function(args)
  if SlashCmdList.ROTATIONFORGE then SlashCmdList.ROTATIONFORGE(args or "") end
end, "[command] rotation helper: lock, unlock, talent, track, debug... (empty: its settings)")
