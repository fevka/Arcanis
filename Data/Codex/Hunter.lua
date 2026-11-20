-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Hunter talent builds for WoW Forever.

ns.Codex:RegisterBuild("HUNTER", "Leveling", "Beast Mastery Pet Leveling", 31, 20, 0,
{
	TALENTS = {
		"Improved Aspect of the Hawk",
		"Endurance Training",
		"Thick Hide",
		"Unleashed Fury",
		"Ferocity",
		"Spirit Bond",
		"Intimidation",
		"Bestial Wrath",
		"Lethal Shots",
		"Mortal Shots",
		"Aimed Shot",
	},
	DESC = [[Beast Mastery Leveling (10-60, Forever)
	The classic pet-tank leveling machine, improved: Bestial Wrath at 40 turns your pet into a second player for 18 seconds. Send pet, stack Serpent Sting, auto + Arcane Shot. Spirit Bond + Mend Pet means near-zero downtime across all 60 levels.
	]],
	PROS = [[
*Pet tanks = safest solo class in the game
*Bestial Wrath melts elites and dungeon bosses
*Feign Death + traps save bad pulls
	]],
	CONS = [[
*Pet management (feed, train ranks, revive costs)
*Damage split: you + pet must both scale
	]],
	ROT = [[
Stats: Agility > Attack Power > Crit > Stamina > Intellect
Pet: Boar/Boar-family early (Charge), Cat later (DPS); keep Growl on, feed for loyalty
Single: Hunter's Mark > Serpent Sting > Auto + Arcane Shot > Multi-Shot on adds
Elite: Bestial Wrath + Intimidation stun + Rapid Fire
New dungeons: Blackmaw Hold (55-60) - Tranq Shot duty often falls on you

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Mutant Scale Breastplate (Chest, Mail) - Mutanus the Devourer, Wailing Caverns
*Savage Trodders (Feet, Mail) - Lord Serpentis, Wailing Caverns
*Cobrahn's Grasp (Waist, Mail) - Lord Cobrahn, Wailing Caverns
*Ogre Grips (Hands, Mail) - Hamhock, The Stockade
*Jimmied Handcuffs (Wrist, Mail) - Bruegal Ironknuckle, The Stockade
*Bandsaw Wristbands (Wrist, Mail) - Sneed, The Deadmines

	]],
})

ns.Codex:RegisterBuild("HUNTER", "PVE", "Marksmanship Lone Wolf Raid", 5, 31, 15,
{
	TALENTS = {
		"Endurance Training",
		"Lethal Shots",
		"Mortal Shots",
		"Aimed Shot",
		"Efficiency",
		"Hawk Eye",
		"Sniper Shot",
		"Scatter Shot",
		"Deflection",
		"Survivalist",
	},
	DESC = [[Marksmanship PVE (Level 60 raids, Forever)
	Lone Wolf makes petless ranged Hunter real: build around Sniper Shot and ranged crit. Aimed Shot is trained now, so your points buy Efficiency + Hawk Eye + Mortal Shots multipliers instead of the shot itself. Sniper Shot is the 31-point payoff - long-range execute pressure on Hyjal Summit and Barrow Deeps bosses.
	]],
	PROS = [[
*Top ranged DPS without pet AI duties
*Trueshot Aura = raid-wide AP both MM and BM want
*Tranq Shot + traps = raid utility
	]],
	CONS = [[
*No pet = no offtank/intercept safety net
*Mana-hungry; Viper management on long fights
	]],
	ROT = [[
Stats: Agility > Hit (cap) > Crit > Attack Power > Haste
Single: Hunter's Mark > Serpent Sting > Aimed Shot > Multi-Shot (weave) > Auto filler
Execute: Sniper Shot window on bosses under threshold
Aspects: Hawk (damage), Viper only when OOM, Cheetah never in combat
Camp: Skinning Camp Chair (2% crit) does NOT stack with Moonkin Aura - check group
	]],
})

ns.Codex:RegisterBuild("HUNTER", "PVP", "Survival Trap Control PVP", 0, 20, 31,
{
	TALENTS = {
		"Improved Wing Clip",
		"Deflection",
		"Entrapment",
		"Survivalist",
		"Counterattack",
		"Lacerating Strikes",
		"Lethal Shots",
		"Mortal Shots",
		"Aimed Shot",
		"Scatter Shot",
	},
	DESC = [[Survival PVP (Forever battlegrounds)
	Control melee/trap plan around the Survival capstone Lacerating Strikes. Scatter Shot + Freezing Trap + Wing Clip kiting, Counterattack punishes melee. Survival support points keep ranged options open when closed down.
	]],
	PROS = [[
*Best Hunter dueling toolkit (traps + scatter + wing clip)
*Lacerating Strikes bleeds through bubble-adjacent mitigation
*Flare + Track Hidden counters Rogues/Druids
	]],
	CONS = [[
*Lower pure burst than MM
*Trap arming still takes setup and prediction
	]],
	ROT = [[
Opener: Hunter's Mark > Concussive > kite > Scatter > Freezing Trap > Aimed burst
Melee on you: Wing Clip > Counterattack > Disengage-range kite > Entrapment Frost
Vs stealth: Flare on cooldown, track, AoE Multi-Shot to break stealth
Race: Dwarf Stoneform (bleed/poison clear), Orc stun resist, Human new pairing solid
	]],
})
