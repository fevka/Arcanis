-- Arcanis: yukseltme isaretleri (modul "ItemNeeds"in parcasi; ayarlar onun: bagArrow, rollMarks).
--   * Cantada: Gear:Upgrades'in buldugu giyilebilir yukseltmelerin dugmesinde yesil yukari ok (oyunun cantalari;
--     Baganator yukluyse onun kose ikonu API'si).
--   * Grup loot zarinda: yukseltmeye ok, takip listesindeki (Journal:Track) esyaya yildiz: "Need" de.
-- Hesap yalniz olaylarda (BAG_UPDATE_DELAYED, PLAYER_EQUIPMENT_CHANGED, seviye, START_LOOT_ROLL); boyama
-- hazir kumeden okur. Dokular korumasiz (dugmelerin cocugu), savasta da guvenli.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local GM = { ups = {}, marks = {} }
ns.GearMarks = GM

local function on(key)
  local IN = ns.ItemNeeds
  return IN and IN:IsEnabled() and IN.db and IN.db[key] ~= false or false
end

-- ===== Kararlar (testli) =====

-- Cantadaki yukseltmeler: Gear:Upgrades ile ayni kural (gomlek/tabard, bos yuvaya cop, takili kopya elenir).
-- Doner: { ["canta:yuva"] = fark }
function GM:Scan()
  local set = {}
  if on("bagArrow") and ns.Gear then
    local ok, list = pcall(ns.Gear.Upgrades, ns.Gear, 200)
    for _, u in ipairs(ok and list or {}) do
      if u.bag and u.bagSlot then set[u.bag .. ":" .. u.bagSlot] = u.delta end
    end
  end
  self.ups = set
  return set
end

function GM:IsBagUpgrade(bag, slot)
  return bag ~= nil and slot ~= nil and self.ups[bag .. ":" .. slot] ~= nil
end

local NO_UPGRADE = { INVTYPE_BODY = true, INVTYPE_TABARD = true }

-- Baglanti (rastgele ekli statlar dahil) takili esyadan iyi mi? Giyilemez / yuklenmedi / takilinin kendisi: false.
function GM:IsUpgrade(link)
  local G = ns.Gear
  local d = type(link) == "string" and P.ItemDetailsFromLink(link)
  if not (G and d and G.SLOTS[d.equipLoc]) or NO_UPGRADE[d.equipLoc] then return false end
  local ok, delta, _, eqLink, score = pcall(G.Compare, G, d)
  if not (ok and type(delta) == "number" and delta > 0.5) or (eqLink ~= nil and eqLink == link) then return false end
  return eqLink ~= nil or (type(score) == "number" and score > 0)
end

-- Loot zari: yukseltme mi, takip listesinde mi?
function GM:RollMarks(link)
  if not (link and on("rollMarks")) then return false, false end
  local id = P.ItemIdFromLink(link)
  local J = ns.Journal
  local wish = id and J and J.char and J:IsTracked(id) or false
  return self:IsUpgrade(link), wish and true or false
end

-- ===== Cizim =====

