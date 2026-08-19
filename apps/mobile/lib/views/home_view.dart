import 'package:flutter/material.dart';
import '../models/peer_message.dart';
import '../services/camera_service.dart';
import '../services/gemini_service.dart';
import '../services/pairing_service.dart';

class HomeView extends StatefulWidget {
  final PairingService pairingService;
  final String apiKey;
  const HomeView({super.key, required this.pairingService, required this.apiKey});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _camera = CameraService();
  final _gemini = GeminiService();
  bool _cameraReady = false;
  bool _capturing = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _camera.initialize().then((_) {
      if (mounted) setState(() => _cameraReady = true);
    });
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  // トリガー発火時の共通処理（画面タップ / Bluetoothリモコンいずれからも呼ばれる想定）。
  Future<void> _onTrigger() async {
    if (_capturing || !_cameraReady) return;
    setState(() {
      _capturing = true;
      _lastError = null;
    });
    try {
      final bytes = await _camera.captureJpegBytes();
      final steps = await _gemini.solve(apiKey: widget.apiKey, imageBytes: bytes);
      await widget.pairingService.send(StepsMessage(steps));
    } on GeminiApiException catch (e) {
      setState(() => _lastError = e.message);
      await widget.pairingService.send(ErrorMessage(code: e.code, message: e.message));
    } catch (e) {
      setState(() => _lastError = '予期しないエラーが発生しました');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<PairingStatus>(
                stream: widget.pairingService.statusStream,
                initialData: widget.pairingService.status,
                builder: (context, snapshot) => Text(
                  _statusLabel(snapshot.data ?? PairingStatus.idle),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            if (_lastError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_lastError!, style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _onTrigger,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _capturing ? Colors.grey : Colors.blueAccent,
                    ),
                    child: Icon(
                      _capturing ? Icons.hourglass_top : Icons.camera_alt,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'タップして手元のノートを撮影・送信',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(PairingStatus status) {
    switch (status) {
      case PairingStatus.idle:
        return '未接続';
      case PairingStatus.connectingSignaling:
        return 'シグナリングサーバーに接続中…';
      case PairingStatus.connectingPeer:
        return 'PCとの接続を確立中…';
      case PairingStatus.connected:
        return 'PCと接続済み';
      case PairingStatus.failed:
        return '接続に失敗しました';
    }
  }
}
