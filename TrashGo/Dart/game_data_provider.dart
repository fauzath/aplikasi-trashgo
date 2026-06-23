import 'package:flutter/foundation.dart';
import '../models/outfit_model.dart';
import '../models/trash_item.dart';
import '../models/leaderboard_entry.dart';
import '../models/daily_mission.dart';
import '../utils/app_constants.dart';

class GameDataProvider extends ChangeNotifier {
  // ─── User Profile ───────────────────────────────────────────────────────────
  String _fullName = '';
  String _email = '';
  bool _isLoggedIn = false;

  String get fullName => _fullName;
  String get email => _email;
  bool get isLoggedIn => _isLoggedIn;

  // ─── Character Stats ─────────────────────────────────────────────────────────
  String _characterName = '';
  String _gender = 'Female'; // 'Male' | 'Female'
  int _level = 1;
  int _currentXP = 139;
  static const int maxXP = 200;
  int _points = 500;
  int _streak = 0;
  String _socialRank = '-';

  String get characterName => _characterName;
  String get gender => _gender;
  int get level => _level;
  int get currentXP => _currentXP;
  int get points => _points;
  int get streak => _streak;
  String get socialRank => _socialRank;

  // ─── Active Outfit ───────────────────────────────────────────────────────────
  String _currentOutfitPath = AppAssets.defaultFemale;
  String get currentOutfitPath => _currentOutfitPath;

  // ─── Outfits Collection ──────────────────────────────────────────────────────
  final List<OutfitModel> _outfits = [
    OutfitModel(
      id: 'none',
      name: 'Default',
      fullAssetPath: '',
      thumbAssetPath: '',
      cost: 0,
      isOwned: true,
    ),
    OutfitModel(
      id: 'pisang',
      name: 'Banana Peel',
      fullAssetPath: AppAssets.charaBanana,
      thumbAssetPath: AppAssets.charakBanana,
      cost: 300,
    ),
    OutfitModel(
      id: 'telur',
      name: 'Eggshell',
      fullAssetPath: AppAssets.charaEgg,
      thumbAssetPath: AppAssets.charakEgg,
      cost: 300,
    ),
    OutfitModel(
      id: 'daun',
      name: 'Leaf Cloak',
      fullAssetPath: AppAssets.charaLeaf,
      thumbAssetPath: AppAssets.charakLeaf,
      cost: 500,
    ),
    OutfitModel(
      id: 'botol',
      name: 'Plastic Bottle',
      fullAssetPath: AppAssets.charaBottle,
      thumbAssetPath: AppAssets.charakBottle,
      cost: 500,
    ),
    OutfitModel(
      id: 'kardus',
      name: 'Cardboard Box',
      fullAssetPath: AppAssets.charaBox,
      thumbAssetPath: AppAssets.charakBox,
      cost: 700,
    ),
    OutfitModel(
      id: 'kaleng',
      name: 'Tin Can',
      fullAssetPath: AppAssets.charaCan,
      thumbAssetPath: AppAssets.charakCan,
      cost: 700,
    ),
  ];

  List<OutfitModel> get outfits => _outfits;

