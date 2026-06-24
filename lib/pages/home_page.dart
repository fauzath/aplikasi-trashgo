import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../services/user_database.dart';
import '../utils/responsive_size.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/profile_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  int _asInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return defaultValue;
  }

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

  String _rankFromLeaderboard({
    required QuerySnapshot<Map<String, dynamic>>? snapshot,
    required String uid,
    required String fallbackRank,
  }) {
    final cleanFallback = fallbackRank.trim();

    if (snapshot == null || snapshot.docs.isEmpty) {
      return cleanFallback.isEmpty ? '-' : cleanFallback;
    }

    final index = snapshot.docs.indexWhere((doc) => doc.id == uid);
    if (index < 0) {
      return cleanFallback.isEmpty ? '-' : cleanFallback;
    }

    return '${index + 1}';
  }


  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int _effectiveStreakDays(Map<String, dynamic> data) {
    final storedStreak = _asInt(data['streakDays'], 0);
    if (storedStreak <= 0) return 0;

    final lastActiveDate = _asString(data['lastActiveDate'], '');
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    if (lastActiveDate == todayKey || lastActiveDate == yesterdayKey) {
      return storedStreak;
    }

    return 0;
  }

  String _displayCharacterName(String value, String outfitId) {
    return UserDatabase.displayCharacterName(value, outfitId: outfitId);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Data user tidak ditemukan',
                style: TextStyle(fontSize: 17),
              ),
            ),
          );
        }

        final data = snapshot.data!.data()!;

        final fullName = _asString(data['fullName'], '[Full Name]');
        final email = _asString(data['email'], user.email ?? '[E-Mail]');
        final profileImageBase64 = _asString(data['profileImageBase64'], '');

        final selectedOutfitId = _asString(
          data['selectedOutfitId'],
          UserDatabase.defaultOutfitId,
        );

        final rawCharacterName = _asString(
          data['characterName'],
          'Default Character',
        );

        final rawCharacterModel = _asString(
          data['selectedOutfitModel'],
          UserDatabase.modelPathForOutfit(selectedOutfitId),
        );

        final rawCharacterPreview = _asString(
          data['selectedOutfitPreview'],
          UserDatabase.previewPathForOutfit(selectedOutfitId),
        );

        final bool isValidOutfit = UserDatabase.validOutfitIds.contains(selectedOutfitId) &&
            UserDatabase.validModelPaths.contains(rawCharacterModel) &&
            UserDatabase.validPreviewPaths.contains(rawCharacterPreview);

        final characterModel = isValidOutfit
            ? rawCharacterModel
            : UserDatabase.defaultModelPath;

        final characterPreview = isValidOutfit
            ? rawCharacterPreview
            : UserDatabase.defaultPreviewPath;

        final characterName = isValidOutfit
            ? _displayCharacterName(rawCharacterName, selectedOutfitId)
            : 'Default Character';

        final points = _asInt(data['points'], 0);
        final level = _asInt(data['level'], 1);
        final currentXp = _asInt(data['xp'], 0);
        final maxXp = _asInt(data['maxXp'], 200);
        final rank = _asString(data['rank'], '-');
        final streakDays = _effectiveStreakDays(data);

        final double progress = maxXp == 0 ? 0 : currentXp / maxXp;
        final imageBytes = _decodeBase64Image(profileImageBase64);

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = MediaQuery.sizeOf(context).width;
                        final height = constraints.maxHeight;
                        final smallPhone = AppSize.isSmallPhone(context);
                        final horizontalPadding = AppSize.horizontalPadding(context);

                        final topPadding = AppSize.clampDouble(
                          height * 0.035,
                          22,
                          34,
                        );

                        // Bagian statistik ditahan di bawah supaya tidak kelihatan
                        // seperti mengambang di tengah layar Android 11.
                        final bottomContentHeight = AppSize.clampDouble(
                          height * (smallPhone ? 0.365 : 0.35),
                          286,
                          325,
                        );

                        final characterTop = topPadding + (smallPhone ? 78 : 88);
                        final characterBottom = bottomContentHeight + 8;
                        final characterHeight = AppSize.clampDouble(
                          height - characterTop - characterBottom,
                          230,
                          width <= 390 ? 365 : 405,
                        );

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: horizontalPadding,
                              right: horizontalPadding,
                              top: topPadding,
                              child: _header(
                                context: context,
                                fullName: fullName,
                                email: email,
                                imageBytes: imageBytes,
                              ),
                            ),

                            Positioned(
                              left: 0,
                              right: 0,
                              top: characterTop,
                              height: characterHeight,
                              child: TrashCharacter(
                                modelPath: characterModel,
                                previewImagePath: characterPreview,
                                height: characterHeight,
                              ),
                            ),

                            Positioned(
                              left: horizontalPadding,
                              right: horizontalPadding,
                              bottom: smallPhone ? 18 : 24,
                              child: _homeBottomContent(
                                context: context,
                                characterName: characterName,
                                points: points,
                                level: level,
                                progress: progress,
                                currentXp: currentXp,
                                maxXp: maxXp,
                                rank: rank,
                                streakDays: streakDays,
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _homeBottomContent({
    required BuildContext context,
    required String characterName,
    required int points,
    required int level,
    required double progress,
    required int currentXp,
    required int maxXp,
    required String rank,
    required int streakDays,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _characterInfo(
          context: context,
          characterName: characterName,
        ),
        SizedBox(height: AppSize.gap(context, 16)),
        _pointsAndLevel(
          points: points,
          level: level,
        ),
        SizedBox(height: AppSize.gap(context, 12)),
        _xpBar(progress),
        SizedBox(height: AppSize.gap(context, 8)),
        Text(
          '$currentXp XP / $maxXp XP',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        SizedBox(height: AppSize.gap(context, 18)),
        _rankAndStreakCard(
          context: context,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          rank: rank,
          streakDays: streakDays,
        ),
      ],
    );
  }

  Widget _header({
    required BuildContext context,
    required String fullName,
    required String email,
    required Uint8List? imageBytes,
  }) {
    final avatarSize = AppSize.isSmallPhone(context) ? 66.0 : 74.0;
    final notificationSize = AppSize.isSmallPhone(context) ? 46.0 : 50.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            showProfileDialog(
              context: context,
              fullName: fullName,
              email: email,
            );
          },
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              image: imageBytes == null
                  ? null
                  : DecorationImage(
                      image: MemoryImage(imageBytes),
                      fit: BoxFit.cover,
                    ),
            ),
            child: imageBytes == null
                ? const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF5B5B5B),
                    size: 30,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello,',
                style: TextStyle(
                  color: Color(0xFF006C93),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                fullName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFFF6A2A),
                  fontSize: 22,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/notification');
          },
          child: Container(
            width: notificationSize,
            height: notificationSize,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC400),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
      ],
    );
  }

  Widget _characterInfo({
    required BuildContext context,
    required String characterName,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            characterName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/customize');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFA8C48C),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Customize',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pointsAndLevel({
    required int points,
    required int level,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text(
            'Points',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$points',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD84D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const Spacer(),
          const Text(
            'Level',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$level',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.eco_rounded,
            color: Color(0xFF00B84A),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _xpBar(double progress) {
    final double safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 14,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          FractionallySizedBox(
            widthFactor: safeProgress,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF257E87),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankAndStreakCard({
    required BuildContext context,
    required String userId,
    required String rank,
    required int streakDays,
  }) {
    final hasStreak = streakDays > 0;

    return Container(
      height: AppSize.isSmallPhone(context) ? 88 : 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/leaderboard');
              },
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF06C4D4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _liveRankText(
                            userId: userId,
                            fallbackRank: rank,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'RANK',
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '🏆',
                      style: TextStyle(fontSize: 48),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/streak');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasStreak ? '$streakDays DAYS' : '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: hasStreak ? 17 : 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: hasStreak ? 0.8 : 0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'STREAK',
                          style: TextStyle(
                            fontSize: 15,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 48),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveRankText({
    required String userId,
    required String fallbackRank,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        final rankText = _rankFromLeaderboard(
          snapshot: snapshot.data,
          uid: userId,
          fallbackRank: fallbackRank,
        );

        final hasRank = rankText.trim().isNotEmpty && rankText != '-';

        return Text(
          hasRank ? rankText : '-',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: hasRank ? 24 : 23,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }

  Widget _smallMinus() {
    return Container(
      width: 14,
      height: 4,
      color: Colors.black,
    );
  }
}

class TrashCharacter extends StatelessWidget {
  final String modelPath;
  final String previewImagePath;
  final double height;

  const TrashCharacter({
    super.key,
    required this.modelPath,
    required this.previewImagePath,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final width = AppSize.clampDouble(
      MediaQuery.sizeOf(context).width * 0.76,
      260,
      330,
    );

    return Center(
      child: SizedBox(
        height: height,
        width: width,
        child: ModelViewer(
          key: ValueKey(modelPath),
          src: modelPath,
          alt: 'TrashGo Character',
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
          backgroundColor: Colors.transparent,
          ar: false,
          cameraOrbit: '0deg 72deg 5m',
          cameraTarget: '0m 1.2m 0.5m',
        ),
      ),
    );
  }
}
