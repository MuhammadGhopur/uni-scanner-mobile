import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  late List<CameraDescription> _cameras;
  List<CameraDescription> get cameras => _cameras;

  Future<void> initCameras() async {
    _cameras = await availableCameras();
  }

  CameraController getCameraController(CameraDescription camera) {
    return CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
  }
}
