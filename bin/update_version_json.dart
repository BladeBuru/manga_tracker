import 'dart:convert';
import 'dart:io';

void main() async {
  final version = Platform.environment['VERSION'];
  final apkUrl = Platform.environment['APK_URL'];
  final rawNotes = Platform.environment['NOTES'];

  if (version == null || apkUrl == null || rawNotes == null) {
    stderr.writeln("❌ VERSION, APK_URL ou NOTES manquants !");
    exit(1);
  }

  final file = File('assets/version.json');
  Map<String, dynamic> data = {};

  if (file.existsSync()) {
    data = jsonDecode(await file.readAsString());
  }

  data['latestVersion'] = version;
  data['apkUrl'] = apkUrl;
  data['inherit'] = true;

  data['changelog'] ??= [];

  final notesList = rawNotes
      .split('\\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  data['changelog'].insert(0, {
    'version': version,
    'notes': notesList,
  });

  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(data));
  print("✅ version.json mis à jour avec $version");
}
