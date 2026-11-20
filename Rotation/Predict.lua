local _, A = ...
local ns = A.RF
if not ns then return end

-- Sira tahmini: "bu yetenegi bastin" varsayip oncelik listesini yeniden calistirir.
-- Tahmin modunda (ns.sim) Core'daki okumalar su sekilde degisir:
--   * cooldown'lu yetenek (temel cooldown > 1.5 sn) bir daha hazir degil (ns.Ready)
--   * proc harcandi (ns.Proc)
--   * duration'li buyu/debuff hedefte/ustunde sayilir, ayni gruptaki digerleri kalkar
--     (ns.AuraRemaining), yigini bir artar (ns.Stacks)
--   * durus yetenegi aktif durusu degistirir (ns.ActiveForm)
-- Rage / mana savasta gizli oldugu icin harcanan kaynak hesaba katilmaz: ilk ikon
-- kesin, sonrakiler "muhtemel" siradir.

local function Apply(cls, rec)
    local sim = ns.sim
    local key = rec.key
    local def = key and cls.spells[key]
    local s = key and ns.spells[key]
    if not def or not s then return end

    if def.stance then sim.form = s.id end

    if def.duration then
        sim.auras[key] = true
        if def.group then
            for k, d in pairs(cls.spells) do
                if k ~= key and d.group == def.group then sim.auraOff[k] = true end
            end
        end
        if def.maxStacks then sim.stackAdd[key] = (sim.stackAdd[key] or 0) + 1 end
    end

    local baseMS = ns.Call(GetSpellBaseCooldown, s.id) or 0
    if baseMS > 1500 or def.once or ns.Proc(key) then sim.used[key] = true end
end

-- Tahmin durumu her cagrida silinip yeniden kullanilir (4 Hz, cop uretmesin)
local sim = { used = {}, auras = {}, auraOff = {}, stackAdd = {}, form = nil }
local lastErr

local function Run(cls, first, n, out)
    local prev = first
    for _ = 1, n do
        Apply(cls, prev)
        local nextRec = cls.Next()
        if not nextRec or not nextRec.key then break end
        out[#out + 1] = nextRec
        prev = nextRec
    end
end

-- first: su anki ana oneri. n tane sonraki tahmini doner.
function ns.PredictQueue(cls, first, n)
    local out = {}   -- yeni tablo: Core sonucu 0.25 sn saklar
    if not first or not first.key then return out end
    wipe(sim.used); wipe(sim.auras); wipe(sim.auraOff); wipe(sim.stackAdd)
    sim.form = nil
    ns.sim = sim
    -- Hata olsa bile tahmin modu acik kalmasin; sadece tahminde patlayan hata bir kez yazilir
    local ok, err = pcall(Run, cls, first, n, out)
    ns.sim = nil
    if not ok and err ~= lastErr then
        lastErr = err
        ns.Print(ns.L("|cffff4040Tahmin hatasi:|r ") .. tostring(err))
    end
    return out
end