  // ─── Trashdex Collection ─────────────────────────────────────────────────────
  final List<TrashItem> _trashdexItems = [
    // Anorganik
    TrashItem(
      id: 'plastic_bottle',
      name: 'Botol Plastik',
      category: TrashCategory.anorganik,
      description: 'Botol berbahan PET (Polyethylene Terephthalate), digunakan untuk kemasan air minum sekali pakai.',
      ecoImpact: 'Membutuhkan hingga 450 tahun untuk terurai di lingkungan. Dapat mencemari lautan dan melukai satwa liar jika tidak dikelola dengan benar.',
      recyclingTips: 'Cuci bersih, lepas tutup dan label, lalu masukkan ke tempat sampah daur ulang biru. Bisa diolah menjadi serat tekstil atau botol baru.',
    ),
    TrashItem(
      id: 'plastic_bag',
      name: 'Kantong Plastik',
      category: TrashCategory.anorganik,
      description: 'Kantong berbahan LDPE/HDPE, digunakan sebagai wadah belanja sehari-hari.',
      ecoImpact: 'Sulit terurai dan sering berakhir di lautan, membahayakan ekosistem laut.',
      recyclingTips: 'Kumpulkan dan bawa ke drop-point khusus plastik. Gunakan kembali sebagai liner sampah kecil.',
    ),
    TrashItem(
      id: 'tin_can',
      name: 'Kaleng Minuman',
      category: TrashCategory.anorganik,
      description: 'Kaleng aluminium untuk minuman ringan, salah satu material yang paling efisien didaur ulang.',
      ecoImpact: 'Produksi aluminium sangat energi-intensif. Daur ulang menghemat hingga 95% energi produksi.',
      recyclingTips: 'Cuci, gepeng, dan masukkan ke bin logam. Aluminium dapat didaur ulang berkali-kali tanpa kehilangan kualitas.',
    ),
    TrashItem(
      id: 'cardboard',
      name: 'Kardus',
      category: TrashCategory.anorganik,
      description: 'Kemasan berbahan kertas tebal corrugated, digunakan untuk pengiriman dan penyimpanan.',
      ecoImpact: 'Dapat terurai secara alami namun membutuhkan pohon sebagai bahan baku. Mendaur ulang kardus menghemat air dan energi.',
      recyclingTips: 'Lipat rata, jaga tetap kering, dan bundel dengan tali. Serahkan ke pengepul atau tempat sampah daur ulang.',
    ),
    TrashItem(
      id: 'glass_bottle',
      name: 'Botol Kaca',
      category: TrashCategory.anorganik,
      description: 'Wadah kaca untuk minuman, saus, dan produk lainnya.',
      ecoImpact: 'Membutuhkan ribuan tahun untuk terurai, namun dapat didaur ulang 100% tanpa kehilangan kualitas.',
      recyclingTips: 'Cuci bersih, lepas tutup, dan masukkan ke bin kaca khusus. Botol utuh bisa dikembalikan ke produsen untuk diisi ulang.',
    ),
    TrashItem(
      id: 'electronic_waste',
      name: 'Limbah Elektronik',
      category: TrashCategory.anorganik,
      description: 'Perangkat elektronik usang seperti baterai, kabel, dan gadget.',
      ecoImpact: 'Mengandung bahan beracun (merkuri, timbal) yang berbahaya bagi tanah dan air jika dibuang sembarangan.',
      recyclingTips: 'Bawa ke pusat pengumpulan e-waste resmi atau program take-back produsen. Jangan dibuang ke TPA biasa.',
    ),
    TrashItem(
      id: 'styrofoam',
      name: 'Styrofoam',
      category: TrashCategory.anorganik,
      description: 'Busa polistirena yang digunakan untuk wadah makanan dan kemasan.',
      ecoImpact: 'Hampir tidak bisa terurai dan sulit didaur ulang. Pecahannya mencemari tanah dan lautan.',
      recyclingTips: 'Hindari penggunaan. Beberapa fasilitas khusus bisa mendaur ulang styrofoam bersih menjadi bahan bangunan.',
    ),
    TrashItem(
      id: 'battery',
      name: 'Baterai',
      category: TrashCategory.anorganik,
      description: 'Baterai sekali pakai atau isi ulang dari berbagai perangkat.',
      ecoImpact: 'Mengandung asam, logam berat, dan elektrolit korosif yang sangat berbahaya jika bocor ke tanah.',
      recyclingTips: 'Simpan dalam wadah tertutup dan bawa ke drop-point pengumpulan baterai di supermarket atau kantor pos.',
    ),

    // Organik
    TrashItem(
      id: 'banana_peel',
      name: 'Kulit Pisang',
      category: TrashCategory.organik,
      description: 'Kulit buah pisang, kaya akan potasium dan serat yang bermanfaat untuk tanah.',
      ecoImpact: 'Terurai relatif cepat (2-5 minggu) dan memperkaya tanah dengan nutrisi. Namun pembuangan massal dapat menarik hama.',
      recyclingTips: 'Masukkan ke komposter rumahan atau bin sampah organik hijau. Bisa diolah menjadi pupuk organik berkualitas tinggi.',
    ),
    TrashItem(
      id: 'dry_leaves',
      name: 'Daun Kering',
      category: TrashCategory.organik,
      description: 'Daun yang telah gugur dari pohon, mengandung karbon tinggi.',
      ecoImpact: 'Terurai alami dan menjadi humus yang menyuburkan tanah. Membakar daun kering menghasilkan polutan berbahaya.',
      recyclingTips: 'Kumpulkan untuk kompos atau mulsa taman. Campurkan dengan sampah "hijau" (nitrogen-tinggi) untuk kompos seimbang.',
    ),
    TrashItem(
      id: 'food_scraps',
      name: 'Sisa Makanan',
      category: TrashCategory.organik,
      description: 'Sisa nasi, sayuran, buah, dan makanan lainnya dari dapur.',
      ecoImpact: 'Di TPA menghasilkan gas metana (28x lebih kuat dari CO₂ sebagai GRK). Namun sangat berharga sebagai bahan kompos.',
      recyclingTips: 'Gunakan komposter kecil atau program biogas komunal. Hindari pembuangan ke saluran air.',
    ),
    TrashItem(
      id: 'eggshell',
      name: 'Cangkang Telur',
      category: TrashCategory.organik,
      description: 'Cangkang telur ayam atau bebek, kaya kalsium karbonat.',
      ecoImpact: 'Terurai lambat (hingga 3 tahun) tapi sangat bermanfaat untuk meningkatkan pH tanah asam.',
      recyclingTips: 'Haluskan dan campurkan ke tanah taman atau kompos. Ampuh mengusir siput dan keong dari tanaman.',
    ),
    TrashItem(
      id: 'coffee_grounds',
      name: 'Ampas Kopi',
      category: TrashCategory.organik,
      description: 'Bubuk kopi sisa penyeduhan, kaya nitrogen dan nutrisi mikro.',
      ecoImpact: 'Terurai cepat dan memperbaiki struktur tanah serta mendorong aktivitas cacing tanah.',
      recyclingTips: 'Taburkan langsung ke tanaman yang menyukai asam (mawar, blueberry), atau tambahkan ke kompos.',
    ),
    TrashItem(
      id: 'vegetable_scraps',
      name: 'Kulit Sayuran',
      category: TrashCategory.organik,
      description: 'Kulit wortel, kentang, bawang, dan sayuran lainnya.',
      ecoImpact: 'Sangat kaya nutrisi dan terurai cepat, ideal sebagai bahan kompos berkualitas tinggi.',
      recyclingTips: 'Simpan dalam freezer sampai penuh lalu rebus untuk kaldu sayuran, atau langsung masukkan ke komposter.',
    ),
    TrashItem(
      id: 'wood_waste',
      name: 'Limbah Kayu',
      category: TrashCategory.organik,
      description: 'Serbuk gergaji, potongan kayu kecil, atau ranting pohon.',
      ecoImpact: 'Terurai lebih lambat dari limbah organik lainnya, namun dapat menjadi biochar yang sangat bermanfaat.',
      recyclingTips: 'Gunakan sebagai mulsa kebun, bahan bakar biomassa, atau bawa ke fasilitas pengolahan limbah kayu.',
    ),
  ];

