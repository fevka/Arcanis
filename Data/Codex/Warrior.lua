-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Warrior talent builds for WoW Forever.

ns.Codex:RegisterBuild("WARRIOR", "Leveling", "Arms Leveling 2H", 31, 20, 0,
{
	TALENTS = {
		"Deflection",
		"Cruelty",
		"Improved Rend",
		"Improved Charge",
		"Tactical Mastery",
		"Improved Overpower",
		"Anger Management",
		"Deep Wounds",
		"Two-Handed Weapon Specialization",
		"Impale",
		"Sweeping Strikes",
		"Mortal Strike",
		"Cruelty",
		"Unbridled Wrath",
		"Improved Cleave",
		"Blood Craze",
	},
	DESC = [[Arms Leveling (10-60, Forever)
	Classic Arms leveling adapted for Forever: Rend + Overpower windows, Tactical Mastery keeps 10 Rage when you swap stances, and trained Slam fills gaps from level 20. Mortal Strike at 40 is your execution tool through the 40s and 50s.
	]],
	PROS = [[
*Strong solo burst with Overpower + Mortal Strike
*Deflection + Tactical Mastery smooth stance dancing
*Trained Slam gives a real button while questing
	]],
	CONS = [[
*Weapon dependent: a slow 2H upgrade matters more than talents
*Downtime between pulls without a healer
	]],
	ROT = [[
Stats: Strength > Attack Power > Crit > Agility > Stamina
Weapon: slowest 2H you can find, keep it within ~5 levels
Single: Charge > Rend > Mortal Strike > Overpower (on dodge) > Slam filler > Execute under 20%
Multi: Sweeping Strikes + Cleave/Whirlwind
Stance: Battle for damage, Defensive when tanking dungeons (Hall of Thanes 13-18, Lordaeron 15-20)

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Mutant Scale Breastplate (Chest, Mail) - Mutanus the Devourer, Wailing Caverns
*Savage Trodders (Feet, Mail) - Lord Serpentis, Wailing Caverns
*Cobrahn's Grasp (Waist, Mail) - Lord Cobrahn, Wailing Caverns
*Ogre Grips (Hands, Mail) - Hamhock, The Stockade
*Jimmied Handcuffs (Wrist, Mail) - Bruegal Ironknuckle, The Stockade
*Bandsaw Wristbands (Wrist, Mail) - Sneed, The Deadmines

	]],
})

ns.Codex:RegisterBuild("WARRIOR", "PVE", "Fury Dual-Wield Raid", 17, 34, 0,
{
	TALENTS = {
		"Cruelty",
		"Unbridled Wrath",
		"Improved Demoralizing Shout",
		"Enrage",
		"Flurry",
		"Bloodthirst",
		"Deflection",
		"Improved Rend",
		"Tactical Mastery",
		"Anger Management",
		"Deep Wounds",
		"Impale",
	},
	DESC = [[Fury PVE (Level 60 dungeons/raids, Forever)
	Fury keeps its Classic identity: Bloodthirst + Flurry sustain with Enrage windows. Forever tuned Sunder Armor threat (small AP scaling), so your raid job is real DPS while the tank holds with Shield Slam. Improved Intercept stays in Fury for movement fights (Hyjal Summit, Barrow Deeps).
	]],
	PROS = [[
*Best sustained Warrior DPS with Flurry uptime
*Enrage + Bloodthirst self-healing smooths healers' job
*Brings Battle Shout + Sunder support
	]],
	CONS = [[
*Needs hit gear before it shines (hit cap matters most)
*Squishy without a shield; stance discipline required
	]],
	ROT = [[
Stats: Hit (cap first) > Crit > Strength/Attack Power > Haste
Weapons: 2x slow 1H (or 2H Fury if your loot luck says so)
Single: Bloodthirst on cooldown > Whirlwind > Heroic Strike (rage dump) > Execute under 20%
Multi: Whirlwind + Cleave with Sweeping Strikes if Arms-sub
Cooldowns: Death Wish + Recklessness on pull, Bloodrage to open
Camp: Blacksmithing Sharpening Wheel (Strength) + campfire food XP buff
	]],
})

ns.Codex:RegisterBuild("WARRIOR", "PVP", "Arms Mortal Strike PVP", 33, 18, 0,
{
	TALENTS = {
		"Deflection",
		"Improved Rend",
		"Improved Charge",
		"Tactical Mastery",
		"Improved Hamstring",
		"Improved Overpower",
		"Anger Management",
		"Deep Wounds",
		"Two-Handed Weapon Specialization",
		"Impale",
		"Mortal Strike",
		"Improved Intercept",
		"Enrage",
	},
	DESC = [[Arms PVP (Forever battlegrounds)
	Mortal Strike's 50% healing reduction is the win condition. Improved Hamstring + Improved Intercept (trained ranks 30/42/52) give Forever Arms real stickiness. Weapon specializations are gone, so the tree is about control + burst, not passive weapon lock-in.
	]],
	PROS = [[
*Mortal Strike shuts down healers
*Intercept + Hamstring control mobile targets
*Skyborne Walk on Air glide helps repositioning
	]],
	CONS = [[
*Kited by Frost Mages without support
*Needs a healer or Engineering cover to stay up
	]],
	ROT = [[
Stats: Stamina > Strength > Crit (survive the opener, then burst)
Opener: Charge > Rend > Mortal Strike > Hamstring > Overpower on dodge
Vs casters: Intercept stun + Pummel/Shield Bash (swap Defensive for reflect value)
Racials: Orc stun resist, Human perception-style tools, Forsaken WotF (toned down in Forever) all viable
	]],
})
