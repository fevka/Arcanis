-- Arcanis: modul sistemi.
--
--   local M = ns:NewModule("Arrow", { defaults = { scale = 1 }, charDefaults = {} })
--   function M:OnInitialize() end   -- veritabani hazir, bir kez
--   function M:OnEnable() end       -- modul acildiginda
--   function M:OnDisable() end      -- modul kapandiginda
--   M.db     -> ns.db.modules[isim]    (hesap geneli)
--   M.char   -> ns.char.modules[isim]  (karakter bazli)
--
-- Bir modul kullanici tarafindan kapatildiysa (M:SetEnabled(false)) bu tercih
-- ns.db.modules[isim].disabled altinda saklanir.
local _, ns = ...

local modules = {}
local order = {}
local booted = false

local Module = {}
Module.__index = Module

function Module:IsEnabled()
  return self.enabled == true
end

function Module:Enable()
  if self.enabled or not self.initialized then return false end
  self.enabled = true
  if self.OnEnable then ns.SafeCall(self.OnEnable, self) end
  ns:Send("ARCANIS_MODULE_ENABLED", self.name)
  return true
end

function Module:Disable()
  if not self.enabled then return false end
  self.enabled = false
  ns:OffAll(self)
  if self.OnDisable then ns.SafeCall(self.OnDisable, self) end
  ns:Send("ARCANIS_MODULE_DISABLED", self.name)
  return true
end

-- Kullanici tercihi: kalici olarak ac/kapat.
function Module:SetEnabled(state)
  if not self.initialized then return end
  -- varsayilani kapali modulde acik secim false yazilir (nil'i FillDefaults yeniden "kapali" yapardi)
  if self.defaults.disabled then self.db.disabled = not state else self.db.disabled = (not state) or nil end
  if state then self:Enable() else self:Disable() end
end

local function initModule(mod)
  if mod.initialized then return end
  ns.db.modules[mod.name] = ns.db.modules[mod.name] or {}
  ns.char.modules[mod.name] = ns.char.modules[mod.name] or {}
  mod.db = ns.FillDefaults(ns.db.modules[mod.name], mod.defaults)
  mod.char = ns.FillDefaults(ns.char.modules[mod.name], mod.charDefaults)
  mod.initialized = true
  if mod.OnInitialize then ns.SafeCall(mod.OnInitialize, mod) end
end

function ns:NewModule(name, opts)
  assert(type(name) == "string" and name ~= "", "Arcanis: module name required")
  assert(not modules[name], "Arcanis: module '" .. name .. "' already exists")
  opts = opts or {}
  local mod = setmetatable({
    name = name,
    defaults = opts.defaults or {},
    charDefaults = opts.charDefaults or {},
    enabled = false,
    initialized = false,
  }, Module)
  modules[name] = mod
  order[#order + 1] = name
  -- Gec kaydolan modul (veritabani zaten hazirsa) hemen baslatilir.
  if booted then
    initModule(mod)
    if not mod.db.disabled then mod:Enable() end
  end
  return mod
end

function ns:GetModule(name)
  return modules[name]
end

function ns:IterateModules()
  local i = 0
  return function()
    i = i + 1
    local name = order[i]
    if name then return name, modules[name] end
  end
end

-- Boot.lua tarafindan cagrilir.
function ns:InitializeModules()
  booted = true
  for _, name in ipairs(order) do initModule(modules[name]) end
end

function ns:EnableModules()
  for _, name in ipairs(order) do
    local mod = modules[name]
    if mod.initialized and not mod.db.disabled then mod:Enable() end
  end
end
