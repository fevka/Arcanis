-- Arcanis class codex data (generated). Do not edit by hand.
local _, ns = ...

-- Warlock talent builds for WoW Forever.

ns.Codex:RegisterBuild("WARLOCK", "Leveling", "Affliction Drain Leveling", 31, 20, 0,
{
	TALENTS = {
		"Suppression",
		"Improved Corruption",
		"Improved Life Tap",
		"Fel Concentration",
		"Nightfall",
		"Grim Reach",
		"Siphon Life",
		"Shadow Mastery",
		"Dark Pact",
		"Improved Imp",
		"Demonic Embrace",
	},
	DESC = [[Affliction Leveling (10-60, Forever)
	Drain-tank forever: Corruption + Siphon Life + Drain Life with Fel Concentration pushback armor, Nightfall instant Shadow Bolts, Dark Pact converting pet mana. Voidwalker tanks, you drain. One Bane per target rule barely matters solo - keep Bane of Agony up and go.
	]],
	PROS = [[
*Near-zero downtime (Drain Life + Siphon + Dark Pact)
*Voidwalker = personal tank for elites
*Fear + Howl + Banish handle adds and runners
	]],
	CONS = [[
*Shard management (Drain Soul for shards)
*Slow mount-era travel between dots; Ghost Wolf envy
	]],
	ROT = [[
Stats: Intellect > Spell Power (Shadow) > Stamina > Spirit > Haste
Single: Bane of Agony > Corruption > Siphon Life > Drain Life to full > Drain Soul execute (shard)
Multi: Howl of Terror > dot spread > Fear-juggle, Healthstone pre-made
Pet: Voidwalker (solo), Imp out-of-danger, Sayaad Seduction for humanoid control

Dungeon loot watch (Forever dungeons, /arcanis journal):
*Slime-encrusted Pads (Shoulder, Cloth) - Mutanus the Devourer, Wailing Caverns
*Serpent Gloves (Hands, Cloth) - Lord Serpentis, Wailing Caverns
*Slither Cord (Waist, Cloth) - Lord Pythas, Wailing Caverns
*Robe of the Moccasin (Chest, Cloth) - Lord Cobrahn, Wailing Caverns
*Bridgebreaker Bindings (Wrist, Cloth) - Kam Deepfury, The Stockade
*Silk-threaded Trousers (Legs, Cloth) - Trash Drops, The Deadmines

	]],
})

ns.Codex:RegisterBuild("WARLOCK", "PVE", "Destruction Shadowflame Raid", 7, 7, 37,
{
	TALENTS = {
		"Cataclysm",
		"Bane",
		"Aftermath",
		"Devastation",
		"Destructive Reach",
		"Intensity",
		"Ruin",
		"Emberstorm",
		"Conflagrate",
		"Suppression",
		"Improved Corruption",
		"Fel Intellect",
	},
	DESC = [[Destruction PVE (Level 60 raids, Forever)
	Shadow and Flame cross-pollinate: Conflagrate strengthens Shadow damage, Shadowburn strengthens Fire, with chances to preserve Immolate or refund a Soul Shard. Play both schools instead of one. Bane of Havoc is single-target now - coordinate which Warlock covers which priority add.
	]],
	PROS = [[
*Huge burst windows with Conflagrate/Shadowburn cross-school procs
*Curse of Elements/Shadow + Banes = raid debuff core
*Soulstone + Healthstones + summon = raid utility
	]],
	CONS = [[
*One Bane per target per Warlock - no stacking cheese
*Threat spikes; Salvation + Soulshatter-equivalent discipline
	]],
	ROT = [[
Stats: Hit (cap) > Spell Power (Fire/Shadow) > Crit > Haste > Intellect
Single: Curse of Elements > Immolate > Conflagrate > Incinerate/Shadow Bolt filler > Shadowburn execute
Banes: Havoc on priority add, Doom on long bosses, Elements/Weakness by assignment
Pet: Imp (Fire damage bonus, Blood Pact stamina) for raids; Felhunter for magic-heavy fights
	]],
})

ns.Codex:RegisterBuild("WARLOCK", "PVE", "Demonology Felguard Raid", 0, 31, 20,
{
	TALENTS = {
		"Improved Healthstone",
		"Improved Imp",
		"Demonic Embrace",
		"Fel Intellect",
		"Fel Domination",
		"Demonic Sacrifice",
		"Master Summoner",
		"Master Demonologist",
		"Soul Link",
		"Cataclysm",
		"Bane",
	},
	DESC = [[Demonology PVE (Level 60 raids, Forever)
	Pet-choice bonuses are redesigned: Imp = Fire damage, Sayaad = Shadow damage, Felhunter = magic reduction. Match the pet to the encounter and your tree. Soul Link + Demonic Sacrifice lines keep the Lock alive while the pet works.
	]],
	PROS = [[
*Tankiest caster (Soul Link + high stamina + pet peel)
*Pet bonuses tunable per fight
*Still brings full curse/Bane coverage
	]],
	CONS = [[
*Pet AI on movement fights
*Below Affliction/Destruction on pure patchwerk-style parses
	]],
	ROT = [[
Pet by fight: Imp (fire-weak bosses), Sayaad (shadow-weak), Felhunter (magic damage), Voidwalker (adds)
Single: dots > Shadow Bolt filler > pet attack macros; Demonic Sacrifice when pet must be sacked
Cooldowns: Fel Domination instant summons, Soulstone the healer pre-pull
	]],
})

ns.Codex:RegisterBuild("WARLOCK", "PVP", "Affliction Nightfall PVP", 33, 18, 0,
{
	TALENTS = {
		"Suppression",
		"Improved Corruption",
		"Improved Life Tap",
		"Fel Concentration",
		"Nightfall",
		"Grim Reach",
		"Siphon Life",
		"Curse of Exhaustion",
		"Shadow Mastery",
		"Improved Howl of Terror",
		"Unstable Affliction",
		"Improved Imp",
		"Demonic Embrace",
	},
	DESC = [[Affliction PVP (Forever battlegrounds)
	Exhaustion kiting + Unstable Affliction dispel-punish + Nightfall instant Bolts. Sayaad Seduction chains, Fear/Howl control, Death Coil clutch. One-Bane rule means pick Havoc/Exhaustion/Elements by matchup, not by habit.
	]],
	PROS = [[
*Best spread pressure (dots on everyone)
*Unstable Affliction punishes dispellers
*Fear chains + Seduction win 1vX
	]],
	CONS = [[
*Needs time; burst classes can run you over in the opener
*WotF (toned down), Tremor, and dispels answer fears
	]],
	ROT = [[
Spread: Agony + Corruption on all targets > Exhaustion on kill target > Nightfall procs
Control: Fear healer > Seduction DPS > Howl on peel trains > Death Coil low targets
Survival: Healthstone + Drain Life + Soul Link pet, portal/gateway-equivalent positioning
Race: Forsaken (Devouring Plague synergy + WotF), Orc stun resist, Human new options
	]],
})
