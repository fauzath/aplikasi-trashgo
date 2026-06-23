class LeaderboardEntry {
  final String id;
  final String name;
  final int xp;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.xp,
    this.isCurrentUser = false,
  });
}
