class OutfitModel {
  final String id;
  final String name;
  final String fullAssetPath;   // chara_*.png
  final String thumbAssetPath;  // charak_*.png
  final int cost;
  bool isOwned;

  OutfitModel({
    required this.id,
    required this.name,
    required this.fullAssetPath,
    required this.thumbAssetPath,
    required this.cost,
    this.isOwned = false,
  });
}
