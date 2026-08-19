import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

/// PeerJS Cloud (0.peerjs.com) が使うシグナリングWebSocketプロトコルの
/// 最小実装。PC側 (apps/web) は `peerjs` npm パッケージのデフォルト設定
/// (key: 'peerjs', 既定ホスト) を使ってRoom IDでPeerを待ち受けているため、
/// スマホ側もこの最小クライアントで同じシグナリングサーバーに接続し、
/// SDP/ICE candidateをやり取りする。
///
/// 参考: https://github.com/peers/peerjs-server (WebSocketメッセージ仕様)
class PeerJsSignaling {
  static const _host = '0.peerjs.com';
  static const _port = 443;
  static const _key = 'peerjs';
  static const _version = '1.5.5';

  final String peerId;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _openController = StreamController<void>.broadcast();
  bool _open = false;

  PeerJsSignaling({String? peerId}) : peerId = peerId ?? _randomId();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<void> get onOpen => _openController.stream;
  bool get isOpen => _open;

  static String _randomId() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  Future<void> connect() async {
    final token = _randomId();
    final uri = Uri(
      scheme: 'wss',
      host: _host,
      port: _port,
      path: '/peerjs',
      queryParameters: {
        'key': _key,
        'id': peerId,
        'token': token,
        'version': _version,
      },
    );
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        if (msg['type'] == 'OPEN') {
          _open = true;
          _openController.add(null);
          _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
            _send({'type': 'HEARTBEAT'});
          });
        }
        _messageController.add(msg);
      },
      onError: (_) => _open = false,
      onDone: () => _open = false,
    );
  }

  void _send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  void sendOffer({
    required String dst,
    required String connectionId,
    required String sdp,
  }) {
    _send({
      'type': 'OFFER',
      'dst': dst,
      'payload': {
        'sdp': {'type': 'offer', 'sdp': sdp},
        'type': 'data',
        'connectionId': connectionId,
        'label': connectionId,
        'reliable': true,
        'serialization': 'json',
        'browser': 'dart',
      },
    });
  }

  void sendAnswer({
    required String dst,
    required String connectionId,
    required String sdp,
  }) {
    _send({
      'type': 'ANSWER',
      'dst': dst,
      'payload': {
        'sdp': {'type': 'answer', 'sdp': sdp},
        'connectionId': connectionId,
        'browser': 'dart',
      },
    });
  }

  void sendCandidate({
    required String dst,
    required String connectionId,
    required Map<String, dynamic> candidate,
  }) {
    _send({
      'type': 'CANDIDATE',
      'dst': dst,
      'payload': {
        'candidate': candidate,
        'type': 'data',
        'connectionId': connectionId,
      },
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _openController.close();
  }
}
