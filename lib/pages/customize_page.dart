import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../services/user_database.dart';
import '../utils/app_popup.dart';
import '../utils/responsive_size.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_bottom_nav.dart';
import 'splash_page.dart';

class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  String selectedOutfitId = UserDatabase.defaultOutfitId;
  bool _hasInitializedSelectedOutfit = false;

  final List<OutfitItem> outfits = const [
    OutfitItem(
      id: UserDatabase.defaultOutfitId,
      name: 'Default Character',
      type: 'Basic',
      modelPath: UserDatabase.defaultModelPath,
      previewImagePath: UserDatabase.defaultPreviewPath,
      price: 0,
    ),
    OutfitItem(
      id: UserDatabase.royalOutfitId,
      name: 'Set Royal',
      type: 'Premium Outfit',
      modelPath: UserDatabase.royalModelPath,
      previewImagePath: UserDatabase.royalPreviewPath,
      price: 300,
    ),
    OutfitItem(
      id: UserDatabase.maidOutfitId,
      name: 'Maid Set',
      type: 'Premium Outfit',
      modelPath: UserDatabase.maidModelPath,
      previewImagePath: UserDatabase.maidPreviewPath,
      price: 450,
    ),
    OutfitItem(
      id: UserDatabase.clownOutfitId,
      name: 'Clown Set',
      type: 'Premium Outfit',
      modelPath: UserDatabase.clownModelPath,
      previewImagePath: UserDatabase.clownPreviewPath,
      price: 450,
    ),
  ];

  OutfitItem get selectedOutfit {
    return outfits.firstWhere(
      (item) => item.id == selectedOutfitId,
      orElse: () => outfits.first,
    );
  }

  int _asInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return defaultValue;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Future<void> _buyOrUseOutfit({
    required BuildContext context,
    required OutfitItem outfit,
    required Map<String, dynamic> userData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final points = _asInt(userData['points'], 0);
    final ownedOutfits = _asMap(userData['ownedOutfits']);
    final isOwned = outfit.id == UserDatabase.defaultOutfitId || ownedOutfits[outfit.id] == true;

    try {
      if (isOwned) {
        await userRef.update({
          'selectedOutfitId': outfit.id,
          'selectedOutfitModel': outfit.modelPath,
          'selectedOutfitPreview': outfit.previewImagePath,
          'characterName': UserDatabase.characterNameForOutfit(outfit.id),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!context.mounted) return;
        AppPopup.show(
          context,
          title: 'Outfit digunakan',
          message: '${outfit.name} sekarang aktif di karakter kamu.',
          type: AppPopupType.success,
        );
        return;
      }

      if (points < outfit.price) {
        AppPopup.show(
          context,
          title: 'Points belum cukup',
          message: 'Kamu butuh ${outfit.price} points untuk membeli ${outfit.name}.',
          type: AppPopupType.warning,
        );
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception('Data user tidak ditemukan');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentPoints = _asInt(data['points'], 0);
        final currentOwnedOutfits = _asMap(data['ownedOutfits']);

        if (currentPoints < outfit.price) {
          throw Exception('Points kamu belum cukup');
        }

        currentOwnedOutfits[UserDatabase.defaultOutfitId] = true;
        currentOwnedOutfits[outfit.id] = true;

        transaction.update(userRef, {
          'points': currentPoints - outfit.price,
          'ownedOutfits': currentOwnedOutfits,
          'selectedOutfitId': outfit.id,
          'selectedOutfitModel': outfit.modelPath,
          'selectedOutfitPreview': outfit.previewImagePath,
          'characterName': UserDatabase.characterNameForOutfit(outfit.id),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      await userRef.collection('notifications').add({
        'title': 'Outfit Unlocked',
        'description': '${outfit.name} berhasil dibeli dan digunakan pada karakter kamu.',
        'type': 'customize',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      AppPopup.show(
        context,
        title: 'Outfit terbuka',
        message: '${outfit.name} berhasil dibeli dan dipakai.',
        type: AppPopupType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppPopup.show(
        context,
        title: 'Gagal customize',
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppPopupType.error,
      );
    }
  }

  void _selectOutfit(String outfitId) {
    setState(() {
      selectedOutfitId = outfitId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Data user tidak ditemukan')),
          );
        }

        final userData = snapshot.data!.data()!;
        final points = _asInt(userData['points'], 0);
        final ownedOutfits = _asMap(userData['ownedOutfits']);
        final currentSelectedId = (userData['selectedOutfitId'] ?? UserDatabase.defaultOutfitId).toString();
        final currentIsValid = outfits.any((item) => item.id == currentSelectedId);

        // Ambil outfit yang sedang dipakai dari Firestore hanya sekali saat halaman dibuka.
        // Jangan sync terus-menerus, karena kalau user sedang memilih Default Character
        // sementara yang aktif masih Set Royal, preview akan dipaksa balik ke Set Royal.
        if (!_hasInitializedSelectedOutfit) {
          selectedOutfitId = currentIsValid ? currentSelectedId : UserDatabase.defaultOutfitId;
          _hasInitializedSelectedOutfit = true;
        }

        final isSelectedOwned = selectedOutfit.id == UserDatabase.defaultOutfitId ||
            ownedOutfits[selectedOutfit.id] == true;

        return Scaffold(
          body: AuthBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(height: AppSize.gap(context, 18)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSize.horizontalPadding(context)),
                    child: Row(
                      children: [
                        const AppBackButton(),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Text(
                            'Customize',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '$points pts',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSize.gap(context, 14)),
                  _previewCard(
                    context: context,
                    outfit: selectedOutfit,
                    isOwned: isSelectedOwned,
                  ),
                  SizedBox(height: AppSize.gap(context, 12)),
                  isSelectedOwned
                      ? _actionButton(
                          text: currentSelectedId == selectedOutfit.id ? 'Using' : 'Use Outfit',
                          color: const Color(0xFF7EA348),
                          onPressed: currentSelectedId == selectedOutfit.id
                              ? null
                              : () {
                                  _buyOrUseOutfit(
                                    context: context,
                                    outfit: selectedOutfit,
                                    userData: userData,
                                  );
                                },
                        )
                      : _actionButton(
                          text: 'Buy   ${selectedOutfit.price} pts',
                          color: const Color(0xFFFF8A00),
                          onPressed: () {
                            _buyOrUseOutfit(
                              context: context,
                              outfit: selectedOutfit,
                              userData: userData,
                            );
                          },
                        ),
                  SizedBox(height: AppSize.gap(context, 15)),
                  Expanded(
                    child: _bottomPanel(
                      ownedOutfits: ownedOutfits,
                      currentSelectedOutfitId: currentSelectedId,
                    ),
                  ),
                  const AppBottomNav(selectedIndex: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _previewCard({
    required BuildContext context,
    required OutfitItem outfit,
    required bool isOwned,
  }) {
    final height = AppSize.clampDouble(
      MediaQuery.sizeOf(context).height * 0.36,
      300,
      380,
    );

    return Container(
      width: AppSize.clampDouble(MediaQuery.sizeOf(context).width * 0.84, 300, 350),
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF81A98C).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 18,
            right: 18,
            bottom: 88,
            child: isOwned
                ? ModelViewer(
                    key: ValueKey(outfit.modelPath),
                    src: outfit.modelPath,
                    alt: outfit.name,
                    autoRotate: true,
                    cameraControls: true,
                    disableZoom: false,
                    backgroundColor: Colors.transparent,
                    ar: false,
                    cameraOrbit: '0deg 72deg 5m',
                    cameraTarget: '0m 1.2m 0.5m',
                  )
                : const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 190,
                        height: 0.9,
                        color: Color(0xFF41664F),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 45,
            child: Text(
              outfit.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: Text(
              isOwned ? 'Category: ${outfit.type}' : 'Locked outfit. Buy first to use this item.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 210,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: const Color(0xFF7EA348),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel({
    required Map<String, dynamic> ownedOutfits,
    required String currentSelectedOutfitId,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.horizontalPadding(context),
        0,
        AppSize.horizontalPadding(context),
        0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 26),

          const Text(
            'Outfits',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            height: 1.5,
            color: Colors.black,
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 14, bottom: 14),
              itemCount: outfits.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final outfit = outfits[index];
                final isOwned = outfit.id == UserDatabase.defaultOutfitId ||
                    ownedOutfits[outfit.id] == true;
                final isSelectedPreview = selectedOutfitId == outfit.id;
                final isUsed = currentSelectedOutfitId == outfit.id;

                return GestureDetector(
                  onTap: () => _selectOutfit(outfit.id),
                  child: OutfitBox(
                    outfit: outfit,
                    isOwned: isOwned,
                    isSelectedPreview: isSelectedPreview,
                    isUsed: isUsed,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OutfitBox extends StatelessWidget {
  final OutfitItem outfit;
  final bool isOwned;
  final bool isSelectedPreview;
  final bool isUsed;

  const OutfitBox({
    super.key,
    required this.outfit,
    required this.isOwned,
    required this.isSelectedPreview,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE880),
        borderRadius: BorderRadius.circular(12),
        border: isSelectedPreview
            ? Border.all(color: const Color(0xFF41664F), width: 3)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: isOwned
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        outfit.previewImagePath,
                        width: 62,
                        height: 62,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: Color(0xFF41664F),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          outfit.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF41664F),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '?',
                    style: TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7F7438),
                    ),
                  ),
          ),
          if (isUsed)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF7EA348),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OutfitItem {
  final String id;
  final String name;
  final String type;
  final String modelPath;
  final String previewImagePath;
  final int price;

  const OutfitItem({
    required this.id,
    required this.name,
    required this.type,
    required this.modelPath,
    required this.previewImagePath,
    required this.price,
  });
}


