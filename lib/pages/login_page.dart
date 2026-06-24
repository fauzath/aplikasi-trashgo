import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_popup.dart';
import 'splash_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscurePassword = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppPopup.show(
        context,
        title: 'Login belum lengkap',
        message: 'E-mail dan password harus diisi.',
        type: AppPopupType.warning,
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      AppPopup.show(
        context,
        title: 'Login berhasil',
        message: 'Selamat datang kembali di TrashGo.',
        type: AppPopupType.success,
      );

      Navigator.pushReplacementNamed(context, '/auth');
    } on FirebaseAuthException catch (e) {
      String message = 'Login gagal';

      if (e.code == 'user-not-found') {
        message = 'User tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'invalid-credential') {
        message = 'Email atau password salah';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi internet bermasalah. Cek internet atau izin internet app.';
      } else {
        message = e.message ?? 'Login gagal';
      }

      if (!mounted) return;

      AppPopup.show(
        context,
        title: 'Login gagal',
        message: message,
        type: AppPopupType.error,
      );
    } catch (e) {
      if (!mounted) return;

      AppPopup.show(
        context,
        title: 'Terjadi error',
        message: '$e',
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(30, 0, 30, bottomInset + 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 135),

                    const Text(
                      'Welcome',
                      style: TextStyle(
                        color: Color(0xFF006BA3),
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const Text(
                      'Back!',
                      style: TextStyle(
                        color: Color(0xFFFF6B2A),
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(36, 38, 36, 23),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FAFAE).withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _authTextField(
                            controller: emailController,
                            hintText: 'E-Mail',
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 35),

                          _authTextField(
                            controller: passwordController,
                            hintText: 'Password',
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 41),

                          SizedBox(
                            width: double.infinity,
                            height: 59,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006BA3),
                                disabledBackgroundColor: Colors.grey,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : const Text(
                                'Log In',
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

                    const SizedBox(height: 18),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: 'Don’t have an account? ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 45),
                  ],
                ),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
            width: 1.5,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }
}