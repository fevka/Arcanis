-- Arcanis: davet ve duello suzgeci (modul "Social"). Iki anahtar, ikisi de varsayilan kapali:
--   invites: arkadas, Battle.net arkadasi ya da lonca uyesi olmayanin grup davetini reddeder
--   duels  : her duello istegini reddeder
-- Reddedilen her biri db.blocked'ta sayilir; bildirim turu "social" (Toast, ns.NOTICE_TYPES).
local _, ns = ...

local P = ns.Provider
local L = ns.L

local Social = ns:NewModule("Social", {
  defaults = { invites = false, duels = false, notify = true, blocked = { invites = 0, duels = 0 } },
})
ns.Social = Social

-- Karar: "decline" ya da nil. known = arkadas / Battle.net / lonca
function Social.Decide(db, kind, known)
  if kind == "invite" then return (db.invites and not known) and "decline" or nil end
  if kind == "duel" then return db.duels and "decline" or nil end
  return nil
end

function Social:Blocked(kind, name)
  local key = kind == "invite" and "invites" or "duels"
  self.db.blocked[key] = (self.db.blocked[key] or 0) + 1
  if self.db.notify and ns.Toast then
    local text = kind == "invite" and L["Declined a group invite from %s"] or L["Declined a duel from %s"]
    ns.Toast:Show(text:format(type(name) == "string" and name or "?"), "info", nil, nil, { cat = "social", prio = "low" })
  end
end

function Social:OnInvite(_, name, _, _, _, _, _, guid)
  name = P.NotSecret(name)
  if Social.Decide(self.db, "invite", P.KnownPlayer(name, guid)) and P.DeclineInvite() then self:Blocked("invite", name) end
end

function Social:OnDuel(_, name)
  name = P.NotSecret(name)
  if Social.Decide(self.db, "duel") and P.DeclineDuel() then self:Blocked("duel", name) end
end

function Social:OnEnable()
  ns:On("PARTY_INVITE_REQUEST", self, "OnInvite")
  ns:On("DUEL_REQUESTED", self, "OnDuel")
end
