-- Arcanis: olay yonetimi.
--   Oyun olaylari : ns:On(event, owner, handler) / ns:Off(event, owner)
--   Ic mesajlar   : ns:Listen(msg, owner, handler) / ns:Unlisten(msg, owner) / ns:Send(msg, ...)
-- handler: fonksiyon, owner icindeki metot adi (string) ya da nil (owner[event]).
-- Cagri sekli: handler(owner, event, ...)
local _, ns = ...

local frame = CreateFrame("Frame")
local gameListeners = {}   -- event -> { {owner=, fn=}, ... }
local msgListeners = {}    -- message -> { {owner=, fn=}, ... }

local function resolve(owner, event, handler)
  handler = handler or event
  if type(handler) == "string" then
    local method = owner[handler]
    assert(type(method) == "function", "Arcanis: '" .. handler .. "' method not found")
    return method
  end
  assert(type(handler) == "function", "Arcanis: gecersiz handler")
  return handler
end

local function add(map, key, owner, fn)
  local list = map[key]
  if not list then
    list = {}
    map[key] = list
  end
  for _, entry in ipairs(list) do
    if entry.owner == owner then
      entry.fn = fn          -- ayni owner tekrar kaydolursa guncelle
      return false
    end
  end
  list[#list + 1] = { owner = owner, fn = fn }
  return true
end

local function remove(map, key, owner)
  local list = map[key]
  if not list then return false end
  for i = #list, 1, -1 do
    if list[i].owner == owner then
      table.remove(list, i)
      if #list == 0 then map[key] = nil end
      return true
    end
  end
  return false
end

local function dispatch(list, event, ...)
  if not list then return end
  local snapshot = {}                       -- dagitim sirasinda degisiklige karsi kopya
  for i = 1, #list do snapshot[i] = list[i] end
  for i = 1, #snapshot do
    local entry = snapshot[i]
    ns.SafeCall(entry.fn, entry.owner, event, ...)
  end
end

frame:SetScript("OnEvent", function(_, event, ...)
  dispatch(gameListeners[event], event, ...)
end)

-- Olay kaydi: dinleyenlerin hepsi ayni birimi istiyorsa (unit, ornek "player") oyun yalniz o birimin olayini
-- gonderir (RegisterUnitEvent); biri bile tum birimleri istiyorsa RegisterEvent. Basarisiz kayit false doner.
local unitOf, registered = {}, {}   -- event -> kayitli birim (nil: tum birimler); kayit yapildi mi
local function register(event)
  local list, unit = gameListeners[event], nil
  for i, e in ipairs(list) do
    if i == 1 then unit = e.unit elseif e.unit ~= unit then unit = nil end
  end
  if not (unit and frame.RegisterUnitEvent) then unit = nil end
  if registered[event] and unitOf[event] == unit then return true end
  if registered[event] then frame:UnregisterEvent(event) end   -- filtre degisti: yeniden kaydol
  local ok
  if unit then ok = pcall(frame.RegisterUnitEvent, frame, event, unit)
  else ok = pcall(frame.RegisterEvent, frame, event) end
  registered[event], unitOf[event] = ok or nil, ok and unit or nil
  return ok
end

-- unit (istege bagli): yalniz bu birimin UNIT_* olaylari (sik olaylar sehirde her oyuncu icin gelmesin).
function ns:On(event, owner, handler, unit)
  owner = owner or self
  local fn = resolve(owner, event, handler)
  add(gameListeners, event, owner, fn)
  for _, e in ipairs(gameListeners[event]) do if e.owner == owner then e.unit = unit end end
  -- Bilinmeyen olay (istemci surumune gore yok) tum modulu dusurmesin; kaydi geri al.
  if not register(event) then
    remove(gameListeners, event, owner)
    if gameListeners[event] then register(event) end   -- filtre degisirken kayit silinmisti: kalanlar geri
    ns:Debug("unknown event: " .. tostring(event))
  end
end

function ns:Off(event, owner)
  owner = owner or self
  if not remove(gameListeners, event, owner) then return end
  if not gameListeners[event] then
    frame:UnregisterEvent(event)
    unitOf[event], registered[event] = nil, nil
  else
    register(event)   -- kalanlar tek birim istiyorsa filtre daralir
  end
end

function ns:OffAll(owner)
  for event in pairs(gameListeners) do ns:Off(event, owner) end
  for msg in pairs(msgListeners) do remove(msgListeners, msg, owner) end
end

function ns:Listen(msg, owner, handler)
  owner = owner or self
  add(msgListeners, msg, owner, resolve(owner, msg, handler))
end

function ns:Unlisten(msg, owner)
  remove(msgListeners, msg, owner or self)
end

function ns:Send(msg, ...)
  dispatch(msgListeners[msg], msg, ...)
end
