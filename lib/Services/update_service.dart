import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '0.0.0',
      changelog: json['changelog'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
    );
  }
}

class UpdateService {
  // Use a direct download link for the version.json file on Google Drive
  // The user must provide the file ID of the version.json file.
  static const String _versionJsonUrl = 'https://drive.google.com/uc?export=download&id=12zYliIXyDuoVznHu3zSb1e-8VIsMvSyl';
  
  // The folder link for manual opening if update fails or for fallback
  static const String _folderUrl = 'https://drive.google.com/drive/folders/1ruV9Dsa2Ooz2SbNaF01XwH26vnGdUXt2';

  /// Compares version strings like 'v1.0.2' or '1.0.3'
  static int compareVersion(String v1, String v2) {
    // Strip 'v' prefix if present
    String cleanV1 = v1.startsWith('v') ? v1.substring(1) : v1;
    String cleanV2 = v2.startsWith('v') ? v2.startsWith('v') ? v2.substring(1) : v2 : v2;
    
    List<int> v1Parts = cleanV1.split('.').map(int.parse).toList();
    List<int> v2Parts = cleanV2.split('.').map(int.parse).toList();
    
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
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch remote version info
      // Note: If direct link fails, we might need a different approach or ask user for API key.
      // For now, we assume a publicly accessible JSON file.
      final response = await http.get(Uri.parse(_versionJsonUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final remoteInfo = UpdateInfo.fromJson(data);
        
        if (compareVersion(remoteInfo.version, currentVersion) > 0) {
          return remoteInfo;
        }
      }
    } catch (e) {
      print('Check for update failed: $e');
    }
    return null;
  }

  static Future<void> launchUpdateUrl(String? url) async {
    final uri = Uri.parse(url ?? _folderUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
