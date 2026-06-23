import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/game_data_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

enum ScanStage { stage1Scanning, stage1Failed, stage1Success, stage2Searching, stage2BinFound, stage2Completed }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  ScanStage _stage = ScanStage.stage1Scanning;
  Timer? _timer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startStage1();
  }

  void _startStage1() {
    setState(() => _stage = ScanStage.stage1Scanning);
    // Simulate 3s scan – 20% chance failure, 80% success
    _timer = Timer(const Duration(seconds: 3), () {
      final fail = DateTime.now().millisecond % 5 == 0;
      if (fail) {
        setState(() => _stage = ScanStage.stage1Failed);
      } else {
        setState(() => _stage = ScanStage.stage1Success);
        _startStage2();
      }
    });
  }

  void _startStage2() {
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _stage = ScanStage.stage2Searching);
      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _stage = ScanStage.stage2BinFound);
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _stage = ScanStage.stage2Completed);
          _onScanSuccess();
        });
      });
    });
  }

  void _onScanSuccess() {
    final gd = context.read<GameDataProvider>();
    gd.addReward(xp: 50, pts: 100);
    gd.unlockTrashItem('plastic_bottle');
    gd.markToday();
    _showSuccessModal();
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessModal(onDone: () {
        Navigator.of(context).pop();
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }),
    );
  }

  void _rescan() {
    setState(() => _stage = ScanStage.stage1Scanning);
    _startStage1();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (_stage) {
      case ScanStage.stage2Searching: return AppColors.scanOrangeRed;
      case ScanStage.stage2BinFound: return AppColors.scanBlue;
      case ScanStage.stage2Completed: return AppColors.scanGreen;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Simulated camera background
          Container(color: const Color(0xFF888888)),
          // Dimmed overlay
          Container(color: Colors.black.withOpacity(0.25)),
          // Scan frame
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: _stage == ScanStage.stage1Scanning ? _pulse.value : 1.0,
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderColor, width: 3),
                    color: Colors.white.withOpacity(0.08),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(
                      'assets/images/charak_botol.png',
                      fit: BoxFit.contain,
                      opacity: const AlwaysStoppedAnimation(0.5),
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white38, size: 80),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom info panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _bottomPanel(),
            ),
          ),
          // Stage 1 failure modal
          if (_stage == ScanStage.stage1Failed)
            _NotDetectedModal(onRescan: _rescan),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.trashdex);
          if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _bottomPanel() {
    switch (_stage) {
      case ScanStage.stage1Scanning:
        return Center(child: Text('Scanning...', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textLight)));
      case ScanStage.stage1Failed:
        return Center(child: Text('Scanning...', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textLight)));
      case ScanStage.stage1Success:
      case ScanStage.stage2Searching:
      case ScanStage.stage2BinFound:
      case ScanStage.stage2Completed:
        return Row(
          children: [
            SizedBox(
              width: 40,
              child: Image.asset(AppAssets.charakBottle, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.delete_outline, color: AppColors.textMedium)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Anorganic', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.scanBlue)),
              Text('Plastic Bottle', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentOrange)),
            ]),
            const Spacer(),
            _ThrowButton(stage: _stage),
          ],
        );
    }
  }
}

class _ThrowButton extends StatelessWidget {
  final ScanStage stage;
  const _ThrowButton({required this.stage});

  Color get _color {
    if (stage == ScanStage.stage2BinFound) return AppColors.scanBlue;
    if (stage == ScanStage.stage2Completed) return AppColors.scanGreen;
    return AppColors.accentOrange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      child: const Icon(Icons.recycling, color: Colors.white, size: 34),
    );
  }
}

class _NotDetectedModal extends StatelessWidget {
  final VoidCallback onRescan;
  const _NotDetectedModal({required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.accentYellow, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: AppColors.primaryGreen, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Trash Not Detected', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Text(
              'No trash object found in frame. Please rescan and point the camera correctly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRescan,
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(25)),
                alignment: Alignment.center,
                child: Text('Rescan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accentYellow)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SuccessModal extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessModal({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.scanGreen, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Action Verified!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('+50 XP  •  +100 Points', style: GoogleFonts.poppins(fontSize: 15, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Plastic Bottle unlocked in Trashdex!', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(25)),
              alignment: Alignment.center,
              child: Text('Back to Home', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}
