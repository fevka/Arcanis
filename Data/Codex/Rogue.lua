-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Rogue talent builds for WoW Forever.

ns.Codex:RegisterBuild("ROGUE", "Leveling", "Combat Swords Leveling", 20, 31, 0,
{
	TALENTS = {
		"Improved Sinister Strike",
		"Precision",
		"Dual Wield Specialization",
		"Riposte",
		"Flawless Execution",
		"Hack and Slash",
		"Blade Flurry",
		"Adrenaline Rush",
		"Malice",
		"Ruthlessness",
		"Relentless Strikes",
		"Lethality",
	},
	DESC = [[Combat Leveling (10-60, Forever)
	Fastest all-round solo Rogue: two swords, Sinister Strike + Eviscerate, Blade Flurry at 32-ish, Adrenaline Rush at 42-ish, then Malice/Relentless Strikes/Lethality from Assassination. Hack and Slash rewards swords; Riposte gives a reason to value parry while fighting face-to-face.
	]],
	PROS = [[
*Blade Flurry = fastest multi-mob clearing Rogue has
*Riposte + Flawless Execution smooth solo combat
*No positional requirement (unlike dagger builds)
	]],
	CONS = [[
*Weapon dependent; slow main-hand upgrades hurt
*Energy starvation without Slice and Dice upkeep
	]],
	ROT = [[
Stats: Agility > Attack Power > Hit > Crit > Stamina
Weapons: 2x swords (Hack and Slash); keep Instant Poison main, Deadly off
Single: Sinister Strike > Slice and Dice (uptime first) > Eviscerate at 5
Multi: Blade Flurry + Adrenaline Rush, Evasion for the second mob
Stealth bonus: Cheap Shot/Ambush openers on humanoids, Sap extra targets

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Gloves of the Fang (Hands, Leather) - Trash Drops, Wailing Caverns
*Footpads of the Fang (Feet, Leather) - Lord Serpentis, Wailing Caverns
*Armor of the Fang (Chest, Leather) - Lord Pythas, Wailing Caverns
*Leggings of the Fang (Legs, Leather) - Lord Cobrahn, Wailing Caverns
*Serpent's Shoulders (Shoulder, Leather) - Lady Anacondra, Wailing Caverns
*Belt of the Fang (Waist, Leather) - Lady Anacondra, Wailing Caverns

	]],
})

ns.Codex:RegisterBuild("ROGUE", "PVE", "Assassination Mutilate Venom", 31, 20, 0,
{
	TALENTS = {
		"Malice",
		"Ruthlessness",
		"Relentless Strikes",
		"Cold Blood",
		"Improved Poisons",
		"Vile Poisons",
		"Lethality",
		"Seal Fate",
		"Mutilate",
		"Venom",
		"Precision",
		"Dual Wield Specialization",
		"Puncturing Wounds",
	},
	DESC = [[Assassination PVE (Level 60 dungeons/raids, Forever)
	Dagger build around Mutilate + Venom + Seal Fate, poison-first priority. Mutilate needs 20 Assassination points and daggers; Venom (31) converts combo points into a poison-damage window. Seal Fate at 35 (leveling route) keeps the cycle fed. Requires attacking from behind - position or GTFO.
	]],
	PROS = [[
*Huge single-target with poisons rolling + Venom window
*Cold Blood guarantees opener crits
*Brings Expose Armor + interrupts (Kick)
	]],
	CONS = [[
*Daggers-only Mutilate; swords are a different build
*Positional; frontal-immune bosses punish the spec
	]],
	ROT = [[
Stats: Hit (cap, Precision helps) > Agility > Attack Power > Crit
Poisons: Instant main-hand, Deadly off-hand; Venom window = reapply aggressively
Single: Mutilate to 4-5 > Slice and Dice > Mutilate > Venom > Eviscerate/Rupture
Cooldowns: Cold Blood + Adrenaline-family trinkets on pull, Vanish for threat drop
Tier: Grimstitch Armor bonuses favor this build; carry poison consumables
	]],
})

ns.Codex:RegisterBuild("ROGUE", "PVP", "Subtlety Control PVP", 20, 0, 31,
{
	TALENTS = {
		"Camouflage",
		"Master of Deception",
		"Opportunity",
		"Elusiveness",
		"Dirty Tricks",
		"Improved Ambush",
		"Premeditation",
		"Serrated Blades",
		"Preparation",
		"Hemorrhage",
		"Dirty Deeds",
		"Quietus",
		"Thousand Cuts",
		"Malice",
		"Ruthlessness",
	},
	DESC = [[Subtlety PVP (Forever battlegrounds)
	Stealth access, Premeditation openers, Preparation double Vanish/Evasion, Hemorrhage mid-tree distinct button, Thousand Cuts capstone fed by Rupture ticks (energy discounts). No Shadowstep in Forever - mobility is Sprint/Vanish/Preparation resets + WotF-style racial answers.
	]],
	PROS = [[
*Best opener control (Cheap Shot/Ambush/Premeditation)
*Preparation = second life every fight
*Cold Blood (Assassination dip) guarantees Eviscerate kills
	]],
	CONS = [[
*No Shadowstep; sticking to targets takes setup
*Thousand Cuts needs Rupture rolling to pay off
	]],
	ROT = [[
Opener: Stealth > Premeditation > Ambush/Cheap Shot > Hemorrhage > Rupture > Thousand Cuts window
Reset: Vanish > re-stealth > second opener; Preparation refreshes Vanish+Evasion
Vs casters: Kick/Garrote silence pressure, Blind the healer, stack bleeds
Battlegrounds: guard/roam with Camouflage + Elusiveness; Darkspear Islands skirmish role
	]],
})
