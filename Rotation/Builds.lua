local _, A = ...
local ns = A.RF
if not ns then return end

-- Addon ile gelen sirali leveling build'leri (10-60, 51 puan). Her adim: { "Talent", hedefRank }
-- (yorum: adimin bittigi level). spec: talent bolumu (1..3), otomatik secimde kullanilir.
-- (istemci 1.60.1.70755, 3 Kasim 2026 hotfix'i dahil). Talent adlari Ingilizce istemci.
-- Oyunda kendi build'ini eklemek icin: /wf rotation import.

ns.builds = ns.builds or {}

ns.builds.WARRIOR = {
    { key = "arms", name = "Arms (leveling)", spec = 1,
      steps = {
        { "Improved Heroic Strike", 1 },            -- L10
        { "Deflection", 3 },                        -- L13
        { "Improved Rend", 3 },                     -- L16
        { "Improved Charge", 2 },                   -- L18
        { "Improved Tactical Mastery", 3 },         -- L21
        { "Anger Management", 1 },                  -- L22
        { "Deep Wounds", 3 },                       -- L25
        { "Two-Handed Weapon Specialization", 3 },  -- L28
        { "Improved Overpower", 2 },                -- L30
        { "Bloodthrill", 2 },                       -- L32
        { "Sweeping Strikes", 1 },                  -- L33
        { "Impale", 2 },                            -- L35
        { "Weaponmaster", 4 },                      -- L39
        { "Mortal Strike", 1 },                     -- L40
        { "Weaponmaster", 5 },                      -- L41
        { "Improved Slam", 2 },                     -- L43
        { "Cruelty", 5 },                           -- L48
        { "Unbridled Wrath", 5 },                   -- L53
        { "Improved Bloodrage", 2 },                -- L55
        { "Iron Will", 5 },                         -- L60
      } },
    { key = "fury", name = "Fury (leveling)", spec = 2,
      steps = {
        { "Cruelty", 5 },                           -- L14
        { "Lingering Rage", 1 },                    -- L15
        { "Unbridled Wrath", 5 },                   -- L20
        { "Furious Precision", 3 },                 -- L23
        { "Piercing Howl", 1 },                     -- L24
        { "Enrage", 2 },                            -- L26
        { "Dual Wield Specialization", 3 },         -- L29
        { "Death Wish", 1 },                        -- L30
        { "Dual Wield Specialization", 5 },         -- L32
        { "Reckless Swings", 1 },                   -- L33
        { "Improved Execute", 2 },                  -- L35
        { "Flurry", 2 },                            -- L37
        { "Improved Whirlwind", 2 },                -- L39
        { "Bloodthirst", 1 },                       -- L40
        { "Flurry", 3 },                            -- L41
        { "Improved Heroic Strike", 3 },            -- L44
        { "Improved Rend", 3 },                     -- L47
        { "Improved Charge", 2 },                   -- L49
        { "Improved Tactical Mastery", 3 },         -- L52
        { "Anger Management", 1 },                  -- L53
        { "Deep Wounds", 3 },                       -- L56
        { "Impale", 2 },                            -- L58
        { "Improved Bloodrage", 2 },                -- L60
      } },
    { key = "prot", name = "Protection (leveling)", spec = 3,
      steps = {
        { "Improved Bloodrage", 2 },                -- L11
        { "Shield Specialization", 5 },             -- L16
        { "Anticipation", 5 },                      -- L21
        { "Improved Revenge", 3 },                  -- L24
        { "Master of Defense", 2 },                 -- L26
        { "Improved Thunder Clap", 3 },             -- L29
        { "Last Stand", 1 },                        -- L30
        { "Defiance", 3 },                          -- L33
        { "Improved Sunder Armor", 3 },             -- L36
        { "Concussion Blow", 1 },                   -- L37
        { "Focused Rage", 2 },                      -- L39
        { "Shield Slam", 1 },                       -- L40
        { "Focused Rage", 3 },                      -- L41
        { "Bastion", 5 },                           -- L46
        { "Improved Heroic Strike", 3 },            -- L49
        { "Deflection", 5 },                        -- L54
        { "Improved Rend", 3 },                     -- L57
        { "Deep Wounds", 3 },                       -- L60
      } },
}

ns.builds.HUNTER = {
    { key = "bm", name = "Beast Mastery (leveling)", spec = 1,
      steps = {
        { "Deadly Aspects", 5 },                    -- L14
        { "Focused Fire", 2 },                      -- L16
        { "Improved Revive Pet", 2 },               -- L18
        { "Endurance Training", 1 },                -- L19
        { "Pathfinding", 2 },                       -- L21
        { "Unleashed Fury", 3 },                    -- L24
        { "Summon Hawk", 1 },                       -- L25
        { "Bestial Swiftness", 1 },                 -- L26
        { "Unleashed Fury", 4 },                    -- L27
        { "Ferocity", 2 },                          -- L29
        { "Intimidation", 1 },                      -- L30
        { "Bestial Discipline", 2 },                -- L32
        { "Ferocity", 5 },                          -- L35
        { "Frenzy", 4 },                            -- L39
        { "Bestial Wrath", 1 },                     -- L40
        { "Lethal Attacks", 5 },                    -- L45
        { "Careful Aim", 5 },                       -- L50
        { "Rapid Killing", 2 },                     -- L52
        { "Efficiency", 3 },                        -- L55
        { "Mortal Shots", 5 },                      -- L60
      } },
    { key = "mm", name = "Marksmanship (leveling)", spec = 2,
      steps = {
        { "Lethal Attacks", 5 },                    -- L14
        { "Improved Stings", 1 },                   -- L15
        { "Efficiency", 5 },                        -- L20
        { "Careful Aim", 5 },                       -- L25
        { "Trueshot Aura", 1 },                     -- L26
        { "Mortal Shots", 5 },                      -- L31
        { "Barrage", 3 },                           -- L34
        { "Ranged Weapon Specialization", 5 },      -- L39
        { "Deadly Aspects", 5 },                    -- L44
        { "Focused Fire", 2 },                      -- L46
        { "Endurance Training", 3 },                -- L49
        { "Unleashed Fury", 5 },                    -- L54
        { "Ferocity", 1 },                          -- L55
        { "Improved Tracking", 5 },                 -- L60
      } },
    { key = "sv", name = "Survival (leveling)", spec = 3,
      steps = {
        { "Improved Tracking", 5 },                 -- L14
        { "Savage Strikes", 2 },                    -- L16
        { "Survivalist", 3 },                       -- L19
        { "Clever Traps", 2 },                      -- L21
        { "Surefooted", 3 },                        -- L24
        { "Predator's Edge", 4 },                   -- L28
        { "Deterrence", 1 },                        -- L29
        { "Strider Kick", 1 },                      -- L30
        { "Predator's Edge", 5 },                   -- L31
        { "Expose Prey", 2 },                       -- L33
        { "Resourcefulness", 2 },                   -- L35
        { "Lightning Reflexes", 1 },                -- L36
        { "Survivalist's Discipline", 2 },          -- L38
        { "Counterattack", 1 },                     -- L39
        { "Lacerating Strikes", 1 },                -- L40
        { "Lightning Reflexes", 5 },                -- L44
        { "Deadly Aspects", 5 },                    -- L49
        { "Lethal Attacks", 5 },                    -- L54
        { "Careful Aim", 5 },                       -- L59
        { "Lone Wolf", 1 },                         -- L60
      } },
}

ns.builds.MAGE = {
    { key = "arcane", name = "Arcane (leveling)", spec = 1,
      steps = {
        { "Wand Specialization", 1 },               -- L10
        { "Improved Channeling", 4 },               -- L14
        { "Arcane Resilience", 1 },                 -- L15
        { "Arcane Concentration", 5 },              -- L20
        { "Arcane Blast", 1 },                      -- L21
        { "Missile Barrage", 2 },                   -- L23
        { "Arcane Impact", 3 },                     -- L26
        { "Arcane Meditation", 3 },                 -- L29
        { "Arcane Geometry", 1 },                   -- L30
        { "Presence of Mind", 1 },                  -- L31
        { "Arcane Mind", 5 },                       -- L36
        { "Arcane Instability", 3 },                -- L39
        { "Arcane Power", 1 },                      -- L40
        { "Incineration", 4 },                      -- L44
        { "Improved Frostbolt", 5 },                -- L49
        { "Precision", 3 },                         -- L52
        { "Ice Shards", 5 },                        -- L57
        { "Frost Channeling", 3 },                  -- L60
      } },
    { key = "fire", name = "Fire (leveling)", spec = 2,
      steps = {
        { "Incineration", 5 },                      -- L14
        { "Accelerant", 1 },                        -- L15
        { "Ignite", 4 },                            -- L19
        { "Pyroblast", 1 },                         -- L20
        { "Ignite", 5 },                            -- L21
        { "Improved Fire Blast", 2 },               -- L23
        { "Impact", 1 },                            -- L24
        { "Improved Scorch", 3 },                   -- L27
        { "Heating Up", 1 },                        -- L28
        { "Flame Throwing", 2 },                    -- L30
        { "Master of Elements", 3 },                -- L33
        { "Critical Mass", 3 },                     -- L36
        { "Fire Power", 3 },                        -- L39
        { "Combustion", 1 },                        -- L40
        { "Improved Channeling", 5 },               -- L45
        { "Arcane Resilience", 2 },                 -- L47
        { "Wand Specialization", 2 },               -- L49
        { "Magic Absorption", 1 },                  -- L50
        { "Arcane Concentration", 5 },              -- L55
        { "Arcane Meditation", 2 },                 -- L57
        { "Precision", 3 },                         -- L60
      } },
    { key = "frost", name = "Frost (leveling)", spec = 3,
      steps = {
        { "Improved Frostbolt", 5 },                -- L14
        { "Precision", 3 },                         -- L17
        { "Frostbite", 2 },                         -- L19
        { "Ice Lance", 1 },                         -- L20
        { "Frostbite", 3 },                         -- L21
        { "Ice Shards", 3 },                        -- L24
        { "Ice Block", 1 },                         -- L25
        { "Shatter", 3 },                           -- L28
        { "Ice Shards", 4 },                        -- L29
        { "Fingers of Frost", 2 },                  -- L31
        { "Improved Cone of Cold", 2 },             -- L33
        { "Cold Snap", 1 },                         -- L34
        { "Winter's Chill", 5 },                    -- L39
        { "Ice Barrier", 1 },                       -- L40
        { "Improved Cone of Cold", 3 },             -- L41
        { "Ice Shards", 5 },                        -- L42
        { "Improved Channeling", 5 },               -- L47
        { "Arcane Concentration", 5 },              -- L52
        { "Missile Barrage", 2 },                   -- L54
        { "Arcane Subtlety", 2 },                   -- L56
        { "Arcane Blast", 1 },                      -- L57
        { "Arcane Meditation", 3 },                 -- L60
      } },
}

ns.builds.ROGUE = {
    { key = "assassination", name = "Assassination (leveling)", spec = 1,
      steps = {
        { "Remorseless Attacks", 2 },
        { "Efficient Strikes", 2 },
        { "Coup de Grace", 3 },
        { "Puncturing Wounds", 3 },
        { "Precision", 3 },
        { "Malice", 3 },
        { "Improved Slice and Dice", 3 },
        { "Ruthlessness", 2 },
        { "Malice", 5 },
        { "Lethality", 2 },
        { "Ruthlessness", 3 },
        { "Cold Blood", 1 },
        { "Endurance", 2 },
        { "Deflection", 2 },
        { "Flawless Execution", 1 },
        { "Improved Poisons", 4 },
        { "Venom", 1 },
        { "Relentless Strikes", 5 },
        { "Seal Fate", 3 },
        { "Improved Poisons", 5 },
        { "Mutilate", 1 },
        { "Opportunity", 4 },
      } },
    { key = "combat", name = "Combat (leveling)", spec = 2,
      steps = {
        { "Remorseless Attacks", 2 },
        { "Efficient Strikes", 2 },
        { "Coup de Grace", 3 },
        { "Deflection", 3 },
        { "Precision", 2 },
        { "Riposte", 1 },
        { "Precision", 3 },
        { "Endurance", 2 },
        { "Lightning Reflexes", 1 },
        { "Flawless Execution", 1 },
        { "Aggression", 3 },
        { "Weapon Expertise", 1 },
        { "Blade Flurry", 1 },
        { "Weapon Expertise", 2 },
        { "Dual Wield Specialization", 2 },
        { "Hack and Slash", 5 },
        { "Flash of Steel", 1 },
        { "Adrenaline Rush", 1 },
        { "Malice", 3 },
        { "Improved Slice and Dice", 3 },
        { "Ruthlessness", 2 },
        { "Malice", 5 },
        { "Lethality", 2 },
        { "Ruthlessness", 3 },
        { "Cold Blood", 1 },
        { "Flash of Steel", 5 },
      } },
    { key = "subtlety", name = "Subtlety (leveling)", spec = 3,
      steps = {
        { "Remorseless Attacks", 2 },
        { "Efficient Strikes", 2 },
        { "Opportunity", 5 },
        { "Improved Ambush", 3 },
        { "Camouflage", 2 },
        { "Initiative", 3 },
        { "Premeditation", 1 },
        { "Serrated Blades", 1 },
        { "Ghostly Strike", 1 },
        { "Serrated Blades", 3 },
        { "Elusiveness", 2 },
        { "Hemorrhage", 1 },
        { "Coup de Grace", 3 },
        { "Precision", 3 },
        { "Deflection", 3 },
        { "Riposte", 1 },
        { "Composure", 2 },
        { "Endurance", 1 },
        { "Flawless Execution", 1 },
        { "Weapon Expertise", 2 },
        { "Aggression", 2 },
        { "Blade Flurry", 1 },
        { "Malice", 5 },
        { "Ruthlessness", 2 },
      } },
}

ns.builds.PRIEST = {
    { key = "discipline", name = "Discipline (leveling)", spec = 1,
      steps = {
        { "Twin Disciplines", 5 },
        { "Mental Strength", 5 },
        { "Meditation", 1 },
        { "Mental Agility", 1 },
        { "Inner Focus", 1 },
        { "Improved Power Word: Shield", 1 },
        { "Mental Agility", 2 },
        { "Improved Power Word: Shield", 2 },
        { "Meditation", 2 },
        { "Mental Agility", 3 },
        { "Improved Power Word: Shield", 3 },
        { "Meditation", 3 },
        { "Penance", 1 },
        { "Twilight Focus", 2 },
        { "Soul Warding", 1 },
        { "Renewed Hope", 4 },
        { "Divine Aegis", 3 },
        { "Improved Renew", 1 },
        { "Holy Specialization", 1 },
        { "Improved Renew", 2 },
        { "Holy Specialization", 2 },
        { "Twilight Focus", 3 },
        { "Improved Renew", 3 },
        { "Holy Specialization", 5 },
        { "Divine Fury", 5 },
        { "Inspiration", 3 },
        { "Improved Healing", 3 },
      } },
    { key = "holy", name = "Holy (leveling)", spec = 2,
      steps = {
        { "Twilight Focus", 1 },
        { "Improved Renew", 1 },
        { "Holy Specialization", 1 },
        { "Twilight Focus", 2 },
        { "Improved Renew", 2 },
        { "Holy Specialization", 2 },
        { "Twilight Focus", 3 },
        { "Improved Renew", 3 },
        { "Holy Specialization", 5 },
        { "Divine Fury", 5 },
        { "Inspiration", 3 },
        { "Improved Healing", 2 },
        { "Holy Binding", 1 },
        { "Improved Healing", 3 },
        { "Litany of Light", 1 },
        { "Spirit of Redemption", 1 },
        { "Spiritual Guidance", 1 },
        { "Litany of Light", 2 },
        { "Spiritual Healing", 3 },
        { "Prayer of Mending", 1 },
        { "Twin Disciplines", 5 },
        { "Mental Strength", 2 },
        { "Spiritual Guidance", 4 },
        { "Mental Strength", 5 },
        { "Mental Agility", 1 },
        { "Inner Focus", 1 },
        { "Meditation", 1 },
        { "Mental Agility", 2 },
        { "Meditation", 2 },
        { "Mental Agility", 3 },
        { "Meditation", 3 },
      } },
    { key = "shadow", name = "Shadow (leveling)", spec = 3,
      steps = {
        { "Shadow Focus", 5 },
        { "Improved Shadow Word: Pain", 2 },
        { "Improved Mind Blast", 4 },
        { "Mind Flay", 1 },
        { "Improved Mind Flay", 2 },
        { "Spirit Tap", 1 },
        { "Shadow Weaving", 3 },
        { "Vampiric Embrace", 1 },
        { "Spirit Tap", 2 },
        { "Devouring Contagion", 2 },
        { "Spirit Tap", 5 },
        { "Darkness", 5 },
        { "Shadowform", 1 },
        { "Twin Disciplines", 5 },
        { "Early Demise", 2 },
        { "Martyrdom", 2 },
        { "Mental Strength", 3 },
        { "Inner Focus", 1 },
        { "Meditation", 3 },
        { "Mental Strength", 5 },
        { "Shadow Reach", 2 },
      } },
}

ns.builds.DRUID = {
    { key = "balance", name = "Balance (leveling)", spec = 1,
      steps = {
        { "Improved Wrath", 2 },
        { "Genesis", 5 },
        { "Moonglow", 3 },
        { "Nature's Reach", 2 },
        { "Nature's Majesty", 2 },
        { "Nature's Splendor", 1 },
        { "Insect Swarm", 1 },
        { "Nature's Focus", 5 },
        { "Reflection", 3 },
        { "Improved Moonfire", 2 },
        { "Vengeance", 5 },
        { "Improved Starfire", 5 },
        { "Eclipse", 3 },
        { "Nature's Grace", 1 },
        { "Moonkin Form", 1 },
        { "Moonfury", 5 },
        { "Naturalist", 5 },
      } },
    { key = "feral", name = "Feral (leveling)", spec = 2,
      steps = {
        { "Ferocity", 5 },
        { "Furor", 3 },
        { "Feral Swiftness", 2 },
        { "Savage Fury", 2 },
        { "Feral Charge", 1 },
        { "Sharpened Claws", 2 },
        { "Shredding Attacks", 3 },
        { "Predatory Strikes", 2 },
        { "Leader of the Pack", 1 },
        { "Predatory Strikes", 3 },
        { "Natural Instinct", 2 },
        { "Blood Frenzy", 2 },
        { "Rend and Tear", 3 },
        { "Predatory Discipline", 1 },
        { "Shifting Power", 1 },
        { "Primal Bite", 1 },
        { "Rend and Tear", 5 },
        { "Lacerate", 1 },
        { "Heart of the Wild", 5 },
        { "Furor", 5 },
        { "Genesis", 5 },
        { "Nature's Majesty", 2 },
        { "Nature's Reach", 2 },
      } },
    { key = "restoration", name = "Restoration (leveling)", spec = 3,
      steps = {
        { "Nature's Focus", 1 },
        { "Heart of the Wild", 1 },
        { "Nature's Focus", 2 },
        { "Heart of the Wild", 5 },
        { "Reflection", 3 },
        { "Bloom", 1 },
        { "Nature's Focus", 5 },
        { "Naturalist", 5 },
        { "Gift of Nature", 1 },
        { "Nature's Swiftness", 1 },
        { "Gift of Nature", 5 },
        { "Tranquil Spirit", 1 },
        { "Improved Rejuvenation", 1 },
        { "Tranquil Spirit", 5 },
        { "Genesis", 1 },
        { "Swiftmend", 1 },
        { "Improved Rejuvenation", 3 },
        { "Living Spirit", 1 },
        { "Improved Tranquility", 1 },
        { "Living Spirit", 2 },
        { "Improved Tranquility", 2 },
        { "Living Spirit", 3 },
        { "Improved Regrowth", 1 },
        { "Genesis", 5 },
        { "Moonglow", 1 },
        { "Nature's Majesty", 1 },
        { "Moonglow", 2 },
        { "Nature's Majesty", 2 },
        { "Moonglow", 3 },
        { "Nature's Splendor", 1 },
      } },
}

ns.builds.PALADIN = {
    { key = "holy", name = "Holy (leveling)", spec = 1,
      steps = {
        { "Spiritual Focus", 5 },
        { "Healing Light", 1 },
        { "Reverence", 1 },
        { "Healing Light", 2 },
        { "Reverence", 2 },
        { "Healing Light", 3 },
        { "Illumination", 1 },
        { "Purifying Power", 2 },
        { "Divine Favor", 1 },
        { "Illumination", 5 },
        { "Infusion of Light", 1 },
        { "Oath of Light", 1 },
        { "Infusion of Light", 2 },
        { "Divine Precision", 1 },
        { "Holy Shock", 1 },
        { "Boundless Light", 2 },
        { "Holy Power", 5 },
        { "Light's Vigil", 1 },
        { "Divine Intellect", 5 },
        { "Precision", 1 },
        { "Guardian's Favor", 1 },
        { "Precision", 2 },
        { "Guardian's Favor", 2 },
        { "Precision", 3 },
        { "Benediction", 5 },
        { "Conviction", 1 },
        { "Sacred Duty", 1 },
        { "Conviction", 2 },
        { "Sacred Duty", 2 },
        { "Conviction", 3 },
      } },
    { key = "protection", name = "Protection (leveling)", spec = 2,
      steps = {
        { "Divine Intellect", 1 },
        { "Redoubt", 5 },
        { "Precision", 1 },
        { "Sacred Duty", 1 },
        { "Precision", 3 },
        { "Templar's Bulwark", 1 },
        { "Sacred Duty", 2 },
        { "Shield Specialization", 1 },
        { "Toughness", 1 },
        { "Shield Specialization", 2 },
        { "Toughness", 5 },
        { "Swift Judgement", 1 },
        { "Holy Shield", 1 },
        { "Improved Righteous Fury", 1 },
        { "Anticipation", 1 },
        { "Improved Righteous Fury", 2 },
        { "Anticipation", 2 },
        { "Improved Righteous Fury", 3 },
        { "Anticipation", 5 },
        { "Iron Creed", 1 },
        { "Shieldsworn", 1 },
        { "Divine Strength", 5 },
        { "Improved Seals", 3 },
        { "Iron Creed", 3 },
        { "Deflection", 5 },
        { "Conviction", 3 },
        { "Improved Seals", 5 },
      } },
    { key = "retribution", name = "Retribution (leveling)", spec = 3,
      steps = {
        { "Benediction", 5 },
        { "Improved Judgement", 1 },
        { "Conviction", 1 },
        { "Sanctified Judgement", 1 },
        { "Improved Judgement", 2 },
        { "Conviction", 3 },
        { "Sanctified Judgement", 3 },
        { "Vindication", 1 },
        { "Seal of Command", 1 },
        { "Vindication", 3 },
        { "Sacred Arbiter", 1 },
        { "Two-Handed Weapon Specialization", 3 },
        { "Divine Strength", 1 },
        { "Repentance", 1 },
        { "Vengeance", 3 },
        { "Champion of the Light", 5 },
        { "Divine Strength", 5 },
        { "Reverence", 1 },
        { "Improved Seals", 1 },
        { "Reverence", 2 },
        { "Improved Seals", 4 },
        { "Divine Intellect", 5 },
        { "Precision", 2 },
        { "Improved Seals", 5 },
        { "Holy Conduit", 2 },
      } },
}

ns.builds.SHAMAN = {
    { key = "elemental", name = "Elemental (leveling)", spec = 1,
      steps = {
        { "Convection", 1 },
        { "Concussion", 1 },
        { "Convection", 2 },
        { "Concussion", 2 },
        { "Convection", 3 },
        { "Concussion", 3 },
        { "Convection", 4 },
        { "Concussion", 4 },
        { "Convection", 5 },
        { "Concussion", 5 },
        { "Elemental Devastation", 1 },
        { "Elemental Alacrity", 1 },
        { "Call of Flame", 1 },
        { "Elemental Alacrity", 2 },
        { "Call of Flame", 2 },
        { "Elemental Alacrity", 3 },
        { "Call of Flame", 3 },
        { "Elemental Focus", 1 },
        { "Elemental Warding", 3 },
        { "Call of Thunder", 1 },
        { "Lightning Overload", 3 },
        { "Elemental Fury", 5 },
        { "Lightning Mastery", 1 },
        { "Thundering Strikes", 1 },
        { "Tidal Focus", 1 },
        { "Thundering Strikes", 2 },
        { "Tidal Focus", 2 },
        { "Thundering Strikes", 3 },
        { "Tidal Focus", 3 },
        { "Thundering Strikes", 4 },
        { "Tidal Focus", 4 },
        { "Thundering Strikes", 5 },
        { "Tidal Focus", 5 },
        { "Mindfulness", 1 },
        { "Totemic Focus", 1 },
        { "Improved Reincarnation", 1 },
        { "Mindfulness", 2 },
        { "Totemic Focus", 2 },
        { "Improved Reincarnation", 2 },
        { "Mindfulness", 3 },
        { "Totemic Focus", 5 },
      } },
    { key = "enhancement", name = "Enhancement (leveling)", spec = 2,
      steps = {
        { "Thundering Strikes", 5 },
        { "Mental Dexterity", 3 },
        { "Ancestral Knowledge", 2 },
        { "Shamanistic Focus", 1 },
        { "Elemental Weapons", 3 },
        { "Ancestral Knowledge", 3 },
        { "Stormstrike", 1 },
        { "Improved Ghost Wolf", 2 },
        { "Flurry", 2 },
        { "Improved Stormstrike", 2 },
        { "Mental Quickness", 2 },
        { "Flurry", 3 },
        { "Maelstrom Weapon", 5 },
        { "Rage of the Farseer", 1 },
        { "Flurry", 5 },
        { "Spirit Weapons", 1 },
        { "Concussion", 5 },
        { "Elemental Devastation", 3 },
        { "Convection", 2 },
        { "Elemental Focus", 1 },
        { "Convection", 5 },
        { "Reverberation", 1 },
        { "Earthbound", 1 },
        { "Trial by Fire", 1 },
      } },
    { key = "restoration", name = "Restoration (leveling)", spec = 3,
      steps = {
        { "Improved Healing Wave", 1 },
        { "Tidal Focus", 1 },
        { "Improved Healing Wave", 2 },
        { "Tidal Focus", 2 },
        { "Improved Healing Wave", 3 },
        { "Tidal Focus", 3 },
        { "Improved Healing Wave", 5 },
        { "Mindfulness", 2 },
        { "Water Shield", 1 },
        { "Tidal Focus", 5 },
        { "Mindfulness", 3 },
        { "Ancestral Healing", 1 },
        { "Healing Focus", 1 },
        { "Ancestral Healing", 2 },
        { "Healing Focus", 2 },
        { "Ancestral Healing", 3 },
        { "Healing Focus", 3 },
        { "Mana Tide Totem", 1 },
        { "Tidal Mastery", 1 },
        { "Restorative Totems", 1 },
        { "Tidal Mastery", 2 },
        { "Restorative Totems", 2 },
        { "Tidal Mastery", 3 },
        { "Restorative Totems", 3 },
        { "Tidal Mastery", 4 },
        { "Restorative Totems", 4 },
        { "Tidal Mastery", 5 },
        { "Restorative Totems", 5 },
        { "Healing Way", 1 },
        { "Nature's Swiftness", 1 },
        { "Healing Way", 3 },
        { "Purification", 5 },
        { "Riptide", 1 },
        { "Thundering Strikes", 1 },
        { "Ancestral Knowledge", 1 },
        { "Thundering Strikes", 2 },
        { "Ancestral Knowledge", 2 },
        { "Thundering Strikes", 3 },
        { "Ancestral Knowledge", 3 },
        { "Thundering Strikes", 4 },
        { "Ancestral Knowledge", 4 },
        { "Thundering Strikes", 5 },
        { "Ancestral Knowledge", 5 },
      } },
}

ns.builds.WARLOCK = {
    { key = "affliction", name = "Affliction (leveling)", spec = 1,
      steps = {
        { "Suppression", 4 },
        { "Improved Corruption", 5 },
        { "Improved Life Tap", 1 },
        { "Pandemic", 3 },
        { "Fel Concentration", 3 },
        { "Nightfall", 2 },
        { "Malevolence", 2 },
        { "Soul Siphon", 3 },
        { "Malevolence", 4 },
        { "Shadow Mastery", 5 },
        { "Malevolence", 5 },
        { "Siphon Life", 1 },
        { "Improved Life Tap", 2 },
        { "Improved Drains", 3 },
        { "Unholy Power", 5 },
        { "Demonic Energies", 2 },
        { "Fel Vitality", 3 },
        { "Improved Bane of Agony", 2 },
        { "Grim Reach", 2 },
        { "Suppression", 5 },
      } },
    { key = "demonology", name = "Demonology (leveling)", spec = 2,
      steps = {
        { "Improved Health Funnel", 1 },
        { "Demonic Embrace", 1 },
        { "Unholy Power", 1 },
        { "Improved Health Funnel", 2 },
        { "Demonic Embrace", 2 },
        { "Unholy Power", 2 },
        { "Demonic Embrace", 3 },
        { "Unholy Power", 5 },
        { "Demonic Aegis", 1 },
        { "Improved Voidwalker", 1 },
        { "Fel Vitality", 1 },
        { "Demonic Energies", 1 },
        { "Fel Vitality", 3 },
        { "Demonic Sacrifice", 1 },
        { "Master Summoner", 2 },
        { "Decimation", 1 },
        { "Soul Link", 1 },
        { "Improved Life Tap", 1 },
        { "Decimation", 2 },
        { "Demonic Knowledge", 3 },
        { "Master Demonologist", 5 },
        { "Suppression", 1 },
        { "Improved Corruption", 1 },
        { "Improved Life Tap", 2 },
        { "Suppression", 2 },
        { "Improved Corruption", 2 },
        { "Suppression", 3 },
        { "Improved Corruption", 3 },
        { "Suppression", 4 },
        { "Improved Corruption", 4 },
        { "Suppression", 5 },
        { "Bane", 4 },
        { "Improved Corruption", 5 },
        { "Bane", 5 },
        { "Grim Reach", 1 },
        { "Soul Harvest", 1 },
        { "Grim Reach", 2 },
        { "Soul Harvest", 2 },
      } },
    { key = "destruction", name = "Destruction (leveling)", spec = 3,
      steps = {
        { "Suppression", 4 },
        { "Bane", 5 },
        { "Aftermath", 5 },
        { "Shadowburn", 1 },
        { "Ruin", 4 },
        { "Conflagrate", 1 },
        { "Ruin", 5 },
        { "Agonizing Flames", 3 },
        { "Fire and Brimstone", 3 },
        { "Bane of Havoc", 1 },
        { "Cataclysm", 1 },
        { "Shadow and Flame", 5 },
        { "Incinerate", 1 },
        { "Cataclysm", 3 },
        { "Improved Corruption", 5 },
        { "Suppression", 5 },
        { "Improved Life Tap", 2 },
        { "Unholy Power", 5 },
        { "Demonic Energies", 1 },
      } },
}
