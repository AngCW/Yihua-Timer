import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;
  final String? assetName;

  UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    this.assetName,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    // GitHub Release JSON structure
    final assets = json['assets'] as List?;
    String downloadUrl = json['html_url'] ?? '';
    String? assetName;

    // Favor Windows executable (.exe or .msix)
    if (assets != null && assets.isNotEmpty) {
      final winAsset = assets.firstWhere(
        (a) => a['name'].toString().toLowerCase().endsWith('.exe') || 
               a['name'].toString().toLowerCase().endsWith('.zip') ||
               a['name'].toString().toLowerCase().endsWith('.msix'),
        orElse: () => assets.first,
      );
      downloadUrl = winAsset['browser_download_url'];
      assetName = winAsset['name'];
    }

    return UpdateInfo(
      version: json['tag_name'] ?? '0.0.0',
      changelog: json['body'] ?? '',
      downloadUrl: downloadUrl,
      assetName: assetName,
    );
  }
}

class UpdateService {
  static const String _owner = 'AngCW';
  static const String _repo = 'Yihua-Timer';
  static const String _releasesApiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static int compareVersion(String v1, String v2) {
    String cleanV1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
    String cleanV2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');
    
    List<int> v1Parts = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
       int p1 = i < v1Parts.length ? v1Parts[i] : 0;
       int p2 = i < v2Parts.length ? v2Parts[i] : 0;
       if (p1 > p2) return 1;
       if (p2 > p1) return -1;
    }
    return 0;
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(_releasesApiUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final remoteInfo = UpdateInfo.fromJson(data);
        
        if (compareVersion(remoteInfo.version, currentVersion) > 0) {
          return remoteInfo;
        }
      }
    } catch (e) {
      print('GitHub check update failed: $e');
    }
    return null;
  }

  static Future<File?> downloadUpdate(
    UpdateInfo info, 
    Function(double)? onProgress
  ) async {
    try {
      final response = await http.Client().send(http.Request('GET', Uri.parse(info.downloadUrl)));
      final total = response.contentLength ?? 0;
      int received = 0;

      final tempDir = await getTemporaryDirectory();
      final savePath = p.join(tempDir.path, info.assetName ?? 'update.zip');
      final file = File(savePath);
      final sink = file.openWrite();

      await response.stream.map((chunk) {
        received += chunk.length;
        if (onProgress != null && total > 0) {
          onProgress(received / total);
        }
        return chunk;
      }).pipe(sink);

      await sink.close();
      return file;
    } catch (e) {
      print('Download update failed: $e');
      return null;
    }
  }

  static Future<void> launchUpdateUrl(String? url) async {
    final uri = Uri.parse(url ?? 'https://github.com/$_owner/$_repo/releases');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> installUpdate(File file) async {
    if (Platform.isWindows) {
      // Launch the installer (exe or msix or zip folder)
      await Process.start('explorer.exe', [file.path]);
    }
  }
}
