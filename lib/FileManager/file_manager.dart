import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;

Future<void> saveToJsonFile(Map<String, dynamic> data, String timerProfileName, String jsonType) async {
  Directory? baseDir = await getApplicationDocumentsDirectory();
  String fullPath = p.join(baseDir.path, timerProfileName);
  Directory fullDir = Directory(fullPath);

  if (!await fullDir.exists()) fullDir.create();

  if (!jsonType.endsWith(".json")) jsonType += ".json";

  String filePath = p.join(fullDir.path, jsonType);
  File file = File(filePath);

  if (!await file.exists()) file.parent.create(recursive: true);

  String jsonString = jsonEncode(data);
  file.writeAsString(jsonString);
  print("json written to $filePath");
}