  List<TrashItem> get trashdexItems => _trashdexItems;

  List<TrashItem> get anorganikItems =>
      _trashdexItems.where((i) => i.category == TrashCategory.anorganik).toList();

  List<TrashItem> get organikItems =>
      _trashdexItems.where((i) => i.category == TrashCategory.organik).toList();

  // ─── Streak Calendar ─────────────────────────────────────────────────────────
  final Set<DateTime> _activeDays = {
    DateTime(2026, 6, 1),
    DateTime(2026, 6, 2),
    DateTime(2026, 6, 3),
    DateTime(2026, 6, 4),
    DateTime(2026, 6, 5),
    DateTime(2026, 6, 17),
    DateTime(2026, 6, 18),
    DateTime(2026, 6, 19),
    DateTime(2026, 6, 20),
    DateTime(2026, 6, 21),
  };
  Set<DateTime> get activeDays => _activeDays;

  // ─── Daily Missions ──────────────────────────────────────────────────────────
  final List<DailyMission> _missions = [
    DailyMission(id: 'm1', description: 'Scan dan buang 1 sampah plastik ke tempat yang benar', points: 100, xp: 50),
    DailyMission(id: 'm2', description: 'Login ke aplikasi selama 3 hari berturut-turut', points: 50, xp: 25),
    DailyMission(id: 'm3', description: 'Temukan dan scan sampah organik baru untuk Trashdex', points: 150, xp: 75),
    DailyMission(id: 'm4', description: 'Buang sampah anorganik ke bin yang tepat', points: 100, xp: 50),
    DailyMission(id: 'm5', description: 'Kumpulkan total 3 jenis sampah berbeda hari ini', points: 200, xp: 100),
  ];
  List<DailyMission> get missions => _missions;

  // ─── Leaderboard Data ────────────────────────────────────────────────────────
  final List<LeaderboardEntry> _globalBoard = [
    const LeaderboardEntry(id: 'g1', name: 'EcoWarrior99', xp: 4500),
    const LeaderboardEntry(id: 'g2', name: 'GreenHero', xp: 3800),
    const LeaderboardEntry(id: 'g3', name: 'RecycleKing', xp: 3200),
    const LeaderboardEntry(id: 'g4', name: 'PlanetSaver', xp: 1000),
    const LeaderboardEntry(id: 'g5', name: 'CleanEarth', xp: 980),
    const LeaderboardEntry(id: 'g6', name: 'TrashHunter', xp: 800),
  ];

