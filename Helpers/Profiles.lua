-- Arcanis: ayar profilleri (Ayarlar > General > Profiles; modul degil, hep acik).
-- Profil = hesap geneli ayarlarin adli kopyasi: modul acik/kapali + her modulun varsayilanlarinda adi gecen
-- duz ayarlari (sayi, metin, acik/kapali) + PROFILE_TABLES'taki ayar tablolari + genel ayarlar (GENERAL).
-- Alinmayanlar (bilerek): karakter verisi (ns.char: rehber ilerlemesi, sekmeler...), modullerin ogrendigi veri
-- (rare noktalari, farm yerleri, fiyat taramalari, uçus sureleri...), QoL'un sakladigi oyuncu CVar'lari.
-- Kayit ns.db.profiles[ad]; karakterin varsayilani ns.char.profile: girilen karakterin profili hesapta son
-- yuklenenden farkliysa moduller acilmadan once uygulanir. Elle yukleme arayuzu yeniden yukler.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Profiles = {}
ns.Profiles = Profiles

Profiles.GENERAL = { "theme", "accent", "font", "fontScale", "locale", "noticeLevel", "noticeCustom" }
-- tablo olan varsayilanlardan yalniz bunlar ayardir (digerleri ogrenilmis veri)
Profiles.PROFILE_TABLES = {
  Nav = { color = true, distColor = true, labelColor = true }, MapReveal = { color = true },
  MapMarkers = { mini = true, world = true }, Mentor = { mountGoal = true },
  Island = { bg = true, groupNames = true, hub = true, itemStyle = true, strip = true },
  UITweaks = { frames = true },
}

local function copy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = copy(x) end
  return t
end
Profiles.Copy = copy

-- Su anki ayarlarin kopyasi
function Profiles:Snapshot()
  local snap = { general = {}, modules = {} }
  for _, k in ipairs(self.GENERAL) do snap.general[k] = copy(ns.db[k]) end
  for name, mod in ns:IterateModules() do
    if mod.initialized then
      local tables = self.PROFILE_TABLES[name] or {}
      local m = { disabled = mod.db.disabled }
      for k, def in pairs(mod.defaults) do
        if k ~= "disabled" and (type(def) ~= "table" or tables[k]) then m[k] = copy(mod.db[k]) end
      end
      snap.modules[name] = m
    end
  end
  return snap
end

-- Kopyayi kayitli ayarlara yazar (moduller acilip kapanmaz; cagiran yeniden yukler ya da moduller sonra acilir).
-- Profilde olmayan anahtar oldugu gibi kalir; profilde nil olan (varsayilan) varsayilana doner.
function Profiles:Write(snap)
  for _, k in ipairs(self.GENERAL) do ns.db[k] = copy(snap.general and snap.general[k]) end
  for name, m in pairs(snap.modules or {}) do
    local mod = ns:GetModule(name)
    if mod and mod.initialized then
      for k, v in pairs(mod.defaults) do
        if m[k] ~= nil then mod.db[k] = copy(m[k])
        elseif k ~= "disabled" and (type(v) ~= "table" or (self.PROFILE_TABLES[name] or {})[k]) then mod.db[k] = copy(v) end
      end
      mod.db.disabled = m.disabled
    end
  end
end

