-- Arcanis: yetenek planlayicisi (modul "TalentPlanner"). Class Codex > Talents > Planner: oyuncu yetenek agacinda
-- puan puan plan yapar, karakter basina adli planlar saklar, leveling build'imizle karsilastirir, metin olarak disa /
-- ice aktarir. "Siradaki talent icin kullan" secili plan rotasyon yardimcisinin talent rehberini surer
-- (Rotation/TalentGuide.lua ns.ActiveBuild).
-- Agac: oyunun kendi trait agaci (ns.RF.TalentLayout: bolum, satir, x, max rank, buyu, dugum, kenarlar). Kurallar
-- Classic'inki: satir basina bolumde 5 puan, kenarla bagli ust dugum tam rutbede, secim dugumunde tek giris, 51 puan.
-- Plan = puan sirasi (her puan bir yetenek anahtari: buyu kimligi, yoksa ad). Gecerlilik sira bastan oynatilarak
-- denetlenir; bu yuzden puan kaldirmak sonrakileri bozuyorsa reddedilir.
-- Metin bicimi (kendi bicimimiz): "AP1:<SINIF>:<anahtar.anahtar...>:<puan sirasi>", anahtar buyu kimligi 36 tabanli
-- (ad ise "!" onekli), puan sirasi anahtar listesinde 0-61 sira, tek karakter. Hesaplayici linkleri ve loadout kodlari
-- rotasyon yardimcisinin cozucusuyle (ns.RF.DecodeTalentCode) okunur, sira bolum bolum satir satir kurulur.
local _, ns = ...

local P = ns.Provider
local L = ns.L

local TP = ns:NewModule("TalentPlanner", { charDefaults = { presets = {} } })
ns.TalentPlanner = TP

TP.MAX_POINTS = 51
TP.ROW_POINTS = 5
local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

