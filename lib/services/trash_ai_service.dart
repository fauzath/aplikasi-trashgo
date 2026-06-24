import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AiDetection {
  final String label;
  final double score;
  final Rect box; // koordinat model: 0..inputSize

  const AiDetection({
    required this.label,
    required this.score,
    required this.box,
  });

  Offset get center => Offset(
        box.left + box.width / 2,
        box.top + box.height / 2,
      );

  bool get isBin => TrashAiService.binLabels.contains(label);
  bool get isTrash => TrashAiService.trashLabels.contains(label);

  @override
  String toString() {
    return 'AiDetection(label: $label, score: ${score.toStringAsFixed(2)}, box: $box)';
  }
}

class TrashAiService {
  static const String modelAsset = 'assets/models/best_int8.tflite';
  static const String labelsAsset = 'assets/models/labels.txt';

  // Urutan label harus sama dengan assets/models/labels.txt.
  // Labels otomatis dinormalisasi ke lowercase + underscore.
  static const Set<String> binLabels = {
    'bin_inorganic',
    'bin_organic',
  };

  static const Set<String> trashLabels = {
    'can',
    'cardboard',
    'dry_leaves',
    'food_waste',
    'glass_bottle',
    'paper',
    'plastic_bag',
    'plastic_bottle',
  };

  static const Map<String, String> correctBinByTrash = {
    'dry_leaves': 'bin_organic',
    'food_waste': 'bin_organic',
    'can': 'bin_inorganic',
    'cardboard': 'bin_inorganic',
    'glass_bottle': 'bin_inorganic',
    'paper': 'bin_inorganic',
    'plastic_bag': 'bin_inorganic',
    'plastic_bottle': 'bin_inorganic',
  };

  // Threshold dibuat lebih ketat supaya tidak gampang salah deteksi.
  // Kalau terlalu sering tidak terdeteksi, turunkan sedikit di sini.
  static const double trashThreshold = 0.45;
  static const double binThreshold = 0.35;
  static const double nmsThreshold = 0.45;

  Interpreter? _interpreter;
  List<String> _labels = [];
  int _inputSize = 416;

  // Dipakai oleh UI untuk menghitung area scan.
  // Static supaya bisa dipanggil dari scan_page tanpa error.
  static int inputSize = 416;

  int get modelInputSize => _inputSize;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> load() async {
    if (_interpreter != null) return;

    final labelsRaw = await rootBundle.loadString(labelsAsset);
    _labels = labelsRaw
        .split('\n')
        .map((e) => _normalizeLabel(e))
        .where((e) => e.isNotEmpty)
        .toList();

    final options = InterpreterOptions()..threads = 2;

    _interpreter = await Interpreter.fromAsset(modelAsset, options: options);
    _interpreter!.allocateTensors();

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    final inputShape = inputTensor.shape;
    final outputShape = outputTensor.shape;

    if (inputShape.length >= 3) {
      _inputSize = inputShape[1];
      TrashAiService.inputSize = _inputSize;
    }

    debugPrint('======= TRASHGO AI DEBUG =======');
    debugPrint('Labels count: ${_labels.length}');
    debugPrint('Labels: $_labels');
    debugPrint('Input shape: $inputShape');
    debugPrint('Output shape: $outputShape');
    debugPrint('Input type: ${inputTensor.type}');
    debugPrint('Output type: ${outputTensor.type}');
    debugPrint('Input size used: $_inputSize');
    debugPrint('================================');

    if (outputShape.length == 3) {
      final channelsFirst = outputShape[1] < outputShape[2];
      final channels = channelsFirst ? outputShape[1] : outputShape[2];
      final modelClassCount = channels - 4;
      if (modelClassCount != _labels.length) {
        throw Exception(
          'Jumlah labels.txt tidak cocok. Model punya $modelClassCount class, '
          'labels.txt punya ${_labels.length}. Cek urutan/isi labels.txt.',
        );
      }
    }
  }

