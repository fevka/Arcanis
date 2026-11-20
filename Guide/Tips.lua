-- Arcanis: gorev ipuclari (ns.Tips).
-- Kaynaklar (oncelik sirasiyla): oyuncunun kendi ipuclari (ns.db.tips, /wf tip) ve Data/QuestTips.lua varsayilanlari.
-- Deger duz metin ya da { enUS = "...", trTR = "..." } tablosu olabilir. Anahtar: gorev ID'si.
local _, ns = ...

local Tips = { defaults = {} }
ns.Tips = Tips

function Tips:SetDefaults(map)
  for id, text in pairs(map) do self.defaults[id] = text end
end

function Tips:Get(questId)
  if not questId then return nil end
  local user = ns.db and ns.db.tips and ns.db.tips[questId]
  local value = user or self.defaults[questId]
  if value == nil then return nil end
  local text = ns:LocalizedText(value)
  if text and text ~= "" then return text end
  return nil
end

-- Kestirme ipucu (veride shortcut = true, ornek olum kestirmesi): adim penceresinde quest kutusu kapali olsa da
-- ayri satirda gosterilir. Metin ya da nil.
function Tips:Shortcut(questId)
  local value = questId and self.defaults[questId]
  if type(value) ~= "table" or not value.shortcut then return nil end
  local text = ns:LocalizedText(value)
  return text ~= "" and text or nil
end

function Tips:Set(questId, text)
  ns.db.tips = ns.db.tips or {}
  ns.db.tips[questId] = text
end

-- /wf tip                -> aktif adimin gorevinin ipucunu gosterir
-- /wf tip <id>           -> o gorevin ipucunu gosterir
-- /wf tip [id] <metin>   -> kendi ipucunu kaydeder
-- /wf tip [id] clear     -> kendi ipucunu siler
ns:RegisterCommand("tip", function(args)
  args = (args or ""):match("^%s*(.-)%s*$")
  local id, rest = args:match("^(%d+)%s*(.*)$")
  if not id then
    local step = ns.Engine and ns.Engine:GetStep()
    id, rest = step and step.quest, args
  end
  id = tonumber(id)
  if not id then
    ns:Print(ns.L["Usage: /wf tip [questId] <text|clear>"])
    return
  end
  if rest == "" then
    local tip = Tips:Get(id)
    ns:Print(tip and ns.L["Tip: %s"]:format(tip) or ns.L["No tip for quest %d."]:format(id))
  elseif rest == "clear" then
    ns.db.tips = ns.db.tips or {}
    ns.db.tips[id] = nil
    ns:Print(ns.L["Tip removed for quest %d."]:format(id))
  else
    Tips:Set(id, rest)
    ns:Print(ns.L["Tip saved for quest %d."]:format(id))
  end
  if ns.Window then ns.Window:Update() end
end, "[questId] [text|clear] show or set a quest tip")
