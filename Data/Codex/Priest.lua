-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Priest talent builds for WoW Forever.

ns.Codex:RegisterBuild("PRIEST", "Leveling", "Shadow Leveling", 0, 5, 46,
{
	TALENTS = {
		"Spirit Tap",
		"Improved Shadow Word: Pain",
		"Shadow Focus",
		"Improved Mind Blast",
		"Mind Flay",
		"Shadow Weaving",
		"Vampiric Embrace",
		"Darkness",
		"Shadowform",
		"Wand Specialization",
	},
	DESC = [[Shadow Leveling (10-60, Forever)
	Spirit Tap + wand is still the engine: dot, Mind Flay, wand between casts, full mana after every kill. Shadowform at 40 doubles down. Devouring Plague (trained, all Priests) adds a Shadow nuke every minute. Fear Ward is baseline now - Undead and Dwarf both have answers.
	]],
	PROS = [[
*Spirit Tap = infinite mana chain-pulling
*Bubble + Fear + Psychic Scream = best escape kit
*Heals dungeons as Shadow while leveling
	]],
	CONS = [[
*Shadowform locks Holy spells; swap for healing dungeons
*Wand upgrades gate your damage more than talents
	]],
	ROT = [[
Stats: Spirit (Tap scaling) > Intellect > Spell Power > Stamina
Single: Power Word: Shield > Shadow Word: Pain > Mind Blast > Mind Flay > SW:P refresh > wand
Multi: Psychic Scream > dot spread > Mind Flay priority target
Elite: Devouring Plague + Shadowfiend-equivalent cooldowns; Fear-juggle adds
New dungeons: Ruins of Lordaeron (15-20) - Dispel Magic duty is yours

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Slime-encrusted Pads (Shoulder, Cloth) - Mutanus the Devourer, Wailing Caverns
*Serpent Gloves (Hands, Cloth) - Lord Serpentis, Wailing Caverns
*Slither Cord (Waist, Cloth) - Lord Pythas, Wailing Caverns
*Robe of the Moccasin (Chest, Cloth) - Lord Cobrahn, Wailing Caverns
*Bridgebreaker Bindings (Wrist, Cloth) - Kam Deepfury, The Stockade
*Silk-threaded Trousers (Legs, Cloth) - Trash Drops, The Deadmines

	]],
})

ns.Codex:RegisterBuild("PRIEST", "PVE", "Holy Prayer of Mending Raid", 21, 30, 0,
{
	TALENTS = {
		"Unbreakable Will",
		"Wand Specialization",
		"Silent Resolve",
		"Improved Power Word: Shield",
		"Martyrdom",
		"Inner Focus",
		"Meditation",
		"Penance",
		"Divine Aegis",
		"Healing Focus",
		"Improved Renew",
		"Holy Specialization",
		"Divine Fury",
		"Prayer of Mending",
		"Spiritual Healing",
	},
	DESC = [[Holy/Discipline PVE (Level 60 raids, Forever)
	Party-healing plan around Holy Shock-style tools and Prayer of Mending capstone, backed by Penance + Divine Aegis absorbs from Discipline. Divine Spirit is baseline - your points buy throughput, not the buff. Fear Ward baseline frees the old Dwarf-only slot for throughput picks.
	]],
	PROS = [[
*Prayer of Mending = best party-wide smart heal
*Penance + shields = tank-spike answers
*Stamina/Spirit buffs + Fear Ward = raid utility
	]],
	CONS = [[
*Mana-hungry; Meditation + Spirit gearing mandatory
*No combat rez; deaths stick
	]],
	ROT = [[
Stats: Spirit (Meditation regen) > Healing/Spell Power > Intellect > mp5 > Crit
Tank: Power Word: Shield (Weakened Soul watch) > Penance > Greater Heal ranks
Raid: Prayer of Mending on cooldown, Renew on movers, Prayer of Healing for AoE
Buffs: Fortitude + Spirit on everyone; Fear Ward pre-placed on Onyxia-style fears
Camp: Tailoring Faction Banner (Spirit) does NOT stack with Divine Spirit - coordinate
	]],
})

ns.Codex:RegisterBuild("PRIEST", "PVP", "Discipline Survival PVP", 31, 20, 0,
{
	TALENTS = {
		"Unbreakable Will",
		"Wand Specialization",
		"Silent Resolve",
		"Improved Power Word: Shield",
		"Martyrdom",
		"Inner Focus",
		"Meditation",
		"Penance",
		"Divine Aegis",
		"Healing Focus",
		"Improved Renew",
		"Spell Warding",
	},
	DESC = [[Discipline PVP (Forever battlegrounds)
	Shield + Penance + Inner Focus throughput with Silence resistance (Silent Resolve) and pushback armor (Martyrdom). Mana Burn wars decide mirror matches; Devouring Plague gives every Priest a Shadow kill-button, not just Undead.
	]],
	PROS = [[
*Hardest healer to kill (bubble + Penance self-heal + Inner Focus)
*Mana Burn breaks enemy healers
*Fear Ward baseline answers fear chains
	]],
	CONS = [[
*Offensive dispel pressure drains mana fast
*Needs peels vs double-melee trains
	]],
	ROT = [[
Survival: pre-shield > Penance self > Psychic Scream > Fear Ward pre-fear
Offense: Mana Burn enemy healer, Devouring Plague + SW:P + Mind Blast burst
Support: dispel teammates, Power Infusion-equivalent windows on your DPS
Race: Dwarf (Fear Ward history + Stoneform), Human (new options), Forsaken Devouring Plague synergy + WotF (toned down)
	]],
})
