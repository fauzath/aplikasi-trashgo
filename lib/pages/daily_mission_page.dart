import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_popup.dart';
import '../widgets/app_bottom_nav.dart';
import 'splash_page.dart';

class DailyMissionPage extends StatelessWidget {
  const DailyMissionPage({super.key});

  String get todayKey => _dateKey(DateTime.now());

  String get yesterdayKey => _dateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      );

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  final List<MissionItem> missions = const [
    MissionItem(
      id: 'mission_login',
      description: 'Login ke aplikasi hari ini',
      points: 50,
      exp: 20,
      icon: Icons.login,
      requirement: 'Buka aplikasi hari ini',
      needsScan: false,
    ),
    MissionItem(
      id: 'mission_scan',
      description: 'Lakukan scan sampah berhasil',
      points: 100,
      exp: 40,
      icon: Icons.center_focus_weak,
      requirement: 'Reward bisa diklaim setelah scan berhasil',
      needsScan: true,
    ),
    MissionItem(
      id: 'mission_collection',
      description: 'Buka collection sampah kamu',
      points: 75,
      exp: 30,
      icon: Icons.layers,
      requirement: 'Buka halaman Collection hari ini',
      needsScan: false,
    ),
    MissionItem(
      id: 'mission_streak',
      description: 'Cek streak harian kamu',
      points: 75,
      exp: 30,
      icon: Icons.local_fire_department,
      requirement: 'Buka halaman Streak hari ini',
      needsScan: false,
    ),
    MissionItem(
      id: 'mission_sorting',
      description: 'Pilah sampah sesuai kategori',
      points: 150,
      exp: 60,
      icon: Icons.recycling,
      requirement: 'Berhasil buang sampah ke bin yang sesuai',
      needsScan: true,
    ),
  ];

  Future<void> claimMission({
    required BuildContext context,
    required MissionItem mission,
    required Map<String, dynamic> currentUserData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception('Data user tidak ditemukan');
        }

        final data = snapshot.data() as Map<String, dynamic>;

        final completedMissions = Map<String, dynamic>.from(
          data['completedMissions'] ?? {},
        );
        final todayCompleted = Map<String, dynamic>.from(
          completedMissions[todayKey] ?? {},
        );

        if (todayCompleted[mission.id] == true) {
          throw Exception('Misi ini sudah diklaim hari ini');
        }

        final missionProgress = Map<String, dynamic>.from(
          data['missionProgress'] ?? {},
        );
        final todayProgress = Map<String, dynamic>.from(
          missionProgress[todayKey] ?? {},
        );

        final isEligible = mission.id == 'mission_login' || todayProgress[mission.id] == true;
        if (!isEligible) {
          throw Exception('Misi ini belum selesai. Jalankan aksinya dulu.');
        }

        final currentPoints = _asInt(data['points'], 0);
        final currentXp = _asInt(data['xp'], 0);
        final currentLevel = _asInt(data['level'], 1);
        final currentMaxXp = _asInt(data['maxXp'], 200);

        int newXp = currentXp + mission.exp;
        int newLevel = currentLevel;
        int newMaxXp = currentMaxXp;

        while (newXp >= newMaxXp) {
          newXp -= newMaxXp;
          newLevel++;
          newMaxXp += 100;
        }

        final lastActiveDate = (data['lastActiveDate'] ?? '').toString();
        final currentStreak = _asInt(data['streakDays'], 0);
        final activeDates = Map<String, dynamic>.from(data['activeDates'] ?? {});

        int newStreak = currentStreak;
        if (activeDates[todayKey] != true) {
          if (lastActiveDate == yesterdayKey) {
            newStreak = currentStreak + 1;
          } else {
            newStreak = 1;
          }
          activeDates[todayKey] = true;
        }

        todayCompleted[mission.id] = true;
        completedMissions[todayKey] = todayCompleted;

        transaction.update(userRef, {
          'points': currentPoints + mission.points,
          'xp': newXp,
          'level': newLevel,
          'maxXp': newMaxXp,
          'streakDays': newStreak,
          'lastActiveDate': todayKey,
          'activeDates': activeDates,
          'completedMissions': completedMissions,
          'lastMissionDate': todayKey,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      await userRef.collection('notifications').add({
        'title': 'Mission Completed',
        'description':
            'Kamu menyelesaikan "${mission.description}" dan mendapatkan ${mission.points} points + ${mission.exp} XP.',
        'type': 'mission',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      AppPopup.show(
        context,
        title: 'Mission berhasil',
        message: 'Reward mission sudah masuk ke akun kamu.',
        type: AppPopupType.success,
      );
    } catch (e) {
      if (!context.mounted) return;

      AppPopup.show(
        context,
        title: 'Mission belum bisa diklaim',
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppPopupType.warning,
      );
    }
  }

  static int _asInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return defaultValue;
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

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 38),
              const Center(
                child: Text(
                  'Daily Mission',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('Data user tidak ditemukan'));
                    }

                    final data = snapshot.data!.data()!;
                    final completedMissions = Map<String, dynamic>.from(
                      data['completedMissions'] ?? {},
                    );
                    final todayCompleted = Map<String, dynamic>.from(
                      completedMissions[todayKey] ?? {},
                    );
                    final missionProgress = Map<String, dynamic>.from(
                      data['missionProgress'] ?? {},
                    );
                    final todayProgress = Map<String, dynamic>.from(
                      missionProgress[todayKey] ?? {},
                    );

                    final completedCount = missions
                        .where((mission) => todayCompleted[mission.id] == true)
                        .length;

                    return Column(
                      children: [
                        _progressSummary(completedCount),
                        const SizedBox(height: 15),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            itemCount: missions.length,
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 10);
                            },
                            itemBuilder: (context, index) {
                              final mission = missions[index];
                              final isClaimed = todayCompleted[mission.id] == true;
                              final isEligible = mission.id == 'mission_login' ||
                                  todayProgress[mission.id] == true;

                              return MissionCard(
                                mission: mission,
                                isClaimed: isClaimed,
                                isEligible: isEligible,
                                onClaim: () {
                                  claimMission(
                                    context: context,
                                    mission: mission,
                                    currentUserData: data,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const AppBottomNav(selectedIndex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressSummary(int completedCount) {
    final total = missions.length;
    final progress = total == 0 ? 0.0 : completedCount / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today Progress',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$completedCount / $total',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFE6E6E6),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7EA348)),
            ),
          ),
        ],
      ),
    );
  }
}

