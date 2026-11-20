-- Arcanis: RotationForge'un dili Arcanis'in diline uyar (Arcanis'in dosyasi; tools/import_rotation.py bunu
-- Rotation\Locale.lua'nin hemen arkasina koyar ve silmez). RotationForge "auto"yu oyunun diline cevirir; burada
-- "auto" Arcanis'in secili dili olur. Her ayar degisikliginde ve ilk acilista (panel o dilde kurulur) gecerli.
local _, A = ...
local RF = A.RF
if not (RF and RF.SetLanguage) then return end

local original = RF.SetLanguage
function RF.SetLanguage(choice)
  if (choice == nil or choice == "auto") and A.localeCode then choice = A.localeCode end
  return original(choice)
end
