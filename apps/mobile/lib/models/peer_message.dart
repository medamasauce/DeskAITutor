import 'hint_step.dart';

/// PC側 (apps/web/src/types.ts の `PeerToPcMessage`) と同じJSON形状。
/// DataChannelはPeerJSの `serialization: 'json'` を使うため、
/// ここで作るMapがそのままJSON文字列としてPC側に届く。
sealed class PeerToPcMessage {
  Map<String, dynamic> toJson();
}

class StepsMessage extends PeerToPcMessage {
  final List<HintStep> steps;
  StepsMessage(this.steps);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'steps',
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

class ErrorMessage extends PeerToPcMessage {
  final String code;
  final String message;
  ErrorMessage({required this.code, required this.message});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error',
        'code': code,
        'message': message,
      };
}