local function texture(btn, key, icon, size, point, x, y, r, g, b, rot)
  local t = btn[key]
  if not t then
    t = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetTexture(icon)
    t:SetSize(size, size)
    t:SetPoint(point, btn, point, x, y)
    if rot and t.SetRotation then t:SetRotation(rot) end
    t:SetVertexColor(r, g, b, 1)
    btn[key] = t
    GM.marks[#GM.marks + 1] = t
  end
  return t
end

-- sag ok (rarrow) 90 derece dondurulunce yukari bakar
local function upArrow(btn, size, point, x, y)
  return texture(btn, "arcUp", ns.Skin.Icons.rarrow, size or 16, point or "TOPLEFT", x or -2, y or 2, 0.3, 0.95, 0.35, math.pi / 2)
end
GM.UpArrow = upArrow

local function star(btn)
  return texture(btn, "arcStar", ns.Skin.Icons.star, 18, "TOPRIGHT", 6, 6, 1, 0.82, 0.2)
end

local function containerFrames()
  local list = {}
  for i = 1, (NUM_CONTAINER_FRAMES or 13) do
    local f = _G["ContainerFrame" .. i]
    if f then list[#list + 1] = f end
  end
  if ContainerFrameCombinedBags then list[#list + 1] = ContainerFrameCombinedBags end
  return list
end

local function eachButton(f, fn)
  if f.EnumerateValidItems then
    for _, btn in f:EnumerateValidItems() do fn(btn) end
    return
  end
  local name = f.GetName and f:GetName()
  for i = 1, 40 do
    local btn = name and _G[name .. "Item" .. i]
    if not btn then break end
    fn(btn)
  end
end

local function bagSlot(btn)
  local bag = btn.GetBagID and btn:GetBagID()
  if bag == nil then
    local parent = btn.GetParent and btn:GetParent()
    bag = parent and parent.GetID and parent:GetID()
  end
  return bag, btn.GetID and btn:GetID()
end

function GM:PaintBags()
  for _, f in ipairs(containerFrames()) do
    if f.IsShown and f:IsShown() then
      eachButton(f, function(btn)
        local up = self:IsBagUpgrade(bagSlot(btn))
        if up or btn.arcUp then upArrow(btn):SetShown(up) end   -- dugmeler baska cantaya yeniden kullanilir
      end)
    end
  end
end

local function rollIcon(f)
  local name = f.GetName and f:GetName()
  return f.IconFrame or (name and _G[name .. "IconFrame"]) or f
end

function GM:PaintRolls()
  for i = 1, (NUM_GROUP_LOOT_FRAMES or 4) do
    local f = _G["GroupLootFrame" .. i]
    if f and f.IsShown and f:IsShown() then
      local icon = rollIcon(f)
      local up, wish = self:RollMarks(P.LootRollLink(f.rollID))
      if up or icon.arcUp then upArrow(icon, 18, "BOTTOMRIGHT", 5, -5):SetShown(up) end
      if wish or icon.arcStar then star(icon):SetShown(wish) end
    end
  end
end

-- Baganator: kendi kose ikonu API'si (yalniz bu basit API varsa; yoksa oyunun cantalari yeter)
function GM:HookBagAddon()
  local api = type(Baganator) == "table" and type(Baganator.API) == "table" and Baganator.API
  if self.bagAddon or not (api and api.RegisterCornerWidget) then return end
  self.bagAddon = api
  pcall(api.RegisterCornerWidget, L["Arcanis: upgrade"], "arcanis_upgrade", function(_, details)
    if not on("bagArrow") then return false end
    local link = details and details.itemLink
    if not link then return false end
    if not P.ItemDetailsFromLink(link) then return nil end   -- esya bilgisi gelmedi: sonra yeniden sorar
    return GM:IsUpgrade(link)
  end, function(btn)
    local t = btn:CreateTexture(nil, "OVERLAY")
    t:SetTexture(ns.Skin.Icons.rarrow)
    t:SetSize(15, 15)
    if t.SetRotation then t:SetRotation(math.pi / 2) end
    t:SetVertexColor(0.3, 0.95, 0.35, 1)
    return t
  end, { corner = "top_left", priority = 1 })
end

function GM:Refresh()
  self.pending = nil
  self:Scan()
  self:PaintBags()
end

-- olaylar kumelenir (cok canta olayi tek taramaya)
function GM:Queue()
  if self.pending then return end
  self.pending = true
  if not P.After(0.2, function() ns.SafeCall(GM.Refresh, GM) end) then self:Refresh() end
end

-- ItemNeeds:OnEnable cagirir; olaylar modulun adina (kapaninca ns:OffAll temizler)
function GM:Start(owner)
  ns:On("BAG_UPDATE_DELAYED", owner, function() GM:Queue() end)
  ns:On("PLAYER_EQUIPMENT_CHANGED", owner, function() GM:Queue() end)
  ns:On("PLAYER_LEVEL_UP", owner, function() GM:Queue() end)
  ns:On("START_LOOT_ROLL", owner, function()
    if not P.After(0.1, function() ns.SafeCall(GM.PaintRolls, GM) end) then GM:PaintRolls() end
  end)
  ns:On("ADDON_LOADED", owner, function() GM:HookBagAddon() end)
  self:HookBagAddon()
  if not self.hooked then
    self.hooked = true
    for _, f in ipairs(containerFrames()) do
      if f.HookScript then f:HookScript("OnShow", function() ns.SafeCall(GM.PaintBags, GM) end) end
      if f.UpdateItems and hooksecurefunc then hooksecurefunc(f, "UpdateItems", function() ns.SafeCall(GM.PaintBags, GM) end) end
    end
    if ContainerFrame_Update and hooksecurefunc then
      hooksecurefunc("ContainerFrame_Update", function() ns.SafeCall(GM.PaintBags, GM) end)
    end
    for i = 1, (NUM_GROUP_LOOT_FRAMES or 4) do
      local f = _G["GroupLootFrame" .. i]
      if f and f.HookScript then f:HookScript("OnShow", function() ns.SafeCall(GM.PaintRolls, GM) end) end
    end
  end
  self:Queue()
end

function GM:Clear()
  self.ups = {}
  for _, t in ipairs(self.marks) do t:Hide() end
end
