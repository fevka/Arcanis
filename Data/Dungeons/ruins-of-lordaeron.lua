local _, ns = ...
ns.DungeonExtra("ruins-of-lordaeron", {
  quests = {
    { id = 95250, name = "Abominable Creatures", level = 21, req = 16, side = "Alliance", giver = "Captain Truman, just inside Ruins of Lordaeron (left of the entrance)", turnin = "Captain Truman, just inside Ruins of Lordaeron", note = { enUS = "Collect the Head of the Baron in the Ruins of Lordaeron and bring it back to Captain Truman.", trTR = "Ruins of Lordaeron'da Head of the Baron'ı topla ve Captain Truman'a geri götür." }, rew = "Choose: Monstrous Cleaver, Grave Shroud or Slain Baron's Signet\\n6,188 XP" },
    { id = 97288, name = "Unending Torment", level = 21, req = 16, side = "Horde", giver = "Starts from Abominable Head, drops inside Ruins of Lordaeron.", turnin = "Master Apothecary Faranell, Undercity (48.8, 69.3)", note = { enUS = "Deliver the Abominable Head to Master Apothecary Faranell in the Undercity.", trTR = "Abominable Head'i Undercity'deki Master Apothecary Faranell'e götür." }, rew = "5,300 XP" },
    { id = 92401, name = "A Frightened Request", level = 22, req = 15, side = "Horde", giver = "Tabitha Heartweaver, The Sepulcher, Silverpine Forest (44.4, 43.0)", turnin = "Tabitha Heartweaver, The Sepulcher, Silverpine Forest (44.4, 43.0)", note = { enUS = "Investigate the disappearance of Edward Heartweaver in the Ruins of Lordaeron.", trTR = "Ruins of Lordaeron'da Edward Heartweaver'ın kayboluşunu araştır." }, rew = "Choose: Edwards' Knife or Tabitha's Cuffs\\n7,040 XP • Undercity +150" },
    { id = 92415, name = "Remember That I Love You", level = 22, req = 15, side = "Alliance", giver = "Starts from Blood-Stained Letter, graveyard inside Ruins of Lordaeron.", turnin = "Orphan Matron Nightingale, Stormwind City (56.3, 54.0)", note = { enUS = "Bring the Blood-Stained Letter to Orphan Matron Nightingale in Stormwind City.", trTR = "Blood-Stained Letter'ı Stormwind City'deki Orphan Matron Nightingale'e götür." }, rew = "Tarnished Locket\\n9,750 XP" },
    { id = 92421, name = "Light's Justice", level = 22, req = 15, side = "Horde", giver = "Morbin Lightbane, Undercity (57.4, 90.4)", turnin = "Morbin Lightbane, Undercity (57.4, 90.4)", note = { enUS = "Collect 25 Intact Limbs in the Ruins of Lordaeron and bring them to Morbin Lightbane.", trTR = "Ruins of Lordaeron'da 25 Intact Limbs topla ve Morbin Lightbane'e götür." }, rew = "Choose: The Stitcher or Spare Part Bindings\\n7,040 XP • 45s • Undercity +150" },
    { id = 92422, name = "The Wrath of Rath'mael", level = 22, req = 15, side = "Horde", giver = "Deathguard Kristof, Brill, Tirisfal Glades (65.2, 60.2)", turnin = "Deathguard Kristof, Brill, Tirisfal Glades (65.2, 60.2)", note = { enUS = "Kill Rath'mael in the Ruins of Lordaeron.", trTR = "Ruins of Lordaeron'da Rath'mael'i öldür." }, rew = "Choose: Forsaken Greataxe or Gnarled Necromancer's Staff\\n0 XP • Undercity +150" },
    { id = 95189, name = "Crest of Lordaeron", level = 22, req = 16, side = "Alliance", giver = "Starts from Crest of Lordaeron, drops inside Ruins of Lordaeron.", turnin = "Lady Dena Kennedy, Stormwind City", note = { enUS = "Return the Crest of Lordaeron to Lady Dena Kennedy in Stormwind City.", trTR = "Crest of Lordaeron'u Stormwind City'deki Lady Dena Kennedy'ye geri götür." }, rew = "Small Sack of Gems\\n9,750 XP" },
    { id = 95195, name = "Bloodied Insignia", level = 22, req = 16, side = "Alliance", giver = "Starts from Bloodied Insignia, drops inside Ruins of Lordaeron.", turnin = "General Marcus Jonathan, Stormwind City (69.2, 82.7)", note = { enUS = "Collect 10 Bloodied Insignias and take them to General Marcus Jonathan in Stormwind City.", trTR = "10 Bloodied Insignias topla ve Stormwind City'deki General Marcus Jonathan'a götür." }, rew = "Choose: Duty Bound Leggings or Remembrance Armor\\n9,750 XP • 45s" },
    { id = 95204, name = "Crest of Lordaeron", level = 22, req = 16, side = "Horde", giver = "Starts from Crest of Lordaeron, drops inside Ruins of Lordaeron.", turnin = "Oran Snakewrithe, Undercity (73.1, 32.9)", note = { enUS = "Bring the Crest of Lordaeron to Oran Snakewrithe in the Undercity.", trTR = "Crest of Lordaeron'u Undercity'deki Oran Snakewrithe'a götür." }, rew = "Small Sack of Gems\\n8,320 XP" },
    { id = 95216, name = "The New Plague", level = 22, req = 16, side = "Horde", giver = "Theodore Griffs, Undercity (46.3, 71.9)", turnin = "Theodore Griffs, Undercity (46.3, 71.9)", note = { enUS = "Kill Witherfang in the Ruins of Lordaeron and collect the Highly Toxic Strain from him.", trTR = "Ruins of Lordaeron'da Witherfang'i öldür ve ondan Highly Toxic Strain'i topla." }, rew = "Choose: Plaguefang or Blight Gloves\\n8,320 XP" },
  },
  loot = {
    { boss = "The Baron", items = {
      { id = 271204, n = "Meathook Slicer", q = 3, s = "One-Hand, Dagger", c = "14356789" },
      { id = 271205, n = "Abomination Bones", q = 3, s = "Chest, Mail", c = "36", a = "12" },
      { id = 271206, n = "Leftover Abomination Skin", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
    } },
    { boss = "Witherfang", items = {
      { id = 271201, n = "Atrophic Girdle", q = 3, s = "Waist, Mail", c = "36", a = "12" },
      { id = 271202, n = "Witherbite Bracers", q = 3, s = "Wrist, Leather", c = "49", a = "36" },
      { id = 271203, n = "Segmented Spider Leg", q = 3, s = "Two-Hand, Staff", c = "5789632" },
    } },
    { boss = "The Abandoned", items = {
      { id = 271207, n = "Rotmender's Leggings", q = 3, s = "Legs, Cloth", c = "578", a = "926" },
      { id = 271208, n = "Grip of Fear", q = 3, s = "Hands, Mail", c = "36", a = "12" },
      { id = 271216, n = "Scepter of the Abandoned", q = 3, s = "Main Hand, Mace", c = "124695" },
    } },
    { boss = "Bjork", items = {
      { id = 271209, n = "Bonerust Leggings", q = 3, s = "Legs, Mail", c = "36", a = "12" },
      { id = 271210, n = "Tuskwrap Belt", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
      { id = 271217, n = "Corpse Chopper", q = 3, s = "Two-Hand, Axe", c = "1236" },
    } },
    { boss = "Rath'mael", items = {
      { id = 271213, n = "Mirror of Rath'mael", q = 3, s = "Off Hand, Shield", c = "126" },
      { id = 271214, n = "Rotmender's Treads", q = 3, s = "Feet, Cloth", c = "578", a = "926" },
      { id = 271215, n = "Coldspire Staff", q = 3, s = "Two-Hand, Staff", c = "5789632" },
      { id = 273085, n = "Blueprint: Fermenter", q = 2, s = "Blueprint" },
      { id = 273103, n = "Blueprint: Arcane Salvager", q = 2, s = "Blueprint" },
    } },
    { boss = "Viktor the Vile", items = {
      { id = 271211, n = "Vilewalkers", q = 3, s = "Feet, Mail", c = "36", a = "12" },
      { id = 271212, n = "Bloodied Chestwraps", q = 3, s = "Chest, Leather", c = "49", a = "36" },
      { id = 271218, n = "Vileblood Scimitar", q = 3, s = "One-Hand, Sword", c = "124378" },
    } },
    { boss = "Lordaeron Captain", items = {
      { id = 6641, n = "Haunting Blade", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 6642, n = "Phantom Armor", q = 3, s = "Chest, Mail", c = "36", a = "12" },
    } },
    { boss = "Trash Drops", items = {
      { id = 286981, n = "Death Bindings", q = 3, s = "Wrist, Mail", c = "36", a = "12" },
      { id = 286977, n = "Sword of the Fallen", q = 3, s = "Two-Hand, Sword", c = "124378" },
      { id = 286978, n = "Rotmender's Garb", q = 3, s = "Chest, Cloth", c = "578", a = "926" },
      { id = 286980, n = "Rotmender's Sash", q = 3, s = "Waist, Cloth", c = "578", a = "926" },
    } },
  },
})
