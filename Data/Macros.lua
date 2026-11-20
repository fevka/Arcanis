-- Arcanis: sinif makrolari (Class Codex > Macros). Hepsi ozgun; Forever (Classic tabanli) buyuleriyle yazildi.
--   name  : makro adi (en cok 16 harf, oyunun makro listesindeki ad)
--   spells: buyu ID'leri; govdedeki {1}, {2}... kurulurken oyunun dilindeki buyu adina doner (P.SpellName)
--   need  : kurulabilmesi icin bilinmesi gereken buyuler (spells icindeki sira numarasi; yoksa {1})
--   icon  : buyusuz makronun ikonu (buyulu makrolar buyu ikonlarindan secer, Keys:MacroIcons)
--   kind  : hazir aciklama ("help" | "focus" | "harm"), ya da desc(adlar) -> metin
-- Oyunda olmayan bir buyu (P.SpellName nil) makroyu listeden cikarir.
local _, ns = ...
local L = ns.L

local HELP = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {1}"
local FOCUS = "#showtooltip\n/cast [@focus,harm,nodead][] {1}"
local HARM = "#showtooltip\n/cast [@mouseover,harm,nodead][] {1}"

local function help(name, id) return { name = name, spells = { id }, body = HELP, kind = "help" } end
local function focus(name, id) return { name = name, spells = { id }, body = FOCUS, kind = "focus" } end
local function harm(name, id) return { name = name, spells = { id }, body = HARM, kind = "harm" } end
local buff = help
local function wand() return { name = "AP Wand", spells = { 5019 }, body = "#showtooltip\n/cast !{1}",
  desc = function(n) return L["Starts shooting your wand without turning it off when pressed again (%s)."]:format(n[1]) end } end

ns.ClassMacros = {
  -- her sinifa: odak hedefi makrolarin "focus" satirlari icin
  ALL = {
    { name = "AP Focus", body = "/focus [@mouseover,exists,nodead][]", icon = "Spell_Holy_MindVision",
      desc = function() return L["Sets your focus to the unit under your mouse, else your target. The focus macros below use it."] end },
  },
  WARRIOR = {
    { name = "AP Charge", spells = { 100, 20252, 2457 }, need = { 1, 3 },
      body = "#showtooltip\n/cast [stance:1] {1}; [stance:3] {2}; {3}",
      desc = function(n) return L["%s in Battle Stance, %s in Berserker Stance; in any other stance it switches to Battle Stance."]:format(n[1], n[2]) end },
    { name = "AP Strike", spells = { 78 }, body = "#showtooltip {1}\n/startattack\n/cast {1}",
      desc = function(n) return L["Starts auto-attack and queues %s on your next swing."]:format(n[1]) end },
    { name = "AP Interrupt", spells = { 72, 6552 }, body = "#showtooltip\n/cast [stance:3] {2}; {1}",
      desc = function(n) return L["%s in Battle or Defensive Stance (needs a shield), %s in Berserker Stance."]:format(n[1], n[2]) end },
    harm("AP Taunt", 355),
  },
  MAGE = {
    focus("AP Poly", 118),
    focus("AP Counter", 2139),
    buff("AP Intellect", 1459),
    wand(),
  },
  PRIEST = {
    help("AP Flash", 2061),
    help("AP Renew", 139),
    help("AP Shield", 17),
    help("AP Dispel", 527),
    buff("AP Fortitude", 1243),
    wand(),
  },
  DRUID = {
    help("AP Rejuv", 774),
    help("AP Touch", 5185),
    help("AP Innervate", 29166),
    help("AP Rebirth", 20484),
    buff("AP Wild", 1126),
    { name = "AP Faerie", spells = { 770, 16857 }, body = "#showtooltip\n/cast [noform] {1}; {2}",
      desc = function(n) return L["%s in caster form, %s in Bear or Cat Form."]:format(n[1], n[2]) end },
  },
  PALADIN = {
    help("AP Holy Light", 635),
    help("AP Flash", 19750),
    help("AP Purify", 1152),
    help("AP Protect", 1022),
    focus("AP Hammer", 853),
    buff("AP Blessing", 19740),
  },
  SHAMAN = {
    help("AP Wave", 331),
    help("AP Lesser Wave", 8004),
    help("AP Cure", 526),
    focus("AP Shock", 8042),
  },
  ROGUE = {
    { name = "AP Opener", spells = { 1833, 1752 }, body = "#showtooltip\n/startattack\n/cast [stealth] {1}; {2}",
      desc = function(n) return L["%s while stealthed, %s otherwise."]:format(n[1], n[2]) end },
    { name = "AP Ambush", spells = { 8676, 53 }, body = "#showtooltip\n/startattack\n/cast [stealth] {1}; {2}",
      desc = function(n) return L["%s while stealthed, %s otherwise."]:format(n[1], n[2]) end },
    { name = "AP Stealth", spells = { 1784 }, body = "#showtooltip {1}\n/cast [nostealth] {1}",
      desc = function(n) return L["Enters %s but never cancels it when pressed again."]:format(n[1]) end },
    harm("AP Sap", 6770),
    focus("AP Kick", 1766),
  },
  HUNTER = {
    { name = "AP Pet", spells = { 982, 883, 136 }, need = { 2 },
      body = "#showtooltip\n/cast [@pet,dead] {1}; [nopet] {2}; {3}",
      desc = function(n) return L["One button for your pet: %s if it is dead, %s if it is away, %s otherwise."]:format(n[1], n[2], n[3]) end },
    { name = "AP Pull", spells = { 3044 }, body = "#showtooltip {1}\n/petattack\n/cast {1}",
      desc = function(n) return L["Sends your pet in and fires %s."]:format(n[1]) end },
    { name = "AP Aspect", spells = { 13165, 5118 }, need = { 1, 2 },
      body = "#showtooltip\n/cast [combat] {1}; {2}",
      desc = function(n) return L["%s in combat, %s out of combat."]:format(n[1], n[2]) end },
    { name = "AP Pet Attack", body = "/petattack [@mouseover,harm,nodead][]",
      desc = function() return L["Sends your pet at the enemy under your mouse, else your target."] end },
  },
  WARLOCK = {
    { name = "AP Dots", spells = { 172, 980, 348 }, need = { 1, 2, 3 },
      body = "#showtooltip\n/castsequence reset=target {1}, {2}, {3}",
      desc = function(n) return L["Press repeatedly: %s, %s, then %s. A new target starts over."]:format(n[1], n[2], n[3]) end },
    focus("AP Fear", 5782),
    harm("AP Banish", 710),
    { name = "AP Pet Attack", body = "/petattack [@mouseover,harm,nodead][]",
      desc = function() return L["Sends your pet at the enemy under your mouse, else your target."] end },
    wand(),
  },
}
