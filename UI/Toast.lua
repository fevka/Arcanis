-- Arcanis: kisa bildirim kutusu (ns.Toast). Sirayla gosterir, birkac saniye sonra silinir.
--   ns.Toast:Show(text [, kind])   kind: "info" (kehribar) | "warn" (kirmizi)
local _, ns = ...

local unpack = unpack or table.unpack
local Skin = ns.Skin
local C = Skin.Colors

local Toast = { queue = {}, hold = 3.5, fade = 0.6 }
ns.Toast = Toast

local KIND_COLOR = { info = C.accent, warn = { 0.90, 0.32, 0.32, 1 } }

function Toast:Build()
  if self.frame then return end
  local f = CreateFrame("Frame", "ArcanisToast", UIParent, "BackdropTemplate")
  ns.Skin:RegisterRoot(f)
  f:SetSize(360, 38)
  f:SetPoint("TOP", UIParent, "TOP", 0, -130)
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  Skin:ApplyBackdrop(f, C.bg, C.accent)
  f.stripe = f:CreateTexture(nil, "ARTWORK")
  f.stripe:SetSize(3, 38)
  f.stripe:SetPoint("LEFT", 1, 0)
  f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  Skin:SetFont(f.text, 12, "OUTLINE")
  f.text:SetPoint("LEFT", 14, 0)
  f.text:SetPoint("RIGHT", -10, 0)
  f.text:SetJustifyH("LEFT")
  f.text:SetTextColor(unpack(C.text))
  f:Hide()
  f:SetScript("OnUpdate", function(frame, elapsed) Toast:Tick(elapsed) end)
  self.frame = f
end

function Toast:Next()
  self:Build()
  if self.current or #self.queue == 0 then return end
  local item = table.remove(self.queue, 1)
  local color = KIND_COLOR[item.kind] or KIND_COLOR.info
  local f = self.frame
  f.text:SetText(item.text)
  f.stripe:SetColorTexture(color[1], color[2], color[3], 1)
  f:SetBackdropBorderColor(color[1], color[2], color[3], 1)
  f:SetAlpha(1)
  f:Show()
  self.current, self.age = item, 0
end

function Toast:Tick(elapsed)
  if not self.current then return end
  self.age = self.age + elapsed
  local over = self.age - self.hold
  if over > 0 then
    local a = 1 - over / self.fade
    if a <= 0 then
      self.frame:Hide()
      self.current = nil
      self:Next()
    else
      self.frame:SetAlpha(a)
    end
  end
end

-- Bildirim duzeyi (sahibin istegi, 13 Kasim 2026; ns.db.noticeLevel: "few" | "normal" | "many"). Her bildirimin
-- onemi: opts.prio "low" (ipucu, bilgi: bolgeye girdin, seviye suresi, Mentor ipucu, ozellik onerisi), "normal",
-- "high"; verilmezse uyari ("warn"), tiklanabilir (action) ya da yanip sonen bildirim "high", digerleri "normal".
-- few: yalniz high; normal: normal + high; many: hepsi.
-- custom: oyuncu her turu ayri acip kapatir (ns.db.noticeCustom[opts.cat], yoksa acik; Settings > Alerts).
-- Turu olmayan bildirim "normal" kuralina gore. Turler: ns.NOTICE_TYPES.
ns.NOTICE_TYPES = { "warn", "upgrade", "whisper", "enemy", "mail", "quest", "zone", "level", "mentor",
  "profession", "discover", "dungeon", "travel", "rare", "social" }
local PRIO = { low = 1, normal = 2, high = 3 }
local NEED = { few = 3, normal = 2, many = 1 }
function ns.NoticeAllowed(kind, action, opts)
  local level = ns.db and ns.db.noticeLevel or "normal"
  local cat = opts and opts.cat
  if level == "custom" then
    if cat then
      local c = ns.db.noticeCustom
      return not (c and c[cat] == false)
    end
    level = "normal"
  end
  local prio = opts and opts.prio
  if not prio then prio = (kind == "warn" or action or (opts and opts.flash)) and "high" or "normal" end
  return (PRIO[prio] or 2) >= (NEED[level] or 2)
end

-- Anahtarli bildirimi kapat (gosterilen ya da sirada bekleyen; ada aciksa adadaki).
function Toast:Dismiss(key)
  if not key then return end
  if ns.Island and ns.Island.Dismiss then ns.Island:Dismiss(key) end
  for i = #self.queue, 1, -1 do if self.queue[i].key == key then table.remove(self.queue, i) end end
  if self.current and self.current.key == key then self.age = self.hold end   -- solarak kapanir
end

-- body (istege bagli): adada ikinci satir; ayri kutuda metnin sonuna eklenir.
-- action: istege bagli; adada bildirime tiklaninca calisir (toast yalniz gosterir).
function Toast:Show(text, kind, body, action, opts)
  if not ns.NoticeAllowed(kind, action, opts) then return end   -- bildirim duzeyi
  -- ust ada aciksa bildirimler oraya gider (opts: flash / hold / color yalniz adada)
  if ns.Island and ns.Island:TakesNotices() then return ns.Island:Push(text, body, kind, action, opts) end
  local item = { text = body and (text .. " - " .. body) or text, kind = kind or "info", key = opts and opts.key }
  -- ayni anahtar (ust uste beceri artisi): gosterilen ya da bekleyen bildirim guncellenir, yenisi siraya girmez
  if item.key and self.current and self.current.key == item.key then
    self.current, self.age = item, 0
    self.frame.text:SetText(item.text); self.frame:SetAlpha(1)
    return
  end
  for i, it in ipairs(self.queue) do
    if item.key and it.key == item.key then self.queue[i] = item; return end
  end
  if #self.queue >= 5 then table.remove(self.queue, 1) end
  self.queue[#self.queue + 1] = item
  self:Next()
end
