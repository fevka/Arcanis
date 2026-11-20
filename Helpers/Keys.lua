-- Arcanis: tus atamalari ve makrolar (modul "Keys").
-- Tuslar Bindings.xml'de tanimlidir (Oyun ayarlari > Tus Atamalari > Arcanis Path); burada okunur/atanir.
-- Makrolar dogrudan oyunun makro listesine (karakter makrosu) kurulur.
local _, ns = ...

local L = ns.L

-- macroIcons: makro basina secilen ikon; custom: oyuncunun editorde kurdugu makrolar (karakter kaydi)
local Keys = ns:NewModule("Keys", { charDefaults = { macroIcons = {}, custom = {} } })
ns.Keys = Keys

Keys.BINDINGS = {
  { name = "ARCANISPATH_NEXT", title = function() return L["Next step"] end, desc = function() return L["Moves the guide one step forward."] end },
  { name = "ARCANISPATH_PREV", title = function() return L["Previous step"] end, desc = function() return L["Moves the guide one step back."] end },
  { name = "ARCANISPATH_NEAREST", title = function() return L["Go to the nearest quest"] end, desc = function() return L["Points the guide at your closest quest."] end },
  { name = "CLICK ArcanisPathQuestItem:LeftButton", title = function() return L["Use quest item"] end, desc = function() return L["Uses the item your current quest needs."] end },
  { name = "ARCANISPATH_WINDOW", title = function() return L["Show or hide the step window"] end, desc = function() return L["Toggles the compact route panel."] end },
  { name = "ARCANISPATH_MAIN", title = function() return L["Open Arcanis Path"] end, desc = function() return L["Opens or closes the main window."] end },
}

Keys.MACROS = {
  { name = "AP Next", body = "/wf next", title = function() return L["Next step"] end, desc = function() return L["/wf next"] end },
  { name = "AP Nearest", body = "/wf nearest", title = function() return L["Go to the nearest quest"] end, desc = function() return L["/wf nearest"] end },
  { name = "AP Item", body = "/click ArcanisPathQuestItem", title = function() return L["Use quest item"] end, desc = function() return L["/click ArcanisPathQuestItem"] end },
}

BINDING_HEADER_ARCANISPATH = "Arcanis Path"
local function setNames()
  for _, b in ipairs(Keys.BINDINGS) do _G["BINDING_NAME_" .. b.name] = b.title() end
end
setNames()

local function inCombat() return InCombatLockdown and InCombatLockdown() end

function Keys:KeyOf(name)
  if not GetBindingKey then return nil end
  local k1, k2 = GetBindingKey(name)
  return k1, k2
end

local function save()
  if SaveBindings then pcall(SaveBindings, (GetCurrentBindingSet and GetCurrentBindingSet()) or 1) end
end

-- Dondurur: true | false, neden ("combat")
-- Yakalanan girdi -> baglanti adi ("ALT-CTRL-SHIFT-" + tus). Fare: OnMouseDown dugme adi ya da tekerlek
-- ("MOUSEWHEELUP"/"MOUSEWHEELDOWN"). Sol/sag tus tek basina arayuzu kullanmak icindir: degistiricisiz nil
-- (iptal). Degistirici tuslarin kendisi nil (beklemeye devam: false).
local MOUSE = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3", Button4 = "BUTTON4",
  Button5 = "BUTTON5" }
local MODS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true }
function Keys.Combo(input, alt, ctrl, shift)
  if MODS[input] then return false end
  local key = MOUSE[input] or input
  if not key or key == "ESCAPE" then return nil end
  if (key == "BUTTON1" or key == "BUTTON2") and not (alt or ctrl or shift) then return nil end
  return (alt and "ALT-" or "") .. (ctrl and "CTRL-" or "") .. (shift and "SHIFT-" or "") .. key
end

function Keys:SetKey(name, key)
  if inCombat() then return false, "combat" end
  if not SetBinding then return false end
  local k1, k2 = self:KeyOf(name)
  if k1 then SetBinding(k1) end
  if k2 then SetBinding(k2) end
  SetBinding(key, name)
  save()
  return true
end

function Keys:ClearKey(name)
  if inCombat() or not SetBinding then return false end
  local k1, k2 = self:KeyOf(name)
  if k1 then SetBinding(k1) end
  if k2 then SetBinding(k2) end
  save()
  return true
end

-- Kurulu makronun sirasi (yoksa 0). Once karakter makrosu; yoksa ayni adli hesap geneli (Genel sekme) makro da
-- bizimdir (adlar "AP ..."; sahibin bulgusu, 15 Kasim 2026: Genel sekmedeki makrolar "Install" gorunuyordu):
-- Install onu gunceller, Uninstall onu siler. Yalniz "AP " adli sinif makrolarinda: ozel makronun adini oyuncu
-- yazar, Genel sekmedeki kendi elle yazdigi ayni adli makro ezilmemeli.
function Keys:MacroIndex(m)
  local P = ns.Provider
  local i = P.CharacterMacroIndex(m.name)
  if i > 0 then return i end
  if not GetMacroIndexByName or not (m.name or ""):find("^AP ") then return 0 end
  local ok, idx = pcall(GetMacroIndexByName, m.name)
  return ok and type(idx) == "number" and idx > 0 and idx or 0
