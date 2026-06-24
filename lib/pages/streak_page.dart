import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/app_back_button.dart';
import 'splash_page.dart';

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  late DateTime focusedMonth;
  bool _missionOpenMarked = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    focusedMonth = DateTime(now.year, now.month, 1);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _markStreakMissionOpened(String uid) async {
    final todayKey = _dateKey(DateTime.now());
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.update({
      'missionProgress.$todayKey.mission_streak': true,
      'lastStreakOpenDate': todayKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _daysInMonth(int year, int month) {
    final firstDayNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);

    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
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

  DateTime? _tryParseDateKey(String value) {
    if (value.trim().isEmpty) return null;
    try {
      final parts = value.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  int _effectiveStreakDays({
    required int storedStreakDays,
    required String lastActiveDate,
  }) {
    if (storedStreakDays <= 0) return 0;

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    // Streak masih dianggap aktif kalau user aktif hari ini atau kemarin.
    // Kalau lewat 1 hari penuh tanpa aktivitas, streak hangus di tampilan.
    if (lastActiveDate == todayKey || lastActiveDate == yesterdayKey) {
      return storedStreakDays;
    }

    return 0;
  }

  Set<String> _currentStreakKeys({
    required int effectiveStreakDays,
    required String lastActiveDate,
  }) {
    final lastDate = _tryParseDateKey(lastActiveDate);
    if (lastDate == null || effectiveStreakDays <= 0) return <String>{};

    return List.generate(effectiveStreakDays, (index) {
      return _dateKey(lastDate.subtract(Duration(days: index)));
    }).toSet();
  }

  void _previousMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
    });
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      focusedMonth = DateTime(now.year, now.month, 1);
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

    if (!_missionOpenMarked) {
      _missionOpenMarked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markStreakMissionOpened(user.uid).catchError((_) {});
      });
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 720;
    final fireSize = compact ? 104.0 : 128.0;
    final streakFontSize = compact ? 38.0 : 44.0;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int storedStreakDays = 0;
        String lastActiveDate = '';
        Map<String, dynamic> activeDates = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          storedStreakDays = _asInt(data['streakDays'], 0);
          lastActiveDate = (data['lastActiveDate'] ?? '').toString();
          activeDates = _asMap(data['activeDates']);
        }

        final effectiveStreakDays = _effectiveStreakDays(
          storedStreakDays: storedStreakDays,
          lastActiveDate: lastActiveDate,
        );

        final currentStreakKeys = _currentStreakKeys(
          effectiveStreakDays: effectiveStreakDays,
          lastActiveDate: lastActiveDate,
        );

        return Scaffold(
          body: AuthBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(height: compact ? 12 : 19),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: const [
                        AppBackButton(),
                        SizedBox(width: 30),
                        Text(
                          'Streak',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 10),
                  Text(
                    '🔥',
                    style: TextStyle(fontSize: fireSize),
                  ),
                  SizedBox(height: compact ? 0 : 4),
                  Text(
                    '$effectiveStreakDays DAYS',
                    style: TextStyle(
                      color: const Color(0xFFFF6B2A),
                      fontSize: streakFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _calendarHeader(),
                          const SizedBox(height: 12),
                          _weekHeader(),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _calendarGrid(
                              activeDates: activeDates,
                              currentStreakKeys: currentStreakKeys,
                            ),
                          ),
                        ],
                      ),
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

  Widget _calendarHeader() {
    final now = DateTime.now();
    final isCurrentMonth = focusedMonth.year == now.year &&
        focusedMonth.month == now.month;

    return Row(
      children: [
        const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
        Flexible(
          child: GestureDetector(
            onTap: isCurrentMonth ? null : _goToCurrentMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_monthName(focusedMonth.month)} ${focusedMonth.year}',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
        ),
      ],
    );
  }

  Widget _weekHeader() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: days.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _calendarGrid({
    required Map<String, dynamic> activeDates,
    required Set<String> currentStreakKeys,
  }) {
    final now = DateTime.now();
    final year = focusedMonth.year;
    final month = focusedMonth.month;

    final int daysInMonth = _daysInMonth(year, month);
    final DateTime firstDay = DateTime(year, month, 1);

    final int startOffset = firstDay.weekday - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellExtent = ((constraints.maxHeight - 14) / 6).clamp(31.0, 42.0).toDouble();

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            mainAxisExtent: cellExtent,
          ),
          itemBuilder: (context, cellIndex) {
            final dayNumber = cellIndex - startOffset + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(year, month, dayNumber);
            final key = _dateKey(date);
            final bool hasHistory = activeDates[key] == true;
            final bool isCurrentStreak = currentStreakKeys.contains(key);
            final bool isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            final Color? fillColor = isCurrentStreak
                ? const Color(0xFFFFC20E)
                : hasHistory
                    ? const Color(0xFFD7D7D7)
                    : isToday
                        ? const Color(0xFFECECEC)
                        : Colors.transparent;

            return Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: isToday
                      ? Border.all(
                          color: Colors.black,
                          width: 1.5,
                        )
                      : null,
                ),
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.black,
                    fontWeight: isCurrentStreak || isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
