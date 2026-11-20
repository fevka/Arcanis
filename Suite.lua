-- Suite kaydi: Path kendini konsola kaydeder (konsol yoksa atlanir).
local _, ns = ...
local Engine = _G.ArcanisEngine

local function opt(modName, field)
  return {
    get = function() local m = ns:GetModule(modName); return m and m.db and m.db[field] ~= false end,
    set = function(v) local m = ns:GetModule(modName); if m and m.db then m.db[field] = v and true or false end end,
  }
end

if Engine and type(Engine.RegisterSuiteAddon) == "function" then
  local list = {}
  local function add(label, tip, modName, field)
    local o = opt(modName, field); o.label, o.tip = label, tip
    list[#list + 1] = o
  end
  add("Skip low-level quests", "Rehberde gri (cok dusuk seviyeli) gorev adimlarini atlar.", "Engine", "skipGray")
  add("Low health warning", "Savasta can dusunce uyarir.", "Alerts", "lowHealth")
  add("Talent point tips", "Seviye atlayinca Oracle build'ine gore yetenek onerir.", "Build", "tips")
  add("Show XP per hour", "Adim penceresinde saatlik XP gosterir.", "Leveling", "show")

  -- Dogru cagri: nokta (RegisterSuiteAddon def alir); iki cagri bicimi de Engine'de calisir.
  Engine.RegisterSuiteAddon({
    id = "Arcanis",
    title = "ArcanisPath (Level Up)",
    version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("Arcanis", "Version")) or "0.9",
    global = "Arcanis",
    sortOrder = 21,
    notes = "Level up rehberleri, adim penceresi, zindan gunlugu, gorev otomasyonu, XP/saat. /wf",
    panel = function()
      local W = ns.PathWindow
      if not W then return nil end
      W:BuildFrame()
      return W.frame
    end,
    settingList = list,
    health = function()
      if not ns.Engine then return false, "Arcanis engine yok" end
      if not ns.Guides or #ns.Guides.order == 0 then return false, "Rehber bulunamadi" end
      return true
    end,
  })
end
