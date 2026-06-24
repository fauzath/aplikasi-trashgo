import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/trash_dataset.dart';
import '../services/trash_ai_service.dart';
import '../utils/app_popup.dart';
import '../widgets/app_bottom_nav.dart';

// Alur aksi buang sampah:
// 1) Kamera mendeteksi tempat sampah.
// 2) Kamera mendeteksi sampah di luar tempat sampah.
// 3) Sampah bergerak mendekati tempat sampah.
// 4) Sampah didekatkan sampai menyentuh zona aksi tempat sampah.
// 5) Sistem memberi status siap dibuang.
// 6) Sampah hilang dari frame setelah siap dibuang.
// 7) Sistem menyimpulkan aksi buang sampah berhasil, lalu reward + collection.

enum ScanStatus {
  loading,
  waitingForBin,
  binDetected,
  waitingTrashOutside,
  trashOutside,
  movingToBin,
  readyToDispose,
  verifyingDispose,
  trashAtMouth,
  wrongBin,
  disposed,
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TrashAiService _ai = TrashAiService();

  CameraController? _cameraController;
  CameraDescription? _cameraDescription;

  ScanStatus status = ScanStatus.loading;
  TrashItem? scannedTrash;
  List<AiDetection> detections = [];

  bool isSaving = false;
  bool _isDetecting = false;
  bool _rewardTriggered = false;

  String? _candidateTrashLabel;
  int _candidateTrashCount = 0;

  String? _lockedTrashLabel;
  String? _expectedBinLabel;

  // Bin dan sampah dikunci beberapa detik supaya saat tangan/sampah menutupi bin,
  // sistem tidak langsung reset. Ini penting untuk kasus occlusion.
  AiDetection? _lockedBinDetection;
  DateTime? _lastBinSeenAt;
  DateTime? _lastCorrectBinVisibleAt;
  AiDetection? _lastTrashDetection;

  DateTime? _trashLockedAt;
  DateTime? _mouthEnteredAt;
  bool _enteredMouthConfirmedWithFreshBin = false;

  bool _trashWasOutsideBin = false;
  bool _enteredMouthOnce = false;

  int _enteredMouthFrames = 0;
  int _missingAfterMouthFrames = 0;
  int _movingCloserFrames = 0;

  double? _lastDistanceToMouth;

  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  String _infoMessage = 'Menyiapkan kamera AI...';

  // AI cek kamera tiap 1.4 detik.
  // Ini dibuat sedang: tidak terlalu berat, tapi tidak terlalu lambat saat aksi buang.
  static const int inferenceIntervalMs = 1400;

  // Sampah harus label sama minimal 2x sebelum dikunci.
  // Jangan 3x karena interval kamera 1 detik akan terasa seperti tidak mendeteksi.
  static const int stableTrashRequiredCount = 2;

  // Sampah cukup 1 frame berada di zona aksi bin agar user tidak kesulitan
  // saat sampah ketutup tangan atau bin.
  static const int requiredMouthFrames = 1;

  // Setelah status siap dibuang, sampah harus hilang beberapa frame berturut-turut.
  // 3 frame x 1.4 detik = sekitar 4 detik validasi akhir.
  static const int requiredMissingFramesAfterMouth = 3;

  // Berapa lama posisi bin terakhir tetap dipakai walaupun bin tertutup tangan/sampah.
  static const int binMemoryMs = 30000;

  // Saat validasi sukses, bin harus masih fresh/baru terlihat.
  // Kalau kamera digoyang sampai bin hilang lama, reward tidak keluar.
  static const int successBinFreshMs = 10000;

  // Jarak harus turun minimal sekian pixel model agar dianggap bergerak mendekat.
  static const double minCloserDelta = 4.0;

  // Harus ada gerakan mendekat minimal beberapa frame sebelum boleh dianggap masuk.
  static const int requiredMovingCloserFrames = 1;

  // Minimal waktu sejak sampah terkunci sampai boleh reward.
  // Ini mencegah proses terlalu cepat karena objek hilang akibat kamera goyang.
  static const int minTrashJourneyMs = 2500;

