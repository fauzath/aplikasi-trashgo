class DailyMission {
  final String id;
  final String description;
  final int points;
  final int xp;
  bool isCompleted;

  DailyMission({
    required this.id,
    required this.description,
    required this.points,
    required this.xp,
    this.isCompleted = false,
  });
}
