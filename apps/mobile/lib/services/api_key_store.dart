import 'package:shared_preferences/shared_preferences.dart';

/// 端末ローカルにのみGemini APIキーを保存する（外部送信しない）。
class ApiKeyStore {
  static const _prefKey = 'gemini_api_key';

  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  Future<void> save(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, apiKey);
  }
}
