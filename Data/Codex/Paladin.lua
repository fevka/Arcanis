-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Paladin talent builds for WoW Forever.

ns.Codex:RegisterBuild("PALADIN", "Leveling", "Retribution Leveling", 0, 0, 31,
{
	TALENTS = {
		"Improved Blessing of Might",
		"Benediction",
		"Improved Judgement",
		"Conviction",
		"Seal of Command",
		"Pursuit of Justice",
		"Eye for an Eye",
		"Sanctity Aura",
		"Two-Handed Weapon Specialization",
		"Vengeance",
		"Twist of Light",
		"Divine Strength",
		"Divine Intellect",
	},
	DESC = [[Retribution Leveling (10-60, Forever)
	Forever Ret actually has buttons: Holy Strike from level 6, Seal of Command, Judgement without losing your seal. Level as Ret with a slow 2H, keep Blessing of Might up, judge on cooldown. Twist of Light at 40+ turns the tree into a real DPS spec instead of an auto-attack meme.
	]],
	PROS = [[
*Holy Strike + Judgement = active rotation while leveling
*Self-healing (Holy Light, Lay on Hands) = zero downtime
*Plate + bubble = survives bad pulls and world PVP
	]],
	CONS = [[
*Mana pool still small; downrank or drink between chains
*Slow without Pursuit of Justice early
	]],
	ROT = [[
Stats: Strength > Crit > Attack Power > Stamina > Intellect
Seal: Command for leveling (twist to Fury only when tanking)
Single: Judgement > Holy Strike > Crusader Strike > auto + Seal procs
Multi: Consecration (trained, cheap now) + Retribution Aura
Survival: Divine Shield + Lay on Hands are full resets; bubble-pull dungeon quests

Class quests (do not skip while leveling):
*Tome of Valor (1651/1652) -> Test of Righteousness (1653/1654/1806) -> Verigan's Fist 6953
*Mats: Whitestone Oak Lumber (Deadmines Goblin Woodcarver), Jordan's Smithing Hammer (SFK),
 Refined Ore Shipment (1655 reward), Purified Kor Gem (1442; Corrupted Kor Gem from BFD naga)
*Horde Paladins: A Moon-Kissed Blade chain instead (95036/95042)

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Mutant Scale Breastplate (Chest, Mail) - Mutanus the Devourer, Wailing Caverns
*Savage Trodders (Feet, Mail) - Lord Serpentis, Wailing Caverns
*Cobrahn's Grasp (Waist, Mail) - Lord Cobrahn, Wailing Caverns
*Ogre Grips (Hands, Mail) - Hamhock, The Stockade
*Jimmied Handcuffs (Wrist, Mail) - Bruegal Ironknuckle, The Stockade
*Bandsaw Wristbands (Wrist, Mail) - Sneed, The Deadmines

]],
})

ns.Codex:RegisterBuild("PALADIN", "PVE", "Holy Raid Healer", 31, 20, 0,
{
	TALENTS = {
		"Divine Intellect",
		"Spiritual Focus",
		"Healing Light",
		"Illumination",
		"Improved Lay on Hands",
		"Unyielding Faith",
		"Light's Vigil",
		"Improved Blessing of Wisdom",
		"Guardian's Favor",
		"Anticipation",
		"Toughness",
	},
	DESC = [[Holy PVE (Level 60 dungeons/raids, Forever)
	Holy gains faster follow-up heals, shorter Holy Shock cooldown and targeted party healing via Light's Vigil. Illumination now refunds half (not full) mana, and Reverence adds Spirit regen while casting - so gear Spirit and plan mana like a Classic healer, not a MoP one. Kings/Consecration are already trained: your points go to throughput.
	]],
	PROS = [[
*Best single-target tank healer; Light's Vigil adds party splash
*Blessings (Might/Wisdom/Salvation) + Auras = raid utility no one replaces
*Plate + Divine Shield = survives mechanics
	]],
	CONS = [[
*Illumination nerf means downranking discipline matters
*No group-wide emergency button; positioning is everything
	]],
	ROT = [[
Stats: Intellect > Spirit (Reverence scaling) > Spell Power/Healing > Crit > mp5
Single: Holy Light (downranked) / Flash of Light filler, Holy Shock on cooldown
Party: Light's Vigil procs + targeted Holy coverage
Buffs: Wisdom on healers, Might on melee, Salvation on DPS; keep one Blessing per class
Camp: Alchemy Mana Well (mana regen) does NOT stack with Blessing of Wisdom - coordinate
Legacy: Professions tree helps long raid nights; campsite Blessing coverage
	]],
})

