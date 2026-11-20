-- Arcanis: slash komutlari (/arcanis, /wf).
--   ns:RegisterCommand("ok", function(args) ... end, "aciklama")
local _, ns = ...

local L = ns.L

local commands = {}
local commandOrder = {}

function ns:RegisterCommand(name, fn, help)
  name = name:lower()
  if not commands[name] then commandOrder[#commandOrder + 1] = name end
  commands[name] = { fn = fn, help = help or "" }
end

-- { { name = "ok", help = "aciklama" }, ... } kayit sirasinda.
function ns:ListCommands()
  local list = {}
  for _, name in ipairs(commandOrder) do list[#list + 1] = { name = name, help = commands[name].help } end
  return list
end

local function handle(input)
  input = (input or ""):match("^%s*(.-)%s*$")
  local name, rest = input:match("^(%S+)%s*(.*)$")
  name = name and name:lower() or (commands.path and "path") or (commands.settings and "settings") or "help"
  local cmd = commands[name]
  if not cmd then
    ns:Print(L["Unknown command: %s. Type /wf help."]:format(name))
    return
  end
  ns.SafeCall(cmd.fn, rest)
end

SLASH_ARCANIS1 = "/arcanis"
SLASH_ARCANIS2 = "/wf"
SlashCmdList["ARCANIS"] = handle

ns:RegisterCommand("help", function()
  ns:Print(L["Commands:"])
  for _, name in ipairs(commandOrder) do
    print("  |cffffff00/wf " .. name .. "|r " .. L[commands[name].help])
  end
end, "list commands")

ns:RegisterCommand("version", function()
  ns:Print(L["version %s"]:format(ns.version))
end, "show version")

ns:RegisterCommand("debug", function()
  ns.debug = not ns.debug
  ns:Print(L["debug output %s"]:format(ns.debug and L["on"] or L["off"]))
end, "toggle debug messages")

ns:RegisterCommand("modules", function()
  ns:Print(L["Modules:"])
  local any = false
  for name, mod in ns:IterateModules() do
    any = true
    print(("  %s  %s"):format(mod:IsEnabled() and ("|cff00ff00" .. L["on"] .. "|r ") or ("|cffff4040" .. L["off"] .. "|r"), name))
  end
  if not any then print("  " .. L["(no modules registered)"]) end
end, "list modules")

ns:RegisterCommand("toggle", function(args)
  args = (args or ""):match("^%s*(%S*)")
  if args == "" then ns:Print(L["Usage: /wf toggle <module>"]) return end
  local mod = ns:GetModule(args)
  if not mod then
    ns:Print(L["Module not found: '%s'"]:format(tostring(args)))
    return
  end
  mod:SetEnabled(not mod:IsEnabled())
  ns:Print((mod:IsEnabled() and L["%s enabled"] or L["%s disabled"]):format(args))
end, "<module> enable/disable a module")

-- Her seyi siler (altin defteri, kayitlar, fiyatlar, rare'ler): yalniz "/wf reset confirm" ile.
ns:RegisterCommand("reset", function(args)
  if (args or ""):lower():match("^%s*confirm%s*$") == nil then
    ns:Print(L["This erases every Arcanis setting and saved record (gold ledger, recordings, prices, rares). Type /wf reset confirm to go ahead."])
    return
  end
  ns:ResetDatabase()
  ns:Print(L["Settings reset. Type /reload to refresh the interface."])
end, "reset all settings")

-- /wf perf [sn]: kare suresi nereye gidiyor. Bilinen her kare / tik isleri ve olay dagitimi (SafeCall, olay adiyla)
-- sure boyunca sarilip olculur, sonra eski haline doner. Yalniz tani; kalici degisiklik yok.
local PERF_TARGETS = {
  { "Engine", "Evaluate" }, { "Engine", "Tick" }, { "Island", "Update" }, { "Nav", "Tick" },
  { "Window", "Update" }, { "Brain", "Get" }, { "Planner", "Next" },
}
function ns:Perf(seconds)
  local now = debugprofilestop
  if not now or self.perfRunning then return false end
  seconds = math.max(3, math.min(60, tonumber(seconds) or 10))
  local stats, restore = {}, {}
  local function add(label, ms)
    local s = stats[label]
    if not s then s = { total = 0, n = 0, max = 0 }; stats[label] = s end
    s.total, s.n = s.total + ms, s.n + 1
    if ms > s.max then s.max = ms end
  end
  local function wrap(tbl, key, label)
    local orig = tbl and tbl[key]
    if type(orig) ~= "function" then return end
    local function done(t0, ...)
      add(label, now() - t0)
      return ...
    end
    tbl[key] = function(...) return done(now(), orig(...)) end
    restore[#restore + 1] = function() tbl[key] = orig end
  end
  for _, t in ipairs(PERF_TARGETS) do wrap(ns[t[1]], t[2], t[1] .. ":" .. t[2]) end
  if ns.Island and ns.Island.Chat then wrap(ns.Island.Chat, "Refresh", "Chat:Refresh") end
  if ns.Island and ns.Island.Hub then wrap(ns.Island.Hub, "Update", "Hub:Update") end
  local safe = ns.SafeCall
  ns.SafeCall = function(fn, owner, event, ...)
    local t0 = now()
    local ok = safe(fn, owner, event, ...)
    add(type(event) == "string" and ("event " .. event) or "other calls", now() - t0)
    return ok
  end
  restore[#restore + 1] = function() ns.SafeCall = safe end
  -- kare sureleri
  local frames, worst, total = 0, 0, 0
  local clock = CreateFrame("Frame")
  clock:SetScript("OnUpdate", function(_, dt)
    frames, total = frames + 1, total + dt
    if dt > worst then worst = dt end
  end)
  self.perfRunning = true
  ns:Print(L["Measuring for %d s: keep doing what feels slow."]:format(seconds))
  local function finish()
    clock:SetScript("OnUpdate", nil)
    for i = #restore, 1, -1 do restore[i]() end
    self.perfRunning = nil
    local rows = {}
    for label, s in pairs(stats) do rows[#rows + 1] = { label = label, s = s } end
    table.sort(rows, function(a, b) return a.s.total > b.s.total end)
    ns:Print(L["Performance: %d frames, %.0f fps, worst frame %.0f ms. Arcanis time per item:"]:format(
      frames, frames / math.max(total, 0.001), worst * 1000))
    for i = 1, math.min(10, #rows) do
      local r = rows[i]
      print(("  %-34s %7.1f ms  %5d x  max %.1f ms"):format(r.label, r.s.total, r.s.n, r.s.max))
    end
    return rows
  end
  if not (ns.Provider and ns.Provider.After and ns.Provider.After(seconds, finish)) then self.perfFinish = finish end
  return true
end

ns:RegisterCommand("perf", function(args) ns:Perf(args) end, "[seconds] measure where frame time goes")

ns:RegisterCommand("locale", function(args)
  args = (args or ""):match("^%s*(.-)%s*$")
  local available = ns:DescribeLocales()
  if args == "" then
    ns:Print(L["Language: %s (available: %s)"]:format(ns.localeCode, available))
    return
  end
  local code = args:lower() == "auto" and "auto" or args
  if ns:SetLocale(code) then
    ns.db.locale = (code ~= "auto") and ns.localeCode or nil
    ns:Print(L["Language set to %s."]:format(ns.localeCode))
  else
    ns:Print(L["Unknown language: %s (available: %s)"]:format(args, available))
  end
end, "[code|auto] show or set the interface language")
