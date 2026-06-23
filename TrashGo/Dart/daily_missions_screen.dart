import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text('Daily Mission', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: gd.missions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final m = gd.missions[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: m.isCompleted ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(m.description,
                            style: GoogleFonts.poppins(fontSize: 13, color: m.isCompleted ? AppColors.primaryGreen : AppColors.textDark,
                              decoration: m.isCompleted ? TextDecoration.lineThrough : null)),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${m.points}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentOrange)),
                          Text('pts', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
                        ]),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${m.xp}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                          Text('XP', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
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
