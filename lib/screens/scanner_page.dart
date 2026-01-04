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
import '../utils/po_matcher.dart';
import '../utils/text_extractor.dart';
import '../services/google_sheet_service.dart';

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
  final GoogleSheetService _googleSheetService = GoogleSheetService();

  bool isFlashOn = false;
  bool isScanning = true;
  bool isProcessing = false;
  bool _isAddingData = false;
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
    _allPoNumbers = await _sqliteService.getAllPoNumbers();
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

          try {
            await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
          } catch (audioError) {
            print('ERROR playing audio: $audioError');
          }
          HapticFeedback.mediumImpact();

          final data = await _sqliteService.getProductByPo(extractedPo);
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
                poNumber = extractedPo;
                sku = data['sku'] ?? "";
                custId = data['cust_id'] ?? "";
                width = extractedWidth;
                size = extractedSize;
                
              });
            } else {
              // If not all data is extracted, continue scanning
              isScanning = true;
              _startAutoScan();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PO tidak ditemukan di database')),
            );
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
                        ElevatedButton(
                          onPressed: (poNumber.isNotEmpty &&
                                  sku.isNotEmpty &&
                                  width.isNotEmpty &&
                                  size.isNotEmpty &&
                                  !_isAddingData)
                              ? () async {
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Data successfully added to Google Sheet!'
                                              : 'Failed to add data to Google Sheet. Check your connection or script.',
                                        ),
                                      ),
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
                                      qtyValue = "0";   // Reset values
                                    });
                                    isScanning = true;
                                    _startAutoScan();
                                  }
                                }
                              : null,
                          child: const Text("Add"),
                        ),
                        ElevatedButton(
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