  // Minimal waktu setelah status siap dibuang sebelum boleh dinilai hilang/berhasil.
  static const int minMouthToDisappearMs = 800;

  @override
  void initState() {
    super.initState();
    _initCameraAndAi();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _ai.close();
    super.dispose();
  }

  Future<void> _initCameraAndAi() async {
    try {
      await _ai.load();

      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraDescription = backCamera;

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      await controller.startImageStream(_processFrame);

      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        status = ScanStatus.waitingForBin;
        _infoMessage = 'Arahkan kamera ke tempat sampah terlebih dahulu.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        status = ScanStatus.waitingForBin;
        _infoMessage = 'Kamera/model gagal dibuka: $e';
      });
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _rewardTriggered || isSaving) return;

    final now = DateTime.now();
    if (now.difference(_lastInference).inMilliseconds < inferenceIntervalMs) {
      return;
    }
    _lastInference = now;

    final camera = _cameraDescription;
    if (camera == null) return;

    _isDetecting = true;
    try {
      final results = await _ai.detectCameraImage(image, camera);
      if (!mounted) return;
      _evaluateDetections(results);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _infoMessage = 'Deteksi error: $e';
      });
    } finally {
      _isDetecting = false;
    }
  }

  TrashItem? _trashByIdOrNull(String id) {
    for (final item in TrashDataset.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  AiDetection? _firstOrNull(List<AiDetection> list) {
    return list.isEmpty ? null : list.first;
  }

  void _evaluateDetections(List<AiDetection> results) {
    final filteredResults = results.where(_isDetectionInScanArea).toList();

    final trashObjects = filteredResults
        .where((d) => d.isTrash && d.score >= TrashAiService.trashThreshold)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final bins = filteredResults
        .where((d) => d.isBin && d.score >= TrashAiService.binThreshold)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // STEP 1: Kamera harus melihat tempat sampah dulu.
    // Tetapi setelah bin pernah terlihat, posisi bin disimpan sementara.
    // Jadi saat sampah/tangan menutupi bin, alur tidak langsung gagal/reset.
    final now = DateTime.now();
    final expectedBin = _expectedBinLabel;

    if (bins.isNotEmpty) {
      final binToRemember = expectedBin == null
          ? bins.first
          : _firstOrNull(bins.where((b) => b.label == expectedBin).toList());

      if (binToRemember != null) {
        _lockedBinDetection = binToRemember;
        _lastBinSeenAt = now;
        _lastCorrectBinVisibleAt = now;
      }
    }

    final hasFreshBinMemory = _lockedBinDetection != null &&
        _lastBinSeenAt != null &&
        now.difference(_lastBinSeenAt!).inMilliseconds <= binMemoryMs;

    final effectiveBins = <AiDetection>[...bins];
    if (hasFreshBinMemory) {
      final remembered = _lockedBinDetection!;
      final alreadyVisible = effectiveBins.any((b) => b.label == remembered.label);
      if (!alreadyVisible) {
        effectiveBins.add(remembered);
      }
    }

    if (effectiveBins.isEmpty) {
      setState(() {
        detections = filteredResults;
        status = ScanStatus.waitingForBin;
        _infoMessage = _lockedBinDetection == null
            ? 'Tempat sampah belum terdeteksi. Arahkan kamera ke bin.'
            : 'Bin lock habis. Arahkan lagi kamera ke tempat sampah.';
      });
      return;
    }

    // Kalau sampah sudah terkunci, cari bin yang sesuai dengan jenis sampahnya.
    final correctBin = expectedBin == null
        ? _firstOrNull(effectiveBins)
        : _firstOrNull(effectiveBins.where((b) => b.label == expectedBin).toList());

    final wrongBin = expectedBin == null
        ? null
        : _firstOrNull(bins.where((b) => b.label != expectedBin).toList());

    // STEP 2: Setelah bin terlihat, deteksi sampah di luar tempat sampah.
    if (_lockedTrashLabel == null) {
      final visibleBin = correctBin ?? effectiveBins.first;

      final outsideTrash = trashObjects.where((trash) {
        return _trashIsOutsideBin(trash, visibleBin);
      }).toList();

      // Pada kamera nyata, sampah sering muncul menutupi sebagian bin sehingga
      // fungsi outside bisa gagal. Karena itu, selama ada objek sampah yang
      // jelas terdeteksi, tetap kita kunci sebagai sampah. Status outside tetap
      // dicek lagi pada tahap berikutnya.
      if (trashObjects.isEmpty) {
        _candidateTrashLabel = null;
        _candidateTrashCount = 0;
        setState(() {
          detections = filteredResults;
          scannedTrash = null;
          status = ScanStatus.binDetected;
          _infoMessage = 'Tempat sampah terdeteksi. Sekarang tampilkan sampah di frame yang sama.';
        });
        return;
      }

      final bestTrash = outsideTrash.isNotEmpty ? outsideTrash.first : trashObjects.first;

      if (_candidateTrashLabel == bestTrash.label) {
        _candidateTrashCount++;
      } else {
        _candidateTrashLabel = bestTrash.label;
        _candidateTrashCount = 1;
      }

      if (_candidateTrashCount < stableTrashRequiredCount) {
        setState(() {
          detections = filteredResults;
          scannedTrash = null;
          status = ScanStatus.waitingTrashOutside;
          _infoMessage = 'Mengecek ulang sampah: ${_prettyName(bestTrash.label)}...';
        });
        return;
      }

      final trashItem = _trashByIdOrNull(bestTrash.label);
      final binForTrash = TrashAiService.correctBinByTrash[bestTrash.label];

      if (trashItem == null || binForTrash == null) {
        setState(() {
          detections = filteredResults;
          scannedTrash = null;
          status = ScanStatus.waitingTrashOutside;
          _infoMessage = 'Label ${bestTrash.label} belum ada di TrashDataset / mapping bin.';
        });
        return;
      }

      _lockedTrashLabel = bestTrash.label;
      _expectedBinLabel = binForTrash;
      scannedTrash = trashItem;
      _trashWasOutsideBin = true;
      _enteredMouthOnce = false;
      _enteredMouthFrames = 0;
      _missingAfterMouthFrames = 0;
      _movingCloserFrames = 0;
      _trashLockedAt = now;
      _mouthEnteredAt = null;
      _enteredMouthConfirmedWithFreshBin = false;
      _lastDistanceToMouth = _distanceToMouth(bestTrash, visibleBin);
      _lastTrashDetection = bestTrash;

      setState(() {
        detections = filteredResults;
        status = ScanStatus.trashOutside;
        _infoMessage = '${trashItem.name} terdeteksi. Dekatkan pelan ke area ${_binName(binForTrash)}.';
      });
      return;
    }

    final lockedTrashLabel = _lockedTrashLabel!;
    final binForLockedTrash = _expectedBinLabel!;
    final trashItem = scannedTrash;

    if (trashItem == null) return;

    final currentCorrectBin = _firstOrNull(
      effectiveBins.where((b) => b.label == binForLockedTrash).toList(),
    );

    final visibleCorrectBinNow = _firstOrNull(
      bins.where((b) => b.label == binForLockedTrash).toList(),
    );

    final binFreshForSuccess = visibleCorrectBinNow != null ||
        (_lastCorrectBinVisibleAt != null &&
            now.difference(_lastCorrectBinVisibleAt!).inMilliseconds <= successBinFreshMs);

    if (currentCorrectBin == null) {
      setState(() {
        detections = filteredResults;
        status = wrongBin != null ? ScanStatus.wrongBin : ScanStatus.waitingForBin;
        _infoMessage = wrongBin != null
            ? '${trashItem.name} salah tempat. Harusnya ke ${_binName(binForLockedTrash)}.'
            : '${trashItem.name} terkunci. Arahkan kamera ke ${_binName(binForLockedTrash)}.';
      });
      return;
    }

    final currentTrashList = trashObjects.where((d) => d.label == lockedTrashLabel).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final currentTrash = _firstOrNull(currentTrashList);

    // STEP 5: Setelah sampah masuk zona aksi dan status siap dibuang,
    // reward hanya kalau sampah hilang berturut-turut, bin masih fresh,
    // kamera tidak goyang drastis, dan durasinya masuk akal.
    if (_enteredMouthOnce) {
      if (currentTrash == null) {
        _missingAfterMouthFrames++;

        final mouthTimeOk = _mouthEnteredAt != null &&
            now.difference(_mouthEnteredAt!).inMilliseconds >= minMouthToDisappearMs;
        final journeyTimeOk = _trashLockedAt != null &&
            now.difference(_trashLockedAt!).inMilliseconds >= minTrashJourneyMs;
        final missingFramesOk = _missingAfterMouthFrames >= requiredMissingFramesAfterMouth;
        final canReward = _trashWasOutsideBin &&
            _enteredMouthOnce &&
            missingFramesOk &&
            mouthTimeOk &&
            journeyTimeOk &&
            binFreshForSuccess &&
            _enteredMouthConfirmedWithFreshBin;

        setState(() {
          detections = filteredResults;
          status = ScanStatus.verifyingDispose;
          _infoMessage = !binFreshForSuccess
              ? 'Sampah hilang, tapi bin tidak fresh. Jangan goyang kamera, arahkan lagi ke bin.'
              : 'Memverifikasi sampah sudah dibuang (${_missingAfterMouthFrames}/$requiredMissingFramesAfterMouth).';
        });

        if (canReward && !_rewardTriggered) {
          _rewardTriggered = true;
          _collectReward();
        }
        return;
      }

      _lastTrashDetection = currentTrash;

      if (_trashEnteredMouthArea(currentTrash, currentCorrectBin)) {
        _missingAfterMouthFrames = 0;
        _mouthEnteredAt ??= now;
        if (binFreshForSuccess) {
          _enteredMouthConfirmedWithFreshBin = true;
        }
        setState(() {
          detections = filteredResults;
          status = ScanStatus.readyToDispose;
          _infoMessage = 'Siap dibuang. Masukkan sampah sekarang sampai hilang dari frame.';
        });
        return;
      }

      if (_trashIsOutsideBin(currentTrash, currentCorrectBin)) {
        // Sampah keluar lagi, jadi ulang dari tahap mendekat.
        _enteredMouthOnce = false;
        _enteredMouthFrames = 0;
        _missingAfterMouthFrames = 0;
        _mouthEnteredAt = null;
        _enteredMouthConfirmedWithFreshBin = false;
      }
    }

    if (currentTrash == null) {
      // PENTING: jangan langsung dianggap berhasil hanya karena sampah hilang.
      // Sampah harus masuk zona aksi / siap dibuang dulu. Ini mencegah false success saat kamera goyang.
      _missingAfterMouthFrames = 0;
      setState(() {
        detections = filteredResults;
        status = ScanStatus.binDetected;
        _infoMessage = '${trashItem.name} hilang sebelum siap dibuang. Tampilkan lagi sampahnya, dekatkan ke bin, lalu tunggu status siap dibuang.';
      });
      return;
    }

    _lastTrashDetection = currentTrash;

    final visibleWrongBin = _firstOrNull(bins.where((b) => b.label != binForLockedTrash).toList());
    if (visibleWrongBin != null && _trashEnteredMouthArea(currentTrash, visibleWrongBin)) {
      setState(() {
        detections = filteredResults;
        status = ScanStatus.wrongBin;
        _infoMessage = '${trashItem.name} salah tempat. Harusnya ke ${_binName(binForLockedTrash)}.';
      });
      _enteredMouthOnce = false;
      _enteredMouthFrames = 0;
      _missingAfterMouthFrames = 0;
      return;
    }

    // STEP 4: Sampah menyentuh zona aksi tempat sampah.
    // Setelah tahap ini, sistem tidak memaksa membaca sampah tepat masuk mulut bin.
    // User cukup diminta membuang sampah, lalu sistem verifikasi sampah hilang.
    if (_trashEnteredMouthArea(currentTrash, currentCorrectBin)) {
      if (!binFreshForSuccess) {
        setState(() {
          detections = filteredResults;
          status = ScanStatus.movingToBin;
          _infoMessage = 'Bin sempat hilang. Arahkan kamera agar bin terlihat lagi sebelum membuang sampah.';
        });
        return;
      }

      // Jangan terlalu mengunci syarat gerak mendekat, karena interval AI
      // bisa melewatkan momen gerakan. Yang penting: sampah pernah masuk
      // zona aksi bin, lalu hilang setelah status siap dibuang.
      if (_trashWasOutsideBin || _movingCloserFrames >= requiredMovingCloserFrames) {
        _enteredMouthFrames++;
      } else {
        _enteredMouthFrames++;
      }

      if (_enteredMouthFrames >= requiredMouthFrames) {
        _enteredMouthOnce = true;
        _mouthEnteredAt ??= now;
        _enteredMouthConfirmedWithFreshBin = true;
      }

      setState(() {
        detections = filteredResults;
        status = ScanStatus.readyToDispose;
        _infoMessage = _enteredMouthFrames >= requiredMouthFrames
            ? 'Siap dibuang. Masukkan sampah sekarang sampai hilang dari frame.'
            : 'Sampah sudah dekat area bin (${_enteredMouthFrames}/$requiredMouthFrames). Tahan sebentar.';
      });
      return;
    }

    // STEP 3: Sampah bergerak mendekati tempat sampah.
    final distanceNow = _distanceToMouth(currentTrash, currentCorrectBin);
    final lastDistance = _lastDistanceToMouth;

    if (lastDistance != null && distanceNow < lastDistance - minCloserDelta) {
      _movingCloserFrames++;
    }

    _lastDistanceToMouth = distanceNow;
    _enteredMouthFrames = 0;
    _missingAfterMouthFrames = 0;

    final outside = _trashIsOutsideBin(currentTrash, currentCorrectBin);
    if (outside) {
      _trashWasOutsideBin = true;
    }

    setState(() {
      detections = filteredResults;
      status = _movingCloserFrames >= requiredMovingCloserFrames ? ScanStatus.movingToBin : ScanStatus.trashOutside;
      _infoMessage = _movingCloserFrames >= requiredMovingCloserFrames
          ? '${trashItem.name} bergerak mendekati ${_binName(binForLockedTrash)}. Dekatkan sampai muncul status siap dibuang.'
          : '${trashItem.name} masih di luar tempat sampah. Dekatkan perlahan ke area bin (${_movingCloserFrames}/$requiredMovingCloserFrames).';
    });
  }

  bool _isDetectionInScanArea(AiDetection detection) {
    final s = TrashAiService.inputSize.toDouble();
    final min = s * 0.04;
    final max = s * 0.96;
    final c = detection.center;
    return c.dx >= min && c.dx <= max && c.dy >= min && c.dy <= max;
  }

  bool _trashIsOutsideBin(AiDetection trash, AiDetection bin) {
    if (_isPointInsideWithMargin(trash.center, bin.box)) return false;

    final overlap = _overlapArea(trash.box, bin.box);
    final trashArea = trash.box.width * trash.box.height;
    if (trashArea <= 0) return true;

    final overlapRatio = overlap / trashArea;
    return overlapRatio < 0.15;
  }

  Rect _binMouthRect(AiDetection bin) {
    final b = bin.box;

    // Ini bukan lagi "mulut bin" yang sempit.
    // Ini adalah zona aksi tempat sampah: area sekitar bin yang cukup longgar
    // agar sampah yang ketutup tangan / blur tetap bisa divalidasi.
    final expandX = b.width * 0.42;
    final expandTop = b.height * 0.30;
    final expandBottom = b.height * 0.18;

    return Rect.fromLTRB(
      b.left - expandX,
      b.top - expandTop,
      b.right + expandX,
      b.bottom + expandBottom,
    );
  }

  bool _trashEnteredMouthArea(AiDetection trash, AiDetection bin) {
    final actionZone = _binMouthRect(bin);

    // Kalau titik tengah sampah sudah masuk zona aksi, dianggap siap dibuang.
    if (actionZone.contains(trash.center)) return true;

    final overlap = _overlapArea(trash.box, actionZone);
    final trashArea = trash.box.width * trash.box.height;
    if (trashArea <= 0) return false;

    final overlapRatio = overlap / trashArea;
    if (overlapRatio >= 0.03) return true;

    // Fallback tambahan: kalau sampah sudah sangat dekat dengan area bin,
    // tetap dianggap masuk zona aksi. Ini membantu saat box AI bergeser.
    final distance = _distanceToMouth(trash, bin);
    final nearEnough = distance <= bin.box.height * 0.95;
    final verticalOk = trash.box.bottom >= bin.box.top - (bin.box.height * 0.20);

    return nearEnough && verticalOk;
  }

  bool _trashNearMouth(AiDetection trash, AiDetection bin) {
    if (_trashEnteredMouthArea(trash, bin)) return true;

    final distance = _distanceToMouth(trash, bin);

    // Batas dibuat relatif terhadap tinggi bin supaya tetap fleksibel untuk
    // bin yang dekat/jauh dari kamera.
    return distance <= bin.box.height * 0.62;
  }

  double _distanceToMouth(AiDetection trash, AiDetection bin) {
    final mouthCenter = _binMouthRect(bin).center;
    final dx = trash.center.dx - mouthCenter.dx;
    final dy = trash.center.dy - mouthCenter.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  bool _isPointInsideWithMargin(Offset point, Rect box) {
    final marginX = box.width * 0.05;
    final marginY = box.height * 0.05;
    final innerBox = Rect.fromLTRB(
      box.left + marginX,
      box.top + marginY,
      box.right - marginX,
      box.bottom - marginY,
    );
    return innerBox.contains(point);
  }

  double _overlapArea(Rect a, Rect b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.right, b.right);
    final bottom = math.min(a.bottom, b.bottom);
    final w = math.max(0.0, right - left);
    final h = math.max(0.0, bottom - top);
    return w * h;
  }

  String _binName(String binLabel) {
    return binLabel == 'bin_organic'
        ? 'tempat sampah organik'
        : 'tempat sampah anorganik';
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

  Future<void> _collectReward() async {
    if (isSaving) return;
    if (scannedTrash == null) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    setState(() {
      isSaving = true;
      status = ScanStatus.disposed;
      _infoMessage = 'Aksi buang sampah berhasil: sampah dekat bin lalu hilang dari frame.';
    });

    final trash = scannedTrash!;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    bool isNewCollectionItem = false;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception('Data user tidak ditemukan');
        }

        final data = snapshot.data() as Map<String, dynamic>;

        final currentPoints = _asInt(data['points'], 0);
        final currentXp = _asInt(data['xp'], 0);
        final currentLevel = _asInt(data['level'], 1);
        final maxXp = _asInt(data['maxXp'], 200);
        final totalScans = _asInt(data['totalScans'], 0);

        final unlockedItems = _asMap(data['unlockedItems']);

        if (unlockedItems[trash.id] != true) {
          isNewCollectionItem = true;
          unlockedItems[trash.id] = true;
        }

        int newXp = currentXp + trash.rewardExp;
        int newLevel = currentLevel;
        int newMaxXp = maxXp;

        while (newXp >= newMaxXp) {
          newXp -= newMaxXp;
          newLevel++;
          newMaxXp += 100;
        }

        final activeDates = _asMap(data['activeDates']);
        final lastActiveDate = (data['lastActiveDate'] ?? '').toString();
        final currentStreakDays = _asInt(data['streakDays'], 0);

        final today = DateTime.now();
        final todayKey = _dateKey(today);
        final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));

        int newStreakDays = currentStreakDays;
        if (lastActiveDate != todayKey) {
          newStreakDays = lastActiveDate == yesterdayKey
              ? currentStreakDays + 1
              : 1;
        }
        activeDates[todayKey] = true;

        final missionProgress = _asMap(data['missionProgress']);
        final todayMissionProgress = _asMap(missionProgress[todayKey]);
        todayMissionProgress['mission_scan'] = true;
        todayMissionProgress['mission_sorting'] = true;
        missionProgress[todayKey] = todayMissionProgress;

        transaction.update(userRef, {
          'points': currentPoints + trash.rewardPoints,
          'xp': newXp,
          'level': newLevel,
          'maxXp': newMaxXp,
          'totalScans': totalScans + 1,
          'lastScanTrash': trash.id,
          'lastScanTrashName': trash.name,
          'lastScanCategory': trash.category,
          'unlockedItems': unlockedItems,
          'activeDates': activeDates,
          'lastActiveDate': todayKey,
          'streakDays': newStreakDays,
          'missionProgress': missionProgress,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      await userRef.collection('notifications').add({
        'title': 'Trash Disposed',
        'description':
            '${trash.name} berhasil dibuang ke tempat sampah yang sesuai. Kamu mendapatkan ${trash.rewardPoints} points dan ${trash.rewardExp} XP.',
        'type': 'scan',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (isNewCollectionItem) {
        await userRef.collection('notifications').add({
          'title': 'New Collection Unlocked',
          'description': '${trash.name} berhasil masuk ke Collection baru kamu.',
          'type': 'collection',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      setState(() {
        isSaving = false;
        status = ScanStatus.disposed;
      });

      _showSuccessDialog(
        trash: trash,
        isNewCollectionItem: isNewCollectionItem,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
        _rewardTriggered = false;
        status = ScanStatus.binDetected;
        _infoMessage = e.toString().replaceAll('Exception: ', '');
      });

      AppPopup.show(
        context,
        title: 'Scan gagal',
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppPopupType.error,
      );
    }
  }

  void _resetScan() {
    setState(() {
      status = ScanStatus.waitingForBin;
      scannedTrash = null;
      detections = [];
      isSaving = false;
      _rewardTriggered = false;
      _candidateTrashLabel = null;
      _candidateTrashCount = 0;
      _lockedTrashLabel = null;
      _expectedBinLabel = null;
      _lockedBinDetection = null;
      _lastBinSeenAt = null;
      _lastCorrectBinVisibleAt = null;
      _lastTrashDetection = null;
      _trashLockedAt = null;
      _mouthEnteredAt = null;
      _enteredMouthConfirmedWithFreshBin = false;
      _trashWasOutsideBin = false;
      _enteredMouthOnce = false;
      _enteredMouthFrames = 0;
      _missingAfterMouthFrames = 0;
      _movingCloserFrames = 0;
      _lastDistanceToMouth = null;
      _infoMessage = 'Arahkan kamera ke tempat sampah terlebih dahulu.';
    });
  }

  void _showSuccessDialog({
    required TrashItem trash,
    required bool isNewCollectionItem,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Column(
            children: const [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF7EA348),
                child: Icon(Icons.check, color: Colors.yellow, size: 40),
              ),
              SizedBox(height: 16),
              Text(
                '+[Poin] +[EXP]',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Berhasil terdeteksi buang sampah. ${trash.rewardPoints} poin dan ${trash.rewardExp} EXP ditambahkan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isNewCollectionItem
                    ? '${trash.name} baru masuk ke Collection kamu.'
                    : '${trash.name} sudah pernah tercatat di Collection kamu.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 210,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScan();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF83A54A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color get _statusColor {
    switch (status) {
      case ScanStatus.loading:
      case ScanStatus.waitingForBin:
      case ScanStatus.waitingTrashOutside:
        return const Color(0xFF8D8D8D);
      case ScanStatus.binDetected:
      case ScanStatus.readyToDispose:
      case ScanStatus.verifyingDispose:
      case ScanStatus.trashAtMouth:
        return const Color(0xFF006BA3);
      case ScanStatus.trashOutside:
      case ScanStatus.movingToBin:
        return const Color(0xFFFF5A14);
      case ScanStatus.wrongBin:
        return const Color(0xFFE84D4D);
      case ScanStatus.disposed:
        return const Color(0xFF477D4A);
    }
  }

  String get _bottomStatusText {
    switch (status) {
      case ScanStatus.loading:
        return 'Loading AI...';
      case ScanStatus.waitingForBin:
        return 'Bin not detected';
      case ScanStatus.binDetected:
        return 'Bin detected';
      case ScanStatus.waitingTrashOutside:
        return 'Checking trash...';
      case ScanStatus.trashOutside:
        return 'Trash outside bin';
      case ScanStatus.movingToBin:
        return 'Moving to bin';
      case ScanStatus.readyToDispose:
        return 'Ready to dispose';
      case ScanStatus.verifyingDispose:
        return 'Verifying dispose';
      case ScanStatus.trashAtMouth:
        return 'Trash near bin';
      case ScanStatus.wrongBin:
        return 'Wrong bin';
      case ScanStatus.disposed:
        return 'Disposed';
    }
  }

  String _prettyName(String id) {
    return id
        .split('_')
        .map((e) => e.isEmpty ? e : e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _cameraPreview() {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _scanFrame() {
    final width = MediaQuery.of(context).size.width;

    // UBAH INI:
    // makin kecil = kotak scan makin kecil
    // makin besar = kotak scan makin besar
    final frameSize = width * 0.76;

    // UBAH INI:
    // minus = kotak naik
    // plus = kotak turun
    const scanOffsetY = 40.0;

    return Center(
      child: Transform.translate(
        offset: const Offset(0, scanOffsetY),
        child: SizedBox(
          width: frameSize,
          height: frameSize,
          child: CustomPaint(
            painter: _ScannerCornerPainter(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _bottomInfoPanel() {
    final trash = scannedTrash;

    if (trash == null) {
      return Container(
        height: 88,
        width: double.infinity,
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(
          _bottomStatusText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      height: 88,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        children: [
          const SizedBox(width: 52),
          SizedBox(
            width: 40,
            height: 58,
            child: Image.asset(
              trash.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  '?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trash.category == 'Organik' ? 'Organic' : 'Anorganic',
                  style: const TextStyle(
                    color: Color(0xFF7FB0D6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  trash.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFF5A14),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 112,
            height: 88,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(42),
              ),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.yellow,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugText() {
    return Text(
      _infoMessage,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: Colors.black54,
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _resetButton() {
    return SizedBox(
      width: 54,
      height: 54,
      child: FloatingActionButton.small(
        heroTag: 'reset_scan_button',
        backgroundColor: Colors.white,
        elevation: 8,
        onPressed: _resetScan,
        child: const Icon(
          Icons.refresh_rounded,
          color: Colors.black87,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navHeight = AppBottomNav.heightFor(context);
    const bottomPanelHeight = 88.0;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final safeTop = MediaQuery.paddingOf(context).top;
          final frameSize = math.min(
            screenWidth * 0.79,
            constraints.maxHeight * 0.43,
          );

          final bottomPanelTop = constraints.maxHeight - navHeight - bottomPanelHeight;
          final rawFrameTop = (bottomPanelTop - frameSize) * 0.43;
          final minFrameTop = safeTop + 92;
          final maxFrameTop = math.max(
            minFrameTop,
            bottomPanelTop - frameSize - 18,
          );
          final frameTop = rawFrameTop
              .clamp(minFrameTop, maxFrameTop)
              .toDouble();
          final debugTop = math.max(safeTop + 12, frameTop - 50).toDouble();

          return Stack(
            children: [
              Positioned.fill(child: _cameraPreview()),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.10),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: debugTop,
                child: _debugText(),
              ),
              Positioned(
                left: (screenWidth - frameSize) / 2,
                top: frameTop,
                child: _scanFrame(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: navHeight,
                child: _bottomInfoPanel(),
              ),
              Positioned(
                right: 22,
                bottom: navHeight + bottomPanelHeight + 16,
                child: _resetButton(),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(selectedIndex: 1),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  final Color color;

  const _ScannerCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const radius = 28.0;
    const cornerLength = 52.0;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );

    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rect, outlinePaint);

    final path = Path();

    path.moveTo(0, cornerLength);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(cornerLength, 0);

    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, cornerLength);

    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(size.width - cornerLength, size.height);

    path.moveTo(cornerLength, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}