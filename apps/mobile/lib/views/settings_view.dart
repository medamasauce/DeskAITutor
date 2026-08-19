import 'package:flutter/material.dart';
import '../services/api_key_store.dart';

class SettingsView extends StatefulWidget {
  final void Function(String apiKey) onSaved;
  const SettingsView({super.key, required this.onSaved});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _controller = TextEditingController();
  final _store = ApiKeyStore();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _store.load().then((key) {
      if (key != null && mounted) _controller.text = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini APIキーの設定')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Google AI Studioで取得した無料枠のAPIキーを入力してください。\n'
              'キーは端末内にのみ保存され、外部には送信されません。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'APIキー',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final key = _controller.text.trim();
                if (key.isEmpty) return;
                await _store.save(key);
                widget.onSaved(key);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('保存して次へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
