import Foundation

/// Central repository of category keywords for receipt categorization
struct KeywordCatalog {
    
    /// Keyword set for a single category with weighted match types
    struct CategoryKeywordSet {
        let id: String
        let merchantKeywords: [String]   // +8 points
        let productKeywords: [String]    // +4 points (or +6 in items zone)
        let generalKeywords: [String]    // +2 points
        let negativeKeywords: [String]   // -8 points
    }
    
    /// All category definitions
    static let categories: [CategoryKeywordSet] = [
        
        // MARK: - Gıda & İçecek (food_drink)
        CategoryKeywordSet(
            id: "food_drink",
            merchantKeywords: [
                "starbucks", "kahve dunyasi", "kahve dünyası", "gloria jeans", "espresso lab",
                "mado", "simit sarayi", "simit sarayı", "burger king", "mcdonalds", "mcdonald's",
                "popeyes", "kfc", "dominos", "domino's", "pizza hut", "little caesars",
                "sbarro", "tavuk dunyasi", "tavuk dünyası", "komagene", "usta donerci",
                "kofteci yusuf", "köfteci yusuf", "baydoner", "cafe", "kahve", "restoran",
                "lokanta", "restaurant", "kebap", "kebab", "pide", "lahmacun"
            ],
            productKeywords: [
                "kahve", "latte", "espresso", "americano", "cappuccino", "mocha", "macchiato",
                "filtre kahve", "turk kahvesi", "türk kahvesi", "cay", "çay", "su", "kola",
                "icecek", "içecek", "meyve suyu", "smoothie", "frappe",
                "yemek", "tost", "sandvic", "sandviç", "burger", "hamburger", "pizza",
                "doner", "döner", "iskender", "corba", "çorba", "salata", "tatli", "tatlı",
                "pasta", "kek", "kurabiye", "cikolata", "çikolata", "croissant", "pogaca", "poğaça",
                "simit", "borek", "börek", "manti", "mantı", "lahmacun", "pide", "kebap"
            ],
            generalKeywords: [
                "yeme", "icme", "içme", "food", "drink", "cafe", "restaurant", "menu", "menü",
                "servis", "garson", "masa", "siparis", "sipariş", "paket", "gel al"
            ],
            negativeKeywords: [
                "benzin", "dizel", "motorin", "lpg", "lt", "litre", "pompa", "plaka",
                "service", "atolye", "atölye", "tamir", "eczane", "recete", "reçete",
                "pantolon", "kazak", "gomlek", "gömlek", "tisort", "tişört"
            ]
        ),
        
        // MARK: - Giyim (clothing)
        CategoryKeywordSet(
            id: "clothing",
            merchantKeywords: [
                "lc waikiki", "lcw", "defacto", "koton", "mavi", "mavi jeans", "colins", "colin's",
                "zara", "hm", "h&m", "bershka", "pull&bear", "pull bear", "stradivarius",
                "boyner", "flo", "atasun", "kinetix", "nike", "adidas", "puma", "new balance",
                "skechers", "under armour", "reebok", "converse", "vans", "lacoste",
                "network", "ipekyol", "vakko", "beymen", "machka", "roman"
            ],
            productKeywords: [
                "pantolon", "kazak", "gomlek", "gömlek", "tisort", "tişört", "tshirt", "t-shirt",
                "sweat", "sweatshirt", "hoodie", "mont", "kaban", "ceket", "palto",
                "etek", "elbise", "dress", "bluz", "hirka", "hırka", "yelek",
                "ayakkabi", "ayakkabı", "sneaker", "bot", "cizme", "çizme", "sandalet",
                "corap", "çorap", "kemer", "canta", "çanta", "sapka", "şapka", "bere",
                "atki", "atkı", "eldiven", "sal", "şal", "esarp", "eşarp"
            ],
            generalKeywords: [
                "giyim", "giysi", "moda", "fashion", "style", "beden", "renk", "numara",
                "kumas", "kumaş", "cotton", "polyester", "denim", "jean", "jeans"
            ],
            negativeKeywords: [
                "benzin", "dizel", "litre", "lt", "kdv", "fatura", "market",
                "sebze", "meyve", "sut", "süt", "peynir", "yemek", "kahve"
            ]
        ),
        
        // MARK: - Ulaşım (transport)
        CategoryKeywordSet(
            id: "transport",
            merchantKeywords: [
                "shell", "opet", "bp", "total", "totalenergies", "petrol", "petrol ofisi", "po",
                "aytemiz", "lukoil", "esso", "mobil", "alpet", "kadoil", "turkuaz",
                "metro", "tramvay", "otobus", "otobüs", "iett", "ego", "eshot",
                "marmaray", "izban", "baskentray", "hgs", "ogs", "bilet", "mobiett",
                "istanbulkart", "kentkart", "uber", "bitaksi", "martı", "scooter"
            ],
            productKeywords: [
                "benzin", "kursunsuz", "kurşunsuz", "dizel", "motorin", "lpg", "yakit", "yakıt",
                "litre", "lt", "pompa", "95", "97", "eurodizel", "euro diesel",
                "plaka", "arac", "araç", "otopark", "park", "vale", "bilet", "abonman", "abonelik",
                "hgs", "ogs", "gecis", "geçiş", "kopru", "köprü", "otoyol"
            ],
            generalKeywords: [
                "utts", "tts", "tasit tanima", "taşıt tanıma", "filo", "otomasyon",
                "yakit otomasyon", "yakıt otomasyon", "istasyon", "akaryakit", "akaryakıt"
            ],
            negativeKeywords: [
                "latte", "espresso", "cappuccino", "kahve", "kazak", "pantolon",
                "gomlek", "gömlek", "tisort", "tişört", "market", "migros"
            ]
        ),
        
        // MARK: - Market / Alışveriş (market)
        CategoryKeywordSet(
            id: "market",
            merchantKeywords: [
                "migros", "a101", "sok", "şok", "bim", "carrefour", "file", "macrocenter",
                "macro center", "metro", "kipa", "hakmar", "bizim", "onur market",
                "gratis", "watsons", "rossmann", "eve", "cosmetica"
            ],
            productKeywords: [
                "sebze", "meyve", "sut", "süt", "peynir", "yogurt", "yoğurt",
                "ekmek", "yumurta", "et", "tavuk", "balik", "balık",
                "deterjan", "temizlik", "poset", "poşet", "cips", "biskuvi", "bisküvi",
                "cikolata", "çikolata", "sakiz", "sakız", "seker", "şeker",
                "makarna", "pirinc", "pirinç", "bulgur", "un", "yag", "yağ",
                "tuz", "baharat", "sos", "konserve", "dondurma", "meyve suyu"
            ],
            generalKeywords: [
                "market", "supermarket", "süpermarket", "alisveris", "alışveriş",
                "groseri", "grocery", "kasaodeme", "kasa", "sepet"
            ],
            negativeKeywords: [
                "benzin", "dizel", "motorin", "litre", "lt", "pantolon", "kazak",
                "ayakkabi", "ayakkabı", "abonelik", "fatura"
            ]
        ),
        
        // MARK: - Hizmet / Faturalar (service)
        CategoryKeywordSet(
            id: "service",
            merchantKeywords: [
                "turkcell", "vodafone", "turktelekom", "türk telekom", "superonline", "superbox",
                "iski", "igdas", "igdaş", "bedas", "başkent gaz", "izgas", "egegaz",
                "enerjisa", "ckedas", "gediz", "toroslar", "bogazici", "boğaziçi",
                "netflix", "spotify", "youtube", "google", "apple", "icloud",
                "amazon", "prime", "disney"
            ],
            productKeywords: [
                "fatura", "abonelik", "aidat", "tahsilat", "hizmet bedeli",
                "elektrik", "su", "dogalgaz", "doğalgaz", "internet", "telefon",
                "hat", "paket", "tarife", "kontör", "kontor"
            ],
            generalKeywords: [
                "servis", "hizmet", "ucret", "ücret", "odeme", "ödeme", "donem", "dönem",
                "ay", "aylik", "aylık", "yillik", "yıllık"
            ],
            negativeKeywords: [
                "latte", "espresso", "kahve", "yemek", "benzin", "dizel",
                "pantolon", "kazak", "market"
            ]
        ),
        
        // MARK: - Sağlık (health)
        CategoryKeywordSet(
            id: "health",
            merchantKeywords: [
                "eczane", "pharmacy", "hastane", "hospital", "klinik", "clinic",
                "medikal", "medical", "saglik", "sağlık", "poliklinik",
                "dis", "diş", "goz", "göz", "laboratuvar", "lab"
            ],
            productKeywords: [
                "ilac", "ilaç", "recete", "reçete", "muayene", "serum", "vitamin",
                "aspirin", "parol", "antibiyotik", "sargı", "bant", "alerji",
                "sinüs", "grip", "soguk alginligi", "soğuk algınlığı"
            ],
            generalKeywords: [
                "saglik", "sağlık", "health", "tedavi", "terapi", "doktor", "dr",
                "hekim", "uzman", "randevu"
            ],
            negativeKeywords: [
                "benzin", "lt", "litre", "market", "kahve", "yemek"
            ]
        ),
        
        // MARK: - Ekipman (equipment)
        CategoryKeywordSet(
            id: "equipment",
            merchantKeywords: [
                "teknosa", "vatan", "mediamarkt", "media markt", "apple", "apple store",
                "samsung", "xiaomi", "huawei", "hepsiburada", "trendyol", "n11",
                "amazon", "gittigidiyor"
            ],
            productKeywords: [
                "iphone", "telefon", "bilgisayar", "laptop", "tablet", "ipad",
                "ekran", "monitor", "monitör", "klavye", "mouse", "fare",
                "kulaklik", "kulaklık", "sarj", "şarj", "kablo", "adaptör",
                "yazici", "yazıcı", "printer", "harddisk", "ssd", "ram"
            ],
            generalKeywords: [
                "ofis", "donanim", "donanım", "ekipman", "elektronik", "tech", "teknoloji"
            ],
            negativeKeywords: [
                "benzin", "market", "kahve", "yemek", "pantolon", "kazak"
            ]
        ),
        
        // MARK: - Eğlence (entertainment)
        CategoryKeywordSet(
            id: "entertainment",
            merchantKeywords: [
                "sinema", "cinema", "cinemaximum", "mars", "avsar", "tiyatro", "theatre",
                "konser", "biletix", "biletinial", "passo", "playstation", "steam",
                "xbox", "nintendo", "boks", "spor"
            ],
            productKeywords: [
                "bilet", "ticket", "gise", "gişe", "koltuk", "seans", "film",
                "oyun", "game", "konsol", "abonelik", "premium"
            ],
            generalKeywords: [
                "eglence", "eğlence", "entertainment", "fun", "hobi", "aktivite"
            ],
            negativeKeywords: [
                "benzin", "market", "kahve", "eczane"
            ]
        ),
        
        // MARK: - Eğitim (education)
        CategoryKeywordSet(
            id: "education",
            merchantKeywords: [
                "udemy", "coursera", "skillshare", "linkedin learning",
                "kurs", "course", "egitim", "eğitim", "akademi", "okul",
                "universite", "üniversite", "kitap", "book", "d&r", "dr",
                "kitapyurdu", "idefix", "remzi", "yapi kredi yayinlari"
            ],
            productKeywords: [
                "kitap", "book", "dergi", "magazine", "kurs", "course",
                "egitim", "eğitim", "ders", "seminer", "webinar", "sertifika"
            ],
            generalKeywords: [
                "ogrenme", "öğrenme", "learning", "study", "calisma", "çalışma"
            ],
            negativeKeywords: [
                "benzin", "market", "kahve", "yemek"
            ]
        ),
        
        // MARK: - Seyahat (travel)
        CategoryKeywordSet(
            id: "travel",
            merchantKeywords: [
                "otel", "hotel", "booking", "airbnb", "trivago", "hotels",
                "ucak", "uçak", "flight", "thy", "turk hava yollari", "türk hava yolları",
                "pegasus", "anadolujet", "sunexpress", "seyahat", "travel",
                "ets tur", "jolly", "tatil", "holiday"
            ],
            productKeywords: [
                "konaklama", "accommodation", "oda", "room", "rezervasyon",
                "ucak bileti", "uçak bileti", "flight ticket", "otel", "hotel",
                "tatil", "holiday", "tur", "tour", "gezi", "trip"
            ],
            generalKeywords: [
                "seyahat", "travel", "turizm", "tourism", "vize", "visa", "pasaport"
            ],
            negativeKeywords: [
                "benzin", "market", "kahve"
            ]
        ),
        
        // MARK: - Kira (rent)
        CategoryKeywordSet(
            id: "rent",
            merchantKeywords: [
                "emlak", "remax", "century21", "coldwell banker", "emlakjet",
                "sahibinden", "hepsiemlak"
            ],
            productKeywords: [
                "kira", "rent", "depozito", "aidat", "kontrat", "sozlesme", "sözleşme"
            ],
            generalKeywords: [
                "emlak", "apartman", "daire", "ev", "konut", "gayrimenkul"
            ],
            negativeKeywords: [
                "benzin", "market", "kahve", "yemek"
            ]
        ),
        
        // MARK: - Vergi (tax)
        CategoryKeywordSet(
            id: "tax",
            merchantKeywords: [
                "vergi dairesi", "maliye", "sgk", "sosyal guvenlik",
                "gelir idaresi", "gib"
            ],
            productKeywords: [
                "vergi", "sgk", "stopaj", "otv", "ötv", "kdv", "mtv",
                "harc", "harç", "ceza", "gecikme", "faiz"
            ],
            generalKeywords: [
                "beyanname", "tahakkuk", "odeme", "ödeme", "taksit"
            ],
            negativeKeywords: [
                "benzin", "market", "kahve", "yemek"
            ]
        )
    ]
    
    /// Find a category by ID
    static func category(for id: String) -> CategoryKeywordSet? {
        return categories.first { $0.id == id }
    }
}
