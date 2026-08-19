import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/hint_step.dart';
import 'package:mobile/models/peer_message.dart';

void main() {
  group('HintStep', () {
    test('round-trips through JSON', () {
      const step = HintStep(order: 1, content: '両辺を2で割る', latex: 'x = 4');
      final json = step.toJson();
      final parsed = HintStep.fromJson(json);

      expect(parsed.order, 1);
      expect(parsed.content, '両辺を2で割る');
      expect(parsed.latex, 'x = 4');
    });

    test('omits latex key when absent', () {
      const step = HintStep(order: 2, content: 'ヒントのみ');
      expect(step.toJson().containsKey('latex'), isFalse);
    });
  });

  group('PeerToPcMessage', () {
    test('StepsMessage matches the web app\'s expected shape', () {
      final msg = StepsMessage([
        const HintStep(order: 1, content: 'まず整理する', latex: '2x=8'),
      ]);
      final json = msg.toJson();

      expect(json['type'], 'steps');
      expect(json['steps'], isA<List>());
      expect((json['steps'] as List).first, {'order': 1, 'content': 'まず整理する', 'latex': '2x=8'});
    });

    test('ErrorMessage matches the web app\'s expected shape', () {
      final msg = ErrorMessage(code: 'RATE_LIMIT', message: '今日はAPIの利用上限に達しました');
      final json = msg.toJson();

      expect(json, {
        'type': 'error',
        'code': 'RATE_LIMIT',
        'message': '今日はAPIの利用上限に達しました',
      });
    });
  });
}