ns.Codex:RegisterBuild("PALADIN", "PVE", "Protection Seal of Fury Tank", 0, 31, 20,
{
	TALENTS = {
		"Improved Devotion Aura",
		"Precision",
		"Guardian's Favor",
		"Toughness",
		"Blessing of Sanctuary",
		"Anticipation",
		"Improved Righteous Fury",
		"Holy Shield",
		"Improved Blessing of Might",
		"Seal of Command",
		"Conviction",
	},
	DESC = [[Protection Tank (Level 60, Forever)
	Forever finally gives Paladin a taunt: judge while Seal of Fury is active. Holy Shield gives 20% block (4 charges, down from 30%) - watch charge consumption on multi-pulls. Consecration is trained, so threat is Consecration + Holy Shield + Judgement instead of auto-attack praying.
	]],
	PROS = [[
*Real taunt via Seal of Fury Judgement
*Best AoE threat for new dungeons (Hall of Thanes, Drowned City)
*Bubble + Lay on Hands = wipe insurance
	]],
	CONS = [[
*Mana-limited on long pulls; bring Wisdom/Judgement of Wisdom
*Holy Shield charges melt under many attackers
	]],
	ROT = [[
Stats: Stamina > Defense > Block/Block Value > Strength > Intellect
Seal: Fury (taunt value); Righteousness only for snap threat without taunt need
Single: Judgement > Holy Shield > Consecration > Holy Strike/Seal refresh
Multi: Consecrate, Holy Shield upkeep, tab-Judgement; Blessing of Sanctuary on self
New dungeons: Krol'dok (40-45) and Alcaz Prison (48-53) hit hard - pre-shield every pull
	]],
})

ns.Codex:RegisterBuild("PALADIN", "PVP", "Retribution Burst PVP", 11, 0, 40,
{
	TALENTS = {
		"Divine Strength",
		"Divine Intellect",
		"Spiritual Focus",
		"Healing Light",
		"Improved Blessing of Might",
		"Benediction",
		"Improved Judgement",
		"Conviction",
		"Seal of Command",
		"Pursuit of Justice",
		"Eye for an Eye",
		"Sanctity Aura",
		"Vengeance",
		"Twist of Light",
	},
	DESC = [[Retribution PVP (Forever battlegrounds)
	Vengeance now stacks to 5 over 30 seconds from non-periodic crits - sustained combat builds it, and the long duration carries stacks between targets. Seal-twisting is a designed mechanic in Forever: twist Command/Fury/Righteousness to the matchup. Burst window is Hammer of Wrath execute + twisted Judgements.
	]],
	PROS = [[
*Huge execute burst with Vengeance stacked
*Blessing of Freedom + Protection swing fights
*Bubble counters enemy cooldowns
	]],
	CONS = [[
*Kited without Freedom; purge classes hurt
*Vengeance falls off if you can't stay in combat
	]],
	ROT = [[
Seals: twist Command (damage) / Justice (slow) / Fury (durability)
Burst: build 5 Vengeance > Hammer of Wrath range > Judgement + Holy Strike
Support: Freedom your carrier, Protection your healer, Cleanse slows/poisons
Race note: Human (new Hunter synergy irrelevant - take perception value), Dwarf Stoneform, Forsaken WotF (toned down but still answers fear)
	]],
})
