local _, A = ...
local ns = A.RF
if not ns then return end
local L = ns.L

-- Ayarlar: Settings > Modules > Rotation helper cekmecesi (/wf rotation, /rof).
-- Kontroller iki listeden kurulur: GENERAL (ns.db) ve sinif modulunun
-- options listesi (ns.cdb). Yeni bir sinif eklenince ayarlari kendiliginden gelir.

local GENERAL = {
    { type = "header", label = "Genel" },
    { type = "toggle", key = "locked", label = "Ikonlari kilitle",
      tip = "Kilitliyken ikonlar suruklenemez ve sadece saldirilabilir bir hedef varken gorunur. Kilit acikken tum ikonlar soru isaretiyle gorunur: boyut ve yerlesimi ayarlarken ac." },
    { type = "cycle", key = "showWhen", label = "Ne zaman gorunsun", values = { "target", "combat", "always" },
      names = { target = "Saldirilabilir hedef varken", combat = "Yalniz savasta", always = "Her zaman" },
      tip = "Her zaman: hedef yokken de ikonlar son oneriyle ekranda kalir. Kilit acikken ikonlar yerlesim icin hep gorunur." },
    { type = "toggle", key = "glow", label = "Aksiyon barinda vurgula",
      tip = "Sari: ana oneri. Mavi: kucuk ikon. Kirmizi: interrupt. Mor: AoE. Blizzard, ElvUI ve Bartender4 barlari." },
    { type = "cycle", key = "mode", label = "Oneri kaynagi", values = { "custom", "auto", "blizzard" },
      names = { custom = "Kendi listemiz", auto = "Once Blizzard asistani", blizzard = "Sadece Blizzard asistani" } },

    { type = "header", label = "Yerlesim" },
    { type = "cycle", key = "layoutMode", label = "Gruplari tasima", values = { "free", "together" },
      names = { free = "Serbest (her grup kendi tutamacindan)", together = "Birlikte (hepsi tek parca)" },
      tip = "Kilidi ac (/rof unlock): her grubun ustunde sari bir tutamac cikar, oradan surukle. Hic suruklenmemis grup ana gruba gore varsayilan yerinde durur." },
    { type = "cycle", key = "iconLayout", label = "Varsayilan dizilis", values = { "horizontal", "vertical" },
      names = { horizontal = "Yatay (AoE sola, kucuk ikon uste, cooldown'lar alta)",
                vertical = "Dikey (AoE uste, kucuk ikon saga, cooldown'lar yanina)" },
      tip = "Birlikte modunda ve henuz suruklenmemis gruplarin yeri." },
    { type = "cycle", key = "queueDir", label = "Sira ikonlarinin yonu", values = { "right", "left", "down", "up" },
      names = { right = "Saga", left = "Sola", down = "Asagi", up = "Yukari" } },
    { type = "button", label = "Konumlari sifirla", width = 160,
      onClick = function() ns.UI_ResetPositions() end, tip = "Tum gruplari varsayilan yerine dondurur." },

    { type = "header", label = "Ikonlar" },
    { type = "slider", key = "scale", min = 0.5, max = 3, step = 0.1, label = "Genel olcek",
      tip = "Tum ikonlari birlikte buyutur / kucultur." },
    { type = "slider", key = "mainSize", min = 24, max = 120, step = 2, label = "Ana ikon boyutu" },
    { type = "slider", key = "iconSpacing", min = 0, max = 30, step = 1, label = "Ikon araligi" },

    { type = "header", label = "Siradaki yetenekler" },
    { type = "slider", key = "queueCount", min = 0, max = 3, step = 1, zero = "Kapali",
      label = "Kac yetenek gosterilsin",
      tip = "Ana ikondan sonra basilacaklarin tahmini. Ilk ikon kesin; sonrakiler tahmin, cunku savasta rage / mana gizli." },
    { type = "slider", key = "queueSize", min = 16, max = 96, step = 2, label = "Sira ikonu boyutu" },
    { type = "slider", key = "queueAlpha", min = 0.2, max = 1, step = 0.05, label = "Sira ikonu gorunurlugu",
      tip = "Dusuk deger: tahmin oldugu belli olsun diye daha soluk." },

    { type = "header", label = "Kucuk ikon" },
    { type = "toggle", key = "showExtra", label = "Kucuk ikonu goster",
      tip = "GCD disi yetenekler (Heroic Strike, Shield Block, Bloodrage, Auto Shot), cooldown'lar ve savunma. Kapaliyken interrupt yine gosterilir." },
    { type = "slider", key = "extraSize", min = 16, max = 96, step = 2, label = "Kucuk ikon boyutu" },

    { type = "header", label = "AoE" },
    { type = "cycle", key = "aoeDisplay", label = "AoE gosterimi", values = { "separate", "auto", "off" },
      names = { separate = "Ayri ikon (ana ikon hep tek hedef)", auto = "Otomatik (ana ikon AoE'ye gecer)",
                off = "Kapali" } },
    { type = "toggle", key = "aoeAlways", label = "AoE ikonu savasta hep gorunsun",
      tip = "Ayri ikon modunda: dusman sayimindan bagimsiz olarak AoE onerisini goster (nameplate'ler kapaliysa isine yarar)." },
    { type = "slider", key = "aoeSize", min = 16, max = 96, step = 2, label = "AoE ikonu boyutu" },

    { type = "header", label = "Buyuk cooldown'lar" },
    { type = "toggle", key = "cds", label = "Buyuk cooldown'lari goster / oner",
      tip = "Sinif cooldown'lari (Death Wish, Arcane Power, Bestial Wrath...), racial'lar (Blood Fury, Berserking...), \"Use:\" etkili trinket'ler ve /rof track ile ekledigin yetenekler. Her birinin kullanim modu sinif bolumunde." },
    { type = "cycle", key = "cdDisplay", label = "Nerede gosterilsin", values = { "bar", "extra" },
      names = { bar = "Ayri cooldown cubugu (hepsi, sure dilimiyle)", extra = "Kucuk ikonda (sadece onerilen)" } },
    { type = "toggle", key = "cdGlow", label = "Onerilen cooldown parlasin",
      tip = "Cubukta altin kenarlik, aksiyon barinda turuncu parlama." },
    { type = "toggle", key = "cdOnlyReady", label = "Cubukta sadece hazir olanlar" },
    { type = "slider", key = "cdSize", min = 16, max = 80, step = 2, label = "Cooldown ikonu boyutu" },
    { type = "slider", key = "cdMax", min = 1, max = 12, step = 1, label = "Cubukta en fazla ikon" },
    { type = "cycle", key = "cdDir", label = "Cubugun buyume yonu",
      values = { "right", "left", "center", "down", "up" },
      names = { right = "Saga", left = "Sola", center = "Ortadan iki yana", down = "Asagi", up = "Yukari" },
      tip = "Ikon sayisi degisince cubuk bu yone uzar / kisalir. Ortali: hep merkezde kalir." },
    { type = "slider", key = "cdPerRow", min = 0, max = 12, step = 1, zero = "Tek satir",
      label = "Satira sarma (ikon sayisi)", tip = "Bu kadar ikondan sonra alt satira (dikey yonlerde yan sutuna) gec." },
    { type = "button", label = "Cooldown sirasini sifirla", width = 200,
      onClick = function() ns.CooldownOrderReset() end,
      tip = "Kilit acikken cubuktaki ikonlari surukleyip birakarak siralayabilirsin; bu buton varsayilan siraya dondurur." },

    { type = "header", label = "Interrupt" },
    { type = "toggle", key = "interrupt", label = "Interrupt oner",
      tip = "Hedef kesilebilir bir buyu cast ederken kucuk ikonda kirmizi cerceveyle: Pummel / Shield Bash (Warrior), Counterspell (Mage). Hunter'in Forever'da interrupt'i yok." },
    { type = "slider", key = "interruptDelay", min = 0, max = 1.5, step = 0.1, zero = "Hemen",
      label = "Interrupt gecikmesi (sn)", tip = "Cast basladiktan bu kadar sonra oner." },

    { type = "header", label = "Talent" },
    { type = "toggle", key = "talentGuide", label = "Talent rehberi",
      tip = "Bos talent puanin varken secili build'e gore siradaki talent'i gosterir. Puan harcamaz. /rof talent ile sonraki 5 adim." },
    { type = "toggle", key = "talentChat", label = "Talent: sohbete yaz" },
    { type = "toggle", key = "talentGlow", label = "Talent: parlama",
      tip = "Talent butonu ve talent ekraninda siradaki talent'in ustunde yesil parlama." },
}

