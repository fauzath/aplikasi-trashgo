import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/app_back_button.dart';
import '../widgets/app_bottom_nav.dart';
import 'splash_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: const [
                    AppBackButton(),
                    SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _globalHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('points', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Gagal memuat leaderboard:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }

                    final users = (snapshot.data?.docs ?? []).map((doc) {
                      final data = doc.data();

                      return LeaderboardUser(
                        uid: doc.id,
                        fullName: _asString(data['fullName'], 'Name'),
                        points: _asInt(data['points'], 0),
                        xp: _asInt(data['xp'], 0),
                        level: _asInt(data['level'], 1),
                        profileImageBase64: _asString(
                          data['profileImageBase64'],
                          '',
                        ),
                      );
                    }).toList();

                    final topOne = users.isNotEmpty ? users[0] : null;
                    final topTwo = users.length > 1 ? users[1] : null;
                    final topThree = users.length > 2 ? users[2] : null;
                    final restUsers = users.length > 3
                        ? users.sublist(3)
                        : <LeaderboardUser>[];

                    return Column(
                      children: [
                        SizedBox(
                          height: 312,
                          child: _podium(
                            topOne: topOne,
                            topTwo: topTwo,
                            topThree: topThree,
                          ),
                        ),
                        Expanded(
                          child: _rankingPanel(restUsers),
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
  }

  Widget _globalHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 29),
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF7E9F43),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_rounded, color: Colors.white, size: 22),
            SizedBox(width: 9),
            Text(
              'Global Ranking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podium({
    required LeaderboardUser? topOne,
    required LeaderboardUser? topTwo,
    required LeaderboardUser? topThree,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _podiumBlock(
                    number: '2',
                    height: 112,
                    color: const Color(0xFF3297CD),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _podiumBlock(
                    number: '1',
                    height: 164,
                    color: const Color(0xFFFFC20E),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _podiumBlock(
                    number: '3',
                    height: 98,
                    color: const Color(0xFF5E964A),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: _podiumProfile(
              user: topOne,
              avatarSize: 72,
              width: 126,
              isChampion: true,
            ),
          ),
          Positioned(
            top: 93,
            left: 22,
            child: _podiumProfile(
              user: topTwo,
              avatarSize: 58,
              width: 96,
            ),
          ),
          Positioned(
            top: 106,
            right: 22,
            child: _podiumProfile(
              user: topThree,
              avatarSize: 58,
              width: 96,
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumProfile({
    required LeaderboardUser? user,
    required double avatarSize,
    required double width,
    bool isChampion = false,
  }) {
    final String name = user?.fullName ?? '-';
    final String points = user == null ? '-' : '${user.points} pts';
    final Uint8List? imageBytes = _decodeBase64Image(
      user?.profileImageBase64 ?? '',
    );

    return SizedBox(
      width: width,
      child: Column(
        children: [
          if (isChampion) ...[
            const Text(
              '👑',
              style: TextStyle(fontSize: 23, height: 0.9),
            ),
            const SizedBox(height: 2),
          ],
          AppProfileAvatar(
            imageBytes: imageBytes,
            size: avatarSize,
            radius: isChampion ? 7 : 6,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            points,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Color(0xFF005B85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumBlock({
    required String number,
    required double height,
    required Color color,
  }) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _rankingPanel(List<LeaderboardUser> restUsers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: restUsers.isEmpty
          ? Column(
              children: const [
                _EmptyRankingRow(rank: 4),
                SizedBox(height: 10),
                _EmptyRankingRow(rank: 5),
                Spacer(),
                Text(
                  'Belum ada ranking lainnya',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
              ],
            )
          : ListView.separated(
              itemCount: restUsers.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final user = restUsers[index];
                final rank = index + 4;

                return LeaderboardListItem(
                  rank: rank,
                  user: user,
                  imageBytes: _decodeBase64Image(user.profileImageBase64),
                );
              },
            ),
    );
  }
}

class LeaderboardUser {
  final String uid;
  final String fullName;
  final int points;
  final int xp;
  final int level;
  final String profileImageBase64;

  const LeaderboardUser({
    required this.uid,
    required this.fullName,
    required this.points,
    required this.xp,
    required this.level,
    required this.profileImageBase64,
  });
}

class LeaderboardListItem extends StatelessWidget {
  final int rank;
  final LeaderboardUser user;
  final Uint8List? imageBytes;

  const LeaderboardListItem({
    super.key,
    required this.rank,
    required this.user,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = rank.isEven
        ? const Color(0xFFFFBD72)
        : const Color(0xFFFFE880);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppProfileAvatar(
            imageBytes: imageBytes,
            size: 46,
            radius: 7,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Level ${user.level} • ${user.xp} XP',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${user.points} pts',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRankingRow extends StatelessWidget {
  final int rank;

  const _EmptyRankingRow({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Colors.black38,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black38,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '- pts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class AppProfileAvatar extends StatelessWidget {
  final Uint8List? imageBytes;
  final double size;
  final double radius;

  const AppProfileAvatar({
    super.key,
    required this.imageBytes,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? Icon(
              Icons.camera_alt,
              color: const Color(0xFF5B5B5B),
              size: size * 0.33,
            )
          : Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );
  }
}