end

-- Makroyu kurar ya da gunceller. Dondurur: true | false, neden ("combat" | "full")
function Keys:InstallMacro(m)
  if inCombat() then return false, "combat" end
  local idx = self:MacroIndex(m)
  local icon = self:MacroIcon(m)
  if idx and idx > 0 then
    if EditMacro then pcall(EditMacro, idx, m.name, icon, m.body) end
    return true
  end
  if not CreateMacro then return false end
  local ok, res = pcall(CreateMacro, m.name, icon, m.body, 1)
  if ok and res then return true end
  return false, "full"
end

-- Ikon secimi: makronun buyulerinin ikonlari (ilki varsayilan) ya da "otomatik" (soru isareti: oyun
-- #showtooltip ile o an kullanilacak buyunun ikonunu gosterir). Buyusuz makroda verideki `icon`.
local AUTO_ICON = "INV_Misc_QuestionMark"
Keys.AUTO_ICON = AUTO_ICON
function Keys:MacroIcons(m)
  local out = {}
  for _, t in ipairs(m.icons or {}) do out[#out + 1] = t end
  out[#out + 1] = AUTO_ICON
  return out
end

function Keys:MacroIcon(m)
  local pick = self.char and self.char.macroIcons and self.char.macroIcons[m.name]
  for _, t in ipairs(self:MacroIcons(m)) do if t == pick then return t end end
  return self:MacroIcons(m)[1]
end

-- Sonraki ikona gecer (secim karakter kaydinda kalir; kurulu makroya Codex InstallMacro ile hemen yazar)
function Keys:CycleMacroIcon(m)
  local list, cur = self:MacroIcons(m), self:MacroIcon(m)
  local i = 1
  for k, t in ipairs(list) do if t == cur then i = k end end
  local nxt = list[i % #list + 1]
  self.char.macroIcons[m.name] = nxt
  return nxt
end

-- Kurulu makroyu siler (oyuncunun Uninstall dugmesi). Donus: true | false, "combat"
function Keys:UninstallMacro(m)
  if inCombat() then return false, "combat" end
  local idx = self:MacroIndex(m)
  if idx > 0 and DeleteMacro then pcall(DeleteMacro, idx) end
  return true
end

-- Sinif makrolari (Data/Macros.lua): oyunun dilindeki buyu adlariyla kurulmaya hazir liste.
-- Her oge: { name, body, desc, known (gereken buyuler biliniyor), missing (bilinmeyen ilk buyu adi) }
local KIND = {
  help = function(n) return L["Casts %s on the friend under your mouse, else your friendly target, else you."]:format(n[1]) end,
  focus = function(n) return L["Casts %s on your focus if it is an enemy, else on your target."]:format(n[1]) end,
  harm = function(n) return L["Casts %s on the enemy under your mouse, else your target."]:format(n[1]) end,
}
-- Buyu biliniyor mu, rutbesine bakmadan: veride rutbe 1 kimligi var, ust rutbe ogrenilince oyun eskisini
-- "bilinmiyor" der (Heroic Strike 78 -> 285, 1608...). Ayni adin herhangi bir rutbesi yeter (istemci listesi, Training).
local function knowsAnyRank(P, id, class)
  if P.KnowsSpell(id) then return true end
  local Tr = ns.Training
  local idx = Tr and Tr.RankIndex and Tr:RankIndex(class or (P.PlayerClassToken and P.PlayerClassToken()))
  -- ada gore: baslangic rutbesi (78, 1752) egitmen listesinde yok, oradaki rutbe 1 baska kimlik (284, 1757)
  local e = idx and idx.byId[id]
  local name = e and e.name or P.SpellName(id)
  for _, other in pairs(idx and name and idx.byName[name] or {}) do
    if other ~= id and P.KnowsSpell(other) then return true end
  end
  return false
end
Keys.KnowsAnyRank = knowsAnyRank

function Keys:ClassMacros(class)
  local P, out = ns.Provider, {}
  local data = ns.ClassMacros or {}
  local function add(m)
    local names = {}
    for i, id in ipairs(m.spells or {}) do
      names[i] = P.SpellName(id)
      if not names[i] then return end -- bu buyu oyunda yok
    end
    local known, missing = true, nil
    for _, i in ipairs(m.need or (m.spells and { 1 }) or {}) do
      if not knowsAnyRank(P, m.spells[i], class) then known, missing = false, missing or names[i] end
    end
    local body = m.body:gsub("{(%d)}", function(i) return names[tonumber(i)] end)
    local desc = m.desc and m.desc(names) or (KIND[m.kind] and KIND[m.kind](names)) or ""
    local icons, seen = {}, {}
    if m.icon then icons[1] = m.icon; seen[m.icon] = true end
    for _, n in ipairs(names) do
      local t = P.SpellIcon(n)
      if t and not seen[t] then icons[#icons + 1] = t; seen[t] = true end
    end
    out[#out + 1] = { name = m.name, body = body, desc = desc, known = known, missing = missing, icons = icons }
  end
  for _, m in ipairs(data.ALL or {}) do add(m) end
  for _, m in ipairs(data[class or ""] or {}) do add(m) end
  return out
end

-- Makro editoru: secimlerden (spec) makro metni kurar. spec alanlari:
--   name, action ("cast" | "use"), spell (buyu ya da esya adi), target ("" | "mouseover" | "focus" | "player" |
--   "cursor"), check ("" | "harm" | "help"), nodead, tooltip, stopcasting, startattack, mod ("" | "shift" | "ctrl" |
--   "alt") ve modSpell (degistirici basiliyken atilacak).
Keys.MACRO_MAX, Keys.NAME_MAX = 255, 16
local FALLBACK = { mouseover = true, focus = true }   -- hedef yoksa normal hedefe dus
function Keys.BuildMacro(spec)
  local lines = {}
  local verb = spec.action == "use" and "/use" or "/cast"
  if spec.tooltip then lines[#lines + 1] = "#showtooltip" end
  if spec.stopcasting then lines[#lines + 1] = "/stopcasting" end
  if spec.startattack then lines[#lines + 1] = "/startattack" end
  local spell = (spec.spell or ""):match("^%s*(.-)%s*$")
  if spell ~= "" then
    local conds = {}
    if spec.target and spec.target ~= "" then conds[#conds + 1] = "@" .. spec.target end
    if spec.check and spec.check ~= "" then conds[#conds + 1] = spec.check end
    if spec.nodead then conds[#conds + 1] = "nodead" end
    local main = #conds > 0 and ("[" .. table.concat(conds, ",") .. "]") or ""
    if main ~= "" and FALLBACK[spec.target] then main = main .. "[]" end
    local parts = {}
    local modSpell = (spec.modSpell or ""):match("^%s*(.-)%s*$")
    if spec.mod and spec.mod ~= "" and modSpell ~= "" then parts[#parts + 1] = ("[mod:%s] %s"):format(spec.mod, modSpell) end
    parts[#parts + 1] = (main ~= "" and (main .. " ") or "") .. spell
    lines[#lines + 1] = verb .. " " .. table.concat(parts, "; ")
  end
  return table.concat(lines, "\n")
end

-- Kaydedip kurulabilir mi: true | false, neden ("name" | "empty" | "long")
function Keys.CheckMacro(spec)
  local name = (spec.name or ""):match("^%s*(.-)%s*$")
  if name == "" or #name > Keys.NAME_MAX then return false, "name" end
  local body = Keys.BuildMacro(spec)
  if not body:find("/", 1, true) then return false, "empty" end
  if #body > Keys.MACRO_MAX then return false, "long" end
  return true
end

-- Editorde kurulan makronun kurulabilir hali (InstallMacro / UninstallMacro / MacroIndex icin)
function Keys:CustomMacro(spec)
  local icon = (not spec.tooltip and spec.action ~= "use" and ns.Provider.SpellIcon(spec.spell or "")) or AUTO_ICON
  return { name = (spec.name or ""):match("^%s*(.-)%s*$"), body = Keys.BuildMacro(spec), icons = { icon } }
end

-- Kaydeder (ayni adli olani gunceller; ad degistiyse eski oyun makrosu silinir) ve kurar. Donus: InstallMacro gibi.
function Keys:SaveCustom(spec, oldName)
  local ok, why = Keys.CheckMacro(spec)
  if not ok then return false, why end
  if inCombat() then return false, "combat" end
  local list = self.char.custom
  local m = self:CustomMacro(spec)
  if oldName and oldName ~= m.name then self:UninstallMacro({ name = oldName }) end
  local copy = {}
  for k, v in pairs(spec) do copy[k] = v end
  copy.name = m.name
  local slot = #list + 1
  for i, s in ipairs(list) do if s.name == (oldName or m.name) or s.name == m.name then slot = i break end end
  list[slot] = copy
  return self:InstallMacro(m)
end

function Keys:DeleteCustom(name)
  if inCombat() then return false, "combat" end
  local list = self.char.custom
  for i = #list, 1, -1 do if list[i].name == name then table.remove(list, i) end end
  return self:UninstallMacro({ name = name })
end

function Keys:OnEnable() setNames() end
