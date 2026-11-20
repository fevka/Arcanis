-- Arcanis: gorev odulu ekipman kaynagi (modul "ItemNeeds"in parcasi; ayar `questUps`).
-- Gorev odulu verisi pakette yok (bildigimiz kaynaklar atif istiyor): oyuncu bir gorevin penceresini gorunce
-- (QUEST_DETAIL, QUEST_COMPLETE) odul esyalari hesap geneli kaydedilir: `IN.db.rewards[gorev] = { c = { secimli },
-- r = { sabit } }` (yalniz esya kimligi). Diger karakterler de yararlanir.
-- IN:QuestUpgrades: gunlukteki, rehberde sirasi gelecek (simdiki + sonraki rehber) ve yakindaki rehber disi
-- gorevlerin bilinen odulleri Gear:SourceUpgrade ile puanlanir. Class Codex > Character ve Mentor "Now" gosterir.
local _, ns = ...

local P = ns.Provider
local IN = ns.ItemNeeds

IN.QUEST_AHEAD = 3   -- odul en cok bu kadar seviye sonra giyilebilir (zindan yukseltmeleriyle ayni pencere)

local function ids(count, linkFn)
  local out = {}
  for i = 1, count do
    local id = P.ItemIdFromLink(linkFn(i))
    if not id then return nil end   -- baglanti henuz gelmedi: eksik liste yazilmaz
    out[#out + 1] = id
  end
  return out
end

-- Acik gorev penceresinin odullerini kaydet. Doner: true (kaydedildi ya da esya odulu yok), false (eksik).
function IN:RecordRewards()
  local q = P.QuestID()
  if not q or q == 0 then return true end
  local nc, nr = P.QuestChoiceCount(), P.QuestRewardCount()
  if nc == 0 and nr == 0 then return true end
  local c, r = ids(nc, P.QuestChoiceLink), ids(nr, P.QuestRewardLink)
  if not (c and r) then return false end
  self.db.rewards = self.db.rewards or {}
  self.db.rewards[q] = { c = #c > 0 and c or nil, r = #r > 0 and r or nil }
  return true
end

-- Pencere olayi: hemen oku (otomatik kabul pencereyi kapatabilir), eksikse bir kez sonra dene
function IN:OnQuestWindow()
  if self:RecordRewards() then return end
  P.After(0.5, function() ns.SafeCall(IN.RecordRewards, IN) end)
end

local function giver(q)
  local g = ns.BrainData and ns.BrainData.givers and ns.BrainData.givers[q]
  if not g then return nil end
  return g[1], g[6], g[7], g[8] and g[8] * 100, g[9] and g[9] * 100
end

-- Gorev odulu yukseltmeleri, buyukten kucuge. Doner: list, pending (esya bilgisi yuklenmedi: sonra yeniden sor)
--   { quest, name, itemId, link, delta, slot, slotName, needLevel?, source = "log"|"guide"|"next"|"near",
--     npc?, zone?, x?, y? (0-100) }
function IN:QuestUpgrades(level, info, token, limit)
  local rewards = self.db and self.db.rewards
  local G = ns.Gear
  if not (G and rewards and next(rewards) and self.db.questUps ~= false) then return {}, false end
  local src, order = {}, {}
  local function add(q, kind)
    if q and rewards[q] and not src[q] and not P.IsQuestFlaggedCompleted(q) then
      src[q] = kind
      order[#order + 1] = q
    end
  end
  for _, e in ipairs(P.QuestLogList()) do add(e.id, "log") end
  local E = ns.Engine
  if E and E.guide then
    local steps = E.guide.steps or {}
    for i = (E.Reach and E:Reach()) or 1, #steps do
      local s = steps[i]
      if s.type == "accept" and E:IsVisible(s, info) then add(s.quest, "guide") end
    end
    local nextGuide = ns.Guides and ns.Guides.GetNext and ns.Guides:GetNext(E.guide, info)
    for _, s in ipairs(nextGuide and nextGuide.steps or {}) do
      if s.type == "accept" and E:IsVisible(s, info) then add(s.quest, "next") end
    end
    local B, zone = ns.Brain, P.ZoneText and P.ZoneText()
    if B and B.GiversNear and zone then
      local ok, gs = pcall(B.GiversNear, B, zone, E.guide, info)
      for _, g in ipairs(ok and gs or {}) do add(g.quest, "near") end
    end
  end
  local specId = G:GetSpec(token)
  local out, pending = {}, false
  for _, q in ipairs(order) do
    local best
    for _, list in ipairs({ rewards[q].c or {}, rewards[q].r or {} }) do
      for _, id in ipairs(list) do
        local item = P.ItemDetails(id)
        if not item then
          pending = true
        else
          local delta, slot, at = G:SourceUpgrade(item, token, specId, level, self.QUEST_AHEAD)
          if delta and (not best or delta > best.delta) then
            best = { quest = q, itemId = id, link = item.link, delta = delta, slot = slot, slotName = G:SlotName(slot),
              needLevel = at > level and at or nil, source = src[q] }
          end
        end
      end
    end
    if best then
      local name, npc, zone, x, y = giver(q)
      best.name = P.QuestName(q, name)
      best.npc, best.zone, best.x, best.y = npc, zone, x, y
      out[#out + 1] = best
    end
  end
  table.sort(out, function(a, b) return a.delta > b.delta end)
  for i = #out, (limit or 10) + 1, -1 do out[i] = nil end
  return out, pending
end
