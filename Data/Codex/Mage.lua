-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Mage talent builds for WoW Forever.

ns.Codex:RegisterBuild("MAGE", "Leveling", "Frost Leveling Control", 0, 0, 51,
{
	TALENTS = {
		"Improved Frostbolt",
		"Elemental Precision",
		"Ice Shards",
		"Frostbite",
		"Improved Frost Nova",
		"Permafrost",
		"Piercing Ice",
		"Cold Snap",
		"Shatter",
		"Ice Block",
		"Winter's Chill",
		"Ice Barrier",
	},
	DESC = [[Frost Leveling (10-60, Forever)
	The AoE-farming king, untouched at its core: Frostbite + Shatter crits, Improved Nova control, Cold Snap double-block safety. Ice Lance joins the tree as a finisher. Level as Frost, farm as Frost, and only consider Fire at 60 with gear + a tank.
	]],
	PROS = [[
*Safest solo: roots, slows, double Ice Block
*AoE grinding (Blizzard + Frostbite) = fastest 40-60 XP/hour
*Free food/water/ports = zero upkeep
	]],
	CONS = [[
*Single-target below Fire with equal gear at 60
*Resists on higher-level mobs punish grinding above range
	]],
	ROT = [[
Stats: Intellect > Spell Power (Frost) > Crit (Shatter) > Stamina > Spirit
Single: Frostbolt x3 (Winter's Chill stacks) > Fire Blast finisher > Ice Lance execute
AoE: gather ( engineering/rocket-helm era tactics ) > Frost Nova > Blink out > Blizzard x2 > Cone of Cold cleanup
Survival: Cold Snap resets Nova+Block; Ice Barrier pre-pull on elites

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Slime-encrusted Pads (Shoulder, Cloth) - Mutanus the Devourer, Wailing Caverns
*Serpent Gloves (Hands, Cloth) - Lord Serpentis, Wailing Caverns
*Slither Cord (Waist, Cloth) - Lord Pythas, Wailing Caverns
*Robe of the Moccasin (Chest, Cloth) - Lord Cobrahn, Wailing Caverns
*Bridgebreaker Bindings (Wrist, Cloth) - Kam Deepfury, The Stockade
*Silk-threaded Trousers (Legs, Cloth) - Trash Drops, The Deadmines

	]],
})

ns.Codex:RegisterBuild("MAGE", "PVE", "Fire Combustion Raid", 0, 31, 20,
{
	TALENTS = {
		"Improved Fireball",
		"Ignite",
		"Flame Throwing",
		"Incinerate",
		"Pyroblast",
		"Burning Soul",
		"Improved Scorch",
		"Master of Elements",
		"Critical Mass",
		"Fire Power",
		"Combustion",
		"Arcane Subtlety",
		"Arcane Focus",
		"Clearcasting",
	},
	DESC = [[Fire PVE (Level 60 raids, Forever)
	Combustion + Ignite rolling with Hot Streak joining the tree. Ignite no longer double-dips percentage modifiers (Sept tuning), so the spec is steadier and less ignite-lottery. Scorch stacking + Critical Mass keep the raid's fire crit aura up for fellow Mages and Warlocks.
	]],
	PROS = [[
*Top Mage raid DPS with Ignite rolling + Combustion windows
*Scorch debuff + Critical Mass buff the whole raid
*Hot Streak adds instant Pyro game
	]],
	CONS = [[
*Threat-heavy; needs Salvation/Tranquil Air discipline
*Fire-immune/resist fights (Molten Core) force Frost set
	]],
	ROT = [[
Stats: Hit (cap) > Spell Power (Fire) > Crit > Haste > Intellect
Single: Scorch x5 (stack) > Fireball filler > Pyroblast on Hot Streak > Combustion with trinkets
AoE: Flamestrike > Blast Wave-equivalent tools > Arcane Explosion
Threat: stop at 80% on Omen-style meters, Ice Block clears, Invisibility-equivalent resets if talented
New raids: Hyjal Summit fire-vulnerable bosses favor this; Barrow Deeps tight spaces favor Frost
	]],
})

ns.Codex:RegisterBuild("MAGE", "PVP", "Frost Shatter Control PVP", 16, 0, 35,
{
	TALENTS = {
		"Arcane Subtlety",
		"Arcane Focus",
		"Clearcasting",
		"Improved Frostbolt",
		"Elemental Precision",
		"Ice Shards",
		"Frostbite",
		"Improved Frost Nova",
		"Permafrost",
		"Piercing Ice",
		"Cold Snap",
		"Shatter",
		"Ice Block",
	},
	DESC = [[Frost PVP (Forever battlegrounds)
	Shatter combos with Frostbite/Nova control and Cold Snap resets. Ice Lance gives the tree a real instant finisher to pair with Counterspell locks. Arcane dip buys Clearcasting + resist-piercing for the opener.
	]],
	PROS = [[
*Best control in the game (roots, slows, sheep, CS)
*Double Block + Cold Snap = unkillable in skilled hands
*Shatter burst deletes cloth in one window
	]],
	CONS = [[
*Dispel classes strip the combo pieces
*Mana battles vs Priests/Warlocks go long
	]],
	ROT = [[
Opener: Polymorph healer > Frostbolt x2 > Nova > Shatter combo > Ice Lance > Counterspell the rescue
Vs melee: kite with Rank-1 Frostbolt slow, Nova-Blink separation, Block the burst
Vs casters: CS on heal casts, Spellsteal-equivalent pressure if available, LOS jukes
Race: Gnome Escape Artist, Human new options, Orc Mage NEW (stun resist), Forsaken WotA answers fears
	]],
})
