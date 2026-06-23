import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  void _submit() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty) { setState(() => _error = 'Full name is required.'); return; }
    if (!email.contains('@')) { setState(() => _error = 'Enter a valid email.'); return; }
    if (pass.length < 6) { setState(() => _error = 'Password must be at least 6 characters.'); return; }
    if (pass != confirm) { setState(() => _error = 'Passwords do not match.'); return; }

    context.read<GameDataProvider>().signUp(name, email);
    Navigator.pushReplacementNamed(context, AppRoutes.characterCreation);
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
                Text('Create', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accentBlue)),
                Text('Account', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accentOrange)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      _buildField(ctrl: _nameCtrl, hint: 'Full Name', isPassword: false, obscure: false),
                      const SizedBox(height: 18),
                      _buildField(ctrl: _emailCtrl, hint: 'E-Mail', isPassword: false, obscure: false),
                      const SizedBox(height: 18),
                      _buildField(
                        ctrl: _passCtrl, hint: 'Password', isPassword: true, obscure: _obscurePass,
                        onToggle: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        ctrl: _confirmCtrl, hint: 'Confirm Password', isPassword: true, obscure: _obscureConfirm,
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12)),
                      ],
                      const SizedBox(height: 24),
                      _PrimaryButton(label: 'Sign In', onTap: _submit),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.poppins(color: AppColors.textDark),
                        children: [
                          TextSpan(text: 'Log In', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
    required bool isPassword,
    required bool obscure,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword && obscure,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        suffixIcon: isPassword && onToggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                onPressed: onToggle,
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
        width: double.infinity, height: 56,
        decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(30)),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
