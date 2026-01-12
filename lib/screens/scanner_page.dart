import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Import for OverlayEntry
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../services/camera_service.dart';
import '../services/text_recognition_service.dart';
import '../services/firestore_service.dart';
import '../utils/po_matcher.dart';
import '../utils/text_extractor.dart';
import '../services/google_sheet_service.dart';
import '../models/purchase_order.dart'; // Import PurchaseOrder model

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  final CameraService _cameraService = CameraService();
  final TextRecognitionService _ocr = TextRecognitionService();
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GoogleSheetService _googleSheetService = GoogleSheetService();

  bool isFlashOn = false;
  bool isScanning = true;
  bool isProcessing = false;
  bool _isAddingData = false;
  bool _showRescanButton = true; // New state variable
  Timer? scanTimer;

  String poNumber = "";
  String sku = "";
  String custId = "";
  String width = "";
  String size = "";

  String rightValue = "0";
  String leftValue = "0";
  String qtyValue = "0";

  List<String> _allPoNumbers = [];

  void _showTopNotification(String message, bool isSuccess) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Menyesuaikan dengan status bar
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800], // Warna abu kehitaman
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Timer(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

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
    _allPoNumbers = await _firestoreService.getAllPoNumbers();
    setState(() {});
    _startAutoScan();
  }

  void _startAutoScan() {
    scanTimer?.cancel();
    isScanning = true;

    scanTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!isScanning || isProcessing) return;
      isProcessing = true;

      try {
        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFile(File(image.path));
        final result = await _ocr.processImage(inputImage);

        final raw = _ocr.normalize(result.text);
        final extractedPo = PoMatcher.findPoFromOcr(
          ocrText: raw,
          poList: _allPoNumbers,
        );

        if (extractedPo != null && extractedPo.isNotEmpty) {
          isScanning = false;
          scanTimer?.cancel();

          final data = await _firestoreService.getProductByPo(extractedPo);
          final extractedWidth = TextExtractor.extractWidth(raw);
          final extractedSize = TextExtractor.extractSize(raw);

          if (data != null) {
            // Check if all required data is extracted
            if (extractedPo.isNotEmpty &&
                (data['sku'] ?? "").isNotEmpty &&
                (data['cust_id'] ?? "").isNotEmpty &&
                extractedWidth.isNotEmpty &&
                extractedSize.isNotEmpty) {
              setState(() {
                poNumber = data['po_number'] ?? ""; // Ekstrak dari map
                sku = data['sku'] ?? "";
                custId = data['cust_id'] ?? "";
                width = extractedWidth;
                size = extractedSize;
                try {
                  _audioPlayer.play(AssetSource('sounds/beep.mp3'));
                } catch (audioError) {
                  print('ERROR playing audio: $audioError');
                }
                HapticFeedback.mediumImpact();
              });
            } else {
              // If not all data is extracted, continue scanning
              isScanning = true;
              _startAutoScan();
            }
          } else {
            _showTopNotification('PO tidak ditemukan di database', false);
            isScanning = true;
            _startAutoScan();
          }
        }
      } catch (e) {
        print('ERROR SCAN: $e');
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

          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: toggleFlash,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                radius: 24,
                child: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          if (!isScanning)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SKU : $sku",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("PO : $poNumber",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Cust ID : $custId",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Width : $width",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Size : $size",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (poNumber.isNotEmpty &&
                                    sku.isNotEmpty &&
                                    width.isNotEmpty &&
                                    size.isNotEmpty &&
                                    !_isAddingData)
                                ? () async {
                                    setState(() {
                                      rightValue = "";
                                      leftValue = "";
                                      qtyValue = "";
                                    });
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Right or Left'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                title: const Text('Right'),
                                                onTap: () {
                                                  setState(() {
                                                    rightValue = "1";
                                                    leftValue = "";
                                                    qtyValue = "1";
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              ListTile(
                                                title: const Text('Left'),
                                                onTap: () {
                                                  setState(() {
                                                    rightValue = "";
                                                    leftValue = "1";
                                                    qtyValue = "1";
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );

                                    if (rightValue == "" && leftValue == "") {
                                      // User closed the dialog without making a selection
                                      return;
                                    }

                                    setState(() {
                                      _isAddingData = true;
                                      _showRescanButton = false; // Hide Rescan button
                                    });
                                    try {
                                      final success = await _googleSheetService.sendScannedData(
                                        poNumber: poNumber,
                                        sku: sku,
                                        width: width,
                                        size: size,
                                        right: rightValue,
                                        left: leftValue,
                                        qty: qtyValue,
                                      );
                                      _showTopNotification(
                                        success
                                            ? 'Data berhasil ditambahkan ke Google Sheet!'
                                            : 'Gagal menambahkan data ke Google Sheet. Periksa koneksi atau skrip Anda.',
                                        success,
                                      );
                                    } finally {
                                      setState(() {
                                        _isAddingData = false;
                                        poNumber = "";
                                        sku = "";
                                        custId = "";
                                        width = "";
                                        size = "";
                                        rightValue = "0"; // Reset values
                                        leftValue = "0"; // Reset values
                                        qtyValue = "0"; // Reset values
                                        _showRescanButton = true; // Show Rescan button again
                                      });
                                      isScanning = true;
                                      _startAutoScan();
                                    }
                                  }
                                : null,
                            child: const Text("Add"),
                          ),
                        ),
                        const SizedBox(width: 10), // Add some spacing
                        Visibility(
                          visible: _showRescanButton,
                          child: Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  poNumber = "";
                                  sku = "";
                                  custId = "";
                                  width = "";
                                  size = "";
                                });
                                isScanning = true;
                                _startAutoScan();
                              },
                              child: const Text("Rescan"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scanTimer?.cancel();
    _cameraController?.dispose();
    _ocr.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
