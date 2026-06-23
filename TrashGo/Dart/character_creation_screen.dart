import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  String _selectedGender = 'Female';
  final _nameCtrl = TextEditingController();
  String? _error;

  void _start() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a character name!');
      return;
    }
    context.read<GameDataProvider>().initCharacter(name, _selectedGender);
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text('Choose', style: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.accentBlue)),
                Text('Character', style: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.accentOrange)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _GenderCard(gender: 'Female', selected: _selectedGender == 'Female', onTap: () => setState(() => _selectedGender = 'Female'))),
                    const SizedBox(width: 16),
                    Expanded(child: _GenderCard(gender: 'Male', selected: _selectedGender == 'Male', onTap: () => setState(() => _selectedGender = 'Male'))),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Character Name',
                          hintStyle: GoogleFonts.poppins(color: Colors.white70),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12)),
                      ],
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _start,
                        child: Container(
                          width: double.infinity, height: 56,
                          decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(28)),
                          alignment: Alignment.center,
                          child: Text('Start', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String gender;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({required this.gender, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = gender == 'Female'
        ? (selected ? AppColors.accentOrange : AppColors.accentOrange.withOpacity(0.5))
        : (selected ? AppColors.accentBlue : AppColors.accentBlue.withOpacity(0.5));
    final assetPath = gender == 'Female' ? AppAssets.defaultFemale : AppAssets.defaultMale;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 200,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: selected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(assetPath, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    gender == 'Female' ? Icons.face_2_rounded : Icons.face_rounded,
                    size: 80, color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(gender, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
