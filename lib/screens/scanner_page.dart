import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../services/camera_service.dart';
import '../services/text_recognition_service.dart';
import '../services/sqlite_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  final CameraService _cameraService = CameraService();
  final TextRecognitionService _ocr = TextRecognitionService();
  final SQLiteService _sqliteService = SQLiteService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isFlashOn = false;
  bool isScanning = true;
  bool isProcessing = false;
  bool _isSaving = false;
  Timer? scanTimer;

  String sku = "";
  String poNumber = "";
  String custId = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initCameras();
    _cameraController =
        _cameraService.getCameraController(_cameraService.cameras.first);

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off);
    setState(() {});
    _startAutoScan();
  }

  void _startAutoScan() {
    isScanning = true;
    scanTimer?.cancel();

    scanTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!isScanning || isProcessing) return;
      isProcessing = true;

      try {
        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFile(File(image.path));
        final result = await _ocr.processImage(inputImage);

        final raw = _ocr.normalize(result.text);
        final lines = raw.split('\n');
        final po = _ocr.extractPoFromLine4(lines);

        if (po.isNotEmpty) {
          isScanning = false;
          scanTimer?.cancel();

          _audioPlayer.play(AssetSource('sounds/beep.mp3'));
          HapticFeedback.mediumImpact();

          final data = await _sqliteService.getProductByPo(po);

          if (data != null) {
            setState(() {
              poNumber = data['po_number'] ?? "";
              sku = data['sku'] ?? "";
              custId = data['cust_id'] ?? "";
            });
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PO Number tidak ditemukan')),
              );
            }
            isScanning = true;
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: $e')),
          );
        }
        isScanning = true;
      } finally {
        isProcessing = false;
      }
    });
  }

  Future<void> toggleFlash() async {
    await _cameraController?.setFlashMode(
      isFlashOn ? FlashMode.off : FlashMode.torch,
    );
    setState(() => isFlashOn = !isFlashOn);
  }

  Future<void> saveProductToDatabase() async {
    if (_isSaving || sku.isEmpty || poNumber.isEmpty || custId.isEmpty) return;

    setState(() => _isSaving = true);

    final product = {
      'po_number': poNumber,
      'cust_id': custId,
      'sku': sku,
    };

    try {
      await _sqliteService.insertProduct(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan')),
        );
      }
    } finally {
      setState(() {
        sku = "";
        poNumber = "";
        custId = "";
        _isSaving = false;
      });

      isScanning = true;
      _startAutoScan();
    }
  }

  @override
  void dispose() {
    scanTimer?.cancel();
    _cameraController?.dispose();
    _ocr.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
        ],
      ),
    );
  }
}
