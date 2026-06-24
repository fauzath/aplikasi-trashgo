import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/user_database.dart';
import '../utils/app_popup.dart';
import 'splash_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> signUpUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showPopup(
        'Semua data harus diisi.',
        title: 'Sign Up belum lengkap',
        type: AppPopupType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      _showPopup(
        'Password dan Confirm Password tidak sama.',
        title: 'Password belum cocok',
        type: AppPopupType.warning,
      );
      return;
    }

    if (password.length < 6) {
      _showPopup(
        'Password minimal 6 karakter.',
        title: 'Password terlalu pendek',
        type: AppPopupType.warning,
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await user.updateDisplayName(fullName);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            UserDatabase.initialUserData(
              uid: user.uid,
              fullName: fullName,
              email: email,
            ),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Welcome to TrashGo',
        'description': 'Akun kamu berhasil dibuat. Mulai scan sampah dan kumpulkan points!',
        'type': 'welcome',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showPopup(
        'Akun berhasil dibuat. Mulai scan sampah dan kumpulkan points!',
        title: 'Sign Up berhasil',
        type: AppPopupType.success,
      );
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    } on FirebaseAuthException catch (e) {
      String message = 'Sign Up gagal';

      if (e.code == 'email-already-in-use') {
        message = 'Email sudah digunakan';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      } else {
        message = e.message ?? 'Sign Up gagal';
      }

      if (!mounted) return;
      _showPopup(
        message,
        title: 'Sign Up gagal',
        type: AppPopupType.error,
      );
    } catch (e) {
      if (!mounted) return;
      _showPopup(
        'Terjadi error: $e',
        title: 'Terjadi error',
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showPopup(
    String message, {
    String title = 'Notification',
    AppPopupType type = AppPopupType.info,
  }) {
    AppPopup.show(
      context,
      title: title,
      message: message,
      type: type,
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 90),
                  const Text(
                    'Create',
                    style: TextStyle(
                      color: Color(0xFF006BA3),
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Account',
                    style: TextStyle(
                      color: Color(0xFFFF6B2A),
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 55),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(36, 34, 36, 23),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FAFAE).withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _authTextField(
                          controller: fullNameController,
                          hintText: 'Full Name',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 27),
                        _authTextField(
                          controller: emailController,
                          hintText: 'E-Mail',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 27),
                        _authTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscurePassword = !obscurePassword);
                            },
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 27),
                        _authTextField(
                          controller: confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                            },
                            icon: Icon(
                              obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 39),
                        SizedBox(
                          width: double.infinity,
                          height: 59,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : signUpUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006BA3),
                              disabledBackgroundColor: Colors.grey,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 23),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color: Color(0xFF006BA3),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }
}
