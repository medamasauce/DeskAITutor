import 'dart:io';
import 'package:camera/camera.dart';

/// トリガー発火時のみ1枚キャプチャする。
/// 連続ストリーミングは行わず、発熱・電池消費を抑える。
class CameraService {
  CameraController? _controller;

  Future<void> initialize() async {
    if (_controller != null) return;
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
  }

  CameraController? get controller => _controller;

  Future<List<int>> captureJpegBytes() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not initialized');
    }
    final file = await controller.takePicture();
    return File(file.path).readAsBytes();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
