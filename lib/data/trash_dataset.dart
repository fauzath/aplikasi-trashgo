class TrashItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imagePath;
  final int rewardPoints;
  final int rewardExp;

  const TrashItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imagePath,
    required this.rewardPoints,
    required this.rewardExp,
  });
}

class TrashDataset {
  static const List<TrashItem> items = [
    TrashItem(
      id: 'can',
      name: 'Can',
      category: 'Anorganik',
      description: 'Kaleng termasuk sampah anorganik dan dapat didaur ulang.',
      imagePath: 'assets/images/trash/anorganik/can.png',
      rewardPoints: 100,
      rewardExp: 50,
    ),
    TrashItem(
      id: 'cardboard',
      name: 'Cardboard',
      category: 'Anorganik',
      description: 'Kardus termasuk sampah anorganik berbahan kertas tebal dan dapat didaur ulang.',
      imagePath: 'assets/images/trash/anorganik/cardboard.png',
      rewardPoints: 90,
      rewardExp: 45,
    ),
    TrashItem(
      id: 'glass_bottle',
      name: 'Glass Bottle',
      category: 'Anorganik',
      description: 'Botol kaca termasuk sampah anorganik dan dapat dipilah untuk daur ulang.',
      imagePath: 'assets/images/trash/anorganik/glass_bottle.png',
      rewardPoints: 120,
      rewardExp: 60,
    ),
    TrashItem(
      id: 'paper',
      name: 'Paper',
      category: 'Anorganik',
      description: 'Kertas bekas termasuk sampah anorganik yang dapat dikumpulkan dan didaur ulang.',
      imagePath: 'assets/images/trash/anorganik/paper.png',
      rewardPoints: 80,
      rewardExp: 40,
    ),
    TrashItem(
      id: 'plastic_bag',
      name: 'Plastic Bag',
      category: 'Anorganik',
      description: 'Kantong plastik termasuk sampah anorganik dan sebaiknya dipilah agar tidak mencemari lingkungan.',
      imagePath: 'assets/images/trash/anorganik/plastic_bag.png',
      rewardPoints: 90,
      rewardExp: 45,
    ),
    TrashItem(
      id: 'plastic_bottle',
      name: 'Plastic Bottle',
      category: 'Anorganik',
      description: 'Botol plastik termasuk sampah anorganik yang dapat didaur ulang.',
      imagePath: 'assets/images/trash/anorganik/plastic_bottle.png',
      rewardPoints: 100,
      rewardExp: 50,
    ),
    TrashItem(
      id: 'dry_leaves',
      name: 'Dry Leaves',
      category: 'Organik',
      description: 'Daun kering termasuk sampah organik dan dapat dimanfaatkan sebagai kompos.',
      imagePath: 'assets/images/trash/organik/dry_leaves.png',
      rewardPoints: 70,
      rewardExp: 35,
    ),
    TrashItem(
      id: 'food_waste',
      name: 'Food Waste',
      category: 'Organik',
      description: 'Sisa makanan termasuk sampah organik yang dapat diolah menjadi kompos.',
      imagePath: 'assets/images/trash/organik/food_waste.png',
      rewardPoints: 80,
      rewardExp: 40,
    ),
  ];

  static List<TrashItem> byCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }

  static TrashItem byId(String id) {
    return items.firstWhere(
          (item) => item.id == id,
      orElse: () => items.first,
    );
  }
}