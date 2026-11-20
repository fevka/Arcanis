-- Arcanis: varsayilan gorev ipuclari. Anahtar: gorev ID'si; deger metin ya da { enUS = "...", trTR = "..." }.
-- Kendi cumlelerinle yaz; baska rehberlerden metin yapistirma. Oyuncu kendi ipuclarini /wf tip ile ekler.
-- shortcut = true: kestirme (ornek olum kestirmesi); adim penceresinde quest kutusu kapaliyken de ayri satirda.
-- Ornek:  [25126] = { enUS = "The boars wander south of the training dummies.", trTR = "Yabandomuzlari manken alaninin guneyinde dolasir." },
local _, ns = ...

-- Skyborne: Valanaar uzak; olunce spirit healer teslim yerine yakin diriltir (oyuncu bulgusu)
local VALANAAR = { shortcut = true,
  enUS = "Shortcut: Valanaar is a long walk. Dying is faster: the spirit healer revives you close to it.",
  trTR = "Kestirme: Valanaar uzak. Ölmek daha hızlı: spirit healer seni ona yakın diriltir." }
-- Skyborne: Falaath Village harabeleri uzak; olunce spirit healer koyun hemen yaninda diriltir (oyuncu bulgusu)
local FALAATH = { shortcut = true,
  enUS = "Shortcut: Falaath Village is a long walk. Dying is faster: the spirit healer revives you right next to the village.",
  trTR = "Kestirme: Falaath Village uzak. Ölmek daha hızlı: spirit healer seni köyün hemen yanında diriltir." }

ns.Tips:SetDefaults({
  [92579] = VALANAAR, [92701] = VALANAAR, [93948] = VALANAAR,   -- To Valanaar (iki taraf), Deliver the Signet
  [92550] = FALAATH, [92551] = FALAATH,                         -- Havoc in the Highlands, Stolen Supplies
  -- Look To The Stars: Bronze Tube hic bir yaratiktan dusmez (16 Kasim 2026, oyuncu bulgusu: ok kayboluyordu)
  [174] = { enUS = "No monster drops the Bronze Tube. Buy one at the Auction House in Stormwind, or ask an engineer to make it.",
    trTR = "Bronze Tube hiçbir yaratıktan düşmez. Stormwind'deki Auction House'tan satın al ya da bir mühendise yaptır." },
})
