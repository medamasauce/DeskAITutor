import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/views/settings_view.dart';

void main() {
  testWidgets('SettingsView shows API key field and save button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsView(onSaved: (_) {})),
    );
    await tester.pump();

    expect(find.text('APIキー'), findsOneWidget);
    expect(find.text('保存して次へ'), findsOneWidget);
  });
}
