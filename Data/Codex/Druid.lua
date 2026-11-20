-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Druid talent builds for WoW Forever.

ns.Codex:RegisterBuild("DRUID", "Leveling", "Feral Cat Leveling", 0, 31, 20,
{
	TALENTS = {
		"Ferocity",
		"Brutal Impact",
		"Sharpened Claws",
		"Feral Aggression",
		"Primal Fury",
		"Feline Swiftness",
		"Primal Bite",
		"Berserk",
		"Furor",
		"Natural Shapeshifter",
		"Thick Hide",
	},
	DESC = [[Feral Leveling (10-60, Forever)
	Cat from 20 with Primal Bite (no debuff tax anymore) and Berserk waiting at 40+. Bear for elites and dungeons on the same tree. Furor energy on shapeshift + Feline Swiftness keep the pace; heal yourself between pulls and never stop.
	]],
	PROS = [[
*Fastest Druid leveling (cat burst + travel form at 30)
*Bear tanks all leveling dungeons
*Zero downtime (heals, roots, stealth skips)
	]],
	CONS = [[
*Gear two sets (cat DPS + bear mitigation)
*Primal Bite lost its debuff - pure damage now
	]],
	ROT = [[
Stats: Agility/Strength > Attack Power > Crit > Stamina (cat); Stamina/Armor/Defense (bear)
Cat: Pounce/Ravage opener > Claw/Shred > Rip + Ferocious Bite finishers > Primal Bite on cooldown
Bear: Maul + Swipe threat, Bash stuns, Frenzied Regeneration panic
Form flow: Travel between packs, Cat to kill, Bear when things go wrong, caster to heal

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Gloves of the Fang (Hands, Leather) - Trash Drops, Wailing Caverns
*Footpads of the Fang (Feet, Leather) - Lord Serpentis, Wailing Caverns
*Armor of the Fang (Chest, Leather) - Lord Pythas, Wailing Caverns
*Leggings of the Fang (Legs, Leather) - Lord Cobrahn, Wailing Caverns
*Serpent's Shoulders (Shoulder, Leather) - Lady Anacondra, Wailing Caverns
*Belt of the Fang (Waist, Leather) - Lady Anacondra, Wailing Caverns

	]],
})

ns.Codex:RegisterBuild("DRUID", "PVE", "Restoration Wild Growth Raid", 0, 11, 40,
{
	TALENTS = {
		"Furor",
		"Natural Shapeshifter",
		"Naturalist",
		"Omen of Clarity",
		"Tranquil Spirit",
		"Improved Rejuvenation",
		"Nature's Swiftness",
		"Gift of Nature",
		"Improved Tranquility",
		"Wild Growth",
		"Sharpened Claws",
		"Primal Fury",
	},
	DESC = [[Restoration PVE (Level 60 raids, Forever)
	Wild Growth capstone gives Resto the raid-wide blanket heal Classic lacked, alongside Nature's Swiftness + Tranquility. Improved Mark of the Wild is baseline - your points buy healing, not the buff. Innervate the Priest, battle-rez the tank, decurse the raid.
	]],
	PROS = [[
*Wild Growth + Rejuvenation blanketing = best HoT coverage
*Innervate + Battle Rez = raid-defining utility
*Bear off-tank possible on hybrid points
	]],
	CONS = [[
*Direct burst below Paladin/Priest peaks
*Dispel/curse duty eats globals on some bosses
	]],
	ROT = [[
Stats: Spirit (regen) > Healing/Spell Power > Intellect > mp5 > Crit
Tank: Rejuvenation + Regrowth + Healing Touch ranks
Raid: Wild Growth on cooldown clusters, Rejuvenation pre-HoT, Tranquility for AoE bursts
Utility: Innervate your Priest at 70% mana, Battle Rez priority targets, Decurse/Nature's Cure rotation
Camp: Herbalism Incense Candle (Intellect) does NOT stack with Arcane Intellect - coordinate
	]],
})

ns.Codex:RegisterBuild("DRUID", "PVE", "Balance Eclipse Raid", 31, 20, 0,
{
	TALENTS = {
		"Improved Wrath",
		"Nature's Grasp",
		"Focused Starlight",
		"Improved Moonfire",
		"Insect Swarm",
		"Vengeance",
		"Moonkin Form",
		"Eclipse",
		"Furor",
		"Natural Shapeshifter",
		"Thick Hide",
	},
	DESC = [[Balance PVE (Level 60 raids, Forever)
	Wrath hits ~50% harder than Classic and Eclipse proc-weaves Wrath/Starfire. Omen of Clarity and Nature's Grasp are trained, so points go to Vengeance crit and Moonkin aura. The spec is real in Forever - bring Faerie Fire, crit aura, and Innervate.
	]],
	PROS = [[
*Eclipse windows = competitive caster DPS
*Moonkin aura (crit) + Faerie Fire + Innervate = raid value
*Combat rez + off-heals in one package
	]],
	CONS = [[
*Mana-hungry; needs Innervate/potion planning
*Hit-capped gear competes with Mages/Locks
	]],
	ROT = [[
Stats: Hit (cap) > Spell Power (Nature/Arcane) > Crit > Haste > Intellect
Single: Faerie Fire > Moonfire + Insect Swarm upkeep > Wrath to Eclipse > Starfire during Lunar
AoE: Hurricane on demand, Barkskin to finish casts
Form: Moonkin for aura (armor trade accepted), caster to Innervate/rez
	]],
})

ns.Codex:RegisterBuild("DRUID", "PVP", "Feral Flag Runner PVP", 14, 37, 0,
{
	TALENTS = {
		"Ferocity",
		"Brutal Impact",
		"Sharpened Claws",
		"Feral Aggression",
		"Primal Fury",
		"Feline Swiftness",
		"Primal Bite",
		"Heart of the Wild",
		"Berserk",
		"Furor",
		"Natural Shapeshifter",
	},
	DESC = [[Feral PVP (Forever battlegrounds)
	Uncatchable flag carrier and node defender: Travel Form + Feline Swiftness + Bear durability, Powershift out of slows, Bash/Charge-equivalent interrupts, Berserk kill windows. Skyborne forms work identically - pick for looks.
	]],
	PROS = [[
*Best flag carrier (speed + durability + self-heals)
*Powershifting breaks slows/roots
*Berserk + Primal Bite burst surprises
	]],
	CONS = [[
*Mana burns fast under dispel/purge pressure
*Needs support vs focused burst trains
	]],
	ROT = [[
Carry: Bear + Frenzied Regeneration + Barkskin, Travel Form between points, heal in caster only when safe
Fight: Pounce > Maim/Bash > Primal Bite > Ferocious Bite; Bear vs melee trains
Support: roots, Cyclone-equivalent control, Innervate your healer, rez after wipes
	]],
})
