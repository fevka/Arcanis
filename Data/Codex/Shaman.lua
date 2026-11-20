-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Shaman talent builds for WoW Forever.

ns.Codex:RegisterBuild("SHAMAN", "Leveling", "Enhancement Leveling", 0, 31, 20,
{
	TALENTS = {
		"Improved Lightning Shield",
		"Guardian Totems",
		"Thundering Strikes",
		"Improved Ghost Wolf",
		"Anticipation",
		"Flurry",
		"Parry",
		"Rage of the Farseer",
		"Convection",
		"Concussion",
		"Call of Flame",
	},
	DESC = [[Enhancement Leveling (10-60, Forever)
	Windfury + Flurry with Thundering Strikes crit behind it. Improved Ghost Wolf (no more 1s cast tax era) keeps you moving between pulls; Guardian Totems toughen Stoneskin/Windwall/Grounding coverage. Rage of the Farseer at 40+ is the payoff storm.
	]],
	PROS = [[
*Windfury burst deletes quest mobs
*Self-heal (Lesser Healing Wave) + Ghost Wolf = great uptime
*Totems buff dungeon groups while you DPS
	]],
	CONS = [[
*Weapon dependent (slow 2H with high top-end)
*Totem twisting taxes mana on long chains
	]],
	ROT = [[
Stats: Agility/Strength > Attack Power > Crit > Stamina > Intellect
Weapon: slowest 2H (Windfury loves top-end); Rockbiter early, Windfury from 30
Single: Lightning Shield > Stormstrike (when available) > Earth Shock > auto
Multi: Magma/Fire Nova totem + Chain Lightning if Elemental-leaning
Totems: Strength of Earth + Windfury + Healing Stream + Searing; Totemic Projection repositions

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Mutant Scale Breastplate (Chest, Mail) - Mutanus the Devourer, Wailing Caverns
*Savage Trodders (Feet, Mail) - Lord Serpentis, Wailing Caverns
*Cobrahn's Grasp (Waist, Mail) - Lord Cobrahn, Wailing Caverns
*Ogre Grips (Hands, Mail) - Hamhock, The Stockade
*Jimmied Handcuffs (Wrist, Mail) - Bruegal Ironknuckle, The Stockade
*Bandsaw Wristbands (Wrist, Mail) - Sneed, The Deadmines

	]],
})

ns.Codex:RegisterBuild("SHAMAN", "PVE", "Restoration Riptide Raid", 0, 0, 51,
{
	TALENTS = {
		"Improved Healing Wave",
		"Tidal Focus",
		"Ancestral Healing",
		"Healing Grace",
		"Tidal Mastery",
		"Healing Way",
		"Nature's Swiftness",
		"Mana Tide Totem",
		"Riptide",
		"Totemic Focus",
		"Call of Thunder",
	},
	DESC = [[Restoration PVE (Level 60 raids, Forever)
	Riptide capstone gives Resto a real instant heal alongside Chain Heal bounces, Healing Way tank coverage and Mana Tide for the raid. Call of the Elements drops the full Totem Bar in one cast - your setup time is gone. Faster Lightning Bolt/Chain Lightning also means Ele-offspec threat on hybrid fights.
	]],
	PROS = [[
*Riptide + Chain Heal = best raid spread healing
*Mana Tide + Bloodlust-family tools = raid mana engine
*Totems (Tremor/Poison Cleansing/Grounding) trivialize mechanics
	]],
	CONS = [[
*Single-target burst below Paladin/Priest peaks
*Totem range forces positioning discipline
	]],
	ROT = [[
Stats: Healing/Spell Power > Intellect > mp5 > Crit > Spirit
Tank: Healing Way-buffed Healing Waves, Nature's Swiftness emergency
Raid: Chain Heal on melee clusters, Riptide on movers/tanks, Mana Tide on cooldown rotation
Totems: Mana Spring + Healing Stream + Tremor + situational resist; Call of the Elements opener
New raids: Hyjal Summit (20) - poison/disease cleansing duty; Barrow Deeps (10) - tight Riptide triage
	]],
})

ns.Codex:RegisterBuild("SHAMAN", "PVE", "Elemental Lava Burst Raid", 31, 20, 0,
{
	TALENTS = {
		"Convection",
		"Concussion",
		"Call of Flame",
		"Elemental Focus",
		"Call of Thunder",
		"Improved Fire Totems",
		"Lightning Overload",
		"Elemental Fury",
		"Lava Burst",
		"Thundering Strikes",
		"Guardian Totems",
	},
	DESC = [[Elemental PVE (Level 60 raids, Forever)
	Flame Shock > Lava Burst (+20% with Shock up) with Lightning Overload double-casts and Elemental Fury crit multiplier. Spells are half a second faster than Classic, so the rotation breathes. Earthbound root adds control no Classic Ele had.
	]],
	PROS = [[
*Lava Burst execute-style nuke with Shock synergy
*Overload procs = free damage, no extra mana
*Totem of Wrath-family hit/crit for the raid
	]],
	CONS = [[
*Mana-hungry; Clearcasting/Overload luck swings parses
*Threat-limited without Salvation; Tranquil Air discipline
	]],
	ROT = [[
Stats: Spell Power > Hit (cap) > Crit > Haste > Intellect
Single: Flame Shock > Lava Burst > Lightning Bolt filler > Chain Lightning on 2+
Cooldowns: Elemental Mastery + trinkets with Bloodlust; Mana Tide request rotation
Race: Orc (new Mage/Shaman options don't change Ele - stun resist still king), Troll Berserking, Dwarf NEW (Wildhammer - Stoneform clears bleeds), Skyborne Windshaper (Elemental Insight vs elementals)
	]],
})

ns.Codex:RegisterBuild("SHAMAN", "PVP", "Enhancement Windfury PVP", 11, 40, 0,
{
	TALENTS = {
		"Convection",
		"Concussion",
		"Elemental Focus",
		"Improved Lightning Shield",
		"Guardian Totems",
		"Thundering Strikes",
		"Improved Ghost Wolf",
		"Shamanistic Rage",
		"Flurry",
		"Parry",
		"Weapon Mastery",
		"Rage of the Farseer",
	},
	DESC = [[Enhancement PVP (Forever battlegrounds)
	Windfury one-shots with Shamanistic Rage sustain and Ghost Wolf mobility. Earthbind root (Earthbound) + Frost Shock kiting + Grounding Totem eats enemy cooldowns. Purge spam breaks Paladin/Priest sustain.
	]],
	PROS = [[
*Windfury burst ends fights in one stun window
*Ghost Wolf + root control the field
*Purge/Grounding/Cleansing answer every caster
	]],
	CONS = [[
*Kited by Frost Mages/Hunters without support
*Totems killable; repositioning costs globals
	]],
	ROT = [[
Opener: Lightning Shield > Stormstrike > Earth Shock (interrupt) > Windfury autos
Vs casters: Grounding pre-cast, Wind Shear-equivalent shocks, Purge buffs
Vs melee: Earthbind + Frost Shock kite, Stoneclaw timing, Shamanistic Rage to reset
Support: Bloodlust timing, off-heal with Nature's Swiftness, Tremor vs fear teams
	]],
})