  final List<LeaderboardEntry> _friendsBoard = [
    const LeaderboardEntry(id: 'f1', name: 'Budi S.', xp: 1200),
    const LeaderboardEntry(id: 'f2', name: 'Siti R.', xp: 950),
    const LeaderboardEntry(id: 'f3', name: 'Andi P.', xp: 600),
    const LeaderboardEntry(id: 'f4', name: 'Dewi K.', xp: 400),
  ];

  List<LeaderboardEntry> get globalBoard => _globalBoard;
  List<LeaderboardEntry> get friendsBoard => _friendsBoard;

  // ─── Notifications ───────────────────────────────────────────────────────────
  final List<Map<String, String>> notifications = [
    {'title': '🎉 Level Up!', 'desc': 'Selamat! Kamu telah mencapai Level 2!'},
    {'title': '🔥 Streak 5 Hari!', 'desc': 'Luar biasa! Kamu telah menjaga streak selama 5 hari berturut-turut.'},
    {'title': '🌿 Item Baru di Trashdex', 'desc': 'Kamu berhasil membuka Kulit Pisang di Trashdex!'},
    {'title': '🏆 Naik Ranking', 'desc': 'Kamu sekarang berada di posisi ke-5 leaderboard global.'},
    {'title': '⭐ Misi Harian Selesai', 'desc': 'Kamu telah menyelesaikan semua misi harian hari ini!'},
    {'title': '💎 Outfit Terbuka', 'desc': 'Outfit Banana Peel kini tersedia untuk dibeli di Outfit Shop.'},
    {'title': '📅 Pengingat Misi', 'desc': 'Jangan lupa scan sampahmu hari ini untuk menjaga streak!'},
  ];

  // ─── Auth Methods ────────────────────────────────────────────────────────────
  void login(String name, String email) {
    _fullName = name;
    _email = email;
    _isLoggedIn = true;
    notifyListeners();
  }

  void signUp(String name, String email) {
    _fullName = name;
    _email = email;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _fullName = '';
    _email = '';
    _isLoggedIn = false;
    _characterName = '';
    _currentXP = 0;
    _points = 0;
    _streak = 0;
    _level = 1;
    notifyListeners();
  }

  // ─── Character Setup ─────────────────────────────────────────────────────────
  void initCharacter(String name, String gender) {
    _characterName = name;
    _gender = gender;
    _currentOutfitPath = gender == 'Female' ? AppAssets.defaultFemale : AppAssets.defaultMale;
    notifyListeners();
  }

  // ─── XP & Points ─────────────────────────────────────────────────────────────
  void addReward({required int xp, required int pts}) {
    _currentXP += xp;
    _points += pts;
    while (_currentXP >= maxXP) {
      _currentXP -= maxXP;
      _level++;
    }
    notifyListeners();
  }

  // ─── Trashdex Unlock ─────────────────────────────────────────────────────────
  void unlockTrashItem(String itemId) {
    final idx = _trashdexItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _trashdexItems[idx].isUnlocked = true;
      notifyListeners();
    }
  }

  // ─── Outfit Purchase & Equip ─────────────────────────────────────────────────
  bool purchaseOutfit(String outfitId) {
    final idx = _outfits.indexWhere((o) => o.id == outfitId);
    if (idx == -1) return false;
    final outfit = _outfits[idx];
    if (outfit.isOwned) return false;
    if (_points < outfit.cost) return false;
    _points -= outfit.cost;
    _outfits[idx].isOwned = true;
    notifyListeners();
    return true;
  }

  void equipOutfit(String outfitId) {
    if (outfitId == 'none') {
      _currentOutfitPath = _gender == 'Female' ? AppAssets.defaultFemale : AppAssets.defaultMale;
      notifyListeners();
      return;
    }
    final idx = _outfits.indexWhere((o) => o.id == outfitId);
    if (idx != -1 && _outfits[idx].isOwned) {
      _currentOutfitPath = _outfits[idx].fullAssetPath;
      notifyListeners();
    }
  }

  // ─── Streak Mark ─────────────────────────────────────────────────────────────
  void markToday() {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    _activeDays.add(d);
    _streak++;
    notifyListeners();
  }
}
