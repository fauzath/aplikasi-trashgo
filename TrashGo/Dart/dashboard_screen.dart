import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';
import 'scan_screen.dart';
import 'trashdex_screen.dart';
import 'more_menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) { setState(() => _navIndex = 0); return; }
    if (index == 1) { Navigator.pushNamed(context, AppRoutes.scan); return; }
    if (index == 2) { Navigator.pushNamed(context, AppRoutes.trashdex); return; }
    if (index == 3) { Navigator.pushNamed(context, AppRoutes.profile); return; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(child: _DashboardBody()),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _TopBar(fullName: gd.fullName),
          const SizedBox(height: 24),
          _CharacterFrame(outfitPath: gd.currentOutfitPath, characterName: gd.characterName),
          const SizedBox(height: 16),
          _StatsRow(points: gd.points, level: gd.level),
          const SizedBox(height: 10),
          _XPBar(currentXP: gd.currentXP),
          const SizedBox(height: 14),
          _RankStreakCard(rank: gd.socialRank, streak: gd.streak),
          const SizedBox(height: 24),
          _QuickActions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String fullName;
  const _TopBar({required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.black54, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello,', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.accentBlue, fontWeight: FontWeight.w500)),
            Text(fullName.isNotEmpty ? fullName : 'Trainer',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.accentOrange, fontWeight: FontWeight.w700)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.accentYellow, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}

class _CharacterFrame extends StatelessWidget {
  final String outfitPath;
  final String characterName;
  const _CharacterFrame({required this.outfitPath, required this.characterName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: Image.asset(
              outfitPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 200, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(characterName.isNotEmpty ? characterName : 'Hero',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.outfitShop),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(20)),
                  child: Text('Customize', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int points;
  final int level;
  const _StatsRow({required this.points, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'Points', value: points.toString(), icon: '⭐'),
        const SizedBox(width: 12),
        _StatChip(label: 'Level', value: level.toString(), icon: '⬆'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label  ', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(width: 4),
        Text(icon, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _XPBar extends StatelessWidget {
  final int currentXP;
  const _XPBar({required this.currentXP});

  @override
  Widget build(BuildContext context) {
    final pct = (currentXP / GameDataProvider.maxXP).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.5),
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text('$currentXP XP/${GameDataProvider.maxXP}XP',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
      ],
    );
  }
}

class _RankStreakCard extends StatelessWidget {
  final String rank;
  final int streak;
  const _RankStreakCard({required this.rank, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 80,
            decoration: BoxDecoration(color: AppColors.cardTeal, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$rank RD', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('RANK', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ]),
                const Spacer(),
                const Text('🏆', style: TextStyle(fontSize: 32)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 80,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$streak', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text('DAYS STREAK', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
                ]),
                const Spacer(),
                const Text('🔥', style: TextStyle(fontSize: 32)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action('📷', 'Scan', AppRoutes.scan),
      _Action('🏆', 'Rank', AppRoutes.leaderboard),
      _Action('📅', 'Calendar', AppRoutes.calendar),
      _Action('📋', 'Missions', AppRoutes.dailyMissions),
      _Action('🌿', 'Dex', AppRoutes.trashdex),
      _Action('👕', 'Outfits', AppRoutes.outfitShop),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        final a = actions[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, a.route),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(a.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(a.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ]),
          ),
        );
      },
    );
  }
}

class _Action {
  final String emoji, label, route;
  const _Action(this.emoji, this.label, this.route);
}