function Profiles:List()
  local out = {}
  for name in pairs(ns.db.profiles or {}) do out[#out + 1] = name end
  table.sort(out)
  return out
end

local function clean(name) return type(name) == "string" and name:match("^%s*(.-)%s*$") or "" end

function Profiles:Save(name)
  name = clean(name)
  if name == "" then return false end
  ns.db.profiles = ns.db.profiles or {}
  ns.db.profiles[name] = self:Snapshot()
  ns.db.activeProfile = name
  return true
end

function Profiles:CopyTo(from, to)
  to = clean(to)
  local src = ns.db.profiles and ns.db.profiles[from]
  if not src or to == "" or to == from then return false end
  ns.db.profiles[to] = copy(src)
  return true
end

function Profiles:Delete(name)
  if not (ns.db.profiles and ns.db.profiles[name]) then return false end
  ns.db.profiles[name] = nil
  if ns.db.activeProfile == name then ns.db.activeProfile = nil end
  if ns.char.profile == name then ns.char.profile = nil end
  return true
end

-- Profili yazar; reload = true ise arayuzu yeniden yukler (acik moduller yeni ayarlarla kurulsun)
function Profiles:Load(name, reload)
  local snap = ns.db.profiles and ns.db.profiles[name]
  if not snap then return false end
  self:Write(snap)
  ns.db.activeProfile = name
  if reload then
    if not P.ReloadUI() then ns:Print(L["Profile loaded. Type /reload to apply it."]) end
  end
  return true
end

-- Genel ayarlar (tema, yazi, dil) Boot'ta modullerden once uygulanmisti: profil yazilinca yeniden
function Profiles:ApplyGeneral()
  local S = ns.Skin
  if S and S.ApplyTheme then S:ApplyTheme(ns.db.theme, ns.db.accent) end
  if S and S.ApplyFont then S:ApplyFont(ns.db.font, ns.db.fontScale) end
  if not (ns.db.locale and ns:SetLocale(ns.db.locale)) then ns:SetLocale("auto") end
end

-- Karakterin varsayilan profili: moduller acilmadan once (ARCANIS_INITIALIZED, PLAYER_LOGIN'den once)
function Profiles:OnInitialized()
  local want = ns.char.profile
  if not want then return end
  if not (ns.db.profiles and ns.db.profiles[want]) then ns.char.profile = nil; return end
  if ns.db.activeProfile == want then return end
  self:Load(want, false)
  self:ApplyGeneral()
end
ns:Listen("ARCANIS_INITIALIZED", Profiles, "OnInitialized")

-- Ayarlar > General karti. ob: sayfanin kurucusu (UI/Settings.lua newBuilder)
function Profiles:BuildSettings(page_ob, page)
  local ob = page_ob:Group(function() return L["Profiles"] end,
    function() return L["Save all Arcanis settings under a name and load them on any character. Guide progress is never part of a profile."] end)
  local sel = { name = ns.db.activeProfile }
  local function items()
    local list = {}
    for _, n in ipairs(Profiles:List()) do list[#list + 1] = { value = n, text = n } end
    if #list == 0 then list[1] = { value = "", text = L["No profiles yet"] } end
    return list
  end
  local function refresh() if page.refresh then page.refresh() end end
  page.profileDD = ob:Dropdown("Profile", "The profile the buttons below work on.", items,
    function() return sel.name or "" end, function(v) sel.name = v ~= "" and v or nil end)
  ob:Custom("New name", "Type a name, then Save or Copy.", 220, function(r)
    local eb = ns.Skin:CreateEditBox(r, 220, 24)
    eb:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    page.profileName = eb
  end)
  local function typed() return clean(page.profileName and page.profileName:GetText()) end
  ob:Buttons("Save or copy", "Save: the current settings under the new name (or over the selected profile). Copy: the selected profile under the new name.", {
    { function() return L["Save"] end, function()
      local name = typed() ~= "" and typed() or sel.name
      if Profiles:Save(name) then
        sel.name = name
        if page.profileName then page.profileName:SetText("") end
        ns:Print(L["Profile saved: %s"]:format(name))
        refresh()
      end
    end, true },
    { function() return L["Copy"] end, function()
      if sel.name and Profiles:CopyTo(sel.name, typed()) then
        sel.name = typed(); page.profileName:SetText(""); refresh()
      end
    end },
  })
  local del = {}
  local buttons = ob:Buttons("Load or delete", "Load replaces your settings with the profile and reloads the interface.", {
    { function() return L["Load"] end, function() if sel.name then Profiles:Load(sel.name, true) end end },
    { "Delete", function()
      if not sel.name then return end
      local btn = page.profileDelete
      if del.name == sel.name and del.untilT and P.Now() < del.untilT then
        Profiles:Delete(sel.name)
        sel.name, del.name = nil, nil
        btn:SetText(L["Delete"])
        refresh()
        return
      end
      del.name, del.untilT = sel.name, P.Now() + 4
      btn:SetText(L["Click again to confirm"])
      P.After(4, function() if del.name then del.name = nil; btn:SetText(L["Delete"]) end end)
    end },
  })
  page.profileDelete = buttons[1]   -- Buttons sagdan sola kurar: ilk eleman son dugme
  page.profileCharSw = ob:Switch("Load on this character", "This character loads the selected profile when you log in with it.",
    function() return sel.name ~= nil and ns.char.profile == sel.name end,
    function(v)
      if v and sel.name then ns.char.profile = sel.name; ns.db.activeProfile = ns.db.activeProfile or sel.name
      elseif not v and ns.char.profile == sel.name then ns.char.profile = nil end
    end)
  page.profileSel = sel
end

ns:RegisterCommand("profile", function(arg)
  arg = clean(arg)
  if arg == "" then
    local list = Profiles:List()
    ns:Print(#list > 0 and table.concat(list, ", ") or L["No profiles yet"])
  elseif not Profiles:Load(arg, true) then
    ns:Print(L["No profile named %s."]:format(arg))
  end
end, "list profiles or load one: /wf profile <name>")
