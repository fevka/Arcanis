-- Arcanis: Mentor bilgi bankasi (ns.MentorTips). Yeni oyuncular icin rehber bilgiler.
local _, ns = ...
ns.MentorTips = {
  -- ===================== BASICS =====================
  { id = "rested-xp", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Rested XP: log out in an inn or city", trTR = "Rested XP: handa veya şehirde çıkış yap" },
    text = { enUS = "Logging out inside an inn or capital city builds Rested XP (your XP bar turns blue). While rested, kills give double XP; quest XP does not use it up. You gain about one level per week, up to a level and a half. Logging out anywhere else builds it four times slower.",
             trTR = "Bir han veya başkent içinde çıkış yaparsan Rested XP birikir (XP çubuğun maviye döner). Rested durumdayken öldürdüğün yaratıklar iki kat XP verir; görev XP'si Rested'i harcamaz. Haftada yaklaşık bir seviye birikir, en fazla bir buçuk seviyeye kadar. Başka bir yerde çıkış yaparsan dört kat yavaş birikir." } },

  { id = "hearthstone-basics", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Your Hearthstone is a free teleport", trTR = "Hearthstone ücretsiz bir ışınlanmadır" },
    text = { enUS = "The Hearthstone in your bags teleports you to the inn you last set as home. To change it, talk to an innkeeper and choose 'Make this inn your home'. The cooldown is long, so use it to return from a long questing trip, not for short hops.",
             trTR = "Çantandaki Hearthstone seni en son ev yaptığın hana ışınlar. Evini değiştirmek için bir hancıyla konuşup 'Make this inn your home' seçeneğini seç. Bekleme süresi uzundur; kısa mesafeler için değil, uzun bir görev yolculuğundan dönmek için kullan." } },

  { id = "inn-set-home", cat = "basics", min = 1, max = 60, class = nil, trigger = "inn",
    title = { enUS = "Set your home at this inn", trTR = "Evini bu handa belirle" },
    text = { enUS = "You are at an inn. If you plan to quest in this area for a while, talk to the innkeeper and make it your home, so your Hearthstone brings you back here. Innkeepers also sell cheap food and water.",
             trTR = "Bir handasın. Bu bölgede bir süre görev yapacaksan hancıyla konuşup burayı evin yap; böylece Hearthstone seni buraya getirir. Hancılar ayrıca ucuz yiyecek ve su satar." } },

  { id = "flight-paths", cat = "basics", min = 1, max = 60, class = nil, trigger = "flightmaster",
    title = { enUS = "Talk to every flight master you see", trTR = "Gördüğün her flight master'la konuş" },
    text = { enUS = "You can only use a flight master after you have discovered it by talking to it. Pick up every flight point you pass, even if you do not need it yet. Flights are cheap, and later they connect the whole continent.",
             trTR = "Bir flight master'ı kullanabilmek için önce onunla konuşup keşfetmen gerekir. Şu an gerekmese bile geçtiğin her flight point'i al. Uçuşlar ucuzdur ve ileride tüm kıtayı birbirine bağlar." } },

  { id = "bag-space", cat = "basics", min = 1, max = 30, class = nil, trigger = "bagsfull",
    title = { enUS = "Bags are full: what to do", trTR = "Çantalar doldu: ne yapmalı" },
    text = { enUS = "Sell gray items to any vendor; they only exist to be sold. Keep white and green items that are useful or sellable. Buy or craft bigger bags as soon as you can: Tailors make them from cloth, and 6 to 10 slot bags are cheap on the Auction House.",
             trTR = "Gri eşyaları herhangi bir satıcıya sat; sadece satılmak için vardır. İşe yarayan veya satılabilir beyaz ve yeşil eşyaları sakla. Fırsat bulur bulmaz daha büyük çanta al veya yaptır: Tailor'lar kumaştan çanta yapar ve 6-10 slotluk çantalar Auction House'ta ucuzdur." } },

  { id = "repairs", cat = "basics", min = 1, max = 60, class = nil, trigger = "lowdura",
    title = { enUS = "Repair your gear before it breaks", trTR = "Eşyalarını kırılmadan tamir ettir" },
    text = { enUS = "Your armor is getting damaged. Items at 0 durability stop giving stats, and broken weapons cannot be used. Any vendor with an anvil icon on the minimap can repair gear; most armor and weapon merchants do. Repairs get costlier at higher levels, so keep some silver aside.",
             trTR = "Zırhın hasar görüyor. Dayanıklılığı 0 olan eşyalar stat vermez, kırık silahlar kullanılamaz. Mini haritada örs simgesi olan her satıcı tamir yapar; çoğu zırh ve silah tüccarı yapar. Yüksek seviyelerde tamir pahalılaşır, bu yüzden biraz gümüş ayır." } },

  { id = "vendor-vs-ah", cat = "basics", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Vendor or Auction House?", trTR = "Satıcı mı, Auction House mu?" },
    text = { enUS = "Gray items go to vendors. Green and better items, crafting materials, cloth and herbs usually sell for far more on the Auction House than to a vendor. The Auction House takes a small cut and a listing deposit, so price reasonably and use 12 or 24 hour listings.",
             trTR = "Gri eşyalar satıcıya gider. Yeşil ve üstü eşyalar, zanaat malzemeleri, kumaş ve otlar Auction House'ta genelde satıcıdan çok daha fazla eder. Auction House küçük bir komisyon ve listeleme ücreti alır; makul fiyat ver ve 12 veya 24 saatlik listeleme kullan." } },

  { id = "quest-log-limit", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Quest log holds 20 quests", trTR = "Görev günlüğü 20 görev alır" },
    text = { enUS = "Your quest log has a hard limit of 20 quests, so abandon quests that are gray, far away or need a group you cannot find. Gray quests give almost no XP. Yellow and green quests are worth doing; orange and red ones are hard for your level.",
             trTR = "Görev günlüğünün sınırı 20'dir; gri, çok uzak veya bulamadığın bir grup gerektiren görevleri bırak. Gri görevler neredeyse hiç XP vermez. Sarı ve yeşil görevler yapmaya değer; turuncu ve kırmızı olanlar seviyen için zordur." } },

  { id = "death-corpse-run", cat = "basics", min = 1, max = 60, class = nil, trigger = "death",
    title = { enUS = "You died: how to come back", trTR = "Öldün: nasıl geri dönersin" },
    text = { enUS = "Release your spirit and run back to your corpse as a ghost. When you are close, a button lets you resurrect with no penalty except 10 percent durability loss. The Spirit Healer at the graveyard can also revive you instantly, but that costs 25 percent durability and gives resurrection sickness.",
             trTR = "Release Spirit'e basıp hayalet olarak cesedine koş; yaklaşınca çıkan düğmeyle yalnızca yüzde 10 dayanıklılık kaybıyla dirilirsin. Mezarlıktaki Spirit Healer seni anında da diriltir ama bu yüzde 25 dayanıklılık kaybına mal olur ve resurrection sickness verir." } },

  { id = "res-sickness", cat = "basics", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Resurrection sickness is expensive", trTR = "Resurrection sickness pahalıdır" },
    text = { enUS = "Reviving at the Spirit Healer gives resurrection sickness: all your stats are reduced by 75 percent for up to 10 minutes (shorter at low levels). Below level 10 there is no sickness, so it is fine to use early on. Later, walk back to your corpse instead.",
             trTR = "Spirit Healer'da dirilmek resurrection sickness verir: tüm statların 10 dakikaya kadar yüzde 75 düşer (düşük seviyede daha kısa). 10. seviyenin altında bu hastalık yoktur, bu yüzden başlangıçta kullanmakta sakınca yok. Daha sonra bunun yerine cesedine yürüyerek dön." } },

  { id = "eat-drink", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Eat and drink between fights", trTR = "Dövüşler arasında ye ve iç" },
    text = { enUS = "Health and mana regenerate slowly on their own. Sitting down to eat food or drink water restores them much faster. Buy a stack of the best food and water your level allows from innkeepers and general vendors; it is cheap and saves a lot of time.",
             trTR = "Can ve mana kendiliğinden yavaş dolar. Oturup yemek yemek veya su içmek çok daha hızlı doldurur. Hancılardan ve genel satıcılardan seviyenin izin verdiği en iyi yiyecek ve sudan bir deste al; ucuzdur ve çok zaman kazandırır." } },

  { id = "capital-city", cat = "basics", min = 5, max = 60, class = nil, trigger = "city",
    title = { enUS = "Welcome to a capital city", trTR = "Bir başkente hoş geldin" },
    text = { enUS = "Capitals have everything: class trainers, profession trainers, the bank, the Auction House, a mailbox and an inn. Ask a city guard for directions; they mark locations on your map. Set your Hearthstone here if you will be returning often.",
             trTR = "Başkentlerde her şey vardır: sınıf trainer'ları, meslek trainer'ları, banka, Auction House, posta kutusu ve han. Yol sormak için şehir muhafızıyla konuş; konumu haritanda işaretler. Sık döneceksen Hearthstone'unu buraya ayarla." } },

  { id = "bank-basics", cat = "basics", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Use the bank for things you do not carry", trTR = "Taşımadığın şeyler için bankayı kullan" },
    text = { enUS = "The bank in each capital stores items you do not need on you, such as crafting materials or gear for later. Extra bank bag slots cost money, but the first ones are cheap. Your bank holds the same items in every capital of your faction.",
             trTR = "Her başkentteki banka, zanaat malzemeleri veya ileride giyeceğin eşyalar gibi üzerinde taşıman gerekmeyen şeyleri saklar. Ek banka çanta slotları paralıdır ama ilkleri ucuzdur. Bankan, tarafının tüm başkentlerinde aynı eşyaları gösterir." } },

  { id = "mailbox", cat = "basics", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Mail items to your other characters", trTR = "Eşyaları diğer karakterlerine postala" },
    text = { enUS = "Mailboxes let you send items and gold to any character on your realm and faction, including your own alts. Mail between your own characters arrives instantly; mail to other players takes about an hour. Auction House sales and expired listings arrive by mail too.",
             trTR = "Posta kutularıyla kendi alt karakterlerin dahil, sunucundaki ve tarafındaki her karaktere eşya ve altın gönderebilirsin. Kendi karakterlerin arasındaki posta anında ulaşır; başka oyunculara yaklaşık bir saat sürer. Auction House satışları ve süresi dolan ilanlar da postayla gelir." } },

  { id = "map-and-minimap", cat = "basics", min = 1, max = 20, class = nil, trigger = nil,
    title = { enUS = "Read the minimap icons", trTR = "Mini harita simgelerini oku" },
    text = { enUS = "On the minimap, a yellow exclamation mark is an available quest and a yellow question mark is a quest to turn in. Hover over icons to see what they are. The tracking button lets you track vendors, repair NPCs, herbs or ore, depending on your skills.",
             trTR = "Mini haritada sarı ünlem alınabilir bir görev, sarı soru işareti ise teslim edilecek bir görevdir. Ne olduklarını görmek için simgelerin üzerine gel. Takip düğmesiyle yeteneklerine göre satıcıları, tamircileri, otları veya madenleri takip edebilirsin." } },

  { id = "weapon-skills", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Weapon skills must be trained and leveled", trTR = "Silah yetenekleri öğrenilmeli ve yükseltilmeli" },
    text = { enUS = "You can only equip weapon types your class has learned. Weapon masters in capitals teach new types for a small fee. Each weapon skill rises as you hit enemies; a fresh skill makes you miss a lot, so level it on easy mobs first.",
             trTR = "Sadece sınıfının öğrendiği silah türlerini kuşanabilirsin. Başkentlerdeki weapon master'lar küçük bir ücretle yeni türler öğretir. Her silah yeteneği düşmana vurdukça yükselir; yeni bir yetenekle çok ıskalarsın, bu yüzden önce kolay yaratıklarda yükselt." } },

  { id = "ui-keybinds", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Bind your abilities to keys", trTR = "Yeteneklerini tuşlara ata" },
    text = { enUS = "Clicking spells with the mouse is slow. Drag abilities onto the action bar, press the number keys to use them, and use the mouse to turn and look. You can turn on extra action bars in Interface Options under ActionBars.",
             trTR = "Büyülere fareyle tıklamak yavaştır. Yetenekleri action bar'a sürükle, sayı tuşlarıyla kullan ve dönmek ile etrafa bakmak için fareyi kullan. Ek action bar'ları Interface Options içindeki ActionBars bölümünden açabilirsin." } },

  { id = "addons-basics", cat = "basics", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "A few addons go a long way", trTR = "Birkaç addon çok iş görür" },
    text = { enUS = "Addons are safe and allowed; they go in the game's Interface/AddOns folder. Good first picks are a bag addon, a threat meter, a quest helper and an Auction House helper. Keep the list small while you learn the game.",
             trTR = "Addon'lar güvenli ve serbesttir; oyunun Interface/AddOns klasörüne atılır. İlk tercihler için bir çanta addon'u, bir threat ölçer, bir görev yardımcısı ve bir Auction House yardımcısı iyidir. Oyunu öğrenirken listeyi kısa tut." } },

  { id = "macros-basics", cat = "basics", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Macros: small scripts for your bar", trTR = "Makrolar: action bar için küçük komutlar" },
    text = { enUS = "Type /macro to open the macro window. A simple useful one is a mount macro, or '/cast [@mouseover] Spell' to cast on whatever your mouse is over. Macros cannot make decisions for you in combat; one button press is one action.",
             trTR = "Makro penceresini açmak için /macro yaz. Basit ve işe yarar örnek bir binek makrosu veya farenin üzerinde durduğu hedefe büyü atan '/cast [@mouseover] Büyü' makrosudur. Makrolar savaşta senin yerine karar veremez; bir tuş bir eylemdir." } },

  { id = "bank-space", cat = "basics", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Your bank is bigger than in Classic", trTR = "Bankan Classic'tekinden büyük" },
    text = { enUS = "In Forever the bank has 48 slots and room for 8 extra bags. Store crafting materials and gear you keep for later there instead of filling your bags. Every capital and major town has a banker.",
             trTR = "Forever'da bankada 48 slot ve 8 ek çanta yeri var. Meslek malzemelerini ve sonra kullanacağın eşyaları çantanı doldurmak yerine orada sakla. Her başkentte ve büyük kasabada bir banker bulunur." } },

  { id = "early-bag-dun-morogh", cat = "basics", min = 4, max = 10, class = nil, trigger = nil,
    title = { enUS = "A free bag in Dun Morogh", trTR = "Dun Morogh'da bedava çanta" },
    text = { enUS = "Dwarves and Gnomes can pick up Grund and Gozwin at level 4 in the hills of Coldridge Valley. It rewards a 6-slot bag, which is a big help in your first hours. Other starting zones do not seem to have one yet.",
             trTR = "Dwarf ve Gnome'lar 4. seviyede Coldridge Valley'nin tepelerinde Grund and Gozwin görevini alabilir. Ödülü 6 slotluk bir çantadır ve ilk saatlerinde çok işe yarar. Diğer başlangıç bölgelerinde şimdilik benzeri görünmüyor." } },

  -- ===================== LEVELING =====================
  { id = "train-spells", cat = "leveling", min = 1, max = 60, class = nil, trigger = "trainer",
    title = { enUS = "New spells are not automatic", trTR = "Yeni büyüler otomatik gelmez" },
    text = { enUS = "You learn new spells and higher ranks from your class trainer; they do not come automatically. Visit the trainer every 2 levels. New ranks get expensive, so if you are short on gold, skip ranks of spells you rarely use.",
             trTR = "Yeni büyüleri ve üst rank'ları otomatik olarak değil, sınıf trainer'ından öğrenirsin. Her 2 seviyede bir trainer'a uğra. Yeni rank'lar pahalılaşır; altının azsa nadiren kullandığın büyülerin rank'larını atla." } },

  { id = "level-10", cat = "leveling", min = 10, max = 10, class = nil, trigger = "level",
    title = { enUS = "Level 10: talents and your first big step", trTR = "Seviye 10: talent puanları ve ilk büyük adım" },
    text = { enUS = "From level 10 you gain one talent point per level; open the talent window and pick a tree to focus on. Hunters get their pet quest, Warriors learn Defensive Stance, and your trainer has important new abilities. Most starting zones also send you to a bigger zone now.",
             trTR = "10. seviyeden itibaren her seviyede bir talent puanı kazanırsın; talent penceresini açıp odaklanacağın bir ağaç seç. Hunter'lar pet görevini alır, Warrior'lar Defensive Stance'i öğrenir ve trainer'ında önemli yeni yetenekler vardır. Çoğu başlangıç bölgesi seni artık daha büyük bir bölgeye yönlendirir." } },

  { id = "level-20", cat = "leveling", min = 20, max = 20, class = nil, trigger = "level",
    title = { enUS = "Level 20: new zones, new tools", trTR = "Seviye 20: yeni bölgeler, yeni araçlar" },
    text = { enUS = "Rogues can learn poisons, Druids get Cat Form, and Warlocks get the Succubus. Your first real dungeons are available around now. Start saving gold for your level 40 mount from here.",
             trTR = "Rogue'lar zehir öğrenebilir, Druid'ler Cat Form'u, Warlock'lar Succubus'u alır. İlk gerçek zindanlar bu seviyelerde açılır. 40. seviye bineğin için altın biriktirmeye şimdiden başla." } },

  { id = "level-30", cat = "leveling", min = 30, max = 30, class = nil, trigger = "level",
    title = { enUS = "Level 30: the mid game", trTR = "Seviye 30: oyunun ortası" },
    text = { enUS = "Warriors get Berserker Stance through a quest, and Priests and Druids get stronger healing. Quests get longer and more spread out; group quests reward excellent gear, so do them when you find a group.",
             trTR = "Warrior'lar bir görevle Berserker Stance'i alır; Priest ve Druid'lerin iyileştirmesi güçlenir. Görevler daha uzun ve dağınık olur; grup görevleri çok iyi eşya verir, grup bulduğunda yap." } },

  { id = "level-40", cat = "leveling", min = 40, max = 40, class = nil, trigger = "level",
    title = { enUS = "Level 40: buy your mount", trTR = "Seviye 40: bineğini al" },
    text = { enUS = "You can now learn Riding from your race's riding trainer: 100 gold, and your first mount is included. Honored reputation with that faction gives 10% off. Paladins and Warlocks get their mount through their class instead. Warriors and Paladins can also wear plate now, and Hunters and Shamans move to mail.",
             trTR = "Artık ırkının riding trainer'ından Riding öğrenebilirsin: 100 altın, ilk binek de bu fiyata dahil. O faction'la Honored itibarda %10 indirim alırsın. Paladin ve Warlock'lar bineklerini sınıfları üzerinden alır. Warrior ve Paladin'ler artık plate giyebilir; Hunter ve Shaman'lar mail'e geçer." } },

  { id = "level-50", cat = "leveling", min = 50, max = 50, class = nil, trigger = "level",
    title = { enUS = "Level 50: the home stretch", trTR = "Seviye 50: son düzlük" },
    text = { enUS = "Each class gets a special quest line around now that rewards a strong item. Max-level dungeons start to appear; their gear carries you into endgame. Start thinking about reputation with factions whose rewards you want.",
             trTR = "Her sınıf bu seviyelerde güçlü bir eşya veren özel bir görev zinciri alır. Üst seviye zindanlar görünmeye başlar; oradaki eşyalar seni endgame'e taşır. Ödüllerini istediğin faction'lar için reputasyon kasmayı düşünmeye başla." } },

  { id = "level-60", cat = "leveling", min = 60, max = 60, class = nil, trigger = "level",
    title = { enUS = "Level 60: the game really begins", trTR = "Seviye 60: oyun şimdi başlıyor" },
    text = { enUS = "Congratulations. Now the goals are better gear from dungeons, reputation, your epic mount, and eventually raids with a guild. Run the max-level dungeons, finish quest chains you skipped, and make sure your professions are maxed.",
             trTR = "Tebrikler. Artık hedefler zindanlardan daha iyi eşya, reputasyon, epik binek ve sonunda bir lonca ile raid'ler. Üst seviye zindanları koş, atladığın görev zincirlerini bitir ve mesleklerinin maksimumda olduğundan emin ol." } },

  { id = "quest-colors", cat = "leveling", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Quest and mob colors tell difficulty", trTR = "Görev ve yaratık renkleri zorluğu gösterir" },
    text = { enUS = "Gray mobs are trivial and give no XP, green mobs are easy, yellow mobs are your level, orange mobs are hard and red mobs will probably kill you. Fighting mobs 1 to 3 levels below you is the fastest way to level solo.",
             trTR = "Gri yaratıklar önemsizdir ve XP vermez, yeşil kolay, sarı senin seviyende, turuncu zor, kırmızı ise büyük ihtimalle seni öldürür. Solo seviye atlamanın en hızlı yolu senden 1-3 seviye düşük yaratıklarla savaşmaktır." } },

  { id = "elite-quests", cat = "leveling", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Elite and group quests need a group", trTR = "Elite ve grup görevleri grup ister" },
    text = { enUS = "Quests marked Group or Elite involve monsters with a golden dragon around their portrait; they have far more health and deal far more damage than normal. Do not try them alone at your level. Ask in zone chat, or save them until you outlevel them by 5 or more.",
             trTR = "Group veya Elite olarak işaretli görevlerde, portresinin etrafında altın ejderha olan yaratıklar bulunur; bunların canı ve hasarı normalden çok daha fazladır. Seviyendeyken tek başına deneme. Bölge sohbetinde sor veya onları 5 veya daha fazla seviye geçene kadar beklet." } },

  { id = "turn-in-batches", cat = "leveling", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Pick up every quest in a hub first", trTR = "Önce bir merkezdeki tüm görevleri al" },
    text = { enUS = "Collect all the quests in a town before heading out, then do them in one loop and turn them in together. Running back and forth for single quests is the biggest time waster at low level.",
             trTR = "Yola çıkmadan önce kasabadaki tüm görevleri topla, sonra hepsini tek bir turda yap ve birlikte teslim et. Tek tek görev için gidip gelmek düşük seviyede en büyük zaman kaybıdır." } },

  { id = "dungeon-levels", cat = "leveling", min = 13, max = 60, class = nil, trigger = "firstdungeonlevel",
    title = { enUS = "Your first dungeons", trTR = "İlk zindanların" },
    text = { enUS = "Low-level dungeons: Ragefire Chasm (13-18, Horde), The Deadmines (17-24, Alliance), Wailing Caverns (17-24), Shadowfang Keep (22-30), Blackfathom Deeps (24-32), The Stockade (22-30, Alliance). Dungeon quests give great gear; pick them up outside before you go in.",
             trTR = "Düşük seviye zindanlar: Ragefire Chasm (13-18, Horde), The Deadmines (17-24, Alliance), Wailing Caverns (17-24), Shadowfang Keep (22-30), Blackfathom Deeps (24-32), The Stockade (22-30, Alliance). Zindan görevleri çok iyi eşya verir; girmeden önce dışarıdan al." } },

  { id = "mid-dungeons", cat = "leveling", min = 28, max = 60, class = nil, trigger = nil,
    title = { enUS = "Mid-level dungeons", trTR = "Orta seviye zindanlar" },
    text = { enUS = "Gnomeregan (29-38), Razorfen Kraul (29-38), Scarlet Monastery (34-45, four wings), Razorfen Downs (37-46), Uldaman (41-51), Zul'Farrak (44-54), Maraudon (46-55). Scarlet Monastery is a favorite of many players for its gear and XP.",
             trTR = "Gnomeregan (29-38), Razorfen Kraul (29-38), Scarlet Monastery (34-45, dört kanat), Razorfen Downs (37-46), Uldaman (41-51), Zul'Farrak (44-54), Maraudon (46-55). Scarlet Monastery, eşyaları ve XP'si yüzünden birçok oyuncunun favorisidir." } },

  { id = "high-dungeons", cat = "leveling", min = 48, max = 60, class = nil, trigger = nil,
    title = { enUS = "High-level dungeons", trTR = "Yüksek seviye zindanlar" },
    text = { enUS = "Sunken Temple (50-56), Blackrock Depths (52-60), Dire Maul (55-60), Lower and Upper Blackrock Spire (55-60), Stratholme and Scholomance (58-60). Blackrock Depths is huge and has many quests; it is worth several visits.",
             trTR = "Sunken Temple (50-56), Blackrock Depths (52-60), Dire Maul (55-60), Lower ve Upper Blackrock Spire (55-60), Stratholme ve Scholomance (58-60). Blackrock Depths çok büyüktür ve çok sayıda görevi vardır; birkaç kez gitmeye değer." } },

  { id = "zone-hopping", cat = "leveling", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Move on when quests turn green", trTR = "Görevler yeşile dönünce bölge değiştir" },
    text = { enUS = "When most quests in a zone are green or gray, move on to a zone that matches your level; a guard or the map can point you there. There are usually two zones per level range, and you can use either.",
             trTR = "Bir bölgedeki görevlerin çoğu yeşil veya gri olduğunda seviyene uygun bir bölgeye geç; muhafız veya harita sana yol gösterir. Genelde her seviye aralığı için iki bölge vardır ve ikisini de kullanabilirsin." } },

  { id = "riding-cost", cat = "leveling", min = 25, max = 40, class = nil, trigger = nil,
    title = { enUS = "Start saving for your mount now", trTR = "Bineğin için şimdiden biriktir" },
    text = { enUS = "At level 40, Riding costs 100 gold with your first mount included, a huge amount for a new player. From now on, sell everything you do not use on the Auction House, do not buy gear upgrades you will outlevel in a few hours, and gather materials while you quest.",
             trTR = "40. seviyede Riding 100 altındır ve ilk binek bu fiyata dahildir; yeni bir oyuncu için büyük bir miktar. Bundan sonra kullanmadığın her şeyi Auction House'ta sat, birkaç saatte geçeceğin eşyaları alma ve görev yaparken malzeme topla." } },

  { id = "legacy-first-point", cat = "leveling", min = 25, max = 25, class = nil, trigger = "level",
    title = { enUS = "Level 25: your first Legacy point", trTR = "Seviye 25: ilk Legacy puanın" },
    text = { enUS = "Reaching 25 with a class for the first time earns a Legacy point for your whole account. Press Y to open Legacy and spend it; each character picks its own perks, up to 16 points. Levels 45 and 60 on each class give more.",
             trTR = "Bir sınıfla ilk kez 25'e ulaşmak bütün hesabına bir Legacy puanı kazandırır. Legacy'yi açmak için Y'ye bas ve puanı harca; her karakter kendi perk'lerini seçer, en fazla 16 puan. Her sınıfta 45 ve 60. seviyeler daha fazla puan verir." } },

  { id = "legacy-leveling-perks", cat = "leveling", min = 25, max = 60, class = nil, trigger = nil,
    title = { enUS = "Legacy perks that speed up leveling", trTR = "Seviye atlamayı hızlandıran Legacy perk'leri" },
    text = { enUS = "For leveling, Well Rested (more and faster Rested XP) and Thrill of Adventure (health and mana back on kills) are open from the start. Talented starts your talent points before level 10, and Frequent Flier halves flight costs later. Class trainers in the capitals can reset your Legacy points.",
             trTR = "Seviye atlamak için Well Rested (daha çok ve daha hızlı Rested XP) ve Thrill of Adventure (öldürünce can ve mana geri gelir) baştan açıktır. Talented talent puanlarını 10. seviyeden önce başlatır, Frequent Flier ise ileride uçuş ücretlerini yarıya indirir. Başkentlerdeki sınıf trainer'ları Legacy puanlarını sıfırlayabilir." } },

  { id = "cozy-sleeping-bag", cat = "leveling", min = 14, max = 40, class = nil, trigger = nil,
    title = { enUS = "Cozy Sleeping Bag: extra XP for an hour", trTR = "Cozy Sleeping Bag: bir saat ek XP" },
    text = { enUS = "From level 14 you can follow a six-step chain with no quest giver, starting from items left in Westfall or the Barrens. Its Cozy Sleeping Bag gives up to 3% more XP for an hour after you lie in it for a few minutes, and you are rested while inside.",
             trTR = "14. seviyeden itibaren, Westfall veya Barrens'ta bırakılmış eşyalarla başlayan, görev vereni olmayan altı adımlık bir zincir yapabilirsin. Ödülü Cozy Sleeping Bag, içinde birkaç dakika yatınca bir saat boyunca %3'e kadar ek XP verir; içindeyken de dinlenmiş sayılırsın." } },

  { id = "no-flying", cat = "leveling", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "No flying mounts in Forever", trTR = "Forever'da uçan binek yok" },
    text = { enUS = "Forever has no flying mounts and no level scaling, so plan your routes on the ground: flight paths, boats, zeppelins and your mount. New ship routes link more places, such as Tanaris and Riverglades.",
             trTR = "Forever'da uçan binek ve seviye ölçekleme yok; rotalarını yerde planla: uçuş noktaları, gemiler, zeplinler ve bineğin. Yeni gemi hatları daha çok yeri birbirine bağlar, örneğin Tanaris ile Riverglades'i." } },

  { id = "epic-riding", cat = "gold", min = 50, max = 60, class = nil, trigger = nil,
    title = { enUS = "Save 1,000 gold for level 60 riding", trTR = "60. seviye Riding için 1.000 altın biriktir" },
    text = { enUS = "At level 60, the faster Riding skill costs 1,000 gold, and a new mount is included as at level 40. Extra mounts at that level cost around 200 gold. Start putting gold aside from level 50.",
             trTR = "60. seviyede daha hızlı Riding becerisi 1.000 altın tutar ve 40. seviyedeki gibi yeni bir binek de dahildir. O seviyede ek binekler 200 altın civarındadır. 50. seviyeden itibaren altın ayırmaya başla." } },

  -- ===================== COMBAT =====================
  { id = "pulling", cat = "combat", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Pull one mob at a time", trTR = "Yaratıkları teker teker çek" },
    text = { enUS = "Most deaths come from fighting more than one enemy. Use a ranged ability or a wand to pull a single mob away from its friends and back to you, and check for patrols before you engage. Nearby mobs with social behavior (humanoids especially) will join the fight together.",
             trTR = "Ölümlerin çoğu birden fazla düşmanla savaşmaktan gelir. Tek bir yaratığı menzilli bir yetenek veya wand ile arkadaşlarından uzağa, kendine çek ve saldırmadan önce devriye gezenleri kontrol et. Yakındaki sosyal yaratıklar (özellikle insansılar) savaşa birlikte katılır." } },

  { id = "aggro-radius", cat = "combat", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Aggro range depends on level", trTR = "Aggro menzili seviyeye bağlıdır" },
    text = { enUS = "Mobs attack you when you get close. The higher their level is compared to yours, the farther away they notice you. Mobs more than 10 levels below you ignore you completely. Walk around groups of mobs, not through them.",
             trTR = "Yaratıklar yaklaştığında saldırır; seviyeleri seninkine göre ne kadar yüksekse seni o kadar uzaktan fark ederler. Senden 10 seviyeden fazla düşük yaratıklar seni tamamen görmezden gelir. Yaratık gruplarının içinden değil, etrafından dolaş." } },

  { id = "running-away", cat = "combat", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Know when to run", trTR = "Ne zaman kaçacağını bil" },
    text = { enUS = "If a fight goes badly, run toward guards, a town or different terrain; mobs give up the chase after you get far enough and reset. Running does not work against mobs that are much faster than you or have ranged attacks, so decide early. Dying costs only time and durability.",
             trTR = "Savaş kötü giderse muhafızlara, kasabaya veya farklı bir araziye doğru kaç; yaratıklar yeterince uzaklaştığında kovalamayı bırakıp sıfırlanır. Senden çok hızlı veya menzilli saldırısı olan yaratıklara karşı kaçmak işe yaramaz, bu yüzden erken karar ver. Ölmek sadece zamana ve dayanıklılığa mal olur." } },

  { id = "threat-groups", cat = "combat", min = 13, max = 60, class = nil, trigger = nil,
    title = { enUS = "Threat: let the tank go first", trTR = "Threat: önce tank saldırsın" },
    text = { enUS = "In a group, mobs attack whoever has built the most threat (through damage or healing). Give the tank a few seconds to build threat before you attack, and attack the tank's target, not a random mob. If you pull aggro, stop attacking and run toward the tank.",
             trTR = "Grupta yaratıklar en çok threat (hasar veya iyileştirme yoluyla) üretene saldırır. Saldırmadan önce tank'a threat kurması için birkaç saniye ver ve rastgele bir yaratığa değil, tank'ın hedefine saldır. Aggro çekersen saldırmayı bırak ve tank'a doğru koş." } },

  { id = "roles", cat = "combat", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "The three roles: tank, healer, DPS", trTR = "Üç rol: tank, healer, DPS" },
    text = { enUS = "Tanks (mainly Warriors, also bear Druids and Paladins) hold the enemy's attention. Healers (Priests, Druids, Shamans, Paladins) keep everyone alive. Everyone else deals damage. Say your role when you join a group; tanks and healers are always in short supply.",
             trTR = "Tank'lar (çoğunlukla Warrior, ayrıca bear Druid ve Paladin) düşmanın dikkatini üzerinde tutar. Healer'lar (Priest, Druid, Shaman, Paladin) herkesi hayatta tutar. Diğer herkes hasar verir. Gruba katılırken rolünü söyle; tank ve healer her zaman azdır." } },

  { id = "crowd-control", cat = "combat", min = 15, max = 60, class = nil, trigger = nil,
    title = { enUS = "Do not break crowd control", trTR = "Crowd control'ü bozma" },
    text = { enUS = "Mages use Polymorph, Rogues use Sap, Priests use Shackle Undead and Hunters use Freezing Trap. A controlled mob breaks free the moment it takes damage, so never attack a polymorphed or trapped target. Use the skull and cross marks on targets to agree on the kill order.",
             trTR = "Mage'ler Polymorph, Rogue'lar Sap, Priest'ler Shackle Undead, Hunter'lar Freezing Trap kullanır. Kontrol altındaki yaratık hasar aldığı anda kurtulur; Polymorph'lanmış veya tuzağa düşmüş hedefe asla saldırma. Öldürme sırasını belirlemek için hedeflerdeki kuru kafa ve çarpı işaretlerini kullan." } },

  { id = "stat-priority", cat = "combat", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Which stats matter for you", trTR = "Hangi statlar senin için önemli" },
    text = { enUS = "Strength for Warriors, Paladins and melee Shamans; Agility for Rogues, Hunters and cat Druids; Intellect and Spirit for Mages, Priests, Warlocks and caster Druids and Shamans. Stamina is good for everyone. Avoid gear with stats your class never uses.",
             trTR = "Warrior, Paladin ve yakın dövüş Shaman'lar için Strength; Rogue, Hunter ve cat Druid'ler için Agility; Mage, Priest, Warlock ile büyücü Druid ve Shaman'lar için Intellect ve Spirit. Stamina herkese iyi gelir. Sınıfının hiç kullanmadığı statlara sahip eşyalardan kaçın." } },

  { id = "first-aid-value", cat = "combat", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "First Aid saves your life", trTR = "First Aid hayatını kurtarır" },
    text = { enUS = "First Aid is a secondary skill that everyone can learn alongside their two main professions. Bandages heal a lot over several seconds and cost only cloth you already loot. For classes without heals, it cuts the downtime between fights a lot.",
             trTR = "First Aid, iki ana mesleğin yanında herkesin öğrenebileceği ikincil bir yetenektir. Bandajlar birkaç saniyede çok iyileştirir ve sadece zaten topladığın kumaşa mal olur. İyileştirmesi olmayan sınıflarda dövüşler arasındaki bekleme süresini ciddi şekilde azaltır." } },

  { id = "pvp-flag", cat = "combat", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "PvP flag and contested zones", trTR = "PvP bayrağı ve çekişmeli bölgeler" },
    text = { enUS = "On PvP realms, the other faction can attack you in contested zones from your early 20s. On PvE realms you only become attackable if you attack a flagged player or an enemy guard. Type /pvp to toggle your flag; it stays on for 5 minutes after your last hostile action.",
             trTR = "PvP sunucularında 20'li seviyelerin başından itibaren çekişmeli bölgelerde karşı taraf sana saldırabilir. PvE sunucularında yalnızca bayraklı bir oyuncuya veya düşman muhafıza saldırırsan saldırılabilir olursun. Bayrağı açıp kapatmak için /pvp yaz; son düşmanca hareketinden sonra 5 dakika açık kalır." } },

  -- ===================== GEAR =====================
  { id = "armor-types", cat = "gear", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Wear the heaviest armor you can", trTR = "Giyebildiğin en ağır zırhı giy" },
    text = { enUS = "Cloth: Mage, Priest, Warlock. Leather: Rogue, Druid, and Hunters and Shamans until 40. Mail: Hunters and Shamans from 40, Warriors and Paladins until 40. Plate: Warriors and Paladins from 40. Heavier armor reduces physical damage, but the stats on the item matter more.",
             trTR = "Cloth: Mage, Priest, Warlock. Leather: Rogue, Druid ve 40. seviyeye kadar Hunter ile Shaman. Mail: 40. seviyeden itibaren Hunter ve Shaman, 40. seviyeye kadar Warrior ve Paladin. Plate: 40. seviyeden itibaren Warrior ve Paladin. Ağır zırh fiziksel hasarı azaltır ama eşyadaki statlar daha önemlidir." } },

  { id = "soulbound-boe", cat = "gear", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Soulbound vs Bind on Equip", trTR = "Soulbound ve Bind on Equip farkı" },
    text = { enUS = "Items marked Soulbound are bound to your character forever and can only be sold to vendors. Bind on Equip items can be traded until you wear them, so a green item you do not need is worth money on the Auction House. Bind on Pickup items bind the moment you loot them.",
             trTR = "Soulbound yazan eşyalar sonsuza dek karakterine bağlıdır ve sadece satıcıya satılabilir. Bind on Equip eşyalar sen giyene kadar takas edilebilir; ihtiyacın olmayan bir yeşil eşya Auction House'ta para eder. Bind on Pickup eşyalar aldığın anda bağlanır." } },

  { id = "quest-rewards", cat = "gear", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Quest rewards are your main upgrades", trTR = "Görev ödülleri asıl eşya kaynağındır" },
    text = { enUS = "Most of your gear while leveling comes from quests. When a quest offers a choice, pick the item with stats for your class; if none fits, take the one that sells for the most money. Compare items by holding Shift while hovering over them.",
             trTR = "Seviye atlarken eşyalarının çoğu görevlerden gelir. Bir görev seçim sunduğunda sınıfına uygun statlara sahip eşyayı al; hiçbiri uymuyorsa satıcıya en pahalıya gideni seç. Eşyaları karşılaştırmak için üzerine gelirken Shift'e bas." } },

  { id = "when-to-buy", cat = "gear", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "When buying gear is worth it", trTR = "Eşya almak ne zaman mantıklı" },
    text = { enUS = "Buying armor from the Auction House while leveling is rarely worth it; you replace it within a few levels. The one exception is your weapon: a good weapon upgrade for a melee class or Hunter speeds up every fight and is worth a few gold.",
             trTR = "Seviye atlarken Auction House'tan zırh almak nadiren değer; birkaç seviyede değişir. Tek istisna silahın: yakın dövüş sınıfı veya Hunter için iyi bir silah yükseltmesi her savaşı hızlandırır ve birkaç altına değer." } },

  { id = "item-colors", cat = "gear", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Item quality colors", trTR = "Eşya kalite renkleri" },
    text = { enUS = "Gray is junk, white is common, green is uncommon and has stats, blue is rare (dungeons and hard quests), purple is epic (raids and rare drops). A higher level green item often beats a lower level blue one; always read the stats rather than trusting the color.",
             trTR = "Gri çöp, beyaz common, yeşil statlı uncommon, mavi rare (zindanlar ve zor görevler), mor epic (raid'ler ve nadir düşenler). Yüksek seviyeli bir yeşil, düşük seviyeli bir maviden çoğu zaman iyidir; renge güvenmek yerine her zaman statlara bak." } },

  { id = "dual-wield", cat = "gear", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Dual wield and two-handers", trTR = "Çift silah ve iki elli silahlar" },
    text = { enUS = "Rogues dual wield from level 10. Warriors and Hunters learn Dual Wield from their trainer at level 20. Enhancement Shamans get it much later through talents. Leveling Warriors and Shamans usually do better with a slow two-handed weapon.",
             trTR = "Rogue'lar 10. seviyeden itibaren çift silah kullanır. Warrior'lar ve Hunter'lar Dual Wield'ı 20. seviyede trainer'dan öğrenir. Enhancement Shaman'lar bunu çok daha sonra talent ile alır. Seviye atlayan Warrior ve Shaman'lar genelde yavaş iki elli bir silahla daha iyi gider." } },

  { id = "enchant-weapon", cat = "gear", min = 20, max = 60, class = nil, trigger = nil,
    title = { enUS = "Cheap enchants are worth it on long-lived items", trTR = "Uzun süre kullanacağın eşyalara ucuz enchant yaptırmaya değer" },
    text = { enUS = "Enchanters can add stats to your gear. While leveling, enchant only items you will keep for a long time, like a good weapon. Ask in a capital or in trade chat; most enchanters work for the materials plus a tip.",
             trTR = "Enchanter'lar eşyanın stat'larını artırabilir. Seviye atlarken yalnızca iyi bir silah gibi uzun süre kullanacağın eşyalara enchant yaptır. Başkentte veya trade sohbetinde sor; çoğu enchanter malzeme artı bahşiş karşılığı çalışır." } },

  -- ===================== GOLD =====================
  { id = "gold-no-buying", cat = "gold", min = 1, max = 30, class = nil, trigger = nil,
    title = { enUS = "Gold rule one: do not spend early", trTR = "Altın kuralı bir: başta harcama yapma" },
    text = { enUS = "Before level 40, your gold has only three good uses: spells from the trainer, bags and food. Skip optional spell ranks, do not buy armor, and sell everything you do not need. The mount at level 40 is your first big goal.",
             trTR = "40. seviyeden önce altının yalnızca üç iyi kullanımı var: trainer'dan büyüler, çantalar ve yiyecek. İsteğe bağlı büyü rank'larını atla, zırh alma ve ihtiyacın olmayan her şeyi sat. 40. seviyedeki binek ilk büyük hedefin." } },

  { id = "gold-gathering", cat = "gold", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Gathering professions pay while you level", trTR = "Toplama meslekleri seviye atlarken para kazandırır" },
    text = { enUS = "Mining, Herbalism and Skinning earn money from things you walk past anyway. Raw materials sell steadily on the Auction House because crafters need them to level. Two gathering professions are the easiest way to afford your mount.",
             trTR = "Mining, Herbalism ve Skinning, zaten yanından geçtiğin şeylerden para kazandırır. Ham malzemeler Auction House'ta sürekli satılır, çünkü zanaatkârlar seviye atlamak için bunlara ihtiyaç duyar. İki toplama mesleği, bineğini almanın en kolay yoludur." } },

  { id = "gold-cloth", cat = "gold", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Never vendor cloth", trTR = "Kumaşı asla satıcıya satma" },
    text = { enUS = "Linen, Wool, Silk, Mageweave and Runecloth drop from humanoids and are always in demand for Tailoring, First Aid and reputation. Sell full stacks on the Auction House or keep them for your own First Aid.",
             trTR = "Linen, Wool, Silk, Mageweave ve Runecloth insansılardan düşer; Tailoring, First Aid ve reputasyon için her zaman talep görür. Dolu desteleri Auction House'ta sat veya kendi First Aid'in için sakla." } },

  { id = "gold-scams", cat = "gold", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Scams: Blizzard never whispers you", trTR = "Dolandırıcılık: Blizzard sana whisper atmaz" },
    text = { enUS = "Never share your password or click links sent in whispers. Game masters never ask for your login. Do not accept trades for 'free gold' that ask you to put up an item first, and check the trade window twice before accepting. Report spammers and move on.",
             trTR = "Şifreni asla paylaşma ve whisper ile gelen linklere tıklama. Game master'lar asla giriş bilgilerini sormaz. Önce senin eşya koymanı isteyen 'bedava altın' takaslarını kabul etme ve takas penceresini onaylamadan önce iki kez kontrol et. Spam yapanları bildir ve devam et." } },

  { id = "gold-ah-pricing", cat = "gold", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Pricing on the Auction House", trTR = "Auction House'ta fiyatlandırma" },
    text = { enUS = "Search for the item before you list it and price it slightly under the cheapest current buyout. Weekend evenings have the most buyers. Always set a buyout price; most players never bid. Undercutting by a lot only loses you money.",
             trTR = "Listelemeden önce eşyayı ara ve fiyatını mevcut en ucuz buyout'un biraz altına koy. En çok alıcı hafta sonu akşamları olur. Her zaman bir buyout fiyatı koy; çoğu oyuncu teklif vermez. Fiyatı çok fazla kırmak sadece para kaybettirir." } },

  { id = "gold-vendor-recipes", cat = "gold", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Limited-supply vendor items", trTR = "Sınırlı stoklu satıcı eşyaları" },
    text = { enUS = "Some vendors sell recipes and patterns in limited quantity (shown with a count). These often resell on the Auction House for several times the vendor price. If you see one for a few silver, it is usually worth grabbing.",
             trTR = "Bazı satıcılar tarif ve desenleri sınırlı miktarda satar (adet gösterilir). Bunlar Auction House'ta çoğu zaman satıcı fiyatının birkaç katına gider. Birkaç gümüşe bir tane görürsen genelde almaya değer." } },

  { id = "gold-loot-everything", cat = "gold", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Loot every kill, turn on auto loot", trTR = "Her öldürdüğünü yağmala, Auto Loot'u aç" },
    text = { enUS = "Enable Auto Loot in the Interface options so a single click takes everything. Gray items from 20 kills add up to real silver at low level. Skin beasts if you have Skinning; the leather sells well.",
             trTR = "Tek tıkla her şeyi almak için Interface ayarlarından Auto Loot'u aç. Düşük seviyede 20 yaratıktan düşen gri eşyalar ciddi gümüş eder. Skinning'in varsa hayvanların derisini yüz; deri iyi satılır." } },

  -- ===================== PROFESSIONS =====================
  { id = "prof-choose", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Choosing your two professions", trTR = "İki mesleğini seçmek" },
    text = { enUS = "You get two primary professions. For a first character, two gathering professions (Mining plus Skinning, or Herbalism plus Skinning) give the most gold with no cost. Crafting professions are expensive to level and mostly pay off at max level.",
             trTR = "İlk karakter için iki toplama mesleği (Mining ile Skinning veya Herbalism ile Skinning) hiçbir maliyet olmadan en çok altını kazandırır. Crafting mesleklerini yükseltmek pahalıdır ve çoğunlukla maksimum seviyede karşılığını verir." } },

  { id = "prof-secondary", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "First Aid, Cooking and Fishing are free extras", trTR = "First Aid, Cooking ve Fishing ücretsiz ekstralardır" },
    text = { enUS = "Secondary professions do not take a profession slot; everyone can learn all three. First Aid is nearly mandatory, Cooking turns meat you loot into useful buff food, and Fishing is a slow but steady gold source. Trainers are in every capital.",
             trTR = "İkincil meslekler meslek slotu kaplamaz; herkes üçünü de öğrenebilir. First Aid neredeyse zorunludur, Cooking yağmaladığın etleri işe yarar buff yemeğine çevirir, Fishing ise yavaş ama istikrarlı bir altın kaynağıdır. Trainer'lar her başkentte bulunur." } },

  { id = "prof-level-with-you", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Level professions as you go", trTR = "Meslekleri ilerledikçe yükselt" },
    text = { enUS = "Gather nodes in every zone you quest in. You start as Apprentice; at 50, 125 and 200 skill you learn Journeyman, Expert and Artisan from a trainer (at character level 10, 20 and 35). Nodes too high for your skill show red on the tooltip. If you fall behind, you must go back to low zones later.",
             trTR = "Görev yaptığın her bölgede kaynak topla. Apprentice olarak başlarsın; 50, 125 ve 200 skill'de trainer'dan sırasıyla Journeyman, Expert ve Artisan'ı öğrenirsin (karakter seviyesi 10, 20 ve 35 olmalı). Skill'in için fazla yüksek kaynaklar ipucunda kırmızı görünür. Geri kalırsan sonra düşük seviyeli bölgelere dönmen gerekir." } },

  { id = "prof-tailoring-bags", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Tailoring makes bags for everyone", trTR = "Tailoring herkese çanta yapar" },
    text = { enUS = "Tailoring needs no gathering profession, just cloth from humanoids. It makes bags, which every player and every alt needs, and cloth armor for casters. Pair it with Enchanting to disenchant what you craft.",
             trTR = "Tailoring bir toplama mesleği gerektirmez, sadece insansılardan düşen kumaş yeter. Her oyuncunun ve her alt karakterin ihtiyaç duyduğu çantaları ve caster'lar için cloth zırh yapar. Yaptıklarını disenchant etmek için Enchanting ile eşleştir." } },

  { id = "prof-engineering", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Engineering: fun gadgets, costly to level", trTR = "Engineering: eğlenceli aletler, yükseltmesi pahalı" },
    text = { enUS = "Engineering gives you bombs, goggles and, later, useful trinkets, and it is loved in PvP. It pairs with Mining and eats a lot of ore, so it is slow and expensive while leveling. Pick it for fun, not for gold.",
             trTR = "Engineering sana bombalar, gözlükler ve ileride faydalı trinket'ler verir; PvP'de çok sevilir. Mining ile eşleşir ve çok ore tüketir, bu yüzden seviye atlarken yavaş ve pahalıdır. Altın için değil, eğlence için seç." } },

  { id = "prof-skinning", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Skinning: gold from every beast", trTR = "Skinning: her hayvandan altın" },
    text = { enUS = "Skinning requires a Skinning Knife (from a vendor) and lets you skin beasts after looting them. It levels naturally while you kill, and leather sells well to Leatherworkers. Hunters and Druids who kill many beasts benefit the most.",
             trTR = "Skinning için bir Skinning Knife (satıcıdan alınır) gerekir; hayvanları yağmaladıktan sonra derilerini yüzmeni sağlar. Öldürdükçe kendiliğinden yükselir ve deri Leatherworker'lara iyi satılır. Çok hayvan öldüren Hunter ve Druid'ler en çok yararlanır." } },

  { id = "prof-unlearn", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "You can unlearn a profession", trTR = "Bir mesleği bırakabilirsin" },
    text = { enUS = "If you regret a profession, open the skills window and click the small unlearn icon next to it. You lose all progress, so decide early. Unlearning costs nothing; you only have to learn it again from scratch.",
             trTR = "Bir mesleğe pişman olursan Skills penceresini aç ve yanındaki küçük unlearn simgesine tıkla. Tüm ilerlemeni kaybedersin, o yüzden erken karar ver. Bırakmanın bir bedeli yok; sadece mesleği sıfırdan yeniden öğrenmen gerekir." } },

  { id = "prof-legacy-points", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Crafting skill earns Legacy points", trTR = "Crafting becerisi Legacy puanı kazandırır" },
    text = { enUS = "Reaching 150, 225 and 300 in Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking or Tailoring each gives a Legacy point. Gathering professions, Cooking, Fishing and First Aid give none, so a crafting profession also pays off for your account.",
             trTR = "Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking veya Tailoring'de 150, 225 ve 300'e ulaşmak her biri bir Legacy puanı verir. Toplama meslekleri, Cooking, Fishing ve First Aid puan vermez; yani bir crafting mesleği hesabına da kazandırır." } },

  { id = "prof-camping", cat = "professions", min = 10, max = 60, class = nil, trigger = nil,
    title = { enUS = "Camping: your professions build the camp", trTR = "Camping: kampı meslekler kurar" },
    text = { enUS = "In the open world you can set up a camp. Each profession unlocks a camp object at 20 skill and upgrades it at 140 and 300; the upgrade replaces the old object and keeps its buff. Camp objects give buffs to everyone resting there, and they share a cooldown.",
             trTR = "Açık dünyada kamp kurabilirsin. Her meslek 20 beceride bir kamp nesnesi açar, 140 ve 300'de onu yükseltir; yükseltme eski nesnenin yerine geçer ve buff'ını korur. Kamp nesneleri orada dinlenen herkese buff verir ve ortak bir bekleme süresi paylaşır." } },

  -- go: taraf basina kamp (kart "Arrow" dugmesi); iki yerel kaynakta ayni yer, oyunda dogrulanmadi
  { id = "prof-merchants-favor", cat = "professions", min = 10, max = 60, class = nil, trigger = nil,
    go = { Alliance = { npc = "Tamelyn Aldridge", zone = "Redridge Mountains", x = 10.4, y = 71.0 },
           Horde = { npc = "Dokimi", zone = "The Barrens", x = 50.1, y = 29.4 } },
    title = { enUS = "Waylaid Crates and Merchant's Favor", trTR = "Waylaid Crate'ler ve Merchant's Favor" },
    text = { enUS = "From level 10 you can find Waylaid Crates in the world. Fill one with a bundle of gathered or crafted goods of its rank and deliver it to your faction's trade camp (Three Corners in Redridge, or near the Crossroads). The Merchant's Favor you earn buys patterns that are sold nowhere else.",
             trTR = "10. seviyeden itibaren dünyada Waylaid Crate bulabilirsin. Birini, rütbesine uygun bir deste toplama veya üretim malzemesiyle doldur ve faction'ının ticaret kampına götür (Redridge'deki Three Corners ya da Crossroads yakını). Kazandığın Merchant's Favor ile başka hiçbir yerde satılmayan tarifler alırsın." } },

  { id = "prof-forever-recipes", cat = "professions", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Old profession guides are out of date", trTR = "Eski meslek rehberleri güncel değil" },
    text = { enUS = "In Forever many Tailoring, Blacksmithing and Leatherworking recipes turn grey 25 to 35 points sooner than in Classic, so trust the recipe colour in your window, not an old guide. First Aid now makes Healing Potions too, while Alchemy makes its own Discolored Healing Potions.",
             trTR = "Forever'da birçok Tailoring, Blacksmithing ve Leatherworking tarifi Classic'e göre 25-35 puan erken griye döner; eski rehbere değil penceredeki tarif rengine güven. Artık First Aid de Healing Potion yapar; Alchemy ise kendi Discolored Healing Potion'larını yapar." } },

  -- ===================== SOCIAL =====================
  { id = "loot-need-greed", cat = "social", min = 13, max = 60, class = nil, trigger = nil,
    title = { enUS = "Need or Greed?", trTR = "Need mi Greed mi?" },
    text = { enUS = "In groups, roll Need only on items you will actually equip right now for your main role. Greed means you want it to sell or disenchant. Rolling Need on something you cannot use is the fastest way to get kicked and blacklisted on your realm.",
             trTR = "Gruplarda yalnızca ana rolün için şu an gerçekten kuşanacağın eşyalara Need at. Greed, eşyayı satmak veya disenchant etmek istediğin anlamına gelir. Kullanamayacağın bir eşyaya Need atmak, gruptan atılmanın ve sunucuda kara listeye girmenin en hızlı yoludur." } },

  { id = "guild-join", cat = "social", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Join a guild early", trTR = "Erken bir loncaya katıl" },
    text = { enUS = "A guild gives you people to ask questions, group with and, later, raid with. A leveling-friendly guild is better than a hardcore one for a new player. If a guild feels wrong, type /gquit and find another; there is no penalty.",
             trTR = "Lonca sana soru sorabileceğin, grup kurabileceğin ve ileride raid yapabileceğin insanlar kazandırır. Yeni bir oyuncu için seviye atlamaya uygun bir lonca, hardcore bir loncadan daha iyidir. Lonca sana uymuyorsa /gquit yaz ve başka birini bul; cezası yok." } },

  { id = "lfg-etiquette", cat = "social", min = 13, max = 60, class = nil, trigger = nil,
    title = { enUS = "Finding and keeping a group", trTR = "Grup bulmak ve grupta kalmak" },
    text = { enUS = "Ask in the LookingForGroup channel or in a city, giving your role, level and the dungeon name. When you join, say hello, ask about anything you do not know, and do not leave after one wipe. Being honest that you are new goes a long way with most people.",
             trTR = "Rolünü, seviyeni ve zindan adını yazarak LookingForGroup kanalında veya şehirde sor. Gruba katılınca selam ver, bilmediğin şeyleri sor ve tek bir wipe'tan sonra ayrılma. Yeni olduğunu dürüstçe söylemek çoğu insanda iyi karşılık bulur." } },

  { id = "chat-channels", cat = "social", min = 1, max = 60, class = nil, trigger = nil,
    title = { enUS = "Chat basics", trTR = "Sohbet temelleri" },
    text = { enUS = "/s says to nearby players, /p is party, /g is guild, /1 is the General channel of your zone, /w Name whispers someone, and /r replies to the last whisper. Trade chat only works in cities. Use /who to see who is online in a zone or level range.",
             trTR = "/s yakındaki oyunculara, /p gruba, /g loncaya, /1 bölgenin General kanalına yazar; /w İsim birine whisper atar, /r son whisper'a cevap verir. Trade sohbeti yalnızca şehirlerde çalışır. Bir bölgede veya seviye aralığında kimlerin çevrimiçi olduğunu görmek için /who kullan." } },

  { id = "reputation", cat = "social", min = 20, max = 60, class = nil, trigger = nil,
    title = { enUS = "Reputation unlocks rewards", trTR = "Reputasyon ödülleri açar" },
    text = { enUS = "Every quest raises reputation with its faction. At Honored and Revered, faction vendors sell useful items and recipes. Turning in cloth to city quartermasters also raises city reputation, which lets you buy other races' mounts at Exalted.",
             trTR = "Her görev kendi fraksiyonunun reputasyonunu artırır; Honored ve Revered'de fraksiyon satıcıları faydalı eşya ve tarif satar. Şehir quartermaster'larına kumaş teslim etmek de şehir reputasyonunu artırır; Exalted'da diğer ırkların bineklerini alabilirsin." } },

  { id = "share-quests", cat = "social", min = 5, max = 60, class = nil, trigger = nil,
    title = { enUS = "Share quests with your party", trTR = "Görevleri grubunla paylaş" },
    text = { enUS = "In your quest log, click Share Quest to give a quest to party members who have not picked it up yet, as long as they are nearby. Kills and most quest items count for everyone in the party, so questing together is much faster.",
             trTR = "Görev günlüğünde Share Quest'e tıklayarak yakındaki ve görevi henüz almamış grup üyelerine görevi verebilirsin. Öldürmeler ve çoğu görev eşyası gruptaki herkes için sayılır, bu yüzden birlikte görev yapmak çok daha hızlıdır." } },

  -- ===================== CLASS: HUNTER =====================
  { id = "hunter-pet", cat = "class", min = 10, max = 60, class = "HUNTER", trigger = nil,
    title = { enUS = "Hunter: tame a pet at level 10", trTR = "Hunter: 10. seviyede bir pet evcilleştir" },
    text = { enUS = "At level 10, your trainer gives you the pet quest chain; finish it to learn Tame Beast. Your pet is your tank: send it in first, then shoot. Your pet's level never exceeds yours, and a pet more than 5 levels below you takes a while to catch up.",
             trTR = "10. seviyede trainer'ın sana pet görev zincirini verir; Tame Beast'i öğrenmek için bitir. Pet'in senin tank'ın: önce onu gönder, sonra ateş et. Pet'in seviyesi seninkini geçemez; senden 5 seviyeden fazla düşük bir pet'in yetişmesi biraz zaman alır." } },

  { id = "hunter-feed", cat = "class", min = 10, max = 60, class = "HUNTER", trigger = nil,
    title = { enUS = "Hunter: feed your pet or it leaves", trTR = "Hunter: pet'ini besle yoksa gider" },
    text = { enUS = "Pets have a happiness level shown by the face next to their portrait. Unhappy pets do less damage and eventually run away. Feed them food from their diet (check the pet tab) about every half hour; meat for cats and wolves, bread for bears.",
             trTR = "Pet'lerin portresinin yanındaki yüzle gösterilen bir mutluluk seviyesi vardır. Mutsuz pet'ler daha az hasar verir ve sonunda kaçar. Yaklaşık yarım saatte bir diyetine uygun yiyecek ver (pet sekmesine bak); kediler ve kurtlar için et, ayılar için ekmek." } },

  { id = "hunter-ammo", cat = "class", min = 1, max = 60, class = "HUNTER", trigger = nil,
    title = { enUS = "Hunter: never run out of ammo", trTR = "Hunter: mühimmatın asla bitmesin" },
    text = { enUS = "Your ranged weapon needs arrows or bullets in the ammo slot and a quiver or ammo pouch to hold them. Always carry several stacks and buy better ammo as you level; it directly increases your damage. Check your ammo count before every dungeon.",
             trTR = "Menzilli silahın için ammo slotunda ok veya mermi, bunları taşımak için de bir quiver veya ammo pouch gerekir. Her zaman birkaç deste taşı ve seviye atladıkça daha iyi mühimmat al; hasarını doğrudan artırır. Her zindandan önce mühimmat sayını kontrol et." } },

  { id = "hunter-dead-zone", cat = "class", min = 10, max = 60, class = "HUNTER", trigger = nil,
    title = { enUS = "Hunter: keep your distance", trTR = "Hunter: mesafeni koru" },
    text = { enUS = "You cannot shoot enemies within 8 yards of you; this is the dead zone. Let your pet hold the mob, stay at range, and if something reaches you, use Concussive Shot or Wing Clip and step back. Mend Pet keeps your pet alive.",
             trTR = "8 yard'dan yakın düşmanlara ateş edemezsin; buna dead zone denir. Pet'in yaratığı tutsun, menzilde kal; bir şey sana ulaşırsa Concussive Shot veya Wing Clip kullanıp geri çekil. Mend Pet pet'ini hayatta tutar." } },

  -- ===================== CLASS: WARLOCK =====================
  { id = "warlock-shards", cat = "class", min = 1, max = 60, class = "WARLOCK", trigger = nil,
    title = { enUS = "Warlock: soul shards power your demons", trTR = "Warlock: demonların gücü soul shard'lardan gelir" },
    text = { enUS = "Summoning your Voidwalker and most demons costs a Soul Shard. Get shards by casting Drain Soul on an enemy as it dies. Keep 5 to 10 shards at all times and buy a soul bag later; shards fill ordinary bag slots fast.",
             trTR = "Voidwalker'ı ve çoğu demonu çağırmak bir Soul Shard harcar. Düşman ölürken ona Drain Soul atarak shard kazanırsın. Her zaman 5-10 shard taşı ve ileride bir soul bag al; shard'lar normal çanta slotlarını hızla doldurur." } },

  { id = "warlock-voidwalker", cat = "class", min = 10, max = 60, class = "WARLOCK", trigger = nil,
    title = { enUS = "Warlock: Voidwalker is your tank", trTR = "Warlock: Voidwalker senin tank'ın" },
    text = { enUS = "Get the Voidwalker from your level 10 trainer quest. Send it in first, let it hit a couple times, then cast your DoTs. If you pull aggro, its Sacrifice ability shields you. Life Tap turns health into mana; use it with Drain Life to stay healthy.",
             trTR = "Voidwalker'ı 10. seviyedeki trainer görevinden al. Önce onu gönder, birkaç kez vurmasını bekle, sonra DoT'larını at. Aggro çekersen Sacrifice yeteneği seni kalkanla korur. Life Tap canı manaya çevirir; sağlıklı kalmak için Drain Life ile birlikte kullan." } },

  { id = "warlock-healthstone", cat = "class", min = 10, max = 60, class = "WARLOCK", trigger = nil,
    title = { enUS = "Warlock: free healthstones and summons", trTR = "Warlock: bedava healthstone ve summon" },
    text = { enUS = "Create Healthstone gives you an instant heal item, and groups love getting one each. From level 20, Ritual of Summoning lets you bring party members to you with two helpers; it makes you very welcome in dungeon groups.",
             trTR = "Create Healthstone sana anında iyileştiren bir eşya verir; gruplar herkese bir tane verilmesine bayılır. 20. seviyeden itibaren Ritual of Summoning, iki yardımcıyla grup üyelerini yanına çağırır; bu seni zindan gruplarında çok aranan biri yapar." } },

  -- ===================== CLASS: ROGUE =====================
  { id = "rogue-poisons", cat = "class", min = 20, max = 60, class = "ROGUE", trigger = nil,
    title = { enUS = "Rogue: poisons at level 20", trTR = "Rogue: 20. seviyede zehirler" },
    text = { enUS = "At level 20 pick up the poison quest from your trainer in a capital. Instant Poison on your main hand and Deadly or Crippling on your off hand add a lot of damage. Poisons last 30 minutes and are bought from poison vendors near the Rogue trainer.",
             trTR = "20. seviyede başkentteki trainer'dan zehir görevini al. Ana elde Instant Poison, diğer elde Deadly veya Crippling Poison çok hasar ekler. Zehirler 30 dakika sürer ve Rogue trainer'ının yakınındaki zehir satıcılarından alınır." } },

  { id = "rogue-stealth", cat = "class", min = 1, max = 60, class = "ROGUE", trigger = nil,
    title = { enUS = "Rogue: open from Stealth", trTR = "Rogue: Stealth ile başla" },
    text = { enUS = "Stealth lets you choose your fights and skip packs you do not need. Open with Ambush or Cheap Shot from behind, then Sinister Strike and finish with Eviscerate. You move slower in Stealth, so use it only when approaching a target.",
             trTR = "Stealth, savaşlarını seçmeni ve gereksiz grupları atlamanı sağlar. Arkadan Ambush veya Cheap Shot ile başla, sonra Sinister Strike kullan ve Eviscerate ile bitir. Stealth'te yürümek normalden yavaştır, bu yüzden yalnızca hedefe yaklaşırken kullan." } },

  { id = "rogue-lockpick", cat = "class", min = 16, max = 60, class = "ROGUE", trigger = nil,
    title = { enUS = "Rogue: Pick Lock and daggers", trTR = "Rogue: Pick Lock ve hançerler" },
    text = { enUS = "Learn Pick Lock from your trainer around level 16 and level it on locked boxes you find. In cities, people pay you to open their lockboxes. Keep a dagger in your bags: Ambush and Backstab need one in the main hand, while Sinister Strike works with any weapon.",
             trTR = "Pick Lock'u yaklaşık 16. seviyede trainer'dan öğren ve bulduğun kilitli kutularda yükselt. Şehirlerde insanlar kendi lockbox'larını açman için sana para verir. Çantanda bir hançer bulundur: Ambush ve Backstab ana elde hançer ister, Sinister Strike her silahla çalışır." } },

  -- ===================== CLASS: DRUID =====================
  { id = "druid-bear-quest", cat = "class", min = 10, max = 60, class = "DRUID", trigger = nil,
    title = { enUS = "Druid: Bear Form quest at level 10", trTR = "Druid: 10. seviyede Bear Form görevi" },
    text = { enUS = "Your trainer gives you a quest chain at level 10 that takes you to Moonglade and rewards Bear Form. Bear is your tank and solo form early on. At level 16, another chain rewards Aquatic Form, and you learn Cat Form from the trainer at level 20.",
             trTR = "10. seviyede trainer'ın sana Moonglade'e götüren ve Bear Form ödülü veren bir görev zinciri verir. Bear, erken dönemde hem tank hem solo formundur. 16. seviyede başka bir zincir Aquatic Form verir; Cat Form'u ise 20. seviyede trainer'dan öğrenirsin." } },

  { id = "druid-forms-usage", cat = "class", min = 20, max = 60, class = "DRUID", trigger = nil,
    title = { enUS = "Druid: pick the right form for the job", trTR = "Druid: işe uygun formu seç" },
    text = { enUS = "Cat Form is the fastest way to level solo once you have it. Bear tanks dungeons, and caster form heals. Shifting out of a form costs mana, so plan your shifts. Travel Form at level 30 is a free 40 percent speed boost outdoors.",
             trTR = "Cat Form'u aldıktan sonra solo seviye atlamanın en hızlı yoludur. Bear zindanlarda tank olur, caster formu iyileştirir. Formdan çıkmak mana harcar, o yüzden geçişlerini planla. 30. seviyedeki Travel Form dışarıda bedava yüzde 40 hız verir." } },

  { id = "druid-heal-group", cat = "class", min = 15, max = 60, class = "DRUID", trigger = nil,
    title = { enUS = "Druid: groups want you as healer or tank", trTR = "Druid: gruplar seni healer veya tank olarak ister" },
    text = { enUS = "In dungeons most groups expect a Druid to heal or tank, not play Cat. Rejuvenation and Regrowth are strong early heals, and Mark of the Wild buffs everyone. Learn to tank in Bear Form if you want fast group invites.",
             trTR = "Zindanlarda çoğu grup bir Druid'in Cat oynamasını değil, healer veya tank olmasını bekler. Rejuvenation ve Regrowth güçlü erken iyileştirmelerdir; Mark of the Wild herkese buff verir. Hızlı grup daveti istiyorsan Bear Form ile tank olmayı öğren." } },

  -- ===================== CLASS: PALADIN =====================
  { id = "paladin-seals", cat = "class", min = 1, max = 60, class = "PALADIN", trigger = nil,
    title = { enUS = "Paladin: Seal first, then Judgement", trTR = "Paladin: önce Seal, sonra Judgement" },
    text = { enUS = "Your damage comes from keeping a Seal active and using Judgement on the target. Seal of Righteousness is a solid default early on. Keep Blessing of Might on yourself, keep Devotion Aura on, and use a slow two-handed weapon for leveling.",
             trTR = "Hasarın, bir Seal'i aktif tutup hedefe Judgement kullanmaktan gelir. Seal of Righteousness erken dönemde sağlam bir başlangıç seçimidir. Kendine Blessing of Might at, Devotion Aura'yı açık tut ve seviye atlamak için yavaş bir iki elli silah kullan." } },

  { id = "paladin-quests", cat = "class", min = 12, max = 60, class = "PALADIN", trigger = nil,
    title = { enUS = "Paladin: class quests for Redemption and more", trTR = "Paladin: Redemption ve dahası için sınıf görevleri" },
    text = { enUS = "Around level 12, your trainer gives you the Redemption quest; Redemption is your resurrection spell, and groups expect you to have it. Later quests reward Verigan's Fist, a great mace around level 20, and your free Warhorse at level 40.",
             trTR = "Yaklaşık 12. seviyede trainer'ın sana diriltme büyün Redemption'ın görevini verir; yap, gruplar bunu senden bekler. Sonraki görevler 20. seviye civarında harika bir topuz olan Verigan's Fist'i ve 40. seviyede bedava Warhorse'unu verir." } },

  { id = "paladin-bubble", cat = "class", min = 1, max = 60, class = "PALADIN", trigger = nil,
    title = { enUS = "Paladin: Divine Shield and Lay on Hands", trTR = "Paladin: Divine Shield ve Lay on Hands" },
    text = { enUS = "Divine Shield makes you immune for a few seconds; use it to heal yourself mid-fight or to escape. Lay on Hands fully heals a target but has a very long cooldown and uses all your mana, so save it for emergencies. Both make you very hard to kill.",
             trTR = "Divine Shield seni birkaç saniye dokunulmaz yapar; savaş ortasında kendini iyileştirmek veya kaçmak için kullan. Lay on Hands bir hedefi tamamen iyileştirir ama bekleme süresi çok uzundur ve tüm mananı harcar; acil durumlara sakla. İkisi de seni öldürmeyi çok zorlaştırır." } },

  -- ===================== CLASS: SHAMAN =====================
  { id = "shaman-totem-quests", cat = "class", min = 4, max = 60, class = "SHAMAN", trigger = nil,
    title = { enUS = "Shaman: totem quests unlock each element", trTR = "Shaman: totem görevleri her elementi açar" },
    text = { enUS = "Your trainer gives you quests for the Earth totem at level 4, Fire at 10, Water at 20 and Air at 30. Without the quest, you cannot drop that element's totems. Totems are cheap, strong group buffs; drop them every fight.",
             trTR = "Trainer'ın sana 4. seviyede Earth totem, 10'da Fire, 20'de Water ve 30'da Air görevlerini verir. Görevi yapmadan o elementin totemlerini koyamazsın. Totemler ucuz ve güçlü grup buff'larıdır; her savaşta koy." } },

  { id = "shaman-leveling", cat = "class", min = 1, max = 60, class = "SHAMAN", trigger = nil,
    title = { enUS = "Shaman: Rockbiter and a slow two-hander", trTR = "Shaman: Rockbiter ve yavaş iki elli silah" },
    text = { enUS = "Put Rockbiter Weapon on a slow two-handed weapon and open with Lightning Bolt, then melee, using Earth Shock when you need burst damage. Drink often; Shamans burn mana fast. Ghost Wolf at level 20 is your free speed boost outdoors.",
             trTR = "Yavaş bir iki elli silaha Rockbiter Weapon koy ve Lightning Bolt ile başla; sonra yakın dövüşe geç ve ani hasar gerektiğinde Earth Shock kullan. Sık sık su iç; Shaman'lar manayı hızlı tüketir. 20. seviyedeki Ghost Wolf dışarıda bedava hız artışıdır." } },

  { id = "shaman-reincarnation", cat = "class", min = 30, max = 60, class = "SHAMAN", trigger = nil,
    title = { enUS = "Shaman: Reincarnation and Ankhs", trTR = "Shaman: Reincarnation ve Ankh" },
    text = { enUS = "Reincarnation lets you resurrect yourself once an hour but uses an Ankh from your bags. Buy a few from reagent vendors and keep them with you. Also carry the reagents for Water Walking and Water Breathing.",
             trTR = "Reincarnation, saatte bir kendini diriltmeni sağlar ama çantandan bir Ankh harcar. Reagent satıcılarından birkaç tane al ve yanında taşı. Water Walking ve Water Breathing için gereken reagent'ları da yanında bulundur." } },

  -- ===================== CLASS: WARRIOR =====================
  { id = "warrior-stances", cat = "class", min = 10, max = 60, class = "WARRIOR", trigger = nil,
    title = { enUS = "Warrior: stance quests", trTR = "Warrior: stance görevleri" },
    text = { enUS = "Defensive Stance comes from a quest at level 10 and Berserker Stance from one at level 30; your trainer gives both. Battle Stance is for leveling, Defensive for tanking, and Berserker for damage. From level 14, Tactical Mastery lets you keep some rage when you switch stances.",
             trTR = "Defensive Stance 10. seviyedeki, Berserker Stance ise 30. seviyedeki bir görevden gelir; ikisini de trainer'ın verir. Battle Stance seviye atlamak, Defensive tanklık, Berserker hasar içindir. 14. seviyeden itibaren Tactical Mastery, stance değiştirirken rage'inin bir kısmını korumanı sağlar." } },

  { id = "warrior-leveling", cat = "class", min = 1, max = 60, class = "WARRIOR", trigger = nil,
    title = { enUS = "Warrior: weapon quality is everything", trTR = "Warrior: silah kalitesi her şeydir" },
    text = { enUS = "Warriors depend on gear more than any other class while leveling. A slow, high-damage two-hander makes your Heroic Strike and, later, Mortal Strike hit hard. Carry bandages and food, use Charge on every pull, and rest to full before fighting two mobs.",
             trTR = "Warrior'lar seviye atarken eşyaya en çok bağımlı sınıftır. Yüksek hasarlı yavaş bir iki elli silah, Heroic Strike'ı ve ileride Mortal Strike'ı sert vurdurur. Bandaj ve yiyecek taşı, her çekişte Charge kullan ve iki yaratıkla dövüşmeden önce tamamen dinlen." } },

  { id = "warrior-tanking", cat = "class", min = 15, max = 60, class = "WARRIOR", trigger = nil,
    title = { enUS = "Warrior: tanking basics", trTR = "Warrior: tank temelleri" },
    text = { enUS = "In Defensive Stance with a shield, Sunder Armor and Revenge build threat. Mark the target, pull with a thrown weapon or gun, and tell your DPS when to start. Taunt pulls a mob back when someone else grabs it. Groups will always need you.",
             trTR = "Kalkanla Defensive Stance'teyken Sunder Armor ve Revenge threat kurar. Hedefi işaretle, fırlatma silahı veya tüfekle çek ve DPS'e ne zaman başlayacağını söyle. Taunt, başkasına geçen yaratığı geri çeker. Gruplar sana her zaman ihtiyaç duyar." } },

  { id = "warrior-forever-spec", cat = "class", min = 10, max = 60, class = "WARRIOR", trigger = nil,
    title = { enUS = "Warrior: solo as Protection, group as Arms", trTR = "Warrior: solo Protection, grupta Arms" },
    text = { enUS = "In Forever, Warriors struggle against higher-level mobs. For solo leveling a one-hander and shield with Protection talents keeps your rage steady in Defensive Stance. With a healer or friends, a two-hander with Arms talents kills faster.",
             trTR = "Forever'da Warrior'lar üst seviye yaratıklara karşı zorlanır. Solo seviye atlarken tek elli silah, kalkan ve Protection talent'ları Defensive Stance'te rage'ini sabit tutar. Healer veya arkadaşlarla iki elli silah ve Arms talent'ları daha hızlı öldürür." } },

  -- ===================== CLASS: MAGE =====================
  { id = "mage-food", cat = "class", min = 1, max = 60, class = "MAGE", trigger = nil,
    title = { enUS = "Mage: free food and water forever", trTR = "Mage: sonsuza dek bedava yiyecek ve su" },
    text = { enUS = "Conjure Water and Conjure Food give you free supplies. Conjure a few stacks before you log out, because they vanish after 15 minutes offline. Groups will ask you for water, so keep extra. Learn new ranks from the trainer as they unlock.",
             trTR = "Conjure Water ve Conjure Food sana bedava erzak verir. Çıkış yapmadan önce birkaç deste yarat, çünkü çevrimdışı 15 dakika sonra yok olurlar. Gruplar senden su isteyecek, o yüzden fazladan bulundur. Yeni rank'ları açıldıkça trainer'dan öğren." } },

  { id = "mage-portals", cat = "class", min = 20, max = 60, class = "MAGE", trigger = nil,
    title = { enUS = "Mage: teleports at 20, portals at 40", trTR = "Mage: 20'de teleport, 40'ta portal" },
    text = { enUS = "You learn Teleport spells to capital cities from the Portal Trainer in each capital from level 20, and group Portals from level 40. They need a Rune of Teleportation or Rune of Portals reagent from a vendor. Portals earn tips and save you tons of travel time.",
             trTR = "Başkentlere Teleport büyülerini 20. seviyeden itibaren her başkentteki Portal Trainer'dan, grup Portal'larını ise 40. seviyeden itibaren öğrenirsin. Bir satıcıdan Rune of Teleportation veya Rune of Portals reagent'ı gerekir. Portal'lar bahşiş kazandırır ve seyahat süresinden büyük tasarruf sağlar." } },

  { id = "mage-kiting", cat = "class", min = 1, max = 60, class = "MAGE", trigger = nil,
    title = { enUS = "Mage: Frost Nova and keep distance", trTR = "Mage: Frost Nova ve mesafe koru" },
    text = { enUS = "You have low health, so never let mobs reach you. Open with Frostbolt, cast Frost Nova when they get close, step back and keep casting. Polymorph removes one enemy from a fight; sheep the second mob before it touches you.",
             trTR = "Canın düşüktür, o yüzden yaratıkların sana ulaşmasına asla izin verme. Frostbolt ile başla, yaklaşınca Frost Nova at, geri çekil ve büyü atmaya devam et. Polymorph bir düşmanı savaştan çıkarır; ikinci yaratığı sana dokunmadan sheep yap." } },

  -- ===================== CLASS: PRIEST =====================
  { id = "priest-wand", cat = "class", min = 5, max = 60, class = "PRIEST", trigger = nil,
    title = { enUS = "Priest: your wand is your best friend", trTR = "Priest: wand'in en iyi dostun" },
    text = { enUS = "Learn Wands from a weapon master, or use the wand from the early quest. Cast Power Word: Shield on yourself, then Shadow Word: Pain and Mind Blast, and finish with Shoot from your wand; it costs no mana. Upgrade your wand whenever you can; it is your main leveling tool.",
             trTR = "Wand kullanmayı bir weapon master'dan öğren veya erken görevdeki wand'i kullan. Kendine Power Word: Shield at, sonra Shadow Word: Pain ve Mind Blast kullan, wand'inin Shoot'uyla bitir; mana harcamaz. Fırsat buldukça wand'ini yükselt; ana seviye atlama aracındır." } },

  { id = "priest-racial-spells", cat = "class", min = 10, max = 60, class = "PRIEST", trigger = nil,
    title = { enUS = "Priest: new spells at 10 and 20", trTR = "Priest: 10 ve 20'de yeni büyüler" },
    text = { enUS = "In Forever, Fear Ward and Devouring Plague are no longer racial: every Priest learns both at level 20. Some races still get extra spells at 10 and 20, so check your trainer and class quests at those levels.",
             trTR = "Forever'da Fear Ward ve Devouring Plague artık ırksal değil: her Priest ikisini de 20. seviyede öğrenir. Bazı ırklar 10 ve 20'de hâlâ ek büyüler alır; bu seviyelerde trainer'ına ve sınıf görevlerine bak." } },

  { id = "priest-healing-groups", cat = "class", min = 13, max = 60, class = "PRIEST", trigger = nil,
    title = { enUS = "Priest: healing in dungeons", trTR = "Priest: zindanlarda iyileştirme" },
    text = { enUS = "As the group healer, keep the tank up first, use Power Word: Shield on whoever is being hit, and Renew to patch up others. Let the tank build threat before healing heavily; big heals too early pull aggro. Drink after every pull if needed; nobody minds.",
             trTR = "Grup healer'ı olarak önce tank'ı ayakta tut, vurulan kişiye Power Word: Shield at ve diğerlerini Renew ile idare et. Ağır iyileştirmeden önce tank'ın threat kurmasını bekle; erken büyük iyileştirme aggro çeker. Gerekirse her çekişten sonra su iç; kimse aldırmaz." } },
}
