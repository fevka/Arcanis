-- Arcanis: "What's new" notlari (UI/WhatsNew.lua). Yeni surum en ustte; her not { enUS, trTR }, kendi cumlelerimiz.
-- Surum toc'taki "## Version" ile ayni yazilir; yalniz oyuncunun gordugunden yeni surumlerin notlari gosterilir.
local _, ns = ...

ns.WhatsNewData = {
  { version = "0.9.0", notes = {
    { enUS = "Profiles: save all your Arcanis settings under a name and load them on another character (Settings > General).",
      trTR = "Profiller: tüm Arcanis ayarlarını bir adla kaydet ve başka bir karakterde yükle (Ayarlar > Genel)." },
    { enUS = "Move Blizzard windows by dragging them; Ctrl + mouse wheel changes their size. Arcanis remembers where you put them.",
      trTR = "Blizzard pencerelerini sürükleyerek taşı; Ctrl + fare tekerleği boyutlarını değiştirir. Arcanis yerlerini hatırlar." },
    { enUS = "Chat helpers: a copy button on each chat window, clickable web links and chat that fades when nothing happens.",
      trTR = "Sohbet yardımcıları: her sohbet penceresinde kopyalama düğmesi, tıklanabilir web bağlantıları ve bir şey olmayınca solan sohbet." },
    { enUS = "Invites and duels from strangers can be declined for you, with a count of how many were blocked.",
      trTR = "Yabancılardan gelen grup davetleri ve düellolar senin yerine reddedilebilir; kaç tanesinin engellendiği sayılır." },
    { enUS = "Minimap: gather addon buttons behind one button, and an optional square minimap.",
      trTR = "Minimap: eklenti düğmelerini tek bir düğmenin arkasında topla, istersen kare minimap kullan." },
    { enUS = "Tooltips can follow your mouse and stay hidden in combat.",
      trTR = "İpuçları fareni izleyebilir ve savaşta gizli kalabilir." },
  } },
}
