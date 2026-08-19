import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/api_key_store.dart';
import 'services/pairing_service.dart';
import 'views/home_view.dart';
import 'views/qr_scan_view.dart';
import 'views/settings_view.dart';

void main() {
  runApp(const DeskAiTutorApp());
}

class DeskAiTutorApp extends StatelessWidget {
  const DeskAiTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desk AI Tutor',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const RootFlow(),
    );
  }
}

/// 起動フロー: APIキー未設定 -> 設定画面 / QR未スキャン -> QRスキャン画面
/// / ペアリング済み -> 待機画面(タップトリガー)。
class RootFlow extends StatefulWidget {
  const RootFlow({super.key});

  @override
  State<RootFlow> createState() => _RootFlowState();
}

class _RootFlowState extends State<RootFlow> {
  final _apiKeyStore = ApiKeyStore();
  String? _apiKey;
  PairingService? _pairingService;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await [Permission.camera].request();
    final key = await _apiKeyStore.load();
    setState(() {
      _apiKey = key;
      _loading = false;
    });
  }

  void _onApiKeySaved(String key) {
    setState(() => _apiKey = key);
  }

  void _onRoomScanned(String roomId) {
    final service = PairingService();
    service.connect(roomId);
    setState(() => _pairingService = service);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_apiKey == null) {
      return SettingsView(onSaved: _onApiKeySaved);
    }
    final pairing = _pairingService;
    if (pairing == null) {
      return QrScanView(onScanned: _onRoomScanned);
    }
    return HomeView(pairingService: pairing, apiKey: _apiKey!);
  }
}