  static String _normalizeLabel(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_');
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<List<AiDetection>> detectCameraImage(
    CameraImage cameraImage,
    CameraDescription camera,
  ) async {
    final interpreter = _interpreter;
    if (interpreter == null || _labels.isEmpty) return [];

    img.Image rgbImage = _cameraImageToImage(cameraImage);

    // Rotasi kamera Android portrait.
    if (camera.sensorOrientation == 90) {
      rgbImage = img.copyRotate(rgbImage, angle: 90);
    } else if (camera.sensorOrientation == 270) {
      rgbImage = img.copyRotate(rgbImage, angle: -90);
    } else if (camera.sensorOrientation == 180) {
      rgbImage = img.copyRotate(rgbImage, angle: 180);
    }

    final resized = img.copyResize(
      rgbImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);

    final input = _createInput(resized, inputTensor);
    final output = _createOutput(outputTensor.shape, outputTensor.type);

    interpreter.run(input, output);

    final decoded = _decodeOutput(output, outputTensor);

    // Debug ringan: hanya top result. Bisa hapus kalau sudah final.
    if (decoded.isNotEmpty) {
      debugPrint('Top AI: ${decoded.take(3).toList()}');
    }

    return decoded;
  }

  dynamic _createInput(img.Image image, Tensor inputTensor) {
    final type = inputTensor.type;
    final scale = inputTensor.params.scale;
    final zeroPoint = inputTensor.params.zeroPoint;

    // Format YOLO TFLite dari Ultralytics: [1, inputSize, inputSize, 3]
    return List.generate(1, (_) {
      return List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final p = image.getPixel(x, y);
          final r = p.r.toDouble() / 255.0;
          final g = p.g.toDouble() / 255.0;
          final b = p.b.toDouble() / 255.0;

          if (type == TensorType.float32 || type == TensorType.float16) {
            return [r, g, b];
          }

          int q(double value) {
            if (scale == 0) return value.round();
            return (value / scale + zeroPoint).round();
          }

          return [q(r), q(g), q(b)];
        });
      });
    });
  }

  dynamic _createOutput(List<int> shape, TensorType type) {
    dynamic make(int dim) {
      if (dim == shape.length - 1) {
        if (type == TensorType.float32 || type == TensorType.float16) {
          return List<double>.filled(shape[dim], 0.0);
        }
        return List<int>.filled(shape[dim], 0);
      }
      return List.generate(shape[dim], (_) => make(dim + 1));
    }

    return make(0);
  }

  List<AiDetection> _decodeOutput(dynamic output, Tensor outputTensor) {
    final shape = outputTensor.shape;
    if (shape.length != 3) return [];

    // Model YOLO TFLite: [1, 14, 3549] = 4 box + 10 class untuk imgsz 416.
    // Beberapa export bisa [1, 3549, 13], jadi dua-duanya di-handle.
    final channelsFirst = shape[1] < shape[2];
    final channels = channelsFirst ? shape[1] : shape[2];
    final anchors = channelsFirst ? shape[2] : shape[1];
    final classCount = channels - 4;

    final detections = <AiDetection>[];

    for (int i = 0; i < anchors; i++) {
      double getValue(int c) {
        final raw = channelsFirst ? output[0][c][i] : output[0][i][c];
        return _dequantize(raw, outputTensor);
      }

      double cx = getValue(0);
      double cy = getValue(1);
      double w = getValue(2);
      double h = getValue(3);

      // Ada export yang output box 0..1, ada yang sudah 0..inputSize.
      if (cx <= 1.5 && cy <= 1.5 && w <= 1.5 && h <= 1.5) {
        cx *= _inputSize;
        cy *= _inputSize;
        w *= _inputSize;
        h *= _inputSize;
      }

      int bestClass = -1;
      double bestScore = -1;

      for (int c = 0; c < classCount && c < _labels.length; c++) {
        final score = getValue(4 + c).clamp(0.0, 1.0);
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      if (bestClass < 0 || bestClass >= _labels.length) continue;

      final label = _labels[bestClass];
      final threshold = binLabels.contains(label) ? binThreshold : trashThreshold;

      // Abaikan label yang bukan sampah/bin final.
      if (!trashLabels.contains(label) && !binLabels.contains(label)) continue;
      if (bestScore < threshold) continue;

      final left = (cx - w / 2).clamp(0.0, _inputSize.toDouble());
      final top = (cy - h / 2).clamp(0.0, _inputSize.toDouble());
      final right = (cx + w / 2).clamp(0.0, _inputSize.toDouble());
      final bottom = (cy + h / 2).clamp(0.0, _inputSize.toDouble());

      if (right <= left || bottom <= top) continue;
      if ((right - left) < 10 || (bottom - top) < 10) continue;

      detections.add(
        AiDetection(
          label: label,
          score: bestScore,
          box: Rect.fromLTRB(left, top, right, bottom),
        ),
      );
    }

    return _nms(detections, nmsThreshold).take(10).toList();
  }

  double _dequantize(dynamic value, Tensor tensor) {
    final v = value is num ? value.toDouble() : 0.0;
    final type = tensor.type;
    if (type == TensorType.float32 || type == TensorType.float16) return v;

    final scale = tensor.params.scale;
    final zeroPoint = tensor.params.zeroPoint;
    if (scale == 0) return v;
    return (v - zeroPoint) * scale;
  }

  List<AiDetection> _nms(List<AiDetection> detections, double threshold) {
    final sorted = [...detections]..sort((a, b) => b.score.compareTo(a.score));
    final picked = <AiDetection>[];

    for (final det in sorted) {
      var keep = true;
      for (final old in picked) {
        if (det.label == old.label && _iou(det.box, old.box) > threshold) {
          keep = false;
          break;
        }
      }
      if (keep) picked.add(det);
    }

    return picked;
  }

  double _iou(Rect a, Rect b) {
    final left = max(a.left, b.left);
    final top = max(a.top, b.top);
    final right = min(a.right, b.right);
    final bottom = min(a.bottom, b.bottom);

    final interW = max(0.0, right - left);
    final interH = max(0.0, bottom - top);
    final inter = interW * interH;

    final union = a.width * a.height + b.width * b.height - inter;
    if (union <= 0) return 0;
    return inter / union;
  }

  img.Image _cameraImageToImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888) {
      final plane = image.planes.first;
      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    }

    final width = image.width;
    final height = image.height;
    final out = img.Image(width: width, height: height);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yp = yPlane.bytes[yIndex];
        final up = uPlane.bytes[uvIndex];
        final vp = vPlane.bytes[uvIndex];

        final r = (yp + 1.402 * (vp - 128)).round();
        final g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round();
        final b = (yp + 1.772 * (up - 128)).round();

        out.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }

    return out;
  }
}
