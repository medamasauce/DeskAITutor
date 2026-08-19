import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/gemini_service.dart';

http.Client _fakeClient(int statusCode, String body) {
  return MockClient((request) async => http.Response(
        body,
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ));
}

void main() {
  group('GeminiService', () {
    test('parses steps from a well-formed structured response', () async {
      final geminiJson = jsonEncode({
        'steps': [
          {'order': 1, 'content': '両辺から3を引く', 'latex': '2x=8'},
          {'order': 2, 'content': '両辺を2で割る', 'latex': 'x=4'},
        ],
      });
      final responseBody = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': geminiJson},
              ],
            },
          },
        ],
      });

      final service = GeminiService(client: _fakeClient(200, responseBody));
      final steps = await service.solve(apiKey: 'dummy', imageBytes: [1, 2, 3]);

      expect(steps, hasLength(2));
      expect(steps[0].order, 1);
      expect(steps[1].latex, 'x=4');
    });

    test('maps HTTP 429 to a RATE_LIMIT GeminiApiException', () async {
      final service = GeminiService(client: _fakeClient(429, '{}'));

      await expectLater(
        service.solve(apiKey: 'dummy', imageBytes: [1]),
        throwsA(isA<GeminiApiException>().having((e) => e.code, 'code', 'RATE_LIMIT')),
      );
    });

    test('maps HTTP 500 to a SERVER_ERROR GeminiApiException', () async {
      final service = GeminiService(client: _fakeClient(500, '{}'));

      await expectLater(
        service.solve(apiKey: 'dummy', imageBytes: [1]),
        throwsA(isA<GeminiApiException>().having((e) => e.code, 'code', 'SERVER_ERROR')),
      );
    });
  });
}
