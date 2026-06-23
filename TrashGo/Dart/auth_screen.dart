import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _LogoBlock(),
                const Spacer(flex: 4),
                _AuthButton(
                  label: 'Log In',
                  filled: true,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
                const SizedBox(height: 14),
                _AuthButton(
                  label: 'Sign Up',
                  filled: false,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
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

class _LogoBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primaryGreen, width: 3),
          ),
          child: const Icon(Icons.delete_sweep_rounded, size: 80, color: AppColors.primaryGreen),
        ),
        const SizedBox(height: 16),
        Text(
          'Trash Go!',
          style: GoogleFonts.courierPrime(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _AuthButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: filled ? AppColors.primaryDark : AppColors.primaryGreen.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
