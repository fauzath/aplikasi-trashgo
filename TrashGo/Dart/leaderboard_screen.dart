import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../models/leaderboard_entry.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _showGlobal = true;

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();
    final entries = _showGlobal ? gd.globalBoard : gd.friendsBoard;
    final sorted = [...entries]..sort((a, b) => b.xp.compareTo(a.xp));

    // Insert current user at proper rank
    final userEntry = LeaderboardEntry(id: 'user', name: gd.fullName.isEmpty ? 'You' : gd.fullName, xp: gd.currentXP, isCurrentUser: true);
    final allEntries = [...sorted];

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Toggle tab
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    _TabBtn(label: 'Global', active: _showGlobal, leftRadius: true, rightRadius: false,
                      onTap: () => setState(() => _showGlobal = true)),
                    _TabBtn(label: 'Friends', active: !_showGlobal, leftRadius: false, rightRadius: true,
                      onTap: () => setState(() => _showGlobal = false)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Top 3 podium
              if (allEntries.length >= 3)
                _PodiumRow(entries: allEntries.take(3).toList()),
              const SizedBox(height: 4),
              // List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: allEntries.length - 3 + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i < allEntries.length - 3) {
                        return _ListRow(rank: i + 4, entry: allEntries[i + 3], isUser: false);
                      } else {
                        return _ListRow(rank: -1, entry: userEntry, isUser: true);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.scan);
          if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.trashdex);
          if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.profile);
        },
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool leftRadius, rightRadius;
  final VoidCallback onTap;

  const _TabBtn({required this.label, required this.active, required this.leftRadius, required this.rightRadius, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? AppColors.primaryGreen : AppColors.accentBlue,
            borderRadius: BorderRadius.horizontal(
              left: leftRadius ? const Radius.circular(26) : Radius.zero,
              right: rightRadius ? const Radius.circular(26) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.white70)),
        ),
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _PodiumRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final heights = [140.0, 180.0, 120.0]; // 2nd, 1st, 3rd
    final colors = [AppColors.silver, AppColors.gold, AppColors.bronze];
    final order = [1, 0, 2]; // display order: 2nd, 1st, 3rd

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: order.map((rank) {
          final entry = entries[rank];
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 24, color: Colors.black38),
                ),
                const SizedBox(height: 4),
                Text(entry.name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                Container(
                  height: heights[rank],
                  decoration: BoxDecoration(
                    color: colors[rank],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  alignment: Alignment.center,
                  child: Text('${rank + 1}', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isUser;

  const _ListRow({required this.rank, required this.entry, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.podiumUser : AppColors.podiumListOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        SizedBox(width: 28, child: Text(rank > 0 ? '$rank' : '-',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark))),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
          child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.black38),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(entry.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        Text('${entry.xp}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(width: 4),
        Text('XP', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
      ]),
    );
  }
}
