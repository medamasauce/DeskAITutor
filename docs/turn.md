# TURN中継について

## デフォルト構成

本プロジェクトはWebRTCのICE経路として、既定で以下を使用します。

1. Googleのパブリック STUN サーバー（`stun.l.google.com:19302`）
2. [Open Relay Project](https://www.metered.ca/tools/openrelay/) の無料 TURN サーバー（STUNのみで直接接続できない場合のフォールバック）

通信内容自体はWebRTCのDTLSで暗号化されるため、TURN業者はペイロードを復号できません。ただし、TURN経由時には送信元/宛先IPアドレスや通信量などの**メタデータ**がTURN業者から見える構造になります。この点が気になる場合は、以下の自前TURN（coturn）構築をご検討ください。

## 自前TURN（coturn）を使う場合（オプション）

メタデータも外部に一切触れさせたくない場合は、自宅サーバーやVPS上に [coturn](https://github.com/coturn/coturn) を構築し、`apps/web/src/iceConfig.ts` の `ICE_SERVERS` を自前のTURNサーバー情報に差し替えてください。

```bash
# 例: Ubuntu/Debian系での最小インストール
sudo apt-get install coturn

# /etc/turnserver.conf の主な設定例
listening-port=3478
tls-listening-port=5349
realm=your-domain.example.com
user=deskaitutor:CHANGE_ME_STRONG_PASSWORD
lt-cred-mech
cert=/etc/letsencrypt/live/your-domain.example.com/fullchain.pem
pkey=/etc/letsencrypt/live/your-domain.example.com/privkey.pem
```

```ts
// apps/web/src/iceConfig.ts
export const ICE_SERVERS: RTCIceServer[] = [
  { urls: 'stun:stun.l.google.com:19302' },
  {
    urls: 'turn:your-domain.example.com:3478',
    username: 'deskaitutor',
    credential: 'CHANGE_ME_STRONG_PASSWORD',
  },
]
```

自前TURNを常時起動しておく必要があるため、「Zero Server Cost」の原則からは外れる点に注意してください（プライバシーとの trade-off です）。
