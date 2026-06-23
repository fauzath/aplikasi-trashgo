enum TrashCategory { organik, anorganik }

class TrashItem {
  final String id;
  final String name;
  final TrashCategory category;
  final String description;
  final String ecoImpact;
  final String recyclingTips;
  bool isUnlocked;

  TrashItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.ecoImpact,
    required this.recyclingTips,
    this.isUnlocked = false,
  });
}
