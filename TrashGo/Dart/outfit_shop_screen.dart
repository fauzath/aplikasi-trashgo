import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../models/outfit_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

class OutfitShopScreen extends StatefulWidget {
  const OutfitShopScreen({super.key});

  @override
  State<OutfitShopScreen> createState() => _OutfitShopScreenState();
}

class _OutfitShopScreenState extends State<OutfitShopScreen> {
  String _previewId = 'none';

  String _previewPath(GameDataProvider gd) {
    if (_previewId == 'none') {
      return gd.gender == 'Female' ? AppAssets.defaultFemale : AppAssets.defaultMale;
    }
    return gd.outfits.firstWhere((o) => o.id == _previewId, orElse: () => gd.outfits.first).fullAssetPath;
  }

  OutfitModel? _previewOutfit(GameDataProvider gd) {
    if (_previewId == 'none') return null;
    try {
      return gd.outfits.firstWhere((o) => o.id == _previewId);
    } catch (_) { return null; }
  }

  void _onTile(GameDataProvider gd, OutfitModel outfit) {
    setState(() => _previewId = outfit.id);
  }

  void _purchase(BuildContext context, GameDataProvider gd, OutfitModel outfit) {
    final success = gd.purchaseOutfit(outfit.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? '✅ ${outfit.name} purchased!' : '❌ Not enough points!',
        style: GoogleFonts.poppins(fontSize: 14)),
      backgroundColor: success ? AppColors.primaryGreen : Colors.red.shade600,
      duration: const Duration(seconds: 2),
    ));
  }

  void _equip(GameDataProvider gd, String id) {
    gd.equipOutfit(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('👕 Outfit equipped!', style: GoogleFonts.poppins(fontSize: 14)),
      backgroundColor: AppColors.primaryGreen,
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();
    final preview = _previewOutfit(gd);
    final isOwned = preview == null || preview.isOwned;

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Character preview panel
              Expanded(
                flex: 55,
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Image.asset(
                          _previewPath(gd),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded, size: 160,
                            color: AppColors.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    if (preview != null)
                      Positioned(
                        bottom: 20, left: 0, right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: isOwned
                                ? () => _equip(gd, preview.id)
                                : () => _purchase(context, gd, preview),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              decoration: BoxDecoration(
                                color: isOwned ? AppColors.primaryGreen : AppColors.accentOrange,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                isOwned ? 'Equip' : 'Buy  ${preview.cost} pts',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Drag handle
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
              // Outfit grid panel
              Expanded(
                flex: 45,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(children: [
                          Text('Outfit', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text('${gd.points} pts ⭐', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
                        ]),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, childAspectRatio: 1, crossAxisSpacing: 12, mainAxisSpacing: 12,
                          ),
                          itemCount: gd.outfits.length,
                          itemBuilder: (_, i) {
                            final outfit = gd.outfits[i];
                            final isSelected = _previewId == outfit.id;
                            return GestureDetector(
                              onTap: () => _onTile(gd, outfit),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: AppColors.cardYellow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected ? Border.all(color: AppColors.primaryGreen, width: 2.5) : null,
                                ),
                                child: outfit.id == 'none'
                                    ? const Icon(Icons.block_rounded, size: 48, color: Colors.grey)
                                    : Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Image.asset(outfit.thumbAssetPath, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(outfit.name[0],
                                              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
