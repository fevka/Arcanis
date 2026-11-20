-- Arcanis Path sayfasi: Keybinds. Tus atama (tikla, tusa bas) ve hazir makrolar.
local _, ns = ...

local Win = ns.PathWindow
local Skin = ns.Skin
local C = Skin.Colors
local L = ns.L
local unpack = unpack or table.unpack
local U = Win.UI
local fstr, safe = U.fstr, U.safe

-- Tus yakalama: tum ekrani kaplayan gorunmez cerceve klavye, fare tuslari (orta, 4, 5; sol/sag yalniz Shift/Ctrl/
-- Alt ile) ve tekerlegi dinler; ESC ya da degistiricisiz sol/sag tik iptal eder.
local capture
-- owner: sayfa; sayfa gizlenirse (pencere kapandi) ya da savas baslarsa yakalama iptal olur (sonraki tus yutulmasin).
local function startCapture(onKey, owner)
  if not capture then
    capture = CreateFrame("Frame", nil, UIParent)
    capture:SetAllPoints(UIParent)
    capture:SetFrameStrata("FULLSCREEN_DIALOG")
    capture:EnableKeyboard(true)
    capture:EnableMouse(true)
    if capture.EnableMouseWheel then capture:EnableMouseWheel(true) end
    local function take(self, input)
      local combo = ns.Keys.Combo(input, IsAltKeyDown and IsAltKeyDown(), IsControlKeyDown and IsControlKeyDown(),
        IsShiftKeyDown and IsShiftKeyDown())
      if combo == false then return end   -- yalniz degistirici: asil tus beklenir
      self:Hide()
      if self.onKey then self.onKey(combo) end   -- nil: iptal, etiket eski haline doner
    end
    capture:SetScript("OnKeyDown", take)
    capture:SetScript("OnMouseDown", take)
    capture:SetScript("OnMouseWheel", function(self, delta) take(self, delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
    local function cancel(self)
      self:Hide()
      if self.onKey then self.onKey(nil) end
    end
    capture:SetScript("OnUpdate", function(self)
      if self.owner and self.owner.IsVisible and not self.owner:IsVisible() then cancel(self) end
    end)
    capture:SetScript("OnEvent", cancel)   -- PLAYER_REGEN_DISABLED
    capture:SetScript("OnHide", function(self) self:UnregisterAllEvents() end)
  end
  capture.onKey, capture.owner = onKey, owner
  capture:RegisterEvent("PLAYER_REGEN_DISABLED")
  capture:Show()
  return capture
end

local function buildKeys(page)
  local K = ns.Keys
  local ob = ns.Settings.OptionList(page)
  page.keyRows = {}

  ob:Header("Key bindings", "Click Set, then press a key or mouse button (middle, 4, 5, wheel; left and right only with Shift, Ctrl or Alt). Esc cancels.")
  for _, b in ipairs(K.BINDINGS) do
    ob:Custom(b.title, b.desc, 300, function(r)
      local clear = Skin:CreateButton(r, L["Clear"], 70, 22)
      clear:SetPoint("RIGHT", r, "RIGHT", -12, 0)
      local set = Skin:CreateButton(r, L["Set"], 70, 22, true)
      set:SetPoint("RIGHT", clear, "LEFT", -6, 0)
      local key = fstr(r, 12, C.accentHover, "RIGHT", "OUTLINE")
      key:SetPoint("RIGHT", set, "LEFT", -12, 0)
      key:SetWidth(130)
      set:SetScript("OnClick", safe(function()
        key:SetText(L["Press a key..."])
        page.capture = startCapture(function(combo)
          if combo then
            local ok, why = K:SetKey(b.name, combo)
            if not ok and why == "combat" then ns:Print(L["Not possible in combat."]) end
          end
          page.refresh()
        end, page)
      end))
      clear:SetScript("OnClick", safe(function() K:ClearKey(b.name); page.refresh() end))
      page.keyRows[#page.keyRows + 1] = { def = b, key = key, set = set, frame = r }
    end)
  end

  ob:Header("Macros", "Ready-made macros for your action bars. Install, then drag them from the macro window (/macro).")
  page.macroRows = {}
  for _, m in ipairs(K.MACROS) do
    ob:Custom(m.title, m.desc, 260, function(r)
      local btn = Skin:CreateButton(r, "", 110, 22, true)
      btn:SetPoint("RIGHT", r, "RIGHT", -12, 0)
      local state = fstr(r, 11, C.textDim, "RIGHT")
      state:SetPoint("RIGHT", btn, "LEFT", -12, 0)
      state:SetWidth(120)
      btn:SetScript("OnClick", safe(function()
        local ok, why = K:InstallMacro(m)
        if not ok then ns:Print(why == "combat" and L["Not possible in combat."] or L["No free macro slots."]) end
        page.refresh()
      end))
      page.macroRows[#page.macroRows + 1] = { def = m, btn = btn, state = state }
    end)
  end

  if _G.BinderPanel then
    ob:Header("ArcanisBinder", nil)
    ob:Buttons("Open ArcanisBinder", "Class key binding and action bar sets from ArcanisBinder.", {
      { "Open ArcanisBinder", function() local b = _G.BinderPanel; if b and b.Show then b:Show() end end },
    })
  end

  ob:Finish(function()
    for _, e in ipairs(page.keyRows) do
      local k1 = K:KeyOf(e.def.name)
      e.key:SetText(k1 or ("|cff777777" .. L["not set"] .. "|r"))
    end
    for _, e in ipairs(page.macroRows) do
      local installed = K:MacroIndex(e.def) > 0
      e.state:SetText(installed and ("|cff66dd77" .. L["installed"] .. "|r") or L["not installed"])
      e.btn:SetText(installed and L["Update"] or L["Install"])
    end
  end)
end

Win:RegisterPage({
  id = "keys", order = 80, icon = "menu",
  title = function() return L["Keybinds"] end,
  available = function() return ns.Keys and ns.Keys:IsEnabled() end,
  build = buildKeys,
})
