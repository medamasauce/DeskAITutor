import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hint_step.dart';

class GeminiApiException implements Exception {
  final String code; // 'RATE_LIMIT' | 'SERVER_ERROR' | 'AUTH' | 'UNKNOWN'
  final String message;
  GeminiApiException(this.code, this.message);
}

/// Gemini APIへ手元ノートの画像を送信し、構造化された解法ステップ
/// (steps: [{order, content, latex?}]) を取得する。
/// response_schemaで構造化出力を強制することで、モデルが
/// 「一気に全解答を出してしまう」挙動をAPI側でも抑制する
/// (UI側の段階的開示ガードと合わせた二重の安全策)。
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _model = 'gemini-2.5-flash';
  static const _systemPrompt = '''
あなたは中学・高校生向けの学習アシスタントです。
画像に写っている手書きのノートや問題集の内容を正確に読み取り、
解答そのものではなく「解き方のステップ」を順番に生成してください。

- 手書きの数式は正確にLaTeXへ変換すること
- 各ステップは1つの操作・考え方に限定し、細かく分割すること
- 最初のステップで答えを明かさないこと
''';

  static final _responseSchema = {
    'type': 'OBJECT',
    'properties': {
      'steps': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'order': {'type': 'INTEGER'},
            'content': {'type': 'STRING'},
            'latex': {'type': 'STRING'},
          },
          'required': ['order', 'content'],
        },
      },
    },
    'required': ['steps'],
  };

  Future<List<HintStep>> solve({
    required String apiKey,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {'text': '写真の内容を解析し、解法ステップをsteps配列で返してください。'},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': _responseSchema,
      },
    });

    final http.Response res;
    try {
      res = await _client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    } catch (_) {
      throw GeminiApiException('NETWORK', 'ネットワークに接続できませんでした');
    }

    if (res.statusCode == 429) {
      throw GeminiApiException('RATE_LIMIT', '今日はAPIの利用上限に達しました');
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw GeminiApiException('AUTH', 'APIキーが正しくないか、権限がありません');
    }
    if (res.statusCode >= 500) {
      throw GeminiApiException('SERVER_ERROR', 'Gemini APIが一時的に利用できません');
    }
    if (res.statusCode != 200) {
      throw GeminiApiException('UNKNOWN', 'エラーが発生しました (${res.statusCode})');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _parseSteps(json);
  }

  List<HintStep> _parseSteps(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List;
      final parts = (candidates.first as Map<String, dynamic>)['content']['parts'] as List;
      final text = (parts.first as Map<String, dynamic>)['text'] as String;
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final steps = parsed['steps'] as List;
      return steps
          .map((s) => HintStep.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw GeminiApiException('UNKNOWN', 'AIの応答を解析できませんでした');
    }
  }
}