class MissionItem {
  final String id;
  final String description;
  final int points;
  final int exp;
  final IconData icon;
  final String requirement;
  final bool needsScan;

  const MissionItem({
    required this.id,
    required this.description,
    required this.points,
    required this.exp,
    required this.icon,
    required this.requirement,
    required this.needsScan,
  });
}

class MissionCard extends StatelessWidget {
  final MissionItem mission;
  final bool isClaimed;
  final bool isEligible;
  final VoidCallback onClaim;

  const MissionCard({
    super.key,
    required this.mission,
    required this.isClaimed,
    required this.isEligible,
    required this.onClaim,
  });

  String get _buttonText {
    if (isClaimed) return 'Done';
    if (!isEligible) return 'Locked';
    return 'Claim';
  }

  Color get _buttonColor {
    if (isClaimed) return const Color(0xFF7EA348);
    if (!isEligible) return const Color(0xFF9B9B9B);
    return const Color(0xFF006BA3);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isClaimed ? const Color(0xFFE8E8E8) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isClaimed
              ? Colors.transparent
              : isEligible
                  ? const Color(0xFFFFC400)
                  : const Color(0xFFD8D8D8),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEligible || isClaimed
                  ? const Color(0xFFFFE880)
                  : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              mission.icon,
              color: Colors.black,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mission.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isClaimed ? 'Selesai hari ini' : mission.requirement,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isEligible ? const Color(0xFF41664F) : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${mission.points} pts • +${mission.exp} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF6B2A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            height: 38,
            child: ElevatedButton(
              onPressed: isClaimed || !isEligible ? null : onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
                disabledBackgroundColor: _buttonColor,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                _buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