ns.OPTIONS_GENERAL = GENERAL

-- Ayarlar Arcanis'in ayar kurucusuyla cizilir (Settings > Modules > Rotation helper cekmecesi): ayri pencere,
-- oyun dokulu kontrol ya da Blizzard ayar kategorisi yok. Metinler bu modulun dilinden (L, Turkce kaynak
-- anahtarlar); kurucu metin yerine islev kabul eder.

local function Changed()
    if ns.SetLanguage then ns.SetLanguage(ns.db.language) end
    if ns.UI_Apply then ns.UI_Apply() end
    if ns.TalentGuide_Update then ns.TalentGuide_Update() end
end
ns.Options_Changed = Changed

local function Text(s) return s and function() return L(s) end or nil end

local function Values(def) return type(def.values) == "function" and def.values() or def.values end
local function Names(def) return (type(def.names) == "function" and def.names() or def.names) or {} end

local function Fmt(step)
    if step < 0.1 then return "%.2f" elseif step < 1 then return "%.1f" end
    return "%d"
end

-- Tek tanim -> kurucu satiri (store: ayar tablosunu veren islev)
local function Control(ob, def, store)
    local label, tip = Text(def.label), Text(def.tip)
    if def.type == "header" then
        ob:Header(label)
    elseif def.type == "toggle" then
        ob:Switch(label, tip, function() return store()[def.key] and true or false end,
            function(v) store()[def.key] = v and true or false; Changed() end)
    elseif def.type == "slider" then
        ob:Slider(label, tip, def.min, def.max, def.step,
            function() return store()[def.key] or def.default or def.min end,
            function(v) store()[def.key] = v; Changed() end, Fmt(def.step))
    elseif def.type == "cycle" then
        ob:Dropdown(label, tip, function()
            local items, names = {}, Names(def)
            for _, v in ipairs(Values(def)) do items[#items + 1] = { value = v, text = names[v] and L(names[v]) or tostring(v) } end
            return items
        end, function()
            local v = store()[def.key]
            if v == nil then v = def.default end
            return v
        end, function(v) store()[def.key] = v; Changed() end)
    elseif def.type == "button" then
        ob:Buttons(label, tip, { { label, function() def.onClick(); Changed() end } })
    end
end

-- Cok kullanilan bolumler temel ayarlarda, digerleri "Advanced"de
local BASIC = { ["Genel"] = true, ["Ikonlar"] = true, ["Talent"] = true }

local function Build(ob, list, store, basic)
    local section
    for _, def in ipairs(list) do
        if def.type == "header" then section = def.label end
        if (BASIC[section] and true or false) == basic then Control(ob, def, store) end
    end
end

-- Her buyuk cooldown icin kullanim modu (ns.cdb.cdMode[key]). Trinket satirlari slot basina hep gorunur
-- (takili esya degisebilir); racial'lar sadece biliniyorsa.
local function CooldownRows(ob, cls)
    local rows = {}
    for _, c in ipairs(cls.cooldowns or {}) do
        local s = ns.spells[c.key]
        if s then rows[#rows + 1] = { key = c.key, label = s.name, default = c.default or "big" } end
    end
    for _, key in ipairs(ns.RACIAL_ORDER) do
        local s = ns.spells[key]
        if s then rows[#rows + 1] = { key = key, label = s.name .. " " .. L("(racial)"), default = ns.RACIAL_DEFAULT[key] } end
    end
    local slots, labels = ns.TrinketSlots()
    for _, slot in ipairs(slots) do
        rows[#rows + 1] = { key = "Trinket" .. slot, label = L(labels[slot]), default = "big" }
    end
    for _, t in ipairs(ns.TrackedEntries()) do rows[#rows + 1] = t end
    if #rows == 0 then return end
    ob:Header(Text("Cooldown kullanimi"))
    local modes = ns.cdb.cdMode
    for _, r in ipairs(rows) do
        if modes[r.key] == nil then modes[r.key] = r.default end
        local name = r.label
        Control(ob, { type = "cycle", key = r.key, values = ns.CD_MODES, names = ns.CD_MODE_NAMES, default = r.default,
                      label = name, tip = "Yetenek eklemek icin: /rof track <ad>   cikarmak icin: /rof untrack <ad>" },
                function() return ns.cdb.cdMode end)
    end
end

-- Cekmece govdesi. basic: temel bolumler + sinif secenekleri; degilse gelismis bolumler + cooldown modlari.
function ns.Options_Body(ob, basic)
    if not ns.db then return end
    Build(ob, GENERAL, function() return ns.db end, basic)
    local cls = ns.classes[ns.playerClass or ""]
    if not (cls and ns.cdb) then return end
    if basic then
        ob:Header(function() return select(1, UnitClass("player")) or ns.playerClass end)
        -- Talent build secimi (sinifin build listesinden); liste her acilista okunur (iceri aktarilan build)
        if ns.BuildsForClass then
            Control(ob, { type = "cycle", key = "build", label = "Talent build",
                values = function()
                    local v = { "auto" }
                    for _, b in ipairs(ns.BuildsForClass()) do v[#v + 1] = b.key end
                    return v
                end,
                names = function()
                    local n = { auto = "Otomatik (en cok puanli agac)" }
                    for _, b in ipairs(ns.BuildsForClass()) do n[b.key] = b.name end
                    return n
                end }, function() return ns.cdb end)
        end
        for _, def in ipairs(cls.options or {}) do Control(ob, def, function() return ns.cdb end) end
    else
        CooldownRows(ob, cls)
    end
end

-- Varsayilanlar: Core'daki duz degerler; tablolar (konumlar, sinif ayarlari) korunur
function ns.ResetAll()
    for k, v in pairs(ns.defaults) do
        if type(v) ~= "table" then ns.db[k] = v end
    end
    local cls = ns.classes[ns.playerClass]
    for _, o in ipairs(cls and cls.options or {}) do
        if o.key and ns.cdb then ns.cdb[o.key] = o.default end
    end
    if ns.cdb then
        ns.cdb.build = "auto"
        wipe(ns.cdb.cdMode)   -- cooldown modlari varsayilana (takip listesi korunur)
    end
    Changed()
    ns.Options_Refresh()
    ns.Print(L("Ayarlar varsayilana dondu."))
end

-- Eski girisler (komutlar, /rof): Arcanis'in ayar cekmecesi
function ns.Options_Init() end

function ns.Options_Refresh()
    local S = A.Settings
    local mp = S and S.pages and S.pages.modules and S.pages.modules.frame
    local d = mp and mp.drawers and mp.drawers.Rotation
    if d and d.refresh then pcall(d.refresh) end
end

function ns.Options_Open()
    if A.Settings then A.Settings:OpenOptions("Rotation") end
end
