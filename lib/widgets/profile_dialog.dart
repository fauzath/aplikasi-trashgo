import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_popup.dart';
import '../utils/responsive_size.dart';

Future<void> showProfileDialog({
  required BuildContext context,
  required String fullName,
  required String email,
}) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      return ProfileDialogContent(
        fallbackFullName: fullName,
        fallbackEmail: email,
      );
    },
  );
}

class ProfileDialogContent extends StatefulWidget {
  final String fallbackFullName;
  final String fallbackEmail;

  const ProfileDialogContent({
    super.key,
    required this.fallbackFullName,
    required this.fallbackEmail,
  });

  @override
  State<ProfileDialogContent> createState() => _ProfileDialogContentState();
}

class _ProfileDialogContentState extends State<ProfileDialogContent> {
  bool isUploading = false;

  String _asString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  Uint8List? _decodeBase64Image(String value) {
    if (value.trim().isEmpty) return null;

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final picker = ImagePicker();

      final pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 45,
      );

      if (!mounted) return;

      if (pickedImage == null) return;

      setState(() {
        isUploading = true;
      });

      final bytes = await pickedImage.readAsBytes();

      if (!mounted) return;

      final String base64Image = base64Encode(bytes);

      if (base64Image.length > 900000) {
        setState(() {
          isUploading = false;
        });

        AppPopup.show(
          context,
          title: 'Foto terlalu besar',
          message: 'Pilih foto lain dengan ukuran yang lebih kecil ya.',
          type: AppPopupType.warning,
        );
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageBase64': base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      AppPopup.show(
        context,
        title: 'Foto berhasil diganti',
        message: 'Profile picture kamu sudah diperbarui.',
        type: AppPopupType.success,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      AppPopup.show(
        context,
        title: 'Gagal mengganti foto',
        message: '$e',
        type: AppPopupType.error,
      );
    }
  }

  Future<void> _removeProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      setState(() {
        isUploading = true;
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageBase64': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      AppPopup.show(
        context,
        title: 'Foto profil dihapus',
        message: 'Profile picture kamu sudah dikosongkan.',
        type: AppPopupType.success,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      AppPopup.show(
        context,
        title: 'Gagal menghapus foto',
        message: '$e',
        type: AppPopupType.error,
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pop();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/welcome',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('User tidak ditemukan'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String fullName = widget.fallbackFullName;
        String email = widget.fallbackEmail;
        String profileImageBase64 = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          fullName = _asString(data['fullName'], widget.fallbackFullName);
          email = _asString(data['email'], widget.fallbackEmail);
          profileImageBase64 = _asString(data['profileImageBase64'], '');
        }

        final Uint8List? imageBytes = _decodeBase64Image(profileImageBase64);

        final dialogHorizontalInset = AppSize.isSmallPhone(context) ? 18.0 : 28.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: dialogHorizontalInset),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Stack(
                  children: [
                    ProfileAvatarLarge(
                      imageBytes: imageBytes,
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: isUploading ? null : _pickProfileImage,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC400),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: isUploading
                              ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6A2A),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 20),

                _infoCard(
                  icon: Icons.person,
                  title: 'Full Name',
                  value: fullName,
                ),

                const SizedBox(height: 10),

                _infoCard(
                  icon: Icons.email,
                  title: 'Email',
                  value: email,
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _smallButton(
                        text: 'Change Photo',
                        color: const Color(0xFF006BA3),
                        onTap: isUploading ? null : _pickProfileImage,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _smallButton(
                        text: 'Remove',
                        color: const Color(0xFFFF8A00),
                        onTap: imageBytes == null || isUploading
                            ? null
                            : _removeProfileImage,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE880),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required String text,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 43,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class ProfileAvatarLarge extends StatelessWidget {
  final Uint8List? imageBytes;

  const ProfileAvatarLarge({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? const Icon(
        Icons.camera_alt,
        color: Color(0xFF5B5B5B),
        size: 39,
      )
          : Image.memory(
        bytes,
        fit: BoxFit.cover,
      ),
    );
  }
}