-- ===== Agac =====
-- layout: { { rec, ... } x3 } (RF.TalentLayout bicimi). Doner: grid { cells = { cell }, byKey, byName }
-- cell = { key, name, spellID, nodeID, section, row, col, max, parents = { anahtar } }
function TP.Grid(layout)
  local grid = { cells = {}, byKey = {}, byName = {} }
  local byNode = {}
  for s, list in ipairs(layout or {}) do
    local xs, col = {}, {}
    for _, rec in ipairs(list) do xs[#xs + 1] = rec.x or 0 end
    table.sort(xs)
    for _, x in ipairs(xs) do if not col[x] then col[x] = (col.n or 0) + 1; col.n = col[x] end end
    for _, rec in ipairs(list) do
      local key = rec.spellID or rec.name
      if key and not grid.byKey[key] then
        local c = { key = key, name = rec.name, spellID = rec.spellID, nodeID = rec.nodeID, section = s,
                    row = rec.row or 1, col = col[rec.x or 0] or 1, max = rec.max or 1, edges = rec.edges, parents = {} }
        grid.cells[#grid.cells + 1] = c
        grid.byKey[key] = c
        grid.byName[rec.name:lower()] = c
        if rec.nodeID then byNode[rec.nodeID] = byNode[rec.nodeID] or {}; table.insert(byNode[rec.nodeID], c) end
      end
    end
  end
  -- kenar kaynagi hedefin onkosulu
  for _, c in ipairs(grid.cells) do
    for _, target in ipairs(c.edges or {}) do
      for _, t in ipairs(byNode[target] or {}) do t.parents[#t.parents + 1] = c.key end
    end
  end
  return grid
end

-- Oyunun agaci (okunamadiysa nil)
function TP:LiveGrid()
  local RF = ns.RF
  if not (RF and RF.TalentLayout and RF.TalentCount and RF.TalentCount() > 0) then return nil end
  return TP.Grid(RF.TalentLayout())
end

-- ===== Kurallar =====
function TP.Ranks(order)
  local r = {}
  for _, k in ipairs(order or {}) do r[k] = (r[k] or 0) + 1 end
  return r
end

-- Bir puan su an verilebilir mi: ranks/spent (bolum basina) o ana kadarki durum. Doner: true ya da false, neden.
local function legal(grid, key, ranks, spent, total)
  local c = grid.byKey[key]
  if not c then return false, "unknown" end
  if total >= TP.MAX_POINTS then return false, "points" end
  if (ranks[key] or 0) >= c.max then return false, "max" end
  if (spent[c.section] or 0) < (c.row - 1) * TP.ROW_POINTS then return false, "row" end
  for _, pk in ipairs(c.parents) do
    local p = grid.byKey[pk]
    if p and (ranks[pk] or 0) < p.max then return false, "parent" end
  end
  if c.nodeID then
    for _, o in ipairs(grid.cells) do
      if o ~= c and o.nodeID == c.nodeID and (ranks[o.key] or 0) > 0 then return false, "choice" end
    end
  end
  return true
end

-- Sira bastan oynatilir. Doner: true ya da false, bozuk puanin sirasi, neden.
function TP.Validate(grid, order)
  local ranks, spent = {}, {}
  for i, k in ipairs(order or {}) do
    local ok, why = legal(grid, k, ranks, spent, i - 1)
    if not ok then return false, i, why end
    local c = grid.byKey[k]
    ranks[k] = (ranks[k] or 0) + 1
    spent[c.section] = (spent[c.section] or 0) + 1
  end
  return true
end

-- Plana puan ekler / son puanini kaldirir. Doner: true ya da false, neden.
function TP.Add(grid, plan, key)
  local order = plan.order
  order[#order + 1] = key
  local ok, _, why = TP.Validate(grid, order)
  if not ok then order[#order] = nil end
  return ok, why
end

function TP.Remove(grid, plan, key)
  local order = plan.order
  for i = #order, 1, -1 do
    if order[i] == key then
      table.remove(order, i)
      local ok, _, why = TP.Validate(grid, order)
      if not ok then table.insert(order, i, key) return false, why end
      return true
    end
  end
  return false, "none"
end

-- Bolum basina puan
function TP.Spent(grid, order)
  local spent = { 0, 0, 0 }
  for _, k in ipairs(order or {}) do
    local c = grid.byKey[k]
    if c then spent[c.section] = (spent[c.section] or 0) + 1 end
  end
  return spent
end

-- Sirasiz rutbelerden ({ anahtar = rutbe }) gecerli sira: once en cok puanli bolum, her bolumde satir satir
-- (ayni satirda once onkosul olanlar); kalan puanlar sonraki turlarda. Doner: order ya da nil.
function TP.OrderFromRanks(grid, ranks)
  local spent = { 0, 0, 0 }
  for k, n in pairs(ranks) do
    local c = grid.byKey[k]
    if not c then return nil end
    spent[c.section] = spent[c.section] + n
  end
  local cells = {}
  for _, c in ipairs(grid.cells) do if (ranks[c.key] or 0) > 0 then cells[#cells + 1] = c end end
  table.sort(cells, function(a, b)
    if a.section ~= b.section then
      if spent[a.section] ~= spent[b.section] then return spent[a.section] > spent[b.section] end
      return a.section < b.section
    end
    if a.row ~= b.row then return a.row < b.row end
    return a.col < b.col
  end)
  local order, have, left = {}, {}, 0
  for _, c in ipairs(cells) do left = left + ranks[c.key] end
  -- her turda verilebilen ilk puan; tur ilerlemezse gecersiz
  while left > 0 do
    local placed = false
    for _, c in ipairs(cells) do
      if (have[c.key] or 0) < ranks[c.key] then
        order[#order + 1] = c.key
        if TP.Validate(grid, order) then
          have[c.key] = (have[c.key] or 0) + 1
          left, placed = left - 1, true
          break
        end
        order[#order] = nil
      end
    end
    if not placed then return nil end
  end
  return order
end

-- ===== Metin =====
local function b36(n)
  local s = ""
  repeat
    local d = n % 36
    s = DIGITS:sub(d + 1, d + 1) .. s
    n = math.floor(n / 36)
  until n == 0
  return s
end

function TP.Export(order, class)
  local keys, at, seq = {}, {}, {}
  for _, k in ipairs(order) do
    if not at[k] then
      keys[#keys + 1] = type(k) == "number" and b36(k) or ("!" .. tostring(k):gsub("[%.:]", ""))
      at[k] = #keys
    end
    local i = at[k] - 1
    seq[#seq + 1] = DIGITS:sub(i + 1, i + 1)
  end
  return ("AP1:%s:%s:%s"):format(class or "", table.concat(keys, "."), table.concat(seq))
end

-- Doner: order, sinif ya da nil, hata metni
function TP.Import(grid, text, class)
  text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local cls, head, seq = text:match("^AP1:(%u*):([^:]*):(%w*)$")
  if cls then
    if class and cls ~= "" and cls ~= class then return nil, nil, L["This plan is for another class."] end
    local keys = {}
    for part in (head .. "."):gmatch("([^%.]*)%.") do
      if part ~= "" then keys[#keys + 1] = part:sub(1, 1) == "!" and part:sub(2) or tonumber(part, 36) end
    end
    local order = {}
    for ch in seq:gmatch(".") do
      local k = keys[(DIGITS:find(ch, 1, true) or 0)]
      if k == nil or not grid.byKey[k] then return nil, nil, L["The plan does not match your talent tree."] end
      order[#order + 1] = k
    end
    if not TP.Validate(grid, order) then return nil, nil, L["The plan breaks the talent rules."] end
    return order, cls
  end
  -- hesaplayici linki / loadout kodu: ad -> rutbe, sira bizden
  local RF = ns.RF
  local ranks, err = RF and RF.DecodeTalentCode and RF.DecodeTalentCode(text)
  if not ranks then return nil, nil, err or L["Unknown code."] end
  local byKey = {}
  for name, r in pairs(ranks) do
    local c = grid.byName[name:lower()]
    if not c then return nil, nil, L["The plan does not match your talent tree."] end
    byKey[c.key] = r
  end
  local order = TP.OrderFromRanks(grid, byKey)
  if not order then return nil, nil, L["The plan breaks the talent rules."] end
  return order
end

-- ===== Planlar (karakter basina) =====
function TP:Presets() return self.char.presets end

function TP:NewPreset(name, order)
  local list = self.char.presets
  list[#list + 1] = { name = name or L["Plan %d"]:format(#list + 1), order = order or {} }
  return #list
end

function TP:DeletePreset(i)
  local list = self.char.presets
  if not list[i] then return end
  table.remove(list, i)
  if self.char.active == i then self.char.active = nil
  elseif self.char.active and self.char.active > i then self.char.active = self.char.active - 1 end
  self:Changed()
end

function TP:SetActive(i)
  self.char.active = i
  self:Changed()
end

-- talent rehberi ve isaretler yeniden
function TP:Changed()
  local RF = ns.RF
  if RF and RF.TalentGuide_Update then ns.SafeCall(RF.TalentGuide_Update) end
end

-- Rotasyon yardimcisinin build bicimi: { key, name, spec, steps = { { ad, hedef rutbe } } } ya da nil
function TP:ActiveBuild(grid)
  if not self:IsEnabled() then return nil end
  local p = self.char.active and self.char.presets[self.char.active]
  if not (p and #p.order > 0) then return nil end
  grid = grid or self:LiveGrid()
  if not grid then return nil end
  local steps, count = {}, {}
  for _, k in ipairs(p.order) do
    local c = grid.byKey[k]
    if c then
      count[k] = (count[k] or 0) + 1
      steps[#steps + 1] = { c.name, count[k] }
    end
  end
  local spent, spec = TP.Spent(grid, p.order), 1
  for s = 2, 3 do if spent[s] > spent[spec] then spec = s end end
  return { key = "planner", name = p.name, spec = spec, steps = steps, source = "planner" }
end

-- Codex build'inin hedef rutbeleri (anahtar -> rutbe); ad agacta yoksa unknown listesinde
function TP.BuildRanks(grid, build)
  local out, unknown = {}, {}
  local RF = ns.RF
  for _, name in ipairs(build and build.TALENTS or {}) do
    local c = grid.byName[name:lower()]
    if not c and RF and RF.Talent then
      local rec = RF.Talent(name)
      c = rec and grid.byName[rec.name:lower()]
    end
    if c then
      out[c.key] = build.PERPOINT and math.min((out[c.key] or 0) + 1, c.max) or c.max
    else
      unknown[#unknown + 1] = name
    end
  end
  return out, unknown
end

-- Plan ile build farki: { { name, plan, build } } (yalniz farkli olanlar, agac sirasinda)
function TP.Compare(grid, order, build)
  local mine, theirs = TP.Ranks(order), TP.BuildRanks(grid, build)
  local out = {}
  for _, c in ipairs(grid.cells) do
    local a, b = mine[c.key] or 0, theirs[c.key] or 0
    if a ~= b then out[#out + 1] = { name = c.name, key = c.key, plan = a, build = b } end
  end
  return out
end
