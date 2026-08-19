import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'ice_config.dart';
import 'peerjs_signaling.dart';
import '../models/peer_message.dart';

enum PairingStatus { idle, connectingSignaling, connectingPeer, connected, failed }

/// スマホ側 (送信側) のP2Pペアリングサービス。
/// PC側 (apps/web の useReceiverPeer) がRoom IDでPeerを待ち受けているので、
/// このサービスはそのRoom ID宛にWebRTC接続(DataChannel)を確立し、
/// 構造化データ (PeerToPcMessage) を送信する。
class PairingService {
  PeerJsSignaling? _signaling;
  RTCPeerConnection? _pc;
  RTCDataChannel? _channel;

  final _statusController = StreamController<PairingStatus>.broadcast();
  Stream<PairingStatus> get statusStream => _statusController.stream;
  PairingStatus _status = PairingStatus.idle;
  PairingStatus get status => _status;

  void _setStatus(PairingStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Future<void> connect(String targetRoomId) async {
    _setStatus(PairingStatus.connectingSignaling);
    final signaling = PeerJsSignaling();
    _signaling = signaling;

    final connectionId = 'dc_${DateTime.now().millisecondsSinceEpoch}';

    final pc = await createPeerConnection(iceServersConfig);
    _pc = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      signaling.sendCandidate(
        dst: targetRoomId,
        connectionId: connectionId,
        candidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _setStatus(PairingStatus.failed);
      }
    };

    final channel = await pc.createDataChannel(
      connectionId,
      RTCDataChannelInit(),
    );
    _channel = channel;
    channel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _setStatus(PairingStatus.connected);
      }
    };

    signaling.messages.listen((msg) => _handleSignalingMessage(msg, targetRoomId));

    await signaling.connect();
    await signaling.onOpen.first;

    _setStatus(PairingStatus.connectingPeer);
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    signaling.sendOffer(dst: targetRoomId, connectionId: connectionId, sdp: offer.sdp!);
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> msg, String targetRoomId) async {
    final pc = _pc;
    if (pc == null) return;
    final payload = msg['payload'] as Map<String, dynamic>?;

    switch (msg['type']) {
      case 'ANSWER':
        final sdp = payload?['sdp'] as Map<String, dynamic>?;
        if (sdp != null) {
          await pc.setRemoteDescription(RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String));
        }
        break;
      case 'CANDIDATE':
        final candidate = payload?['candidate'] as Map<String, dynamic>?;
        if (candidate != null) {
          await pc.addCandidate(RTCIceCandidate(
            candidate['candidate'] as String?,
            candidate['sdpMid'] as String?,
            candidate['sdpMLineIndex'] as int?,
          ));
        }
        break;
      case 'ERROR':
      case 'LEAVE':
      case 'EXPIRE':
        _setStatus(PairingStatus.failed);
        break;
    }
  }

  bool get isConnected => _channel?.state == RTCDataChannelState.RTCDataChannelOpen;

  Future<void> send(PeerToPcMessage message) async {
    final channel = _channel;
    if (channel == null || !isConnected) {
      throw StateError('DataChannel is not open');
    }
    await channel.send(RTCDataChannelMessage(jsonEncode(message.toJson())));
  }

  Future<void> dispose() async {
    await _channel?.close();
    await _pc?.close();
    _signaling?.dispose();
  }
}
