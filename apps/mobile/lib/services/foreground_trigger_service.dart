import 'dart:async';
import 'package:flutter/services.dart';

/// TriggerForegroundService (Android/Kotlin) とのブリッジ。
/// フォアグラウンドサービスの起動/停止、バッテリー最適化除外の依頼、
/// Bluetoothリモコンのメディアボタン検知イベントの受信を担う。
class ForegroundTriggerService {
  static const _channel = MethodChannel('com.deskaitutor.mobile/trigger');

  final _triggerController = StreamController<void>.broadcast();
  Stream<void> get onTrigger => _triggerController.stream;

  ForegroundTriggerService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMediaButtonTrigger') {
        _triggerController.add(null);
      }
    });
  }

  Future<void> start() => _channel.invokeMethod('startForegroundService');

  Future<void> stop() => _channel.invokeMethod('stopForegroundService');

  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return result ?? false;
  }

  Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod('requestIgnoreBatteryOptimizations');

  void dispose() {
    _triggerController.close();
  }
}
