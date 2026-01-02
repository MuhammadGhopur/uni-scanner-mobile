import 'package:flutter/material.dart';
import 'package:uni_scanner/screens/scanner_page.dart';
import 'package:uni_scanner/services/camera_service.dart';

final CameraService _cameraService = CameraService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _cameraService.initCameras();
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
