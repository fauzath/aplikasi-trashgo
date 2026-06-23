import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _displayed = DateTime(2026, 6);

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Flame + streak hero
              Expanded(
                flex: 45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 100)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${gd.streak} ', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.accentOrange, fontWeight: FontWeight.w700)),
                        Text('DAYS', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.accentOrange)),
                      ],
                    ),
                  ],
                ),
              ),
              // Calendar panel
              Expanded(
                flex: 55,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      // Header
                      Row(children: [
                        Text('Calendars', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                          child: Text(_monthLabel(_displayed),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // Day grid
                      Expanded(child: _CalendarGrid(month: _displayed, activeDays: gd.activeDays)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.scan);
          if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.trashdex);
          if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Set<DateTime> activeDays;

  const _CalendarGrid({required this.month, required this.activeDays});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Detect run streaks for highlighting
    final rows = <List<int?>>[];
    var row = <int?>[...List.filled(firstDay.weekday % 7, null)];
    for (int d = 1; d <= daysInMonth; d++) {
      row.add(d);
      if (row.length == 7) { rows.add(row); row = []; }
    }
    if (row.isNotEmpty) {
      while (row.length < 7) row.add(null);
      rows.add(row);
    }

    return Column(
      children: rows.map((r) => Expanded(
        child: Row(
          children: r.map((day) {
            if (day == null) return const Expanded(child: SizedBox());
            final dt = DateTime(month.year, month.month, day);
            final isActive = activeDays.any((a) => a.year == dt.year && a.month == dt.month && a.day == dt.day);
            return Expanded(
              child: _DayCell(day: day, isActive: isActive),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isActive;
  const _DayCell({required this.day, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentYellow : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          color: isActive ? AppColors.textDark : AppColors.textMedium,
        ),
      ),
    );
  }
}
