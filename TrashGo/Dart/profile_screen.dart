import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Stack(
            children: [
              // Background dashboard glimpse
              Opacity(
                opacity: 0.4,
                child: Column(children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black26, width: 2),
                      ), child: const Icon(Icons.camera_alt_rounded, color: Colors.black26)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Hello,', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.accentBlue, fontWeight: FontWeight.w500)),
                        Text(gd.fullName, style: GoogleFonts.poppins(fontSize: 16, color: AppColors.accentOrange, fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                  ),
                ]),
              ),
              // Profile card
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    margin: const EdgeInsets.only(top: 80),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      children: [
                        // Avatar + edit
                        Transform.translate(
                          offset: const Offset(0, -36),
                          child: Stack(alignment: Alignment.bottomRight, children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 40, color: Colors.black26),
                            ),
                            Container(
                              width: 32, height: 32,
                              decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                            ),
                          ]),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -24),
                          child: Column(children: [
                            // Name
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppColors.accentYellow, borderRadius: BorderRadius.circular(24)),
                              child: Column(children: [
                                // User name row
                                Row(children: [
                                  const Icon(Icons.person_rounded, color: Colors.black87),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(gd.fullName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800))),
                                  Container(width: 32, height: 32,
                                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white)),
                                ]),
                                const SizedBox(height: 16),
                                // Email row
                                Row(children: [
                                  const Icon(Icons.email_rounded, color: Colors.black87),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(gd.email, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMedium))),
                                  Container(width: 32, height: 32,
                                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white)),
                                ]),
                                const SizedBox(height: 16),
                                // Password row
                                Row(children: [
                                  const Icon(Icons.lock_rounded, color: Colors.black87),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('••••••••', style: GoogleFonts.poppins(fontSize: 18, color: AppColors.textMedium))),
                                  Container(width: 32, height: 32,
                                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white)),
                                ]),
                                const SizedBox(height: 24),
                                // Logout
                                GestureDetector(
                                  onTap: () {
                                    context.read<GameDataProvider>().logout();
                                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (_) => false);
                                  },
                                  child: Container(
                                    width: double.infinity, height: 52,
                                    decoration: BoxDecoration(color: AppColors.accentOrange, borderRadius: BorderRadius.circular(26)),
                                    alignment: Alignment.center,
                                    child: Text('Log Out', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.scan);
          if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.trashdex);
        },
      ),
    );
  }
}
