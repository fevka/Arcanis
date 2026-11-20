local _, A = ...
local ns = A.RF
if not ns then return end
-- Uretilmis build listesi. Son calisma: 2026-11-10T19:07:25.293Z
ns.autoBuilds = {
    HUNTER = {
        { key = "auto_bm", name = "Beast Mastery", spec = 1, updated = "2026-11-10",
          steps = { { "Deadly Aspects", 5 }, { "Focused Fire", 2 }, { "Improved Revive Pet", 2 }, { "Endurance Training", 1 }, { "Pathfinding", 2 }, { "Unleashed Fury", 3 }, { "Summon Hawk", 1 }, { "Bestial Swiftness", 1 }, { "Unleashed Fury", 4 }, { "Ferocity", 2 }, { "Intimidation", 1 }, { "Bestial Discipline", 2 }, { "Ferocity", 5 }, { "Frenzy", 4 }, { "Bestial Wrath", 1 }, { "Lethal Attacks", 5 }, { "Careful Aim", 5 }, { "Rapid Killing", 2 }, { "Efficiency", 3 }, { "Trueshot Aura", 1 }, { "Mortal Shots", 4 } } },
        { key = "auto_mm", name = "Marksmanship", spec = 2, updated = "2026-11-10",
          steps = { { "Deadly Aspects", 5 }, { "Endurance Training", 3 }, { "Lethal Attacks", 5 }, { "Improved Tracking", 5 }, { "Focused Fire", 2 }, { "Efficiency", 5 }, { "Careful Aim", 5 }, { "Unleashed Fury", 5 }, { "Rapid Killing", 2 }, { "Trueshot Aura", 1 }, { "Mortal Shots", 5 }, { "Rapid Recuperation", 2 }, { "Barrage", 1 }, { "Ranged Weapon Specialization", 5 } } },
        { key = "auto_sv", name = "Survival", spec = 3, updated = "2026-11-10",
          steps = { { "Deadly Aspects", 5 }, { "Lethal Attacks", 5 }, { "Improved Tracking", 5 }, { "Careful Aim", 5 }, { "Savage Strikes", 2 }, { "Survivalist", 3 }, { "Rapid Killing", 2 }, { "Lone Wolf", 1 }, { "Clever Traps", 2 }, { "Surefooted", 3 }, { "Predator's Edge", 5 }, { "Resourcefulness", 2 }, { "Expose Prey", 2 }, { "Survivalist's Discipline", 2 }, { "Strider Kick", 1 }, { "Lightning Reflexes", 5 }, { "Lacerating Strikes", 1 } } },
    },
    ROGUE = {
        { key = "auto_assassination", name = "Assassination", spec = 1, updated = "2026-11-10",
          steps = { { "Remorseless Attacks", 2 }, { "Efficient Strikes", 2 }, { "Coup de Grace", 3 }, { "Puncturing Wounds", 3 }, { "Precision", 3 }, { "Malice", 3 }, { "Improved Slice and Dice", 3 }, { "Ruthlessness", 2 }, { "Malice", 5 }, { "Lethality", 2 }, { "Ruthlessness", 3 }, { "Cold Blood", 1 }, { "Endurance", 2 }, { "Deflection", 2 }, { "Flawless Execution", 1 }, { "Improved Poisons", 4 }, { "Venom", 1 }, { "Relentless Strikes", 5 }, { "Seal Fate", 3 }, { "Improved Poisons", 5 }, { "Mutilate", 1 }, { "Opportunity", 4 } } },
        { key = "auto_combat", name = "Combat", spec = 2, updated = "2026-11-10",
          steps = { { "Remorseless Attacks", 2 }, { "Efficient Strikes", 2 }, { "Coup de Grace", 3 }, { "Deflection", 3 }, { "Precision", 2 }, { "Riposte", 1 }, { "Precision", 3 }, { "Endurance", 2 }, { "Lightning Reflexes", 1 }, { "Flawless Execution", 1 }, { "Aggression", 3 }, { "Weapon Expertise", 1 }, { "Blade Flurry", 1 }, { "Weapon Expertise", 2 }, { "Dual Wield Specialization", 2 }, { "Hack and Slash", 5 }, { "Flash of Steel", 1 }, { "Adrenaline Rush", 1 }, { "Malice", 3 }, { "Improved Slice and Dice", 3 }, { "Ruthlessness", 2 }, { "Malice", 5 }, { "Lethality", 2 }, { "Ruthlessness", 3 }, { "Cold Blood", 1 }, { "Flash of Steel", 5 } } },
        { key = "auto_subtlety", name = "Subtlety", spec = 3, updated = "2026-11-10",
          steps = { { "Remorseless Attacks", 2 }, { "Efficient Strikes", 2 }, { "Opportunity", 5 }, { "Improved Ambush", 3 }, { "Camouflage", 2 }, { "Initiative", 3 }, { "Premeditation", 1 }, { "Serrated Blades", 1 }, { "Ghostly Strike", 1 }, { "Serrated Blades", 3 }, { "Elusiveness", 2 }, { "Hemorrhage", 1 }, { "Coup de Grace", 3 }, { "Precision", 3 }, { "Deflection", 3 }, { "Riposte", 1 }, { "Composure", 2 }, { "Endurance", 1 }, { "Flawless Execution", 1 }, { "Weapon Expertise", 2 }, { "Aggression", 2 }, { "Blade Flurry", 1 }, { "Malice", 5 }, { "Ruthlessness", 2 } } },
    },
    WARRIOR = {
        { key = "auto_arms", name = "Arms", spec = 1, updated = "2026-11-10",
          steps = { { "Improved Rend", 3 }, { "Deflection", 2 }, { "Improved Overpower", 2 }, { "Improved Tactical Mastery", 3 }, { "Anger Management", 1 }, { "Deep Wounds", 3 }, { "Improved Charge", 1 }, { "Two-Handed Weapon Specialization", 3 }, { "Spearing Strike", 1 }, { "Improved Charge", 2 }, { "Sweeping Strikes", 1 }, { "Bloodthrill", 2 }, { "Weaponmaster", 2 }, { "Improved Slam", 2 }, { "Weaponmaster", 5 }, { "Mortal Strike", 1 }, { "Cruelty", 5 }, { "Lingering Rage", 5 }, { "Enrage", 5 }, { "Deflection", 5 }, { "Improved Bloodrage", 2 } } },
        { key = "auto_fury", name = "Fury", spec = 2, updated = "2026-11-10",
          steps = { { "Improved Heroic Strike", 3 }, { "Improved Rend", 3 }, { "Cruelty", 5 }, { "Improved Bloodrage", 2 }, { "Improved Charge", 2 }, { "Improved Tactical Mastery", 3 }, { "Unbridled Wrath", 5 }, { "Anger Management", 1 }, { "Deep Wounds", 3 }, { "Furious Precision", 3 }, { "Enrage", 2 }, { "Impale", 2 }, { "Dual Wield Specialization", 5 }, { "Reckless Swings", 1 }, { "Improved Execute", 2 }, { "Improved Berserker Rage", 2 }, { "Death Wish", 1 }, { "Improved Whirlwind", 2 }, { "Flurry", 3 }, { "Bloodthirst", 1 } } },
        { key = "auto_prot", name = "Protection", spec = 3, updated = "2026-11-10",
          steps = { { "Shield Specialization", 5 }, { "Improved Revenge", 3 }, { "Improved Thunder Clap", 2 }, { "Master of Defense", 2 }, { "Last Stand", 1 }, { "Improved Thunder Clap", 3 }, { "Improved Bloodrage", 1 }, { "Vanguard", 1 }, { "Improved Bloodrage", 2 }, { "Anticipation", 3 }, { "Concussion Blow", 1 }, { "Focused Rage", 3 }, { "Anticipation", 4 }, { "Bastion", 5 }, { "Shield Slam", 1 }, { "Cruelty", 5 }, { "Unbridled Wrath", 5 }, { "Enrage", 5 }, { "Deflection", 5 } } },
    },
}
