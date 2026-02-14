import 'dart:io';
import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import "package:path_provider/path_provider.dart";
import 'package:path/path.dart' as p;

Future<void> saveFileToDevice(Map<String, dynamic> data, String jsonFileName, String fileType) async{

  //append .json to jsonFileName if not exist
  if (!jsonFileName.endsWith(".json")) jsonFileName += ".json";

  //turn to json
  final jsonString = jsonEncode(data);

  //find or create main directory
  Directory? documentsDir = await getApplicationDocumentsDirectory();
  String docPath = p.join(documentsDir.path, "YihuaTimer");

  Directory fullDir = Directory(docPath);

  if (!await fullDir.exists()){
    await fullDir.create(recursive: true);
    print("Directory created at: ${fullDir.path}");
  }


  //find or create sub-directory for different timer profiles
  String filePath = p.join(fullDir.path, jsonFileName);
  File file = File(filePath);
  await file.writeAsString(jsonString);
  print("save successful");
}