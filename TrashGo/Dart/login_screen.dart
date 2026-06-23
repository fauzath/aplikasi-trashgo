import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _error;

  void _submit() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    final name = email.split('@').first;
    context.read<GameDataProvider>().login(name, email);
    if (context.read<GameDataProvider>().characterName.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.characterCreation);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text('Welcome', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accentBlue)),
                Text('Back!', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accentOrange)),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      _buildField(ctrl: _emailCtrl, hint: 'E-Mail', icon: Icons.email_outlined, isPassword: false),
                      const SizedBox(height: 20),
                      _buildField(ctrl: _passCtrl, hint: 'Password', icon: Icons.lock_outline, isPassword: true),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12)),
                      ],
                      const SizedBox(height: 24),
                      _PrimaryButton(label: 'Log In', onTap: _submit),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.poppins(color: AppColors.textDark),
                        children: [
                          TextSpan(text: 'Sign Up', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        ],
                      ),
                    ),
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

  Widget _buildField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword && _obscurePass,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              )
            : null,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.accentBlue,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
