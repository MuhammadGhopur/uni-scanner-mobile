import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


late List<CameraDescription> cameras;

const String GOOGLE_SHEET_URL = 'https://script.google.com/macros/s/AKfycbzx2KZmmtoW7EKfj9xzlhBH9tSiI30EVYkx7pov0_XiPVaq0gLNkkqNIDwLEin9Sdlr/exec';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScannerPage(),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late CameraController _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isFlashOn = false;
  bool isScanning = true;
  bool isProcessing = false;
  Timer? scanTimer;

  String width = "";
  String sku = "";
  String poNumber = "";
  String usSize = "";
  String? _lastImagePath;

  Future<void> _deleteImageFile(String? path) async {
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.storage.request();

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    await _cameraController.setFlashMode(FlashMode.off);

    _startAutoScan();
    setState(() {});
  }

  String normalize(String text) {
    return text.toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1');
  }

  String extractWidth(List<String> lines) {
    const valid = ['M', 'D', 'W', 'N', 'E'];
    for (final l in lines) {
      final t = l.trim();
      if (valid.contains(t) && t.length == 1) return t;
    }
    return "";
  }

  String extractSku(String text) {
    final m = RegExp(r'\bGR[A-Z0-9]{4,6}\b').firstMatch(text);
    return m != null ? m.group(0)! : "";
  }

  String extractPo(String text) {
    final m = RegExp(r'\bP\d{5,7}\b').firstMatch(text);
    return m != null ? m.group(0)! : "";
  }

  String extractUsSize(List<String> lines) {
    for (final l in lines) {
      final m = RegExp(r'(\d{1,2}(\.\d)?)\s*US').firstMatch(l);
      if (m != null) return m.group(1)!;
    }
    return "";
  }

  // ================= AUTO SCAN =================
  void _startAutoScan() {
    isScanning = true;
    scanTimer?.cancel();

    scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!isScanning || isProcessing) return;
      isProcessing = true;

      try {
        final image = await _cameraController.takePicture();
        _lastImagePath = image.path; // Store the path
        final inputImage = InputImage.fromFile(File(image.path));
        final result = await _textRecognizer.processImage(inputImage);

        await _deleteImageFile(_lastImagePath); // Delete the image after processing

        final raw = normalize(result.text);
        final lines = raw.split('\n');

        final w = extractWidth(lines);
        final s = extractSku(raw);
        final p = extractPo(raw);
        final u = extractUsSize(lines);

        if (w.isNotEmpty && s.isNotEmpty && p.isNotEmpty && u.isNotEmpty) {
          isScanning = false;
          scanTimer?.cancel();

          // 🔔 BEEP + GETAR
          _audioPlayer.play(AssetSource('sounds/beep.mp3'));
          HapticFeedback.mediumImpact();

          setState(() {
            width = w;
            sku = s;
            poNumber = p;
            usSize = u;
            _lastImagePath = null; // Clear the path after successful scan
          });
        }
      } catch (e) {
        print("Error during scan: $e");
      } finally {
        isProcessing = false;
      }
    });
  }

  Future<void> saveToExcel() async {
    if (width.isEmpty || sku.isEmpty || poNumber.isEmpty || usSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk ditambahkan.')),
      );
      return;
    }

    final data = {
      'width': width,
      'sku': sku,
      'po': poNumber,
      'usSize': usSize,
      'Time': DateTime.now().toIso8601String(), // Add current timestamp
    };

    try {
      final response = await http.post(
        Uri.parse(GOOGLE_SHEET_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil ditambahkan ke Google Sheet')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan data: ${response.statusCode}')),
        );
        print('Error response: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
      print('Error sending data to Google Sheet: $e');
    }

    setState(() {
      width = "";
      sku = "";
      poNumber = "";
      usSize = "";
    });

    await _deleteImageFile(_lastImagePath);
    _lastImagePath = null;

    _startAutoScan();
  }

  Future<void> toggleFlash() async {
    await _cameraController.setFlashMode(
      isFlashOn ? FlashMode.off : FlashMode.torch,
    );
    setState(() => isFlashOn = !isFlashOn);
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController)),

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
                    Text("Width : $width",
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                    Text("SKU : $sku",
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                    Text("PO : $poNumber",
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                    Text("US Size : $usSize",
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                width = "";
                                sku = "";
                                poNumber = "";
                                usSize = "";
                              });
                              await _deleteImageFile(_lastImagePath);
                              _lastImagePath = null;
                              _startAutoScan();
                            },
                            child: const Text("Scan Ulang"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saveToExcel,
                            child: const Text("Tambahkan"),
                          ),
                        ),
                      ],
                    )
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
    _cameraController.dispose();
    _textRecognizer.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
